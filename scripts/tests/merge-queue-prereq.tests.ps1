<#
.SYNOPSIS
    Regression tests for the two merge-queue prerequisites (issue #1325).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Reads the workflow and the script as text and
    runs a series of asserts. Exit code 0 if everything passes, 1 on a failure -- so usable as a CI gate.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/merge-queue-prereq.tests.ps1

    WHY THIS SUITE EXISTS. A GitHub merge queue is the only remedy for the staleness race that actually
    converges (#1292 measured the race; #1325 measured every non-queue repo-settings remedy and rejected
    them -- `strict_required_status_checks_policy` + `allow_auto_merge` + `allow_update_branch` were all
    turned on and reverted the same day, because GitHub performs NO server-side base-sync of a PR branch
    outside a queue). Enabling one is a repo-settings change and Dave's. What is NOT his, and what this
    suite guards, is the two things that must already be true in the tree before that switch is flipped.

    THE DECISION WAS SETTLED ON SEPTEMBER 3, 2026 AND THE ANSWER IS NO (#1355) -- AND THIS SUITE STAYS.
    A no priced against a 12.3%/~5min problem is not a never, and the reopen condition is written into
    Sylvester's lens beside the decision. Neither guard is dead code in the meantime: guard 2 is right
    with no queue anywhere -- "merged" had been an inference from an exit code, on the one script that
    writes to the trunk -- and guard 1 costs nothing while inert. Do not remove either as unused.

    BOTH FAIL SILENTLY AND BOTH FAIL BADLY, which is why they are pinned rather than commented:

      1. `.github/workflows/ci.yml` must carry the `merge_group` trigger. A required workflow without it
         never runs for a queue entry, so `lint-en-tests` never reports -- and GitHub's own warning is
         that the merge then fails. That is a TOTAL MERGE OUTAGE on the trunk, not a degradation. The
         trigger is inert until a queue exists, so nothing about the repo today would notice it being
         removed; the notice would arrive as the first merge after a queue is switched on.

      2. `scripts/release/ship-pr.ps1` must read the PR's state after `gh pr merge` rather than trusting
         its exit code. `gh pr merge --help`: "When targeting a branch that requires a merge queue ... If
         required checks have passed, the pull request will be added to the merge queue." ADDED, exit 0,
         not merged. Step 5 folds the entry onto the trunk on the strength of that exit code, so under a
         queue an ordinary ship would write a fold commit for a PR that has not landed -- the changelog
         entry on the trunk ahead of its own merge, with nothing in the run saying so.

    THE SECOND ONE IS ALSO RIGHT TODAY, with no queue anywhere: 'merged' had been an inference from an
    exit code, on the one script that writes to the trunk. That is why its assert does not wait for a
    queue to exist either.

    THE ASSERTS ARE ABOUT THE PROPERTY, NOT THE SPELLING, as far as text asserts allow: the trigger is
    matched as a top-level key of the `on:` block (not merely as the substring, which every comment on
    this page also contains), and the readback is matched by what it reads and by its refusal, not by the
    variable name it happens to use.

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

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ciPath = Join-Path $repoRoot '.github\workflows\ci.yml'
$shipPath = Join-Path $repoRoot 'scripts\release\ship-pr.ps1'
$shipMirror = Join-Path $repoRoot 'plugins\dkj-policy\scripts\release\ship-pr.ps1'

$ci = Get-Content -LiteralPath $ciPath -Raw
$ship = Get-Content -LiteralPath $shipPath -Raw

Write-Host "== prerequisite 1: ci.yml triggers on merge_group (#1325) ==" -ForegroundColor Cyan

# THE TRIGGER, matched as a key rather than as a word. Every paragraph of reasoning on that page names
# `merge_group` too, so a substring match would stay green with the trigger itself deleted -- which is
# exactly the silent state this assert exists to catch.
$onBlock = [regex]::Match($ci, '(?ms)^on:\r?\n(?<body>(?:[ \t]+\S[^\r\n]*\r?\n)+)')
Assert-True ($onBlock.Success) 'ci.yml still declares a top-level on: block'
Assert-True ($onBlock.Success -and $onBlock.Groups['body'].Value -match '(?m)^\s{2}merge_group:') `
    'ci.yml triggers on merge_group -- without it a required check never reports in a queue and merges fail outright'

# The two triggers that were there first must survive the addition: a queue does not replace either.
Assert-True ($onBlock.Success -and $onBlock.Groups['body'].Value -match '(?m)^\s{2}pull_request:') `
    'and the pull_request trigger is untouched -- the PR gate is what a queue entry is promoted from'
Assert-True ($onBlock.Success -and $onBlock.Groups['body'].Value -match '(?m)^\s{2}push:') `
    'and the push trigger is untouched -- the trunk tip still carries a check of its own'

# A queue entry must run the SUITES, not just lint: it is the projected merge being certified before it
# lands, so the #1300 fold-commit shortcut must not reach it. That shortcut is gated on the push event,
# which is what keeps merge_group out of it -- assert the gate rather than the absence of a mention.
$suiteStep = [regex]::Match($ci, '(?ms)- name: Test suites.*?shell: powershell')
Assert-True ($suiteStep.Success) 'the Test suites step is still in ci.yml'
Assert-True ($suiteStep.Success -and $suiteStep.Value -match "if:[^\r\n]*github\.event_name == 'push'") `
    'and its skip is gated on the push event, so a merge_group run still runs the suites in full'

# The reasoning has to travel with the trigger: an inert line with no cited issue is the first thing a
# later sweep removes as dead configuration.
Assert-True ($ci -like '*#1325*') 'ci.yml cites the issue that explains why an inert trigger is there at all'

Write-Host "== prerequisite 2: ship-pr reads the merge state before folding (#1325) ==" -ForegroundColor Cyan

# The readback itself. Matched on WHAT IT READS -- the PR's state field -- so renaming the variable or
# restructuring the retry keeps this green while deleting the read does not.
Assert-True ($ship -match "'pr',\s*'view'[^\r\n]*'state'") `
    'ship-pr reads the PR state from gh after the merge'
Assert-True ($ship -match "(?m)^\s*\}\s*elseif\s*\(\s*\`$mergedState -ne 'MERGED'\s*\)") `
    'and refuses when that state is positively read as something other than MERGED'

# THE ORDER IS THE WHOLE POINT. The read has to sit between the merge and the fold; a read placed after
# step 5 would pass a substring assert and prevent nothing.
$mergeIdx = $ship.IndexOf("'pr', 'merge'")
$stateIdx = [regex]::Match($ship, "'pr',\s*'view'[^\r\n]*'state'").Index
$foldIdx = $ship.IndexOf('--- Step 5:')
Assert-True ($mergeIdx -gt 0 -and $stateIdx -gt $mergeIdx) 'the state read comes after the gh pr merge call'
Assert-True ($foldIdx -gt 0 -and $stateIdx -lt $foldIdx) 'and before step 5, which is the step that folds onto the trunk'

# A FAILED READ IS NOT A FINDING, deliberately: turning a network blip into a refusal between the merge
# and the fold would manufacture the trapped-entry state (#1270) that the fold exists to prevent. This
# assert is the one that stops a later "tighten the gate" sweep from inverting it.
Assert-True ($ship -match 'not checked \(this is not a finding\)[^\r\n]*"\s*-ForegroundColor DarkGray') `
    'an unreadable state does NOT refuse -- only a state read as non-MERGED does'

Write-Host "== the plugin mirror carries the same script ==" -ForegroundColor Cyan

# ship-pr.ps1 is plugin payload: consumers get this guard by plugin update, and a repo-settings change
# never reaches them at all. The shared-scripts drift lint covers the pair in general; this assert is
# here so the merge-queue guard specifically cannot land in the root copy alone.
Assert-True (Test-Path -LiteralPath $shipMirror) 'the plugin mirror of ship-pr.ps1 still exists'
if (Test-Path -LiteralPath $shipMirror) {
    $mirror = Get-Content -LiteralPath $shipMirror -Raw
    Assert-True ($mirror -match "'pr',\s*'view'[^\r\n]*'state'") `
        'and it carries the merge-state readback too -- consumers get this by plugin update, not by settings'
}

if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
