param(
    [string] $RunDir,
    [int] $ReplayChunkCases = 50,
    [int] $ReplayChunkTimeoutSeconds = 120,
    [int] $ParallelWorkers = 4,
    [switch] $NoRawSqlancerReplay,
    # Prepends the self-contained part of the EGRAPH context setup to every chunk, so the probe
    # tables a wrapper shape queries (egraph_fts4c and friends) exist in the chunk's own database.
    #
    # OPT-IN, because it was measured NET NEGATIVE. A/B on the same 2000 captured cases from the
    # 20260909 run, four workers, identical input:
    #
    #                 line      branch    function   missing-context errors
    #   prelude on    71.90%    76.62%    81.95%     201
    #   prelude on    71.86%    76.58%    81.92%     201     <- same-arm noise: 0.04pp
    #   prelude off   72.70%    77.41%    82.43%     250
    #
    # So it does what it was built for - "no such table: egraph_fts4c" drops from 287 to 233 and
    # missing-context errors from 250 to 201 - and still costs 0.80pp of line coverage, 20x the
    # 0.04pp same-arm noise. Not chunk timeouts (zero in both arms) and not CREATE conflicts (zero
    # "already exists" in both arms); the mechanism is still unexplained. Until it is, the default
    # stays off so the pipeline keeps the better number, and the switch keeps the experiment
    # reproducible.
    [switch] $ContextPrelude
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

$buildDir = Join-Path $coverageRoot "build"
$sourceDir = Join-Path $coverageRoot "sqlite-amalgamation-3530400"
$sqliteExe = Join-Path $buildDir "sqlite3_cov.exe"
$gcovExe = "D:\Dev-Cpp\TDM-GCC-64\bin\gcov.exe"
$sqliteSource = Join-Path $sourceDir "sqlite3.c"

if (-not (Test-Path -LiteralPath $sqliteExe)) {
    throw "Missing instrumented SQLite executable: $sqliteExe"
}
if (-not (Test-Path -LiteralPath $gcovExe)) {
    throw "Missing gcov executable: $gcovExe"
}
if (-not (Test-Path -LiteralPath $sqliteSource)) {
    throw "Missing SQLite source file: $sqliteSource"
}

function Write-IsolatedReplay {
    param(
        [string] $SourcePath,
        [string] $DestinationPath,
        [string] $RunDir
    )

    $databaseCount = 0
    $reader = [System.IO.StreamReader]::new($SourcePath)
    $writer = [System.IO.StreamWriter]::new($DestinationPath, $false, [System.Text.UTF8Encoding]::new($false))
    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            if ($line.StartsWith("-- Time: ")) {
                $dbPath = (Join-Path $RunDir ("codecov-replay-{0:D6}.db" -f $databaseCount)).Replace("\", "/")
                $writer.WriteLine(".open $dbPath")
                $databaseCount++
            }
            $writer.WriteLine($line)
        }
    } finally {
        $reader.Close()
        $writer.Close()
    }
    return $databaseCount
}

function Write-ReplayPreamble {
    param([System.IO.StreamWriter] $Writer)

    $Writer.WriteLine(".bail off")
    $Writer.WriteLine(".timer off")
    $Writer.WriteLine(".timeout 1000")
    $Writer.WriteLine("PRAGMA foreign_keys=OFF;")
    $Writer.WriteLine("PRAGMA defer_foreign_keys=OFF;")
    $Writer.WriteLine("PRAGMA ignore_check_constraints=ON;")
    $Writer.WriteLine("PRAGMA recursive_triggers=ON;")
    $Writer.WriteLine("PRAGMA trusted_schema=ON;")
    $Writer.WriteLine("PRAGMA automatic_index=ON;")
    $Writer.WriteLine("PRAGMA journal_mode=OFF;")
    $Writer.WriteLine("PRAGMA synchronous=OFF;")
    # NOT temp_store=MEMORY: vdbesort.c guards its whole PMA / external-merge
    # path with !sqlite3TempInMemory(db), so an in-memory temp store hides that
    # subsystem from the measurement no matter how large the sort is. The run
    # being measured uses a file-backed temp store, so the replay must too.
    $Writer.WriteLine("PRAGMA temp_store=FILE;")
}

function Write-ReplayFtsSecureFallback {
    param([System.IO.StreamWriter] $Writer)

    $Writer.WriteLine("-- EGRAPH_REPLAY_CONTEXT_FALLBACK fts5_secure")
    $Writer.WriteLine("CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts_secure USING fts5(title, body, tokenize='porter');")
    $Writer.WriteLine("INSERT OR REPLACE INTO egraph_fts_secure(rowid, title, body) VALUES (900001, 'alpha coverage', 'sqlite fts5 secure delete vocabulary prefix'), (900002, 'beta coverage', 'token prefix merge delete optimize'), (900003, 'gamma coverage', 'query planner variants and egraph testing');")
    $Writer.WriteLine("CREATE VIRTUAL TABLE IF NOT EXISTS egraph_fts_secure_vocab USING fts5vocab(egraph_fts_secure, 'row');")
}

