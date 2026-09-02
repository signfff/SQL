package sqlancer.sqlite3.oracle;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

public final class EGraphContextReplayWriter {

    private static final int MAX_STATEMENTS = Integer.getInteger("sqlite3.egraph.contextReplay.maxStatements", 4000);
    private static final AtomicInteger STATEMENT_COUNT = new AtomicInteger();
    private static final Set<String> WRITTEN_STATEMENTS = new LinkedHashSet<>();
    private static String currentReplayPath;

    private EGraphContextReplayWriter() {
    }

    public static void record(String sql) {
        String replayPath = System.getProperty("egraph.contextReplay.file");
        if (replayPath == null || replayPath.isBlank() || sql == null) {
            return;
        }
        String statement = normalize(sql);
        if (statement.isBlank()) {
            return;
        }
        synchronized (EGraphContextReplayWriter.class) {
            if (!replayPath.equals(currentReplayPath)) {
                currentReplayPath = replayPath;
                WRITTEN_STATEMENTS.clear();
                STATEMENT_COUNT.set(0);
            }
            if (STATEMENT_COUNT.get() >= MAX_STATEMENTS || !WRITTEN_STATEMENTS.add(statement)) {
                return;
            }
            STATEMENT_COUNT.incrementAndGet();
            appendStatement(replayPath, statement);
        }
    }

    private static String normalize(String sql) {
        String statement = sql.strip();
        while (statement.endsWith(";")) {
            statement = statement.substring(0, statement.length() - 1).stripTrailing();
        }
        return statement;
    }

    private static void appendStatement(String replayPath, String statement) {
        File replayFile = new File(replayPath);
        File parent = replayFile.getParentFile();
        if (parent != null && !parent.exists()) {
            parent.mkdirs();
        }
        try (FileWriter writer = new FileWriter(replayFile, true)) {
            writer.write("-- EGRAPH_CONTEXT_REPLAY_STATEMENT");
            writer.write(System.lineSeparator());
            writer.write(statement);
            writer.write(';');
            writer.write(System.lineSeparator());
        } catch (IOException ignored) {
        }
    }
}
