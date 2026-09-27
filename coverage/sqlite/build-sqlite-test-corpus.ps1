param(
    [Parameter(Mandatory = $true)]
    [string]$SQLiteSourceDir,

    [string]$OutputFile = "D:\sqlancer\coverage\sqlite\sqlite-official-test-corpus.sql",

    [int]$MaxFiles = 0,

    [int]$MaxSqlBlocks = 20000,

    [int]$MaxSelects = 5000,

    [int]$MaxSetupStatements = 30000,

    # Deliberately looser than the reader's 80: this stage only cuts the runaway cases, and
    # filter-official-egraph-corpus.ps1 applies the reader's own limits afterwards.
    [int]$MaxCaseSetupStatements = 200,

    [switch]$FlatOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-BracedBlock {
    param(
        [string]$Text,
        [int]$OpenBraceIndex
    )

    $depth = 0
    $inSingle = $false
    $inDouble = $false
    for ($i = $OpenBraceIndex; $i -lt $Text.Length; $i++) {
        $ch = $Text[$i]
        if ($ch -eq "'" -and -not $inDouble) {
            $inSingle = -not $inSingle
        } elseif ($ch -eq '"' -and -not $inSingle) {
            $inDouble = -not $inDouble
        } elseif (-not $inSingle -and -not $inDouble) {
            if ($ch -eq '{') {
                $depth++
                if ($depth -eq 1) {
                    $start = $i + 1
                }
            } elseif ($ch -eq '}') {
                $depth--
                if ($depth -eq 0) {
                    return [PSCustomObject]@{
                        Body = $Text.Substring($start, $i - $start)
                        End  = $i
                    }
                }
            }
        }
    }
    return $null
}

function Split-SqlStatements {
    param([string]$Sql)

    $result = New-Object System.Collections.Generic.List[string]
    $current = New-Object System.Text.StringBuilder
    $inSingle = $false
    $inDouble = $false
    for ($i = 0; $i -lt $Sql.Length; $i++) {
        $ch = $Sql[$i]
        [void]$current.Append($ch)
        if ($ch -eq "'" -and -not $inDouble) {
            if ($i + 1 -lt $Sql.Length -and $Sql[$i + 1] -eq "'") {
                $i++
                [void]$current.Append($Sql[$i])
            } else {
                $inSingle = -not $inSingle
            }
        } elseif ($ch -eq '"' -and -not $inSingle) {
            if ($i + 1 -lt $Sql.Length -and $Sql[$i + 1] -eq '"') {
                $i++
                [void]$current.Append($Sql[$i])
            } else {
                $inDouble = -not $inDouble
            }
        } elseif ($ch -eq ';' -and -not $inSingle -and -not $inDouble) {
            $statement = $current.ToString().Trim()
            if ($statement.EndsWith(";")) {
                $statement = $statement.Substring(0, $statement.Length - 1).Trim()
            }
            if ($statement.Length -gt 0) {
                $result.Add($statement)
            }
            [void]$current.Clear()
        }
    }
    $tail = $current.ToString().Trim()
    if ($tail.Length -gt 0) {
        $result.Add($tail)
    }
    return $result
}

function Remove-LineComments {
    param([string]$Sql)
    return (($Sql -split "`r?`n") | ForEach-Object {
        $line = $_
        $idx = $line.IndexOf("--")
        if ($idx -ge 0) {
            $line.Substring(0, $idx)
        } else {
            $line
        }
    }) -join "`n"
}

function Is-UsableSql {
    param([string]$Statement)
    if ([string]::IsNullOrWhiteSpace($Statement)) {
        return $false
    }
    if ($Statement -match '[\$\[\]]') {
        return $false
    }
    if ($Statement -match '(?i)\b(test|catch|execsql|do_execsql_test|foreach|if|proc|set)\b') {
        return $false
    }
    if ($Statement.Length -gt 10000) {
        return $false
    }
    return $true
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

function Is-SafeCorpusSetup {
    param([string[]]$Statements)
    if ($Statements.Count -gt $MaxCaseSetupStatements) {
        return $false
    }
    foreach ($stmt in $Statements) {
        $normalized = ($stmt.Trim() -replace '\s+', ' ').ToUpperInvariant()
        if ($normalized.Contains("SQLITE_MASTER") -or $normalized.Contains("SQLITE_SCHEMA")) {
            return $false
        }
        if ($normalized -match '^PRAGMA\s+(WRITABLE_SCHEMA|PAGE_SIZE|MAX_PAGE_COUNT|JOURNAL_MODE|LOCKING_MODE|INCREMENTAL_VACUUM|AUTO_VACUUM|SYNCHRONOUS)\b') {
            return $false
        }
        if ($normalized -match '^(VACUUM|ATTACH|DETACH)\b') {
            return $false
        }
    }
    return $true
}

function Extract-SqlBlocks {
    param([string]$Text)

    $blocks = New-Object System.Collections.Generic.List[string]
    $patterns = @(
        '(?s)\bdo_execsql_test\s+\S+\s*\{',
        '(?s)\bdo_catchsql_test\s+\S+\s*\{',
        '(?s)\bexecsql\s*\{',
        '(?s)\bcatchsql\s*\{'
    )
    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($Text, $pattern)) {
            $open = $Text.IndexOf('{', $match.Index)
            if ($open -lt 0) {
                continue
            }
            $block = Read-BracedBlock -Text $Text -OpenBraceIndex $open
            if ($null -ne $block) {
                $blocks.Add($block.Body)
            }
        }
    }
    return $blocks
}

