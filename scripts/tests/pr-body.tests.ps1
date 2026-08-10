<#
.SYNOPSIS
    Regression tests for scripts/lib/pr-body-lib.ps1 (the PR-body description refresh).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Exit code 0 if everything passes, 1 on a
    failure -- so usable as a CI gate.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/pr-body.tests.ps1

    What this suite is for. open-pr.ps1 -RefreshBody rewrites the description of an ALREADY OPEN PR from
    the changelog entry. That is a write against a live PR body, so the failure that matters is not a
    crash but a WRONG REWRITE: half the old text left behind, an unrelated section swallowed, or -- the
    one measured on August 4, 2026 while doing this by hand -- an empty body published because a string
    operation silently produced $null. Every assert below exists to make one of those impossible.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\pr-body-lib.ps1')

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

Write-Host "Get-EntryDescription" -ForegroundColor Cyan

$entry = @'
### Some title - Feat - 2026-08-04

**The first paragraph.** With detail.

**The second paragraph.**
'@
Assert-Equal "**The first paragraph.** With detail.`n`n**The second paragraph.**" (Get-EntryDescription -EntryText $entry) 'everything after the heading, trimmed'

# Only the FIRST '###' is the heading. An entry whose prose carries further headings must not be cut
# short at one of them -- that returns something plausible instead of failing, the worst shape.
$deep = @'
### Title - Docs - 2026-08-04

Opening line.

### A heading inside the prose

Still part of the description.
'@
Assert-True ((Get-EntryDescription -EntryText $deep) -match 'Still part of the description') 'a later ### stays inside the description'
Assert-True ((Get-EntryDescription -EntryText $deep) -match 'A heading inside the prose') 'and the later heading itself is kept'

Assert-Equal '' (Get-EntryDescription -EntryText '') 'empty input -> empty string'
Assert-Equal '' (Get-EntryDescription -EntryText "No heading here at all.`nJust prose.") 'no heading -> empty string, so the caller can keep the placeholder'
Assert-Equal '' (Get-EntryDescription -EntryText '### Heading with nothing after it') 'a heading with no body -> empty string'
# CRLF is what a file read on Windows hands over; splitting on "`n" alone would leave a trailing "`r".
Assert-Equal 'Body line.' (Get-EntryDescription -EntryText "### T - Feat - 2026-08-04`r`n`r`nBody line.`r`n") 'CRLF input does not leave carriage returns behind'

Write-Host ""
Write-Host "Update-PrBodySection" -ForegroundColor Cyan

$body = @'
## What does this change do?
The old description.

## Type of change
- [x] `docs/` something

## Checklist
- [x] Entry created
'@

$changed = $false
$out = Update-PrBodySection -Body $body -Heading '## What does this change do?' -Content 'The NEW description.' -Changed ([ref]$changed)
Assert-True $changed                                  'a real change is reported as changed'
Assert-True ($out -match 'The NEW description\.')     'the new content is in'
Assert-True ($out -notmatch 'The old description')    'the old content is gone'
Assert-True ($out -match '(?m)^- \[x\] `docs/` something') 'the Type of change section survives untouched'
Assert-True ($out -match '(?m)^- \[x\] Entry created')     'the Checklist section survives untouched'
Assert-True ($out -match '(?ms)NEW description\.\s*\n## Type of change') 'exactly one blank line before the next section'

# The boundary is same-level-or-higher, NOT the next heading of any kind. A description containing its
# own deeper heading must be replaced whole; stopping at the deeper one would strand half the old text
# below the new -- a body that reads as though it says two different things.
$deepBody = @'
## What does this change do?
Old opening.

### An old sub-heading
Old detail that must also go.

## Type of change
- [x] `feat/`
'@
$changed = $false
$out2 = Update-PrBodySection -Body $deepBody -Heading '## What does this change do?' -Content 'Replacement.' -Changed ([ref]$changed)
Assert-True ($out2 -notmatch 'An old sub-heading')        'a deeper heading inside the section is replaced too'
Assert-True ($out2 -notmatch 'Old detail that must also go') 'and so is the text under it'
Assert-True ($out2 -match '(?m)^- \[x\] `feat/`')         'while the next same-level section is kept'

# A '##' inside a fence is not a boundary. Not hypothetical: an entry documenting this very feature
# writes the heading it is explaining.
$fenced = @'
## What does this change do?
Old.

