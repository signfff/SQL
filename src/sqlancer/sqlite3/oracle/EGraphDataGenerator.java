package sqlancer.sqlite3.oracle;

import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import sqlancer.IgnoreMeException;
import sqlancer.common.schema.AbstractTables;
import sqlancer.sqlite3.SQLite3GlobalState;
import sqlancer.sqlite3.SQLite3ToStringVisitor;
import sqlancer.sqlite3.ast.SQLite3Case;
import sqlancer.sqlite3.ast.SQLite3Constant;
import sqlancer.sqlite3.ast.SQLite3Expression;
import sqlancer.sqlite3.ast.SQLite3Expression.BetweenOperation;
import sqlancer.sqlite3.ast.SQLite3Expression.CollateOperation;
import sqlancer.sqlite3.ast.SQLite3Expression.BinaryComparisonOperation;
import sqlancer.sqlite3.ast.SQLite3Expression.BinaryComparisonOperation.BinaryComparisonOperator;
import sqlancer.sqlite3.ast.SQLite3Expression.SQLite3ColumnName;
import sqlancer.sqlite3.ast.SQLite3Expression.SQLite3PostfixUnaryOperation;
import sqlancer.sqlite3.ast.SQLite3Expression.Sqlite3BinaryOperation;
import sqlancer.sqlite3.ast.SQLite3RowValueExpression;
import sqlancer.sqlite3.ast.SQLite3UnaryOperation;
import sqlancer.sqlite3.schema.SQLite3Schema.SQLite3Column;
import sqlancer.sqlite3.schema.SQLite3Schema.SQLite3Table;

public class EGraphDataGenerator {

    private static final int TARGET_ROWS = 14;
    private static final long NULL_MARKER = Long.MIN_VALUE;
    private static final long TEXT_EMPTY = Long.MAX_VALUE;       // '' (empty string)
    private static final long TEXT_SHORT = Long.MAX_VALUE - 1;   // 'abc' (short text)
    private static final long TEXT_NUMERIC = Long.MAX_VALUE - 2; // '42' (numeric-as-text)

    // Enable with -Degraph.data.monitor=true
    private static final boolean DATA_MONITOR = Boolean.getBoolean("egraph.data.monitor");
    private static int dataCheckCounter = 0;

    private static final int MAX_EXPR_DEPTH = 25;
    private static final Pattern INTEGER_LITERAL = Pattern.compile("(?<![\\w.])-?\\d+(?![\\w.])");
    private static final Pattern REAL_LITERAL = Pattern.compile(
            "(?<![\\w.])-?(?:\\d+\\.\\d*|\\.\\d+)(?:[eE][+-]?\\d+)?(?![\\w.])|(?<![\\w.])-?\\d+[eE][+-]?\\d+(?![\\w.])");
    private static final Pattern LEADING_NUMBER = Pattern.compile("^[+-]?(\\d+\\.?\\d*|\\.\\d+)([eE][+-]?\\d+)?");
    private static final Pattern SINGLE_QUOTED_LITERAL = Pattern.compile("'(?:''|[^'])*'");
    private static final Pattern HEX_BLOB_LITERAL = Pattern.compile("(?i)\\bX'([0-9A-F]*)'");

    /**
     * Three-valued verdict on whether a WHERE clause can ever evaluate to TRUE.
     *
     * <p>
     * Measured on a 45 s run, 43% of generated base queries matched no row, and 65% of those were structurally
     * unsatisfiable rather than badly seeded: {@code (c0)-(c0)} is always 0, {@code (c0)<(c0)} is always false, and any
     * comparison against a NULL literal is always NULL. No amount of generated data makes those return a row, and an
     * empty original result makes the metamorphic comparison vacuous, so they are rejected before the data setup and
     * the probe run.
     * </p>
     *
     * <p>
     * ALWAYS_FALSE and ALWAYS_NULL are kept apart because NOT distinguishes them: {@code NOT (c0 < c0)} is TRUE for a
     * non-NULL column, while {@code NOT (c0 = NULL)} stays NULL. Collapsing them would reject satisfiable clauses.
     * </p>
     */
    private enum Truth {
        /** Definitely true for any data, which makes NOT of it definitely false. */
        ALWAYS_TRUE, POSSIBLY_TRUE, ALWAYS_FALSE, ALWAYS_NULL
    }

    private static boolean canBeTrue(Truth truth) {
        return truth == Truth.ALWAYS_TRUE || truth == Truth.POSSIBLY_TRUE;
    }

    /**
     * Nodes that yield 0, 1 or NULL rather than an arbitrary value. Their outcome domain is what lets a comparison
     * between two of them be decided statically, and they carry no column affinity.
     */
    private static boolean isBooleanProducing(SQLite3Expression expr) {
        if (expr instanceof BinaryComparisonOperation || expr instanceof SQLite3PostfixUnaryOperation
                || expr instanceof BetweenOperation) {
            return true;
        }
        if (expr instanceof SQLite3UnaryOperation) {
            return ((SQLite3UnaryOperation) expr).getOperation() == SQLite3UnaryOperation.UnaryOperator.NOT;
        }
        if (expr instanceof Sqlite3BinaryOperation) {
            Sqlite3BinaryOperation.BinaryOperator op = ((Sqlite3BinaryOperation) expr).getOperator();
            return op == Sqlite3BinaryOperation.BinaryOperator.AND
                    || op == Sqlite3BinaryOperation.BinaryOperator.OR;
        }
        return false;
    }

    /** The possible outcomes of a boolean-producing node whose truth value is already known. */
    private enum BoolDomain {
        ONE_OR_NULL, ZERO_OR_NULL, UNKNOWN
    }

    private static BoolDomain boolDomain(SQLite3Expression expr, int depth) {
        if (!isBooleanProducing(expr)) {
            return BoolDomain.UNKNOWN;
        }
        switch (analyzeTruth(expr, depth)) {
            case ALWAYS_TRUE:
                return BoolDomain.ONE_OR_NULL;
            case ALWAYS_FALSE:
            case ALWAYS_NULL:
                return BoolDomain.ZERO_OR_NULL;
            default:
                return BoolDomain.UNKNOWN;
        }
    }

    /**
     * Decides a comparison between two boolean-producing nodes with known outcome domains. NULL on either side yields
     * NULL, which is not true, so only the concrete pairs need checking.
     */
    private static Truth compareDomains(BoolDomain left, BinaryComparisonOperator op, BoolDomain right) {
        if (left == BoolDomain.UNKNOWN || right == BoolDomain.UNKNOWN) {
            return Truth.POSSIBLY_TRUE;
        }
        int leftValue = left == BoolDomain.ONE_OR_NULL ? 1 : 0;
        int rightValue = right == BoolDomain.ONE_OR_NULL ? 1 : 0;
        boolean holds;
        switch (op) {
            case SMALLER:
                holds = leftValue < rightValue;
                break;
            case SMALLER_EQUALS:
                holds = leftValue <= rightValue;
                break;
            case GREATER:
                holds = leftValue > rightValue;
                break;
            case GREATER_EQUALS:
                holds = leftValue >= rightValue;
                break;
            case EQUALS:
                holds = leftValue == rightValue;
                break;
            case NOT_EQUALS:
                holds = leftValue != rightValue;
                break;
            default:
                return Truth.POSSIBLY_TRUE;
        }
        // The concrete pair may still be NULL on either side, so a holding
        // comparison is only "possibly" true, while a failing one can never be true.
        return holds ? Truth.POSSIBLY_TRUE : Truth.ALWAYS_FALSE;
    }

    // Escape hatch for A/B measurement and for the case where the analysis ever
    // rejects something it should not.
    private static final boolean SATISFIABILITY_FILTER = !"false"
            .equalsIgnoreCase(System.getProperty("sqlite3.egraph.satisfiabilityFilter", "true"));

    /** Returns false only when the clause provably never evaluates to TRUE, whatever the data. */
    public static boolean isPotentiallySatisfiable(SQLite3Expression expr) {
        if (!SATISFIABILITY_FILTER) {
            return true;
        }
        if (expr == null) {
            return false;
        }
        return canBeTrue(analyzeTruth(expr, 0));
    }

    private static Truth analyzeTruth(SQLite3Expression expr, int depth) {
        if (expr == null || depth > MAX_EXPR_DEPTH) {
            return Truth.POSSIBLY_TRUE; // unknown shape: never reject on ignorance
        }
        if (expr instanceof SQLite3Constant) {
            return constantTruth((SQLite3Constant) expr);
        }
        if (expr instanceof BinaryComparisonOperation) {
            return comparisonTruth((BinaryComparisonOperation) expr, depth);
        }
        if (expr instanceof Sqlite3BinaryOperation) {
            return binaryTruth((Sqlite3BinaryOperation) expr, depth);
        }
        if (expr instanceof SQLite3UnaryOperation) {
            SQLite3UnaryOperation unary = (SQLite3UnaryOperation) expr;
            Truth inner = analyzeTruth(unary.getExpression(), depth + 1);
            switch (unary.getOperation()) {
                case NOT:
                    // NOT flips both definite outcomes; NULL stays NULL.
                    switch (inner) {
                        case ALWAYS_FALSE:
                            return Truth.ALWAYS_TRUE;
                        case ALWAYS_TRUE:
                            return Truth.ALWAYS_FALSE;
                        case ALWAYS_NULL:
                            return Truth.ALWAYS_NULL;
                        default:
                            return Truth.POSSIBLY_TRUE;
                    }
                case MINUS:
                case PLUS:
                    // Sign changes neither zero-ness nor NULL-ness, but a definite
                    // non-zero value stays definitely true only in magnitude terms.
                    return inner == Truth.ALWAYS_NULL ? Truth.ALWAYS_NULL
                            : inner == Truth.ALWAYS_FALSE ? Truth.ALWAYS_FALSE : Truth.POSSIBLY_TRUE;
                default:
                    return Truth.POSSIBLY_TRUE; // ~0 is -1, which is true
            }
        }
        if (expr instanceof SQLite3PostfixUnaryOperation) {
            SQLite3PostfixUnaryOperation post = (SQLite3PostfixUnaryOperation) expr;
            if (analyzeTruth(post.getExpression(), depth + 1) == Truth.ALWAYS_NULL) {
                // Only ISNULL holds for a value that is always NULL.
                String name = post.getOperation().toString().toUpperCase(java.util.Locale.ROOT);
                return name.contains("ISNULL") || name.contains("IS_NULL") ? Truth.ALWAYS_TRUE : Truth.ALWAYS_FALSE;
            }
            return Truth.POSSIBLY_TRUE;
        }
        if (expr instanceof BetweenOperation) {
            BetweenOperation between = (BetweenOperation) expr;
            if (analyzeTruth(between.getExpression(), depth + 1) == Truth.ALWAYS_NULL) {
                return Truth.ALWAYS_NULL; // NULL BETWEEN ... is NULL
            }
            return Truth.POSSIBLY_TRUE;
        }
        return Truth.POSSIBLY_TRUE;
    }

