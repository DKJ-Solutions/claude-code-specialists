<#
.SYNOPSIS
    Regression tests for scripts/lib/pr-issues-lib.ps1 (the resolves gate's decision table).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Dot-sources the lib and runs a series of
    asserts. Exit code 0 if everything passes, 1 on a failure -- so usable as a CI gate.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/pr-issues.tests.ps1

    What this suite is for: PRs #341, #342 and #343 each repaired issues and each referenced them
    with a PLAIN mention instead of a closing keyword, so eight repaired findings stayed OPEN after
    the merge. The gate in open-pr.ps1 exists to make that unrepeatable, and these asserts are what
    keep the gate honest. Two properties are load-bearing and asserted in BOTH directions:

      1. One closing keyword PER issue. GitHub does not distribute a keyword over a comma list, so a
         'Closes #331, #332' form would close the first and silently leave the second open -- the
         very failure being gated. The block's shape is asserted, not just its content.
      2. PR references are NOT issue mentions. A changelog entry routinely cites the PR it follows
         on from ('as PR #341 established'), and counting those would make the gate cry wolf on
         nearly every branch -- a gate that always fires gets bypassed, which is how it would
         quietly stop working.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\pr-issues-lib.ps1')

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

function Assert-Set {
    <# Compares two int sets order-insensitively, reported as a readable list. #>
    param([int[]]$Expected, [int[]]$Actual, [string]$Name)
    $e = (@($Expected | Sort-Object -Unique) -join ',')
    $a = (@($Actual   | Sort-Object -Unique) -join ',')
    Assert-Equal $e $a $Name
}

Write-Host "ConvertTo-IssueNumberList" -ForegroundColor Cyan
# This function exists because `powershell -File` cannot bind an [int[]]: '332,340' arrives as one
# string and casts to 332340, reading the comma as a THOUSANDS SEPARATOR -- silently, no error.
# Measured on Windows PowerShell 5.1 while building the gate; these asserts pin the parser that
# replaced that binding.
Assert-Set @()          (ConvertTo-IssueNumberList -Value '')            'empty string -> no numbers'
Assert-Set @()          (ConvertTo-IssueNumberList -Value $null)         'null -> no numbers'
Assert-Set @(332)       (ConvertTo-IssueNumberList -Value '332')         'single number'
Assert-Set @(332, 340)  (ConvertTo-IssueNumberList -Value '332,340')     'comma list -> BOTH numbers (not 332340)'
Assert-Set @(332, 340)  (ConvertTo-IssueNumberList -Value '332, 340')    'comma + space'
Assert-Set @(332, 340)  (ConvertTo-IssueNumberList -Value '332 340')     'space separated'
Assert-Set @(332, 340)  (ConvertTo-IssueNumberList -Value '332;340')     'semicolon separated'
Assert-Set @(332, 340)  (ConvertTo-IssueNumberList -Value '#332, #340')  'leading # tolerated'
Assert-Set @(332)       (ConvertTo-IssueNumberList -Value '332,332')     'duplicates collapse'
Assert-Set @(331, 332)  (ConvertTo-IssueNumberList -Value '332,331')     'result is sorted'
Assert-Set @()          (ConvertTo-IssueNumberList -Value 'none')        'a word yields nothing (never issue 0)'
Assert-Set @(332)       (ConvertTo-IssueNumberList -Value 'issue 332')   'a number inside prose is still found'

Write-Host "Get-IssueMentions" -ForegroundColor Cyan
Assert-Set @()          (Get-IssueMentions -Text '')                       'empty text -> no mentions'
Assert-Set @()          (Get-IssueMentions -Text $null)                    'null text -> no mentions'
Assert-Set @(332)       (Get-IssueMentions -Text 'fixes the thing in #332') 'a bare #332 is a mention'
Assert-Set @(331, 332)  (Get-IssueMentions -Text '#331 and #332')          'two mentions, both found'
Assert-Set @(332)       (Get-IssueMentions -Text '#332 and again #332')    'duplicates collapse'
Assert-Set @(331, 332)  (Get-IssueMentions -Text '#332 then #331')         'result is sorted'
Assert-Set @(340)       (Get-IssueMentions -Text 'see https://github.com/o/r/issues/340') 'issue LINK is a mention'

# Property 2 -- the anti-cry-wolf direction.
Assert-Set @()  (Get-IssueMentions -Text 'as PR #341 established for this class')       'PR #341 is not an issue mention'
Assert-Set @()  (Get-IssueMentions -Text 'as PRs #341-#343 showed')                     'PRs #341-#343 RANGE form excluded'
Assert-Set @()  (Get-IssueMentions -Text 'PRs #341, #342 and #343 each did it')         'PRs list form excluded across commas and "and"'
Assert-Set @()  (Get-IssueMentions -Text 'pull requests #341 through #343')             'pull requests ... through ... excluded'
# The range scrub must not swallow a following, unrelated mention -- it has to stop at the end of
# the PR list, not run on through the sentence.
Assert-Set @(332) (Get-IssueMentions -Text 'PRs #341-#343 each left #332 open')          'the range scrub stops at the list, #332 still found'
Assert-Set @()  (Get-IssueMentions -Text 'see pull request #341 for the shape')         'pull request #341 excluded'
Assert-Set @()  (Get-IssueMentions -Text '[PR #343](https://github.com/o/r/pull/343)')  'a /pull/ link is not an issue mention'
Assert-Set @(332) (Get-IssueMentions -Text 'PR #341 fixed #332')                        'a real mention alongside a PR reference still counts'

# --- Three false negatives found in review, each of which defeated the gate silently --------------
# 1. A slash-separated list. The lookbehind used to exclude '#N' after '/', so only the first number
#    in '#334/#329/#335' survived -- on a branch whose entry lists issues that way, the gate would
#    simply not fire for the rest.
Assert-Set @(329, 334, 335, 338) (Get-IssueMentions -Text '#334/#329/#335/#338') 'slash-separated list -> ALL four numbers'
Assert-Set @(326, 340)           (Get-IssueMentions -Text 'the round dossiers #326/#340') 'slash pair -> both numbers'
# 2. A genuine issue right after a SINGULAR PR reference. 'PR #341 and #332' says nothing about #332
#    being a PR, and swallowing it hid a real open issue. A missed mention is the bug the gate exists
#    to prevent; a surplus one only asks a question. So the list scrub needs a PLURAL head.
Assert-Set @(332) (Get-IssueMentions -Text 'This continues the work from PR #341 and #332, an open bug.') 'singular PR + "and #332" -> #332 survives'
Assert-Set @(332) (Get-IssueMentions -Text 'Fixed alongside PR #341, #332 in the same release.')          'singular PR + ", #332" -> #332 survives'
# ...while the plural list form stays excluded, and an unambiguous range does too.
Assert-Set @()    (Get-IssueMentions -Text 'PRs #341, #342 and #343 each did it')  'plural PRs + list -> still excluded'
Assert-Set @()    (Get-IssueMentions -Text 'PR #341-#343 covered it')              'singular PR + dash RANGE -> excluded (unambiguous)'
# 3. Code spans. A doc explaining this gate writes the pattern it explains; GitHub does not link a
#    reference inside backticks, so it is not a mention there either.
Assert-Set @()    (Get-IssueMentions -Text 'the example `#332` is prose')           'a backticked reference is not a mention'
Assert-Set @(340) (Get-IssueMentions -Text 'see `#332` but really #340')            'only the live reference counts'

Write-Host "Remove-MarkdownCodeSpans" -ForegroundColor Cyan
Assert-Equal '' (Remove-MarkdownCodeSpans -Text '')   'empty text -> empty'
Assert-True ((Remove-MarkdownCodeSpans -Text 'a `#332` b') -notmatch '#332') 'inline span blanked'
Assert-True ((Remove-MarkdownCodeSpans -Text 'a `#332` b') -match 'a')       'text around it survives'
Assert-True ((Remove-MarkdownCodeSpans -Text 'a ``#332`` b') -notmatch '#332') 'double-backtick span blanked'
$fencedText = "before`n" + '```' + "`nCloses #332`n" + '```' + "`nafter"
Assert-True ((Remove-MarkdownCodeSpans -Text $fencedText) -notmatch '#332') 'fenced block blanked'
Assert-True ((Remove-MarkdownCodeSpans -Text $fencedText) -match 'before')  'text before the fence survives'
Assert-True ((Remove-MarkdownCodeSpans -Text $fencedText) -match 'after')   'text after the fence survives'
# The filler is deliberately NOT whitespace. With spaces, 'Closes `x` #332' would blank to
# 'Closes     #332' and read as a live declaration -- while GitHub, which needs the keyword directly
# before the reference, closes nothing there. So the filler must break that adjacency...
Assert-True ((Remove-MarkdownCodeSpans -Text 'Closes `x` #332') -notmatch 'Closes\s+#332') 'a span does not leave keyword and reference looking adjacent'
Assert-Equal $false (Test-HasClosingKeyword -Text 'Closes `x` #332') 'a span between keyword and reference -> not a declaration (as on GitHub)'
# ...while still not hiding a reference that follows a span directly (the filler is not a word
# character either, so the mention lookbehind still lets it through).
Assert-Set @(332) (Get-IssueMentions -Text 'see `x`#332') 'a reference straight after a span is still a mention'
Assert-Equal 'a || b' (Remove-MarkdownCodeSpans -Text 'a `` b') 'length is preserved (offsets stay usable)'

Write-Host "Test-HasClosingKeyword" -ForegroundColor Cyan
Assert-Equal $false (Test-HasClosingKeyword -Text 'mentions #332 only')      'a plain mention does NOT count as closing'
Assert-Equal $false (Test-HasClosingKeyword -Text '')                        'empty body closes nothing'
Assert-Equal $true  (Test-HasClosingKeyword -Text 'Closes #332')             'Closes #332 counts'
Assert-Equal $true  (Test-HasClosingKeyword -Text 'closes #332')             'lowercase counts'
Assert-Equal $true  (Test-HasClosingKeyword -Text 'Fixes #332')              'Fixes counts'
Assert-Equal $true  (Test-HasClosingKeyword -Text 'Resolved #332')           'Resolved counts'
Assert-Equal $true  (Test-HasClosingKeyword -Text 'Closes: #332')            'the colon form counts'
Assert-Equal $true  (Test-HasClosingKeyword -Text 'Closes https://github.com/o/r/issues/332') 'the URL form counts'
# The word alone is not a keyword unless it is bound to a reference -- otherwise prose like
# "this closes the gap in #332" would read as a closing declaration GitHub will not honour.
Assert-Equal $false (Test-HasClosingKeyword -Text 'this closes the gap described in issue 332') 'a keyword with no #reference does not count'
# The critical review finding: prose explaining the gate must not trigger it. GitHub does not link a
# reference inside a code span, so a keyword there closes nothing on GitHub either.
Assert-Equal $false (Test-HasClosingKeyword -Text 'GitHub closes only the first: `Closes #331, #332`') 'a backticked keyword does NOT count'
Assert-Equal $true  (Test-HasClosingKeyword -Text 'Closes #331 -- see `#332` too')                     'a live keyword still counts next to a backticked one'

Write-Host "Get-ClosedIssueNumbers" -ForegroundColor Cyan
Assert-Set @()         (Get-ClosedIssueNumbers -Text 'mentions #332 only')          'plain mention -> closes nothing'
Assert-Set @(332)      (Get-ClosedIssueNumbers -Text 'Closes #332')                 'single keyword -> that number'
Assert-Set @(331, 332) (Get-ClosedIssueNumbers -Text "Closes #331`nCloses #332")    'one per line -> both'
Assert-Set @(340)      (Get-ClosedIssueNumbers -Text 'Fixes https://github.com/o/r/issues/340') 'URL form -> that number'
# Property 1, the false-green direction: the comma form GitHub does NOT honour must not be reported
# as closing the trailing numbers, or the ship-pr verification would pass on a wrong set.
Assert-Set @(331)      (Get-ClosedIssueNumbers -Text 'Closes #331, #332')           'comma form closes ONLY the first (as GitHub does)'
# This decides what ship-pr force-closes after a merge, so a prose example reaching it would close an
# unrelated issue and credit the wrong PR -- the critical review finding, reproduced on this repo's
# own changelog entry before the fix.
Assert-Set @()         (Get-ClosedIssueNumbers -Text 'so `Closes #331, #332` closes the first') 'a backticked example declares NOTHING'
$fencedBody = "text`n" + '```' + "`nCloses #331`n" + '```' + "`nmore text"
Assert-Set @()         (Get-ClosedIssueNumbers -Text $fencedBody)                    'a fenced example declares NOTHING'
Assert-Set @(331)      (Get-ClosedIssueNumbers -Text "Closes #331`n`nExample: ``Closes #999``") 'the live keyword counts, the fenced one does not'

Write-Host "New-ResolvesBlock" -ForegroundColor Cyan
Assert-Equal '' (New-ResolvesBlock -Issues @())        'no issues -> empty block (safe to append)'
Assert-Equal '' (New-ResolvesBlock -Issues @(0))       'a non-positive number is ignored'

$block = New-ResolvesBlock -Issues @(332, 331)
Assert-True ($block -match '(?m)^Closes #331$') 'block has its own line for #331'
Assert-True ($block -match '(?m)^Closes #332$') 'block has its own line for #332'
Assert-True ($block -notmatch ',')              'block contains NO comma list (GitHub would close only the first)'
Assert-Equal 2 (@([regex]::Matches($block, '(?m)^Closes #\d+$')).Count) 'one closing line PER issue'
Assert-True ($block -match '## Resolved issues')  'block carries its heading'
# Round trip: what the writer produces is exactly what the recogniser reads back.
Assert-Set @(331, 332) (Get-ClosedIssueNumbers -Text $block) 'round trip: writer output reads back as both issues'

$dupBlock = New-ResolvesBlock -Issues @(332, 332, 331)
Assert-Equal 2 (@([regex]::Matches($dupBlock, '(?m)^Closes #\d+$')).Count) 'duplicate input -> one line each'

Write-Host "Add-ResolvesBlock" -ForegroundColor Cyan
Assert-Equal 'body text' (Add-ResolvesBlock -Body 'body text' -Issues @()) 'no issues -> body unchanged'
$appended = Add-ResolvesBlock -Body '## What does this change do?' -Issues @(332)
Assert-True ($appended -match '## What does this change do') 'the original body survives'
Assert-True ($appended -match '(?m)^Closes #332$')           'the closing line is appended'
# Idempotence: re-running must not stack a second block (the accumulation-bug shape this repo keeps
# finding -- #275's preview/apply drift and #331's second pruning pass).
$twice = Add-ResolvesBlock -Body $appended -Issues @(332)
Assert-Equal 1 (@([regex]::Matches($twice, '(?m)^Closes #332$')).Count) 'idempotent: #332 is not closed twice'
$mixed = Add-ResolvesBlock -Body $appended -Issues @(332, 331)
Assert-Equal 1 (@([regex]::Matches($mixed, '(?m)^Closes #332$')).Count) 'already-closed number not repeated'
Assert-Equal 1 (@([regex]::Matches($mixed, '(?m)^Closes #331$')).Count) 'the new number IS added'
$fromEmpty = Add-ResolvesBlock -Body '' -Issues @(332)
Assert-True ($fromEmpty -match '(?m)^Closes #332$') 'an empty body still gets the block'

Write-Host "Get-ResolvesDecision -- the gate's whole table" -ForegroundColor Cyan

$explicit = Get-ResolvesDecision -Resolves @(331, 332) -OpenMentions @(340)
Assert-Equal $true      $explicit.Allowed 'explicit -Resolves -> allowed'
Assert-Set  @(331, 332) $explicit.Issues  'explicit -Resolves -> those issues'

$no = Get-ResolvesDecision -NoResolves -OpenMentions @(340)
Assert-Equal $true $no.Allowed  '-NoResolves -> allowed even with an open mention'
Assert-Set  @()    $no.Issues   '-NoResolves -> closes nothing'

$viaBody = Get-ResolvesDecision -Body 'Closes #332' -OpenMentions @(332)
Assert-Equal $true  $viaBody.Allowed 'a body with a closing keyword satisfies the gate'
Assert-Set  @(332)  $viaBody.Issues  'the issues come from the body'

$blocked = Get-ResolvesDecision -Body 'this fixes the thing from #332' -OpenMentions @(332)
Assert-Equal $false $blocked.Allowed 'open mention + no decision -> BLOCKED'
Assert-Set  @(332)  $blocked.Blocked 'the blocked verdict names the issue'
Assert-Set  @()     $blocked.Issues  'a blocked verdict closes nothing'

$closedOnly = Get-ResolvesDecision -Body 'context from #300' -OpenMentions @()
Assert-Equal $true $closedOnly.Allowed 'mentions that are not open issues -> allowed'
Assert-Set  @()    $closedOnly.Issues  'nothing to close'

# The deliberate escape hatch: an unknown open/closed state must NOT block. A gate that wedges the
# PR flow on a network hiccup is worse than the bookkeeping slip it guards against.
$unknown = Get-ResolvesDecision -Body 'mentions #332' -OpenMentions $null
Assert-Equal $true $unknown.Allowed 'undeterminable state -> allowed (warn, never wedge)'
Assert-True ($unknown.Reason -match 'could not be determined') 'and the reason says so'

# -Resolves wins over -NoResolves when both are passed: an explicit list is a more specific
# statement than a blanket "nothing", so it must not be silently discarded.
$both = Get-ResolvesDecision -Resolves @(331) -NoResolves
Assert-Equal $true $both.Allowed  'both flags -> allowed'
Assert-Set  @(331) $both.Issues   '-Resolves wins over -NoResolves'

Write-Host "Get-ResolvesDecision -- Undeclared (review finding: a partial -Resolves went silent)" -ForegroundColor Cyan
# -Resolves naming one of two open mentions used to leave the second invisible: allowed, unclosed, and
# unreported -- a partial recurrence of the very failure this gate was built for. It must not BLOCK
# (closing one of two is legitimate) but it must be SAID.
$partial = Get-ResolvesDecision -Resolves @(332) -OpenMentions @(332, 400)
Assert-Equal $true  $partial.Allowed    'partial -Resolves is still allowed (not a block)'
Assert-Set  @(332)  $partial.Issues     'only the declared issue is closed'
Assert-Set  @(400)  $partial.Undeclared 'the undeclared open mention IS reported'

$full = Get-ResolvesDecision -Resolves @(332, 400) -OpenMentions @(332, 400)
Assert-Set  @()     $full.Undeclared    'declaring all of them reports nothing'

# -NoResolves answers for every mentioned issue, so repeating them would turn a decision into a nag.
$noNag = Get-ResolvesDecision -NoResolves -OpenMentions @(332, 400)
Assert-Set  @()     $noNag.Undeclared   '-NoResolves reports no undeclared issues'

# A body-carried keyword is a declaration like any other, so the same reporting applies to it.
$bodyPartial = Get-ResolvesDecision -Body 'Closes #332' -OpenMentions @(332, 400)
Assert-Set  @(332)  $bodyPartial.Issues     'the body declaration is honoured'
Assert-Set  @(400)  $bodyPartial.Undeclared 'and the rest is still reported'

# Unknown state -> nothing to compare against, so nothing is claimed.
$unknownUndeclared = Get-ResolvesDecision -Resolves @(332) -OpenMentions $null
Assert-Set  @()     $unknownUndeclared.Undeclared 'an undeterminable state reports no undeclared issues'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
