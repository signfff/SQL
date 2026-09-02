Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Location "D:\sqlancer"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runDir = "D:\sqlancer\coverage\sqlite\manual-1h-$stamp"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$baseArgs = Get-Content -LiteralPath "D:\sqlancer\target\sqlancer-run.args"
if ($baseArgs.Count -eq 0) {
    throw "target\sqlancer-run.args is empty"
}

$newArgs = New-Object System.Collections.Generic.List[string]
$nextTimeout = $false
$nextQueries = $false
$insertedLog = $false

foreach ($line in $baseArgs) {
    if ($nextTimeout) {
        $newArgs.Add("3600")
        $nextTimeout = $false
        continue
    }
    if ($nextQueries) {
        $newArgs.Add("1000000")
        $nextQueries = $false
        continue
    }
    if ($line -eq "--timeout-seconds") {
        $newArgs.Add($line)
        $nextTimeout = $true
        continue
    }
    if ($line -eq "--num-queries") {
        $newArgs.Add($line)
        $nextQueries = $true
        continue
    }
    if (-not $insertedLog -and $line -eq "sqlite3") {
        $newArgs.Add("--log-each-select")
        $newArgs.Add("true")
        $newArgs.Add("--egraph-log-each-select")
        $newArgs.Add("true")
        $insertedLog = $true
    }
    $newArgs.Add($line)
}

if (-not $insertedLog) {
    throw "Could not find sqlite3 marker in sqlancer-run.args"
}

$argsFile = Join-Path $runDir "sqlancer-codecov-1h.args"
Set-Content -LiteralPath $argsFile -Value $newArgs -Encoding ASCII

$logFile = "D:\sqlancer\logs\sqlite3\database0-cur.log"
if (Test-Path -LiteralPath $logFile) {
    Copy-Item -LiteralPath $logFile -Destination (Join-Path $runDir "previous-database0-cur.log") -Force
    Remove-Item -LiteralPath $logFile -Force
}