    private static Truth constantTruth(SQLite3Constant c) {
        if (c.isNull()) {
            return Truth.ALWAYS_NULL;
        }
        Double numeric = numericValueOf(c);
        if (numeric == null) {
            return Truth.POSSIBLY_TRUE;
        }
        return numeric == 0.0 ? Truth.ALWAYS_FALSE : Truth.ALWAYS_TRUE;
    }

    private static Truth comparisonTruth(BinaryComparisonOperation cmp, int depth) {
        BinaryComparisonOperator op = cmp.getOperator();
        boolean nullAware = op == BinaryComparisonOperator.IS || op == BinaryComparisonOperator.IS_NOT;
        if (!nullAware) {
            // Any comparison with a NULL operand yields NULL - not only against a
            // literal NULL, but also against a subexpression that is always NULL.
            if (isNullConstant(cmp.getLeft()) || isNullConstant(cmp.getRight())
                    || analyzeTruth(cmp.getLeft(), depth + 1) == Truth.ALWAYS_NULL
                    || analyzeTruth(cmp.getRight(), depth + 1) == Truth.ALWAYS_NULL) {
                return Truth.ALWAYS_NULL;
            }
            Truth domainVerdict = compareDomains(boolDomain(cmp.getLeft(), depth + 1), op,
                    boolDomain(cmp.getRight(), depth + 1));
            if (domainVerdict == Truth.ALWAYS_FALSE) {
                return Truth.ALWAYS_FALSE;
            }
        }
        String left = canonical(cmp.getLeft(), 0);
        String right = canonical(cmp.getRight(), 0);
        if (left == null || right == null || !left.equals(right)) {
            return Truth.POSSIBLY_TRUE;
        }
        // Both sides are the same expression, so the outcome depends only on the operator.
        switch (op) {
            case SMALLER:
            case GREATER:
            case NOT_EQUALS:
            case IS_NOT:
                return Truth.ALWAYS_FALSE;
            case IS:
                return Truth.ALWAYS_TRUE; // X IS X holds even for NULL
            default:
                return Truth.POSSIBLY_TRUE; // =, <=, >=, LIKE, GLOB hold for a non-NULL value
        }
    }

    private static Truth binaryTruth(Sqlite3BinaryOperation bin, int depth) {
        Sqlite3BinaryOperation.BinaryOperator op = bin.getOperator();
        Truth left = analyzeTruth(bin.getLeft(), depth + 1);
        Truth right = analyzeTruth(bin.getRight(), depth + 1);
        switch (op) {
            case AND:
                if (left == Truth.ALWAYS_TRUE && right == Truth.ALWAYS_TRUE) {
                    return Truth.ALWAYS_TRUE;
                }
                if (left == Truth.ALWAYS_FALSE || right == Truth.ALWAYS_FALSE) {
                    return Truth.ALWAYS_FALSE; // false AND anything is false, even NULL
                }
                if (!canBeTrue(left) || !canBeTrue(right)) {
                    return Truth.ALWAYS_NULL;
                }
                return Truth.POSSIBLY_TRUE;
            case OR:
                if (left == Truth.ALWAYS_TRUE || right == Truth.ALWAYS_TRUE) {
                    return Truth.ALWAYS_TRUE; // true OR anything is true, even NULL
                }
                if (canBeTrue(left) || canBeTrue(right)) {
                    return Truth.POSSIBLY_TRUE;
                }
                return left == Truth.ALWAYS_NULL || right == Truth.ALWAYS_NULL ? Truth.ALWAYS_NULL
                        : Truth.ALWAYS_FALSE;
            default:
                break;
        }
        // Arithmetic and bitwise operators propagate NULL: any operand that is
        // always NULL makes the whole value NULL, which is never true.
        if (left == Truth.ALWAYS_NULL || right == Truth.ALWAYS_NULL) {
            return Truth.ALWAYS_NULL;
        }
        switch (op) {
            case MULTIPLY:
            case DIVIDE:
                // 0 * x and 0 / x are 0; x / 0 is NULL. An operand that can never be
                // true is either 0 or NULL, so the result can never be true either.
                if (!canBeTrue(left) || !canBeTrue(right)) {
                    return Truth.ALWAYS_FALSE;
                }
                return isProvablyZero(bin, 0) ? Truth.ALWAYS_FALSE : Truth.POSSIBLY_TRUE;
            case ARITHMETIC_AND:
                // 0 & x is 0.
                if (!canBeTrue(left) || !canBeTrue(right)) {
                    return Truth.ALWAYS_FALSE;
                }
                return Truth.POSSIBLY_TRUE;
            case PLUS:
            case ARITHMETIC_OR:
            case CONCATENATE:
                // Only zero on both sides keeps the result at zero.
                if (left == Truth.ALWAYS_FALSE && right == Truth.ALWAYS_FALSE) {
                    return Truth.ALWAYS_FALSE;
                }
                return Truth.POSSIBLY_TRUE;
            case MINUS:
            case REMAINDER:
                // x - x is 0; x % x is 0 or NULL.
                if (left == Truth.ALWAYS_FALSE && right == Truth.ALWAYS_FALSE) {
                    return Truth.ALWAYS_FALSE;
                }
                return isProvablyZero(bin, 0) ? Truth.ALWAYS_FALSE : Truth.POSSIBLY_TRUE;
            default:
                return Truth.POSSIBLY_TRUE;
        }
    }

    /** True when the expression's numeric value is 0 for every possible input. */
    private static boolean isProvablyZero(SQLite3Expression expr, int depth) {
        if (expr == null || depth > MAX_EXPR_DEPTH) {
            return false;
        }
        if (expr instanceof SQLite3Constant) {
            SQLite3Constant c = (SQLite3Constant) expr;
            if (c.isNull()) {
                return false;
            }
            Double numeric = numericValueOf(c);
            return numeric != null && numeric == 0.0;
        }
        if (expr instanceof SQLite3UnaryOperation) {
            SQLite3UnaryOperation unary = (SQLite3UnaryOperation) expr;
            switch (unary.getOperation()) {
                case MINUS:
                case PLUS:
                    return isProvablyZero(unary.getExpression(), depth + 1);
                default:
                    return false;
            }
        }
        if (expr instanceof Sqlite3BinaryOperation) {
            Sqlite3BinaryOperation bin = (Sqlite3BinaryOperation) expr;
            switch (bin.getOperator()) {
                case MINUS:
                case REMAINDER: {
                    String left = canonical(bin.getLeft(), 0);
                    String right = canonical(bin.getRight(), 0);
                    return left != null && left.equals(right);
                }
                case MULTIPLY:
                    return isProvablyZero(bin.getLeft(), depth + 1) || isProvablyZero(bin.getRight(), depth + 1);
                default:
                    return false;
            }
        }
        return false;
    }

    private static boolean isNullConstant(SQLite3Expression expr) {
        return expr instanceof SQLite3Constant && ((SQLite3Constant) expr).isNull();
    }

    /** Numeric value of a constant under SQLite's truthiness rules, or null when it cannot be determined. */
    private static Double numericValueOf(SQLite3Constant c) {
        try {
            switch (c.getDataType()) {
                case INT:
                    return (double) c.asInt();
                case REAL:
                    return c.asDouble();
                case BINARY:
                    return 0.0; // a blob converts to 0 in a numeric context
                case TEXT: {
                    String text = c.asString();
                    if (text == null) {
                        return null;
                    }
                    Matcher matcher = LEADING_NUMBER.matcher(text.trim());
                    if (!matcher.find()) {
                        return 0.0; // text with no numeric prefix converts to 0
                    }
                    return Double.parseDouble(matcher.group());
                }
                default:
                    return null;
            }
        } catch (Exception ignored) {
            return null;
        }
    }

    /**
     * Canonical text for the subtrees the satisfiability analysis needs to compare. Returns null for node kinds it
     * cannot render, which makes the caller treat the two sides as possibly different rather than identical.
     */
    private static String canonical(SQLite3Expression expr, int depth) {
        if (expr == null || depth > MAX_EXPR_DEPTH) {
            return null;
        }
        if (expr instanceof SQLite3ColumnName) {
            SQLite3Column col = ((SQLite3ColumnName) expr).getColumn();
            return col == null ? null : "col:" + col.getFullQualifiedName();
        }
        if (expr instanceof SQLite3Constant) {
            SQLite3Constant c = (SQLite3Constant) expr;
            if (c.isNull()) {
                return "const:null";
            }
            try {
                return "const:" + c.getDataType() + ":" + c.toString();
            } catch (Exception ignored) {
                return null;
            }
        }
        if (expr instanceof SQLite3UnaryOperation) {
            SQLite3UnaryOperation unary = (SQLite3UnaryOperation) expr;
            String inner = canonical(unary.getExpression(), depth + 1);
            return inner == null ? null : "un:" + unary.getOperation() + "(" + inner + ")";
        }
        if (expr instanceof SQLite3PostfixUnaryOperation) {
            SQLite3PostfixUnaryOperation post = (SQLite3PostfixUnaryOperation) expr;
            String inner = canonical(post.getExpression(), depth + 1);
            return inner == null ? null : "post:" + post.getOperation() + "(" + inner + ")";
        }
        if (expr instanceof Sqlite3BinaryOperation) {
            Sqlite3BinaryOperation bin = (Sqlite3BinaryOperation) expr;
            String left = canonical(bin.getLeft(), depth + 1);
            String right = canonical(bin.getRight(), depth + 1);
            return left == null || right == null ? null
                    : "bin:" + bin.getOperator() + "(" + left + "," + right + ")";
        }
        if (expr instanceof BinaryComparisonOperation) {
            BinaryComparisonOperation cmp = (BinaryComparisonOperation) expr;
            String left = canonical(cmp.getLeft(), depth + 1);
            String right = canonical(cmp.getRight(), depth + 1);
            return left == null || right == null ? null
                    : "cmp:" + cmp.getOperator() + "(" + left + "," + right + ")";
        }
        return null;
    }

