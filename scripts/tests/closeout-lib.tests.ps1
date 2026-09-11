<#
.SYNOPSIS
    Tests for scripts/lib/closeout-lib.ps1 -- the close-out receipt shape (issue #1884), and the
    structural half: that every chain-ending script actually reaches it.

.DESCRIPTION
    THE STRUCTURAL HALF IS THE POINT OF THIS SUITE, and it is the half a unit test of the function
    cannot buy. #1884's diagnosis is that step 6 of the ritual has been repaired in prose four times
    and lost four times; the repair is a mechanism, and a mechanism that is defined but not CALLED is
    the fifth prose repair with extra steps. So the asserts below read the five callers' source text
    and hold each to three things: it dot-sources the lib, the dot-source is GUARDED, and it calls
    the function. A later tidy-up that drops a call site goes red here.

    WHY THE GUARD IS ASSERTED AND NOT JUST THE DOT-SOURCE. These scripts are mirrored into every
    consumer's plugin cache and arrive by plugin UPDATE rather than by choice, so a consumer whose
    mirror predates this lib runs a ship-pr that dot-sources a file they do not have. An unguarded
    dot-source there is a crash on load of the script that merges their work -- the worst possible
    place to land an ordering dependency. Same reasoning git-porcelain-lib's registry entry gives.

    THE OUTPUT IS ASSERTED ON ITS THREE PARTS, not on its exact wording. The wording is prose and
    will be sharpened; what must not drift is that all three parts are present, because "what
    happened / where to read it / whether the session can be cleared" IS the receipt, and a reminder
    that has quietly lost one of them is worse than none. The ceiling is asserted as a line count for
    the same reason: a reminder about brevity that grows past its own ceiling teaches the opposite of
    what it says.

    IT SPAWNS NOTHING AND WRITES NOTHING. The function takes two strings and prints, so the whole
    suite is a dot-source plus reads of source text -- no fixture repo, no temp directory, and none
    of the predictable-temp-path class #1664 is closing.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibPath  = Join-Path $RepoRoot 'scripts\lib\closeout-lib.ps1'

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}
function Assert-True {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}

Assert-True (Test-Path -LiteralPath $LibPath) 'closeout-lib.ps1 exists at its registered source path'
. $LibPath

# Write-Host does not go down the output stream, so the printed lines are captured from the
# information stream (6>&1) rather than by assigning the call. Reading MessageData.Message keeps the
# colour argument out of the comparison.
function Get-ReceiptLines {
    param([hashtable]$CallArgs = @{})
    $out = Write-CloseOutReceipt @CallArgs 6>&1
    return @($out | ForEach-Object { "$($_.MessageData.Message)" })
}

Write-Host ''
Write-Host 'The printed shape -- the three parts, and the ceiling' -ForegroundColor Cyan

$lines = Get-ReceiptLines @{ Cite = 'PR #1885' }
$body  = ($lines -join "`n")

# ONE LEADING BLANK LINE is deliberate and asserted: this prints under whatever the run last said,
# and an unseparated reminder reads as another line of that report.
Assert-Equal '' $lines[0] 'it opens with a blank line, so it is not read as part of the run above it'

$said = @($lines | Where-Object { $_.Trim() -ne '' })
Assert-Equal 3 $said.Count 'three non-empty lines with no bypass -- its own stated ceiling'

Assert-True ($body -match 'receipt, not a report') 'part 0: it names the rule it is enforcing'
Assert-True ($body -match 'What happened')          'part 1: what happened'
Assert-True ($body -match 'where to read it')       'part 2: where to read it'
Assert-True ($body -match 'session can be cleared') 'part 3: whether the session can be cleared'
Assert-True ($body -match 'two or three lines')     'the ceiling is stated, not implied'

# REHOUSED, NOT CUT. #1408 settled that the ceiling is a ceiling and not the word budget the August 27
# decision refused: over it, a surplus moves to a durable home rather than being deleted. A reminder
# that said only "be shorter" would re-open exactly that argument.
Assert-True ($body -match 'rehoused')   'the surplus is rehoused rather than cut'
Assert-True ($body -match 'PR body')    '...and the reminder names a home for it'

Write-Host ''
Write-Host "The citation -- the middle part is the caller's to fill in" -ForegroundColor Cyan

Assert-True (($lines -join '') -match [regex]::Escape('(PR #1885)')) 'a supplied citation is printed in the line'

$bare = (Get-ReceiptLines) -join "`n"
Assert-True ($bare -match 'where to read it, and')   'no citation: the sentence still reads'
Assert-True ($bare -notmatch '\(\s*\)')              '...and prints no empty parenthesis'

$padded = (Get-ReceiptLines @{ Cite = '  issue #1884  ' }) -join ''
Assert-True ($padded -match [regex]::Escape('(issue #1884)')) "a citation is trimmed, so a caller's padding cannot reach the line"

Write-Host ''
Write-Host "The bypass clause -- #1884's second finding" -ForegroundColor Cyan

# THE CLAUSE IS CONDITIONAL, and that is what keeps its signal. A run that skipped nothing must not
# print a sentence about skipping, or the one run that did is indistinguishable from the rest.
$clean = (Get-ReceiptLines @{ Cite = 'PR #1' }) -join "`n"
Assert-True ($clean -notmatch 'skipped') 'no bypass given: no bypass clause at all'

$skipped = Get-ReceiptLines @{ Cite = 'PR #1'; Bypass = '-SkipTests' }
Assert-Equal 4 @($skipped | Where-Object { $_.Trim() -ne '' }).Count 'a bypass adds exactly one line'
$skippedBody = $skipped -join "`n"
Assert-True ($skippedBody -match 'skipped -SkipTests') 'it names the switch the operator actually typed'
Assert-True ($skippedBody -match 'PR body')            '...and sends it to the PR body, not the reply'

