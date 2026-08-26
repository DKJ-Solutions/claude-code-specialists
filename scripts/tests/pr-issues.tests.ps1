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

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