    public static boolean isEgraphCompatible(SQLite3Expression expr) {
        if (expr == null) return false;
        if (expr instanceof SQLite3Constant || expr instanceof SQLite3ColumnName) {
            return false;
        }
        // Reject bitwise/concat at root; egraph cannot rewrite them
        if (expr instanceof Sqlite3BinaryOperation) {
            Sqlite3BinaryOperation bin = (Sqlite3BinaryOperation) expr;
            Sqlite3BinaryOperation.BinaryOperator op = bin.getOperator();
            if (op == Sqlite3BinaryOperation.BinaryOperator.ARITHMETIC_AND
                    || op == Sqlite3BinaryOperation.BinaryOperator.ARITHMETIC_OR
                    || op == Sqlite3BinaryOperation.BinaryOperator.CONCATENATE
                    || op == Sqlite3BinaryOperation.BinaryOperator.SHIFT_LEFT
                    || op == Sqlite3BinaryOperation.BinaryOperator.SHIFT_RIGHT) {
                return false;
            }
        }
        // Full tree scan: column reference + depth
        EgraphCompatChecker c = new EgraphCompatChecker();
        c.walk(expr, 0);
        return c.hasColumn && !c.unsupported && c.maxDepth <= MAX_EXPR_DEPTH;
    }

    public static void setupDataForCorpusQuery(SQLite3GlobalState state,
            AbstractTables<SQLite3Table, SQLite3Column> targetTables, String query) throws java.sql.SQLException {
        if (query == null || query.isBlank()) {
            return;
        }
        String where = extractWhereClause(query);
        Set<Long> numericValues = extractIntegerLiterals(where);
        Set<String> realValues = extractRealLiterals(where);
        Set<String> textValues = extractTextLiterals(where);
        Set<String> blobValues = extractBlobLiterals(where);
        addBoundaryValues(numericValues);
        addDerivedTextValues(textValues);

        sqlancer.SQLConnection sc = (sqlancer.SQLConnection) state.getConnection();
        for (SQLite3Table table : targetTables.getTables()) {
            try (Statement delete = sc.createStatement()) {
                delete.execute("DELETE FROM \"" + table.getName() + "\"");
            } catch (Exception ignored) {
            }
            if (generateCorpusInserts(sc, table, numericValues, realValues, textValues, blobValues) == 0) {
                throw new IgnoreMeException();
            }
        }
    }

    private static String extractWhereClause(String query) {
        String upper = query.toUpperCase(java.util.Locale.ROOT);
        int whereIdx = upper.indexOf(" WHERE ");
        if (whereIdx < 0) {
            return "";
        }
        int end = query.length();
        for (String token : List.of(" ORDER BY ", " LIMIT ", " GROUP BY ", " HAVING ", " WINDOW ", " UNION ",
                " INTERSECT ", " EXCEPT ")) {
            int idx = upper.indexOf(token, whereIdx + 7);
            if (idx >= 0 && idx < end) {
                end = idx;
            }
        }
        return query.substring(whereIdx + 7, end);
    }

    private static Set<Long> extractIntegerLiterals(String where) {
        Set<Long> values = new LinkedHashSet<>();
        Matcher matcher = INTEGER_LITERAL.matcher(where);
        while (matcher.find() && values.size() < 16) {
            try {
                values.add(Long.parseLong(matcher.group()));
            } catch (NumberFormatException ignored) {
            }
        }
        return values;
    }

    private static Set<String> extractTextLiterals(String where) {
        Set<String> values = new LinkedHashSet<>();
        Matcher matcher = SINGLE_QUOTED_LITERAL.matcher(where);
        while (matcher.find() && values.size() < 8) {
            int start = matcher.start();
            if (start > 0 && (where.charAt(start - 1) == 'x' || where.charAt(start - 1) == 'X')) {
                continue;
            }
            String literal = matcher.group();
            String value = literal.substring(1, literal.length() - 1).replace("''", "'");
            values.add(value);
        }
        return values;
    }

    private static Set<String> extractRealLiterals(String where) {
        Set<String> values = new LinkedHashSet<>();
        Matcher matcher = REAL_LITERAL.matcher(where);
        while (matcher.find() && values.size() < 12) {
            values.add(matcher.group());
        }
        return values;
    }

    private static Set<String> extractBlobLiterals(String where) {
        Set<String> values = new LinkedHashSet<>();
        Matcher matcher = HEX_BLOB_LITERAL.matcher(where);
        while (matcher.find() && values.size() < 8) {
            values.add("x'" + matcher.group(1).toLowerCase(java.util.Locale.ROOT) + "'");
        }
        return values;
    }

    private static void addBoundaryValues(Set<Long> values) {
        List<Long> seed = new ArrayList<>(values);
        values.add(0L);
        values.add(1L);
        values.add(-1L);
        for (Long value : seed) {
            values.add(value - 1);
            values.add(value + 1);
        }
    }

    private static int generateCorpusInserts(sqlancer.SQLConnection sc, SQLite3Table table, Set<Long> numericValues,
            Set<String> realValues, Set<String> textValues, Set<String> blobValues) throws java.sql.SQLException {
        List<SQLite3Column> cols = getWritableColumns(table);
        if (cols.isEmpty()) {
            return 0;
        }
        List<Long> nums = new ArrayList<>(numericValues);
        List<String> texts = new ArrayList<>(textValues);
        if (texts.isEmpty()) {
            texts.addAll(defaultTextValues());
        }
        List<String> reals = new ArrayList<>(realValues);
        if (reals.isEmpty()) {
            reals.addAll(defaultRealSqlValues());
        }
        List<String> blobs = new ArrayList<>(blobValues);
        if (blobs.isEmpty()) {
            blobs.addAll(defaultBlobSqlValues());
        }

        int poolSize = Math.max(Math.max(nums.size(), texts.size()), Math.max(reals.size(), blobs.size()));
        int rows = Math.max(TARGET_ROWS, Math.min(40, poolSize + 8));
        int insertedRows = 0;
        for (int r = 0; r < rows; r++) {
            StringBuilder sb = new StringBuilder();
            sb.append("INSERT INTO \"").append(table.getName()).append("\" (").append(columnList(cols))
                    .append(") VALUES (");
            for (int c = 0; c < cols.size(); c++) {
                if (c > 0) {
                    sb.append(", ");
                }
                SQLite3Column col = cols.get(c);
                if (r == 0) {
                    sb.append("NULL");
                } else {
                    List<String> pool = corpusSqlLiteralPoolForColumn(col, nums, reals, texts, blobs);
                    sb.append(pool.get((r - 1) % pool.size()));
                }
            }
            sb.append(")");
            try (Statement insert = sc.createStatement()) {
                insert.execute(sb.toString());
                insertedRows++;
            } catch (Exception ignored) {
            }
        }
        return insertedRows;
    }

    private static List<String> corpusSqlLiteralPoolForColumn(SQLite3Column col, List<Long> nums, List<String> reals,
            List<String> texts, List<String> blobs) {
        List<String> result = new ArrayList<>();
        switch (col.getType()) {
            case TEXT:
                for (String text : texts) {
                    addUnique(result, sqlString(text));
                }
                for (Long num : nums) {
                    addUnique(result, sqlString(String.valueOf(num)));
                }
                for (String real : reals) {
                    addUnique(result, sqlString(real));
                }
                break;
            case REAL:
                result.addAll(reals);
                for (Long num : nums) {
                    addUnique(result, num + ".0");
                }
                break;
            case BINARY:
                result.addAll(blobs);
                for (String text : texts) {
                    addUnique(result, "CAST(" + sqlString(text) + " AS BLOB)");
                }
                break;
            case NONE:
                for (Long num : nums) {
                    addUnique(result, String.valueOf(num));
                }
                result.addAll(reals);
                for (String text : texts) {
                    addUnique(result, sqlString(text));
                }
                result.addAll(blobs);
                break;
            case INT:
            case NULL:
            default:
                for (Long num : nums) {
                    addUnique(result, String.valueOf(num));
                }
                for (String text : texts) {
                    if (looksNumericText(text)) {
                        addUnique(result, sqlString(text));
                    }
                }
                break;
        }
        if (result.isEmpty()) {
            result.add("0");
            result.add("1");
            result.add("-1");
        }
        return result;
    }

    private static List<String> defaultTextValues() {
        return List.of("", "abc", "42", "0", "1", "-1", "alpha", "beta", "brain", "brainz", "zzzz", " ");
    }

    private static List<String> defaultRealSqlValues() {
        return List.of("0.0", "1.0", "-1.0", "0.5", "-0.5", "1.25", "-1.25", "42.5");
    }

    private static List<String> defaultBlobSqlValues() {
        return List.of("x''", "x'00'", "x'01'", "x'616263'", "x'3432'", "x'7979'");
    }

    private static void addUnique(List<String> values, String value) {
        if (value != null && !values.contains(value)) {
            values.add(value);
        }
    }

    private static boolean looksNumericText(String text) {
        return text != null && text.trim().matches("[-+]?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][-+]?\\d+)?");
    }

    private static void addDerivedTextValues(Set<String> values) {
        List<String> seed = new ArrayList<>(values);
        for (String value : seed) {
            addTextDerivatives(values, value);
            if (values.size() >= 24) {
                break;
            }
        }
    }

    private static void addTextDerivatives(Set<String> values, String value) {
        if (value == null) {
            return;
        }
        if (!value.isEmpty()) {
            values.add(value + "z");
            values.add(value + "0");
            values.add(value.substring(0, Math.max(0, value.length() - 1)));
        }
        String like = concreteLikeValue(value);
        if (!like.isEmpty()) {
            values.add(like);
            values.add(like + "z");
        }
        String glob = concreteGlobValue(value);
        if (!glob.isEmpty()) {
            values.add(glob);
            values.add(glob + "z");
        }
    }

    private static String concreteLikeValue(String pattern) {
        StringBuilder sb = new StringBuilder();
        boolean escaped = false;
        for (int i = 0; i < pattern.length(); i++) {
            char ch = pattern.charAt(i);
            if (escaped) {
                sb.append(ch);
                escaped = false;
            } else if (ch == '\\') {
                escaped = true;
            } else if (ch == '%' || ch == '_') {
                sb.append('a');
            } else {
                sb.append(ch);
            }
        }
        return sb.length() == 0 ? "a" : sb.toString();
    }

