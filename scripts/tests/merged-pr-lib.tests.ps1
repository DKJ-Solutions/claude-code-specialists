<#
.SYNOPSIS
    Regression tests for scripts/lib/merged-pr-lib.ps1 -- the merged-PR proof both team-shopify's
    sync-main.ps1 and the workflow plugin's prune-merged.ps1 call (inbound #1190 and #1191, promoted to
    one source by issue #1194).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/merged-pr-lib.tests.ps1

    WHY THIS SUITE EXISTS AS A SUITE. Neither caller's own suite can drive this: both fixtures use a
    local bare repo as their origin, so a real 'gh pr list' has no GitHub repository to answer for and
    the merged-PR arm is unreachable from either. sync-main.tests.ps1 therefore asserts the WIRING
    statically and prune-merged.tests.ps1 stubs gh; the DECISION is pure, so it is exercised here
    directly, once, for both.

    WHAT THE CASES PROTECT is a false answer arriving through the guard's own output. Branch names get
    recycled -- sync branch names are date-stamped, and deleteBranchOnMerge frees any name the moment its
    PR lands -- so matching on the bare name lets a merged branch vouch for the brand-new, unmerged one
    standing in its place. Measured in a consumer on September 1, 2026: 'sync/live-2026-09-01' merged as
    PR #141 and deleted, re-created the same day with open PR #159. sync-main reported '1 found on
    origin, all merged' and stacked a branch on the pile the guard exists to prevent; prune-merged
    printed 'merged PR' and force-deleted the standing one. Same miss, opposite losses.

    THE COMPARER HAS ITS OWN CASES, AND THEY ARE WHY THIS FILE IS SHARED. When the mechanism lived twice,
    one copy keyed its map with [System.StringComparer]::Ordinal and said why, and the other used a bare
    '@{}' -- whose comparer is case-insensitive -- so the two disagreed about the one question the map
    exists to answer, on the day both were written (issue #1194). A guard that costs nothing today is
    exactly the guard a second copy leaves out, so it is pinned here rather than trusted to a comment.

    BOTH TRANSPORTS ARE COVERED, because that is the seam the split runs along: the callers keep their
    own gh transport and share everything after it, so a rule enforced for the TSV rows and not for the
    object rows would be the divergence back in a new shape.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $RepoRoot 'scripts\lib\merged-pr-lib.ps1')

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message" -ForegroundColor Red }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}

Write-Host ''
Write-Host '== merged-pr-lib.tests ==' -ForegroundColor Cyan

$tipMerged   = ('a' * 39) + '1'
$tipStanding = ('b' * 39) + '2'
$tipOther    = ('c' * 39) + '3'
$reused      = 'sync/live-2026-09-01'

# --- the TSV transport (sync-main.ps1's) ----------------------------------------------------------
Write-Host ''
Write-Host 'Get-MergedPrTipsFromTsv -- the tab-separated rows, as a lookup' -ForegroundColor Cyan

$tips = Get-MergedPrTipsFromTsv -Lines @(
    "$reused`t$tipMerged",
    "sync/live-2026-08-30`t$tipOther",
    '',
    $null,
    'Merging pull request #141',
    "sync/live-2026-08-29`t",
    "sync/live-2026-08-28`tnot-a-sha"
)
Assert-Equal 2 $tips.Count 'tsv: only the rows shaped "<name> TAB <sha>" are read'
Assert-True ($tips.ContainsKey($reused)) 'tsv: and the merged branch is one of them'
Assert-True (-not $tips.ContainsKey('sync/live-2026-08-29')) 'tsv: a row whose headRefOid was null is dropped rather than stored as a tipless match'
Assert-True (-not $tips.ContainsKey('sync/live-2026-08-28')) 'tsv: a second field that is not an object name is not a tip'
Assert-Equal 0 (Get-MergedPrTipsFromTsv -Lines @()).Count 'tsv: no merged PRs is an empty lookup rather than a throw'
Assert-Equal 0 (Get-MergedPrTipsFromTsv).Count 'tsv: and so is no argument at all'

# --- the object transport (prune-merged.ps1's) ----------------------------------------------------
Write-Host ''
Write-Host 'Get-MergedPrTips -- the same lookup from gh''s JSON rows' -ForegroundColor Cyan