## Type of change
- [x] `feat/`
'@
$withFence = @"
Replacement that explains itself:

``````markdown
## Type of change
``````

Done.
"@
$changed = $false
$out3 = Update-PrBodySection -Body $fenced -Heading '## What does this change do?' -Content $withFence -Changed ([ref]$changed)
Assert-True ($out3 -match '(?m)^- \[x\] `feat/`')  'the real Type of change section is still there after a fenced copy of its heading'
Assert-True ($out3 -match 'Done\.')               'the content after the fence is kept'

# A body that already says exactly this must not be rewritten -- the caller skips the API call, so a
# rerun produces no PR activity at all.
$same = Update-PrBodySection -Body $body -Heading '## What does this change do?' -Content 'The old description.' -Changed ([ref]$changed)
Assert-Equal $body $same 'identical content leaves the body byte-identical'
Assert-True (-not $changed) 'and reports no change, so no pr edit is sent'

# A heading that is not present is not an error: the body comes back untouched and unchanged.
$changed = $false
$absent = Update-PrBodySection -Body $body -Heading '## Not in this template' -Content 'x' -Changed ([ref]$changed)
Assert-Equal $body $absent 'an absent heading leaves the body alone'
Assert-True (-not $changed) 'and reports no change'

# THE MEASURED FAILURE, asserted directly: on August 4, 2026 a hand-written refresh published an EMPTY
# body because a failed string operation passed $null on. Whatever else these functions do, they must
# never turn a non-empty body into nothing.
$changed = $false
Assert-Equal $body (Update-PrBodySection -Body $body -Heading '## What does this change do?' -Content '' -Changed ([ref]$changed)) 'empty replacement content leaves the body untouched rather than emptying the section'
Assert-True (-not $changed) 'and is reported as no change, so nothing is sent'
Assert-Equal '' (Update-PrBodySection -Body '' -Heading '## Any' -Content 'x') 'an empty body in stays empty out (nothing to update)'

# The last section in the body has no following heading, so it must not gain a trailing blank line.
$tail = "## Intro`nkeep`n`n## Last section`nold tail"
$changed = $false
$outTail = Update-PrBodySection -Body $tail -Heading '## Last section' -Content 'new tail' -Changed ([ref]$changed)
Assert-Equal "## Intro`nkeep`n`n## Last section`nnew tail" $outTail 'replacing the final section adds no trailing blank line'

# CRLF bodies keep their line endings: gh returns whatever the PR has, and rewriting a CRLF body with LF
# would show up as a whole-body diff on GitHub.
# NB the section text below carries no backtick on purpose: inside a double-quoted PowerShell string a
# backtick starts an escape, and '`f' is a FORM FEED -- which is a parse error here, not a literal.
$crlf = "## What does this change do?`r`nOld.`r`n`r`n## Type of change`r`n- [x] feat branch"
$outCrlf = Update-PrBodySection -Body $crlf -Heading '## What does this change do?' -Content 'New.'
Assert-True ($outCrlf.Contains("`r`n")) 'a CRLF body stays CRLF'
Assert-True (-not ($outCrlf -match "[^`r]`n")) 'and gains no bare LF line endings'

# --- Get-PrTitle: the PR title is composed, not typed (#506 + #505) -------------------------------
# The whole point of the change is that these two facts cannot drift apart, so the asserts are about
# COMPOSITION and about the shapes that would produce a nameless or malformed PR.
Write-Host ""
Write-Host "Get-PrTitle -- the type from the branch, the words from the entry" -ForegroundColor Cyan

Assert-Equal 'fix: the release runs the suites' (Get-PrTitle -Prefix 'fix' -TitleWords 'the release runs the suites') 'the prefix and the words are joined with one colon and one space'
Assert-Equal 'feat: a thing' (Get-PrTitle -Prefix 'feat' -TitleWords "  a thing  ") 'surrounding whitespace is trimmed off both halves'

# A title reaches `gh pr create --title` as ONE argument; a newline in it is not a formatting nicety.
Assert-Equal 'docs: first line only' (Get-PrTitle -Prefix 'docs' -TitleWords "first line only`nand a second paragraph") 'a multi-line section yields the first non-empty line'
Assert-Equal 'docs: after the blanks' (Get-PrTitle -Prefix 'docs' -TitleWords "`n`n  after the blanks`nmore") 'leading blank lines are skipped rather than winning'
Assert-Equal 'fix: two spaces collapse' (Get-PrTitle -Prefix 'fix' -TitleWords "two   spaces collapse") 'inner whitespace is collapsed to single spaces'