    private static String concreteGlobValue(String pattern) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < pattern.length(); i++) {
            char ch = pattern.charAt(i);
            if (ch == '*') {
                sb.append('a');
            } else if (ch == '?') {
                sb.append('b');
            } else if (ch == '[') {
                int end = pattern.indexOf(']', i + 1);
                if (end > i + 1) {
                    String body = pattern.substring(i + 1, end);
                    sb.append(globClassRepresentative(body));
                    i = end;
                } else {
                    sb.append(ch);
                }
            } else {
                sb.append(ch);
            }
        }
        return sb.length() == 0 ? "a" : sb.toString();
    }

    private static char globClassRepresentative(String body) {
        if (body.startsWith("^")) {
            return 'z';
        }
        for (int i = 0; i < body.length(); i++) {
            char ch = body.charAt(i);
            if (ch != '-') {
                return ch;
            }
        }
        return 'a';
    }

    private static String sqlString(String value) {
        return "'" + value.replace("'", "''") + "'";
    }

    /** Scans for column references and tracks max nesting depth. */
    private static class EgraphCompatChecker {
        boolean hasColumn;
        boolean unsupported;
        int maxDepth;

        void walk(SQLite3Expression e, int depth) {
            if (e == null || unsupported) return;
            if (depth > maxDepth) maxDepth = depth;
            if (e instanceof SQLite3ColumnName) {
                hasColumn = true;
            } else if (e instanceof BinaryComparisonOperation) {
                BinaryComparisonOperation c = (BinaryComparisonOperation) e;
                walk(c.getLeft(), depth + 1); walk(c.getRight(), depth + 1);
            } else if (e instanceof Sqlite3BinaryOperation) {
                Sqlite3BinaryOperation b = (Sqlite3BinaryOperation) e;
                if (isUnsupportedBinaryOperator(b.getOperator())) {
                    unsupported = true;
                    return;
                }
                walk(b.getLeft(), depth + 1); walk(b.getRight(), depth + 1);
            } else if (e instanceof BetweenOperation) {
                BetweenOperation b = (BetweenOperation) e;
                walk(b.getExpression(), depth + 1);
                walk(b.getLeft(), depth + 1); walk(b.getRight(), depth + 1);
            } else if (e instanceof SQLite3UnaryOperation) {
                if (((SQLite3UnaryOperation) e).getOperation() == SQLite3UnaryOperation.UnaryOperator.NEGATE) {
                    unsupported = true;
                    return;
                }
                walk(((SQLite3UnaryOperation) e).getExpression(), depth + 1);
            } else if (e instanceof SQLite3PostfixUnaryOperation) {
                walk(((SQLite3PostfixUnaryOperation) e).getExpression(), depth + 1);
            }
        }

        private static boolean isUnsupportedBinaryOperator(Sqlite3BinaryOperation.BinaryOperator op) {
            return op == Sqlite3BinaryOperation.BinaryOperator.ARITHMETIC_AND
                    || op == Sqlite3BinaryOperation.BinaryOperator.ARITHMETIC_OR
                    || op == Sqlite3BinaryOperation.BinaryOperator.CONCATENATE
                    || op == Sqlite3BinaryOperation.BinaryOperator.SHIFT_LEFT
                    || op == Sqlite3BinaryOperation.BinaryOperator.SHIFT_RIGHT;
        }
    }

    //  Arithmetic extraction: column + wrapper path 

    private static class ColumnExtraction {
        final SQLite3Column column;
        final List<ArithStep> path; // innermost to outermost

        ColumnExtraction(SQLite3Column column, List<ArithStep> path) {
            this.column = column;
            this.path = path;
        }

        boolean isSimple() { return path.isEmpty(); }
    }

    private static class ArithStep {
        final Sqlite3BinaryOperation.BinaryOperator op;
        final long literal;
        final boolean literalOnLeft; // true: K OP col, false: col OP K

        ArithStep(Sqlite3BinaryOperation.BinaryOperator op, long literal, boolean literalOnLeft) {
            this.op = op;
            this.literal = literal;
            this.literalOnLeft = literalOnLeft;
        }
    }

    private static class CrossColumnConstraint {
        final SQLite3Column colA;
        final SQLite3Column colB;
        final BinaryComparisonOperator operator;

        CrossColumnConstraint(SQLite3Column colA, SQLite3Column colB, BinaryComparisonOperator operator) {
            this.colA = colA;
            this.colB = colB;
            this.operator = operator;
        }
    }

    //  Setup 

    public static void setupData(SQLite3GlobalState state,
            AbstractTables<SQLite3Table, SQLite3Column> targetTables,
            SQLite3Expression whereExpr) throws java.sql.SQLException {
        sqlancer.SQLConnection sc = (sqlancer.SQLConnection) state.getConnection();

        int checkNum = ++dataCheckCounter;
        if (DATA_MONITOR) {
            System.err.println();
            System.err.println(repeat("-", 64));
            System.err.printf("  EGRAPH DATA GENERATION #%d%n", checkNum);
            System.err.println(repeat("-", 64));
            System.err.println();
            System.err.println("  [1] WHERE expression:");
            System.err.println("  ");
            SQLite3ToStringVisitor v = new SQLite3ToStringVisitor();
            v.visit(whereExpr);
            String whereStr = v.get();
            System.err.println("  " + formatLong(whereStr, 60));
        }

        // 1. Clear data
        for (SQLite3Table table : targetTables.getTables()) {
            Statement s = sc.createStatement();
            try { s.execute("DELETE FROM \"" + table.getName() + "\""); } catch (Exception ignored) {}
            s.close();
        }

        if (DATA_MONITOR) {
            System.err.println("  (tables cleared)");
        }

        // 2. Collect values from WHERE
        List<SQLite3Column> allCols = targetTables.getColumns();
        Map<String, List<Long>> columnValues = new HashMap<>();
        Map<String, List<String>> columnLiteralValues = new HashMap<>();
        for (SQLite3Column col : allCols) {
            columnValues.put(col.getName(), new ArrayList<>());
            columnLiteralValues.put(col.getName(), new ArrayList<>());
        }
        List<CrossColumnConstraint> crossConstraints = new ArrayList<>();
        collectValues(whereExpr, columnValues, columnLiteralValues, allCols, crossConstraints);

        if (DATA_MONITOR) {
            System.err.println();
            System.err.println("  [2] Values extracted from WHERE:");
            System.err.println("  ");
            for (SQLite3Column col : allCols) {
                List<Long> vals = columnValues.get(col.getName());
                List<String> literals = columnLiteralValues.get(col.getName());
                String display = formatValueList(vals);
                String literalDisplay = literals.isEmpty() ? "" : " literals=" + literals;
                String marker = vals.isEmpty() && literals.isEmpty() ? "  (not referenced; defaults)" : "";
                System.err.printf("  %s (%s): %s%s%s%n", col.getName(), col.getType(), display, literalDisplay,
                        marker);
            }
        }

        // 3. Ensure defaults (varied by column type when no values were extracted)
        for (SQLite3Column col : allCols) {
            List<Long> vals = columnValues.get(col.getName());
            if (vals.isEmpty()) {
                // Numeric defaults for all columns as fallback
                vals.add(0L); vals.add(1L); vals.add(-1L);
                // Extra text-like defaults for TEXT columns
                if (col.getType() == sqlancer.sqlite3.schema.SQLite3DataType.TEXT) {
                    vals.add(TEXT_EMPTY);
                    vals.add(TEXT_SHORT);
                    vals.add(TEXT_NUMERIC);
                }
            }
            ensureDefaultColumnLiterals(col, columnLiteralValues.get(col.getName()));
        }

        // 4. Insert into each table
        for (SQLite3Table table : targetTables.getTables()) {
            if (generateInserts(sc, table, columnValues, columnLiteralValues, crossConstraints) == 0) {
                throw new IgnoreMeException();
            }
        }

        if (DATA_MONITOR) {
            System.err.println();
            System.err.println("  [3] Data after insertion (SELECT *):");
            System.err.println("  ");
            for (SQLite3Table table : targetTables.getTables()) {
                String tableName = table.getName();
                System.err.printf("  Table: %s%n", tableName);
                Statement s = sc.createStatement();
                try {
                    java.sql.ResultSet rs = s.executeQuery("SELECT * FROM \"" + tableName + "\"");
                    int nCols = rs.getMetaData().getColumnCount();
                    int rowNum = 0;
                    while (rs.next()) {
                        StringBuilder row = new StringBuilder();
                        row.append("  row[");
                        row.append(rowNum);
                        row.append("] ");
                        for (int c = 1; c <= nCols; c++) {
                            if (c > 1) row.append(" | ");
                            String val = rs.getString(c);
                            row.append(val == null ? "NULL" : (val.length() > 12 ? val.substring(0, 11) + "..." : val));
                        }
                        System.err.println(row);
                        rowNum++;
                    }
                    rs.close();
                } catch (Exception e) {
                    System.err.println("  (error reading table)");
                }
                s.close();
            }
            System.err.println();
        }
    }

    private static int generateInserts(sqlancer.SQLConnection sc, SQLite3Table table,
            Map<String, List<Long>> columnValues,
            Map<String, List<String>> columnLiteralValues,
            List<CrossColumnConstraint> crossConstraints) throws java.sql.SQLException {
        List<SQLite3Column> cols = getWritableColumns(table);
        if (cols.isEmpty()) {
            return 0;
        }
        int extraRows = crossConstraints.isEmpty() ? 0 : 6 * crossConstraints.size();
        // Grow the base row count with the largest per-column value pool so the
        // modulo cycling below can actually insert every collected boundary
        // value. Without this, pools longer than TARGET_ROWS-1 would silently
        // drop their tail entries.
        int maxPoolSize = 0;
        for (SQLite3Column col : cols) {
            List<Long> pool = columnValues.get(col.getName());
            List<String> literalPool = columnLiteralValues.get(col.getName());
            if (pool != null) {
                maxPoolSize = Math.max(maxPoolSize, pool.size());
            }
            if (literalPool != null) {
                maxPoolSize = Math.max(maxPoolSize, literalPool.size());
            }
        }
        int baseRows = Math.max(TARGET_ROWS, Math.min(40, maxPoolSize + 8));
        int totalRows = baseRows + extraRows;
        int insertedRows = 0;

        for (int r = 0; r < totalRows; r++) {
            StringBuilder sb = new StringBuilder();
            sb.append("INSERT INTO \"").append(table.getName()).append("\" (").append(columnList(cols))
                    .append(") VALUES (");
            for (int c = 0; c < cols.size(); c++) {
                if (c > 0) sb.append(", ");
                String colName = cols.get(c).getName();
                List<Long> pool = columnValues.get(colName);
                List<String> literalPool = columnLiteralValues.get(colName);
                if ((pool == null || pool.isEmpty()) && (literalPool == null || literalPool.isEmpty())) {
                    sb.append("NULL");
                    continue;
                }
                if (r == 0) { sb.append("NULL"); }
                else if (r < baseRows) {
                    // Normal rows: modulo cycling
                    if (literalPool != null && !literalPool.isEmpty()
                            && (pool == null || pool.isEmpty() || shouldUseLiteralPool(cols.get(c), literalPool, r))) {
                        sb.append(literalPool.get((r - 1) % literalPool.size()));
                    } else {
                        long val = pool.get((r - 1) % pool.size());
                        sb.append(valueToSql(val));
                    }
                } else {
                    // Cross-column specialized rows. The offset has to be relative
                    // to baseRows, which is where this branch starts: baseRows grows
                    // with the largest value pool, so subtracting the fixed
                    // TARGET_ROWS overshot the constraint list whenever a pool was
                    // bigger than TARGET_ROWS - 8.
                    int extraIdx = r - baseRows;
                    int constraintIdx = extraIdx / 6;
                    int subRow = extraIdx % 6;
                    if (constraintIdx >= crossConstraints.size()) {
                        sb.append("NULL");
                        continue;
                    }
                    CrossColumnConstraint cc = crossConstraints.get(constraintIdx);
                    sb.append(crossColValue(colName, cc, subRow, pool, columnValues));
                }
            }
            sb.append(")");
            Statement s = sc.createStatement();
            try { s.execute(sb.toString()); insertedRows++; } catch (Exception ignored) {}
            s.close();
        }
        return insertedRows;
    }

    private static void ensureDefaultColumnLiterals(SQLite3Column col, List<String> literalPool) {
        if (literalPool == null || !literalPool.isEmpty()) {
            return;
        }
        switch (col.getType()) {
            case TEXT:
                for (String text : defaultTextValues()) {
                    addUnique(literalPool, sqlString(text));
                }
                break;
            case REAL:
                literalPool.addAll(defaultRealSqlValues());
                break;
            case BINARY:
                literalPool.addAll(defaultBlobSqlValues());
                break;
            case NONE:
                literalPool.addAll(defaultRealSqlValues());
                for (String text : defaultTextValues()) {
                    addUnique(literalPool, sqlString(text));
                }
                literalPool.addAll(defaultBlobSqlValues());
                break;
            case INT:
            case NULL:
            default:
                break;
        }
    }

    private static boolean shouldUseLiteralPool(SQLite3Column col, List<String> literalPool, int rowIndex) {
        if (literalPool == null || literalPool.isEmpty()) {
            return false;
        }
        switch (col.getType()) {
            case TEXT:
            case BINARY:
            case NONE:
                return true;
            case REAL:
                return rowIndex % 2 == 1;
            case INT:
            case NULL:
            default:
                return rowIndex % 4 == 1;
        }
    }

    private static List<SQLite3Column> getWritableColumns(SQLite3Table table) {
        return table.getColumns().stream()
                .filter(c -> !c.isGenerated())
                .collect(java.util.stream.Collectors.toList());
    }

    private static String columnList(List<SQLite3Column> cols) {
        return cols.stream()
                .map(c -> "\"" + c.getName().replace("\"", "\"\"") + "\"")
                .collect(java.util.stream.Collectors.joining(", "));
    }

    /** Generate a value for a column in a cross-column specialized row. */
    private static String crossColValue(String colName, CrossColumnConstraint cc, int subRow,
            List<Long> ownPool, Map<String, List<Long>> allPools) {
        boolean isA = cc.colA.getName().equals(colName);
        boolean isB = cc.colB.getName().equals(colName);
        if (!isA && !isB) {
            // Uninvolved column ?use first non-NULL value from pool
            for (long v : ownPool) {
                if (v != NULL_MARKER) return valueToSql(v);
            }
            return "NULL";
        }

        List<Long> poolA = allPools.get(cc.colA.getName());
        List<Long> poolB = allPools.get(cc.colB.getName());

        // Get non-NULL values from each pool
        long valA = firstNonNull(poolA, 0L);
        long valB = firstNonNull(poolB, 0L);
        long otherA = findOther(poolA, valA, 10L);
        long otherB = findOther(poolB, valB, 5L);

        // Pick pair based on subRow
        long pickA, pickB;
        switch (subRow) {
            case 0: // both satisfy ?pickA OP pickB is TRUE
                pickA = satisfyingVal(valA, valB, otherA, otherB, cc.operator);
                pickB = satisfyingValForB(valA, valB, otherA, otherB, cc.operator, pickA);
                break;
            case 1: // left violates ?pickA OP pickB is FALSE
                pickA = violatingVal(valA, valB, otherA, otherB, cc.operator);
                pickB = valB;
                break;
            case 2: // right violates ?pickB OP pickA is FALSE for opposite direction
                pickA = valA;
                pickB = violatingVal(valB, valA, otherB, otherA, flipOp(cc.operator));
                break;
            case 3: // boundary ?try equality or off-by-one
                pickA = valA;
                pickB = valA;
                break;
            case 4: // NULL left
                return isA ? "NULL" : valueToSql(valB);
            case 5: // NULL right
                return isB ? "NULL" : valueToSql(valA);
            default:
                pickA = valA; pickB = valB;
        }

        if (isA) return valueToSql(pickA);
        else return valueToSql(pickB);
    }

    private static long firstNonNull(List<Long> pool, long def) {
        for (long v : pool) { if (v != NULL_MARKER) return v; }
        return def;
    }

    private static long findOther(List<Long> pool, long exclude, long def) {
        for (long v : pool) { if (v != NULL_MARKER && v != exclude) return v; }
        return def;
    }

    private static long satisfyingVal(long a, long b, long altA, long altB,
            BinaryComparisonOperator op) {
        if (evaluateConstraint(a, op, b)) return a;
        if (evaluateConstraint(altA, op, b)) return altA;
        if (evaluateConstraint(a, op, altB)) return a;
        // Synthesize a value that satisfies
        switch (op) {
            case GREATER: case GREATER_EQUALS: return b + 5;
            case SMALLER: case SMALLER_EQUALS: return b - 5;
            case EQUALS: return b;
            case NOT_EQUALS: return b + 1;
            default: return a;
        }
    }

    private static long satisfyingValForB(long a, long b, long altA, long altB,
            BinaryComparisonOperator op, long pickA) {
        if (evaluateConstraint(pickA, op, b)) return b;
        if (evaluateConstraint(pickA, op, altB)) return altB;
        switch (op) {
            case GREATER: case GREATER_EQUALS: return pickA - 1;
            case SMALLER: case SMALLER_EQUALS: return pickA + 1;
            case EQUALS: return pickA;
            case NOT_EQUALS: return pickA + 1;
            default: return b;
        }
    }

    private static long violatingVal(long a, long b, long altA, long altB,
            BinaryComparisonOperator op) {
        if (!evaluateConstraint(a, op, b)) return a;
        if (!evaluateConstraint(altA, op, b)) return altA;
        if (!evaluateConstraint(a, op, altB)) return a;
        switch (op) {
            case GREATER: return b - 1;
            case GREATER_EQUALS: return b - 1;
            case SMALLER: return b + 1;
            case SMALLER_EQUALS: return b + 1;
            case EQUALS: return b + 1;
            case NOT_EQUALS: return b;
            default: return a;
        }
    }

    private static boolean evaluateConstraint(long leftVal,
            BinaryComparisonOperator op, long rightVal) {
        switch (op) {
            case EQUALS: return leftVal == rightVal;
            case NOT_EQUALS: return leftVal != rightVal;
            case SMALLER: return leftVal < rightVal;
            case GREATER: return leftVal > rightVal;
            case SMALLER_EQUALS: return leftVal <= rightVal;
            case GREATER_EQUALS: return leftVal >= rightVal;
            default: return true;
        }
    }


    /** Convert a marker value to its SQL literal representation. */
    private static String valueToSql(long val) {
        if (val == NULL_MARKER) return "NULL";
        if (val == TEXT_EMPTY) return "''";
        if (val == TEXT_SHORT) return "'abc'";
        if (val == TEXT_NUMERIC) return "'42'";
        return String.valueOf(val);
    }

    private static void collectValues(SQLite3Expression expr,
            Map<String, List<Long>> values, Map<String, List<String>> literalValues,
            List<SQLite3Column> allCols,
            List<CrossColumnConstraint> crossConstraints) {
        if (expr == null) return;
        if (expr instanceof Sqlite3BinaryOperation) {
            Sqlite3BinaryOperation b = (Sqlite3BinaryOperation) expr;
            collectValues(b.getLeft(), values, literalValues, allCols, crossConstraints);
            collectValues(b.getRight(), values, literalValues, allCols, crossConstraints);
        } else if (expr instanceof BinaryComparisonOperation) {
            BinaryComparisonOperation c = (BinaryComparisonOperation) expr;
            handleCmp(c.getLeft(), c.getRight(), c.getOperator(), values, literalValues, allCols, crossConstraints);
        } else if (expr instanceof BetweenOperation) {
            BetweenOperation b = (BetweenOperation) expr;
            SQLite3Column col = findColumnInExpr(b.getExpression(), allCols);
            if (col != null) {
                if (!addBetweenLiteralValues(col, b.getLeft(), b.getRight(), values, literalValues)) {
                    List<Long> v = values.get(col.getName());
                    long lo = extractLong(b.getLeft(), 10);
                    long hi = extractLong(b.getRight(), 20);
                    v.add((lo + hi) / 2); v.add(lo - 1); v.add(hi + 1);
                    v.add(lo); v.add(hi); v.add(NULL_MARKER);
                }
            }
        } else if (expr instanceof SQLite3UnaryOperation) {
            collectValues(((SQLite3UnaryOperation) expr).getExpression(), values, literalValues, allCols,
                    crossConstraints);
        } else if (expr instanceof SQLite3PostfixUnaryOperation) {
            // 先递归进去再加 0/1/NULL。以前只加 0/1/NULL 就返回，于是
            // `(c0 < 0.2289) IS TRUE` 里那个 0.2289 整个丢掉，该列只能吃默认值，
            // 边界三点全没了。
            SQLite3Expression inner = ((SQLite3PostfixUnaryOperation) expr).getExpression();
            collectValues(inner, values, literalValues, allCols, crossConstraints);
            SQLite3Column col = findColumnInExpr(inner, allCols);
            if (col != null) {
                List<Long> v = values.get(col.getName());
                v.add(0L); v.add(1L); v.add(NULL_MARKER);
            }
        } else if (expr instanceof CollateOperation) {
            // COLLATE / CAST 只是包装，里面的比较照样可以反推
            collectValues(((CollateOperation) expr).getExpression(), values, literalValues, allCols, crossConstraints);
        } else if (expr instanceof SQLite3Expression.Cast) {
            collectValues(((SQLite3Expression.Cast) expr).getExpression(), values, literalValues, allCols,
                    crossConstraints);
        } else if (expr instanceof SQLite3Case) {
            SQLite3Case caseExpr = (SQLite3Case) expr;
            if (caseExpr instanceof SQLite3Case.SQLite3CaseWithBaseExpression) {
                collectValues(((SQLite3Case.SQLite3CaseWithBaseExpression) caseExpr).getBaseExpr(), values,
                        literalValues, allCols, crossConstraints);
            }
            for (SQLite3Case.CasePair pair : caseExpr.getPairs()) {
                collectValues(pair.getCond(), values, literalValues, allCols, crossConstraints);
                collectValues(pair.getThen(), values, literalValues, allCols, crossConstraints);
            }
            collectValues(caseExpr.getElseExpr(), values, literalValues, allCols, crossConstraints);
        } else if (expr instanceof SQLite3RowValueExpression) {
            for (SQLite3Expression part : ((SQLite3RowValueExpression) expr).getExpressions()) {
                collectValues(part, values, literalValues, allCols, crossConstraints);
            }
        } else if (expr instanceof SQLite3Expression.MatchOperation) {
            SQLite3Expression.MatchOperation match = (SQLite3Expression.MatchOperation) expr;
            collectValues(match.getLeft(), values, literalValues, allCols, crossConstraints);
            collectValues(match.getRight(), values, literalValues, allCols, crossConstraints);
        } else if (expr instanceof SQLite3Expression.InOperation) {
            handleIn((SQLite3Expression.InOperation) expr, values, literalValues, allCols, crossConstraints);
        } else if (expr instanceof SQLite3Expression.Function) {
            handleFunction((SQLite3Expression.Function) expr, values, literalValues, allCols, crossConstraints);
        }
    }

    /**
     * `c0 IN (1, 2, 3)` 的列表字面量以前全丢。把它们直接塞进左侧列的池：命中列表里的值才让谓词为真，
     * 同时补一个列表外的值（最大值 + 1）作为“刚好不满足”的对照。
     */
    private static void handleIn(SQLite3Expression.InOperation in,
            Map<String, List<Long>> values, Map<String, List<String>> literalValues,
            List<SQLite3Column> allCols, List<CrossColumnConstraint> crossConstraints) {
        collectValues(in.getLeft(), values, literalValues, allCols, crossConstraints);
        List<SQLite3Expression> list = in.getRightExpressionList();
        if (list == null) {
            return; // IN (SELECT ...) 无法静态取值
        }
        SQLite3Column col = findColumnInExpr(in.getLeft(), allCols);
        if (col == null) {
            for (SQLite3Expression item : list) {
                collectValues(item, values, literalValues, allCols, crossConstraints);
            }
            return;
        }
        long maxInt = Long.MIN_VALUE;
        boolean sawInt = false;
        for (SQLite3Expression item : list) {
            if (!(item instanceof SQLite3Constant)) {
                continue;
            }
            SQLite3Constant c = (SQLite3Constant) item;
            if (c.isNull()) {
                values.get(col.getName()).add(NULL_MARKER);
                continue;
            }
            try {
                switch (c.getDataType()) {
                    case INT:
                        long v = c.asInt();
                        values.get(col.getName()).add(v);
                        maxInt = Math.max(maxInt, v);
                        sawInt = true;
                        break;
                    case REAL:
                        addSqlLiteral(literalValues, col.getName(), String.valueOf(c.asDouble()));
                        break;
                    case TEXT:
                        addTextLiteral(literalValues, col.getName(), c.asString());
                        break;
                    case BINARY:
                        addBlobCmpValues(literalValues, col.getName(), c.asBinary(),
                                BinaryComparisonOperator.EQUALS, false);
                        break;
                    default:
                        break;
                }
            } catch (Exception ignored) {
            }
        }
        if (sawInt) {
            values.get(col.getName()).add(maxInt + 1); // 列表外的对照值
        }
    }

    /**
     * 函数包住列时的反推。只做能确定反解的几个：其余情况递归进参数，至少把参数里的字面量捞出来。
     */
    private static void handleFunction(SQLite3Expression.Function fn,
            Map<String, List<Long>> values, Map<String, List<String>> literalValues,
            List<SQLite3Column> allCols, List<CrossColumnConstraint> crossConstraints) {
        for (SQLite3Expression arg : fn.getArguments()) {
            collectValues(arg, values, literalValues, allCols, crossConstraints);
        }
        SQLite3Expression[] args = fn.getArguments();
        if (args.length == 0) {
            return;
        }
        SQLite3Column col = findColumnInExpr(args[0], allCols);
        if (col == null) {
            return;
        }
        String name = fn.getName() == null ? "" : fn.getName().toLowerCase(java.util.Locale.ROOT);
        List<Long> pool = values.get(col.getName());
        switch (name) {
            case "abs":
                // abs(c0) 的结果只覆盖非负值，补上正负两侧和 0
                pool.add(0L); pool.add(1L); pool.add(-1L); pool.add(NULL_MARKER);
                break;
            case "length":
                // 让长度覆盖 0/1/3，配合文本池
                addTextLiteral(literalValues, col.getName(), "");
                addTextLiteral(literalValues, col.getName(), "a");
                addTextLiteral(literalValues, col.getName(), "abc");
                break;
            case "upper":
            case "lower":
                // 大小写两侧都给，才可能命中 upper(c0)='ABC' 这类
                addTextLiteral(literalValues, col.getName(), "abc");
                addTextLiteral(literalValues, col.getName(), "ABC");
                addTextLiteral(literalValues, col.getName(), "AbC");
                break;
            case "trim":
            case "ltrim":
            case "rtrim":
                addTextLiteral(literalValues, col.getName(), "  abc  ");
                addTextLiteral(literalValues, col.getName(), "abc");
                break;
            case "typeof":
                // 每种存储类各来一个，让 typeof(c0)='...' 有机会命中
                pool.add(1L); pool.add(NULL_MARKER);
                addSqlLiteral(literalValues, col.getName(), "1.5");
                addTextLiteral(literalValues, col.getName(), "abc");
                addSqlLiteral(literalValues, col.getName(), "x'6162'");
                break;
            case "hex":
            case "quote":
                addSqlLiteral(literalValues, col.getName(), "x'6162'");
                addTextLiteral(literalValues, col.getName(), "ab");
                break;
            default:
                break;
        }
    }


    //  Enhanced handleCmp with arithmetic inversion and cross-column detection 

    private static void handleCmp(SQLite3Expression left, SQLite3Expression right,
            BinaryComparisonOperator op,
            Map<String, List<Long>> values, Map<String, List<String>> literalValues,
            List<SQLite3Column> allCols,
            List<CrossColumnConstraint> crossConstraints) {

        // Step 1: Try bare column on left, constant on right
        if (trySimpleCmp(left, right, op, false, values, literalValues, allCols)) return;
        // Step 2: Try bare column on right, constant on left (flipped)
        if (trySimpleCmp(right, left, op, true, values, literalValues, allCols)) return;

        // Step 3: Try arithmetic inversion ?column inside expression vs constant
        if (tryArithInvert(left, right, op, false, values, allCols)) return;
        if (tryArithInvert(right, left, op, true, values, allCols)) return;

        // Step 4: Cross-column detection ?both sides reference columns
        SQLite3Column colA = findColumnInExpr(left, allCols);
        SQLite3Column colB = findColumnInExpr(right, allCols);
        if (colA != null && colB != null) {
            crossConstraints.add(new CrossColumnConstraint(colA, colB, op));
            // Ensure both columns have at least basic values
            ensureBasicValues(values, colA.getName());
            ensureBasicValues(values, colB.getName());
        }
    }

    /** Bare column OP constant ?same as old handleCmp path. */
    private static boolean trySimpleCmp(SQLite3Expression colSide, SQLite3Expression litSide,
            BinaryComparisonOperator op, boolean flipped,
            Map<String, List<Long>> values, Map<String, List<String>> literalValues,
            List<SQLite3Column> allCols) {
        SQLite3Column col = findColumnInExpr(colSide, allCols);
        if (col == null) return false;
        if (!(litSide instanceof SQLite3Constant)) return false;
        SQLite3Constant c = (SQLite3Constant) litSide;
        if (c.isNull()) return false;
        if (c.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.INT) {
            addCmpValues(values, col.getName(), c.asInt(), op, flipped);
        } else if (c.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.REAL) {
            addRealCmpValues(literalValues, col.getName(), c.asDouble(), op, flipped);
        } else if (c.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.TEXT) {
            addTextCmpValues(literalValues, col.getName(), c.asString(), op, flipped);
        } else if (c.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.BINARY) {
            addBlobCmpValues(literalValues, col.getName(), c.asBinary(), op, flipped);
        } else {
            return false;
        }
        return true;
    }

    /** (col-expr) OP constant ?invert arithmetic to get bare column constraint. */
    private static boolean tryArithInvert(SQLite3Expression colSide, SQLite3Expression litSide,
            BinaryComparisonOperator op, boolean flipped,
            Map<String, List<Long>> values, List<SQLite3Column> allCols) {
        ColumnExtraction ext = findColumnWithPath(colSide, allCols);
        if (ext == null || ext.isSimple()) return false; // simple case already handled
        if (!(litSide instanceof SQLite3Constant)) return false;
        SQLite3Constant c = (SQLite3Constant) litSide;
        if (c.isNull()) return false;
        long litVal;
        try { litVal = c.asInt(); } catch (Exception e) { return false; }

        BinaryComparisonOperator curOp = flipped ? flipOp(op) : op;
        long curVal = litVal;

        // Walk arithmetic path outermost ?innermost (reverse of path order)
        for (int i = ext.path.size() - 1; i >= 0; i--) {
            ArithStep step = ext.path.get(i);
            long K = step.literal;
            Sqlite3BinaryOperation.BinaryOperator aOp = step.op;

            if (step.literalOnLeft) {
                // (K OP inner) CMP V
                if (aOp == Sqlite3BinaryOperation.BinaryOperator.PLUS) {
                    curVal = curVal - K;
                } else if (aOp == Sqlite3BinaryOperation.BinaryOperator.MINUS) {
                    curVal = K - curVal;
                    curOp = flipOp(curOp);
                } else if (aOp == Sqlite3BinaryOperation.BinaryOperator.MULTIPLY) {
                    if (K == 0) return false;
                    curVal = curVal / K;
                    if (K < 0) curOp = flipOp(curOp);
                } else {
                    return false; // DIVIDE, REMAINDER, bitwise, concat ?skip
                }
            } else {
                // (inner OP K) CMP V
                if (aOp == Sqlite3BinaryOperation.BinaryOperator.PLUS) {
                    curVal = curVal - K;
                } else if (aOp == Sqlite3BinaryOperation.BinaryOperator.MINUS) {
                    curVal = curVal + K;
                } else if (aOp == Sqlite3BinaryOperation.BinaryOperator.MULTIPLY) {
                    if (K == 0) return false;
                    curVal = curVal / K;
                    if (K < 0) curOp = flipOp(curOp);
                } else if (aOp == Sqlite3BinaryOperation.BinaryOperator.DIVIDE) {
                    if (K == 0) return false;
                    curVal = curVal * K;
                } else {
                    return false;
                }
            }
        }

        addCmpValues(values, ext.column.getName(), curVal, curOp, false);
        return true;
    }

    private static boolean addBetweenLiteralValues(SQLite3Column col, SQLite3Expression left,
            SQLite3Expression right, Map<String, List<Long>> values, Map<String, List<String>> literalValues) {
        if (!(left instanceof SQLite3Constant) || !(right instanceof SQLite3Constant)) {
            return false;
        }
        SQLite3Constant lo = (SQLite3Constant) left;
        SQLite3Constant hi = (SQLite3Constant) right;
        if (lo.isNull() || hi.isNull()) {
            return false;
        }
        String colName = col.getName();
        if (lo.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.TEXT
                || hi.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.TEXT) {
            String loText = constantAsTextSeed(lo);
            String hiText = constantAsTextSeed(hi);
            addTextLiteral(literalValues, colName, loText);
            addTextLiteral(literalValues, colName, hiText);
            addTextLiteral(literalValues, colName, loText + "m");
            addTextLiteral(literalValues, colName, "");
            addTextLiteral(literalValues, colName, hiText + "z");
            return true;
        }
        if (lo.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.REAL
                || hi.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.REAL) {
            double loReal = constantAsDoubleSeed(lo, 10.0);
            double hiReal = constantAsDoubleSeed(hi, 20.0);
            addSqlLiteral(literalValues, colName, sqlReal((loReal + hiReal) / 2.0));
            addSqlLiteral(literalValues, colName, sqlReal(loReal));
            addSqlLiteral(literalValues, colName, sqlReal(hiReal));
            addSqlLiteral(literalValues, colName, sqlReal(loReal - 1.0));
            addSqlLiteral(literalValues, colName, sqlReal(hiReal + 1.0));
            return true;
        }
        if (lo.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.BINARY
                || hi.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.BINARY) {
            addSqlLiteral(literalValues, colName, constantAsBlobSqlSeed(lo));
            addSqlLiteral(literalValues, colName, constantAsBlobSqlSeed(hi));
            addSqlLiteral(literalValues, colName, "x''");
            addSqlLiteral(literalValues, colName, "x'00'");
            addSqlLiteral(literalValues, colName, "x'ff'");
            return true;
        }
        return false;
    }

    private static void addRealCmpValues(Map<String, List<String>> literalValues, String colName,
            double val, BinaryComparisonOperator op, boolean flipped) {
        if (!Double.isFinite(val)) {
            return;
        }
        BinaryComparisonOperator effectiveOp = flipped ? flipOp(op) : op;
        double step = Math.max(1.0, Math.abs(val) * 0.001);
        switch (effectiveOp) {
            case EQUALS:
                addSqlLiteral(literalValues, colName, sqlReal(val));
                addSqlLiteral(literalValues, colName, sqlReal(val + step));
                break;
            case NOT_EQUALS:
                addSqlLiteral(literalValues, colName, sqlReal(val + step));
                addSqlLiteral(literalValues, colName, sqlReal(val));
                break;
            case SMALLER:
                addSqlLiteral(literalValues, colName, sqlReal(val - step));
                addSqlLiteral(literalValues, colName, sqlReal(val));
                addSqlLiteral(literalValues, colName, sqlReal(val + step));
                break;
            case SMALLER_EQUALS:
                addSqlLiteral(literalValues, colName, sqlReal(val));
                addSqlLiteral(literalValues, colName, sqlReal(val - step));
                addSqlLiteral(literalValues, colName, sqlReal(val + step));
                break;
            case GREATER:
                addSqlLiteral(literalValues, colName, sqlReal(val + step));
                addSqlLiteral(literalValues, colName, sqlReal(val));
                addSqlLiteral(literalValues, colName, sqlReal(val - step));
                break;
            case GREATER_EQUALS:
                addSqlLiteral(literalValues, colName, sqlReal(val));
                addSqlLiteral(literalValues, colName, sqlReal(val + step));
                addSqlLiteral(literalValues, colName, sqlReal(val - step));
                break;
            default:
                addSqlLiteral(literalValues, colName, sqlReal(val));
                break;
        }
    }

    private static void addTextCmpValues(Map<String, List<String>> literalValues, String colName,
            String val, BinaryComparisonOperator op, boolean flipped) {
        if (val == null) {
            return;
        }
        if (op == BinaryComparisonOperator.LIKE) {
            if (flipped) {
                addTextLiteral(literalValues, colName, "%");
                addTextLiteral(literalValues, colName, "%" + val + "%");
                addTextLiteral(literalValues, colName, val);
            } else {
                addTextLiteral(literalValues, colName, concreteLikeValue(val));
                addTextLiteral(literalValues, colName, val);
            }
            return;
        }
        if (op == BinaryComparisonOperator.GLOB) {
            if (flipped) {
                addTextLiteral(literalValues, colName, "*");
                addTextLiteral(literalValues, colName, "*" + val + "*");
                addTextLiteral(literalValues, colName, val);
            } else {
                addTextLiteral(literalValues, colName, concreteGlobValue(val));
                addTextLiteral(literalValues, colName, val);
            }
            return;
        }

        BinaryComparisonOperator effectiveOp = flipped ? flipOp(op) : op;
        switch (effectiveOp) {
            case EQUALS:
                addTextLiteral(literalValues, colName, val);
                addTextLiteral(literalValues, colName, val + "z");
                addTextLiteral(literalValues, colName, "");
                break;
            case NOT_EQUALS:
                addTextLiteral(literalValues, colName, val + "z");
                addTextLiteral(literalValues, colName, "");
                addTextLiteral(literalValues, colName, val);
                break;
            case SMALLER:
                addTextLiteral(literalValues, colName, previousTextSeed(val));
                addTextLiteral(literalValues, colName, "");
                addTextLiteral(literalValues, colName, val);
                break;
            case SMALLER_EQUALS:
                addTextLiteral(literalValues, colName, val);
                addTextLiteral(literalValues, colName, previousTextSeed(val));
                addTextLiteral(literalValues, colName, val + "z");
                break;
            case GREATER:
                addTextLiteral(literalValues, colName, val + "z");
                addTextLiteral(literalValues, colName, "zzzz");
                addTextLiteral(literalValues, colName, val);
                break;
            case GREATER_EQUALS:
                addTextLiteral(literalValues, colName, val);
                addTextLiteral(literalValues, colName, val + "z");
                addTextLiteral(literalValues, colName, previousTextSeed(val));
                break;
            default:
                addTextLiteral(literalValues, colName, val);
                break;
        }
        LinkedHashSet<String> derived = new LinkedHashSet<>();
        derived.add(val);
        addTextDerivatives(derived, val);
        for (String text : derived) {
            addTextLiteral(literalValues, colName, text);
        }
    }

    private static void addBlobCmpValues(Map<String, List<String>> literalValues, String colName,
            byte[] bytes, BinaryComparisonOperator op, boolean flipped) {
        String blob = bytesToBlobSql(bytes);
        BinaryComparisonOperator effectiveOp = flipped ? flipOp(op) : op;
        switch (effectiveOp) {
            case EQUALS:
                addSqlLiteral(literalValues, colName, blob);
                addSqlLiteral(literalValues, colName, "x''");
                break;
            case NOT_EQUALS:
                addSqlLiteral(literalValues, colName, "x''");
                addSqlLiteral(literalValues, colName, "x'00'");
                addSqlLiteral(literalValues, colName, blob);
                break;
            case SMALLER:
            case SMALLER_EQUALS:
                addSqlLiteral(literalValues, colName, "x''");
                addSqlLiteral(literalValues, colName, blob);
                addSqlLiteral(literalValues, colName, "x'ff'");
                break;
            case GREATER:
            case GREATER_EQUALS:
                addSqlLiteral(literalValues, colName, "x'ff'");
                addSqlLiteral(literalValues, colName, blob);
                addSqlLiteral(literalValues, colName, "x''");
                break;
            default:
                addSqlLiteral(literalValues, colName, blob);
                break;
        }
    }

    private static void addTextLiteral(Map<String, List<String>> literalValues, String colName, String value) {
        addSqlLiteral(literalValues, colName, sqlString(value == null ? "" : value));
    }

    private static void addSqlLiteral(Map<String, List<String>> literalValues, String colName, String sqlLiteral) {
        if (sqlLiteral == null || sqlLiteral.isBlank()) {
            return;
        }
        List<String> values = literalValues.get(colName);
        if (values == null || values.size() >= 24 || values.contains(sqlLiteral)) {
            return;
        }
        values.add(sqlLiteral);
    }

    private static String constantAsTextSeed(SQLite3Constant constant) {
        if (constant.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.TEXT) {
            return constant.asString();
        }
        if (constant.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.INT) {
            return String.valueOf(constant.asInt());
        }
        if (constant.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.REAL) {
            return sqlReal(constant.asDouble());
        }
        if (constant.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.BINARY) {
            return constantAsBlobSqlSeed(constant);
        }
        return "";
    }

    private static double constantAsDoubleSeed(SQLite3Constant constant, double fallback) {
        try {
            if (constant.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.REAL) {
                return constant.asDouble();
            }
            if (constant.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.INT) {
                return constant.asInt();
            }
        } catch (RuntimeException ignored) {
        }
        return fallback;
    }

    private static String constantAsBlobSqlSeed(SQLite3Constant constant) {
        if (constant.getDataType() == sqlancer.sqlite3.schema.SQLite3DataType.BINARY) {
            return bytesToBlobSql(constant.asBinary());
        }
        return "CAST(" + sqlString(constantAsTextSeed(constant)) + " AS BLOB)";
    }

    private static String sqlReal(double value) {
        if (!Double.isFinite(value)) {
            return "0.0";
        }
        String result = Double.toString(value);
        return result.contains(".") || result.contains("E") || result.contains("e") ? result : result + ".0";
    }

    private static String previousTextSeed(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        if (value.length() == 1) {
            return "";
        }
        return value.substring(0, value.length() - 1);
    }

    private static String bytesToBlobSql(byte[] bytes) {
        StringBuilder sb = new StringBuilder("x'");
        for (byte b : bytes) {
            int value = b & 0xff;
            if (value < 16) {
                sb.append('0');
            }
            sb.append(Integer.toHexString(value));
        }
        sb.append("'");
        return sb.toString();
    }

    /** Append comparison boundary values for a bare column to its pool. */
    private static void addCmpValues(Map<String, List<Long>> values, String colName,
            long val, BinaryComparisonOperator op, boolean flipped) {
        List<Long> v = values.get(colName);
        switch (op) {
            case EQUALS: v.add(val); v.add(val+1); v.add(NULL_MARKER); break;
            case NOT_EQUALS: v.add(val+1); v.add(val); v.add(NULL_MARKER); break;
            case SMALLER: if(flipped){v.add(val+1);v.add(val);v.add(val-1);}else{v.add(val-1);v.add(val);v.add(val+1);} v.add(NULL_MARKER); break;
            case GREATER: if(flipped){v.add(val-1);v.add(val);v.add(val+1);}else{v.add(val+1);v.add(val);v.add(val-1);} v.add(NULL_MARKER); break;
            case SMALLER_EQUALS:if(flipped){v.add(val+1);v.add(val);v.add(val-1);}else{v.add(val);v.add(val-1);v.add(val+1);} v.add(NULL_MARKER); break;
            case GREATER_EQUALS:if(flipped){v.add(val-1);v.add(val);v.add(val+1);}else{v.add(val);v.add(val+1);v.add(val-1);} v.add(NULL_MARKER); break;
            default: break;
        }
    }

    private static BinaryComparisonOperator flipOp(BinaryComparisonOperator op) {
        switch (op) {
            case SMALLER: return BinaryComparisonOperator.GREATER;
            case GREATER: return BinaryComparisonOperator.SMALLER;
            case SMALLER_EQUALS: return BinaryComparisonOperator.GREATER_EQUALS;
            case GREATER_EQUALS: return BinaryComparisonOperator.SMALLER_EQUALS;
            default: return op; // EQUALS, NOT_EQUALS are symmetric
        }
    }

    private static void ensureBasicValues(Map<String, List<Long>> values, String colName) {
        List<Long> v = values.get(colName);
        if (v.isEmpty()) {
            v.add(0L); v.add(1L); v.add(-1L);
        }
    }

    /** Extract long from a SQLite3Constant, with fallback. */
    private static long extractLong(SQLite3Expression expr, long fallback) {
        if (expr instanceof SQLite3Constant) {
            SQLite3Constant c = (SQLite3Constant) expr;
            if (c.isNull()) return fallback;
            try { return c.asInt(); } catch (Exception e) { return fallback; }
        }
        return fallback;
    }

    /** Recursive column finder ?penetrates arithmetic and unary wrappers. */
    private static SQLite3Column findColumnInExpr(SQLite3Expression expr, List<SQLite3Column> allCols) {
        if (expr == null) return null;
        if (expr instanceof SQLite3ColumnName) {
            return matchColumn((SQLite3ColumnName) expr, allCols);
        }
        if (expr instanceof SQLite3UnaryOperation) {
            return findColumnInExpr(((SQLite3UnaryOperation) expr).getExpression(), allCols);
        }
        if (expr instanceof SQLite3PostfixUnaryOperation) {
            return findColumnInExpr(((SQLite3PostfixUnaryOperation) expr).getExpression(), allCols);
        }
        // 看穿包装节点：COLLATE / CAST / 单参函数里的列，对比较的反推是可用的
        if (expr instanceof CollateOperation) {
            return findColumnInExpr(((CollateOperation) expr).getExpression(), allCols);
        }
        if (expr instanceof SQLite3Expression.Cast) {
            return findColumnInExpr(((SQLite3Expression.Cast) expr).getExpression(), allCols);
        }
        if (expr instanceof Sqlite3BinaryOperation) {
            Sqlite3BinaryOperation bin = (Sqlite3BinaryOperation) expr;
            // Try left first, then right (only one side can be a column for our purposes)
            SQLite3Column col = findColumnInExpr(bin.getLeft(), allCols);
            if (col != null) return col;
            return findColumnInExpr(bin.getRight(), allCols);
        }
        return null;
    }

    /** Find column with arithmetic path ?for inversion support. */
    private static ColumnExtraction findColumnWithPath(SQLite3Expression expr, List<SQLite3Column> allCols) {
        if (expr == null) return null;
        if (expr instanceof SQLite3ColumnName) {
            SQLite3Column col = matchColumn((SQLite3ColumnName) expr, allCols);
            if (col != null) return new ColumnExtraction(col, new ArrayList<>());
            return null;
        }
        if (expr instanceof SQLite3UnaryOperation) {
            return findColumnWithPath(((SQLite3UnaryOperation) expr).getExpression(), allCols);
        }
        if (expr instanceof Sqlite3BinaryOperation) {
            Sqlite3BinaryOperation bin = (Sqlite3BinaryOperation) expr;
            Sqlite3BinaryOperation.BinaryOperator op = bin.getOperator();
            // Only arithmetic operators are invertible
            if (op != Sqlite3BinaryOperation.BinaryOperator.PLUS
                    && op != Sqlite3BinaryOperation.BinaryOperator.MINUS
                    && op != Sqlite3BinaryOperation.BinaryOperator.MULTIPLY
                    && op != Sqlite3BinaryOperation.BinaryOperator.DIVIDE) {
                return null;
            }
            SQLite3Expression left = bin.getLeft();
            SQLite3Expression right = bin.getRight();

            ColumnExtraction leftExt = findColumnWithPath(left, allCols);
            if (leftExt != null && isConstantExpr(right)) {
                long litVal = extractLong(right, 0);
                leftExt.path.add(new ArithStep(op, litVal, false));
                return leftExt;
            }

            ColumnExtraction rightExt = findColumnWithPath(right, allCols);
            if (rightExt != null && isConstantExpr(left)) {
                long litVal = extractLong(left, 0);
                rightExt.path.add(new ArithStep(op, litVal, true));
                return rightExt;
            }
        }
        return null;
    }

    /** Check if an expression subtree contains no column references. */
    private static boolean isConstantExpr(SQLite3Expression expr) {
        if (expr == null) return true;
        if (expr instanceof SQLite3Constant) return true;
        if (expr instanceof SQLite3ColumnName) return false;
        if (expr instanceof Sqlite3BinaryOperation) {
            Sqlite3BinaryOperation bin = (Sqlite3BinaryOperation) expr;
            return isConstantExpr(bin.getLeft()) && isConstantExpr(bin.getRight());
        }
        if (expr instanceof SQLite3UnaryOperation) {
            return isConstantExpr(((SQLite3UnaryOperation) expr).getExpression());
        }
        if (expr instanceof SQLite3PostfixUnaryOperation) {
            return isConstantExpr(((SQLite3PostfixUnaryOperation) expr).getExpression());
        }
        if (expr instanceof BinaryComparisonOperation) {
            BinaryComparisonOperation cmp = (BinaryComparisonOperation) expr;
            return isConstantExpr(cmp.getLeft()) && isConstantExpr(cmp.getRight());
        }
        return false;
    }

    private static SQLite3Column matchColumn(SQLite3ColumnName colName, List<SQLite3Column> allCols) {
        for (SQLite3Column col : allCols) {
            if (col.getName().equals(colName.getColumn().getName())) return col;
        }
        return null;
    }

    //  Monitoring helpers 

    private static String repeat(String s, int n) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < n; i++) { sb.append(s); }
        return sb.toString();
    }

    private static String formatLong(String s, int maxLen) {
        if (s == null) return "<null>";
        if (s.length() <= maxLen) return s;
        StringBuilder result = new StringBuilder();
        int pos = 0;
        while (pos < s.length() && pos < maxLen * 2) {
            int end = Math.min(pos + maxLen, s.length());
            if (pos > 0) result.append("\n  ");
            result.append(s.substring(pos, end));
            pos = end;
        }
        if (pos < s.length()) result.append("...");
        return result.toString();
    }

    private static String formatValueList(List<Long> vals) {
        if (vals.isEmpty()) return "[]";
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < vals.size(); i++) {
            if (i > 0) sb.append(", ");
            long v = vals.get(i);
            if (v == NULL_MARKER) sb.append("NULL");
            else if (v == TEXT_EMPTY) sb.append("''");
            else if (v == TEXT_SHORT) sb.append("'abc'");
            else if (v == TEXT_NUMERIC) sb.append("'42'");
            else sb.append(v);
        }
        sb.append("]");
        return sb.toString();
    }
}