# THE ROWS ARE SHAPED AS prune-merged.ps1 SHAPES THEM, from ConvertFrom-Json's headRefName/headRefOid.
# The $null-oid and the not-a-sha rows are the JSON equivalents of the two dropped TSV rows above: gh
# writes headRefOid as JSON null for a PR whose head ref is gone, and ConvertFrom-Json hands that
# through as $null rather than as an absent property.
$rows = Get-MergedPrTips -Pairs @(
    [pscustomobject]@{ Name = $reused;                Tip = $tipMerged },
    [pscustomobject]@{ Name = 'sync/live-2026-08-30'; Tip = $tipOther },
    [pscustomobject]@{ Name = 'sync/live-2026-08-29'; Tip = $null },
    [pscustomobject]@{ Name = 'sync/live-2026-08-28'; Tip = 'not-a-sha' },
    [pscustomobject]@{ Name = '';                     Tip = $tipMerged },
    $null
)
Assert-Equal 2 $rows.Count 'pairs: the same four rows are dropped for the same four reasons'
Assert-True ($rows.ContainsKey($reused)) 'pairs: and the merged branch survives'
Assert-True (Test-RefMergedByPr -Name $reused -Tip $tipMerged -MergedTips $rows) 'pairs: the two transports agree on the answer'

# A hashtable row rather than a pscustomobject: the parameter is typed [object[]], and a caller reaching
# for the cheaper literal must not silently get an empty map.
$hashRows = Get-MergedPrTips -Pairs @(@{ Name = $reused; Tip = $tipMerged })
Assert-True (Test-RefMergedByPr -Name $reused -Tip $tipMerged -MergedTips $hashRows) 'pairs: a hashtable row is read like an object row'

# --- the proof ------------------------------------------------------------------------------------
Write-Host ''
Write-Host 'Test-RefMergedByPr -- was THIS ref merged, or just its name?' -ForegroundColor Cyan

# THE DEFECT ITSELF, in one assert: same name, different commit. The merged PR is real, and it is not
# about this ref.
Assert-True (-not (Test-RefMergedByPr -Name $reused -Tip $tipStanding -MergedTips $tips)) `
    'merged/reused: a RE-CREATED branch of an already-merged name is standing, not merged'

# AND THE CASE THE NAME CHECK WAS ADDED FOR, which the repair must not break: on a repo without
# delete_branch_on_merge a squash-merged ref lingers forever, at exactly the tip its PR carried.
Assert-True (Test-RefMergedByPr -Name $reused -Tip $tipMerged -MergedTips $tips) `
    'merged/squash: a ref still sitting at the tip its merged PR carried IS merged'

# A BRANCH SOMEBODY PUSHED TO AFTER THE MERGE is the same shape as the reused name and wants the same
# answer: it holds a commit the trunk has not seen, so it is not proven merged.
Assert-True (-not (Test-RefMergedByPr -Name 'sync/live-2026-08-30' -Tip $tipStanding -MergedTips $tips)) `
    'merged/moved: a ref that has moved on since its PR merged is unproven again'

Assert-True (Test-RefMergedByPr -Name $reused -Tip $tipMerged.ToUpperInvariant() -MergedTips $tips) `
    'merged/sha-case: an object name is hex, so the comparison does not care which case it arrives in'

# THE THREE UNKNOWNS, all answering 'not merged'. That is each caller's own direction rather than a rule
# of its own -- sync-main refuses the run, prune-merged keeps the branch -- and both need the same no.
Assert-True (-not (Test-RefMergedByPr -Name $reused -Tip '' -MergedTips $tips)) `
    'merged/no-tip: an unreadable tip is not merged'
Assert-True (-not (Test-RefMergedByPr -Name $reused -Tip $tipMerged -MergedTips $null)) `
    'merged/gh-silent: a gh that could not answer proves nothing about any branch'
