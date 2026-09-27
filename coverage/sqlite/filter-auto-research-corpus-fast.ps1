param(
    [string]$AutoReplay = "",

    [string]$OutputFile = "D:\sqlancer\coverage\sqlite\auto-research-filtered-corpus.sql",

    [int]$MaxSetup = 3000,

    [int]$MaxSelects = 5000,

    [int]$MaxPerScoreBucket = 2000,

    [int]$MaxCaseSetupStatements = 80,

    [int]$MaxCaseSetupChars = 12000,

    [int]$MaxCaseSetupStatementChars = 2000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "egraph-corpus-format.ps1")

$coverageRoot = "D:\sqlancer\coverage\sqlite"

function Resolve-LatestAutoReplay {
    # finish-long-codecov.ps1 writes its auto research into "<run dir>\auto-research", one level
    # below the directories this used to scan, so the freshest results - the ones measured on the
    # current build - were invisible here and a week-old directory kept winning on LastWriteTime.
    # Measured when it did: the rebuilt corpus came out with 5 cases instead of 5000.
    # start-long-codecov-capture.ps1 was fixed the same way; this is the same search.
    $candidateDirs = New-Object System.Collections.Generic.List[object]
    foreach ($dir in (Get-ChildItem -LiteralPath $coverageRoot -Directory)) {
        if ($dir.Name -like "auto-research-smoke-*") { continue }
        foreach ($relative in @("auto-research-results.csv", "auto-research\auto-research-results.csv")) {
            $resultsFile = Join-Path $dir.FullName $relative
            if (Test-Path -LiteralPath $resultsFile) {
                $candidateDirs.Add((Get-Item -LiteralPath (Split-Path -Parent $resultsFile)))
            }
        }
    }
    $latest = $candidateDirs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) {
        throw "No auto-research result directory found under $coverageRoot"
    }
    $baselineReplayRef = Join-Path $latest.FullName "baseline-replay-path.txt"
    if (Test-Path -LiteralPath $baselineReplayRef) {
        $baselineReplayPath = (Get-Content -LiteralPath $baselineReplayRef -Raw).Trim()
        if (-not [string]::IsNullOrWhiteSpace($baselineReplayPath) -and (Test-Path -LiteralPath $baselineReplayPath)) {
            return $baselineReplayPath
        }
    }
    $baselineReplay = Join-Path (Join-Path $latest.FullName "baseline") "replay.sql"
    if (Test-Path -LiteralPath $baselineReplay) {
        return $baselineReplay
    }
    $resultsPath = Join-Path $latest.FullName "auto-research-results.csv"
    $rows = Import-Csv -LiteralPath $resultsPath
    foreach ($row in $rows) {
        if ($row.Name -eq "baseline") {
            continue
        }
        $candidate = $null
        if ($row.PSObject.Properties.Name -contains "Dir" -and -not [string]::IsNullOrWhiteSpace($row.Dir)) {
            $candidate = Join-Path $row.Dir "replay.sql"
        } else {
            $candidate = Join-Path (Join-Path $latest.FullName $row.Name) "replay.sql"
        }
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    throw "No ranked auto-research replay.sql found in $resultsPath"
}

if ([string]::IsNullOrWhiteSpace($AutoReplay)) {
    $AutoReplay = Resolve-LatestAutoReplay
}

function Normalize-SqlLine {
    param([string]$Line)
    $line = $Line.Trim()
    if ($line.Length -eq 0 -or $line.StartsWith("--")) {
        return ""
    }
    $comment = $line.IndexOf("; --")
    if ($comment -ge 0) {
        $line = $line.Substring(0, $comment + 1)
    }
    if ($line.EndsWith(";")) {
        $line = $line.Substring(0, $line.Length - 1).Trim()
    }
    return $line
}

function Is-SetupStatement {
    param([string]$Statement)
    return $Statement -match '^(?i)(CREATE|INSERT|UPDATE|DELETE|DROP|ALTER|REINDEX|ANALYZE|PRAGMA|VACUUM|BEGIN|COMMIT|ROLLBACK)\b'
}

function Is-EGraphSelect {
    param([string]$Statement)
    $normalized = ($Statement -replace '\s+', ' ').ToUpperInvariant()
    if (-not $normalized.StartsWith("SELECT ")) {
        return $false
    }
    if (-not $normalized.Contains(" WHERE ")) {
        return $false
    }
    $unsupported = @(
        " WITH ", " MATCH ", " JOIN ", " GROUP BY ", " HAVING ", " WINDOW ", " OVER ",
        " UNION ", " INTERSECT ", " EXCEPT ", " VALUES ", " INDEXED BY ", " RETURNING ",
        " PRAGMA ", " CREATE ", " INSERT ", " UPDATE ", " DELETE ", " DROP ", " ALTER ",
        " REINDEX ", " ANALYZE ", " VACUUM ", " TRIGGER "
    )
    $padded = " $normalized "
    foreach ($token in $unsupported) {
        if ($padded.Contains($token)) {
            return $false
        }
    }
    return -not $normalized.Contains(" FROM (")
}

