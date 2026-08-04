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

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
