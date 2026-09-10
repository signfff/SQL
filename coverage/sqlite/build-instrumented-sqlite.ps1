<#
.SYNOPSIS
    Builds the gcov-instrumented SQLite shell used for code coverage.

.DESCRIPTION
    The coverage numbers are only meaningful if the instrumented binary is a
    feature-equivalent build of the SQLite that SQLancer actually tests, which is
    the native library inside sqlite-jdbc. The defines below were derived by
    diffing 'PRAGMA compile_options' of both builds; keep them in sync whenever
    the sqlite-jdbc dependency is upgraded:

        java -cp target\sqlancer-2.0.0.jar CompileOptions.java   (JDBC side)
        .\build\sqlite3_cov.exe  ->  PRAGMA compile_options;     (coverage side)

    Rebuilding replaces sqlite3.gcno, which invalidates every previously
    collected .gcda file, so all coverage baselines restart from here.
#>
param(
    [string] $SourceDir = "D:\sqlancer\coverage\sqlite\sqlite-amalgamation-3530400",
    [string] $BuildDir = "D:\sqlancer\coverage\sqlite\build",
    [string] $Gcc = "D:\Dev-Cpp\TDM-GCC-64\bin\gcc.exe",
    [switch] $NoBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

foreach ($path in @($SourceDir, $BuildDir, $Gcc)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing path: $path"
    }
}

$sqliteSource = Join-Path $SourceDir "sqlite3.c"
$shellSource = Join-Path $SourceDir "shell.c"
$exePath = Join-Path $BuildDir "sqlite3_cov.exe"

# Feature flags: present in the sqlite-jdbc build, so the coverage build needs
# them too. Without ENABLE_FTS3 every fts4 statement in the workload failed with
# "no such module: fts4" and its code stayed permanently uncovered.
$featureDefines = @(
    "-DSQLITE_ENABLE_FTS3",
    "-DSQLITE_ENABLE_FTS3_PARENTHESIS",
    "-DSQLITE_ENABLE_FTS5",
    "-DSQLITE_ENABLE_RTREE",
    "-DSQLITE_ENABLE_DBSTAT_VTAB",
    "-DSQLITE_ENABLE_STAT4",
    "-DSQLITE_ENABLE_MATH_FUNCTIONS",
    "-DSQLITE_ENABLE_COLUMN_METADATA",
    "-DSQLITE_ENABLE_LOAD_EXTENSION",
    # Added 2026-09-08 after diffing PRAGMA compile_options against the sqlite-jdbc build; it was
    # missing here in the 3.49.1 build too, so this was never aligned. Verified working:
    # median(x) returns a value on the coverage binary.
    "-DSQLITE_ENABLE_PERCENTILE"
    #
    # Two differences remain and CANNOT be closed from the public amalgamation:
    #
    #   SQLITE_ENABLE_UPDATE_DELETE_LIMIT - must be passed to lemon when parse.c is generated, not
    #     to gcc. The shipped amalgamation carries pre-generated parse tables without the rule, so
    #     defining the macro only makes PRAGMA compile_options claim support that is not there
    #     (verified: "DELETE FROM t LIMIT 1" still fails to parse with the macro defined, while it
    #     succeeds under sqlite-jdbc). Deliberately NOT defined - a compile_options entry that lies
    #     is worse than a visible difference. Consequence to keep in mind: SQLancer can execute
    #     "DELETE/UPDATE ... LIMIT" during a run, and those statements will fail on replay. That is
    #     a real contributor to the "Replay chunks failed" count and it is not a coverage bug.
    #
    #   JDBC_EXTENSIONS - registered by the sqlite-jdbc driver itself, not an amalgamation flag.
)

# Limits and behaviour: a statement that the JDBC build accepts must not be
# rejected here, otherwise the replay loses coverage that the run really had.
$limitDefines = @(
    "-DSQLITE_THREADSAFE=1",
    "-DSQLITE_MAX_WORKER_THREADS=8",
    "-DSQLITE_MAX_ATTACHED=125",
    "-DSQLITE_MAX_COLUMN=32767",
    "-DSQLITE_MAX_FUNCTION_ARG=127",
    "-DSQLITE_MAX_LENGTH=2147483647",
    "-DSQLITE_MAX_SQL_LENGTH=1073741824",
    "-DSQLITE_MAX_VARIABLE_NUMBER=250000",
    "-DSQLITE_MAX_PAGE_COUNT=4294967294",
    "-DSQLITE_MAX_MMAP_SIZE=1099511627776",
    "-DSQLITE_DEFAULT_MEMSTATUS=0",
    "-DSQLITE_DEFAULT_FILE_PERMISSIONS=0666",
    "-DSQLITE_DISABLE_PAGECACHE_OVERFLOW_STATS",
    "-DSQLITE_HAVE_ISNAN"
)

if (-not $NoBackup) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = Join-Path (Split-Path -Parent $BuildDir) "build-backup-$stamp"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    Get-ChildItem -LiteralPath $BuildDir -File |
        Where-Object { $_.Extension -in @(".exe", ".gcno") } |
        ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $backupDir -Force }
    Write-Host "Backed up previous binary and notes files to: $backupDir"
}

# Stale counters cannot be read against the new notes files.
Get-ChildItem -LiteralPath $BuildDir -File |
    Where-Object { $_.Extension -in @(".gcda", ".gcno", ".gcov") } |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

$compileArgs = @("-O0", "-g", "--coverage") + $featureDefines + $limitDefines +
    @("-o", $exePath, $shellSource, $sqliteSource)

Write-Host "Compiling instrumented SQLite (this takes a few minutes)..."
Write-Host ("  gcc " + ($compileArgs -join " "))
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Push-Location $BuildDir
try {
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $Gcc $compileArgs
    $exitCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $oldErrorActionPreference
    Pop-Location
}
$stopwatch.Stop()
if ($exitCode -ne 0) {
    throw "gcc failed with exit code $exitCode"
}
Write-Host ("Compiled in {0:N1} min" -f $stopwatch.Elapsed.TotalMinutes)

foreach ($artifact in @("sqlite3_cov.exe", "sqlite3.gcno", "shell.gcno")) {
    $path = Join-Path $BuildDir $artifact
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Build did not produce $artifact"
    }
    "{0,-18} {1,12:N0} bytes" -f $artifact, (Get-Item -LiteralPath $path).Length | Write-Host
}

Write-Host ""
Write-Host "Verifying the modules the coverage wrappers depend on..."
$probe = @(
    "CREATE VIRTUAL TABLE f4 USING fts4(a);",
    "CREATE VIRTUAL TABLE f5 USING fts5(a);",
    "CREATE VIRTUAL TABLE r1 USING rtree(id, x0, x1);",
    "CREATE VIRTUAL TABLE d1 USING dbstat;",
    "SELECT json_valid('{}');",
    "SELECT 'modules-ok';"
) -join "`n"
$probeOut = $probe | & $exePath ":memory:" 2>&1
$probeText = ($probeOut | Out-String)
if ($probeText -match "modules-ok" -and $probeText -notmatch "no such module") {
    Write-Host "  all probed modules available"
} else {
    Write-Warning "module probe reported problems:"
    Write-Warning $probeText
}

# Counters from the probe run must not be mistaken for workload coverage.
Get-ChildItem -LiteralPath $BuildDir -File -Filter "*.gcda" |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

Write-Host ""
Write-Host "Instrumented build ready: $exePath"
Write-Host "All previous .gcda data is now invalid; coverage baselines restart from this build."
