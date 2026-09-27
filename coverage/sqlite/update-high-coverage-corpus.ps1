param(
    [string] $RunDir = "",

    [string] $OutputFile = "D:\sqlancer\coverage\sqlite\high-coverage-egraph-corpus.sql",

    [string] $ManifestFile = "D:\sqlancer\coverage\sqlite\high-coverage-egraph-corpus.csv",

    [int] $MaxCases = 500,

    [double] $NearBestLineCoverageDelta = 0.25,

    [switch] $AlwaysAppend
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "egraph-corpus-format.ps1")

Set-Location "D:\sqlancer"

if ([string]::IsNullOrWhiteSpace($RunDir)) {
    $lastRunFile = "D:\sqlancer\coverage\sqlite\last-long-codecov-run.txt"
    if (-not (Test-Path -LiteralPath $lastRunFile)) {
        throw "RunDir was not provided and $lastRunFile does not exist."
    }
    $RunDir = (Get-Content -LiteralPath $lastRunFile -TotalCount 1).Trim()
}

$resolvedRunDir = (Resolve-Path -LiteralPath $RunDir).Path
$coverageRoot = "D:\sqlancer\coverage\sqlite"
$resolvedCoverageRoot = (Resolve-Path -LiteralPath $coverageRoot).Path
if (-not $resolvedRunDir.StartsWith($resolvedCoverageRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Unexpected run dir outside coverage root: $resolvedRunDir"
}

$coverageReport = Join-Path $resolvedRunDir "sqlite-code-coverage-result.txt"
$replayAll = Join-Path $resolvedRunDir "replay-all.sql"
if (-not (Test-Path -LiteralPath $coverageReport)) {
    throw "Missing coverage report: $coverageReport. Run finish-long-codecov.ps1 first."
}
if (-not (Test-Path -LiteralPath $replayAll)) {
    throw "Missing replay-all.sql: $replayAll"
}

function Read-LineCoverage {
    param([string] $Path)
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match 'Line coverage:\s+([0-9.]+)%') {
            return [double] $matches[1]
        }
    }
    return 0.0
}

function Get-InstrumentedBuildId {
    <#
        Coverage percentages are only comparable within one instrumented build:
        rebuilding sqlite3_cov.exe with different feature flags changes the
        number of executable lines, so the same workload reports a different
        percentage. The notes file size and timestamp identify the build.
    #>
    param([string] $BuildDir = "D:\sqlancer\coverage\sqlite\build")

    $notes = Join-Path $BuildDir "sqlite3.gcno"
    if (-not (Test-Path -LiteralPath $notes)) {
        return "unknown"
    }
    $item = Get-Item -LiteralPath $notes
    return "{0}-{1:yyyyMMddHHmmss}" -f $item.Length, $item.LastWriteTimeUtc
}

function Read-BestLineCoverage {
    <#
        Returns the best coverage recorded for the current instrumented build.
        Rows from other builds are ignored: comparing across builds would either
        block every append after a rebuild that added code (a lower percentage
        over a larger denominator) or wave everything through after one that
        removed code.
    #>
    param(
        [string] $Path,
        [string] $BuildId
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        return 0.0
    }
    $best = 0.0
    foreach ($row in Import-Csv -LiteralPath $Path) {
        $rowBuildId = if ($row.PSObject.Properties.Name -contains "InstrumentedBuildId") {
            $row.InstrumentedBuildId
        } else {
            $null
        }
        if ($rowBuildId -ne $BuildId) {
            continue
        }
        if ($row.LineCoverage -and [double] $row.LineCoverage -gt $best) {
            $best = [double] $row.LineCoverage
        }
    }
    return $best
}

function Read-ExistingQueries {
    param([string] $Path)
    $queries = New-Object 'System.Collections.Generic.HashSet[string]'
    if (-not (Test-Path -LiteralPath $Path)) {
        return ,$queries
    }
    $inQuery = $false
    $query = New-Object System.Text.StringBuilder
    foreach ($line in [System.IO.File]::ReadLines($Path)) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "-- EGRAPH_BASE_QUERY") {
            $inQuery = $true
            [void] $query.Clear()
            continue
        }
        if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_END")) {
            if ($query.Length -gt 0) {
                [void] $queries.Add((($query.ToString().Trim() -replace ";$", "").Trim() -replace "\s+", " "))
            }
            $inQuery = $false
            continue
        }
        if ($inQuery) {
            [void] $query.AppendLine($line)
        }
    }
    return ,$queries
}

