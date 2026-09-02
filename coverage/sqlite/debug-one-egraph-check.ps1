param(
    [int] $TimeoutSeconds = 90,
    [int] $NumQueries = 50,
    [int] $RandomSeed = 1,
    [int] $MaxVariants = 3,
    [int] $ExamplesLimit = 5,
    [int] $TableRows = 20,
    [int] $ResultRows = 50,
    [string] $EGraphUrl = "http://127.0.0.1:3000",
    [switch] $IncludeAutoResearchCorpus,
    [switch] $NoAutoResearchCorpus
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Location "D:\sqlancer"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runDir = "D:\sqlancer\coverage\sqlite\debug-one-egraph-$stamp"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

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

$inputFiles = New-Object System.Collections.Generic.List[string]
$officialInput = "D:\sqlancer\coverage\sqlite\sqlite-official-select-only-variant-ready-corpus.sql"
$highCoverageCorpus = "D:\sqlancer\coverage\sqlite\high-coverage-egraph-corpus.sql"
$autoResearchCorpus = "D:\sqlancer\coverage\sqlite\auto-research-filtered-corpus.sql"
if ($IncludeAutoResearchCorpus -and $NoAutoResearchCorpus) {
    throw "Use either -IncludeAutoResearchCorpus or -NoAutoResearchCorpus, not both."
}

$officialInputStatus = "missing: $officialInput"
if (Test-Path -LiteralPath $officialInput) {
    $inputFiles.Add($officialInput)
    $officialInputStatus = "included: $officialInput"
}
$highCoverageInputStatus = "missing: $highCoverageCorpus"
if (Test-Path -LiteralPath $highCoverageCorpus) {
    $inputFiles.Add($highCoverageCorpus)
    $highCoverageInputStatus = "included: $highCoverageCorpus"
}
$autoResearchCorpusStatus = "disabled with -NoAutoResearchCorpus; auto research still guides wrappers via results CSV"
if (-not $NoAutoResearchCorpus) {
    if (Test-Path -LiteralPath $autoResearchCorpus) {
        $inputFiles.Add($autoResearchCorpus)
        $autoResearchCorpusStatus = "included: $autoResearchCorpus"
    } else {
        $autoResearchCorpusStatus = "missing: $autoResearchCorpus"
    }
}
if ($inputFiles.Count -eq 0) {
    throw "No EGRAPH input corpus files found."
}
$combinedEgraphInput = [string]::Join([System.IO.Path]::PathSeparator, $inputFiles)

$latestAutoResearch = Get-ChildItem -LiteralPath "D:\sqlancer\coverage\sqlite" -Directory |
    Where-Object {
        $_.Name -notlike "auto-research-smoke-*" -and
        (Test-Path -LiteralPath (Join-Path $_.FullName "auto-research-results.csv"))
    } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$autoResearchResults = $null
if ($null -ne $latestAutoResearch) {
    $autoResearchResults = Join-Path $latestAutoResearch.FullName "auto-research-results.csv"
}

$javaExe = (Get-Command java.exe -ErrorAction Stop).Source
$javaArgs = New-Object System.Collections.Generic.List[string]
$javaArgs.Add("--enable-native-access=ALL-UNNAMED")
$javaArgs.Add("-Dsqlancer.statementTimeoutSeconds=15")
$javaArgs.Add("-Degraph.monitor=true")
$javaArgs.Add("-Degraph.data.monitor=true")
$javaArgs.Add("-Degraph.coverage.file=$runDir\workload-hints.txt")
$javaArgs.Add("-Degraph.replay.file=$runDir\replay.sql")
$javaArgs.Add("-Degraph.trace.file=$runDir\egraph-trace.log")
$javaArgs.Add("-Degraph.examples.file=$runDir\egraph-examples.txt")
$javaArgs.Add("-Degraph.singleSideEmptyLog=$runDir\single-side-empty-reproducers.sql")
$javaArgs.Add("-Degraph.examples.limit=$ExamplesLimit")
$javaArgs.Add("-Degraph.examples.tableRows=$TableRows")
$javaArgs.Add("-Degraph.examples.resultRows=$ResultRows")
$javaArgs.Add("-Dsqlite3.egraph.input.maxQueries=60000")
$javaArgs.Add("-Dsqlite3.egraph.input.maxCaseSetupStatements=80")
$javaArgs.Add("-Dsqlite3.egraph.corpus.maxAttemptsPerCheck=8")
$javaArgs.Add("-Dsqlite3.egraph.corpus.maxCases=200")
$javaArgs.Add("-Dsqlite3.egraph.corpus.maxEmptyCases=0")
$javaArgs.Add("-Dsqlite3.egraph.corpus.selectOnlyTemplates=true")
$javaArgs.Add("-Dsqlite3.egraph.baseSkeletons=true")
if ($null -ne $autoResearchResults -and (Test-Path -LiteralPath $autoResearchResults)) {
    $javaArgs.Add("-Dsqlite3.egraph.autoResearchGuidedShapes=true")
    $javaArgs.Add("-Dsqlite3.egraph.autoResearchResults=$autoResearchResults")
} else {
    $javaArgs.Add("-Dsqlite3.egraph.autoResearchGuidedShapes=false")
}
$javaArgs.Add("-cp")
$javaArgs.Add($javaClasspath)
$javaArgs.Add("sqlancer.Main")
$javaArgs.Add("--num-threads=1")
$javaArgs.Add("--num-tries=1")
$javaArgs.Add("--max-generated-databases=1")
$javaArgs.Add("--num-queries=$NumQueries")
$javaArgs.Add("--num-statement-kind-retries=3")
$javaArgs.Add("--timeout-seconds=$TimeoutSeconds")
$javaArgs.Add("--random-seed=$RandomSeed")
$javaArgs.Add("--print-progress-information=true")
$javaArgs.Add("--print-progress-summary=true")
$javaArgs.Add("--log-each-select=true")
$javaArgs.Add("--egraph-log-each-select=true")
$javaArgs.Add("--egraph-url=$EGraphUrl")
$javaArgs.Add("--egraph-max-variants=$MaxVariants")
$javaArgs.Add("--egraph-timeout-millis=3000")
$javaArgs.Add("sqlite3")
$javaArgs.Add("--oracle=EGRAPH")
$javaArgs.Add("--egraph-input-file=$combinedEgraphInput")

$javaArgsFile = Join-Path $runDir "java-args.txt"
$consoleLog = Join-Path $runDir "console.log"
[System.IO.File]::WriteAllLines($javaArgsFile, $javaArgs, [System.Text.Encoding]::ASCII)

Write-Host "Debug run dir: $runDir"
Write-Host "Official EGRAPH input: $officialInputStatus"
Write-Host "High-coverage corpus input: $highCoverageInputStatus"
Write-Host "Auto-research corpus input: $autoResearchCorpusStatus"
if ($null -ne $autoResearchResults) {
    Write-Host "Auto-research results: $autoResearchResults"
} else {
    Write-Host "Auto-research results: missing; wrapper guidance disabled"
}
Write-Host "Combined EGRAPH inputs: $combinedEgraphInput"
Write-Host "Console log: $consoleLog"
Write-Host "Example log: $(Join-Path $runDir 'egraph-examples.txt')"
Write-Host "Trace log: $(Join-Path $runDir 'egraph-trace.log')"

$oldErrorActionPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = "Continue"
    & $javaExe "@$javaArgsFile" *> $consoleLog
    $exitCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $oldErrorActionPreference
}

Write-Host "SQLancer exit code: $exitCode"
Write-Host "Debug run dir: $runDir"
if (Test-Path -LiteralPath (Join-Path $runDir "egraph-examples.txt")) {
    Write-Host "Open example with:"
    Write-Host "Get-Content `"$runDir\egraph-examples.txt`""
} else {
    Write-Host "No egraph example was recorded. Increase -NumQueries or -TimeoutSeconds and rerun."
}
