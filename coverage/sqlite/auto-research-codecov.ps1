param(
    [string] $BaseReplay = "",
    [string] $OutputRoot = "",
    [string] $BaselineCoverageDir = "",
    [switch] $ReplayBaseline,
    [string[]] $CaseName = @(),
    [int] $ProgressIntervalSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Location "D:\sqlancer"

$coverageRoot = "D:\sqlancer\coverage\sqlite"
$buildDir = Join-Path $coverageRoot "build"
$sqliteExe = Join-Path $buildDir "sqlite3_cov.exe"
$sourceDir = Join-Path $coverageRoot "sqlite-amalgamation-3530400"
$gcovExe = "D:\Dev-Cpp\TDM-GCC-64\bin\gcov.exe"

if (-not (Test-Path -LiteralPath $sqliteExe)) {
    throw "Missing instrumented SQLite binary: $sqliteExe"
}
if (-not (Test-Path -LiteralPath $gcovExe)) {
    throw "Missing gcov: $gcovExe"
}
if ([string]::IsNullOrWhiteSpace($BaseReplay)) {
    $latestRun = Get-ChildItem -LiteralPath $coverageRoot -Directory |
        Where-Object { $_.Name -like "manual-1h-*" -or $_.Name -like "manual-long-*" -or $_.Name -like "manual-long-mixed-*" } |
        Where-Object {
            (Test-Path -LiteralPath (Join-Path $_.FullName "replay.sql")) -or
            (Test-Path -LiteralPath (Join-Path $_.FullName "replay-all.sql"))
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($latestRun) {
        $candidateReplay = Join-Path $latestRun.FullName "replay.sql"
        if (Test-Path -LiteralPath $candidateReplay) {
            $BaseReplay = $candidateReplay
        } else {
            $BaseReplay = Join-Path $latestRun.FullName "replay-all.sql"
        }
    } else {
        $BaseReplay = Join-Path $coverageRoot "replay.sql"
    }
}
if (-not (Test-Path -LiteralPath $BaseReplay)) {
    throw "Missing base replay SQL: $BaseReplay"
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputRoot = Join-Path $coverageRoot "auto-research-$stamp"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$script:ProgressLogPath = Join-Path $OutputRoot "auto-research-progress.log"
if ($ProgressIntervalSeconds -lt 1) {
    $ProgressIntervalSeconds = 30
}

function Write-ResearchProgress {
    param(
        [string] $Message,
        [string] $CaseName = ""
    )

    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ([string]::IsNullOrWhiteSpace($CaseName)) {
        $line = "[$stamp] $Message"
    } else {
        $line = "[$stamp] [$CaseName] $Message"
    }
    Write-Host $line
    Add-Content -LiteralPath $script:ProgressLogPath -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

function Get-FileLengthOrZero {
    param([string] $Path)

    if (Test-Path -LiteralPath $Path) {
        return [long] (Get-Item -LiteralPath $Path).Length
    }
    return [long] 0
}

function Format-ByteCount {
    param([long] $Bytes)

    if ($Bytes -ge 1GB) {
        return ("{0:n1}GB" -f ($Bytes / 1GB))
    }
    if ($Bytes -ge 1MB) {
        return ("{0:n1}MB" -f ($Bytes / 1MB))
    }
    if ($Bytes -ge 1KB) {
        return ("{0:n1}KB" -f ($Bytes / 1KB))
    }
    return "${Bytes}B"
}

function Test-CoverageArtifacts {
    param([string] $Dir)

    return (
        -not [string]::IsNullOrWhiteSpace($Dir) -and
        (Test-Path -LiteralPath (Join-Path $Dir "sqlite3.c.gcov")) -and
        (Test-Path -LiteralPath (Join-Path $Dir "gcov-sqlite3-summary.txt")) -and
        (Test-Path -LiteralPath (Join-Path $Dir "gcov-sqlite3-functions.txt"))
    )
}

function Resolve-BaselineCoverageDir {
    if (-not [string]::IsNullOrWhiteSpace($BaselineCoverageDir)) {
        if (-not (Test-CoverageArtifacts -Dir $BaselineCoverageDir)) {
            throw "Missing baseline coverage artifacts in: $BaselineCoverageDir"
        }
        return $BaselineCoverageDir
    }

    $baseReplayPath = (Resolve-Path -LiteralPath $BaseReplay).Path
    $baseReplayParent = Split-Path -Parent $baseReplayPath
    if (Test-CoverageArtifacts -Dir $baseReplayParent) {
        return $baseReplayParent
    }

    $latestCoverageRun = Get-ChildItem -LiteralPath $coverageRoot -Directory |
        Where-Object {
            ($_.Name -like "manual-1h-*" -or $_.Name -like "manual-long-*" -or $_.Name -like "manual-long-mixed-*") -and
            (Test-CoverageArtifacts -Dir $_.FullName)
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($latestCoverageRun) {
        return $latestCoverageRun.FullName
    }

    return ""
}

$reuseBaselineCoverage = -not $ReplayBaseline
if ($reuseBaselineCoverage) {
    $BaselineCoverageDir = Resolve-BaselineCoverageDir
    if ([string]::IsNullOrWhiteSpace($BaselineCoverageDir)) {
        Write-ResearchProgress -Message "no reusable baseline coverage artifacts found; falling back to full baseline replay"
        $reuseBaselineCoverage = $false
    } else {
        Write-ResearchProgress -Message "reusing baseline coverage artifacts: $BaselineCoverageDir"
    }
} else {
    Write-ResearchProgress -Message "ReplayBaseline was requested; baseline will be replayed from SQL"
}
Set-Content -LiteralPath (Join-Path $OutputRoot "baseline-replay-path.txt") -Value $BaseReplay -Encoding UTF8
if (-not [string]::IsNullOrWhiteSpace($BaselineCoverageDir)) {
    Set-Content -LiteralPath (Join-Path $OutputRoot "baseline-coverage-dir.txt") -Value $BaselineCoverageDir -Encoding UTF8
}

$cases = @(
    @{
        Name = "baseline"
        Description = "Only replay the captured SQLancer workload."
        Sql = ""
    },
    @{
        Name = "fts5"
        Description = "FTS5 virtual table, MATCH, bm25, highlight, snippet, fts5vocab."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_fts_vocab;
DROP TABLE IF EXISTS ar_fts;
CREATE VIRTUAL TABLE ar_fts USING fts5(title, body, tokenize='porter');
INSERT INTO ar_fts(rowid, title, body) VALUES
  (1, 'sqlite query planner', 'coverage driven sql testing for sqlite query planner'),
  (2, 'compiler pipeline', 'parser resolver optimizer code generator virtual machine'),
  (3, 'egraph variants', 'equivalent sql variants and metamorphic testing');
SELECT rowid, bm25(ar_fts), highlight(ar_fts, 0, '[', ']'),
       snippet(ar_fts, 1, '<', '>', '...', 8)
  FROM ar_fts WHERE ar_fts MATCH 'sqlite OR compiler OR variants'
  ORDER BY rank LIMIT 5;
INSERT INTO ar_fts(ar_fts, rank) VALUES('rank', 'bm25(10.0, 5.0)');
SELECT rowid, title FROM ar_fts('coverage');
CREATE VIRTUAL TABLE ar_fts_vocab USING fts5vocab(ar_fts, 'row');
SELECT term, doc, cnt FROM ar_fts_vocab WHERE term >= 'a' ORDER BY term LIMIT 10;
DROP TABLE ar_fts_vocab;
DROP TABLE ar_fts;
"@
    },
    @{
        Name = "rtree"
        Description = "RTREE virtual table search, update, delete."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_rt;
CREATE VIRTUAL TABLE ar_rt USING rtree(id, x1, x2, y1, y2);
INSERT INTO ar_rt VALUES
  (1, 0.0, 10.0, 0.0, 10.0),
  (2, 5.0, 15.0, 5.0, 15.0),
  (3, -5.0, 1.0, -5.0, 1.0);
SELECT id FROM ar_rt WHERE x1 <= 6.0 AND x2 >= 6.0 AND y1 <= 6.0 AND y2 >= 6.0 ORDER BY id;
UPDATE ar_rt SET x1 = x1 - 1.0, x2 = x2 + 1.0 WHERE id = 1;
DELETE FROM ar_rt WHERE id IN (SELECT id FROM ar_rt WHERE x2 < 2.0);
SELECT count(*) FROM ar_rt;
DROP TABLE ar_rt;
"@
    },
    @{
        Name = "trigger_view_fk"
        Description = "Views, triggers, foreign keys, cascading actions."
        Sql = @"
ROLLBACK;
COMMIT;
PRAGMA foreign_keys=ON;
DROP VIEW IF EXISTS ar_child_view;
DROP TRIGGER IF EXISTS ar_child_ai;
DROP TRIGGER IF EXISTS ar_child_au;
DROP TABLE IF EXISTS ar_audit;
DROP TABLE IF EXISTS ar_child;
DROP TABLE IF EXISTS ar_parent;
CREATE TABLE ar_parent(id INTEGER PRIMARY KEY, name TEXT UNIQUE);
CREATE TABLE ar_child(
  id INTEGER PRIMARY KEY,
  parent_id INTEGER REFERENCES ar_parent(id) ON UPDATE CASCADE ON DELETE SET NULL,
  value INTEGER CHECK(value BETWEEN 0 AND 100)
);
CREATE TABLE ar_audit(action TEXT, old_value INTEGER, new_value INTEGER);
CREATE VIEW ar_child_view AS
  SELECT c.id, p.name, c.value FROM ar_child AS c LEFT JOIN ar_parent AS p ON p.id = c.parent_id;
CREATE TRIGGER ar_child_ai AFTER INSERT ON ar_child
BEGIN
  INSERT INTO ar_audit VALUES('insert', NULL, NEW.value);
END;
CREATE TRIGGER ar_child_au AFTER UPDATE OF value ON ar_child
BEGIN
  INSERT INTO ar_audit VALUES('update', OLD.value, NEW.value);
END;
INSERT INTO ar_parent VALUES(1, 'p1'), (2, 'p2');
INSERT INTO ar_child VALUES(10, 1, 20), (11, 2, 30);
UPDATE ar_parent SET id = 3 WHERE id = 1;
UPDATE ar_child SET value = value + 5 WHERE parent_id = 3;
DELETE FROM ar_parent WHERE id = 2;
SELECT * FROM ar_child_view ORDER BY id;
SELECT action, count(*) FROM ar_audit GROUP BY action;
DROP VIEW ar_child_view;
DROP TRIGGER ar_child_ai;
DROP TRIGGER ar_child_au;
DROP TABLE ar_audit;
DROP TABLE ar_child;
DROP TABLE ar_parent;
PRAGMA foreign_keys=OFF;
"@
    },
    @{
        Name = "tx_wal_vacuum"
        Description = "Transactions, savepoints, WAL, checkpoint, vacuum, integrity checks."
        Sql = @"
ROLLBACK;
COMMIT;
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
DROP TABLE IF EXISTS ar_tx;
CREATE TABLE ar_tx(id INTEGER PRIMARY KEY, v TEXT);
BEGIN IMMEDIATE;
INSERT INTO ar_tx(v) VALUES('a'), ('b'), ('c');
SAVEPOINT ar_sp1;
UPDATE ar_tx SET v = upper(v) WHERE id <= 2;
ROLLBACK TO ar_sp1;
RELEASE ar_sp1;
COMMIT;
PRAGMA wal_checkpoint(FULL);
PRAGMA integrity_check;
PRAGMA quick_check;
PRAGMA optimize;
VACUUM;
DROP TABLE ar_tx;
PRAGMA journal_mode=DELETE;
"@
    },
    @{
        Name = "json_table_valued"
        Description = "JSON scalar and table-valued functions."
        Sql = @"
ROLLBACK;
COMMIT;
WITH doc(j) AS (
  VALUES(json_object('a', json_array(1,2,3), 'b', json_object('x', 7), 'c', 'text'))
)
SELECT json_extract(j, '$.b.x'), json_type(j, '$.a'), json_array_length(j, '$.a'),
       json_set(j, '$.b.y', 9), json_patch(j, json_object('d', 4))
  FROM doc;
SELECT key, value, type FROM json_each('{"a":[1,2],"b":{"x":3},"c":null}') ORDER BY key;
SELECT fullkey, atom FROM json_tree('{"a":[1,{"b":2}],"c":3}') WHERE atom IS NOT NULL ORDER BY id;
"@
    },
    @{
        Name = "alter_index_analyze"
        Description = "ALTER TABLE, expression/partial indexes, ANALYZE, REINDEX."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_idx2;
DROP TABLE IF EXISTS ar_idx;
CREATE TABLE ar_idx(a INTEGER, b TEXT, c REAL);
INSERT INTO ar_idx VALUES (1,'one',1.0), (2,'two',2.0), (3,'three',3.0), (NULL,'none',NULL);
CREATE INDEX ar_idx_expr ON ar_idx((a + 1), lower(b)) WHERE c IS NOT NULL;
CREATE UNIQUE INDEX ar_idx_partial ON ar_idx(b COLLATE NOCASE) WHERE a IS NOT NULL;
SELECT * FROM ar_idx INDEXED BY ar_idx_expr WHERE (a + 1) > 1 ORDER BY lower(b);
REINDEX ar_idx_expr;
ANALYZE ar_idx;
ALTER TABLE ar_idx ADD COLUMN d TEXT DEFAULT 'd';
ALTER TABLE ar_idx RENAME COLUMN b TO b2;
ALTER TABLE ar_idx RENAME TO ar_idx2;
SELECT a, b2, d FROM ar_idx2 NOT INDEXED WHERE d = 'd';
DROP INDEX ar_idx_expr;
DROP INDEX ar_idx_partial;
DROP TABLE ar_idx2;
"@
    },
    @{
        Name = "returning_upsert"
        Description = "UPSERT and RETURNING paths."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_upsert;
CREATE TABLE ar_upsert(id INTEGER PRIMARY KEY, k TEXT UNIQUE, v INTEGER);
INSERT INTO ar_upsert(k, v) VALUES('a', 1), ('b', 2) RETURNING id, k, v;
INSERT INTO ar_upsert(k, v) VALUES('a', 10)
  ON CONFLICT(k) DO UPDATE SET v = excluded.v + ar_upsert.v
  RETURNING id, k, v;
UPDATE ar_upsert SET v = v + 1 WHERE k IN ('a','b') RETURNING id, v;
DELETE FROM ar_upsert WHERE v > 2 RETURNING id, k;
DROP TABLE ar_upsert;
"@
    },
    @{
        Name = "dbstat_storage"
        Description = "DBSTAT virtual table, page-count/storage inspection."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_dbstat;
CREATE TABLE ar_dbstat(id INTEGER PRIMARY KEY, payload TEXT);
WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM n WHERE x < 200)
INSERT INTO ar_dbstat SELECT x, printf('payload-%04d-%s', x, hex(randomblob(16))) FROM n;
CREATE INDEX ar_dbstat_payload ON ar_dbstat(payload);
ANALYZE;
PRAGMA page_count;
PRAGMA freelist_count;
SELECT name, path, pageno, pagetype, ncell FROM dbstat WHERE name LIKE 'ar_dbstat%' ORDER BY pageno LIMIT 20;
DROP TABLE ar_dbstat;
"@
    },
    @{
        Name = "recursive_window_aggregate"
        Description = "Recursive CTE, aggregate, FILTER, window frames."
        Sql = @"
ROLLBACK;
COMMIT;
WITH RECURSIVE seq(x) AS (
  VALUES(1) UNION ALL SELECT x + 1 FROM seq WHERE x < 25
),
ranked AS (
  SELECT x,
         x % 5 AS g,
         sum(x) OVER (PARTITION BY x % 5 ORDER BY x ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_sum,
         count(*) FILTER (WHERE x % 2 = 0) OVER () AS even_count
  FROM seq
)
SELECT g, count(*), sum(x), avg(rolling_sum), max(even_count),
       group_concat(x, ',') FILTER (WHERE x <= 10)
  FROM ranked
 GROUP BY g
HAVING sum(x) > 10
 ORDER BY g;
"@
    },
    @{
        Name = "fts5_secure_vocab"
        Description = "FTS5 secure-delete, delete/optimize, MATCH, highlight, and fts5vocab."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_fts_secure_vocab;
DROP TABLE IF EXISTS ar_fts_secure;
CREATE VIRTUAL TABLE ar_fts_secure USING fts5(title, body, tokenize='porter');
INSERT INTO ar_fts_secure(rowid, title, body) VALUES
  (1, 'alpha coverage', 'sqlite fts5 secure delete vocabulary prefix'),
  (2, 'beta coverage', 'token prefix merge delete optimize'),
  (3, 'gamma coverage', 'query planner variants and egraph testing'),
  (4, 'delta coverage', 'prefix prefix prefix token data');
INSERT INTO ar_fts_secure(ar_fts_secure, rank) VALUES('secure-delete', 1);
DELETE FROM ar_fts_secure
 WHERE rowid IN (SELECT rowid FROM ar_fts_secure WHERE ar_fts_secure MATCH 'prefix OR token' LIMIT 2);
INSERT INTO ar_fts_secure(rowid, title, body)
  VALUES(5, 'epsilon coverage', 'replacement token data after secure delete');
SELECT rowid, bm25(ar_fts_secure), highlight(ar_fts_secure, 0, '[', ']')
  FROM ar_fts_secure
 WHERE ar_fts_secure MATCH 'coverage OR token'
 ORDER BY rank LIMIT 8;
INSERT INTO ar_fts_secure(ar_fts_secure) VALUES('optimize');
CREATE VIRTUAL TABLE ar_fts_secure_vocab USING fts5vocab(ar_fts_secure, 'row');
SELECT term, doc, cnt FROM ar_fts_secure_vocab WHERE term >= 'a' ORDER BY term LIMIT 16;
DROP TABLE ar_fts_secure_vocab;
DROP TABLE ar_fts_secure;
"@
    },
    @{
        Name = "jsonb_stress"
        Description = "JSONB validity, JSON merge patch, json_tree, json_pretty, and malformed JSONB probes."
        Sql = @"
ROLLBACK;
COMMIT;
SELECT json_valid(jsonb('{"a":[1,2,3],"b":{"x":7}}'), 8),
       json_extract(jsonb('{"a":[1,2,3]}'), '$.a[1]'),
       json_type(jsonb('{"b":{"x":7}}'), '$.b');
SELECT json_patch(jsonb('{"a":1,"b":{"x":2}}'), jsonb('{"b":{"y":3},"c":[4,5]}')),
       json_pretty(jsonb('{"nested":{"array":[1,{"x":2}]}}'));
SELECT fullkey, atom
  FROM json_tree(jsonb('{"a":[1,{"b":2}],"c":{"d":3}}'))
 WHERE atom IS NOT NULL
 ORDER BY id;
SELECT json_valid(x'4a534f4e', 8), json_valid(x'00', 8);
"@
    },
    @{
        Name = "xfer_optimization"
        Description = "INSERT INTO dst SELECT * FROM src transfer optimization."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_xfer_dst;
DROP TABLE IF EXISTS ar_xfer_src;
CREATE TABLE ar_xfer_src(a INTEGER PRIMARY KEY, b TEXT, c REAL);
CREATE TABLE ar_xfer_dst(a INTEGER PRIMARY KEY, b TEXT, c REAL);
INSERT INTO ar_xfer_src(a, b, c) VALUES
  (1, 'one', 1.0), (2, 'two', 2.0), (3, 'three', 3.0), (4, 'four', 4.0);
INSERT INTO ar_xfer_dst SELECT * FROM ar_xfer_src;
SELECT a, b, c FROM ar_xfer_dst WHERE a >= 0 ORDER BY a LIMIT 8;
DROP TABLE ar_xfer_dst;
DROP TABLE ar_xfer_src;
"@
    },
    @{
        Name = "multi_select_order_by"
        Description = "Compound SELECT ORDER BY and LIMIT paths."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_ms;
CREATE TABLE ar_ms(id INTEGER PRIMARY KEY, v INTEGER, tag TEXT);
INSERT INTO ar_ms(id, v, tag) VALUES
  (1, 10, 'alpha'), (2, 20, 'beta'), (3, 30, 'gamma'), (4, 40, 'delta');
SELECT v, tag FROM ar_ms WHERE v <= 20
 UNION ALL
SELECT v, tag FROM ar_ms WHERE v >= 30
 ORDER BY tag DESC, v ASC LIMIT 8;
SELECT v FROM ar_ms WHERE tag LIKE 'a%'
 UNION
SELECT v FROM ar_ms WHERE tag LIKE 'd%'
 ORDER BY 1 DESC;
DROP TABLE ar_ms;
"@
    },
    @{
        Name = "join_optimizer"
        Description = "RIGHT/FULL JOIN, multi-way joins, IN-subqueries, and planner index choices."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_join_dim;
DROP TABLE IF EXISTS ar_join_right;
DROP TABLE IF EXISTS ar_join_left;
CREATE TABLE ar_join_left(id INTEGER PRIMARY KEY, k INTEGER, v INTEGER, tag TEXT);
CREATE TABLE ar_join_right(id INTEGER PRIMARY KEY, k INTEGER, v INTEGER, flag INTEGER);
CREATE TABLE ar_join_dim(k INTEGER PRIMARY KEY, label TEXT);
WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 96)
INSERT INTO ar_join_left(id, k, v, tag)
SELECT x, x % 16, x * 3, printf('L%03d', x) FROM n;
WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 128)
INSERT INTO ar_join_right(id, k, v, flag)
SELECT x, x % 16, x * 5, x % 3 FROM n;
WITH RECURSIVE n(x) AS (VALUES(0) UNION ALL SELECT x + 1 FROM n WHERE x < 15)
INSERT INTO ar_join_dim(k, label) SELECT x, printf('D%02d', x) FROM n;
CREATE INDEX ar_join_left_k_v ON ar_join_left(k, v);
CREATE INDEX ar_join_right_k_flag ON ar_join_right(k, flag);
CREATE INDEX ar_join_left_partial ON ar_join_left(v) WHERE k >= 0;
ANALYZE ar_join_left;
ANALYZE ar_join_right;
ANALYZE ar_join_dim;
SELECT r.id, l.tag FROM ar_join_left AS l RIGHT JOIN ar_join_right AS r
  ON r.k = l.k
 WHERE r.flag IN (SELECT flag FROM ar_join_right WHERE k BETWEEN 0 AND 8)
 ORDER BY r.k, l.id LIMIT 24;
SELECT coalesce(l.k, r.k), count(*) FROM ar_join_left AS l
 FULL OUTER JOIN ar_join_right AS r ON r.k = l.k AND r.flag = l.k % 3
 GROUP BY coalesce(l.k, r.k) ORDER BY 1 LIMIT 16;
SELECT count(*) FROM ar_join_left AS l
 JOIN ar_join_right AS r ON r.k = l.k
 JOIN ar_join_dim AS d ON d.k = r.k
 WHERE d.k IN (SELECT k FROM ar_join_dim WHERE k < 12) AND r.v > l.v;
DROP TABLE ar_join_dim;
DROP TABLE ar_join_right;
DROP TABLE ar_join_left;
"@
    },
    @{
        Name = "alter_fk_stress"
        Description = "Deferred/composite foreign keys, FK actions, foreign_key_check, rename and DROP COLUMN."
        Sql = @"
ROLLBACK;
COMMIT;
PRAGMA foreign_keys=OFF;
DROP VIEW IF EXISTS ar_alter_fk_view;
DROP TRIGGER IF EXISTS ar_alter_fk_ai;
DROP TABLE IF EXISTS ar_alter_fk_renamed;
DROP TABLE IF EXISTS ar_alter_fk_rename;
DROP TABLE IF EXISTS ar_fk_audit;
DROP TABLE IF EXISTS ar_fk_child2;
DROP TABLE IF EXISTS ar_fk_parent2;
DROP TABLE IF EXISTS ar_fk_child;
DROP TABLE IF EXISTS ar_fk_parent;
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=ON;
CREATE TABLE ar_fk_parent(id INTEGER PRIMARY KEY, code TEXT UNIQUE);
CREATE TABLE ar_fk_child(
  id INTEGER PRIMARY KEY,
  pid INTEGER DEFAULT 0 REFERENCES ar_fk_parent(id) ON UPDATE CASCADE ON DELETE SET DEFAULT,
  note TEXT
);
CREATE TABLE ar_fk_audit(action TEXT, child_id INTEGER, old_pid INTEGER, new_pid INTEGER);
CREATE TRIGGER ar_alter_fk_ai AFTER UPDATE OF pid ON ar_fk_child
BEGIN
  INSERT INTO ar_fk_audit VALUES('pid-update', NEW.id, OLD.pid, NEW.pid);
END;
INSERT INTO ar_fk_parent(id, code) VALUES (0, 'default'), (1, 'p1'), (2, 'p2');
INSERT INTO ar_fk_child(id, pid, note) VALUES (10, 1, 'c1'), (11, 2, 'c2');
UPDATE ar_fk_parent SET id = 3 WHERE id = 1;
DELETE FROM ar_fk_parent WHERE id = 2;
PRAGMA foreign_key_check;
CREATE TABLE ar_fk_parent2(a INTEGER, b INTEGER, PRIMARY KEY(a, b));
CREATE TABLE ar_fk_child2(
  id INTEGER PRIMARY KEY,
  a INTEGER,
  b INTEGER,
  FOREIGN KEY(a, b) REFERENCES ar_fk_parent2(a, b) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);
BEGIN;
INSERT INTO ar_fk_parent2(a, b) VALUES (1, 1), (2, 2);
INSERT INTO ar_fk_child2(id, a, b) VALUES (1, 1, 1), (2, 2, 2);
DELETE FROM ar_fk_parent2 WHERE a = 1;
COMMIT;
CREATE TABLE ar_alter_fk_rename(id INTEGER PRIMARY KEY, a INTEGER, b TEXT, drop_me TEXT DEFAULT 'x');
CREATE INDEX ar_alter_fk_expr ON ar_alter_fk_rename((a + length(b))) WHERE a IS NOT NULL;
CREATE VIEW ar_alter_fk_view AS SELECT id, a, b FROM ar_alter_fk_rename WHERE a >= 0;
INSERT INTO ar_alter_fk_rename(id, a, b) VALUES (1, 10, 'alpha'), (2, 20, 'beta');
ALTER TABLE ar_alter_fk_rename RENAME COLUMN b TO renamed_b;
ALTER TABLE ar_alter_fk_rename DROP COLUMN drop_me;
ALTER TABLE ar_alter_fk_rename RENAME TO ar_alter_fk_renamed;
SELECT id, a, renamed_b FROM ar_alter_fk_renamed WHERE a >= 0 ORDER BY id;
PRAGMA foreign_keys=OFF;
DROP VIEW IF EXISTS ar_alter_fk_view;
DROP TABLE IF EXISTS ar_alter_fk_renamed;
DROP TABLE IF EXISTS ar_fk_child2;
DROP TABLE IF EXISTS ar_fk_parent2;
DROP TABLE IF EXISTS ar_fk_child;
DROP TABLE IF EXISTS ar_fk_parent;
DROP TABLE IF EXISTS ar_fk_audit;
"@
    },
    @{
        Name = "integrity_check_stress"
        Description = "B-tree integrity checks, auto-vacuum, freelist, page movement, and large indexed payloads."
        Sql = @"
ROLLBACK;
COMMIT;
PRAGMA auto_vacuum=FULL;
PRAGMA page_size=4096;
VACUUM;
DROP TABLE IF EXISTS ar_ic_child;
DROP TABLE IF EXISTS ar_ic;
CREATE TABLE ar_ic(id INTEGER PRIMARY KEY, k INTEGER NOT NULL, payload TEXT, extra BLOB);
CREATE TABLE ar_ic_child(id INTEGER PRIMARY KEY, parent_id INTEGER REFERENCES ar_ic(id), note TEXT);
CREATE INDEX ar_ic_k_payload ON ar_ic(k, payload);
CREATE INDEX ar_ic_payload_expr ON ar_ic((length(payload))) WHERE k >= 0;
WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x + 1 FROM n WHERE x < 512)
INSERT INTO ar_ic(id, k, payload, extra)
SELECT x, x % 37, printf('payload-%04d-%s', x, hex(randomblob(24))), randomblob(64) FROM n;
INSERT INTO ar_ic_child(parent_id, note)
SELECT id, printf('child-%04d', id) FROM ar_ic WHERE id % 17 = 0;
DELETE FROM ar_ic_child WHERE parent_id IN (SELECT id FROM ar_ic WHERE id % 19 = 0);
DELETE FROM ar_ic WHERE id % 19 = 0;
UPDATE ar_ic SET payload = payload || '-updated' WHERE id % 23 = 0;
PRAGMA cell_size_check=ON;
PRAGMA integrity_check;
PRAGMA quick_check;
PRAGMA freelist_count;
PRAGMA page_count;
DROP TABLE ar_ic_child;
DROP TABLE ar_ic;
PRAGMA incremental_vacuum;
PRAGMA cell_size_check=OFF;
"@
    },
    @{
        Name = "scalar_aggregate_stress"
        Description = "Date/time, printf/format, replace, group_concat, FILTER, and collation edge cases."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_scalar;
CREATE TABLE ar_scalar(id INTEGER PRIMARY KEY, g INTEGER, n REAL, txt TEXT);
INSERT INTO ar_scalar(id, g, n, txt) VALUES
  (1, 0, -1.5, 'alpha'),
  (2, 0, 0.0, 'Beta'),
  (3, 1, 2.25, 'gamma'),
  (4, 1, 1000000.5, 'delta'),
  (5, 2, NULL, ''),
  (6, 2, 9223372036854775807, 'quote''value');
SELECT timediff('2024-02-29 12:34:56.789', '1900-01-01 00:00:00.001'),
       strftime('%Y-%m-%d %H:%M:%f %J %s %W %w', '2024-02-29 12:34:56.789'),
       printf('%!.*q|%lld|%#x|%.17g|%c', 12, txt, id, id, n, 65)
  FROM ar_scalar
 WHERE id IN (1, 2, 6)
 ORDER BY id;
SELECT g,
       group_concat(replace(txt, 'a', 'A'), '|') FILTER (WHERE txt IS NOT NULL),
       sum(CASE WHEN typeof(n) = 'real' THEN n ELSE 0 END),
       max(txt COLLATE NOCASE)
  FROM ar_scalar
 GROUP BY g
HAVING count(*) >= 1
 ORDER BY g;
SELECT replace(format('%08d-%s-%Q', id, txt, txt), '0', '_')
  FROM ar_scalar
 WHERE txt GLOB '*[ae]*' OR txt = ''
 ORDER BY txt COLLATE NOCASE;
DROP TABLE ar_scalar;
"@
    },
    @{
        Name = "virtual_table_update_stress"
        Description = "RTREE and FTS5 virtual table xUpdate/delete paths and constraint callbacks."
        Sql = @"
ROLLBACK;
COMMIT;
DROP TABLE IF EXISTS ar_vtab_fts;
DROP TABLE IF EXISTS ar_vtab_rt;
CREATE VIRTUAL TABLE ar_vtab_rt USING rtree(id, x1, x2, y1, y2);
INSERT INTO ar_vtab_rt VALUES
  (1, 0.0, 10.0, 0.0, 10.0),
  (2, 5.0, 15.0, 5.0, 15.0),
  (3, -5.0, 1.0, -5.0, 1.0),
  (4, 20.0, 30.0, 20.0, 30.0);
UPDATE ar_vtab_rt SET x1 = x1 - 0.5, x2 = x2 + 0.5 WHERE id IN (1, 2);
SELECT id FROM ar_vtab_rt
 WHERE x1 <= 6.0 AND x2 >= 6.0 AND y1 <= 6.0 AND y2 >= 6.0
 ORDER BY id;
DELETE FROM ar_vtab_rt WHERE id IN (SELECT id FROM ar_vtab_rt WHERE x2 < 2.0 OR x1 > 25.0);
SELECT rtreecheck('ar_vtab_rt');
CREATE VIRTUAL TABLE ar_vtab_fts USING fts5(title, body);
INSERT INTO ar_vtab_fts(rowid, title, body) VALUES
  (1, 'one', 'alpha beta gamma'),
  (2, 'two', 'delta epsilon zeta');
UPDATE ar_vtab_fts SET body = body || ' updated' WHERE rowid = 1;
DELETE FROM ar_vtab_fts WHERE ar_vtab_fts MATCH 'delta';
SELECT rowid, title FROM ar_vtab_fts WHERE ar_vtab_fts MATCH 'alpha OR updated';
DROP TABLE ar_vtab_fts;
DROP TABLE ar_vtab_rt;
"@
    },
    @{
        Name = "attach_vacuum_wal"
        Description = "ATTACH, schema switching, WAL checkpoint, VACUUM, optimize."
        Sql = @"
ROLLBACK;
COMMIT;
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
ATTACH ':memory:' AS ar_aux;
CREATE TABLE ar_aux.t(id INTEGER PRIMARY KEY, v TEXT);
INSERT INTO ar_aux.t(v) VALUES('aux-a'), ('aux-b'), ('aux-c');
SELECT count(*), max(v) FROM ar_aux.t WHERE id > 0;
DETACH ar_aux;
DROP TABLE IF EXISTS ar_vac;
CREATE TABLE ar_vac(id INTEGER PRIMARY KEY, v TEXT);
INSERT INTO ar_vac(v) VALUES('a'), ('b'), ('c');
DELETE FROM ar_vac WHERE id = 2;
PRAGMA wal_checkpoint(FULL);
PRAGMA optimize;
VACUUM;
DROP TABLE ar_vac;
PRAGMA journal_mode=DELETE;
"@
    }
)

if ($CaseName.Count -gt 0) {
    $selectedNames = New-Object 'System.Collections.Generic.HashSet[string]' -ArgumentList ([StringComparer]::OrdinalIgnoreCase)
    foreach ($rawName in $CaseName) {
        foreach ($name in ([string] $rawName -split ",")) {
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                [void] $selectedNames.Add($name.Trim())
            }
        }
    }
    $cases = @($cases | Where-Object { $_.Name -eq "baseline" -or $selectedNames.Contains($_.Name) })
    foreach ($name in $selectedNames) {
        if (-not ($cases | Where-Object { $_.Name -eq $name })) {
            throw "Unknown auto-research case: $name"
        }
    }
}

function Reset-GcovData {
    Remove-Item -LiteralPath (Join-Path $buildDir "sqlite3.gcda") -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $buildDir "shell.gcda") -Force -ErrorAction SilentlyContinue
}

