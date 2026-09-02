param(
    [string] $OutputPath = "D:\sqlancer\coverage\sqlite\debug-one-egraph-20260828-172830\egraph-examples-report-v4-report.docx"
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

function Run {
    param(
        [string] $Text,
        [string] $Font = "Microsoft YaHei",
        [int] $Size = 21,
        [bool] $Bold = $false,
        [string] $Color = "1F2937"
    )
    $boldXml = if ($Bold) { "<w:b/>" } else { "" }
    return "<w:r><w:rPr><w:rFonts w:ascii=`"$Font`" w:hAnsi=`"$Font`" w:eastAsia=`"$Font`"/><w:sz w:val=`"$Size`"/><w:color w:val=`"$Color`"/>$boldXml</w:rPr><w:t xml:space=`"preserve`">$(Escape-Xml $Text)</w:t></w:r>"
}

function Paragraph {
    param(
        [string] $Text,
        [string] $Style = "Normal",
        [string] $Color = "1F2937",
        [bool] $Bold = $false
    )
    $styleXml = if ([string]::IsNullOrWhiteSpace($Style)) { "" } else { "<w:pStyle w:val=`"$Style`"/>" }
    return "<w:p><w:pPr>$styleXml</w:pPr>$(Run -Text $Text -Color $Color -Bold $Bold)</w:p>"
}

function CodeParagraph {
    param([string] $Text)
    return "<w:p><w:pPr><w:spacing w:before=`"40`" w:after=`"80`"/><w:shd w:fill=`"F8FAFC`"/><w:ind w:left=`"180`" w:right=`"180`"/></w:pPr>$(Run -Text $Text -Font "Consolas" -Size 17 -Color "111827")</w:p>"
}

function CellParagraphs {
    param(
        [string] $Text,
        [bool] $Header = $false,
        [bool] $Code = $false
    )
    $font = if ($Code) { "Consolas" } else { "Microsoft YaHei" }
    $size = if ($Code) { 16 } elseif ($Header) { 19 } else { 18 }
    $color = if ($Header) { "FFFFFF" } else { "1F2937" }
    $bold = $Header
    $parts = @()
    foreach ($line in (($Text -replace "`r`n", "`n") -split "`n")) {
        $parts += "<w:p><w:pPr><w:spacing w:before=`"0`" w:after=`"40`" w:line=`"280`" w:lineRule=`"auto`"/></w:pPr>$(Run -Text $line -Font $font -Size $size -Color $color -Bold $bold)</w:p>"
    }
    return ($parts -join "")
}

function TableXml {
    param(
        [string[]] $Headers,
        [object[]] $Rows,
        [int[]] $Widths,
        [bool[]] $CodeColumns = @()
    )
    $grid = ($Widths | ForEach-Object { "<w:gridCol w:w=`"$_`"/>" }) -join ""
    $xml = New-Object System.Text.StringBuilder
    [void] $xml.Append("<w:tbl><w:tblPr><w:tblW w:w=`"9360`" w:type=`"dxa`"/><w:tblInd w:w=`"120`" w:type=`"dxa`"/><w:tblLayout w:type=`"fixed`"/><w:tblBorders><w:top w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:left w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:bottom w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:right w:val=`"single`" w:sz=`"4`" w:color=`"CBD5E1`"/><w:insideH w:val=`"single`" w:sz=`"4`" w:color=`"E2E8F0`"/><w:insideV w:val=`"single`" w:sz=`"4`" w:color=`"E2E8F0`"/></w:tblBorders><w:tblCellMar><w:top w:w=`"80`" w:type=`"dxa`"/><w:left w:w=`"120`" w:type=`"dxa`"/><w:bottom w:w=`"80`" w:type=`"dxa`"/><w:right w:w=`"120`" w:type=`"dxa`"/></w:tblCellMar></w:tblPr><w:tblGrid>$grid</w:tblGrid>")

    [void] $xml.Append("<w:tr>")
    for ($i = 0; $i -lt $Headers.Count; $i++) {
        [void] $xml.Append("<w:tc><w:tcPr><w:tcW w:w=`"$($Widths[$i])`" w:type=`"dxa`"/><w:shd w:fill=`"334155`"/><w:vAlign w:val=`"center`"/></w:tcPr>$(CellParagraphs -Text $Headers[$i] -Header $true)</w:tc>")
    }
    [void] $xml.Append("</w:tr>")

    foreach ($row in $Rows) {
        [void] $xml.Append("<w:tr>")
        for ($i = 0; $i -lt $Headers.Count; $i++) {
            $text = [string] $row[$i]
            $isCode = $CodeColumns.Count -gt $i -and $CodeColumns[$i]
            [void] $xml.Append("<w:tc><w:tcPr><w:tcW w:w=`"$($Widths[$i])`" w:type=`"dxa`"/><w:vAlign w:val=`"center`"/></w:tcPr>$(CellParagraphs -Text $text -Code $isCode)</w:tc>")
        }
        [void] $xml.Append("</w:tr>")
    }
    [void] $xml.Append("</w:tbl>")
    return $xml.ToString()
}

function SectionBreak {
    return "<w:p><w:pPr><w:spacing w:after=`"120`"/></w:pPr></w:p>"
}

function Write-ZipEntry {
    param(
        [System.IO.Compression.ZipArchive] $Zip,
        [string] $Name,
        [string] $Content
    )
    $entry = $Zip.CreateEntry($Name)
    $stream = $entry.Open()
    $writer = [System.IO.StreamWriter]::new($stream, [System.Text.UTF8Encoding]::new($false))
    try {
        $writer.Write($Content)
    } finally {
        $writer.Close()
    }
}

$body = New-Object System.Text.StringBuilder

[void] $body.Append((Paragraph "SQLite EGRAPH 短测样例报告：补数策略对照" "Title" "0F172A" $true))
[void] $body.Append((Paragraph "目的：对照两个短测样例，说明补数逻辑何时只能使用默认值，何时可以从 WHERE 中提取出更有针对性的测试数据。" "Subtitle" "475569" $false))

[void] $body.Append((Paragraph "一、对照结论" "Heading1" "1D4ED8" $true))
[void] $body.Append((Paragraph "本报告只关注补数结果本身。t0 是主查询数据表；egraph_* 对象是 wrapper/context 辅助对象，用于构造执行上下文，下面不展开分析。"))
[void] $body.Append((TableXml `
    -Headers @("类别", "识别条件", "补数表现") `
    -Widths @(1500, 4260, 3600) `
    -Rows @(
        @("不能识别", "WHERE 中没有可直接提取的列-常量边界，或者表达式主要由列间运算、NULL、空字符串、布尔组合构成。", "t0 只能使用默认池：NULL、0、1、-1，并循环补齐到目标行数。"),
        @("能识别", "WHERE 中存在可提取的数字字面量或简单列-常量关系，例如 c0=512、c0*5。", "t0 会插入字面量本身，并补 n-1/n+1，因此会出现 512、511、513 这类针对性数据。")
    )))

[void] $body.Append((Paragraph "二、查询与判定对象" "Heading1" "1D4ED8" $true))
[void] $body.Append((TableXml `
    -Headers @("名称", "含义", "比较关系") `
    -Widths @(1500, 4900, 2960) `
    -Rows @(
        @("BASE", "送给 EGRAPH 的基础 SELECT。", "用于生成变体"),
        @("ORIGINAL", "SQLite 实际执行的原始查询。", "和每个 VARIANT 比结果集"),
        @("VARIANT", "EGRAPH 改写 WHERE 后得到的查询。", "行数不同、内容不同、或一边空一边非空，都应判为 mismatch")
    )))

[void] $body.Append((Paragraph "三、不能识别：只能使用默认值" "Heading1" "1D4ED8" $true))
[void] $body.Append((Paragraph "来源：RANDOM_GENERATED_1_3。这个例子的 WHERE 里没有可直接绑定到某一列的数字边界，因此数据生成器无法推导出类似 512、511、513 这样的针对性值，只能给每列补默认池。"))
[void] $body.Append((CodeParagraph "SELECT ALL * FROM t0 WHERE (((((((t0.c1) OR (''))) OR (((NULL)/(t0.c0))))) OR (((t0.c2)-(t0.c0))))) LIMIT 10;"))
[void] $body.Append((TableXml `
    -Headers @("表", "行数", "数据/含义") `
    -Widths @(2100, 900, 6360) `
    -Rows @(
        @("t0(c0 REAL, c1 INTEGER, c2 REAL)", "14", "第 0 行：NULL | NULL | NULL`n后续按默认值循环：0.0 | 0 | 0.0、1.0 | 1 | 1.0、-1.0 | -1 | -1.0`n原因：WHERE 没有识别出可反推的列边界，只能使用默认池 NULL/0/1/-1。"),
        @("egraph_multiselect_probe", "4", "辅助 wrapper/context 表；不参与补数判断，本例主要观察 t0 的数据。")
    )))
[void] $body.Append((TableXml `
    -Headers @("查询", "查到行数", "说明") `
    -Widths @(1500, 1100, 6760) `
    -Rows @(
        @("BASE", "8", "主查询在默认补数下仍然非空。"),
        @("ORIGINAL", "8", "套 egraph_multiselect_probe 的 EXISTS wrapper 后，结果不变。"),
        @("VARIANT #1/#2/#3", "均为 8", "EGRAPH 改写后和 ORIGINAL 一致，本例未发现 bug。")
    )))

[void] $body.Append((Paragraph "分析结论" "Heading2" "0369A1" $true))
[void] $body.Append((Paragraph "这类 WHERE 的核心问题是缺少明确的列-常量边界。表达式里虽然有列、NULL、空字符串和列间算术，但当前补数逻辑无法稳定反推出新的具体值，因此只能退回默认补数池。"))

[void] $body.Append((Paragraph "四、能识别：从 WHERE 字面量补出特殊值" "Heading1" "1D4ED8" $true))
[void] $body.Append((Paragraph "来源：CORPUS_OFFICIAL_SELECT_TEMPLATE。这个例子的 WHERE 直接包含数字 5 和 512，因此官方 SELECT 字符串路径可以抽取这些字面量，并补上下边界。"))
[void] $body.Append((CodeParagraph "SELECT `"c0`" FROM `"t0`" WHERE `"c0`" BETWEEN `"c0`" AND `"c0`"*5 OR `"c0`"=512 ORDER BY `"c0`";"))
[void] $body.Append((TableXml `
    -Headers @("来源", "补入 t0.c0 的值", "解释") `
    -Widths @(1900, 3000, 4460) `
    -Rows @(
        @("NULL 探测", "NULL", "覆盖 SQLite 三值逻辑、IS NULL、比较中 NULL 传播等行为。"),
        @("默认值", "0, 1, -1", "保证没有可用常量时也有基础数据；这里即使已有常量也会保留。"),
        @("WHERE 字面量", "5, 512", "5 来自 c0*5；512 来自 c0=512。"),
        @("边界邻居", "4, 6, 511, 513", "对每个识别到的数字 n，额外插入 n-1 和 n+1，用来覆盖等值、边界附近比较和 planner 分支。"),
        @("循环补齐", "5, 512, 0, 1", "目标行数至少 14 行，候选值不够时按候选池循环补齐。")
    )))
[void] $body.Append((TableXml `
    -Headers @("rowid", "t0.c0", "值的来源") `
    -Widths @(1000, 1800, 6560) `
    -Rows @(
        @("0", "NULL", "NULL 探测"),
        @("1", "5", "WHERE 字面量：c0*5"),
        @("2", "512", "WHERE 字面量：c0=512"),
        @("3", "0", "默认值"),
        @("4", "1", "默认值"),
        @("5", "-1", "默认值"),
        @("6", "4", "5 - 1"),
        @("7", "6", "5 + 1"),
        @("8", "511", "512 - 1"),
        @("9", "513", "512 + 1"),
        @("10-13", "5, 512, 0, 1", "循环补齐到 14 行")
    )))

[void] $body.Append((TableXml `
    -Headers @("查询", "查到行数", "说明") `
    -Widths @(1500, 1100, 6760) `
    -Rows @(
        @("BASE", "12", "只执行官方 SELECT 模板本身。"),
        @("ORIGINAL", "12", "套 egraph_alter_probe 的 EXISTS wrapper 后，结果不变。"),
        @("VARIANT #1", "12", "把 c0=512 对称改写为 512=c0，结果一致。"),
        @("VARIANT #2", "12", "规范化括号和比较表达式，结果一致。"),
        @("VARIANT #3", "12", "把 c0*5 改写为 5*c0，结果一致。")
    )))

[void] $body.Append((Paragraph "五、报告结论" "Heading1" "1D4ED8" $true))
[void] $body.Append((TableXml `
    -Headers @("问题", "当前行为", "含义") `
    -Widths @(2400, 3300, 3660) `
    -Rows @(
        @("没有可识别常量时", "通常补 NULL/0/1/-1，并按目标行数循环。", "能避免很多空表问题，但复杂 WHERE 的命中能力有限。"),
        @("有数字字面量时", "保留原值，并补 n-1/n+1。", "像 512 这种值可以被精准带入 t0，质量明显更高。"),
        @("bug 判定", "比较 ORIGINAL 和 VARIANT 的结果集。", "行数不同、内容不同、或一边空一边非空都应作为 mismatch 处理。")
    )))

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $($body.ToString())
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$stylesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault><w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:eastAsia="Microsoft YaHei"/><w:sz w:val="21"/><w:color w:val="1F2937"/></w:rPr></w:rPrDefault>
    <w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="300" w:lineRule="auto"/></w:pPr></w:pPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:after="120" w:line="300" w:lineRule="auto"/></w:pPr><w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:eastAsia="Microsoft YaHei"/><w:sz w:val="21"/><w:color w:val="1F2937"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:before="0" w:after="120"/></w:pPr><w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:eastAsia="Microsoft YaHei"/><w:b/><w:sz w:val="34"/><w:color w:val="0F172A"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:after="220"/></w:pPr><w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:eastAsia="Microsoft YaHei"/><w:sz w:val="21"/><w:color w:val="475569"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="280" w:after="140"/></w:pPr><w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:eastAsia="Microsoft YaHei"/><w:b/><w:sz w:val="28"/><w:color w:val="1D4ED8"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="200" w:after="100"/></w:pPr><w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:eastAsia="Microsoft YaHei"/><w:b/><w:sz w:val="24"/><w:color w:val="0369A1"/></w:rPr></w:style>
</w:styles>
"@

$contentTypes = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
"@

$rels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"@

$docRels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>
"@

$core = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>SQLite EGRAPH 短测样例报告：补数策略对照</dc:title>
  <dc:creator>SQLancer EGRAPH Report Generator</dc:creator>
  <cp:lastModifiedBy>SQLancer EGRAPH Report Generator</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$(Get-Date -Format s)Z</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$(Get-Date -Format s)Z</dcterms:modified>
</cp:coreProperties>
"@

$app = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>SQLancer</Application>
</Properties>
"@

$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
}
Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue

$zip = [System.IO.Compression.ZipFile]::Open($OutputPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    Write-ZipEntry -Zip $zip -Name "[Content_Types].xml" -Content $contentTypes
    Write-ZipEntry -Zip $zip -Name "_rels/.rels" -Content $rels
    Write-ZipEntry -Zip $zip -Name "word/document.xml" -Content $documentXml
    Write-ZipEntry -Zip $zip -Name "word/styles.xml" -Content $stylesXml
    Write-ZipEntry -Zip $zip -Name "word/_rels/document.xml.rels" -Content $docRels
    Write-ZipEntry -Zip $zip -Name "docProps/core.xml" -Content $core
    Write-ZipEntry -Zip $zip -Name "docProps/app.xml" -Content $app
} finally {
    $zip.Dispose()
}

Write-Host "Readable report written:"
Write-Host $OutputPath