function Get-SelectScore {
    param([string]$Statement)
    $s = ($Statement -replace '\s+', ' ').ToUpperInvariant()
    $score = 0
    foreach ($token in @(" AND ", " OR ", " NOT ", " BETWEEN ", " IS NULL", " IS NOT NULL", " LIKE ", " GLOB ",
            " IN ", " EXISTS ", "CASE ", "CAST(", "TYPEOF(", "JSON_", "COLLATE")) {
        if ($s.Contains($token)) {
            $score += 4
        }
    }
    foreach ($op in @(">=", "<=", "<>", "!=", "=", ">", "<", "+", "-", "*", "/", "%")) {
        if ($s.Contains($op)) {
            $score += 1
        }
    }
    if ($s -match "X'[0-9A-F]+'") {
        $score += 5
    }
    if ($s -match "\b9223372036854775807\b|\b-9223372036854775808\b") {
        $score += 6
    }
    if ($s -match "\bSQLITE_(MASTER|SCHEMA)\b") {
        $score += 4
    }
    if ($s.Length -gt 180) {
        $score += 2
    }
    return $score
}

function Get-CaseScore {
    param(
        [string]$BaseQuery,
        [string]$CaseBlock
    )
    $score = Get-SelectScore -Statement $BaseQuery
    $s = ($CaseBlock -replace '\s+', ' ').ToUpperInvariant()
    foreach ($token in @(
            " EGRAPH_FTS", " FTS5", " MATCH ", " BM25(", " HIGHLIGHT(", " SNIPPET(",
            " RTREE", " RTREECHECK(", " DBSTAT", " WAL", " WAL_CHECKPOINT", " VACUUM",
            " FOREIGN_KEY", " FOREIGN KEY", " TRIGGER ", " VIEW ", " ALTER TABLE ",
            " DROP COLUMN", " RENAME COLUMN", " ANALYZE", " REINDEX", " RETURNING",
            " UPSERT", " ON CONFLICT", " JSONB", " JSON_TREE", " JSON_PRETTY",
            " WINDOW ", " OVER ", " FILTER ", " RIGHT JOIN ", " FULL OUTER JOIN ",
            " UNION ALL ", " ORDER BY ", " GROUP BY ", " MATERIALIZED ")) {
        if ($s.Contains($token)) {
            $score += 5
        }
    }
    return $score
}

function Read-EGraphCaseBlocks {
    param([string]$Path)

    # The delta expansion lives in egraph-corpus-format.ps1, dot-sourced above: this stage only says
    # which expanded cases it wants and what it wants to know about them.
    $seen = New-Object 'System.Collections.Generic.HashSet[string]'
    $expanded = Expand-EGraphCorpusCases -Path $Path -Accept {
        param($info)
        ($null -eq $info.Rows -or $info.Rows -gt 0) -and
            $info.SetupStatements -le $MaxCaseSetupStatements -and
            $info.SetupChars -le $MaxCaseSetupChars -and
            $info.LongestSetupStatement -le $MaxCaseSetupStatementChars -and
            (Is-EGraphSelect -Statement $info.BaseQuery) -and
            $seen.Add(($info.CaseText -replace "\s+", " "))
    }
    $result = New-Object System.Collections.Generic.List[object]
    foreach ($case in $expanded) {
        $result.Add([PSCustomObject]@{
            Score = Get-CaseScore -BaseQuery $case.BaseQuery -CaseBlock $case.CaseText
            Rows  = $case.Rows
            Query = $case.BaseQuery
            Block = $case.CaseText
        })
    }
    return $result
}

if (-not (Test-Path $AutoReplay)) {
    throw "Auto replay not found: $AutoReplay"
}

