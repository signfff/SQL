param(
    [string] $InputPath = "D:\sqlancer\coverage\sqlite\debug-one-egraph-20260828-172830\egraph-examples-report-v4-report.docx",
    [string] $OutputPath = "D:\sqlancer\coverage\sqlite\debug-one-egraph-20260828-172830\egraph-examples-report-v5-first-inserts.docx"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Escape-Xml {
    param([string] $Text)
    if ($null -eq $Text) {
        return ""
    }
    return [System.Security.SecurityElement]::Escape($Text)
}

function New-RunXml {
    param(
        [string] $Text,
        [string] $Font = "Microsoft YaHei",
        [int] $Size = 18,
        [bool] $Bold = $false,
        [string] $Color = "1F2937"
    )
    $boldXml = if ($Bold) { "<w:b/>" } else { "" }
    return "<w:r><w:rPr><w:rFonts w:ascii=`"$Font`" w:hAnsi=`"$Font`" w:eastAsia=`"$Font`"/><w:sz w:val=`"$Size`"/><w:color w:val=`"$Color`"/>$boldXml</w:rPr><w:t xml:space=`"preserve`">$(Escape-Xml $Text)</w:t></w:r>"
}

function New-CellXml {
    param(
        [string] $Text,
        [int] $Width,
        [bool] $Header = $false
    )
    $fill = if ($Header) { "<w:shd w:fill=`"334155`"/>" } else { "" }
    $color = if ($Header) { "FFFFFF" } else { "1F2937" }
    $bold = $Header
    $size = if ($Header) { 18 } else { 17 }
    $paragraphs = @()
    foreach ($line in (($Text -replace "`r`n", "`n") -split "`n")) {
        $paragraphs += "<w:p><w:pPr><w:spacing w:before=`"0`" w:after=`"30`" w:line=`"260`" w:lineRule=`"auto`"/></w:pPr>$(New-RunXml -Text $line -Size $size -Color $color -Bold $bold)</w:p>"
    }
    $cellBody = $paragraphs -join ""
    return "<w:tc><w:tcPr><w:tcW w:w=`"$Width`" w:type=`"dxa`"/>$fill<w:vAlign w:val=`"center`"/></w:tcPr>$cellBody</w:tc>"
}

function New-InsertedTableXml {
    $rows = @(
        @("0",  "NULL", "NULL", "NULL", "NULL 探测"),
        @("1",  "0.0",  "0",    "0.0",  "默认值 0"),
        @("2",  "1.0",  "1",    "1.0",  "默认值 1"),
        @("3",  "-1.0", "-1",   "-1.0", "默认值 -1"),
        @("4",  "0.0",  "0",    "0.0",  "默认值循环"),
        @("5",  "1.0",  "1",    "1.0",  "默认值循环"),
        @("6",  "-1.0", "-1",   "-1.0", "默认值循环"),
        @("7",  "0.0",  "0",    "0.0",  "默认值循环"),
        @("8",  "1.0",  "1",    "1.0",  "默认值循环"),
        @("9",  "-1.0", "-1",   "-1.0", "默认值循环"),
        @("10", "0.0",  "0",    "0.0",  "默认值循环"),
        @("11", "1.0",  "1",    "1.0",  "默认值循环"),
        @("12", "-1.0", "-1",   "-1.0", "默认值循环"),
        @("13", "0.0",  "0",    "0.0",  "默认值循环")
    )
    $widths = @(900, 1500, 1500, 1500, 3960)
    $headers = @("行号", "c0 REAL", "c1 INTEGER", "c2 REAL", "来源")
    $grid = ($widths | ForEach-Object { "<w:gridCol w:w=`"$_`"/>" }) -join ""
    $xml = New-Object System.Text.StringBuilder

    $headingRun = New-RunXml -Text "t0 插入数据明细（total_rows=14）" -Size 22 -Bold $true -Color "0369A1"
    [void] $xml.Append("<w:p xmlns:w=`"http://schemas.openxmlformats.org/wordprocessingml/2006/main`"><w:pPr><w:pStyle w:val=`"Heading2`"/><w:spacing w:before=`"160`" w:after=`"80`"/></w:pPr>$headingRun</w:p>")
    [void] $xml.Append("<w:tbl xmlns:w=`"http://schemas.openxmlformats.org/wordprocessingml/2006/main`"><w:tblPr><w:tblW w:w=`"9360`" w:type=`"dxa`"/><w:tblInd w:w=`"120`" w:type=`"dxa`"/><w:tblLayout w:type=`"fixed`"/><w:tblBorders><w:top w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:left w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:bottom w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:right w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:insideH w:val=`"single`" w:sz=`"4`" w:color=`"E2E8F0`"/><w:insideV w:val=`"single`" w:sz=`"4`" w:color=`"E2E8F0`"/></w:tblBorders><w:tblCellMar><w:top w:w=`"80`" w:type=`"dxa`"/><w:left w:w=`"120`" w:type=`"dxa`"/><w:bottom w:w=`"80`" w:type=`"dxa`"/><w:right w:w=`"120`" w:type=`"dxa`"/></w:tblCellMar></w:tblPr><w:tblGrid>$grid</w:tblGrid>")
    [void] $xml.Append("<w:tr>")
    for ($i = 0; $i -lt $headers.Count; $i++) {
        [void] $xml.Append((New-CellXml -Text $headers[$i] -Width $widths[$i] -Header $true))
    }
    [void] $xml.Append("</w:tr>")
    foreach ($row in $rows) {
        [void] $xml.Append("<w:tr>")
        for ($i = 0; $i -lt $headers.Count; $i++) {
            [void] $xml.Append((New-CellXml -Text ([string] $row[$i]) -Width $widths[$i]))
        }
        [void] $xml.Append("</w:tr>")
    }
    [void] $xml.Append("</w:tbl>")
    return $xml.ToString()
}

if (-not (Test-Path -LiteralPath $InputPath)) {
    throw "Input DOCX not found: $InputPath"
}

$inZip = [System.IO.Compression.ZipFile]::OpenRead($InputPath)
$entries = @()
try {
    foreach ($entry in $inZip.Entries) {
        $stream = $entry.Open()
        $memory = New-Object System.IO.MemoryStream
        try {
            $stream.CopyTo($memory)
            $entries += [pscustomobject]@{
                Name = $entry.FullName
                Bytes = $memory.ToArray()
            }
        } finally {
            $memory.Dispose()
            $stream.Dispose()
        }
    }
} finally {
    $inZip.Dispose()
}

$documentEntry = $entries | Where-Object { $_.Name -eq "word/document.xml" } | Select-Object -First 1
if ($null -eq $documentEntry) {
    throw "word/document.xml not found in $InputPath"
}

$documentXmlText = [System.Text.Encoding]::UTF8.GetString($documentEntry.Bytes)
[xml] $documentXml = $documentXmlText
$nsm = New-Object System.Xml.XmlNamespaceManager($documentXml.NameTable)
$nsm.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
$tables = $documentXml.SelectNodes("//w:body/w:tbl", $nsm)

$target = $null
foreach ($table in $tables) {
    $text = (($table.SelectNodes(".//w:t", $nsm) | ForEach-Object { $_.'#text' }) -join "")
    if ($text.Contains("t0(c0 REAL, c1 INTEGER, c2 REAL)") -and $text.Contains("默认池") -and -not $text.Contains("512")) {
        $target = $table
        break
    }
}

if ($null -eq $target) {
    throw "Target table for the first unrecognized case was not found."
}

$fragment = $documentXml.CreateDocumentFragment()
$fragment.InnerXml = New-InsertedTableXml
$parent = $target.ParentNode
$anchor = $target
foreach ($child in @($fragment.ChildNodes)) {
    $inserted = $parent.InsertAfter($child, $anchor)
    $anchor = $inserted
}

$settings = New-Object System.Xml.XmlWriterSettings
$settings.Encoding = New-Object System.Text.UTF8Encoding($false)
$settings.OmitXmlDeclaration = $false
$settings.Indent = $false
$outMemory = New-Object System.IO.MemoryStream
$writer = [System.Xml.XmlWriter]::Create($outMemory, $settings)
try {
    $documentXml.Save($writer)
} finally {
    $writer.Close()
}
$newDocumentBytes = $outMemory.ToArray()
$outMemory.Dispose()

$parentDir = Split-Path -Parent $OutputPath
if ($parentDir -and -not (Test-Path -LiteralPath $parentDir)) {
    New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
}
Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue

$outZip = [System.IO.Compression.ZipFile]::Open($OutputPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($entry in $entries) {
        $newEntry = $outZip.CreateEntry($entry.Name)
        $stream = $newEntry.Open()
        try {
            if ($entry.Name -eq "word/document.xml") {
                $stream.Write($newDocumentBytes, 0, $newDocumentBytes.Length)
            } else {
                $stream.Write($entry.Bytes, 0, $entry.Bytes.Length)
            }
        } finally {
            $stream.Dispose()
        }
    }
} finally {
    $outZip.Dispose()
}

Write-Host "Updated DOCX written:"
Write-Host $OutputPath
