package sqlancer.sqlite3;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import sqlancer.IgnoreMeException;
import sqlancer.OracleFactory;
import sqlancer.Randomly;
import sqlancer.common.oracle.CompositeTestOracle;
import sqlancer.common.oracle.EGraphMetamorphicOracle;
import sqlancer.common.oracle.NoRECOracle;
import sqlancer.common.oracle.RustEGraphVariantGenerator;
import sqlancer.common.oracle.TLPWhereOracle;
import sqlancer.common.oracle.TestOracle;
import sqlancer.common.query.ExpectedErrors;
import sqlancer.common.query.SQLQueryAdapter;
import sqlancer.common.query.SQLancerResultSet;
import sqlancer.common.schema.AbstractTables;
import sqlancer.sqlite3.ast.SQLite3Expression;
import sqlancer.sqlite3.ast.SQLite3Constant;
import sqlancer.sqlite3.ast.SQLite3Expression.BinaryComparisonOperation;
import sqlancer.sqlite3.ast.SQLite3Expression.BinaryComparisonOperation.BinaryComparisonOperator;
import sqlancer.sqlite3.ast.SQLite3Expression.SQLite3ColumnName;
import sqlancer.sqlite3.ast.SQLite3Expression.Sqlite3BinaryOperation;
import sqlancer.sqlite3.ast.SQLite3Expression.Sqlite3BinaryOperation.BinaryOperator;
import sqlancer.sqlite3.ast.SQLite3Expression.SQLite3OrderingTerm;
import sqlancer.sqlite3.ast.SQLite3Expression.SQLite3OrderingTerm.Ordering;
import sqlancer.sqlite3.ast.SQLite3Select;
import sqlancer.sqlite3.gen.SQLite3ExpressionGenerator;
import sqlancer.sqlite3.schema.SQLite3Schema.SQLite3Column;
import sqlancer.sqlite3.schema.SQLite3Schema.SQLite3Table;
import sqlancer.sqlite3.oracle.SQLite3CODDTestOracle;
import sqlancer.sqlite3.oracle.SQLite3Fuzzer;
import sqlancer.sqlite3.oracle.SQLite3PivotedQuerySynthesisOracle;
import sqlancer.sqlite3.oracle.SQLite3EGraphInputCorpus.CorpusQueryInput;
import sqlancer.sqlite3.oracle.EGraphContextReplayWriter;
import sqlancer.sqlite3.oracle.EGraphPredicateFilter;
import sqlancer.sqlite3.oracle.SQLite3EGraphInputCorpus;
import sqlancer.sqlite3.oracle.EGraphSqlCoverage;
import sqlancer.sqlite3.oracle.tlp.SQLite3TLPAggregateOracle;
import sqlancer.sqlite3.oracle.tlp.SQLite3TLPDistinctOracle;
import sqlancer.sqlite3.oracle.tlp.SQLite3TLPGroupByOracle;
import sqlancer.sqlite3.oracle.tlp.SQLite3TLPHavingOracle;

public enum SQLite3OracleFactory implements OracleFactory<SQLite3GlobalState> {
    PQS {
        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws SQLException {
            return new SQLite3PivotedQuerySynthesisOracle(globalState);
        }

        @Override
        public boolean requiresAllTablesToContainRows() {
            return true;
        }

    },
    EGRAPH {
        @Override
        public boolean requiresAllTablesToContainRows() {
            // Deliberately false. The flag makes ProviderAdapter.getTestOracle discard the whole
            // database as soon as *any* table has zero rows, throwing away the entire schema
            // generation and data insertion - which is what collapsed throughput to 39% when the
            // oracle stopped filling tables itself. EGRAPH instead skips empty tables when it
            // picks its target, so an unrelated empty table costs nothing.
            return false;
        }

        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws SQLException {
            if (globalState.getOptions().getEGraphUrl() == null
                    || globalState.getOptions().getEGraphUrl().isBlank()) {
                throw new IllegalArgumentException("SQLite3 EGRAPH oracle requires --egraph-url");
            }
            SQLite3ExpressionGenerator gen = new SQLite3ExpressionGenerator(globalState);
            ExpectedErrors errors = ExpectedErrors.newErrors().with(SQLite3Errors.getExpectedExpressionErrors())
                    .with(SQLite3Errors.getMatchQueryErrors()).with(SQLite3Errors.getQueryErrors())
                    .with("misuse of aggregate", "misuse of window function",
                            "second argument to nth_value must be a positive integer", "no such table",
                            "no query solution", "unable to use function MATCH in the requested context")
                    .build();
            List<CorpusQueryInput> corpusInputs = SQLite3EGraphInputCorpus
                    .readQueryInputRecords(globalState.getDbmsSpecificOptions());

            EGraphMetamorphicOracle.QueryGenerator<SQLite3GlobalState> queryGenerator = (state) -> {
                if (!corpusInputs.isEmpty() && Randomly.fromOptions(true, true, false)) {
                    try {
                        return createCorpusGeneratedQuery(state, corpusInputs);
                    } catch (IgnoreMeException ignored) {
                        try {
                            resetCorpusSchema(state);
                        } catch (Exception resetError) {
                            throw new IgnoreMeException();
                        }
                        // Fall back to the generated base-query path below.
                    }
                }
                if (CORPUS_SETUP_ONLY) {
                    EGraphSqlCoverage.trace("corpus-setup-only skip reason=random-generation-path-disabled");
                    throw new IgnoreMeException();
                }
                SQLite3Provider.ensureEGraphRandomDatabase(state);
                // Pick a table to query. Regular tables, plus R-Tree virtual tables when
                // egraph.rtreeTargets is on (default). R-Tree is the one virtual-table module whose
                // predicates the existing rule set can already rewrite: its columns are numeric, so
                // a WHERE over them is the same comparison/AND/OR tree the e-graph handles for a
                // plain table - no new language nodes or rules needed.
                //
                // The reason to want it: on a plain table these rewrites are pointless, because
                // SQLite's front end (sqlite3WhereSplit flattening AND, sqlite3ExprCommute
                // normalising `const OP col`) collapses every spelling to the same VDBE program, so
                // both sides of the comparison run identical bytecode and a defect cancels out. On
                // an R-Tree the constraint push-down happens *after* that normalisation and depends
                // on the shape of the term list, so the spellings do not collapse. Measured on one
                // predicate (x1 <= 6.0 AND x2 >= 6.0, 32 variants): six distinct plans, including
                // full-scan-with-post-filter (no constraint consumed), one-constraint, two
                // constraints in either order, and MULTI-INDEX OR with two separate R-Tree scans.
                // Those are six different paths through rtree.c that must all agree.
                //
                // FTS stays excluded: its index is only reachable through MATCH, which egraphMode
                // removes and which SqlLang has no node for, so rewriting an FTS predicate would
                // only ever produce full-table scans.
                // Empty tables are skipped rather than filled: a base query over an empty table
                // matches nothing, which makes the metamorphic comparison vacuous.
                // Skip empty tables rather than filling them: a base query over an empty table
                // matches nothing, which makes the metamorphic comparison vacuous. Selecting
                // around them is far cheaper than DELETE + reinserting a controlled pool, and
                // the data then comes entirely from SQLancer's own INSERT/UPDATE actions.
                List<SQLite3Table> tables = state.getSchema().getDatabaseTables().stream()
                        .filter(t -> !t.isView() && (!t.isVirtual() || isRtreeTable(state, t))
                                && t.getNrRows(state) > 0)
                        .collect(java.util.stream.Collectors.toList());
                if (tables.isEmpty())
                    throw new IgnoreMeException();
                SQLite3Table chosen = Randomly.fromList(tables);
                // Which kind of table the base query targets. Without this the report cannot tell
                // "R-Tree was never picked" from "R-Tree was picked but every check was discarded",
                // and the first two runs after enabling R-Tree targets were unreadable for exactly
                // that reason.
                // A free-form random predicate on an R-Tree reads as a full scan with a post-filter:
                // the module only consumes `coordinateColumn <op> constant` terms, which the
                // generator practically never produces. Build the WHERE from constraint terms
                // instead for most R-Tree checks, and leave the rest on the random path so the
                // shapes the rule set is usually exercised on stay represented.
                int coordinateColumns = rtreeCoordinateColumns(state, chosen);
                boolean rtreePushdown = coordinateColumns >= 2 && RTREE_PUSHDOWN_PERCENT > 0
                        && Randomly.getNotCachedInteger(0, 100) < RTREE_PUSHDOWN_PERCENT;
                // On a plain table the random predicate leaves every rewrite at "same opcodes,
                // different order". An index-usable term instead lets the NOT-wrapping rules turn
                // an index seek into a full scan, which is the only strategy-level difference the
                // existing rule set can reach here. Prepared before the report bucket is chosen
                // because it can fail (no named column, no non-blob row) and then this check has to
                // fall back to the random path.
                IndexedPredicate indexedPredicate = !chosen.isVirtual() && INDEXED_PREDICATE_PERCENT > 0
                        && Randomly.getNotCachedInteger(0, 100) < INDEXED_PREDICATE_PERCENT
                                ? prepareIndexedPredicate(state, chosen)
                                : null;
                // The paths are reported apart because the plan histogram buckets by exactly this
                // string, and comparing them within one run is the whole point of the split.
                EGraphSqlCoverage.recordTargetTableKind(chosen.isVirtual()
                        ? (rtreePushdown ? "RTREE_VIRTUAL_PUSHDOWN" : "RTREE_VIRTUAL_RANDOM")
                        : (indexedPredicate != null ? "REGULAR_INDEXED_CONST" : "REGULAR_RANDOM"));
                AbstractTables<SQLite3Table, SQLite3Column> targetTables = new AbstractTables<>(
                        java.util.Collections.singletonList(chosen));

                SQLite3ExpressionGenerator configuredGen = gen.setEgraphMode().setTablesAndColumns(targetTables);
                SQLite3Select select;
                SQLite3Expression whereCondition;
                // Retry until WHERE references at least one column (egraph requires column
                // refs)
                int attempts = 0;
                do {
                    select = configuredGen.generateSelect();
                    select.setFromList(configuredGen.getTableRefs());
                    if (rtreePushdown) {
                        whereCondition = generateRtreePushdownWhere(chosen, coordinateColumns, configuredGen);
                    } else if (indexedPredicate != null) {
                        whereCondition = generateIndexedConstantWhere(indexedPredicate, configuredGen);
                    } else {
                        whereCondition = configuredGen.generateBooleanExpression();
                    }
                    attempts++;
                    // Reject clauses that can never be TRUE (x-x, x<x, comparisons
                    // with NULL, ...) here rather than discovering it with a probe
                    // query after the data setup: an empty original result makes the
                    // metamorphic comparison vacuous.
                    if (EGraphPredicateFilter.isEgraphCompatible(whereCondition)) {
                        EGraphSqlCoverage.recordSatisfiability(
                                EGraphPredicateFilter.isPotentiallySatisfiable(whereCondition));
                    }
                } while ((!EGraphPredicateFilter.isEgraphCompatible(whereCondition)
                        || !EGraphPredicateFilter.isPotentiallySatisfiable(whereCondition)) && attempts < 100);
                if (!EGraphPredicateFilter.isEgraphCompatible(whereCondition)
                        || !EGraphPredicateFilter.isPotentiallySatisfiable(whereCondition)) {
                    throw new IgnoreMeException();
                }
                // Return SELECT for oracle to execute + egraph to rewrite + compare
                // An index seek and a full scan visit rows in different orders, so a LIMIT would
                // make the two sides return different rows and an ORDER BY with ties would make the
                // order-sensitive comparison fire - both are false positives, not defects. Measured:
                // `c1 > 1 LIMIT 5` returns ids 26,9,49,32,15 and the scanning spelling returns
                // 4,5,9,10,11. Without LIMIT the multiset comparison is safe.
                EGraphBaseQuery baseQuery = buildEGraphBaseQuery(select, whereCondition, targetTables,
                        indexedPredicate != null);
                String rewriteQuery = baseQuery.sql;
                boolean baseHasRows = queryProducesRows(state, rewriteQuery);
                EGraphSqlCoverage.recordBaseProbe(rewriteQuery, baseHasRows);
                if (!baseHasRows) {
                    // An empty original is only vacuous if the variants are empty too. If a variant
                    // returns rows, that is the cleanest signal this oracle has - no row-order and no
                    // value-formatting ambiguity, straight to hasSingleSideEmptyMismatch. Discarding
                    // every empty base query is exactly what keeps that judgment unreachable: the
                    // workload report has original-only/variant-only empty pinned at 0 across every
                    // run so far. Sampled rather than always-on because ~78% of base queries probe
                    // empty and most of those checks will compare two empty results and learn nothing.
                    if (EMPTY_BASE_CHECK_PERCENT <= 0
                            || Randomly.getNotCachedInteger(0, 100) >= EMPTY_BASE_CHECK_PERCENT) {
                        throw new IgnoreMeException();
                    }
                    // No wrapper shape here: a shape over an empty base filters to empty anyway and
                    // would only cost a probe. The plain comparison is what carries the signal.
                    EGraphSqlCoverage.recordEmptyBaseCheck();
                    EGraphSqlCoverage.recordCheck();
                    EGraphSqlCoverage.analyzeWhere(rewriteQuery);
                    return new EGraphMetamorphicOracle.GeneratedQuery(rewriteQuery, rewriteQuery, variant -> variant,
                            "RANDOM_GENERATED_1_3_EMPTY_BASE");
                }
                EGraphSqlCoverage.recordWrapperShape(baseQuery.shapeName);
                EGraphCoverageContext originalContext = createEGraphCoverageContext(state, targetTables,
                        chooseEGraphExecutionCoverageShape(EGraphCoverageShape.PLAIN));
                EGraphCoverageContext variantContext = createVariantEGraphCoverageContext(originalContext,
                        targetTables);
                String result = wrapEGraphCoverageShape(rewriteQuery, originalContext);
                ProbeOutcome wrappedOutcome = probeQuery(state, result);
                EGraphSqlCoverage.recordOriginalWrapper(originalContext.shape.name(), wrappedOutcome.name(), result);
                if (wrappedOutcome != ProbeOutcome.ROWS) {
                    // The wrapper filtered away every row of a base query that was
                    // just probed non-empty, so this check would compare two empty
                    // result sets. Drop the shape rather than the check.
                    originalContext = createEGraphCoverageContext(null, targetTables, EGraphCoverageShape.PLAIN);
                    variantContext = originalContext;
                    result = rewriteQuery;
                }
                EGraphSqlCoverage.recordCheck();
                EGraphSqlCoverage.analyzeWhere(rewriteQuery);
                EGraphCoverageContext finalVariantContext = variantContext;
                return new EGraphMetamorphicOracle.GeneratedQuery(result, rewriteQuery,
                        variant -> wrapEGraphCoverageShape(variant, finalVariantContext), "RANDOM_GENERATED_1_3");
            };
            return new EGraphMetamorphicOracle<>(globalState, queryGenerator, errors,
                    new RustEGraphVariantGenerator(globalState.getOptions().getEGraphUrl(),
                            globalState.getOptions().getEGraphMaxVariants(),
                            globalState.getOptions().getEGraphTimeoutMillis()));
        }

    },
    NoREC {
        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws SQLException {
            SQLite3ExpressionGenerator gen = new SQLite3ExpressionGenerator(globalState);
            ExpectedErrors errors = ExpectedErrors.newErrors().with(SQLite3Errors.getExpectedExpressionErrors())
                    .with(SQLite3Errors.getMatchQueryErrors()).with(SQLite3Errors.getQueryErrors())
                    .with("misuse of aggregate", "misuse of window function",
                            "second argument to nth_value must be a positive integer", "no such table",
                            "no query solution", "unable to use function MATCH in the requested context")
                    .build();
            return new NoRECOracle<>(globalState, gen, errors);
        }
    },
    AGGREGATE {
        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws SQLException {
            return new SQLite3TLPAggregateOracle(globalState);
        }

    },
    WHERE {
        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws SQLException {
            SQLite3ExpressionGenerator gen = new SQLite3ExpressionGenerator(globalState);
            ExpectedErrors expectedErrors = ExpectedErrors.newErrors().with(SQLite3Errors.getExpectedExpressionErrors())
                    .build();
            return new TLPWhereOracle<>(globalState, gen, expectedErrors);
        }

    },
    DISTINCT {
        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws SQLException {
            return new SQLite3TLPDistinctOracle(globalState);
        }
    },
    GROUP_BY {
        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws SQLException {
            return new SQLite3TLPGroupByOracle(globalState);
        }
    },
    HAVING {
        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws SQLException {
            return new SQLite3TLPHavingOracle(globalState);
        }
    },
    FUZZER {
        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws SQLException {
            return new SQLite3Fuzzer(globalState);
        }
    },
    QUERY_PARTITIONING {
        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws Exception {
            List<TestOracle<SQLite3GlobalState>> oracles = new ArrayList<>();
            oracles.add(WHERE.create(globalState));
            oracles.add(DISTINCT.create(globalState));
            oracles.add(GROUP_BY.create(globalState));
            oracles.add(HAVING.create(globalState));
            oracles.add(AGGREGATE.create(globalState));
            return new CompositeTestOracle<SQLite3GlobalState>(oracles, globalState);
        }
    },
    CODDTest {
        @Override
        public TestOracle<SQLite3GlobalState> create(SQLite3GlobalState globalState) throws SQLException {
            return new SQLite3CODDTestOracle(globalState);
        }

        @Override
        public boolean requiresAllTablesToContainRows() {
            return true;
        }
    };

    private enum EGraphCoverageShape {
        PLAIN,
        DISTINCT,
        GROUP_BY,
        DERIVED_TABLE,
        COMPOUND_UNION_ALL,
        CORRELATED_SUBQUERY,
        MATERIALIZED_CTE,
        NOT_MATERIALIZED_CTE,
        AUTOMATIC_INDEX,
        CO_ROUTINE,
        MULTI_INDEX_OR,
        LIMIT_OFFSET,
        WHERE_CASE_TRUE,
        WHERE_FUNCTION_TRUE,
        WHERE_COLLATE_TRUE,
        SCALAR_SUBQUERY,
        WINDOW_COUNT,
        VALUES_CTE_JOIN,
        RECURSIVE_CTE,
        FTS5_MATCH_CONTEXT,
        RTREE_CONTEXT,
        RTREE_DEEP_CONTEXT,
        DBSTAT_CONTEXT,
        VIEW_TRIGGER_FK_CONTEXT,
        ANALYZE_INDEX_CONTEXT,
        JSON_CONTEXT,
        TX_WAL_VACUUM_CONTEXT,
        AUTO_VACUUM_INTEGRITY_CONTEXT,
        ATTACH_VACUUM_WAL_CONTEXT,
        ALTER_INDEX_ANALYZE_CONTEXT,
        SELECT_WHERE_STRESS_CONTEXT,
        EXPR_STRESS_CONTEXT,
        WINDOW_STRESS_CONTEXT,
        RESOLVE_STRESS_CONTEXT,
        SORTER_STRESS_CONTEXT,
        JOIN_OPTIMIZER_CONTEXT,
        ALTER_FK_STRESS_CONTEXT,
        INTEGRITY_CHECK_CONTEXT,
        SCALAR_AGGREGATE_CONTEXT,
        VIRTUAL_TABLE_UPDATE_CONTEXT,
        FTS5_SECURE_DELETE_CONTEXT,
        FTS5_DEEP_CONTEXT,
        VIRTUAL_TABLE_SAVEPOINT_CONTEXT,
        JSONB_STRESS_CONTEXT,
        XFER_OPTIMIZATION_CONTEXT,
        MULTI_SELECT_ORDER_BY_CONTEXT,
        // The three shapes below aggregate the inner result instead of appending a
        // constant-true EXISTS filter, so the value they compute lands in the
        // result set and a wrong value becomes a mismatch the oracle reports.

        ROW_VALUE_CONTEXT,
        AGGREGATE_ORDER_BY_CONTEXT,
        WINDOW_RANGE_FULLSCAN_CONTEXT,
        // Function batteries. Every value lands in the result set, so a wrong
        // result from any of these built-ins is a mismatch. All inputs are fixed
        // literals: 'now', random() and last_insert_rowid() would differ between
        // the original and the variant execution and fake a bug.
        SCALAR_FUNCTION_BATTERY_CONTEXT,
        DATE_MODIFIER_BATTERY_CONTEXT,
        WINDOW_FUNCTION_BATTERY_CONTEXT,
        FTS4_MATCH_CONTEXT,
        FTS4_AUX_CONTEXT,
        BLOOM_FILTER_CONTEXT,
        MULTI_INDEX_OR_ROWSET_CONTEXT,
        INDEX_FUNCTION_VALUE_CONTEXT,
        SORTER_DEEP_MERGE_CONTEXT,
        FTS5_DEEP_QUERY_CONTEXT,
        FTS5_AUX_DEEP_CONTEXT,
        FTS4_DEEP_SEGMENT_CONTEXT,
        FTS5_VARIANT_CONFIG_CONTEXT,
        PRAGMA_VTAB_CONTEXT,
        FTS4_MERGE_LCS_CONTEXT,
        FTS3_TOKENIZE_TABLE_CONTEXT,
        FTS5_TOMBSTONE_CONTEXT,
        FTS5_TOKENIZER_VARIANT_CONTEXT,
        SQL_SYNTAX_BATTERY_CONTEXT,
        // Built-ins that the SQLancer expression generator never emits, so their
        // implementations had never been entered: unistrFunc and the percentile
        // extension. Same battery rules as above - fixed literals only.
        COLD_FUNCTION_BATTERY_CONTEXT,
        // INSTEAD OF triggers and ALTER TABLE ... DROP CONSTRAINT. Both are DDL,
        // so they can only live in the setup; the wrapper just reads the probe.
        COLD_DDL_TRIGGER_CONTEXT
    }

    private enum EGraphBaseQueryShape {
        PLAIN,
        COLUMN_PROJECTION,
        DISTINCT_COLUMNS,
        ORDER_BY_COLUMN,
        LIMIT_10,
        ORDER_BY_COLUMN_LIMIT_10
    }

    private static final AtomicInteger TX_CONTEXT_COUNT = new AtomicInteger();
    private static final AtomicInteger ATTACH_CONTEXT_COUNT = new AtomicInteger();
    private static final AtomicInteger INTEGRITY_CONTEXT_COUNT = new AtomicInteger();
    private static final AtomicInteger AUTO_VACUUM_INTEGRITY_CONTEXT_COUNT = new AtomicInteger();
    private static final boolean EGRAPH_BASE_SKELETONS = Boolean
            .parseBoolean(System.getProperty("sqlite3.egraph.baseSkeletons", "true"));
    private static final boolean EGRAPH_SELECT_ONLY_TEMPLATES = Boolean
            .parseBoolean(System.getProperty("sqlite3.egraph.corpus.selectOnlyTemplates", "true"));
    private static final boolean REPLAY_CORPUS_CASE_SETUP = Boolean
            .parseBoolean(System.getProperty("sqlite3.egraph.corpus.replayCaseSetup", "true"));
    private static final int MAX_CORPUS_ATTEMPTS_PER_CHECK = Integer
            .getInteger("sqlite3.egraph.corpus.maxAttemptsPerCheck", 2);
    private static final Set<String> BAD_CORPUS_INPUTS = ConcurrentHashMap.newKeySet();
    /**
     * Diagnostic switch: only run corpus cases that bring their own setup, i.e. replay the corpus CREATE/INSERT
     * verbatim. With -Dsqlite3.egraph.corpusSetupOnly=true everything that would instead run against data SQLancer
     * produced on its own is refused - the random-generation path entirely, and corpus cases without setup
     * statements. Used to measure how much of the workload survives on corpus-provided data alone.
     */
    private static final boolean CORPUS_SETUP_ONLY = Boolean.getBoolean("sqlite3.egraph.corpusSetupOnly");

    private static final boolean RTREE_TARGETS = !"false"
            .equalsIgnoreCase(System.getProperty("egraph.rtreeTargets", "true"));

    /**
     * Per table: -1 when it is not backed by the rtree module, otherwise how many coordinate columns
     * it declares - everything between the id column and the first auxiliary ("+name") column. Read
     * from sqlite_master rather than guessed from the name, because SQLancer's "rt0" convention is
     * not something this oracle should depend on. Cached per name so the lookup does not repeat on
     * every check.
     */
    private static final Map<String, Integer> RTREE_TABLE_CACHE = new ConcurrentHashMap<>();

    private static boolean isRtreeTable(SQLite3GlobalState state, SQLite3Table table) {
        return rtreeCoordinateColumns(state, table) >= 0;
    }

    /**
     * Coordinate columns of an R-Tree table, or -1 if the table is not one. Only these columns can
     * carry a constraint the module consumes, so this is what {@link #generateRtreePushdownWhere}
     * builds its terms from.
     */
    private static int rtreeCoordinateColumns(SQLite3GlobalState state, SQLite3Table table) {
        if (!RTREE_TARGETS || table == null || !table.isVirtual()) {
            return -1;
        }
        Integer cached = RTREE_TABLE_CACHE.get(table.getName());
        if (cached != null) {
            return cached;
        }
        int coordinates = -1;
        try {
            SQLQueryAdapter q = new SQLQueryAdapter(
                    "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '" + table.getName() + "'");
            try (SQLancerResultSet rs = q.executeAndGet(state)) {
                if (rs != null && rs.next()) {
                    String sql = rs.getString(1);
                    if (sql != null) {
                        String normalized = sql.toLowerCase(java.util.Locale.ROOT);
                        // rtree or rtree_i32; no other module name contains it
                        if (normalized.contains("rtree")) {
                            coordinates = countRtreeCoordinateColumns(sql, table.getColumns().size());
                        }
                    }
                }
            }
        } catch (Exception ignored) {
            coordinates = -1;
        }
        RTREE_TABLE_CACHE.put(table.getName(), coordinates);
        return coordinates;
    }

    /**
     * Counts the coordinate columns in a {@code CREATE VIRTUAL TABLE ... USING rtree(...)}: the
     * module arguments after the id column, up to the first auxiliary one. Getting this wrong is not
     * dangerous - a constraint on an auxiliary column is simply not consumed and stays a post-filter
     * - so the parse is deliberately simple and clamps to what the schema actually has.
     */
    private static int countRtreeCoordinateColumns(String createStatement, int nrSchemaColumns) {
        int open = createStatement.indexOf('(');
        int close = createStatement.lastIndexOf(')');
        if (open < 0 || close < open) {
            return 0;
        }
        String[] args = createStatement.substring(open + 1, close).split(",");
        int coordinates = 0;
        for (int i = 1; i < args.length; i++) {   // argument 0 is the id column
            if (args[i].trim().startsWith("+")) {
                break;
            }
            coordinates++;
        }
        coordinates = Math.max(0, Math.min(coordinates, nrSchemaColumns - 1));
        return coordinates - coordinates % 2;   // coordinates always come in (min, max) pairs
    }

    // Percentage of R-Tree-targeted base queries whose WHERE is assembled from push-down-eligible
    // constraint terms instead of being taken from the free-form expression generator. 0 restores
    // the previous behaviour; the remainder still goes through the random generator, which keeps
    // the predicate shapes the rule set is normally exercised on in the mix.
    private static final int RTREE_PUSHDOWN_PERCENT = Integer
            .parseInt(System.getProperty("egraph.rtreePushdownPercent", "80"));

    /**
     * Percentage of non-virtual base queries whose WHERE is built as {@code indexedColumn <op>
     * constant}, with an index guaranteed on that column.
     *
     * <p>
     * The point is not the comparison itself but what the rewrite rules can then do with it:
     * {@code allowedOp} (sqlite3.c) only index-matches TK_EQ..TK_GE, so a term the rules wrap in
     * NOT - which is exactly what gt-to-not-lteq and its five siblings produce - stops being
     * index-usable and compiles to a full scan while the original compiles to an index seek. That is
     * a strategy-level difference on a plain table, where the rest of the rule set only manages to
     * reorder the same opcodes. Measured by hand: {@code c1 > 1} gives SEARCH USING INDEX, and
     * {@code NOT (c1 <= 1)} gives SCAN, both returning the same 28 rows.
     * </p>
     *
     * <p>
     * 0 restores the previous always-random behaviour. Left at 0 until an A/B says otherwise.
     * </p>
     */
    private static final int INDEXED_PREDICATE_PERCENT = Integer
            .parseInt(System.getProperty("egraph.indexedPredicatePercent", "0"));

    /** A column with an index on it plus a constant taken from that column, so the term matches rows. */
    private static final class IndexedPredicate {
        private final SQLite3Column column;
        private final SQLite3Constant constant;

        IndexedPredicate(SQLite3Column column, SQLite3Constant constant) {
            this.column = column;
            this.constant = constant;
        }
    }

    /**
     * Creates the index and samples the constant, or returns null when this table has nothing
     * usable - no named column, or no row holding an integer, real or text value. Callers fall back
     * to the random predicate path, which is also what keeps the in-run control arm populated.
     */
    private static IndexedPredicate prepareIndexedPredicate(SQLite3GlobalState state, SQLite3Table table) {
        if (state == null || table == null || table.isVirtual() || !hasUsableIdentifier(table.getName())) {
            return null;
        }
        List<SQLite3Column> candidates = table.getColumns().stream()
                .filter(SQLite3OracleFactory::hasUsableIdentifier)
                .collect(java.util.stream.Collectors.toList());
        if (candidates.isEmpty()) {
            return null;
        }
        SQLite3Column column = Randomly.fromList(candidates);
        String indexName = quoteIdentifier(
                "egraph_ixp_" + sanitizeIdentifierPart(table.getName()) + "_" + sanitizeIdentifierPart(column.getName()));
        // IF NOT EXISTS, so this is a no-op after the first check that picks this column. A column
        // that cannot be indexed (a generated column in some SQLite builds) fails here and the
        // sampled constant would still produce a full scan on both sides, so give up instead.
        if (!executeContextStatement(state, "CREATE INDEX IF NOT EXISTS " + indexName + " ON "
                + quoteIdentifier(table.getName()) + "(" + quoteIdentifier(column.getName()) + ")", true)) {
            return null;
        }
        SQLite3Constant constant = sampleColumnConstant(state, table, column);
        return constant == null ? null : new IndexedPredicate(column, constant);
    }

