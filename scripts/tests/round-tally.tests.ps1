<#
.SYNOPSIS
    Tests for round-tally.measure.ps1 -- the counter that replaced the hand-counted totals line of a
    round's step table (inbound #387).

.DESCRIPTION
    The measurement script asserts nothing itself, by design: on a given set of papers whatever it
    counts IS the tally. So its correctness is pinned here, and the interesting cases are the ones
    where a plausible counter is quietly wrong -- a bolded cell, a column that is not a round, a table
    that is not the step table, a cell with no marker at all. Those are how a total ends up looking
    complete while missing rows, which is the whole defect this replaces.

    The markers are built from code points rather than typed as literals: Windows PowerShell 5.1
    decodes a BOM-less file as ANSI, so an emoji pasted into this file would arrive at the script as
    mojibake and the suite would be testing the wrong bytes. Same reason teardown.ps1 builds its
    middle dot with [char]0x00B7.

    Dependency-free (no Pester), exit 1 on the first failure, same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Measure  = Join-Path $RepoRoot 'scripts\tests\round-tally.measure.ps1'
$TmpDir   = Join-Path ([System.IO.Path]::GetTempPath()) "round-tally-tests-$PID"

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}
function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}

# The round's scoring vocabulary, by code point. The script has no opinion about these -- that is the
# property under test -- so the suite is free to pick any symbols it likes.
$RED    = [char]::ConvertFromUtf32(0x1F534)   # blocked
$GREEN  = [char]::ConvertFromUtf32(0x1F7E2)   # green
$YELLOW = [char]::ConvertFromUtf32(0x1F7E1)   # friction
$WHITE  = [char]::ConvertFromUtf32(0x26AA)    # not measured
$DASH   = [char]0x2014                        # the row did not exist in that round

function Write-Fixture {
    <# Writes a markdown file as real UTF-8, and returns its path. #>
    param([string]$Name, [string[]]$Lines)
    if (-not (Test-Path -LiteralPath $TmpDir)) { New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null }
    $p = Join-Path $TmpDir $Name
    [System.IO.File]::WriteAllText($p, (($Lines -join "`r`n") + "`r`n"), (New-Object System.Text.UTF8Encoding $false))
    return $p
}

# Via the shared capture helper rather than `2>&1`: one of the cases here deliberately makes the
# measurement Write-Error and exit 1, and on 5.1 a redirected stderr line from a native command raises
# NativeCommandError -- which under $ErrorActionPreference = 'Stop' would kill this suite on the case
# that is passing. Sylvester #15's rule: capture first, judge the exit code after.
. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')

function Invoke-Measure {
    param([string[]]$ScriptArgs)
    $r = Invoke-NativeCapture -FilePath 'powershell' `
        -Arguments (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Measure) + $ScriptArgs)
    return [pscustomobject]@{ Code = $r.ExitCode; Out = ((@($r.Output) | ForEach-Object { "$_" }) -join "`n") }
}

# Reads the generated table back as a map: column -> array of counts, so a case can assert on figures
# instead of on formatting.
function Get-Row {
    param([string]$Text, [string]$Column)
    $m = [regex]::Match($Text, "(?m)^\|\s*\*\*$([regex]::Escape($Column))\*\*\s*\|(?<rest>.*)\|\s*$")
    if (-not $m.Success) { return $null }
    return @($m.Groups['rest'].Value -split '\|' | ForEach-Object { $_.Trim() })
}

