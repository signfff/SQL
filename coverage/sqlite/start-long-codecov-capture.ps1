param(
    [switch] $IncludeAutoResearchCorpus,
    [switch] $NoAutoResearchCorpus,
    # Extra -D properties, e.g. -ExtraJavaProps '-Dsqlite3.egraph.corpusSetupOnly=true'
    [string[]] $ExtraJavaProps = @(),
    # Suffix for the run directory so A/B runs are told apart at a glance
    [string] $RunTag = "",
    # Ceiling for the JVM heap. Empty leaves the JVM its default, a quarter of the machine.
    [string] $JavaHeapMax = "3g",
    # How many corpus cases are kept in memory. Every kept case holds its setup statements, so this
    # is the corpus reader's share of the heap.
    [int] $MaxCorpusQueries = 30000,
    # The trunk build that judges a mismatch, check-in 75c1ee9de6 (3.54.0, 2026-09-24). Record which
    # check-in it came from: trunk moves daily and a verdict against "latest" cannot be rechecked.
    # It is a native build on purpose - reaching the same binary through WSL kept a second virtual
    # machine resident for the whole run, and WSL2 does not hand that memory back. Empty turns the
    # refereeing off and makes every mismatch a finding again.
    [string] $RefereeCommand = "D:\sqlancer\coverage\sqlite\trunk\sqlite3_trunk.exe",
    # Wall-clock limit for the capture. -1 keeps the original behaviour of running
    # until Ctrl+C; a positive value makes the run unattended.
    [int] $TimeoutSeconds = -1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Location "D:\sqlancer"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runSuffix = if ([string]::IsNullOrWhiteSpace($RunTag)) { "" } else { "-$RunTag" }
$runDir = "D:\sqlancer\coverage\sqlite\manual-long-codecov-$stamp$runSuffix"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$lastRunFile = "D:\sqlancer\coverage\sqlite\last-long-codecov-run.txt"
Set-Content -LiteralPath $lastRunFile -Value $runDir -Encoding ASCII

$logFile = "D:\sqlancer\logs\sqlite3\database0-cur.log"
if (Test-Path -LiteralPath $logFile) {
    Copy-Item -LiteralPath $logFile -Destination (Join-Path $runDir "previous-database0-cur.log") -Force
    Remove-Item -LiteralPath $logFile -Force
}

$jar = "D:\sqlancer\target\sqlancer-2.0.0.jar"
if (-not (Test-Path -LiteralPath $jar)) {
    throw "Missing $jar. Build SQLancer first."
}
$classpathFile = "D:\sqlancer\target\classpath.txt"
$javaClasspath = $jar
if (Test-Path -LiteralPath $classpathFile) {
    $mavenClasspath = (Get-Content -LiteralPath $classpathFile -Raw).Trim()
    if (-not [string]::IsNullOrWhiteSpace($mavenClasspath)) {
        $javaClasspath = (@($jar, $mavenClasspath)) -join [System.IO.Path]::PathSeparator
    }
}
$rawEgraphInputFile = "D:\sqlancer\coverage\sqlite\sqlite-official-test-corpus.sql"
$filteredEgraphInputFile = "D:\sqlancer\coverage\sqlite\sqlite-official-select-only-corpus.sql"
$egraphInputFile = "D:\sqlancer\coverage\sqlite\sqlite-official-select-only-variant-ready-corpus.sql"

$rebuildOfficialSeeds = ($env:SQLANCER_REBUILD_OFFICIAL_SEEDS -eq "1")
if ($rebuildOfficialSeeds) {
    $variantReadyCasesCsv = "D:\sqlancer\coverage\sqlite\sqlite-official-select-only-variant-ready-cases.csv"
    $acceptanceProfile = "D:\sqlancer\coverage\sqlite\egraph-acceptance-profile-select-only.csv"
    $filterScript = "D:\sqlancer\coverage\sqlite\build-official-select-only-corpus.ps1"
    $profileScript = "D:\sqlancer\coverage\sqlite\profile-egraph-acceptance.ps1"
    $variantReadyScript = "D:\sqlancer\coverage\sqlite\build-variant-ready-official-corpus.ps1"
    if (-not (Test-Path -LiteralPath $filterScript)) {
        throw "Missing EGRAPH input filter script: $filterScript"
    }
    if (-not (Test-Path -LiteralPath $profileScript)) {
        throw "Missing EGRAPH acceptance profiler script: $profileScript"
    }
    if (-not (Test-Path -LiteralPath $variantReadyScript)) {
        throw "Missing EGRAPH variant-ready corpus builder: $variantReadyScript"
    }

    & powershell -ExecutionPolicy Bypass -File $filterScript `
        -InputFile $rawEgraphInputFile `
        -OutputFile $filteredEgraphInputFile
    & powershell -ExecutionPolicy Bypass -File $profileScript `
        -InputFile $filteredEgraphInputFile `
        -OutputFile $acceptanceProfile
    & powershell -ExecutionPolicy Bypass -File $variantReadyScript `
        -InputCorpus $filteredEgraphInputFile `
        -ProfileCsv $acceptanceProfile `
        -OutputCorpus $egraphInputFile `
        -OutputCasesCsv $variantReadyCasesCsv
}
if (-not (Test-Path -LiteralPath $egraphInputFile)) {
    throw "Missing variant-ready EGRAPH input corpus: $egraphInputFile"
}
$variantReadyCaseCount = ([regex]::Matches(
        [System.IO.File]::ReadAllText($egraphInputFile),
        "-- EGRAPH_CORPUS_CASE_BEGIN")).Count
if ($variantReadyCaseCount -le 0) {
    throw "Variant-ready EGRAPH input corpus has no cases: $egraphInputFile"
}
$highCoverageCorpus = "D:\sqlancer\coverage\sqlite\high-coverage-egraph-corpus.sql"
$autoResearchCorpus = "D:\sqlancer\coverage\sqlite\auto-research-filtered-corpus.sql"
if ($IncludeAutoResearchCorpus -and $NoAutoResearchCorpus) {
    throw "Use either -IncludeAutoResearchCorpus or -NoAutoResearchCorpus, not both."
}
# finish-long-codecov.ps1 writes its auto research into "<run dir>\auto-research", one level below
# the directories this used to scan, so the freshest results - the ones measured on the current
# instrumented build - were invisible here and a months-old CSV kept winning on LastWriteTime.
$autoResearchCandidates = New-Object System.Collections.Generic.List[object]
foreach ($dir in (Get-ChildItem -LiteralPath "D:\sqlancer\coverage\sqlite" -Directory)) {
    if ($dir.Name -like "auto-research-smoke-*") { continue }
    foreach ($relative in @("auto-research-results.csv", "auto-research\auto-research-results.csv")) {
        $candidate = Join-Path $dir.FullName $relative
        if (Test-Path -LiteralPath $candidate) {
            $autoResearchCandidates.Add((Get-Item -LiteralPath $candidate))
        }
    }
}
$latestAutoResearch = $autoResearchCandidates |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if ($null -eq $latestAutoResearch) {
    throw "Missing auto-research results under D:\sqlancer\coverage\sqlite"
}
$autoResearchResults = $latestAutoResearch.FullName
if (-not (Test-Path -LiteralPath $autoResearchResults)) {
    throw "Missing auto-research results: $autoResearchResults"
}
$egraphInputFiles = New-Object System.Collections.Generic.List[string]
$egraphInputFiles.Add($egraphInputFile)
$highCoverageInputStatus = "missing: $highCoverageCorpus"
if (Test-Path -LiteralPath $highCoverageCorpus) {
    $egraphInputFiles.Add($highCoverageCorpus)
    $highCoverageInputStatus = "included: $highCoverageCorpus"
}
$autoResearchCorpusStatus = "disabled with -NoAutoResearchCorpus; auto research still guides wrappers via results CSV"
if (-not $NoAutoResearchCorpus) {
    if (Test-Path -LiteralPath $autoResearchCorpus) {
        $egraphInputFiles.Add($autoResearchCorpus)
        $autoResearchCorpusStatus = "included: $autoResearchCorpus"
    } else {
        $autoResearchCorpusStatus = "missing: $autoResearchCorpus"
    }
}
$combinedEgraphInput = [string]::Join([System.IO.Path]::PathSeparator, $egraphInputFiles)

Write-Host "Run dir: $runDir"
Write-Host "Official EGRAPH input: $egraphInputFile"
Write-Host "Official EGRAPH variant-ready cases: $variantReadyCaseCount"
Write-Host "High-coverage corpus input: $highCoverageInputStatus"
Write-Host "Auto-research corpus input: $autoResearchCorpusStatus"
Write-Host "Auto-research results: $autoResearchResults"
Write-Host "Combined EGRAPH inputs: $combinedEgraphInput"
if ($TimeoutSeconds -gt 0) {
    Write-Host ("SQLancer will stop after {0} seconds ({1:N1} h)." -f $TimeoutSeconds, ($TimeoutSeconds / 3600))
} else {
    Write-Host "SQLancer will run without a time limit."
}
Write-Host "Corpus capture is interval-sampled (every 3rd case) so the recorded window spans the whole run."
Write-Host "Snapshots are delta encoded (full snapshot every 50 cases), which is what makes that density affordable."
Write-Host "Stop it with Ctrl+C, then run:"
Write-Host "powershell -ExecutionPolicy Bypass -File .\coverage\sqlite\finish-long-codecov.ps1 -ParallelWorkers 4"

$javaExe = (Get-Command java.exe -ErrorAction Stop).Source
$javaArgs = @()
# Without a ceiling the JVM takes a quarter of the machine and never gives it back, and the corpus
# reader holds every case it keeps. On a 16 GB machine that plus the file cache of a multi-GB corpus
# plus WSL, which the referee needs, is enough to put the system under memory pressure and have the
# run killed. A capture run is not heap-hungry - it streams the corpus and keeps maxQueries cases.
if (-not [string]::IsNullOrWhiteSpace($JavaHeapMax)) {
    $javaArgs += "-Xmx$JavaHeapMax"
}
# Split on commas as well as across array elements. powershell.exe -File does not turn
# `-ExtraJavaProps 'a','b'` into an array - it hands over the single string "a,b" - and a -D property
# glued to the next one is not rejected by the JVM, it silently becomes part of the first property's
# value. That cost a four-hour run: -Degraph.indexedPredicatePercent got the value
# "70,-Degraph.rtreeTargets=false" and SQLancer died in a static initialiser having written nothing.
foreach ($entry in $ExtraJavaProps) {
    if ([string]::IsNullOrWhiteSpace($entry)) { continue }
    foreach ($p in ($entry -split ",")) {
        if (-not [string]::IsNullOrWhiteSpace($p)) { $javaArgs += $p.Trim() }
    }
}
$javaArgs += @(
    "--enable-native-access=ALL-UNNAMED",
    "-Dsqlancer.statementTimeoutSeconds=15",
    "-Degraph.coverage.file=$runDir\workload-hints.txt",
    "-Degraph.replay.file=$runDir\replay-all.sql",
    "-Degraph.contextReplay.file=$runDir\replay-context.sql",
    "-Degraph.trace.file=$runDir\egraph-trace.log",
    "-Degraph.singleSideEmptyLog=$runDir\single-side-empty-reproducers.sql",
    "-Dsqlite3.egraph.input.maxQueries=$MaxCorpusQueries",
    "-Dsqlite3.egraph.input.maxCaseSetupStatements=80",
    "-Dsqlite3.egraph.corpus.maxAttemptsPerCheck=4",
    "-Dsqlite3.egraph.corpus.maxCases=200000",
    "-Dsqlite3.egraph.corpus.maxEmptyCases=20000",
    "-Dsqlite3.egraph.corpus.sampleInterval=3",
    "-Dsqlite3.egraph.corpus.keyframeInterval=50",
    # Pairs where the variant errored but the original ran. Not a bug report on its own - a deeper
    # rewritten tree can legitimately hit "expression tree is too large" - but the counter is what
    # surfaced the IS UNKNOWN and double-LIMIT defects, so keep capturing it.
    ("-Degraph.variantOnlyError.log=" + (Join-Path $runDir "variant-only-errors.log")),
    # Reproducers for the strongest judgment the oracle has: one side empty, the other not.
    "-Degraph.singleSideEmptyLog=$runDir\single-side-empty-reproducers.sql",
    "-Dsqlite3.egraph.corpus.maxRowsPerTable=128",
    "-Dsqlite3.egraph.contextReplay.maxStatements=4000",
    "-Dsqlite3.egraph.corpus.selectOnlyTemplates=true",
    "-Dsqlite3.egraph.baseSkeletons=true",
    "-Dsqlite3.egraph.autoResearchGuidedShapes=true",
    # Every mismatch goes to a build of SQLite's trunk before it is reported: one the trunk build
    # answers the same way on both queries is a defect upstream has already fixed, and the run is
    # left with what is new. The value is quoted because java's @argfile splits a line on spaces.
    # Doubled backslashes, then quoted. java's @argfile treats a backslash inside quotes as an
    # escape, so "D:\sqlancer\coverage\sqlite\trunk\sqlite3_trunk.exe" reached the JVM as
    # "D:sqlancercoveragesqlite" and the referee could not start a single time - which is what every
    # "referee could not answer" in the captures before this was.
    ("-Degraph.referee.command=""" + $RefereeCommand.Replace("\", "\\") + """"),
    "-Degraph.referee.log=$runDir\referee.sql",
    "-Degraph.knownBugs.log=$runDir\known-bugs.sql",
    "-Dsqlite3.egraph.autoResearchResults=$autoResearchResults",
    "-cp", $javaClasspath,
    "sqlancer.Main",
    "--num-threads=1",
    "--num-tries=100000",
    "--max-generated-databases=-1",
    "--num-queries=100000000",
    "--num-statement-kind-retries=3",
    "--timeout-seconds=$TimeoutSeconds",
    "--print-progress-information=true",
    "--print-progress-summary=true",
    "--log-each-select=true",
    "--egraph-log-each-select=false",
    "--egraph-url=http://127.0.0.1:3000",
    "--egraph-max-variants=16",
    "--egraph-timeout-millis=3000",
    "sqlite3",
    "--oracle=EGRAPH",
    "--egraph-input-file=$combinedEgraphInput"
)

$javaArgsFile = Join-Path $runDir "java-args.txt"
[System.IO.File]::WriteAllLines($javaArgsFile, $javaArgs, [System.Text.Encoding]::ASCII)

$exitCode = $null
try {
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $javaExe "@$javaArgsFile" *> (Join-Path $runDir "sqlancer.out.log")
    $exitCode = $LASTEXITCODE
} finally {
    if (Get-Variable -Name oldErrorActionPreference -Scope Local -ErrorAction SilentlyContinue) {
        $ErrorActionPreference = $oldErrorActionPreference
    }
    if (Test-Path -LiteralPath $logFile) {
        Copy-Item -LiteralPath $logFile -Destination (Join-Path $runDir "database0-cur.log") -Force
    }
}
Write-Host "SQLancer exit code: $exitCode"
Write-Host "Run dir: $runDir"