# '' is how open-pr says "this branch prefix is not in the table". Inventing a type there would state
# something no table backs -- the PR is labelled 'question' for exactly that reason.
Assert-Equal 'words alone' (Get-PrTitle -Prefix '' -TitleWords 'words alone') 'an empty prefix yields the words without a type'

# EMPTY IN, EMPTY OUT -- and open-pr turns that into a refusal naming the entry, rather than handing
# `gh` a bare '--title ""' to complain about a flag.
Assert-Equal '' (Get-PrTitle -Prefix 'fix' -TitleWords '') 'no words means no title, not a bare prefix'
Assert-Equal '' (Get-PrTitle -Prefix 'fix' -TitleWords "   `n  `n") 'a whitespace-only section is no title either'

# --- Get-PrDescription: the PR body is the answer onwards, not the whole dossier --------------------
#
# The three sections it drops are answered by the PAGE around the body -- Branch title IS the PR title,
# Branch ID is a creation timestamp, Branch type is the label -- and the one it drops at the end is
# filled by the FOLD, so it is empty in every PR body by construction. Kept: the answer and Significance,
# because how far a change reaches and what it is worth is what a reviewer is deciding about.
Write-Host "Get-PrDescription -- the PR body starts at the answer" -ForegroundColor Cyan
$dossier = @'
## `fix/x` changelog

### Branch title

A short title

### Branch ID

20260809-113542

### Branch type

fix

### What does the change on this branch bring to main?

The real answer.

### Significance

#### Tier 0

Because of this.

**Score:** 3

### Pull Request

'@
$prDesc = Get-PrDescription -EntryText $dossier
Assert-True ($prDesc -match '(?m)^The real answer\.$')      'the answer is carried'
Assert-True ($prDesc -match '(?m)^## Significance$')        'Significance is kept -- it is what a reviewer decides about'
Assert-True ($prDesc -match '(?m)^\*\*Score:\*\* 3$')       'and its scores come with it'
Assert-True ($prDesc -notmatch 'A short title')             'the Branch title is dropped -- it IS the PR title, shown above the body'
Assert-True ($prDesc -notmatch '20260809-113542')           'the Branch ID is dropped -- a timestamp a reviewer cannot act on'
Assert-True ($prDesc -notmatch '(?m)^### Branch type$')     'the Branch type section is dropped -- it is the PR label'
Assert-True ($prDesc -notmatch '(?m)^### Pull Request$')    'the Pull Request section is dropped -- the fold fills it, so it is always empty here'
Assert-True ($prDesc -notmatch 'What does the change on this branch bring to main') 'the heading itself is dropped -- the template carries it, so it cannot appear twice'

# PROMOTED ONE LEVEL (Dave, August 9, 2026). The entry's sections are H3 and its tiers H4 because the
# entry is an H2 inside CHANGELOG.md; a PR body is a document of its own, whose title GitHub prints
# above it. Carried across unchanged, a body started at H2 with tiers at H4 -- the shape of a fragment.
Assert-True ($prDesc -match '(?m)^## Significance$')  'Significance is promoted from H3 to H2'
Assert-True ($prDesc -match '(?m)^### Tier 0$')       'and the tier from H4 to H3'
Assert-True ($prDesc -notmatch '(?m)^### Significance$') 'the original H3 level is gone, not merely duplicated'
Assert-True ($prDesc -notmatch '(?m)^#### ')          'nothing in the body is left at H4'

# THE FENCE CASE, which is not hypothetical: the entry documenting this change quotes these headings
# inside a fence. Cutting at a fenced heading would return plausible half-output rather than failing.
$fenced = @'
## `fix/y` changelog

### What does the change on this branch bring to main?

Before the fence.

```text
### Pull Request
### Significance
```

After the fence.

### Pull Request

'@
$fencedDesc = Get-PrDescription -EntryText $fenced
Assert-True ($fencedDesc -match '(?m)^After the fence\.$') 'a fenced heading does not end the description'
Assert-True ($fencedDesc -match '(?m)^### Pull Request$')  'and the fenced quote itself survives inside the body'
# The promotion must not reach inside a fence either: a fenced heading is SAMPLE TEXT, and an entry
# explaining this format would have its own example silently rewritten to say something else.
Assert-True ($fencedDesc -match '(?m)^### Significance$')  'a heading inside a fence keeps its level -- it is a quote, not a section'

