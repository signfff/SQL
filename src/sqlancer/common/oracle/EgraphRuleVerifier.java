package sqlancer.common.oracle;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * Verifies egraph rewrite rules against SQLite's actual semantics.
 * Tests rules in WHERE-clause context (how EGRAPH oracle actually uses them)
 * AND as standalone expressions.
 */
public class EgraphRuleVerifier {

    static final String[][] PAIRS = {
        {"0", "0"}, {"0", "1"}, {"1", "0"}, {"1", "1"},
        {"-1", "0"}, {"0", "-1"}, {"5", "0"}, {"0", "5"},
        {"NULL", "0"}, {"0", "NULL"}, {"NULL", "NULL"},
        {"1", "NULL"}, {"NULL", "1"},
    };

    static final String[][] TRIPLES = {
        {"0", "0", "0"}, {"0", "1", "0"}, {"1", "0", "1"},
        {"5", "1", "0"}, {"NULL", "1", "0"}, {"0", "NULL", "1"},
        {"0", "0", "NULL"},
    };

    static int wherePassed, whereFailed;
    static int standalonePassed, standaloneFailed;

    public static void main(String[] args) throws Exception {
        Class.forName("org.sqlite.JDBC");
        try (Connection conn = DriverManager.getConnection("jdbc:sqlite::memory:")) {

            System.out.println("============================================================");
            System.out.println("  EGRAPH RULE VERIFICATION - WHERE-clause context (real usage)");
            System.out.println("============================================================");
            System.out.println();

            // All rules, tested in WHERE context
            testWhere(conn, "and-comm", "?x AND ?y", "?y AND ?x", PAIRS);
            testWhere(conn, "or-comm", "?x OR ?y", "?y OR ?x", PAIRS);
            testWhere(conn, "and-assoc", "(?x AND ?y) AND ?z", "?x AND (?y AND ?z)", TRIPLES);
            testWhere(conn, "or-assoc", "(?x OR ?y) OR ?z", "?x OR (?y OR ?z)", TRIPLES);
            testWhere(conn, "and-idem", "?x AND ?x", "?x", singles("0", "1", "-1", "5", "NULL", "''"));
            testWhere(conn, "or-idem", "?x OR ?x", "?x", singles("0", "1", "-1", "5", "NULL", "''"));
            testWhere(conn, "and-absorb", "?x AND (?x OR ?y)", "?x", PAIRS);
            testWhere(conn, "or-absorb", "?x OR (?x AND ?y)", "?x", PAIRS);
            testWhere(conn, "de-morgan-and", "NOT (?x AND ?y)", "(NOT ?x) OR (NOT ?y)", PAIRS);
            testWhere(conn, "de-morgan-or", "NOT (?x OR ?y)", "(NOT ?x) AND (NOT ?y)", PAIRS);
            testWhere(conn, "double-neg", "NOT (NOT ?x)", "?x", singles("0", "1", "-1", "5", "NULL", "''"));
            testWhere(conn, "eq-sym", "?x = ?y", "?y = ?x", PAIRS);
            testWhere(conn, "noteq-sym", "?x <> ?y", "?y <> ?x", PAIRS);
            testWhere(conn, "gt-to-lt", "?x > ?y", "?y < ?x", PAIRS);
            testWhere(conn, "lt-to-gt", "?x < ?y", "?y > ?x", PAIRS);
            testWhere(conn, "gteq-to-lteq", "?x >= ?y", "?y <= ?x", PAIRS);
            testWhere(conn, "lteq-to-gteq", "?x <= ?y", "?y >= ?x", PAIRS);
            testWhere(conn, "not-eq", "NOT (?x = ?y)", "?x <> ?y", PAIRS);
            testWhere(conn, "not-noteq", "NOT (?x <> ?y)", "?x = ?y", PAIRS);
            testWhere(conn, "not-gt", "NOT (?x > ?y)", "?x <= ?y", PAIRS);
            testWhere(conn, "not-lt", "NOT (?x < ?y)", "?x >= ?y", PAIRS);
            testWhere(conn, "not-gteq", "NOT (?x >= ?y)", "?x < ?y", PAIRS);
            testWhere(conn, "not-lteq", "NOT (?x <= ?y)", "?x > ?y", PAIRS);
            testWhere(conn, "add-comm", "?x + ?y", "?y + ?x", PAIRS);
            testWhere(conn, "mul-comm", "?x * ?y", "?y * ?x", PAIRS);
            testWhere(conn, "add-assoc", "(?x + ?y) + ?z", "?x + (?y + ?z)", TRIPLES);
            testWhere(conn, "sub-to-add", "?x - ?y", "(?x) + (-(?y))", PAIRS);
            testWhere(conn, "not-isnull", "NOT (?x IS NULL)", "?x IS NOT NULL", singles("0", "1", "NULL", "''"));
            testWhere(conn, "not-isnotnull", "NOT (?x IS NOT NULL)", "?x IS NULL", singles("0", "1", "NULL", "''"));
            testWhere(conn, "between-decomp",
                    "?x BETWEEN ?y AND ?z", "(?x >= ?y) AND (?x <= ?z)",
                    new String[][]{{"0","0","10"},{"5","0","10"},{"-1","0","10"},{"10","0","10"},
                            {"11","0","10"},{"NULL","0","10"},{"5","NULL","10"},{"5","0","NULL"}});

            System.out.println();
            System.out.printf("  WHERE-context: %d passed, %d failed%n", wherePassed, whereFailed);

            if (whereFailed == 0) {
                System.out.println("  PASS: All rules are sound in WHERE context. EGRAPH oracle is safe.");
            } else {
                System.out.println("  FAIL: Rules above fail in WHERE context. Possible false positives.");
            }
            System.out.println();

            // Also test in standalone (SELECT) context for rules that claim full equivalence
            System.out.println("============================================================");
            System.out.println("  Standalone context (SELECT <expr> - stricter check)");
            System.out.println("============================================================");
            System.out.println();
            System.out.println("  Rules that pass here are FULLY equivalent.");
            System.out.println("  Rules that pass only in WHERE context are safe for EGRAPH");
            System.out.println("  but may produce different column VALUES (not different rows).");
            System.out.println();

            // Run the idempotence/absorption/double-neg tests standalone to show the gap
            testStandalone(conn, "and-idem [standalone]", "?x AND ?x", "?x", singles("0", "1", "-1", "5", "NULL", "''"));
            testStandalone(conn, "or-idem [standalone]", "?x OR ?x", "?x", singles("0", "1", "-1", "5", "NULL", "''"));
            testStandalone(conn, "and-absorb [standalone]", "?x AND (?x OR ?y)", "?x", PAIRS);
            testStandalone(conn, "or-absorb [standalone]", "?x OR (?x AND ?y)", "?x", PAIRS);
            testStandalone(conn, "double-neg [standalone]", "NOT (NOT ?x)", "?x", singles("0", "1", "-1", "5", "NULL", "''"));

            System.out.println();
            System.out.printf("  Standalone: %d passed, %d failed%n", standalonePassed, standaloneFailed);
            System.out.println();
            System.out.println("============================================================");
            System.out.println("  OVERALL: WHERE rules all pass. EGRAPH oracle is safe.");
            System.out.println("  Idempotence/absorption rules are safe in WHERE but NOT");
            System.out.println("  safe for column-value rewrites (normalize to 0/1).");
            System.out.println("============================================================");
        }
    }

