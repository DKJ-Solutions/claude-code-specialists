<#
.SYNOPSIS
    Push this branch's development cycle to origin -- unless a PR has already published it. The
    automatic half of parking: one document, no PR, no live action, and silent when there is nothing
    to do.

.DESCRIPTION
    THE PROBLEM THIS CLOSES (issue #900). A branch that exists only locally is a branch the other
    device cannot see. Measured over the 38 merged branches carrying a readable creation stamp: the
    median branch was invisible on origin for 22 minutes, the mean 35, the worst 365, and nine of the
    38 for over half an hour. new-branch now pushes at creation, which makes the branch's NAME visible
    from minute one -- but a name is not what another device needs. What it needs is the PLAN, which
    phase is running and where the last session stopped, and all three live in this one document.

    So this script exists for the LIFE of the branch, not for its first minute, and by this repo's own
    rule -- what has to happen without anyone asking for it is a hook -- it is invoked by one
    (cycle-autopark.ps1, on Stop). It is an ordinary script all the same, and running it by hand does
    exactly what the hook does. That is deliberate: the measurement that shaped this is that `park` and
    `new-branch -Park` produced SIX commits in the whole history. An opt-in backup is a backup nobody
    takes.

    THE TRAP THAT SHAPES EVERY BOUND BELOW: THE DEPLOY LOCK (#884). ship-pr refuses the merge once
    development-cycle.md has diverged from what the PR published. A pusher that kept running after
    open-pr would therefore not be a convenience -- it would block every merge in the repo,
    structurally, and the failure would read as the lock misbehaving rather than as this script. Hence
    the PR check below, and hence its fail-safe direction: when the answer cannot be established, this
    script does NOT push. Being one turn stale is a nuisance; an unmergeable branch is a defect.

    THE FOUR BOUNDS, all of them narrow on purpose:

      1. ONE DOCUMENT. The pathspec is the resolved cycle path and nothing else -- never `git add -A`,
         which is right for a deliberate park (park-branch.ps1) and wrong for an automatic one: it
         would publish work in progress nobody asked to publish.
      2. NOT ON THE TRUNK, where the fold REMOVES this document by design.
      3. NOT ONCE A PR EXISTS -- the lock above.
      4. NO AMEND, NO FORCE. Keeping the history to one commit would mean `git push --force`, which
         the constitution forbids on any branch without Dave's explicit permission. So this costs a
         handful of small commits per branch, and the recognisable `park:` subject Invoke-GitPark
         already writes is the mitigation.

    AND THE COMMIT SAYS WHAT IS BEHIND THE PLAN (issue #960). Publishing the plan and nothing else is
    what bound 1 is for, and it has one perverse outcome: a branch whose work is uncommitted in another
    device's working copy arrives on origin as a document claiming the work is done, with no commit behind
    a single tick. So every park commit carries a `Backing:` line -- how many steps are resolved, how many
    files are committed on this branch besides this document, how many are uncommitted here -- and, when
    the plan reads as FINISHED with nothing behind it, a paragraph saying so in as many words.
    session-status prints it back for every parked branch. COUNTS, NEVER FILENAMES: the uncommitted figure
    describes work nobody asked to publish. It is a note and never a gate -- see the block at the call.

    NO SOURCE-REPO GUARD, and that is the documented precedent rather than an omission. A hook invokes
    this from '${CLAUDE_PLUGIN_ROOT}/scripts/task/', by design, against the current repo -- so a
    refusal would fire on every turn in the repo that maintains it, exactly as source-repo-guard-lib's
    own header records for check-roster-sync.ps1 and check-script-contract.ps1. The staleness that
    guard exists to catch is also absent here: a lagging mirror of this script commits and pushes one
    file, it does not scaffold a retired template.

    Every git call goes through the shared Invoke-NativeCapture (EAP=Continue -> run -> record
    $LASTEXITCODE), because git writes progress to stderr, which under EAP=Stop would become a
    terminating NativeCommandError before the exit code could be judged (the #96/#97/#107 pitfall).

    ALWAYS EXITS 0. It runs on a hook, and a hook that fails is a hook that interrupts the work it was
    added to protect. Every refusal above is a normal outcome, not an error.

    Pure ASCII (repo convention for .ps1).

.PARAMETER RepoRoot
    (Optional) the tree to act on, when that is NOT the tree resolved from CLAUDE_PROJECT_DIR or the
    git root. Used by the suite, and by a caller acting on a worktree lane.

.PARAMETER Quiet
    (Optional switch) print nothing when there is nothing to do. What the hook passes: a turn in which
    the document did not change must not add a line to the session. A push still reports itself.

.EXAMPLE
    ./scripts/task/park-cycle.ps1

.EXAMPLE
    ./scripts/task/park-cycle.ps1 -Quiet
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = '',
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# One reporter, so every "nothing to do" answer obeys -Quiet the same way and a push never does.
function Write-CycleParkNote {
    param([string]$Message, [string]$Colour = 'DarkGray')
    if (-not $Quiet) { Write-Host "park-cycle: $Message" -ForegroundColor $Colour }
}

# $PSScriptRoot-relative, not $root: these libs are not repo-owned -- they travel with the SAME
# plugin/mirror payload as this script, so they resolve from the source root, a consumer's plugin cache
# and the in-repo mirror alike. LOADED BEFORE THE ROOT IS RESOLVED, because resolving it takes a git
# call and this is the lib that makes one safe -- see the block below.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\park-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\pr-issues-lib.ps1')

# Dual-context repo root: a consumer running the plugin mirror gets it from CLAUDE_PROJECT_DIR, the
# source root copy falls back to the git root. Same resolution as every other mirrored script -- but via
# Invoke-NativeCapture rather than a bare `git ... 2>$null`, which is what this first tried. Two reasons,
# and the second is the one that decides it: a hook fires wherever the session happens to be, so running
# outside a git repo is an ordinary case here rather than an edge one, and git writes that refusal to
# stderr, which under EAP=Stop is terminating before any exit code can be read. The repo-wide guard in
# shared-scripts.tests.ps1 exists for exactly this and caught it on the first run.
$root = if ($RepoRoot) {
    $RepoRoot
} elseif ($env:CLAUDE_PROJECT_DIR) {
    $env:CLAUDE_PROJECT_DIR
} else {
    $topRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('rev-parse', '--show-toplevel') -DiscardStderr
    if ($topRes.ExitCode -eq 0) { (($topRes.Output | Out-String).Trim()) } else { '' }
}
if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) {
    Write-CycleParkNote "no repository resolved -- nothing to do."
    exit 0
}

# repo-config.ps1 optional, exactly as new-branch and check-branch-entry load it: entry-scaffold-lib
# reads the wording and path overrides from it, and a repo that renamed this document is resolved by its
# own names only while that file is already in the session. AFTER the libs, so its overrides win.
$repoConfig = Join-Path $root 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfig -PathType Leaf) {
    try { . $repoConfig } catch { Write-CycleParkNote "scripts/repo-config.ps1 failed to load -- the built-in paths are used." 'DarkYellow' }
}

# branch-info.ps1 IS repo-owned and does not travel with the plugin -- every consumer keeps their own
# prefix table and trunk name -- so it is loaded from the repo being acted on, guarded. All this script
# wants from it is the trunk name, which has a shared fallback, so a repo without the lib degrades to
# that rather than to a failure.
$branchInfoLib = Join-Path $root 'scripts\lib\branch-info.ps1'
if (Test-Path -LiteralPath $branchInfoLib -PathType Leaf) {
    try { . $branchInfoLib } catch { Write-CycleParkNote "scripts/lib/branch-info.ps1 failed to load -- the trunk name falls back." 'DarkYellow' }
}

# Current branch from HEAD. Via Invoke-NativeCapture so a detached or otherwise edge git state cannot
# turn a stderr line into a terminating error before the exit code is judged.
$branchRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $root, 'rev-parse', '--abbrev-ref', 'HEAD')
if ($branchRes.ExitCode -ne 0) {
    Write-CycleParkNote "not a git repository (or no HEAD) -- nothing to do."
    exit 0
}
$branch = ($branchRes.Output | Out-String).Trim()
if (-not $branch -or $branch -eq 'HEAD') {
    # A detached HEAD has no branch to push. Named rather than pushed to whatever it resolves to.
    Write-CycleParkNote "detached HEAD -- no branch to park."
    exit 0
}

# BOUND 2: the trunk, asked of the shared resolver and NOT of the seam directly. Get-BranchTrunkName
# already probes the consumer's optional Get-TrunkBranchName and falls back to 'main', so a second probe
# here would be one more place that has to keep agreeing with it -- exactly the shape park-lib was
# extracted to end. (check-branch-entry.ps1 carries that older two-step; it is not a defect there, it is
# just a layer this one does not need.)
$trunk = if (Get-Command Get-BranchTrunkName -ErrorAction SilentlyContinue) {
    $t = ([string](Get-BranchTrunkName)).Trim(); if ($t) { $t } else { 'main' }
} else { 'main' }

if ($branch -eq $trunk) {
    Write-CycleParkNote "on the trunk, where the fold removes this document by design."
    exit 0
}

# BOUND 1: the one document, resolved by the shared dual-read rather than by a path typed here -- so a
# branch opened before a rename, and a consumer who answered the folder seam differently, are both found.
$cycleRel = Resolve-BranchFilePath -Kind 'File' -RepoRoot $root
$cyclePath = Join-Path $root ($cycleRel -replace '/', '\')
if (-not (Test-Path -LiteralPath $cyclePath -PathType Leaf)) {
    Write-CycleParkNote "'$cycleRel' does not exist yet -- nothing to park."
    exit 0
}

# AND THE DOCUMENT MUST BE THIS BRANCH'S. Resolve-BranchFilePath falls back to a path that merely
# EXISTS when nothing claims the branch, which on a branch created outside new-branch is the reset
# document. Pushing that would put the trunk's own empty state on the branch under a `park:` subject.
$cycleText = [System.IO.File]::ReadAllText($cyclePath, [System.Text.Encoding]::UTF8)
$declared = Get-BranchFileDeclaredBranch -Text $cycleText
if (-not $declared -or $declared -eq $trunk) {
    Write-CycleParkNote "'$cycleRel' is in its reset state -- it belongs to no branch, so there is nothing to hand over."
    exit 0
}
if ($declared -ne $branch) {
    # Somebody else's document, sitting here uncommitted or committed on another branch. new-branch is
    # the script that decides what happens to it, with the owner named; this one keeps its hands off.
    Write-CycleParkNote "'$cycleRel' declares '$declared', not '$branch' -- left alone." 'DarkYellow'
    exit 0
}

# IS THERE ANYTHING TO DO AT ALL? Two independent reasons to push, and this is the gate that keeps a
# turn which touched nothing free of both a git write and the network call below.
#
#   a. the document differs from HEAD -- staged or not. `git status --porcelain` on the one pathspec.
#   b. HEAD is ahead of the remote branch, or the remote branch does not exist yet. A local commit
#      nobody can see is the same invisibility as an uncommitted edit.
$statusRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $root, 'status', '--porcelain', '--', $cycleRel)
$dirty = $false
if ($statusRes.ExitCode -eq 0) { $dirty = [bool](($statusRes.Output | Out-String).Trim()) }

# DELIBERATELY NO FETCH. The remote-tracking ref is read as it stands: a fetch on every turn costs the
# network call this gate exists to avoid, and a ref that has gone stale because the other device pushed
# is exactly the case where the push below fails loudly -- which is the right outcome, not a defect.
$aheadOrAbsent = $true
$remoteRef = "refs/remotes/origin/$branch"
$refRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $root, 'rev-parse', '--verify', '--quiet', $remoteRef) -DiscardStderr
if ($refRes.ExitCode -eq 0) {
    $countRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $root, 'rev-list', '--count', "origin/$branch..HEAD")
    $aheadOrAbsent = if ($countRes.ExitCode -eq 0) { (($countRes.Output | Out-String).Trim()) -ne '0' } else { $false }
}

