package sqlancer.sqlite3.oracle;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

import sqlancer.ComparatorHelper;
import sqlancer.SQLGlobalState;
import sqlancer.common.query.SQLQueryAdapter;
import sqlancer.common.query.SQLancerResultSet;
import sqlancer.sqlite3.SQLite3GlobalState;
import sqlancer.sqlite3.schema.SQLite3Schema.SQLite3Column;
import sqlancer.sqlite3.schema.SQLite3Schema.SQLite3Table;

public final class EGraphExampleLogger {

    private static final String EXAMPLE_PATH = System.getProperty("egraph.examples.file", "");
    private static final int MAX_EXAMPLES = Integer.getInteger("egraph.examples.limit", 20);
    private static final int MAX_ROWS_PER_TABLE = Integer.getInteger("egraph.examples.tableRows", 8);
    private static final int MAX_RESULT_ROWS = Integer.getInteger("egraph.examples.resultRows", 20);
    private static final AtomicInteger EXAMPLE_COUNT = new AtomicInteger();

    private EGraphExampleLogger() {
    }

    public static boolean isEnabled() {
        return !EXAMPLE_PATH.isBlank() && EXAMPLE_COUNT.get() < MAX_EXAMPLES;
    }

    public static void record(SQLGlobalState<?, ?> state, String rewriteQuery, String originalQuery,
            List<String> originalResult, List<String> variantQueries, List<List<String>> variantResults,
            String querySource) {
        if (!(state instanceof SQLite3GlobalState) || !isEnabled()) {
            return;
        }
        int exampleId = EXAMPLE_COUNT.incrementAndGet();
        if (exampleId > MAX_EXAMPLES) {
            return;
        }
        File file = new File(EXAMPLE_PATH);
        File parent = file.getParentFile();
        if (parent != null && !parent.exists()) {
            parent.mkdirs();
        }
        synchronized (EGraphExampleLogger.class) {
            // 显式 UTF-8：默认平台编码在 Windows 上是 GBK，中文标签会乱码。
            try (FileWriter writer = new FileWriter(file, java.nio.charset.StandardCharsets.UTF_8, true)) {
                writer.write("============================================================\n");
                writer.write("EGRAPH 样例 #" + exampleId + "\n");
                writer.write("============================================================\n\n");
                writer.write("[查询来源]\n");
                writer.write((querySource == null || querySource.isBlank() ? "UNKNOWN" : querySource) + "\n\n");
                writer.write("[数据库结构]\n");
                writeSchema((SQLite3GlobalState) state, writer);
                writer.write("\n[源数据表内容]\n");
                writeTableRows((SQLite3GlobalState) state, writer);
                writer.write("\n[裸查询 —— 送给 egraph 求变体的]\n");
                writer.write(rewriteQuery + ";\n");
                writeExecutedQueryResult((SQLite3GlobalState) state, writer, "裸查询结果", rewriteQuery);
                writer.write("\n[原查询 —— 套上 wrapper 后实际执行的]\n");
                writer.write(originalQuery + ";\n");
                writer.write("\n[原查询结果 共 " + originalResult.size() + " 行]\n");
                writeResultRows(writer, originalResult);
                for (int i = 0; i < variantQueries.size(); i++) {
                    List<String> rows = variantResults.get(i);
                    writer.write("\n[变体 #" + (i + 1) + " —— 套上同样 wrapper 后实际执行的]\n");
                    writer.write(variantQueries.get(i) + ";\n");
                    writer.write("\n[变体 #" + (i + 1) + " 结果 共 " + rows.size() + " 行]\n");
                    writeResultRows(writer, rows);
                }
                writer.write("\n");
                writer.flush();
            } catch (Throwable ignored) {
            }
        }
    }

