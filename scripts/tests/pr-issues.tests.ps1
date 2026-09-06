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

function Assert-NameSet {
    <#
        The same comparison for CHECK NAMES rather than issue numbers, and a separate function because
        Assert-Set is [int[]] on purpose: handed 'claude-review' it does not fail the assert, it throws
        a parameter-transformation error mid-suite. Names are compared order-insensitively too -- the
        verdict sorts its lists, and an assert that also pinned the order would fail on a resort that
        changed nothing.
    #>
    param([string[]]$Expected, [string[]]$Actual, [string]$Name)
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

# THE EN AND EM DASH RANGES, which nothing exercised until August 23, 2026. The dash class in
# Get-IssueMentions has carried all three characters since it was written, and only the ASCII hyphen
# was ever asserted -- so the two typographic dashes were live, unmeasured behaviour. That became
# load-bearing the day the class stopped being a literal and started being composed from code points
# ($dashes, for the repo's ASCII rule on .ps1): a composition that silently produced the wrong two
# characters would still match every hyphen assert above and change nothing a suite could see.
# A range written with a real en dash is not exotic -- it is what a word processor and most editors
# produce from '#341-#343' on their own, so a changelog entry pasted from anywhere reaches this path.
# Built from code points here too, for the same reason the lib is.
$enDash = [char]0x2013
$emDash = [char]0x2014
Assert-Set @()    (Get-IssueMentions -Text "as PRs #341$enDash#343 showed")   'PRs #341<en dash>#343 RANGE form excluded'
Assert-Set @()    (Get-IssueMentions -Text "as PRs #341$emDash#343 showed")   'PRs #341<em dash>#343 RANGE form excluded'
Assert-Set @()    (Get-IssueMentions -Text "PR #341$enDash#343 covered it")   'singular PR + en-dash RANGE -> excluded (unambiguous)'
Assert-Set @(332) (Get-IssueMentions -Text "PRs #341$enDash#343 each left #332 open") 'the en-dash range scrub stops at the list, #332 still found'

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
Assert-True ($block -match '## Resolved issues')  'block carries its heading, at H2 by default -- what every consumer body still uses'

# THE LEVEL IS A PARAMETER, AND THAT IS A CORRECTNESS FIX RATHER THAN STYLING (August 9, 2026). The
# block must be a SIBLING of the description: -RefreshBody replaces the description by scanning to the
# next heading at its level or shallower, so a block DEEPER than the description sits inside it and is
# deleted by the next refresh -- taking the closing keywords with it. GitHub would then close nothing at
# the merge, which is the #341-#343 failure walking back in through the door built to stop it.
$blockH1 = New-ResolvesBlock -Issues @(7) -Level 1
Assert-True ($blockH1 -match '(?m)^# Resolved issues$')  'the level is honoured: H1 for a body whose description is H1'
Assert-True ($blockH1 -match '(?m)^Closes #7$')          'and the closing keyword is unaffected by the level'
Assert-Set @(7) (Get-ClosedIssueNumbers -Text $blockH1)  'the reader is keyword-based, so it reads an H1 block exactly as it reads an H2 one'

# Add-ResolvesBlock DERIVES the level from the body it is appending to, so no caller has to remember.
$h1Body = "# What does the change on this branch bring to main?`n`nSome text."
Assert-True ((Add-ResolvesBlock -Body $h1Body -Issues @(9)) -match '(?m)^# Resolved issues$') 'an H1 body gets an H1 block'
$h2Body = "## What does this change do?`n`nSome text."
Assert-True ((Add-ResolvesBlock -Body $h2Body -Issues @(9)) -match '(?m)^## Resolved issues$') "a consumer's H2 body still gets an H2 block"
$noHeading = 'just a paragraph'
Assert-True ((Add-ResolvesBlock -Body $noHeading -Issues @(9)) -match '(?m)^## Resolved issues$') 'a body with no heading falls back to H2, the level every body carried before this'
# A fenced heading is sample text and must not decide the level of a real section.
$fencedFirst = "``````text`n# not a heading`n```````n`n## Real heading`n`ntext"
Assert-True ((Add-ResolvesBlock -Body $fencedFirst -Issues @(9)) -match '(?m)^## Resolved issues$') 'a heading inside a fence does not set the level'
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
Write-Host "Get-TargetIssueWarnings -- the already-done check (issue #1282)" -ForegroundColor Cyan
# The gap #1282 measured: the resolves gate blocks only on a mentioned issue that is still OPEN, so a
# branch targeting an issue that has since been CLOSED, or one another open/merged PR already resolves,
# reaches a gate-green PR and is found at the merge conflict. This helper is the facts behind the
# warning; it never blocks.

Assert-Equal 0 (@(Get-TargetIssueWarnings -TargetIssues @()).Count) 'no target issues -> nothing to say'

# Target still open, no rival PR -> nothing to say.
$stillOpen = @(Get-TargetIssueWarnings -TargetIssues @(1270) -OpenIssues @(1270, 42))
Assert-Equal 0 $stillOpen.Count 'an open target with no rival PR produces no warning'

# Target CLOSED (the open list is known and does not contain it).
$closed = @(Get-TargetIssueWarnings -TargetIssues @(1270) -OpenIssues @(42, 99))
Assert-Equal 1     $closed.Count       'a closed target produces one record'
Assert-Equal 1270  $closed[0].Issue    'the record names the issue'
Assert-True  $closed[0].IsClosed       'and marks it closed'
Assert-Equal 0     @($closed[0].ClaimingPrs).Count 'with no claiming PR when none was supplied'

# Open list undeterminable -> IsClosed is never asserted (the not-blocking treatment).
$noList = @(Get-TargetIssueWarnings -TargetIssues @(1270) -OpenIssues $null)
Assert-Equal 0 $noList.Count 'an undeterminable open-issue state claims nothing'

# A rival OPEN PR whose body closes the number.
$rivalJson = '[{"number":1276,"state":"OPEN","headRefName":"fix/other-v1","body":"Closes #1270"}]'
$rival = @(Get-TargetIssueWarnings -TargetIssues @(1270) -OpenIssues @(1270) -OtherPrsJson $rivalJson -CurrentBranch 'fix/mine-v1')
Assert-Equal 1     $rival.Count                  'a rival PR that closes the number produces a record'
Assert-Equal $false $rival[0].IsClosed           'the issue itself is still open here'
Assert-Equal 1276  @($rival[0].ClaimingPrs)[0].Number 'the claiming PR number comes through'
Assert-Equal 'OPEN' @($rival[0].ClaimingPrs)[0].State 'and its state'

# A MERGED rival counts too -- that is the exact #1282 case.
$mergedJson = '[{"number":1276,"state":"MERGED","headRefName":"fix/other-v1","body":"Closes #1270"}]'
$merged = @(Get-TargetIssueWarnings -TargetIssues @(1270) -OpenIssues @(1270) -OtherPrsJson $mergedJson -CurrentBranch 'fix/mine-v1')
Assert-Equal 'MERGED' @($merged[0].ClaimingPrs)[0].State 'a merged rival is reported'

# A CLOSED rival PR is an abandoned attempt (in #1282, the duplicate itself) -- NOT evidence the work is done.
$closedRivalJson = '[{"number":1281,"state":"CLOSED","headRefName":"fix/other-v1","body":"Closes #1270"}]'
$closedRival = @(Get-TargetIssueWarnings -TargetIssues @(1270) -OpenIssues @(1270) -OtherPrsJson $closedRivalJson -CurrentBranch 'fix/mine-v1')
Assert-Equal 0 $closedRival.Count 'a CLOSED rival PR is not reported'

# This branch's OWN open PR carries the keyword by design on a resumed run -- not a rival.
$ownJson = '[{"number":500,"state":"OPEN","headRefName":"fix/mine-v1","body":"Closes #1270"}]'
$own = @(Get-TargetIssueWarnings -TargetIssues @(1270) -OpenIssues @(1270) -OtherPrsJson $ownJson -CurrentBranch 'fix/mine-v1')
Assert-Equal 0 $own.Count "this branch's own PR is never reported as a rival claimant"

# A rival PR that only MENTIONS the number (no closing keyword) does not count -- same reader as the gate.
$mentionOnlyJson = '[{"number":1276,"state":"MERGED","headRefName":"fix/other-v1","body":"context from #1270, unrelated"}]'
$mentionOnly = @(Get-TargetIssueWarnings -TargetIssues @(1270) -OpenIssues @(1270) -OtherPrsJson $mentionOnlyJson -CurrentBranch 'fix/mine-v1')
Assert-Equal 0 $mentionOnly.Count 'a bare mention in a rival PR body is not a claim'

# Unparseable PR JSON -> no claiming PRs, and IsClosed is still evaluated from the open list.
$badJson = @(Get-TargetIssueWarnings -TargetIssues @(1270) -OpenIssues @(42) -OtherPrsJson 'not json' -CurrentBranch 'fix/mine-v1')
Assert-Equal 1 $badJson.Count            'unparseable PR JSON does not throw'
Assert-True  $badJson[0].IsClosed        'and the closed-target signal still fires'
Assert-Equal 0 @($badJson[0].ClaimingPrs).Count 'with no claiming PR from JSON that would not parse'

# The whole #1282 scenario in one call: target #1270, closed; PR #1276 merged resolving it; PR #1281
# closed on this branch also carrying the keyword. One record: closed, claimed by #1276 alone.
$scenarioJson = '[{"number":1276,"state":"MERGED","headRefName":"fix/unfolded-entry-on-main-unguarded-v1","body":"Closes #1270"},{"number":1281,"state":"CLOSED","headRefName":"fix/unfolded-entry-on-main-sessioncheck-v1","body":"Closes #1270"}]'
$scenario = @(Get-TargetIssueWarnings -TargetIssues @(1270) -OpenIssues @(42, 99) -OtherPrsJson $scenarioJson -CurrentBranch 'fix/unfolded-entry-on-main-sessioncheck-v1')
Assert-Equal 1     $scenario.Count       'the #1282 scenario produces exactly one record'
Assert-True  $scenario[0].IsClosed       'the target is reported closed'
Assert-Equal 1     @($scenario[0].ClaimingPrs).Count 'and exactly one claiming PR (the merged one, not the abandoned duplicate)'
Assert-Equal 1276  @($scenario[0].ClaimingPrs)[0].Number 'which is #1276'

# Two target issues, one closed and one open+claimed -> a record for each, with the right signal.
$twoJson = '[{"number":90,"state":"OPEN","headRefName":"fix/other-v1","body":"Closes #401"}]'
$two = @(Get-TargetIssueWarnings -TargetIssues @(400, 401) -OpenIssues @(401) -OtherPrsJson $twoJson -CurrentBranch 'fix/mine-v1')
Assert-Equal 2 $two.Count 'both targets that have something to say are reported'
$rec400 = $two | Where-Object { $_.Issue -eq 400 }
$rec401 = $two | Where-Object { $_.Issue -eq 401 }
Assert-True  $rec400.IsClosed                       '#400 is closed'
Assert-Equal 0 @($rec400.ClaimingPrs).Count         'and has no claiming PR'
Assert-Equal $false $rec401.IsClosed                '#401 is still open'
Assert-Equal 90 @($rec401.ClaimingPrs)[0].Number    'but is claimed by PR #90'

Write-Host ""
Write-Host "Get-ExistingPrRecord" -ForegroundColor Cyan

# What open-pr.ps1 does with the answer: an existing PR means the gates and the push still run but
# `gh pr create` is skipped, and the existing body's closing keywords count as a declaration. So a
# WRONG answer here is not a crash -- it silently opens a duplicate or blocks a resumable branch.

# The empty list is the ordinary "no PR yet" answer and MUST read as $null, not as a record. In 5.1
# indexing the parsed result with [0] also yields $null here, which is why this is asserted rather
# than assumed: the two forms agree on this case and disagree on the next one.
Assert-True ($null -eq (Get-ExistingPrRecord -Json '[]')) 'an empty list means no existing PR'

# One record -- the case that matters, and the one where the 5.1 pitfall bites: with `@(... |
# ConvertFrom-Json)` the single collected element IS the whole Object[], so .number would be an
# array member-enumeration rather than the number.
$one = Get-ExistingPrRecord -Json '[{"number":457,"url":"https://github.com/o/r/pull/457","body":"Closes #123"}]'
Assert-True ($null -ne $one)                'a single record is found'
Assert-Equal 457 $one.number                'the number is the record field, not an enumerated array'
Assert-Equal 'https://github.com/o/r/pull/457' $one.url 'the url comes through'
Assert-Equal 'Closes #123' $one.body        'the body comes through, so the gate can read it'

# The body of a found record has to satisfy the resolves gate on its own -- otherwise resuming the
# branch would demand a decision that is already published on the PR and cannot be changed by
# declaring it again here.
Assert-True (Test-HasClosingKeyword -Text $one.body) "a found record's body satisfies the resolves gate"
$fromExisting = Get-ResolvesDecision -Body $one.body -OpenMentions @(123)
Assert-True $fromExisting.Allowed           'and the gate therefore allows the resumed PR'
Assert-Set  @(123) $fromExisting.Issues     'crediting the issue the existing body declares'

# --limit 1 is what open-pr passes, but the parser must not depend on gh honouring it.
$first = Get-ExistingPrRecord -Json '[{"number":10,"body":"a"},{"number":11,"body":"b"}]'
Assert-Equal 10 $first.number               'the FIRST record wins when gh returns several'

# Every unreadable answer collapses to "no existing PR". That is deliberate and not an oversight: the
# caller then behaves exactly as it did before this feature existed -- a duplicate `gh pr create` that
# gh refuses with its own message -- instead of wedging the PR flow on a bad payload.
Assert-True ($null -eq (Get-ExistingPrRecord -Json 'not json at all')) 'unparseable JSON means no existing PR'
Assert-True ($null -eq (Get-ExistingPrRecord -Json ''))                'empty input means no existing PR'
Assert-True ($null -eq (Get-ExistingPrRecord -Json '   '))             'whitespace means no existing PR'
Assert-True ($null -eq (Get-ExistingPrRecord -Json '[{"url":"https://x/1"}]')) 'a record without a number is not believed'

# THE SHAPE THIS FUNCTION REPLACED, asserted as wrong on purpose. ship-pr.ps1's step 2 used
#     $prs = @($prList.Output | ConvertFrom-Json); $pr = $prs[0].number
# and both halves fail in 5.1: the count is 1 even for an empty list, so its `-lt 1` guard was dead
# code, and $prs[0] is the whole Object[], whose .number member-enumerates to the EMPTY STRING when
# there is nothing. The script then ran `gh pr merge ''`. These two asserts exist so a future
# simplification back to that form fails here instead of on main.
$oldShapeEmpty = @('[]' | ConvertFrom-Json)
Assert-Equal 1  $oldShapeEmpty.Count      'the replaced @(text | ConvertFrom-Json) shape counts 1 for an empty list'
Assert-Equal '' "$($oldShapeEmpty[0].number)" 'and yields the empty string as a PR number'
Assert-True ($null -eq (Get-ExistingPrRecord -Json '[]')) 'Get-ExistingPrRecord answers $null there, so the guard can fire'

# The append path: what open-pr writes back when this run declares an issue the existing body lacks.
# Idempotent per issue, so a rerun does not stack duplicate blocks -- asserted here because the caller
# decides whether to call `gh pr edit` by comparing against the original string.
$appended = Add-ResolvesBlock -Body $one.body -Issues @(123, 456)
Assert-Set  @(123, 456) (Get-ClosedIssueNumbers -Text $appended) 'the missing issue is appended, the present one kept'
Assert-Equal $appended (Add-ResolvesBlock -Body $appended -Issues @(123, 456)) 'appending twice changes nothing'
Assert-Equal $one.body (Add-ResolvesBlock -Body $one.body -Issues @(123)) 'nothing to add leaves the body identical (no pr edit call)'


# --- Get-CheckWaitReport: which check governed the merge wait (issue #831) ------------------------
# The SELECTION is what a suite can reach; the gh call is not. So every assert here is about the
# payload -> line mapping, and the shapes that must NOT produce a line are asserted as loudly as the
# ones that must: a fabricated ordering is worse than a missing one, which is the whole reason #831
# exists -- it was opened because two readings from a sample of three had been quoted as a tendency.
Write-Host ""
Write-Host "Get-CheckWaitReport -- which check governed the wait" -ForegroundColor Cyan

Assert-Equal '0s'      (Format-CheckDuration -Seconds 0)    'duration: zero reads as 0s -- the median answer here, not an unmeasured one'
Assert-Equal '59s'     (Format-CheckDuration -Seconds 59)   'duration: below a minute stays in seconds'
Assert-Equal '1m 00s'  (Format-CheckDuration -Seconds 60)   'duration: a whole minute pads the seconds'
Assert-Equal '9m 08s'  (Format-CheckDuration -Seconds 548)  'duration: seconds are zero-padded so a column lines up'
Assert-Equal '14m 05s' (Format-CheckDuration -Seconds 845)  'duration: matches the shape the release notes already use'
Assert-Equal ''        (Format-CheckDuration -Seconds -1)   'duration: unmeasured returns empty, so a caller can concatenate'

# Both timestamp shapes must land on the same answer: 5.1's ConvertFrom-Json hands back a [datetime],
# other editions can hand back the string. A reader of only one of them would mis-order on the other.
$asText = ConvertTo-CheckTimestamp -Value '2026-08-24T09:14:05Z'
$asDate = ConvertTo-CheckTimestamp -Value ([datetime]::Parse('2026-08-24T09:14:05Z').ToUniversalTime())
Assert-Equal $asDate.Ticks $asText.Ticks 'timestamp: a string and an already-parsed [datetime] agree'
Assert-True ($null -eq (ConvertTo-CheckTimestamp -Value $null)) 'timestamp: absent is $null, not the epoch'
Assert-True ($null -eq (ConvertTo-CheckTimestamp -Value ''))    'timestamp: empty is $null'
Assert-True ($null -eq (ConvertTo-CheckTimestamp -Value 'soon')) 'timestamp: unreadable is $null rather than a throw'

$twoChecks = @'
[
  {"name":"lint-en-tests","startedAt":"2026-08-24T09:00:00Z","completedAt":"2026-08-24T09:09:58Z"},
  {"name":"claude-review","startedAt":"2026-08-24T09:00:00Z","completedAt":"2026-08-24T09:14:05Z"}
]
'@
$requiredOnly = '[{"name":"lint-en-tests"}]'

$line = Get-CheckWaitReport -ChecksJson $twoChecks -RequiredNamesJson $requiredOnly -WaitedSeconds 845
Assert-True ($line -like "*'claude-review' finished last*")        'the check that finished LAST is the one named as governing'
Assert-True ($line -like '*NOT required*')                         'and it is labelled against the ruleset, never against a hardcoded name'
Assert-True ($line -like '*14m 05s*')                              'its own duration is reported'
Assert-True ($line -like '*4m 07s after the last required check*') 'the excess over the last required check is what this run actually paid'
Assert-True ($line -like '*waited 14m 05s*')                       'the wall-clock the script itself spent is stated separately'

# The ordinary case, and the one nobody could see before: the required check governs and the
# non-required one finished long ago. Measured at 77 of 100 runs -- so this is the line that must not
# invent a cost out of an ordering it does not have.
$requiredGoverns = @'
[
  {"name":"lint-en-tests","startedAt":"2026-08-24T09:00:00Z","completedAt":"2026-08-24T09:08:37Z"},
  {"name":"claude-review","startedAt":"2026-08-24T09:00:00Z","completedAt":"2026-08-24T09:03:02Z"}
]
'@
$line2 = Get-CheckWaitReport -ChecksJson $requiredGoverns -RequiredNamesJson $requiredOnly -WaitedSeconds 517
Assert-True ($line2 -like "*'lint-en-tests' finished last*") 'the required check governing is reported as plainly as the other way round'
Assert-True ($line2 -like '*, required*')                    'and labelled required'
Assert-True (-not ($line2 -like '*after the last required check*')) 'no excess is stated when the required check governed -- there is none'

# Without the required set the line still says which check governed, and says NOTHING about required.
$line3 = Get-CheckWaitReport -ChecksJson $twoChecks -WaitedSeconds 845
Assert-True ($line3 -like "*'claude-review' finished last*") 'an unknown ruleset does not cost the reader the ordering'
Assert-True (-not ($line3 -like '*required*'))               'but an unknown answer is left unstated rather than guessed'

# A ruleset payload that does not parse must behave exactly as an absent one, never as "not required".
$line4 = Get-CheckWaitReport -ChecksJson $twoChecks -RequiredNamesJson 'not json at all' -WaitedSeconds 845
Assert-True (-not ($line4 -like '*required*')) 'an unparseable ruleset payload degrades to silence, not to a wrong label'

# Unmeasured wall-clock is omitted rather than printed as zero -- 0s is a real, common answer here.
$line5 = Get-CheckWaitReport -ChecksJson $twoChecks -RequiredNamesJson $requiredOnly
Assert-True (-not ($line5 -like '*waited*'))                 'an unmeasured wait is left out, so it cannot be read as 0s'
Assert-True ($line5 -like "*'claude-review' finished last*") 'while the ordering is still reported'

# Every shape that cannot answer the question returns $null, so the caller prints its own fallback.
Assert-True ($null -eq (Get-CheckWaitReport -ChecksJson ''))     'empty payload: no line'
Assert-True ($null -eq (Get-CheckWaitReport -ChecksJson '   '))  'whitespace payload: no line'
Assert-True ($null -eq (Get-CheckWaitReport -ChecksJson '[]'))   'empty list: no line -- the 5.1 array trap that bit Get-ExistingPrRecord'
Assert-True ($null -eq (Get-CheckWaitReport -ChecksJson 'nope')) 'unparseable payload: no line'
Assert-True ($null -eq (Get-CheckWaitReport -ChecksJson '[{"name":"x"}]')) 'a check with no completedAt cannot have finished last'
Assert-True ($null -eq (Get-CheckWaitReport -ChecksJson '[{"completedAt":"2026-08-24T09:00:00Z"}]')) 'a nameless record cannot be named'

# A check with no startedAt still finished, and still governed. Report the ordering, not a duration.
$noStart = '[{"name":"claude-review","completedAt":"2026-08-24T09:14:05Z"}]'
$line6 = Get-CheckWaitReport -ChecksJson $noStart -WaitedSeconds 845
Assert-True ($line6 -like "*'claude-review' finished last*") 'a missing startedAt does not cost the ordering'
Assert-True ($line6 -like '*duration unknown*')              'and the duration says so instead of being computed from nothing'

# A single check is the common shape in a repo with one workflow, and it governs by definition.
$onlyOne = '[{"name":"lint-en-tests","startedAt":"2026-08-24T09:00:00Z","completedAt":"2026-08-24T09:09:58Z"}]'
$line7 = Get-CheckWaitReport -ChecksJson $onlyOne -RequiredNamesJson $requiredOnly -WaitedSeconds 598
Assert-True ($line7 -like "*'lint-en-tests' finished last*") 'one check governs its own wait -- Sort-Object over a single item still answers'
Assert-True ($line7 -like '*, required*')                    'and is still labelled from the ruleset'

# --- THE ZERO TIMESTAMP: a check that has NOT finished yet (issue #977) ---------------------------
#
# `gh pr checks --json` serialises an unfinished check's completedAt as `0001-01-01T00:00:00Z` -- the
# THIRD shape, alongside a real stamp and an absent field, and the one nothing above reached. Every
# assert in this suite fed it stamps that were either real or missing, so the report was only ever
# exercised on payloads where the race had already resolved. It cost a live run in a consumer repo: the
# [int] cast overflowed on -63,923,427,029 seconds AFTER `CI green.` was printed and BEFORE the merge,
# leaving the PR unmerged and the entry unfolded with every check green.
#
# THE CRASH IS THE SMALLER HALF. An unfinished check did not govern the wait, so the fix has to produce
# the RIGHT line and not merely a surviving one -- which is what the first two asserts below pin.
$zeroCompleted = @'
[
  {"name":"lint-en-tests","startedAt":"2026-08-24T09:00:00Z","completedAt":"2026-08-24T09:09:58Z"},
  {"name":"claude-review","startedAt":"2026-08-24T09:09:00Z","completedAt":"0001-01-01T00:00:00Z"}
]
'@
$line8 = Get-CheckWaitReport -ChecksJson $zeroCompleted -RequiredNamesJson $requiredOnly -WaitedSeconds 598
Assert-True ($line8 -like "*'lint-en-tests' finished last*") 'a check that has not finished cannot have finished last'
Assert-True (-not ($line8 -like '*claude-review*'))          'so it takes no part in the ordering at all'
Assert-True ($line8 -like '*9m 58s*')                        'and the check that DID finish still reports its own duration'

# Both timestamp shapes carry it, and only one of them was proposed for repair in #977. In 5.1 which one
# arrives depends on the edition rather than the payload, so a guard on either alone works on one
# machine and overflows on the next -- measured: this machine hands the zero date through as a STRING.
Assert-True ($null -eq (ConvertTo-CheckTimestamp -Value '0001-01-01T00:00:00Z')) 'timestamp: gh zero time as a string is unreadable, not the floor of the type'
Assert-True ($null -eq (ConvertTo-CheckTimestamp -Value ([datetime]::MinValue)))  'timestamp: and as an already-parsed [datetime] too'
Assert-True ($null -eq (Get-CheckWaitReport -ChecksJson '[{"name":"x","completedAt":"0001-01-01T00:00:00Z"}]')) 'a payload of nothing but unfinished checks answers nothing -- no line, no throw'

# The zero date on startedAt costs the duration and nothing else: the check finished, so it still orders.
$zeroStarted = '[{"name":"lint-en-tests","startedAt":"0001-01-01T00:00:00Z","completedAt":"2026-08-24T09:09:58Z"}]'
$line9 = Get-CheckWaitReport -ChecksJson $zeroStarted -RequiredNamesJson $requiredOnly -WaitedSeconds 598
Assert-True ($line9 -like "*'lint-en-tests' finished last*") 'a zero startedAt does not cost the ordering'
Assert-True ($line9 -like '*duration unknown*')              'and the duration says so rather than being computed from the floor of the type'

# THE CLASS, not just the door #977 came through. A readable but absurd stamp is a span no [int] holds,
# from the same untrusted field, and it would reach the same cast -- at BOTH arithmetic sites. The second
# is only reachable when a non-required check governs, which is why the excess payload is asserted too.
$farFuture = '[{"name":"lint-en-tests","startedAt":"2026-08-24T09:00:00Z","completedAt":"9999-12-31T23:59:59Z"}]'
$line10 = Get-CheckWaitReport -ChecksJson $farFuture -RequiredNamesJson $requiredOnly -WaitedSeconds 598
Assert-True ($line10 -like '*duration unknown*') 'a duration too large for an [int] is unmeasured, not a throw'
$farFutureExcess = @'
[
  {"name":"lint-en-tests","startedAt":"2026-08-24T09:00:00Z","completedAt":"2026-08-24T09:09:58Z"},
  {"name":"claude-review","startedAt":"2026-08-24T09:00:00Z","completedAt":"9999-12-31T23:59:59Z"}
]
'@
$line11 = Get-CheckWaitReport -ChecksJson $farFutureExcess -RequiredNamesJson $requiredOnly -WaitedSeconds 598
Assert-True ($line11 -like "*'claude-review' finished last*")         'the excess site survives the same input'
Assert-True (-not ($line11 -like '*after the last required check*'))  'and an excess it cannot measure is left out rather than stated wrong'

# The helper itself, so the ordering of round-check-cast is pinned rather than inferred from the lines
# above. -1 is the vocabulary both callers already read as unmeasured, which Format-CheckDuration turns
# into '' -- so an unrenderable duration concatenates away instead of aborting the run printing it.
Assert-Equal 598 (ConvertTo-CheckSeconds -Span ([timespan]::FromSeconds(598)))     'seconds: an ordinary span is a whole number of seconds'
Assert-Equal 1   (ConvertTo-CheckSeconds -Span ([timespan]::FromMilliseconds(501))) 'seconds: rounded, not truncated'
Assert-Equal -1  (ConvertTo-CheckSeconds -Span ([timespan]::FromSeconds(-5)))      'seconds: a negative span is unmeasured, which is what the guard was always meant to catch'
Assert-Equal -1  (ConvertTo-CheckSeconds -Span ([timespan]::FromDays(100000)))     'seconds: and so is one no [int] holds -- range-checked BEFORE the cast, or the cast throws first'
# --- -Resolves TOGETHER WITH -RefreshBody: the block must survive the refresh (#919) -----------------
#
# THE #341-#343 FAILURE REACHED THROUGH THE DOOR BUILT TO PREVENT IT. Everything above asserts that the
# closing block is COMPOSED correctly; nothing asserted that it still reaches GitHub. On PR #916,
# 'open-pr.ps1 -Resolves 913 -RefreshBody' published a body closing nothing: the two body edits run
# SEQUENTIALLY on one variable, the block was appended first, and the refresh then replaced it. The run
# printed a lost-section warning and exited 0, which is why it read as a success.
#
# WHY THE REFRESH CAN REACH THAT FAR is local to a heading-less PR template, which is this repo's shape:
# with no heading above the placeholder the description is the body's LEADING section, and with no
# heading below it there is no stop -- so the leading section is the whole body. Both halves are
# Update-PrBodySection's documented behaviour, and both are right on their own. It is the ORDER that
# loses the block, which is why this section asserts the composition rather than either lib.
Write-Host "-Resolves survives -RefreshBody (#919)" -ForegroundColor Cyan

# Dot-sourced HERE rather than beside the lib at the top, deliberately: this is the one section that
# needs the other PR lib, and the reason it needs it IS the finding -- each lib was correct alone.
. (Join-Path $PSScriptRoot '..\lib\pr-body-lib.ps1')

# The published body of an open PR in this repo: the pasted DEPLOY section, then the block open-pr
# appended on an earlier run. No heading precedes it, exactly as the template produces.
$publishedBody = @'
### DEPLOY: `fix/refresh-body-drops-the-resolves-block-v1`

The description as it was published, which the refresh is about to rewrite.

### Resolved issues

Closes #919
'@
$entryDescription = @'
### DEPLOY: `fix/refresh-body-drops-the-resolves-block-v1`

The description as the changelog entry now words it.
'@

Assert-Set @(919) (Get-ClosedIssueNumbers -Text $publishedBody) 'setup: the published body closes #919 before either edit runs'

# THE MECHANISM, PINNED. A leading-section refresh with no stops replaces the whole body -- so the old
# order really did lose the block, and this assert is what would notice if that ever stopped being true
# (a template gaining a heading changes the answer, and this section would then need re-reading).
$oldOrder = Add-ResolvesBlock -Body $publishedBody -Issues @(919)
$oldOrder = Update-PrBodySection -Body $oldOrder -Heading '' -Content $entryDescription -StopAtHeading @()
Assert-Set @() (Get-ClosedIssueNumbers -Text $oldOrder) 'append-then-refresh loses the closing keyword -- the shape measured on PR #916'

# THE ORDER open-pr.ps1 RUNS SINCE #919: refresh first, append last. No new knowledge of stops or
# heading levels is needed for it -- the append is idempotent per issue, so it restores what the
# rewrite took and is a no-op where nothing was taken.
$newOrder = Update-PrBodySection -Body $publishedBody -Heading '' -Content $entryDescription -StopAtHeading @()
$newOrder = Add-ResolvesBlock -Body $newOrder -Issues @(919)
Assert-Set @(919) (Get-ClosedIssueNumbers -Text $newOrder) 'refresh-then-append keeps the closing keyword -- GitHub still closes #919 at the merge'
Assert-True ($newOrder -like '*the changelog entry now words it*') 'and the refresh still did its own job'

# ONE BLOCK, NOT TWO. The append runs on every -Resolves run, so a body the refresh did NOT eat must
# come back unchanged -- a second 'Closes #919' would be a duplicate section on every push.
$survived = Add-ResolvesBlock -Body $publishedBody -Issues @(919)
Assert-Equal $publishedBody $survived 'appending to a body that already closes the issue is a no-op, so a surviving block is not doubled'
Assert-Equal 1 ([regex]::Matches($newOrder, '(?m)^\s*Closes\s+#919\b').Count) 'exactly one closing keyword in the assembled body'

# AND THE SCRIPT ITSELF STILL RUNS THEM IN THAT ORDER. The asserts above prove the composition; this one
# proves open-pr.ps1 uses it, which is the half that was wrong. Read from the source for the same reason
# the placeholder coupling in pr-body.tests.ps1 is: nothing else can see a re-swap, and it fails silently.
$openPrPath = Join-Path $PSScriptRoot '..\release\open-pr.ps1'
Assert-True (Test-Path -LiteralPath $openPrPath) 'open-pr.ps1 exists where this suite looks for it'
$openPrText  = [System.IO.File]::ReadAllText((Resolve-Path $openPrPath).Path, [System.Text.Encoding]::UTF8)
$idxExisting = $openPrText.IndexOf('if ($existingPr) {')
$idxRefresh  = if ($idxExisting -ge 0) { $openPrText.IndexOf('if ($RefreshBody) {', $idxExisting) } else { -1 }
$idxAppend   = if ($idxExisting -ge 0) { $openPrText.IndexOf('Add-ResolvesBlock -Body $newBody', $idxExisting) } else { -1 }
Assert-True ($idxExisting -ge 0) 'the existing-PR path is still recognisable in open-pr.ps1'
Assert-True ($idxRefresh -gt $idxExisting) 'the -RefreshBody block sits on the existing-PR path'
Assert-True ($idxAppend -gt $idxRefresh)   'open-pr.ps1 appends the closing block AFTER the refresh, not before it (#919)'

# --- The merge verdict: which check failing actually blocks a merge (issue #943) ------------------
#
# WHY THIS SUITE EXISTS. ship-pr.ps1 read the exit code of `gh pr checks --watch` as its merge verdict.
# That exit code is non-zero when ANY check fails, so one broken advisory workflow refused every merge:
# on August 26, 2026 `claude-review` was red on every PR (#942) while `lint-en-tests` -- the only check
# the `main` ruleset requires -- was green, and GitHub itself called those PRs MERGEABLE / UNSTABLE.
# The live remote no suite can reach is the query; the SELECTION is what is asserted here.
#
# The payloads below are the real ones, read off PR #937 that day:
#   gh pr checks 937 --json name,bucket,state           -> claude-review fail, branch-entry + lint pass
#   gh pr checks 937 --required --json name,bucket,state -> lint-en-tests pass
# Both returned EXIT 0. That is the reason every assert here feeds a payload rather than an exit code:
# in --json mode gh reports the outcome in the records and not in its exit status.

Assert-Equal 'pass'    (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a'; bucket = 'pass' }))     'bucket pass -> pass'
Assert-Equal 'fail'    (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a'; bucket = 'fail' }))     'bucket fail -> fail'
Assert-Equal 'pending' (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a'; bucket = 'pending' }))  'bucket pending -> pending'
Assert-Equal 'pass'    (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a'; bucket = 'skipping' })) 'a SKIPPED check does not block a merge on GitHub either -> pass'
Assert-Equal 'fail'    (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a'; bucket = 'cancel' }))   'a CANCELLED check never went green -> fail, not pass'
Assert-Equal 'fail'    (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a'; state = 'STARTUP_FAILURE' })) 'state fallback: a workflow that never started -> fail'
Assert-Equal 'fail'    (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a'; state = 'TIMED_OUT' }))       'state fallback: timed out -> fail'
Assert-Equal 'pending' (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a'; state = 'IN_PROGRESS' }))     'state fallback: in progress -> pending'
Assert-Equal 'pass'    (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a'; state = 'SUCCESS' }))         'state fallback: success -> pass'

# 'unknown' is NOT a synonym for 'pass', and this is the assert that keeps it that way: the only caller
# is deciding whether a merge is safe, so a record it cannot read must not read as green.
Assert-Equal 'unknown' (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a' }))                   'no bucket and no state -> unknown, never pass'
Assert-Equal 'unknown' (Get-CheckOutcome -Record ([pscustomobject]@{ name = 'a'; bucket = 'wat' }))   'an unrecognised bucket with no state -> unknown'
Assert-Equal 'unknown' (Get-CheckOutcome -Record $null)                                              'a null record -> unknown'

$pr937All      = '[{"bucket":"fail","completedAt":"2026-08-26T16:07:10Z","name":"claude-review","state":"FAILURE"},{"bucket":"pass","completedAt":"2026-08-26T16:06:58Z","name":"branch-entry","state":"SUCCESS"},{"bucket":"pass","completedAt":"2026-08-26T16:15:43Z","name":"lint-en-tests","state":"SUCCESS"}]'
$pr937Required = '[{"bucket":"pass","name":"lint-en-tests","state":"SUCCESS"}]'

# THE CASE THE ISSUE IS ABOUT, in the exact shape it was measured in.
$v = Get-MergeBlockVerdict -RequiredChecksJson $pr937Required -ChecksJson $pr937All
Assert-True (-not $v.Blocked) 'PR #937 shape: required green, advisory red -> the merge is NOT blocked'
Assert-NameSet @('claude-review') $v.FailedOther 'and the run can NAME the not-required check that failed'
Assert-NameSet @() $v.FailedRequired 'nothing required failed'
Assert-True ($v.Reason -like '*claude-review*') 'the reason names it too, so the transcript says which check was merged past'

# The other direction, which must keep behaving exactly as it did before the change.
$vReq = Get-MergeBlockVerdict -RequiredChecksJson '[{"bucket":"fail","name":"lint-en-tests","state":"FAILURE"}]' -ChecksJson $pr937All
Assert-True $vReq.Blocked 'a REQUIRED check failing still blocks the merge'
Assert-NameSet @('lint-en-tests') $vReq.FailedRequired 'and it is named'
Assert-True ($vReq.Reason -like '*REQUIRES*') 'the refusal says the ruleset requires it -- the whole basis of the decision'

# Not-green is broader than failing: a required check still running, or one whose state cannot be read,
# is not something to merge past either. After --watch neither should occur; both are asserted anyway,
# because "cannot happen" is how the premise this suite replaces was justified.
$vPend = Get-MergeBlockVerdict -RequiredChecksJson '[{"bucket":"pending","name":"lint-en-tests","state":"IN_PROGRESS"}]' -ChecksJson $pr937All
Assert-True $vPend.Blocked 'a required check that has not finished blocks the merge'
$vUnk = Get-MergeBlockVerdict -RequiredChecksJson '[{"name":"lint-en-tests"}]' -ChecksJson $pr937All
Assert-True $vUnk.Blocked 'a required check whose state cannot be read blocks the merge'

# THE CONSERVATIVE HALF, and the one that keeps this fix from being a regression: with no readable
# required list there is no way to tell a ruleset that requires nothing from one whose required checks
# have not reported, so it refuses -- which is precisely what the script did before #943.
foreach ($bad in @('', '   ', 'not json at all', '[]', '[{"noname":1}]')) {
    $vBad = Get-MergeBlockVerdict -RequiredChecksJson $bad -ChecksJson $pr937All
    Assert-True $vBad.Blocked "an unreadable required list ('$bad') keeps refusing, exactly as before #943"
}

# ChecksJson is presentation only. Absent, the verdict must not move.
$vNoAll = Get-MergeBlockVerdict -RequiredChecksJson $pr937Required
Assert-True (-not $vNoAll.Blocked) 'the verdict is made from the required list alone -- no ChecksJson needed'
Assert-NameSet @() $vNoAll.FailedOther 'with nothing to read, nothing is named'
$vJunkAll = Get-MergeBlockVerdict -RequiredChecksJson $pr937Required -ChecksJson 'not json'
Assert-True (-not $vJunkAll.Blocked) 'an unreadable ChecksJson costs a name and cannot change the verdict'

# TWO OR MORE REQUIRED CHECKS -- the 5.1 array-flattening pitfall, which this file already warns about
# at step 2 of ship-pr.ps1 and which both parses here walked into anyway. `@(@($json | ConvertFrom-Json))`
# hands back ONE element holding the whole array, whose .name member-enumerates to every name at once:
# two required checks became the single string 'a b'. Measured on 2026-08-26 -- with exactly one required
# check it works by accident, because a one-element array is handed through as the object itself, and one
# required check is all this repo's ruleset has ever had.
$twoRequiredGreen = '[{"bucket":"pass","name":"lint-en-tests","state":"SUCCESS"},{"bucket":"pass","name":"branch-entry","state":"SUCCESS"}]'
$vTwo = Get-MergeBlockVerdict -RequiredChecksJson $twoRequiredGreen -ChecksJson $pr937All
Assert-True (-not $vTwo.Blocked) 'two required checks, both green -> not blocked'
Assert-NameSet @('claude-review') $vTwo.FailedOther 'and branch-entry is recognised as required, so it is not listed as an other failure'
$vTwoBad = Get-MergeBlockVerdict -RequiredChecksJson '[{"bucket":"pass","name":"lint-en-tests","state":"SUCCESS"},{"bucket":"fail","name":"branch-entry","state":"FAILURE"}]'
Assert-NameSet @('branch-entry') $vTwoBad.FailedRequired 'the SECOND of two required checks failing is still seen'
Assert-True $vTwoBad.Blocked 'and it blocks'

# The same pitfall in Get-CheckWaitReport's required-name parse, which had been there since #831 and
# mislabelled every wait in any repo with more than one required check.
$twoChecks = '[{"name":"a","startedAt":"2026-08-26T16:00:00Z","completedAt":"2026-08-26T16:07:10Z"},{"name":"b","startedAt":"2026-08-26T16:00:00Z","completedAt":"2026-08-26T16:15:43Z"}]'
$reportTwo = Get-CheckWaitReport -ChecksJson $twoChecks -RequiredNamesJson '[{"name":"a"},{"name":"b"}]' -WaitedSeconds 10
Assert-True ($reportTwo -like '*, required)*') "two required names: 'b' governed and IS required -- the label must say so"
Assert-True ($reportTwo -notlike '*NOT required*') 'and must not say the opposite'
$reportOne = Get-CheckWaitReport -ChecksJson $twoChecks -RequiredNamesJson '[{"name":"a"}]' -WaitedSeconds 10
Assert-True ($reportOne -like '*NOT required*') 'one required name: the not-required label still works'
Assert-True ($reportOne -like "*after the last required check ('a')*") 'and the excess-wait clause still fires'

# The prose helper. Quoted per name, so a check name containing a space cannot read as two.
Assert-Equal ''                     (Format-CheckNameList -Names @())                'no names -> empty, so a caller can concatenate unconditionally'
Assert-Equal "'a'"                  (Format-CheckNameList -Names @('a'))             'one name'
Assert-Equal "'a' and 'b'"          (Format-CheckNameList -Names @('a','b'))         'two names joined with and'
Assert-Equal "'a', 'b' and 'c'"     (Format-CheckNameList -Names @('a','b','c'))     'three names: commas then and'
Assert-Equal "'lint en tests'"      (Format-CheckNameList -Names @('lint en tests')) 'a name with spaces stays one quoted item'
Assert-Equal "'a'"                  (Format-CheckNameList -Names @('a','',$null))    'blanks are dropped rather than quoted as empty'

# INBOUND #1044 -- A RUN THAT NEVER STARTED IS NOT A CHECK THAT WENT RED.
# Measured August 28, 2026 in a consumer repo: Actions refused to start jobs because an account
# payment had failed, every run ended in ~4s with zero steps, and ship-pr reported "CI did not pass
# ... Fix CI and re-run". Both halves true, and together they send the reader into their own code for
# a state no branch can repair -- it cost a hand-merge. The verdict above is deliberately untouched;
# what these asserts pin is the DIAGNOSIS printed beside the refusal.

# The lookup key: only the failing records, only their Actions run, deduped, in order.
$linkChecks = '[{"bucket":"fail","name":"lint-en-tests","state":"FAILURE","link":"https://github.com/o/r/actions/runs/123/job/456"},{"bucket":"pass","name":"branch-entry","state":"SUCCESS","link":"https://github.com/o/r/actions/runs/999/job/1"},{"bucket":"fail","name":"claude-review","state":"FAILURE","link":"https://github.com/o/r/actions/runs/123/job/789"}]'
Assert-NameSet @('123') (Get-FailedCheckRunIds -ChecksJson $linkChecks) 'two failing checks from ONE run yield that run once, and the green check is not asked about'
$extChecks = '[{"bucket":"fail","name":"ext","state":"FAILURE","link":"https://ci.example.com/build/7"}]'
Assert-NameSet @() (Get-FailedCheckRunIds -ChecksJson $extChecks) 'a failing status with no Actions run is skipped -- it has no jobs to ask about'
Assert-NameSet @() (Get-FailedCheckRunIds -ChecksJson $pr937All) 'a payload without the link field yields nothing rather than throwing'
foreach ($bad in @('', '   ', 'not json', '[]')) {
    Assert-NameSet @() (Get-FailedCheckRunIds -ChecksJson $bad) "an unreadable checks payload ('$bad') yields no run ids"
}

# The diagnosis itself. Both shapes the report measured count as "nothing ran".
$runNoJobs  = '{"conclusion":"failure","status":"completed","url":"https://github.com/o/r/actions/runs/123","jobs":[]}'
$runNoSteps = '{"conclusion":"failure","status":"completed","url":"https://github.com/o/r/actions/runs/123","jobs":[{"name":"lint-en-tests","steps":[]}]}'
$runRan     = '{"conclusion":"failure","status":"completed","url":"https://github.com/o/r/actions/runs/123","jobs":[{"name":"lint-en-tests","steps":[{"name":"Set up job","conclusion":"success"}]}]}'

$noteA = Get-StalledRunNote -RunJson $runNoJobs -RunId '123'
Assert-True ($noteA -ne '') 'a run with an empty jobs array is recognised as never having started'
Assert-True ($noteA -like '*never started*') 'and the note says so in those words -- the whole point of the repair'
Assert-True ($noteA -like '*not a check that went red*') 'it states the negative too, since that is the reading being corrected'
Assert-True ($noteA -like '*gh run view 123*') 'and names the one command that prints the reason, which the run page does not show'

$noteB = Get-StalledRunNote -RunJson $runNoSteps -RunId '123'
Assert-True ($noteB -ne '') 'a run whose only job executed no step is the same state'
Assert-True ($noteB -like '*one job executed no step*') 'and the note distinguishes it from "no job at all"'

# THE ASSERT THAT KEEPS THIS FROM CRYING WOLF. An ordinary red check runs steps, and on those the
# operator must keep reading the old wording -- "fix CI and re-run" is correct there.
Assert-Equal '' (Get-StalledRunNote -RunJson $runRan -RunId '123') 'a job that executed even one step is an ordinary failure -- no note'
$runMixed = '{"status":"completed","jobs":[{"name":"a","steps":[]},{"name":"b","steps":[{"name":"Set up job"}]}]}'
Assert-Equal '' (Get-StalledRunNote -RunJson $runMixed) 'one job of two having run is still "something ran"'
$runTwoIdle = '{"status":"completed","jobs":[{"name":"a","steps":[]},{"name":"b","steps":[]}]}'
Assert-True ((Get-StalledRunNote -RunJson $runTwoIdle) -like '*none of its 2 jobs executed a step*') 'two idle jobs are counted rather than described in the singular'

# A run that has not finished has no steps either. ship-pr only reaches this after --watch, so it
# cannot happen there -- asserted anyway, because "cannot happen" is how the premise #943 replaced
# was justified.
Assert-Equal '' (Get-StalledRunNote -RunJson '{"status":"in_progress","jobs":[{"name":"a","steps":[]}]}') 'a run still in progress is not stalled'
Assert-Equal '' (Get-StalledRunNote -RunJson '{"status":"queued","jobs":[]}') 'a queued run is not stalled either'

# Unreadable in, empty out: a diagnostic must never be the reason a refusal cannot be printed.
foreach ($bad in @('', '   ', 'not json', 'null', '{}', '{"status":"completed"}')) {
    Assert-Equal '' (Get-StalledRunNote -RunJson $bad) "an unreadable run payload ('$bad') costs the note and nothing else"
}

# Without a run id the note still stands and falls back to the URL the payload carried.
$noteNoId = Get-StalledRunNote -RunJson $runNoJobs
Assert-True ($noteNoId -like '*https://github.com/o/r/actions/runs/123*') 'no run id: the note points at the run URL instead'
Assert-True ($noteNoId -notlike '*gh run view *') 'and does not print a command with a missing argument'

# AND SHIP-PR ITSELF STILL USES IT. The asserts above prove the decision; this one proves the caller
# asks for it -- the same reasoning as the open-pr ordering assert above, and the same failure mode: a
# reverted call site would leave every assert here green while the merge refused as before.
$shipPrPath = Join-Path $PSScriptRoot '..\release\ship-pr.ps1'
Assert-True (Test-Path -LiteralPath $shipPrPath) 'ship-pr.ps1 exists where this suite looks for it'
$shipText = [System.IO.File]::ReadAllText((Resolve-Path $shipPrPath).Path, [System.Text.Encoding]::UTF8)
Assert-True ($shipText -like '*Get-MergeBlockVerdict -RequiredChecksJson*') 'ship-pr.ps1 consults the verdict rather than the --watch exit code alone'
Assert-True ($shipText -like '*--required*name,bucket,state*') 'and asks gh for the required checks WITH their state, since --json mode does not carry it in the exit code'
Assert-True ($shipText -like '*Get-FailedCheckRunIds -ChecksJson*') 'ship-pr.ps1 asks which runs failed before it words the refusal (#1044)'
Assert-True ($shipText -like '*Get-StalledRunNote -RunJson*') 'and asks whether those runs ever started'
Assert-True ($shipText -like '*startedAt,completedAt,link*') 'which needs the link field, the only one naming the run behind a check'
Assert-True ($shipText -like '*CI never RAN for PR*') 'and a stalled run gets its own lead sentence rather than "CI did not pass"'
Assert-True ($shipText -like '*Fix CI and re-run, or merge manually once green.*') 'while an ordinary red check keeps the wording that is correct for it'
$idxWatch   = $shipText.IndexOf("'--watch'")
$idxVerdict = $shipText.IndexOf('Get-MergeBlockVerdict')
Assert-True ($idxWatch -ge 0 -and $idxVerdict -gt $idxWatch) 'the wait still happens FIRST and the verdict second -- #831 kept the wait, #943 changed only the verdict'

# THE FALLBACK LINE IS ABOUT THE PAYLOAD, NOT ABOUT THE RULESET (inbound #1083). $line3 above already
# proves a repo that requires NOTHING still gets a rendered report -- so the fallback is not that repo's
# line, and wording it as one would send a reader with no ruleset looking for a setting they cannot have.
Assert-True ($shipText -like '*no readable check facts*') 'ship-pr''s wait-report fallback names the payload it could not read'
Assert-True ($shipText -notmatch 'which check governed could not be read') 'and no longer words that as a fault about the wait itself'


# --- Get-LostWatchNote: the watch dropped, CI did not (issue #1219) -------------------------------
# Measured on PR #1218, September 2, 2026: `gh pr checks --watch` died after nine clean poll cycles on
# `wsarecv: An existing connection was forcibly closed by the remote host`, exited non-zero, and
# ship-pr said "CI did not pass ... Fix CI and re-run" about a run that went green minutes later. The
# third case of the distinction #943 and #1044 already drew twice -- and the verdict is untouched for
# the third time: these asserts pin the DIAGNOSIS and the RETRY DECISION, never the merge.

# The measured payload, read seconds after the drop: one check green, two still running, none failed.
$dropped = '[{"bucket":"pass","name":"branch-entry","state":"SUCCESS"},{"bucket":"pending","name":"lint-en-tests","state":"IN_PROGRESS"},{"bucket":"pending","name":"claude-review","state":"PENDING"}]'
$lostNote = Get-LostWatchNote -ChecksJson $dropped -PrNumber '1218'
Assert-True ($lostNote -ne '') 'nothing failed while two checks are still running -- the exit code is contradicted by the payload'
Assert-True ($lostNote -like '*WATCH dropped*') 'and the note names the watch as what broke, which is the whole reading being corrected'
Assert-True ($lostNote -like '*nothing to re-run*') 'it states the negative too: there is no branch-side repair for a healthy run'
Assert-True ($lostNote -like "*'claude-review' and 'lint-en-tests' are still running*") 'the pending checks are named and read as prose, not as System.Object[]'
Assert-True ($lostNote -like '*gh pr checks 1218 --watch*') 'and it names the one command that re-enters the wait'

$lostNoteOne = Get-LostWatchNote -ChecksJson '[{"bucket":"pending","name":"lint-en-tests","state":"QUEUED"}]' -PrNumber '7'
Assert-True ($lostNoteOne -like "*'lint-en-tests' is still running*") 'one pending check is described in the singular'

# THE ASSERT THAT KEEPS THIS FROM MIS-NARRATING A REAL FAILURE, and it is the mirror of the
# cry-wolf assert Get-StalledRunNote carries. ONE failing check makes the non-zero exit a verdict,
# whatever else is still pending, and there the old wording is the correct one.
$redPlusPending = '[{"bucket":"fail","name":"lint-en-tests","state":"FAILURE"},{"bucket":"pending","name":"claude-review","state":"PENDING"}]'
Assert-Equal '' (Get-LostWatchNote -ChecksJson $redPlusPending) 'a failing check beside a pending one is a verdict -- no note, so "Fix CI and re-run" still prints'
Assert-Equal '' (Get-LostWatchNote -ChecksJson $pr937All) 'the #943 payload (claude-review red, lint-en-tests green) is a verdict too'
foreach ($state in @('CANCELLED', 'TIMED_OUT', 'STARTUP_FAILURE')) {
    $cj = "[{`"bucket`":`"fail`",`"name`":`"a`",`"state`":`"$state`"},{`"bucket`":`"pending`",`"name`":`"b`",`"state`":`"PENDING`"}]"
    Assert-Equal '' (Get-LostWatchNote -ChecksJson $cj) "a $state check is read through Get-CheckOutcome and is not a socket either"
}

# NOTHING PENDING, NOTHING SAID. A payload in which everything passed does not reach this -- the
# verdict is not Blocked there, so the caller takes its merge-proceeds path -- and "all green and the
# watch exited non-zero" wants a different sentence from this one.
Assert-Equal '' (Get-LostWatchNote -ChecksJson '[{"bucket":"pass","name":"a","state":"SUCCESS"}]') 'every check passed: not this note''s case'
Assert-Equal '' (Get-LostWatchNote -ChecksJson '[{"bucket":"weird","name":"a","state":"HUH"}]') 'an unrecognised state is not proof anything is running, so nothing is claimed'

# UNREADABLE IN, EMPTY OUT -- the OPPOSITE of Get-MergeBlockVerdict's answer to the same input, and
# right in both places. There silence must refuse, because it guards a merge; here silence must not
# narrate, because a "CI is still running" in front of a red check is worse than the old wording.
foreach ($bad in @('', '   ', 'not json', 'null', '[]', '{}', '[{"bucket":"pending"}]')) {
    Assert-Equal '' (Get-LostWatchNote -ChecksJson $bad) "an unreadable checks payload ('$bad') costs the note and the retry, and claims nothing"
}

# Without a PR number the note still stands and simply stops after the state it read.
$lostNoId = Get-LostWatchNote -ChecksJson $dropped
Assert-True ($lostNoId -like '*WATCH dropped*') 'no PR number: the diagnosis is unchanged'
Assert-True ($lostNoId -notlike '*gh pr checks  --watch*') 'and no command is printed with a missing argument'

# AND SHIP-PR ACTUALLY RETRIES ON IT. The asserts above prove the decision; these prove the caller
# both asks for it and acts on it -- the same reasoning as the #1044 call-site asserts above, and the
# same failure mode: a reverted call site would leave every assert here green while a dropped watch
# still cost a re-checkout and a duplicate gate run.
Assert-True ($shipText -like '*Get-LostWatchNote -ChecksJson*') 'ship-pr.ps1 asks whether a non-zero watch was the connection rather than a check (#1219)'
Assert-True ($shipText -like '*maxWatchAttempts*') 'and the retry is BOUNDED rather than a loop with no ceiling'
Assert-True ($shipText -like '*CI is still RUNNING for PR*') 'a dropped watch gets its own lead sentence, beside "CI never RAN" and "CI did not pass"'
$idxWatchCall = $shipText.IndexOf("'--watch'")
$idxLost      = $shipText.IndexOf('Get-LostWatchNote -ChecksJson')
Assert-True ($idxLost -gt $idxWatchCall) 'the read happens AFTER the watch it is diagnosing'
# The retry needs the check payload, so the fact-pair read moved inside the loop -- and the loop has to
# close after it, or the second attempt would judge the first attempt's payload.
$idxLoopHead  = $shipText.IndexOf('$watchAttempt++')
Assert-True ($idxLoopHead -ge 0 -and $idxLoopHead -lt $idxWatchCall) 'the watch call sits inside the attempt loop rather than before it'
$idxFacts     = $shipText.IndexOf('startedAt,completedAt,link')
Assert-True ($idxFacts -gt $idxWatchCall -and $idxFacts -lt $idxLost) 'and the check facts are re-read per attempt, which is what the decision is made from'


# --- issue #1350: the watch started BEFORE the checks registered ---------------------------------
# Observed on PR #1348, September 3, 2026: `gh pr checks --watch` ran seconds after open-pr pushed a
# new head, printed `no checks reported` in its own output and exited non-zero -- and ship-pr read
# that transient as a CI verdict ("Fix CI and re-run"), because none of the three wording guards
# covers "nothing is registered". The fix reuses step 3's registration wait: it is a function now
# (Wait-CheckRegistration), so the watch loop can fall back into the SAME wait rather than through to
# Get-MergeBlockVerdict. Text asserts, like the #1044 / #1219 call-site pins above -- the function is
# script-local and dot-sourcing ship-pr.ps1 to reach it would run the whole ship.
Write-Host "ship-pr.ps1 -- the watch re-enters the registration wait when it starts too early (#1350)" -ForegroundColor Cyan
Assert-True ($shipText -like '*function Wait-CheckRegistration*') 'step 3''s registration wait is a function, so it can be re-entered (#1350)'
Assert-True ($shipText -like "*-notmatch 'no checks reported'*") 'and it still breaks out on the TEXT, not the exit code, exactly as the inline loop did'
$idxFn       = $shipText.IndexOf('function Wait-CheckRegistration')
$idxFirstUse = $shipText.IndexOf('Wait-CheckRegistration -Pr')
$idxReentry  = $shipText.LastIndexOf('Wait-CheckRegistration -Pr')
Assert-True ($idxFn -ge 0 -and $idxFirstUse -gt $idxFn) 'the function is defined before it is called'
Assert-True ($idxFirstUse -lt $idxWatchCall) 'step 3 runs the wait before the --watch call, as the inline loop did'
Assert-True ($idxReentry -gt $idxWatchCall) 'and the watch loop re-enters that SAME wait after --watch (#1350)'
Assert-True ($shipText -like '*back to the registration wait (#1350)*') 'the fallback says what it is doing, rather than wording the transient as a CI failure'
$idxGuard = $shipText.IndexOf("-match 'no checks reported'")
Assert-True ($idxGuard -gt $idxWatchCall -and $idxGuard -lt $idxReentry) 'the re-entry is guarded by the watch''s own no-checks output -- a real red check (a table, not that phrase) still falls through to the verdict'
Assert-True ($shipText -like '*-AlreadyWaited $waited*') 'and it shares the 180s budget rather than restarting it, so a race that will not settle still ends in the #1234 refusal'
$countSuiteNote = ([regex]::Matches($shipText, 'Get-MissingCheckSuiteNote -SuitesJson')).Count
Assert-Equal 1 $countSuiteNote 'the #1234 / #1247 timeout diagnostic moved WITH the loop into the function -- written once, not duplicated at the watch site'


# --- Get-MissingCheckSuiteNote: no Actions suite was ever created (issue #1234) --------------------
# Measured on PR #1233, September 2, 2026, head b09c71b2: the step-3 probe ran its full 180s and
# refused with "Check the workflow", while `gh run list` was empty and the commit's check-suite list
# held netlify and claude and NO github-actions suite -- Actions demonstrably healthy elsewhere in the
# repo the same minute. The fourth case of the distinction #943, #1044 and #1219 already drew three
# times, and the refusal is untouched for the fourth time: these asserts pin the DIAGNOSIS, never the
# merge decision.
Write-Host "Get-MissingCheckSuiteNote -- no Actions suite for this commit" -ForegroundColor Cyan

# The measured payload: two suites from other providers, none from Actions.
$suitesNoActions = '{"total_count":2,"check_suites":[{"status":"queued","app":{"slug":"netlify"}},{"status":"queued","app":{"slug":"claude"}}]}'
$missNote = Get-MissingCheckSuiteNote -SuitesJson $suitesNoActions -PrNumber '1233'
Assert-True ($missNote -ne '') 'two suites and none from Actions is recognised as "no workflow was ever asked to run"'
Assert-True ($missNote -like '*no Actions check suite*') 'and the note names what is MISSING rather than sending the reader to the workflow files'
Assert-True ($missNote -like "*only 'netlify' and 'claude' registered*") 'the suites that DO exist are named, so the reader sees what was asked and what was not'
Assert-True ($missNote -like '*NOT a paths: filter*') 'it states the negative too, since "check the workflow" is the reading being corrected'
Assert-True ($missNote -like '*gh pr close 1233 && gh pr reopen 1233*') 'and it names the remedy, which is not a thing an operator guesses'
Assert-True ($missNote -like '*not a diagnosis*') 'while saying plainly that the reopen is the cheapest thing to TRY, not a cause it has established'

# THE ASSERT THAT KEEPS THIS FROM CRYING WOLF, the same one its three siblings carry. An Actions suite
# that exists and has not reported is exactly the case the OLD wording is correct for -- there the
# workflow really may be why -- so this note must stay out of the way whatever that suite is doing.
$suitesWithActions = '{"check_suites":[{"status":"queued","app":{"slug":"netlify"}},{"status":"in_progress","app":{"slug":"github-actions"}}]}'
Assert-Equal '' (Get-MissingCheckSuiteNote -SuitesJson $suitesWithActions -PrNumber '1233') 'an Actions suite that exists is not this note''s case'
Assert-Equal '' (Get-MissingCheckSuiteNote -SuitesJson '{"check_suites":[{"status":"completed","app":{"slug":"github-actions"}}]}') 'a completed Actions suite is not it either -- the question is existence, not outcome'

# An empty suite list is the same finding said differently, and gets its own clause rather than a
# sentence naming an empty list, which reads as a bug in the note.
$missEmpty = Get-MissingCheckSuiteNote -SuitesJson '{"total_count":0,"check_suites":[]}' -PrNumber '7'
Assert-True ($missEmpty -like '*nothing registered for it at all*') 'a commit carrying no suite whatsoever says so'
Assert-True ($missEmpty -like '*gh pr close 7 && gh pr reopen 7*') 'and still gets the remedy -- the finding is the same one'

# Singular where one other provider registered, plural where several did.
$missOne = Get-MissingCheckSuiteNote -SuitesJson '{"check_suites":[{"app":{"slug":"netlify"}}]}'
Assert-True ($missOne -like "*only 'netlify' registered*") 'one foreign suite reads the same way -- the clause takes no grammatical number'
Assert-True ($missNote -notlike '*commit -- the commit*') 'and the sentence names the commit once, not twice'

# A suite whose app gh did not return is skipped rather than throwing -- absent is not empty under
# Set-StrictMode, the trap every reader in this lib guards against.
$missAppless = Get-MissingCheckSuiteNote -SuitesJson '{"check_suites":[{"status":"queued"},{"app":null},{"app":{"slug":"netlify"}}]}'
Assert-True ($missAppless -like "*'netlify'*") 'a suite with no readable app is skipped and the readable one still counted'
Assert-True ($missAppless -notlike '*and*registered*') 'and the unreadable ones are not listed beside it'

# The same slug twice is one provider, not two -- GitHub lists a suite per app INSTALLATION, and #1233
# itself came back with three github-actions rows once the reopen had fired.
$missDupe = Get-MissingCheckSuiteNote -SuitesJson '{"check_suites":[{"app":{"slug":"netlify"}},{"app":{"slug":"netlify"}}]}'
Assert-True ($missDupe -like "*only 'netlify' registered*") 'a repeated slug is deduped rather than listed twice'

# UNREADABLE IN, EMPTY OUT: a diagnostic must never be the reason a refusal cannot be printed. The
# refusal prints with or without this note, which is what makes attempting the read safe at all.
foreach ($bad in @('', '   ', 'not json', 'null', '{}', '[]', '{"total_count":0}')) {
    Assert-Equal '' (Get-MissingCheckSuiteNote -SuitesJson $bad) "an unreadable check-suites payload ('$bad') costs the note and nothing else"
}

# Without a PR number the diagnosis still stands and simply stops before the command.
$missNoId = Get-MissingCheckSuiteNote -SuitesJson $suitesNoActions
Assert-True ($missNoId -like '*no Actions check suite*') 'no PR number: the diagnosis is unchanged'
Assert-True ($missNoId -notlike '*gh pr close *') 'and no command is printed with a missing argument'

# --- The conflicting PR: the one cause that is checkable rather than guessed (issue #1247) ---------
# Measured September 2, 2026. A pull_request workflow runs against refs/pull/<n>/merge, which a
# conflicting PR does not have -- so no suite is created for it, and #1247 read that as an Actions
# outage across the whole org. PR #1243 (CONFLICTING) had no merge ref and 0 suites, and stayed at 0
# through a close/reopen AND a freshly pushed head; #1240 and #1249, opened either side of it, each had
# a merge ref and three suites. These asserts pin the DIAGNOSIS; the refusal is untouched, again.
Write-Host "Get-MissingCheckSuiteNote -- the conflicting PR (#1247)" -ForegroundColor Cyan

$missConflict = Get-MissingCheckSuiteNote -SuitesJson $suitesNoActions -PrNumber '1243' -Mergeable 'CONFLICTING'
Assert-True ($missConflict -like '*CONFLICTING*') 'a conflicting PR is named as such, in GitHub''s own word'
Assert-True ($missConflict -like '*refs/pull/*') 'and the note says WHICH commit does not exist, since that is the whole mechanism'
Assert-True ($missConflict -like '*Resolve the conflict*') 'the repair named is the one that works -- resolve, then push'
# THE POINT OF THE BRANCH, not a nicety: the reopen is measured to do nothing here, and printing it
# beside the real repair leaves the reader to choose between them with the cheap one listed first.
Assert-True ($missConflict -notlike '*gh pr close 1243 && gh pr reopen 1243*') 'and the reopen is WITHHELD rather than offered beside it'
Assert-True ($missConflict -like '*measured*') 'while saying the reopen was measured doing nothing, so the reader does not try it anyway'
Assert-True ($missConflict -like '*no Actions check suite*') 'the #1234 finding still leads -- the conflict explains it, it does not replace it'

# EVERY OTHER ANSWER LEAVES THE #1234 WORDING EXACTLY AS IT WAS. UNKNOWN is GitHub still computing the
# merge, and reading it as a conflict would be this function guessing at a cause -- the failure it
# exists to end. An absent argument is the back-compat path every existing caller takes.
foreach ($state in @('MERGEABLE', 'UNKNOWN', '', '   ')) {
    $missOther = Get-MissingCheckSuiteNote -SuitesJson $suitesNoActions -PrNumber '1233' -Mergeable $state
    Assert-True ($missOther -like '*gh pr close 1233 && gh pr reopen 1233*') "mergeable '$state' still gets the reopen -- only CONFLICTING is decisive"
    Assert-True ($missOther -notlike '*Resolve the conflict*') "mergeable '$state' is never told to resolve a conflict it may not have"
}
Assert-Equal $missNote (Get-MissingCheckSuiteNote -SuitesJson $suitesNoActions -PrNumber '1233') 'and the note is byte-identical to the pre-#1247 one when nothing is passed'

# gh's answer arrives as JSON text through Invoke-NativeCapture, so tolerate what that hands back.
Assert-True ((Get-MissingCheckSuiteNote -SuitesJson $suitesNoActions -PrNumber '9' -Mergeable ' conflicting ') -like '*Resolve the conflict*') 'the state is matched case-insensitively and trimmed, as gh output reaches it'

# An Actions suite that EXISTS is still not this note's case, conflict or no conflict: there the
# ordinary "the check has not reported yet" wording is the correct one and this must stay out of it.
Assert-Equal '' (Get-MissingCheckSuiteNote -SuitesJson $suitesWithActions -PrNumber '1243' -Mergeable 'CONFLICTING') 'a conflicting PR that DOES have an Actions suite is not this note''s case either'

# AND SHIP-PR'S PROBE ACTUALLY ASKS. Same reasoning and same failure mode as the #1044 and #1219
# call-site asserts above: a reverted call site leaves every assert here green while the refusal goes
# on sending the reader to YAML that is fine.
Assert-True ($shipText -like '*Get-MissingCheckSuiteNote -SuitesJson*') 'ship-pr.ps1 asks whether an Actions suite exists before it words the step-3 refusal (#1234)'
Assert-True ($shipText -like '*commits/$sha/check-suites*') 'and reads it for the commit the PR actually carries'
Assert-True ($shipText -like '*Check the workflow, or merge manually once it is green.*') 'while the old wording survives for the one case it is correct for'
# The #1247 half of the same guard: the conflict branch above is unreachable in production unless the
# call site actually reads the state and passes it, and nothing else in this suite would notice.
Assert-True ($shipText -like '*-Mergeable $mergeable*') 'ship-pr.ps1 passes the PR''s mergeable state, so the conflict branch is reachable at all (#1247)'
Assert-True ($shipText -like "*'--json', 'mergeable'*") 'and reads it from gh rather than inferring it from the checkout'
$idxSuiteNote = $shipText.IndexOf('Get-MissingCheckSuiteNote')
$idxWatchArg  = $shipText.IndexOf("'--watch'")
Assert-True ($idxSuiteNote -ge 0 -and $idxSuiteNote -lt $idxWatchArg) 'the read sits in the PRE-watch probe it diagnoses, not beside the post-watch notes'


# --- Get-PrCreateFailureReason: gh's own answer, not a guess (inbound #1077) -----------------------
# open-pr replaced gh's message with "Creating the PR failed (is gh logged in?)" on a run where gh had
# just listed PRs, pushed and read the issue list -- so the loudest line on screen named the one thing
# that was demonstrably fine, and sent the reader to gh auth status, then to their token, then to their
# network, for a branch that was in fact completely finished.
Write-Host "Get-PrCreateFailureReason -- the reason gh actually gave" -ForegroundColor Cyan
$ghFail = @(
    'Creating pull request for docs/audience-note-v1 into main in DaveKJohn/thumbnail-generator',
    '',
    'pull request create failed: GraphQL: No commits between main and docs/audience-note-v1 (createPullRequest)'
)
Assert-Equal 'pull request create failed: GraphQL: No commits between main and docs/audience-note-v1 (createPullRequest)' `
    (Get-PrCreateFailureReason -OutputLines $ghFail) 'create failure: the reason is gh''s last line, not its progress line'
Assert-Equal 'boom' (Get-PrCreateFailureReason -OutputLines @('boom', '', '   ')) 'create failure: trailing blank lines are not the reason'
Assert-Equal 'trimmed' (Get-PrCreateFailureReason -OutputLines @('  trimmed  ')) 'create failure: the line comes back trimmed'
# EMPTY IS THE ONE CASE THE OLD MESSAGE WAS RIGHT FOR, so it has to be distinguishable: a gh that printed
# nothing leaves the caller with nothing better than a hint about the environment.
Assert-Equal '' (Get-PrCreateFailureReason -OutputLines @()) 'create failure: no output yields no reason'
Assert-Equal '' (Get-PrCreateFailureReason -OutputLines @('', '  ')) 'create failure: blank output yields no reason either'
Assert-Equal '' (Get-PrCreateFailureReason -OutputLines $null) 'create failure: and $null is not a crash'

# AND OPEN-PR ASKS FOR IT, plus the merged lookup that stops the run ever reaching that failure. Both are
# call-site asserts for the same reason the ship-pr ones below are: a reverted caller leaves every assert
# above green while the script behaves exactly as it did before.
$openPrPath = Join-Path $PSScriptRoot '..\release\open-pr.ps1'
Assert-True (Test-Path -LiteralPath $openPrPath) 'open-pr.ps1 exists where this suite looks for it'
$openText = [System.IO.File]::ReadAllText((Resolve-Path $openPrPath).Path, [System.Text.Encoding]::UTF8)
Assert-True ($openText -like '*Get-PrCreateFailureReason -OutputLines $create.Output*') 'open-pr reports gh''s own reason for a failed create'
Assert-True ($openText -like "*'--state', 'merged'*") 'open-pr asks whether the branch has an ALREADY-MERGED PR'
Assert-True ($openText -like '*is already merged -- nothing to open*') 'and says so as its own outcome rather than failing'
$idxOpenLookup = $openText.IndexOf("'--state', 'open'")
$idxMergedLookup = $openText.IndexOf("'--state', 'merged'")
Assert-True ($idxOpenLookup -ge 0 -and $idxMergedLookup -gt $idxOpenLookup) 'the merged lookup is the FALLBACK -- an open PR is still the first answer'
$idxCreate = $openText.IndexOf("'pr', 'create'")
Assert-True ($idxCreate -gt $idxMergedLookup) 'and it sits above the create, which is the path it exists to keep the run off'

$shipMergedText = [System.IO.File]::ReadAllText((Resolve-Path (Join-Path $PSScriptRoot '..\release\ship-pr.ps1')).Path, [System.Text.Encoding]::UTF8)
Assert-True ($shipMergedText -like '*is already merged -- nothing to ship*') 'ship-pr reads the same state for itself, since it is runnable on its own'

# --- Get-FailedCheckRunRefs / Get-AuthoredFailureNote: the reason, relayed (#1103) ---------------
#
# Eight issues have been filed here against a red `claude-review` whose own diagnostic step had
# already printed the cause -- the last of them #1103, and #966 concluded from the same silence that
# a secret needed rotating. ship-pr merges past that check by the ruleset and says so; what these
# asserts pin is the SENTENCE printed beside it.

# The refs are the run read widened by one key, so the run answer above must not have moved.
$refs = @(Get-FailedCheckRunRefs -ChecksJson $linkChecks)
Assert-Equal 2 $refs.Count 'both failing checks are returned, and the green one is not'
Assert-NameSet @('lint-en-tests', 'claude-review') @($refs | ForEach-Object { $_.Name }) 'each ref names its check, which is what the note is titled with'
Assert-NameSet @('456', '789') @($refs | ForEach-Object { $_.JobId }) 'and its JOB, the key annotations are addressed by -- not the run'
Assert-NameSet @('123') @($refs | ForEach-Object { $_.RunId } | Sort-Object -Unique) 'while the run id is still read from the same link'
$runOnly = '[{"bucket":"fail","name":"a","state":"FAILURE","link":"https://github.com/o/r/actions/runs/55"}]'
Assert-NameSet @('55') (Get-FailedCheckRunIds -ChecksJson $runOnly) 'a link naming a run but no job still answers the run question'
Assert-Equal '' (@(Get-FailedCheckRunRefs -ChecksJson $runOnly)[0].JobId) 'and simply has no job to ask annotations of'
Assert-NameSet @() (Get-FailedCheckRunRefs -ChecksJson $extChecks) 'an external status is skipped here too -- it has no annotations either'
foreach ($bad in @('', '   ', 'not json', '[]')) {
    Assert-NameSet @() (Get-FailedCheckRunRefs -ChecksJson $bad) "an unreadable checks payload ('$bad') yields no refs"
}

# The real payload, trimmed: this is what run 33267175141's job answered on August 29, 2026 -- the
# authored diagnostic sitting among the runner's own untitled noise and a deprecation warning.
# KEPT VERBATIM, including a headline the workflow no longer writes. #1112 repaired that sentence --
# it vouched for the reset time this same payload got wrong by 2.5 days -- but what is under test
# here is the SELECTION rule, not the wording, and a real captured payload is worth more to it than
# a re-typed current one. The current headline lives in .github/workflows/claude-code-review.yml.
$annReal = '[' +
  '{"annotation_level":"warning","title":"","message":"Node.js 20 is deprecated."},' +
  '{"annotation_level":"failure","title":"claude-review -- out of quota -- the review did not run",' +
  '"message":"The review did not run: the account behind CLAUDE_CODE_OAUTH_TOKEN is out of quota. It resets on the clock and not on a re-run; the reason below names WHICH limit it is and when it comes back, which is hours for a session window and days for a weekly one. Nothing to do with this diff. You have hit your weekly limit - resets Aug 31, 7am (UTC)"},' +
  '{"annotation_level":"failure","title":"","message":"Process completed with exit code 1."},' +
  '{"annotation_level":"failure","title":"","message":"Action failed with error: Claude execution failed: result is_error:true"}]'
$noteQuota = Get-AuthoredFailureNote -AnnotationsJson $annReal -CheckName 'claude-review'
Assert-True ($noteQuota -like 'claude-review*') 'the note names the check it belongs to'
Assert-True ($noteQuota -notlike '*claude-review: claude-review*') 'ONCE -- this repo titles its own annotation with the job name, and prefixing it again stutters'
Assert-True ((Get-AuthoredFailureNote -AnnotationsJson $annReal -CheckName 'other') -like 'other: *') 'a title that does NOT carry the name is prefixed, which is what the parameter is for'
Assert-True ($noteQuota -like '*out of quota*') 'and carries the title the workflow authored'
Assert-True ($noteQuota -like '*resets Aug 31*') 'and the message, which is where upstream states a reset time -- relayed, not vouched for (#1112)'
Assert-True ($noteQuota -notlike '*exit code 1*') 'the runner exit noise is not what gets relayed'
Assert-True ($noteQuota -notlike '*Node.js 20*') 'and neither is a WARNING -- the run went red, and a deprecation is not why'

# THE ASSERT THAT KEEPS THIS FROM CRYING WOLF, the same one Get-StalledRunNote carries: a job that
# left no authored sentence must produce no line at all, so the operator's transcript does not gain a
# reassuring-looking note that says nothing.
$annBare = '[{"annotation_level":"failure","title":"","message":"Process completed with exit code 1."}]'
Assert-Equal '' (Get-AuthoredFailureNote -AnnotationsJson $annBare -CheckName 'x') 'untitled failures only: no note, and the old wording stands alone'
$annWarnOnly = '[{"annotation_level":"warning","title":"Something","message":"m"}]'
Assert-Equal '' (Get-AuthoredFailureNote -AnnotationsJson $annWarnOnly -CheckName 'x') 'a titled WARNING is not a red run explaining itself'

# Order, bounds, and the optional name.
$annTwo = '[{"annotation_level":"failure","title":"first","message":"a"},{"annotation_level":"failure","title":"second","message":"b"}]'
Assert-True ((Get-AuthoredFailureNote -AnnotationsJson $annTwo) -like 'first*') 'the FIRST titled failure wins -- a workflow diagnoses itself before the runner exits'
Assert-True ((Get-AuthoredFailureNote -AnnotationsJson $annTwo) -notlike '*claude*') 'without a check name the note is the authored sentence alone'
$annLong = '[{"annotation_level":"failure","title":"t","message":"' + ('x' * 700) + '"}]'
Assert-True ((Get-AuthoredFailureNote -AnnotationsJson $annLong).Length -lt 540) 'the message is capped -- free text from a workflow, going into a console'
Assert-True ((Get-AuthoredFailureNote -AnnotationsJson $annReal).Length -gt 400) 'but not at the 300 the annotation itself uses: that cut off "resets Aug 31", the one actionable word'
$annMulti = '[{"annotation_level":"failure","title":"t","message":"line one\nline two"}]'
Assert-True ((Get-AuthoredFailureNote -AnnotationsJson $annMulti) -notlike '*line two*') 'and cut to its first line, since this is pasted into a console'

# --- The two caps that bound the SAME string, pinned so neither moves alone (#1116) ---------------
#
# `claude-code-review.yml` writes `headline + ' ' + reason` into one annotation and this function
# relays that annotation to the operator. Both bound it and neither can see the other: a
# 296-character headline plus a 300-character reason is 597 against a relay that cuts at 500, and
# the part the relay drops is the TAIL of the reason -- where "resets Aug 31, 7am (UTC)" lives.
#
# #1116 MEASURED THAT OVERLAP AND LEFT IT STANDING, which is why this pins the numbers instead of
# asserting the sum fits. 500 - 296 - 1 = 203, so the console shows 203 characters of reason
# whichever end owns the cut; lowering the workflow's 300 to 203 would hand that reader the same
# text, drop the "..." that marks the loss, and cost the GitHub annotation up to 97 characters no
# 500 bounds. Sampled traffic makes it hypothetical anyway -- 45 titled failure annotations over
# August 27-29, 2026 with reasons of 51 to 55 characters, and the longest since (#1164's spend-limit
# string, August 31) at 121 -- all against 203 of room.
#
# So what must not happen silently is a MOVE. A longer headline, a raised reason cap or a lowered
# relay cap each change that arithmetic, and each is reasonable on its own terms while being wrong
# against the other file. These asserts fail on any of the three and name the reasoning to read.
$wfPath = (Join-Path $PSScriptRoot '..\..\.github\workflows\claude-code-review.yml')
Assert-True (Test-Path -LiteralPath $wfPath) 'the reviewed workflow is where these asserts expect it -- a rename must fail here, not silently pass'
$wfText = Get-Content -LiteralPath $wfPath -Raw

# Read with .Contains, not -like: the needle carries '[', which -like takes as a character class.
$libText = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\lib\pr-issues-lib.ps1') -Raw
$libCaps = @([regex]::Matches($libText, '\$message\.Length -gt (\d+)\)|\$message\.Substring\(0, (\d+)\)') |
    ForEach-Object { if ($_.Groups[1].Success) { [int]$_.Groups[1].Value } else { [int]$_.Groups[2].Value } })
Assert-Equal 2 $libCaps.Count 'the relay states its bound twice -- the test and the cut -- and both are read'
Assert-Equal $libCaps[0] $libCaps[1] 'and they agree with each other: a message cut at one number must be the one tested against it'
$relayCap = $libCaps[0]
Assert-Equal 500 $relayCap 'the relay still cuts at the 500 #1116 did its arithmetic against'

# THE NEEDLE BINDS TO THE FIELD, not to the shape -- because the edge this comment used to merely
# predict has since happened. It read: "the needle occurs exactly once in the file today; a SECOND jq
# slice added elsewhere would go unread here rather than caught." #1118 added that second slice, to
# `status` one line above, and the outcome was worse than unread: the new slice sits EARLIER in the
# file, so `Match` returned 32 and this assert went red against a `reason` cap nobody had touched.
# Anchoring on `.result` is what makes the two independent, and the status cap gets its own assert
# below rather than sharing this one.
$wfReason = [regex]::Match($wfText, '\(\.result // ""\)[^\r\n]*\| \.\[0:(\d+)\]')
Assert-True $wfReason.Success 'the workflow still caps the reason it appends, and this is where'
Assert-Equal 300 ([int]$wfReason.Groups[1].Value) 'at the same 300 -- raising it widens an overlap that was measured, not overlooked'

# And the status cap, which is a bound on a DIFFERENT thing: not an overlap with the relay, but the
# length of a value this repo does not own and cannot predict (#1118).
$wfStatus = [regex]::Match($wfText, '\(\.api_error_status // ""\)[^\r\n]*\| \.\[0:(\d+)\]')
Assert-True $wfStatus.Success 'and the status it interpolates is capped too, on the line that reads it'
Assert-True ([int]$wfStatus.Groups[1].Value -lt 300) 'well under the reason cap -- a status is three digits, and the rest is a field this repo does not own'

# THE HEADLINE IS THE THIRD NUMBER, and the one most likely to move: it is prose, and #974, #1055,
# #1112 and #1164 each rewrote it. Its length is what turns the other two into 203, so it is read
# from the file rather than trusted. 296 today; the assert is the arithmetic, not the constant, so a
# rewrite that keeps the sum honest passes and one that eats the reason's room does not.
$headlines = @([regex]::Matches($wfText, "(?m)^\s*headline='([^']*)'") | ForEach-Object { $_.Groups[1].Value })
Assert-True ($headlines.Count -ge 3) 'the literal headlines are readable -- the interpolated *) branch has no static length and needs none'
$longestMeasuredReason = 121  # #1164's spend-limit string, August 31 2026 -- the session/weekly ones ran 51-55
foreach ($h in $headlines) {
    $room = $relayCap - $h.Length - 1
    Assert-True ($room -ge $longestMeasuredReason) "the $($h.Length)-character headline leaves the console $room characters of reason -- more than the $longestMeasuredReason ever measured"
}

# --- THE PRE-SDK FAILURE CLASS: a titled annotation where there was none (#1245) -----------------
#
# The asserts above all describe a failure the SDK lived long enough to REPORT. When the action dies
# before the SDK is reached, `execution_file` is empty, the *Why the review failed* step is skipped,
# and the workflow used to write no titled annotation at all -- so `Get-AuthoredFailureNote` selected
# nothing and ship-pr printed nothing beside the red mark. That is the #966 silence in a class the 429
# work never reached, and it is not hypothetical: run 33663986438 (September 2, 2026) failed the
# app-token exchange with a 401, and its only failure annotations were the runner's two UNTITLED ones.
#
# WHAT THESE PIN IS THE COVERAGE, not the wording. `failure()` has exactly two cases here and each
# needs a step, so the guard is that BOTH gates exist and that the second one authors a title. A
# rewrite of either sentence passes; deleting the second step, or renaming the output either gate
# reads, does not.
$wfGates = @([regex]::Matches($wfText, "steps\.claude-review\.outputs\.execution_file (!=|==) ''") |
    ForEach-Object { $_.Groups[1].Value })
Assert-NameSet @('!=', '==') $wfGates 'both halves of failure() are diagnosed -- a result message to read, and none'
Assert-Equal 2 $wfGates.Count 'and exactly once each: two gates on the same output, so neither class falls between them'

# The literals are read out of the workflow rather than re-typed, so this cannot drift from the file
# it describes -- the same reason the headline loop above reads its own.
$wfPreSdk = [regex]::Match($wfText, "(?s)- name: Why the review never started.*?\z")
Assert-True $wfPreSdk.Success 'the pre-SDK step is still named as these asserts address it'
$preShort = [regex]::Match($wfPreSdk.Value, "(?m)^\s*short='([^']*)'").Groups[1].Value
$preHead  = [regex]::Match($wfPreSdk.Value, "(?m)^\s*headline='([^']*)'").Groups[1].Value
Assert-True ($preShort -and $preHead) 'and still builds its annotation from a short title and a headline'
Assert-True ($wfPreSdk.Value.Contains('::error title=claude-review -- ${short}::')) 'which it writes as a TITLED failure annotation -- the one field the relay reads'
foreach ($punct in @(',', '::')) {
    Assert-True (-not $preShort.Contains($punct)) "the title carries no '$punct' -- both are annotation-command syntax, as the step above notes"
}

# END TO END, through the function ship-pr actually calls: the annotation this step writes must come
# back out as a sentence, where the runner's untitled 401 came back as ''.
$annPreSdk = '[' +
  '{"annotation_level":"warning","title":"","message":"Node.js 20 is deprecated."},' +
  '{"annotation_level":"failure","title":"claude-review -- ' + $preShort + '","message":"' + $preHead + '"},' +
  '{"annotation_level":"failure","title":"","message":"Process completed with exit code 1."},' +
  '{"annotation_level":"failure","title":"","message":"Action failed with error: Claude Code is not installed on this repository. Please install the Claude Code GitHub App at https://github.com/apps/claude"}]'
$notePreSdk = Get-AuthoredFailureNote -AnnotationsJson $annPreSdk -CheckName 'claude-review'
Assert-True ($notePreSdk -like 'claude-review*') 'the pre-SDK note names its check'
Assert-True ($notePreSdk -notlike '*claude-review: claude-review*') 'once, like the quota note -- the title already carries the job name'
Assert-True ($notePreSdk.Contains($preShort)) 'and carries the title the workflow authored'
Assert-True ($notePreSdk -notlike '*exit code 1*') 'not the runner exit noise'
Assert-True ($notePreSdk -notlike '*not installed on this repository*') 'and not the runner UNTITLED error either -- relaying that is the lib change #1112 ruled out, so the workflow states its own case'

# THE CAP, AND WHY THIS ONE IS AN ABSOLUTE RATHER THAN #1116's ARITHMETIC. The quota headlines leave
# room for a reason the relay may cut; this one has NO reason appended -- there is no result message
# to take one from -- so its whole note is literals from this repo and must arrive intact. If it ever
# does not, the fix is a shorter sentence here, not a wider cap there.
Assert-True ($notePreSdk.Length -lt $relayCap) "the pre-SDK note is $($notePreSdk.Length) characters against the relay's $relayCap -- it carries no reason, so it must arrive whole"
Assert-True ($notePreSdk -notlike '*...') 'and therefore unmarked by the truncation ellipsis'

# The claims it makes are bounded to what an EMPTY output proves, which is the standing rule of that
# workflow after #974, #1055, #1112 and #1164. A quota status cannot be among them: a 429 or 529
# arrives WITH a result message, so it is the other step's business and naming it here would be the
# over-claim those four issues each repaired.
foreach ($overclaim in @('429', '529', 'quota', 'resets')) {
    Assert-True (-not $preHead.Contains($overclaim)) "the pre-SDK headline does not mention '$overclaim' -- that class arrives with a result message and is diagnosed by the other step"
}

# Unreadable in, empty out -- a diagnostic must never be the reason the warning beside it cannot print.
foreach ($bad in @('', '   ', 'not json', 'null', '[]', '[{}]', '[{"annotation_level":"failure"}]')) {
    Assert-Equal '' (Get-AuthoredFailureNote -AnnotationsJson $bad -CheckName 'x') "an unreadable annotations payload ('$bad') costs the note and nothing else"
}

# AND SHIP-PR ASKS FOR IT, on the path where the merge PROCEEDS. Same reasoning as the #1044 call-site
# assert above: without this, a reverted call site leaves every assert here green while the operator
# reads the red mark with no reason beside it, which is the whole defect.
Assert-True ($shipText -like '*Get-AuthoredFailureNote -AnnotationsJson*') 'ship-pr relays what the failing workflow said about itself (#1103)'
Assert-True ($shipText -like '*check-runs/*/annotations*') 'reading it from the check run, which is where an authored annotation lives'
Assert-True ($shipText -like '*FailedOther -notcontains*') 'and only for the NOT-REQUIRED failures -- a required one is a refusal, not a merge that walks past'
$idxProceed = $shipText.IndexOf('a check FAILED but the merge is not blocked')
$idxSpoken  = $shipText.IndexOf('Get-AuthoredFailureNote')
Assert-True ($idxProceed -ge 0 -and $idxSpoken -gt $idxProceed) 'the reason is printed under that warning, where the reader has just landed'
Write-Host ""
# --- The PRODUCER of the annotation everything above relays (issue #1118) -------------------------
# Asserted on the workflow text for exactly the reason cut-release-guardrail gives for asserting on
# ci.yml: a workflow is the one caller no suite gets to run. Everything above this line tests the
# CONSUMER -- Get-AuthoredFailureNote reading what the check left behind -- so a regression in what
# claude-code-review.yml is allowed to PUT there would leave every assert in this file green.
#
# Three properties, one per way `status` could reach a workflow command unescaped. It is upstream's
# field, this repo cannot measure its domain, and #1112 is the standing reminder not to claim
# otherwise -- so these pin the SHAPE that needs no claim rather than a belief about the value.
$reviewYmlPath = Join-Path $PSScriptRoot '..\..\.github\workflows\claude-code-review.yml'
Assert-True (Test-Path -LiteralPath $reviewYmlPath) 'claude-code-review.yml exists where this suite looks for it'
$reviewYml = [System.IO.File]::ReadAllText((Resolve-Path $reviewYmlPath).Path, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "claude-code-review.yml -- what may reach the annotation (#1118)" -ForegroundColor Cyan

# 1. The newline axis. A command substitution strips TRAILING newlines and keeps internal ones, and a
#    workflow command counts at the START of a line -- so an unsplit status is a forgery surface.
Assert-True ($reviewYml -like '*(.api_error_status // "") | tostring | split(*') 'the status is single-lined where it is read, the same treatment the reason beside it gets'

# 2. The title axis. The comment above the case block states that the annotation TITLE may hold
#    neither a comma nor a '::' -- and until #1118 the one branch that could not know what it was
#    putting there was the only one putting a variable there.
$shortLines = @($reviewYml -split "`r?`n" | Where-Object { $_ -match '\bshort=' })
Assert-True ($shortLines.Count -ge 4) 'every case branch still sets a short form'
Assert-True (-not ($shortLines | Where-Object { $_ -like '*$status*' })) 'and none interpolates the status into it -- the short form IS the title, where a comma or a :: is command syntax'

# 3. The percent axis. The runner percent-DECODES a command's data, so an unescaped %0A renders as a
#    newline. `reason` was escaped from the start; `headline` needs it too now that it carries status.
#
#    AND THE COUNT IS PART OF THE PROPERTY, not bookkeeping around it -- which #1245 is why. That
#    issue added a THIRD emission site, for the pre-SDK class whose headline is pure literal and so
#    needs no escaping on today's text. Exempting it is the #1118 shape exactly: the branch nobody
#    escaped was the branch nobody had interpolated into YET, and it was the one that broke. So the
#    invariant is every site, and a new site raises this number deliberately rather than passing
#    under a `-ge`.
$errLines = @($reviewYml -split "`r?`n" | Where-Object { $_ -like '*::error title=claude-review*' })
Assert-True ($errLines.Count -eq 3) 'the annotation is emitted from exactly three places -- with a reason, without one, and the pre-SDK step that has none to take (#1245)'
Assert-True (-not ($errLines | Where-Object { $_ -notlike '*${headline//%/%25}*' })) 'and EVERY ONE escapes the headline -- the variable the case block interpolates the status into, and the one a literal-only site is tempted to leave bare (#1245)'
Assert-True (($errLines | Where-Object { $_ -like '*${reason//%/%25}*' }).Count -eq 1) 'while the reason keeps its own escape on the one line that carries it'


Write-Host ""
Write-Host "The label gate: does the label this PR would be given exist? (inbound #1221)" -ForegroundColor Cyan

# THE PAYLOAD IS THE REAL SHAPE of `gh label list --json name`, which is a flat array of {name}.
$labelJson = '[{"name":"documentation"},{"name":"question"},{"name":"inbound"}]'
$labelNames = @(Get-LabelNames -Json $labelJson)
Assert-Equal 3 $labelNames.Count 'every label name is read out of a gh label list payload'
Assert-Equal 'documentation' $labelNames[0] 'and in the order gh gave them'

# UNREADABLE IN, EMPTY OUT -- and the CALLER must read empty as "could not be asked", never as "the
# label is missing". A single-record payload is in this list on purpose: 5.1 hands a one-element parsed
# array to the pipeline as the record itself, which is the trap the assign-first/wrap-second shape
# navigates.
foreach ($bad in @('', '   ', 'not json', 'null', '[]', '[{}]', '[{"colour":"red"}]')) {
    Assert-Equal 0 (@(Get-LabelNames -Json $bad)).Count "an unreadable label payload ('$bad') yields no names rather than a wrong answer"
}
Assert-Equal 1 (@(Get-LabelNames -Json '[{"name":"bug"}]')).Count 'a ONE-record payload is read as one name, not flattened away'
Assert-Equal 1 (@(Get-LabelNames -Json '[{"name":"bug"},{"name":"bug"}]')).Count 'a duplicated name is counted once'

# THE MEASURED CASE. 'bug' and 'enhancement' were deleted org-wide in BWJ-ecommerce/smartwatchbanden on
# September 1, 2026 because the issue TYPE now carries that classification, and the next PR died on
# "could not add label: 'bug' not found" -- after every gate had run and the branch had been pushed.
$missing = Get-MissingLabelNote -Labels $labelNames -Label 'bug' -Prefix 'fix' `
                                -SeamPath 'scripts\lib\branch-info.ps1' -Repo 'BWJ-ecommerce/smartwatchbanden'
Assert-True ($missing -ne '') "the measured case is caught: 'bug' is not among the repo's labels"
Assert-True ($missing -like "*'bug' is not a label in BWJ-ecommerce/smartwatchbanden*") 'the note names the label and the repository'
Assert-True ($missing -like "*'fix/'*") 'and the branch prefix that produced it'
Assert-True ($missing -like '*branch-info.ps1*') 'and the repo-owned seam file that maps them, so the reader is sent to the edit'
Assert-True ($missing -like '*before the push*') 'and says the refusal came before the push, which is the whole point of the gate'
Assert-True ($missing -like '*gh label create*') 'the first remedy is paste-ready'
Assert-True ($missing -like "*'documentation', 'question' and 'inbound'*") 'the labels that DO exist are named -- what turns the refusal into a repair when the answer is a rename'

# A LABEL THAT EXISTS COSTS NOTHING AND SAYS NOTHING.
Assert-Equal '' (Get-MissingLabelNote -Labels $labelNames -Label 'documentation' -Prefix 'docs' -Repo 'x/y') 'a label that exists produces no note'
# CASE-INSENSITIVE, because GitHub is: it refuses to create 'Bug' beside 'bug', and `--label bug`
# attaches the existing 'Bug'. Refusing a PR gh would have opened is the one direction this gate must
# never fail in.
Assert-Equal '' (Get-MissingLabelNote -Labels @('Bug') -Label 'bug' -Prefix 'fix' -Repo 'x/y') 'a label that differs only in case is the same label to GitHub, so it is not refused'

# NOTHING TO JUDGE AGAINST IS NOT A REFUSAL -- an old gh with no --json, a network hiccup, a repo with
# no labels at all. A diagnostic must never be the reason a PR cannot be opened.
Assert-Equal '' (Get-MissingLabelNote -Labels @() -Label 'bug' -Prefix 'fix' -Repo 'x/y') 'an empty label list is "unknowable" and not "absent"'
Assert-Equal '' (Get-MissingLabelNote -Labels $null -Label 'bug' -Prefix 'fix' -Repo 'x/y') 'and so is no list at all'
Assert-Equal '' (Get-MissingLabelNote -Labels $labelNames -Label '' -Prefix 'fix' -Repo 'x/y') 'and so is an empty label -- a repo that attaches none has nothing for this gate to judge (inbound #1395)'

# THE FALLBACK HAS THE SAME HOLE ONE LAYER DOWN, which the report named: open-pr substitutes 'question'
# for an unknown prefix, and that is a GitHub DEFAULT label a repo may equally have deleted. The check
# is on the label that would be SENT, whatever produced it.
$fallbackNote = Get-MissingLabelNote -Labels @('documentation') -Label 'question' -Prefix '' -Repo 'x/y'
Assert-True ($fallbackNote -ne '') "the unknown-prefix fallback is checked too, not trusted"
Assert-True ($fallbackNote -like '*unknown-prefix fallback*') 'and the note says that is where the label came from, since there is no prefix to name'
Assert-True ($fallbackNote -notlike "*''/*") 'and it never prints an empty prefix as if it were one'

# ABOVE TEN LABELS THE COUNT REPLACES THE LIST. A label set is unbounded in a way a commit's check
# suites are not, and this note is read once in a terminal.
$many = @(1..12 | ForEach-Object { "label-$_" })
$manyNote = Get-MissingLabelNote -Labels $many -Label 'bug' -Prefix 'fix' -Repo 'x/y'
Assert-True ($manyNote -like '*12 labels do exist*') 'a large label set is counted rather than listed'
Assert-True ($manyNote -like '*gh label list --repo x/y*') 'and the command that lists them is given instead'
Assert-True ($manyNote -notlike '*label-7*') 'so the refusal cannot become a wall of names'

# AND open-pr.ps1 ACTUALLY RUNS IT, BEFORE THE PUSH. Without this assert every check above stays green
# while the label is resolved one line before `gh pr create` again -- which IS the defect, not a
# regression in the helper. Same reasoning as the #919 ordering assert above and the #1044 call-site one
# below: the script is the one caller no suite gets to run.
$idxLabelGate = $openPrText.IndexOf('Get-MissingLabelNote -Labels')
$idxPush      = $openPrText.IndexOf("Invoke-NativeCapture -FilePath 'git' -Arguments @('push'")
# LastIndexOf BEFORE the push, not IndexOf: -GatesOnly calls Invoke-WorkflowGates near the top of the
# script and exits, so the first occurrence is not the one on the push path.
$idxGates     = if ($idxPush -ge 0) { $openPrText.LastIndexOf('Invoke-WorkflowGates -RepoRoot', $idxPush) } else { -1 }
$idxCreate    = $openPrText.IndexOf("@('pr', 'create'")
Assert-True ($idxLabelGate -ge 0) 'open-pr.ps1 asks whether the label exists (inbound #1221)'
Assert-True ($idxPush -gt $idxLabelGate) 'and it asks BEFORE the push, which is the whole repair -- a failed create after the push leaves a pushed branch with no PR'
Assert-True ($idxGates -gt $idxLabelGate) 'and before the lint and test gates, so the author hears it in seconds rather than after the suites'
Assert-True ($idxCreate -gt $idxLabelGate) 'and the create still gets the label that was checked'
Assert-True ($openPrText -like "*@('label', 'list', '--json', 'name', '--limit', '500'*") 'the query names --limit, because gh label list defaults to 30 and a truncated list would refuse a label that exists'
$idxResolve = $openPrText.IndexOf('$label = $info.Label')
Assert-True ($idxResolve -ge 0 -and $idxResolve -lt $idxPush) 'the label is RESOLVED before the push too -- a check on a label resolved later would be checking nothing'
Assert-True (([regex]::Matches($openPrText, '\$label = \$info\.Label')).Count -eq 1) 'and resolved in exactly one place, so the checked label and the sent label cannot differ'
Assert-True ($openPrText -like '*if (-not $existingPr) {*') 'the gate is on the create path only -- an existing PR keeps its own labels and is never sent one'

Write-Host ""
Write-Host "open-pr.ps1 sends NO --label when the seam answers none (inbound #1395)" -ForegroundColor Cyan
# THE MEASURED CASE. BWJ-ecommerce/smartwatchbanden abolished PR labels outright on September 4, 2026 --
# the issue TYPE carries the classification now -- so its prefix table answers Label = $null for every
# prefix it knows. Get-MissingLabelNote reads that as "nothing to check" (asserted above) and the create
# appended `--label ''` anyway, which gh reads as a label that does not exist: it refuses the WHOLE
# create, after the push, with every gate including the label gate green.
#
# TEXT ASSERTS, for the same reason the block above gives: the script is the one caller no suite gets to
# run, and the helper being right is exactly what was already true when this failed.
$idxCreateLine = $openPrText.IndexOf("@('pr', 'create'")
$createLine    = if ($idxCreateLine -ge 0) { ($openPrText.Substring($idxCreateLine) -split "`n")[0] } else { '' }
Assert-True ($createLine -notlike '*--label'', $label*') 'the create no longer interpolates the label into its fixed argument list -- an empty answer became `--label ''''`, a label gh cannot find'
Assert-True ($createLine -like '*+ $labelArgs*') 'it appends a composed $labelArgs instead, the way it already appends the optional assignee and milestone'
Assert-True (([regex]::Matches($openPrText, '\$labelArgs = if \(\$label\)')).Count -eq 1) 'and $labelArgs is composed in exactly one place, so the checked label and the sent label still cannot differ'
Assert-True ($openPrText -like '*$labelArgs = if ($label) { @(''--label'', $label) } else { @() }*') 'the flag travels only when there is a label to put behind it'

# THE NORMALISATION IS PART OF THE REPAIR, not tidiness: the seam is free to answer $null, and $null in a
# native argument list is an EMPTY ARGUMENT rather than an absent one. Trimmed too -- ' ' is not a label.
$idxTrim = $openPrText.IndexOf('$label = "$label".Trim()')
Assert-True ($idxTrim -ge 0) 'the resolved label is normalised to a trimmed string, so a $null or blank seam answer cannot reach gh as an argument'
Assert-True ($idxTrim -gt $idxResolve -and $idxTrim -lt $idxLabelGate) 'and it happens between the resolve and the gate, so both read the same value'

# THE QUERY IS SKIPPED, not merely the compare: a `gh label list` whose answer cannot change the outcome
# is the cheapest call in this script to leave out, and both of its failure warnings would otherwise name
# a label there is none of.
$idxEmptyBranch = $openPrText.IndexOf('if (-not $label) {')
$idxLabelList   = $openPrText.IndexOf("@('label', 'list', '--json'")
Assert-True ($idxEmptyBranch -ge 0) 'open-pr.ps1 recognises "this repo attaches no label" as an answer rather than a gap'
Assert-True ($idxEmptyBranch -lt $idxLabelList) 'and it recognises it BEFORE asking gh for a label list whose answer cannot matter'
Assert-True ($idxEmptyBranch -lt $idxLabelGate) 'and before the compare, so the success line can never announce that '''' exists in the repository'

Write-Host ""
Write-Host "open-pr.ps1 wires in the already-done check (issue #1282)" -ForegroundColor Cyan
# The helper is proven pure above; this proves the script actually calls it, and BEFORE the push --
# a warning that arrives after forty test suites and a push is the failure #1282 describes, not a fix.
$idxAlreadyDone = $openPrText.IndexOf('Get-TargetIssueWarnings -TargetIssues')
Assert-True ($idxAlreadyDone -ge 0) 'open-pr.ps1 calls Get-TargetIssueWarnings'
Assert-True ($idxAlreadyDone -lt $idxPush) 'and it runs before the push, so the author hears it in seconds'
Assert-True ($idxAlreadyDone -lt $idxGates) 'and before the lint and test gates'
Assert-True ($openPrText.Contains("'number,state,headRefName,body'")) 'the PR-body search asks for the four fields the helper reads'
Assert-True ($openPrText.Contains("'--state', 'all'")) "the search is --state all, so a MERGED claimant counts -- that is the #1282 case"
Assert-True ($openPrText -like '*-CurrentBranch $branch*') "the current branch is passed, so this branch's own PR is not read as a rival"

# --- Get-DirectPushBlockingRules / Get-FoldPushVerdict (issue #1278) ------------------------------
# WHY THIS BLOCK EXISTS. ship-pr merged PR #1271, checked out main, folded, committed -- and the push
# was refused with GH013, "Required status check 'lint-en-tests' is expected". The run ended
# merged-but-unfolded: the entry unfolded, the branch document still on the trunk, every gate green
# until a release trips over it. That is step 0's own failure mode reached by a second route, so the
# repair is step 0's answer -- refuse before the merge, where refusing costs nothing.
#
# THE TWO READS ARE INDEPENDENT, and that is the property the whole check rests on. Measured against
# the live API on September 3, 2026: `rules/branches/main` returns `required_status_checks` to an
# account whose `current_user_can_bypass` is `always`, so the rule list does NOT tell you whether this
# account is bound by it. A verdict made from the rule list alone would refuse every ship in this repo.
Write-Host "`nGet-DirectPushBlockingRules / Get-FoldPushVerdict (#1278)" -ForegroundColor Cyan

# The live shape, transcribed from `gh api repos/DKJ-Solutions/claude-code-specialists/rules/branches/main`
# on the day of the failure -- so the fixture is what GitHub actually sends, not what it might send.
$rulesMain = @'
[{"type":"deletion","ruleset_source_type":"Repository","ruleset_source":"DKJ-Solutions/claude-code-specialists","ruleset_id":19008062},
 {"type":"non_fast_forward","ruleset_source_type":"Repository","ruleset_source":"DKJ-Solutions/claude-code-specialists","ruleset_id":19008062},
 {"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":false,"do_not_enforce_on_create":false,"required_status_checks":[{"context":"lint-en-tests","integration_id":15368}]},"ruleset_source_type":"Repository","ruleset_source":"DKJ-Solutions/claude-code-specialists","ruleset_id":19008062}]
'@

$blocking = Get-DirectPushBlockingRules -BranchRulesJson $rulesMain
Assert-True $blocking.Readable 'the live rules payload reads'
Assert-Equal 1 $blocking.Blocking.Count 'one ruleset carries a rule a direct push cannot satisfy'
Assert-Equal '19008062' $blocking.Blocking[0].RulesetId 'and it is named by id, which is what the bypass is looked up with'
Assert-Equal 'required_status_checks' ($blocking.Blocking[0].Rules -join ',') 'only the blocking rule is reported'
Assert-Equal 'lint-en-tests' ($blocking.Blocking[0].Contexts -join ',') 'and the check context, so the refusal can name what the remote names'

# THE THREE THAT DO NOT BLOCK, asserted by name. `deletion` and `non_fast_forward` sit in the SAME
# ruleset as the one that does, so a function that reported per-ruleset instead of per-rule would look
# identical on this repo and refuse a fold on a trunk that merely forbids force-pushes.
$harmless = Get-DirectPushBlockingRules -BranchRulesJson '[{"type":"deletion","ruleset_id":7},{"type":"non_fast_forward","ruleset_id":7},{"type":"required_linear_history","ruleset_id":7},{"type":"required_signatures","ruleset_id":7}]'
Assert-True $harmless.Readable 'a payload of only non-blocking rules still reads'
Assert-Equal 0 $harmless.Blocking.Count 'deletion, non_fast_forward, required_linear_history and required_signatures do not block a fold'

# The other two that DO, and they are the definition of each rule rather than a guess: `pull_request`
# demands the change arrive through a PR (a fold does not), and `update` restricts the ref update itself.
$pr = Get-DirectPushBlockingRules -BranchRulesJson '[{"type":"pull_request","ruleset_id":8}]'
Assert-Equal 1 $pr.Blocking.Count 'a pull_request rule blocks a fold -- the fold is not a pull request'
$upd = Get-DirectPushBlockingRules -BranchRulesJson '[{"type":"update","ruleset_id":9}]'
Assert-Equal 1 $upd.Blocking.Count 'an update rule blocks a fold -- it restricts the ref update itself'

# EMPTY IS NOT UNREADABLE, and 5.1 makes that worth an assert: '[]' parses to $null, which is exactly
# what a failed parse leaves behind. Read as unreadable, every consumer with an unprotected trunk would
# get a warning on every ship for a question that has a clean answer.
$none = Get-DirectPushBlockingRules -BranchRulesJson '[]'
Assert-True $none.Readable 'an empty rule list READS -- a trunk with no rules is an answer, not a failure'
Assert-Equal 0 $none.Blocking.Count 'and nothing blocks'

Assert-True (-not (Get-DirectPushBlockingRules -BranchRulesJson '').Readable) 'an empty payload is unreadable'
Assert-True (-not (Get-DirectPushBlockingRules -BranchRulesJson 'not json').Readable) 'and so is an unparseable one'

# THE VERDICT, and the case the issue is about. `maikel-bwj` is neither an OrganizationAdmin nor holder
# of the repo admin role, the two bypass actors main-ci-gate carries, so its current_user_can_bypass is
# 'never' -- and every ship-pr run from that account merged and then could not push the fold.
$blocked = Get-FoldPushVerdict -BranchRulesJson $rulesMain -BypassByRulesetId @{ '19008062' = 'never' } -NameByRulesetId @{ '19008062' = 'main-ci-gate' }
Assert-True $blocked.Blocked 'an account that cannot bypass the required status check is refused BEFORE the merge (#1278)'
Assert-True (-not $blocked.Unknown) 'and that is a decision, not an unknown'
Assert-True ($blocked.Reason -like '*main-ci-gate*') 'the reason names the ruleset, so the remedy has an address'
Assert-True ($blocked.Reason -like '*lint-en-tests*') 'and the check, so it is recognisably the same event as the GH013 text'

# THE OTHER HALF, and the one that must not regress: this repo's own owner ships many times a day
# through exactly this ruleset. A verdict that refused here would be worse than the defect.
$allowed = Get-FoldPushVerdict -BranchRulesJson $rulesMain -BypassByRulesetId @{ '19008062' = 'always' }
Assert-True (-not $allowed.Blocked) 'an account with bypass ships as before'
Assert-True (-not $allowed.Unknown) 'and says so rather than warning'

# 'pull_requests_only' IS NOT BYPASS HERE. GitHub's three values answer "may this actor bypass"; only
# 'always' answers yes for a DIRECT push, and the fold is a direct push by design. Asserted separately
# because the word 'bypass' in that value is exactly what invites reading it as a yes.
$prOnly = Get-FoldPushVerdict -BranchRulesJson $rulesMain -BypassByRulesetId @{ '19008062' = 'pull_requests_only' }
Assert-True $prOnly.Blocked 'pull_requests_only is not bypass for a fold -- the fold is not a pull request'

# UNKNOWN WARNS, IT DOES NOT REFUSE -- the opposite posture to Get-MergeBlockVerdict, and deliberately.
# There an unread required-check list could let red code onto the trunk. Here the thing at risk is a
# fold that can be redone by hand, while refusing on an unread ruleset would take ship-pr away from
# every consumer whose token cannot read one. Same answer as step 0's own unreadable-worktree arm.
$unknownBypass = Get-FoldPushVerdict -BranchRulesJson $rulesMain -BypassByRulesetId @{}
Assert-True (-not $unknownBypass.Blocked) 'an unread bypass never refuses a ship'
Assert-True $unknownBypass.Unknown 'but it does say the question was not answered'

$unknownRules = Get-FoldPushVerdict -BranchRulesJson 'not json'
Assert-True (-not $unknownRules.Blocked) 'an unread rule list never refuses a ship either'
Assert-True $unknownRules.Unknown 'and is likewise reported rather than swallowed'

$clean = Get-FoldPushVerdict -BranchRulesJson '[]'
Assert-True (-not $clean.Blocked) 'a trunk with no rules ships'
Assert-True (-not $clean.Unknown) 'silently -- there is nothing to warn about'

# A ruleset whose blocking rule is bypassable while a SECOND one is not: the verdict is per ruleset, and
# one bypassable ruleset must not clear another. Both live in the same payload, as they would on a repo
# carrying an org ruleset on top of its own.
$twoRulesets = '[{"type":"required_status_checks","parameters":{"required_status_checks":[{"context":"ci"}]},"ruleset_id":1,"ruleset_source_type":"Repository"},{"type":"pull_request","ruleset_id":2,"ruleset_source_type":"Organization","ruleset_source":"DKJ-Solutions"}]'
$mixed = Get-FoldPushVerdict -BranchRulesJson $twoRulesets -BypassByRulesetId @{ '1' = 'always'; '2' = 'never' }
Assert-True $mixed.Blocked 'bypass on one ruleset does not clear another that blocks'
Assert-True ($mixed.Reason -notlike '*ruleset_id*1*applies*') 'and the bypassed one is not named as a blocker'
$twoBlocking = Get-DirectPushBlockingRules -BranchRulesJson $twoRulesets
$orgRec = @($twoBlocking.Blocking | Where-Object { $_.RulesetId -eq '2' })[0]
Assert-Equal 'Organization' $orgRec.SourceType 'the source type travels, because an org ruleset is not under repos/<repo>/rulesets and asking for it there 404s'
Assert-Equal 'DKJ-Solutions' $orgRec.Source 'and so does the org name the detail read needs'

# AND ship-pr.ps1 ACTUALLY RUNS IT, BEFORE THE MERGE. Without this assert every check above stays green
# while the orchestrator merges first and folds into a rejection again -- which IS the defect, not a
# regression in the helper. Same reasoning as the open-pr ordering asserts above: this file is the one
# caller no suite gets to run.
$idxFoldGate = $shipText.IndexOf('Get-FoldPushVerdict -BranchRulesJson')
$idxOpenPr   = $shipText.IndexOf("'-File', (Join-Path `$PSScriptRoot 'open-pr.ps1')")
$idxMergeNow = $shipText.IndexOf("@('pr', 'merge'")
Assert-True ($idxFoldGate -ge 0) 'ship-pr.ps1 asks whether it can push the fold (#1278)'
Assert-True ($idxOpenPr -gt $idxFoldGate) 'and it asks BEFORE step 1, so nothing is pushed and no PR exists when it refuses'
Assert-True ($idxMergeNow -gt $idxFoldGate) 'and long before the merge, which is the whole repair'
$idxWorktree = $shipText.IndexOf("Get-WorktreeHoldingBranch -PorcelainLines")
Assert-True ($idxWorktree -ge 0 -and $idxWorktree -lt $idxFoldGate) 'the free local check still runs first -- a network read must not cost the one that needs no network'
Assert-True ($shipText -like '*rules/branches/main*') 'the trunk rules are read from the branch endpoint, which does NOT filter by bypass'
Assert-True ($shipText -like '*current_user_can_bypass*') 'and the bypass from the ruleset detail, which is the only endpoint carrying it'
Assert-True ($shipText -like '*orgs/$($rec.Source)/rulesets/*') 'an Organization ruleset is read from the org endpoint'
Assert-True ($shipText -like '*this is the cheap place to stop*') 'the refusal says nothing was merged, which is the fact the reader needs first'


# --- Get-MergeQueueVerdict: is the trunk behind a merge queue? (issue #1506) ----------------------
# WHY THIS BLOCK EXISTS. Under a queue `gh pr merge` ENQUEUES and exits 0; GitHub merges the PR
# minutes later on a gh-readonly-queue/** branch, in a process the shipping session never observes.
# Folding on that exit code writes the changelog entry onto the trunk ahead of the merge it describes
# (#1325), so ship-pr has to know which of the two worlds it is in BEFORE it decides to fold.
#
# THE PAYLOAD IS THE ONE STEP 0b ALREADY FETCHED, which is why this is a separate reader over the same
# JSON rather than a second gh call -- and why the assert below feeds it the live shape verbatim.
Write-Host ""
Write-Host "Get-MergeQueueVerdict -- the trunk behind a queue (#1506)" -ForegroundColor Cyan

# The live shape, transcribed from `gh api repos/DKJ-Solutions/claude-code-specialists/rules/branches/main`
# on September 6, 2026, the day the queue went live on main-ci-gate. Trimmed to the type/ruleset_id
# pairs this function reads; the parameters blocks are Get-DirectPushBlockingRules's business.
$rulesQueued = '[{"type":"deletion","ruleset_id":19008062},{"type":"non_fast_forward","ruleset_id":19008062},{"type":"required_status_checks","ruleset_id":19008062,"parameters":{"required_status_checks":[{"context":"lint-en-tests"}]}},{"type":"merge_queue","ruleset_id":19008062,"parameters":{"merge_method":"MERGE"}}]'

$q = Get-MergeQueueVerdict -BranchRulesJson $rulesQueued
Assert-True $q.Readable 'the live trunk payload is readable'
Assert-True $q.Active 'and a merge_queue rule in it reads as an active queue'

# The same trunk WITHOUT the queue rule -- this repo's own shape until September 6, 2026. Readable and
# not active is the answer that sends ship-pr down the direct-merge path, so it must be distinguishable
# from the unreadable case below by more than the Active flag alone.
$rulesNoQueue = '[{"type":"deletion","ruleset_id":19008062},{"type":"required_status_checks","ruleset_id":19008062}]'
$nq = Get-MergeQueueVerdict -BranchRulesJson $rulesNoQueue
Assert-True $nq.Readable 'a trunk with rules but no merge_queue is still readable'
Assert-True (-not $nq.Active) 'and reads as no queue'

# A trunk with NO rules at all -- the ordinary consumer. An empty JSON array parses to $null in 5.1,
# which is the legitimate "no rules" answer and must not be mistaken for unparseable.
$empty = Get-MergeQueueVerdict -BranchRulesJson '[]'
Assert-True $empty.Readable 'an empty rule list is readable, not unreadable -- 5.1 parses [] to $null'
Assert-True (-not $empty.Active) 'and reads as no queue'

# UNREADABLE IS NOT "NO QUEUE", and this pair is the assert that stops a later simplification from
# collapsing them. Both return Active = $false; only Readable tells the caller whether that $false was
# an answer or a shrug, and ship-pr keeps its OLD behaviour on a shrug.
Assert-True (-not (Get-MergeQueueVerdict -BranchRulesJson '').Readable) 'an empty payload is unreadable'
Assert-True (-not (Get-MergeQueueVerdict -BranchRulesJson 'not json').Readable) 'and so is an unparseable one'
Assert-True (-not (Get-MergeQueueVerdict -BranchRulesJson 'not json').Active) 'and an unreadable payload never claims a queue'

# The type is matched case- and whitespace-insensitively, like every other type read in this file.
Assert-True (Get-MergeQueueVerdict -BranchRulesJson '[{"type":" Merge_Queue "}]').Active `
    'the rule type is normalised before it is compared, as the sibling readers do'

# AND THE OMISSION IN Get-DirectPushBlockingRules IS DELIBERATE, so it is pinned rather than left to be
# "fixed" by a later sweep. A merge_queue rule DOES block a direct push -- both refusals appeared in the
# GH013 text of the fold-on-merge run carrying the #1504 merge -- but a caller reads this verdict first
# and never reaches the fold-push question, so listing the type there too would add an unreachable
# branch and a second answer to one question.
$mqOnly = Get-DirectPushBlockingRules -BranchRulesJson '[{"type":"merge_queue","ruleset_id":19008062}]'
Assert-True $mqOnly.Readable 'a merge_queue-only payload is readable'
Assert-Equal 0 $mqOnly.Blocking.Count 'and merge_queue is NOT a fold-push blocker -- Get-MergeQueueVerdict owns that question (#1506)'

# --- Get-RequiredCheckRunIds: which Actions run sits behind a named check? (issue #1292 re-anchor) ---
# THE RE-ANCHOR: the retired Get-CertifyingRunTimestamp read a check's own startedAt directly out of
# the checks payload -- a red-team caught that startedAt under-refuses (it can only be LATER than the
# true ref-fix moment, so a commit landing in that gap silently reads as tested when it was not). The
# repair instead finds the RUN behind a required check from its 'link', so the caller can ask that
# run's own created_at, which stays anchored across a re-run in a way startedAt does not (see
# Get-CertifyingRunCreatedAt's own header for the measured instance).
Write-Host ""
Write-Host "Get-RequiredCheckRunIds -- the run(s) behind named checks (issue #1292 re-anchor)" -ForegroundColor Cyan

$oneLinked = '[{"name":"lint-en-tests","link":"https://github.com/o/r/actions/runs/111/job/222"}]'
Assert-Equal '111' (@(Get-RequiredCheckRunIds -ChecksJson $oneLinked -Names @('lint-en-tests'))[0]) 'a single named check resolves its run id from the link'

# No names at all -- nothing to look up, so no read of the payload is even attempted.
Assert-Equal 0 @(Get-RequiredCheckRunIds -ChecksJson $oneLinked -Names @()).Count 'no names -> empty'
Assert-Equal 0 @(Get-RequiredCheckRunIds -ChecksJson $oneLinked).Count 'Names omitted (defaults to empty) -> empty'

# Every unreadable ChecksJson shape collapses to empty, same posture as every other reader in this file.
foreach ($bad in @('', '   ', 'not json', 'null', '[]', '{}')) {
    Assert-Equal 0 @(Get-RequiredCheckRunIds -ChecksJson $bad -Names @('lint-en-tests')).Count "unreadable ChecksJson ('$bad') -> empty"
}
Assert-Equal 0 @(Get-RequiredCheckRunIds -Names @('lint-en-tests')).Count 'ChecksJson omitted -> empty'

# A name absent from the checks payload -- nothing in the payload can answer for it.
Assert-Equal 0 @(Get-RequiredCheckRunIds -ChecksJson $oneLinked -Names @('claude-review')).Count 'a name matching no record -> empty'

# TWO NAMED CHECKS, DIFFERENT RUNS -- both ids come back, in payload order.
$twoLinked = @'
[
  {"name":"lint-en-tests","link":"https://github.com/o/r/actions/runs/111/job/222"},
  {"name":"claude-review","link":"https://github.com/o/r/actions/runs/333/job/444"}
]
'@
$twoIds = @(Get-RequiredCheckRunIds -ChecksJson $twoLinked -Names @('lint-en-tests', 'claude-review'))
Assert-Equal (('111', '333') -join ',') ($twoIds -join ',') 'two named checks -> both run ids, in payload order'

# TWO NAMED CHECKS, THE SAME RUN -- one id, not two: two jobs of one workflow run share a run id, and
# the caller must not ask gh for the same run's created_at twice.
$sameRun = @'
[
  {"name":"lint-en-tests","link":"https://github.com/o/r/actions/runs/111/job/222"},
  {"name":"claude-review","link":"https://github.com/o/r/actions/runs/111/job/555"}
]
'@
$dedupedIds = @(Get-RequiredCheckRunIds -ChecksJson $sameRun -Names @('lint-en-tests', 'claude-review'))
Assert-Equal 1 $dedupedIds.Count 'two checks from the SAME run -> one id, deduplicated'
Assert-Equal '111' $dedupedIds[0] 'and it is the shared run id'

# A LINK NAMING NO ACTIONS RUN IS SKIPPED, not a crash and not a bogus id -- an external status check
# (e.g. a third-party CI service) has no Actions run behind it at all.
$externalLink = '[{"name":"netlify","link":"https://app.netlify.com/deploy/abc123"}]'
Assert-Equal 0 @(Get-RequiredCheckRunIds -ChecksJson $externalLink -Names @('netlify')).Count 'a link naming no Actions run resolves nothing'

# NON-NAMED CHECKS ARE IGNORED even when they carry a resolvable run -- only the caller's own -Names
# take part, so a check outside the ruleset cannot smuggle its run in.
$withNonRequired = @'
[
  {"name":"lint-en-tests","link":"https://github.com/o/r/actions/runs/111/job/222"},
  {"name":"netlify","link":"https://github.com/o/r/actions/runs/999/job/888"}
]
'@
$onlyRequired = @(Get-RequiredCheckRunIds -ChecksJson $withNonRequired -Names @('lint-en-tests'))
Assert-Equal (@('111') -join ',') ($onlyRequired -join ',') "a non-required check's run id does not ride along"

# A record with no name is skipped rather than throwing, same as every other reader in this file.
Assert-Equal 0 @(Get-RequiredCheckRunIds -ChecksJson '[{"link":"https://github.com/o/r/actions/runs/111/job/222"}]' -Names @('lint-en-tests')).Count 'a nameless record cannot match a required name'


# --- Get-CertifyingRunCreatedAt: the earliest already-fetched created_at (issue #1292 re-anchor) -----
# PURE reduction over values the caller has already fetched (`gh api .../actions/runs/<id>
# --jq '.created_at'`) for each id Get-RequiredCheckRunIds named. Anchored on created_at rather than a
# check's startedAt specifically because created_at stays fixed across a re-run and startedAt does not
# -- verified on a genuine re-run in the source repo's own history; see the function's own header.
Write-Host ""
Write-Host "Get-CertifyingRunCreatedAt -- the earliest already-fetched created_at (issue #1292 re-anchor)" -ForegroundColor Cyan

Assert-Equal ([datetime]::Parse('2026-09-02T15:59:52Z').ToUniversalTime().Ticks) `
    ((Get-CertifyingRunCreatedAt -CreatedAtValues @('2026-09-02T15:59:52Z')).Ticks) `
    'a single value returns its own timestamp'

# THE EARLIEST WINS, because a ruleset can require checks from more than one distinct triggering run;
# the earliest is closest to when ANY of them fixed a ref this branch is being merged against.
$earliestCreated = Get-CertifyingRunCreatedAt -CreatedAtValues @('2026-09-02T15:59:52Z', '2026-09-02T10:00:00Z')
Assert-Equal ([datetime]::Parse('2026-09-02T10:00:00Z').ToUniversalTime().Ticks) $earliestCreated.Ticks 'two values -> the EARLIER one wins, not the first in the array'

# THE ZERO-TIME SHAPE (issue #977's `0001-01-01T00:00:00Z`) MUST STILL BE SKIPPED, NOT TREATED AS THE
# EARLIEST -- a zero anchor would otherwise always be the minimum and would void every certificate,
# exactly the failure the retired Get-CertifyingRunTimestamp's own asserts caught, carried over here.
$skippingZeroCreated = Get-CertifyingRunCreatedAt -CreatedAtValues @('0001-01-01T00:00:00Z', '2026-09-02T10:00:00Z')
Assert-Equal ([datetime]::Parse('2026-09-02T10:00:00Z').ToUniversalTime().Ticks) $skippingZeroCreated.Ticks 'a zero-time value is skipped rather than winning as the earliest'

# When EVERY value is zero-time, blank, unparseable, or absent, none can answer -- $null, never the
# floor of the type.
Assert-True ($null -eq (Get-CertifyingRunCreatedAt -CreatedAtValues @('0001-01-01T00:00:00Z'))) 'every value unstarted-shaped -> $null, never the epoch'
Assert-True ($null -eq (Get-CertifyingRunCreatedAt -CreatedAtValues @('', '   ', $null))) 'blank/whitespace/null values -> $null'
Assert-True ($null -eq (Get-CertifyingRunCreatedAt)) 'no values at all (default) -> $null'
Assert-True ($null -eq (Get-CertifyingRunCreatedAt -CreatedAtValues @())) 'an explicit empty array -> $null'
Assert-True ($null -eq (Get-CertifyingRunCreatedAt -CreatedAtValues @('not a date'))) 'an unparseable value -> $null'

# An unparseable value beside a real one costs nothing -- the real one still wins.
$mixedCreated = Get-CertifyingRunCreatedAt -CreatedAtValues @('not a date', '2026-09-02T10:00:00Z')
Assert-Equal ([datetime]::Parse('2026-09-02T10:00:00Z').ToUniversalTime().Ticks) $mixedCreated.Ticks 'an unparseable value beside a real one -> the real one wins'


# --- Get-StaleCertificateVerdict: has 'main' moved since the certifying run? (issue #1292) ----------
# PURE: the caller does the git reading (fetch + first-parent log since the certifying timestamp) and
# hands the resulting SHA list here. This is the whole decision table, without a live remote.
Write-Host ""
Write-Host "Get-StaleCertificateVerdict -- has 'main' moved since the certifying run? (issue #1292)" -ForegroundColor Cyan

$noCommits = Get-StaleCertificateVerdict -NewMainCommits @()
Assert-Equal $false $noCommits.Stale        'no new commits -> not stale'
Assert-Equal 0      $noCommits.Count        'and the count is zero'
Assert-Equal 0      @($noCommits.Commits).Count 'and the commit list is empty, not $null'

$defaulted = Get-StaleCertificateVerdict
Assert-Equal $false $defaulted.Stale 'the default (no -NewMainCommits at all) reads the same as an explicit empty list'

$nullPassed = Get-StaleCertificateVerdict -NewMainCommits $null
Assert-Equal $false $nullPassed.Stale 'an explicit $null is treated the same as no commits, not as a crash'

$oneCommit = Get-StaleCertificateVerdict -NewMainCommits @('aaaaaaaa1111111111111111111111111111aaaa')
Assert-Equal $true $oneCommit.Stale  'one commit -> stale'
Assert-Equal 1     $oneCommit.Count  'and the count is one'
Assert-Equal 'aaaaaaaa1111111111111111111111111111aaaa' $oneCommit.Commits[0] 'and the SHA itself comes through'

$shaA = 'a1111111111111111111111111111111111111a'
$shaB = 'b2222222222222222222222222222222222222b'
$shaC = 'c3333333333333333333333333333333333333c'
$severalCommits = Get-StaleCertificateVerdict -NewMainCommits @($shaA, $shaB, $shaC)
Assert-Equal $true $severalCommits.Stale 'several commits -> stale'
Assert-Equal 3     $severalCommits.Count 'with the right count'
Assert-Equal (($shaA, $shaB, $shaC) -join ',') (($severalCommits.Commits) -join ',') 'and the SHAs come through in the order git produced them'

# DUPLICATE SHAs ARE DE-DUPLICATED (piped through Select-Object -Unique), so a commit that shows up
# twice in the log read (e.g. a caller that re-queries) does not inflate the count.
$dupedCommits = Get-StaleCertificateVerdict -NewMainCommits @($shaA, $shaA, $shaB)
Assert-Equal $true $dupedCommits.Stale 'duplicates still read as stale'
Assert-Equal 2     $dupedCommits.Count 'but the duplicate is not counted twice'

# NULL/EMPTY/WHITESPACE ENTRIES ARE FILTERED OUT AND DO NOT INFLATE THE COUNT -- git's own output is
# newline-split by the caller and could hand through a blank line at the end.
$withBlanks = Get-StaleCertificateVerdict -NewMainCommits @($shaA, '', '   ', $null, $shaB)
Assert-Equal $true $withBlanks.Stale 'blank/whitespace/null entries beside real SHAs still read as stale'
Assert-Equal 2     $withBlanks.Count 'and they are not counted as commits themselves'

# Blanks alone -> no commits at all, not a stale verdict manufactured from nothing.
$onlyBlanks = Get-StaleCertificateVerdict -NewMainCommits @('', '   ', $null)
Assert-Equal $false $onlyBlanks.Stale 'only blank/whitespace/null entries -> not stale'
Assert-Equal 0      $onlyBlanks.Count 'with a count of zero'


# --- ship-pr.ps1's step 3b: the wiring, as far as a suite without a live remote can reach it --------
# THE ACTUAL git fetch/gh api/git log/refusal WIRING DRIVES A REAL REMOTE AND IS NOT COVERED HERE -- the
# same known gap this file's own header states for step 3's wait, step 4's merge, and every other live
# git/gh call in this script. What follows is what IS assertable without one: that step 3b calls the
# pure functions above with the arguments the re-anchor actually needs, that it reuses the check facts
# step 3 already fetched to find the run(s) rather than searching fresh, that -SkipStaleCheck actually
# gates the whole block, and that EVERY refusal path the re-anchor added -- not only the stale-certificate
# one -- prints a recognisable sentence and names the valve. Anchors are literal code fragments (a call
# with its actual argument names, an exact printed sentence) rather than a text-position ordering, per
# Sylvester's own caution: his FIRST build of this step broke an existing ordering assert in this file by
# mentioning a function name earlier in a doc comment, so a position-based assert here would carry the
# identical fragility on the very branch that pointed it out.
#
# THE FAIL-CLOSED LINE MOVED WITH THE RE-ANCHOR, AND BOTH SIDES OF IT ARE ASSERTED: no required check
# named still WARNS (nothing to protect there -- refusing would permanently block a repo with no
# ruleset), but once one IS named, every read that follows -- the run id, its created_at, the fetch, the
# log -- FAILS CLOSED rather than warning, which is the opposite of what the retired
# Get-CertifyingRunTimestamp build did.
Write-Host ""
Write-Host "ship-pr.ps1's step 3b -- what is assertable without a live remote (issue #1292 re-anchor)" -ForegroundColor Cyan

Assert-True ($shipText -like '*Get-RequiredCheckRunIds -ChecksJson $checkFactsJson -Names $staleCheckNames*') 'step 3b finds the run(s) behind the required check(s) from the check facts step 3 already fetched -- no fresh search'
Assert-True ($shipText -like '*Get-CertifyingRunCreatedAt -CreatedAtValues $createdAtValues*') 'and reduces the fetched created_at values with the re-anchored selector, not the retired startedAt one'
Assert-True ($shipText -like '*Get-StaleCertificateVerdict -NewMainCommits $newMainCommits*') 'and hands the freshly fetched main history to the verdict function, unchanged by the re-anchor'
Assert-True ($shipText -like '*$requiredFactsJson | ConvertFrom-Json*') 'the required check names for the stale check are parsed from the already-fetched required-checks payload, not a second gh call'
Assert-True ($shipText -like '*''api'', "repos/$repo/actions/runs/$runId", ''--jq'', ''.created_at''*') 'the one NEW network call per certifying run asks for that run''s own created_at, not a check''s startedAt'

# -SkipStaleCheck actually gates the block: the whole read-and-refuse path sits behind the switch.
Assert-True ($shipText -like '*if ($SkipStaleCheck) {*') 'the escape valve is an if/else around the whole step, not a flag checked deep inside it'
Assert-True ($shipText -like '*-SkipStaleCheck set -- not checking whether*') 'and taking the escape valve says so out loud rather than silently skipping'

# NO REQUIRED CHECK NAMED -> WARN, NOT REFUSE. Nothing this predicate can protect in that repo (no
# ruleset, or an unreadable one -- indistinguishable here), so refusing would permanently block ship-pr
# on every repo without one.
Assert-True ($shipText -like '*if ($staleCheckNames.Count -eq 0) {*') 'an unknown required-check state is branched on explicitly, not folded into the refusal path'
Assert-True ($shipText -like '*no required check name is known -- not checked*') 'and it warns rather than refuses -- there is nothing here for the predicate to protect'

# ONCE A REQUIRED CHECK IS NAMED, EVERY SUBSEQUENT READ FAILS CLOSED -- the opposite posture from the
# retired build, which warned on an unresolved anchor. Each refusal below names the valve.
Assert-True ($shipText -like '*no GitHub Actions run could be found behind the required check(s)*') 'an unresolvable run behind a NAMED required check refuses -- known certificate, not verified'
Assert-True ($shipText -like '*could not read ''created_at'' for at least one run*') 'a failed created_at read refuses too, for the same reason'
Assert-True ($shipText -like '*reported no readable ''created_at''*') 'and an unparseable created_at across every run refuses as well'
Assert-True ($shipText -like '*''git fetch origin main'' failed -- NOT merged*') 'a failed fetch of ''main'' now refuses rather than warning'
Assert-True ($shipText -like '*could not read the history of ''origin/main'' -- NOT merged*') 'and so does a failed git log, for the same reason'

# The two SINGLE-LINE refusals (git fetch, git log) can be checked as one contiguous literal fragment
# spanning the refusal text AND the valve, safely -- there is no line wrap between them to reflow. The
# other two are here-strings whose wrap point is a formatting detail, not a fact worth pinning down to
# an exact line break, so for those the existence checks above are as far as this suite goes.
Assert-True ($shipText -like "*'git fetch origin main' failed -- NOT merged (issue #1292). -SkipStaleCheck ships on the old certificate anyway.*") 'the failed-fetch refusal names -SkipStaleCheck in the same single-line message'
Assert-True ($shipText -like "*could not read the history of 'origin/main' -- NOT merged (issue #1292). -SkipStaleCheck ships on the old certificate anyway.*") 'the failed-log refusal names -SkipStaleCheck in the same single-line message'

# AND THE FAILED FETCH KEEPS GIT'S OWN DIAGNOSIS (issue #1334). The refusal above says the fetch failed;
# only git says WHY -- the auth error, the host, the reason. The flag that would drop it was added here on
# a credential argument #1330 had measured as false 23 minutes earlier (git anonymizes the URL itself via
# transport_anonymize_url), which is the fourth call site #1313 warned would copy that retired reasoning.
# The call is asserted WHOLE, as one literal fragment, so re-adding -DiscardStderr anywhere in it fails
# this suite -- an assert on the flag's absence would pass on a call that no longer exists.
Assert-True ($shipText -like "*Invoke-NativeCapture -FilePath 'git' -Arguments @('fetch', 'origin', 'main', '--quiet')*") 'step 3b''s fetch of main runs WITHOUT -DiscardStderr, so git''s own failure output survives'
Assert-True ($shipText -like '*$fetchMain.Output | Where-Object*') 'and the failure path prints that captured output before the refusal, rather than discarding it'
Assert-True ($shipText -like '*native-capture-lib.ps1*') 'the comment points at the seam holding the measurement, so the next reader meets it rather than the retired rule'

# THE git log THREE LINES BELOW KEEPS THE FLAG, on an independent reason: its output is PARSED into
# $newMainCommits, so a stray line becomes a fake SHA. That one is not the defect and must not be swept
# along with it.
Assert-True ($shipText -like "*-DiscardStderr -Arguments @('log', 'origin/main', '--first-parent'*") 'the PARSED git log keeps -DiscardStderr -- a different call with a different reason'

# The stale-certificate refusal itself names the commit count, the PR, and the remedy -- the facts a
# reader needs to act on it. Unchanged by the re-anchor, since Get-StaleCertificateVerdict did not move.
Assert-True ($shipText -like '*gained $($staleVerdict.Count) commit(s) after the run that certified PR*') 'the refusal states how many commits and which PR they voided the certificate for'
Assert-True ($shipText -like '*stale-CI certificate*') 'and leads with a recognisable, greppable name for the failure'
Assert-True ($shipText -like '*git merge origin/main*') 'the remedy tells the operator how to bring the branch forward'
Assert-True ($shipText -like '*-SkipStaleCheck ships on the old certificate anyway*') 'and the escape valve is documented right beside the refusal it bypasses'
Assert-True ($shipText -like '*exit 1*') 'a stale certificate is a hard refusal (an exit code), not a warning that lets the merge through'

if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