# BACK-COMPAT: a pre-dossier entry has no such section, and '' is how this says so -- open-pr then falls
# back to Get-EntryDescription, which is the behaviour every consumer with a branch in flight has today.
$preDossier = "### Old entry - Feat - 2026-07-01`n`nJust a paragraph.`n"
Assert-Equal '' (Get-PrDescription -EntryText $preDossier) 'a pre-dossier entry yields "" so the caller can fall back'
Assert-True ((Get-EntryDescription -EntryText $preDossier) -match 'Just a paragraph') 'and the fallback still reads it whole'
Assert-Equal '' (Get-PrDescription -EntryText '') 'empty in, empty out -- no throw'

# The retired heading is read too, for the standing reason: entries carrying it exist in every consumer.
$retired = "## ``fix/z`` changelog`n`n### What does this change do?`n`nOld-style answer.`n"
Assert-True ((Get-PrDescription -EntryText $retired) -match 'Old-style answer') 'the retired section name is still recognised'

# --- The template and open-pr must agree on the description placeholder (#538) ----------------------
#
# THE ONE COUPLING IN THIS MECHANISM THAT FAILS SILENTLY. open-pr fills the PR body by replacing a
# placeholder LINE from .github/pull_request_template.md with the changelog entry, matched by exact
# string equality against a list inside open-pr.ps1. If someone edits the template's comment -- a
# typo fix, a reworded hint, a stray trailing space -- the match stops firing and the PR is opened
# with the placeholder still in it and no description at all. Nothing errors: the template is valid
# markdown, the script exits 0, and the loss is visible only to whoever reads the published body.
#
# Measured need: the template was rewritten on 2026-08-09 (#538) down to a single section, which is
# exactly the kind of edit that breaks this without anyone looking. Asserted from BOTH files rather
# than from a constant here, so this suite cannot agree with itself while the repo disagrees.
Write-Host "template <-> open-pr placeholder agreement" -ForegroundColor Cyan
$repoRootForTemplate = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$templateFile = Join-Path $repoRootForTemplate '.github\pull_request_template.md'
$openPrFile   = Join-Path $repoRootForTemplate 'scripts\release\open-pr.ps1'

Assert-True (Test-Path -LiteralPath $templateFile) 'the PR template exists where open-pr looks for it'
Assert-True (Test-Path -LiteralPath $openPrFile)   'open-pr.ps1 exists where this suite looks for it'

$templateLinesForTest = @(Get-Content -LiteralPath $templateFile -Encoding UTF8)
$openPrText           = [System.IO.File]::ReadAllText($openPrFile, [System.Text.Encoding]::UTF8)

# A placeholder is an HTML comment on its own line -- the shape open-pr replaces wholesale.
$placeholderLines = @($templateLinesForTest | Where-Object { $_.Trim() -match '^<!--.*-->$' })
Assert-True ($placeholderLines.Count -ge 1) 'the template carries at least one comment line to substitute'

# The load-bearing assert: at least one of them is VERBATIM in the recognised list. This was a substring
# search over open-pr.ps1's own text until August 10, 2026, because the three literals lived inline in
# that script and there was nothing else to ask. Since #573 moved them into this lib the assert can call
# the list instead of grepping for it -- the same test, now performing the same whole-line comparison
# open-pr performs rather than an approximation of it.
$matched = @($placeholderLines | Where-Object { @(Get-PrDescriptionPlaceholderDefaults) -contains $_.Trim() })
Assert-True ($matched.Count -ge 1) 'open-pr recognises the template placeholder verbatim -- otherwise every PR body loses its description, silently'

# And the description heading open-pr reads (the template's first heading, AT ANY LEVEL) must actually
# be there, since -RefreshBody has nothing to target without it. The pattern is level-agnostic on
# purpose: it read '^##' until this repo's template was promoted to H1, at which point open-pr found
# nothing and would have degraded to "the description was left as it is" on every run -- a silent loss
# of the whole feature, worded as a decision. This assert is what would have caught that.
$firstHeading = @($templateLinesForTest | Where-Object { $_ -match '^#{1,6}\s+\S' }) | Select-Object -First 1
Assert-True ([bool]$firstHeading) 'the template has a heading for the description to live under'
Assert-True ($openPrText -match "Where-Object \{ \`$_ -match '\^#\{1,6\}\\s\+\\S' \}") 'and open-pr looks for it at any level, not just H2'

