package sqlancer.sqlite3.oracle;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

/**
 * Recognises the mismatches that a bug already reported to SQLite produces, so a run can be left with the findings
 * that are new.
 *
 * <p>
 * A defect that is live in the shipped engine reports itself on every check that reaches it. Measured on the nested
 * RIGHT JOIN report: 1324 mismatches in 60 seconds, all the same defect. Left alone they bury anything else the run
 * finds, which is why the shapes that reach them are kept out of the workload entirely.
 * </p>
 *
 * <p>
 * A signature matches only when every one of its patterns is found in the base query, so it takes the shape and the
 * feature that carries the defect together rather than a single token. Nothing is dropped: every suppressed mismatch
 * is appended to the log named by {@code egraph.knownBugs.log}, and the count per signature is reported at the end of
 * the run. {@code -Degraph.knownBugs=false} turns the recognition off and makes every mismatch a finding again.
 * </p>
 */
public final class EGraphKnownBugs {

    private static final boolean ENABLED = !"false".equalsIgnoreCase(System.getProperty("egraph.knownBugs", "true"));
    private static final Map<String, AtomicLong> SUPPRESSED = new ConcurrentHashMap<>();
    private static final List<Signature> SIGNATURES = load();

    private EGraphKnownBugs() {
    }

    private static final class Signature {
        private final String name;
        private final List<Pattern> patterns;

        Signature(String name, List<Pattern> patterns) {
            this.name = name;
            this.patterns = patterns;
        }

        boolean matches(String query) {
            for (Pattern pattern : patterns) {
                if (!pattern.matcher(query).find()) {
                    return false;
                }
            }
            return true;
        }
    }

    private static Signature signature(String name, String... regexes) {
        List<Pattern> patterns = new ArrayList<>();
        for (String regex : regexes) {
            patterns.add(Pattern.compile(regex, Pattern.CASE_INSENSITIVE));
        }
        return new Signature(name, patterns);
    }

    private static List<Signature> load() {
        List<Signature> signatures = new ArrayList<>();
        // Reported, confirmed, and still live in the engine this runs against. Each was seen to
        // repeat hundreds of times in a single short run.
        signatures.add(signature("nested-right-join-is-null", "RIGHT\\s+JOIN", "IS\\s+NULL"));
        // The row value is matched with one level of nesting allowed, since the report spells it
        // ((c1),(c1)), and the opening parenthesis must not follow an identifier, or substr(a,2) IN
        // (SELECT min(x) ...) would be taken for a row value.
        signatures.add(signature("row-value-in-aggregate-subquery",
                "(?<![A-Za-z0-9_])\\(\\s*(?:\\([^()]*\\)|[^(),])+\\s*,\\s*(?:\\([^()]*\\)|[^(),])+\\s*\\)"
                        + "\\s*IN\\s*\\(\\s*SELECT",
                "\\b(min|max)\\s*\\("));
        signatures.addAll(readFile());
        return signatures;
    }

    /**
     * Reads extra signatures from the file named by {@code egraph.knownBugs.file}, one per line:
     * {@code name = regex [&& regex ...]}. Blank lines and lines starting with # are skipped, and a line whose regex
     * does not compile is skipped with a warning rather than failing the run.
     */
    private static List<Signature> readFile() {
        String path = System.getProperty("egraph.knownBugs.file");
        List<Signature> signatures = new ArrayList<>();
        if (path == null || path.isBlank()) {
            return signatures;
        }
        try {
            for (String line : Files.readAllLines(Path.of(path), StandardCharsets.UTF_8)) {
                String trimmed = line.strip();
                if (trimmed.isEmpty() || trimmed.startsWith("#")) {
                    continue;
                }
                int separator = trimmed.indexOf('=');
                if (separator <= 0) {
                    continue;
                }
                String name = trimmed.substring(0, separator).strip();
                String[] regexes = trimmed.substring(separator + 1).split("&&");
                for (int i = 0; i < regexes.length; i++) {
                    regexes[i] = regexes[i].strip();
                }
                try {
                    signatures.add(signature(name, regexes));
                } catch (PatternSyntaxException e) {
                    System.err.println("[EGRAPH] known-bug signature '" + name + "' skipped: " + e.getMessage());
                }
            }
        } catch (IOException e) {
            System.err.println("[EGRAPH] cannot read " + path + ": " + e.getMessage());
        }
        return signatures;
    }

    /** The name of the reported bug this mismatch belongs to, or null when it is a finding of its own. */
    public static String recognise(String baseQuery) {
        if (!ENABLED || baseQuery == null) {
            return null;
        }
        for (Signature signature : SIGNATURES) {
            if (signature.matches(baseQuery)) {
                return signature.name;
            }
        }
        return null;
    }

    /** Records a suppressed mismatch and appends it to the known-bug log, if one was configured. */
    public static void record(String name, String baseQuery, String originalQuery, String variantQuery,
            int originalRows, int variantRows) {
        SUPPRESSED.computeIfAbsent(name, ignored -> new AtomicLong()).incrementAndGet();
        String path = System.getProperty("egraph.knownBugs.log");
        if (path == null || path.isBlank()) {
            return;
        }
        String entry = "-- EGRAPH_KNOWN_BUG " + name + " original_rows=" + originalRows + " variant_rows="
                + variantRows + System.lineSeparator() + baseQuery + System.lineSeparator() + originalQuery
                + System.lineSeparator() + variantQuery + System.lineSeparator() + System.lineSeparator();
        try {
            Path file = Path.of(path);
            if (file.getParent() != null) {
                Files.createDirectories(file.getParent());
            }
            Files.writeString(file, entry, StandardCharsets.UTF_8, StandardOpenOption.CREATE,
                    StandardOpenOption.APPEND);
        } catch (IOException ignored) {
            // The log is a convenience; the count still reaches the report.
        }
    }

    /** One line per signature that fired, for the end-of-run report. Empty when none did. */
    public static List<String> report() {
        List<String> lines = new ArrayList<>();
        SUPPRESSED.entrySet().stream()
                .sorted((a, b) -> Long.compare(b.getValue().get(), a.getValue().get()))
                .forEach(entry -> lines.add(String.format(Locale.ROOT, "  # %-40s %8d", entry.getKey(),
                        entry.getValue().get())));
        return lines;
    }
}