function Save-GcovDataSnapshot {
    param([string] $SnapshotDir)

    New-Item -ItemType Directory -Force -Path $SnapshotDir | Out-Null
    foreach ($name in @("sqlite3.gcda", "shell.gcda")) {
        $source = Join-Path $buildDir $name
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $SnapshotDir $name) -Force
        }
    }
}

function Restore-GcovDataSnapshot {
    param([string] $SnapshotDir)

    if (-not (Test-Path -LiteralPath $SnapshotDir)) {
        throw "Missing gcov baseline snapshot: $SnapshotDir"
    }
    Reset-GcovData
    foreach ($name in @("sqlite3.gcda", "shell.gcda")) {
        $source = Join-Path $SnapshotDir $name
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $buildDir $name) -Force
        }
    }
}

function Write-GcovFileSummary {
    param(
        [string] $FunctionsPath,
        [string] $SummaryPath
    )

    $lines = @(Get-Content -LiteralPath $FunctionsPath)
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^File '") {
            $start = $i
            break
        }
    }
    if ($start -ge 0) {
        [System.IO.File]::WriteAllLines($SummaryPath, $lines[$start..($lines.Count - 1)],
            [System.Text.UTF8Encoding]::new($true))
    } else {
        [System.IO.File]::WriteAllLines($SummaryPath, @(), [System.Text.UTF8Encoding]::new($true))
    }
}

