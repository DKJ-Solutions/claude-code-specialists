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

    Everything else it needs was already repo-owned: Get-RepoName for the `gh --repo` target, and
    Get-ChangelogHeading, which it never reads itself -- fold-changelog-entry.ps1 does.

    Steps, stopping on the first failure (nothing is forced):
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
      3. Wait for the required CI check to finish (gh pr checks <pr> --watch). Branch protection on
         main blocks the merge until it is green; if a check FAILS, this stops WITHOUT merging.
      4. Merge (gh pr merge <pr> --<method>, from Get-PrMergeMethod; 'merge' by default), with the
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
    separator ('332,340' -> 332340), silently and without an error.

.PARAMETER NoResolves
    Passed through to open-pr.ps1: declare that this PR closes no issue.

.PARAMETER RefreshBody
    Passed through to open-pr.ps1: on a branch whose PR is already open, rewrite that PR's description
    from the current changelog entry. Opt-in, so a body edited on github.com is never overwritten unasked.
    No effect when the PR is being created in this run.

.EXAMPLE
    ./scripts/release/ship-pr.ps1

.EXAMPLE
    ./scripts/release/ship-pr.ps1 -Resolves 331,332
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
    Write-Error "ship-pr cannot run -- missing repo-owned file: $configPath (Get-RepoName). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward."
    exit 1
}

# Repo name from the local repo-config (single source), and the shared native-capture helper (#114).
. $configPath
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
# For Get-ExistingPrRecord in step 2. $PSScriptRoot-relative, not $repoRoot: like native-capture-lib
# this one is not repo-owned -- it travels with the same plugin/mirror payload as this script.
. (Join-Path $PSScriptRoot '..\lib\pr-issues-lib.ps1')
# For the step-list gate before the merge in step 4 (Get-BranchFilePaths / Get-BranchProgressFindings).
# Same plugin-payload sibling, same reasoning as the two above.
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
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

# --- Step 3: wait for the required CI check ------------------------------------------------------
# The CI checks can lag a few seconds behind the push: `gh pr checks` prints "no checks reported"
# and exits 0 while none are registered yet -- indistinguishable by exit code from "all passed", so
# a bare --watch could return immediately and let the merge below run straight into a BLOCKED wall.
# First poll (on the TEXT, not the exit code) until at least one check is registered, then --watch it.
# Deliberately does NOT name a check: this step watches whatever checks the PR has and reads the exit
# code, so naming one here would be a claim about the consumer's CI that this script cannot keep.
Write-Host "ship-pr: waiting for the CI check(s) on PR #$pr..." -ForegroundColor Cyan
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
# --watch now blocks until the registered check finishes; exit 0 = all passed, non-zero = a failure.
# Branch protection blocks the merge until green, so a non-zero here means we must NOT merge.
$checks = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'checks', "$pr", '--watch', '--interval', "$PollSeconds", '--repo', $repo)
$checks.Output | ForEach-Object { Write-Host $_ }
if ($checks.ExitCode -ne 0) {
    Write-Error "CI did not pass for PR #$pr (exit $($checks.ExitCode)) -- NOT merged. Fix CI and re-run, or merge manually once green."
    exit 1
}
Write-Host "ship-pr: CI green." -ForegroundColor Green

