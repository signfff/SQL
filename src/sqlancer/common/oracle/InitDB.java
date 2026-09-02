package sqlancer.common.oracle;

import java.io.BufferedReader;
import java.io.FileReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

/**
 * Creates a SQLite database from a .sql file.
 * Usage: java -cp target\sqlancer-2.0.0.jar sqlancer.common.oracle.InitDB mytest.sql mytest.db
 */
public class InitDB {
    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.err.println("Usage: java -cp target\\sqlancer-2.0.0.jar sqlancer.common.oracle.InitDB <file.sql> <output.db>");
            System.exit(1);
        }
        String sqlFile = args[0];
        String dbPath = args[1];

        // Delete existing database
        java.io.File db = new java.io.File(dbPath);
        if (db.exists()) db.delete();

        String url = "jdbc:sqlite:" + dbPath;
        try (Connection conn = DriverManager.getConnection(url);
             Statement stmt = conn.createStatement();
             BufferedReader reader = new BufferedReader(new FileReader(sqlFile))) {

            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                if (line.isEmpty() || line.startsWith("--")) continue;
                sb.append(line).append(" ");
                if (line.endsWith(";")) {
                    String sql = sb.toString().trim();
                    System.out.println("Executing: " + sql);
                    stmt.execute(sql);
                    sb.setLength(0);
                }
            }
        }
        System.out.println("Done. Database created: " + dbPath);
    }
}
