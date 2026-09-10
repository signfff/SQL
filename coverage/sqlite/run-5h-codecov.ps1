<#
.SYNOPSIS
    Unattended 5-hour EGRAPH capture followed by the coverage measurement.

.DESCRIPTION
    Runs the whole loop without needing Ctrl+C:
      1. makes sure the Rust egraph server is listening on :3000
      2. captures for -Hours hours (start-long-codecov-capture.ps1 -TimeoutSeconds)
      3. replays the capture against the instrumented SQLite and produces the
         coverage report plus the uncovered-code analysis (finish-long-codecov.ps1)

    Everything is logged to the run directory, so the console can be closed once
    the run has started.
#>
param(
    [double] $Hours = 5,
    [int] $ParallelWorkers = 4,
    [switch] $SkipServerStart,
    [switch] $SkipAutoResearch,
    # Passed straight through to start-long-codecov-capture.ps1, e.g.
    #   -ExtraJavaProps '-Degraph.indexedPredicatePercent=70','-Degraph.rtreeTargets=false'
    [string[]] $ExtraJavaProps = @(),
    # Suffix for the run directory, so an A/B pair is told apart at a glance
    [string] $RunTag = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = "D:\sqlancer"
$coverageRoot = Join-Path $root "coverage\sqlite"
$startScript = Join-Path $coverageRoot "start-long-codecov-capture.ps1"
$finishScript = Join-Path $coverageRoot "finish-long-codecov.ps1"
$autoResearchScript = Join-Path $coverageRoot "auto-research-codecov.ps1"
$serverExe = Join-Path $root "egraph-server\target\release\egraph-server.exe"
$timeoutSeconds = [int] [math]::Round($Hours * 3600)

foreach ($path in @($startScript, $finishScript, $autoResearchScript, (Join-Path $coverageRoot "build\sqlite3_cov.exe"))) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing prerequisite: $path"
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $root "target\sqlancer-2.0.0.jar"))) {
    throw "Missing target\sqlancer-2.0.0.jar - build with: mvn -q package -DskipTests"
}

function Test-EGraphServer {
    try {
        Invoke-WebRequest -Uri "http://127.0.0.1:3000/" -TimeoutSec 3 -UseBasicParsing | Out-Null
        return $true
    } catch [System.Net.WebException] {
        # A 404 still proves something is listening on the port.
        return $null -ne $_.Exception.Response
    } catch {
        return $false
    }
}

if (-not (Test-EGraphServer)) {
    if ($SkipServerStart) {
        throw "The egraph server is not answering on :3000 and -SkipServerStart was given."
    }
    if (-not (Test-Path -LiteralPath $serverExe)) {
        throw "The egraph server is not running and $serverExe does not exist."
    }
    Write-Host "Starting the egraph server..."
    Start-Process -FilePath $serverExe -WorkingDirectory (Split-Path -Parent $serverExe) -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $root "egraph-server.out.log") `
        -RedirectStandardError (Join-Path $root "egraph-server.err.log") | Out-Null
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Seconds 1
        if (Test-EGraphServer) {
            break
        }
    }
    if (-not (Test-EGraphServer)) {
        throw "The egraph server did not come up on :3000."
    }
}
Write-Host "egraph server: up"

$overallStart = Get-Date
Write-Host ("=== Phase 1/3: capture for {0:N1} h, started {1:HH:mm:ss} ===" -f $Hours, $overallStart)
# Called directly rather than through powershell.exe -File so that -ExtraJavaProps stays an
# array: passed on a command line its elements would bind positionally instead.
$startParams = @{ TimeoutSeconds = $timeoutSeconds }
if ($ExtraJavaProps.Count -gt 0) {
    $startParams["ExtraJavaProps"] = $ExtraJavaProps
}
if (-not [string]::IsNullOrWhiteSpace($RunTag)) {
    $startParams["RunTag"] = $RunTag
}
& $startScript @startParams
$captureEnd = Get-Date
Write-Host ("Capture finished after {0:N2} h" -f ($captureEnd - $overallStart).TotalHours)

$runDir = (Get-Content -LiteralPath (Join-Path $coverageRoot "last-long-codecov-run.txt") -TotalCount 1).Trim()
Write-Host "Run dir: $runDir"
$replayFile = Join-Path $runDir "replay-all.sql"
if (Test-Path -LiteralPath $replayFile) {
    Write-Host ("Capture size: {0:N2} GB" -f ((Get-Item -LiteralPath $replayFile).Length / 1GB))
} else {
    Write-Warning "No replay-all.sql in the run dir; the coverage phase will have nothing to replay."
}

Write-Host ("=== Phase 2/3: coverage measurement, started {0:HH:mm:ss} ===" -f (Get-Date))
& powershell -ExecutionPolicy Bypass -File $finishScript -RunDir $runDir -ParallelWorkers $ParallelWorkers
$coverageEnd = Get-Date

# Phase 3: rank candidate workloads by their coverage delta so the ranking can steer the next
# round's wrapper shapes. Non-fatal on purpose - a four-hour capture plus a completed coverage
# measurement must not be thrown away because the research phase tripped over a missing baseline.
$autoResearchStatus = "skipped"
if (-not $SkipAutoResearch) {
    Write-Host ("=== Phase 3/3: auto-research, started {0:HH:mm:ss} ===" -f (Get-Date))
    $autoResearchOut = Join-Path $runDir "auto-research"
    try {
        & powershell -ExecutionPolicy Bypass -File $autoResearchScript -BaseReplay $replayFile -OutputRoot $autoResearchOut
        if ($LASTEXITCODE -ne 0) {
            throw "auto-research-codecov.ps1 exited with $LASTEXITCODE"
        }
        $autoResearchStatus = "ok: $autoResearchOut"
    } catch {
        $autoResearchStatus = "FAILED: $($_.Exception.Message)"
        Write-Warning "Auto-research phase failed, capture and coverage results are unaffected: $($_.Exception.Message)"
    }
}
$done = Get-Date

Write-Host ""
Write-Host ("=== Done. Capture {0:N2} h, coverage {1:N2} h, auto-research {2:N2} h, total {3:N2} h ===" -f `
        ($captureEnd - $overallStart).TotalHours, ($coverageEnd - $captureEnd).TotalHours,
        ($done - $coverageEnd).TotalHours, ($done - $overallStart).TotalHours)
Write-Host "Auto-research:      $autoResearchStatus" 
$report = Join-Path $runDir "sqlite-code-coverage-result.txt"
if (Test-Path -LiteralPath $report) {
    Write-Host ""
    Get-Content -LiteralPath $report | Select-String -Pattern "Line coverage|Branches|Calls executed|Functions executed|delta-encoded|chunks failed"
    Write-Host ""
    Write-Host "Full report:        $report"
    Write-Host "Uncovered analysis: $(Join-Path $runDir 'uncovered-code-report.txt')"
    Write-Host "Workload hints:     $(Join-Path $runDir 'workload-hints.txt')"
}
