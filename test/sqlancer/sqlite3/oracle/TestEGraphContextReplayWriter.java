package sqlancer.sqlite3.oracle;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.jupiter.api.Test;

public class TestEGraphContextReplayWriter {

    @Test
    public void testRecordsUniqueContextStatements() throws Exception {
        Path replayFile = Files.createTempFile("egraph-context-replay", ".sql");
        String oldPath = System.getProperty("egraph.contextReplay.file");
        try {
            System.setProperty("egraph.contextReplay.file", replayFile.toString());

            EGraphContextReplayWriter.record("CREATE TABLE t0(c0 INTEGER)");
            EGraphContextReplayWriter.record("CREATE TABLE t0(c0 INTEGER);");
            EGraphContextReplayWriter.record("INSERT INTO t0 VALUES(1)");

            String contents = Files.readString(replayFile, StandardCharsets.UTF_8);
            assertEquals(2, count(contents, "-- EGRAPH_CONTEXT_REPLAY_STATEMENT"));
            assertEquals(1, count(contents, "CREATE TABLE t0(c0 INTEGER);"));
            assertTrue(contents.contains("INSERT INTO t0 VALUES(1);"));
        } finally {
            if (oldPath == null) {
                System.clearProperty("egraph.contextReplay.file");
            } else {
                System.setProperty("egraph.contextReplay.file", oldPath);
            }
        }
    }

    private static int count(String text, String needle) {
        int count = 0;
        int index = 0;
        while ((index = text.indexOf(needle, index)) >= 0) {
            count++;
            index += needle.length();
        }
        return count;
    }
}