Assert-True (-not (Test-RefMergedByPr -Name 'sync/live-2026-07-01' -Tip $tipMerged -MergedTips $tips)) `
    'merged/absent: a name no merged PR carried is unproven, even at a tip some other PR did merge'

# --- the comparer, which is what issue #1194 was about ---------------------------------------------
Write-Host ''
Write-Host 'The ordinal comparer -- the guard the second copy was missing (#1194)' -ForegroundColor Cyan

# A hashtable's default comparer is case-insensitive, which would let a merged 'Sync/...' vouch for a
# standing 'sync/...'; git refs are case-sensitive, so those are two branches. Asserted on BOTH
# transports: the whole point of one source is that neither caller can be the one without it.
Assert-True (-not (Test-RefMergedByPr -Name $reused.ToUpperInvariant() -Tip $tipMerged -MergedTips $tips)) `
    'case/tsv: a name differing only in case is a different branch'
Assert-True (-not (Test-RefMergedByPr -Name $reused.ToUpperInvariant() -Tip $tipMerged -MergedTips $rows)) `
    'case/pairs: and the object transport keys its map exactly the same way'
Assert-True (-not $tips.ContainsKey($reused.ToUpperInvariant())) `
    'case: ContainsKey itself answers case-sensitively, which is where a bare @{} silently differed'

# TWO NAMES DIFFERING ONLY IN CASE ARE TWO ENTRIES, not one overwriting the other -- the other half of
# the same property, and the half a ContainsKey assert cannot see.
$cased = Get-MergedPrTipsFromTsv -Lines @("$reused`t$tipMerged", "$($reused.ToUpperInvariant())`t$tipOther")
Assert-Equal 2 $cased.Count 'case: two names differing only in case are two branches, so two entries'
Assert-True (Test-RefMergedByPr -Name $reused -Tip $tipMerged -MergedTips $cased) 'case: and each keeps its own tip'
Assert-True (-not (Test-RefMergedByPr -Name $reused -Tip $tipOther -MergedTips $cased)) 'case: neither vouching for the other''s'

# --- one name, several merged PRs -------------------------------------------------------------------
Write-Host ''
Write-Host 'One name, two merged PRs -- the ordinary end state of a recycled name' -ForegroundColor Cyan

$twice = Get-MergedPrTipsFromTsv -Lines @("$reused`t$tipMerged", "$reused`t$tipOther", "$reused`t$tipMerged")
Assert-Equal 1 $twice.Count 'twice: two merged PRs on one name are one entry'
Assert-True (Test-RefMergedByPr -Name $reused -Tip $tipMerged -MergedTips $twice) 'twice: the first tip still proves itself'
Assert-True (Test-RefMergedByPr -Name $reused -Tip $tipOther  -MergedTips $twice) 'twice: and so does the second'
Assert-True (-not (Test-RefMergedByPr -Name $reused -Tip $tipStanding -MergedTips $twice)) 'twice: a third tip on that name is still unproven'

# --- the middle answer ------------------------------------------------------------------------------
Write-Host ''
Write-Host 'Test-MergedPrNameKnown -- the sentence to print once the proof has said no' -ForegroundColor Cyan

# IT IS NOT A PROOF, and the asserts say so in the one direction that matters: it answers TRUE for
# exactly the case Test-RefMergedByPr answers FALSE for, which is what makes prune-merged's
# 'used this name, but not this commit' a different sentence from 'no merged PR' rather than a
# different verdict.
Assert-True (Test-MergedPrNameKnown -Name $reused -MergedTips $tips) `
    'known/recycled: a name a merged PR carried is known, whatever tip this ref is on'
Assert-True (-not (Test-RefMergedByPr -Name $reused -Tip $tipStanding -MergedTips $tips)) `
    'known/recycled: and that same ref is still not proven merged -- two questions, two answers'
Assert-True (-not (Test-MergedPrNameKnown -Name 'sync/live-2026-07-01' -MergedTips $tips)) `
    'known/absent: a name no merged PR carried is unknown, which is the "no merged PR" sentence'
Assert-True (-not (Test-MergedPrNameKnown -Name $reused -MergedTips $null)) `
    'known/gh-silent: a gh that could not answer knows no names at all'
Assert-True (-not (Test-MergedPrNameKnown -Name $reused.ToUpperInvariant() -MergedTips $tips)) `
    'known/case: and it reads the same ordinal map, so it cannot recycle a name the proof would not'

Write-Host ''
Write-Host "merged-pr-lib.tests: $script:pass passed, $script:fail failed" -ForegroundColor $(if ($script:fail) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
