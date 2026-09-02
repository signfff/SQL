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

$coverageRoot = "D:\sqlancer\coverage\sqlite"

function Resolve-LatestAutoReplay {
    $latest = Get-ChildItem -LiteralPath $coverageRoot -Directory |
        Where-Object {
            $_.Name -notlike "auto-research-smoke-*" -and
            (Test-Path -LiteralPath (Join-Path $_.FullName "auto-research-results.csv"))
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
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

    $result = New-Object System.Collections.Generic.List[object]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]'
    $block = New-Object System.Text.StringBuilder
    $baseQuery = New-Object System.Text.StringBuilder
    # replay-all.sql is delta encoded (full snapshot on keyframes, only the
    # changed statements in between). Accumulate them so every emitted corpus
    # case carries a setup that can be replayed on its own.
    $currentSetupLines = New-Object System.Collections.Generic.List[string]
    $accumulatedSetupLines = New-Object System.Collections.Generic.List[string]
    $inCase = $false
    $inSetup = $false
    $inBaseQuery = $false
    $rows = $null
    $setupStatements = 0
    $setupChars = 0
    $setupStatementTooLong = $false

    foreach ($line in [System.IO.File]::ReadLines($Path)) {
        $trimmed = $line.Trim()
        if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_BEGIN")) {
            $inCase = $true
            $inSetup = $false
            $inBaseQuery = $false
            $rows = $null
            $setupStatements = 0
            $setupChars = 0
            $setupStatementTooLong = $false
            [void]$block.Clear()
            [void]$baseQuery.Clear()
            if ($trimmed -match "rows=(-?\d+)") {
                $rows = [int]$Matches[1]
            }
            $line = $line.Replace(" setup=delta", " setup=full")
        }
        if (-not $inCase) {
            continue
        }

        if ($trimmed -eq "-- EGRAPH_CORPUS_SETUP_DELTA") {
            # Replay the accumulated snapshot first, then this case's delta.
            $inSetup = $true
            $inBaseQuery = $false
            $currentSetupLines.Clear()
            [void]$block.AppendLine("-- EGRAPH_CORPUS_SETUP_BEGIN")
            foreach ($setupLine in $accumulatedSetupLines) {
                $currentSetupLines.Add($setupLine)
                [void]$block.AppendLine($setupLine)
                $setupTrimmed = $setupLine.Trim()
                if ($setupTrimmed.Length -gt 0 -and -not $setupTrimmed.StartsWith("--")) {
                    $setupStatements++
                    $setupChars += $setupTrimmed.Length
                    if ($setupTrimmed.Length -gt $MaxCaseSetupStatementChars) {
                        $setupStatementTooLong = $true
                    }
                }
            }
            continue
        }

        [void]$block.AppendLine($line)

        if ($trimmed -eq "-- EGRAPH_CORPUS_SETUP_BEGIN") {
            $inSetup = $true
            $inBaseQuery = $false
            $currentSetupLines.Clear()
            continue
        }
        if ($trimmed -eq "-- EGRAPH_BASE_QUERY") {
            if ($inSetup) {
                $accumulatedSetupLines.Clear()
                $accumulatedSetupLines.AddRange($currentSetupLines)
            }
            $inSetup = $false
            $inBaseQuery = $true
            continue
        }
        if ($trimmed.StartsWith("-- EGRAPH_REPLAY_QUERY")) {
            $inBaseQuery = $false
            continue
        }
        if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_END")) {
            $query = ($baseQuery.ToString().Trim() -replace ";\s*$", "").Trim()
            $caseText = $block.ToString().TrimEnd()
            $dedupeKey = ($caseText -replace "\s+", " ")
            if (($null -eq $rows -or $rows -gt 0) -and
                    $setupStatements -le $MaxCaseSetupStatements -and
                    $setupChars -le $MaxCaseSetupChars -and
                    (-not $setupStatementTooLong) -and
                    (Is-EGraphSelect -Statement $query) -and
                    $seen.Add($dedupeKey)) {
                $result.Add([PSCustomObject]@{
                    Score = Get-CaseScore -BaseQuery $query -CaseBlock $caseText
                    Rows  = $rows
                    Query = $query
                    Block = $caseText
                })
            }
            $inCase = $false
            $inSetup = $false
            $inBaseQuery = $false
            continue
        }
        if ($inSetup -and $trimmed.Length -gt 0 -and -not $trimmed.StartsWith("--")) {
            $currentSetupLines.Add($line)
            $setupStatements++
            $setupChars += $trimmed.Length
            if ($trimmed.Length -gt $MaxCaseSetupStatementChars) {
                $setupStatementTooLong = $true
            }
            continue
        }
        if ($inBaseQuery -and -not $trimmed.StartsWith("--")) {
            [void]$baseQuery.AppendLine($line)
        }
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