Write-Host "Run dir: $runDir"
Write-Host "Args file: $argsFile"
Write-Host "SQLancer is running silently. Monitor with:"
Write-Host "Get-Content `"$runDir\sqlancer.out.log`" -Tail 20 -Wait"

$javaExe = (Get-Command java.exe -ErrorAction Stop).Source
$javaArgs = @(
    "-Degraph.coverage.file=$runDir\workload-hints.txt",
    "@$argsFile"
)
$process = Start-Process -FilePath $javaExe `
    -ArgumentList $javaArgs `
    -RedirectStandardOutput "$runDir\sqlancer.out.log" `
    -RedirectStandardError "$runDir\sqlancer.err.log" `
    -WindowStyle Hidden `
    -Wait `
    -PassThru

Write-Host "SQLancer exit code: $($process.ExitCode)"

if (-not (Test-Path -LiteralPath $logFile)) {
    throw "SQLancer finished but did not create $logFile. Check $runDir\sqlancer.err.log"
}

Copy-Item -LiteralPath $logFile -Destination (Join-Path $runDir "replay.sql") -Force
Write-Host "1h capture finished."
Write-Host "Run dir: $runDir"

$coverageRoot = "D:\sqlancer\coverage\sqlite"
$buildDir = Join-Path $coverageRoot "build"
$sourceDir = Join-Path $coverageRoot "sqlite-amalgamation-3490100"
$sqliteExe = Join-Path $buildDir "sqlite3_cov.exe"
$gcovExe = "D:\Dev-Cpp\TDM-GCC-64\bin\gcov.exe"
$sqliteSource = Join-Path $sourceDir "sqlite3.c"

function Parse-GcovSummary {
    param([string] $SummaryPath)
    $result = [ordered]@{
        LinePct = 0.0
        LineTotal = 0
        BranchExecPct = 0.0
        BranchTotal = 0
        BranchTakenPct = 0.0
        CallsPct = 0.0
        CallsTotal = 0
    }
    foreach ($line in Get-Content -LiteralPath $SummaryPath) {
        if ($line -match '^Lines executed:([0-9.]+)% of ([0-9]+)$') {
            $result.LinePct = [double] $matches[1]
            $result.LineTotal = [int] $matches[2]
        } elseif ($line -match '^Branches executed:([0-9.]+)% of ([0-9]+)$' -and $result.BranchExecPct -eq 0.0) {
            $result.BranchExecPct = [double] $matches[1]
            $result.BranchTotal = [int] $matches[2]
        } elseif ($line -match '^Taken at least once:([0-9.]+)% of ([0-9]+)$') {
            $result.BranchTakenPct = [double] $matches[1]
        } elseif ($line -match '^Calls executed:([0-9.]+)% of ([0-9]+)$' -and $result.CallsTotal -eq 0) {
            $result.CallsPct = [double] $matches[1]
            $result.CallsTotal = [int] $matches[2]
        }
    }
    return $result
}

function Parse-FunctionCoverage {
    param([string] $FunctionsPath)
    $lines = Get-Content -LiteralPath $FunctionsPath
    $total = 0
    $covered = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -like "Function '*") {
            $total++
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match 'Lines executed:([0-9.]+)%') {
                if ([double] $matches[1] -gt 0) {
                    $covered++
                }
            }
        }
    }
    $pct = if ($total -gt 0) { 100.0 * $covered / $total } else { 0.0 }
    return [ordered]@{ Covered = $covered; Total = $total; Pct = $pct }
}

if ((Test-Path -LiteralPath $sqliteExe) -and (Test-Path -LiteralPath $gcovExe) -and
        (Test-Path -LiteralPath $sqliteSource)) {
    Write-Host "Replaying captured SQL with instrumented SQLite..."

    $resolvedBuildDir = (Resolve-Path -LiteralPath $buildDir).Path
    if ($resolvedBuildDir -ne "D:\sqlancer\coverage\sqlite\build") {
        throw "Unexpected build dir: $resolvedBuildDir"
    }

    Get-ChildItem -LiteralPath $resolvedBuildDir -File |
        Where-Object { $_.Extension -eq ".gcda" -or $_.Extension -eq ".gcov" } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

    $replayFile = Join-Path $runDir "replay.sql"
    $replayDb = Join-Path $runDir "codecov-replay.db"
    Remove-Item -LiteralPath $replayDb -Force -ErrorAction SilentlyContinue

    Push-Location $resolvedBuildDir
    try {
        $oldErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $replayProcess = Start-Process -FilePath $sqliteExe `
            -ArgumentList @($replayDb) `
            -RedirectStandardInput $replayFile `
            -RedirectStandardOutput (Join-Path $runDir "sqlite-replay.out.log") `
            -RedirectStandardError (Join-Path $runDir "sqlite-replay.err.log") `
            -WorkingDirectory $resolvedBuildDir `
            -WindowStyle Hidden `
            -Wait `
            -PassThru
        $replayExit = $replayProcess.ExitCode
        & $gcovExe -b -c -o . $sqliteSource > (Join-Path $runDir "gcov-sqlite3-summary.txt") 2> (Join-Path $runDir "gcov-sqlite3.err.txt")
        $gcovExit = $LASTEXITCODE
        & $gcovExe -f -b -c -o . $sqliteSource > (Join-Path $runDir "gcov-sqlite3-functions.txt") 2> (Join-Path $runDir "gcov-sqlite3-functions.err.txt")
        $gcovFuncExit = $LASTEXITCODE
        $ErrorActionPreference = $oldErrorActionPreference
        Copy-Item -LiteralPath (Join-Path $resolvedBuildDir "sqlite3.c.gcov") -Destination (Join-Path $runDir "sqlite3.c.gcov") -Force -ErrorAction SilentlyContinue
    } finally {
        if (Get-Variable -Name oldErrorActionPreference -Scope Local -ErrorAction SilentlyContinue) {
            $ErrorActionPreference = $oldErrorActionPreference
        }
        Pop-Location
    }

    $summary = Parse-GcovSummary -SummaryPath (Join-Path $runDir "gcov-sqlite3-summary.txt")
    $functions = Parse-FunctionCoverage -FunctionsPath (Join-Path $runDir "gcov-sqlite3-functions.txt")
    $replayErrors = (Select-String -Path (Join-Path $runDir "sqlite-replay.err.log") `
            -Pattern 'Parse error|Runtime error|Error:' -CaseSensitive:$false -ErrorAction SilentlyContinue).Count
    $missingContextErrors = (Select-String -Path (Join-Path $runDir "sqlite-replay.err.log") `
            -Pattern 'no such table: egraph|no such index: egraph' -CaseSensitive:$false -ErrorAction SilentlyContinue).Count

    $report = New-Object System.Collections.Generic.List[string]
    $report.Add("SQLite code coverage result")
    $report.Add("===========================")
    $report.Add("")
    $report.Add("Run")
    $report.Add("- Result dir: $runDir")
    $report.Add("- SQLancer duration configured by this script: 3600 seconds")
    $report.Add("- SQLancer replay file: $replayFile")
    $report.Add("- SQLite replay exit code: $replayExit")
    $report.Add("- gcov exit code: $gcovExit")
    $report.Add("- gcov function exit code: $gcovFuncExit")
    $report.Add("- SQLite replay error count: $replayErrors")
    $report.Add("- Missing egraph context error count: $missingContextErrors")
    $report.Add("")
    $report.Add("SQLite code coverage (gcov / sqlite3.c)")
    $report.Add(("- Line coverage: {0:N2}% of {1}" -f $summary.LinePct, $summary.LineTotal))
    $report.Add(("- Branches executed: {0:N2}% of {1}" -f $summary.BranchExecPct, $summary.BranchTotal))
    $report.Add(("- Branches taken at least once: {0:N2}%" -f $summary.BranchTakenPct))
    $report.Add(("- Calls executed: {0:N2}% of {1}" -f $summary.CallsPct, $summary.CallsTotal))
    $report.Add(("- Functions executed: {0}/{1} = {2:N2}%" -f $functions.Covered, $functions.Total, $functions.Pct))
    $report.Add("")
    $report.Add("Notes")
    $report.Add("- This is real SQLite engine source coverage for sqlite3.c, not feature coverage.")
    $report.Add("- Missing egraph context errors should be 0; otherwise replay did not reproduce runtime context completely.")
    [System.IO.File]::WriteAllLines((Join-Path $runDir "sqlite-code-coverage-result.txt"), $report,
        [System.Text.UTF8Encoding]::new($true))

    Write-Host "Code coverage report: $runDir\sqlite-code-coverage-result.txt"
} else {
    Write-Host "Skipped code coverage replay because sqlite3_cov.exe/gcov/sqlite3.c was not found."
}