function Select-NonEmptyCases {
    param(
        [string] $Path,
        [int] $Limit,
        [System.Collections.Generic.HashSet[string]] $SeenQueries
    )
    # The delta expansion lives in egraph-corpus-format.ps1, dot-sourced above: this stage only says
    # which expanded cases it wants.
    $expanded = Expand-EGraphCorpusCases -Path $Path -Limit $Limit -Accept {
        param($info)
        ($null -ne $info.Rows -and $info.Rows -gt 0) -and $info.QueryBlockText.Length -gt 0 `
                -and $SeenQueries.Add($info.QueryBlockText)
    }
    $cases = New-Object System.Collections.Generic.List[string]
    foreach ($case in $expanded) {
        $cases.Add($case.CaseText)
    }
    return $cases
}

$lineCoverage = Read-LineCoverage -Path $coverageReport
$instrumentedBuildId = Get-InstrumentedBuildId
$bestLineCoverage = Read-BestLineCoverage -Path $ManifestFile -BuildId $instrumentedBuildId
$shouldAppend = $AlwaysAppend -or $bestLineCoverage -eq 0.0 -or
        $lineCoverage -ge ($bestLineCoverage - $NearBestLineCoverageDelta)

if (-not $shouldAppend) {
    Write-Host ("Coverage {0:N2}% is below current high-coverage window for build ${instrumentedBuildId}; best {1:N2}%, delta {2:N2}." -f `
            $lineCoverage, $bestLineCoverage, $NearBestLineCoverageDelta)
    return
}

$parent = Split-Path -Parent $OutputFile
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
}

$seenQueries = Read-ExistingQueries -Path $OutputFile
$selectedCases = @(Select-NonEmptyCases -Path $replayAll -Limit $MaxCases -SeenQueries $seenQueries)

if ($selectedCases.Count -eq 0) {
    Write-Host "No new non-empty EGRAPH cases to append."
    return
}

$writer = New-Object System.IO.StreamWriter($OutputFile, $true, [System.Text.UTF8Encoding]::new($false))
try {
    if ((Get-Item -LiteralPath $OutputFile -ErrorAction SilentlyContinue).Length -eq 0) {
        $writer.WriteLine("-- High-coverage EGRAPH corpus accumulated from future runs")
        $writer.WriteLine("-- Only non-empty replay blocks that reached at least one EGRAPH variant are appended.")
        $writer.WriteLine("")
    }
    $writer.WriteLine("-- HIGH_COVERAGE_RUN_BEGIN run=$resolvedRunDir line_coverage=$lineCoverage generated=$(Get-Date -Format o)")
    foreach ($caseBlock in $selectedCases) {
        $writer.WriteLine($caseBlock)
        $writer.WriteLine("")
    }
    $writer.WriteLine("-- HIGH_COVERAGE_RUN_END")
    $writer.WriteLine("")
} finally {
    $writer.Close()
}

$manifestParent = Split-Path -Parent $ManifestFile
if ($manifestParent -and -not (Test-Path -LiteralPath $manifestParent)) {
    New-Item -ItemType Directory -Force -Path $manifestParent | Out-Null
}
$manifestExists = Test-Path -LiteralPath $ManifestFile
$row = [pscustomobject]@{
    Timestamp = Get-Date -Format o
    RunDir = $resolvedRunDir
    InstrumentedBuildId = $instrumentedBuildId
    LineCoverage = $lineCoverage
    PreviousBestLineCoverage = $bestLineCoverage
    CasesAppended = $selectedCases.Count
    OutputFile = $OutputFile
}
if ($manifestExists) {
    $row | Export-Csv -LiteralPath $ManifestFile -Append -NoTypeInformation -Encoding UTF8
} else {
    $row | Export-Csv -LiteralPath $ManifestFile -NoTypeInformation -Encoding UTF8
}

Write-Host "High-coverage corpus updated:"
Write-Host $OutputFile
Write-Host ("Line coverage: {0:N2}% (previous best {1:N2}% for build {2})" -f `
        $lineCoverage, $bestLineCoverage, $instrumentedBuildId)
Write-Host "Cases appended: $($selectedCases.Count)"