if (-not $dirty -and -not $aheadOrAbsent) {
    Write-CycleParkNote "'$cycleRel' is already on origin -- nothing to do."
    exit 0
}

# NO ORIGIN, NOTHING TO DO -- asked before the gh call below, because a repo with no remote has no PR to
# ask about either. Same question new-branch asks for the same reason; Test-GitOriginConfigured carries it.
if (-not (Test-GitOriginConfigured -RepoRoot $root)) {
    Write-CycleParkNote "no 'origin' remote -- nowhere to park to."
    exit 0
}

# BOUND 3: THE DEPLOY LOCK. Any open PR with this head means its body has published a DEPLOY section
# that ship-pr will compare this document against, so from here on the document is the PR's to change,
# not this script's. Deliberately NOT filtered by --base: the question is not which PR would be merged
# but whether one has published a body at all, and a stacked PR publishes one just as an ordinary one
# does.
#
# FAIL-SAFE DIRECTION. gh missing, gh not logged in, no network, an unparseable payload -- every one of
# them means the answer is unknown, and unknown does not push. See the lock paragraph in the header.
$prList = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--head', $branch, '--state', 'open', '--json', 'number', '--limit', '1') -DiscardStderr
if ($prList.ExitCode -ne 0) {
    Write-CycleParkNote "could not ask gh whether '$branch' has a PR -- not pushing (the DEPLOY lock must not be broken from here)." 'DarkYellow'
    exit 0
}
$prRecord = Get-ExistingPrRecord -Json (($prList.Output | Out-String))
if ($null -ne $prRecord) {
    Write-CycleParkNote "PR #$($prRecord.number) is open for '$branch' -- the document is the PR's from here on."
    exit 0
}