    /**
     * Reads one value out of the column so the comparison is satisfiable by construction. Blobs and
     * NULLs are filtered out in SQL rather than here: a blob literal has to round-trip through
     * x'..' to stay a blob, and a NULL comparison is rejected by EGraphPredicateFilter anyway.
     */
    private static SQLite3Constant sampleColumnConstant(SQLite3GlobalState state, SQLite3Table table,
            SQLite3Column column) {
        String columnName = quoteIdentifier(column.getName());
        String sql = "SELECT typeof(" + columnName + "), " + columnName + " FROM "
                + quoteIdentifier(table.getName()) + " WHERE typeof(" + columnName
                + ") IN ('integer', 'real', 'text') ORDER BY random() LIMIT 1";
        try (SQLancerResultSet rs = new SQLQueryAdapter(sql, false).executeAndGet(state, false)) {
            if (rs == null || !rs.next()) {
                return null;
            }
            String type = rs.getString(1);
            String value = rs.getString(2);
            if (type == null || value == null) {
                return null;
            }
            switch (type) {
            case "integer":
                return SQLite3Constant.createIntConstant(Long.parseLong(value));
            case "real":
                return SQLite3Constant.createRealConstant(Double.parseDouble(value));
            default:
                return SQLite3Constant.createTextConstant(value);
            }
        } catch (Exception ignored) {
            return null;
        }
    }

    /**
     * Builds {@code column <op> constant}. Deliberately plain: the NOT wrapping that costs the term
     * its index usability is what the rule set produces on its own, so the base query has to hand it
     * a term that is index-usable to begin with.
     */
    private static SQLite3Expression generateIndexedConstantWhere(IndexedPredicate prepared,
            SQLite3ExpressionGenerator gen) {
        SQLite3Expression columnRef = new SQLite3ColumnName(prepared.column, null);
        BinaryComparisonOperator operator = Randomly.fromOptions(BinaryComparisonOperator.EQUALS,
                BinaryComparisonOperator.NOT_EQUALS, BinaryComparisonOperator.SMALLER,
                BinaryComparisonOperator.SMALLER_EQUALS, BinaryComparisonOperator.GREATER,
                BinaryComparisonOperator.GREATER_EQUALS);
        SQLite3Expression predicate = new BinaryComparisonOperation(columnRef, prepared.constant, operator);
        if (Randomly.getBooleanWithRatherLowProbability()) {
            // Two terms on the same column: the optimiser then has to pick which one drives the
            // index seek and which stays a post-filter, and the rules can move that boundary.
            predicate = new Sqlite3BinaryOperation(predicate,
                    new BinaryComparisonOperation(new SQLite3ColumnName(prepared.column, null), prepared.constant,
                            Randomly.fromOptions(BinaryComparisonOperator.SMALLER_EQUALS,
                                    BinaryComparisonOperator.GREATER_EQUALS,
                                    BinaryComparisonOperator.NOT_EQUALS)),
                    BinaryOperator.AND);
        }
        if (Randomly.getBooleanWithRatherLowProbability()) {
            // A term the index cannot serve, so "index seek plus post-filter" stays in the mix.
            predicate = new Sqlite3BinaryOperation(predicate, gen.generateBooleanExpression(), BinaryOperator.AND);
        }
        return predicate;
    }

    // Bound for the "constraint that matches everything" terms. Kept below 1e7 so Double.toString
    // does not switch to exponent notation, which the rewrite server's parser has no need to see.
    private static final double RTREE_WIDE_BOUND = 1000000.0;

    /**
     * Builds a WHERE clause over an R-Tree table's coordinate columns that the module can actually
     * consume.
     *
     * <p>
     * The module only takes terms of the form {@code coordinateColumn <op> constant} that sit
     * directly in the top-level AND/OR structure; anything else stays a post-filter over a full
     * scan. The free-form generator practically never emits that shape - it builds arbitrary
     * arithmetic trees and column-vs-column comparisons - which is why R-Tree targets produced a
     * single plan for 94% of their checks while regular tables managed more than one for 17%. With
     * constraint terms the rewrites become visible: the same predicate compiles to a full scan, a
     * one-constraint scan, a two-constraint scan in either order, or a MULTI-INDEX OR over two
     * separate R-Tree scans, and all of them have to return the same rows.
     * </p>
     */
    private static SQLite3Expression generateRtreePushdownWhere(SQLite3Table table, int coordinateColumns,
            SQLite3ExpressionGenerator gen) {
        List<SQLite3Column> columns = table.getColumns();
        int nrPairs = coordinateColumns / 2;
        int pair = (int) Randomly.getNotCachedInteger(0, nrPairs);
        double pivot = rtreePivot();
        SQLite3Expression predicate;
        switch ((int) Randomly.getNotCachedInteger(0, nrPairs >= 2 ? 6 : 5)) {
            case 0: {
                // Point containment - the canonical R-Tree query, and the shape that produced six
                // distinct plans across its rewrites when this was measured by hand.
                predicate = rtreeAnd(
                        rtreeConstraint(columns, pair, false, pivot, BinaryComparisonOperator.SMALLER_EQUALS),
                        rtreeConstraint(columns, pair, true, pivot, BinaryComparisonOperator.GREATER_EQUALS));
                break;
            }
            case 1: {
                // Interval overlap: the same two constraints, but with a different bound on each.
                double lower = pivot - Randomly.getNotCachedInteger(1, 9);
                double upper = pivot + Randomly.getNotCachedInteger(1, 9);
                predicate = rtreeAnd(
                        rtreeConstraint(columns, pair, false, upper, BinaryComparisonOperator.SMALLER_EQUALS),
                        rtreeConstraint(columns, pair, true, lower, BinaryComparisonOperator.GREATER_EQUALS));
                break;
            }
            case 2: {
                // Strict bounds. RTREE_LT and RTREE_GT are separate opcodes from RTREE_LE/RTREE_GE
                // in the module's constraint program, and the rewrite rules move between them.
                predicate = rtreeAnd(rtreeConstraint(columns, pair, false, pivot, BinaryComparisonOperator.SMALLER),
                        rtreeConstraint(columns, pair, true, pivot, BinaryComparisonOperator.GREATER));
                break;
            }
            case 3: {
                // A single constraint, leaving the other coordinate to the post-filter.
                predicate = Randomly.getBoolean()
                        ? rtreeConstraint(columns, pair, false, pivot, BinaryComparisonOperator.SMALLER_EQUALS)
                        : rtreeConstraint(columns, pair, true, pivot, BinaryComparisonOperator.GREATER_EQUALS);
                break;
            }
            case 4: {
                // Wide open: true for any row, so the check does not depend on where the data
                // happens to sit, while the module still has two constraints to consume.
                predicate = rtreeAnd(
                        rtreeConstraint(columns, pair, false, RTREE_WIDE_BOUND,
                                BinaryComparisonOperator.SMALLER_EQUALS),
                        rtreeConstraint(columns, pair, true, -RTREE_WIDE_BOUND,
                                BinaryComparisonOperator.GREATER_EQUALS));
                break;
            }
            default: {
                // Two pairs at once - four terms, which is where the order the module receives them
                // in starts to matter.
                int other = (pair + 1) % nrPairs;
                predicate = rtreeAnd(
                        rtreeAnd(rtreeConstraint(columns, pair, false, pivot,
                                BinaryComparisonOperator.SMALLER_EQUALS),
                                rtreeConstraint(columns, pair, true, pivot,
                                        BinaryComparisonOperator.GREATER_EQUALS)),
                        rtreeAnd(rtreeConstraint(columns, other, false, RTREE_WIDE_BOUND,
                                BinaryComparisonOperator.SMALLER_EQUALS),
                                rtreeConstraint(columns, other, true, -RTREE_WIDE_BOUND,
                                        BinaryComparisonOperator.GREATER_EQUALS)));
                break;
            }
        }
        // An OR of two constraint lists is what SQLite turns into MULTI-INDEX OR: two independent
        // R-Tree scans feeding a rowset merge, which a single AND chain never reaches.
        if (Randomly.getBooleanWithRatherLowProbability()) {
            double second = rtreePivot();
            predicate = rtreeOr(predicate,
                    rtreeAnd(rtreeConstraint(columns, pair, false, second, BinaryComparisonOperator.SMALLER_EQUALS),
                            rtreeConstraint(columns, pair, true, second, BinaryComparisonOperator.GREATER_EQUALS)));
        }
        // A term the module cannot consume keeps the "constraint plus post-filter" path in the mix,
        // and keeps some of the generator's own shapes in the R-Tree workload.
        if (Randomly.getBooleanWithRatherLowProbability()) {
            predicate = rtreeAnd(predicate, gen.generateBooleanExpression());
        }
        return predicate;
    }

    /**
     * A value to constrain against. {@code SQLite3Provider#seedRtreeTable} fills the EGRAPH R-Tree
     * with intervals inside [-20, 24], so pivots in that band keep containment queries non-empty on
     * the one table the oracle can count on; the occasional far-out value exercises the path where
     * the module consumes a constraint that then matches nothing.
     */
    private static double rtreePivot() {
        if (Randomly.getBooleanWithSmallProbability()) {
            return Randomly.getNotCachedInteger(-1000, 1001);
        }
        double base = Randomly.getNotCachedInteger(-20, 25);
        return Randomly.getBoolean() ? base : base + 0.5;
    }

    /** Column {@code 1 + 2 * pair} is a pair's minimum, the one after it its maximum. */
    private static SQLite3Expression rtreeCoordinate(List<SQLite3Column> columns, int pair, boolean upperBound) {
        return new SQLite3ColumnName(columns.get(1 + 2 * pair + (upperBound ? 1 : 0)), null);
    }

    private static SQLite3Expression rtreeConstraint(List<SQLite3Column> columns, int pair, boolean upperBound,
            double value, BinaryComparisonOperator operator) {
        return new BinaryComparisonOperation(rtreeCoordinate(columns, pair, upperBound), rtreeLiteral(value),
                operator);
    }

    /**
     * Integer and real spellings of the same bound reach the module through different affinity
     * handling, and rtree_i32 stores what rtree keeps as a float, so both are worth emitting.
     */
    private static SQLite3Expression rtreeLiteral(double value) {
        if (value == Math.rint(value) && Randomly.getBoolean()) {
            return SQLite3Constant.createIntConstant((long) value);
        }
        return SQLite3Constant.createRealConstant(value);
    }

    private static SQLite3Expression rtreeAnd(SQLite3Expression left, SQLite3Expression right) {
        return new Sqlite3BinaryOperation(left, right, BinaryOperator.AND);
    }

    private static SQLite3Expression rtreeOr(SQLite3Expression left, SQLite3Expression right) {
        return new Sqlite3BinaryOperation(left, right, BinaryOperator.OR);
    }

    // Percentage of empty-probe base queries that are checked anyway instead of discarded. 0 restores
    // the previous always-discard behaviour. Default is a small sample so the single-side-empty
    // judgment starts producing data without materially moving throughput.
    private static final int EMPTY_BASE_CHECK_PERCENT = Integer
            .getInteger("egraph.emptyBaseCheckPercent", 10);

    private static final boolean AUTO_RESEARCH_GUIDED_SHAPES = Boolean
            .parseBoolean(System.getProperty("sqlite3.egraph.autoResearchGuidedShapes", "true"));
    private static final String AUTO_RESEARCH_RESULTS = System.getProperty("sqlite3.egraph.autoResearchResults",
            "D:\\sqlancer\\coverage\\sqlite\\auto-research-from-long-20260818-130511\\auto-research-results.csv");
    private static final List<EGraphCoverageShape> AUTO_RESEARCH_SHAPES = loadAutoResearchShapes();

    private static EGraphCoverageShape chooseEGraphCoverageShape() {
        EGraphCoverageShape autoShape = chooseAutoResearchShape();
        if (autoShape != null && Randomly.fromOptions(true, true, false)) {
            return autoShape;
        }
        return Randomly.fromOptions(EGraphCoverageShape.PLAIN, EGraphCoverageShape.PLAIN, EGraphCoverageShape.PLAIN,
                EGraphCoverageShape.DISTINCT, EGraphCoverageShape.GROUP_BY, EGraphCoverageShape.DERIVED_TABLE,
                EGraphCoverageShape.COMPOUND_UNION_ALL, EGraphCoverageShape.CORRELATED_SUBQUERY,
                EGraphCoverageShape.MATERIALIZED_CTE, EGraphCoverageShape.AUTOMATIC_INDEX,
                EGraphCoverageShape.CO_ROUTINE, EGraphCoverageShape.MULTI_INDEX_OR,
                EGraphCoverageShape.NOT_MATERIALIZED_CTE, EGraphCoverageShape.LIMIT_OFFSET,
                EGraphCoverageShape.WHERE_CASE_TRUE, EGraphCoverageShape.WHERE_FUNCTION_TRUE,
                EGraphCoverageShape.WHERE_COLLATE_TRUE, EGraphCoverageShape.SCALAR_SUBQUERY,
                EGraphCoverageShape.WINDOW_COUNT, EGraphCoverageShape.VALUES_CTE_JOIN,
                EGraphCoverageShape.RECURSIVE_CTE, EGraphCoverageShape.FTS5_MATCH_CONTEXT,
                EGraphCoverageShape.FTS5_DEEP_CONTEXT,
                EGraphCoverageShape.RTREE_CONTEXT, EGraphCoverageShape.RTREE_DEEP_CONTEXT,
                EGraphCoverageShape.DBSTAT_CONTEXT,
                EGraphCoverageShape.VIEW_TRIGGER_FK_CONTEXT, EGraphCoverageShape.ANALYZE_INDEX_CONTEXT,
                EGraphCoverageShape.JSON_CONTEXT, EGraphCoverageShape.TX_WAL_VACUUM_CONTEXT,
                EGraphCoverageShape.AUTO_VACUUM_INTEGRITY_CONTEXT,
                EGraphCoverageShape.ATTACH_VACUUM_WAL_CONTEXT,
                EGraphCoverageShape.ALTER_INDEX_ANALYZE_CONTEXT, EGraphCoverageShape.SELECT_WHERE_STRESS_CONTEXT,
                EGraphCoverageShape.EXPR_STRESS_CONTEXT, EGraphCoverageShape.WINDOW_STRESS_CONTEXT,
                EGraphCoverageShape.RESOLVE_STRESS_CONTEXT, EGraphCoverageShape.SORTER_STRESS_CONTEXT,
                EGraphCoverageShape.JOIN_OPTIMIZER_CONTEXT, EGraphCoverageShape.ALTER_FK_STRESS_CONTEXT,
                EGraphCoverageShape.INTEGRITY_CHECK_CONTEXT, EGraphCoverageShape.SCALAR_AGGREGATE_CONTEXT,
                EGraphCoverageShape.VIRTUAL_TABLE_UPDATE_CONTEXT,
                EGraphCoverageShape.FTS5_SECURE_DELETE_CONTEXT,
                EGraphCoverageShape.VIRTUAL_TABLE_SAVEPOINT_CONTEXT, EGraphCoverageShape.JSONB_STRESS_CONTEXT,
                EGraphCoverageShape.XFER_OPTIMIZATION_CONTEXT, EGraphCoverageShape.MULTI_SELECT_ORDER_BY_CONTEXT,
                EGraphCoverageShape.ROW_VALUE_CONTEXT, EGraphCoverageShape.AGGREGATE_ORDER_BY_CONTEXT,
                EGraphCoverageShape.WINDOW_RANGE_FULLSCAN_CONTEXT,
                EGraphCoverageShape.SCALAR_FUNCTION_BATTERY_CONTEXT,
                EGraphCoverageShape.DATE_MODIFIER_BATTERY_CONTEXT,
                EGraphCoverageShape.WINDOW_FUNCTION_BATTERY_CONTEXT,
                EGraphCoverageShape.FTS4_MATCH_CONTEXT, EGraphCoverageShape.FTS4_AUX_CONTEXT,
                EGraphCoverageShape.BLOOM_FILTER_CONTEXT, EGraphCoverageShape.MULTI_INDEX_OR_ROWSET_CONTEXT,
                EGraphCoverageShape.INDEX_FUNCTION_VALUE_CONTEXT,
                EGraphCoverageShape.SORTER_DEEP_MERGE_CONTEXT,
                EGraphCoverageShape.FTS5_DEEP_QUERY_CONTEXT, EGraphCoverageShape.FTS5_AUX_DEEP_CONTEXT,
                EGraphCoverageShape.FTS4_DEEP_SEGMENT_CONTEXT,
                EGraphCoverageShape.FTS5_VARIANT_CONFIG_CONTEXT, EGraphCoverageShape.PRAGMA_VTAB_CONTEXT,
                EGraphCoverageShape.FTS4_MERGE_LCS_CONTEXT, EGraphCoverageShape.FTS3_TOKENIZE_TABLE_CONTEXT,
                EGraphCoverageShape.FTS5_TOMBSTONE_CONTEXT,
                EGraphCoverageShape.FTS5_TOKENIZER_VARIANT_CONTEXT,
                EGraphCoverageShape.SQL_SYNTAX_BATTERY_CONTEXT,
                EGraphCoverageShape.COLD_FUNCTION_BATTERY_CONTEXT,
                EGraphCoverageShape.COLD_DDL_TRIGGER_CONTEXT);
    }

    private static EGraphCoverageShape chooseAutoResearchShape() {
        if (!AUTO_RESEARCH_GUIDED_SHAPES || AUTO_RESEARCH_SHAPES.isEmpty()) {
            return null;
        }
        return Randomly.fromList(AUTO_RESEARCH_SHAPES);
    }

    private static List<EGraphCoverageShape> loadAutoResearchShapes() {
        List<EGraphCoverageShape> shapes = new ArrayList<>();
        Path path = Path.of(AUTO_RESEARCH_RESULTS);
        if (!Files.isRegularFile(path)) {
            return shapes;
        }
        try {
            List<String> lines = Files.readAllLines(path, StandardCharsets.UTF_8);
            int rank = 0;
            for (String line : lines) {
                if (line.startsWith("\"Name\"") || line.isBlank()) {
                    continue;
                }
                String name = readFirstCsvColumn(line);
                List<EGraphCoverageShape> mapped = mapAutoResearchCaseToShapes(name);
                if (mapped.isEmpty()) {
                    continue;
                }
                int weight = Math.max(1, 6 - rank);
                for (int i = 0; i < weight; i++) {
                    shapes.addAll(mapped);
                }
                rank++;
                if (rank >= 8) {
                    break;
                }
            }
        } catch (IOException ignored) {
            return new ArrayList<>();
        }
        return shapes;
    }

    private static String readFirstCsvColumn(String line) {
        if (line.startsWith("\"")) {
            StringBuilder result = new StringBuilder();
            for (int i = 1; i < line.length(); i++) {
                char c = line.charAt(i);
                if (c == '"' && i + 1 < line.length() && line.charAt(i + 1) == '"') {
                    result.append('"');
                    i++;
                } else if (c == '"') {
                    return result.toString();
                } else {
                    result.append(c);
                }
            }
        }
        int comma = line.indexOf(',');
        return comma >= 0 ? line.substring(0, comma).trim() : line.trim();
    }

    private static List<EGraphCoverageShape> mapAutoResearchCaseToShapes(String name) {
        switch (name) {
            case "alter_index_analyze":
                return List.of(EGraphCoverageShape.ALTER_INDEX_ANALYZE_CONTEXT,
                        EGraphCoverageShape.ANALYZE_INDEX_CONTEXT, EGraphCoverageShape.AUTOMATIC_INDEX,
                        EGraphCoverageShape.MULTI_INDEX_OR, EGraphCoverageShape.SQL_SYNTAX_BATTERY_CONTEXT);
            case "json_table_valued":
                return List.of(EGraphCoverageShape.JSON_CONTEXT, EGraphCoverageShape.JSONB_STRESS_CONTEXT,
                        EGraphCoverageShape.EXPR_STRESS_CONTEXT);
            case "jsonb_stress":
                return List.of(EGraphCoverageShape.JSONB_STRESS_CONTEXT, EGraphCoverageShape.JSON_CONTEXT,
                        EGraphCoverageShape.EXPR_STRESS_CONTEXT);
            case "recursive_window_aggregate":
                return List.of(EGraphCoverageShape.RECURSIVE_CTE, EGraphCoverageShape.WINDOW_STRESS_CONTEXT,
                        EGraphCoverageShape.WINDOW_COUNT, EGraphCoverageShape.GROUP_BY);
            case "dbstat_storage":
                return List.of(EGraphCoverageShape.DBSTAT_CONTEXT, EGraphCoverageShape.ANALYZE_INDEX_CONTEXT);
            case "trigger_view_fk":
                return List.of(EGraphCoverageShape.VIEW_TRIGGER_FK_CONTEXT, EGraphCoverageShape.RESOLVE_STRESS_CONTEXT);
            case "returning_upsert":
                // UPSERT and RETURNING are grammar forms, not data shapes.
                return List.of(EGraphCoverageShape.SQL_SYNTAX_BATTERY_CONTEXT,
                        EGraphCoverageShape.ALTER_INDEX_ANALYZE_CONTEXT,
                        EGraphCoverageShape.SELECT_WHERE_STRESS_CONTEXT);
            case "fts5":
                return List.of(EGraphCoverageShape.FTS5_DEEP_CONTEXT, EGraphCoverageShape.FTS5_MATCH_CONTEXT,
                        EGraphCoverageShape.FTS5_TOMBSTONE_CONTEXT,
                        EGraphCoverageShape.FTS5_TOKENIZER_VARIANT_CONTEXT);
            case "fts5_secure_vocab":
                return List.of(EGraphCoverageShape.FTS5_DEEP_CONTEXT, EGraphCoverageShape.FTS5_SECURE_DELETE_CONTEXT,
                        EGraphCoverageShape.FTS5_MATCH_CONTEXT, EGraphCoverageShape.FTS5_TOMBSTONE_CONTEXT);
            case "rtree":
                return List.of(EGraphCoverageShape.RTREE_DEEP_CONTEXT, EGraphCoverageShape.RTREE_CONTEXT);
            case "tx_wal_vacuum":
                return List.of(EGraphCoverageShape.AUTO_VACUUM_INTEGRITY_CONTEXT,
                        EGraphCoverageShape.TX_WAL_VACUUM_CONTEXT);
            case "attach_vacuum_wal":
                return List.of(EGraphCoverageShape.ATTACH_VACUUM_WAL_CONTEXT,
                        EGraphCoverageShape.TX_WAL_VACUUM_CONTEXT);
            case "xfer_optimization":
                return List.of(EGraphCoverageShape.XFER_OPTIMIZATION_CONTEXT);
            case "multi_select_order_by":
                return List.of(EGraphCoverageShape.MULTI_SELECT_ORDER_BY_CONTEXT,
                        EGraphCoverageShape.COMPOUND_UNION_ALL);
            case "join_optimizer":
                return List.of(EGraphCoverageShape.JOIN_OPTIMIZER_CONTEXT,
                        EGraphCoverageShape.SELECT_WHERE_STRESS_CONTEXT, EGraphCoverageShape.MULTI_INDEX_OR);
            case "alter_fk_stress":
                return List.of(EGraphCoverageShape.ALTER_FK_STRESS_CONTEXT,
                        EGraphCoverageShape.VIEW_TRIGGER_FK_CONTEXT, EGraphCoverageShape.ALTER_INDEX_ANALYZE_CONTEXT);
            case "integrity_check_stress":
                return List.of(EGraphCoverageShape.AUTO_VACUUM_INTEGRITY_CONTEXT,
                        EGraphCoverageShape.INTEGRITY_CHECK_CONTEXT,
                        EGraphCoverageShape.TX_WAL_VACUUM_CONTEXT, EGraphCoverageShape.DBSTAT_CONTEXT);
            case "scalar_aggregate_stress":
                return List.of(EGraphCoverageShape.SCALAR_AGGREGATE_CONTEXT, EGraphCoverageShape.EXPR_STRESS_CONTEXT);
            case "virtual_table_update_stress":
                return List.of(EGraphCoverageShape.VIRTUAL_TABLE_SAVEPOINT_CONTEXT,
                        EGraphCoverageShape.VIRTUAL_TABLE_UPDATE_CONTEXT, EGraphCoverageShape.RTREE_DEEP_CONTEXT,
                        EGraphCoverageShape.RTREE_CONTEXT, EGraphCoverageShape.FTS5_DEEP_CONTEXT,
                        EGraphCoverageShape.FTS5_SECURE_DELETE_CONTEXT);
            default:
                return List.of();
        }
    }

    private static EGraphMetamorphicOracle.GeneratedQuery createCorpusGeneratedQuery(SQLite3GlobalState state,
            List<CorpusQueryInput> corpusInputs) throws Exception {
        List<CorpusQueryInput> candidates = new ArrayList<>(corpusInputs);
        int attempts = Math.min(Math.max(1, MAX_CORPUS_ATTEMPTS_PER_CHECK), candidates.size());
        while (!candidates.isEmpty() && attempts > 0) {
            CorpusQueryInput candidate = Randomly.fromList(candidates);
            candidates.remove(candidate);
            String inputKey = getCorpusInputKey(candidate);
            if (BAD_CORPUS_INPUTS.contains(inputKey)) {
                continue;
            }
            try {
                EGraphSqlCoverage.trace("corpus-candidate start source=" + getCorpusSourceName(candidate)
                        + " setupStatements=" + candidate.getSetupStatements().size() + " query="
                        + shortenForTrace(candidate.getQuery()));
                return createSingleCorpusGeneratedQuery(state, candidate);
            } catch (IgnoreMeException e) {
                EGraphSqlCoverage.trace("corpus-candidate rejected source=" + getCorpusSourceName(candidate)
                        + " query=" + shortenForTrace(candidate.getQuery()));
                BAD_CORPUS_INPUTS.add(inputKey);
                try {
                    resetCorpusSchema(state);
                } catch (Exception ignored) {
                }
                attempts--;
            }
        }
        throw new IgnoreMeException();
    }

    private static EGraphMetamorphicOracle.GeneratedQuery createSingleCorpusGeneratedQuery(SQLite3GlobalState state,
            CorpusQueryInput selectedInput) throws Exception {
        boolean replayedCorpusSetup = false;
        if (selectedInput.hasSetupStatements() && REPLAY_CORPUS_CASE_SETUP) {
            EGraphSqlCoverage.trace("corpus-setup start source=" + getCorpusSourceName(selectedInput)
                    + " statements=" + selectedInput.getSetupStatements().size());
            if (!replayCorpusSetupForQuery(state, selectedInput)) {
                EGraphSqlCoverage.trace("corpus-setup failed source=" + getCorpusSourceName(selectedInput));
                throw new IgnoreMeException();
            }
            EGraphSqlCoverage.trace("corpus-setup done source=" + getCorpusSourceName(selectedInput));
            replayedCorpusSetup = true;
        }
        String rewriteQuery = selectedInput.getQuery();
        if (rewriteQuery == null || rewriteQuery.isBlank()) {
            throw new IgnoreMeException();
        }
        if (!replayedCorpusSetup && CORPUS_SETUP_ONLY) {
            EGraphSqlCoverage.trace("corpus-setup-only skip source=" + getCorpusSourceName(selectedInput)
                    + " reason=no-setup-statements");
            throw new IgnoreMeException();
        }
        if (!replayedCorpusSetup) {
            SQLite3Provider.ensureEGraphRandomDatabase(state);
        }
        List<SQLite3Table> tables = state.getSchema().getDatabaseTables().stream()
                .filter(t -> !t.isView() && !t.isVirtual() && !t.getColumns().isEmpty()
                        && t.getNrRows(state) > 0)
                .collect(java.util.stream.Collectors.toList());
        if (tables.isEmpty()) {
            throw new IgnoreMeException();
        }
        SQLite3Table chosen = Randomly.fromList(tables);
        AbstractTables<SQLite3Table, SQLite3Column> targetTables = new AbstractTables<>(
                java.util.Collections.singletonList(chosen));
        if (!replayedCorpusSetup) {
            if (EGRAPH_SELECT_ONLY_TEMPLATES) {
                rewriteQuery = mapSelectOnlyCorpusQuery(rewriteQuery, targetTables);
            }
        }
        EGraphSqlCoverage.trace("corpus-base-nonempty-probe start source=" + getCorpusSourceName(selectedInput)
                + " query=" + shortenForTrace(rewriteQuery));
        if (!queryProducesRows(state, rewriteQuery)) {
            EGraphSqlCoverage.trace("corpus-base-nonempty-probe empty source=" + getCorpusSourceName(selectedInput)
                    + " query=" + shortenForTrace(rewriteQuery));
            throw new IgnoreMeException();
        }
        EGraphSqlCoverage.trace("corpus-base-nonempty-probe done source=" + getCorpusSourceName(selectedInput));
        EGraphCoverageContext originalContext = createEGraphCoverageContext(state, targetTables,
                chooseEGraphCorpusExecutionCoverageShape());
        String originalQuery = wrapEGraphCoverageShape(rewriteQuery, originalContext);
        EGraphSqlCoverage.trace("corpus-wrapper-nonempty-probe start source=" + getCorpusSourceName(selectedInput)
                + " query=" + shortenForTrace(originalQuery));
        if (!queryProducesRows(state, originalQuery)) {
            originalContext = createEGraphCoverageContext(null, targetTables, EGraphCoverageShape.PLAIN);
            originalQuery = rewriteQuery;
            EGraphSqlCoverage.trace("corpus-wrapper-nonempty-probe fallback-plain source="
                    + getCorpusSourceName(selectedInput));
        } else {
            EGraphSqlCoverage.trace("corpus-wrapper-nonempty-probe done source=" + getCorpusSourceName(selectedInput));
        }
        EGraphSqlCoverage.recordWrapperShape(replayedCorpusSetup ? "CORPUS_INPUT" : "CORPUS_SELECT_TEMPLATE");
        EGraphSqlCoverage.recordCheck();
        EGraphSqlCoverage.analyzeWhere(rewriteQuery);
        EGraphCoverageContext finalOriginalContext = originalContext;
        String querySource = replayedCorpusSetup ? getCorpusSourceName(selectedInput)
                : getNoSetupCorpusSourceName(selectedInput);
        return new EGraphMetamorphicOracle.GeneratedQuery(originalQuery, rewriteQuery,
                variant -> wrapEGraphCoverageShape(variant, finalOriginalContext),
                querySource);
    }

