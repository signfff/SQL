param(
    [switch] $IncludeAutoResearchCorpus,
    [switch] $NoAutoResearchCorpus,
    # Extra -D properties, e.g. -ExtraJavaProps '-Dsqlite3.egraph.deriveData=defaults'
    [string[]] $ExtraJavaProps = @(),
    # Suffix for the run directory so A/B runs are told apart at a glance
    [string] $RunTag = "",
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
$latestAutoResearch = Get-ChildItem -LiteralPath "D:\sqlancer\coverage\sqlite" -Directory |
    Where-Object {
        $_.Name -notlike "auto-research-smoke-*" -and
        (Test-Path -LiteralPath (Join-Path $_.FullName "auto-research-results.csv"))
    } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if ($null -eq $latestAutoResearch) {
    throw "Missing auto-research results under D:\sqlancer\coverage\sqlite"
}
$autoResearchResults = Join-Path $latestAutoResearch.FullName "auto-research-results.csv"
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
foreach ($p in $ExtraJavaProps) { if (-not [string]::IsNullOrWhiteSpace($p)) { $javaArgs += $p } }
$javaArgs += @(
    "--enable-native-access=ALL-UNNAMED",
    "-Dsqlancer.statementTimeoutSeconds=15",
    "-Degraph.coverage.file=$runDir\workload-hints.txt",
    "-Degraph.replay.file=$runDir\replay-all.sql",
    "-Degraph.contextReplay.file=$runDir\replay-context.sql",
    "-Degraph.trace.file=$runDir\egraph-trace.log",
    "-Degraph.singleSideEmptyLog=$runDir\single-side-empty-reproducers.sql",
    "-Dsqlite3.egraph.input.maxQueries=60000",
    "-Dsqlite3.egraph.input.maxCaseSetupStatements=80",
    "-Dsqlite3.egraph.corpus.maxAttemptsPerCheck=4",
    "-Dsqlite3.egraph.corpus.maxCases=200000",
    "-Dsqlite3.egraph.corpus.maxEmptyCases=20000",
    "-Dsqlite3.egraph.corpus.sampleInterval=3",
    "-Dsqlite3.egraph.corpus.keyframeInterval=50",
    "-Dsqlite3.egraph.corpus.maxRowsPerTable=128",
    "-Dsqlite3.egraph.contextReplay.maxStatements=4000",
    "-Dsqlite3.egraph.corpus.selectOnlyTemplates=true",
    "-Dsqlite3.egraph.baseSkeletons=true",
    "-Dsqlite3.egraph.autoResearchGuidedShapes=true",
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
    "--egraph-max-variants=3",
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
