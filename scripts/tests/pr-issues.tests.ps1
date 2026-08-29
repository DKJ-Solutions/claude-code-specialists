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
# August 27-29, 2026, reasons of 51 to 55 characters against 203 of room.
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

# One Match, not Matches, and the needle occurs exactly once in the file today -- checked. A SECOND
# jq slice added elsewhere would go unread here rather than caught, which is the known edge: the
# subject is this reason's cap, and a new one would want its own assert either way.
$wfReason = [regex]::Match($wfText, '\(\.\[0\] // ""\) \| \.\[0:(\d+)\]')
Assert-True $wfReason.Success 'the workflow still caps the reason it appends, and this is where'
Assert-Equal 300 ([int]$wfReason.Groups[1].Value) 'at the same 300 -- raising it widens an overlap that was measured, not overlooked'

# THE HEADLINE IS THE THIRD NUMBER, and the one most likely to move: it is prose, and #974, #1055
# and #1112 each rewrote it. Its length is what turns the other two into 203, so it is read from
# the file rather than trusted. 296 today; the assert is the arithmetic, not the constant, so a
# rewrite that keeps the sum honest passes and one that eats the reason's room does not.
$headlines = @([regex]::Matches($wfText, "(?m)^\s*headline='([^']*)'") | ForEach-Object { $_.Groups[1].Value })
Assert-True ($headlines.Count -ge 3) 'the literal headlines are readable -- the interpolated *) branch has no static length and needs none'
$longestMeasuredReason = 55
foreach ($h in $headlines) {
    $room = $relayCap - $h.Length - 1
    Assert-True ($room -ge $longestMeasuredReason) "the $($h.Length)-character headline leaves the console $room characters of reason -- more than the 55 ever measured"
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
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
