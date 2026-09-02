<#
.SYNOPSIS
    Reports which SQLite code the last coverage run never reached.

.DESCRIPTION
    Reads the gcov output of a finished run and answers "what should the next
    long run attack": which functions were never entered, grouped into SQLite
    subsystems, with the EGraphCoverageShape wrappers that can drive each one.

    Machine-readable outputs (consumed by the research loop, same role as
    auto-research-results.csv):
      uncovered-functions.csv  one row per never-entered function
      uncovered-modules.csv    subsystem totals, worst first, with shape hints
    Human-readable: uncovered-code-report.txt, uncovered-line-runs.txt
#>
param(
    [string] $RunDir = "",
    [int] $MinRunLength = 5,
    [int] $Top = 200
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$coverageRoot = "D:\sqlancer\coverage\sqlite"

# Subsystem classification, most specific pattern first. Shapes are
# EGraphCoverageShape values (SQLite3OracleFactory) that exercise the subsystem;
# an empty list means no wrapper drives that code yet, which is itself the
# finding.
$moduleRules = @(
    @{ Pattern = '^(sqlite3_?)?[Ff]ts5';          Module = 'FTS5';              Shapes = 'FTS5_MATCH_CONTEXT,FTS5_DEEP_CONTEXT,FTS5_SECURE_DELETE_CONTEXT,FTS5_DEEP_QUERY_CONTEXT,FTS5_AUX_DEEP_CONTEXT,FTS5_TOMBSTONE_CONTEXT,FTS5_TOKENIZER_VARIANT_CONTEXT,FTS5_VARIANT_CONFIG_CONTEXT' }
    @{ Pattern = '^(sqlite3_?)?[Ff]ts[34]|fts3|fts4'; Module = 'FTS3/FTS4';     Shapes = 'FTS4_MATCH_CONTEXT,FTS4_AUX_CONTEXT,FTS4_DEEP_SEGMENT_CONTEXT,FTS4_MERGE_LCS_CONTEXT,FTS3_TOKENIZE_TABLE_CONTEXT' }
    @{ Pattern = '^porter|^unicode|[Tt]okeniz';   Module = 'FTS tokenizers';    Shapes = 'FTS5_TOKENIZER_VARIANT_CONTEXT,FTS5_DEEP_QUERY_CONTEXT,FTS3_TOKENIZE_TABLE_CONTEXT,FTS4_MATCH_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Rr]tree|geopoly';   Module = 'RTREE/GEOPOLY';     Shapes = 'RTREE_CONTEXT,RTREE_DEEP_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Jj]sonb?|^jsonb?';  Module = 'JSON';              Shapes = 'JSON_CONTEXT,JSONB_STRESS_CONTEXT' }
    @{ Pattern = 'dbstat';                        Module = 'DBSTAT';            Shapes = 'DBSTAT_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Ww]indow|^winFunc'; Module = 'Window functions';  Shapes = 'WINDOW_COUNT,WINDOW_RANGE_FULLSCAN_CONTEXT,WINDOW_FUNCTION_BATTERY_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Ww]al';             Module = 'WAL';               Shapes = 'TX_WAL_VACUUM_CONTEXT,ATTACH_VACUUM_WAL_CONTEXT' }
    @{ Pattern = 'vacuum';                        Module = 'VACUUM';            Shapes = 'TX_WAL_VACUUM_CONTEXT,AUTO_VACUUM_INTEGRITY_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Aa]lter|[Rr]ename'; Module = 'ALTER TABLE';       Shapes = 'ALTER_INDEX_ANALYZE_CONTEXT,ALTER_FK_STRESS_CONTEXT,SQL_SYNTAX_BATTERY_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Tt]rigger';         Module = 'Triggers';          Shapes = 'VIEW_TRIGGER_FK_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Ff][Kk]ey|foreignKey'; Module = 'Foreign keys';   Shapes = 'VIEW_TRIGGER_FK_CONTEXT,ALTER_FK_STRESS_CONTEXT,SQL_SYNTAX_BATTERY_CONTEXT' }
    @{ Pattern = 'integrity|[Cc]keckpoint|checkpoint'; Module = 'Integrity/checkpoint'; Shapes = 'INTEGRITY_CHECK_CONTEXT,AUTO_VACUUM_INTEGRITY_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Ww]here';           Module = 'WHERE optimizer';   Shapes = 'JOIN_OPTIMIZER_CONTEXT,SELECT_WHERE_STRESS_CONTEXT,MULTI_INDEX_OR,AUTOMATIC_INDEX' }
    @{ Pattern = '^(sqlite3)?[Ss]elect|^flattenSubquery|^pushDown'; Module = 'SELECT planner'; Shapes = 'SELECT_WHERE_STRESS_CONTEXT,DERIVED_TABLE,CO_ROUTINE,MATERIALIZED_CTE,MULTI_SELECT_ORDER_BY_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Ee]xpr';            Module = 'Expressions';       Shapes = 'EXPR_STRESS_CONTEXT,ROW_VALUE_CONTEXT,SCALAR_FUNCTION_BATTERY_CONTEXT,WHERE_CASE_TRUE' }
    @{ Pattern = '^(sqlite3)?[Ss]orter|^vdbeSorter'; Module = 'Sorter';         Shapes = 'SORTER_STRESS_CONTEXT,SORTER_DEEP_MERGE_CONTEXT,MULTI_SELECT_ORDER_BY_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Rr]esolve|lookupName'; Module = 'Name resolution'; Shapes = 'RESOLVE_STRESS_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Aa]nalyze|^stat[0-9]|loadStat'; Module = 'ANALYZE/stat'; Shapes = 'ANALYZE_INDEX_CONTEXT,ALTER_INDEX_ANALYZE_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Vv]tab|moduleApi';  Module = 'Virtual tables';    Shapes = 'VIRTUAL_TABLE_UPDATE_CONTEXT,VIRTUAL_TABLE_SAVEPOINT_CONTEXT' }
    @{ Pattern = 'xferOpt|xferCompatible';        Module = 'INSERT xfer opt';   Shapes = 'XFER_OPTIMIZATION_CONTEXT' }
    @{ Pattern = 'upsert';                        Module = 'UPSERT';            Shapes = 'SQL_SYNTAX_BATTERY_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Aa]ttach';          Module = 'ATTACH';            Shapes = 'ATTACH_VACUUM_WAL_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Pp]ragma';          Module = 'PRAGMA';            Shapes = 'SQL_SYNTAX_BATTERY_CONTEXT,PRAGMA_VTAB_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Ss]ession|changeset|^sessionn'; Module = 'Session/changeset'; Shapes = '' }
    @{ Pattern = '^(sqlite3)?[Bb]ackup';          Module = 'Backup API';        Shapes = '' }
    @{ Pattern = '^(sqlite3)?[Bb]tree|^balance|^cellInfo'; Module = 'B-tree';   Shapes = 'AUTOMATIC_INDEX,MULTI_INDEX_OR_ROWSET_CONTEXT,BLOOM_FILTER_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Pp]ager|^pcache|^walIndex'; Module = 'Pager/pcache'; Shapes = 'TX_WAL_VACUUM_CONTEXT,FTS4_MERGE_LCS_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Vv]dbe|^opcode|^sqlite3Step'; Module = 'VDBE';    Shapes = 'SQL_SYNTAX_BATTERY_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Oo]s|^win[A-Z]|^unix'; Module = 'OS layer';       Shapes = 'FTS4_MERGE_LCS_CONTEXT' }
    @{ Pattern = '^(sqlite3)?[Mm]em|^malloc|^mutex|^sqlite3Mutex'; Module = 'Memory/mutex'; Shapes = '' }
    @{ Pattern = '^sqlite3Bitvec';                Module = 'Bitvec';            Shapes = 'INTEGRITY_CHECK_CONTEXT,TX_WAL_VACUUM_CONTEXT' }
    @{ Pattern = '^yy|^sqlite3Parser|^sqlite3RunParser|^sqlite3GetToken'; Module = 'SQL parser'; Shapes = 'SQL_SYNTAX_BATTERY_CONTEXT,EXPR_STRESS_CONTEXT,SELECT_WHERE_STRESS_CONTEXT' }
    @{ Pattern = '^datetime|^dateFunc|^timeFunc|^juliandayFunc|^strftime|^parseYyyy|^parseHh|^currentTime'; Module = 'Date/time functions'; Shapes = 'DATE_MODIFIER_BATTERY_CONTEXT' }
    # Must stay last among the sqlite3_* rules: the public C API is only entered
    # by a C caller, so no SQL workload can ever cover it. Reporting it as a
    # coverage target would send the next run after unreachable code.
    @{ Pattern = '^sqlite3_';                     Module = 'C API surface';     Shapes = '' }
)

# Subsystems no SQL statement can drive; they need a C harness, not a wrapper.
$apiOnlyModules = @('C API surface', 'Session/changeset', 'Backup API')

# Covering these changes no query result, so a metamorphic oracle cannot turn
# them into a bug report: EXPLAIN and debug rendering, error formatting, and
# destructors. Chasing them raises the coverage percentage and nothing else,
# which is exactly the trade the guidance should not recommend.
$nonResultPatterns = @(
    'Display|Explain|ExpandSql|NextOpcode|^sqlite3VdbeList$|Trace|Print|Dump|Comment|Coverage',
    'Error$|Error[A-Z]|Misuse|Corrupt|Malformed|OomFault',
    'Delete$|Free$|Cleanup$|Destroy$|Release$|Unref$|Clear$|Finalize$|Reset$|Close$'
)

function Test-AffectsResults {
    param([string] $Name, [string[]] $Patterns)

    foreach ($pattern in $Patterns) {
        if ($Name -match $pattern) {
            return $false
        }
    }
    return $true
}

function Resolve-AnalysisRunDir {
    <#
        Picks the run whose gcov output should be analysed. Prefers the pointer
        that finish-long-codecov.ps1 maintains; falls back to the newest run dir
        that actually holds both required inputs. The build directory is skipped
        on purpose: it holds transient gcov output, not a run.
    #>
    param([string] $Requested, [string] $Root)

    if (-not [string]::IsNullOrWhiteSpace($Requested)) {
        return (Resolve-Path -LiteralPath $Requested).Path
    }

    $pointer = Join-Path $Root "last-long-codecov-run.txt"
    if (Test-Path -LiteralPath $pointer) {
        $candidate = (Get-Content -LiteralPath $pointer -TotalCount 1).Trim()
        if ((Test-Path -LiteralPath $candidate) -and
            (Test-Path -LiteralPath (Join-Path $candidate "sqlite3.c.gcov"))) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $latest = Get-ChildItem -LiteralPath $Root -Directory |
        Where-Object {
            $_.Name -notlike "build*" -and
            (Test-Path -LiteralPath (Join-Path $_.FullName "sqlite3.c.gcov")) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName "gcov-sqlite3-functions.txt"))
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $latest) {
        throw ("No run directory under {0} holds both sqlite3.c.gcov and " +
            "gcov-sqlite3-functions.txt. Run finish-long-codecov.ps1 first." -f $Root)
    }
    return $latest.FullName
}

