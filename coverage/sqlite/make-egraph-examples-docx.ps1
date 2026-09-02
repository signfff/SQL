param(
    [string]$InputPath = ".\coverage\sqlite\debug-one-egraph-20260828-172830\egraph-examples.txt",
    [string]$OutputPath = "",
    [int]$MaxResultRowsPerQuery = 8,
    [int]$MaxSampleRowsPerTable = 14
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function U([string]$Text) {
    return [System.Text.RegularExpressions.Regex]::Replace($Text, "\\u([0-9A-Fa-f]{4})", {
        param($m)
        return [string][char][Convert]::ToInt32($m.Groups[1].Value, 16)
    })
}

function X([string]$Text) {
    if ($null -eq $Text) {
        return ""
    }
    return [System.Security.SecurityElement]::Escape($Text)
}

function LinesFrom([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }
    return @($Text -split "`r?`n" | Where-Object { $_.Trim().Length -gt 0 })
}

function New-Cell([string[]]$Lines, [int]$Width, [bool]$Header, [bool]$Code) {
    $fill = ""
    if ($Header) {
        $fill = '<w:shd w:fill="F2F4F7"/>'
    }
    $paragraphs = New-Object System.Collections.Generic.List[string]
    if ($null -eq $Lines -or $Lines.Count -eq 0) {
        $Lines = @("")
    }
    foreach ($line in $Lines) {
        $font = "Calibri"
        $eastAsiaFont = "Microsoft YaHei"
        $size = "18"
        if ($Code) {
            $font = "Consolas"
            $size = "16"
        }
        $boldOpen = ""
        if ($Header) {
            $boldOpen = "<w:b/>"
        }
        $paragraphs.Add("<w:p><w:pPr><w:spacing w:after=`"0`" w:line=`"240`" w:lineRule=`"auto`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"$font`" w:hAnsi=`"$font`" w:eastAsia=`"$eastAsiaFont`"/>$boldOpen<w:sz w:val=`"$size`"/><w:szCs w:val=`"$size`"/></w:rPr><w:t xml:space=`"preserve`">$(X $line)</w:t></w:r></w:p>")
    }
    return "<w:tc><w:tcPr><w:tcW w:w=`"$Width`" w:type=`"dxa`"/>$fill<w:vAlign w:val=`"top`"/></w:tcPr>$($paragraphs -join '')</w:tc>"
}

function New-Table([object[]]$Rows, [int[]]$Widths, [bool]$CodeBody = $false) {
    if ($Rows.Count -eq 0) {
        return ""
    }
    $grid = ($Widths | ForEach-Object { "<w:gridCol w:w=`"$_`"/>" }) -join ""
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("<w:tbl><w:tblPr><w:tblW w:w=`"9360`" w:type=`"dxa`"/><w:tblInd w:w=`"120`" w:type=`"dxa`"/><w:tblBorders><w:top w:val=`"single`" w:sz=`"4`" w:space=`"0`" w:color=`"D0D7DE`"/><w:left w:val=`"single`" w:sz=`"4`" w:space=`"0`" w:color=`"D0D7DE`"/><w:bottom w:val=`"single`" w:sz=`"4`" w:space=`"0`" w:color=`"D0D7DE`"/><w:right w:val=`"single`" w:sz=`"4`" w:space=`"0`" w:color=`"D0D7DE`"/><w:insideH w:val=`"single`" w:sz=`"4`" w:space=`"0`" w:color=`"D0D7DE`"/><w:insideV w:val=`"single`" w:sz=`"4`" w:space=`"0`" w:color=`"D0D7DE`"/></w:tblBorders><w:tblCellMar><w:top w:w=`"80`" w:type=`"dxa`"/><w:left w:w=`"120`" w:type=`"dxa`"/><w:bottom w:w=`"80`" w:type=`"dxa`"/><w:right w:w=`"120`" w:type=`"dxa`"/></w:tblCellMar></w:tblPr><w:tblGrid>$grid</w:tblGrid>")
    for ($r = 0; $r -lt $Rows.Count; $r++) {
        $isHeader = ($r -eq 0)
        $row = @($Rows[$r])
        [void]$sb.Append("<w:tr>")
        for ($c = 0; $c -lt $Widths.Count; $c++) {
            $value = ""
            if ($c -lt $row.Count -and $null -ne $row[$c]) {
                $value = [string]$row[$c]
            }
            $lines = LinesFrom $value
            [void]$sb.Append((New-Cell $lines $Widths[$c] $isHeader ($CodeBody -and -not $isHeader)))
        }
        [void]$sb.Append("</w:tr>")
    }
    [void]$sb.Append("</w:tbl>")
    return $sb.ToString()
}

function New-Paragraph([string]$Text, [string]$Style = "", [bool]$Code = $false) {
    $pStyle = ""
    if ($Style.Length -gt 0) {
        $pStyle = "<w:pPr><w:pStyle w:val=`"$Style`"/><w:spacing w:after=`"120`"/></w:pPr>"
    } else {
        $pStyle = "<w:pPr><w:spacing w:after=`"120`"/></w:pPr>"
    }
    $font = "Calibri"
    $eastAsiaFont = "Microsoft YaHei"
    $size = "21"
    if ($Code) {
        $font = "Consolas"
        $size = "17"
    }
    return "<w:p>$pStyle<w:r><w:rPr><w:rFonts w:ascii=`"$font`" w:hAnsi=`"$font`" w:eastAsia=`"$eastAsiaFont`"/><w:sz w:val=`"$size`"/><w:szCs w:val=`"$size`"/></w:rPr><w:t xml:space=`"preserve`">$(X $Text)</w:t></w:r></w:p>"
}

function Parse-Schema([string]$Body) {
    $items = New-Object System.Collections.Generic.List[object]
    $current = $null
    foreach ($line in ($Body -split "`r?`n")) {
        if ($line -match '^--\s+(\S+)\s+(.+)\s*$') {
            if ($null -ne $current) {
                $items.Add($current)
            }
            $current = [ordered]@{ Type = $matches[1]; Name = $matches[2]; Sql = New-Object System.Collections.Generic.List[string] }
        } elseif ($null -ne $current -and $line.Trim().Length -gt 0) {
            $current.Sql.Add($line.Trim())
        }
    }
    if ($null -ne $current) {
        $items.Add($current)
    }
    return $items.ToArray()
}

function Parse-SampleTables([string]$Body) {
    $tables = New-Object System.Collections.Generic.List[object]
    $current = $null
    foreach ($line in ($Body -split "`r?`n")) {
        if ($line -match '^--\s+table\s+(.+?)\s+total_rows=(\d+)\s*$') {
            if ($null -ne $current) {
                $tables.Add($current)
            }
            $current = [ordered]@{ Name = $matches[1]; TotalRows = [int]$matches[2]; Rows = New-Object System.Collections.Generic.List[string] }
        } elseif ($null -ne $current -and $line.Trim().Length -gt 0) {
            $current.Rows.Add($line.Trim())
        }
    }
    if ($null -ne $current) {
        $tables.Add($current)
    }
    return $tables.ToArray()
}

function Parse-Examples([string]$Text) {
    $examples = New-Object System.Collections.Generic.List[object]
    $rx = [regex]::new('(?ms)^=+\r?\nEGRAPH EXAMPLE #(\d+)\r?\n=+\r?\n(.*?)(?=^=+\r?\nEGRAPH EXAMPLE #|\z)')
    foreach ($m in $rx.Matches($Text)) {
        $ex = [ordered]@{
            Id = [int]$m.Groups[1].Value
            Source = ""
            Schema = @()
            Tables = @()
            Queries = [ordered]@{}
        }
        $sectionRx = [regex]::new('(?ms)^\[([^\]]+)\]\r?\n(.*?)(?=^\[[^\]]+\]\r?\n|\z)')
        foreach ($sm in $sectionRx.Matches($m.Groups[2].Value)) {
            $name = $sm.Groups[1].Value.Trim()
            $body = $sm.Groups[2].Value.Trim()
            if ($name -eq "SOURCE") {
                $ex.Source = ($body -split "`r?`n" | Select-Object -First 1).Trim()
            } elseif ($name -eq "DATABASE SCHEMA") {
                $ex.Schema = Parse-Schema $body
            } elseif ($name -eq "DATABASE SAMPLE ROWS") {
                $ex.Tables = Parse-SampleTables $body
            } elseif ($name -eq "BASE QUERY SENT TO EGRAPH") {
                $ex.Queries["BASE"] = [ordered]@{ Label = "BASE"; Sql = $body; Rows = $null; Samples = @() }
            } elseif ($name -eq "ORIGINAL QUERY EXECUTED BY SQLITE") {
                $ex.Queries["ORIGINAL"] = [ordered]@{ Label = "ORIGINAL"; Sql = $body; Rows = $null; Samples = @() }
            } elseif ($name -match '^VARIANT #(\d+) QUERY EXECUTED BY SQLITE$') {
                $key = "VARIANT #$($matches[1])"
                $ex.Queries[$key] = [ordered]@{ Label = $key; Sql = $body; Rows = $null; Samples = @() }
            } elseif ($name -match '^BASE QUERY RESULT rows=(\d+)$') {
                if (-not $ex.Queries.Contains("BASE")) {
                    $ex.Queries["BASE"] = [ordered]@{ Label = "BASE"; Sql = ""; Rows = $null; Samples = @() }
                }
                $ex.Queries["BASE"].Rows = [int]$matches[1]
                $ex.Queries["BASE"].Samples = @(LinesFrom $body)
            } elseif ($name -match '^ORIGINAL RESULT rows=(\d+)$') {
                if (-not $ex.Queries.Contains("ORIGINAL")) {
                    $ex.Queries["ORIGINAL"] = [ordered]@{ Label = "ORIGINAL"; Sql = ""; Rows = $null; Samples = @() }
                }
                $ex.Queries["ORIGINAL"].Rows = [int]$matches[1]
                $ex.Queries["ORIGINAL"].Samples = @(LinesFrom $body)
            } elseif ($name -match '^VARIANT #(\d+) RESULT rows=(\d+)$') {
                $key = "VARIANT #$($matches[1])"
                if (-not $ex.Queries.Contains($key)) {
                    $ex.Queries[$key] = [ordered]@{ Label = $key; Sql = ""; Rows = $null; Samples = @() }
                }
                $ex.Queries[$key].Rows = [int]$matches[2]
                $ex.Queries[$key].Samples = @(LinesFrom $body)
            }
        }
        $examples.Add($ex)
    }
    return $examples.ToArray()
}

function Get-QueryRows([object]$Example, [string]$Key) {
    if ($Example.Queries.Contains($Key) -and $null -ne $Example.Queries[$Key].Rows) {
        return [string]$Example.Queries[$Key].Rows
    }
    return "-"
}

function Get-VariantRows([object]$Example) {
    $values = New-Object System.Collections.Generic.List[string]
    foreach ($key in $Example.Queries.Keys) {
        if ($key -like "VARIANT #*") {
            $values.Add("$key=$(Get-QueryRows $Example $key)")
        }
    }
    if ($values.Count -eq 0) {
        return "-"
    }
    return ($values -join "; ")
}

function Get-TableRowsSummary([object]$Example) {
    if ($Example.Tables.Count -eq 0) {
        return "-"
    }
    return (($Example.Tables | ForEach-Object { "$($_.Name)=$($_.TotalRows)" }) -join "; ")
}

function Get-QueryOutcomeNote([object]$Example) {
    $originalRows = Get-QueryRows $Example "ORIGINAL"
    $bad = New-Object System.Collections.Generic.List[string]
    foreach ($key in $Example.Queries.Keys) {
        if ($key -like "VARIANT #*") {
            $rows = Get-QueryRows $Example $key
            if ($rows -ne $originalRows) {
                $bad.Add("$key rows=$rows")
            }
        }
    }
    if ($bad.Count -eq 0) {
        return U "\u4e0e Original \u4e00\u81f4"
    }
    return (U "\u4e0e Original \u4e0d\u4e00\u81f4: ") + ($bad -join "; ")
}

function Extract-WorkloadSummary([string]$Path) {
    $summary = [ordered]@{}
    if (-not (Test-Path -LiteralPath $Path)) {
        return $summary
    }
    $text = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path), [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($text, 'Total checks:\s*(\d+)\s*\|\s*With variants:\s*(\d+)\s*\(([^)]+)\)')
    if ($m.Success) {
        $summary[(U "\u603b\u68c0\u67e5\u6570")] = $m.Groups[1].Value
        $summary[(U "\u6709\u53d8\u4f53\u68c0\u67e5")] = "$($m.Groups[2].Value) ($($m.Groups[3].Value))"
    }
    $m = [regex]::Match($text, 'Executed queries:\s*(\d+)\s*\|\s*Explained:\s*(\d+)\s*\|\s*Explain failures:\s*(\d+)')
    if ($m.Success) {
        $summary[(U "\u6267\u884c\u67e5\u8be2")] = $m.Groups[1].Value
        $summary["EXPLAIN"] = "explained=$($m.Groups[2].Value), failures=$($m.Groups[3].Value)"
    }
    $m = [regex]::Match($text, 'Original queries checked:\s*(\d+)\s*\|\s*Empty:\s*(\d+)\s*\(([^)]+)\)\s*\|\s*Non-empty:\s*(\d+)\s*\(([^)]+)\)')
    if ($m.Success) {
        $summary[(U "\u539f\u59cb\u67e5\u8be2\u7a7a\u7ed3\u679c")] = "$($m.Groups[2].Value) / $($m.Groups[1].Value) ($($m.Groups[3].Value))"
        $summary[(U "\u539f\u59cb\u67e5\u8be2\u975e\u7a7a")] = "$($m.Groups[4].Value) / $($m.Groups[1].Value) ($($m.Groups[5].Value))"
    }
    $m = [regex]::Match($text, 'Compared variant pairs:\s*(\d+)\s*\|\s*Both empty:\s*(\d+)\s*\(([^)]+)\)\s*\|\s*Both non-empty:\s*(\d+)\s*\(([^)]+)\)')
    if ($m.Success) {
        $summary[(U "\u5bf9\u6bd4\u53d8\u4f53\u5bf9")] = $m.Groups[1].Value
        $summary[(U "\u4e24\u8fb9\u5747\u7a7a")] = "$($m.Groups[2].Value) ($($m.Groups[3].Value))"
        $summary[(U "\u4e24\u8fb9\u5747\u975e\u7a7a")] = "$($m.Groups[4].Value) ($($m.Groups[5].Value))"
    }
    $m = [regex]::Match($text, 'Single-side empty mismatches \(bug candidates\):\s*original-only empty\s*(\d+)\s*\(([^)]+)\)\s*\|\s*variant-only empty\s*(\d+)\s*\(([^)]+)\)')
    if ($m.Success) {
        $summary[(U "\u5355\u8fb9\u7a7a\u4e0d\u4e00\u81f4\uff08BUG \u5019\u9009\uff09")] = "original-only=$($m.Groups[1].Value) ($($m.Groups[2].Value)); variant-only=$($m.Groups[3].Value) ($($m.Groups[4].Value))"
    } else {
        $m = [regex]::Match($text, 'Empty side in compared pairs:\s*original empty\s*(\d+)\s*\(([^)]+)\)\s*\|\s*variant empty\s*(\d+)\s*\(([^)]+)\)')
        if ($m.Success) {
            $summary[(U "\u5355\u8fb9\u7a7a\u4e0d\u4e00\u81f4\uff08BUG \u5019\u9009\uff09")] = "original-empty-side=$($m.Groups[1].Value) ($($m.Groups[2].Value)); variant-empty-side=$($m.Groups[3].Value) ($($m.Groups[4].Value))"
        }
    }
    return $summary
}

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path (Split-Path -Parent $resolvedInput) "egraph-examples-report.docx"
}
if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
} else {
    $resolvedOutput = [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $OutputPath))
}

$inputText = [System.IO.File]::ReadAllText($resolvedInput, [System.Text.Encoding]::UTF8)
$examples = Parse-Examples $inputText
if ($examples.Count -eq 0) {
    throw "No EGRAPH examples found in $resolvedInput"
}

$workloadPath = Join-Path (Split-Path -Parent $resolvedInput) "workload-hints.txt"
$workload = Extract-WorkloadSummary $workloadPath

$body = New-Object System.Text.StringBuilder
[void]$body.Append((New-Paragraph (U "SQLite EGRAPH \u77ed\u6d4b\u6837\u4f8b\u62a5\u544a") "Title"))
[void]$body.Append((New-Paragraph ((U "\u751f\u6210\u65f6\u95f4: ") + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))))

$metaRows = @(
    @((U "\u9879\u76ee"), (U "\u503c")),
    @((U "\u6e90\u6587\u4ef6"), [string]$resolvedInput),
    @((U "\u8fd0\u884c\u76ee\u5f55"), (Split-Path -Parent $resolvedInput)),
    @((U "\u6837\u4f8b\u6570"), [string]$examples.Count)
)
[void]$body.Append((New-Table $metaRows @(2100, 7260)))

if ($workload.Count -gt 0) {
    [void]$body.Append((New-Paragraph (U "\u5de5\u4f5c\u8d1f\u8f7d\u6458\u8981") "Heading1"))
    $rows = New-Object System.Collections.Generic.List[object]
    $rows.Add(@((U "\u9879\u76ee"), (U "\u503c")))
    foreach ($key in $workload.Keys) {
        $rows.Add(@([string]$key, [string]$workload[$key]))
    }
    [void]$body.Append((New-Table $rows.ToArray() @(3000, 6360)))
}

[void]$body.Append((New-Paragraph (U "\u6837\u4f8b\u603b\u89c8") "Heading1"))
$overview = New-Object System.Collections.Generic.List[object]
$overview.Add(@((U "\u6837\u4f8b"), (U "\u6765\u6e90"), (U "\u521d\u59cb\u8868\u884c\u6570"), (U "Base \u67e5\u5230"), (U "Original \u67e5\u5230"), (U "Variant \u67e5\u5230"), (U "\u8bf4\u660e")))
foreach ($ex in $examples) {
    $overview.Add(@(
        "#$($ex.Id)",
        $ex.Source,
        (Get-TableRowsSummary $ex),
        (Get-QueryRows $ex "BASE"),
        (Get-QueryRows $ex "ORIGINAL"),
        (Get-VariantRows $ex),
        (Get-QueryOutcomeNote $ex)
    ))
}
[void]$body.Append((New-Table $overview.ToArray() @(760, 1280, 2500, 760, 900, 1700, 1460)))

[void]$body.Append((New-Paragraph (U "\u6ce8: \u5224\u5b9a SQLite \u6f5c\u5728\u903b\u8f91\u9519\u8bef\u65f6\uff0c\u6838\u5fc3\u5bf9\u6bd4\u5bf9\u8c61\u662f Original Query \u4e0e Variant Query \u7684\u7ed3\u679c\u96c6\u3002Base Query \u662f\u9001\u5165 EGRAPH \u7684\u57fa\u7840\u8bed\u53e5\uff0c\u52a0 wrapper \u540e\u884c\u6570\u53ef\u80fd\u56e0 UNION ALL \u7b49\u5916\u5c42\u7ed3\u6784\u53d8\u5316\u3002")))

foreach ($ex in $examples) {
    [void]$body.Append((New-Paragraph ("Example #$($ex.Id) - $($ex.Source)") "Heading1"))

    [void]$body.Append((New-Paragraph (U "\u6570\u636e\u5e93\u5bf9\u8c61") "Heading2"))
    $schemaRows = New-Object System.Collections.Generic.List[object]
    $schemaRows.Add(@((U "\u7c7b\u578b"), (U "\u540d\u79f0"), "SQL / Definition"))
    foreach ($item in $ex.Schema) {
        $schemaRows.Add(@([string]$item.Type, [string]$item.Name, (($item.Sql | ForEach-Object { [string]$_ }) -join "`n")))
    }
    [void]$body.Append((New-Table $schemaRows.ToArray() @(1100, 2200, 6060) $true))

    [void]$body.Append((New-Paragraph (U "\u521d\u59cb\u8868\u6570\u636e") "Heading2"))
    $tableRows = New-Object System.Collections.Generic.List[object]
    $tableRows.Add(@((U "\u8868\u540d"), (U "\u603b\u884c\u6570"), (U "\u6837\u4f8b\u884c")))
    foreach ($t in $ex.Tables) {
        $rowsShown = @($t.Rows | Select-Object -First $MaxSampleRowsPerTable)
        $suffix = ""
        if ($t.Rows.Count -gt $rowsShown.Count) {
            $suffix = "`n... ($($t.Rows.Count - $rowsShown.Count) more sample rows omitted)"
        }
        $tableRows.Add(@([string]$t.Name, [string]$t.TotalRows, (($rowsShown | ForEach-Object { [string]$_ }) -join "`n") + $suffix))
    }
    [void]$body.Append((New-Table $tableRows.ToArray() @(2000, 1000, 6360) $true))

    [void]$body.Append((New-Paragraph (U "\u67e5\u8be2\u4e0e\u7ed3\u679c\u884c\u6570") "Heading2"))
    $queryRows = New-Object System.Collections.Generic.List[object]
    $queryRows.Add(@((U "\u67e5\u8be2"), (U "\u67e5\u5230\u884c\u6570"), "SQL"))
    foreach ($key in $ex.Queries.Keys) {
        $q = $ex.Queries[$key]
        $queryRows.Add(@([string]$q.Label, (Get-QueryRows $ex $key), [string]$q.Sql))
    }
    [void]$body.Append((New-Table $queryRows.ToArray() @(1300, 1100, 6960) $true))

    [void]$body.Append((New-Paragraph (U "\u7ed3\u679c\u6837\u672c") "Heading2"))
    $resultRows = New-Object System.Collections.Generic.List[object]
    $resultRows.Add(@((U "\u67e5\u8be2"), (U "\u67e5\u5230\u884c\u6570"), (U "\u7ed3\u679c\u884c\u6837\u672c")))
    foreach ($key in $ex.Queries.Keys) {
        $q = $ex.Queries[$key]
        $samples = @($q.Samples | Select-Object -First $MaxResultRowsPerQuery)
        $suffix = ""
        if ($q.Samples.Count -gt $samples.Count) {
            $suffix = "`n... ($($q.Samples.Count - $samples.Count) more result rows omitted)"
        }
        $sampleText = (($samples | ForEach-Object { [string]$_ }) -join "`n") + $suffix
        if ([string]::IsNullOrWhiteSpace($sampleText)) {
            $sampleText = "-"
        }
        $resultRows.Add(@([string]$q.Label, (Get-QueryRows $ex $key), $sampleText))
    }
    [void]$body.Append((New-Table $resultRows.ToArray() @(1300, 1100, 6960) $true))
}

$stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Microsoft YaHei"/>
      <w:sz w:val="21"/>
      <w:szCs w:val="21"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:after="240"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Microsoft YaHei"/>
      <w:b/>
      <w:color w:val="1F4E79"/>
      <w:sz w:val="32"/>
      <w:szCs w:val="32"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:keepNext/>
      <w:spacing w:before="240" w:after="120"/>
      <w:outlineLvl w:val="0"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Microsoft YaHei"/>
      <w:b/>
      <w:color w:val="1F4E79"/>
      <w:sz w:val="26"/>
      <w:szCs w:val="26"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:keepNext/>
      <w:spacing w:before="160" w:after="80"/>
      <w:outlineLvl w:val="1"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Microsoft YaHei"/>
      <w:b/>
      <w:color w:val="234061"/>
      <w:sz w:val="24"/>
      <w:szCs w:val="24"/>
    </w:rPr>
  </w:style>
</w:styles>
'@

$documentXml = "<?xml version=`"1.0`" encoding=`"UTF-8`" standalone=`"yes`"?><w:document xmlns:wpc=`"http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas`" xmlns:mc=`"http://schemas.openxmlformats.org/markup-compatibility/2006`" xmlns:o=`"urn:schemas-microsoft-com:office:office`" xmlns:r=`"http://schemas.openxmlformats.org/officeDocument/2006/relationships`" xmlns:m=`"http://schemas.openxmlformats.org/officeDocument/2006/math`" xmlns:v=`"urn:schemas-microsoft-com:vml`" xmlns:wp14=`"http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing`" xmlns:wp=`"http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing`" xmlns:w10=`"urn:schemas-microsoft-com:office:word`" xmlns:w=`"http://schemas.openxmlformats.org/wordprocessingml/2006/main`" xmlns:w14=`"http://schemas.microsoft.com/office/word/2010/wordml`" xmlns:wpg=`"http://schemas.microsoft.com/office/word/2010/wordprocessingGroup`" xmlns:wpi=`"http://schemas.microsoft.com/office/word/2010/wordprocessingInk`" xmlns:wne=`"http://schemas.microsoft.com/office/word/2006/wordml`" xmlns:wps=`"http://schemas.microsoft.com/office/word/2010/wordprocessingShape`" mc:Ignorable=`"w14 wp14`"><w:body>$($body.ToString())<w:sectPr><w:pgSz w:w=`"12240`" w:h=`"15840`"/><w:pgMar w:top=`"1440`" w:right=`"1440`" w:bottom=`"1440`" w:left=`"1440`" w:header=`"720`" w:footer=`"720`" w:gutter=`"0`"/><w:cols w:space=`"720`"/><w:docGrid w:linePitch=`"360`"/></w:sectPr></w:body></w:document>"

$contentTypesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
'@

$relsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
'@

$coreXml = "<?xml version=`"1.0`" encoding=`"UTF-8`" standalone=`"yes`"?><cp:coreProperties xmlns:cp=`"http://schemas.openxmlformats.org/package/2006/metadata/core-properties`" xmlns:dc=`"http://purl.org/dc/elements/1.1/`" xmlns:dcterms=`"http://purl.org/dc/terms/`" xmlns:dcmitype=`"http://purl.org/dc/dcmitype/`" xmlns:xsi=`"http://www.w3.org/2001/XMLSchema-instance`"><dc:title>SQLite EGRAPH example report</dc:title><dc:creator>Codex</dc:creator><cp:lastModifiedBy>Codex</cp:lastModifiedBy><dcterms:created xsi:type=`"dcterms:W3CDTF`">$((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))</dcterms:created><dcterms:modified xsi:type=`"dcterms:W3CDTF`">$((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))</dcterms:modified></cp:coreProperties>"

$appXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Codex</Application>
</Properties>
'@

$outDir = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$buildDir = Join-Path $outDir (".docx-build-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $buildDir | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildDir "_rels") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildDir "word") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildDir "docProps") | Out-Null

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $buildDir "[Content_Types].xml"), $contentTypesXml, $utf8)
[System.IO.File]::WriteAllText((Join-Path $buildDir "_rels\.rels"), $relsXml, $utf8)
[System.IO.File]::WriteAllText((Join-Path $buildDir "word\document.xml"), $documentXml, $utf8)
[System.IO.File]::WriteAllText((Join-Path $buildDir "word\styles.xml"), $stylesXml, $utf8)
[System.IO.File]::WriteAllText((Join-Path $buildDir "docProps\core.xml"), $coreXml, $utf8)
[System.IO.File]::WriteAllText((Join-Path $buildDir "docProps\app.xml"), $appXml, $utf8)

if (Test-Path -LiteralPath $resolvedOutput) {
    Remove-Item -LiteralPath $resolvedOutput -Force
}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($resolvedOutput, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in Get-ChildItem -LiteralPath $buildDir -Recurse -File) {
        $entryName = $file.FullName.Substring($buildDir.Length + 1).Replace('\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entryName) | Out-Null
    }
} finally {
    $zip.Dispose()
}
Remove-Item -LiteralPath $buildDir -Recurse -Force

Write-Host "DOCX written: $resolvedOutput"
Write-Host "Examples: $($examples.Count)"