    private static EGraphBaseQuery buildEGraphBaseQuery(SQLite3Select select, SQLite3Expression whereCondition,
            AbstractTables<SQLite3Table, SQLite3Column> targetTables, boolean rowOrderMustNotMatter) {
        List<SQLite3Column> columns = targetTables.getColumns().stream()
                .filter(SQLite3OracleFactory::hasUsableIdentifier)
                .collect(java.util.stream.Collectors.toList());
        EGraphBaseQueryShape shape = chooseEGraphBaseQueryShape(columns, rowOrderMustNotMatter);
        resetEGraphBaseQuery(select, whereCondition);
        switch (shape) {
            case COLUMN_PROJECTION:
                select.setFetchColumns(columnProjection(columns));
                break;
            case DISTINCT_COLUMNS:
                select.setFromOptions(SQLite3Select.SelectType.DISTINCT);
                select.setFetchColumns(columnProjection(columns));
                break;
            case ORDER_BY_COLUMN:
                select.setOrderByClauses(orderByColumn(columns));
                break;
            case LIMIT_10:
                select.setLimitClause(SQLite3Constant.createIntConstant(10));
                break;
            case ORDER_BY_COLUMN_LIMIT_10:
                select.setOrderByClauses(orderByColumn(columns));
                select.setLimitClause(SQLite3Constant.createIntConstant(10));
                break;
            case PLAIN:
                break;
            default:
                throw new AssertionError(shape);
        }
        return new EGraphBaseQuery(select.asString(), "BASE_" + shape.name());
    }

    private static void resetEGraphBaseQuery(SQLite3Select select, SQLite3Expression whereCondition) {
        select.setFromOptions(SQLite3Select.SelectType.ALL);
        select.setFetchColumns(Arrays.asList(SQLite3ColumnName.createDummy("*")));
        select.setWhereClause(whereCondition);
        select.setGroupByClause(List.of());
        select.setHavingClause(null);
        select.setOrderByClauses(List.of());
        select.setLimitClause(null);
        select.setOffsetClause(null);
    }

    private static EGraphBaseQueryShape chooseEGraphBaseQueryShape(List<SQLite3Column> columns,
            boolean rowOrderMustNotMatter) {
        if (!EGRAPH_BASE_SKELETONS || columns.isEmpty()) {
            return EGraphBaseQueryShape.PLAIN;
        }
        if (rowOrderMustNotMatter) {
            // The three shapes whose result is a set: no LIMIT to pick different rows with, and no
            // ORDER BY to switch the comparison to order-sensitive.
            return Randomly.fromOptions(EGraphBaseQueryShape.PLAIN, EGraphBaseQueryShape.PLAIN,
                    EGraphBaseQueryShape.COLUMN_PROJECTION, EGraphBaseQueryShape.DISTINCT_COLUMNS);
        }
        return Randomly.fromOptions(EGraphBaseQueryShape.PLAIN, EGraphBaseQueryShape.PLAIN,
                EGraphBaseQueryShape.COLUMN_PROJECTION, EGraphBaseQueryShape.DISTINCT_COLUMNS,
                EGraphBaseQueryShape.ORDER_BY_COLUMN, EGraphBaseQueryShape.LIMIT_10,
                EGraphBaseQueryShape.ORDER_BY_COLUMN_LIMIT_10);
    }

    private static List<SQLite3Expression> columnProjection(List<SQLite3Column> columns) {
        if (columns.isEmpty()) {
            return Arrays.asList(SQLite3ColumnName.createDummy("*"));
        }
        List<SQLite3Column> selected = new ArrayList<>(Randomly.nonEmptySubset(columns));
        if (selected.size() > 3) {
            selected = new ArrayList<>(selected.subList(0, 3));
        }
        return selected.stream().map(c -> new SQLite3ColumnName(c, null))
                .collect(java.util.stream.Collectors.toList());
    }

    private static List<SQLite3Expression> orderByColumn(List<SQLite3Column> columns) {
        if (columns.isEmpty()) {
            return List.of();
        }
        Ordering ordering = Randomly.fromOptions(Ordering.ASC, Ordering.DESC);
        SQLite3Column column = Randomly.fromList(columns);
        return Arrays.asList(new SQLite3OrderingTerm(new SQLite3ColumnName(column, null), ordering));
    }

    private static String mapSelectOnlyCorpusQuery(String query,
            AbstractTables<SQLite3Table, SQLite3Column> targetTables) {
        String stripped = stripTrailingSemicolon(query);
        int fromIdx = findTopLevelKeyword(stripped, "FROM", 0);
        int whereIdx = fromIdx < 0 ? -1 : findTopLevelKeyword(stripped, "WHERE", fromIdx + 4);
        if (fromIdx < 0 || whereIdx < 0 || whereIdx <= fromIdx) {
            throw new IgnoreMeException();
        }
        SQLite3Table targetTable = targetTables.getTables().get(0);
        List<SQLite3Column> targetColumns = targetTables.getColumns().stream()
                .filter(SQLite3OracleFactory::hasUsableIdentifier)
                .collect(java.util.stream.Collectors.toList());
        if (targetColumns.isEmpty() || !hasUsableIdentifier(targetTable.getName())) {
            throw new IgnoreMeException();
        }
        SelectOnlyFrom from = parseSelectOnlyFrom(stripped.substring(fromIdx + 4, whereIdx).trim());
        if (from == null) {
            throw new IgnoreMeException();
        }
        SelectOnlyMapper mapper = new SelectOnlyMapper(targetColumns);
        Set<String> sourceQualifiers = new HashSet<>();
        sourceQualifiers.add(normalizeIdentifier(from.tableName));
        if (from.alias != null && !from.alias.isBlank()) {
            sourceQualifiers.add(normalizeIdentifier(from.alias));
        }
        String targetTableName = quoteIdentifier(targetTable.getName());
        String projection = rewriteSelectOnlyIdentifiers(stripped.substring(0, fromIdx), mapper, sourceQualifiers,
                targetTableName);
        String suffix = rewriteSelectOnlyIdentifiers(stripped.substring(whereIdx), mapper, sourceQualifiers,
                targetTableName);
        String mapped = projection + "FROM " + targetTableName + " " + suffix;
        if (mapper.mappedColumnCount() == 0) {
            throw new IgnoreMeException();
        }
        return mapped;
    }

    private static SelectOnlyFrom parseSelectOnlyFrom(String fromClause) {
        if (fromClause == null || fromClause.isBlank() || fromClause.contains(",")
                || fromClause.contains("(") || fromClause.contains(")")) {
            return null;
        }
        String normalized = fromClause.toUpperCase(Locale.ROOT);
        if (normalized.contains(" JOIN ") || normalized.contains(" INDEXED ") || normalized.contains(" NOT INDEXED ")) {
            return null;
        }
        String[] parts = fromClause.trim().split("\\s+");
        if (parts.length == 1) {
            return new SelectOnlyFrom(unquoteIdentifier(parts[0]), null);
        }
        if (parts.length == 2) {
            return new SelectOnlyFrom(unquoteIdentifier(parts[0]), unquoteIdentifier(parts[1]));
        }
        if (parts.length == 3 && "AS".equalsIgnoreCase(parts[1])) {
            return new SelectOnlyFrom(unquoteIdentifier(parts[0]), unquoteIdentifier(parts[2]));
        }
        return null;
    }

    private static int findTopLevelKeyword(String sql, String keyword, int start) {
        int depth = 0;
        boolean inSingle = false;
        boolean inDouble = false;
        for (int i = Math.max(0, start); i <= sql.length() - keyword.length(); i++) {
            char ch = sql.charAt(i);
            if (inSingle) {
                if (ch == '\'') {
                    if (i + 1 < sql.length() && sql.charAt(i + 1) == '\'') {
                        i++;
                    } else {
                        inSingle = false;
                    }
                }
                continue;
            }
            if (inDouble) {
                if (ch == '"') {
                    if (i + 1 < sql.length() && sql.charAt(i + 1) == '"') {
                        i++;
                    } else {
                        inDouble = false;
                    }
                }
                continue;
            }
            if (ch == '\'') {
                inSingle = true;
                continue;
            }
            if (ch == '"') {
                inDouble = true;
                continue;
            }
            if (ch == '(') {
                depth++;
                continue;
            }
            if (ch == ')') {
                if (depth > 0) {
                    depth--;
                }
                continue;
            }
            if (depth == 0 && sql.regionMatches(true, i, keyword, 0, keyword.length())) {
                boolean beforeOk = i == 0 || !isIdentifierPart(sql.charAt(i - 1));
                int after = i + keyword.length();
                boolean afterOk = after >= sql.length() || !isIdentifierPart(sql.charAt(after));
                if (beforeOk && afterOk) {
                    return i;
                }
            }
        }
        return -1;
    }

    private static String rewriteSelectOnlyIdentifiers(String sql, SelectOnlyMapper mapper, Set<String> sourceQualifiers,
            String targetTableName) {
        StringBuilder out = new StringBuilder(sql.length() + 32);
        boolean inSingle = false;
        boolean inDouble = false;
        for (int i = 0; i < sql.length();) {
            char ch = sql.charAt(i);
            if (inSingle) {
                out.append(ch);
                if (ch == '\'') {
                    if (i + 1 < sql.length() && sql.charAt(i + 1) == '\'') {
                        out.append(sql.charAt(i + 1));
                        i += 2;
                        continue;
                    }
                    inSingle = false;
                }
                i++;
                continue;
            }
            if (inDouble) {
                out.append(ch);
                if (ch == '"') {
                    if (i + 1 < sql.length() && sql.charAt(i + 1) == '"') {
                        out.append(sql.charAt(i + 1));
                        i += 2;
                        continue;
                    }
                    inDouble = false;
                }
                i++;
                continue;
            }
            if (ch == '\'') {
                inSingle = true;
                out.append(ch);
                i++;
                continue;
            }
            if (ch == '"') {
                inDouble = true;
                out.append(ch);
                i++;
                continue;
            }
            if (!isIdentifierStart(ch)) {
                out.append(ch);
                i++;
                continue;
            }
            int start = i;
            i++;
            while (i < sql.length() && isIdentifierPart(sql.charAt(i))) {
                i++;
            }
            String token = sql.substring(start, i);
            if (isBlobLiteralPrefix(sql, token, i)) {
                out.append(token);
                continue;
            }
            int next = skipWhitespace(sql, i);
            String normalized = normalizeIdentifier(token);
            if (next < sql.length() && sql.charAt(next) == '.' && sourceQualifiers.contains(normalized)) {
                out.append(targetTableName);
                continue;
            }
            if (isSqlKeywordOrFunction(token, next < sql.length() ? sql.charAt(next) : '\0')
                    || sourceQualifiers.contains(normalized)) {
                out.append(token);
                continue;
            }
            out.append(mapper.map(token));
        }
        return out.toString();
    }

    private static boolean isBlobLiteralPrefix(String sql, String token, int nextIndex) {
        return token.length() == 1 && ("x".equals(token) || "X".equals(token))
                && nextIndex < sql.length() && sql.charAt(nextIndex) == '\'';
    }

    private static int skipWhitespace(String sql, int index) {
        int i = index;
        while (i < sql.length() && Character.isWhitespace(sql.charAt(i))) {
            i++;
        }
        return i;
    }

    private static boolean isIdentifierStart(char ch) {
        return Character.isLetter(ch) || ch == '_';
    }

    private static boolean isIdentifierPart(char ch) {
        return Character.isLetterOrDigit(ch) || ch == '_' || ch == '$';
    }

    private static String normalizeIdentifier(String identifier) {
        return unquoteIdentifier(identifier).toUpperCase(Locale.ROOT);
    }

    private static String unquoteIdentifier(String identifier) {
        String result = identifier == null ? "" : identifier.trim();
        if (result.length() >= 2) {
            char first = result.charAt(0);
            char last = result.charAt(result.length() - 1);
            if ((first == '"' && last == '"') || (first == '`' && last == '`') || (first == '[' && last == ']')) {
                return result.substring(1, result.length() - 1);
            }
        }
        return result;
    }

    private static boolean isSqlKeywordOrFunction(String token, char nextNonWhitespace) {
        String upper = token.toUpperCase(Locale.ROOT);
        if (SQL_TEMPLATE_KEYWORDS.contains(upper)) {
            return true;
        }
        return nextNonWhitespace == '(' && SQL_TEMPLATE_FUNCTIONS.contains(upper);
    }

    private static final Set<String> SQL_TEMPLATE_KEYWORDS = Set.of("SELECT", "ALL", "DISTINCT", "FROM", "WHERE",
            "ORDER", "BY", "LIMIT", "OFFSET", "ASC", "DESC", "NULL", "TRUE", "FALSE", "IS", "NOT", "AND", "OR",
            "BETWEEN", "LIKE", "GLOB", "ESCAPE", "IN", "EXISTS", "CASE", "WHEN", "THEN", "ELSE", "END", "AS",
            "COLLATE", "BINARY", "NOCASE", "RTRIM", "CAST", "ROWID", "OID", "_ROWID_");

    private static final Set<String> SQL_TEMPLATE_FUNCTIONS = Set.of("ABS", "COALESCE", "GLOB", "IFNULL", "INSTR",
            "LENGTH", "LIKE", "LIKELIHOOD", "LIKELY", "LOWER", "LTRIM", "MAX", "MIN", "NULLIF", "PRINTF", "QUOTE",
            "ROUND", "RTRIM", "SOUNDEX", "SUBSTR", "SUM", "COUNT", "TOTAL", "AVG", "TYPEOF", "UNICODE", "UNLIKELY",
            "UPPER", "DATE", "TIME", "DATETIME", "JULIANDAY", "STRFTIME", "JSON", "JSON_ARRAY",
            "JSON_ARRAY_LENGTH", "JSON_EXTRACT", "JSON_INSERT", "JSON_OBJECT", "JSON_PATCH", "JSON_REMOVE",
            "JSON_TYPE", "JSON_VALID", "JSON_QUOTE", "BASE64", "BASE85");

    private static String getCorpusInputKey(CorpusQueryInput input) {
        return input.getSourceName() + "\n" + input.getQuery();
    }

    private static String getCorpusSourceName(CorpusQueryInput input) {
        String sourceName = input.getSourceName();
        if (sourceName == null) {
            return "CORPUS_REPLAY_SETUP";
        }
        String normalized = sourceName.replace('\\', '/').toLowerCase(java.util.Locale.ROOT);
        if (normalized.endsWith("high-coverage-egraph-corpus.sql")) {
            return "CORPUS_HIGH_COVERAGE";
        }
        if (normalized.endsWith("sqlite-official-test-corpus.sql")
                || normalized.endsWith("sqlite-official-egraph-filtered-corpus.sql")) {
            return "CORPUS_OFFICIAL";
        }
        if (normalized.endsWith("sqlite-official-select-only-corpus.sql")
                || normalized.endsWith("sqlite-official-select-only-variant-ready-corpus.sql")) {
            return "CORPUS_OFFICIAL_SELECT_TEMPLATE";
        }
        if (normalized.endsWith("auto-research-filtered-corpus.sql")) {
            return "CORPUS_AUTO_RESEARCH";
        }
        return "CORPUS_REPLAY_SETUP";
    }

    private static String getNoSetupCorpusSourceName(CorpusQueryInput input) {
        String sourceName = getCorpusSourceName(input);
        if ("CORPUS_OFFICIAL_SELECT_TEMPLATE".equals(sourceName) || "CORPUS_AUTO_RESEARCH".equals(sourceName)
                || "CORPUS_HIGH_COVERAGE".equals(sourceName)) {
            return sourceName;
        }
        return "CORPUS_RANDOM_SCHEMA";
    }

    /**
     * Outcome of the non-empty probe. A failing statement used to be indistinguishable from an empty result, which made
     * "the wrapper filtered every row" and "the wrapper does not even run" look identical in the statistics.
     */
    private enum ProbeOutcome {
        ROWS, EMPTY, ERROR,
        /**
         * SQLQueryAdapter swallows errors that are on the expected-error list and returns a null result set instead of
         * throwing. Counting that as an empty result made wrappers look like they filtered every row when in fact the
         * statement never ran.
         */
        EXPECTED_ERROR
    }

    private static ProbeOutcome probeQuery(SQLite3GlobalState state, String queryString) {
        if (state == null || queryString == null || queryString.isBlank()) {
            return ProbeOutcome.ERROR;
        }
        EGraphSqlCoverage.trace("queryProducesRows start sql=" + shortenForTrace(queryString));
        String probe = "SELECT 1 FROM (" + stripTrailingSemicolon(queryString) + ") AS egraph_non_empty_probe LIMIT 1";
        try (SQLancerResultSet rs = new SQLQueryAdapter(probe, false).executeAndGet(state, false)) {
            if (rs == null) {
                EGraphSqlCoverage.trace("queryProducesRows expected-error sql=" + shortenForTrace(queryString));
                return ProbeOutcome.EXPECTED_ERROR;
            }
            boolean hasRows = rs.next();
            EGraphSqlCoverage.trace("queryProducesRows done rows=" + hasRows + " sql=" + shortenForTrace(queryString));
            return hasRows ? ProbeOutcome.ROWS : ProbeOutcome.EMPTY;
        } catch (Exception e) {
            EGraphSqlCoverage.trace("queryProducesRows exception sql=" + shortenForTrace(queryString));
            EGraphSqlCoverage.recordProbeError(e.getMessage(), queryString);
            return ProbeOutcome.ERROR;
        }
    }

    private static boolean queryProducesRows(SQLite3GlobalState state, String queryString) {
        return probeQuery(state, queryString) == ProbeOutcome.ROWS;
    }

    private static String shortenForTrace(String sql) {
        if (sql == null) {
            return "<null>";
        }
        String normalized = sql.strip().replaceAll("\\s+", " ");
        if (normalized.length() > 180) {
            return normalized.substring(0, 177) + "...";
        }
        return normalized;
    }

    private static String stripTrailingSemicolon(String queryString) {
        String result = queryString.trim();
        while (result.endsWith(";")) {
            result = result.substring(0, result.length() - 1).trim();
        }
        return result;
    }

    private static boolean replayCorpusSetupForQuery(SQLite3GlobalState state, CorpusQueryInput input) {
        try {
            resetCorpusSchema(state);
        } catch (Exception ignored) {
        }
        boolean executedSetupStatement = false;
        boolean schemaChanged = false;
        for (String statement : input.getSetupStatements()) {
            try {
                SQLQueryAdapter query = new SQLQueryAdapter(statement, corpusStatementCouldAffectSchema(statement));
                if (query.execute(state, false)) {
                    executedSetupStatement = true;
                    logExecutedContextStatement(state, query);
                    schemaChanged |= query.couldAffectSchema();
                }
            } catch (AssertionError ignored) {
            } catch (RuntimeException ignored) {
            } catch (Exception ignored) {
            }
        }
        try {
            if (schemaChanged) {
                state.updateSchema();
            }
        } catch (AssertionError ignored) {
            return false;
        } catch (RuntimeException ignored) {
            return false;
        } catch (Exception ignored) {
            return false;
        }
        return executedSetupStatement && !state.getSchema().getDatabaseTables().isEmpty();
    }

    private static void resetCorpusSchema(SQLite3GlobalState state) throws Exception {
        try {
            state.updateSchema();
        } catch (AssertionError ignored) {
            return;
        }
        List<SQLite3Table> tables = new ArrayList<>(state.getSchema().getDatabaseTables());
        for (SQLite3Table table : tables) {
            if (table.isView()) {
                executeContextStatement(state, "DROP VIEW IF EXISTS " + quoteIdentifier(table.getName()), true);
            }
        }
        for (SQLite3Table table : tables) {
            if (!table.isView()) {
                executeContextStatement(state, "DROP TABLE IF EXISTS " + quoteIdentifier(table.getName()), true);
            }
        }
        state.updateSchema();
    }

    private static boolean corpusStatementCouldAffectSchema(String statement) {
        String normalized = statement.stripLeading().toUpperCase(java.util.Locale.ROOT);
        return normalized.matches("(?s)^(CREATE|DROP|ALTER)\\b.*")
                || normalized.matches("(?s).*\\b(CREATE|DROP|ALTER)\\s+(TABLE|INDEX|VIEW|TRIGGER|VIRTUAL)\\b.*");
    }

    private static EGraphCoverageShape chooseEGraphCorpusExecutionCoverageShape() {
        EGraphCoverageShape autoShape = chooseAutoResearchShape();
        if (autoShape != null && Randomly.fromOptions(true, true, false)) {
            return autoShape;
        }
        return Randomly.fromOptions(EGraphCoverageShape.PLAIN, EGraphCoverageShape.PLAIN,
                EGraphCoverageShape.DERIVED_TABLE, EGraphCoverageShape.DISTINCT,
                EGraphCoverageShape.COMPOUND_UNION_ALL, EGraphCoverageShape.MATERIALIZED_CTE,
                EGraphCoverageShape.NOT_MATERIALIZED_CTE, EGraphCoverageShape.CO_ROUTINE,
                EGraphCoverageShape.LIMIT_OFFSET, EGraphCoverageShape.WHERE_CASE_TRUE,
                EGraphCoverageShape.WHERE_FUNCTION_TRUE, EGraphCoverageShape.WHERE_COLLATE_TRUE,
                EGraphCoverageShape.SCALAR_SUBQUERY, EGraphCoverageShape.WINDOW_COUNT,
                EGraphCoverageShape.VALUES_CTE_JOIN, EGraphCoverageShape.RECURSIVE_CTE,
                EGraphCoverageShape.FTS5_MATCH_CONTEXT, EGraphCoverageShape.FTS5_DEEP_CONTEXT,
                EGraphCoverageShape.RTREE_CONTEXT, EGraphCoverageShape.RTREE_DEEP_CONTEXT,
                EGraphCoverageShape.DBSTAT_CONTEXT, EGraphCoverageShape.VIEW_TRIGGER_FK_CONTEXT,
                EGraphCoverageShape.ANALYZE_INDEX_CONTEXT, EGraphCoverageShape.JSON_CONTEXT,
                EGraphCoverageShape.TX_WAL_VACUUM_CONTEXT, EGraphCoverageShape.AUTO_VACUUM_INTEGRITY_CONTEXT,
                EGraphCoverageShape.ATTACH_VACUUM_WAL_CONTEXT,
                EGraphCoverageShape.ALTER_INDEX_ANALYZE_CONTEXT,
                EGraphCoverageShape.SELECT_WHERE_STRESS_CONTEXT, EGraphCoverageShape.EXPR_STRESS_CONTEXT,
                EGraphCoverageShape.WINDOW_STRESS_CONTEXT, EGraphCoverageShape.RESOLVE_STRESS_CONTEXT,
                EGraphCoverageShape.SORTER_STRESS_CONTEXT, EGraphCoverageShape.JOIN_OPTIMIZER_CONTEXT,
                EGraphCoverageShape.ALTER_FK_STRESS_CONTEXT, EGraphCoverageShape.FTS5_SECURE_DELETE_CONTEXT,
                EGraphCoverageShape.INTEGRITY_CHECK_CONTEXT, EGraphCoverageShape.SCALAR_AGGREGATE_CONTEXT,
                EGraphCoverageShape.VIRTUAL_TABLE_UPDATE_CONTEXT,
                EGraphCoverageShape.VIRTUAL_TABLE_SAVEPOINT_CONTEXT, EGraphCoverageShape.JSONB_STRESS_CONTEXT,
                EGraphCoverageShape.XFER_OPTIMIZATION_CONTEXT,
                EGraphCoverageShape.MULTI_SELECT_ORDER_BY_CONTEXT, EGraphCoverageShape.ROW_VALUE_CONTEXT,
                EGraphCoverageShape.AGGREGATE_ORDER_BY_CONTEXT,
                EGraphCoverageShape.WINDOW_RANGE_FULLSCAN_CONTEXT,
                EGraphCoverageShape.SCALAR_FUNCTION_BATTERY_CONTEXT,
                EGraphCoverageShape.DATE_MODIFIER_BATTERY_CONTEXT,
                EGraphCoverageShape.WINDOW_FUNCTION_BATTERY_CONTEXT,
                EGraphCoverageShape.FTS4_MATCH_CONTEXT, EGraphCoverageShape.FTS4_AUX_CONTEXT,
                EGraphCoverageShape.BLOOM_FILTER_CONTEXT, EGraphCoverageShape.MULTI_INDEX_OR_ROWSET_CONTEXT,
                EGraphCoverageShape.INDEX_FUNCTION_VALUE_CONTEXT,
                EGraphCoverageShape.SORTER_DEEP_MERGE_CONTEXT,
                EGraphCoverageShape.FTS5_DEEP_QUERY_CONTEXT, EGraphCoverageShape.FTS5_AUX_DEEP_CONTEXT,
                EGraphCoverageShape.FTS4_DEEP_SEGMENT_CONTEXT,
                EGraphCoverageShape.FTS5_VARIANT_CONFIG_CONTEXT, EGraphCoverageShape.PRAGMA_VTAB_CONTEXT,
                EGraphCoverageShape.FTS4_MERGE_LCS_CONTEXT, EGraphCoverageShape.FTS3_TOKENIZE_TABLE_CONTEXT,
                EGraphCoverageShape.FTS5_TOMBSTONE_CONTEXT,
                EGraphCoverageShape.FTS5_TOKENIZER_VARIANT_CONTEXT,
                EGraphCoverageShape.SQL_SYNTAX_BATTERY_CONTEXT,
                EGraphCoverageShape.COLD_FUNCTION_BATTERY_CONTEXT,
                EGraphCoverageShape.COLD_DDL_TRIGGER_CONTEXT);
    }

    private static EGraphCoverageShape chooseEGraphExecutionCoverageShape(EGraphCoverageShape inputShape) {
        if (inputShape != EGraphCoverageShape.PLAIN && Randomly.fromOptions(true, true, false)) {
            return EGraphCoverageShape.PLAIN;
        }
        return chooseEGraphCoverageShape();
    }

    private static EGraphCoverageContext createEGraphCoverageContext(SQLite3GlobalState state,
            AbstractTables<SQLite3Table, SQLite3Column> targetTables, EGraphCoverageShape requestedShape)
            throws Exception {
        EGraphCoverageShape shape = requestedShape;
        SQLite3Table table = targetTables.getTables().get(0);
        List<SQLite3Column> columns = targetTables.getColumns().stream()
                .filter(SQLite3OracleFactory::hasUsableIdentifier)
                .collect(java.util.stream.Collectors.toList());
        if (columns.isEmpty() || !hasUsableIdentifier(table.getName())) {
            return new EGraphCoverageContext(EGraphCoverageShape.PLAIN, quoteIdentifier(table.getName()), null, null,
                    null, null);
        }
        SQLite3Column column = Randomly.fromList(columns);
        SQLite3Column secondColumn = columns.size() > 1 ? columns.get(1) : column;
        if ((shape == EGraphCoverageShape.MULTI_INDEX_OR || shape == EGraphCoverageShape.AUTOMATIC_INDEX)
                && columns.size() < 2) {
            shape = EGraphCoverageShape.PLAIN;
        }
        if (shape == EGraphCoverageShape.MULTI_INDEX_OR) {
            addMultiIndexOrIndexes(state, table, column, secondColumn);
        } else if (state != null && !prepareHighCoverageContext(state, table, columns, column, shape)) {
            shape = EGraphCoverageShape.PLAIN;
        }
        String groupByColumns = columns.stream().map(c -> quoteIdentifier(c.getName()))
                .collect(java.util.stream.Collectors.joining(", "));
        return new EGraphCoverageContext(shape, quoteIdentifier(table.getName()), quoteIdentifier(column.getName()),
                quoteIdentifier(secondColumn.getName()),
                quoteIdentifier(getEGraphContextIndexName(table.getName(), column.getName())),
                groupByColumns);
    }

    private static EGraphCoverageContext createVariantEGraphCoverageContext(EGraphCoverageContext originalContext,
            AbstractTables<SQLite3Table, SQLite3Column> targetTables) throws Exception {
        if (!Randomly.fromOptions(true, false, false)) {
            return originalContext;
        }
        EGraphCoverageShape variantShape = chooseCrossPlanShape(originalContext.shape);
        if (variantShape == originalContext.shape) {
            return originalContext;
        }
        return createEGraphCoverageContext(null, targetTables, variantShape);
    }

