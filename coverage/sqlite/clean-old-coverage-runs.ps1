<#
    Deletes the bulk artifacts of past coverage runs. Their value has already
    been extracted into auto-research-results.csv and the corpora, and the
    captures are in the pre-delta snapshot format replayed against the old
    instrumented binary, so they cannot be compared with new numbers anyway.

    Always kept, regardless of size: every .csv (auto-research results),
    the coverage reports, and the gcov summary / function listings.
#>
param([switch] $Apply)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = "D:\sqlancer\coverage\sqlite"
$keepNames = @(
    "sqlite-code-coverage-result.txt",
    "sqlite-code-coverage-result.OLDBINARY.txt",
    "gcov-sqlite3-summary.txt",
    "gcov-sqlite3-functions.txt",
    "workload-hints.txt",
    "java-args.txt",
    "auto-research-results.csv",
    "uncovered-code-report.txt",
    "uncovered-line-runs.txt"
)
$dirPatterns = @("manual-long-*", "manual-1h-*", "auto-research-from-long-*", "debug-*",
    "auto-research-smoke-*", "delta-smoke-*")

$targets = New-Object System.Collections.Generic.List[object]
foreach ($pattern in $dirPatterns) {
    foreach ($dir in @(Get-ChildItem -LiteralPath $root -Directory -Filter $pattern -ErrorAction SilentlyContinue)) {
        foreach ($file in @(Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -ErrorAction SilentlyContinue)) {
            if ($keepNames -contains $file.Name -or $file.Extension -eq ".csv") {
                continue
            }
            if ($file.Length -lt 512KB) {
                continue
            }
            $targets.Add([pscustomobject]@{
                    Path = $file.FullName
                    Bytes = $file.Length
                    Run = $dir.Name
                })
        }
    }
}

if ($targets.Count -eq 0) {
    "Nothing to clean."
    return
}

$targets | Group-Object Run | ForEach-Object {
    [pscustomobject]@{
        GB = [math]::Round((($_.Group | Measure-Object -Property Bytes -Sum).Sum) / 1GB, 2)
        Files = $_.Count
        Run = $_.Name
    }
} | Sort-Object GB -Descending | Select-Object -First 12 | Format-Table -AutoSize

$totalGb = [math]::Round((($targets | Measure-Object -Property Bytes -Sum).Sum) / 1GB, 2)
"TOTAL: {0} files, {1} GB across {2} run dirs" -f $targets.Count, $totalGb,
    (@($targets | Group-Object Run).Count)

if (-not $Apply) {
    ""
    "Dry run only. Re-run with -Apply to delete."
    return
}

$failed = 0
foreach ($target in $targets) {
    try {
        Remove-Item -LiteralPath $target.Path -Force -ErrorAction Stop
    } catch {
        $failed++
        Write-Warning ("could not remove {0}: {1}" -f $target.Path, $_.Exception.Message)
    }
}
"Deleted {0} of {1} files ({2} failed)." -f ($targets.Count - $failed), $targets.Count, $failed
