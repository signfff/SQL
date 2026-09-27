package sqlancer.sqlite3.oracle;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * The context statements the current database was built with, so another engine can be put in the same position.
 *
 * <p>
 * A wrapper shape reaches for tables the context setup created, and some of those live in a database attached from
 * memory. Handing a second engine only the database file leaves those tables missing, and every query that names one
 * fails there - which is why the trunk referee could not answer for any check that used such a shape. Replaying these
 * statements first puts them back.
 * </p>
 *
 * <p>
 * Kept per thread and cleared whenever the context is rebuilt, so what it holds belongs to the check being run rather
 * than to some earlier database. Statements are recorded only when they succeeded.
 * </p>
 */
public final class EGraphContextSnapshot {

    private static final int MAX_STATEMENTS = Integer.getInteger("sqlite3.egraph.contextSnapshot.maxStatements", 2000);
    private static final ThreadLocal<List<String>> STATEMENTS = ThreadLocal.withInitial(ArrayList::new);

    private EGraphContextSnapshot() {
    }

    public static void reset() {
        STATEMENTS.get().clear();
    }

    public static void record(String statement) {
        if (statement == null || statement.isBlank()) {
            return;
        }
        List<String> statements = STATEMENTS.get();
        if (statements.size() >= MAX_STATEMENTS) {
            return;
        }
        statements.add(statement.strip());
    }

    /** The statements in the order they ran, for replaying elsewhere. */
    public static List<String> current() {
        return Collections.unmodifiableList(new ArrayList<>(STATEMENTS.get()));
    }
}