function Get-FunctionModule {
    param([string] $Name, [object[]] $Rules)

    foreach ($rule in $Rules) {
        if ($Name -match $rule.Pattern) {
            return [pscustomobject]@{ Module = $rule.Module; Shapes = $rule.Shapes }
        }
    }
    return [pscustomobject]@{ Module = 'other'; Shapes = '' }
}

function Get-UncoveredFunctions {
    param([string] $Path, [object[]] $Rules, [string[]] $ApiOnlyModules, [string[]] $NonResultPatterns)

    $result = New-Object System.Collections.Generic.List[object]
    $lines = @(Get-Content -LiteralPath $Path)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch "^Function '(.+)'$") {
            continue
        }
        $name = $matches[1]
        if ($i + 1 -ge $lines.Count -or $lines[$i + 1] -notmatch 'Lines executed:([0-9.]+)% of ([0-9]+)') {
            continue
        }
        $pct = [double] $matches[1]
        $lineCount = [int] $matches[2]
        if ($pct -ne 0.0) {
            continue
        }
        $classification = Get-FunctionModule -Name $name -Rules $Rules
        $drivable = -not ($ApiOnlyModules -contains $classification.Module)
        $affectsResults = Test-AffectsResults -Name $name -Patterns $NonResultPatterns
        $result.Add([pscustomobject]@{
                Function = $name
                Lines = $lineCount
                Module = $classification.Module
                DrivableFromSql = $drivable
                AffectsResults = $affectsResults
                OracleTarget = ($drivable -and $affectsResults)
                SuggestedShapes = $classification.Shapes
            })
    }
    return $result
}