$caseCandidates = Read-EGraphCaseBlocks -Path $AutoReplay
if ($caseCandidates.Count -gt 0) {
    $selectedCases = $caseCandidates |
        Sort-Object -Property Score -Descending |
        Select-Object -First $MaxSelects

    $parent = Split-Path -Parent $OutputFile
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force $parent | Out-Null
    }

    $writer = New-Object System.IO.StreamWriter($OutputFile, $false, [System.Text.Encoding]::UTF8)
    try {
        $writer.WriteLine("-- Filtered auto-research EGRAPH corpus")
        $writer.WriteLine("-- Format: EGRAPH corpus-case blocks")
        $writer.WriteLine("-- Auto replay: $AutoReplay")
        $writer.WriteLine("-- Generated: $(Get-Date -Format o)")
        $writer.WriteLine("-- Case candidates: $($caseCandidates.Count)")
        $writer.WriteLine("-- Case selected: $($selectedCases.Count)")
        $writer.WriteLine("")
        foreach ($case in $selectedCases) {
            $writer.WriteLine($case.Block)
            $writer.WriteLine("")
        }
    } finally {
        $writer.Close()
    }

    $size = (Get-Item -LiteralPath $OutputFile).Length
    Write-Host "Filtered auto-research corpus written:"
    Write-Host $OutputFile
    Write-Host "Format: EGRAPH corpus-case blocks"
    Write-Host "Case candidates: $($caseCandidates.Count)"
    Write-Host "Case selected: $($selectedCases.Count)"
    Write-Host "Output bytes: $size"
    return
}

$setup = New-Object System.Collections.Generic.List[string]
$seenSetup = New-Object 'System.Collections.Generic.HashSet[string]'
$seenSelect = New-Object 'System.Collections.Generic.HashSet[string]'
$buckets = @{}
$linesRead = 0
$selectCandidates = 0

$reader = [System.IO.File]::OpenText($AutoReplay)
try {
    while ($null -ne ($line = $reader.ReadLine())) {
        $linesRead++
        $stmt = Normalize-SqlLine -Line $line
        if ($stmt.Length -eq 0) {
            continue
        }
        $normalized = ($stmt -replace '\s+', ' ')
        if (Is-SetupStatement -Statement $stmt) {
            if ($setup.Count -lt $MaxSetup -and $seenSetup.Add($normalized)) {
                $setup.Add($stmt)
            }
            continue
        }
        if (Is-EGraphSelect -Statement $stmt) {
            if (-not $seenSelect.Add($normalized)) {
                continue
            }
            $selectCandidates++
            $score = Get-SelectScore -Statement $stmt
            if (-not $buckets.ContainsKey($score)) {
                $buckets[$score] = New-Object System.Collections.Generic.List[string]
            }
            if ($buckets[$score].Count -lt $MaxPerScoreBucket) {
                $buckets[$score].Add($stmt)
            }
        }
    }
} finally {
    $reader.Close()
}

$selected = New-Object System.Collections.Generic.List[string]
foreach ($score in ($buckets.Keys | Sort-Object -Descending)) {
    foreach ($stmt in $buckets[$score]) {
        if ($selected.Count -ge $MaxSelects) {
            break
        }
        $selected.Add($stmt)
    }
    if ($selected.Count -ge $MaxSelects) {
        break
    }
}

$parent = Split-Path -Parent $OutputFile
if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Force $parent | Out-Null
}

$writer = New-Object System.IO.StreamWriter($OutputFile, $false, [System.Text.Encoding]::UTF8)
try {
    $writer.WriteLine("-- Filtered auto-research EGRAPH corpus")
    $writer.WriteLine("-- Auto replay: $AutoReplay")
    $writer.WriteLine("-- Generated: $(Get-Date -Format o)")
    $writer.WriteLine("-- Lines read: $linesRead")
    $writer.WriteLine("-- Setup selected: $($setup.Count)")
    $writer.WriteLine("-- SELECT candidates: $selectCandidates")
    $writer.WriteLine("-- SELECT selected: $($selected.Count)")
    $writer.WriteLine("")
    $writer.WriteLine("-- AUTO-RESEARCH SETUP SAMPLE -------------------------------------")
    foreach ($stmt in $setup) {
        $writer.WriteLine($stmt.TrimEnd(';') + ";")
    }
    $writer.WriteLine("")
    $writer.WriteLine("-- AUTO-RESEARCH HIGH-VALUE SELECT INPUTS --------------------------")
    foreach ($stmt in $selected) {
        $writer.WriteLine($stmt.TrimEnd(';') + ";")
    }
} finally {
    $writer.Close()
}

$size = (Get-Item -LiteralPath $OutputFile).Length
Write-Host "Filtered auto-research corpus written:"
Write-Host $OutputFile
Write-Host "Lines read: $linesRead"
Write-Host "Setup selected: $($setup.Count)"
Write-Host "SELECT candidates: $selectCandidates"
Write-Host "SELECT selected: $($selected.Count)"
Write-Host "Output bytes: $size"
