package sqlancer.sqlite3.oracle;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Records the context statements so the coverage replay can run them again. Ordinary statements are written once:
 * repeating one on every refresh adds no coverage. Statements that change connection state (transactions, savepoints,
 * ATTACH/DETACH) cannot be deduplicated that way, because the statements between them depend on them: dropping the
 * second COMMIT leaves the next BEGIN failing, and dropping the second ATTACH leaves everything that uses the
 * attachment failing. They are held back instead and written just before the next new statement, and an opener
 * followed directly by its closer is cancelled, since nothing new ran in between.
 */
public final class EGraphContextReplayWriter {

    private static final int MAX_STATEMENTS = Integer.getInteger("sqlite3.egraph.contextReplay.maxStatements", 4000);
    private static final AtomicInteger STATEMENT_COUNT = new AtomicInteger();
    private static final Set<String> WRITTEN_STATEMENTS = new LinkedHashSet<>();
    private static final List<String> PENDING_STATE_STATEMENTS = new ArrayList<>();
    private static String currentReplayPath;

    private static final Pattern ATTACH = Pattern
            .compile("(?is)^ATTACH\\s+(?:DATABASE\\s+)?.*\\s+AS\\s+[\"'`\\[]?([^\"'`\\]\\s;]+)[\"'`\\]]?$");
    private static final Pattern DETACH = Pattern
            .compile("(?is)^DETACH\\s+(?:DATABASE\\s+)?[\"'`\\[]?([^\"'`\\]\\s;]+)[\"'`\\]]?$");
    private static final Pattern SAVEPOINT = Pattern.compile("(?is)^SAVEPOINT\\s+[\"'`\\[]?([^\"'`\\]\\s;]+)[\"'`\\]]?$");
    private static final Pattern RELEASE = Pattern
            .compile("(?is)^RELEASE\\s+(?:SAVEPOINT\\s+)?[\"'`\\[]?([^\"'`\\]\\s;]+)[\"'`\\]]?$");
    private static final Pattern ROLLBACK_TO = Pattern.compile(
            "(?is)^ROLLBACK\\s+(?:TRANSACTION\\s+)?TO\\s+(?:SAVEPOINT\\s+)?[\"'`\\[]?([^\"'`\\]\\s;]+)[\"'`\\]]?$");

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
                PENDING_STATE_STATEMENTS.clear();
                STATEMENT_COUNT.set(0);
            }
            if (STATEMENT_COUNT.get() >= MAX_STATEMENTS) {
                return;
            }
            if (isStateStatement(statement)) {
                holdBack(statement);
                return;
            }
            if (!WRITTEN_STATEMENTS.add(statement)) {
                return;
            }
            for (String pending : PENDING_STATE_STATEMENTS) {
                write(replayPath, pending);
            }
            PENDING_STATE_STATEMENTS.clear();
            write(replayPath, statement);
        }
    }

    private static void write(String replayPath, String statement) {
        STATEMENT_COUNT.incrementAndGet();
        appendStatement(replayPath, statement);
    }

    private static boolean isStateStatement(String statement) {
        String upper = statement.toUpperCase(Locale.ROOT);
        return upper.startsWith("BEGIN") || upper.startsWith("COMMIT") || upper.startsWith("END")
                || upper.startsWith("ROLLBACK") || upper.startsWith("SAVEPOINT") || upper.startsWith("RELEASE")
                || upper.startsWith("ATTACH") || upper.startsWith("DETACH");
    }

    private static void holdBack(String statement) {
        String last = PENDING_STATE_STATEMENTS.isEmpty() ? null
                : PENDING_STATE_STATEMENTS.get(PENDING_STATE_STATEMENTS.size() - 1);
        if (last != null && closes(last, statement)) {
            PENDING_STATE_STATEMENTS.remove(PENDING_STATE_STATEMENTS.size() - 1);
            return;
        }
        String savepoint = name(ROLLBACK_TO, statement);
        if (savepoint != null && last != null && savepoint.equals(name(SAVEPOINT, last))) {
            // Rolling back to a savepoint that nothing has been written under is a no-op.
            return;
        }
        PENDING_STATE_STATEMENTS.add(statement);
    }

    private static boolean closes(String opener, String closer) {
        String upperOpener = opener.toUpperCase(Locale.ROOT);
        String upperCloser = closer.toUpperCase(Locale.ROOT);
        if (upperOpener.startsWith("BEGIN")) {
            return upperCloser.startsWith("COMMIT") || upperCloser.startsWith("END")
                    || upperCloser.startsWith("ROLLBACK") && name(ROLLBACK_TO, closer) == null;
        }
        String savepoint = name(SAVEPOINT, opener);
        if (savepoint != null) {
            return savepoint.equals(name(RELEASE, closer));
        }
        String schema = name(ATTACH, opener);
        return schema != null && schema.equals(name(DETACH, closer));
    }

    private static String name(Pattern pattern, String statement) {
        Matcher matcher = pattern.matcher(statement);
        return matcher.matches() ? matcher.group(1).toLowerCase(Locale.ROOT) : null;
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
