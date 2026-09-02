param(
    [string]$OfficialCorpus = "D:\sqlancer\coverage\sqlite\sqlite-official-test-corpus.sql",

    [string]$AutoReplay = "D:\sqlancer\coverage\sqlite\auto-research-from-long-20260818-130511\alter_index_analyze\replay.sql",

    [string]$OutputFile = "D:\sqlancer\coverage\sqlite\combined-egraph-corpus.sql",

    [switch]$FilterOnly,

    [int]$MaxAutoSetup = 5000,

    [int]$MaxAutoSelects = 5000,

    [int]$MaxOnlineCases = 0,

    [string]$OnlineReplayRoot = "D:\sqlancer\coverage\sqlite"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Remove-LineComment {
    param([string]$Line)
    $inSingle = $false
    $inDouble = $false
    for ($i = 0; $i -lt $Line.Length - 1; $i++) {
        $ch = $Line[$i]
        if ($ch -eq "'" -and -not $inDouble) {
            if ($i + 1 -lt $Line.Length -and $Line[$i + 1] -eq "'") {
                $i++
            } else {
                $inSingle = -not $inSingle
            }
        } elseif ($ch -eq '"' -and -not $inSingle) {
            if ($i + 1 -lt $Line.Length -and $Line[$i + 1] -eq '"') {
                $i++
            } else {
                $inDouble = -not $inDouble
            }
        } elseif ($ch -eq '-' -and $Line[$i + 1] -eq '-' -and -not $inSingle -and -not $inDouble) {
            return $Line.Substring(0, $i)
        }
    }
    return $Line
}

function Read-SqlStatements {
    param([string]$Path)

    $result = New-Object System.Collections.Generic.List[string]
    $current = New-Object System.Text.StringBuilder
    $inSingle = $false
    $inDouble = $false
    $reader = [System.IO.File]::OpenText($Path)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            $uncommented = Remove-LineComment -Line $line
            for ($i = 0; $i -lt $uncommented.Length; $i++) {
                $ch = $uncommented[$i]
                [void]$current.Append($ch)
                if ($ch -eq "'" -and -not $inDouble) {
                    if ($i + 1 -lt $uncommented.Length -and $uncommented[$i + 1] -eq "'") {
                        $i++
                        [void]$current.Append($uncommented[$i])
                    } else {
                        $inSingle = -not $inSingle
                    }
                } elseif ($ch -eq '"' -and -not $inSingle) {
                    if ($i + 1 -lt $uncommented.Length -and $uncommented[$i + 1] -eq '"') {
                        $i++
                        [void]$current.Append($uncommented[$i])
                    } else {
                        $inDouble = -not $inDouble
                    }
                } elseif ($ch -eq ';' -and -not $inSingle -and -not $inDouble) {
                    $stmt = $current.ToString().Trim()
                    if ($stmt.EndsWith(";")) {
                        $stmt = $stmt.Substring(0, $stmt.Length - 1).Trim()
                    }
                    if ($stmt.Length -gt 0) {
                        $result.Add($stmt)
                    }
                    [void]$current.Clear()
                }
            }
            [void]$current.Append("`n")
        }
        $tail = $current.ToString().Trim()
        if ($tail.Length -gt 0) {
            $result.Add($tail)
        }
    } finally {
        $reader.Close()
    }
    return $result
}

function Is-SetupStatement {
    param([string]$Statement)
    $s = $Statement.TrimStart()
    return $s -match '^(?i)(CREATE|INSERT|UPDATE|DELETE|DROP|ALTER|REINDEX|ANALYZE|PRAGMA|VACUUM|BEGIN|COMMIT|ROLLBACK)\b'
}

