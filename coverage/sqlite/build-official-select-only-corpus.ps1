param(
    [string] $InputFile = "D:\sqlancer\coverage\sqlite\sqlite-official-test-corpus.sql",
    [string] $OutputFile = "D:\sqlancer\coverage\sqlite\sqlite-official-select-only-corpus.sql",
    [string] $ReportFile = "D:\sqlancer\coverage\sqlite\sqlite-official-select-only-corpus.csv",
    [int] $MaxCases = 20000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Normalize-Sql {
    param([string] $Statement)
    return (($Statement.Trim() -replace '\s+', ' ').ToUpperInvariant())
}

function Read-SqlStatementsFromText {
    param([string] $Text)
    $result = New-Object System.Collections.Generic.List[string]
    $current = New-Object System.Text.StringBuilder
    $inSingle = $false
    $inDouble = $false
    $reader = New-Object System.IO.StringReader($Text)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            for ($i = 0; $i -lt $line.Length; $i++) {
                $ch = $line[$i]
                [void] $current.Append($ch)
                if ($ch -eq "'" -and -not $inDouble) {
                    if ($i + 1 -lt $line.Length -and $line[$i + 1] -eq "'") {
                        $i++
                        [void] $current.Append($line[$i])
                    } else {
                        $inSingle = -not $inSingle
                    }
                } elseif ($ch -eq '"' -and -not $inSingle) {
                    if ($i + 1 -lt $line.Length -and $line[$i + 1] -eq '"') {
                        $i++
                        [void] $current.Append($line[$i])
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
                    [void] $current.Clear()
                }
            }
            [void] $current.Append("`n")
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

function Add-ReasonCount {
    param(
        [hashtable] $Counts,
        [string] $Reason
    )
    if (-not $Counts.ContainsKey($Reason)) {
        $Counts[$Reason] = 0
    }
    $Counts[$Reason]++
}

function Find-TopLevelKeyword {
    param(
        [string] $Sql,
        [string] $Keyword,
        [int] $Start = 0
    )
    $depth = 0
    $inSingle = $false
    $inDouble = $false
    for ($i = $Start; $i -le $Sql.Length - $Keyword.Length; $i++) {
        $ch = $Sql[$i]
        if ($inSingle) {
            if ($ch -eq "'") {
                if ($i + 1 -lt $Sql.Length -and $Sql[$i + 1] -eq "'") {
                    $i++
                } else {
                    $inSingle = $false
                }
            }
            continue
        }
        if ($inDouble) {
            if ($ch -eq '"') {
                if ($i + 1 -lt $Sql.Length -and $Sql[$i + 1] -eq '"') {
                    $i++
                } else {
                    $inDouble = $false
                }
            }
            continue
        }
        if ($ch -eq "'") {
            $inSingle = $true
            continue
        }
        if ($ch -eq '"') {
            $inDouble = $true
            continue
        }
        if ($ch -eq '(') {
            $depth++
            continue
        }
        if ($ch -eq ')') {
            if ($depth -gt 0) {
                $depth--
            }
            continue
        }
        if ($depth -eq 0) {
            $candidate = $Sql.Substring($i, $Keyword.Length)
            if ($candidate.Equals($Keyword, [System.StringComparison]::OrdinalIgnoreCase)) {
                $beforeOk = $i -eq 0 -or (-not [char]::IsLetterOrDigit($Sql[$i - 1]) -and $Sql[$i - 1] -ne '_')
                $afterIndex = $i + $Keyword.Length
                $afterOk = $afterIndex -ge $Sql.Length -or (-not [char]::IsLetterOrDigit($Sql[$afterIndex]) -and $Sql[$afterIndex] -ne '_')
                if ($beforeOk -and $afterOk) {
                    return $i
                }
            }
        }
    }
    return -1
}

function Get-TopLevelFromClause {
    param([string] $Statement)
    $fromIdx = Find-TopLevelKeyword -Sql $Statement -Keyword "FROM"
    if ($fromIdx -lt 0) {
        return $null
    }
    $whereIdx = Find-TopLevelKeyword -Sql $Statement -Keyword "WHERE" -Start ($fromIdx + 4)
    if ($whereIdx -lt 0) {
        return $null
    }
    return $Statement.Substring($fromIdx + 4, $whereIdx - $fromIdx - 4).Trim()
}

function Get-QueryRejectReason {
    param([string] $Statement)
    $normalized = Normalize-Sql -Statement $Statement
    if (-not $normalized.StartsWith("SELECT ")) {
        return "not-select"
    }
    if (-not (" $normalized ").Contains(" WHERE ")) {
        return "no-where"
    }
    if ($normalized -match '\bSQLITE_(TEMP_)?(MASTER|SCHEMA|STAT1|STAT4)\b') {
        return "sqlite-internal-schema"
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
            return "unsupported-" + (($token.Trim() -replace '\s+', '-').ToLowerInvariant())
        }
    }
    if ($normalized.Contains(" FROM (")) {
        return "derived-from"
    }
    $fromClause = Get-TopLevelFromClause -Statement $Statement
    if ($null -eq $fromClause -or [string]::IsNullOrWhiteSpace($fromClause)) {
        return "no-top-level-from"
    }
    if ($fromClause.Contains(",") -or $fromClause.Contains("(") -or $fromClause.Contains(")")) {
        return "multi-or-complex-from"
    }
    $fromParts = @($fromClause -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($fromParts.Count -gt 3) {
        return "complex-from-alias"
    }
    if ($fromParts.Count -eq 3 -and -not $fromParts[1].Equals("AS", [System.StringComparison]::OrdinalIgnoreCase)) {
        return "complex-from-alias"
    }
    return $null
}

function Write-Case {
    param(
        [System.IO.StreamWriter] $Writer,
        [string] $SourceLine,
        [string] $Query
    )
    $Writer.WriteLine($SourceLine)
    $Writer.WriteLine("-- EGRAPH_CORPUS_SETUP_BEGIN")
    $Writer.WriteLine("-- EGRAPH_BASE_QUERY")
    $queryText = $Query.Trim()
    if (-not $queryText.EndsWith(";")) {
        $queryText += ";"
    }
    $Writer.WriteLine($queryText)
    $Writer.WriteLine("-- EGRAPH_CORPUS_CASE_END")
    $Writer.WriteLine()
}

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input corpus not found: $InputFile"
}

$outDir = Split-Path -Parent $OutputFile
if (-not [string]::IsNullOrWhiteSpace($outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$reasonCounts = @{}
$seenQueries = New-Object "System.Collections.Generic.HashSet[string]"
$totalCases = 0
$keptCases = 0
$sourceLine = "-- EGRAPH_CORPUS_CASE_BEGIN source=$InputFile mode=select-only"
$queryText = New-Object System.Text.StringBuilder
$inCase = $false
$inQuery = $false

$writer = [System.IO.StreamWriter]::new($OutputFile, $false, [System.Text.UTF8Encoding]::new($false))
try {
    $writer.WriteLine("-- SQLite official SELECT-only corpus for SQLancer EGRAPH")
    $writer.WriteLine("-- Source: $InputFile")
    $writer.WriteLine("-- Setup: stripped")
    $writer.WriteLine("-- Generated: $((Get-Date).ToString('o'))")
    $writer.WriteLine()

    foreach ($line in [System.IO.File]::ReadLines($InputFile)) {
        $trimmed = $line.Trim()
        if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_BEGIN")) {
            $inCase = $true
            $inQuery = $false
            $sourceLine = "$trimmed mode=select-only"
            [void] $queryText.Clear()
            continue
        }
        if (-not $inCase) {
            continue
        }
        if ($trimmed -eq "-- EGRAPH_BASE_QUERY") {
            $inQuery = $true
            continue
        }
        if ($trimmed -eq "-- EGRAPH_CORPUS_CASE_END") {
            $totalCases++
            foreach ($query in @(Read-SqlStatementsFromText -Text $queryText.ToString())) {
                $reason = Get-QueryRejectReason -Statement $query
                if ($null -ne $reason) {
                    Add-ReasonCount -Counts $reasonCounts -Reason "query-$reason"
                    continue
                }
                $key = ($query.Trim() -replace '\s+', ' ')
                if ($seenQueries.Contains($key)) {
                    Add-ReasonCount -Counts $reasonCounts -Reason "query-duplicate"
                    continue
                }
                [void] $seenQueries.Add($key)
                Write-Case -Writer $writer -SourceLine $sourceLine -Query $query
                $keptCases++
                if ($keptCases -ge $MaxCases) {
                    break
                }
            }
            $inCase = $false
            $inQuery = $false
            if ($keptCases -ge $MaxCases) {
                break
            }
            continue
        }
        if ($inQuery) {
            [void] $queryText.AppendLine($line)
        }
    }
} finally {
    $writer.Dispose()
}

$reportRows = New-Object System.Collections.Generic.List[object]
$reportRows.Add([pscustomobject]@{ Kind = "summary"; Reason = "total-cases"; Count = $totalCases }) | Out-Null
$reportRows.Add([pscustomobject]@{ Kind = "summary"; Reason = "kept-cases"; Count = $keptCases }) | Out-Null
foreach ($entry in ($reasonCounts.GetEnumerator() | Sort-Object Name)) {
    $reportRows.Add([pscustomobject]@{ Kind = "skip"; Reason = $entry.Key; Count = $entry.Value }) | Out-Null
}
$reportRows | Export-Csv -LiteralPath $ReportFile -NoTypeInformation -Encoding UTF8

Write-Host "SELECT-only official corpus written: $OutputFile"
Write-Host "Report: $ReportFile"
Write-Host "Total input cases: $totalCases"
Write-Host "Kept SELECT-only cases: $keptCases"