function Parse-GcovSummary {
    param([string] $SummaryPath)
    $text = Get-Content -LiteralPath $SummaryPath
    $result = [ordered]@{
        LinePct = 0.0
        LinesTotal = 0
        BranchExecPct = 0.0
        BranchesTotal = 0
        BranchTakenPct = 0.0
        CallsPct = 0.0
        CallsTotal = 0
    }
    foreach ($line in $text) {
        if ($line -match '^Lines executed:([0-9.]+)% of ([0-9]+)$' -and $result.LinePct -eq 0.0) {
            $result.LinePct = [double]$matches[1]
            $result.LinesTotal = [int]$matches[2]
        } elseif ($line -match '^Branches executed:([0-9.]+)% of ([0-9]+)$' -and $result.BranchExecPct -eq 0.0) {
            $result.BranchExecPct = [double]$matches[1]
            $result.BranchesTotal = [int]$matches[2]
        } elseif ($line -match '^Taken at least once:([0-9.]+)% of ([0-9]+)$' -and $result.BranchTakenPct -eq 0.0) {
            $result.BranchTakenPct = [double]$matches[1]
        } elseif ($line -match '^Calls executed:([0-9.]+)% of ([0-9]+)$' -and $result.CallsPct -eq 0.0) {
            $result.CallsPct = [double]$matches[1]
            $result.CallsTotal = [int]$matches[2]
        }
    }
    return $result
}

