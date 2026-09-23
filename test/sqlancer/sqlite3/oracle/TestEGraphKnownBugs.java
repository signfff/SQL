package sqlancer.sqlite3.oracle;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import org.junit.jupiter.api.Test;

public class TestEGraphKnownBugs {

    @Test
    public void testRecognisesTheNestedRightJoinReport() {
        String query = "SELECT * FROM t1 JOIN t0 ON (t0.a >= 3 OR t0.a <= 0) RIGHT JOIN t2 ON 1 WHERE t1.b IS NULL";
        assertEquals("nested-right-join-is-null", EGraphKnownBugs.recognise(query));
    }

    @Test
    public void testRecognisesTheRowValueInReport() {
        String query = "SELECT c1 FROM t0 WHERE ((c1),(c1)) IN (SELECT c.c1, min(c.c1) FROM t0 AS c)";
        assertEquals("row-value-in-aggregate-subquery", EGraphKnownBugs.recognise(query));
    }

    @Test
    public void testLeavesOrdinaryQueriesAlone() {
        assertNull(EGraphKnownBugs.recognise("SELECT * FROM t0 WHERE c0 > 1"));
        // A right join without the IS NULL filter is a different query from the reported one.
        assertNull(EGraphKnownBugs.recognise("SELECT * FROM t1 RIGHT JOIN t2 ON 1 WHERE t1.b > 3"));
        // A row value without an aggregate on the right is not the reported shape either.
        assertNull(EGraphKnownBugs.recognise("SELECT * FROM t0 WHERE (c0, c1) IN (SELECT c0, c1 FROM t0)"));
        // An aggregate alone is not enough.
        assertNull(EGraphKnownBugs.recognise("SELECT * FROM t0 WHERE c0 = (SELECT min(c1) FROM t0)"));
        // A two-argument function call in front of IN is not a row value.
        assertNull(EGraphKnownBugs.recognise("SELECT * FROM t0 WHERE substr(a, 2) IN (SELECT min(c1) FROM t0)"));
    }

    @Test
    public void testNullQueryIsNotRecognised() {
        assertNull(EGraphKnownBugs.recognise(null));
    }
}