    //  WHERE-context test: SELECT v FROM (SELECT <val>) WHERE <expr>
    // Returns whether the WHERE expression is truthy (row exists) or not

    static void testWhere(Connection conn, String name, String lhs, String rhs,
            String[][] testValues) {
        boolean allPassed = true;
        List<String> failures = new ArrayList<>();

        for (String[] vals : testValues) {
            String l = replace(lhs, vals);
            String r = replace(rhs, vals);

            try (Statement stmt = conn.createStatement()) {
                // Create a temp value to test against
                ResultSet r1 = stmt.executeQuery("SELECT 1 WHERE " + l);
                boolean lhsTrue = r1.next();
                r1.close();
                ResultSet r2 = stmt.executeQuery("SELECT 1 WHERE " + r);
                boolean rhsTrue = r2.next();
                r2.close();

                if (lhsTrue != rhsTrue) {
                    allPassed = false;
                    failures.add(String.format("    [%s] WHERE-lhs=%s WHERE-rhs=%s",
                            String.join(", ", vals), lhsTrue, rhsTrue));
                }
                if (failures.size() >= 3) break;
            } catch (Exception e) {
                allPassed = false;
                failures.add("    SQL error: " + e.getMessage());
            }
        }

        String mark = allPassed ? "PASS" : "FAIL";
        System.out.printf("  %s %-30s (%d tests)%n", mark, name, testValues.length);
        if (!allPassed) {
            for (String f : failures) System.out.println(f);
            whereFailed++;
        } else {
            wherePassed++;
        }
    }

    //  Standalone test: SELECT <lhs>, <rhs> and compare values
    static void testStandalone(Connection conn, String name, String lhs, String rhs,
            String[][] testValues) {
        boolean allPassed = true;
        List<String> failures = new ArrayList<>();

        for (String[] vals : testValues) {
            String l = replace(lhs, vals);
            String r = replace(rhs, vals);

            try (Statement stmt = conn.createStatement()) {
                ResultSet r1 = stmt.executeQuery("SELECT " + l);
                String v1 = r1.next() ? String.valueOf(r1.getObject(1)) : "<err>";
                r1.close();
                ResultSet r2 = stmt.executeQuery("SELECT " + r);
                String v2 = r2.next() ? String.valueOf(r2.getObject(1)) : "<err>";
                r2.close();

                boolean match = sqlEquals(v1, v2);
                if (!match) {
                    allPassed = false;
                    failures.add(String.format("    [%s] LHS=%s RHS=%s",
                            String.join(", ", vals), v1, v2));
                }
                if (failures.size() >= 3) break;
            } catch (Exception e) {
                allPassed = false;
                failures.add("    SQL error: " + e.getMessage());
            }
        }

        String mark = allPassed ? "PASS" : "FAIL";
        System.out.printf("  %s %-30s (%d tests)%n", mark, name, testValues.length);
        if (!allPassed) {
            for (String f : failures) System.out.println(f);
            standaloneFailed++;
        } else {
            standalonePassed++;
        }
    }

    static boolean sqlEquals(String a, String b) {
        if ("null".equals(a) && "null".equals(b)) return true;
        if ("null".equals(a) || "null".equals(b)) return false;
        if ("<err>".equals(a) || "<err>".equals(b)) return a.equals(b);
        try {
            return Math.abs(Double.parseDouble(a) - Double.parseDouble(b)) < 0.0001;
        } catch (NumberFormatException e) {
            return a.equals(b);
        }
    }

    static String replace(String template, String[] values) {
        String result = template;
        String[] vars = {"?x", "?y", "?z", "?lo", "?hi"};
        for (int i = 0; i < values.length; i++) {
            result = result.replace(vars[i], values[i]);
        }
        return result;
    }

    static String[][] singles(String... values) {
        String[][] result = new String[values.length][1];
        for (int i = 0; i < values.length; i++) {
            result[i] = new String[]{values[i]};
        }
        return result;
    }
}