function Parse-FunctionCoverage {
    param([string] $FunctionsPath)
    $lines = @(Get-Content -LiteralPath $FunctionsPath)
    $total = 0
    $covered = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -like "Function '*") {
            $total++
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match 'Lines executed:([0-9.]+)%') {
                if ([double]$matches[1] -gt 0) {
                    $covered++
                }
            }
        }
    }
    $pct = if ($total -gt 0) { 100.0 * $covered / $total } else { 0.0 }
    return [ordered]@{ Covered = $covered; Total = $total; Pct = $pct }
}

function Parse-CoveredSourceLines {
    param([string] $GcovPath)
    $covered = New-Object 'System.Collections.Generic.HashSet[int]'
    if (-not (Test-Path -LiteralPath $GcovPath)) {
        return $covered
    }
    foreach ($line in Get-Content -LiteralPath $GcovPath) {
        if ($line -match '^\s*([0-9]+):\s*([0-9]+):') {
            [void] $covered.Add([int] $matches[2])
        }
    }
    return $covered
}

function Parse-CoveredFunctions {
    param([string] $FunctionsPath)
    $covered = New-Object 'System.Collections.Generic.HashSet[string]'
    if (-not (Test-Path -LiteralPath $FunctionsPath)) {
        return $covered
    }
    $lines = Get-Content -LiteralPath $FunctionsPath
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^Function '(.+)'$") {
            $name = $matches[1]
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match 'Lines executed:([0-9.]+)%') {
                if ([double] $matches[1] -gt 0) {
                    [void] $covered.Add($name)
                }
            }
        }
    }
    return $covered
}

