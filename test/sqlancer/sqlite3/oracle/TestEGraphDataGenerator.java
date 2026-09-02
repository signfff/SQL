package sqlancer.sqlite3.oracle;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Method;
import java.util.List;
import java.util.Set;

import org.junit.jupiter.api.Test;

import sqlancer.sqlite3.ast.SQLite3Constant;
import sqlancer.sqlite3.ast.SQLite3Expression;
import sqlancer.sqlite3.ast.SQLite3Expression.BinaryComparisonOperation;
import sqlancer.sqlite3.ast.SQLite3Expression.BinaryComparisonOperation.BinaryComparisonOperator;
import sqlancer.sqlite3.ast.SQLite3Expression.SQLite3ColumnName;
import sqlancer.sqlite3.ast.SQLite3Expression.Sqlite3BinaryOperation;
import sqlancer.sqlite3.ast.SQLite3Expression.Sqlite3BinaryOperation.BinaryOperator;
import sqlancer.sqlite3.ast.SQLite3UnaryOperation;
import sqlancer.sqlite3.ast.SQLite3UnaryOperation.UnaryOperator;
import sqlancer.sqlite3.schema.SQLite3DataType;
import sqlancer.sqlite3.schema.SQLite3Schema.SQLite3Column;

public class TestEGraphDataGenerator {

    private static final SQLite3Column COLUMN = new SQLite3Column("c0", SQLite3DataType.INT, false, false, null);

    @Test
    public void testAcceptsSupportedColumnComparison() {
        SQLite3Expression expr = new BinaryComparisonOperation(column(), SQLite3Constant.createIntConstant(1),
                BinaryComparisonOperator.EQUALS);

        assertTrue(EGraphDataGenerator.isEgraphCompatible(expr));
    }

    @Test
    public void testRejectsUnsupportedBinaryOperatorInSubtree() {
        SQLite3Expression concat = new Sqlite3BinaryOperation(column(), SQLite3Constant.createTextConstant("x"),
                BinaryOperator.CONCATENATE);
        SQLite3Expression expr = new BinaryComparisonOperation(concat, SQLite3Constant.createTextConstant("1"),
                BinaryComparisonOperator.EQUALS);

        assertFalse(EGraphDataGenerator.isEgraphCompatible(expr));
    }

    @Test
    public void testRejectsBitwiseNegationInSubtree() {
        SQLite3Expression bitwiseNegation = new SQLite3UnaryOperation(UnaryOperator.NEGATE, column());
        SQLite3Expression expr = new BinaryComparisonOperation(bitwiseNegation, SQLite3Constant.createIntConstant(1),
                BinaryComparisonOperator.EQUALS);

        assertFalse(EGraphDataGenerator.isEgraphCompatible(expr));
    }

    @Test
    @SuppressWarnings("unchecked")
    public void testCorpusLiteralExtractionKeepsBlobAndTextSeparate() throws Exception {
        Set<String> texts = (Set<String>) invokePrivateStatic("extractTextLiterals",
                new Class<?>[] { String.class }, "c0 > 'brain' AND c1 = x'7979' AND c2 = X''");
        Set<String> blobs = (Set<String>) invokePrivateStatic("extractBlobLiterals",
                new Class<?>[] { String.class }, "c0 > 'brain' AND c1 = x'7979' AND c2 = X''");
        Set<String> reals = (Set<String>) invokePrivateStatic("extractRealLiterals",
                new Class<?>[] { String.class }, "c0 = 1.25 AND c1 < -3.5e2");

        assertTrue(texts.contains("brain"));
        assertFalse(texts.contains("7979"));
        assertTrue(blobs.contains("x'7979'"));
        assertTrue(blobs.contains("x''"));
        assertTrue(reals.contains("1.25"));
        assertTrue(reals.contains("-3.5e2"));
    }

    @Test
    @SuppressWarnings("unchecked")
    public void testCorpusLiteralPoolIsTypeAware() throws Exception {
        SQLite3Column textColumn = new SQLite3Column("txt", SQLite3DataType.TEXT, false, false, null);
        SQLite3Column blobColumn = new SQLite3Column("bin", SQLite3DataType.BINARY, false, false, null);

        List<String> textPool = (List<String>) invokePrivateStatic("corpusSqlLiteralPoolForColumn",
                new Class<?>[] { SQLite3Column.class, List.class, List.class, List.class, List.class },
                textColumn, List.of(512L), List.of("1.25"), List.of("brain"), List.of("x'7979'"));
        List<String> blobPool = (List<String>) invokePrivateStatic("corpusSqlLiteralPoolForColumn",
                new Class<?>[] { SQLite3Column.class, List.class, List.class, List.class, List.class },
                blobColumn, List.of(512L), List.of("1.25"), List.of("brain"), List.of("x'7979'"));

        assertTrue(textPool.contains("'brain'"));
        assertTrue(textPool.contains("'512'"));
        assertTrue(textPool.contains("'1.25'"));
        assertTrue(blobPool.contains("x'7979'"));
        assertTrue(blobPool.contains("CAST('brain' AS BLOB)"));
    }

    private static SQLite3ColumnName column() {
        return new SQLite3ColumnName(COLUMN, null);
    }

    private static Object invokePrivateStatic(String methodName, Class<?>[] parameterTypes, Object... args)
            throws Exception {
        Method method = EGraphDataGenerator.class.getDeclaredMethod(methodName, parameterTypes);
        method.setAccessible(true);
        return method.invoke(null, args);
    }
}
