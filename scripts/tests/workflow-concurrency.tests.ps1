<#
.SYNOPSIS
    Regression tests for the concurrency blocks in .github/workflows/*.yml.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Reads the workflow files as text and runs a
    series of asserts. Exit code 0 if everything passes, 1 on a failure -- so usable as a CI gate.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/workflow-concurrency.tests.ps1

    WHY THIS SUITE EXISTS, AND WHY A COMMENT WAS NOT ENOUGH. ci.yml carried a concurrency block whose
    comment named the hazard (the fold commit displacing the merge commit's run), named the stake (a
    cancelled check is not a passing one) and chose a guard -- a conditional cancel-in-progress -- that
    does not cover the path the cancellation actually takes. `cancel-in-progress` governs the
    IN-PROGRESS run; a concurrency group ALSO drops a PENDING run when a third arrival queues into it,
    and that path consults the field not at all. Measured September 3, 2026 (issue #1294) over the 28
    most recent 'merge:' commits on the trunk's first-parent line: 14 success, 14 cancelled, the
    cancelled ones with ZERO jobs allocated. Half the trunk had never been gated.

    So this is the exact class Sylvester's manual says to assert rather than comment: nothing errors,
    no check goes red, and the most convincing thing in the file is the reasoning that is wrong. The
    property is only observable by reading the run history afterwards, which no gate does -- so the
    grouping KEY is what gets pinned here.

    THE ASSERTS ARE ABOUT THE KEY, NOT ABOUT THE VALUE. A future reader repairing this class will reach
    for cancel-in-progress first, because that is the field named in every article about it. What has to
    survive is that a push to `main` shares its group with NO other push. Asserted in both directions:
    the push half must be keyed on the commit, and the PR half must NOT be -- keying a PR per commit
    would silently reopen the ~7m40s reruns PR #933 measured, which is the cost the block was written
    for in the first place.

    unfolded-entry.yml is asserted for the OPPOSITE arrangement, deliberately. There a shared trunk
    group and cancel-in-progress: true are correct: the check is required by nothing, and superseding
    the run is how the ship window (main genuinely carrying an unfolded entry for ~6s) stops reading as
    a stale red. An assert on each keeps a later sweep from "harmonising" the two.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

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

$wfDir = Join-Path $PSScriptRoot '..\..\.github\workflows'

# Read as one string per file. These blocks are a handful of lines and the asserts are substring
# questions, so a YAML parser would add a dependency to answer nothing extra.
$ci = Get-Content -LiteralPath (Join-Path $wfDir 'ci.yml') -Raw
$ue = Get-Content -LiteralPath (Join-Path $wfDir 'unfolded-entry.yml') -Raw

Write-Host "== ci.yml: a push to main is its own concurrency group (#1294) ==" -ForegroundColor Cyan

# The load-bearing property. github.sha is the commit under test, so every push to `main` lands in a
# group of one and nothing can displace it -- pending or in progress.
Assert-True ($ci -match 'concurrency:') 'ci.yml still declares a concurrency block at all'
Assert-True ($ci -match 'group:[^\r\n]*github\.sha') 'the group key uses github.sha, so a push to main shares its group with no other push'
Assert-True ($ci -match "group:[^\r\n]*github\.event_name == 'pull_request'") 'the key branches on the event, which is what keeps the two halves apart'
Assert-True ($ci -match 'group:[^\r\n]*github\.ref') 'and the PR half is still keyed on the ref, not on the commit -- otherwise PR #933 reruns come back'

# The negative direction. Before #1294 this WAS the whole guard, and it was green while half the trunk
# went ungated -- so an assert that only checked this field would have proved nothing.
Assert-True ($ci -match "cancel-in-progress:[^\r\n]*github\.event_name == 'pull_request'") 'cancel-in-progress stays conditional -- but it is no longer what protects the push half'
Assert-True ($ci -notmatch 'cancel-in-progress:\s*true\s*$') 'and it is not a plain true, which would cancel a running trunk gate'

# The reasoning has to travel with the block, because the previous comment is what made the wrong guard
# look considered. Naming the issue is what lets a reader find the 14/14 measurement.
Assert-True ($ci -like '*#1294*') 'the block cites the issue whose measurement explains the key'
Assert-True ($ci -like '*PENDING*') 'and states the mechanism (a pending run is dropped), which is the part cancel-in-progress does not cover'

Write-Host "== unfolded-entry.yml: the OPPOSITE arrangement, and correct there ==" -ForegroundColor Cyan

Assert-True ($ue -match 'group:[^\r\n]*github\.ref') 'its group is shared across the trunk, deliberately'
Assert-True ($ue -notmatch 'group:[^\r\n]*github\.sha') 'and is NOT keyed per commit -- superseding the ship window is the wanted behaviour here'
Assert-True ($ue -match 'cancel-in-progress:\s*true') 'cancel-in-progress: true, so a ~6s ship window does not leave a stale red'
Assert-True ($ue -like '*ci.yml*') 'and it says why it is the opposite of ci.yml, so neither gets harmonised into the other'

if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
