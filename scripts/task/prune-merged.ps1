<#
.SYNOPSIS
    Tidy the local clone after merges: fast-forward the trunk, drop stale remote-tracking refs, and
    delete the local branches that are PROVABLY merged. A branch without that proof is left alone.

.DESCRIPTION
    The other half of branch cleanup. The REMOTE half is GitHub's own -- the repo setting
    "Automatically delete head branches" (`deleteBranchOnMerge`) removes the head branch on every
    merge route there is: the script path, the web UI, another machine, another tool. This script
    never touches a remote branch, and that is deliberate rather than an omission (see the block
    under "What this script does NOT do" below).

    WHY IT SHIPS CENTRALLY (inbound #815, August 21, 2026). It existed as a hand-written copy in two
    consumers and nowhere in the plugin -- which is the `new-branch.ps1` argument of issue #81
    exactly: a mechanism several repos all need, living as a copy in each, is a mechanism that will
    drift. The requester's own words when he noticed the accumulation: "waarom worden branches niet
    automatisch verwijderd na een merge? Dit zou de plugin moeten vertellen". Measured on the repo he
    was looking at: 20 remote heads, 18 of them belonging to already-merged PRs, five days into using
    this workflow.

    THE STEPS, IN ORDER:

      1. Refuse on a dirty tree. Switching branches with uncommitted work either fails halfway or
         drags the work across; both are worse than stopping with a sentence.
      2. Switch to the trunk and fast-forward it (`git pull --ff-only`). Fast-forward ONLY: this
         script is allowed to advance the trunk, never to merge anything into it.
      3. `git fetch --prune` -- drop remote-tracking refs whose remote branch is gone. This matters
         even when the remote branch was auto-deleted at the merge: the stale `origin/<branch>` refs
         otherwise pile up in the clone until pruned, and a clean local branch list is then no
         evidence whatsoever that the remote is clean.
      4. Delete each local branch for which a merge can be PROVEN, and only those:

           a. an ancestor of the trunk -- `git branch -d`, which refuses an unmerged branch on its
              own, so the proof is checked twice;
           b. otherwise, a branch whose PR on GitHub is MERGED -- `git branch -D`. This is the squash
              case: the branch's own tip is deliberately not in the trunk's history, so (a) can never
              see it and `-d` would refuse a branch that is genuinely finished. The merged PR is the
              proof that replaces ancestry, which is why the forced delete is safe HERE and nowhere
              else.

         A branch with neither proof is KEPT and reported with the reason. That is the whole safety
         property: a parked branch (`park-branch.ps1`), unfinished work, or a branch pushed from
         another machine is never lost, because none of them has either proof.

    WHAT THIS SCRIPT DOES NOT DO, and why each is a decision:

      - IT DELETES NOTHING ON THE REMOTE. `git push origin --delete` is a manual action in this
         house: with `deleteBranchOnMerge` on, merged branches disappear by themselves, so a remote
         delete would only ever reach branches that are NOT merged -- exactly the ones whose loss is
         unrecoverable. All of the risk, almost none of the benefit.
      - IT IS NOT PART OF THE MERGE. Reaping is a separate command so that a session cannot delete a
         branch as a side effect of shipping a PR. `ship-pr.ps1` reports the remote setting when it is
         off and stops there.
      - IT DOES NOT PASS `--delete-branch` FOR ANYONE. Beyond covering only the script path, that flag
         also deletes the LOCAL branch, and it was measured on July 16, 2026 leaving the checkout ON
         the merged branch -- with the fold running there and having to be undone by hand.

    Every git call goes through the shared Invoke-NativeCapture (EAP=Continue -> run -> record
    $LASTEXITCODE), because git writes progress to stderr, which under EAP=Stop becomes a terminating
    NativeCommandError before the exit code can be judged (the #96/#97/#107 pitfall).

    Pure ASCII (repo convention for .ps1).

.PARAMETER DryRun
    (Optional switch) report what would be deleted and delete nothing. Steps 2 and 3 -- the
    fast-forward and the prune of remote-tracking refs -- still run: neither loses anything, and
    without them the branch list this reports on is the stale one.

.PARAMETER Remote
    (Optional) the remote to fetch and prune, default 'origin'.

.EXAMPLE
    ./scripts/task/prune-merged.ps1 -DryRun

.EXAMPLE
    ./scripts/task/prune-merged.ps1
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$Remote = 'origin'
)

$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR supplies
# its repo root; in the source root (or outside a session) it falls back to the git root. This way the
# SAME file works in both locations, and the root copy and the plugin mirror stay byte-identical
# (guarded by the shared-scripts drift lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Shared native-capture helper. $PSScriptRoot-relative, not $repoRoot: this lib is not repo-owned --
# it travels with the SAME plugin/mirror payload as this script.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# THE TRUNK COMES FROM THE SEAM, NOT FROM A LITERAL, and the two dot-sources below are what it costs.
# A repo on 'master' that this script assumed was on 'main' would fail its rev-parse and refuse, which
# is the safe direction -- but refusing a correctly-configured consumer is still a defect, and the one
# thing this script must never do is reason about ancestry against the wrong branch.
#
# repo-config.ps1 is OPTIONAL (a repo that never needed it, or one whose edit does not parse); it backs
# the seam function Get-TrunkBranchName, and every value it supplies has a working default. So:
# Test-Path, then try/catch that degrades to a warning. entry-scaffold-lib.ps1 owns Get-BranchTrunkName
# itself and travels with this script.
$repoConfigPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfigPath -PathType Leaf) {
    try { . $repoConfigPath } catch {
        Write-Warning "scripts\repo-config.ps1 could not be loaded ($($_.Exception.Message)); falling back to the default trunk name."
    }
}
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
$trunk = Get-BranchTrunkName

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    return Invoke-NativeCapture -FilePath 'git' -Arguments (@('-C', $repoRoot) + $Arguments)
}

