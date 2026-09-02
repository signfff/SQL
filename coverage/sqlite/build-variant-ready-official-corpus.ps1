param(
    [string] $InputCorpus = "D:\sqlancer\coverage\sqlite\sqlite-official-egraph-filtered-corpus.sql",
    [string] $ProfileCsv = "D:\sqlancer\coverage\sqlite\egraph-acceptance-profile.csv",
    [string] $OutputCorpus = "D:\sqlancer\coverage\sqlite\sqlite-official-egraph-variant-ready-corpus.sql",
    [string] $OutputCasesCsv = "D:\sqlancer\coverage\sqlite\sqlite-official-egraph-variant-ready-cases.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $InputCorpus)) {
    throw "Input corpus not found: $InputCorpus"
}
if (-not (Test-Path -LiteralPath $ProfileCsv)) {
    throw "Acceptance profile CSV not found: $ProfileCsv"
}

$acceptedRows = @(Import-Csv -LiteralPath $ProfileCsv | Where-Object { $_.Status -eq "accepted" })
if ($acceptedRows.Count -eq 0) {
    throw "Acceptance profile has no accepted EGRAPH cases: $ProfileCsv"
}

$acceptedRows | Export-Csv -LiteralPath $OutputCasesCsv -NoTypeInformation -Encoding UTF8

$acceptedIndexes = New-Object "System.Collections.Generic.HashSet[int]"
foreach ($row in $acceptedRows) {
    [void] $acceptedIndexes.Add([int] $row.CaseIndex)
}

$outLines = New-Object "System.Collections.Generic.List[string]"
$outLines.Add("-- SQLite official EGRAPH corpus cases with at least one EGRAPH variant") | Out-Null
$outLines.Add("-- Source corpus: $InputCorpus") | Out-Null
$outLines.Add("-- Source profile: $ProfileCsv") | Out-Null
$outLines.Add("-- Accepted cases: $($acceptedRows.Count)") | Out-Null
$outLines.Add("-- Generated: $((Get-Date).ToString('o'))") | Out-Null
$outLines.Add("") | Out-Null

$caseIndex = 0
$copiedCases = 0
$inCase = $false
$caseLines = New-Object "System.Collections.Generic.List[string]"

foreach ($line in [System.IO.File]::ReadLines($InputCorpus)) {
    $trimmed = $line.Trim()
    if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_BEGIN")) {
        $caseIndex++
        $inCase = $true
        $caseLines.Clear()
        $caseLines.Add($line) | Out-Null
        continue
    }
    if (-not $inCase) {
        continue
    }
    $caseLines.Add($line) | Out-Null
    if ($trimmed -eq "-- EGRAPH_CORPUS_CASE_END") {
        if ($acceptedIndexes.Contains($caseIndex)) {
            foreach ($caseLine in $caseLines) {
                $outLines.Add($caseLine) | Out-Null
            }
            $outLines.Add("") | Out-Null
            $copiedCases++
        }
        $inCase = $false
    }
}

if ($copiedCases -ne $acceptedRows.Count) {
    throw "Variant-ready corpus copy mismatch: copied $copiedCases, expected $($acceptedRows.Count)."
}

$outDir = Split-Path -Parent $OutputCorpus
if (-not [string]::IsNullOrWhiteSpace($outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}
[System.IO.File]::WriteAllLines($OutputCorpus, $outLines, [System.Text.UTF8Encoding]::new($false))

Write-Host "Variant-ready official corpus written: $OutputCorpus"
Write-Host "Variant-ready case CSV written: $OutputCasesCsv"
Write-Host "Cases copied: $copiedCases"