function Get-UncoveredLineRuns {
    param([string] $Path, [int] $MinimumLength)

    $runs = New-Object System.Collections.Generic.List[object]
    $currentStart = 0
    $currentEnd = 0
    $currentPreview = ""

    foreach ($line in [System.IO.File]::ReadLines($Path)) {
        if ($line -match '^\s*#####+:\s*([0-9]+):(.*)$') {
            $lineNumber = [int] $matches[1]
            $source = $matches[2].Trim()
            if ($currentStart -eq 0) {
                $currentStart = $lineNumber
                $currentPreview = $source
            }
            $currentEnd = $lineNumber
            continue
        }
        if ($currentStart -ne 0) {
            $length = $currentEnd - $currentStart + 1
            if ($length -ge $MinimumLength) {
                $runs.Add([pscustomobject]@{
                        StartLine = $currentStart
                        EndLine = $currentEnd
                        Length = $length
                        Preview = $currentPreview
                    })
            }
            $currentStart = 0
            $currentEnd = 0
            $currentPreview = ""
        }
    }
    if ($currentStart -ne 0 -and ($currentEnd - $currentStart + 1) -ge $MinimumLength) {
        $runs.Add([pscustomobject]@{
                StartLine = $currentStart
                EndLine = $currentEnd
                Length = $currentEnd - $currentStart + 1
                Preview = $currentPreview
            })
    }
    return $runs
}