# --- 1. Pre-flight: a git repo, a known trunk, and a clean tree ------------------------------------
$headRes = Invoke-Git -Arguments @('rev-parse', '--abbrev-ref', 'HEAD')
if ($headRes.ExitCode -ne 0) {
    Write-Error "prune-merged cannot run -- not a git repository (or no HEAD): $repoRoot"
    exit 1
}

$trunkRes = Invoke-Git -Arguments @('rev-parse', '--verify', '--quiet', "refs/heads/$trunk")
if ($trunkRes.ExitCode -ne 0) {
    Write-Error "prune-merged cannot run -- this clone has no local branch '$trunk'. That is the trunk this repo declares (Get-TrunkBranchName in scripts\repo-config.ps1, default 'main'); check it out once, or correct the seam."
    exit 1
}

# A dirty tree is refused BEFORE anything is touched, not discovered by a failing checkout halfway
# through: at that point the fetch may already have run and the reader has to work out what did and
# did not happen.
$statusRes = Invoke-Git -Arguments @('status', '--porcelain')
if ($statusRes.ExitCode -ne 0) {
    Write-Error "prune-merged cannot read the working tree state in $repoRoot."
    exit 1
}
$dirty = @(($statusRes.Output | Out-String) -split '\r?\n' | Where-Object { $_.Trim() })
if ($dirty.Count -gt 0) {
    Write-Error "prune-merged refuses on a dirty working tree ($($dirty.Count) change(s)). Switching to '$trunk' would either fail halfway or drag the work across. Commit, park (scripts\task\park-branch.ps1) or stash first."
    exit 1
}

# --- 2. On the trunk, fast-forwarded ---------------------------------------------------------------
$startBranch = ($headRes.Output | Out-String).Trim()
if ($startBranch -ne $trunk) {
    $coRes = Invoke-Git -Arguments @('checkout', $trunk)
    if ($coRes.ExitCode -ne 0) {
        Write-Error "prune-merged could not switch to '$trunk': $(($coRes.Output | Out-String).Trim())"
        exit 1
    }
    Write-Host "Switched to '$trunk' (was on '$startBranch')." -ForegroundColor Green
}

# FAST-FORWARD ONLY. This script may advance the trunk and must never merge anything into it -- a
# merge commit made here would be a change on the trunk that no PR ever carried. A non-fast-forward
# is reported and does not stop the run: the ancestry the deletions are judged on is then simply the
# older trunk, which errs towards KEEPING branches.
$pullRes = Invoke-Git -Arguments @('pull', '--ff-only', $Remote, $trunk)
if ($pullRes.ExitCode -ne 0) {
    Write-Warning "'$trunk' could not be fast-forwarded from $Remote -- continuing against the local '$trunk'. Fewer branches will look merged, never more. ($(($pullRes.Output | Out-String).Trim()))"
} else {
    Write-Host "Fast-forwarded '$trunk' from $Remote." -ForegroundColor Green
}

# --- 3. Drop stale remote-tracking refs ------------------------------------------------------------
# Worth doing even when the remote deletes its own merged branches: those refs stay in the clone until
# pruned, which is why a clean local list proves nothing about the remote (verify that with
# `git ls-remote --heads <remote>`).
$fetchRes = Invoke-Git -Arguments @('fetch', '--prune', $Remote)
if ($fetchRes.ExitCode -ne 0) {
    Write-Warning "could not fetch --prune from $Remote -- stale remote-tracking refs may remain. ($(($fetchRes.Output | Out-String).Trim()))"
} else {
    Write-Host "Pruned stale remote-tracking refs for $Remote." -ForegroundColor Green
}

# --- 4. The branches, and the proof for each -------------------------------------------------------
$listRes = Invoke-Git -Arguments @('for-each-ref', '--format=%(refname:short)', 'refs/heads')
if ($listRes.ExitCode -ne 0) {
    Write-Error "prune-merged could not list the local branches."
    exit 1
}
$branches = @(($listRes.Output | Out-String) -split '\r?\n' |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and $_ -ne $trunk })