function Get-SetDifference {
    param(
        [System.Collections.IEnumerable] $Left,
        [System.Collections.IEnumerable] $Right
    )
    $rightSet = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($item in $Right) {
        [void] $rightSet.Add([string] $item)
    }
    $diff = New-Object System.Collections.Generic.List[string]
    foreach ($item in $Left) {
        $value = [string] $item
        if (-not $rightSet.Contains($value)) {
            $diff.Add($value)
        }
    }
    return $diff
}

function Write-ReplayPreamble {
    param([System.IO.StreamWriter] $Writer)

    $Writer.WriteLine(".bail off")
    $Writer.WriteLine(".timer off")
    $Writer.WriteLine(".timeout 1000")
    $Writer.WriteLine("PRAGMA foreign_keys=OFF;")
    $Writer.WriteLine("PRAGMA defer_foreign_keys=OFF;")
    $Writer.WriteLine("PRAGMA ignore_check_constraints=ON;")
    $Writer.WriteLine("PRAGMA recursive_triggers=ON;")
    $Writer.WriteLine("PRAGMA trusted_schema=ON;")
    $Writer.WriteLine("PRAGMA automatic_index=ON;")
    $Writer.WriteLine("PRAGMA journal_mode=OFF;")
    $Writer.WriteLine("PRAGMA synchronous=OFF;")
    # Must match finish-long-codecov.ps1: NOT temp_store=MEMORY. vdbesort.c guards its whole
    # PMA / external-merge path with !sqlite3TempInMemory(db), so an in-memory temp store makes
    # that subsystem unreachable during measurement. This script was left on MEMORY when
    # finish-long was fixed, which biased every ranking twice over: sorting-related candidates
    # were measured with the subsystem invisible, AND their deltas were computed against a
    # baseline that finish-long had produced with temp_store=FILE.
    $Writer.WriteLine("PRAGMA temp_store=FILE;")
}