$resolvedRunDir = Resolve-AnalysisRunDir -Requested $RunDir -Root $coverageRoot
$resolvedCoverageRoot = (Resolve-Path -LiteralPath $coverageRoot).Path
if (-not $resolvedRunDir.StartsWith($resolvedCoverageRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Unexpected run dir outside coverage root: $resolvedRunDir"
}

$gcovPath = Join-Path $resolvedRunDir "sqlite3.c.gcov"
$functionsPath = Join-Path $resolvedRunDir "gcov-sqlite3-functions.txt"
foreach ($required in @($gcovPath, $functionsPath)) {
    if (-not (Test-Path -LiteralPath $required)) {
        # Failing loudly matters: a missing functions file used to yield an empty
        # "uncovered functions" section that read like perfect coverage.
        throw "Missing analysis input: $required"
    }
}

$allUncovered = @(Get-UncoveredFunctions -Path $functionsPath -Rules $moduleRules -ApiOnlyModules $apiOnlyModules -NonResultPatterns $nonResultPatterns)
$uncoveredFunctions = $allUncovered | Sort-Object Lines -Descending
$uncoveredRuns = @(Get-UncoveredLineRuns -Path $gcovPath -MinimumLength $MinRunLength) |
    Sort-Object Length -Descending

$moduleTotals = $allUncovered | Group-Object Module | ForEach-Object {
    $oracleRows = @($_.Group | Where-Object { $_.OracleTarget })
    $oracleLines = if ($oracleRows.Count -gt 0) {
        ($oracleRows | Measure-Object -Property Lines -Sum).Sum
    } else {
        0
    }
    [pscustomobject]@{
        Module = $_.Name
        UncoveredFunctions = $_.Count
        UncoveredLines = ($_.Group | Measure-Object -Property Lines -Sum).Sum
        OracleTargetLines = $oracleLines
        OracleTargetFunctions = $oracleRows.Count
        DrivableFromSql = ($_.Group | Select-Object -First 1).DrivableFromSql
        SuggestedShapes = ($_.Group | Select-Object -First 1).SuggestedShapes
    }
} | Sort-Object OracleTargetLines -Descending

$functionsCsv = Join-Path $resolvedRunDir "uncovered-functions.csv"
$modulesCsv = Join-Path $resolvedRunDir "uncovered-modules.csv"
$runsOut = Join-Path $resolvedRunDir "uncovered-line-runs.txt"
$reportOut = Join-Path $resolvedRunDir "uncovered-code-report.txt"

$uncoveredFunctions | Export-Csv -LiteralPath $functionsCsv -NoTypeInformation -Encoding UTF8
$moduleTotals | Export-Csv -LiteralPath $modulesCsv -NoTypeInformation -Encoding UTF8
$uncoveredRuns | Select-Object -First $Top | Format-Table -AutoSize | Out-String -Width 240 |
    Set-Content -LiteralPath $runsOut -Encoding UTF8

$totalUncoveredLines = if ($allUncovered.Count -gt 0) {
    ($allUncovered | Measure-Object -Property Lines -Sum).Sum
} else {
    0
}

$report = New-Object System.Collections.Generic.List[string]
$report.Add("SQLite uncovered code analysis")
$report.Add("==============================")
$report.Add("")
$report.Add("Run dir: $resolvedRunDir")
$report.Add("GCOV source: $gcovPath")
$report.Add("Never-entered functions: $($allUncovered.Count)")
$report.Add("Lines in never-entered functions: $totalUncoveredLines")
$report.Add("Minimum uncovered run length: $MinRunLength")
$report.Add("")
$report.Add("Outputs")
$report.Add("- Per function (CSV): $functionsCsv")
$report.Add("- Per subsystem (CSV): $modulesCsv")
$report.Add("- Uncovered line runs: $runsOut")
$report.Add("")
$drivable = @($moduleTotals | Where-Object { $_.DrivableFromSql })
$apiOnly = @($moduleTotals | Where-Object { -not $_.DrivableFromSql })
$drivableLines = if ($drivable.Count -gt 0) { ($drivable | Measure-Object -Property UncoveredLines -Sum).Sum } else { 0 }
$apiOnlyLines = if ($apiOnly.Count -gt 0) { ($apiOnly | Measure-Object -Property UncoveredLines -Sum).Sum } else { 0 }
$noShapeLines = if ($drivable.Count -gt 0) {
    (@($drivable | Where-Object { [string]::IsNullOrWhiteSpace($_.SuggestedShapes) }) |
        Measure-Object -Property OracleTargetLines -Sum).Sum
} else {
    0
}
if ($null -eq $noShapeLines) { $noShapeLines = 0 }

$oracleTargetLines = (@($allUncovered | Where-Object { $_.OracleTarget }) |
    Measure-Object -Property Lines -Sum).Sum
if ($null -eq $oracleTargetLines) { $oracleTargetLines = 0 }
$cosmeticLines = $drivableLines - $oracleTargetLines

$report.Add(("Reachable from SQL: {0} lines; C-API only (needs a C harness): {1} lines" -f `
            $drivableLines, $apiOnlyLines))
$report.Add(("Of the reachable lines, {0} can change a query result (oracle targets) and {1} cannot" -f `
            $oracleTargetLines, $cosmeticLines))
$report.Add("  (the rest is EXPLAIN/debug rendering, error formatting and destructors:")
$report.Add("   covering it moves the percentage but can never produce a bug report)")
$report.Add(("Oracle-target lines with no wrapper shape driving them: {0}" -f $noShapeLines))
$report.Add("")
$report.Add("Oracle targets by subsystem (lines that can change a result, worst first)")
foreach ($module in $drivable) {
    if ($module.OracleTargetLines -eq 0) {
        continue
    }
    $shapes = if ([string]::IsNullOrWhiteSpace($module.SuggestedShapes)) {
        "NO WRAPPER SHAPE DRIVES THIS"
    } else {
        $module.SuggestedShapes
    }
    $report.Add(("- {0,-22} {1,6} oracle lines ({2,5} total) in {3,4} functions  ->  {4}" -f `
                $module.Module, $module.OracleTargetLines, $module.UncoveredLines,
                $module.OracleTargetFunctions, $shapes))
}
$report.Add("")
$report.Add("Top never-entered functions that can change a result")
foreach ($fn in @($uncoveredFunctions | Where-Object { $_.OracleTarget } | Select-Object -First 25)) {
    $report.Add(("- {0} ({1} lines, {2})" -f $fn.Function, $fn.Lines, $fn.Module))
}
$report.Add("")
$report.Add("Not reachable from SQL (excluded from the targets above)")
foreach ($module in $apiOnly) {
    $report.Add(("- {0,-22} {1,6} lines in {2,4} functions" -f `
                $module.Module, $module.UncoveredLines, $module.UncoveredFunctions))
}
$report.Add("")
$report.Add("Top never-entered functions")
foreach ($fn in $uncoveredFunctions | Select-Object -First 30) {
    $report.Add(("- {0} ({1} lines, {2})" -f $fn.Function, $fn.Lines, $fn.Module))
}
$report.Add("")
$report.Add("Top uncovered line runs")
foreach ($run in $uncoveredRuns | Select-Object -First 30) {
    $report.Add(("- lines {0}-{1} ({2} lines): {3}" -f $run.StartLine, $run.EndLine, $run.Length, $run.Preview))
}

Set-Content -LiteralPath $reportOut -Value $report -Encoding UTF8
Get-Content -LiteralPath $reportOut -Encoding UTF8