    private static void writeSchema(SQLite3GlobalState state, FileWriter writer) throws IOException {
        String sql = "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL "
                + "AND name NOT LIKE 'sqlite_%' ORDER BY type, name";
        try (SQLancerResultSet rs = new SQLQueryAdapter(sql).executeAndGet(state)) {
            if (rs == null) {
                writer.write("(结构不可读)\n");
                return;
            }
            while (rs.next()) {
                writer.write("-- " + rs.getString(1) + " " + rs.getString(2) + "\n");
                writer.write(rs.getString(3) + ";\n");
            }
        } catch (Exception e) {
            writer.write("(结构不可读: " + e.getMessage() + ")\n");
        }
    }

    private static void writeTableRows(SQLite3GlobalState state, FileWriter writer) throws IOException {
        try {
            state.updateSchema();
        } catch (Exception ignored) {
        }
        Set<String> emittedTables = new HashSet<>();
        for (SQLite3Table table : state.getSchema().getDatabaseTables()) {
            if (table.isView() || table.isVirtual() || table.getColumns().isEmpty()) {
                continue;
            }
            emittedTables.add(normalizeIdentifierKey(table.getName()));
            writer.write("-- table " + table.getName() + " total_rows=" + countRows(state, table.getName()) + "\n");
            List<SQLite3Column> columns = table.getColumns();
            String valueList = columns.stream().map(c -> "quote(" + quoteIdentifier(c.getName()) + ")")
                    .collect(java.util.stream.Collectors.joining(" || ' | ' || "));
            String sql = "SELECT " + valueList + " FROM " + quoteIdentifier(table.getName()) + " LIMIT "
                    + MAX_ROWS_PER_TABLE;
            try (SQLancerResultSet rs = new SQLQueryAdapter(sql).executeAndGet(state)) {
                if (rs == null) {
                    writer.write("(rows unavailable)\n");
                    continue;
                }
                int rows = 0;
                while (rs.next()) {
                    writer.write("  " + rs.getString(1) + "\n");
                    rows++;
                }
                if (rows == 0) {
                    writer.write("  (empty)\n");
                }
            } catch (Exception e) {
                writer.write("  (rows unavailable: " + e.getMessage() + ")\n");
            }
        }
        writeCatalogContextTableRows(state, writer, emittedTables);
    }

    private static void writeCatalogContextTableRows(SQLite3GlobalState state, FileWriter writer,
            Set<String> emittedTables) throws IOException {
        String sql = "SELECT name FROM sqlite_master WHERE type = 'table' AND sql IS NOT NULL "
                + "AND name LIKE 'egraph_%' AND sql NOT LIKE 'CREATE VIRTUAL TABLE%' ORDER BY name";
        try (SQLancerResultSet rs = new SQLQueryAdapter(sql).executeAndGet(state)) {
            if (rs == null) {
                return;
            }
            while (rs.next()) {
                String tableName = rs.getString(1);
                if (tableName == null || emittedTables.contains(normalizeIdentifierKey(tableName))
                        || isLikelyVirtualShadowTable(tableName)) {
                    continue;
                }
                List<String> columns = readColumnNames(state, tableName);
                if (columns.isEmpty()) {
                    continue;
                }
                writer.write("-- table " + tableName + " total_rows=" + countRows(state, tableName) + "\n");
                String valueList = columns.stream().map(c -> "quote(" + quoteIdentifier(c) + ")")
                        .collect(java.util.stream.Collectors.joining(" || ' | ' || "));
                String rowSql = "SELECT " + valueList + " FROM " + quoteIdentifier(tableName) + " LIMIT "
                        + MAX_ROWS_PER_TABLE;
                try (SQLancerResultSet rowRs = new SQLQueryAdapter(rowSql).executeAndGet(state)) {
                    if (rowRs == null) {
                        writer.write("(rows unavailable)\n");
                        continue;
                    }
                    int rows = 0;
                    while (rowRs.next()) {
                        writer.write("  " + rowRs.getString(1) + "\n");
                        rows++;
                    }
                    if (rows == 0) {
                        writer.write("  (empty)\n");
                    }
                } catch (Exception e) {
                    writer.write("  (rows unavailable: " + e.getMessage() + ")\n");
                }
            }
        } catch (Exception e) {
            writer.write("(context rows unavailable: " + e.getMessage() + ")\n");
        }
    }