function Convert-ReplayLine {
    param([string] $Line)

    if ($Line -match '^\s*INSERT\s+INTO\s+') {
        return [System.Text.RegularExpressions.Regex]::Replace(
            $Line,
            '^\s*INSERT\s+INTO\s+',
            'INSERT OR IGNORE INTO ',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    return $Line
}

function Write-SanitizedReplay {
    param(
        [string] $InputPath,
        [string] $OutputPath
    )

    $reader = [System.IO.StreamReader]::new($InputPath)
    $writer = [System.IO.StreamWriter]::new($OutputPath, $false, [System.Text.UTF8Encoding]::new($false))
    try {
        Write-ReplayPreamble -Writer $writer
        while (($line = $reader.ReadLine()) -ne $null) {
            $writer.WriteLine((Convert-ReplayLine -Line $line))
        }
    } finally {
        $reader.Close()
        $writer.Close()
    }
}

function Write-ResearchCaseReplay {
    param(
        [string] $CaseName,
        [string] $Sql,
        [string] $OutputPath
    )

    $writer = [System.IO.StreamWriter]::new($OutputPath, $false, [System.Text.UTF8Encoding]::new($false))
    try {
        Write-ReplayPreamble -Writer $writer
        $writer.WriteLine("")
        $writer.WriteLine("-- auto-research: $CaseName")
        $writer.WriteLine("PRAGMA foreign_keys=OFF;")
        $writer.WriteLine("PRAGMA ignore_check_constraints=ON;")
        $writer.WriteLine((Normalize-ResearchCaseSql -Sql $Sql))
    } finally {
        $writer.Close()
    }
}

function Normalize-ResearchCaseSql {
    param([string] $Sql)

    $lines = $Sql -split "\r?\n"
    $kept = New-Object System.Collections.Generic.List[string]
    $atStart = $true
    foreach ($line in $lines) {
        if ($atStart) {
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }
            if ($line -match '^\s*(ROLLBACK|COMMIT)\s*;\s*$') {
                continue
            }
            $atStart = $false
        }
        $kept.Add($line)
    }
    return [string]::Join("`r`n", $kept)
}

function Invoke-SqliteReplayWithProgress {
    param(
        [string] $CaseName,
        [string] $DbPath,
        [string] $ReplayPath,
        [string] $OutLog,
        [string] $ErrLog
    )

    Write-ResearchProgress -CaseName $CaseName -Message "sqlite replay started"
    $arguments = "`"$DbPath`" `".read $ReplayPath`""
    $process = Start-Process -FilePath $sqliteExe `
        -ArgumentList $arguments `
        -RedirectStandardOutput $OutLog `
        -RedirectStandardError $ErrLog `
        -NoNewWindow `
        -PassThru
    $start = Get-Date
    $intervalMs = $ProgressIntervalSeconds * 1000
    while (-not $process.WaitForExit($intervalMs)) {
        $process.Refresh()
        $elapsed = [int] ((Get-Date) - $start).TotalSeconds
        $cpu = 0.0
        try {
            $cpu = [double] $process.CPU
        } catch {
            $cpu = 0.0
        }
        $message = "sqlite replay running: elapsed=${elapsed}s cpu=$([math]::Round($cpu, 1))s out=$(Format-ByteCount (Get-FileLengthOrZero -Path $OutLog)) err=$(Format-ByteCount (Get-FileLengthOrZero -Path $ErrLog)) db=$(Format-ByteCount (Get-FileLengthOrZero -Path $DbPath))"
        Write-ResearchProgress -CaseName $CaseName -Message $message
    }
    $process.Refresh()
    $elapsedTotal = [int] ((Get-Date) - $start).TotalSeconds
    Write-ResearchProgress -CaseName $CaseName -Message "sqlite replay finished: exit=$($process.ExitCode) elapsed=${elapsedTotal}s out=$(Format-ByteCount (Get-FileLengthOrZero -Path $OutLog)) err=$(Format-ByteCount (Get-FileLengthOrZero -Path $ErrLog)) db=$(Format-ByteCount (Get-FileLengthOrZero -Path $DbPath))"
    return $process.ExitCode
}

function Run-ResearchCase {
    param(
        $Case,
        [switch] $CandidateOnly,
        [string] $BaselineSnapshotDir = ""
    )

    $caseDir = Join-Path $OutputRoot $Case.Name
    New-Item -ItemType Directory -Force -Path $caseDir | Out-Null
    $caseReplay = Join-Path $caseDir "replay.sql"
    if ($CandidateOnly) {
        if ([string]::IsNullOrWhiteSpace($Case.Sql)) {
            throw "Candidate-only auto-research case has no SQL: $($Case.Name)"
        }
        Write-ResearchProgress -CaseName $Case.Name -Message "preparing candidate-only replay"
        Write-ResearchCaseReplay -CaseName $Case.Name -Sql $Case.Sql -OutputPath $caseReplay
    } else {
        Write-ResearchProgress -CaseName $Case.Name -Message "preparing sanitized full replay"
        Write-SanitizedReplay -InputPath $BaseReplay -OutputPath $caseReplay
        if (-not [string]::IsNullOrWhiteSpace($Case.Sql)) {
            $caseSql = Normalize-ResearchCaseSql -Sql $Case.Sql
            [System.IO.File]::AppendAllText($caseReplay,
                "`r`n-- auto-research: $($Case.Name)`r`nPRAGMA foreign_keys=OFF;`r`nPRAGMA ignore_check_constraints=ON;`r`n$caseSql`r`n",
                [System.Text.Encoding]::UTF8)
        }
    }
    Write-ResearchProgress -CaseName $Case.Name -Message "replay ready: mode=$(if ($CandidateOnly) { 'candidate-only' } else { 'full' }) size=$(Format-ByteCount (Get-FileLengthOrZero -Path $caseReplay))"

    if ($CandidateOnly) {
        if ([string]::IsNullOrWhiteSpace($BaselineSnapshotDir)) {
            Write-ResearchProgress -CaseName $Case.Name -Message "resetting gcov data for candidate-only coverage"
            Reset-GcovData
        } else {
            Write-ResearchProgress -CaseName $Case.Name -Message "restoring baseline gcov snapshot"
            Restore-GcovDataSnapshot -SnapshotDir $BaselineSnapshotDir
        }
    } else {
        Reset-GcovData
    }
    $dbPath = Join-Path $caseDir "replay.db"
    Remove-Item -LiteralPath $dbPath -Force -ErrorAction SilentlyContinue
    $outLog = Join-Path $caseDir "sqlite-replay.out.log"
    $errLog = Join-Path $caseDir "sqlite-replay.err.log"

    Push-Location $buildDir
    try {
        $oldErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $replayExit = Invoke-SqliteReplayWithProgress -CaseName $Case.Name -DbPath $dbPath -ReplayPath $caseReplay -OutLog $outLog -ErrLog $errLog
        # gcov -f prints the per-file summary after the per-function blocks, so a
        # single pass feeds both reports. Two full passes over sqlite3.c per case
        # doubled the analysis cost of every research case.
        Write-ResearchProgress -CaseName $Case.Name -Message "gcov functions started"
        & $gcovExe -f -b -c -o . "$sourceDir\sqlite3.c" > (Join-Path $caseDir "gcov-sqlite3-functions.txt") 2> (Join-Path $caseDir "gcov-sqlite3-functions.err.txt")
        $gcovFuncExit = $LASTEXITCODE
        $gcovExit = $gcovFuncExit
        Write-ResearchProgress -CaseName $Case.Name -Message "gcov functions finished: exit=$gcovFuncExit"
        Copy-Item -LiteralPath (Join-Path $caseDir "gcov-sqlite3-functions.err.txt") `
            -Destination (Join-Path $caseDir "gcov-sqlite3.err.txt") -Force -ErrorAction SilentlyContinue
        Write-GcovFileSummary -FunctionsPath (Join-Path $caseDir "gcov-sqlite3-functions.txt") `
            -SummaryPath (Join-Path $caseDir "gcov-sqlite3-summary.txt")
        $ErrorActionPreference = $oldErrorActionPreference
        Copy-Item -LiteralPath (Join-Path $buildDir "sqlite3.c.gcov") -Destination (Join-Path $caseDir "sqlite3.c.gcov") -Force -ErrorAction SilentlyContinue
    } finally {
        if (Get-Variable -Name oldErrorActionPreference -Scope Local -ErrorAction SilentlyContinue) {
            $ErrorActionPreference = $oldErrorActionPreference
        }
        Pop-Location
    }

    $summary = Parse-GcovSummary -SummaryPath (Join-Path $caseDir "gcov-sqlite3-summary.txt")
    $functions = Parse-FunctionCoverage -FunctionsPath (Join-Path $caseDir "gcov-sqlite3-functions.txt")
    $errCount = @(Select-String -Path (Join-Path $caseDir "sqlite-replay.err.log") -Pattern 'Parse error|Runtime error|Error:' -CaseSensitive:$false -ErrorAction SilentlyContinue).Count

    return [pscustomobject]@{
        Name = $Case.Name
        Description = $Case.Description
        LinePct = $summary.LinePct
        LinesTotal = $summary.LinesTotal
        BranchExecPct = $summary.BranchExecPct
        BranchesTotal = $summary.BranchesTotal
        BranchTakenPct = $summary.BranchTakenPct
        CallsPct = $summary.CallsPct
        CallsTotal = $summary.CallsTotal
        FunctionCovered = $functions.Covered
        FunctionTotal = $functions.Total
        FunctionPct = $functions.Pct
        ReplayErrors = $errCount
        ReplayExit = $replayExit
        GcovExit = $gcovExit
        GcovFuncExit = $gcovFuncExit
        GcovPath = Join-Path $caseDir "sqlite3.c.gcov"
        FunctionsPath = Join-Path $caseDir "gcov-sqlite3-functions.txt"
        Dir = $caseDir
    }
}

function New-BaselineResultFromCoverageDir {
    param([string] $CoverageDir)

    $caseDir = Join-Path $OutputRoot "baseline"
    New-Item -ItemType Directory -Force -Path $caseDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $CoverageDir "sqlite3.c.gcov") -Destination (Join-Path $caseDir "sqlite3.c.gcov") -Force
    Copy-Item -LiteralPath (Join-Path $CoverageDir "gcov-sqlite3-summary.txt") -Destination (Join-Path $caseDir "gcov-sqlite3-summary.txt") -Force
    Copy-Item -LiteralPath (Join-Path $CoverageDir "gcov-sqlite3-functions.txt") -Destination (Join-Path $caseDir "gcov-sqlite3-functions.txt") -Force
    Set-Content -LiteralPath (Join-Path $caseDir "baseline-source.txt") -Value @(
        "Baseline coverage dir: $CoverageDir"
        "Baseline replay path: $BaseReplay"
    ) -Encoding UTF8

    $summary = Parse-GcovSummary -SummaryPath (Join-Path $caseDir "gcov-sqlite3-summary.txt")
    $functions = Parse-FunctionCoverage -FunctionsPath (Join-Path $caseDir "gcov-sqlite3-functions.txt")

    return [pscustomobject]@{
        Name = "baseline"
        Description = "Reused baseline coverage from a previous completed SQLancer coverage run."
        LinePct = $summary.LinePct
        LinesTotal = $summary.LinesTotal
        BranchExecPct = $summary.BranchExecPct
        BranchesTotal = $summary.BranchesTotal
        BranchTakenPct = $summary.BranchTakenPct
        CallsPct = $summary.CallsPct
        CallsTotal = $summary.CallsTotal
        FunctionCovered = $functions.Covered
        FunctionTotal = $functions.Total
        FunctionPct = $functions.Pct
        ReplayErrors = 0
        ReplayExit = ""
        GcovExit = ""
        GcovFuncExit = ""
        GcovPath = Join-Path $caseDir "sqlite3.c.gcov"
        FunctionsPath = Join-Path $caseDir "gcov-sqlite3-functions.txt"
        Dir = $caseDir
    }
}

$results = New-Object System.Collections.Generic.List[object]
Write-Host "Base replay: $BaseReplay"
Write-Host "Output root: $OutputRoot"
Write-ResearchProgress -Message "auto-research started: cases=$($cases.Count) progressInterval=${ProgressIntervalSeconds}s"

$baselineSnapshotDir = Join-Path $OutputRoot "baseline-gcov-snapshot"
$caseIndex = 0
foreach ($case in $cases) {
    $caseIndex++
    Write-ResearchProgress -CaseName $case.Name -Message "case $caseIndex/$($cases.Count) started"
    if ($case.Name -eq "baseline") {
        if ($reuseBaselineCoverage) {
            Write-ResearchProgress -CaseName $case.Name -Message "using reusable baseline coverage artifacts"
            $results.Add((New-BaselineResultFromCoverageDir -CoverageDir $BaselineCoverageDir))
        } else {
            $results.Add((Run-ResearchCase -Case $case))
            Write-ResearchProgress -CaseName $case.Name -Message "saving baseline gcov snapshot"
            Save-GcovDataSnapshot -SnapshotDir $baselineSnapshotDir
        }
    } else {
        if ($reuseBaselineCoverage) {
            $results.Add((Run-ResearchCase -Case $case -CandidateOnly))
        } else {
            $results.Add((Run-ResearchCase -Case $case -CandidateOnly -BaselineSnapshotDir $baselineSnapshotDir))
        }
    }
    Write-ResearchProgress -CaseName $case.Name -Message "case $caseIndex/$($cases.Count) finished"
}

$baseline = $results | Where-Object { $_.Name -eq "baseline" } | Select-Object -First 1
$baselineCoveredLines = Parse-CoveredSourceLines -GcovPath $baseline.GcovPath
$baselineCoveredFunctions = Parse-CoveredFunctions -FunctionsPath $baseline.FunctionsPath

foreach ($result in $results) {
    $coveredLines = Parse-CoveredSourceLines -GcovPath $result.GcovPath
    $coveredFunctions = Parse-CoveredFunctions -FunctionsPath $result.FunctionsPath
    $newLines = @(Get-SetDifference -Left $coveredLines -Right $baselineCoveredLines |
        ForEach-Object { [int] $_ } |
        Sort-Object)
    $newFunctions = @(Get-SetDifference -Left $coveredFunctions -Right $baselineCoveredFunctions |
        Sort-Object)
    $newLinesPath = Join-Path $result.Dir "new-covered-lines-vs-baseline.txt"
    $newFunctionsPath = Join-Path $result.Dir "new-covered-functions-vs-baseline.txt"
    Set-Content -LiteralPath $newLinesPath -Value $newLines -Encoding UTF8
    Set-Content -LiteralPath $newFunctionsPath -Value $newFunctions -Encoding UTF8
    $result | Add-Member -NotePropertyName NewCoveredLines -NotePropertyValue $newLines.Count
    $result | Add-Member -NotePropertyName NewCoveredFunctions -NotePropertyValue $newFunctions.Count
    $result | Add-Member -NotePropertyName NewCoveredLinesPath -NotePropertyValue $newLinesPath
    $result | Add-Member -NotePropertyName NewCoveredFunctionsPath -NotePropertyValue $newFunctionsPath
    $projectedLinePct = $result.LinePct
    if ($baseline.LinesTotal -gt 0) {
        $projectedLinePct = [math]::Min(100.0, $baseline.LinePct + (100.0 * $newLines.Count / $baseline.LinesTotal))
    }
    $projectedFunctionPct = $result.FunctionPct
    if ($baseline.FunctionTotal -gt 0) {
        $projectedFunctionPct = [math]::Min(100.0, 100.0 * ($baseline.FunctionCovered + $newFunctions.Count) / $baseline.FunctionTotal)
    }
    $result | Add-Member -NotePropertyName ProjectedLinePct -NotePropertyValue $projectedLinePct
    $result | Add-Member -NotePropertyName ProjectedLineDelta -NotePropertyValue ($projectedLinePct - $baseline.LinePct)
    $result | Add-Member -NotePropertyName ProjectedFunctionPct -NotePropertyValue $projectedFunctionPct
    $result | Add-Member -NotePropertyName ProjectedFunctionDelta -NotePropertyValue ($projectedFunctionPct - $baseline.FunctionPct)
}

$ranked = $results | ForEach-Object {
    [pscustomobject]@{
        Name = $_.Name
        Description = $_.Description
        NewCoveredLines = $_.NewCoveredLines
        NewCoveredFunctions = $_.NewCoveredFunctions
        ProjectedLinePct = $_.ProjectedLinePct
        ProjectedLineDelta = $_.ProjectedLineDelta
        ProjectedFunctionPct = $_.ProjectedFunctionPct
        ProjectedFunctionDelta = $_.ProjectedFunctionDelta
        LinePct = $_.LinePct
        LineDelta = $_.LinePct - $baseline.LinePct
        BranchExecPct = $_.BranchExecPct
        BranchExecDelta = $_.BranchExecPct - $baseline.BranchExecPct
        BranchTakenPct = $_.BranchTakenPct
        BranchTakenDelta = $_.BranchTakenPct - $baseline.BranchTakenPct
        CallsPct = $_.CallsPct
        CallsDelta = $_.CallsPct - $baseline.CallsPct
        FunctionPct = $_.FunctionPct
        FunctionDelta = $_.FunctionPct - $baseline.FunctionPct
        FunctionCovered = $_.FunctionCovered
        ReplayErrors = $_.ReplayErrors
        NewCoveredLinesPath = $_.NewCoveredLinesPath
        NewCoveredFunctionsPath = $_.NewCoveredFunctionsPath
        Dir = $_.Dir
    }
} | Sort-Object NewCoveredLines, NewCoveredFunctions, LineDelta, FunctionDelta, BranchTakenDelta -Descending

$csvPath = Join-Path $OutputRoot "auto-research-results.csv"
$ranked | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$reportPath = Join-Path $OutputRoot "auto-research-report.txt"
$reportLines = New-Object System.Collections.Generic.List[string]
$reportLines.Add("SQLite code coverage auto-research result")
$reportLines.Add("=========================================")
$reportLines.Add("")
$reportLines.Add("Base replay: $BaseReplay")
$reportLines.Add("Output root: $OutputRoot")
$reportLines.Add("")
$reportLines.Add("Baseline:")
$reportLines.Add(("- Line coverage: {0:N2}%" -f $baseline.LinePct))
$reportLines.Add(("- Branches executed: {0:N2}%" -f $baseline.BranchExecPct))
$reportLines.Add(("- Branches taken at least once: {0:N2}%" -f $baseline.BranchTakenPct))
$reportLines.Add(("- Calls executed: {0:N2}%" -f $baseline.CallsPct))
$reportLines.Add(("- Functions executed: {0}/{1} = {2:N2}%" -f $baseline.FunctionCovered, $baseline.FunctionTotal, $baseline.FunctionPct))
$reportLines.Add("")
$reportLines.Add("Ranked candidates by new SQLite source coverage:")
foreach ($row in $ranked) {
    $reportLines.Add(("- {0}: new lines {1}, new functions {2}, projected line {3:N2}% ({4:+0.00;-0.00;0.00}), projected function {5:N2}% ({6:+0.00;-0.00;0.00})" -f
            $row.Name, $row.NewCoveredLines, $row.NewCoveredFunctions, $row.ProjectedLinePct, $row.ProjectedLineDelta,
            $row.ProjectedFunctionPct, $row.ProjectedFunctionDelta))
    $reportLines.Add(("  {0}" -f $row.Description))
    $reportLines.Add(("  New covered lines: {0}" -f $row.NewCoveredLinesPath))
    $reportLines.Add(("  New covered functions: {0}" -f $row.NewCoveredFunctionsPath))
}
$reportLines.Add("")
$reportLines.Add("CSV: $csvPath")
Set-Content -LiteralPath $reportPath -Value $reportLines -Encoding UTF8

Get-Content -LiteralPath $reportPath -Encoding UTF8