Assert-True (((Get-ReceiptLines @{ Bypass = '   ' }) -join "`n") -notmatch 'skipped') 'whitespace is not a bypass'

Write-Host ''
Write-Host '-Quiet prints nothing' -ForegroundColor Cyan

Assert-Equal 0 (Get-ReceiptLines @{ Cite = 'PR #1'; Quiet = $true }).Count '-Quiet suppresses every line'

Write-Host ''
Write-Host 'The callers actually reach it -- the structural half' -ForegroundColor Cyan

# The five chain endings. A script absent from this list is a chain that ends without the shape, which
# is the state #1884 measured -- so adding a chain ender means adding a row here.
$callers = @(
    @{ Path = 'scripts\release\ship-pr.ps1';              Var = 'shipCloseoutLib' }
    @{ Path = 'scripts\release\open-pr.ps1';              Var = 'openCloseoutLib' }
    @{ Path = 'scripts\release\fold-changelog-entry.ps1'; Var = 'foldCloseoutLib' }
    @{ Path = 'scripts\release\cut-release.ps1';          Var = 'cutCloseoutLib'  }
    @{ Path = 'scripts\task\park-branch.ps1';             Var = 'parkCloseoutLib' }
)
foreach ($c in $callers) {
    $name = Split-Path -Leaf $c.Path
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $c.Path) -Raw
    Assert-True ($text -match 'closeout-lib\.ps1')            "$name dot-sources closeout-lib.ps1"
    Assert-True ($text -match "Test-Path -LiteralPath \`$$($c.Var)") "$name guards that dot-source (a consumer's mirror may predate it)"
    Assert-True ($text -match 'Write-CloseOutReceipt')        "$name calls Write-CloseOutReceipt"
    # THE CALL IS GUARDED THROUGH Test-FunctionDefined, not through `Get-Command -EA SilentlyContinue`
    # (issue #1729): that idiom routes a bare name through the wildcard matcher and answers a MISS by
    # scanning every PATH entry for an executable of that name -- and a miss is exactly the case here,
    # on the consumer whose mirror predates the lib. command-probe-lib's own suite refuses the idiom
    # tree-wide, which is what caught this call site when it was first written the other way.
    Assert-True ($text -match "Test-FunctionDefined 'Write-CloseOutReceipt'") "$name guards the CALL too, and through the cheap probe"
    Assert-True ($text -notmatch 'Get-Command Write-CloseOutReceipt') "...and does not reintroduce the PATH-scanning probe"
}

# SHIP-PR AND OPEN-PR EACH HAVE TWO ENDINGS, and each ending closes out. ship-pr's queue arm exits
# before the foot of the file; open-pr's already-open arm does the same. A single call in either would
# leave one real ending silent, which is the failure this suite is for.
foreach ($two in @('scripts\release\ship-pr.ps1', 'scripts\release\open-pr.ps1')) {
    $n = ([regex]::Matches((Get-Content -LiteralPath (Join-Path $RepoRoot $two) -Raw), 'Write-CloseOutReceipt -Cite')).Count
    Assert-Equal 2 $n "$(Split-Path -Leaf $two) calls it from BOTH of its endings"
}

# THE BYPASS IS READ FROM THE RUN, not typed. ship-pr's helper is what carries #1884's second finding
# into the two scripts that own the switches, so it is asserted rather than left to the call site.
$shipText = Get-Content -LiteralPath (Join-Path $RepoRoot 'scripts\release\ship-pr.ps1') -Raw
Assert-True ($shipText -match 'function Get-ShipBypassNote') 'ship-pr derives the bypass note from its own switches'
$shipLines = $shipText -split "`n"
$defAt = ($shipLines | Select-String -Pattern '^function Get-ShipBypassNote' | Select-Object -First 1).LineNumber
$useAt = ($shipLines | Select-String -Pattern 'Get-ShipBypassNote\)'         | Select-Object -First 1).LineNumber
Assert-True ($defAt -lt $useAt) '...and defines it ABOVE its first call (a script runs top to bottom)'

$openText = Get-Content -LiteralPath (Join-Path $RepoRoot 'scripts\release\open-pr.ps1') -Raw
Assert-True ($openText -match "openSkipped \+= '-SkipTests'") 'open-pr reads -SkipTests into its bypass note'
Assert-True ($openText -match "openSkipped \+= '-SkipLint'")  'open-pr reads -SkipLint into its bypass note'

Write-Host ''
Write-Host 'The lib is ASCII and mirrored' -ForegroundColor Cyan

# The repo-wide script-ASCII rule (check 27) covers this too; asserted here as well because this file
# is one of the few whose whole job is text a person reads, which is where a smart quote gets typed.
$raw = Get-Content -LiteralPath $LibPath -Raw
Assert-True (-not ($raw -cmatch '[^\x00-\x7F]')) 'closeout-lib.ps1 is pure ASCII'

# Mirrored, so a consumer meets the same shape this repo does. shared-scripts.tests.ps1 owns the
# byte-identity assert; this one is only that the registration exists at all.
Assert-True ((Get-Content -LiteralPath (Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1') -Raw) -match "closeout-lib") 'closeout-lib is registered as a shared script'
Assert-True (Test-Path -LiteralPath (Join-Path $RepoRoot 'plugins\dkj-policy\scripts\lib\closeout-lib.ps1')) '...and its plugin mirror is present'

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