function Is-EGraphSelect {
    param([string]$Statement)
    $normalized = ($Statement.Trim() -replace '\s+', ' ').ToUpperInvariant()
    if (-not $normalized.StartsWith("SELECT ")) {
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
    $s = ($Statement.Trim() -replace '\s+', ' ').ToUpperInvariant()
    $score = 0
    foreach ($token in @(" AND ", " OR ", " NOT ", " BETWEEN ", " IS NULL", " IS NOT NULL", " LIKE ", " GLOB ",
            " IN ", " EXISTS ", "CASE ", "CAST(", "TYPEOF(", "JSON_", "COLLATE", "SELECT ")) {
        if ($s.Contains($token)) {
            $score += 3
        }
    }
    foreach ($op in @(">=", "<=", "<>", "!=", "=", ">", "<", "+", "-", "*", "/", "%")) {
        if ($s.Contains($op)) {
            $score += 1
        }
    }
    if ($s -match "X'[0-9A-F]+'") {
        $score += 4
    }
    if ($s -match "\b9223372036854775807\b|\b-9223372036854775808\b") {
        $score += 5
    }
    if ($s -match "\bSQLITE_(MASTER|SCHEMA)\b") {
        $score += 4
    }
    return $score
}

function Add-Unique {
    param(
        [System.Collections.Generic.List[string]]$Target,
        [System.Collections.Generic.HashSet[string]]$Seen,
        [string]$Statement,
        [int]$Limit
    )
    if ($Target.Count -ge $Limit) {
        return
    }
    $normalized = ($Statement.Trim() -replace '\s+', ' ')
    if ($Seen.Add($normalized)) {
        $Target.Add($Statement.Trim())
    }
}

function Read-OnlineCorpusCases {
    param(
        [string]$Root,
        [int]$Limit,
        [System.Collections.Generic.HashSet[string]]$SeenQueries
    )

    $result = New-Object System.Collections.Generic.List[string]
    if ($Limit -le 0 -or -not (Test-Path -LiteralPath $Root)) {
        return $result
    }

    $files = Get-ChildItem -LiteralPath $Root -Recurse -Filter "replay-all.sql" -File |
        Sort-Object LastWriteTime -Descending
    foreach ($file in $files) {
        if ($result.Count -ge $Limit) {
            break
        }
        $inCase = $false
        $inQuery = $false
        $rows = $null
        $block = New-Object System.Text.StringBuilder
        $query = New-Object System.Text.StringBuilder
        foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
            $trimmed = $line.Trim()
            if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_BEGIN")) {
                $inCase = $true
                $inQuery = $false
                $rows = $null
                [void]$block.Clear()
                [void]$query.Clear()
                if ($trimmed -match "rows=(-?\d+)") {
                    $rows = [int]$Matches[1]
                }
            }
            if ($inCase) {
                [void]$block.AppendLine($line)
                if ($inQuery -and -not $trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_END")) {
                    [void]$query.AppendLine($line)
                }
                if ($trimmed -eq "-- EGRAPH_BASE_QUERY") {
                    $inQuery = $true
                    continue
                }
                if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_END")) {
                    $caseQuery = ($query.ToString().Trim() -replace ";$", "").Trim()
                    $normalizedQuery = ($caseQuery -replace "\s+", " ")
                    if (($null -eq $rows -or $rows -gt 0) -and
                            (Is-EGraphSelect -Statement $caseQuery) -and
                            $SeenQueries.Add($normalizedQuery)) {
                        $result.Add($block.ToString().TrimEnd())
                    }
                    $inCase = $false
                    $inQuery = $false
                    if ($result.Count -ge $Limit) {
                        break
                    }
                }
            }
        }
    }
    return $result
}

if ($FilterOnly -and $OutputFile -eq "D:\sqlancer\coverage\sqlite\combined-egraph-corpus.sql") {
    $OutputFile = "D:\sqlancer\coverage\sqlite\auto-research-filtered-corpus.sql"
}

if (-not $FilterOnly -and -not (Test-Path $OfficialCorpus)) {
    throw "Official corpus not found: $OfficialCorpus"
}
if (-not (Test-Path $AutoReplay)) {
    throw "Auto replay not found: $AutoReplay"
}

if (-not $FilterOnly) {
    $officialText = Get-Content -LiteralPath $OfficialCorpus -Raw -Encoding UTF8
} else {
    $officialText = ""
}
$autoStatements = Read-SqlStatements -Path $AutoReplay

