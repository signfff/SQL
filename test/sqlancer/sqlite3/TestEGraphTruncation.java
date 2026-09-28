package sqlancer.sqlite3;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

import sqlancer.sqlite3.SQLite3OracleFactory.TruncationKind;

public class TestEGraphTruncation {

    @Test
    public void testATrailingLimitLeavesTheRowCountComparable() {
        // The statement ends on the LIMIT, so it returns min(limit, matching rows) and two spellings
        // that match the same rows agree on that number whichever ones they reached first.
        assertEquals(TruncationKind.TRAILING,
                SQLite3OracleFactory.truncationKind("SELECT * FROM t0 WHERE c0 > 1 LIMIT 10"));
        assertEquals(TruncationKind.TRAILING,
                SQLite3OracleFactory.truncationKind("SELECT * FROM t0 WHERE c0 > 1 LIMIT 10 OFFSET 5;"));
    }

    @Test
    public void testALimitInsideASubqueryLeavesNothingComparable() {
        // Found by a two-hour run: it reported 4 rows against 5 for two spellings that match exactly
        // the same 13 rows once the LIMIT is removed, measured on 3.53.4 and on trunk. The LIMIT sat
        // inside a derived table the wrapper then filtered, so which ten of the thirteen it kept
        // decided the final count - the row count was no more stable than the rows themselves.
        assertEquals(TruncationKind.NESTED, SQLite3OracleFactory.truncationKind(
                "SELECT * FROM (SELECT * FROM t0 WHERE c1 <> x'1074' LIMIT 10) AS q WHERE q.c1 = 0"));
        assertEquals(TruncationKind.NESTED, SQLite3OracleFactory
                .truncationKind("SELECT * FROM t0 WHERE c0 > 1 LIMIT 10 UNION ALL SELECT * FROM t1"));
    }

    @Test
    public void testNothingTruncatedOrOnlyAnExistsProbe() {
        assertEquals(TruncationKind.NONE, SQLite3OracleFactory.truncationKind("SELECT * FROM t0 WHERE c0 > 1"));
        // The wrappers' own EXISTS probes: which single row is found never reaches the result.
        assertEquals(TruncationKind.NONE, SQLite3OracleFactory.truncationKind(
                "SELECT * FROM t0 WHERE EXISTS (SELECT 1 FROM probe WHERE grp >= 0 LIMIT 1)"));
        // LIMIT -1 keeps everything.
        assertEquals(TruncationKind.NONE,
                SQLite3OracleFactory.truncationKind("SELECT * FROM (SELECT * FROM t0 LIMIT -1) AS q"));
    }
}
