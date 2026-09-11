<#
.SYNOPSIS
    Regression tests for the reach label: the tier model read on an ISSUE instead of on a changelog
    entry, portable to every repo running this workflow (issue #1870).

.DESCRIPTION
    Dependency-free: no Pester, only PowerShell. Exit 0 if everything passes, 1 on a failure.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/reach-label.tests.ps1

    WHAT THIS SUITE IS FOR. The axis moved out of dkj-policy-bwj on September 11, 2026 and became a
    dkj-policy rule, with 'minor' as the name and Get-ReachLabel as the seam for a repo that spells it
    otherwise. Four documents now have to agree about that, and none of them is executable -- so the
    failure they can produce is the silent one: a default stated as 'minor' in one page and 'tier-1' in
    the next, which a reader resolves by typing whichever they read last, and 'gh issue create' then
    refuses the whole filing over.

    Pure ASCII (repo convention for .ps1).
#>

$ErrorActionPreference = 'Stop'
$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$PolicyRoot = Join-Path $RepoRoot 'plugins\dkj-policy'

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

function Get-Text { param([string]$Rel) Get-Content -LiteralPath (Join-Path $PolicyRoot $Rel) -Raw }

# --- the axis is defined where the scale it projects is defined ----------------------------------
Write-Host "`n-- the portable definition --" -ForegroundColor Cyan

# It lives beside the tier model rather than in a consumer's lens, because it IS that model read one
# step earlier. A definition that drifted into a repo-local page would leave the thing consumers
# actually adopt -- the plugin -- silent about the one label it prescribes.
$releases = Get-Text 'RELEASES-portable.md'
Assert-True ($releases -match '###\s+The same scale on an issue') `
    'RELEASES-portable.md carries the reach-label section'
Assert-True ($releases -match 'Get-ReachLabel') `
    'RELEASES-portable.md names the Get-ReachLabel seam'
Assert-True ($releases -match 'defaulting to `minor`') `
    'RELEASES-portable.md states minor as the default'

# The two halves of the projection, both asserted, because stating only the positive one is what makes
# a filter match everything: tier 0 carrying NO label is the half that gives the worklist its value.
Assert-True ($releases -match '(?s)tier 1 or 2 \| `minor`') `
    'the table says tier 1 or 2 carries the label'
Assert-True ($releases -match '(?s)\| tier 0 \| \*\(none\)\*') `
    'the table says tier 0 carries none'

# --- the exception is declared where the opposite rule is stated ---------------------------------
Write-Host "`n-- the labels-are-your-tracker exception --" -ForegroundColor Cyan

# CONTRIBUTING-portable.md tells a consumer that nothing in this plugin reads their labels. That
# sentence is still true of every label but this one, and a prescription sitting only in RELEASES
# would contradict it for a reader who never opens that page.
$contributing = Get-Text 'CONTRIBUTING-portable.md'
Assert-True ($contributing -match 'nothing in\s*\r?\n?this plugin reads either') `
    'CONTRIBUTING-portable.md still states the general rule'
Assert-True ($contributing -match 'the reach label') `
    'CONTRIBUTING-portable.md names the reach label as the exception'
Assert-True ($contributing -match 'RELEASES-portable\.md#the-same-scale-on-an-issue') `
    'the exception links to the definition rather than restating it'

# --- adopt places it, and says which wording belongs to which audience ---------------------------
Write-Host "`n-- adopt-dkj-policy part 4 --" -ForegroundColor Cyan

# A label is a row in a tracker's settings, so nothing in this plugin can write it. Part 4 is the
# step that hands a person the command -- and the audience wordings matter: tier 1 and tier 2 are two
# KINDS of reader, so a repo copying the other one's description names an audience it does not have.
$adopt = Get-Text 'skills\adopt-dkj-policy\SKILL.md'
Assert-True ($adopt -match '##\s+Part 4') `
    'adopt-dkj-policy carries Part 4'
Assert-True ($adopt -match 'gh label create') `
    'Part 4 gives the create command'
Assert-True ($adopt -match 'management and the commissioner notice it') `
    'Part 4 carries the tier-1 wording'
Assert-True ($adopt -match 'subscribers of this service notice it') `
    'Part 4 carries the tier-2 wording'
Assert-True ($adopt -match 'four independent parts') `
    'the frontmatter counts four parts, not three'

# --- the seam is in the contract, optional, and defaulted to minor -------------------------------
Write-Host "`n-- the Get-ReachLabel contract record --" -ForegroundColor Cyan

# Read through the registry rather than by grepping the file: what a consumer's check-script-contract
# reports is the RECORD, and a record whose Default says one thing while the prose says another is
# exactly the drift this suite exists to catch.
. (Join-Path $RepoRoot 'scripts\lib\script-contract-lib.ps1')
$rec = @(Get-ScriptContract | Where-Object { $_.Function -eq 'Get-ReachLabel' })
Assert-True ($rec.Count -eq 1) 'the contract declares Get-ReachLabel exactly once'
if ($rec.Count -eq 1) {
    $r = $rec[0]
    Assert-True ([bool]$r.Optional) 'it is Optional, so an unanswered consumer is not an [ERROR]'
    Assert-True ($r.Default -match "'minor'") 'its Default names minor'
    Assert-True ($r.Adopt -eq 'copy') "its Adopt is 'copy' -- the value states the way of working, not what the repo is"
    Assert-True ($r.Lib -eq 'scripts\repo-config.ps1') 'it is answered in repo-config.ps1'
}

# --- no portable page still calls the DEFAULT tier-1 ---------------------------------------------
Write-Host "`n-- no stale default --" -ForegroundColor Cyan

# The name 'tier-1' is not banned: the axis is still explained in tier numbers, the rename is recorded
# as history, and a store that has not renamed its label answers the seam with exactly that string.
# What must not survive is the claim that tier-1 is what an unanswered repo GETS, which is the sentence
# a reader turns into a typed literal.
$defaultClaim = 'default(?:ing to)?\s+`?tier-1'
foreach ($rel in @('RELEASES-portable.md', 'CONTRIBUTING-portable.md', 'skills\adopt-dkj-policy\SKILL.md',
                   'dkj-policy-bwj\WORKFLOW-portable.md', 'dkj-policy-bwj\README.md',
                   'dkj-policy-bwj\skills\report-issue\SKILL.md')) {
    Assert-True (-not [regex]::IsMatch((Get-Text $rel), $defaultClaim)) `
        "$rel no longer states tier-1 as the default"
}

# --- done ---------------------------------------------------------------------------------------
Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
