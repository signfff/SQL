# The one reader of the EGRAPH corpus-case format on the PowerShell side.
#
# EGraphCorpusCaseWriter.java writes a case as a header, a setup block and the queries. The setup is
# delta encoded: a full snapshot on a keyframe, and in between only the statements that rebuild what
# changed. A stage that wants to pick cases out of such a file has to expand each delta back into a
# standalone case first, and two scripts each had their own copy of that expansion - which is one copy
# too many for a format defined in a fourth place.
#
# Dot-source this and call Expand-EGraphCorpusCases.

Set-StrictMode -Version Latest

function Expand-EGraphCorpusCases {
    <#
    .SYNOPSIS
    Reads a delta-encoded EGRAPH corpus and returns one object per case, each carrying a setup that
    stands on its own.

    .DESCRIPTION
    Each returned object has:
      CaseText              the expanded case, header included, with setup=delta rewritten to setup=full
      Rows                  the row count from the header, or $null when it carried none
      RowsDetermined        whether the header says the query's rows are determined
      BaseQuery             the base query alone: comment lines dropped, stops at the first replay
                            query, trailing semicolon removed
      QueryBlockText        everything after the base-query marker with whitespace collapsed, which is
                            what the high-coverage updater has always deduplicated on - it takes the
                            replay queries in as well, so two cases sharing a base query but differing
                            in their variants count as two
      SetupStatements       how many setup statements the expanded case has
      SetupChars            how many characters those statements come to
      LongestSetupStatement the length of the longest one

    .PARAMETER Accept
    Called once per case with that object and decides whether it is returned. Omit to take every case.

    .PARAMETER Limit
    Stop after this many accepted cases. 0 or less means no limit.
    #>
    param(
        [Parameter(Mandatory = $true)] [string] $Path,
        [scriptblock] $Accept = $null,
        [int] $Limit = 0
    )

    $cases = New-Object System.Collections.Generic.List[object]
    $block = New-Object System.Text.StringBuilder
    $queryBlock = New-Object System.Text.StringBuilder
    $baseQuery = New-Object System.Text.StringBuilder
    # Only statements: a blank or comment line inside a setup block is not replayed, and carrying one
    # into an expanded delta would change the case's text without changing what it does.
    $currentSetupLines = New-Object System.Collections.Generic.List[string]
    $accumulatedSetupLines = New-Object System.Collections.Generic.List[string]

    $inCase = $false
    $inSetup = $false
    $inQueryBlock = $false
    $inBaseQuery = $false
    $rows = $null
    $rowsDetermined = $false
    $setupStatements = 0
    $setupChars = 0
    $longestSetupStatement = 0

    foreach ($line in [System.IO.File]::ReadLines($Path)) {
        $trimmed = $line.Trim()
        $emitted = $line

        if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_BEGIN")) {
            $inCase = $true
            $inSetup = $false
            $inQueryBlock = $false
            $inBaseQuery = $false
            $rows = $null
            $rowsDetermined = $trimmed.Contains(" rows_determined=1")
            $setupStatements = 0
            $setupChars = 0
            $longestSetupStatement = 0
            [void] $block.Clear()
            [void] $queryBlock.Clear()
            [void] $baseQuery.Clear()
            $currentSetupLines.Clear()
            if ($trimmed -match "rows=(-?\d+)") {
                $rows = [int] $Matches[1]
            }
            # The expanded case carries a whole snapshot, so its header has to say so.
            $emitted = $line.Replace(" setup=delta", " setup=full")
        }
        if (-not $inCase) {
            continue
        }

        if ($trimmed -eq "-- EGRAPH_CORPUS_SETUP_DELTA") {
            # What came before, then this case's own statements on top of it.
            $inSetup = $true
            $inQueryBlock = $false
            $inBaseQuery = $false
            $currentSetupLines.Clear()
            [void] $block.AppendLine("-- EGRAPH_CORPUS_SETUP_BEGIN")
            foreach ($setupLine in $accumulatedSetupLines) {
                $currentSetupLines.Add($setupLine)
                [void] $block.AppendLine($setupLine)
                $setupStatements++
                $length = $setupLine.Trim().Length
                $setupChars += $length
                if ($length -gt $longestSetupStatement) {
                    $longestSetupStatement = $length
                }
            }
            continue
        }

        [void] $block.AppendLine($emitted)

        if ($trimmed -eq "-- EGRAPH_CORPUS_SETUP_BEGIN") {
            $inSetup = $true
            $inQueryBlock = $false
            $inBaseQuery = $false
            $currentSetupLines.Clear()
            continue
        }
        if ($trimmed -eq "-- EGRAPH_BASE_QUERY") {
            if ($inSetup) {
                $accumulatedSetupLines.Clear()
                $accumulatedSetupLines.AddRange($currentSetupLines)
            }
            $inSetup = $false
            $inQueryBlock = $true
            $inBaseQuery = $true
            continue
        }
        if ($trimmed.StartsWith("-- EGRAPH_REPLAY_QUERY")) {
            $inBaseQuery = $false
            [void] $queryBlock.AppendLine($line)
            continue
        }
        if ($trimmed.StartsWith("-- EGRAPH_CORPUS_CASE_END")) {
            $info = [PSCustomObject] @{
                CaseText              = $block.ToString().TrimEnd()
                Rows                  = $rows
                RowsDetermined        = $rowsDetermined
                BaseQuery             = ($baseQuery.ToString().Trim() -replace ";\s*$", "").Trim()
                QueryBlockText        = (($queryBlock.ToString().Trim() -replace ";$", "").Trim() -replace "\s+", " ")
                SetupStatements       = $setupStatements
                SetupChars            = $setupChars
                LongestSetupStatement = $longestSetupStatement
            }
            $take = $true
            if ($null -ne $Accept) {
                $take = [bool] (& $Accept $info)
            }
            if ($take) {
                $cases.Add($info)
                if ($Limit -gt 0 -and $cases.Count -ge $Limit) {
                    break
                }
            }
            $inCase = $false
            $inSetup = $false
            $inQueryBlock = $false
            $inBaseQuery = $false
            continue
        }
        if ($inSetup) {
            if ($trimmed.Length -gt 0 -and -not $trimmed.StartsWith("--")) {
                $currentSetupLines.Add($line)
                $setupStatements++
                $setupChars += $trimmed.Length
                if ($trimmed.Length -gt $longestSetupStatement) {
                    $longestSetupStatement = $trimmed.Length
                }
            }
            continue
        }
        if ($inQueryBlock) {
            [void] $queryBlock.AppendLine($line)
            if ($inBaseQuery -and -not $trimmed.StartsWith("--")) {
                [void] $baseQuery.AppendLine($line)
            }
        }
    }
    return $cases
}
