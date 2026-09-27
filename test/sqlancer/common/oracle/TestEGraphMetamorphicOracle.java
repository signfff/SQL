package sqlancer.common.oracle;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import org.junit.jupiter.api.Test;

public class TestEGraphMetamorphicOracle {

    @Test
    public void testResultRowsUseMultisetComparison() {
        List<String> first = List.of("S1:a|S1:x", "S1:a|S1:x", "S1:b|S1:y");
        List<String> sameRowsDifferentOrder = List.of("S1:b|S1:y", "S1:a|S1:x", "S1:a|S1:x");
        List<String> differentDuplicateCount = List.of("S1:b|S1:y", "S1:b|S1:y", "S1:a|S1:x");

        assertTrue(EGraphMetamorphicOracle.resultRowsMatch(first, sameRowsDifferentOrder));
        assertFalse(EGraphMetamorphicOracle.resultRowsMatch(first, differentDuplicateCount));
    }

    @Test
    public void testOrderedQueriesUseSequenceComparison() {
        List<String> first = List.of("S1:a", "S1:b");
        List<String> sameRowsDifferentOrder = List.of("S1:b", "S1:a");

        // The same rows in a different order are not a finding, ORDER BY or not: an ORDER BY inside a
        // wrapper does not order the query around it, and one on a column with ties does not fix the
        // order of the tied rows. Such a difference is counted elsewhere instead.
        assertTrue(EGraphMetamorphicOracle.resultRowsMatch(first, sameRowsDifferentOrder,
                "SELECT c0 FROM t0 ORDER BY c0", "SELECT c0 FROM t0 ORDER BY c0"));
        assertTrue(EGraphMetamorphicOracle.resultRowsMatch(first, sameRowsDifferentOrder,
                "SELECT c0 FROM t0", "SELECT c0 FROM t0"));
        assertFalse(EGraphMetamorphicOracle.resultRowsMatch(first, List.of("S1:a", "S1:c"),
                "SELECT c0 FROM t0 ORDER BY c0", "SELECT c0 FROM t0 ORDER BY c0"));
    }

    @Test
    public void testResultValueEncodingKeepsNullDistinctFromStringNull() {
        assertFalse(EGraphMetamorphicOracle.encodeResultValue(null)
                .equals(EGraphMetamorphicOracle.encodeResultValue("N")));
    }

    @Test
    public void testSingleSideEmptyRowsAreMismatches() {
        assertTrue(EGraphMetamorphicOracle.hasSingleSideEmptyMismatch(List.of("S1:1"), List.of()));
        assertTrue(EGraphMetamorphicOracle.hasSingleSideEmptyMismatch(List.of(), List.of("S1:1")));
        assertFalse(EGraphMetamorphicOracle.hasSingleSideEmptyMismatch(List.of(), List.of()));
        assertFalse(EGraphMetamorphicOracle.hasSingleSideEmptyMismatch(List.of("S1:1"), List.of("S1:2")));
    }
}