$testDir = Join-Path $SQLiteSourceDir "test"
if (-not (Test-Path $testDir)) {
    throw "SQLite test directory not found: $testDir"
}

$files = Get-ChildItem -Path $testDir -Filter "*.test" -File | Sort-Object Name
if ($MaxFiles -gt 0) {
    $files = $files | Select-Object -First $MaxFiles
}

$setup = New-Object System.Collections.Generic.List[string]
$selects = New-Object System.Collections.Generic.List[string]
$cases = New-Object System.Collections.Generic.List[object]
$seen = New-Object 'System.Collections.Generic.HashSet[string]'
$sqlBlocks = 0

foreach ($file in $files) {
    if ($sqlBlocks -ge $MaxSqlBlocks) {
        break
    }
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $fileSetup = New-Object System.Collections.Generic.List[string]
    foreach ($block in Extract-SqlBlocks -Text $text) {
        if ($sqlBlocks -ge $MaxSqlBlocks) {
            break
        }
        $sqlBlocks++
        $clean = Remove-LineComments -Sql $block
        foreach ($stmt in Split-SqlStatements -Sql $clean) {
            $stmt = $stmt.Trim()
            if (-not (Is-UsableSql -Statement $stmt)) {
                continue
            }
            if (Is-SetupStatement -Statement $stmt) {
                if ($FlatOutput -and $setup.Count -lt $MaxSetupStatements -and -not $seen.Contains($stmt)) {
                    [void]$seen.Add($stmt)
                    $setup.Add($stmt)
                }
                if ($fileSetup.Count -lt $MaxSetupStatements) {
                    $fileSetup.Add($stmt)
                }
            } elseif ((Is-EGraphSelect -Statement $stmt) -and $selects.Count -lt $MaxSelects) {
                if ($FlatOutput) {
                    if (-not $seen.Contains($stmt)) {
                        [void]$seen.Add($stmt)
                        $selects.Add($stmt)
                    }
                } else {
                    $selectKey = "$($file.FullName)`n$stmt"
                    if (-not $seen.Contains($selectKey)) {
                        [void]$seen.Add($selectKey)
                        $caseSetup = @($fileSetup)
                        if (Is-SafeCorpusSetup -Statements $caseSetup) {
                            $cases.Add([PSCustomObject]@{
                                Source = $file.FullName
                                Setup  = $caseSetup
                                Query  = $stmt
                            })
                            $selects.Add($stmt)
                        }
                    }
                }
            }
        }
    }
}

$parent = Split-Path -Parent $OutputFile
if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Force $parent | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("-- SQLite official test corpus extracted for SQLancer EGRAPH")
$lines.Add("-- Source: $SQLiteSourceDir")
$lines.Add("-- Generated: $(Get-Date -Format o)")
$lines.Add("-- Format: $(if ($FlatOutput) { 'flat' } else { 'per-case' })")
$lines.Add("-- Setup statements: $(if ($FlatOutput) { $setup.Count } else { ($cases | ForEach-Object { $_.Setup.Count } | Measure-Object -Sum).Sum })")
$lines.Add("-- EGRAPH SELECT inputs: $($selects.Count)")
$lines.Add("")
if ($FlatOutput) {
    $lines.Add("-- SETUP ------------------------------------------------------------")
    foreach ($stmt in $setup) {
        $lines.Add($stmt.TrimEnd(';') + ";")
    }
    $lines.Add("")
    $lines.Add("-- EGRAPH SELECT INPUTS --------------------------------------------")
    foreach ($stmt in $selects) {
        $lines.Add($stmt.TrimEnd(';') + ";")
    }
} else {
    foreach ($case in $cases) {
        $lines.Add("-- EGRAPH_CORPUS_CASE_BEGIN source=$($case.Source)")
        $lines.Add("-- EGRAPH_CORPUS_SETUP_BEGIN")
        foreach ($stmt in $case.Setup) {
            $lines.Add($stmt.TrimEnd(';') + ";")
        }
        $lines.Add("-- EGRAPH_BASE_QUERY")
        $lines.Add($case.Query.TrimEnd(';') + ";")
        $lines.Add("-- EGRAPH_CORPUS_CASE_END")
        $lines.Add("")
    }
}

Set-Content -LiteralPath $OutputFile -Value $lines -Encoding UTF8

Write-Host "SQLite official test corpus written:"
Write-Host $OutputFile
if ($FlatOutput) {
    Write-Host "Setup statements: $($setup.Count)"
} else {
    Write-Host "Per-case records: $($cases.Count)"
}
Write-Host "EGRAPH SELECT inputs: $($selects.Count)"
Write-Host "SQL blocks scanned: $sqlBlocks"
