param(
    [string] $InputFile = "D:\sqlancer\coverage\sqlite\sqlite-official-egraph-filtered-corpus.sql",
    [string] $OutputFile = "D:\sqlancer\coverage\sqlite\egraph-acceptance-profile.csv",
    [string] $EGraphUrl = "http://127.0.0.1:3000",
    [int] $MaxCases = 0,
    [int] $MaxVariants = 3,
    [int] $TimeoutSec = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Convert-ToOneLine {
    param(
        [string] $Text,
        [int] $MaxLength = 1000
    )
    if ($null -eq $Text) {
        return ""
    }
    $result = ($Text.Trim() -replace '\s+', ' ')
    if ($result.Length -gt $MaxLength) {
        return $result.Substring(0, $MaxLength - 3) + "..."
    }
    return $result
}

function Get-SourceFromLine {
    param([string] $Line)
    if ($Line -match '^--\s*EGRAPH_CORPUS_CASE_BEGIN\s+source=(.*)$') {
        return $Matches[1].Trim()
    }
    return ""
}

function Read-EGraphCorpusCases {
    param([string] $Path)
    $cases = New-Object System.Collections.Generic.List[object]
    $sourceLine = ""
    $setupText = New-Object System.Text.StringBuilder
    $queryText = New-Object System.Text.StringBuilder
    $inCase = $false
    $inSetup = $false
    $inQuery = $false
    $caseIndex = 0

    foreach ($line in [System.IO.File]::ReadLines($Path)) {
        $trimmed = $line.Trim()
        if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_BEGIN")) {
            $sourceLine = $trimmed
            [void] $setupText.Clear()
            [void] $queryText.Clear()
            $inCase = $true
            $inSetup = $false
            $inQuery = $false
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
        if ($trimmed -eq "-- EGRAPH_CORPUS_CASE_END") {
            $caseIndex++
            $query = $queryText.ToString().Trim()
            if (-not [string]::IsNullOrWhiteSpace($query)) {
                $cases.Add([pscustomobject]@{
                    CaseIndex = $caseIndex
                    Source = Get-SourceFromLine -Line $sourceLine
                    Query = $query
                }) | Out-Null
            }
            if ($MaxCases -gt 0 -and $cases.Count -ge $MaxCases) {
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
    return $cases
}

function Get-FeatureTags {
    param([string] $Query)
    $q = Convert-ToOneLine -Text $Query -MaxLength 100000
    $features = New-Object System.Collections.Generic.List[string]
    if ($q -match '\bSELECT\s+DISTINCT\b') { [void] $features.Add("DISTINCT") }
    if ($q -match '\bSELECT\s+ALL\b') { [void] $features.Add("SELECT_ALL") }
    if ($q -match '\bORDER\s+BY\b') { [void] $features.Add("ORDER_BY") }
    if ($q -match '\bLIMIT\b') { [void] $features.Add("LIMIT") }
    if ($q -match '\bOFFSET\b') { [void] $features.Add("OFFSET") }
    if ($q -match '\bGROUP\s+BY\b') { [void] $features.Add("GROUP_BY") }
    if ($q -match '\bHAVING\b') { [void] $features.Add("HAVING") }
    if ($q -match '\bJOIN\b') { [void] $features.Add("JOIN") }
    if ($q -match '\bUNION\b|\bINTERSECT\b|\bEXCEPT\b') { [void] $features.Add("COMPOUND") }
    if ($q -match '\bWITH\b') { [void] $features.Add("WITH") }
    if ($q -match '\bEXISTS\s*\(') { [void] $features.Add("EXISTS") }
    if ($q -match '\(\s*SELECT\b') { [void] $features.Add("SUBQUERY") }
    if ($q -match '\bBETWEEN\b') { [void] $features.Add("BETWEEN") }
    if ($q -match '\bIS\s+NULL\b') { [void] $features.Add("IS_NULL") }
    if ($q -match '\bIS\s+NOT\s+NULL\b|\bNOTNULL\b') { [void] $features.Add("IS_NOT_NULL") }
    if ($q -match '\bIS\s+TRUE\b|\bIS\s+FALSE\b|\bIS\s+UNKNOWN\b') { [void] $features.Add("IS_BOOL") }
    if ($q -match '\bLIKE\b') { [void] $features.Add("LIKE") }
    if ($q -match '\bGLOB\b') { [void] $features.Add("GLOB") }
    if ($q -match '\bIN\s*\(') { [void] $features.Add("IN") }
    if ($q -match '\bCOLLATE\b') { [void] $features.Add("COLLATE") }
    if ($q -match '<>|!=|>=|<=|(?<![<>=!])=(?![=])|(?<![<>=])<(?![=])|(?<![<>=])>(?![=])') { [void] $features.Add("COMPARE") }
    if ($q -match '\s[+*/%]\s|[\w)"'']\s-\s[\w("''-]') { [void] $features.Add("ARITHMETIC") }
    if ($q -match '\bAND\b') { [void] $features.Add("AND") }
    if ($q -match '\bOR\b') { [void] $features.Add("OR") }
    if ($q -match '\bNOT\b') { [void] $features.Add("NOT") }
    if ($q -match '\|\|') { [void] $features.Add("CONCAT") }
    if ($q -match '\bCASE\b') { [void] $features.Add("CASE") }
    if ($q -match '\bCAST\s*\(') { [void] $features.Add("CAST") }
    if ($q -match '\b[A-Z_][A-Z0-9_]*\s*\(') { [void] $features.Add("FUNCTION_CALL") }
    return ($features -join ";")
}

function Invoke-JsonPost {
    param(
        [string] $Uri,
        [string] $Body,
        [int] $TimeoutSeconds
    )
    $request = [System.Net.WebRequest]::Create($Uri)
    $request.Method = "POST"
    $request.ContentType = "application/json"
    $request.Timeout = $TimeoutSeconds * 1000
    $request.ReadWriteTimeout = $TimeoutSeconds * 1000
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
    $request.ContentLength = $bytes.Length
    $stream = $request.GetRequestStream()
    try {
        $stream.Write($bytes, 0, $bytes.Length)
    } finally {
        $stream.Dispose()
    }

    $response = $null
    try {
        $response = $request.GetResponse()
    } catch [System.Net.WebException] {
        $response = $_.Exception.Response
        if ($null -eq $response) {
            throw
        }
    }
    try {
        $reader = New-Object System.IO.StreamReader($response.GetResponseStream(), [System.Text.Encoding]::UTF8)
        try {
            $content = $reader.ReadToEnd()
        } finally {
            $reader.Dispose()
        }
        return [pscustomobject]@{
            StatusCode = [int] $response.StatusCode
            Content = $content
        }
    } finally {
        $response.Dispose()
    }
}

function Get-JsonPropertyValue {
    param(
        [object] $Object,
        [string] $Name
    )
    if ($null -eq $Object) {
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

function Invoke-EGraphGenerate {
    param([string] $Query)
    $endpoint = $EGraphUrl.TrimEnd("/") + "/generate-variants"
    $queryBytes = [System.Text.Encoding]::UTF8.GetBytes($Query)
    $body = @{
        query_base64 = [Convert]::ToBase64String($queryBytes)
        max_variants = $MaxVariants
    } | ConvertTo-Json -Compress
    $response = Invoke-JsonPost -Uri $endpoint -Body $body -TimeoutSeconds $TimeoutSec
    $json = $null
    try {
        $json = $response.Content | ConvertFrom-Json
    } catch {
        return [pscustomobject]@{
            Status = "malformed-response"
            VariantCount = 0
            HttpStatus = $response.StatusCode
            Error = Convert-ToOneLine -Text $response.Content -MaxLength 1000
            FirstVariant = ""
        }
    }
    $variants = @()
    $variantValue = Get-JsonPropertyValue -Object $json -Name "variants"
    if ($null -ne $variantValue) {
        $variants = @($variantValue)
    }
    $errorText = ""
    $errorValue = Get-JsonPropertyValue -Object $json -Name "error"
    if ($null -ne $errorValue) {
        $errorText = [string] $errorValue
    }
    $status = "accepted"
    if ($response.StatusCode -ne 200) {
        $status = "server-error"
    } elseif (-not [string]::IsNullOrWhiteSpace($errorText)) {
        $status = "server-error"
    } elseif ($variants.Count -eq 0) {
        $status = "zero-variant"
    }
    $firstVariant = ""
    if ($variants.Count -gt 0 -and $null -ne $variants[0]) {
        $firstVariant = [string] $variants[0]
    }
    return [pscustomobject]@{
        Status = $status
        VariantCount = $variants.Count
        HttpStatus = $response.StatusCode
        Error = Convert-ToOneLine -Text $errorText -MaxLength 1000
        FirstVariant = $firstVariant
    }
}

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input corpus not found: $InputFile"
}
if ($MaxVariants -le 0) {
    throw "MaxVariants must be positive."
}
if ($TimeoutSec -le 0) {
    throw "TimeoutSec must be positive."
}

try {
    [void] (Invoke-EGraphGenerate -Query "SELECT * FROM t0 WHERE c0 = 1")
} catch {
    throw "EGRAPH server is not reachable at $EGraphUrl. Start egraph-server first. Detail: $($_.Exception.Message)"
}

$cases = @(Read-EGraphCorpusCases -Path $InputFile)
if ($cases.Count -eq 0) {
    throw "No EGRAPH corpus cases found in $InputFile"
}

$rows = New-Object System.Collections.Generic.List[object]
$processed = 0
foreach ($case in $cases) {
    $processed++
    $query = [string] $case.Query
    $profile = Invoke-EGraphGenerate -Query $query
    $rows.Add([pscustomobject]@{
        CaseIndex = $case.CaseIndex
        Source = $case.Source
        Status = $profile.Status
        VariantCount = $profile.VariantCount
        HttpStatus = $profile.HttpStatus
        Error = $profile.Error
        Features = Get-FeatureTags -Query $query
        Query = Convert-ToOneLine -Text $query -MaxLength 2000
        FirstVariant = Convert-ToOneLine -Text $profile.FirstVariant -MaxLength 2000
    }) | Out-Null
    if ($processed % 25 -eq 0) {
        Write-Host "Profiled $processed / $($cases.Count) cases..."
    }
}

$outDir = Split-Path -Parent $OutputFile
if (-not [string]::IsNullOrWhiteSpace($outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}
$rows | Export-Csv -LiteralPath $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "EGRAPH acceptance profile written: $OutputFile"
Write-Host "Cases profiled: $($rows.Count)"
$rows | Group-Object Status | Sort-Object Name | ForEach-Object {
    Write-Host ("{0}: {1}" -f $_.Name, $_.Count)
}
