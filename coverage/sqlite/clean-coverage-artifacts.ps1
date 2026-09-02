<#
    Sweeps derived / invalidated coverage artifacts under coverage\sqlite.
    -Apply actually deletes; without it the script only reports.

    Kept on purpose: replay-all.sql captures, sqlite-code-coverage-result.txt
    reports, auto-research-results.csv, the corpora, build-backup-*, and
    sqlite3.c.gcov (input of the uncovered-code analysis).
#>
param([switch] $Apply)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = "D:\sqlancer\coverage\sqlite"
$targets = New-Object System.Collections.Generic.List[object]
$claimed = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

function Get-PathSize {
    param([string] $Path)

    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.PSIsContainer) {
        return [long] $item.Length
    }
    $files = @(Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue)
    if ($files.Count -eq 0) {
        return [long] 0
    }
    $measured = $files | Measure-Object -Property Length -Sum
    if ($null -eq $measured -or $null -eq $measured.Sum) {
        return [long] 0
    }
    return [long] $measured.Sum
}

function Add-Target {
    param([string] $Path, [string] $Reason)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }
    if (-not $claimed.Add($Path)) {
        return
    }
    $targets.Add([pscustomobject]@{ Path = $Path; Bytes = (Get-PathSize -Path $Path); Reason = $Reason })
}

# whole directories that were only ever A/B test scaffolding
foreach ($dir in @("expanded-smoke-20260831", "nodelta-smoke-20260831-043239")) {
    Add-Target -Path (Join-Path $root $dir) -Reason "A/B test scaffold (results recorded)"
}

$runDirs = @(Get-ChildItem -LiteralPath $root -Directory |
    Where-Object { $_.Name -notlike "build*" -and $_.Name -ne "sqlite-amalgamation-3490100" })

foreach ($runDir in $runDirs) {
    if ($claimed.Contains($runDir.FullName)) {
        continue
    }

    Add-Target -Path (Join-Path $runDir.FullName "replay-chunks") -Reason "regenerable from replay-all.sql"
    Add-Target -Path (Join-Path $runDir.FullName "replay.sql") -Reason "duplicate copy of the capture"
    Add-Target -Path (Join-Path $runDir.FullName "raw-replay.sql") -Reason "duplicate copy of the run log"
    Add-Target -Path (Join-Path $runDir.FullName "replay-context-wrapped.sql") -Reason "regenerable wrapper"
    Add-Target -Path (Join-Path $runDir.FullName "egraph-trace.log") -Reason "debug trace"
    # sqlite3.c.gcov is kept: analyze-uncovered-codecov.ps1 reads it to report
    # which code the run never reached. clean-old-coverage-runs.ps1 removes it
    # for superseded runs.

    foreach ($gcdaDir in @(Get-ChildItem -LiteralPath $runDir.FullName -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "gcda-*" })) {
        Add-Target -Path $gcdaDir.FullName -Reason "old-binary counters (invalid after rebuild)"
    }

    foreach ($db in @(Get-ChildItem -LiteralPath $runDir.FullName -Recurse -File -Filter "*.db" `
                -ErrorAction SilentlyContinue)) {
        Add-Target -Path $db.FullName -Reason "replay scratch database"
    }
}

if ($targets.Count -eq 0) {
    "Nothing to clean."
    return
}

$targets | Group-Object Reason | ForEach-Object {
    $sum = ($_.Group | Measure-Object -Property Bytes -Sum).Sum
    [pscustomobject]@{
        GB = [math]::Round($sum / 1GB, 2)
        Items = $_.Count
        Reason = $_.Name
    }
} | Sort-Object GB -Descending | Format-Table -AutoSize

$totalGb = [math]::Round((($targets | Measure-Object -Property Bytes -Sum).Sum) / 1GB, 2)
"TOTAL: {0} items, {1} GB" -f $targets.Count, $totalGb

if (-not $Apply) {
    ""
    "Dry run only. Re-run with -Apply to delete."
    return
}

$failed = 0
foreach ($target in $targets) {
    try {
        Remove-Item -LiteralPath $target.Path -Recurse -Force -ErrorAction Stop
    } catch {
        $failed++
        Write-Warning ("could not remove {0}: {1}" -f $target.Path, $_.Exception.Message)
    }
}
"Deleted {0} of {1} items ({2} failed)." -f ($targets.Count - $failed), $targets.Count, $failed