function Convert-ReplayLine {
    param([string] $Line)

    if ($Line -match '^\s*CREATE\b' -and $Line.Contains('\n')) {
        # 只在该行确实是被压平的多行语句时才展开。判据是单引号个数为奇数
        # （字符串未闭合）—— 否则 CREATE 里字符串字面量内部的字面 \n 两字符
        # 也会被换成真换行，把字符串截断，留下孤立反斜杠，长跑里报了 11 次
        # `unrecognized token: "\"`。
        $quoteCount = ($Line.ToCharArray() | Where-Object { $_ -eq "'" }).Count
        if ($quoteCount % 2 -eq 1) {
            return ($Line -replace '\\n', [System.Environment]::NewLine)
        }
        return $Line
    }
    if ($Line -match '^\s*INSERT\s+INTO\s+') {
        return [System.Text.RegularExpressions.Regex]::Replace(
            $Line,
            '^\s*INSERT\s+INTO\s+',
            'INSERT OR IGNORE INTO ',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    return $Line
}

function Write-ReplayBufferedLines {
    param(
        [System.IO.StreamWriter] $Writer,
        [System.Collections.Generic.List[string]] $Lines
    )

    for ($i = $Lines.Count - 1; $i -ge 0; $i--) {
        $trimmed = $Lines[$i].Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("--")) {
            continue
        }
        if (-not $trimmed.EndsWith(";")) {
            $Lines[$i] = $Lines[$i].TrimEnd() + ";"
        }
        break
    }
    foreach ($bufferedLine in $Lines) {
        $Writer.WriteLine((Convert-ReplayLine -Line $bufferedLine))
    }
    $Lines.Clear()
}

function Flush-EGraphReplayQueryBuffer {
    param(
        [System.IO.StreamWriter] $Writer,
        [System.Collections.Generic.List[string]] $Lines,
        [ref] $FtsSecureFallbackWrittenForCase
    )

    if ($Lines.Count -eq 0) {
        return
    }
    $queryText = [string]::Join([System.Environment]::NewLine, $Lines)
    if (($queryText.IndexOf("egraph_fts_secure_vocab", [System.StringComparison]::OrdinalIgnoreCase) -ge 0) `
            -and (-not $FtsSecureFallbackWrittenForCase.Value)) {
        Write-ReplayFtsSecureFallback -Writer $Writer
        $FtsSecureFallbackWrittenForCase.Value = $true
    }
    Write-ReplayBufferedLines -Writer $Writer -Lines $Lines
}

# The chunked replay runs each chunk against its own fresh database, and it only ever wrote the
# PRAGMA preamble plus the case lines - never the EGRAPH context setup. So every probe table a
# wrapper shape depends on (egraph_fts4c, egraph_fts_content_src, the rtree/json probes, ...) was
# absent, and those wrapped queries died with "no such table". Measured on the 20260909 run:
# 7664 + 1046 such errors and 977 of 1097 chunks marked failed, which threw away exactly the
# coverage those shapes exist to reach (the uncovered report still listed 460 FTS3/FTS4 and 999
# FTS5 oracle lines despite 13 shapes being assigned to them).
#
# The whole context file cannot simply be prepended: it also records statements that touch
# SQLancer's own tables (t0, x1, ttt, ...), which do not exist yet at the head of a chunk. Those
# are the 131-134 errors the standalone context replay reports, and prepending them verbatim would
# multiply that by the chunk count. Rather than parse SQL to tell the two apart, let SQLite decide:
# replay the context against an empty database once and keep only the statements that succeed.
function Get-EGraphContextPrelude {
    param(
        [string] $ContextPath,
        [string] $SqliteExe,
        [string] $ScratchDir
    )

    if (-not (Test-Path -LiteralPath $ContextPath)) {
        return @()
    }
    $statements = @([System.IO.File]::ReadLines($ContextPath) |
        Where-Object { $_.Trim() -ne "" -and -not $_.Trim().StartsWith("--") })
    if ($statements.Count -eq 0) {
        return @()
    }

    New-Item -ItemType Directory -Force -Path $ScratchDir | Out-Null
    # Keep the probe run's counters out of the real measurement.
    $probeGcda = Join-Path $ScratchDir "gcda-probe"
    New-Item -ItemType Directory -Force -Path $probeGcda | Out-Null

    $kept = $statements
    # A statement can also fail because one it depends on failed, so converge instead of filtering
    # once. Three passes is far more than the dependency chains in this file need.
    for ($pass = 0; $pass -lt 3; $pass++) {
        $probeSql = Join-Path $ScratchDir ("context-probe-{0}.sql" -f $pass)
        $probeDb = Join-Path $ScratchDir ("context-probe-{0}.db" -f $pass)
        $probeErr = Join-Path $ScratchDir ("context-probe-{0}.err.log" -f $pass)
        if (Test-Path -LiteralPath $probeDb) { Remove-Item -LiteralPath $probeDb -Force }

        $probeWriter = [System.IO.StreamWriter]::new($probeSql, $false,
            (New-Object System.Text.UTF8Encoding($false)))
        try {
            $probeWriter.WriteLine(".bail off")
            $probeWriter.WriteLine(".timeout 1000")
            $probeWriter.WriteLine("PRAGMA temp_store=FILE;")
            $headerLines = 3
            foreach ($stmt in $kept) { $probeWriter.WriteLine($stmt) }
        } finally {
            $probeWriter.Dispose()
        }

        $oldPrefix = $env:GCOV_PREFIX
        $env:GCOV_PREFIX = $probeGcda
        try {
            $probeProcess = Start-Process -FilePath $SqliteExe -ArgumentList @($probeDb) `
                -RedirectStandardInput $probeSql -RedirectStandardOutput (Join-Path $ScratchDir "context-probe.out.log") `
                -RedirectStandardError $probeErr -WindowStyle Hidden -Wait -PassThru
            $null = $probeProcess
        } finally {
            if ($null -eq $oldPrefix) { Remove-Item Env:\GCOV_PREFIX -ErrorAction SilentlyContinue }
            else { $env:GCOV_PREFIX = $oldPrefix }
        }

        # "Parse error near line N: ..." / "Error near line N: ..." - N indexes the probe file.
        $failedLines = New-Object System.Collections.Generic.HashSet[int]
        if (Test-Path -LiteralPath $probeErr) {
            foreach ($errLine in [System.IO.File]::ReadLines($probeErr)) {
                $m = [regex]::Match($errLine, 'near line (\d+):')
                if ($m.Success) {
                    $null = $failedLines.Add([int] $m.Groups[1].Value - $headerLines)
                }
            }
        }
        if ($failedLines.Count -eq 0) {
            break
        }
        $surviving = New-Object System.Collections.Generic.List[string]
        for ($i = 0; $i -lt $kept.Count; $i++) {
            if (-not $failedLines.Contains($i + 1)) {
                $surviving.Add($kept[$i])
            }
        }
        $kept = @($surviving)
        if ($kept.Count -eq 0) {
            break
        }
    }

    Write-Host ("EGRAPH context prelude: {0} of {1} statements are self-contained and will be prepended to every chunk" -f `
            $kept.Count, $statements.Count)
    return @($kept)
}

function Write-ContextPrelude {
    param(
        [System.IO.StreamWriter] $Writer,
        [string[]] $Statements
    )

    if ($null -eq $Statements -or $Statements.Count -eq 0) {
        return
    }
    $Writer.WriteLine("-- EGRAPH_CONTEXT_PRELUDE_BEGIN")
    foreach ($stmt in $Statements) {
        $Writer.WriteLine($stmt)
    }
    $Writer.WriteLine("-- EGRAPH_CONTEXT_PRELUDE_END")
}

function Write-EGraphReplayChunks {
    param(
        [string] $SourcePath,
        [string] $ChunkDir,
        [int] $CasesPerChunk,
        [string[]] $ContextPrelude = @()
    )

    if ($CasesPerChunk -lt 1) {
        throw "ReplayChunkCases must be positive."
    }
    if (-not (Test-Path -LiteralPath $ChunkDir)) {
        New-Item -ItemType Directory -Force -Path $ChunkDir | Out-Null
    }
    Get-ChildItem -LiteralPath $ChunkDir -File |
        Where-Object { $_.Name -like "chunk-*" -or $_.Name -like "sqlite-replay.*.log" } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

    $chunks = New-Object System.Collections.Generic.List[object]
    $reader = [System.IO.StreamReader]::new($SourcePath)
    $writer = $null
    $chunkIndex = -1
    $casesInChunk = 0
    $currentChunkPath = $null
    $ftsSecureFallbackWrittenForCase = $false
    $inReplayQuery = $false
    $replayQueryLines = New-Object System.Collections.Generic.List[string]
    # Captured cases are delta encoded: a full snapshot every keyframe, and in
    # between only the statements that rebuild what changed. A chunk therefore
    # has to start on a full snapshot, otherwise its first cases would run
    # against a database that was never built.

    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            if ($line.StartsWith("-- EGRAPH_")) {
                if ($inReplayQuery) {
                    Flush-EGraphReplayQueryBuffer -Writer $writer -Lines $replayQueryLines `
                        -FtsSecureFallbackWrittenForCase ([ref] $ftsSecureFallbackWrittenForCase)
                    $inReplayQuery = $false
                }

                if ($line.StartsWith("-- EGRAPH_CORPUS_CASE_BEGIN")) {
                    $ftsSecureFallbackWrittenForCase = $false
                    $isFullSetupCase = -not $line.Contains("setup=delta")
                    if ($writer -eq $null -or ($casesInChunk -ge $CasesPerChunk -and $isFullSetupCase)) {
                        if ($writer -ne $null) {
                            $writer.Close()
                            $chunks.Add([pscustomobject]@{
                                    Index = $chunkIndex
                                    Path  = $currentChunkPath
                                    Cases = $casesInChunk
                                })
                        }
                        $chunkIndex++
                        $casesInChunk = 0
                        $currentChunkPath = Join-Path $ChunkDir ("chunk-{0:D6}.sql" -f $chunkIndex)
                        $writer = [System.IO.StreamWriter]::new($currentChunkPath, $false,
                            [System.Text.UTF8Encoding]::new($false))
                        Write-ReplayPreamble -Writer $writer
                        Write-ContextPrelude -Writer $writer -Statements $ContextPrelude
                    }
                    $casesInChunk++
                }
                if ($writer -eq $null) {
                    $chunkIndex++
                    $currentChunkPath = Join-Path $ChunkDir ("chunk-{0:D6}.sql" -f $chunkIndex)
                    $writer = [System.IO.StreamWriter]::new($currentChunkPath, $false,
                        [System.Text.UTF8Encoding]::new($false))
                    Write-ReplayPreamble -Writer $writer
                        Write-ContextPrelude -Writer $writer -Statements $ContextPrelude
                }
                $writer.WriteLine((Convert-ReplayLine -Line $line))
                if ($line.StartsWith("-- EGRAPH_REPLAY_QUERY")) {
                    $inReplayQuery = $true
                }
                continue
            }

            if ($writer -eq $null) {
                $chunkIndex++
                $currentChunkPath = Join-Path $ChunkDir ("chunk-{0:D6}.sql" -f $chunkIndex)
                $writer = [System.IO.StreamWriter]::new($currentChunkPath, $false,
                    [System.Text.UTF8Encoding]::new($false))
                Write-ReplayPreamble -Writer $writer
                        Write-ContextPrelude -Writer $writer -Statements $ContextPrelude
            }
            if ($inReplayQuery) {
                $replayQueryLines.Add($line)
                continue
            }
            $writer.WriteLine((Convert-ReplayLine -Line $line))
        }
    } finally {
        if ($inReplayQuery -and $writer -ne $null) {
            Flush-EGraphReplayQueryBuffer -Writer $writer -Lines $replayQueryLines `
                -FtsSecureFallbackWrittenForCase ([ref] $ftsSecureFallbackWrittenForCase)
        }
        $reader.Close()
        if ($writer -ne $null) {
            $writer.Close()
            $chunks.Add([pscustomobject]@{
                    Index = $chunkIndex
                    Path  = $currentChunkPath
                    Cases = $casesInChunk
                })
        }
    }
    return $chunks
}

function Append-FileIfExists {
    param(
        [string] $SourcePath,
        [string] $DestinationPath
    )
    if (Test-Path -LiteralPath $SourcePath) {
        Add-Content -LiteralPath $DestinationPath -Value (Get-Content -LiteralPath $SourcePath -Raw) -NoNewline
    }
}

function Measure-ReplayCases {
    param([string] $Path)

    $cases = 0
    $deltaCases = 0
    $reader = [System.IO.StreamReader]::new($Path)
    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            if ($line.StartsWith("-- EGRAPH_CORPUS_CASE_BEGIN")) {
                $cases++
                if ($line.Contains("setup=delta")) {
                    $deltaCases++
                }
            }
        }
    } finally {
        $reader.Close()
    }
    return [pscustomobject]@{ Cases = $cases; DeltaCases = $deltaCases }
}