# THE FALLBACK THAT KEEPS OLDER PRs REFRESHABLE. -RefreshBody targets whatever heading the template
# names today; a PR opened before a rename carries the previous one in its published body, and
# Update-PrBodySection returns the body untouched when it cannot find a heading -- so without a
# fallback such a PR reports "already matches the entry" while matching nothing. Pinned here because
# the strings are the whole mechanism: they are not derivable from anything, only remembered.
Assert-True ($openPrText.Contains('## What does this change do?')) 'open-pr still recognises the pre-#538 description heading, so a PR opened under it stays refreshable'
Assert-True ($openPrText.Contains('## Changelog entry')) 'and the one-day-old heading between them, for PRs opened on August 9, 2026'
Assert-True ($openPrText.Contains('## What does the change on this branch bring to main?')) 'and the H2 form of the current wording, which was live for a single day'
foreach ($legacy in @('## What does the change on this branch bring to main?', '## Changelog entry', '## What does this change do?', '## Wat doet deze wijziging?')) {
    $legacyBody = "$legacy`nold text`n`n## Resolved issues`nCloses #1"
    $didChange = $false
    $out = Update-PrBodySection -Body $legacyBody -Heading $legacy -Content 'new text' -Changed ([ref]$didChange)
    Assert-True $didChange "a body under '$legacy' is rewritable"
    Assert-True ($out -match '(?m)^new text$') "and the new description lands under '$legacy'"
    Assert-True ($out -match '(?m)^Closes #1$') "while the resolved-issues block below '$legacy' is untouched"
}

# ---------------------------------------------------------------------------------------------------
Write-Host "The placeholder list and the reference template cannot disagree (#573)" -ForegroundColor Cyan
#      The whole reason those two moved into this lib: while the strings lived inline in open-pr.ps1,
#      nothing else could read them, so the reference template the plugin ships could not be held against
#      the list that has to recognise it. These asserts are that guarantee, stated rather than assumed.
$known = @(Get-PrDescriptionPlaceholderDefaults)
Assert-True ($known.Count -ge 3) 'the recognised placeholder list still carries the legacy strings, not just the current one'
Assert-True ($known -contains '<!-- Korte beschrijving van wat er verandert en waarom. -->') `
    'the Dutch legacy placeholder is still recognised -- consumer templates carry it right now'
Assert-True ($known -contains '<!-- Short description of what changes and why. -->') `
    'the English legacy placeholder is still recognised'

$canonical = Get-PrTemplateCanonicalPlaceholder
Assert-True ($known -contains $canonical) `
    'the placeholder that gets WRITTEN is one of the ones that gets RECOGNISED'

$reference = @(Get-PrTemplateReference)
Assert-True (@($reference | Where-Object { $known -contains $_ }).Count -eq 1) `
    'the reference template carries exactly one recognised placeholder line -- the defect #573 reported was a template carrying none'
Assert-True (@($reference | Where-Object { $_ -match '^#{1,6}\s+\S' }).Count -ge 1) `
    'the reference template carries a heading, which is what -RefreshBody replaces the description under'
Assert-True ($reference[0] -match '^#{1,6}\s+\S') `
    'and that heading is the FIRST line, because open-pr takes the first heading it finds'

# The shipped file on disk, not just the function: a reference nobody can copy is not a reference. The
# lint gate holds these byte for byte; this asserts the file exists at the path the docs send people to.
$refOnDisk = Join-Path $PSScriptRoot '..\..\plugins\workflows\workflow-davekjohn\templates\pull_request_template.md'
Assert-True (Test-Path -LiteralPath $refOnDisk) `
    'the reference template is actually shipped at the path the skill and CONTRIBUTING-portable name'
if (Test-Path -LiteralPath $refOnDisk) {
    $refText = ([System.IO.File]::ReadAllText($refOnDisk, [System.Text.Encoding]::UTF8)) -replace "`r`n", "`n"
    Assert-True ($refText.TrimEnd() -eq (($reference -join "`n").TrimEnd())) `
        'and its contents are what Get-PrTemplateReference says they are'
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