    private static EGraphCoverageShape chooseCrossPlanShape(EGraphCoverageShape originalShape) {
        switch (originalShape) {
            case PLAIN:
            case DERIVED_TABLE:
            case MATERIALIZED_CTE:
            case CO_ROUTINE:
            case NOT_MATERIALIZED_CTE:
            case LIMIT_OFFSET:
            case WHERE_CASE_TRUE:
            case WHERE_FUNCTION_TRUE:
            case WHERE_COLLATE_TRUE:
            case VALUES_CTE_JOIN:
            case RECURSIVE_CTE:
                return Randomly.fromOptions(EGraphCoverageShape.PLAIN, EGraphCoverageShape.DERIVED_TABLE,
                        EGraphCoverageShape.MATERIALIZED_CTE, EGraphCoverageShape.CO_ROUTINE,
                        EGraphCoverageShape.NOT_MATERIALIZED_CTE, EGraphCoverageShape.LIMIT_OFFSET,
                        EGraphCoverageShape.WHERE_CASE_TRUE, EGraphCoverageShape.WHERE_FUNCTION_TRUE,
                        EGraphCoverageShape.WHERE_COLLATE_TRUE, EGraphCoverageShape.VALUES_CTE_JOIN,
                        EGraphCoverageShape.RECURSIVE_CTE);
            case DISTINCT:
                return EGraphCoverageShape.GROUP_BY;
            case GROUP_BY:
                return EGraphCoverageShape.DISTINCT;
            case COMPOUND_UNION_ALL:
            case CORRELATED_SUBQUERY:
            case AUTOMATIC_INDEX:
            case MULTI_INDEX_OR:
            case SCALAR_SUBQUERY:
            case WINDOW_COUNT:
            case FTS5_MATCH_CONTEXT:
            case FTS5_DEEP_CONTEXT:
            case RTREE_CONTEXT:
            case RTREE_DEEP_CONTEXT:
            case DBSTAT_CONTEXT:
            case VIEW_TRIGGER_FK_CONTEXT:
            case ANALYZE_INDEX_CONTEXT:
            case JSON_CONTEXT:
            case TX_WAL_VACUUM_CONTEXT:
            case AUTO_VACUUM_INTEGRITY_CONTEXT:
            case ATTACH_VACUUM_WAL_CONTEXT:
            case ALTER_INDEX_ANALYZE_CONTEXT:
            case SELECT_WHERE_STRESS_CONTEXT:
            case EXPR_STRESS_CONTEXT:
            case WINDOW_STRESS_CONTEXT:
            case RESOLVE_STRESS_CONTEXT:
            case SORTER_STRESS_CONTEXT:
            case JOIN_OPTIMIZER_CONTEXT:
            case ALTER_FK_STRESS_CONTEXT:
            case INTEGRITY_CHECK_CONTEXT:
            case SCALAR_AGGREGATE_CONTEXT:
            case VIRTUAL_TABLE_UPDATE_CONTEXT:
            case FTS5_SECURE_DELETE_CONTEXT:
            case VIRTUAL_TABLE_SAVEPOINT_CONTEXT:
            case JSONB_STRESS_CONTEXT:
            case XFER_OPTIMIZATION_CONTEXT:
            case MULTI_SELECT_ORDER_BY_CONTEXT:
            case ROW_VALUE_CONTEXT:
            case AGGREGATE_ORDER_BY_CONTEXT:
            case WINDOW_RANGE_FULLSCAN_CONTEXT:
            case SCALAR_FUNCTION_BATTERY_CONTEXT:
            case DATE_MODIFIER_BATTERY_CONTEXT:
            case WINDOW_FUNCTION_BATTERY_CONTEXT:
            case FTS4_MATCH_CONTEXT:
            case FTS4_AUX_CONTEXT:
            case BLOOM_FILTER_CONTEXT:
            case MULTI_INDEX_OR_ROWSET_CONTEXT:
            case INDEX_FUNCTION_VALUE_CONTEXT:
            case SORTER_DEEP_MERGE_CONTEXT:
            case FTS5_DEEP_QUERY_CONTEXT:
            case FTS5_AUX_DEEP_CONTEXT:
            case FTS4_DEEP_SEGMENT_CONTEXT:
            case FTS5_VARIANT_CONFIG_CONTEXT:
            case PRAGMA_VTAB_CONTEXT:
            case FTS4_MERGE_LCS_CONTEXT:
            case FTS3_TOKENIZE_TABLE_CONTEXT:
            case FTS5_TOMBSTONE_CONTEXT:
            case FTS5_TOKENIZER_VARIANT_CONTEXT:
            case SQL_SYNTAX_BATTERY_CONTEXT:
            case COLD_FUNCTION_BATTERY_CONTEXT:
            case COLD_DDL_TRIGGER_CONTEXT:
                return originalShape;
            default:
                throw new AssertionError(originalShape);
        }
    }

