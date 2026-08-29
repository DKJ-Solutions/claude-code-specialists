<#
.SYNOPSIS
    Ship the current branch in one command: open the PR -> wait for the CI check -> merge -> fold.

.DESCRIPTION
    Orchestrates the whole PR chain that is otherwise run by hand
    (open-pr.ps1 -> watch CI -> gh pr merge -> checkout main -> fold-changelog-entry.ps1), so the
    five-step sequence becomes one call. WHEN it may run is governance, not script logic (see
    CLAUDE.md): by default a finished branch ships without asking, but work with a visible result --
    or work that is irreversible/outward-facing -- waits for Dave's explicit word first.

    SHARED SINCE ISSUE #411 -- mirrored into the plugin like open-pr/fold/new-branch, and no longer
    workshop-local. It was excluded on the reasoning that "merge policy and the CI check name are
    repo-specific", and only half of that held up when it was checked. The CI check name is not used by
    this script at all: step 3 watches whatever checks the PR has and reads the exit code, so the name
    only ever appeared in a progress message. The merge method IS a real per-repo policy -- this
    workshop merges, the repo that filed #411 squashes -- so it moved into the seam as the OPTIONAL
    Get-PrMergeMethod rather than staying hardcoded. Note that the issue predicted no new contract
    function would be needed; that prediction is the one part of it that did not survive reading both
    files, and building on it would have shipped one repo's merge policy to the other.

    Everything else it needs was already repo-owned: Get-RepoName for the `gh --repo` target. That
    sentence used to name Get-ChangelogHeading beside it, "which it never reads itself --
    fold-changelog-entry.ps1 does". Neither reads it: the seam was retired on August 5, 2026 with the
    flat changelog (#178), and the fold derives the intro/list boundary from the first entry heading.

    Steps, stopping on the first failure (nothing is forced):
      0. IS 'main' FREE FOR STEP 5 TO CHECK OUT? (issue #1069) git allows one worktree per branch, so a
         second checkout standing on the trunk locks it for the whole clone -- and step 5 checks it out
         HERE in order to fold. Until this step existed that lock was met AFTER the merge, which is the
         worst place in the run to stop: merged, unfolded, and every gate green until a release trips
         over it (measured on PR #1068). Asked before step 1, the last moment at which refusing is free.
         It takes the trunk away from nobody -- it names the directory and the two commands that release
         it -- and an unreadable worktree list warns rather than refuses.
      1. open-pr.ps1 [-SkipLint] [-SkipTests] -- runs the local lint + test gate,
         pushes, and opens the PR. If a gate fails, nothing is pushed and this stops here.

         RESUMES A BRANCH WHOSE PR IS ALREADY OPEN. open-pr.ps1 skips only the `gh pr create` in that
         case and still runs the gates and the push, so this orchestrator carries straight on to
         step 2. Until August 4, 2026 it could not: `gh pr create` was unconditional, a duplicate
         returned non-zero, and step 1's failure meant steps 2-6 never ran -- so a branch whose PR had
         been opened in an earlier session had to be merged and folded BY HAND, which is the five-step
         sequence this script exists to remove. Measured on PR #457 and repaired in open-pr.ps1 rather
         than here: putting the check in the orchestrator would have skipped the gates and the push
         along with the create, and made `open-pr.ps1` on its own still fail on the same branch.

         An existing PR keeps its title -- as every PR now does, the title being composed from the entry
         at creation and never rewritten afterwards (#506) -- and -Resolves is still honoured: the
         closing keywords are appended to the existing body, because step 6 below verifies exactly what
         the merged body declared. Pass -RefreshBody to also rewrite the PR's description from the
         changelog entry -- worth it whenever the entry was extended after the PR was opened, which is
         the normal case on a branch that keeps growing. Both body edits go out as ONE `gh pr edit`.
      2. Look up the PR number for the current branch (gh pr list --head <branch> --base main),
         parsed by Get-ExistingPrRecord. Both details are repairs, measured August 4, 2026: without
         --base a consumer's STACKED PR could be the one merged, and the previous inline parse hit the
         5.1 array-flattening pitfall -- its "no open PR" guard was dead code and a missing PR became
         the empty string, so the script would have run `gh pr merge ''`. See the comment at step 2.
     2b. GIVE THE TRUNK BACK, BEFORE THE WAIT RATHER THAN AFTER IT (issue #1073). Chris's persona says
         both "parking is a state, not a promise to come back within the turn" -- an in-flight ship is a
         finished assignment -- and "it ends on the trunk, which is what makes the session safe to
         clear". A backgrounded ship could not satisfy both, because HEAD did not move until step 5.
         It can now: since #970 the step-4 gates read refs/heads/<branch> and since #972 step 5 reads
         HEAD before it moves anything, so NOTHING BELOW THIS POINT READS THE WORKING TREE'S CONTENT.
         Three conditions, in Get-TrunkReturnDecision and tested there: the primary checkout only, the
         trunk held by nobody else, and a clean tree. Never a refusal -- a tree that cannot go home
         stays where it is and says which of the three it was.
      3. Wait for EVERY check the PR has to finish (gh pr checks <pr> --watch), then judge the merge on
         the ones the ruleset REQUIRES. A failing required check stops the run WITHOUT merging; a
         failing check the ruleset does not require prints a loud warning and does not (issue #943 --
         the exit code of --watch says "something failed", never "the merge is blocked", and reading it
         as the second let one broken advisory workflow block every chain). Either way, print WHICH
         check governed the wait and for how long (#831) -- whichever finished last, labelled against
         the repo's own ruleset. Best-effort: unreadable, and the run says only how long it waited --
         except for the required list, where unreadable means REFUSE, since a ruleset that requires
         nothing and one whose required checks have not reported look identical from here. The wait
         itself is unchanged; see the comment at the step.

         AND SAY, BEFORE THE WATCH BEGINS, THAT NOBODY HAS TO SIT THROUGH IT (issue #985). Backgrounding
         this run is the default: the merge cannot move before the check is green either way, so the only
         thing the wait buys in the foreground is a second look at a result the local gate already gave.
         The lane is printed with it, and it is advice rather than the condition it once was: step 2b has
         already moved this tree to the trunk, so the next branch belongs in a lane because that is where
         you build, not because staying here would cost you your checkout.
      4. TWO GATES, THEN MERGE. The step-list gate refuses while development.md has an unresolved
         step above DEPLOY, and the DEPLOY LOCK (issue #884) refuses when that section no longer matches
         what PR #NN published -- the section is fixed at the moment the PR opens, because it is what the
         review approved and what step 5 folds into CHANGELOG.md. Both are checked here rather than
         inherited from step 1: open-pr has a -Force and a PR opened on github.com ran neither. Neither
         has a -Force of its own. A PR body that cannot be READ is not a finding -- that says something
         about the token, not about the section.
         BOTH JUDGE refs/heads/<branch>, NOT THE WORKING TREE (issue #970): this script waits on CI, and a
         session that backgrounds the ship and starts the next piece of work has moved the checkout by the
         time the gates look. The branch's own commit is what the merge merges.
         Then: gh pr merge <pr> --<method>, from Get-PrMergeMethod ('merge' by default), with the
         merge commit's subject set to 'merge: <branch> (#NN)' so every line in the graph starts with
         a type. No --admin: the CI gate is never bypassed.
      5. Check out main, fast-forward, and hand the fold to fold-changelog-entry.ps1 -Push, which folds
         the entry AND makes the commit itself -- naming CHANGELOG.md and the entry file as the
         commit's pathspec.

         THAT DELEGATION IS THE POINT, not a tidy-up. This step used to run its own `git add -A` +
         `git commit`, which is an unscoped commit landing directly on main under one of the two named
         exceptions to "never commit directly" -- so anything else modified or already staged in the
         tree rode along with it. CLAUDE.md has stated since August 2, 2026 that the fold commit "names
         its paths, so nothing else in the tree can ride along"; that was true of the fold script and
         false of this orchestrator, which is the more commonly used route of the two. An exception is
         only safe while it stays the size it was granted at, and here it was not.

         AND IT GIVES THE TRUNK BACK WHEN THIS IS NOT THE PRIMARY CHECKOUT (step 5b, issue #1069). In
         the primary, ending on the trunk is deliberate -- it is what makes the session safe to clear.
         In a worktree lane the identical line takes the clone-wide lock step 0 above exists to report,
         so a non-primary tree returns to its own branch once the fold has SUCCEEDED. Only on success: a
         failed fold leaves this tree on main mid-repair, which is where whoever finishes it by hand
         needs to be standing. It never fails the ship.
      6. Verify the issues the PR declared it closes are actually CLOSED, and close any that are not
         (verify-resolved-issues.ps1 -- its own script, and tested there).

    Step 6 is the second half of the resolves gate (a lesson from PRs #341-#343, where eight repaired
    findings stayed open because the bodies carried plain mentions instead of closing keywords).
    open-pr.ps1 writes the `Closes #<n>` lines; GitHub honours them on merge into the default branch.
    Step 6 then checks the outcome. A belt on top of a brace: if it never fires, the keyword did its
    job. It cannot fail the ship -- the merge has already happened by then.

    -NoMerge stops after step 1 (open the PR only) -- the same as calling open-pr.ps1 directly, but
    handy when scripting. The native git/gh calls run through Invoke-NativeCapture (the #107 stderr
    guard). Pure ASCII (repo convention for .ps1).

    NOTE (test gap): like open-pr.ps1 this orchestrator drives live git/gh against a real remote and
    is not covered by an automated suite -- the sub-steps it calls (open-pr, fold,
    verify-resolved-issues, the helpers) are tested on their own. Step 6 was deliberately extracted
    into its own script for exactly that reason: it is the one step here that MUTATES state outside
    this repo (it posts comments and closes issues), so leaving it inline would have meant untestable
    write access. What remains untested here is only the orchestration order.

    That gap is not free, and step 2 is the proof: the bug it carried was in an inline PARSE, not in
    the orchestration, and it survived because it sat in the one file no suite reads. Moving the parse
    into pr-issues-lib.ps1 (Get-ExistingPrRecord) is why the same mistake is now a failing assert. The
    lesson generalises: anything in here that is a pure function of text belongs in a lib, precisely
    because this file cannot be tested.

    Repo root: dual-context (CLAUDE_PROJECT_DIR for a consumer running the plugin mirror, otherwise the
    git root), so the root copy and the mirror stay byte-identical -- guarded by the shared-scripts
    drift lint.

.PARAMETER Title
    ACCEPTED AND IGNORED since #506 (August 7, 2026), for the reason open-pr.ps1's own parameter states:
    the PR title is composed from the branch prefix and the entry's 'Branch title' section, so there is
    nothing to pass. Kept as a parameter, and passed through, so that a caller who still supplies one gets
    open-pr's single warning instead of a hard "A parameter cannot be found" at the end of a finished branch
    -- and so the two scripts say the same thing in one place rather than two.

.PARAMETER SkipLint
    Passed through to open-pr.ps1 (skip the lint gate -- escape valve).

.PARAMETER SkipTests
    Passed through to open-pr.ps1 (skip the test gate -- escape valve).

.PARAMETER Force
    Passed through to open-pr.ps1: ship an entry that still carries its scaffold wording (the scaffold
    gate's escape valve).

.PARAMETER NoMerge
    Open the PR and stop (do not wait for CI, merge, or fold).

.PARAMETER PollSeconds
    Poll interval (seconds) for the CI watch. Default 15.

.PARAMETER Resolves
    Passed through to open-pr.ps1: the issue numbers this PR resolves, as a string ('331,332').
    Step 6 verifies them. A string and not an [int[]] for the reason documented on open-pr.ps1's own
    parameter: across `powershell -File` a comma list is cast to one number via the thousands
    separator ('332,340' -> 332340), silently and without an error. Quote it when calling this script
    directly, too -- see the same note there for why an unquoted comma list cannot bind at all.

.PARAMETER NoResolves
    Passed through to open-pr.ps1: declare that this PR closes no issue.

.PARAMETER RefreshBody
    Passed through to open-pr.ps1: on a branch whose PR is already open, rewrite that PR's description
    from the current changelog entry. Opt-in, so a body edited on github.com is never overwritten unasked.
    No effect when the PR is being created in this run.

.EXAMPLE
    ./scripts/release/ship-pr.ps1

.EXAMPLE
    ./scripts/release/ship-pr.ps1 -Resolves '331,332'
#>
[CmdletBinding()]
param(
    [string]$Title = '',
    [switch]$SkipLint,
    [switch]$SkipTests,
    [switch]$Force,
    [switch]$NoMerge,
    [int]$PollSeconds = 15,
    [string]$Resolves = '',
    [switch]$NoResolves,
    [switch]$RefreshBody
)
$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Repo root -- dual context: a consumer running the shared plugin mirror gets its repo root from
# CLAUDE_PROJECT_DIR; in the workshop root (or outside a session) it falls back to the git root. Same
# resolution as every other mirrored script, and the reason this file can be byte-identical in both
# places.
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }
Set-Location $repoRoot

# Pre-flight (#86): this script hard-requires the consumer's repo-config (unlike new-branch,
# which treats it as optional) -- Get-RepoName has no sane default, and without it every gh call below
# would target the wrong repo or none at all. Stop with a pointer instead of a raw dot-source error.
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "ship-pr cannot run -- missing repo-owned file: $configPath (Get-RepoName). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the source repo as a model) and run again afterward."
    exit 1
}

# Repo name from the local repo-config (single source), and the shared native-capture helper (#114) --
# which also carries Get-GitFileTextAtRef, the read the two step-4 gates judge the branch's commit with.
. $configPath
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
# For Get-ExistingPrRecord in step 2. $PSScriptRoot-relative, not $repoRoot: like native-capture-lib
# this one is not repo-owned -- it travels with the same plugin/mirror payload as this script.
. (Join-Path $PSScriptRoot '..\lib\pr-issues-lib.ps1')
# For the step-list gate before the merge in step 4 (Resolve-BranchFilePath, which the gate hands its own
# -Reader, and Get-BranchProgressFindings). Same plugin-payload sibling, same reasoning as the two above.
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
# For the DEPLOY lock before the merge in step 4 (Test-DeployLock, and the Get-PrDescription it calls).
# Loaded AFTER entry-scaffold-lib on purpose: Get-PrDescription probes for the section-heading seams with
# Get-Command and falls back to English defaults when they are absent, so a repo that renamed a heading is
# read by its own names only while that lib is already in the session. Same plugin-payload sibling.
. (Join-Path $PSScriptRoot '..\lib\pr-body-lib.ps1')
# For the trunk-lock pre-flight below and the hand-back at the end of step 5 (issue #1069). Same
# plugin-payload sibling as the four above, and pure text functions for the reason its own header gives:
# the decision they carry -- does another worktree hold the trunk? -- is the one part of this repair that
# CAN be tested, and this file cannot be.
. (Join-Path $PSScriptRoot '..\lib\worktree-lib.ps1')
$repo = Get-RepoName

# The merge method is repo POLICY, not script logic (issue #411): this workshop merges, another repo
# squashes. OPTIONAL and Get-Command-guarded like the other seam reads, so a consumer that never
# thought about it gets 'merge'. Validated rather than passed straight through -- an unexpected value
# would otherwise reach `gh pr merge` as an unknown flag at the one moment this script is about to
# write to main, which is the worst place to discover a typo in a config file.
$mergeMethod = 'merge'
if (Get-Command Get-PrMergeMethod -ErrorAction SilentlyContinue) {
    $configuredMethod = Get-PrMergeMethod
    if ($configuredMethod) {
        if (@('merge', 'squash', 'rebase') -notcontains $configuredMethod) {
            Write-Error "Get-PrMergeMethod in scripts\repo-config.ps1 returned '$configuredMethod'; it must be 'merge', 'squash' or 'rebase'. Nothing was pushed or merged."
            exit 1
        }
        $mergeMethod = $configuredMethod
    }
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq 'main') { Write-Error "You are on main; ship-pr runs from a branch."; exit 1 }

# --- Step 0: is 'main' free for step 5 to check out? (issue #1069) --------------------------------
# THE ORDERING IS THE WHOLE POINT. git allows one worktree per branch, so a tree standing on 'main'
# locks it for the entire clone -- and step 5 checks 'main' out HERE in order to fold. Until this check
# existed, that lock was met at step 5: after the merge. The PR was then merged and NOT folded, which is
# the one state nothing reports (CHANGELOG.md unfolded, the development document still on the trunk,
# every gate green until a release trips over it). Measured on PR #1068, August 29, 2026.
#
# Asked HERE, before step 1, because this is the last moment at which refusing costs nothing: no gate has
# run, nothing is pushed, no PR exists and nothing is merged. The check itself proves nothing about the
# CI wait that follows -- another session can take 'main' while step 3 watches -- which is why step 5's
# in-place arm now carries the full hand-fold instruction as well. This one turns the common case from a
# half-state into a refusal; that one keeps the rare case readable.
#
# NEITHER ARM TAKES 'main' AWAY FROM ANYBODY, and that restraint is deliberate: the holder may be a lane
# with work in it, and this script does not know what. It names the directory and the two commands that
# release it.
#
# IT ALSO ANSWERS THE SECOND HALF OF #1069, at the end of step 5: whether THIS tree is the primary
# checkout. Read here rather than there because it is the same porcelain, and because an unreadable list
# has to fall back to "primary" -- which is the behaviour every run had before this change.
$shipTreeIsPrimary = $true
$wtList = Invoke-NativeCapture -FilePath 'git' -Arguments @('worktree', 'list', '--porcelain')
if ($wtList.ExitCode -eq 0) {
    $primaryRoot = Get-PrimaryWorktreePath -PorcelainLines $wtList.Output
    if ($primaryRoot) {
        $shipTreeIsPrimary = (Get-WorktreePathKey $primaryRoot) -eq (Get-WorktreePathKey $repoRoot)
    }
    $trunkHolder = Get-WorktreeHoldingBranch -PorcelainLines $wtList.Output -Branch 'main' -SelfPath $repoRoot
    if ($trunkHolder) {
        Write-Error @"
'main' is checked out in ANOTHER worktree, so step 5 could not fold after the merge:

  $trunkHolder

Nothing has been pushed or merged -- this is the cheap place to stop. Release the trunk there first,
then run ship-pr again. If that worktree is a finished lane, hand it back:

  powershell -NoProfile -File "scripts\task\worktree-lane.ps1" -HandBack -Lane "$trunkHolder"

If it is a checkout you still want, move it off the trunk yourself (git -C "$trunkHolder" checkout <its branch>).
"@
        exit 1
    }
} else {
    # BEST-EFFORT, never a refusal: an unreadable worktree list says something about git, not about the
    # trunk, and this script has to keep working in a clone that has never had a second worktree.
    Write-Warning "could not read 'git worktree list' -- shipping anyway; step 5 will report it if 'main' turns out to be held elsewhere."
}

# --- Step 1: open the PR (open-pr.ps1 runs the lint + test gate, pushes, opens) ------------------
# -Title is forwarded ONLY when one was given (#506): passing an empty string would make open-pr warn
# about an ignored title on every ordinary run, which is how a warning stops being read.
$openArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'open-pr.ps1'))
if ($Title) { $openArgs += @('-Title', $Title) }
if ($SkipLint)    { $openArgs += '-SkipLint' }
if ($SkipTests)   { $openArgs += '-SkipTests' }
if ($Force)       { $openArgs += '-Force' }
if ($RefreshBody) { $openArgs += '-RefreshBody' }
# Handed over as the raw string. open-pr.ps1 parses it itself precisely BECAUSE this hop goes through
# `powershell -File`, where an [int[]] parameter would silently collapse '331,332' into 331332.
if ($Resolves) { $openArgs += @('-Resolves', $Resolves) }
if ($NoResolves) { $openArgs += '-NoResolves' }
Write-Host "ship-pr: opening the PR..." -ForegroundColor Cyan
& powershell @openArgs
if ($LASTEXITCODE -ne 0) { Write-Error "open-pr failed -- ship-pr stops (nothing merged)."; exit 1 }

if ($NoMerge) {
    Write-Host "ship-pr: -NoMerge set -- PR opened, stopping before the CI wait/merge/fold." -ForegroundColor Green
    exit 0
}

# --- Step 2: find the PR number for this branch --------------------------------------------------
# Parsed by Get-ExistingPrRecord (pr-issues-lib), the same tested function step 1 uses, because THIS
# STEP WAS IN THE 5.1 PITFALL ITSELF -- measured August 4, 2026 while making step 1 resumable:
#
#   $prs = @($prList.Output | ConvertFrom-Json)   # $prs.Count is ALWAYS 1, even for '[]'
#   $pr  = $prs[0].number                         # $prs[0] is the whole Object[], not a record
#
# `@(<text> | ConvertFrom-Json)` collects the parsed array as ONE pipeline element, so the count guard
# below could never fire -- it was dead code -- and `.number` on that element worked only by member
# enumeration. With no open PR that yields the EMPTY STRING rather than nothing, and the script then
# ran `gh pr checks ''` and `gh pr merge ''`. Nothing in the output would have said which PR was being
# merged, in the one script that writes to main. Now: $null means no PR, and the guard is real.
#
# --base main for the reason spelled out in open-pr.ps1's lookup: without it a consumer's stacked PR
# (branch -> branch) could be the one that gets merged, into its intermediate base.
$prList = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--head', $branch, '--base', 'main', '--state', 'open', '--json', 'number', '--limit', '1', '--repo', $repo) -DiscardStderr
if ($prList.ExitCode -ne 0) { Write-Error "Could not list the PR for '$branch' (is gh logged in?)."; exit 1 }
$prRecord = Get-ExistingPrRecord -Json ($prList.Output -join "`n")
if ($null -eq $prRecord) { Write-Error "No open PR to main found for '$branch' after open-pr -- stopping."; exit 1 }
$pr = $prRecord.number
Write-Host "ship-pr: PR #$pr opened for '$branch'." -ForegroundColor Green

# --- Step 2b: give the trunk back BEFORE the wait (issue #1073) -----------------------------------
# THE RULE THIS EXISTS FOR IS NOT IN A SCRIPT, IT IS IN THE ORCHESTRATOR'S BODY, and it said two things
# that a backgrounded ship could not both satisfy. "Parking is a state, not a promise to come back
# within the turn" makes an in-flight ship a FINISHED assignment; "it ends on the trunk, which is what
# makes the session safe to clear" makes a checkout still standing on the branch an unfinished one. A
# parked branch composes them (push, checkout, stop). A backgrounded ship could not: HEAD did not move
# until step 5, after the CI wait, so at the moment the close-out was written the tree was necessarily
# still on the branch. Dave, August 29, 2026, after being handed a session he could not act on: "ik wil
# pas een sessie sluiten als ik terug op de main branch ben."
#
# THE FIX IS THREE LINES BECAUSE TWO EARLIER ONES DID THE WORK. Since #970 both merge gates read
# refs/heads/<branch> instead of the working copy, and since #972 step 5 reads HEAD before it moves
# anything. Read together they say something neither one set out to: NOTHING BELOW THIS POINT READS THE
# CONTENT OF THE WORKING TREE. Step 3 is gh over the network, step 4 is the ref plus gh, step 5 folds
# wherever HEAD already is -- and 'main' is one of the two arms it has always had. So the trunk can be
# handed back here, and step 5 then takes that arm on purpose rather than by luck.
#
# WHY HERE AND NOT ONE LINE EARLIER: the PR must exist first. If step 1 or step 2 fails, the session is
# left on its branch with the work in front of it, which is where a repair happens. Moving HEAD before
# there is anything to come back to would be trading a real state for a tidy one.
#
# THE THREE CONDITIONS ARE IN Get-TrunkReturnDecision, tested, and its header carries what each one
# costs if skipped. What is decided HERE is only what to do with the answer, and the answer is never a
# refusal: no gate has been failed, and a tree that cannot go home is a tree that stays where it is.
# THE REASON IS PRINTED EITHER WAY -- a session told "still on the branch" has to know whether that was
# a decision or a failure, and the difference is exactly what the reader cannot see from HEAD alone.
$statusRead = Invoke-NativeCapture -FilePath 'git' -Arguments @('status', '--porcelain')
$statusLines = if ($statusRead.ExitCode -eq 0) { @($statusRead.Output) } else { @('?? <unreadable>') }
$wtNow = Invoke-NativeCapture -FilePath 'git' -Arguments @('worktree', 'list', '--porcelain')
$trunkReturn = if ($wtNow.ExitCode -eq 0) {
    Get-TrunkReturnDecision -PorcelainLines $wtNow.Output -SelfPath $repoRoot -TrunkBranch 'main' -StatusLines $statusLines
} else {
    # SAME BEST-EFFORT POSTURE AS STEP 0, and for the same reason: an unreadable worktree list says
    # something about git, not about the trunk. The safe default here is the behaviour every run had
    # before this step existed -- stay on the branch and let step 5 decide.
    [pscustomobject]@{ Return = $false; Reason = "'git worktree list' could not be read" }
}
if ($trunkReturn.Return) {
    $back = Invoke-NativeCapture -FilePath 'git' -Arguments @('checkout', 'main')
    if ($back.ExitCode -eq 0) {
        # NOT FAST-FORWARDED HERE, DELIBERATELY. Step 5 fetches and does an explicit ff-only merge of
        # origin/main after the merge lands, which is when there is something to fast-forward TO. Doing
        # it twice would only widen the window in which this tree is ahead of what the PR merged into.
        Write-Host "ship-pr: this checkout is back on 'main' -- the ship runs on PR #$pr from here." -ForegroundColor Green
    } else {
        # NOT FATAL: nothing is merged, the branch is pushed, and step 5 reads HEAD for itself. The one
        # thing that would be wrong is stopping a ship over a checkout that was a convenience.
        $back.Output | ForEach-Object { Write-Host $_ -ForegroundColor DarkYellow }
        Write-Host "ship-pr: could not check out 'main' -- staying on '$branch'; step 5 will fold from here as before." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "ship-pr: staying on '$branch' -- $($trunkReturn.Reason)." -ForegroundColor DarkGray
}

# --- Step 3: wait for the required CI check ------------------------------------------------------
# The CI checks can lag a few seconds behind the push: `gh pr checks` prints "no checks reported"
# and exits 0 while none are registered yet -- indistinguishable by exit code from "all passed", so
# a bare --watch could return immediately and let the merge below run straight into a BLOCKED wall.
# First poll (on the TEXT, not the exit code) until at least one check is registered, then --watch it.
# Deliberately does NOT name a check: this step watches whatever checks the PR has and reads the exit
# code, so naming one here would be a claim about the consumer's CI that this script cannot keep.
#
# WHAT IT DOES SAY, once the watch is over, is which check actually held it up (#831). The wait used to
# be invisible -- the run printed gh's own table and nothing about the ordering, so learning which check
# governed meant opening the Actions page afterwards. That invisibility is how two observations, both
# out of the tail, became a policy question about whether to wait on non-required checks at all.
# Measured over n=100 paired runs in this repo, the non-required check governs 23% of the time at a
# median cost of 0s, so THE WAIT IS LEFT EXACTLY AS IT IS and made legible instead (Dave,
# August 24, 2026). The report still names no check of its own: the governing one is whichever finished
# last, and 'required' comes from the repo's own ruleset via `gh pr checks --required`.
#
# AND WHAT IT SAYS BEFORE THE WATCH IS THAT NOBODY HAS TO SIT HERE (Dave, issue #985, August 27, 2026).
# The wait is real -- 11m48s of `lint-en-tests` on PR #980, against a local run of the same suites minutes
# earlier at 292s -- and it is not buying a first look at the result, it is buying a second one. The merge
# still cannot move before the check is green, so what changes is who holds the session open, not the wait:
# background this run and the ~12 minutes cost nothing.
#
# THE LANE IS PRINTED BESIDE THE INVITATION, AND IT IS NOW ADVICE RATHER THAN A CONDITION. It was a
# condition when this was written: step 5 ran `git checkout main` in THIS tree, so a session that
# backgrounded the ship and then started the next piece of work in the same checkout had HEAD pulled out
# from under it mid-branch. Issue #972 measured that and step 5 now reads HEAD before it moves anything, so
# the hazard is gone -- what is left is the reason the lane was the right answer anyway, measured on
# August 23, 2026: the worktree is where you build, the primary checkout is where you ship. Named here
# rather than left to the docs, because this is the one moment the reader is about to need it.
#
# AND SINCE #1073 THE SECOND LINE SAYS WHERE THE TREE ALREADY IS RATHER THAN THAT IT WILL BE LEFT ALONE.
# Step 2b has just put the primary checkout back on the trunk, which is the state the orchestrator calls
# safe to clear -- so the reader who backgrounds this run is not being asked to accept a tree standing
# mid-flight, and the close-out that follows can say both things at once. Where step 2b declined, it said
# why on the line above this one; the invitation is the same either way, because the wait is somebody
# else's clock whichever branch this tree is on.
#
# A LINE AND NOT A MECHANISM, deliberately. Three shapes were on the table and this is the smallest: a
# green-and-unmerged reporter would re-add half of what #984 had deliberately removed five minutes before
# #985 was filed, and a detached watcher would merge and fold onto the trunk with nobody reading the output.
# The gates at step 4 already read refs/heads/<branch> for exactly this shape (#970), so the hand-off needed
# permission and a reminder rather than machinery -- and #972 then closed the one place that still wrote.
$waitBegan = Get-Date
Write-Host "ship-pr: waiting for the CI check(s) on PR #$pr..." -ForegroundColor Cyan
Write-Host "  Nothing here needs the session -- background this run and the wait costs nothing." -ForegroundColor DarkGray
Write-Host "  Step 2b has already put this tree where a finished chain leaves it, so the close-out is honest (#1073)." -ForegroundColor DarkGray
Write-Host "  The next piece of work still belongs in a lane: scripts\task\worktree-lane.ps1 -Name <name>" -ForegroundColor DarkGray
$maxWaitSec = 180
$waited = 0
while ($true) {
    $probe = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'checks', "$pr", '--repo', $repo)
    if (($probe.Output | Out-String) -notmatch 'no checks reported') { break }
    if ($waited -ge $maxWaitSec) {
        Write-Error "No CI check registered for PR #$pr after ${maxWaitSec}s -- NOT merged. Check the workflow, or merge manually once it is green."
        exit 1
    }
    Write-Host "  (no check registered yet -- waited ${waited}s/${maxWaitSec}s)" -ForegroundColor DarkYellow
    Start-Sleep -Seconds $PollSeconds
    $waited += $PollSeconds
}
# --watch now blocks until the registered check finishes; exit 0 = all passed, non-zero = SOMETHING
# failed. WHICH something is the whole question, and the answer is NOT in that exit code (#943). This
# line used to read "branch protection blocks the merge until green, so a non-zero here means we must
# NOT merge" -- true only of a check the ruleset REQUIRES. `gh pr checks --watch` exits non-zero when
# ANY check fails, so the script inferred "the merge is blocked" from a signal that does not say so,
# and on August 26, 2026 that inference was the whole chain: `claude-review` red on every PR (#942),
# `lint-en-tests` -- the only check the `main` ruleset requires -- green, GitHub itself reporting those
# PRs as MERGEABLE / UNSTABLE, and this script reporting BLOCKED. The wait is untouched (#831 measured
# it and Dave kept it); only the verdict below moved.
$checks = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'checks', "$pr", '--watch', '--interval', "$PollSeconds", '--repo', $repo)
$checks.Output | ForEach-Object { Write-Host $_ }
$waitedSec = [int][math]::Round(((Get-Date) - $waitBegan).TotalSeconds)

# ONE pair of reads, serving both remaining questions: which check governed the wait (#831, the line
# printed further down) and, on a failure, whether what failed is a check the ruleset requires (#943,
# the merge decision). Measured while writing this: `gh pr checks --json` returns exit 0 while
# reporting a failing check in its payload, so the STATE has to be read from the records -- which is
# why both reads ask for `bucket,state` and neither trusts its own exit code for the outcome.
#
# Still best-effort, and the invariant that mattered survives: an unreadable payload cannot turn a
# GREEN run red, because a green watch never consults the verdict at all. What it can do is leave a
# failing run refusing exactly as it did before this change -- Get-MergeBlockVerdict blocks on an
# unreadable required-check list rather than guessing, which is the conservative half of the fix.
# They no longer sit after the decision, because they are now part of it: a failing run that spends
# two gh calls is spending them on the verdict, not on a line nobody will read.
$checkFactsJson = ''
$requiredFactsJson = ''
try {
    # `link` rides along for inbound #1044: it is the only field in this payload that names the
    # Actions RUN behind a check, and the fact separating "the job never started" from "a check went
    # red" lives on the run rather than on the check. It costs nothing on a green run -- the block
    # that reads it is inside the refusal below.
    $checkFacts = Invoke-NativeCapture -FilePath 'gh' -Arguments @(
        'pr', 'checks', "$pr", '--json', 'name,bucket,state,startedAt,completedAt,link', '--repo', $repo)
    if ($checkFacts.ExitCode -eq 0) { $checkFactsJson = $checkFacts.Output -join "`n" }
    # `--required` exits non-zero on a repo whose ruleset requires nothing, which is a legitimate state
    # and not an error. For the wait report the label is then simply omitted rather than guessed; for
    # the verdict it is the case that keeps refusing, since "requires nothing" and "the required checks
    # have not reported" are indistinguishable from here.
    $requiredFacts = Invoke-NativeCapture -FilePath 'gh' -Arguments @(
        'pr', 'checks', "$pr", '--required', '--json', 'name,bucket,state', '--repo', $repo)
    if ($requiredFacts.ExitCode -eq 0) { $requiredFactsJson = $requiredFacts.Output -join "`n" }
} catch {
    $checkFactsJson = ''
    $requiredFactsJson = ''
}

if ($checks.ExitCode -ne 0) {
    $verdict = Get-MergeBlockVerdict -RequiredChecksJson $requiredFactsJson -ChecksJson $checkFactsJson
    if ($verdict.Blocked) {
        # WHICH REFUSAL THIS IS -- inbound #1044. The verdict is unchanged and stays unchanged: this
        # cannot let a merge through, it only decides which sentence the operator reads. A run that
        # never STARTED (an account payment failed, a spending limit reached, no runner available)
        # reports as a plain check failure through `gh pr checks`, and "Fix CI and re-run" then sends
        # the reader into their own code for a state no branch can repair. Measured August 28, 2026 in
        # a consumer repo, where it cost a hand-merge.
        #
        # Best-effort by construction. Every read is guarded and every failure degrades to the wording
        # that was already there -- a diagnostic must never be the reason a refusal cannot be printed.
        $stalled = @()
        try {
            foreach ($runId in @(Get-FailedCheckRunIds -ChecksJson $checkFactsJson)) {
                # -DiscardStderr because this output is PARSED: a gh warning merged into it would
                # break the parse and cost the note. Nothing here reads a job NAME, only counts and
                # the run's own URL, so the console code page cannot change the answer and -Utf8
                # would buy nothing.
                $runFacts = Invoke-NativeCapture -FilePath 'gh' -DiscardStderr -Arguments @(
                    'run', 'view', "$runId", '--json', 'conclusion,status,url,jobs', '--repo', $repo)
                if ($runFacts.ExitCode -ne 0) { continue }
                $note = Get-StalledRunNote -RunJson ($runFacts.Output -join "`n") -RunId $runId
                if ($note) { $stalled += $note }
            }
        } catch {
            $stalled = @()
        }

        if ($stalled.Count -gt 0) {
            Write-Error "CI never RAN for PR #$pr -- NOT merged: $($verdict.Reason). $($stalled -join ' ')"
        } else {
            Write-Error "CI did not pass for PR #$pr (exit $($checks.ExitCode)) -- NOT merged: $($verdict.Reason). Fix CI and re-run, or merge manually once green."
        }
        exit 1
    }
    # Loud, and deliberately not reassuring. The merge is allowed to proceed because the ruleset says
    # so, and that is the only claim being made here -- the red mark is still red and still worth
    # chasing. Printed as a warning rather than swallowed, so a run that merged past a failing check
    # says which check, in the transcript, where the next reader looks.
    Write-Host "ship-pr: a check FAILED but the merge is not blocked -- $($verdict.Reason)." -ForegroundColor Yellow
    Write-Host "  Continuing to step 4. The failing check is still failing; nothing here fixes it." -ForegroundColor Yellow
} else {
    Write-Host "ship-pr: CI green." -ForegroundColor Green
}

$waitReport = $null
if ($checkFactsJson) {
    $waitReport = Get-CheckWaitReport -ChecksJson $checkFactsJson `
        -RequiredNamesJson $requiredFactsJson -WaitedSeconds $waitedSec
}
if ($waitReport) {
    Write-Host "  $waitReport" -ForegroundColor DarkGray
} else {
    Write-Host "  waited $(Format-CheckDuration -Seconds $waitedSec) -- which check governed could not be read" -ForegroundColor DarkGray
}

# --- Step 4: merge (no --admin: never bypass the CI gate) ----------------------------------------
#
# THE STEP-LIST GATE FIRES AGAIN HERE, and that is not belt-and-braces. Dave's requirement is about the
# MERGE -- "pas als alle punten zijn afgevinkt kan de branch met een PR gemergd worden" -- while step 1's
# copy of it runs in open-pr.ps1, which has a -Force. A PR opened through that escape valve, or opened by
# hand on github.com, or opened days ago and resumed by this script, would otherwise land with an
# unfinished plan: exactly what the requirement asks to be impossible. Checked here rather than passed
# down from step 1, because the working copy may have changed since.
#
# READ FROM THE SHIPPING BRANCH'S OWN COMMIT, NOT FROM THE WORKING TREE (issue #970, August 27, 2026).
# Both gates below used to read $repoRoot's copy, on the reasoning that "HEAD is still on the branch at this
# point -- step 5 is what moves to main". That holds for a foreground run and fails for the shape this
# script invites: it waits on CI -- 10m57s on the run that produced the report -- and a session that
# backgrounds the ship and starts the next piece of work has moved the checkout while it waits. Measured
# then: this gate refused PR #969 over "- [ ] TODO: the first step of this branch", the verbatim scaffold
# TODO of a branch created during the wait, while PR #969's own document had no open step at all.
#
# THAT INSTANCE FAILED SAFE AND THE INVERSE IS WHY IT IS REPAIRED. Reverse the two documents -- the shipping
# PR carries an unresolved step, the checkout has since moved to a branch whose steps are all ticked -- and
# the gate PASSES on someone else's document and merges. A gate with no -Force satisfied by a file the PR
# does not contain is worse than no gate: it reports the requirement as met while nothing checked it.
#
# refs/heads/$branch, AND IT IS PROVABLY WHAT THE MERGE MERGES. $branch is HEAD as read at the top of this
# run, and step 1's open-pr.ps1 pushes that branch before this point on every path through here -- a fresh
# PR and a resumed one alike -- so the local tip and the PR's head commit are the same commit. A gh read of
# headRefOid would say the same thing over the network, in a gate that must not refuse because a token
# expired. The full ref name rather than the bare branch: `git show` resolves its left half as a rev, and a
# name that also names a directory is otherwise ambiguous.
#
# NOT "REFUSE WHEN HEAD HAS MOVED", the other shape on the table. The report names a backgrounded ship
# beside the next piece of work as the ordinary shape of that window, so refusing on it would break the
# ordinary case in order to protect it. Nothing downstream needs the checkout to have stayed put either:
# step 5 checks out main and folds from there, whichever branch it was standing on.
#
# THE READ ALSO CLOSES A SECOND HOLE, unreported and smaller: a step ticked in the editor and never
# committed used to satisfy this gate while the PR still carried it unresolved. Both messages below already
# say "commit, and re-run", so this is the gate catching up with what it asks for.
#
# THE PATH IS RESOLVED THROUGH THE SAME READER, which is the half that is easy to get wrong.
# Resolve-BranchFilePath chooses between seven candidate names by READING each one, so resolving against the
# working tree and then reading the answer out of the commit would keep the very mismatch this repairs --
# and it would fail silently: the resolver names a path this branch does not carry, the read comes back
# $null, and the gate reads that as "no document". An absent document is still no finding, the same
# tolerance open-pr.ps1 applies and for the same reason.
#
# AND THE READER'S OWN VARIABLES CARRY THIS SCRIPT'S PREFIX, WHICH IS NOT COSMETIC. A plain scriptblock
# resolves its variables DYNAMICALLY at the point it is invoked -- inside Resolve-BranchFilePath -- so any
# name it uses that the resolver also has as a local resolves to the RESOLVER's, and PowerShell names are
# case-insensitive. `$repoRoot` inside this block would therefore be the resolver's own unbound $RepoRoot
# parameter: empty, silently, on the very arm that does not take it. $shipCycleRoot collides with nothing.
$shipCycleRef  = "refs/heads/$branch"
$shipCycleRoot = $repoRoot
$shipCycleRead = {
    param([string]$Rel)
    Get-GitFileTextAtRef -Ref $shipCycleRef -Path $Rel -RepoRoot $shipCycleRoot
}
$shipProgressRel  = Resolve-BranchFilePath -Kind Cycle -Reader $shipCycleRead
$shipCycleText    = & $shipCycleRead $shipProgressRel
if ($null -ne $shipCycleText) {
    $shipSteps = @(Get-BranchProgressFindings -Text $shipCycleText)
    if ($shipSteps.Count -gt 0) {
        # THE REMEDY COMES WITH THE FINDING, same as open-pr's copy of this gate and for the same measured
        # reason (inbound #1081): the marks resolve an OPEN step and resolve nothing at all for a line that
        # still carries the scaffolder's text, so offering them to both labels sent an author round the
        # same refusal twice.
        $shipDetail = ($shipSteps | ForEach-Object { "  - $($_.Label): $($_.Line)`n      $($_.Remedy)" }) -join "`n"
        Write-Error @"
step-list gate: $shipProgressRel at $shipCycleRef still has unresolved steps - PR #$pr is NOT merged.

$shipDetail

Each finding above says what resolves it. Commit, and re-run. CI has already passed, so a re-run picks
up from here. There is no -Force for this gate.
"@
        exit 1
    }
}

# THE DEPLOY LOCK FIRES HERE, BESIDE THE STEP-LIST GATE AND FOR THE SAME REASON (Dave, issue #884,
# August 25, 2026). The section is fixed at the moment the PR opens: after that the document may not
# diverge from what the PR published, because the PR body is what reviewers approved and the fold in step 5
# is what turns the document into CHANGELOG.md. Without this, an edit made after the review lands in the
# changelog and the release notes having been seen by nobody -- and it lands SILENTLY, because the fold
# removes the document at the merge, so the place a reviewer would compare is the one place it no longer is.
#
# THE MERGE IS THE RIGHT PLACE, not the push. open-pr writes the section into the body, so at push time
# there is nothing to have diverged yet; the window this closes opens the instant the PR exists and shuts
# here. It is also the only point both escape routes pass through -- open-pr has a -Force, and a PR opened
# by hand on github.com never ran it at all.
#
# READ FROM THE SHIPPING BRANCH'S OWN COMMIT -- the same $shipCycleText the step-list gate above judged,
# for the reasons written out there (issue #970). This side of the comparison matters even more than that
# one: the document is what step 5 folds verbatim into CHANGELOG.md, so a lock satisfied by a stray
# checkout's document would be approving the fold of a section it never read.
# An unreadable body is NOT a finding: gh failing here says something about the network or the token, not
# about the section, and a gate that refuses a merge over that would be refusing on no evidence. The
# comparison itself is Test-DeployLock in pr-body-lib, the same function the CI gate calls, so "diverged"
# has one definition rather than two.
if ($null -ne $shipCycleText) {
    # -Utf8 IS LOAD-BEARING HERE (issue #907): the other side of this comparison is read with an
    # explicit UTF-8 decode one line below, and without it this side would be decoded with the console
    # code page instead -- so on cp850 an em-dash in the section came back as three characters and the
    # lock refused a PR whose body was intact.
    $lockView = Invoke-NativeCapture -Utf8 -FilePath 'gh' -Arguments @(
        'pr', 'view', "$pr", '--json', 'body', '--repo', $repo)
    if ($lockView.ExitCode -eq 0) {
        $lockBody = ''
        try {
            $lockBody = [string](($lockView.Output -join "`n") | ConvertFrom-Json).body
        } catch {
            $lockBody = ''
        }
        $lockEntry = Get-DevelopmentEntryText -Text $shipCycleText
        $lock = Test-DeployLock -EntryText $lockEntry -PrBody $lockBody
        if ($lock.Applicable -and -not $lock.Locked) {
            $lockDrift = if ($lock.FirstDrift -eq $lock.Heading) {
                "the body does not carry the section at all -- its heading '$($lock.Heading)' is not in it"
            } else {
                "the first line the body does not have is:`n    $($lock.FirstDrift)"
            }
            Write-Error @"
DEPLOY lock: $shipProgressRel at $shipCycleRef has changed since PR #$pr was opened - it is NOT merged.

$lockDrift

The DEPLOY section is fixed when the PR opens: it is what the review approved, and step 5 folds it
verbatim into CHANGELOG.md and from there into the release notes. Choose one:

  - put the section back to what PR #$pr published, commit, and re-run; or
  - deliberately republish it -- open-pr.ps1 -RefreshBody rewrites the PR body from the document, so
    the change is reviewable where the review happens, and then re-run.

CI has already passed, so a re-run picks up from here. There is no -Force for this gate.
"@
            exit 1
        }
    } else {
        Write-Host "  DEPLOY lock: PR #$pr's body could not be read -- not checked (this is not a finding)." -ForegroundColor DarkGray
    }
}

# THE MERGE COMMIT GETS A TYPED SUBJECT (Dave, August 7, 2026). GitHub's default is
# "Merge pull request #504 from Owner/feat/x", which is the one line in the graph that does not start with
# a type. Everything else does -- feat:, fix:, docs:, fold:, release: -- so scanning the history means
# reading one shape for every commit except the merges, which are half of them.
#
# 'merge: <branch> (#NN)' is the shape, and it matches the fold's own subject one commit later
# ("fold: <branch> changelog (#NN)") field for field -- type, subject, PR number in brackets. A merge
# and its fold read as a pair. That pairing is why the fold kept its PR number when it was renamed from
# 'chore:' to 'fold:' on August 10, 2026, over the shorter form that dropped it.
#
# THE FORMAT WAS INVENTED TWICE ON THE SAME DAY, WHICH IS WHY IT IS WRITTEN DOWN HERE. Derek's lens has
# prescribed 'merge: <branch> (#<PR-number>)' since ba7081e; the first version of this line shipped
# 'merge: PR #NN <branch>' instead, because the lens was not checked before the shape was chosen. Two
# formats for one line is the exact defect this repo spent August 7 removing elsewhere, introduced here by
# the change that removed it there. The older, already-documented one wins -- it is the one that matches
# its neighbour.
#
# SAFE TO CHANGE, CHECKED RATHER THAN ASSUMED: nothing in this repo parses the merge subject -- not a
# script, not a gate, not a document. The PR number stays in the line for anyone who greps for it.
#
# -t is the short form of --subject. This line used to add "and applies to the merge-commit method only;
# a repo configured for squash or rebase has no merge commit for it to name, and gh ignores it there" --
# and that second half was never checked. `gh pr merge --help` documents -t as "Subject text for the merge
# commit" with NO method restriction, and GitHub's merge endpoint takes commit_title for a squash as well,
# so the likelier behaviour is that a squash consumer's squashed commit gets titled 'merge: <branch> (#NN)'
# -- a type label that is wrong for a commit which is the change rather than a merge of it.
#
# NOT REPAIRED HERE, DELIBERATELY. It cannot be reproduced from this repo, which merges, so a fix would be
# built on the same unverified reading that produced the retired sentence. What is corrected is the claim:
# the flag's scope is unknown for squash, and known-harmless for merge. Measure it in a squash-configured
# repo before changing anything.
$mergeSubject = "merge: $branch (#$pr)"
$merge = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'merge', "$pr", "--$mergeMethod", '--subject', $mergeSubject, '--repo', $repo)
$merge.Output | ForEach-Object { Write-Host $_ }
if ($merge.ExitCode -ne 0) { Write-Error "Merge of PR #$pr failed."; exit 1 }
Write-Host "ship-pr: PR #$pr merged (--$mergeMethod)." -ForegroundColor Green

# --- Step 5: main + fold + commit + push ---------------------------------------------------------
#
# WHERE HEAD IS, READ BEFORE ANYTHING MOVES (Dave, issue #972, August 27, 2026). This step used to run
# `git checkout main` unconditionally one line after the merge, on the reasoning that HEAD is still on the
# shipping branch by now. That holds for a foreground run and fails for the shape this script INVITES:
# step 3 tells the reader to background the wait, and a session that then works in the same checkout has
# moved HEAD while CI ran. Measured on git 2.54.0.windows.1, that unconditional line has exactly two
# outcomes and both are defects:
#
#   - THE SESSION'S UNCOMMITTED EDIT COLLIDES with main -> `git checkout main` exits 1 with "Your local
#     changes to the following files would be overwritten by checkout", HEAD stays put, and this script
#     exits between the merge and the fold. That is precisely the state the comment further down calls
#     the one nothing reports: the PR merged, the branch document still in the tree, every gate green
#     until a release trips over it.
#   - IT DOES NOT COLLIDE -> exit 0, HEAD moves to main, AND THE UNCOMMITTED WORK TRAVELS WITH IT. The
#     session is then editing on the trunk with its own work already sitting there, which is the trap
#     Chris's lens measured on August 10, 2026 with a background task pulling the rug rather than a
#     previous chain having left you there.
#
# SO THE TREE THE FOLD RUNS IN IS CHOSEN RATHER THAN ASSUMED. HEAD still on the shipping branch -- the
# foreground run, and the lane discipline the ship-pr skill page made the default -- or already on main:
# nothing about this step changes, down to the command it runs. HEAD anywhere else (another branch, or
# detached, which reads as 'HEAD'): the session moved, its checkout is not this script's to touch, and
# the fold runs in a throwaway worktree instead.
#
# 'ALREADY ON main' IS NOW THE ORDINARY ARM RATHER THAN THE ODD ONE (issue #1073). Step 2b puts the
# primary checkout back on the trunk as soon as the PR exists, so on a normal run this `git checkout
# main` is a no-op that the script takes on purpose. Nothing here needed changing for that -- the arm
# has existed since #972 -- and it is written down because the reverse reads as a defect: a reader who
# meets `-eq 'main'` and knows only the foreground story will think it is unreachable.
#
# THE WORKTREE HAS main CHECKED OUT RATHER THAN BEING DETACHED, AND THAT IS FORCED BY TWO MEASUREMENTS.
# Detached, fold-changelog-entry.ps1's `git push` fails with "fatal: You are not currently on a branch"
# (exit 128) and would need a HEAD:main push written into a script this change has no business touching.
# Attached, git refuses the add outright once the primary holds main -- which is why HEAD -eq 'main' folds
# in place above rather than reaching for a worktree it provably cannot have.
#
# IT IS NOT THE ALTERNATIVE worktree-lane.ps1 DECLINED, and that has to be said here because that script
# says the opposite in as many words. Its declined shape was "fold via whichever worktree HOLDS main", to
# spare a lane its two hand-back commands: a convenience, weighed against "a change to the single line
# that produces the state nothing reports", and rightly declined on that trade. This one adds a tree of
# its own instead of borrowing a lane's, fires only where that single line was ALREADY producing that
# state, and buys correctness rather than two commands. The decline stands; it is about the other thing.
#
# OUTSIDE THE REPO, for worktree-lane.ps1's own measured reason: a worktree inside the tree is walked by
# the lint gate's link scan and by the test suites, which then report a second copy of the whole repo as
# findings. A ship is not linting, but a folder left behind by a crashed run outlives the run, and the
# next gate is what would meet it.
# THE TAKE-DOWN IS A FUNCTION BECAUSE THREE EXIT PATHS OWE IT, not because it reads better. A failed
# fetch, a failed ff-only merge and the fold itself all leave this step, and an `exit 1` that skips the
# removal leaves a worktree holding main -- so the NEXT ship's `git checkout main` fails on a directory
# nobody remembers creating. Declared before the paths that call it, which is what PowerShell requires.
function Remove-ShipFoldWorktree {
    param([string]$Path)
    if (-not $Path) { return }
    $rm = Invoke-NativeCapture -FilePath 'git' -Arguments @('worktree', 'remove', $Path)
    if ($rm.ExitCode -eq 0) { return }
    # A NON-ZERO EXIT HERE DOES NOT MEAN NOTHING HAPPENED -- worktree-lane.ps1 measured that on the
    # Permission-denied case: git had already emptied the tree AND deregistered the worktree, and failed
    # only on deleting the now-empty directory. Reporting "still registered" there would send someone
    # hunting a worktree that is, for every purpose that matters, already gone. So ask git what it thinks
    # now instead of inferring from the exit code.
    $rm.Output | ForEach-Object { Write-Host $_ -ForegroundColor DarkYellow }
    $list = Invoke-NativeCapture -FilePath 'git' -Arguments @('worktree', 'list', '--porcelain')
    $wanted = $Path.Replace('/', '\').TrimEnd('\')
    $stillRegistered = $false
    if ($list.ExitCode -eq 0) {
        $stillRegistered = [bool](@($list.Output |
            Where-Object { $_ -match '^worktree\s+(.+)$' } |
            ForEach-Object { ($_ -replace '^worktree\s+', '').Trim().Replace('/', '\').TrimEnd('\') } |
            Where-Object { $_ -ieq $wanted }))
    }
    if ($stillRegistered) {
        Write-Host "ship-pr: the fold worktree is STILL REGISTERED and still holds main -- the next ship will fail on it." -ForegroundColor Red
        Write-Host "  Remove it: git worktree remove $Path" -ForegroundColor Red
    } else {
        Write-Host "ship-pr: the fold worktree is deregistered; only an empty folder is left behind: $Path" -ForegroundColor DarkYellow
    }
}

$foldTree = $null
$headRead = Invoke-NativeCapture -FilePath 'git' -Arguments @('rev-parse', '--abbrev-ref', 'HEAD')
$headLine = @($headRead.Output | Where-Object { $_ -and "$_".Trim() }) | Select-Object -First 1
# AN UNREADABLE HEAD TAKES THE WORKTREE ROUTE, deliberately. It is the arm that leaves somebody else's
# checkout alone, so being wrong about it costs a temporary directory, while being wrong the other way
# costs the two outcomes above.
$headNow = if ($headRead.ExitCode -eq 0 -and $headLine) { "$headLine".Trim() } else { '' }

if ($headNow -eq $branch -or $headNow -eq 'main') {
    $co = Invoke-NativeCapture -FilePath 'git' -Arguments @('checkout', 'main')
    $co.Output | ForEach-Object { Write-Host $_ }
    # A BARE "git checkout main failed" USED TO BE THE WHOLE MESSAGE HERE, and this is the exact line the
    # merge has already run past -- so it is the one place in the script where a one-line error is most
    # expensive (issue #1069, measured on PR #1068). Step 0 turns the common cause into a refusal before
    # anything is pushed; what reaches here is the narrow window it cannot cover, where another session
    # took 'main' while step 3 watched CI. So say the same thing the worktree arm below says: the state
    # the repo is actually in, and the two commands that finish the job by hand.
    if ($co.ExitCode -ne 0) {
        $foldScript = Join-Path $PSScriptRoot 'fold-changelog-entry.ps1'
        Write-Error @"
PR #$pr IS MERGED but NOT folded -- this tree could not check out main.

git's own reason is above. The usual one is that another worktree took main while the CI wait ran
("fatal: 'main' is already used by worktree at ..."), and this script will not take it away from one.

The PR is merged, the branch document is still in the tree, and every gate stays green until a
release trips over it. Fold from the tree that HOLDS main -- fold-changelog-entry.ps1 has carried
-RepoRoot for exactly this since #101:

  git -C <that worktree> fetch --prune origin; git -C <that worktree> merge --ff-only origin/main
  & "$foldScript" -Branch $branch -RepoRoot <that worktree> -Push

`git worktree list` names it.
"@
        exit 1
    }
} else {
    $foldTree = Join-Path ([System.IO.Path]::GetTempPath()) "ship-pr-fold-$pr-$PID"
    Write-Host "ship-pr: HEAD is on '$headNow', not '$branch' -- this checkout moved while CI ran." -ForegroundColor Yellow
    Write-Host "  Folding in a throwaway worktree instead, so nothing here is touched: $foldTree" -ForegroundColor Yellow
    $wtAdd = Invoke-NativeCapture -FilePath 'git' -Arguments @('worktree', 'add', $foldTree, 'main')
    $wtAdd.Output | ForEach-Object { Write-Host $_ }
    if ($wtAdd.ExitCode -ne 0) {
        $foldScript = Join-Path $PSScriptRoot 'fold-changelog-entry.ps1'
        Write-Error @"
PR #$pr IS MERGED but NOT folded -- no worktree on main could be added at $foldTree.

git's own reason is above. The usual one is that another worktree already has main checked out
("fatal: 'main' is already used by worktree at ..."), and this script will not take it away from one.

The PR is merged, the branch document is still in the tree, and every gate stays green until a
release trips over it. Fold by hand from any tree standing on an up-to-date main:

  git checkout main; git fetch --prune origin; git merge --ff-only origin/main
  & "$foldScript" -Branch $branch -Push
"@
        exit 1
    }
    # GIT'S OWN SPELLING OF THE PATH, not the one composed above. GetTempPath() can hand back an 8.3 short
    # name (%TEMP% under a service account is what does it) while `git worktree list` reports the long one,
    # and the two would then never compare equal -- so the take-down would report a worktree as still
    # registered when git had in fact removed it. Resolved while the directory certainly exists, which is
    # exactly the moment the take-down no longer can.
    $resolved = Resolve-Path -LiteralPath $foldTree -ErrorAction SilentlyContinue
    if ($resolved) { $foldTree = $resolved.ProviderPath }
}
# The tree the rest of this step works in: this checkout, or the throwaway worktree. `-C` on every call
# rather than two copies of the same three commands -- with $foldRoot equal to $repoRoot, which is where
# this script already stands, it is a no-op and the in-place path runs exactly what it ran before.
$foldRoot = if ($foldTree) { $foldTree } else { $repoRoot }

# Fetch + an EXPLICIT ff-only merge of origin/main, not a bare `git pull --ff-only` (lesson of
# July 29, 2026, PR #257). The bare pull aborted with "Cannot fast-forward to multiple branches" on a
# clean main immediately after a merge + prune -- and it aborts HERE, in the one gap between the merge
# and the fold, which is the state nothing reports: the PR is merged, the entry file is still in the
# root, and every gate stays green until a release trips over it. Git raises that error when handed more
# than one ref to merge; naming origin/main explicitly hands it exactly one, so this step cannot reach
# that failure mode, whereas a bare pull depends on whatever FETCH_HEAD happens to hold. Why the pull
# got more than one ref was deliberately not guessed at -- see Derek's lens for that reasoning.
$fetch = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $foldRoot, 'fetch', '--prune', 'origin')
$fetch.Output | ForEach-Object { Write-Host $_ }
if ($fetch.ExitCode -ne 0) { Remove-ShipFoldWorktree -Path $foldTree; Write-Error "git fetch of origin failed."; exit 1 }

$ff = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $foldRoot, 'merge', '--ff-only', 'origin/main')
$ff.Output | ForEach-Object { Write-Host $_ }
if ($ff.ExitCode -ne 0) { Remove-ShipFoldWorktree -Path $foldTree; Write-Error "git merge --ff-only of origin/main failed."; exit 1 }

# The fold, its commit AND its push are all fold-changelog-entry.ps1's job (-Push implies -Commit).
# This used to be a fold followed by `git add -A` + commit + push right here, and that was a real
# defect rather than a duplication: `git add -A` stages the WHOLE tree, so anything else modified or
# already staged was swept into a commit that lands directly on main under a named exception to "never
# commit directly". The fold script commits with an explicit pathspec -- CHANGELOG.md plus the entry
# files it actually folded, and nothing else can enter, whatever is lying around. It also knows which
# of those paths git tracks, so an entry that was never committed does not fail the pathspec after the
# fold has already deleted it.
#
# -Push rather than a separate push here, for the reason that flag exists: a fold commit sitting
# unpushed on main is its own silent half-state, and splitting the commit from the push across two
# scripts is how you get one.
#
# THE FOLD STAYS ITS OWN COMMIT, AND THE REASON IS GIT'S RATHER THAN THIS REPO'S (Dave, August 10, 2026;
# inbound #571). The obvious tidy-up is to fold INTO the merge -- `git merge --no-ff --no-commit <branch>`,
# run the fold without -Commit so it writes to disk only, then one `git commit` -- so a PR leaves one
# commit on main instead of a merge with a `fold: ...` sitting on top of it. The request is
# well-founded on its symptom: measured on August 10, 2026 this repo held 398 merge commits (206 typed
# 'merge: ', 192 older 'Merge pull request') against 410 folds, 394 of which sit directly on a merge in
# first-parent order. They really are one movement written as two commits.
#
# IT IS DECLINED, AND THE DECIDING FACT WAS MEASURED RATHER THAN ARGUED. The pathspec above is not merely
# weakened by that flow -- git refuses to express it at all:
#
#     $ git commit -m "merge: feat/x (#1)" -- CHANGELOG.md contributing-davekjohn/development.md
#     fatal: cannot do a partial commit during a merge.
#
# The only commit git will make while MERGE_HEAD exists is a whole-index one, and in the same test it swept
# an unrelated stray.txt straight into the merge commit -- the exact `git add -A` defect the pathspec was
# introduced to remove. So the guarantee could not move, only be downgraded to a pre-flight "was the
# tree clean before the merge?", which is checked earlier and on different state than the commit it
# protects.
#
# TWO FURTHER COSTS, both real and neither decisive on its own. The merge date loses its provenance: a
# local merge leaves the PR open, so mergedAt is empty and Format-EntryFoldFooter falls back to the clock
# -- the source #469 deliberately moved away from. And the merge stops going through the button, so the
# repo ruleset's required check no longer gates it; CLAUDE.md already records the release commit as the
# least-gated commit in this workflow, and this would extend that to every PR.
#
# WHAT A CONSUMER SHOULD DO INSTEAD: nothing. Two commits per PR is the cost of a fold whose scope git
# enforces, and the typed merge subject above already makes the pair scannable. A repo on squash that wants
# the readable arc should switch to merge on its own merits and accept the trailing fold commit.
Write-Host "ship-pr: folding the changelog entry..." -ForegroundColor Cyan
# -RepoRoot ONLY on the worktree arm. The flag has been there since #101 and its own param comment names
# this exact caller -- "a consumer that runs the fold from a temporary/detached worktree (e.g. a
# ship-pr.ps1 that checks out main elsewhere)" -- so the fold script needed no change for this. It is not
# passed on the in-place arm even though it would resolve to the same directory: that arm is meant to run
# what it always ran, and "unchanged behavior below" is what the fold script promises when it is omitted.
$foldArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', (Join-Path $PSScriptRoot 'fold-changelog-entry.ps1'),
    '-Branch', $branch, '-Push')
if ($foldTree) { $foldArgs += @('-RepoRoot', $foldTree) }
& powershell @foldArgs
$foldExit = $LASTEXITCODE

# AND IT COMES DOWN WHETHER THE FOLD SUCCEEDED OR NOT, before the exit code is judged -- the last of the
# three paths the function above exists for.
Remove-ShipFoldWorktree -Path $foldTree

if ($foldExit -ne 0) { Write-Error "fold-changelog-entry failed -- the fold is NOT committed or NOT pushed. Its own output above says which; do not re-run the fold if it already removed the entry file."; exit 1 }

# --- Step 5b: give the trunk back, if this is not the primary checkout (issue #1069) ---------------
# THE ROOT CAUSE, AND IT IS ONE LINE ABOVE: the in-place arm leaves this tree standing on 'main'. In the
# primary checkout that is deliberate and documented -- a finished chain ends on the trunk, which is what
# makes the session safe to clear. In a LANE it is a global lock: no other worktree can check 'main' out
# from that moment on, nothing warns, and the bill is paid by an unrelated branch after ITS merge. That is
# how PR #1068 was merged and left unfolded.
#
# SO THE RULE IS NOT "always return", IT IS "return where staying was never the point". Only a
# non-primary tree hands the trunk back, and only after a SUCCESSFUL fold: a failed one leaves this tree
# on main mid-repair, which is exactly where whoever finishes it by hand needs to be standing.
#
# BACK TO THE BRANCH RATHER THAN DETACHED, so the lane is where its author left it. Detaching is the
# fallback and not the preference: it always works (nothing can hold a commit) but it hands back a tree
# whose HEAD reads as nothing in particular. Either way the lock is released, which is the part that
# matters to every other worktree on the machine.
if (-not $foldTree -and -not $shipTreeIsPrimary) {
    Write-Host "ship-pr: this is not the primary checkout -- releasing 'main' so other worktrees can use it." -ForegroundColor Cyan
    $back = Invoke-NativeCapture -FilePath 'git' -Arguments @('checkout', $branch)
    if ($back.ExitCode -ne 0) {
        $detach = Invoke-NativeCapture -FilePath 'git' -Arguments @('checkout', '--detach')
        if ($detach.ExitCode -eq 0) {
            Write-Host "  '$branch' could not be checked out here, so this tree is detached instead -- 'main' is free." -ForegroundColor Yellow
        } else {
            # NEVER FAILS THE SHIP. Everything this script was asked to do has happened by now: merged,
            # folded, pushed. What is left is a lock on 'main' that the next run's step 0 will report by
            # name anyway -- so this says it once, here, where it is cheapest to act on.
            Write-Warning "this tree is still on 'main' and is not the primary checkout, so it holds the trunk for the whole clone. Move it off: git -C `"$repoRoot`" checkout $branch"
        }
    }
}

# --- Step 6: the issues the PR declared it closes are actually closed -----------------------------
# Its own script, so this state-MUTATING logic (it comments and closes) is testable against a fake gh
# instead of only reachable through a full live ship -- and so the same check is usable on its own to
# repair bookkeeping after the fact. It never fails the ship: the merge already succeeded.
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verify-resolved-issues.ps1') -Pr $pr -Repo $repo
if ($LASTEXITCODE -ne 0) { Write-Warning "the issue-closing check reported a problem -- verify by hand with: gh issue list --repo $repo --state open" }

Write-Host "Done: PR #$pr shipped -- opened, CI green, merged, folded on main." -ForegroundColor Green

# --- Step 7: the remote branch, if nothing on GitHub is reaping it --------------------------------
# WHY THIS IS A READ AND NOT A FLAG (inbound #815, August 21, 2026). The merge above deliberately does
# NOT pass --delete-branch. The repo setting covers EVERY merge route -- this script, the web UI, another
# machine, another tool -- while the flag covers only the path it is passed on, and two mechanisms for one
# job is precisely the shape that let seven merged branches pile up in July 2026: two documents each named
# a different one and neither was in force. The flag also deletes the LOCAL branch, and on July 16, 2026
# it was measured leaving the checkout ON the merged branch, with the fold then running there.
#
# SO WHAT WAS ACTUALLY MISSING WAS REACH, NOT DOCUMENTATION. Measured on pickup: the setting is named in
# three places in the plugins, one with a paste-ready command -- and all three are setup checklists, read
# once at init, with nothing ever asking again. The reporting consumer had both plugins installed, the
# setting off, and 18 merged branches standing. This says it at the one moment it is true and cheap to
# fix: right after a merge that left a branch behind.
#
# NEVER FAILS THE SHIP, and stays quiet when the answer is yes. The merge has already happened; an
# unreachable gh, an older gh without the field, or a token without repo-read scope are all reasons to say
# nothing rather than to raise an alarm about somebody's tidiness.
$dbomRes = Invoke-NativeCapture -FilePath 'gh' -Arguments @('api', "repos/$repo", '--jq', '.delete_branch_on_merge')
if ($dbomRes.ExitCode -eq 0) {
    $dbom = (($dbomRes.Output | Out-String) -replace '\s', '')
    if ($dbom -eq 'false') {
        Write-Host "Note: '$repo' does not delete head branches on merge, so '$branch' is still on the remote. Switch it on once with:" -ForegroundColor Yellow
        Write-Host "  gh api -X PATCH repos/$repo -F delete_branch_on_merge=true" -ForegroundColor Yellow
        Write-Host "  (the local clone is a separate half -- scripts\task\prune-merged.ps1 reaps that, and deletes nothing it cannot prove is merged)" -ForegroundColor DarkGray
    }
}
