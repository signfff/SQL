param(
    [string] $InputPath = "D:\sqlancer\coverage\sqlite\debug-one-egraph-20260828-172830\egraph-examples-report-v5-first-inserts.docx",
    [string] $OutputPath = "D:\sqlancer\coverage\sqlite\debug-one-egraph-20260828-172830\egraph-examples-report-v6-blob-default.docx"
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

function New-ParagraphXml {
    param(
        [string] $Text,
        [string] $Style = "Normal",
        [int] $Size = 21,
        [string] $Color = "1F2937",
        [bool] $Bold = $false
    )
    $styleXml = if ([string]::IsNullOrWhiteSpace($Style)) { "" } else { "<w:pStyle w:val=`"$Style`"/>" }
    return "<w:p xmlns:w=`"http://schemas.openxmlformats.org/wordprocessingml/2006/main`"><w:pPr>$styleXml</w:pPr>$(New-RunXml -Text $Text -Size $Size -Color $Color -Bold $Bold)</w:p>"
}

function New-CodeParagraphXml {
    param([string] $Text)
    return "<w:p xmlns:w=`"http://schemas.openxmlformats.org/wordprocessingml/2006/main`"><w:pPr><w:spacing w:before=`"40`" w:after=`"80`"/><w:shd w:fill=`"F8FAFC`"/><w:ind w:left=`"180`" w:right=`"180`"/></w:pPr>$(New-RunXml -Text $Text -Font "Consolas" -Size 17 -Color "111827")</w:p>"
}

function New-CellXml {
    param(
        [string] $Text,
        [int] $Width,
        [bool] $Header = $false,
        [bool] $Code = $false
    )
    $fill = if ($Header) { "<w:shd w:fill=`"334155`"/>" } else { "" }
    $font = if ($Code) { "Consolas" } else { "Microsoft YaHei" }
    $color = if ($Header) { "FFFFFF" } else { "1F2937" }
    $bold = $Header
    $size = if ($Code) { 16 } elseif ($Header) { 18 } else { 17 }
    $paragraphs = @()
    foreach ($line in (($Text -replace "`r`n", "`n") -split "`n")) {
        $paragraphs += "<w:p><w:pPr><w:spacing w:before=`"0`" w:after=`"30`" w:line=`"260`" w:lineRule=`"auto`"/></w:pPr>$(New-RunXml -Text $line -Font $font -Size $size -Color $color -Bold $bold)</w:p>"
    }
    $body = $paragraphs -join ""
    return "<w:tc><w:tcPr><w:tcW w:w=`"$Width`" w:type=`"dxa`"/>$fill<w:vAlign w:val=`"center`"/></w:tcPr>$body</w:tc>"
}

function New-TableXml {
    param(
        [string[]] $Headers,
        [object[]] $Rows,
        [int[]] $Widths,
        [bool[]] $CodeColumns = @()
    )
    $grid = ($Widths | ForEach-Object { "<w:gridCol w:w=`"$_`"/>" }) -join ""
    $xml = New-Object System.Text.StringBuilder
    [void] $xml.Append("<w:tbl xmlns:w=`"http://schemas.openxmlformats.org/wordprocessingml/2006/main`"><w:tblPr><w:tblW w:w=`"9360`" w:type=`"dxa`"/><w:tblInd w:w=`"120`" w:type=`"dxa`"/><w:tblLayout w:type=`"fixed`"/><w:tblBorders><w:top w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:left w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:bottom w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:right w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:insideH w:val=`"single`" w:sz=`"4`" w:color=`"E2E8F0`"/><w:insideV w:val=`"single`" w:sz=`"4`" w:color=`"E2E8F0`"/></w:tblBorders><w:tblCellMar><w:top w:w=`"80`" w:type=`"dxa`"/><w:left w:w=`"120`" w:type=`"dxa`"/><w:bottom w:w=`"80`" w:type=`"dxa`"/><w:right w:w=`"120`" w:type=`"dxa`"/></w:tblCellMar></w:tblPr><w:tblGrid>$grid</w:tblGrid>")
    [void] $xml.Append("<w:tr>")
    for ($i = 0; $i -lt $Headers.Count; $i++) {
        [void] $xml.Append((New-CellXml -Text $Headers[$i] -Width $Widths[$i] -Header $true))
    }
    [void] $xml.Append("</w:tr>")
    foreach ($row in $Rows) {
        [void] $xml.Append("<w:tr>")
        for ($i = 0; $i -lt $Headers.Count; $i++) {
            $isCode = $CodeColumns.Count -gt $i -and $CodeColumns[$i]
            [void] $xml.Append((New-CellXml -Text ([string] $row[$i]) -Width $Widths[$i] -Code $isCode))
        }
        [void] $xml.Append("</w:tr>")
    }
    [void] $xml.Append("</w:tbl>")
    return $xml.ToString()
}

function New-BlobExampleXml {
    $section = New-Object System.Text.StringBuilder
    [void] $section.Append((New-ParagraphXml -Text "四、不能识别：BLOB 列默认补 X''" -Style "Heading1" -Size 28 -Color "1D4ED8" -Bold $true))
    [void] $section.Append((New-ParagraphXml -Text "来源：CORPUS_HIGH_COVERAGE。这个例子的主表只有一个 BLOB 列，WHERE 中虽然出现文本字面量 'brain'，但当前补数逻辑不会把它转换成 BLOB 候选值，因此 t0 使用 BLOB 默认补值。"))
    [void] $section.Append((New-CodeParagraphXml -Text "SELECT `"c0`", `"c0`", `"c0`" FROM `"t0`" WHERE +`"c0`">'brain';"))
    [void] $section.Append((New-TableXml `
        -Headers @("表", "行数", "数据/含义") `
        -Widths @(2100, 900, 6360) `
        -Rows @(
            @("t0(c0 BLOB)", "14", "第 0 行：NULL`n第 1-13 行：X''`n原因：WHERE 中没有可用于 BLOB 列的可反推边界，BLOB 列退回默认空 BLOB。"),
            @("辅助表", "多个", "辅助 wrapper/context 表；不参与补数判断。本轮选到 ATTACH wrapper，实际用于判定的是 egraph_attach_probe 的 EXISTS 条件。")
        )))
    $insertRows = @(
        @("0", "NULL", "NULL 探测"),
        @("1", "X''", "BLOB 默认值"),
        @("2", "X''", "BLOB 默认值"),
        @("3", "X''", "BLOB 默认值"),
        @("4", "X''", "BLOB 默认值"),
        @("5", "X''", "BLOB 默认值"),
        @("6", "X''", "BLOB 默认值"),
        @("7", "X''", "BLOB 默认值"),
        @("8", "X''", "BLOB 默认值"),
        @("9", "X''", "BLOB 默认值"),
        @("10", "X''", "BLOB 默认值"),
        @("11", "X''", "BLOB 默认值"),
        @("12", "X''", "BLOB 默认值"),
        @("13", "X''", "BLOB 默认值")
    )
    [void] $section.Append((New-ParagraphXml -Text "t0 插入数据明细（total_rows=14）" -Style "Heading2" -Size 22 -Color "0369A1" -Bold $true))
    [void] $section.Append((New-TableXml `
        -Headers @("行号", "c0 BLOB", "来源") `
        -Widths @(1000, 2100, 6260) `
        -Rows $insertRows `
        -CodeColumns @($false, $true, $false)))
    [void] $section.Append((New-TableXml `
        -Headers @("查询", "查到行数", "说明") `
        -Widths @(1500, 1100, 6760) `
        -Rows @(
            @("BASE", "13", "主查询排除了 NULL 行，13 个 X'' 行均返回。"),
            @("ORIGINAL", "13", "套 egraph_attach_probe 的 EXISTS wrapper 后，结果不变。"),
            @("VARIANT #1/#2", "均为 13", "EGRAPH 只调整括号或交换比较方向，结果与 ORIGINAL 一致，本例未触发 mismatch。")
        )))
    [void] $section.Append((New-ParagraphXml -Text "分析结论" -Style "Heading2" -Size 22 -Color "0369A1" -Bold $true))
    [void] $section.Append((New-ParagraphXml -Text "这个样例说明，默认补数不只包含数值列的 NULL/0/1/-1；当目标列是 BLOB 时，当前会补空 BLOB X''。不过它也暴露出一个限制：文本字面量 'brain' 没有被转化成更丰富的 BLOB 测试值，因此该类输入目前仍属于识别能力较弱的默认补值场景。"))
    return $section.ToString()
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
$body = $documentXml.SelectSingleNode("//w:body", $nsm)

foreach ($p in $body.SelectNodes("./w:p", $nsm)) {
    $text = (($p.SelectNodes(".//w:t", $nsm) | ForEach-Object { $_.'#text' }) -join "")
    if ($text -eq "四、能识别：从 WHERE 字面量补出特殊值") {
        foreach ($t in $p.SelectNodes(".//w:t", $nsm)) {
            $t.InnerText = $t.InnerText.Replace("四、", "五、")
        }
    } elseif ($text -eq "五、报告结论") {
        foreach ($t in $p.SelectNodes(".//w:t", $nsm)) {
            $t.InnerText = $t.InnerText.Replace("五、", "六、")
        }
    }
}

$insertBefore = $null
foreach ($node in $body.ChildNodes) {
    if ($node.LocalName -eq "p") {
        $text = (($node.SelectNodes(".//w:t", $nsm) | ForEach-Object { $_.'#text' }) -join "")
        if ($text -eq "五、能识别：从 WHERE 字面量补出特殊值") {
            $insertBefore = $node
            break
        }
    }
}
if ($null -eq $insertBefore) {
    throw "Insertion point not found."
}

$fragment = $documentXml.CreateDocumentFragment()
$fragment.InnerXml = New-BlobExampleXml
$nodesToInsert = @()
foreach ($child in $fragment.ChildNodes) {
    $nodesToInsert += $child
}
foreach ($child in $nodesToInsert) {
    [void] $body.InsertBefore($child, $insertBefore)
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
