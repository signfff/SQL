package sqlancer.sqlite3.schema;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

public class TestSQLite3Schema {

    @Test
    public void testColumnTypeUsesSqliteAffinityForUnknownTypeNames() {
        assertEquals(SQLite3DataType.TEXT, SQLite3Schema.getColumnType("VARCHAR0"));
        assertEquals(SQLite3DataType.INT, SQLite3Schema.getColumnType("UNSIGNED BIG INT"));
        assertEquals(SQLite3DataType.REAL, SQLite3Schema.getColumnType("DOUBLE PRECISION"));
        assertEquals(SQLite3DataType.BINARY, SQLite3Schema.getColumnType("BLOB SUBTYPE"));
        assertEquals(SQLite3DataType.REAL, SQLite3Schema.getColumnType("NUMERIC"));
    }
}
