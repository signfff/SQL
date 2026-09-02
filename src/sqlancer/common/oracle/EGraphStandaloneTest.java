package sqlancer.common.oracle;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Standalone test: you provide a SQLite database and a SELECT query.
 * This tool sends the query to the egraph server, gets variants,
 * runs both original and variants against YOUR database, and shows
 * the comparison.
 *
 * Usage:
 *   java -cp target\sqlancer-2.0.0.jar sqlancer.common.oracle.EGraphStandaloneTest <database.db> <server-url> "<SQL>"
 *
 * Example:
 *   java -cp target\sqlancer-2.0.0.jar sqlancer.common.oracle.EGraphStandaloneTest mytest.db http://127.0.0.1:3000 "SELECT * FROM t WHERE a > 1 AND b < 10"
 */
public class EGraphStandaloneTest {

    public static void main(String[] args) throws Exception {
        if (args.length < 3) {
            System.err.println("Usage: java -cp target\\sqlancer-2.0.0.jar " +
                    "sqlancer.common.oracle.EGraphStandaloneTest <database.db> <server-url> <SQL>");
            System.err.println();
            System.err.println("Example:");
            System.err.println("  java -cp target\\sqlancer-2.0.0.jar " +
                    "sqlancer.common.oracle.EGraphStandaloneTest mytest.db http://127.0.0.1:3000 " +
                    "\"SELECT * FROM t WHERE a > 1 AND b < 10\"");
            System.exit(1);
        }

        String dbPath = args[0];
        String serverUrl = args[1];
        String originalSql = args[2];

        printSeparator('-', 70);
        System.out.println();
        System.out.println("[1] DATABASE: " + dbPath);
        System.out.println("");

        String url = "jdbc:sqlite:" + dbPath;
        try (Connection conn = DriverManager.getConnection(url)) {

            // Show tables and row counts
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery(
                         "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")) {
                boolean hasTables = false;
                while (rs.next()) {
                    hasTables = true;
                    String tableName = rs.getString(1);
                    try (Statement stmt2 = conn.createStatement();
                         ResultSet rs2 = stmt2.executeQuery(
                                 "SELECT COUNT(*) FROM \"" + tableName + "\"")) {
                        long count = rs2.next() ? rs2.getLong(1) : -1;
                        System.out.printf("  Table '%s': %d rows%n", tableName, count);

                        // Show column names
                        try (ResultSet rs3 = stmt2.executeQuery(
                                "SELECT * FROM \"" + tableName + "\" LIMIT 0")) {
                            StringBuilder cols = new StringBuilder("    Columns: ");
                            int colCount = rs3.getMetaData().getColumnCount();
                            for (int i = 1; i <= colCount; i++) {
                                if (i > 1) cols.append(", ");
                                cols.append(rs3.getMetaData().getColumnName(i))
                                    .append(" (").append(rs3.getMetaData().getColumnTypeName(i)).append(")");
                            }
                            System.out.println(cols);
                        }

                        // Show up to 5 sample rows
                        try (ResultSet rs4 = stmt2.executeQuery(
                                "SELECT * FROM \"" + tableName + "\" LIMIT 5")) {
                            int shown = 0;
                            while (rs4.next()) {
                                StringBuilder row = new StringBuilder("    row[" + shown + "]: ");
                                int nCols = rs4.getMetaData().getColumnCount();
                                for (int c = 1; c <= nCols; c++) {
                                    if (c > 1) row.append(" | ");
                                    String val = rs4.getString(c);
                                    row.append(val == null ? "NULL" : val);
                                }
                                System.out.println(row);
                                shown++;
                            }
                            if (count > 5) {
                                System.out.println("    ... (" + (count - 5) + " more rows)");
                            }
                        }
                    }
                }
                if (!hasTables) {
                    System.out.println("  (no tables found)");
                }
            }

            System.out.println();
            System.out.println("[2] ORIGINAL QUERY");
            System.out.println("");
            System.out.println("  " + originalSql);

            List<String> originalResult = new ArrayList<>();
            long origTime;
            try (Statement stmt = conn.createStatement()) {
                long start = System.currentTimeMillis();
                try (ResultSet rs = stmt.executeQuery(originalSql)) {
                    int colCount = rs.getMetaData().getColumnCount();
                    while (rs.next()) {
                        StringBuilder row = new StringBuilder();
                        for (int c = 1; c <= colCount; c++) {
                            if (c > 1) row.append("|");
                            String val = rs.getString(c);
                            row.append(val == null ? "NULL" : val);
                        }
                        originalResult.add(row.toString());
                    }
                }
                origTime = System.currentTimeMillis() - start;
            }
            System.out.printf("  Result: %d rows (%d ms)%n", originalResult.size(), origTime);
            int showLimit = Math.min(originalResult.size(), 10);
            for (int i = 0; i < showLimit; i++) {
                System.out.printf("    [%d] %s%n", i, originalResult.get(i));
            }
            if (originalResult.size() > 10) {
                System.out.printf("    ... (%d more rows)%n", originalResult.size() - 10);
            }
            if (originalResult.isEmpty()) {
                System.out.println("  WARNING: Original query returned 0 rows; all variants will also " +
                        "return 0 rows, comparison is meaningless.");
            }

            System.out.println();
            System.out.println("[3] EGRAPH VARIANTS");
            System.out.println("");
            System.out.println("  Server: " + serverUrl);

            List<String> variants;
            long serverTime;
            try {
                long start = System.currentTimeMillis();
                variants = getVariants(serverUrl, originalSql, 5);
                serverTime = System.currentTimeMillis() - start;
                System.out.printf("  Response: %d variants (%d ms)%n", variants.size(), serverTime);
            } catch (Exception e) {
                System.err.println("  ERROR contacting egraph server: " + e.getMessage());
                System.err.println("  Make sure the server is running: .\\egraph-server\\target\\release\\egraph-server.exe");
                return;
            }

            if (variants.isEmpty()) {
                System.out.println();
                System.out.println("  ");
                System.out.println("  CONCLUSION: Egraph could not generate any variants.");
                System.out.println("  This WHERE clause uses operators not supported by");
                System.out.println("  the current rewrite rules (only AND/OR/NOT/comparison/");
                System.out.println("  arithmetic/BETWEEN/IS NULL are supported).");
                System.out.println("  ");
                return;
            }

            for (int i = 0; i < variants.size(); i++) {
                String label = variants.get(i).equals(originalSql) ? " [SAME AS ORIGINAL]" : "";
                System.out.printf("  [V%d] %s%s%n", i + 1, truncate(variants.get(i), 150), label);
            }

            System.out.println();
            System.out.println("[4] COMPARISON");
            System.out.println("");
            System.out.printf("  Reference: original query returned %d rows%n", originalResult.size());
            System.out.println();

            int passed = 0;
            int failed = 0;
            for (int i = 0; i < variants.size(); i++) {
                String variantSql = variants.get(i);
                if (variantSql.equals(originalSql)) {
                    System.out.printf("  [V%d] SKIP (identical to original)%n", i + 1);
                    continue;
                }

                List<String> variantResult = new ArrayList<>();
                long varTime;
                try (Statement stmt = conn.createStatement()) {
                    long start = System.currentTimeMillis();
                    try (ResultSet rs = stmt.executeQuery(variantSql)) {
                        int colCount = rs.getMetaData().getColumnCount();
                        while (rs.next()) {
                            StringBuilder row = new StringBuilder();
                            for (int c = 1; c <= colCount; c++) {
                                if (c > 1) row.append("|");
                                String val = rs.getString(c);
                                row.append(val == null ? "NULL" : val);
                            }
                            variantResult.add(row.toString());
                        }
                    }
                    varTime = System.currentTimeMillis() - start;
                } catch (Exception e) {
                    System.out.printf("  [V%d] ERROR: %s%n", i + 1, e.getMessage());
                    failed++;
                    continue;
                }

                boolean match = originalResult.equals(variantResult);
                if (match) {
                    passed++;
                    System.out.printf("  [V%d] %3d rows  %3d ms  MATCH%n",
                            i + 1, variantResult.size(), varTime);
                } else {
                    failed++;
                    System.out.printf("  [V%d] %3d rows  %3d ms  MISMATCH!%n",
                            i + 1, variantResult.size(), varTime);
                    // Show diff
                    int maxRows = Math.max(originalResult.size(), variantResult.size());
                    int showDiff = Math.min(maxRows, 20);
                    for (int r = 0; r < showDiff; r++) {
                        String o = r < originalResult.size() ? originalResult.get(r) : "<missing>";
                        String v = r < variantResult.size() ? variantResult.get(r) : "<missing>";
                        String mark = o.equals(v) ? " " : "!";
                        System.out.printf("    [%d] %s orig: %s%n", r, mark, o);
                        if (!o.equals(v)) {
                            System.out.printf("         %s var:  %s%n", mark, v);
                        }
                    }
                    if (maxRows > 20) {
                        System.out.printf("    ... (%d more rows)%n", maxRows - 20);
                    }
                }
            }

            System.out.printf("  Summary: %d passed, %d failed%n", passed, failed);
            System.out.println();
            printSeparator('-', 70);
        }
    }

    private static List<String> getVariants(String serverUrl, String query, int maxVariants) throws Exception {
        URL endpoint = URI.create(serverUrl + "/generate-variants").toURL();
        HttpURLConnection conn = (HttpURLConnection) endpoint.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(10000);

        ObjectMapper mapper = new ObjectMapper();
        try (OutputStream os = conn.getOutputStream()) {
            String base64Query = Base64.getEncoder().encodeToString(
                    query.getBytes(StandardCharsets.UTF_8));
            mapper.writeValue(os, new VariantRequest(base64Query, maxVariants));
        }

        int code = conn.getResponseCode();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                code == 200 ? conn.getInputStream() : conn.getErrorStream(), StandardCharsets.UTF_8))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
            VariantResponse resp = mapper.readValue(sb.toString(), VariantResponse.class);
            if (code != 200) {
                throw new RuntimeException(resp.error != null ? resp.error : "HTTP " + code);
            }
            if (resp.error != null && !resp.error.isBlank()) {
                throw new RuntimeException(resp.error);
            }
            return resp.variants != null ? resp.variants : new ArrayList<>();
        }
    }

    static class VariantRequest {
        public String query_base64;
        public int max_variants;
        VariantRequest() {}
        VariantRequest(String q, int m) { this.query_base64 = q; this.max_variants = m; }
    }

    static class VariantResponse {
        public List<String> variants;
        public String error;
    }

    private static void printSeparator(char ch, int len) {
        for (int i = 0; i < len; i++) System.out.print(ch);
        System.out.println();
    }

    private static String truncate(String s, int maxLen) {
        if (s == null) return "<null>";
        if (s.length() <= maxLen) return s;
        return s.substring(0, maxLen - 3) + "...";
    }
}
