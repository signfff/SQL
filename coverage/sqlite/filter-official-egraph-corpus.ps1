param(
    [string] $InputFile = "D:\sqlancer\coverage\sqlite\sqlite-official-test-corpus.sql",

    [string] $OutputFile = "D:\sqlancer\coverage\sqlite\sqlite-official-egraph-filtered-corpus.sql",

    [string] $ReportFile = "D:\sqlancer\coverage\sqlite\sqlite-official-egraph-filtered-corpus.csv",

    [string] $DetailReportFile = "D:\sqlancer\coverage\sqlite\sqlite-official-egraph-filtered-corpus-detail.csv",

    [string] $RejectedOutputFile = "D:\sqlancer\coverage\sqlite\sqlite-official-egraph-rejected-corpus.sql",

    [int] $MaxCases = 20000,

    # These three must be the limits SQLite3EGraphInputCorpus applies, or this stage throws away cases
    # the reader would have loaded. They were 40 / 8000 / 1200 with nothing saying why: measured on the
    # 5000-case official corpus, that refused 943 cases (18.9%) that the reader accepts.
    # Java: sqlite3.egraph.input.maxCaseSetupStatements / maxCaseSetupChars / maxCaseSetupStatementChars.
    [int] $MaxCaseSetupStatements = 80,

    [int] $MaxCaseSetupChars = 12000,

    [int] $MaxCaseSetupStatementChars = 2000,

    [string] $SqliteExe = "D:\sqlancer\coverage\sqlite\build\sqlite3_cov.exe",

    [int] $ValidationTimeoutMillis = 3000,

    [int] $ValidationBusyTimeoutMillis = 1000,

    [switch] $SkipValidation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$script:LastValidationDetail = ""

function Remove-LineComment {
    param([string] $Line)
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

function Read-SqlStatementsFromText {
    param([string] $Text)
    $result = New-Object System.Collections.Generic.List[string]
    $current = New-Object System.Text.StringBuilder
    $inSingle = $false
    $inDouble = $false
    $reader = New-Object System.IO.StringReader($Text)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            $uncommented = Remove-LineComment -Line $line
            for ($i = 0; $i -lt $uncommented.Length; $i++) {
                $ch = $uncommented[$i]
                [void] $current.Append($ch)
                if ($ch -eq "'" -and -not $inDouble) {
                    if ($i + 1 -lt $uncommented.Length -and $uncommented[$i + 1] -eq "'") {
                        $i++
                        [void] $current.Append($uncommented[$i])
                    } else {
                        $inSingle = -not $inSingle
                    }
                } elseif ($ch -eq '"' -and -not $inSingle) {
                    if ($i + 1 -lt $uncommented.Length -and $uncommented[$i + 1] -eq '"') {
                        $i++
                        [void] $current.Append($uncommented[$i])
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

function Normalize-Sql {
    param([string] $Statement)
    return (($Statement.Trim() -replace '\s+', ' ').ToUpperInvariant())
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
    return $null
}

function Get-SetupRejectReason {
    param([System.Collections.Generic.List[string]] $Statements)
    if ($Statements.Count -gt $MaxCaseSetupStatements) {
        return "too-many-statements"
    }
    $totalChars = 0
    foreach ($stmt in $Statements) {
        $totalChars += $stmt.Length
        if ($totalChars -gt $MaxCaseSetupChars) {
            return "too-many-chars"
        }
        if ($stmt.Length -gt $MaxCaseSetupStatementChars) {
            return "statement-too-long"
        }
        $normalized = Normalize-Sql -Statement $stmt
        if ($normalized.Contains("SQLITE_MASTER") -or $normalized.Contains("SQLITE_SCHEMA") `
                -or $normalized.Contains("SQLITE_TEMP_MASTER") -or $normalized.Contains("SQLITE_TEMP_SCHEMA")) {
            return "sqlite-schema"
        }
        if ($normalized.Contains("SQLITE_STAT1") -or $normalized.Contains("SQLITE_STAT4")) {
            return "sqlite-stat"
        }
        if ($normalized -match '^PRAGMA\s+(WRITABLE_SCHEMA|PAGE_SIZE|MAX_PAGE_COUNT|JOURNAL_MODE|LOCKING_MODE|INCREMENTAL_VACUUM|AUTO_VACUUM|SYNCHRONOUS|INTEGRITY_CHECK|QUICK_CHECK)\b.*') {
            return "unsafe-pragma"
        }
        if ($normalized -match '^(VACUUM|ATTACH|DETACH|BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)\b.*') {
            return "transaction-or-vacuum"
        }
        if ($normalized.Contains("WITH RECURSIVE") -or $normalized.Contains("RANDOMBLOB(")) {
            return "expensive-expression"
        }
        if ($normalized -match '^INSERT\b.*\bSELECT\b.*') {
            return "insert-select"
        }
    }
    return $null
}

function Write-Case {
    param(
        [System.IO.StreamWriter] $Writer,
        [string] $SourceLine,
        [System.Collections.Generic.List[string]] $SetupStatements,
        [string] $Query
    )
    $Writer.WriteLine($SourceLine)
    $Writer.WriteLine("-- EGRAPH_CORPUS_SETUP_BEGIN")
    foreach ($stmt in $SetupStatements) {
        $trimmed = $stmt.Trim()
        if (-not $trimmed.EndsWith(";")) {
            $trimmed += ";"
        }
        $Writer.WriteLine($trimmed)
    }
    $Writer.WriteLine("-- EGRAPH_BASE_QUERY")
    $queryText = $Query.Trim()
    if (-not $queryText.EndsWith(";")) {
        $queryText += ";"
    }
    $Writer.WriteLine($queryText)
    $Writer.WriteLine("-- EGRAPH_CORPUS_CASE_END")
    $Writer.WriteLine()
}

function Write-RejectedCase {
    param(
        [System.IO.StreamWriter] $Writer,
        [string] $SourceLine,
        [System.Collections.Generic.List[string]] $SetupStatements,
        [string] $Query,
        [string] $Reason,
        [string] $Detail
    )
    $Writer.WriteLine("-- EGRAPH_REJECTED_CASE_BEGIN")
    $Writer.WriteLine("-- source_line: $SourceLine")
    $Writer.WriteLine("-- reason: $Reason")
    if (-not [string]::IsNullOrWhiteSpace($Detail)) {
        $Writer.WriteLine("-- detail: $(Convert-ToOneLine -Text $Detail -MaxLength 500)")
    }
    $Writer.WriteLine("-- EGRAPH_CORPUS_SETUP_BEGIN")
    foreach ($stmt in $SetupStatements) {
        $Writer.WriteLine((Join-SqlStatement -Statement $stmt))
    }
    $Writer.WriteLine("-- EGRAPH_BASE_QUERY")
    if (-not [string]::IsNullOrWhiteSpace($Query)) {
        $Writer.WriteLine((Join-SqlStatement -Statement $Query))
    }
    $Writer.WriteLine("-- EGRAPH_REJECTED_CASE_END")
    $Writer.WriteLine()
}

function Join-SqlStatement {
    param([string] $Statement)
    $trimmed = $Statement.Trim()
    if (-not $trimmed.EndsWith(";")) {
        $trimmed += ";"
    }
    return $trimmed
}

function Convert-ToOneLine {
    param(
        [string] $Text,
        [int] $MaxLength = 1000
    )
    if ($null -eq $Text) {
        return ""
    }
    $normalized = ($Text.Trim() -replace '\s+', ' ')
    if ($normalized.Length -gt $MaxLength) {
        return $normalized.Substring(0, $MaxLength - 3) + "..."
    }
    return $normalized
}

function Get-SourceFromLine {
    param([string] $SourceLine)
    if ($SourceLine -match 'source=(.+)$') {
        return $matches[1].Trim()
    }
    return $SourceLine
}

function Add-DetailRow {
    param(
        [System.Collections.Generic.List[object]] $Rows,
        [int] $CaseIndex,
        [string] $SourceLine,
        [string] $Status,
        [string] $Reason,
        [System.Collections.Generic.List[string]] $SetupStatements,
        [string] $Query,
        [string] $Detail
    )
    $Rows.Add([pscustomobject]@{
        CaseIndex = $CaseIndex
        Source = Get-SourceFromLine -SourceLine $SourceLine
        Status = $Status
        Reason = $Reason
        SetupStatements = if ($null -eq $SetupStatements) { 0 } else { $SetupStatements.Count }
        Query = Convert-ToOneLine -Text $Query -MaxLength 1200
        Detail = Convert-ToOneLine -Text $Detail -MaxLength 1200
    })
}

function Test-EGraphCaseCandidate {
    param(
        [System.Collections.Generic.List[string]] $SetupStatements,
        [string] $Query,
        [int] $CaseIndex
    )
    if ($SkipValidation) {
        $script:LastValidationDetail = "validation skipped"
        return $null
    }
    if (-not (Test-Path -LiteralPath $SqliteExe)) {
        $script:LastValidationDetail = "missing sqlite executable: $SqliteExe"
        return "validation-sqlite-missing"
    }

    $validationDir = Join-Path (Split-Path -Parent $OutputFile) "tmp-official-filter-validation"
    if (-not (Test-Path -LiteralPath $validationDir)) {
        New-Item -ItemType Directory -Force -Path $validationDir | Out-Null
    }
    $sqlPath = Join-Path $validationDir "candidate.sql"
    $outPath = Join-Path $validationDir "candidate.out"
    $errPath = Join-Path $validationDir "candidate.err"

    $queryText = $Query.Trim()
    while ($queryText.EndsWith(";")) {
        $queryText = $queryText.Substring(0, $queryText.Length - 1).Trim()
    }

    $builder = New-Object System.Text.StringBuilder
    [void] $builder.AppendLine(".bail on")
    [void] $builder.AppendLine(".mode list")
    [void] $builder.AppendLine(".headers off")
    [void] $builder.AppendLine(".timeout $ValidationBusyTimeoutMillis")
    foreach ($stmt in $SetupStatements) {
        [void] $builder.AppendLine((Join-SqlStatement -Statement $stmt))
    }
    [void] $builder.AppendLine("SELECT 1 FROM ($queryText) AS egraph_non_empty_probe LIMIT 1;")
    [System.IO.File]::WriteAllText($sqlPath, $builder.ToString(), [System.Text.UTF8Encoding]::new($false))
    if (Test-Path -LiteralPath $outPath) {
        Remove-Item -LiteralPath $outPath -Force
    }
    if (Test-Path -LiteralPath $errPath) {
        Remove-Item -LiteralPath $errPath -Force
    }

    $process = Start-Process -FilePath $SqliteExe -ArgumentList @(":memory:") `
        -RedirectStandardInput $sqlPath `
        -RedirectStandardOutput $outPath `
        -RedirectStandardError $errPath `
        -WindowStyle Hidden `
        -PassThru
    if (-not $process.WaitForExit($ValidationTimeoutMillis)) {
        try {
            $process.Kill()
        } catch {
        }
        $script:LastValidationDetail = "timeout after $ValidationTimeoutMillis ms"
        return "validation-timeout"
    }
    $stderr = if (Test-Path -LiteralPath $errPath) { Get-Content -LiteralPath $errPath -Raw } else { "" }
    $exitCode = $null
    try {
        $exitCode = $process.ExitCode
    } catch {
        $exitCode = $null
    }
    if (($null -ne $exitCode -and $exitCode -ne 0) -or -not [string]::IsNullOrWhiteSpace($stderr)) {
        $script:LastValidationDetail = if (-not [string]::IsNullOrWhiteSpace($stderr)) {
            $stderr
        } else {
            "sqlite exit code $exitCode"
        }
        return "validation-sql-error"
    }
    $stdout = if (Test-Path -LiteralPath $outPath) { Get-Content -LiteralPath $outPath -Raw } else { "" }
    if ([string]::IsNullOrWhiteSpace($stdout)) {
        $script:LastValidationDetail = "non-empty probe returned no rows"
        return "validation-empty"
    }
    $script:LastValidationDetail = ""
    return $null
}

function Add-ReasonCount {
    param(
        [hashtable] $Counts,
        [string] $Reason
    )
    if ($Counts.ContainsKey($Reason)) {
        $Counts[$Reason] = [int] $Counts[$Reason] + 1
    } else {
        $Counts[$Reason] = 1
    }
}

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input corpus not found: $InputFile"
}

$parent = Split-Path -Parent $OutputFile
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
}

$reportParent = Split-Path -Parent $ReportFile
if ($reportParent -and -not (Test-Path -LiteralPath $reportParent)) {
    New-Item -ItemType Directory -Force -Path $reportParent | Out-Null
}

$detailParent = Split-Path -Parent $DetailReportFile
if ($detailParent -and -not (Test-Path -LiteralPath $detailParent)) {
    New-Item -ItemType Directory -Force -Path $detailParent | Out-Null
}

$rejectedParent = Split-Path -Parent $RejectedOutputFile
if ($rejectedParent -and -not (Test-Path -LiteralPath $rejectedParent)) {
    New-Item -ItemType Directory -Force -Path $rejectedParent | Out-Null
}

$reasonCounts = @{}
$totalCases = 0
$keptCases = 0
$seenQueries = New-Object 'System.Collections.Generic.HashSet[string]'
$detailRows = New-Object System.Collections.Generic.List[object]

$writer = New-Object System.IO.StreamWriter($OutputFile, $false, [System.Text.UTF8Encoding]::new($false))
$rejectedWriter = New-Object System.IO.StreamWriter($RejectedOutputFile, $false, [System.Text.UTF8Encoding]::new($false))
try {
    $writer.WriteLine("-- Filtered SQLite official EGRAPH corpus")
    $writer.WriteLine("-- Source: $InputFile")
    $writer.WriteLine("-- Generated: $(Get-Date -Format o)")
    $writer.WriteLine("-- MaxCaseSetupStatements: $MaxCaseSetupStatements")
    $writer.WriteLine("-- MaxCaseSetupChars: $MaxCaseSetupChars")
    $writer.WriteLine("-- MaxCaseSetupStatementChars: $MaxCaseSetupStatementChars")
    $writer.WriteLine("-- Validation: $(-not $SkipValidation)")
    if (-not $SkipValidation) {
        $writer.WriteLine("-- ValidationSqliteExe: $SqliteExe")
        $writer.WriteLine("-- ValidationTimeoutMillis: $ValidationTimeoutMillis")
    }
    $writer.WriteLine("")
    $rejectedWriter.WriteLine("-- Rejected SQLite official EGRAPH corpus cases")
    $rejectedWriter.WriteLine("-- Source: $InputFile")
    $rejectedWriter.WriteLine("-- Generated: $(Get-Date -Format o)")
    $rejectedWriter.WriteLine("-- Use this for extractor diagnostics, not for long-run EGRAPH oracle input.")
    $rejectedWriter.WriteLine("")

    $inCase = $false
    $inSetup = $false
    $inQuery = $false
    $sourceLine = "-- EGRAPH_CORPUS_CASE_BEGIN source=$InputFile"
    $setupText = New-Object System.Text.StringBuilder
    $queryText = New-Object System.Text.StringBuilder

    foreach ($line in [System.IO.File]::ReadLines($InputFile)) {
        $trimmed = $line.Trim()
        if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_BEGIN")) {
            $inCase = $true
            $inSetup = $false
            $inQuery = $false
            $sourceLine = $trimmed
            [void] $setupText.Clear()
            [void] $queryText.Clear()
            continue
        }
        if (-not $inCase) {
            continue
        }
        if ($trimmed -eq "-- EGRAPH_CORPUS_SETUP_BEGIN") {
            $inSetup = $true
            $inQuery = $false
            continue
        }
        if ($trimmed -eq "-- EGRAPH_BASE_QUERY") {
            $inSetup = $false
            $inQuery = $true
            continue
        }
        if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_END")) {
            $totalCases++
            $setupStatements = @(Read-SqlStatementsFromText -Text $setupText.ToString())
            $setupReason = Get-SetupRejectReason -Statements $setupStatements
            if ($null -ne $setupReason) {
                Add-ReasonCount -Counts $reasonCounts -Reason "setup-$setupReason"
                Add-DetailRow -Rows $detailRows -CaseIndex $totalCases -SourceLine $sourceLine `
                    -Status "rejected" -Reason "setup-$setupReason" -SetupStatements $setupStatements `
                    -Query $queryText.ToString() -Detail ""
                Write-RejectedCase -Writer $rejectedWriter -SourceLine $sourceLine -SetupStatements $setupStatements `
                    -Query $queryText.ToString() -Reason "setup-$setupReason" -Detail ""
            } else {
                $queryStatements = @(Read-SqlStatementsFromText -Text $queryText.ToString())
                $accepted = $false
                foreach ($query in $queryStatements) {
                    $queryReason = Get-QueryRejectReason -Statement $query
                    if ($null -ne $queryReason) {
                        Add-ReasonCount -Counts $reasonCounts -Reason "query-$queryReason"
                        Add-DetailRow -Rows $detailRows -CaseIndex $totalCases -SourceLine $sourceLine `
                            -Status "rejected" -Reason "query-$queryReason" -SetupStatements $setupStatements `
                            -Query $query -Detail ""
                        Write-RejectedCase -Writer $rejectedWriter -SourceLine $sourceLine `
                            -SetupStatements $setupStatements -Query $query -Reason "query-$queryReason" -Detail ""
                        continue
                    }
                    $normalizedQuery = ($query.Trim() -replace '\s+', ' ')
                    if ($seenQueries.Contains($normalizedQuery)) {
                        Add-ReasonCount -Counts $reasonCounts -Reason "query-duplicate"
                        Add-DetailRow -Rows $detailRows -CaseIndex $totalCases -SourceLine $sourceLine `
                            -Status "rejected" -Reason "query-duplicate" -SetupStatements $setupStatements `
                            -Query $query -Detail ""
                        Write-RejectedCase -Writer $rejectedWriter -SourceLine $sourceLine `
                            -SetupStatements $setupStatements -Query $query -Reason "query-duplicate" -Detail ""
                        continue
                    }
                    $validationReason = Test-EGraphCaseCandidate -SetupStatements $setupStatements `
                        -Query $query -CaseIndex $totalCases
                    if ($null -ne $validationReason) {
                        Add-ReasonCount -Counts $reasonCounts -Reason $validationReason
                        Add-DetailRow -Rows $detailRows -CaseIndex $totalCases -SourceLine $sourceLine `
                            -Status "rejected" -Reason $validationReason -SetupStatements $setupStatements `
                            -Query $query -Detail $script:LastValidationDetail
                        Write-RejectedCase -Writer $rejectedWriter -SourceLine $sourceLine `
                            -SetupStatements $setupStatements -Query $query -Reason $validationReason `
                            -Detail $script:LastValidationDetail
                        continue
                    }
                    [void] $seenQueries.Add($normalizedQuery)
                    Write-Case -Writer $writer -SourceLine $sourceLine -SetupStatements $setupStatements -Query $query
                    Add-DetailRow -Rows $detailRows -CaseIndex $totalCases -SourceLine $sourceLine `
                        -Status "kept" -Reason "kept" -SetupStatements $setupStatements -Query $query -Detail ""
                    $keptCases++
                    $accepted = $true
                    break
                }
                if (-not $accepted -and $queryStatements.Count -eq 0) {
                    Add-ReasonCount -Counts $reasonCounts -Reason "query-empty"
                    Add-DetailRow -Rows $detailRows -CaseIndex $totalCases -SourceLine $sourceLine `
                        -Status "rejected" -Reason "query-empty" -SetupStatements $setupStatements `
                        -Query "" -Detail ""
                    Write-RejectedCase -Writer $rejectedWriter -SourceLine $sourceLine `
                        -SetupStatements $setupStatements -Query "" -Reason "query-empty" -Detail ""
                }
            }
            if ($keptCases -ge $MaxCases) {
                break
            }
            $inCase = $false
            $inSetup = $false
            $inQuery = $false
            continue
        }
        if ($inSetup) {
            [void] $setupText.AppendLine($line)
        } elseif ($inQuery) {
            [void] $queryText.AppendLine($line)
        }
    }
} finally {
    $writer.Close()
    $rejectedWriter.Close()
}

$rows = New-Object System.Collections.Generic.List[object]
$rows.Add([pscustomobject]@{
    Kind = "summary"
    Reason = "total-cases"
    Count = $totalCases
})
$rows.Add([pscustomobject]@{
    Kind = "summary"
    Reason = "kept-cases"
    Count = $keptCases
})
foreach ($key in ($reasonCounts.Keys | Sort-Object)) {
    $rows.Add([pscustomobject]@{
        Kind = "skip"
        Reason = $key
        Count = $reasonCounts[$key]
    })
}
$rows | Export-Csv -LiteralPath $ReportFile -NoTypeInformation -Encoding UTF8
$detailRows | Export-Csv -LiteralPath $DetailReportFile -NoTypeInformation -Encoding UTF8

Write-Host "Filtered official corpus written:"
Write-Host $OutputFile
Write-Host "Report:"
Write-Host $ReportFile
Write-Host "Detail report:"
Write-Host $DetailReportFile
Write-Host "Rejected diagnostic corpus:"
Write-Host $RejectedOutputFile
Write-Host "Total cases: $totalCases"
Write-Host "Kept cases: $keptCases"