    private static String wrapEGraphCoverageShape(String query, EGraphCoverageContext context) {
        EGraphCoverageShape shape = context.shape;
        EGraphSqlCoverage.recordWrapperShape(shape.name());
        String columnName = context.columnName;
        String secondColumnName = context.secondColumnName;
        String tableName = context.tableName;
        switch (shape) {
            case DERIVED_TABLE:
                return "SELECT * FROM (" + query + ") AS egraph_sub";
            case DISTINCT:
                return "SELECT DISTINCT * FROM (" + query + ") AS egraph_distinct";
            case GROUP_BY:
                return "SELECT * FROM (" + query + ") AS egraph_group GROUP BY " + context.groupByColumns;
            case COMPOUND_UNION_ALL:
                return "SELECT * FROM (" + query + ") AS egraph_left UNION ALL SELECT * FROM (" + query
                        + ") AS egraph_right";
            case CORRELATED_SUBQUERY:
                return "SELECT * FROM (" + query + ") AS egraph_outer WHERE EXISTS (SELECT 1 FROM " + tableName
                        + " AS egraph_inner WHERE egraph_inner." + columnName + " = egraph_outer." + columnName + ")";
            case MATERIALIZED_CTE:
                return "WITH egraph_mat AS MATERIALIZED (" + query + ") SELECT * FROM egraph_mat";
            case NOT_MATERIALIZED_CTE:
                return "WITH egraph_not_mat AS NOT MATERIALIZED (" + query + ") SELECT * FROM egraph_not_mat";
            case AUTOMATIC_INDEX:
                return "SELECT egraph_outer.* FROM (" + query + ") AS egraph_outer JOIN " + tableName
                        + " AS egraph_auto ON egraph_auto." + columnName + " = egraph_outer." + columnName;
            case CO_ROUTINE:
                // LIMIT -1 has to hang off a SELECT of its own. Appended directly to `query` it
                // collides with the LIMIT the base-query generator already emits, producing
                // "LIMIT 10 LIMIT -1" - a syntax error that aborted the whole check. The extra
                // nesting keeps the intent: a LIMIT on a subquery is what stops the flattener and
                // forces SQLite to run it as a co-routine.
                return "SELECT * FROM (SELECT * FROM (" + query
                        + ") AS egraph_co_inner LIMIT -1) AS egraph_co ORDER BY 1";
            case MULTI_INDEX_OR:
                return "SELECT * FROM (" + query + ") AS egraph_outer WHERE egraph_outer." + columnName
                        + " = 0 OR egraph_outer." + secondColumnName + " = 0";
            case LIMIT_OFFSET:
                return "SELECT * FROM (" + query + ") AS egraph_limit LIMIT -1 OFFSET 0";
            case WHERE_CASE_TRUE:
                return "SELECT * FROM (" + query + ") AS egraph_case WHERE CASE WHEN 1 = 1 THEN 1 ELSE 0 END";
            case WHERE_FUNCTION_TRUE:
                return "SELECT * FROM (" + query
                        + ") AS egraph_func WHERE COALESCE(NULL, 1) = 1 AND TYPEOF(1) = 'integer'";
            case WHERE_COLLATE_TRUE:
                return "SELECT * FROM (" + query + ") AS egraph_collate WHERE 'a' COLLATE BINARY = 'a'";
            case SCALAR_SUBQUERY:
                return "SELECT egraph_scalar.*, (SELECT COUNT(*) FROM " + tableName
                        + ") AS egraph_scalar_count FROM (" + query + ") AS egraph_scalar";
            case WINDOW_COUNT:
                return "SELECT egraph_win.*, COUNT(*) FILTER (WHERE 1) OVER "
                        + "(ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS egraph_window_count FROM ("
                        + query + ") AS egraph_win";
            case VALUES_CTE_JOIN:
                return "WITH egraph_const(egraph_one) AS (VALUES(1)) SELECT egraph_values.* FROM (" + query
                        + ") AS egraph_values JOIN egraph_const ON egraph_const.egraph_one = 1";
            case RECURSIVE_CTE:
                return "WITH RECURSIVE egraph_rec(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM egraph_rec WHERE x < 3), "
                        + "egraph_rec_sum(s) AS (SELECT SUM(x) FILTER (WHERE x > 0) FROM egraph_rec) "
                        + "SELECT egraph_recursive.* FROM (" + query
                        + ") AS egraph_recursive JOIN egraph_rec_sum ON egraph_rec_sum.s >= 1";
            case FTS5_MATCH_CONTEXT:
                return "WITH egraph_fts_rank AS (SELECT rowid, bm25(egraph_fts) AS score, "
                        + "highlight(egraph_fts, 0, '[', ']') AS title_hit, "
                        + "snippet(egraph_fts, 1, '<', '>', '...', 8) AS body_hit "
                        + "FROM egraph_fts WHERE egraph_fts MATCH 'sqlite OR compiler OR variants' "
                        + "ORDER BY rank LIMIT 5) SELECT * FROM (" + query
                        + ") AS egraph_fts_q WHERE EXISTS (SELECT 1 FROM egraph_fts_rank "
                        + "WHERE score IS NOT NULL OR title_hit IS NOT NULL OR body_hit IS NOT NULL)";
            case FTS5_DEEP_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_fts_deep_q WHERE EXISTS (SELECT 1 FROM egraph_fts_deep "
                        + "WHERE egraph_fts_deep MATCH 'sqlite OR prefix OR tokenizer' LIMIT 1)";
            case RTREE_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_rtree_q WHERE EXISTS (SELECT 1 FROM egraph_rtree WHERE x1 <= 6.0 AND x2 >= 6.0 "
                        + "AND y1 <= 6.0 AND y2 >= 6.0)";
            case RTREE_DEEP_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_rtree_deep_q WHERE EXISTS (SELECT 1 FROM egraph_rtree_deep "
                        + "WHERE x1 <= 12.0 AND x2 >= 12.0 AND y1 <= 12.0 AND y2 >= 12.0 LIMIT 1)";
            case DBSTAT_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_dbstat_q WHERE EXISTS (SELECT 1 FROM egraph_dbstat "
                        + "WHERE name IS NOT NULL AND pageno >= 0 LIMIT 1)";
            case VIEW_TRIGGER_FK_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_view_q WHERE EXISTS (SELECT 1 FROM egraph_child_view WHERE value >= 0)";
            case ANALYZE_INDEX_CONTEXT:
                return "SELECT * FROM (" + query + ") AS egraph_idx_q WHERE EXISTS (SELECT 1 FROM " + tableName
                        + " INDEXED BY " + context.indexName + " WHERE " + columnName
                        + " IS NOT NULL OR " + columnName + " IS NULL LIMIT 1)";
            case JSON_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_json_q WHERE json_extract(json_object('ok', 1, 'items', json_array(1, 2, 3)), "
                        + "'$.ok') = 1 AND json_type(json_set('{\"a\":1}', '$.b', json_array(2, 3)), '$.b') = 'array' "
                        + "AND EXISTS (SELECT 1 FROM json_tree('{\"items\":[1,2,3]}') WHERE value = 2)";
            case TX_WAL_VACUUM_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_tx_q WHERE EXISTS (SELECT 1 FROM egraph_tx_probe WHERE value >= 0 LIMIT 1)";
            case AUTO_VACUUM_INTEGRITY_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_autovac_q WHERE EXISTS (SELECT 1 FROM egraph_autovac_probe "
                        + "WHERE k >= 0 LIMIT 1)";
            case ATTACH_VACUUM_WAL_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_attach_q WHERE EXISTS (SELECT 1 FROM egraph_attach_probe "
                        + "WHERE value >= 0 LIMIT 1)";
            case ALTER_INDEX_ANALYZE_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_alter_q WHERE EXISTS (SELECT 1 FROM egraph_alter_probe "
                        + "INDEXED BY egraph_alter_value_idx WHERE value >= 0 LIMIT 1)";
            case SELECT_WHERE_STRESS_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_select_where_q WHERE EXISTS (SELECT 1 FROM egraph_plan_probe "
                        + "WHERE v >= 0 LIMIT 1)";
            case EXPR_STRESS_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_expr_q WHERE EXISTS (SELECT 1 FROM egraph_expr_probe "
                        + "WHERE typeof(txt) = 'text' LIMIT 1)";
            case WINDOW_STRESS_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_window_q WHERE EXISTS (SELECT 1 FROM egraph_window_probe "
                        + "WHERE grp >= 0 LIMIT 1)";
            case RESOLVE_STRESS_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_resolve_q WHERE EXISTS (SELECT 1 FROM egraph_resolve_view "
                        + "WHERE alias_value >= 0 LIMIT 1)";
            case SORTER_STRESS_CONTEXT:
                // Only ORDER BY goes through vdbesort.c; GROUP BY uses a temp
                // B-tree and never spills a PMA. The join multiplies the wide
                // probe rows by the inner row count, which carries the sort past
                // the ~1 MB PMA floor into the external merge path.
                //
                // ORDER BY makes the comparison order-sensitive, so the output
                // order has to be fully determined. It is: the sort key
                // (payload, id) is a total order over distinct probe rows, only
                // probe columns are projected, and the rows repeated per inner
                // row are byte-identical, so ties are interchangeable. A sort
                // that loses or duplicates a row still changes the output and is
                // reported.
                //
                // The inline amplifier matters: a base query often returns only a
                // few rows, and one inner row contributes just ~145 KB, so
                // without it the sort stays under the PMA floor and never spills.
                // Amplifying by 8 guarantees ~1.2 MB even for a single-row inner
                // query, and costs nothing in the snapshot (no extra table).
                return "WITH egraph_sorter_amp(k) AS (VALUES(1),(2),(3),(4),(5),(6),(7),(8)) "
                        + "SELECT p.id, p.bucket FROM (" + query
                        + ") AS egraph_sorter_q JOIN egraph_sorter_probe AS p ON p.bucket >= 0 "
                        + "CROSS JOIN egraph_sorter_amp ORDER BY p.payload, p.id";
            case SCALAR_FUNCTION_BATTERY_CONTEXT:
                return "SELECT egraph_fn.*, instr('abcabc', 'ca') AS egraph_fn_instr, "
                        + "instr(x'0102030405', x'0304') AS egraph_fn_instr_blob, "
                        + "unhex('48656C6C6F') AS egraph_fn_unhex, "
                        + "unhex('48-65-6C', '-') AS egraph_fn_unhex_sep, "
                        + "concat('a', 2, NULL, 'b') AS egraph_fn_concat, "
                        + "concat_ws('-', 'a', NULL, 'b', 3) AS egraph_fn_concat_ws, "
                        + "log(100.0) AS egraph_fn_log, log(2, 8.0) AS egraph_fn_logb, "
                        + "log2(64.0) AS egraph_fn_log2, log10(1000.0) AS egraph_fn_log10, "
                        + "format('%!.4f|%+d|%5s|%x', 3.14159, 42, 'ab', 255) AS egraph_fn_format, "
                        + "char(72, 105, 0x4E2D) AS egraph_fn_char, unicode('Z') AS egraph_fn_unicode, "
                        + "ltrim('xxabcxx', 'x') AS egraph_fn_ltrim, rtrim('xxabcxx', 'x') AS egraph_fn_rtrim, "
                        + "trim('xxabcxx', 'x') AS egraph_fn_trim, replace('aaa', 'a', 'bb') AS egraph_fn_replace, "
                        + "substr('abcdef', -3, 2) AS egraph_fn_substr, quote(x'00ff') AS egraph_fn_quote_blob, "
                        + "quote(NULL) AS egraph_fn_quote_null, iif(1 > 0, 'y', 'n') AS egraph_fn_iif, "
                        + "likelihood(1, 0.5) AS egraph_fn_likelihood, likely(1) AS egraph_fn_likely, "
                        + "unlikely(1) AS egraph_fn_unlikely, octet_length('ab') AS egraph_fn_octet_length, "
                        + "sign(-7.5) AS egraph_fn_sign, trunc(-7.9) AS egraph_fn_trunc, "
                        + "ceil(2.1) AS egraph_fn_ceil, floor(-2.1) AS egraph_fn_floor, "
                        + "pow(2, 10) AS egraph_fn_pow, mod(-7, 3) AS egraph_fn_mod, "
                        + "atan2(1, 1) AS egraph_fn_atan2, degrees(3.14159265358979) AS egraph_fn_degrees, "
                        + "radians(180.0) AS egraph_fn_radians, sinh(1.0) AS egraph_fn_sinh, "
                        + "cosh(1.0) AS egraph_fn_cosh, tanh(1.0) AS egraph_fn_tanh, "
                        + "asinh(1.0) AS egraph_fn_asinh, acosh(2.0) AS egraph_fn_acosh, "
                        + "atanh(0.5) AS egraph_fn_atanh, exp(1.0) AS egraph_fn_exp, "
                        + "ln(2.718281828459045) AS egraph_fn_ln, "
                        + "timediff('2026-08-31 12:00:00', '2026-01-01 00:00:00') AS egraph_fn_timediff FROM ("
                        + query + ") AS egraph_fn";
            case DATE_MODIFIER_BATTERY_CONTEXT:
                return "SELECT egraph_dt.*, "
                        + "datetime('2026-08-31 12:34:56', '+1 day', '-2 hours', '+30 minutes', '-15 seconds') "
                        + "AS egraph_dt_offsets, "
                        + "datetime('2026-08-31 12:34:56', '+1 month', '-1 year') AS egraph_dt_ym, "
                        + "datetime('2026-08-31 12:34:56', 'start of month') AS egraph_dt_som, "
                        + "datetime('2026-08-31 12:34:56', 'start of year') AS egraph_dt_soy, "
                        + "datetime('2026-08-31 12:34:56', 'start of day') AS egraph_dt_sod, "
                        + "datetime('2026-08-31 12:34:56', 'weekday 3') AS egraph_dt_weekday, "
                        + "datetime(2461284.0234, 'julianday') AS egraph_dt_julian, "
                        + "datetime(1788000000, 'unixepoch') AS egraph_dt_unix, "
                        + "datetime(1788000000, 'unixepoch', 'localtime') AS egraph_dt_localtime, "
                        + "datetime('2026-08-31 12:34:56', 'utc') AS egraph_dt_utc, "
                        + "datetime('2026-08-31 12:34:56.789', 'subsec') AS egraph_dt_subsec, "
                        + "datetime('2026-08-31 12:34:56', 'ceiling') AS egraph_dt_ceiling, "
                        + "datetime('2026-08-31 12:34:56', 'floor') AS egraph_dt_floor, "
                        + "datetime(1788000000123, 'auto') AS egraph_dt_auto, "
                        + "strftime('%Y|%m|%d|%H|%M|%S|%f|%j|%w|%W|%s|%J|%U|%G|%g|%u|%e|%k|%l|%p|%P|%I|%R|%T|%F', "
                        + "'2026-08-31 12:34:56.789') AS egraph_dt_strftime, "
                        + "julianday('2026-08-31', 'start of month', '+15 days') AS egraph_dt_juliandayf, "
                        + "unixepoch('2026-08-31 12:34:56', 'subsec') AS egraph_dt_unixepochf, "
                        + "timediff('2026-08-31', '2020-02-29') AS egraph_dt_timediff, "
                        + "date('2026-08-31 12:34:56', '+1 day', 'start of month') AS egraph_dt_date, "
                        + "time('2026-08-31 12:34:56', '+90 minutes') AS egraph_dt_time FROM (" + query
                        + ") AS egraph_dt";
            case WINDOW_FUNCTION_BATTERY_CONTEXT:
                // Collapsed to a single row: the OVER clauses need ORDER BY, and
                // that switches the oracle to an order-sensitive comparison which
                // the unordered inner query could not satisfy. The moving ROWS
                // frames are what drive the inverse callbacks
                // (last_valueInvFunc, groupConcatInverse).
                return "SELECT count(*) AS egraph_wf_rows, sum(w.a) AS egraph_wf_nth, "
                        + "sum(w.b) AS egraph_wf_last, sum(w.c) AS egraph_wf_first, "
                        + "sum(w.d) AS egraph_wf_lag, sum(w.e) AS egraph_wf_lead, "
                        + "sum(w.f) AS egraph_wf_ntile, group_concat(w.g) AS egraph_wf_gc, "
                        + "sum(w.h) AS egraph_wf_nth_plain, sum(w.i) AS egraph_wf_rank FROM ("
                        + "SELECT nth_value(p.id, 2) OVER (ORDER BY p.id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) "
                        + "AS a, last_value(p.id) OVER (ORDER BY p.id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) "
                        + "AS b, first_value(p.id) OVER (ORDER BY p.id ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) "
                        + "AS c, lag(p.id, 2, -1) OVER (ORDER BY p.id) AS d, "
                        + "lead(p.id, 2, -1) OVER (ORDER BY p.id) AS e, ntile(4) OVER (ORDER BY p.id) AS f, "
                        + "group_concat(p.bucket) OVER (ORDER BY p.id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) "
                        + "AS g, nth_value(p.id, 3) OVER (ORDER BY p.id ROWS BETWEEN UNBOUNDED PRECEDING AND "
                        + "CURRENT ROW) AS h, dense_rank() OVER (ORDER BY p.bucket) AS i "
                        + "FROM (" + query + ") AS egraph_wf_q JOIN egraph_sorter_probe AS p ON p.bucket = 0"
                        + ") AS w";
            case FTS5_VARIANT_CONFIG_CONTEXT:
                // FTS5 behaves like a different engine per configuration: a
                // contentless_delete index keeps tombstones, detail=none has no
                // position lists at all (so no phrase queries), and each tokenizer
                // has its own implementation. Those code paths are unreachable from
                // a single default-configured table.
                return "SELECT egraph_fts5v_q.*, "
                        + "(SELECT count(*) FROM egraph_fts5_cd WHERE egraph_fts5_cd MATCH 'common') "
                        + "AS egraph_fts5v_tombstone, "
                        + "(SELECT count(*) FROM egraph_fts5_cd WHERE egraph_fts5_cd MATCH 'alpha7 OR alpha9') "
                        + "AS egraph_fts5v_tombstone_or, "
                        + "(SELECT count(*) FROM egraph_fts5_none WHERE egraph_fts5_none MATCH 'common AND word5') "
                        + "AS egraph_fts5v_detail_none, "
                        + "(SELECT count(*) FROM egraph_fts5_none WHERE egraph_fts5_none MATCH 'wor*') "
                        + "AS egraph_fts5v_none_prefix, "
                        + "(SELECT count(*) FROM egraph_fts5_col WHERE egraph_fts5_col MATCH '{a}: common') "
                        + "AS egraph_fts5v_detail_col, "
                        + "(SELECT count(*) FROM egraph_fts5_ascii WHERE egraph_fts5_ascii MATCH 'common') "
                        + "AS egraph_fts5v_ascii, "
                        + "(SELECT count(*) FROM egraph_fts5_ext WHERE egraph_fts5_ext MATCH 'common') "
                        + "AS egraph_fts5v_external FROM (" + query + ") AS egraph_fts5v_q";
            case PRAGMA_VTAB_CONTEXT:
                // The pragma table-valued functions are a virtual-table module of
                // their own (pragmaVtabConnect/BestIndex/Filter/Next).
                return "SELECT egraph_pragma_q.*, "
                        + "(SELECT count(*) FROM pragma_table_info('egraph_sorter_probe')) AS egraph_pv_tinfo, "
                        + "(SELECT count(*) FROM pragma_table_xinfo('egraph_sorter_probe')) AS egraph_pv_txinfo, "
                        + "(SELECT count(*) FROM pragma_index_list('egraph_sorter_probe')) AS egraph_pv_ilist, "
                        + "(SELECT count(*) FROM pragma_function_list WHERE name LIKE 'j%') AS egraph_pv_flist, "
                        + "(SELECT count(*) FROM pragma_module_list WHERE name LIKE 'fts%') AS egraph_pv_mlist, "
                        + "(SELECT count(*) FROM pragma_collation_list) AS egraph_pv_clist FROM (" + query
                        + ") AS egraph_pragma_q";
            case FTS4_MERGE_LCS_CONTEXT:
                // matchinfo's 's'/'y' flags are the LCS computation (fts3MatchinfoLcs),
                // and a three-token phrase drives the doclist/poslist merges. The
                // helpers only work as bare projection items of a SELECT whose FROM
                // names the fts table directly, hence the join rather than a subquery.
                // No ORDER BY: the oracle switches to an order-sensitive comparison as
                // soon as one appears in the query text, so the descending-docid scan
                // lives in the context setup instead.
                return "SELECT egraph_f4m_q.*, length(matchinfo(egraph_fts4m, 'pcxsy')) AS egraph_f4m_lcs, "
                        + "offsets(egraph_fts4m) AS egraph_f4m_offsets, "
                        + "egraph_fts4m.docid AS egraph_f4m_docid FROM (" + query
                        + ") AS egraph_f4m_q, egraph_fts4m "
                        + "WHERE egraph_fts4m MATCH '\"lcsanchor alpha beta\"'";
            case FTS3_TOKENIZE_TABLE_CONTEXT:
                // The fts3tokenize virtual table is an ordinary (read-only) table
                // module, so unlike the fts helpers it can be used from a subquery.
                // Token counts and lengths are real computed values.
                return "SELECT egraph_tok_q.*, "
                        + "(SELECT count(*) FROM egraph_fts3tok "
                        + "WHERE input = 'alpha beta gamma delta epsilon') AS egraph_tok_uni, "
                        + "(SELECT count(*) FROM egraph_fts3tokp "
                        + "WHERE input = 'running jumped quickly testing') AS egraph_tok_porter, "
                        + "(SELECT sum(length(token)) FROM egraph_fts3tok "
                        + "WHERE input = 'sqlite coverage probe') AS egraph_tok_len, "
                        + "(SELECT count(*) FROM egraph_fts4c WHERE egraph_fts4c MATCH 'alpha') "
                        + "AS egraph_tok_content FROM (" + query + ") AS egraph_tok_q";
            case FTS5_TOMBSTONE_CONTEXT:
                // A contentless_delete=1 table keeps deleted rowids in tombstone
                // pages, so every match count below has to consult them.
                return "SELECT egraph_f5cd_q.*, "
                        + "(SELECT count(*) FROM egraph_fts5cd WHERE egraph_fts5cd MATCH 'alpha') "
                        + "AS egraph_f5cd_all, "
                        + "(SELECT count(*) FROM egraph_fts5cd "
                        + "WHERE egraph_fts5cd MATCH 'token7 OR token11 OR token13') AS egraph_f5cd_or, "
                        + "(SELECT count(*) FROM egraph_fts5cd WHERE egraph_fts5cd MATCH 'tomb*') "
                        + "AS egraph_f5cd_prefix FROM (" + query + ") AS egraph_f5cd_q";
            case FTS5_TOKENIZER_VARIANT_CONTEXT:
                // Three tokenizers that the default unicode61 configuration never
                // reaches: ascii folding, tokenchars/separators exceptions, and a
                // detail=none index whose segment iterator is a separate code path.
                return "SELECT egraph_f5tv_q.*, "
                        + "(SELECT count(*) FROM egraph_fts5asc WHERE egraph_fts5asc MATCH 'alpha') "
                        + "AS egraph_f5tv_ascii, "
                        + "(SELECT count(*) FROM egraph_fts5uni WHERE egraph_fts5uni MATCH '\"foo-bar\"') "
                        + "AS egraph_f5tv_uni, "
                        + "(SELECT count(*) FROM egraph_fts5uni WHERE egraph_fts5uni MATCH 'baz') "
                        + "AS egraph_f5tv_sep, "
                        + "(SELECT count(*) FROM egraph_fts5none WHERE egraph_fts5none MATCH 'alpha AND gamma') "
                        + "AS egraph_f5tv_none FROM (" + query + ") AS egraph_f5tv_q";
            case SQL_SYNTAX_BATTERY_CONTEXT:
                // Grammar forms that survive as scalar subqueries: a bracketed
                // sub-join in FROM, USING, a three-keyword join, RIGHT/FULL OUTER
                // JOIN, LIMIT with an offset, a generated column, and a subtype
                // read. All collapse to a count, and none contains ORDER BY -
                // the oracle would switch to an order-sensitive comparison.
                return "SELECT egraph_syn_q.*, "
                        + "(SELECT count(*) FROM (SELECT k FROM egraph_syn_par LIMIT 1, 3)) AS egraph_syn_limit, "
                        + "(SELECT count(*) FROM (egraph_syn_par AS p JOIN egraph_syn_chi AS c ON p.k = c.k)) "
                        + "AS egraph_syn_paren, "
                        + "(SELECT count(*) FROM egraph_syn_par JOIN egraph_syn_chi USING (k)) AS egraph_syn_using, "
                        + "(SELECT count(*) FROM egraph_syn_par NATURAL LEFT OUTER JOIN egraph_syn_chi) "
                        + "AS egraph_syn_natural, "
                        + "(SELECT count(*) FROM egraph_syn_par RIGHT OUTER JOIN egraph_syn_chi "
                        + "ON egraph_syn_par.k = egraph_syn_chi.k) AS egraph_syn_right, "
                        + "(SELECT count(*) FROM egraph_syn_par FULL OUTER JOIN egraph_syn_chi "
                        + "ON egraph_syn_par.k = egraph_syn_chi.k) AS egraph_syn_full, "
                        + "(SELECT sum(g) + sum(h) FROM egraph_syn_def) AS egraph_syn_generated, "
                        + "(SELECT sum(subtype(jsonb(v))) FROM egraph_syn_par) AS egraph_syn_subtype "
                        + "FROM (" + query + ") AS egraph_syn_q";
            case FTS5_DEEP_QUERY_CONTEXT:
                // The full FTS5 query grammar against an index that has prefix
                // indexes, several segments and tombstones: column filters, prefix,
                // phrase, NEAR, NOT, initial-token match, rank ordering, reverse
                // rowid iteration and the three fts5vocab shapes.
                return "SELECT egraph_fts5d_q.*, "
                        + "(SELECT count(*) FROM egraph_fts5d WHERE egraph_fts5d MATCH 'sqlite AND planner') "
                        + "AS egraph_fts5d_and, "
                        + "(SELECT count(*) FROM egraph_fts5d WHERE egraph_fts5d MATCH '{title}: sqlite') "
                        + "AS egraph_fts5d_col, "
                        + "(SELECT count(*) FROM egraph_fts5d WHERE egraph_fts5d MATCH '{title body}: coverage') "
                        + "AS egraph_fts5d_cols, "
                        + "(SELECT count(*) FROM egraph_fts5d WHERE egraph_fts5d MATCH 'term1*') "
                        + "AS egraph_fts5d_prefix, "
                        + "(SELECT count(*) FROM egraph_fts5d WHERE egraph_fts5d MATCH '\"query planner\"') "
                        + "AS egraph_fts5d_phrase, "
                        + "(SELECT count(*) FROM egraph_fts5d WHERE egraph_fts5d MATCH 'NEAR(sqlite planner, 5)') "
                        + "AS egraph_fts5d_near, "
                        + "(SELECT count(*) FROM egraph_fts5d WHERE egraph_fts5d MATCH 'sqlite NOT alpha3') "
                        + "AS egraph_fts5d_not, "
                        + "(SELECT count(*) FROM egraph_fts5d WHERE egraph_fts5d MATCH '^title5') "
                        + "AS egraph_fts5d_initial, "
                        + "(SELECT count(*) FROM (SELECT rowid FROM egraph_fts5d WHERE egraph_fts5d MATCH 'sqlite' "
                        + "ORDER BY rank LIMIT 20)) AS egraph_fts5d_rank, "
                        + "(SELECT count(*) FROM (SELECT rowid FROM egraph_fts5d WHERE egraph_fts5d MATCH 'sqlite' "
                        + "ORDER BY rowid DESC LIMIT 20)) AS egraph_fts5d_reverse, "
                        + "(SELECT count(*) FROM egraph_fts5d_v WHERE term LIKE 'term1%') AS egraph_fts5d_vinst, "
                        + "(SELECT count(*) FROM egraph_fts5d_vr WHERE cnt > 1) AS egraph_fts5d_vrow, "
                        + "(SELECT count(*) FROM egraph_fts5d_vc WHERE col = 'body') AS egraph_fts5d_vcol FROM ("
                        + query + ") AS egraph_fts5d_q";
            case FTS5_AUX_DEEP_CONTEXT:
                // highlight/snippet/bm25 have to be bare projection items of the
                // SELECT that owns the MATCH, so they are computed in a subquery and
                // aggregated here; the aggregate also collapses the ORDER BY rank
                // result to one row, which keeps the comparison order-independent.
                return "SELECT count(*) AS egraph_fts5aux_rows, sum(length(aux.hl)) AS egraph_fts5aux_hl, "
                        + "sum(length(aux.sn)) AS egraph_fts5aux_sn, min(aux.bm) AS egraph_fts5aux_bm FROM ("
                        + "SELECT highlight(egraph_fts5d, 0, '[', ']') AS hl, "
                        + "snippet(egraph_fts5d, 1, '<', '>', '...', 8) AS sn, "
                        + "bm25(egraph_fts5d, 2.0, 1.0) AS bm FROM egraph_fts5d "
                        + "WHERE egraph_fts5d MATCH 'sqlite OR coverage' ORDER BY rank LIMIT 30) AS aux, ("
                        + query + ") AS egraph_fts5aux_q";
            case FTS4_DEEP_SEGMENT_CONTEXT:
                // Queries over an fts4 index built in batches, so it has several
                // segments and multi-level segment b-trees. matchinfo carries the
                // 's' and 'y' flags, which is the LCS computation.
                return "SELECT egraph_fts4d_q.*, "
                        + "(SELECT count(*) FROM egraph_fts4d WHERE egraph_fts4d MATCH 'common sqlite') "
                        + "AS egraph_fts4d_and, "
                        + "(SELECT count(*) FROM egraph_fts4d WHERE egraph_fts4d MATCH '\"common sqlite planner\"') "
                        + "AS egraph_fts4d_phrase, "
                        + "(SELECT count(*) FROM egraph_fts4d WHERE egraph_fts4d MATCH 'common OR w5 OR x7') "
                        + "AS egraph_fts4d_or, "
                        + "(SELECT count(*) FROM egraph_fts4d WHERE egraph_fts4d MATCH 'common NEAR/2 planner') "
                        + "AS egraph_fts4d_near, "
                        + "(SELECT count(*) FROM egraph_fts4d WHERE egraph_fts4d MATCH 'w1*') "
                        + "AS egraph_fts4d_prefix, length(matchinfo(egraph_fts4d, 'pcxnalsy')) "
                        + "AS egraph_fts4d_matchinfo FROM (" + query
                        + ") AS egraph_fts4d_q, egraph_fts4d WHERE egraph_fts4d MATCH 'common planner'";
            case FTS4_MATCH_CONTEXT:
                // FTS3/FTS4 query-expression variety: OR, phrase, NEAR, negation,
                // column filter, prefix and parenthesised groups, across three
                // tokenizers. The match counts are part of the result, so a wrong
                // match set is a mismatch rather than an invisible difference.
                return "SELECT egraph_fts4_q.*, "
                        + "(SELECT count(*) FROM egraph_fts4 WHERE egraph_fts4 MATCH 'sqlite OR coverage') "
                        + "AS egraph_fts4_or, "
                        + "(SELECT count(*) FROM egraph_fts4 WHERE egraph_fts4 MATCH '\"query planner\"') "
                        + "AS egraph_fts4_phrase, "
                        + "(SELECT count(*) FROM egraph_fts4 WHERE egraph_fts4 MATCH 'sqlite NEAR/3 tokenizer') "
                        + "AS egraph_fts4_near, "
                        + "(SELECT count(*) FROM egraph_fts4 WHERE egraph_fts4 MATCH 'segment -alpha') "
                        + "AS egraph_fts4_not, "
                        + "(SELECT count(*) FROM egraph_fts4 WHERE egraph_fts4 MATCH 'title:sqlite') "
                        + "AS egraph_fts4_col, "
                        + "(SELECT count(*) FROM egraph_fts4 WHERE egraph_fts4 MATCH 'tok*') "
                        + "AS egraph_fts4_prefix, "
                        + "(SELECT count(*) FROM egraph_fts4 WHERE egraph_fts4 MATCH '(alpha OR beta) AND sqlite') "
                        + "AS egraph_fts4_group, "
                        + "(SELECT count(*) FROM egraph_fts4_uni WHERE egraph_fts4_uni MATCH 'planner') "
                        + "AS egraph_fts4_unicode, "
                        + "(SELECT count(*) FROM egraph_fts3 WHERE egraph_fts3 MATCH 'variants') "
                        + "AS egraph_fts3_simple, "
                        + "(SELECT count(*) FROM egraph_fts4_aux WHERE term LIKE 's%') AS egraph_fts4_terms FROM ("
                        + query + ") AS egraph_fts4_q";
            case FTS4_AUX_CONTEXT:
                // offsets/snippet/matchinfo only work as bare projection items of a
                // SELECT whose FROM names the fts table directly - not inside an
                // aggregate, not through an alias, not in a nested subquery.
                return "SELECT egraph_fts4_aux_q.*, offsets(egraph_fts4) AS egraph_fts4_offsets, "
                        + "snippet(egraph_fts4, '[', ']', '...', -1, 6) AS egraph_fts4_snippet, "
                        + "length(matchinfo(egraph_fts4, 'pcx')) AS egraph_fts4_matchinfo, "
                        + "egraph_fts4.docid AS egraph_fts4_docid FROM (" + query
                        + ") AS egraph_fts4_aux_q, egraph_fts4 WHERE egraph_fts4 MATCH 'gamma OR sqlite OR planner'";
            case BLOOM_FILTER_CONTEXT:
                // A star join the planner answers with a Bloom filter on each
                // dimension (sqlite3ConstructBloomFilter).
                return "SELECT egraph_bloom_q.*, (SELECT count(*) FROM egraph_star_fact AS f "
                        + "JOIN egraph_star_dim1 AS a ON a.k = f.d1 JOIN egraph_star_dim2 AS b ON b.k = f.d2 "
                        + "WHERE a.label = 'd1-7' AND b.label = 'd2-9') AS egraph_bloom_hits, "
                        + "(SELECT count(*) FROM egraph_star_fact AS f JOIN egraph_star_dim1 AS a ON a.k = f.d1 "
                        + "WHERE a.label LIKE 'd1-1%') AS egraph_bloom_like FROM (" + query + ") AS egraph_bloom_q";
            case MULTI_INDEX_OR_ROWSET_CONTEXT:
                // Equality predicates on two indexed columns make the planner pick
                // MULTI-INDEX OR, whose rowid de-duplication is the RowSet code.
                return "SELECT egraph_or_q.*, (SELECT count(*) FROM egraph_or_probe "
                        + "WHERE a = 5 OR b = 7 OR a = 9) AS egraph_or_hits, "
                        + "(SELECT count(*) FROM egraph_or_probe WHERE a IN (1, 2, 3) OR b IN (4, 5, 6)) "
                        + "AS egraph_or_in, (SELECT sum(id) FROM egraph_or_probe WHERE a = 3 OR b = 11 OR id = 42) "
                        + "AS egraph_or_sum FROM (" + query + ") AS egraph_or_q";
            case INDEX_FUNCTION_VALUE_CONTEXT:
                // A function on the constant side of an indexed comparison, which
                // is evaluated at the index seek boundary (valueFromFunction).
                return "SELECT egraph_idxfn_q.*, (SELECT count(*) FROM egraph_or_probe WHERE a = abs(-7)) "
                        + "AS egraph_idxfn_abs, (SELECT count(*) FROM egraph_or_probe WHERE a = length('abcd')) "
                        + "AS egraph_idxfn_len, (SELECT count(*) FROM egraph_or_probe "
                        + "WHERE a = max(3, 5) AND b = min(11, 19)) AS egraph_idxfn_minmax, "
                        + "(SELECT count(*) FROM egraph_or_probe WHERE a IN (VALUES(3),(5),(7),(11))) "
                        + "AS egraph_idxfn_values FROM (" + query + ") AS egraph_idxfn_q";
            case SORTER_DEEP_MERGE_CONTEXT:
                // Same construction as SORTER_STRESS_CONTEXT, amplified far enough
                // (~21 MB) that the sorter needs more PMAs than it can merge in one
                // pass and has to build a merge tree (vdbeSorterAddToTree).
                // Measured at 0.2 s for the whole sort, so the extra volume is cheap.
                return "WITH RECURSIVE egraph_deep_amp(k) AS (VALUES(1) UNION ALL "
                        + "SELECT k + 1 FROM egraph_deep_amp WHERE k < 144) "
                        + "SELECT p.id, p.bucket FROM (" + query
                        + ") AS egraph_deep_q JOIN egraph_sorter_probe AS p ON p.bucket >= 0 "
                        + "CROSS JOIN egraph_deep_amp ORDER BY p.payload, p.id";
            case ROW_VALUE_CONTEXT:
                // Row-value comparisons in every supported position: =, IN
                // (VALUES ...) and BETWEEN. The counts are part of the result,
                // so a wrong row-value evaluation is reported.
                return "SELECT egraph_rv.*, (SELECT count(*) FROM egraph_rowvalue_probe AS p "
                        + "WHERE (p.a, p.b) IN (VALUES (1, 'x'), (2, 'y'), (3, NULL), (4, 'z'))) "
                        + "AS egraph_rv_in, (SELECT count(*) FROM egraph_rowvalue_probe AS p "
                        + "WHERE (p.a, p.b) = (p.c, p.d)) AS egraph_rv_eq, "
                        + "(SELECT count(*) FROM egraph_rowvalue_probe AS p "
                        + "WHERE (p.a, p.b) BETWEEN (1, 'a') AND (9, 'zzz')) AS egraph_rv_between, "
                        + "(SELECT count(*) FROM egraph_rowvalue_probe AS p WHERE (p.a, p.b) IN "
                        + "(SELECT q2.c, q2.d FROM egraph_rowvalue_probe AS q2)) AS egraph_rv_subquery FROM ("
                        + query + ") AS egraph_rv";
            case AGGREGATE_ORDER_BY_CONTEXT:
                // group_concat with an in-aggregate ORDER BY. The wrapper collapses
                // to a single row, so the order-sensitive comparison this ORDER BY
                // triggers cannot produce a false mismatch from inner row order.
                return "SELECT count(*) AS egraph_agg_rows, "
                        + "group_concat(p.payload, ',' ORDER BY p.id DESC) AS egraph_agg_ordered, "
                        + "group_concat(DISTINCT p.bucket) AS egraph_agg_distinct FROM (" + query
                        + ") AS egraph_agg_q JOIN egraph_sorter_probe AS p ON p.bucket = 0";
            case WINDOW_RANGE_FULLSCAN_CONTEXT:
                // A RANGE frame with EXCLUDE drives the window full-scan path.
                // Collapsed to one row for the same reason as above.
                return "SELECT count(*) AS egraph_win_rows, sum(egraph_win_full.w) AS egraph_win_sum, "
                        + "max(egraph_win_full.w) AS egraph_win_max FROM (SELECT sum(p.id) OVER "
                        + "(ORDER BY p.id RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING "
                        + "EXCLUDE CURRENT ROW) AS w FROM (" + query
                        + ") AS egraph_win_q JOIN egraph_sorter_probe AS p ON p.bucket = 0) AS egraph_win_full";
            case JOIN_OPTIMIZER_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_join_q WHERE EXISTS (SELECT 1 FROM egraph_join_left AS l "
                        + "RIGHT JOIN egraph_join_right AS r ON r.k = l.k "
                        + "WHERE r.k >= 0 LIMIT 1)";
            case ALTER_FK_STRESS_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_alter_fk_q WHERE EXISTS (SELECT 1 FROM egraph_fk_child "
                        + "WHERE pid >= 0 LIMIT 1)";
            case INTEGRITY_CHECK_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_integrity_q WHERE EXISTS (SELECT 1 FROM egraph_integrity_probe "
                        + "WHERE k >= 0 LIMIT 1)";
            case SCALAR_AGGREGATE_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_scalar_func_q WHERE EXISTS (SELECT 1 FROM egraph_scalar_probe "
                        + "WHERE id >= 0 LIMIT 1)";
            case VIRTUAL_TABLE_UPDATE_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_vtab_update_q WHERE EXISTS (SELECT 1 FROM egraph_vtab_rt "
                        + "WHERE x1 <= 6.0 AND x2 >= 6.0 LIMIT 1)";
            case VIRTUAL_TABLE_SAVEPOINT_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_vtab_sp_q WHERE EXISTS (SELECT 1 FROM egraph_vtab_sp_fts "
                        + "WHERE egraph_vtab_sp_fts MATCH 'alpha OR beta' LIMIT 1) "
                        + "AND EXISTS (SELECT 1 FROM egraph_vtab_sp_rt "
                        + "WHERE x1 <= 2.0 AND x2 >= 2.0 LIMIT 1)";
            case FTS5_SECURE_DELETE_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_fts_secure_q WHERE EXISTS (SELECT 1 FROM egraph_fts_secure_vocab "
                        + "WHERE term >= 'a' LIMIT 1)";
            case JSONB_STRESS_CONTEXT:
                // Escaped object labels take jsonLabelCompareEscaped, which the plain
                // '$.a.b' paths never reach. Projected, so a wrong value is a mismatch
                // rather than an invisible difference.
                return "SELECT egraph_jsonb_q.*, "
                        + "json_extract(json_object('a\"b', 7, 'c', 8), '$.\"a\\\"b\"') AS egraph_jsonb_esc, "
                        + "json_extract('{\"x\ty\":5,\"z\":6}', '$.\"x\ty\"') AS egraph_jsonb_esc2, "
                        + "(SELECT count(*) FROM json_tree('{\"a\\\"b\":{\"x\ty\":1}}')) "
                        + "AS egraph_jsonb_tree FROM (" + query
                        + ") AS egraph_jsonb_q WHERE json_valid(jsonb('{\"a\":[1,2],\"b\":{\"x\":3}}'), 8) = 1 "
                        + "AND json_extract(jsonb('{\"a\":[1,2],\"b\":{\"x\":3}}'), '$.b.x') = 3";
            case XFER_OPTIMIZATION_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_xfer_q WHERE EXISTS (SELECT 1 FROM egraph_xfer_dst WHERE a >= 0 LIMIT 1)";
            case MULTI_SELECT_ORDER_BY_CONTEXT:
                return "SELECT * FROM (" + query
                        + ") AS egraph_multiselect_q WHERE EXISTS (SELECT 1 FROM egraph_multiselect_probe "
                        + "WHERE v >= 0 LIMIT 1)";
            case COLD_FUNCTION_BATTERY_CONTEXT:
                // unistr and the percentile extension are compiled in but nothing in
                // the generator ever calls them. Every aggregate sits in a scalar
                // subquery over a literal VALUES list, never beside egraph_cf.*: a
                // bare column next to an aggregate makes SQLite pick an arbitrary
                // row, and the original and the variant pick different ones as soon
                // as their plans differ - a mismatch with no bug behind it.
                // The escapes are written as backslash sequences that reach SQLite
                // as-is, which is what exercises unistr's decoder; spelling them as
                // Java character escapes instead would put raw non-ASCII bytes into
                // the corpus and the replay script for no extra coverage. hex()
                // keeps the compared values ASCII as well.
                return "SELECT egraph_cf.*, "
                        + "hex(unistr('\\u00e9\\u4e2dabc')) AS egraph_cf_unistr, "
                        + "hex(unistr('\\U0001f600')) AS egraph_cf_unistr_hi, "
                        + "unistr('a\\\\b') AS egraph_cf_unistr_bs, "
                        + "unistr(x'4142') AS egraph_cf_unistr_blob, "
                        + "unistr(NULL) AS egraph_cf_unistr_null, "
                        + "unistr_quote('a''b') AS egraph_cf_uq_text, "
                        + "unistr_quote(x'00ff') AS egraph_cf_uq_blob, "
                        + "unistr_quote(NULL) AS egraph_cf_uq_null, "
                        + "unistr_quote(1.5) AS egraph_cf_uq_real, "
                        + "unistr_quote(7) AS egraph_cf_uq_int, "
                        // char(9, 10, 65) rather than the escape sequences: a real
                        // newline in the query text would split the line the replay
                        // writer emits, and unistr_quote is what has to produce the
                        // escaped form anyway.
                        + "unistr_quote(char(9, 10, 65)) AS egraph_cf_uq_ctrl, "
                        + "(SELECT median(column1) FROM (VALUES(1),(2),(3),(10))) AS egraph_cf_median, "
                        + "(SELECT median(column1) FROM (VALUES(1),(NULL),(3))) AS egraph_cf_median_null, "
                        + "(SELECT percentile(column1, 25) FROM (VALUES(1),(2),(3),(10))) AS egraph_cf_p25, "
                        + "(SELECT percentile(column1, 0) FROM (VALUES(1),(2),(3),(10))) AS egraph_cf_p0, "
                        + "(SELECT percentile(column1, 100) FROM (VALUES(1),(2),(3),(10))) AS egraph_cf_p100, "
                        + "(SELECT percentile_cont(column1, 0.5) FROM (VALUES(1),(2),(3),(10))) AS egraph_cf_pc, "
                        + "(SELECT percentile_disc(column1, 0.5) FROM (VALUES(1),(2),(3),(10))) AS egraph_cf_pd, "
                        // The window form goes through percentInverse, which the
                        // plain aggregate form never reaches. The ORDER BY is inside
                        // a scalar subquery over a literal VALUES list, so it cannot
                        // make the compared query order-sensitive.
                        + "(SELECT group_concat(egraph_cf_w) FROM (SELECT percentile_cont(column1, 0.5) OVER "
                        + "(ORDER BY column1 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS egraph_cf_w "
                        + "FROM (VALUES(1),(2),(3),(10)))) AS egraph_cf_pc_window "
                        + "FROM (" + query + ") AS egraph_cf";
            case COLD_DDL_TRIGGER_CONTEXT:
                // The DDL that this shape exists for ran in the setup. What is left
                // for the wrapper is to read the probe back, so a broken INSTEAD OF
                // trigger or a DROP CONSTRAINT that rewrote the table wrong shows up
                // as a wrong value instead of passing silently.
                return "SELECT egraph_cold_q.*, "
                        + "(SELECT count(*) FROM egraph_cold_view) AS egraph_cold_rows, "
                        + "(SELECT sum(v.a) FROM egraph_cold_view AS v WHERE v.a > 0) AS egraph_cold_sum, "
                        + "(SELECT count(*) FROM sqlite_master WHERE type = 'trigger' "
                        + "AND tbl_name = 'egraph_cold_view') AS egraph_cold_triggers "
                        + "FROM (" + query + ") AS egraph_cold_q";
            case PLAIN:
                return query;
            default:
                throw new AssertionError(shape);
        }
    }

    private static void addMultiIndexOrIndexes(SQLite3GlobalState state, SQLite3Table table,
            SQLite3Column leftColumn, SQLite3Column rightColumn) throws Exception {
        if (!hasUsableIdentifier(table.getName()) || !hasUsableIdentifier(leftColumn) || !hasUsableIdentifier(rightColumn)) {
            return;
        }
        if (table.isVirtual()) {
            // CREATE INDEX is not allowed on a virtual table. Reachable since R-Tree tables became
            // eligible base-query targets: the statement raised an unexpected AssertionError and
            // aborted the whole database generation, which is why the R-Tree table was never
            // actually queried in the first run after that change.
            return;
        }
        String tableName = quoteIdentifier(table.getName());
        String leftColumnName = quoteIdentifier(leftColumn.getName());
        String rightColumnName = quoteIdentifier(rightColumn.getName());
        String leftIndexName = quoteIdentifier("egraph_mio_" + sanitizeIdentifierPart(table.getName()) + "_"
                + sanitizeIdentifierPart(leftColumn.getName()));
        String rightIndexName = quoteIdentifier("egraph_mio_" + sanitizeIdentifierPart(table.getName()) + "_"
                + sanitizeIdentifierPart(rightColumn.getName()));
        state.executeStatement(new SQLQueryAdapter("PRAGMA automatic_index=ON", false));
        state.executeStatement(new SQLQueryAdapter(
                "CREATE INDEX IF NOT EXISTS " + leftIndexName + " ON " + tableName + "("
                        + leftColumnName + ")",
                false));
        state.executeStatement(new SQLQueryAdapter(
                "CREATE INDEX IF NOT EXISTS " + rightIndexName + " ON " + tableName + "("
                        + rightColumnName + ")",
                false));
    }

    private static boolean prepareHighCoverageContext(SQLite3GlobalState state, SQLite3Table table,
            List<SQLite3Column> columns, SQLite3Column selectedColumn, EGraphCoverageShape shape) {
        switch (shape) {
            case FTS5_MATCH_CONTEXT:
                return setupFts5Context(state);
            case FTS5_DEEP_CONTEXT:
                return setupFts5DeepContext(state);
            case RTREE_CONTEXT:
                return setupRtreeContext(state);
            case RTREE_DEEP_CONTEXT:
                return setupRtreeDeepContext(state);
            case DBSTAT_CONTEXT:
                return setupDbstatContext(state);
            case VIEW_TRIGGER_FK_CONTEXT:
                return setupViewTriggerFkContext(state);
            case ANALYZE_INDEX_CONTEXT:
                if (columns.isEmpty()) {
                    return false;
                }
                return setupAnalyzeIndexContext(state, table, selectedColumn);
            case JSON_CONTEXT:
                return true;
            case TX_WAL_VACUUM_CONTEXT:
                return setupTxWalVacuumContext(state);
            case AUTO_VACUUM_INTEGRITY_CONTEXT:
                return setupAutoVacuumIntegrityContext(state);
            case ATTACH_VACUUM_WAL_CONTEXT:
                return setupAttachVacuumWalContext(state);
            case ALTER_INDEX_ANALYZE_CONTEXT:
                return setupAlterIndexAnalyzeContext(state);
            case SELECT_WHERE_STRESS_CONTEXT:
                return setupSelectWhereStressContext(state);
            case EXPR_STRESS_CONTEXT:
                return setupExprStressContext(state);
            case WINDOW_STRESS_CONTEXT:
                return setupWindowStressContext(state);
            case RESOLVE_STRESS_CONTEXT:
                return setupResolveStressContext(state);
            case SORTER_STRESS_CONTEXT:
            case AGGREGATE_ORDER_BY_CONTEXT:
            case WINDOW_RANGE_FULLSCAN_CONTEXT:
            case WINDOW_FUNCTION_BATTERY_CONTEXT:
                return setupSorterStressContext(state);
            case ROW_VALUE_CONTEXT:
                return setupRowValueContext(state);
            case FTS4_MATCH_CONTEXT:
            case FTS4_AUX_CONTEXT:
                return setupFts4Context(state);
            case BLOOM_FILTER_CONTEXT:
                return setupStarJoinContext(state);
            case MULTI_INDEX_OR_ROWSET_CONTEXT:
            case INDEX_FUNCTION_VALUE_CONTEXT:
                return setupOrProbeContext(state);
            case SORTER_DEEP_MERGE_CONTEXT:
                return setupSorterStressContext(state);
            case FTS5_DEEP_QUERY_CONTEXT:
            case FTS5_AUX_DEEP_CONTEXT:
                return setupFts5DeepQueryContext(state);
            case FTS4_DEEP_SEGMENT_CONTEXT:
                return setupFts4DeepSegmentContext(state);
            case FTS5_VARIANT_CONFIG_CONTEXT:
                return setupFts5VariantConfigContext(state);
            case PRAGMA_VTAB_CONTEXT:
                return setupSorterStressContext(state);
            case FTS4_MERGE_LCS_CONTEXT:
                return setupFts4MergeLcsContext(state);
            case FTS3_TOKENIZE_TABLE_CONTEXT:
                return setupFts3TokenizeTableContext(state);
            case FTS5_TOMBSTONE_CONTEXT:
                return setupFts5TombstoneContext(state);
            case FTS5_TOKENIZER_VARIANT_CONTEXT:
                return setupFts5TokenizerVariantContext(state);
            case SQL_SYNTAX_BATTERY_CONTEXT:
                return setupSqlSyntaxBatteryContext(state);
            case COLD_FUNCTION_BATTERY_CONTEXT:
                // Pure wrapper: the built-ins need no schema of their own.
                return true;
            case COLD_DDL_TRIGGER_CONTEXT:
                return setupColdDdlTriggerContext(state);
            case JOIN_OPTIMIZER_CONTEXT:
                return setupJoinOptimizerContext(state);
            case ALTER_FK_STRESS_CONTEXT:
                return setupAlterFkStressContext(state);
            case INTEGRITY_CHECK_CONTEXT:
                return setupIntegrityCheckContext(state);
            case SCALAR_AGGREGATE_CONTEXT:
                return setupScalarAggregateContext(state);
            case VIRTUAL_TABLE_UPDATE_CONTEXT:
                return setupVirtualTableUpdateContext(state);
            case FTS5_SECURE_DELETE_CONTEXT:
                return setupFts5SecureDeleteContext(state);
            case VIRTUAL_TABLE_SAVEPOINT_CONTEXT:
                return setupVirtualTableSavepointContext(state);
            case JSONB_STRESS_CONTEXT:
                return setupJsonbStressContext(state);
            case XFER_OPTIMIZATION_CONTEXT:
                return setupXferOptimizationContext(state);
            case MULTI_SELECT_ORDER_BY_CONTEXT:
                return setupMultiSelectOrderByContext(state);
            default:
                return true;
        }
    }

    private static boolean setupFts4MergeLcsContext(SQLite3GlobalState state) {
        // A memory-mapped pager read path (winMapfile / getPageMMap) never opens
        // otherwise; it costs one pragma and applies to the whole connection.
        executeContextStatement(state, "PRAGMA mmap_size = 268435456", false);
        boolean ok = executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fts4m", true);
        ok &= executeContextStatement(state, "CREATE VIRTUAL TABLE egraph_fts4m USING fts4(title, body)", true);
        if (!ok) {
            return false;
        }
        // automerge=0 leaves one segment per batch, so a term's doclist really is
        // spread over several segments instead of being merged into one.
        executeContextStatement(state, "INSERT INTO egraph_fts4m(egraph_fts4m) VALUES('automerge=0')", false);
        for (int batch = 0; batch < 6; batch++) {
            int lo = batch * 32 + 1;
            int hi = lo + 31;
            executeContextStatement(state,
                    "WITH RECURSIVE n(x) AS (VALUES(" + lo + ") UNION ALL SELECT x + 1 FROM n WHERE x < " + hi + ") "
                            + "INSERT INTO egraph_fts4m(docid, title, body) SELECT x, printf('t%d alpha beta', x), "
                            + "printf('common alpha beta gamma w%d %s alpha beta delta zeta rare%d', x, "
                            + "CASE WHEN x % 64 = 1 THEN 'lcsanchor' ELSE 'plainword' END, x) FROM n",
                    false);
        }
        // Run the helper forms here as well: the wrapper only reaches whichever
        // cases the corpus sampler happens to keep, while context setup is replayed
        // on every coverage run.
        executeContextStatement(state, "SELECT docid, matchinfo(egraph_fts4m, 's') FROM egraph_fts4m "
                + "WHERE egraph_fts4m MATCH '\"lcsanchor alpha beta\"'", false);
        executeContextStatement(state, "SELECT docid, matchinfo(egraph_fts4m, 'pcxsal') FROM egraph_fts4m "
                + "WHERE egraph_fts4m MATCH 'alpha OR delta'", false);
        executeContextStatement(state, "SELECT docid, matchinfo(egraph_fts4m, 'y') FROM egraph_fts4m "
                + "WHERE egraph_fts4m MATCH 'alpha NEAR/3 delta'", false);
        executeContextStatement(state, "SELECT docid, offsets(egraph_fts4m) FROM egraph_fts4m "
                + "WHERE egraph_fts4m MATCH '\"alpha beta gamma\"'", false);
        // 'alpha' and 'beta' are adjacent in the body, so NEAR/2 actually matches
        // and the position lists get merged (fts3PoslistMerge). A wider NEAR over
        // tokens that sit further apart matches nothing and merges nothing.
        executeContextStatement(state, "SELECT docid, snippet(egraph_fts4m) FROM egraph_fts4m "
                + "WHERE egraph_fts4m MATCH 'alpha NEAR/2 beta'", false);
        // Descending docid order is the only way into sqlite3Fts3DoclistPrev.
        executeContextStatement(state,
                "SELECT docid FROM egraph_fts4m WHERE egraph_fts4m MATCH 'alpha' ORDER BY docid DESC LIMIT 64",
                false);
        return ok;
    }

    private static boolean setupFts3TokenizeTableContext(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts3tok USING fts3tokenize('unicode61')", true);
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts3tokp USING fts3tokenize('porter')", true);
        // Drop the fts table before the content table it reads from.
        executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fts4c", true);
        executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fts_content_src", true);
        ok &= executeContextStatement(state,
                "CREATE TABLE egraph_fts_content_src(id INTEGER PRIMARY KEY, ca TEXT, cb TEXT)", true);
        executeContextStatement(state,
                "INSERT INTO egraph_fts_content_src(id, ca, cb) VALUES "
                        + "(1, 'alpha one sqlite', 'body one coverage'), "
                        + "(2, 'beta two planner', 'body two variants'), "
                        + "(3, 'gamma three tokenizer', 'body three segment')",
                false);
        // content= without a column list makes fts3 read the column names off the
        // content table itself (fts3ContentColumns).
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE egraph_fts4c USING fts4(content=\"egraph_fts_content_src\")", true);
        if (ok) {
            executeContextStatement(state, "INSERT INTO egraph_fts4c(egraph_fts4c) VALUES('rebuild')", false);
            executeContextStatement(state, "SELECT token, start, \"end\", position FROM egraph_fts3tok "
                    + "WHERE input = 'Hello world foo-bar baz qux'", false);
            executeContextStatement(state,
                    "SELECT token FROM egraph_fts3tokp WHERE input = 'running jumped quickly testing'", false);
            executeContextStatement(state, "SELECT docid FROM egraph_fts4c WHERE egraph_fts4c MATCH 'alpha'", false);
        }
        return ok;
    }

    private static boolean setupFts5TombstoneContext(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fts5cd", true);
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE egraph_fts5cd USING fts5(x, content='', contentless_delete=1)", true);
        if (!ok) {
            return false;
        }
        executeContextStatement(state,
                "WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 128) "
                        + "INSERT INTO egraph_fts5cd(rowid, x) "
                        + "SELECT x, printf('tomb%d alpha common token%d', x, x) FROM n",
                false);
        // Deletes on a contentless_delete table are recorded as tombstones rather
        // than by rewriting the index, which is what the tombstone pages are for.
        executeContextStatement(state, "DELETE FROM egraph_fts5cd WHERE rowid % 3 = 0", false);
        executeContextStatement(state, "DELETE FROM egraph_fts5cd WHERE rowid % 5 = 0", false);
        executeContextStatement(state, "INSERT INTO egraph_fts5cd(egraph_fts5cd) VALUES('merge')", false);
        executeContextStatement(state, "INSERT INTO egraph_fts5cd(egraph_fts5cd) VALUES('optimize')", false);
        executeContextStatement(state, "SELECT rowid FROM egraph_fts5cd WHERE egraph_fts5cd MATCH 'alpha'", false);
        executeContextStatement(state, "SELECT rowid FROM egraph_fts5cd WHERE egraph_fts5cd MATCH 'tomb*'", false);
        return ok;
    }

    private static boolean setupFts5TokenizerVariantContext(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fts5asc", true);
        ok &= executeContextStatement(state, "CREATE VIRTUAL TABLE egraph_fts5asc USING fts5(x, tokenize='ascii')",
                true);
        executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fts5uni", true);
        ok &= executeContextStatement(state, "CREATE VIRTUAL TABLE egraph_fts5uni USING fts5(x, "
                + "tokenize = \"unicode61 tokenchars '-_' separators '@'\")", true);
        executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fts5none", true);
        ok &= executeContextStatement(state, "CREATE VIRTUAL TABLE egraph_fts5none USING fts5(x, y, detail=none)",
                true);
        if (!ok) {
            return false;
        }
        executeContextStatement(state,
                "INSERT INTO egraph_fts5asc(rowid, x) VALUES (1, 'Alpha BETA gamma'), (2, 'alpha delta EPSILON'), "
                        + "(3, 'Gamma zeta alpha')",
                false);
        executeContextStatement(state,
                "INSERT INTO egraph_fts5uni(rowid, x) VALUES (1, 'foo-bar baz@qux'), (2, 'foo_bar alpha'), "
                        + "(3, 'baz alpha foo-bar')",
                false);
        executeContextStatement(state,
                "WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 64) "
                        + "INSERT INTO egraph_fts5none(rowid, x, y) "
                        + "SELECT x, printf('alpha beta w%d', x), printf('gamma w%d', x) FROM n",
                false);
        // A rank= configuration and an ORDER BY rank are what make fts5 resolve a
        // rank function; ORDER BY stays out of the wrapper for the oracle's sake.
        executeContextStatement(state,
                "INSERT INTO egraph_fts5asc(egraph_fts5asc, rank) VALUES('rank', 'bm25(2.0, 1.0)')", false);
        executeContextStatement(state,
                "SELECT rowid, rank FROM egraph_fts5asc WHERE egraph_fts5asc MATCH 'alpha' ORDER BY rank LIMIT 10",
                false);
        executeContextStatement(state, "SELECT rowid FROM egraph_fts5uni WHERE egraph_fts5uni MATCH '\"foo-bar\"'",
                false);
        executeContextStatement(state,
                "SELECT rowid FROM egraph_fts5none WHERE egraph_fts5none MATCH 'alpha AND gamma'", false);
        return ok;
    }

    private static boolean setupSqlSyntaxBatteryContext(SQLite3GlobalState state) {
        // Grammar forms the SQLancer SQLite3 generator never emits, so their
        // yy_reduce actions, VDBE opcodes and sqlite3Pragma branches were dead.
        // DDL/DML can only live here, not in the wrapper.
        boolean ok = executeContextStatement(state, "DROP TABLE IF EXISTS egraph_syn_chi", true);
        ok &= executeContextStatement(state, "DROP TABLE IF EXISTS egraph_syn_chi2", true);
        ok &= executeContextStatement(state, "DROP TABLE IF EXISTS egraph_syn_par", true);
        ok &= executeContextStatement(state, "DROP TABLE IF EXISTS egraph_syn_strict", true);
        ok &= executeContextStatement(state, "DROP TABLE IF EXISTS egraph_syn_def", true);
        ok &= executeContextStatement(state, "DROP TABLE IF EXISTS egraph_syn_wr", true);
        // STRICT drives OP_TypeCheck; the option list after the closing paren is a
        // separate grammar rule again.
        ok &= executeContextStatement(state,
                "CREATE TABLE egraph_syn_strict(a INTEGER PRIMARY KEY, b TEXT NOT NULL, c INT, d ANY) STRICT", true);
        ok &= executeContextStatement(state,
                "CREATE TABLE egraph_syn_wr(a INT, b TEXT, PRIMARY KEY(a)) WITHOUT ROWID, STRICT", true);
        // Every DEFAULT form, a two-argument type name, and both generated-column
        // spellings in one table.
        ok &= executeContextStatement(state,
                "CREATE TABLE egraph_syn_def(a INTEGER PRIMARY KEY, b INT DEFAULT (abs(-5)), c INT DEFAULT +7, "
                        + "d INT DEFAULT -7, e TEXT DEFAULT CURRENT_TIMESTAMP, f NUMERIC(10,2), g AS (b + c), "
                        + "h INT GENERATED ALWAYS AS (b * 2) STORED)",
                true);
        ok &= executeContextStatement(state, "CREATE TABLE egraph_syn_par(k INTEGER PRIMARY KEY, v TEXT)", true);
        ok &= executeContextStatement(state,
                "CREATE TABLE egraph_syn_chi(id INTEGER PRIMARY KEY, k INT, "
                        + "FOREIGN KEY(k) REFERENCES egraph_syn_par(k) MATCH SIMPLE "
                        + "ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE INITIALLY IMMEDIATE)",
                true);
        ok &= executeContextStatement(state,
                "CREATE TABLE egraph_syn_chi2(id INTEGER PRIMARY KEY, k INT REFERENCES egraph_syn_par(k) "
                        + "ON INSERT SET NULL)",
                true);
        if (!ok) {
            return false;
        }
        executeContextStatement(state, "INSERT INTO egraph_syn_def DEFAULT VALUES", false);
        // The DEFAULT CURRENT_TIMESTAMP column definition is what the grammar rule
        // needs, but its value must not differ between context refreshes: the corpus
        // delta encoder compares snapshot statements textually and would rewrite a
        // full snapshot every single time.
        executeContextStatement(state, "UPDATE egraph_syn_def SET e = '2020-01-01 00:00:00'", false);
        executeContextStatement(state,
                "INSERT INTO egraph_syn_par(k, v) VALUES (1, 'p1'), (2, 'p2'), (3, 'p3'), (4, 'p4')", false);
        executeContextStatement(state, "INSERT INTO egraph_syn_chi(id, k) VALUES (1, 1), (2, 2), (3, 3)", false);
        executeContextStatement(state,
                "INSERT INTO egraph_syn_strict VALUES (1, 'a', 2, 3), (2, 'b', 3, 4), (3, 'c', 4, 5)", false);
        // Four upsert spellings: bare DO NOTHING, targeted DO UPDATE, a partial
        // index target, and DO UPDATE with its own WHERE.
        executeContextStatement(state, "INSERT INTO egraph_syn_strict VALUES (1, 'd', 9, 9) ON CONFLICT DO NOTHING",
                false);
        executeContextStatement(state,
                "INSERT INTO egraph_syn_strict VALUES (1, 'e', 8, 8) ON CONFLICT(a) DO UPDATE SET c = excluded.c",
                false);
        executeContextStatement(state,
                "INSERT INTO egraph_syn_strict VALUES (2, 'f', 7, 7) ON CONFLICT(a) WHERE a > 0 DO NOTHING", false);
        executeContextStatement(state, "INSERT INTO egraph_syn_strict VALUES (3, 'g', 6, 6) "
                + "ON CONFLICT(a) DO UPDATE SET c = excluded.c WHERE a > 1", false);
        // Row-value SET, aliased UPDATE/DELETE targets, and RETURNING.
        executeContextStatement(state, "UPDATE egraph_syn_strict SET (b, c) = ('z', 9) WHERE a = 1", false);
        executeContextStatement(state, "UPDATE egraph_syn_strict AS s SET c = c + 1 WHERE s.a = 1", false);
        executeContextStatement(state, "UPDATE main.egraph_syn_strict AS s SET c = c + 1 WHERE s.a = 2", false);
        executeContextStatement(state, "INSERT INTO egraph_syn_par(k, v) VALUES (5, 'p5') RETURNING k, v", false);
        executeContextStatement(state, "UPDATE egraph_syn_par SET v = v || '!' WHERE k = 5 RETURNING k", false);
        executeContextStatement(state, "DELETE FROM egraph_syn_strict AS s WHERE s.a = 3 RETURNING a, b", false);
        // ALTER forms, including renaming a virtual table (OP_VRename).
        executeContextStatement(state, "DROP TABLE IF EXISTS egraph_syn_vt", true);
        executeContextStatement(state, "DROP TABLE IF EXISTS egraph_syn_vt2", true);
        if (executeContextStatement(state, "CREATE VIRTUAL TABLE egraph_syn_vt USING fts5(x)", true)) {
            executeContextStatement(state, "INSERT INTO egraph_syn_vt(rowid, x) VALUES (1, 'alpha beta')", false);
            executeContextStatement(state, "ALTER TABLE egraph_syn_vt RENAME TO egraph_syn_vt2", true);
        }
        executeContextStatement(state, "ALTER TABLE egraph_syn_chi2 DROP COLUMN k", true);
        // ORDER BY ... NULLS LAST/FIRST stays here: the oracle turns order-sensitive
        // the moment ORDER BY shows up anywhere in the compared query text.
        executeContextStatement(state,
                "SELECT a FROM egraph_syn_strict ORDER BY c NULLS LAST, a NULLS FIRST", false);
        executeContextStatement(state, "SELECT a FROM egraph_syn_strict ORDER BY c DESC NULLS FIRST", false);
        executeContextStatement(state,
                "SELECT a, sum(c) OVER w AS s FROM egraph_syn_strict WINDOW w AS (ORDER BY a) ORDER BY a LIMIT 5",
                false);
        executeContextStatement(state, "EXPLAIN SELECT 1", false);
        executeContextStatement(state, "EXPLAIN QUERY PLAN SELECT * FROM egraph_syn_par WHERE k = 1", false);
        // PRAGMA statements can only be issued here; a good part of the
        // sqlite3Pragma switch had never been entered.
        for (String pragma : new String[] { "PRAGMA max_page_count = 1000000", "PRAGMA data_version",
                "PRAGMA collation_list", "PRAGMA database_list", "PRAGMA compile_options", "PRAGMA function_list",
                "PRAGMA module_list", "PRAGMA pragma_list", "PRAGMA table_xinfo(egraph_syn_def)",
                "PRAGMA foreign_key_list(egraph_syn_chi)", "PRAGMA cache_spill = 1", "PRAGMA cell_size_check = 1",
                "PRAGMA reverse_unordered_selects = 1", "PRAGMA reverse_unordered_selects = 0",
                "PRAGMA legacy_alter_table = 1", "PRAGMA legacy_alter_table = 0", "PRAGMA analysis_limit = 400",
                "PRAGMA trusted_schema = 1", "PRAGMA defer_foreign_keys = 1", "PRAGMA defer_foreign_keys = 0",
                "PRAGMA shrink_memory", "PRAGMA optimize" }) {
            executeContextStatement(state, pragma, false);
        }
        return ok;
    }

    private static boolean setupColdDdlTriggerContext(SQLite3GlobalState state) {
        // Two forms the generator never emits. INSTEAD OF is its own grammar rule
        // (trigger_time ::= INSTEAD OF), so the CREATE alone lights up the parser
        // and the DML below lights up the execution path. DROP CONSTRAINT is a
        // 125-line function that had never been entered.
        //
        // Dropping and re-creating rather than CREATE IF NOT EXISTS: ALTER TABLE ...
        // DROP CONSTRAINT removes the constraint for good, so a refreshed context
        // has to rebuild the table or there is nothing left to drop the second time.
        // Every statement is fixed text and the net row state is the same after each
        // refresh, so the corpus delta encoder sees no change to re-serialize.
        executeContextStatement(state, "DROP VIEW IF EXISTS egraph_cold_view", true);
        executeContextStatement(state, "DROP TABLE IF EXISTS egraph_cold_ck", true);
        boolean ok = executeContextStatement(state,
                // Two named CHECK constraints: one gets dropped below, the other
                // stays so the table still carries a constraint at query time.
                // UNIQUE and FOREIGN KEY constraints cannot be dropped at all
                // ("constraint may not be dropped"), so only CHECK reaches the
                // success path.
                "CREATE TABLE egraph_cold_ck(id INTEGER PRIMARY KEY, a INTEGER, "
                        + "CONSTRAINT egraph_cold_c_pos CHECK(a > -100), "
                        + "CONSTRAINT egraph_cold_c_hi CHECK(a < 1000))",
                true);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_cold_ck(id, a) VALUES (1, 10), (2, 20), (3, 30)", false);
        ok &= executeContextStatement(state,
                "CREATE VIEW egraph_cold_view AS SELECT id, a FROM egraph_cold_ck", true);
        ok &= executeContextStatement(state,
                "CREATE TRIGGER egraph_cold_view_ii INSTEAD OF INSERT ON egraph_cold_view "
                        + "BEGIN INSERT INTO egraph_cold_ck(id, a) VALUES (NEW.id, NEW.a); END",
                true);
        ok &= executeContextStatement(state,
                // FOR EACH ROW and a WHEN clause are separate grammar rules again.
                "CREATE TRIGGER egraph_cold_view_iu INSTEAD OF UPDATE OF a ON egraph_cold_view FOR EACH ROW "
                        + "WHEN NEW.a > 0 BEGIN UPDATE egraph_cold_ck SET a = NEW.a WHERE id = OLD.id; END",
                true);
        ok &= executeContextStatement(state,
                "CREATE TRIGGER egraph_cold_view_id INSTEAD OF DELETE ON egraph_cold_view "
                        + "BEGIN DELETE FROM egraph_cold_ck WHERE id = OLD.id; END",
                true);
        if (!ok) {
            return false;
        }
        // Insert, update and delete through the view. Row 4 is added and removed
        // again so the table ends in the same state every refresh; the replay
        // rewrites the INSERT to INSERT OR IGNORE, which an INSTEAD OF trigger
        // accepts unchanged.
        executeContextStatement(state, "INSERT INTO egraph_cold_view(id, a) VALUES (4, 40)", false);
        executeContextStatement(state, "UPDATE egraph_cold_view SET a = 41 WHERE id = 4", false);
        executeContextStatement(state, "DELETE FROM egraph_cold_view WHERE id = 4", false);
        // Last, so the view and the triggers are already in place when the table is
        // rewritten. They survive it: the triggers hang off the view, not the table.
        executeContextStatement(state, "ALTER TABLE egraph_cold_ck DROP CONSTRAINT egraph_cold_c_pos", true);
        return ok;
    }

    private static boolean setupFts5Context(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts USING fts5(title, body, tokenize='porter')", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_fts(rowid, title, body) VALUES "
                        + "(1, 'sqlite query planner', 'coverage driven sql testing for sqlite compiler'), "
                        + "(2, 'compiler pipeline', 'parser resolver optimizer code generator virtual machine'), "
                        + "(3, 'egraph variants', 'equivalent sql variants and metamorphic testing')",
                false);
        if (ok) {
            executeContextStatement(state, "INSERT INTO egraph_fts(egraph_fts, rank) VALUES('rank', 'bm25(10.0, 5.0)')",
                    false);
            executeContextStatement(state, "INSERT INTO egraph_fts(egraph_fts, rank) VALUES('secure-delete', 1)",
                    false);
            executeContextStatement(state,
                    "SELECT rowid, bm25(egraph_fts), highlight(egraph_fts, 0, '[', ']'), "
                            + "snippet(egraph_fts, 1, '<', '>', '...', 8) FROM egraph_fts "
                            + "WHERE egraph_fts MATCH 'sqlite OR compiler OR variants' ORDER BY rank LIMIT 5",
                    false);
            executeContextStatement(state,
                    "SELECT rowid FROM egraph_fts WHERE egraph_fts MATCH '\"sqlite query\" NEAR(testing, 10)' "
                            + "ORDER BY rank LIMIT 5",
                    false);
            executeContextStatement(state, "DELETE FROM egraph_fts WHERE rowid = 2", false);
            executeContextStatement(state, "INSERT INTO egraph_fts(egraph_fts) VALUES('optimize')", false);
            executeContextStatement(state,
                    "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts_vocab USING fts5vocab(egraph_fts, 'row')", true);
            executeContextStatement(state,
                    "SELECT term, doc, cnt FROM egraph_fts_vocab WHERE term >= 'a' ORDER BY term LIMIT 10", false);
        }
        return ok;
    }

    private static boolean setupFts5DeepContext(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts_deep USING fts5(title, body, "
                        + "tokenize='unicode61 remove_diacritics 2', prefix='2 3 4')",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts_deep", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_fts_deep(rowid, title, body) VALUES "
                        + "(1, 'sqlite prefix tokenizer', 'sqlite query planner prefix tokenizer coverage'), "
                        + "(2, 'optimizer merge path', 'prefix posting lists merge optimize rebuild'), "
                        + "(3, 'unicode tokenizer', 'cafe cafe naive jalapeno token folding'), "
                        + "(4, 'near phrase search', 'alpha beta gamma sqlite testing planner variants'), "
                        + "(5, 'deletion tombstone', 'delete optimize rebuild prefix token data'), "
                        + "(6, 'ranking snippets', 'highlight snippet bm25 rank column size detail')",
                false);
        if (ok) {
            executeContextStatement(state,
                    "INSERT INTO egraph_fts_deep(egraph_fts_deep, rank) VALUES('rank', 'bm25(8.0, 3.0)')",
                    false);
            executeContextStatement(state,
                    "SELECT rowid, bm25(egraph_fts_deep), highlight(egraph_fts_deep, 0, '[', ']'), "
                            + "snippet(egraph_fts_deep, 1, '<', '>', '...', 10) "
                            + "FROM egraph_fts_deep WHERE egraph_fts_deep MATCH 'sqlite OR prefix OR tokenizer' "
                            + "ORDER BY rank LIMIT 6",
                    false);
            executeContextStatement(state,
                    "SELECT rowid FROM egraph_fts_deep WHERE egraph_fts_deep MATCH 'sql* OR optim* OR token*' "
                            + "ORDER BY rank LIMIT 6",
                    false);
            executeContextStatement(state,
                    "SELECT rowid FROM egraph_fts_deep WHERE egraph_fts_deep MATCH 'NEAR(sqlite testing, 8)' "
                            + "ORDER BY rank LIMIT 6",
                    false);
            executeContextStatement(state,
                    "DELETE FROM egraph_fts_deep WHERE egraph_fts_deep MATCH 'tombstone OR deletion'", false);
            executeContextStatement(state,
                    "INSERT INTO egraph_fts_deep(rowid, title, body) VALUES "
                            + "(7, 'replacement prefix', 'replacement rows keep prefix tokenizer query nonempty')",
                    false);
            executeContextStatement(state, "INSERT INTO egraph_fts_deep(egraph_fts_deep) VALUES('rebuild')",
                    false);
            executeContextStatement(state, "INSERT INTO egraph_fts_deep(egraph_fts_deep) VALUES('optimize')",
                    false);
            executeContextStatement(state,
                    "INSERT INTO egraph_fts_deep(egraph_fts_deep, rank) VALUES('merge', 8)", false);
            executeContextStatement(state,
                    "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts_deep_vocab "
                            + "USING fts5vocab(egraph_fts_deep, 'instance')",
                    true);
            executeContextStatement(state,
                    "SELECT term, doc, col, offset FROM egraph_fts_deep_vocab "
                            + "WHERE term >= 'a' ORDER BY term, doc LIMIT 24",
                    false);

            boolean triOk = executeContextStatement(state,
                    "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts_trigram USING fts5(content, tokenize='trigram')",
                    true);
            if (triOk) {
                executeContextStatement(state, "DELETE FROM egraph_fts_trigram", false);
                executeContextStatement(state,
                        "INSERT INTO egraph_fts_trigram(rowid, content) VALUES "
                                + "(1, 'alphabet soup beta gamma'), (2, 'sqlite tokenizer trigram coverage'), "
                                + "(3, 'planner variant search space')",
                        false);
                executeContextStatement(state,
                        "SELECT rowid FROM egraph_fts_trigram WHERE egraph_fts_trigram MATCH 'eta' "
                                + "ORDER BY rowid LIMIT 8",
                        false);
            }

            boolean tokenDataOk = executeContextStatement(state,
                    "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts_tokendata "
                            + "USING fts5(body, tokenize='unicode61', tokendata=1)",
                    true);
            if (tokenDataOk) {
                executeContextStatement(state, "DELETE FROM egraph_fts_tokendata", false);
                executeContextStatement(state,
                        "INSERT INTO egraph_fts_tokendata(rowid, body) VALUES "
                                + "(1, 'alpha beta token data'), (2, 'sqlite prefix token data')",
                        false);
                executeContextStatement(state,
                        "SELECT rowid FROM egraph_fts_tokendata WHERE egraph_fts_tokendata MATCH 'token' "
                                + "ORDER BY rank LIMIT 8",
                        false);
            }
        }
        return ok;
    }

    private static boolean setupRtreeContext(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_rtree USING rtree(id, x1, x2, y1, y2)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_rtree", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_rtree VALUES "
                        + "(1, 0.0, 10.0, 0.0, 10.0), "
                        + "(2, 5.0, 15.0, 5.0, 15.0), "
                        + "(3, -5.0, 1.0, -5.0, 1.0)",
                false);
        if (ok) {
            executeContextStatement(state, "UPDATE egraph_rtree SET x1 = x1 - 1.0, x2 = x2 + 1.0 WHERE id = 1",
                    false);
            executeContextStatement(state,
                    "DELETE FROM egraph_rtree WHERE id IN (SELECT id FROM egraph_rtree WHERE x2 < 2.0)", false);
            executeContextStatement(state, "SELECT rtreecheck('egraph_rtree')", false);
        }
        return ok;
    }

    private static boolean setupRtreeDeepContext(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_rtree_deep USING rtree(id, x1, x2, y1, y2)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_rtree_deep", false);
        ok &= executeContextStatement(state,
                "WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 384) "
                        + "INSERT INTO egraph_rtree_deep "
                        + "SELECT x, (x % 32) * 1.0, (x % 32) * 1.0 + 4.0, "
                        + "((x / 32) % 32) * 1.0, ((x / 32) % 32) * 1.0 + 4.0 FROM n",
                false);
        if (ok) {
            executeContextStatement(state,
                    "UPDATE egraph_rtree_deep SET x1 = x1 - 0.25, x2 = x2 + 0.25 WHERE id % 17 = 0",
                    false);
            executeContextStatement(state,
                    "DELETE FROM egraph_rtree_deep WHERE id % 29 = 0 OR (x2 < 3.0 AND y2 < 3.0)", false);
            executeContextStatement(state,
                    "INSERT OR REPLACE INTO egraph_rtree_deep VALUES "
                            + "(10001, 11.0, 13.0, 11.0, 13.0), (10002, -50.0, -40.0, -50.0, -40.0)",
                    false);
            executeContextStatement(state, "SAVEPOINT egraph_rtree_deep_sp", false);
            executeContextStatement(state,
                    "INSERT OR REPLACE INTO egraph_rtree_deep VALUES (10003, 12.0, 14.0, 12.0, 14.0)",
                    false);
            executeContextStatement(state,
                    "UPDATE egraph_rtree_deep SET y1 = y1 - 1.0, y2 = y2 + 1.0 WHERE id = 10001", false);
            executeContextStatement(state, "ROLLBACK TO egraph_rtree_deep_sp", false);
            executeContextStatement(state, "RELEASE egraph_rtree_deep_sp", false);
            executeContextStatement(state,
                    "SELECT id FROM egraph_rtree_deep WHERE x1 <= 12.0 AND x2 >= 12.0 "
                            + "AND y1 <= 12.0 AND y2 >= 12.0 ORDER BY id LIMIT 32",
                    false);
            executeContextStatement(state, "SELECT rtreecheck('egraph_rtree_deep')", false);
        }
        return ok;
    }

    private static boolean setupDbstatContext(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_dbstat USING dbstat(main)",
                true);
        if (ok) {
            executeContextStatement(state,
                    "SELECT name, path, pageno, pagetype, ncell, payload FROM egraph_dbstat "
                            + "WHERE name IS NOT NULL ORDER BY pageno LIMIT 8",
                    false);
            executeContextStatement(state, "PRAGMA page_count", false);
            executeContextStatement(state, "PRAGMA freelist_count", false);
        }
        return ok;
    }

    private static boolean setupViewTriggerFkContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state, "PRAGMA foreign_keys=ON", false);
        try {
            ok &= executeContextStatement(state,
                    "CREATE TABLE IF NOT EXISTS egraph_parent(id INTEGER PRIMARY KEY, name TEXT UNIQUE)", true);
            ok &= executeContextStatement(state,
                    "CREATE TABLE IF NOT EXISTS egraph_child(id INTEGER PRIMARY KEY, parent_id INTEGER REFERENCES "
                            + "egraph_parent(id) ON UPDATE CASCADE ON DELETE SET NULL, value INTEGER CHECK(value BETWEEN "
                            + "0 AND 100))",
                    true);
            ok &= executeContextStatement(state,
                    "CREATE TABLE IF NOT EXISTS egraph_audit(action TEXT, old_value INTEGER, new_value INTEGER)", true);
            ok &= executeContextStatement(state,
                    "CREATE VIEW IF NOT EXISTS egraph_child_view AS SELECT c.id, p.name, c.value FROM egraph_child AS c "
                            + "LEFT JOIN egraph_parent AS p ON p.id = c.parent_id",
                    true);
            ok &= executeContextStatement(state,
                    "CREATE TRIGGER IF NOT EXISTS egraph_child_ai AFTER INSERT ON egraph_child BEGIN INSERT INTO "
                            + "egraph_audit VALUES('insert', NULL, NEW.value); END",
                    true);
            ok &= executeContextStatement(state,
                    "CREATE TRIGGER IF NOT EXISTS egraph_child_au AFTER UPDATE OF value ON egraph_child BEGIN INSERT INTO "
                            + "egraph_audit VALUES('update', OLD.value, NEW.value); END",
                    true);
            ok &= executeContextStatement(state,
                    "INSERT OR IGNORE INTO egraph_parent(id, name) VALUES (1, 'p1'), (2, 'p2')", false);
            ok &= executeContextStatement(state,
                    "INSERT OR IGNORE INTO egraph_child(id, parent_id, value) VALUES (10, 1, 20), (11, 2, 30)", false);
            ok &= executeContextStatement(state, "UPDATE egraph_parent SET id = 3 WHERE id = 1", false);
            ok &= executeContextStatement(state, "UPDATE egraph_child SET value = value + 1 WHERE value < 100", false);
            return ok;
        } finally {
            executeContextStatement(state, "PRAGMA foreign_keys=OFF", false);
        }
    }

    private static boolean setupAnalyzeIndexContext(SQLite3GlobalState state, SQLite3Table table,
            SQLite3Column column) {
        if (!hasUsableIdentifier(table.getName()) || !hasUsableIdentifier(column)) {
            return false;
        }
        if (table.isVirtual()) {
            // Same reason as addMultiIndexOrIndexes: no CREATE INDEX on virtual tables.
            return false;
        }
        String tableName = quoteIdentifier(table.getName());
        String columnName = quoteIdentifier(column.getName());
        String indexName = quoteIdentifier(getEGraphContextIndexName(table.getName(), column.getName()));
        boolean ok = executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS " + indexName + " ON " + tableName + "(" + columnName + ")",
                true);
        executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS " + quoteIdentifier(getEGraphContextIndexName(table.getName(), column.getName()) + "_partial")
                        + " ON " + tableName + "(" + columnName + ") WHERE " + columnName + " IS NOT NULL",
                true);
        executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS " + quoteIdentifier(getEGraphContextIndexName(table.getName(), column.getName()) + "_expr")
                        + " ON " + tableName + "(((" + columnName + ") + 1))",
                true);
        executeContextStatement(state, "ANALYZE " + tableName, false);
        executeContextStatement(state, "REINDEX " + indexName, false);
        return ok;
    }

    private static boolean setupTxWalVacuumContext(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_tx_probe(id INTEGER PRIMARY KEY, value INTEGER NOT NULL)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_tx_probe", false);
        executeContextStatement(state, "PRAGMA journal_mode=WAL", false);
        executeContextStatement(state, "PRAGMA synchronous=NORMAL", false);
        executeContextStatement(state, "PRAGMA wal_autocheckpoint=64", false);

        boolean savepoint = executeContextStatement(state, "SAVEPOINT egraph_tx_probe_sp", false);
        if (savepoint) {
            executeContextStatement(state, "INSERT INTO egraph_tx_probe(id, value) VALUES (1, 10), (2, 20)", false);
            executeContextStatement(state, "UPDATE egraph_tx_probe SET value = value + 1 WHERE id = 1", false);
            executeContextStatement(state, "ROLLBACK TO egraph_tx_probe_sp", false);
            executeContextStatement(state, "RELEASE egraph_tx_probe_sp", false);
        }

        ok &= executeContextStatement(state,
                "INSERT OR REPLACE INTO egraph_tx_probe(id, value) VALUES (1, 10), (2, 20)", false);
        executeContextStatement(state, "PRAGMA wal_checkpoint(PASSIVE)", false);
        executeContextStatement(state, "PRAGMA quick_check", false);
        if (TX_CONTEXT_COUNT.incrementAndGet() % 512 == 0) {
            executeContextStatement(state, "VACUUM", false);
        }
        return ok;
    }

    private static boolean setupAutoVacuumIntegrityContext(SQLite3GlobalState state) {
        int count = AUTO_VACUUM_INTEGRITY_CONTEXT_COUNT.incrementAndGet();
        executeContextStatement(state, "PRAGMA auto_vacuum=INCREMENTAL", false);
        executeContextStatement(state, "PRAGMA page_size=512", false);
        if (count % 32 == 1) {
            executeContextStatement(state, "VACUUM", false);
        }

        boolean ok = true;
        ok &= executeContextStatement(state, "DROP TABLE IF EXISTS egraph_autovac_probe", true);
        ok &= executeContextStatement(state,
                "CREATE TABLE egraph_autovac_probe(id INTEGER PRIMARY KEY, k INTEGER NOT NULL, "
                        + "payload TEXT, extra BLOB)",
                true);
        ok &= executeContextStatement(state,
                "WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 192) "
                        + "INSERT INTO egraph_autovac_probe(id, k, payload, extra) "
                        // Deterministic 128-char hex instead of hex(randomblob(64)): the payload
                        // has to be byte-identical across context refreshes, otherwise the corpus
                        // delta encoder sees a change every time and re-serialises all 192 rows
                        // into every snapshot. Same reasoning as SORTER_STRESS_CONTEXT.
                        + "SELECT x, x % 41, printf('autovac-%04d-%s', x, printf('%016X%016X%016X%016X%016X%016X%016X%016X', x, x * 7919, x * 104729, x * 1299709, x * 15485863, x * 179424673, x * 32452843, x * 49979687)), "
                        + "zeroblob(1400 + (x % 7) * 200) FROM n",
                false);
        executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS egraph_autovac_k_payload ON egraph_autovac_probe(k, payload)",
                true);
        executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS egraph_autovac_payload_len "
                        + "ON egraph_autovac_probe((length(payload))) WHERE k >= 0",
                true);
        executeContextStatement(state, "DELETE FROM egraph_autovac_probe WHERE id % 3 = 0", false);
        executeContextStatement(state,
                "UPDATE egraph_autovac_probe SET extra = zeroblob(2048) WHERE id % 11 = 0", false);
        executeContextStatement(state, "PRAGMA freelist_count", false);
        executeContextStatement(state, "PRAGMA incremental_vacuum(8)", false);
        executeContextStatement(state, "PRAGMA integrity_check", false);
        executeContextStatement(state, "PRAGMA quick_check", false);
        if (count % 16 == 0) {
            executeContextStatement(state, "VACUUM", false);
        }
        executeContextStatement(state, "PRAGMA page_count", false);
        return ok;
    }

    private static boolean setupAttachVacuumWalContext(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_attach_probe(id INTEGER PRIMARY KEY, value INTEGER NOT NULL, "
                        + "note TEXT)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_attach_probe", false);
        ok &= executeContextStatement(state,
                "INSERT OR REPLACE INTO egraph_attach_probe(id, value, note) VALUES "
                        + "(1, 10, 'main-a'), (2, 20, 'main-b'), (3, 30, 'main-c')",
                false);

        executeContextStatement(state, "DETACH egraph_aux", false);
        executeContextStatement(state, "PRAGMA journal_mode=WAL", false);
        executeContextStatement(state, "PRAGMA synchronous=NORMAL", false);
        boolean attached = executeContextStatement(state, "ATTACH ':memory:' AS egraph_aux", false);
        if (attached) {
            executeContextStatement(state, "CREATE TABLE egraph_aux.t(id INTEGER PRIMARY KEY, v TEXT)", false);
            executeContextStatement(state,
                    "INSERT INTO egraph_aux.t(v) VALUES('aux-a'), ('aux-b'), ('aux-c')", false);
            executeContextStatement(state, "SELECT count(*), max(v) FROM egraph_aux.t WHERE id > 0", false);
            executeContextStatement(state, "DETACH egraph_aux", false);
        }
        executeContextStatement(state, "PRAGMA wal_checkpoint(FULL)", false);
        executeContextStatement(state, "PRAGMA optimize", false);
        if (ATTACH_CONTEXT_COUNT.incrementAndGet() % 256 == 0) {
            executeContextStatement(state, "VACUUM", false);
        }
        executeContextStatement(state, "PRAGMA journal_mode=DELETE", false);
        return ok;
    }

    private static boolean setupAlterIndexAnalyzeContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state, "DROP TABLE IF EXISTS egraph_alter_probe", true);
        ok &= executeContextStatement(state,
                "CREATE TABLE egraph_alter_probe(id INTEGER PRIMARY KEY, value INTEGER NOT NULL DEFAULT 0, "
                        + "note TEXT UNIQUE)",
                true);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_alter_probe(id, value, note) VALUES (1, 10, 'alpha'), (2, 20, 'beta')", false);
        ok &= executeContextStatement(state,
                "ALTER TABLE egraph_alter_probe ADD COLUMN extra TEXT DEFAULT 'x'", true);
        ok &= executeContextStatement(state,
                "CREATE INDEX egraph_alter_value_idx ON egraph_alter_probe(value) WHERE value >= 0", true);
        executeContextStatement(state,
                "CREATE INDEX egraph_alter_expr_idx ON egraph_alter_probe((value + length(note)))", true);
        executeContextStatement(state,
                "INSERT INTO egraph_alter_probe(id, value, note, extra) VALUES (3, 30, 'alpha', 'z') "
                        + "ON CONFLICT(note) DO UPDATE SET value = excluded.value + 1 RETURNING id, value",
                false);
        executeContextStatement(state,
                "UPDATE egraph_alter_probe SET value = value + 1 WHERE value < 40 RETURNING id, value", false);
        executeContextStatement(state, "REINDEX egraph_alter_value_idx", false);
        executeContextStatement(state, "ANALYZE egraph_alter_probe", false);
        executeContextStatement(state,
                "SELECT id, value, extra FROM egraph_alter_probe INDEXED BY egraph_alter_value_idx "
                        + "WHERE value >= 0 ORDER BY value LIMIT 4",
                false);
        executeContextStatement(state, "DROP TABLE IF EXISTS egraph_rename_probe", true);
        executeContextStatement(state,
                "CREATE TABLE egraph_rename_probe(id INTEGER PRIMARY KEY, a INTEGER, b TEXT, "
                        + "c INTEGER GENERATED ALWAYS AS (a + length(b)) VIRTUAL, d TEXT DEFAULT 'x')",
                true);
        executeContextStatement(state,
                "CREATE INDEX egraph_rename_probe_expr ON egraph_rename_probe((a + length(b))) WHERE a IS NOT NULL",
                true);
        executeContextStatement(state,
                "CREATE VIEW egraph_rename_probe_view AS SELECT id, a, b, c, d FROM egraph_rename_probe WHERE a >= 0",
                true);
        executeContextStatement(state,
                "CREATE TRIGGER egraph_rename_probe_ai AFTER INSERT ON egraph_rename_probe BEGIN "
                        + "UPDATE egraph_rename_probe SET d = 'seen' WHERE id = NEW.id; END",
                true);
        executeContextStatement(state,
                "INSERT INTO egraph_rename_probe(id, a, b) VALUES (1, 10, 'alpha'), (2, 20, 'beta')", false);
        executeContextStatement(state, "ALTER TABLE egraph_rename_probe RENAME COLUMN b TO renamed_b", true);
        executeContextStatement(state, "ALTER TABLE egraph_rename_probe DROP COLUMN d", true);
        executeContextStatement(state, "ALTER TABLE egraph_rename_probe RENAME TO egraph_renamed_probe", true);
        executeContextStatement(state,
                "SELECT id, a, renamed_b, c FROM egraph_renamed_probe WHERE a >= 0 ORDER BY id", false);
        return ok;
    }

    private static boolean setupSelectWhereStressContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_plan_probe(id INTEGER PRIMARY KEY, v INTEGER, w INTEGER, tag TEXT)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_plan_probe", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_plan_probe(id, v, w, tag) VALUES "
                        + "(1, 0, 10, 'alpha'), (2, 1, 20, 'beta'), (3, 2, 20, 'gamma'), "
                        + "(4, 3, 30, 'delta'), (5, 4, NULL, 'epsilon'), (6, 5, 40, 'zeta')",
                false);
        executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS egraph_plan_v_idx ON egraph_plan_probe(v)", true);
        executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS egraph_plan_w_tag_idx ON egraph_plan_probe(w, tag)", true);
        executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS egraph_plan_partial_idx ON egraph_plan_probe(v) WHERE w IS NOT NULL",
                true);
        executeContextStatement(state, "ANALYZE egraph_plan_probe", false);
        executeContextStatement(state,
                "SELECT p1.id, p2.tag FROM egraph_plan_probe AS p1 "
                        + "LEFT JOIN egraph_plan_probe AS p2 ON p2.w = p1.w "
                        + "WHERE (p1.v = 1 OR p1.w = 20 OR p1.tag IN ('alpha', 'beta')) "
                        + "AND p1.id IN (SELECT id FROM egraph_plan_probe WHERE v BETWEEN 0 AND 4) "
                        + "ORDER BY p1.w, p2.tag LIMIT 8",
                false);
        executeContextStatement(state,
                "SELECT p1.id, p2.tag FROM egraph_plan_probe AS p1 "
                        + "RIGHT JOIN egraph_plan_probe AS p2 ON p2.w = p1.w "
                        + "WHERE p2.v IN (SELECT v FROM egraph_plan_probe WHERE w IS NOT NULL) "
                        + "ORDER BY p2.w, p1.id LIMIT 8",
                false);
        executeContextStatement(state,
                "SELECT * FROM (SELECT v, w FROM egraph_plan_probe WHERE v < 4 "
                        + "UNION ALL SELECT v, w FROM egraph_plan_probe WHERE w >= 20) "
                        + "ORDER BY w DESC, v ASC LIMIT 12",
                false);
        executeContextStatement(state,
                "SELECT v, count(*), max(w) FROM egraph_plan_probe "
                        + "WHERE w IS NOT NULL GROUP BY v HAVING count(*) >= 1 ORDER BY max(w) DESC",
                false);
        return ok;
    }

    private static boolean setupExprStressContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_expr_probe(id INTEGER PRIMARY KEY, n INTEGER, r REAL, txt TEXT)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_expr_probe", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_expr_probe(id, n, r, txt) VALUES "
                        + "(1, NULL, NULL, ''), (2, -1, -1.5, '42'), (3, 0, 0.0, 'alpha'), "
                        + "(4, 1, 1.25, 'Beta'), (5, 7, 3.5, 'text'), (6, 42, 9.0, 'suffix')",
                false);
        executeContextStatement(state,
                "SELECT id, typeof(n), typeof(r), typeof(txt), "
                        + "CASE WHEN n IS NULL THEN 'nil' WHEN n BETWEEN -1 AND 1 THEN 'small' ELSE 'large' END, "
                        + "coalesce(nullif(txt, ''), printf('n=%d', n)), abs(n), round(r, 1), lower(txt), "
                        + "substr(txt || '-x', 1, 4), hex(CAST(txt AS blob)) "
                        + "FROM egraph_expr_probe "
                        + "WHERE (n IS NULL OR n IN (-1, 0, 1, 42)) "
                        + "AND ((CAST(txt AS NUMERIC) >= 0) OR txt GLOB '*a*')",
                false);
        executeContextStatement(state,
                "SELECT id FROM egraph_expr_probe "
                        + "WHERE ((n + 1) * (n - 1)) IS NOT NULL "
                        + "OR (txt COLLATE NOCASE LIKE 'b%' ESCAPE '\\') "
                        + "OR (r NOT BETWEEN -2.0 AND 2.0)",
                false);
        executeContextStatement(state,
                "SELECT json_valid(jsonb('{\"a\":[1,2],\"b\":\"x\"}')), "
                        + "json_extract(jsonb('{\"a\":[1,2]}'), '$.a[0]'), "
                        + "json_pretty(jsonb('{\"a\":{\"b\":1}}'))",
                false);
        executeContextStatement(state,
                "SELECT json_valid('{a:1, b:[2,3,],}', 2), "
                        + "json_extract('{\"escaped\":\"line\\nfeed\"}', '$.escaped'), "
                        + "timediff('2024-02-29 12:34:56', '2023-01-01 00:00:00')",
                false);
        return ok;
    }

    private static boolean setupWindowStressContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_window_probe(id INTEGER PRIMARY KEY, grp INTEGER, v INTEGER)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_window_probe", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_window_probe(id, grp, v) VALUES "
                        + "(1, 0, 10), (2, 0, 20), (3, 0, 20), (4, 1, 5), "
                        + "(5, 1, 15), (6, 1, 25), (7, 2, 30)",
                false);
        executeContextStatement(state,
                "SELECT id, grp, v, "
                        + "row_number() OVER (PARTITION BY grp ORDER BY v, id) AS rn, "
                        + "rank() OVER (PARTITION BY grp ORDER BY v) AS rnk, "
                        + "dense_rank() OVER (PARTITION BY grp ORDER BY v) AS drnk, "
                        + "sum(v) OVER (PARTITION BY grp ORDER BY id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS win_sum, "
                        + "first_value(v) OVER (PARTITION BY grp ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS first_v "
                        + "FROM egraph_window_probe ORDER BY grp, rn",
                false);
        executeContextStatement(state,
                "SELECT grp, avg(v) FILTER (WHERE v >= 10) OVER (PARTITION BY grp) "
                        + "FROM egraph_window_probe ORDER BY grp, id",
                false);
        executeContextStatement(state,
                "SELECT id, v, sum(v) OVER (ORDER BY v RANGE BETWEEN 10 PRECEDING AND 10 FOLLOWING), "
                        + "nth_value(v, 2) OVER (PARTITION BY grp ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING "
                        + "AND UNBOUNDED FOLLOWING) FROM egraph_window_probe ORDER BY grp, v",
                false);
        return ok;
    }

