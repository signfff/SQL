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

        assertFalse(EGraphMetamorphicOracle.resultRowsMatch(first, sameRowsDifferentOrder,
                "SELECT c0 FROM t0 ORDER BY c0", "SELECT c0 FROM t0 ORDER BY c0"));
        assertTrue(EGraphMetamorphicOracle.resultRowsMatch(first, sameRowsDifferentOrder,
                "SELECT c0 FROM t0", "SELECT c0 FROM t0"));
    }

    @Test
    public void testOrderByDetectionHandlesWhitespace() {
        assertTrue(EGraphMetamorphicOracle.requiresOrderSensitiveComparison("SELECT * FROM t0 ORDER \n BY c0"));
        assertFalse(EGraphMetamorphicOracle.requiresOrderSensitiveComparison("SELECT * FROM t0 WHERE c0 = 1"));
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