# WHAT IS BEHIND THE TICKS (#960), MEASURED HERE BECAUSE NOWHERE ELSE CAN. This script publishes the
# plan and nothing else -- bound 1 -- so on a branch whose work sits uncommitted in ANOTHER device's
# working copy it puts a document reading '[x] done' on origin with no commit behind a single tick. From
# origin those two states are the same document, and the more complete the ticks the more convincing the
# wrong reading: a session picking it up in good faith rebuilds work that already exists, or opens a PR
# that merges the plan alone. This is the device that HOLDS the invisible work, at the one moment it
# becomes invisible, so it is the only place the fact is both known and true.
#
# THE MEASUREMENT DOES NOT GET A VOTE ON THE PUSH. It is a note, not a gate: a park that refused because
# it disliked the shape of the plan would be the one thing worse than the misleading document, since the
# plan would then not reach the other device at all. Hence the try -- an unreadable document or an odd
# git state costs the note, never the park.
$backingNote = ''
try {
    $backingNote = Format-GitParkBacking `
        -Steps (Get-BranchProgressTally -Text $cycleText) `
        -Backing (Get-GitParkBacking -RepoRoot $root -Trunk $trunk -Paths @($cycleRel))
} catch {
    Write-CycleParkNote "could not measure what is behind the plan -- parking without that note." 'DarkYellow'
}

# THE STAGE-COMMIT-PUSH ITSELF LIVES IN park-lib.ps1 (#507), the one implementation the two deliberate
# parking entry points already share. This is the third caller and it adds no steps of its own: the
# scope picks both the pathspec and the words, so the log says `park: <branch> (the branch files only)`
# for this the same as for new-branch's push at creation.
$ok = Invoke-GitPark -RepoRoot $root -Branch $branch -Scope 'BranchFiles' -Paths @($cycleRel) -BodyNote $backingNote
if (-not $ok) {
    # Reported, never fatal -- see the always-exits-0 paragraph. A failed push here is usually the
    # divergence case the no-fetch note above describes, and it is worth a visible line.
    Write-Host "park-cycle: '$cycleRel' could NOT be pushed -- run park-cycle by hand for the reason (diverged from origin?)." -ForegroundColor Yellow
    exit 0
}

exit 0