$autoSetup = New-Object System.Collections.Generic.List[string]
$autoSelectCandidates = New-Object System.Collections.Generic.List[object]
$seenSetup = New-Object 'System.Collections.Generic.HashSet[string]'
$seenSelect = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($stmt in $autoStatements) {
    if (Is-SetupStatement -Statement $stmt) {
        Add-Unique -Target $autoSetup -Seen $seenSetup -Statement $stmt -Limit $MaxAutoSetup
    } elseif (Is-EGraphSelect -Statement $stmt) {
        $normalized = ($stmt.Trim() -replace '\s+', ' ')
        if ($seenSelect.Add($normalized)) {
            $autoSelectCandidates.Add([PSCustomObject]@{
                Score = Get-SelectScore -Statement $stmt
                Sql   = $stmt.Trim()
            })
        }
    }
}

$autoSelects = $autoSelectCandidates |
    Sort-Object -Property Score -Descending |
    Select-Object -First $MaxAutoSelects |
    ForEach-Object { $_.Sql }

$onlineCases = New-Object System.Collections.Generic.List[string]
if (-not $FilterOnly) {
    $onlineCases = Read-OnlineCorpusCases -Root $OnlineReplayRoot -Limit $MaxOnlineCases -SeenQueries $seenSelect
}

$parent = Split-Path -Parent $OutputFile
if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Force $parent | Out-Null
}

$writer = New-Object System.IO.StreamWriter($OutputFile, $false, [System.Text.Encoding]::UTF8)
try {
    if ($FilterOnly) {
        $writer.WriteLine("-- Filtered auto-research EGRAPH corpus")
    } else {
        $writer.WriteLine("-- Combined EGRAPH corpus")
        $writer.WriteLine("-- Official corpus: $OfficialCorpus")
    }
    $writer.WriteLine("-- Auto replay: $AutoReplay")
    $writer.WriteLine("-- Generated: $(Get-Date -Format o)")
    $writer.WriteLine("-- Auto setup selected: $($autoSetup.Count)")
    $writer.WriteLine("-- Auto SELECT selected: $($autoSelects.Count)")
    if (-not $FilterOnly) {
        $writer.WriteLine("-- Online corpus cases selected: $($onlineCases.Count)")
    }
    $writer.WriteLine("")
    if (-not $FilterOnly) {
        $writer.WriteLine($officialText.TrimEnd())
        $writer.WriteLine("")
        if ($onlineCases.Count -gt 0) {
            $writer.WriteLine("-- ONLINE ACCUMULATED EGRAPH CASES --------------------------------")
            foreach ($caseBlock in $onlineCases) {
                $writer.WriteLine($caseBlock)
                $writer.WriteLine("")
            }
        }
    }
    $writer.WriteLine("-- AUTO-RESEARCH SETUP SAMPLE -------------------------------------")
    foreach ($stmt in $autoSetup) {
        $writer.WriteLine($stmt.TrimEnd(';') + ";")
    }
    $writer.WriteLine("")
    $writer.WriteLine("-- AUTO-RESEARCH HIGH-VALUE SELECT INPUTS --------------------------")
    foreach ($stmt in $autoSelects) {
        $writer.WriteLine($stmt.TrimEnd(';') + ";")
    }
} finally {
    $writer.Close()
}

$size = (Get-Item -LiteralPath $OutputFile).Length
Write-Host "Combined EGRAPH corpus written:"
Write-Host $OutputFile
if (-not $FilterOnly) {
    Write-Host "Official corpus bytes: $((Get-Item -LiteralPath $OfficialCorpus).Length)"
}
Write-Host "Auto setup selected: $($autoSetup.Count)"
Write-Host "Auto SELECT candidates: $($autoSelectCandidates.Count)"
Write-Host "Auto SELECT selected: $($autoSelects.Count)"
if (-not $FilterOnly) {
    Write-Host "Online corpus cases selected: $($onlineCases.Count)"
}
Write-Host "Output bytes: $size"