# --- Step 4: merge (no --admin: never bypass the CI gate) ----------------------------------------
#
# THE STEP-LIST GATE FIRES AGAIN HERE, and that is not belt-and-braces. Dave's requirement is about the
# MERGE -- "pas als alle punten zijn afgevinkt kan de branch met een PR gemergd worden" -- while step 1's
# copy of it runs in open-pr.ps1, which has a -Force. A PR opened through that escape valve, or opened by
# hand on github.com, or opened days ago and resumed by this script, would otherwise land with an
# unfinished plan: exactly what the requirement asks to be impossible. Checked here rather than passed
# down from step 1, because the working copy may have changed since.
#
# Read from the branch's own checkout, which is where HEAD still is at this point -- step 5 is what moves
# to main. An absent list is no finding, the same tolerance open-pr.ps1 applies and for the same reason.
$shipProgressRel  = (Get-BranchFilePaths).Progress
$shipProgressPath = Join-Path $repoRoot $shipProgressRel
if (Test-Path -LiteralPath $shipProgressPath) {
    $shipSteps = @(Get-BranchProgressFindings -Text ([System.IO.File]::ReadAllText($shipProgressPath, [System.Text.Encoding]::UTF8)))
    if ($shipSteps.Count -gt 0) {
        $shipMarks  = Get-BranchProgressMarks
        $shipDetail = ($shipSteps | ForEach-Object { "  - $($_.Label): $($_.Line)" }) -join "`n"
        Write-Error @"
step-list gate: $shipProgressRel still has unresolved steps - PR #$pr is NOT merged.

$shipDetail

Resolve each step ($($shipMarks.Done.Trim()) done, $($shipMarks.Dropped.Trim()) dropped with a reason), commit, and re-run. CI has already
passed, so a re-run picks up from here. There is no -Force for this gate.
"@
        exit 1
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
$co = Invoke-NativeCapture -FilePath 'git' -Arguments @('checkout', 'main')
$co.Output | ForEach-Object { Write-Host $_ }
if ($co.ExitCode -ne 0) { Write-Error "git checkout main failed."; exit 1 }

# Fetch + an EXPLICIT ff-only merge of origin/main, not a bare `git pull --ff-only` (lesson of
# July 29, 2026, PR #257). The bare pull aborted with "Cannot fast-forward to multiple branches" on a
# clean main immediately after a merge + prune -- and it aborts HERE, in the one gap between the merge
# and the fold, which is the state nothing reports: the PR is merged, the entry file is still in the
# root, and every gate stays green until a release trips over it. Git raises that error when handed more
# than one ref to merge; naming origin/main explicitly hands it exactly one, so this step cannot reach
# that failure mode, whereas a bare pull depends on whatever FETCH_HEAD happens to hold. Why the pull
# got more than one ref was deliberately not guessed at -- see Derek's lens for that reasoning.
$fetch = Invoke-NativeCapture -FilePath 'git' -Arguments @('fetch', '--prune', 'origin')
$fetch.Output | ForEach-Object { Write-Host $_ }
if ($fetch.ExitCode -ne 0) { Write-Error "git fetch of origin failed."; exit 1 }

$ff = Invoke-NativeCapture -FilePath 'git' -Arguments @('merge', '--ff-only', 'origin/main')
$ff.Output | ForEach-Object { Write-Host $_ }
if ($ff.ExitCode -ne 0) { Write-Error "git merge --ff-only of origin/main failed."; exit 1 }

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
#     $ git commit -m "merge: feat/x (#1)" -- CHANGELOG.md branch/branch-changelog.md
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
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'fold-changelog-entry.ps1') -Branch $branch -Push
if ($LASTEXITCODE -ne 0) { Write-Error "fold-changelog-entry failed -- the fold is NOT committed or NOT pushed. Its own output above says which; do not re-run the fold if it already removed the entry file."; exit 1 }

# --- Step 6: the issues the PR declared it closes are actually closed -----------------------------
# Its own script, so this state-MUTATING logic (it comments and closes) is testable against a fake gh
# instead of only reachable through a full live ship -- and so the same check is usable on its own to
# repair bookkeeping after the fact. It never fails the ship: the merge already succeeded.
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verify-resolved-issues.ps1') -Pr $pr -Repo $repo
if ($LASTEXITCODE -ne 0) { Write-Warning "the issue-closing check reported a problem -- verify by hand with: gh issue list --repo $repo --state open" }

Write-Host "Done: PR #$pr shipped -- opened, CI green, merged, folded on main." -ForegroundColor Green
