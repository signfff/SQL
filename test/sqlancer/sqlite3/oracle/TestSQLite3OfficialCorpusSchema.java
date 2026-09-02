package sqlancer.sqlite3.oracle;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

import org.junit.jupiter.api.Test;

import sqlancer.IgnoreMeException;
import sqlancer.SQLConnection;
import sqlancer.sqlite3.SQLite3GlobalState;
import sqlancer.sqlite3.SQLite3Options;
import sqlancer.sqlite3.oracle.SQLite3EGraphInputCorpus.CorpusQueryInput;

public class TestSQLite3OfficialCorpusSchema {

    @Test
    public void testOfficialCorpusSetupSchemasDoNotAssert() throws Exception {
        java.nio.file.Path corpus = java.nio.file.Path.of("coverage", "sqlite", "sqlite-official-test-corpus.sql");
        if (!java.nio.file.Files.isRegularFile(corpus)) {
            return;
        }
        SQLite3Options options = new SQLite3Options();
        options.egraphInputFile = corpus.toString();
        List<CorpusQueryInput> cases = SQLite3EGraphInputCorpus.readQueryInputRecords(options);
        int requestedLimit = Integer.getInteger("sqlancer.sqlite3.officialCorpusSchemaTestLimit", 1000);
        int limit = Math.min(requestedLimit, cases.size());
        for (int i = 0; i < limit; i++) {
            CorpusQueryInput input = cases.get(i);
            assertDoesNotThrow(() -> {
                try {
                    replaySetupAndReadSchema(input);
                } catch (IgnoreMeException ignored) {
                }
            }, "official corpus case " + i);
        }
    }

    private static void replaySetupAndReadSchema(CorpusQueryInput input) throws Exception {
        Class.forName("org.sqlite.JDBC");
        try (java.sql.Connection connection = DriverManager.getConnection("jdbc:sqlite::memory:")) {
            try (Statement statement = connection.createStatement()) {
                for (String sql : input.getSetupStatements()) {
                    try {
                        statement.execute(sql);
                    } catch (SQLException ignored) {
                    }
                }
            }
            SQLite3GlobalState state = new SQLite3GlobalState();
            state.setConnection(new SQLConnection(connection));
            state.setDbmsSpecificOptions(new SQLite3Options());
            state.updateSchema();
        }
    }
}