    private static boolean setupResolveStressContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_resolve_base(id INTEGER PRIMARY KEY, value INTEGER, name TEXT)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_resolve_base", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_resolve_base(id, value, name) VALUES "
                        + "(1, 10, 'a'), (2, 20, 'b'), (3, 30, 'c')",
                false);
        ok &= executeContextStatement(state,
                "CREATE VIEW IF NOT EXISTS egraph_resolve_view AS "
                        + "SELECT id AS alias_id, value AS alias_value, name AS alias_name "
                        + "FROM egraph_resolve_base",
                true);
        executeContextStatement(state,
                "WITH renamed(alias_id, alias_value) AS ("
                        + "SELECT alias_id, alias_value FROM egraph_resolve_view WHERE alias_value >= 10"
                        + ") SELECT r.alias_id, r.alias_value, "
                        + "(SELECT max(v.alias_value) FROM egraph_resolve_view AS v WHERE v.alias_id <= r.alias_id) AS max_seen "
                        + "FROM renamed AS r WHERE r.alias_value IN (SELECT alias_value FROM egraph_resolve_view) "
                        + "ORDER BY r.alias_id",
                false);
        executeContextStatement(state,
                "SELECT output_name, output_value FROM ("
                        + "SELECT alias_name AS output_name, alias_value + 1 AS output_value "
                        + "FROM egraph_resolve_view) AS resolved_aliases "
                        + "WHERE output_value > 0 ORDER BY output_name",
                false);
        return ok;
    }

    private static boolean setupFts5VariantConfigContext(SQLite3GlobalState state) {
        // Building five differently-configured FTS5 indexes is far too expensive to
        // repeat per check - doing so dropped throughput from ~2500 to 24 checks per
        // three minutes. The sentinel table doubles as the existence test: its
        // CREATE only succeeds the first time in a given database.
        if (!executeContextStatement(state, "CREATE TABLE egraph_fts5_variant_built(x)", true)) {
            return true;
        }
        boolean ok = true;
        String documents = "WITH RECURSIVE d(i) AS (VALUES(1) UNION ALL SELECT i + 1 FROM d WHERE i < 120) "
                + "SELECT i, printf('t%d common', i), "
                + "printf('body%d word%d common phrase here alpha%d', i, i, i) FROM d";

        // contentless_delete keeps tombstones instead of rewriting segments, so
        // deleting rows is what exercises the tombstone code.
        // Rebuilt every time on purpose: a contentless index has no DELETE-all, and
        // re-inserting the same rowids would append more index entries, so a setup
        // that ran twice in one check made the original and the variant see
        // different match counts - a false mismatch.
        executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fts5_cd", false);
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE egraph_fts5_cd USING fts5(body, content='', contentless_delete=1)", true);
        ok &= executeContextStatement(state,
                "WITH RECURSIVE d(i) AS (VALUES(1) UNION ALL SELECT i + 1 FROM d WHERE i < 120) "
                        + "INSERT INTO egraph_fts5_cd(rowid, body) SELECT i, "
                        + "printf('doc%d common alpha%d beta%d token%d', i, i, i, i) FROM d",
                false);
        executeContextStatement(state, "DELETE FROM egraph_fts5_cd WHERE rowid % 3 = 0", false);
        executeContextStatement(state, "INSERT INTO egraph_fts5_cd(egraph_fts5_cd) VALUES('optimize')", false);
        executeContextStatement(state, "DELETE FROM egraph_fts5_cd WHERE rowid % 5 = 0", false);
        executeContextStatement(state, "INSERT INTO egraph_fts5_cd(egraph_fts5_cd, rank) VALUES('merge', 2)", false);

        // detail=none stores no position lists, which is a separate iterator
        // implementation and rejects phrase queries outright.
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts5_none USING fts5(a, b, detail=none)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts5_none", false);
        ok &= executeContextStatement(state, "INSERT INTO egraph_fts5_none(rowid, a, b) " + documents, false);

        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts5_col USING fts5(a, b, detail=column)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts5_col", false);
        ok &= executeContextStatement(state, "INSERT INTO egraph_fts5_col(rowid, a, b) " + documents, false);

        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts5_ascii USING fts5(a, b, tokenize=ascii)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts5_ascii", false);
        ok &= executeContextStatement(state, "INSERT INTO egraph_fts5_ascii(rowid, a, b) " + documents, false);

        // An external content table means the index holds no copy of the text and
        // has to read through to the source table.
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_fts5_src(id INTEGER PRIMARY KEY, a TEXT, b TEXT)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts5_src", false);
        ok &= executeContextStatement(state, "INSERT INTO egraph_fts5_src(id, a, b) " + documents, false);
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts5_ext USING fts5(a, b, "
                        + "content='egraph_fts5_src', content_rowid='id')",
                true);
        executeContextStatement(state, "INSERT INTO egraph_fts5_ext(egraph_fts5_ext) VALUES('rebuild')", false);
        return ok;
    }

    private static boolean setupFts5DeepQueryContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts5d USING fts5(title, body, "
                        + "tokenize=\"porter unicode61 remove_diacritics 2\", prefix='2 3 4', columnsize=1, "
                        + "detail=full)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts5d", false);
        // Twenty-odd distinct terms per document, so the index gets large doclists
        // and multi-level structures rather than one tiny segment. Deterministic
        // text: the wrapper compares match counts.
        ok &= executeContextStatement(state,
                "WITH RECURSIVE d(i) AS (VALUES(1) UNION ALL SELECT i + 1 FROM d WHERE i < 128) "
                        + "INSERT INTO egraph_fts5d(rowid, title, body) SELECT i, "
                        + "printf('title%d sqlite coverage doc%d', i, i), printf('body%d term%d alpha%d beta%d "
                        + "gamma%d delta%d epsilon%d zeta%d eta%d theta%d iota%d kappa%d lambda%d mu%d nu%d xi%d "
                        + "omicron%d pi%d rho%d sigma%d tau%d sqlite query planner tokenizer segment doclist merge "
                        + "prefix', i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i) FROM d",
                false);
        // Segment maintenance plus deletes, which is what leaves tombstones behind.
        executeContextStatement(state, "INSERT INTO egraph_fts5d(egraph_fts5d, rank) VALUES('merge', 2)", false);
        executeContextStatement(state, "INSERT INTO egraph_fts5d(egraph_fts5d) VALUES('optimize')", false);
        executeContextStatement(state, "DELETE FROM egraph_fts5d WHERE rowid % 7 = 0", false);
        executeContextStatement(state, "INSERT INTO egraph_fts5d(egraph_fts5d) VALUES('rebuild')", false);
        executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts5d_v USING fts5vocab(egraph_fts5d, 'instance')", true);
        executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts5d_vr USING fts5vocab(egraph_fts5d, 'row')", true);
        executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts5d_vc USING fts5vocab(egraph_fts5d, 'col')", true);
        return ok;
    }

    private static boolean setupFts4DeepSegmentContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts4d USING fts4(title, body, tokenize=simple, "
                        + "matchinfo=fts3)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts4d", false);
        // Four batches rather than one: each batch flushes its own segment, which
        // is what gives the incremental merge something to do. A single bulk load
        // followed by 'rebuild' produces one optimal segment and merges become
        // no-ops.
        for (int batch = 0; batch < 4; batch++) {
            int from = batch * 32 + 1;
            int to = from + 31;
            ok &= executeContextStatement(state,
                    "WITH RECURSIVE d(i) AS (VALUES(" + from + ") UNION ALL SELECT i + 1 FROM d WHERE i < " + to
                            + ") INSERT INTO egraph_fts4d(docid, title, body) SELECT i, printf('t%d sqlite', i), "
                            + "printf('b%d w%d x%d y%d z%d p%d q%d r%d s%d u%d v%d common sqlite planner segment "
                            + "doclist merge deferred phrase', i, i, i, i, i, i, i, i, i, i, i) FROM d",
                    false);
        }
        executeContextStatement(state, "INSERT INTO egraph_fts4d(egraph_fts4d) VALUES('merge=2,2')", false);
        executeContextStatement(state, "INSERT INTO egraph_fts4d(egraph_fts4d) VALUES('merge=4,3')", false);
        executeContextStatement(state, "INSERT INTO egraph_fts4d(egraph_fts4d) VALUES('automerge=2')", false);
        executeContextStatement(state, "INSERT INTO egraph_fts4d(egraph_fts4d) VALUES('integrity-check')", false);
        executeContextStatement(state, "INSERT INTO egraph_fts4d(egraph_fts4d) VALUES('rebuild')", false);
        // The tokenizer itself as a table-valued function.
        executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts4_tok USING fts3tokenize('simple')", true);
        executeContextStatement(state,
                "SELECT count(*) FROM egraph_fts4_tok WHERE input = 'hello world tokenize test'", false);
        return ok;
    }

    private static boolean setupFts4Context(SQLite3GlobalState state) {
        boolean ok = true;
        // Three tokenizers so the tokenizer implementations are all reachable.
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts4 USING fts4(title, body, tokenize=porter)", true);
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts4_uni USING fts4(title, body, "
                        + "tokenize=unicode61 \"remove_diacritics=2\")",
                true);
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts3 USING fts3(title, body, tokenize=simple)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts4", false);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts4_uni", false);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts3", false);
        // Deterministic documents: the wrapper compares match counts, and random
        // text would also make every context refresh look like a data change to
        // the delta-encoded snapshot.
        String documents = "WITH RECURSIVE d(i) AS (VALUES(1) UNION ALL SELECT i + 1 FROM d WHERE i < 60) "
                + "SELECT i, printf('title %d sqlite coverage', i), "
                + "printf('body %d sqlite query planner variants tokenizer prefix merge segment doclist %s', i, "
                + "CASE i % 3 WHEN 0 THEN 'alpha beta gamma' WHEN 1 THEN 'delta epsilon zeta' "
                + "ELSE 'eta theta iota' END) FROM d";
        ok &= executeContextStatement(state, "INSERT INTO egraph_fts4(docid, title, body) " + documents, false);
        ok &= executeContextStatement(state, "INSERT INTO egraph_fts4_uni(docid, title, body) " + documents, false);
        ok &= executeContextStatement(state, "INSERT INTO egraph_fts3(docid, title, body) " + documents, false);
        // Segment maintenance paths.
        executeContextStatement(state, "INSERT INTO egraph_fts4(egraph_fts4) VALUES('optimize')", false);
        executeContextStatement(state, "INSERT INTO egraph_fts4_uni(egraph_fts4_uni) VALUES('merge=2,2')", false);
        executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts4_aux USING fts4aux(egraph_fts4)", true);
        return ok;
    }

    private static boolean setupStarJoinContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_star_fact(id INTEGER PRIMARY KEY, d1 INTEGER, d2 INTEGER, "
                        + "v INTEGER)",
                true);
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_star_dim1(k INTEGER PRIMARY KEY, label TEXT)", true);
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_star_dim2(k INTEGER PRIMARY KEY, label TEXT)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_star_fact", false);
        ok &= executeContextStatement(state, "DELETE FROM egraph_star_dim1", false);
        ok &= executeContextStatement(state, "DELETE FROM egraph_star_dim2", false);
        // 128 rows is enough for the planner to choose Bloom filters here, and it
        // stays within corpus.maxRowsPerTable so the replay keeps the whole table.
        ok &= executeContextStatement(state,
                "WITH RECURSIVE f(i) AS (VALUES(1) UNION ALL SELECT i + 1 FROM f WHERE i < 128) "
                        + "INSERT INTO egraph_star_fact(id, d1, d2, v) SELECT i, i % 11, i % 13, i FROM f",
                false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_star_dim1(k, label) SELECT DISTINCT d1, 'd1-' || d1 FROM egraph_star_fact",
                false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_star_dim2(k, label) SELECT DISTINCT d2, 'd2-' || d2 FROM egraph_star_fact",
                false);
        executeContextStatement(state, "ANALYZE", false);
        return ok;
    }

    private static boolean setupOrProbeContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_or_probe(id INTEGER PRIMARY KEY, a INTEGER, b INTEGER, pad TEXT)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_or_probe", false);
        ok &= executeContextStatement(state,
                "WITH RECURSIVE r(i) AS (VALUES(1) UNION ALL SELECT i + 1 FROM r WHERE i < 128) "
                        + "INSERT INTO egraph_or_probe(id, a, b, pad) SELECT i, i % 17, i % 23, 'pad' || i FROM r",
                false);
        ok &= executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS egraph_or_a ON egraph_or_probe(a)", true);
        ok &= executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS egraph_or_b ON egraph_or_probe(b)", true);
        executeContextStatement(state, "ANALYZE", false);
        // Statement forms that cannot appear in a judged SELECT wrapper, so they
        // run here for coverage only: CREATE TABLE AS SELECT (createTableStmt),
        // UPDATE ... FROM (updateFromSelect) and a vector assignment
        // (sqlite3ExprListAppendVector).
        executeContextStatement(state, "DROP TABLE IF EXISTS egraph_or_cts", false);
        executeContextStatement(state,
                "CREATE TABLE egraph_or_cts AS SELECT a, b, pad FROM egraph_or_probe LIMIT 20", true);
        executeContextStatement(state,
                "UPDATE egraph_or_cts SET pad = s.pad FROM egraph_or_probe AS s WHERE egraph_or_cts.a = s.a", false);
        executeContextStatement(state, "UPDATE egraph_or_cts SET (a, b) = (SELECT 1, 2) WHERE a = 3", false);
        executeContextStatement(state, "UPDATE egraph_or_cts SET (a, b) = (b, a) WHERE a > 10", false);
        return ok;
    }

    private static boolean setupRowValueContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_rowvalue_probe("
                        + "id INTEGER PRIMARY KEY, a INTEGER, b TEXT, c INTEGER, d TEXT)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_rowvalue_probe", false);
        // NULLs on both sides of the comparisons on purpose: row-value NULL
        // handling is where the three-valued logic is easiest to get wrong.
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_rowvalue_probe(id, a, b, c, d) VALUES "
                        + "(1, 1, 'x', 1, 'x'), (2, 2, 'y', 2, 'z'), (3, 3, NULL, 3, NULL), "
                        + "(4, 4, 'z', NULL, 'z'), (5, NULL, 'w', 5, 'w'), (6, 6, 'a', 6, 'a'), "
                        + "(7, 7, 'b', 7, 'B'), (8, 9, 'zzz', 9, 'zzz')",
                false);
        ok &= executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS egraph_rowvalue_probe_ab ON egraph_rowvalue_probe(a, b)", true);
        return ok;
    }

    private static boolean setupSorterStressContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_sorter_probe(id INTEGER PRIMARY KEY, bucket INTEGER, payload TEXT)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_sorter_probe", false);
        ok &= executeContextStatement(state,
                // Wide rows, not many rows. The sorter only writes a PMA once it
                // holds more than SQLITE_DEFAULT_PMA_SIZE (250 pages, ~1 MB), and
                // cache_size cannot lower that floor, so bytes are what matter:
                // 120 rows x ~1.2 KB x the joined inner rows clears 1 MB.
                // Row count stays under corpus.maxRowsPerTable (128) so the
                // replay used for coverage keeps the full table, and the payload
                // is deterministic (no randomblob) so re-creating the context
                // produces byte-identical rows - otherwise every context refresh
                // would look like a change and be re-serialized into every
                // delta-encoded snapshot.
                "WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 120) "
                        + "INSERT INTO egraph_sorter_probe(id, bucket, payload) "
                        + "SELECT x, x % 9, printf('payload-%04d-%s', x, hex(zeroblob(600))) FROM n",
                false);
        executeContextStatement(state, "PRAGMA temp_store=FILE", false);
        // A small page cache and background sorter threads push the sort further
        // down the external merge path: measured on this build, threads=4 takes
        // vdbeSorterFlushPMA from 36% to 86% of its lines. SQLite must return the
        // same rows under any cache size or thread count, so neither setting can
        // turn a correct result into a mismatch.
        executeContextStatement(state, "PRAGMA cache_size=-64", false);
        executeContextStatement(state, "PRAGMA threads=4", false);
        executeContextStatement(state,
                "SELECT bucket, count(*), min(payload), max(payload), group_concat(id, ',') "
                        + "FROM egraph_sorter_probe GROUP BY bucket "
                        + "ORDER BY count(*) DESC, max(payload) COLLATE NOCASE DESC LIMIT 12",
                false);
        executeContextStatement(state,
                "SELECT id, bucket, payload FROM egraph_sorter_probe "
                        + "ORDER BY payload COLLATE NOCASE DESC, bucket ASC, id DESC LIMIT 32 OFFSET 3",
                false);
        executeContextStatement(state, "PRAGMA temp_store=MEMORY", false);
        return ok;
    }

    private static boolean setupJoinOptimizerContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_join_left(id INTEGER PRIMARY KEY, k INTEGER, v INTEGER, tag TEXT)",
                true);
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_join_right(id INTEGER PRIMARY KEY, k INTEGER, v INTEGER, flag INTEGER)",
                true);
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_join_dim(k INTEGER PRIMARY KEY, label TEXT)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_join_left", false);
        ok &= executeContextStatement(state, "DELETE FROM egraph_join_right", false);
        ok &= executeContextStatement(state, "DELETE FROM egraph_join_dim", false);
        ok &= executeContextStatement(state,
                "WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 96) "
                        + "INSERT INTO egraph_join_left(id, k, v, tag) "
                        + "SELECT x, x % 16, x * 3, printf('L%03d', x) FROM n",
                false);
        ok &= executeContextStatement(state,
                "WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 128) "
                        + "INSERT INTO egraph_join_right(id, k, v, flag) "
                        + "SELECT x, x % 16, x * 5, x % 3 FROM n",
                false);
        ok &= executeContextStatement(state,
                "WITH RECURSIVE n(x) AS (VALUES(0) UNION ALL SELECT x + 1 FROM n WHERE x < 15) "
                        + "INSERT INTO egraph_join_dim(k, label) SELECT x, printf('D%02d', x) FROM n",
                false);
        executeContextStatement(state, "CREATE INDEX IF NOT EXISTS egraph_join_left_k_v ON egraph_join_left(k, v)", true);
        executeContextStatement(state, "CREATE INDEX IF NOT EXISTS egraph_join_right_k_flag ON egraph_join_right(k, flag)",
                true);
        executeContextStatement(state, "CREATE INDEX IF NOT EXISTS egraph_join_left_partial ON egraph_join_left(v) WHERE k >= 0",
                true);
        executeContextStatement(state, "ANALYZE egraph_join_left", false);
        executeContextStatement(state, "ANALYZE egraph_join_right", false);
        executeContextStatement(state, "ANALYZE egraph_join_dim", false);
        ok &= executeContextStatement(state,
                "SELECT r.id, l.tag FROM egraph_join_left AS l RIGHT JOIN egraph_join_right AS r "
                        + "ON r.k = l.k WHERE r.flag IN (SELECT flag FROM egraph_join_right WHERE k BETWEEN 0 AND 8) "
                        + "ORDER BY r.k, l.id LIMIT 24",
                false);
        executeContextStatement(state,
                "SELECT coalesce(l.k, r.k), count(*) FROM egraph_join_left AS l "
                        + "FULL OUTER JOIN egraph_join_right AS r ON r.k = l.k AND r.flag = l.k % 3 "
                        + "GROUP BY coalesce(l.k, r.k) ORDER BY 1 LIMIT 16",
                false);
        executeContextStatement(state,
                "SELECT count(*) FROM egraph_join_left AS l JOIN egraph_join_right AS r ON r.k = l.k "
                        + "JOIN egraph_join_dim AS d ON d.k = r.k "
                        + "WHERE d.k IN (SELECT k FROM egraph_join_dim WHERE k < 12) AND r.v > l.v",
                false);
        return ok;
    }

    private static boolean setupAlterFkStressContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state, "PRAGMA foreign_keys=ON", false);
        ok &= executeContextStatement(state, "PRAGMA defer_foreign_keys=ON", false);
        try {
            executeContextStatement(state, "DROP VIEW IF EXISTS egraph_alter_fk_view", true);
            executeContextStatement(state, "DROP TRIGGER IF EXISTS egraph_alter_fk_ai", true);
            executeContextStatement(state, "DROP TABLE IF EXISTS egraph_alter_fk_renamed", true);
            executeContextStatement(state, "DROP TABLE IF EXISTS egraph_alter_fk_rename", true);
            executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fk_audit", true);
            executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fk_child2", true);
            executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fk_parent2", true);
            executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fk_child", true);
            executeContextStatement(state, "DROP TABLE IF EXISTS egraph_fk_parent", true);

            ok &= executeContextStatement(state,
                    "CREATE TABLE egraph_fk_parent(id INTEGER PRIMARY KEY, code TEXT UNIQUE)", true);
            ok &= executeContextStatement(state,
                    "CREATE TABLE egraph_fk_child(id INTEGER PRIMARY KEY, pid INTEGER DEFAULT 0 "
                            + "REFERENCES egraph_fk_parent(id) ON UPDATE CASCADE ON DELETE SET DEFAULT, note TEXT)",
                    true);
            ok &= executeContextStatement(state,
                    "CREATE TABLE egraph_fk_audit(action TEXT, child_id INTEGER, old_pid INTEGER, new_pid INTEGER)",
                    true);
            ok &= executeContextStatement(state,
                    "CREATE TRIGGER egraph_alter_fk_ai AFTER UPDATE OF pid ON egraph_fk_child BEGIN "
                            + "INSERT INTO egraph_fk_audit VALUES('pid-update', NEW.id, OLD.pid, NEW.pid); END",
                    true);
            ok &= executeContextStatement(state,
                    "INSERT INTO egraph_fk_parent(id, code) VALUES (0, 'default'), (1, 'p1'), (2, 'p2')", false);
            ok &= executeContextStatement(state,
                    "INSERT INTO egraph_fk_child(id, pid, note) VALUES (10, 1, 'c1'), (11, 2, 'c2')", false);
            executeContextStatement(state, "UPDATE egraph_fk_parent SET id = 3 WHERE id = 1", false);
            executeContextStatement(state, "DELETE FROM egraph_fk_parent WHERE id = 2", false);
            executeContextStatement(state, "PRAGMA foreign_key_check", false);

            executeContextStatement(state,
                    "CREATE TABLE egraph_fk_parent2(a INTEGER, b INTEGER, PRIMARY KEY(a, b))", true);
            executeContextStatement(state,
                    "CREATE TABLE egraph_fk_child2(id INTEGER PRIMARY KEY, a INTEGER, b INTEGER, "
                            + "FOREIGN KEY(a, b) REFERENCES egraph_fk_parent2(a, b) "
                            + "ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED)",
                    true);
            executeContextStatement(state, "BEGIN", false);
            executeContextStatement(state, "INSERT INTO egraph_fk_parent2(a, b) VALUES (1, 1), (2, 2)", false);
            executeContextStatement(state, "INSERT INTO egraph_fk_child2(id, a, b) VALUES (1, 1, 1), (2, 2, 2)", false);
            executeContextStatement(state, "DELETE FROM egraph_fk_parent2 WHERE a = 1", false);
            executeContextStatement(state, "COMMIT", false);

            executeContextStatement(state,
                    "CREATE TABLE egraph_alter_fk_rename(id INTEGER PRIMARY KEY, a INTEGER, b TEXT, "
                            + "drop_me TEXT DEFAULT 'x')",
                    true);
            executeContextStatement(state,
                    "CREATE INDEX egraph_alter_fk_expr ON egraph_alter_fk_rename((a + length(b))) WHERE a IS NOT NULL",
                    true);
            executeContextStatement(state,
                    "CREATE VIEW egraph_alter_fk_view AS SELECT id, a, b FROM egraph_alter_fk_rename WHERE a >= 0",
                    true);
            executeContextStatement(state,
                    "INSERT INTO egraph_alter_fk_rename(id, a, b) VALUES (1, 10, 'alpha'), (2, 20, 'beta')", false);
            executeContextStatement(state, "ALTER TABLE egraph_alter_fk_rename RENAME COLUMN b TO renamed_b", true);
            executeContextStatement(state, "ALTER TABLE egraph_alter_fk_rename DROP COLUMN drop_me", true);
            executeContextStatement(state, "ALTER TABLE egraph_alter_fk_rename RENAME TO egraph_alter_fk_renamed", true);
            executeContextStatement(state,
                    "SELECT id, a, renamed_b FROM egraph_alter_fk_renamed WHERE a >= 0 ORDER BY id", false);
            return ok;
        } finally {
            executeContextStatement(state, "ROLLBACK", false);
            executeContextStatement(state, "PRAGMA defer_foreign_keys=OFF", false);
            executeContextStatement(state, "PRAGMA foreign_keys=OFF", false);
        }
    }

    private static boolean setupIntegrityCheckContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_integrity_probe(id INTEGER PRIMARY KEY, k INTEGER NOT NULL, "
                        + "payload TEXT, extra BLOB)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_integrity_probe", false);
        ok &= executeContextStatement(state,
                "WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 128) "
                        + "INSERT INTO egraph_integrity_probe(id, k, payload, extra) "
                        + "SELECT x, x % 37, printf('payload-%04d-%s', x, printf('%016X%016X', x * 2654435761, x * 40503)), "
                        + "zeroblob(32) FROM n",
                false);
        executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS egraph_integrity_k_payload ON egraph_integrity_probe(k, payload)", true);
        executeContextStatement(state,
                "CREATE INDEX IF NOT EXISTS egraph_integrity_payload_expr "
                        + "ON egraph_integrity_probe((length(payload))) WHERE k >= 0",
                true);
        executeContextStatement(state, "DELETE FROM egraph_integrity_probe WHERE id % 19 = 0", false);
        executeContextStatement(state,
                "UPDATE egraph_integrity_probe SET payload = payload || '-updated' WHERE id % 23 = 0", false);
        executeContextStatement(state, "PRAGMA cell_size_check=ON", false);
        executeContextStatement(state, "PRAGMA quick_check", false);
        if (INTEGRITY_CONTEXT_COUNT.incrementAndGet() % 64 == 0) {
            executeContextStatement(state, "PRAGMA integrity_check", false);
        }
        if (INTEGRITY_CONTEXT_COUNT.get() % 256 == 0) {
            executeContextStatement(state, "VACUUM", false);
        }
        executeContextStatement(state, "PRAGMA freelist_count", false);
        executeContextStatement(state, "PRAGMA page_count", false);
        executeContextStatement(state, "PRAGMA cell_size_check=OFF", false);
        return ok;
    }

    private static boolean setupScalarAggregateContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_scalar_probe(id INTEGER PRIMARY KEY, g INTEGER, n REAL, txt TEXT)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_scalar_probe", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_scalar_probe(id, g, n, txt) VALUES "
                        + "(1, 0, -1.5, 'alpha'), (2, 0, 0.0, 'Beta'), (3, 1, 2.25, 'gamma'), "
                        + "(4, 1, 1000000.5, 'delta'), (5, 2, NULL, ''), "
                        + "(6, 2, 9223372036854775807, 'quote''value')",
                false);
        executeContextStatement(state,
                "SELECT timediff('2024-02-29 12:34:56.789', '1900-01-01 00:00:00.001'), "
                        + "strftime('%Y-%m-%d %H:%M:%f %J %s %W %w', '2024-02-29 12:34:56.789'), "
                        + "printf('%!.*q|%lld|%#x|%.17g|%c', 12, txt, id, id, n, 65) "
                        + "FROM egraph_scalar_probe WHERE id IN (1, 2, 6) ORDER BY id",
                false);
        executeContextStatement(state,
                "SELECT g, group_concat(replace(txt, 'a', 'A'), '|') FILTER (WHERE txt IS NOT NULL), "
                        + "sum(CASE WHEN typeof(n) = 'real' THEN n ELSE 0 END), max(txt COLLATE NOCASE) "
                        + "FROM egraph_scalar_probe GROUP BY g HAVING count(*) >= 1 ORDER BY g",
                false);
        executeContextStatement(state,
                "SELECT replace(format('%08d-%s-%Q', id, txt, txt), '0', '_') "
                        + "FROM egraph_scalar_probe WHERE txt GLOB '*[ae]*' OR txt = '' ORDER BY txt COLLATE NOCASE",
                false);
        return ok;
    }

    private static boolean setupVirtualTableUpdateContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_vtab_rt USING rtree(id, x1, x2, y1, y2)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_vtab_rt", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_vtab_rt VALUES "
                        + "(1, 0.0, 10.0, 0.0, 10.0), (2, 5.0, 15.0, 5.0, 15.0), "
                        + "(3, -5.0, 1.0, -5.0, 1.0), (4, 20.0, 30.0, 20.0, 30.0)",
                false);
        if (ok) {
            executeContextStatement(state,
                    "UPDATE egraph_vtab_rt SET x1 = x1 - 0.5, x2 = x2 + 0.5 WHERE id IN (1, 2)", false);
            executeContextStatement(state,
                    "SELECT id FROM egraph_vtab_rt WHERE x1 <= 6.0 AND x2 >= 6.0 "
                            + "AND y1 <= 6.0 AND y2 >= 6.0 ORDER BY id",
                    false);
            executeContextStatement(state,
                    "DELETE FROM egraph_vtab_rt WHERE id IN (SELECT id FROM egraph_vtab_rt WHERE x2 < 2.0 OR x1 > 25.0)",
                    false);
            executeContextStatement(state, "SELECT rtreecheck('egraph_vtab_rt')", false);
        }
        boolean ftsOk = executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_vtab_fts USING fts5(title, body)", true);
        if (ftsOk) {
            executeContextStatement(state, "DELETE FROM egraph_vtab_fts", false);
            executeContextStatement(state,
                    "INSERT INTO egraph_vtab_fts(rowid, title, body) VALUES "
                            + "(1, 'one', 'alpha beta gamma'), (2, 'two', 'delta epsilon zeta')",
                    false);
            executeContextStatement(state,
                    "UPDATE egraph_vtab_fts SET body = body || ' updated' WHERE rowid = 1", false);
            executeContextStatement(state, "DELETE FROM egraph_vtab_fts WHERE egraph_vtab_fts MATCH 'delta'", false);
            executeContextStatement(state,
                    "SELECT rowid, title FROM egraph_vtab_fts WHERE egraph_vtab_fts MATCH 'alpha OR updated'", false);
        }
        return ok;
    }

    private static boolean setupVirtualTableSavepointContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_vtab_sp_fts USING fts5(title, body, prefix='2 3')",
                true);
        ok &= executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_vtab_sp_rt USING rtree(id, x1, x2, y1, y2)", true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_vtab_sp_fts", false);
        ok &= executeContextStatement(state, "DELETE FROM egraph_vtab_sp_rt", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_vtab_sp_fts(rowid, title, body) VALUES "
                        + "(1, 'alpha beta', 'alpha beta sqlite virtual table savepoint'), "
                        + "(2, 'beta gamma', 'rollback release savepoint fts5 prefix')",
                false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_vtab_sp_rt VALUES "
                        + "(1, 0.0, 4.0, 0.0, 4.0), (2, 10.0, 20.0, 10.0, 20.0)",
                false);
        if (ok) {
            executeContextStatement(state, "SAVEPOINT egraph_vtab_sp_outer", false);
            executeContextStatement(state,
                    "INSERT OR REPLACE INTO egraph_vtab_sp_fts(rowid, title, body) VALUES "
                            + "(3, 'outer row', 'outer virtual table transaction row')",
                    false);
            executeContextStatement(state,
                    "INSERT OR REPLACE INTO egraph_vtab_sp_rt VALUES (3, 1.0, 3.0, 1.0, 3.0)", false);
            executeContextStatement(state, "SAVEPOINT egraph_vtab_sp_inner", false);
            executeContextStatement(state,
                    "UPDATE egraph_vtab_sp_fts SET body = body || ' inner update' WHERE rowid = 1", false);
            executeContextStatement(state,
                    "UPDATE egraph_vtab_sp_rt SET x1 = x1 - 0.5, x2 = x2 + 0.5 WHERE id = 1", false);
            executeContextStatement(state,
                    "DELETE FROM egraph_vtab_sp_fts WHERE egraph_vtab_sp_fts MATCH 'gamma'", false);
            executeContextStatement(state, "ROLLBACK TO egraph_vtab_sp_inner", false);
            executeContextStatement(state, "RELEASE egraph_vtab_sp_inner", false);
            executeContextStatement(state, "RELEASE egraph_vtab_sp_outer", false);
            executeContextStatement(state,
                    "SELECT rowid FROM egraph_vtab_sp_fts WHERE egraph_vtab_sp_fts MATCH 'alpha OR beta' "
                            + "ORDER BY rank LIMIT 8",
                    false);
            executeContextStatement(state,
                    "SELECT id FROM egraph_vtab_sp_rt WHERE x1 <= 2.0 AND x2 >= 2.0 ORDER BY id LIMIT 8",
                    false);
            executeContextStatement(state, "SELECT rtreecheck('egraph_vtab_sp_rt')", false);
        }
        executeContextStatement(state, "ROLLBACK", false);
        return ok;
    }

    private static boolean setupFts5SecureDeleteContext(SQLite3GlobalState state) {
        boolean ok = executeContextStatement(state,
                "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts_secure USING fts5(title, body, tokenize='porter')",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_fts_secure", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_fts_secure(rowid, title, body) VALUES "
                        + "(1, 'alpha coverage', 'sqlite fts5 secure delete vocabulary prefix'), "
                        + "(2, 'beta coverage', 'token prefix merge delete optimize'), "
                        + "(3, 'gamma coverage', 'query planner variants and egraph testing'), "
                        + "(4, 'delta coverage', 'prefix prefix prefix token data')",
                false);
        if (ok) {
            executeContextStatement(state,
                    "INSERT INTO egraph_fts_secure(egraph_fts_secure, rank) VALUES('secure-delete', 1)", false);
            executeContextStatement(state,
                    "DELETE FROM egraph_fts_secure WHERE rowid IN (SELECT rowid FROM egraph_fts_secure "
                            + "WHERE egraph_fts_secure MATCH 'prefix OR token' LIMIT 2)",
                    false);
            executeContextStatement(state,
                    "INSERT INTO egraph_fts_secure(rowid, title, body) VALUES "
                            + "(5, 'epsilon coverage', 'replacement token data after secure delete')",
                    false);
            executeContextStatement(state,
                    "SELECT rowid, bm25(egraph_fts_secure), highlight(egraph_fts_secure, 0, '[', ']') "
                            + "FROM egraph_fts_secure WHERE egraph_fts_secure MATCH 'coverage OR token' "
                            + "ORDER BY rank LIMIT 8",
                    false);
            executeContextStatement(state, "INSERT INTO egraph_fts_secure(egraph_fts_secure) VALUES('optimize')",
                    false);
            executeContextStatement(state,
                    "CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts_secure_vocab "
                            + "USING fts5vocab(egraph_fts_secure, 'row')",
                    true);
            executeContextStatement(state,
                    "SELECT term, doc, cnt FROM egraph_fts_secure_vocab WHERE term >= 'a' ORDER BY term LIMIT 16",
                    false);
        }
        return ok;
    }

    private static boolean setupJsonbStressContext(SQLite3GlobalState state) {
        executeContextStatement(state,
                "SELECT json_valid(jsonb('{\"a\":[1,2,3],\"b\":{\"x\":7}}'), 8), "
                        + "json_valid(x'4a534f4e', 8), "
                        + "json_extract(jsonb('{\"a\":[1,2,3]}'), '$.a[1]')",
                false);
        executeContextStatement(state,
                "SELECT json_patch(jsonb('{\"a\":1,\"b\":{\"x\":2}}'), "
                        + "jsonb('{\"b\":{\"y\":3},\"c\":[4,5]}')), "
                        + "json_pretty(jsonb('{\"nested\":{\"array\":[1,{\"x\":2}]}}'))",
                false);
        return true;
    }

    private static boolean setupXferOptimizationContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state, "DROP TABLE IF EXISTS egraph_xfer_dst", true);
        ok &= executeContextStatement(state, "DROP TABLE IF EXISTS egraph_xfer_src", true);
        ok &= executeContextStatement(state,
                "CREATE TABLE egraph_xfer_src(a INTEGER PRIMARY KEY, b TEXT, c REAL)", true);
        ok &= executeContextStatement(state,
                "CREATE TABLE egraph_xfer_dst(a INTEGER PRIMARY KEY, b TEXT, c REAL)", true);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_xfer_src(a, b, c) VALUES "
                        + "(1, 'one', 1.0), (2, 'two', 2.0), (3, 'three', 3.0), (4, 'four', 4.0)",
                false);
        if (ok) {
            executeContextStatement(state, "INSERT INTO egraph_xfer_dst SELECT * FROM egraph_xfer_src", false);
            executeContextStatement(state,
                    "SELECT a, b, c FROM egraph_xfer_dst WHERE a >= 0 ORDER BY a LIMIT 8", false);
        }
        return ok;
    }

    private static boolean setupMultiSelectOrderByContext(SQLite3GlobalState state) {
        boolean ok = true;
        ok &= executeContextStatement(state,
                "CREATE TABLE IF NOT EXISTS egraph_multiselect_probe(id INTEGER PRIMARY KEY, v INTEGER, tag TEXT)",
                true);
        ok &= executeContextStatement(state, "DELETE FROM egraph_multiselect_probe", false);
        ok &= executeContextStatement(state,
                "INSERT INTO egraph_multiselect_probe(id, v, tag) VALUES "
                        + "(1, 10, 'alpha'), (2, 20, 'beta'), (3, 30, 'gamma'), (4, 40, 'delta')",
                false);
        if (ok) {
            executeContextStatement(state,
                    "SELECT v, tag FROM egraph_multiselect_probe WHERE v <= 20 "
                            + "UNION ALL SELECT v, tag FROM egraph_multiselect_probe WHERE v >= 30 "
                            + "ORDER BY tag DESC, v ASC LIMIT 8",
                    false);
            executeContextStatement(state,
                    "SELECT v FROM egraph_multiselect_probe WHERE tag LIKE 'a%' "
                            + "UNION SELECT v FROM egraph_multiselect_probe WHERE tag LIKE 'd%' "
                            + "ORDER BY 1 DESC",
                    false);
        }
        return ok;
    }

    private static String getEGraphContextIndexName(String tableName, String columnName) {
        return "egraph_ctx_idx_" + sanitizeIdentifierPart(tableName) + "_" + sanitizeIdentifierPart(columnName);
    }

    private static boolean hasUsableIdentifier(SQLite3Column column) {
        return column != null && hasUsableIdentifier(column.getName());
    }

    private static boolean hasUsableIdentifier(String identifier) {
        return identifier != null && !identifier.isBlank();
    }

    private static String quoteIdentifier(String identifier) {
        return "\"" + identifier.replace("\"", "\"\"") + "\"";
    }

    private static String sanitizeIdentifierPart(String identifier) {
        if (identifier == null || identifier.isBlank()) {
            return "unnamed";
        }
        String sanitized = identifier.replaceAll("[^A-Za-z0-9_]", "_");
        sanitized = sanitized.replaceAll("_+", "_");
        sanitized = sanitized.replaceAll("^_+", "");
        sanitized = sanitized.replaceAll("_+$", "");
        if (sanitized.isEmpty()) {
            return "unnamed";
        }
        return sanitized;
    }

    private static boolean executeContextStatement(SQLite3GlobalState state, String sql, boolean couldAffectSchema) {
        if (state == null) {
            return false;
        }
        try {
            SQLQueryAdapter query = new SQLQueryAdapter(sql, couldAffectSchema || contextStatementCouldAffectSchema(sql));
            boolean success = query.execute(state, false);
            if (success) {
                logExecutedContextStatement(state, query);
                EGraphContextReplayWriter.record(query.getQueryString());
            }
            return success;
        } catch (Throwable ignored) {
            return false;
        }
    }

    private static boolean contextStatementCouldAffectSchema(String sql) {
        if (sql == null) {
            return false;
        }
        String normalized = sql.stripLeading().toUpperCase(java.util.Locale.ROOT);
        return normalized.startsWith("CREATE ") || normalized.startsWith("DROP ") || normalized.startsWith("ALTER ")
                || normalized.startsWith("ATTACH ") || normalized.startsWith("DETACH ")
                || normalized.startsWith("VACUUM");
    }

    private static void logExecutedContextStatement(SQLite3GlobalState state, SQLQueryAdapter query) {
        if (state.getState() != null) {
            state.getState().logStatement(query);
        }
        if (state.getOptions() != null && state.getOptions().logEachSelect() && state.getLogger() != null) {
            state.getLogger().writeCurrent(query.getQueryString());
        }
    }

    private static final class EGraphCoverageContext {
        private final EGraphCoverageShape shape;
        private final String tableName;
        private final String columnName;
        private final String secondColumnName;
        private final String indexName;
        private final String groupByColumns;

        private EGraphCoverageContext(EGraphCoverageShape shape, String tableName, String columnName,
                String secondColumnName, String indexName, String groupByColumns) {
            this.shape = shape;
            this.tableName = tableName;
            this.columnName = columnName;
            this.secondColumnName = secondColumnName;
            this.indexName = indexName;
            this.groupByColumns = groupByColumns;
        }
    }

    private static final class EGraphBaseQuery {
        private final String sql;
        private final String shapeName;

        private EGraphBaseQuery(String sql, String shapeName) {
            this.sql = sql;
            this.shapeName = shapeName;
        }
    }

    private static final class SelectOnlyFrom {
        private final String tableName;
        private final String alias;

        private SelectOnlyFrom(String tableName, String alias) {
            this.tableName = tableName;
            this.alias = alias;
        }
    }

    private static final class SelectOnlyMapper {
        private final List<SQLite3Column> targetColumns;
        private final Map<String, String> mappedColumns = new HashMap<>();

        private SelectOnlyMapper(List<SQLite3Column> targetColumns) {
            this.targetColumns = targetColumns;
        }

        private String map(String sourceIdentifier) {
            String key = normalizeIdentifier(sourceIdentifier);
            return mappedColumns.computeIfAbsent(key, ignored -> {
                SQLite3Column target = targetColumns.get(mappedColumns.size() % targetColumns.size());
                return quoteIdentifier(target.getName());
            });
        }

        private int mappedColumnCount() {
            return mappedColumns.size();
        }
    }

}