$logFile = "D:\sqlancer\logs\sqlite3\database0-cur.log"
$runLogFile = Join-Path $resolvedRunDir "database0-cur.log"
$fullReplayFile = Join-Path $resolvedRunDir "replay-all.sql"
$replayFile = Join-Path $resolvedRunDir "replay.sql"
$replaySource = $logFile
$replayDatabaseCount = 1
$replayCaseCount = 0
$replayDeltaCaseCount = 0

if (Test-Path -LiteralPath $fullReplayFile) {
    $fullReplayInfo = Get-Item -LiteralPath $fullReplayFile
    if ($fullReplayInfo.Length -gt 0) {
        $replaySource = $fullReplayFile
        # Chunked EGRAPH replay reads replay-all.sql directly, so the isolated
        # copy is only needed for the legacy '-- Time:' database format. Copying
        # a multi-GB capture that nothing consumes cost a full extra pass over
        # the whole file.
        $caseStats = Measure-ReplayCases -Path $fullReplayFile
        $replayCaseCount = $caseStats.Cases
        $replayDeltaCaseCount = $caseStats.DeltaCases
        if ($replayCaseCount -gt 0) {
            $replayDatabaseCount = 0
        } else {
            $replayDatabaseCount = Write-IsolatedReplay -SourcePath $fullReplayFile -DestinationPath $replayFile `
                -RunDir $resolvedRunDir
        }
    }
}

if ($replaySource -eq $logFile) {
    if (-not (Test-Path -LiteralPath $logFile)) {
        throw "Missing $logFile. Stop SQLancer after it has written queries, then run this script."
    }
    Copy-Item -LiteralPath $logFile -Destination $replayFile -Force
}

function Parse-GcovSummary {
    param([string] $SummaryPath)
    $result = [ordered]@{
        LinePct = 0.0
        LineTotal = 0
        BranchExecPct = 0.0
        BranchTotal = 0
        BranchTakenPct = 0.0
        CallsPct = 0.0
        CallsTotal = 0
    }
    $inSqliteSource = $false
    foreach ($line in Get-Content -LiteralPath $SummaryPath) {
        if ($line -match "^File '(.+)'$") {
            if ($matches[1] -like "*sqlite3.c") {
                $inSqliteSource = $true
                continue
            }
            if ($inSqliteSource) {
                break
            }
            continue
        }
        if (-not $inSqliteSource) {
            continue
        }
        if ($line -match '^Lines executed:([0-9.]+)% of ([0-9]+)$') {
            $result.LinePct = [double] $matches[1]
            $result.LineTotal = [int] $matches[2]
        } elseif ($line -match '^Branches executed:([0-9.]+)% of ([0-9]+)$' -and $result.BranchExecPct -eq 0.0) {
            $result.BranchExecPct = [double] $matches[1]
            $result.BranchTotal = [int] $matches[2]
        } elseif ($line -match '^Taken at least once:([0-9.]+)% of ([0-9]+)$') {
            $result.BranchTakenPct = [double] $matches[1]
        } elseif ($line -match '^Calls executed:([0-9.]+)% of ([0-9]+)$' -and $result.CallsTotal -eq 0) {
            $result.CallsPct = [double] $matches[1]
            $result.CallsTotal = [int] $matches[2]
        }
    }
    return $result
}

function Parse-FunctionCoverage {
    param([string] $FunctionsPath)
    $lines = @(Get-Content -LiteralPath $FunctionsPath)
    $total = 0
    $covered = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -like "Function '*") {
            $total++
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match 'Lines executed:([0-9.]+)%') {
                if ([double] $matches[1] -gt 0) {
                    $covered++
                }
            }
        }
    }
    $pct = if ($total -gt 0) { 100.0 * $covered / $total } else { 0.0 }
    return [ordered]@{ Covered = $covered; Total = $total; Pct = $pct }
}

function Count-TextMatches {
    param(
        [string] $Path,
        [string] $Pattern
    )
    return @(Select-String -Path $Path -Pattern $Pattern -CaseSensitive:$false -ErrorAction SilentlyContinue).Count
}

function Get-ProcessExitCodeOrNull {
    param([System.Diagnostics.Process] $Process)

    if ($null -eq $Process) {
        return $null
    }
    try {
        if ($Process.HasExited) {
            return $Process.ExitCode
        }
    } catch {
    }
    return $null
}

$replaySourceInfo = Get-Item -LiteralPath $replaySource
$replayHealthNotes = New-Object System.Collections.Generic.List[string]
if ($replayCaseCount -gt 0 -and $replayDatabaseCount -eq 0) {
    $replayHealthNotes.Add("Replay uses EGRAPH corpus-case blocks rather than SQLancer '-- Time:' database blocks.")
}
if ($replayCaseCount -gt 0 -and -not $NoRawSqlancerReplay -and -not (Test-Path -LiteralPath $runLogFile)) {
    $replayHealthNotes.Add("No run-local database0-cur.log was found; coverage will not include the full SQLancer database log.")
}
if ($replaySourceInfo.Length -lt 1048576) {
    $replayHealthNotes.Add(("Replay source is small ({0:N0} bytes); coverage is likely a smoke result, not a long-run result." -f $replaySourceInfo.Length))
}
if ($replayCaseCount -gt 0 -and $replayCaseCount -lt 1000) {
    $replayHealthNotes.Add(("Only {0} EGRAPH replay cases were captured; run longer before trusting coverage." -f $replayCaseCount))
}
if ($replayCaseCount -eq 0 -and $replayDatabaseCount -eq 0 -and $replaySource -ne $logFile) {
    $replayHealthNotes.Add("No replay case or database boundary was found in replay-all.sql.")
}

Write-Host "Run dir: $resolvedRunDir"
Write-Host "Replay source: $replaySource"
Write-Host "Replay file: $replayFile"
Write-Host "Replay database count: $replayDatabaseCount"
Write-Host "Replay EGRAPH case count: $replayCaseCount"
Write-Host "Replay EGRAPH delta-encoded cases: $replayDeltaCaseCount"
Write-Host ("Replay source bytes: {0}" -f $replaySourceInfo.Length)
foreach ($note in $replayHealthNotes) {
    Write-Warning $note
}
Write-Host "Replaying captured SQL with instrumented SQLite..."

$resolvedBuildDir = (Resolve-Path -LiteralPath $buildDir).Path
if ($resolvedBuildDir -ne "D:\sqlancer\coverage\sqlite\build") {
    throw "Unexpected build dir: $resolvedBuildDir"
}

Get-ChildItem -LiteralPath $resolvedBuildDir -File |
    Where-Object { $_.Extension -eq ".gcda" -or $_.Extension -eq ".gcov" } |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

$replayDb = Join-Path $resolvedRunDir "codecov-replay.db"
Get-ChildItem -LiteralPath $resolvedRunDir -File -Filter "codecov-replay*.db" |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

$replayMode = if ($replayCaseCount -gt 0) { "EGRAPH chunked replay" } else { "single replay file" }
$replayChunkCount = 0
$replayChunksTimedOut = 0
$replayChunksFailed = 0
$replayChunksNonZeroExit = 0
$replayChunksExecuted = 0
$rawReplayUsed = $false
$rawReplayDatabaseCount = 0
$rawReplayExit = $null
$rawReplayErrorCount = 0
$gcovToolExit = $null
$parallelWorkerCount = if ($ParallelWorkers -lt 1) { 1 } else { $ParallelWorkers }
$contextReplayFile = Join-Path $resolvedRunDir "replay-context.sql"
$contextReplayUsed = $false
$contextReplayExit = $null
$contextReplayErrorCount = 0

Push-Location $resolvedBuildDir
try {
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $aggregateOut = Join-Path $resolvedRunDir "sqlite-replay.out.log"
    $aggregateErr = Join-Path $resolvedRunDir "sqlite-replay.err.log"
    [System.IO.File]::WriteAllText($aggregateOut, "", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText($aggregateErr, "", [System.Text.UTF8Encoding]::new($false))

    if ((Test-Path -LiteralPath $contextReplayFile) -and (Get-Item -LiteralPath $contextReplayFile).Length -gt 0) {
        $contextReplayUsed = $true
        $contextReplayInput = Join-Path $resolvedRunDir "replay-context-wrapped.sql"
        $contextReplayDb = Join-Path $resolvedRunDir "codecov-context-replay.db"
        $contextOut = Join-Path $resolvedRunDir "sqlite-context-replay.out.log"
        $contextErr = Join-Path $resolvedRunDir "sqlite-context-replay.err.log"
        $contextWriter = [System.IO.StreamWriter]::new($contextReplayInput, $false,
            [System.Text.UTF8Encoding]::new($false))
        try {
            Write-ReplayPreamble -Writer $contextWriter
            foreach ($contextLine in [System.IO.File]::ReadLines($contextReplayFile)) {
                $contextWriter.WriteLine((Convert-ReplayLine -Line $contextLine))
            }
        } finally {
            $contextWriter.Close()
        }

        Write-Host "Replay mode: EGRAPH context replay before captured workload"
        $contextReplayProcess = Start-Process -FilePath $sqliteExe `
            -ArgumentList @($contextReplayDb) `
            -RedirectStandardInput $contextReplayInput `
            -RedirectStandardOutput $contextOut `
            -RedirectStandardError $contextErr `
            -WorkingDirectory $resolvedBuildDir `
            -WindowStyle Hidden `
            -Wait `
            -PassThru
        $contextReplayExit = Get-ProcessExitCodeOrNull -Process $contextReplayProcess
        $contextReplayErrorCount = Count-TextMatches -Path $contextErr -Pattern 'Parse error|Runtime error|Error:'
        Append-FileIfExists -SourcePath $contextOut -DestinationPath $aggregateOut
        Append-FileIfExists -SourcePath $contextErr -DestinationPath $aggregateErr
    }

    if ($replayCaseCount -gt 0 -and -not $NoRawSqlancerReplay -and (Test-Path -LiteralPath $runLogFile)) {
        $rawReplayFile = Join-Path $resolvedRunDir "raw-replay.sql"
        $rawReplayDatabaseCount = Write-IsolatedReplay -SourcePath $runLogFile -DestinationPath $rawReplayFile `
            -RunDir $resolvedRunDir
        if ($rawReplayDatabaseCount -gt 0) {
            $rawReplayUsed = $true
            $rawReplayDb = Join-Path $resolvedRunDir "codecov-raw-replay.db"
            $rawOut = Join-Path $resolvedRunDir "sqlite-raw-replay.out.log"
            $rawErr = Join-Path $resolvedRunDir "sqlite-raw-replay.err.log"
            Write-Host ("Replay mode: raw SQLancer log ({0} databases) before EGRAPH chunks" -f `
                    $rawReplayDatabaseCount)
            $rawReplayProcess = Start-Process -FilePath $sqliteExe `
                -ArgumentList @($rawReplayDb) `
                -RedirectStandardInput $rawReplayFile `
                -RedirectStandardOutput $rawOut `
                -RedirectStandardError $rawErr `
                -WorkingDirectory $resolvedBuildDir `
                -WindowStyle Hidden `
                -Wait `
                -PassThru
            $rawReplayExit = Get-ProcessExitCodeOrNull -Process $rawReplayProcess
            $rawReplayErrorCount = Count-TextMatches -Path $rawErr -Pattern 'Parse error|Runtime error|Error:'
            Append-FileIfExists -SourcePath $rawOut -DestinationPath $aggregateOut
            Append-FileIfExists -SourcePath $rawErr -DestinationPath $aggregateErr
            $replayMode = "raw SQLancer log + EGRAPH chunked replay"
        }
    }

    $gcdaRootDir = $resolvedBuildDir
    if ($replayCaseCount -gt 0) {
        $chunkDir = Join-Path $resolvedRunDir "replay-chunks"
        $contextPrelude = @()
        if ($ContextPrelude) {
            $contextPrelude = @(Get-EGraphContextPrelude -ContextPath $contextReplayFile -SqliteExe $sqliteExe `
                    -ScratchDir (Join-Path $resolvedRunDir "context-prelude"))
        }
        $chunks = @(Write-EGraphReplayChunks -SourcePath $replaySource -ChunkDir $chunkDir `
                -CasesPerChunk $ReplayChunkCases -ContextPrelude $contextPrelude)
        $replayChunkCount = $chunks.Count
        $gcovToolExe = Join-Path (Split-Path -Parent $gcovExe) "gcov-tool.exe"
        $gcdaWorkerDirs = New-Object System.Collections.Generic.List[string]
        for ($w = 0; $w -lt $parallelWorkerCount; $w++) {
            $workerGcdaDir = Join-Path $resolvedRunDir ("gcda-w{0:D2}" -f $w)
            if (Test-Path -LiteralPath $workerGcdaDir) {
                Remove-Item -LiteralPath $workerGcdaDir -Recurse -Force
            }
            New-Item -ItemType Directory -Force -Path $workerGcdaDir | Out-Null
            $gcdaWorkerDirs.Add($workerGcdaDir)
        }

        Write-Host ("Replay mode: chunked EGRAPH cases ({0} chunks, {1} cases/chunk, {2}s timeout/chunk, {3} parallel workers)" -f `
                $replayChunkCount, $ReplayChunkCases, $ReplayChunkTimeoutSeconds, $parallelWorkerCount)

        # Bounded-concurrency chunk replay. Each worker writes gcov data to a
        # private GCOV_PREFIX directory so parallel processes never race on one
        # sqlite3.gcda; gcov-tool merges the directories afterwards.
        $running = New-Object System.Collections.Generic.List[object]
        $nextChunkIndex = 0
        while ($true) {
            while ($nextChunkIndex -lt $replayChunkCount -and $running.Count -lt $parallelWorkerCount) {
                $chunkIndex = $nextChunkIndex
                $nextChunkIndex++
                $chunk = $chunks[$chunkIndex]
                $workerId = $chunkIndex % $parallelWorkerCount
                $chunkDb = Join-Path $chunkDir ("chunk-{0:D6}.db" -f $chunkIndex)
                $chunkOut = Join-Path $chunkDir ("sqlite-replay.{0:D6}.out.log" -f $chunkIndex)
                $chunkErr = Join-Path $chunkDir ("sqlite-replay.{0:D6}.err.log" -f $chunkIndex)
                Get-ChildItem -LiteralPath $chunkDir -File -Filter ("chunk-{0:D6}.db*" -f $chunkIndex) `
                    -ErrorAction SilentlyContinue |
                    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }

                $hadGcovPrefix = Test-Path Env:\GCOV_PREFIX
                if ($hadGcovPrefix) {
                    $oldGcovPrefix = $env:GCOV_PREFIX
                }
                try {
                    $env:GCOV_PREFIX = $gcdaWorkerDirs[$workerId]
                    $replayProcess = Start-Process -FilePath $sqliteExe `
                        -ArgumentList @($chunkDb) `
                        -RedirectStandardInput $chunk.Path `
                        -RedirectStandardOutput $chunkOut `
                        -RedirectStandardError $chunkErr `
                        -WorkingDirectory $resolvedBuildDir `
                        -WindowStyle Hidden `
                        -PassThru
                } finally {
                    if ($hadGcovPrefix) {
                        $env:GCOV_PREFIX = $oldGcovPrefix
                    } else {
                        Remove-Item Env:\GCOV_PREFIX -ErrorAction SilentlyContinue
                    }
                }
                $running.Add(@{
                        Process = $replayProcess
                        Index   = $chunkIndex
                        Start   = Get-Date
                        Out     = $chunkOut
                        Err     = $chunkErr
                    })
            }
            if ($running.Count -eq 0) {
                break
            }
            Start-Sleep -Milliseconds 250
            for ($i = $running.Count - 1; $i -ge 0; $i--) {
                $entry = $running[$i]
                $proc = $entry.Process
                $exited = $false
                try {
                    $proc.Refresh()
                    $exited = $proc.HasExited
                } catch {
                    $exited = $true
                }
                $elapsedSeconds = ((Get-Date) - $entry.Start).TotalSeconds
                $timedOut = $false
                if (-not $exited -and $elapsedSeconds -ge $ReplayChunkTimeoutSeconds) {
                    try {
                        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                        $proc.WaitForExit(5000) | Out-Null
                    } catch {
                    }
                    $exited = $true
                    $timedOut = $true
                    $replayChunksTimedOut++
                    Add-Content -LiteralPath $entry.Err -Value `
                        ("Replay chunk timeout after {0}s: chunk={1:D6}, cases={2}" -f `
                            $ReplayChunkTimeoutSeconds, $entry.Index, $chunks[$entry.Index].Cases)
                }
                if ($exited) {
                    if (-not $timedOut) {
                        $proc.Refresh()
                        $chunkExitCode = Get-ProcessExitCodeOrNull -Process $proc
                        if ($null -ne $chunkExitCode -and $chunkExitCode -ne 0) {
                            $replayChunksNonZeroExit++
                        }
                    }
                    $chunkErrorCount = Count-TextMatches -Path $entry.Err -Pattern 'Parse error|Runtime error|Error:|Replay chunk timeout'
                    if ($chunkErrorCount -gt 0) {
                        $replayChunksFailed++
                    }
                    $replayChunksExecuted++
                    Append-FileIfExists -SourcePath $entry.Out -DestinationPath $aggregateOut
                    Append-FileIfExists -SourcePath $entry.Err -DestinationPath $aggregateErr
                    if (($replayChunksExecuted % 25) -eq 0 -or $replayChunksExecuted -eq $replayChunkCount) {
                        Write-Host ("Replay chunks: {0}/{1}, timed out: {2}, failed: {3}" -f `
                                $replayChunksExecuted, $replayChunkCount, $replayChunksTimedOut, $replayChunksFailed)
                    }
                    $running.RemoveAt($i)
                }
            }
        }

        # Collect every distinct directory that received .gcda data (worker
        # prefixes may nest the object path), plus the build dir used by the
        # raw/context replays, then merge them into one directory for gcov.
        $gcdaDirs = New-Object System.Collections.Generic.List[string]
        foreach ($workerDir in $gcdaWorkerDirs) {
            Get-ChildItem -LiteralPath $workerDir -Recurse -File -Filter "*.gcda" -ErrorAction SilentlyContinue |
                ForEach-Object {
                    if (-not $gcdaDirs.Contains($_.DirectoryName)) {
                        $gcdaDirs.Add($_.DirectoryName)
                    }
                }
        }
        if (Get-ChildItem -LiteralPath $resolvedBuildDir -File -Filter "*.gcda" -ErrorAction SilentlyContinue) {
            $gcdaDirs.Add($resolvedBuildDir)
        }
        if ($gcdaDirs.Count -eq 0) {
            $gcdaDirs.Add($resolvedBuildDir)
        }
        if ($gcdaDirs.Count -gt 1) {
            # gcov-tool merge takes exactly two directories. Passing all worker
            # directories at once fails, and the old fallback then reported the
            # coverage of a single worker as if it were the whole replay, so fold
            # the directories pairwise instead.
            $mergeOutLog = Join-Path $resolvedRunDir "gcov-tool-merge.out.txt"
            $mergeErrLog = Join-Path $resolvedRunDir "gcov-tool-merge.err.txt"
            [System.IO.File]::WriteAllText($mergeOutLog, "", [System.Text.UTF8Encoding]::new($false))
            [System.IO.File]::WriteAllText($mergeErrLog, "", [System.Text.UTF8Encoding]::new($false))
            Write-Host ("Merging gcov data from {0} directories with gcov-tool..." -f $gcdaDirs.Count)
            $mergeAccumulator = $gcdaDirs[0]
            $gcovToolExit = 0
            for ($mergeIndex = 1; $mergeIndex -lt $gcdaDirs.Count; $mergeIndex++) {
                $stepDir = Join-Path $resolvedRunDir ("gcda-merged-{0:D2}" -f $mergeIndex)
                if (Test-Path -LiteralPath $stepDir) {
                    Remove-Item -LiteralPath $stepDir -Recurse -Force
                }
                New-Item -ItemType Directory -Force -Path $stepDir | Out-Null
                & $gcovToolExe merge $mergeAccumulator $gcdaDirs[$mergeIndex] -o $stepDir `
                    >> $mergeOutLog 2>> $mergeErrLog
                $gcovToolExit = $LASTEXITCODE
                if ($gcovToolExit -ne 0) {
                    break
                }
                $mergeAccumulator = $stepDir
            }
            if ($gcovToolExit -eq 0) {
                $gcdaRootDir = $mergeAccumulator
                # gcov reads the notes file next to the merged counters, so the
                # .gcno files have to travel with them.
                Get-ChildItem -LiteralPath $resolvedBuildDir -File -Filter "*.gcno" |
                    ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $gcdaRootDir -Force }
            } else {
                Write-Warning "gcov-tool merge failed (exit $gcovToolExit); coverage numbers may be partial."
                $gcdaRootDir = $gcdaDirs[0]
            }
        } else {
            $gcdaRootDir = $gcdaDirs[0]
        }

        $replayExit = if ($replayChunksTimedOut -gt 0) {
            124
        } elseif ($replayChunksFailed -gt 0) {
            1
        } else {
            0
        }
        if ($rawReplayUsed -and $null -ne $rawReplayExit -and $rawReplayExit -ne 0 -and $replayExit -eq 0) {
            $replayExit = $rawReplayExit
        }
    } else {
        $replayProcess = Start-Process -FilePath $sqliteExe `
            -ArgumentList @($replayDb) `
            -RedirectStandardInput $replayFile `
            -RedirectStandardOutput $aggregateOut `
            -RedirectStandardError $aggregateErr `
            -WorkingDirectory $resolvedBuildDir `
            -WindowStyle Hidden `
            -Wait `
            -PassThru
        $replayExit = Get-ProcessExitCodeOrNull -Process $replayProcess
    }
    # gcov -f already prints the per-file summary after the per-function blocks,
    # so one pass produces both reports. Running gcov twice over sqlite3.c cost
    # hours on a long-run gcda set.
    $functionsPath = Join-Path $resolvedRunDir "gcov-sqlite3-functions.txt"
    $summaryPath = Join-Path $resolvedRunDir "gcov-sqlite3-summary.txt"
    & $gcovExe -f -b -c -o $gcdaRootDir $sqliteSource > $functionsPath 2> (Join-Path $resolvedRunDir "gcov-sqlite3-functions.err.txt")
    $gcovFuncExit = $LASTEXITCODE
    $gcovExit = $gcovFuncExit
    Copy-Item -LiteralPath (Join-Path $resolvedRunDir "gcov-sqlite3-functions.err.txt") `
        -Destination (Join-Path $resolvedRunDir "gcov-sqlite3.err.txt") -Force -ErrorAction SilentlyContinue
    $functionsLines = @(Get-Content -LiteralPath $functionsPath)
    $summaryStart = -1
    for ($fi = 0; $fi -lt $functionsLines.Count; $fi++) {
        if ($functionsLines[$fi] -match "^File '") {
            $summaryStart = $fi
            break
        }
    }
    if ($summaryStart -ge 0) {
        [System.IO.File]::WriteAllLines($summaryPath, $functionsLines[$summaryStart..($functionsLines.Count - 1)],
            [System.Text.UTF8Encoding]::new($true))
    } else {
        [System.IO.File]::WriteAllLines($summaryPath, @(), [System.Text.UTF8Encoding]::new($true))
    }
    $ErrorActionPreference = $oldErrorActionPreference
    Copy-Item -LiteralPath (Join-Path $resolvedBuildDir "sqlite3.c.gcov") -Destination (Join-Path $resolvedRunDir "sqlite3.c.gcov") -Force -ErrorAction SilentlyContinue
} finally {
    if (Get-Variable -Name oldErrorActionPreference -Scope Local -ErrorAction SilentlyContinue) {
        $ErrorActionPreference = $oldErrorActionPreference
    }
    Pop-Location
}

$summary = Parse-GcovSummary -SummaryPath (Join-Path $resolvedRunDir "gcov-sqlite3-summary.txt")
$functions = Parse-FunctionCoverage -FunctionsPath (Join-Path $resolvedRunDir "gcov-sqlite3-functions.txt")
$replayErrors = Count-TextMatches -Path (Join-Path $resolvedRunDir "sqlite-replay.err.log") `
        -Pattern 'Parse error|Runtime error|Error:'
$missingContextErrors = Count-TextMatches -Path (Join-Path $resolvedRunDir "sqlite-replay.err.log") `
        -Pattern 'no such table: egraph|no such index: egraph'

$report = New-Object System.Collections.Generic.List[string]
$report.Add("SQLite code coverage result")
$report.Add("===========================")
$report.Add("")
$report.Add("Run")
$report.Add("- Result dir: $resolvedRunDir")
$report.Add("- SQLancer duration: manual long run without timeout")
$report.Add("- Replay source: $replaySource")
$report.Add("- SQLancer replay file: $replayFile")
$report.Add("- Replay mode: $replayMode")
$report.Add("- Replay database count: $replayDatabaseCount")
$report.Add("- Replay EGRAPH case count: $replayCaseCount")
$report.Add("- Replay EGRAPH delta-encoded cases: $replayDeltaCaseCount")
$report.Add("- EGRAPH context replay used: $contextReplayUsed")
$report.Add("- EGRAPH context replay file: $contextReplayFile")
$report.Add("- EGRAPH context replay exit code: $contextReplayExit")
$report.Add("- EGRAPH context replay error count: $contextReplayErrorCount")
$report.Add("- Raw SQLancer replay used: $rawReplayUsed")
$report.Add("- Raw SQLancer replay database count: $rawReplayDatabaseCount")
$report.Add("- Raw SQLancer replay exit code: $rawReplayExit")
$report.Add("- Raw SQLancer replay error count: $rawReplayErrorCount")
$report.Add("- Replay chunk count: $replayChunkCount")
$report.Add("- Replay parallel workers: $parallelWorkerCount")
$report.Add("- gcov-tool merge exit code: $gcovToolExit")
$report.Add("- Replay chunks executed: $replayChunksExecuted")
$report.Add("- Replay chunks timed out: $replayChunksTimedOut")
$report.Add("- Replay chunks failed: $replayChunksFailed")
$report.Add("- Replay chunks with non-zero exit: $replayChunksNonZeroExit")
$report.Add(("- Replay source bytes: {0}" -f $replaySourceInfo.Length))
$report.Add("- SQLite replay exit code: $replayExit")
$report.Add("- gcov exit code: $gcovExit")
$report.Add("- gcov function exit code: $gcovFuncExit")
$report.Add("- SQLite replay error count: $replayErrors")
$report.Add("- Missing egraph context error count: $missingContextErrors")
$report.Add("")
$report.Add("SQLite code coverage (gcov / sqlite3.c)")
$report.Add(("- Line coverage: {0:N2}% of {1}" -f $summary.LinePct, $summary.LineTotal))
$report.Add(("- Branches executed: {0:N2}% of {1}" -f $summary.BranchExecPct, $summary.BranchTotal))
$report.Add(("- Branches taken at least once: {0:N2}%" -f $summary.BranchTakenPct))
$report.Add(("- Calls executed: {0:N2}% of {1}" -f $summary.CallsPct, $summary.CallsTotal))
$report.Add(("- Functions executed: {0}/{1} = {2:N2}%" -f $functions.Covered, $functions.Total, $functions.Pct))
$report.Add("")
$report.Add("Notes")
$report.Add("- This is real SQLite engine source coverage for sqlite3.c, not feature coverage.")
$report.Add("- Missing egraph context errors should be 0; otherwise replay did not reproduce runtime context completely.")
foreach ($note in $replayHealthNotes) {
    $report.Add("- WARNING: $note")
}
[System.IO.File]::WriteAllLines((Join-Path $resolvedRunDir "sqlite-code-coverage-result.txt"), $report,
    [System.Text.UTF8Encoding]::new($true))

Write-Host "Code coverage report: $resolvedRunDir\sqlite-code-coverage-result.txt"

$highCoverageCorpusScript = Join-Path $coverageRoot "update-high-coverage-corpus.ps1"
if (Test-Path -LiteralPath $highCoverageCorpusScript) {
    & powershell -ExecutionPolicy Bypass -File $highCoverageCorpusScript -RunDir $resolvedRunDir
}

# Which code the run never reached is the input for planning the next one, so it
# is produced here rather than left as a manual step nobody remembers to run.
$uncoveredScript = Join-Path $coverageRoot "analyze-uncovered-codecov.ps1"
if (Test-Path -LiteralPath $uncoveredScript) {
    Write-Host ""
    Write-Host "Analyzing uncovered code..."
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    # Capture first, then trim: piping straight into Select-Object -First closes
    # the pipeline early, which kills the child process and reports exit -1.
    $uncoveredOutput = @(& powershell -ExecutionPolicy Bypass -File $uncoveredScript -RunDir $resolvedRunDir 2>&1)
    $uncoveredExit = $LASTEXITCODE
    $uncoveredOutput | Select-Object -First 45 | ForEach-Object { Write-Host $_ }
    if ($uncoveredExit -ne 0) {
        Write-Warning "Uncovered-code analysis failed (exit $uncoveredExit)."
    }
    $ErrorActionPreference = $oldErrorActionPreference
}