if ($branches.Count -eq 0) {
    Write-Host "Nothing to reap: '$trunk' is the only local branch." -ForegroundColor Green
    exit 0
}

# THE MERGED-PR LOOKUP IS ONE CALL, NOT ONE PER BRANCH. A repo five days into this workflow already
# has dozens of merged PRs and this command is a tidy-up, not a report -- so the whole merged set is
# read once and matched locally. gh may be absent or unauthenticated: that is not an error here, it
# only means proof (b) cannot be established, so a squash-merged branch is KEPT and says why.
$mergedHeads = @()
$ghKnown = $false
$ghCmd = Get-Command 'gh' -ErrorAction SilentlyContinue
if ($ghCmd) {
    $prRes = Invoke-NativeCapture -FilePath 'gh' -Arguments @(
        'pr', 'list', '--state', 'merged', '--limit', '200', '--json', 'headRefName', '--jq', '.[].headRefName')
    if ($prRes.ExitCode -eq 0) {
        $ghKnown = $true
        $mergedHeads = @(($prRes.Output | Out-String) -split '\r?\n' |
            ForEach-Object { $_.Trim() } | Where-Object { $_ })
    } else {
        Write-Warning "gh could not list merged PRs -- a squash-merged branch cannot be proven merged and will be kept. ($(($prRes.Output | Out-String).Trim()))"
    }
} else {
    Write-Warning "gh is not available -- a squash-merged branch cannot be proven merged and will be kept."
}

$deleted = @()
$kept    = @()

foreach ($branch in $branches) {
    $ancestor = (Invoke-Git -Arguments @('merge-base', '--is-ancestor', $branch, $trunk)).ExitCode -eq 0
    $mergedPr = ($mergedHeads -contains $branch)

    if (-not ($ancestor -or $mergedPr)) {
        # THE ONE BRANCH THIS SCRIPT PROTECTS. No ancestry and no merged PR means unfinished work, a
        # parked branch, or a branch pushed from another machine -- and its reason is printed rather
        # than left to be inferred from the absence of a delete line.
        $why = if ($ghKnown) { 'not an ancestor of the trunk and no merged PR' } else { 'not an ancestor of the trunk, and no merged PR could be checked' }
        $kept += [pscustomobject]@{ Branch = $branch; Why = $why }
        continue
    }

    # -d WHERE ANCESTRY PROVES IT, -D ONLY WHERE A MERGED PR DOES. -d refuses an unmerged branch by
    # itself, so the ancestry case is checked twice; -D skips that check, and the merged PR is what
    # replaces it. Choosing -D on ancestry as well would throw the second check away for nothing.
    $flag   = if ($ancestor) { '-d' } else { '-D' }
    $proof  = if ($ancestor) { 'ancestor of ' + $trunk } else { 'merged PR' }

    if ($DryRun) {
        $deleted += [pscustomobject]@{ Branch = $branch; Proof = $proof; Flag = $flag }
        continue
    }

    $delRes = Invoke-Git -Arguments @('branch', $flag, $branch)
    if ($delRes.ExitCode -eq 0) {
        $deleted += [pscustomobject]@{ Branch = $branch; Proof = $proof; Flag = $flag }
    } else {
        # A REFUSED DELETE IS REPORTED AS KEPT, not as a failure of the run. `git branch -d` declining
        # is the safety check doing its job on a branch whose ancestry looked right a moment ago, and
        # the run has other branches to finish.
        $kept += [pscustomobject]@{ Branch = $branch; Why = "git branch $flag refused: $(($delRes.Output | Out-String).Trim())" }
    }
}

# --- The report ------------------------------------------------------------------------------------
$verb = if ($DryRun) { 'Would delete' } else { 'Deleted' }
foreach ($d in $deleted) {
    Write-Host "  $verb $($d.Branch) (git branch $($d.Flag) -- $($d.Proof))" -ForegroundColor Green
}
foreach ($k in $kept) {
    Write-Host "  Kept $($k.Branch) -- $($k.Why)" -ForegroundColor Yellow
}

$summary = "$($deleted.Count) $(if ($DryRun) { 'reapable' } else { 'deleted' }), $($kept.Count) kept, of $($branches.Count) local branch$(if ($branches.Count -eq 1) { '' } else { 'es' }) beside '$trunk'."
Write-Host $summary -ForegroundColor Cyan
if ($DryRun -and $deleted.Count -gt 0) {
    Write-Host "Nothing was deleted -- rerun without -DryRun to reap them." -ForegroundColor DarkGray
}

# THE REMOTE IS NOT THIS SCRIPT'S BUSINESS, and saying so is what stops the next reader concluding
# that a clean local list means a clean remote. One line, printed always, naming the command that
# actually answers it.
Write-Host "The remote is untouched by design -- verify it with: git ls-remote --heads $Remote" -ForegroundColor DarkGray
exit 0
