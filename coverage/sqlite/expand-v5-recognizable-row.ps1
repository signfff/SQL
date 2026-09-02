param(
    [string] $InputPath = "D:\sqlancer\coverage\sqlite\debug-one-egraph-20260828-172830\egraph-examples-report-v5-first-inserts.docx",
    [string] $OutputPath = "D:\sqlancer\coverage\sqlite\debug-one-egraph-20260828-172830\egraph-examples-report-v5-recognizable-expanded.docx"
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
        [int] $Size = 17,
        [bool] $Bold = $false,
        [string] $Color = "1F2937"
    )
    $boldXml = if ($Bold) { "<w:b/>" } else { "" }
    return "<w:r><w:rPr><w:rFonts w:ascii=`"$Font`" w:hAnsi=`"$Font`" w:eastAsia=`"$Font`"/><w:sz w:val=`"$Size`"/><w:color w:val=`"$Color`"/>$boldXml</w:rPr><w:t xml:space=`"preserve`">$(Escape-Xml $Text)</w:t></w:r>"
}

function New-CellBodyXml {
    param([string[]] $Lines)
    $paragraphs = @()
    foreach ($line in $Lines) {
        $paragraphs += "<w:p xmlns:w=`"http://schemas.openxmlformats.org/wordprocessingml/2006/main`"><w:pPr><w:spacing w:before=`"0`" w:after=`"45`" w:line=`"260`" w:lineRule=`"auto`"/></w:pPr>$(New-RunXml -Text $line)</w:p>"
    }
    return ($paragraphs -join "")
}

function Replace-CellBody {
    param(
        [xml] $Document,
        [System.Xml.XmlNamespaceManager] $NamespaceManager,
        [System.Xml.XmlElement] $Cell,
        [string[]] $Lines
    )
    $tcPr = $Cell.SelectSingleNode("./w:tcPr", $NamespaceManager)
    $nodes = @()
    foreach ($child in $Cell.ChildNodes) {
        if ($child -ne $tcPr) {
            $nodes += $child
        }
    }
    foreach ($node in $nodes) {
        [void] $Cell.RemoveChild($node)
    }
    $fragment = $Document.CreateDocumentFragment()
    $fragment.InnerXml = New-CellBodyXml -Lines $Lines
    foreach ($child in @($fragment.ChildNodes)) {
        [void] $Cell.AppendChild($child)
    }
}

function Read-ZipEntriesShared {
    param([string] $Path)
    $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite)
    $zip = [System.IO.Compression.ZipArchive]::new($fs, [System.IO.Compression.ZipArchiveMode]::Read, $false)
    $entries = @()
    try {
        foreach ($entry in $zip.Entries) {
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
        $zip.Dispose()
        $fs.Dispose()
    }
    return $entries
}

if (-not (Test-Path -LiteralPath $InputPath)) {
    throw "Input DOCX not found: $InputPath"
}

$entries = Read-ZipEntriesShared -Path $InputPath
$documentEntry = $entries | Where-Object { $_.Name -eq "word/document.xml" } | Select-Object -First 1
if ($null -eq $documentEntry) {
    throw "word/document.xml not found in $InputPath"
}

$documentXmlText = [System.Text.Encoding]::UTF8.GetString($documentEntry.Bytes)
[xml] $documentXml = $documentXmlText
$nsm = New-Object System.Xml.XmlNamespaceManager($documentXml.NameTable)
$nsm.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")

$firstTable = $documentXml.SelectNodes("//w:tbl", $nsm).Item(0)
if ($null -eq $firstTable) {
    throw "First table not found."
}

$targetRow = $null
foreach ($row in $firstTable.SelectNodes("./w:tr", $nsm)) {
    $cells = $row.SelectNodes("./w:tc", $nsm)
    if ($cells.Count -lt 3) {
        continue
    }
    $label = (($cells.Item(0).SelectNodes(".//w:t", $nsm) | ForEach-Object { $_.'#text' }) -join "")
    if ($label -eq "能识别") {
        $targetRow = $row
        break
    }
}
if ($null -eq $targetRow) {
    throw "Recognizable row was not found in the first table."
}

$targetCells = $targetRow.SelectNodes("./w:tc", $nsm)
Replace-CellBody -Document $documentXml -NamespaceManager $nsm -Cell $targetCells.Item(1) -Lines @(
    "数字：WHERE 中存在数字字面量、简单列-常量比较、BETWEEN、简单算术反推或列间约束。",
    "字符串：WHERE 中存在单引号文本字面量，且目标列是 TEXT 时，会把这些字符串作为候选值。",
    "BLOB：目前不做文本到 BLOB 的语义反推，主要按列类型走默认 BLOB 值。"
)
Replace-CellBody -Document $documentXml -NamespaceManager $nsm -Cell $targetCells.Item(2) -Lines @(
    "数字列：插入 n，并补 n-1/n+1；随机 AST 路径还会补比较边界、BETWEEN 中点/上下界、NULL、列间约束专用行。",
    "TEXT 列：插入 WHERE 提取出的字符串；若没有字符串，默认使用 '', 'abc', '42'。",
    "BLOB 列：当前默认补 NULL 和 X''；这不是把 'brain' 当字符串处理，而是 BLOB 类型的默认空二进制值。"
)

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