    private static void writeExecutedQueryResult(SQLite3GlobalState state, FileWriter writer, String label, String query)
            throws IOException {
        try {
            List<String> rows = readQueryRows(state, query);
            writer.write("\n[" + label + " 共 " + rows.size() + " 行]\n");
            writeResultRows(writer, rows);
        } catch (Throwable e) {
            writer.write("\n[" + label + " 无法获取: " + e.getMessage() + "]\n");
        }
    }

    private static List<String> readQueryRows(SQLite3GlobalState state, String query) throws Exception {
        List<String> rows = new ArrayList<>();
        SQLancerResultSet result = null;
        try {
            result = new SQLQueryAdapter(query).executeAndGet(state);
            if (result == null) {
                return rows;
            }
            int columnCount = result.getColumnCount();
            while (result.next()) {
                StringBuilder row = new StringBuilder();
                for (int i = 1; i <= columnCount; i++) {
                    if (i > 1) {
                        row.append('|');
                    }
                    row.append(encodeResultValue(result.getString(i)));
                }
                rows.add(row.toString());
            }
        } finally {
            if (result != null && !result.isClosed()) {
                result.close();
            }
        }
        return rows;
    }

    private static List<String> readColumnNames(SQLite3GlobalState state, String tableName) {
        List<String> result = new java.util.ArrayList<>();
        String sql = "PRAGMA table_info(" + quoteIdentifier(tableName) + ")";
        try (SQLancerResultSet rs = new SQLQueryAdapter(sql).executeAndGet(state)) {
            if (rs == null) {
                return result;
            }
            while (rs.next()) {
                String columnName = rs.getString(2);
                if (columnName != null) {
                    result.add(columnName);
                }
            }
        } catch (Exception ignored) {
        }
        return result;
    }

    private static boolean isLikelyVirtualShadowTable(String tableName) {
        String normalized = normalizeIdentifierKey(tableName);
        return normalized.endsWith("_content") || normalized.endsWith("_segments")
                || normalized.endsWith("_segdir") || normalized.endsWith("_docsize") || normalized.endsWith("_stat")
                || normalized.endsWith("_data") || normalized.endsWith("_idx") || normalized.endsWith("_config")
                || normalized.endsWith("_node") || normalized.endsWith("_parent") || normalized.endsWith("_rowid");
    }

    private static String countRows(SQLite3GlobalState state, String tableName) {
        String sql = "SELECT COUNT(*) FROM " + quoteIdentifier(tableName);
        try (SQLancerResultSet rs = new SQLQueryAdapter(sql).executeAndGet(state)) {
            if (rs == null || !rs.next()) {
                return "unknown";
            }
            return rs.getString(1);
        } catch (Exception ignored) {
            return "unknown";
        }
    }

    private static void writeResultRows(FileWriter writer, List<String> rows) throws IOException {
        int limit = Math.min(rows.size(), MAX_RESULT_ROWS);
        for (int i = 0; i < limit; i++) {
            writer.write("  row[" + i + "] = " + rows.get(i) + "\n");
        }
        if (rows.size() > limit) {
            writer.write("  ... " + (rows.size() - limit) + " more rows\n");
        } else if (rows.isEmpty()) {
            writer.write("  (empty result)\n");
        }
    }

    private static String quoteIdentifier(String identifier) {
        return "\"" + identifier.replace("\"", "\"\"") + "\"";
    }

    private static String encodeResultValue(String value) {
        if (value == null) {
            return "N";
        }
        String canonicalized = ComparatorHelper.canonicalizeResultValue(value.replaceAll("[\\.]0+$", ""));
        return "S" + canonicalized.length() + ":" + canonicalized;
    }

    private static String normalizeIdentifierKey(String identifier) {
        return identifier.toLowerCase(java.util.Locale.ROOT);
    }
}