try {
    Write-Host "== round-tally.tests: the step-table counter ==" -ForegroundColor Cyan

    # --- 1. The shape from the real papers: several tables, one tally --------------------------------
    # The step table is split over sections (before step 1, test A, test B) and the totals run across
    # all of them. A counter that stopped at the first table would report a plausible third of a round.
    Write-Host "-- one tally across several tables --" -ForegroundColor Cyan
    $f = Write-Fixture -Name 'multi.md' -Lines @(
        '# A round',
        '',
        '### Before step 1',
        '',
        '| stap | v11 | v12 | klasse | issue |',
        '|---|---|---|---|---|',
        "| install | $RED geblokkeerd | $GREEN groen (tekst) | | #334 |",
        "| PATH | $YELLOW wrijving | $GREEN groen | | #334 |",
        '',
        'Prose between the tables, which must not join them.',
        '',
        '### Test A',
        '',
        '| stap | v11 | v12 | klasse | issue |',
        '|---|---|---|---|---|',
        "| A0 | $GREEN groen | $GREEN groen | | |",
        "| A1 | $DASH | $YELLOW wrijving (klein) | 1 | new in v12 |",
        "| A2 | $WHITE niet gemeten | $GREEN groen | | #329 |"
    )
    $r = Invoke-Measure -ScriptArgs @('-Path', $f)
    Assert-Equal 0 $r.Code 'multi: exits 0'
    Assert-True ($r.Out -match 'Counted over 2 table\(s\) and 5 row\(s\)') 'multi: both tables and all five rows are in the tally'
    $v12 = Get-Row -Text $r.Out -Column 'v12'
    Assert-True ($null -ne $v12) 'multi: the v12 row is present'
    if ($v12) {
        # Column order is order of first appearance: red, green, yellow, white, dash.
        Assert-Equal '0' $v12[0] 'multi/v12: no blocked'
        Assert-Equal '4' $v12[1] 'multi/v12: four green -- the "(tekst)" qualifier folds into its base category'
        Assert-Equal '1' $v12[2] 'multi/v12: one friction'
        Assert-Equal '5' $v12[5] 'multi/v12: counted equals the row total'
    }
    $v11 = Get-Row -Text $r.Out -Column 'v11'
    if ($v11) {
        Assert-Equal '1' $v11[0] 'multi/v11: one blocked'
        Assert-Equal '1' $v11[4] 'multi/v11: the row that did not exist in v11 is its own category, not silently green'
    }
    Assert-True ($r.Out -notmatch '(?m)^\|\s*\*\*klasse\*\*') 'multi: a non-round column is not counted as a round'

    # --- 2. THE v13 REGRESSION: the rows a round is ABOUT are bold ----------------------------------
    # Every row a round turned around is bolded in the papers. Reading '*' as the opening character
    # would push exactly those rows out of the count -- a tally that is wrong precisely where the round
    # is interesting, and plausible everywhere else.
    Write-Host "-- emphasis does not hide a cell --" -ForegroundColor Cyan
    $f2 = Write-Fixture -Name 'bold.md' -Lines @(
        '| stap | v13 |',
        '|---|---|',
        "| plain | $GREEN groen |",
        "| **turned around** | **$GREEN groen** |",
        "| _also emphasised_ | _$YELLOW wrijving_ |"
    )
    $r2 = Invoke-Measure -ScriptArgs @('-Path', $f2)
    $b = Get-Row -Text $r2.Out -Column 'v13'
    Assert-True ($null -ne $b) 'bold: the v13 row is present'
    if ($b) {
        Assert-Equal '2' $b[0] 'bold: a bolded cell counts in its own category (#387)'
        Assert-Equal '1' $b[1] 'bold: an underscore-emphasised cell counts too'
        Assert-Equal '3' $b[2] 'bold: everything is counted, nothing unclassified'
    }
    Assert-True ($r2.Out -notmatch 'open with plain text') 'bold: and no cell is reported as markerless'

    # --- 3. A markerless cell is REPORTED, never dropped --------------------------------------------
    # Older columns hold bare prose. Counting them in nothing is correct; saying nothing about them is
    # not -- a bounded count has to say what it bounded.
    Write-Host "-- markerless cells are named --" -ForegroundColor Cyan
    $f3 = Write-Fixture -Name 'bare.md' -Lines @(
        '| stap | v10 | v11 |',
        '|---|---|---|',
        "| A2 extra | niet gemeten | $GREEN groen |",
        "| B6 | niet opgetreden | $GREEN groen |",
        "| B7 | $RED geblokkeerd | $GREEN groen |"
    )
    $r3 = Invoke-Measure -ScriptArgs @('-Path', $f3)
    Assert-True ($r3.Out -match '2 cell\(s\) carry no marker') 'bare: the run warns about the markerless cells'
    Assert-True ($r3.Out -match 'niet opgetreden') 'bare: and each one is listed with its own text'
    Assert-True ($r3.Out -match '(?m)^\| v10 \| A2 extra \| niet gemeten \|') 'bare: named by column and by row'
    $v10 = Get-Row -Text $r3.Out -Column 'v10'
    if ($v10) {
        Assert-Equal '1' $v10[($v10.Count - 2)] 'bare/v10: counted is 1 -- the markerless cells are in NO category'
        Assert-Equal '3' $v10[($v10.Count - 1)] 'bare/v10: while the row total still says 3, so the gap is visible'
    }

    # --- 4. A table that is not the step table is left alone ----------------------------------------
    # A round's papers hold other tables (the findings list, the baseline). Counting a marker out of one
    # of those would inflate a total that a reader has no way to trace back.
    Write-Host "-- unrelated tables are not counted --" -ForegroundColor Cyan
    $f4 = Write-Fixture -Name 'other.md' -Lines @(
        '| stap | v13 |',
        '|---|---|',
        "| A0 | $GREEN groen |",
        '',
        '| issue | status | verdict |',
        '|---|---|---|',
        "| #323 | $GREEN groen | not measured, the condition did not occur |",
        "| #337 | $RED geblokkeerd | still open |"
    )
    $r4 = Invoke-Measure -ScriptArgs @('-Path', $f4)
    Assert-True ($r4.Out -match 'Counted over 1 table\(s\) and 1 row\(s\)') 'other: only the table with a round column is counted'
    $o = Get-Row -Text $r4.Out -Column 'v13'
    if ($o) { Assert-Equal '1' $o[($o.Count - 2)] 'other: and the markers in the unrelated table are not in the tally' }

    # --- 5. One marker, two labels: reported rather than merged silently ----------------------------
    Write-Host "-- a marker used with two labels is flagged --" -ForegroundColor Cyan
    $f5 = Write-Fixture -Name 'labels.md' -Lines @(
        '| stap | v13 |',
        '|---|---|',
        "| A0 | $GREEN groen |",
        "| A1 | $GREEN groen |",
        "| A2 | $GREEN green |"
    )
    $r5 = Invoke-Measure -ScriptArgs @('-Path', $f5)
    Assert-True ($r5.Out -match 'is used with more than one label') 'labels: the divergence is warned about'
    Assert-True ($r5.Out -match '\|\s*column\s*\|\s*\S+\s+groen\s*\|') 'labels: the most frequent label heads the column'

    # --- 6. Nothing to count is an error, not an empty table ----------------------------------------
    Write-Host "-- no round column at all --" -ForegroundColor Cyan
    $f6 = Write-Fixture -Name 'none.md' -Lines @(
        '| issue | status |',
        '|---|---|',
        "| #323 | $GREEN groen |"
    )
    $r6 = Invoke-Measure -ScriptArgs @('-Path', $f6)
    Assert-Equal 1 $r6.Code 'none: exits 1 rather than printing a table of nothing'
    Assert-True ($r6.Out -match 'ColumnPattern') 'none: and points at the parameter that would fix it'

    # --- 7. -ColumnPattern really is the knob ------------------------------------------------------
    $r7 = Invoke-Measure -ScriptArgs @('-Path', $f6, '-ColumnPattern', '^status$')
    Assert-Equal 0 $r7.Code 'pattern: the same file counts fine once the pattern matches its columns'
    Assert-True ($null -ne (Get-Row -Text $r7.Out -Column 'status')) 'pattern: and the column it names is the one counted'

    # --- 8. -OutFile writes UTF-8 without BOM, markers intact --------------------------------------
    # The parameter exists because a 5.1 redirect re-encodes stdout in the console codepage, which
    # would put mojibake into the file a reader pastes from -- and this repo lints for that.
    Write-Host "-- -OutFile round-trips the markers --" -ForegroundColor Cyan
    $outFile = Join-Path $TmpDir 'tally.md'
    $r8 = Invoke-Measure -ScriptArgs @('-Path', $f2, '-OutFile', $outFile)
    Assert-Equal 0 $r8.Code 'outfile: exits 0'
    Assert-True (Test-Path -LiteralPath $outFile) 'outfile: the file is there'
    $bytes = [System.IO.File]::ReadAllBytes($outFile)
    Assert-True (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) `
        'outfile: written without a BOM'
    $back = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8)
    Assert-True ($back.Contains($GREEN)) 'outfile: the marker survives the round trip as itself'
    Assert-True ($back -match 'regenerate, do not retype') 'outfile: and carries the generated marker, like the baseline block'
}
finally {
    if (Test-Path -LiteralPath $TmpDir) { Remove-Item -Recurse -Force -LiteralPath $TmpDir -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
