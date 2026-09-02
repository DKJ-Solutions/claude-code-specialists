<#
.SYNOPSIS
    Creates (or idempotently reuses) a branch and writes the two files it works in: the cycle file and
    the deployment entry, plus the reference templates beside them.

.DESCRIPTION
    ONE SCRIPT PER CONCEPT (Dave, August 7, 2026). This used to be two: new-branch.ps1 made the
    branch and then ran new-changelog-entry.ps1 as a child process to write the files. That second
    name stopped being true on August 6, when the branch/ split gave it a step list to write as well,
    and again on August 7 when it gained the templates -- it described one of four outputs, and it was
    not a documented entry point: no skill named it, and nothing but this script ever called it.

    WHAT THE SPLIT WAS ACTUALLY BUYING, since it was not nothing. The inner script used `exit` as
    control flow -- on the trunk, on a missing branch-info.ps1, and on "the files already exist" --
    and running it as a child process is what kept those exits from killing the caller. Merging meant
    answering each one rather than deleting it:

      * the missing-branch-info pre-flight was ALREADY here, one copy above; the inner one was a
        duplicate and is gone;
      * the trunk refusal MOVED UP, in front of the checkout, which is strictly better: it now
        refuses before touching HEAD instead of after. It looks unreachable -- Test-BranchName
        rejects 'main' -- but that check only knows 'main' while the trunk is configurable, so a
        consumer whose trunk is 'master' can still reach it with -Name master. Deleting it as dead
        code would break exactly that consumer;
      * "the files already exist" was an `exit 0` that this script read as success and carried on
        from. It is a skip now, which is what it always meant.

    The injection-safe environment-variable handoff went with the process boundary: -Title and
    -Intent are parameters again, because there is no argv to requote across.

    Validation runs via the shared SSOT helper Test-BranchName (scripts/lib/branch-info.ps1):
      - Hard reject (exit 1): empty name, name 'main', or a name containing the substring 'final'.
      - Soft warn (proceed): unknown branch prefix -- the entry's type falls back to 'Chore' and
        open-pr later to the 'question' label. Validation is deliberately delegated to the consumer's
        table, so extended prefixes (Shopify's style/, liquid/, ...) simply work.

    THE BASE IS MEASURED AND REPORTED, NOT CHOSEN (inbound #1046, August 28, 2026). worktree-lane.ps1
    refuses a stale trunk in so many words -- "a lane must not be based on a stale trunk" -- while this
    script cut from whatever HEAD held and never asked. It now counts how far the base is behind
    origin/<trunk> and WARNS with that count, twice: before the checkout, and as the last line of the
    run, because everything this script prints in between buries the first copy. It still creates the
    branch: refusing matches the lane and stays open as a follow-up, but this file reaches consumers by
    plugin update rather than by choice. A repo with no origin/<trunk> ref is not asked and not warned,
    which is what keeps the script usable offline. It is measured only where a base is actually being
    CHOSEN -- see the resume rule below, which settles that question first.

    IT RESUMES A BRANCH THAT EXISTS ONLY ON ORIGIN (issue #1139, August 30, 2026). "Already exists" used
    to mean refs/heads/<name> and nothing else, so on a machine that had not fetched a parked branch into
    a local ref the answer was no and `git checkout -b` forked a second branch of that name at the current
    base -- carrying none of the parked work, printing the same clean run, writing a byte-identical
    scaffold. That is this workflow's own cross-device handoff (#900 pushes by default, cycle-autopark
    keeps it current), so the script documented as idempotent was the one blind to it; worktree-lane.ps1
    inherited it whole through its step-4 delegation. Both namespaces are now read, BEFORE anything is
    said about a base: local -> check out; origin only -> create AT THE REMOTE TIP with tracking, and say
    in so many words that this is a resume of parked work rather than a new branch. The remote-tracking
    ref is read from disk and never fetched for on its own account, so this stays usable offline.

.PARAMETER Name
    The branch name, form <prefix>/<short-name> (e.g. feat/new-plugin).

.PARAMETER Title
    (Optional) the branch title -- the human-readable name of the change, written into the
    entry's 'Branch title' section. That is where the heading's old job went: the entry's H2
    names the BRANCH. Left empty, the section is left empty and open-pr refuses the PR until somebody
    writes it, which is strictly better than a placeholder that can be ticked past.

    AND IT IS THE PR TITLE (#506, August 7, 2026). open-pr.ps1 composes '<type>: <this>' from the entry
    rather than taking a title on the command line, so this is typed once and cannot disagree with
    itself. Write it WITHOUT a 'feat:'/'fix:'/'docs:' prefix -- the branch name already carries the type
    and open-pr puts it in front.

.PARAMETER Intent
    (Optional) the direction of the branch -- what still needs to happen and where you left off.
    Recorded in development.md as the opening paragraph of its FIRST PHASE (PLAN), without a heading
    of its own; typically given together with -Park when parking a branch for later / another device (#162).
    It deliberately does not touch the DEPLOY section: an intent is a status, and that section's text folds
    verbatim into CHANGELOG.md.

    It sat ABOVE the phases until #908 (August 26, 2026), where the document's own guidance says nothing
    branch-specific may go and where the CI gate refused it once the entry was written.

.PARAMETER RepoRoot
    (Optional) the tree to create the branch and its document in, when that is NOT the tree you are
    standing in. Used by worktree-lane.ps1 to open a branch inside a lane worktree. Omitted (the
    normal case): unchanged behaviour -- CLAUDE_PROJECT_DIR, else the git root.

.PARAMETER NoPush
    (Optional switch) leave the branch purely local: nothing committed, nothing on origin. The escape
    valve for the rare branch that must not be visible yet -- since #900 the creation push is what
    happens by default, and this is the only way to opt out of it.

.PARAMETER Park
    (Optional switch) ACCEPTED AND DOES NOTHING SINCE #900 (August 26, 2026): what it used to ask for is
    now the default, so a run that names it gets exactly what a run that does not get. Kept rather than
    removed because this script is mirrored into every consumer's plugin cache, where a `-Park` typed
    from a doc, a lens or a habit would otherwise fail on a parameter that is no longer there. It prints
    one line saying so, and -NoPush is the switch that now changes something.

.EXAMPLE
    ./scripts/task/new-branch.ps1 -Name feat/new-plugin -Title "New domain plugin"

.EXAMPLE
    ./scripts/task/new-branch.ps1 -Name feat/spotify-dashboard -Title "Spotify dashboard" -Intent "Skeleton + routing done; next: wire the API client."
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$Title = "",
    [string]$Intent = "",
    # Explicit override of the repo root, for a caller that creates the branch in a tree OTHER than
    # the one it is standing in -- worktree-lane.ps1 opening a lane is the case this exists for. Same
    # parameter, same reasoning and same name as fold-changelog-entry.ps1 has carried since #101.
    #
    # Deliberately a parameter rather than the caller setting CLAUDE_PROJECT_DIR to the target tree:
    # that was tried first and the source-repo guard refused it, correctly. The guard resolves the repo
    # being operated on from CLAUDE_PROJECT_DIR, so pointing that at the lane made THIS file -- sitting
    # in the primary checkout -- look like a released copy run from outside the repo it maintains. The
    # env var answers "which repo is the session working on"; this parameter answers "which tree does
    # this one call write to", and they are not the same question.
    [string]$RepoRoot,
    # The escape valve, and its inverse used to be the switch (see .PARAMETER NoPush / Park). Named for
    # what it PREVENTS rather than as -Local or -Offline: the one thing it turns off is the push, and a
    # reader who wants the branch off the remote is looking for that word.
    [switch]$NoPush,
    [switch]$Park
)

$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
# -RepoRoot, when supplied, wins over both -- see the param comment above. Note: PowerShell variable
# names are case-insensitive, so $RepoRoot (the param) and $repoRoot (used below) are the same
# variable; the guard below only computes the dual-context fallback when it is still empty. Same shape
# as fold-changelog-entry.ps1, deliberately, so the two read alike.
if (-not $repoRoot) {
    $repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }
}

# Pre-flight (#86): this script relies ONLY on scripts\lib\branch-info.ps1 in the consumer's repo
# root (no gh, and repo-config is optional below). If that is missing -- typically on a clean
# consumer -- stop with a clear pointer instead of a raw dot-source error.
$branchInfoPath = Join-Path $repoRoot 'scripts\lib\branch-info.ps1'
if (-not (Test-Path -LiteralPath $branchInfoPath)) {
    Write-Error "new-branch cannot run -- missing repo-owned file: $branchInfoPath (Get-BranchInfo / Test-BranchName / the branch prefix table). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the source repo as a model) and run again afterward."
    exit 1
}
. $branchInfoPath
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
# AND THE SEAM READER (inbound #967). The guidance this script writes into the document states WHERE a
# relative link in the DEPLOY section has to resolve from, and that is the changelog's directory -- a seam,
# not the repo root, since #914 made it isolate-by-default. Resolved in the script and passed in, the way
# cut-release, fold-changelog-entry and adopt-workflow-folder all read it: the computed
# default needs a repo root, and a lib that goes looking for one can find the wrong tree.
. (Join-Path $PSScriptRoot '..\lib\seam-lib.ps1')

# THE NATIVE-COMMAND CAPTURE HELPER, dot-sourced HERE rather than inside the push block where it sat until
# inbound #1046. Two callers now need it and the first one runs long before the push: the stale-base check
# below, which asks git two questions before HEAD is touched. Not repo-owned and dependency-free, so
# loading it early costs a file read and changes nothing else. Why every git call in this repo goes through
# it: the lib's own header (the #96/#97/#107 stderr-under-EAP=Stop lesson).
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# The repo-owned fallback type (#410) -- OPTIONAL, unlike branch-info.ps1 above. repo-config.ps1 may
# be absent (a repo that never needed it) or may fail to load (a syntax error in someone's edit);
# neither is a reason to stop, because every string it supplies has a working default. So: Test-Path,
# then a try/catch that degrades to a warning.
#
# The local name is deliberately $stubFallbackType, NOT $EntryFallbackType: repo-config backs each
# function with a $script: variable of that name, and at script top level the local and script scopes
# are the same -- so a same-named local would overwrite the dot-sourced value before the function is
# ever called, and the configured type would silently read back as the default. That is the collision
# documented on $RepoRoot/$repoRoot in fold-changelog-entry.ps1.
#
# ONLY THE TYPE IS READ HERE. The three prose placeholders moved to entry-scaffold-lib.ps1 when
# open-pr.ps1 gained the gate that refuses an entry still carrying them -- writer and guard must not
# be able to disagree about the wording. The fallback type stays because it is a changelog TYPE rather
# than scaffold prose: 'Chore' is a legitimate final value and can never be evidence of an unedited entry.
$stubFallbackType = 'Chore'

$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $configPath) {
    try {
        . $configPath
        if (Get-Command Get-EntryFallbackType -ErrorAction SilentlyContinue) {
            $v = Get-EntryFallbackType; if ($v) { $stubFallbackType = $v }
        }
    } catch {
        Write-Warning "scripts\repo-config.ps1 could not be loaded ($($_.Exception.Message)) -- writing the development document with the built-in default wording."
    }
}


# Validation via the shared SSOT helper -- no inline repetition of the hard-reject rules. It runs on the name
# AS GIVEN, before the version suffix below is completed, and that order is a measured requirement rather
# than tidiness: completing first turns '-Name main' into 'main-v1', which every hard reject then waves
# through. Caught by this script's own suite on the first run.
$check = Test-BranchName -Branch $Name
if (-not $check.IsValid) {
    Write-Error "new-branch cannot run -- invalid branch name '$Name': $($check.Reason)"
    exit 1
}
if (-not $check.IsKnown) {
    Write-Warning "Unknown branch prefix in '$Name' -- the entry's type falls back to '$stubFallbackType', open-pr later to label 'question'. Classify manually if needed."
}

# THE TRUNK REFUSAL, AND IT RUNS BEFORE THE CHECKOUT. As a separate script this could only fire after
# HEAD had already moved; merged, it fires while nothing has been touched. Test-BranchName already
# rejects the literal 'main', so in a repo whose trunk IS main this is unreachable -- but the trunk is
# configurable (Get-TrunkBranchName) and that check is not, so a consumer on 'master' reaches it with
# -Name master. That is why it is a guard rather than dead code.
$trunk = Get-BranchTrunkName
if ($Name -eq $trunk) {
    Write-Host "'$Name' is the trunk - create a branch instead." -ForegroundColor Red
    exit 1
}

# --- THE VERSION SUFFIX, COMPLETED HERE RATHER THAN DEMANDED (Dave, August 23, 2026) ---------------
#
# A branch name ends in '-v<N>', and a second development cycle on the same subject keeps the name and bumps
# the number. The rule was already half-written in branch-info.ps1: 'final' is refused there BECAUSE a
# version suffix is the honest way to say "another round of this", and Dave's answer when asked for the
# remedy was '-v2'. This makes it the starting point instead of the way out.
#
# IT APPENDS '-v1' AND NOTHING ELSE -- it does NOT look for the lowest free number, and that restraint is
# the whole design. new-branch is documented idempotent: running it again on the same subject RESUMES that
# branch, which is what the new-branch skill relies on and what the -Park flow needs. A version scan would
# turn every rerun into a new branch -- measured on this script's own suite, where the second run landed on
# '-v2' and the assert that HEAD had not moved failed. So a bump is a DECISION somebody states by typing
# '-v2', which is also exactly how Dave's own sentence reads.
#
# AN EXPLICIT '-vN' IS LEFT EXACTLY AS GIVEN, for the same reason: a number somebody typed is a statement.
#
# WHY IT IS NOT A REFUSAL IN Test-BranchName, which is where a rule like this usually goes. Two reasons:
# branch-info.ps1 is REPO-OWNED and does not travel, so enforcing there states the rule to this repo alone
# while this script is the shared one; and a hard refusal breaks every branch in flight, here and in three
# consumers, which meet this convention through a plugin update rather than by choosing to.
if ($Name -notmatch '-v\d+$') {
    $completed = "$Name-v1"
    Write-Host "Branch name completed: '$Name' -> '$completed' (a development cycle carries its version; a second cycle on the same subject is '-v2', typed deliberately)." -ForegroundColor Cyan
    $Name = $completed
}

# --- THE BASE THIS BRANCH IS CUT FROM, MEASURED AND REPORTED (inbound #1046) -----------------------
#
# worktree-lane.ps1 and this script meet the SAME hazard -- a base that is behind origin -- and until now
# they answered it in opposite ways. The lane fetches and bases its worktree on origin/<trunk>, refusing
# outright when the fetch fails: "a lane must not be based on a stale trunk." This script ran
# `git checkout -b` from whatever HEAD happened to be and never looked, in a run that reaches origin
# moments later to push -- so the remote was already in hand when the base was picked.
#
# WHAT THAT COST, measured in a consumer with two sessions on one board: a branch cut from a trunk 17
# commits behind origin/main, to fix an issue the other session had closed by a merged PR FOUR MINUTES
# earlier. The result was a complete duplicate of already-merged work -- branch, commit, PR, every gate
# green on both -- found only when the PR sat without a CI check and the run list was read by hand. The
# claim step does not catch this and it looks like it should: `gh issue edit <n> --add-assignee @me`
# succeeds silently on a CLOSED issue.
#
# IT WARNS AND DOES NOT REFUSE, which is the report's own first step rather than the stronger option it
# names. Refusing matches the lane script and stays open as a follow-up, but this file is mirrored into
# every consumer's plugin cache and arrives by plugin UPDATE rather than by choice -- the same reasoning
# the version-suffix block above gives for keeping its rule out of Test-BranchName. So the first step
# measures the fact the lane already refuses on, and says it out loud.
#
# AND IT SAYS IT TWICE -- here, and as the LAST line of the run. That repeat is the whole difference
# between a warning that works in this script and one that does not: the scaffold, the commit and the
# push all print AFTER this point, so a single line at this depth is off-screen by the time the run
# ends. The bottom copy is the one a reader actually sees.
#
# THE LOCAL QUESTION GATES THE NETWORK ONE, which is what keeps this usable offline. refs/remotes/origin/
# <trunk> is read FIRST: no such ref means no origin, or a clone that has never fetched, and then there is
# nothing to compare against -- so no fetch is attempted and nothing is claimed. Where the ref does exist
# the fetch is attempted to freshen it, and the count is reported either way, NAMING which of the two it
# came from: "17 behind the origin/main you last saw" is a different sentence from "17 behind origin/main",
# and a reader who is offline needs to be told which one they got.
#
# THE FETCH IS THE ONE COST ADDED TO A ROUTINE RUN. worktree-lane already pays it on every lane, and it is
# gated above on a ref that only exists in a repo with a reachable remote in its history, so the repos that
# cannot answer the question pay nothing.
#
# HEAD..origin/<trunk> RATHER THAN A TRUNK-VS-ORIGIN COMPARISON, deliberately: it answers "what is my base
# missing", which is the question, and it stays correct when HEAD is NOT the trunk -- a branch deliberately
# stacked on another branch gets the gap it actually carries instead of a reading about a trunk it was
# never cut from. In a lane worktree (detached at origin/<trunk> by worktree-lane) it reads 0, so the
# route that already handles this hazard is never warned about.
$staleBaseNote = ''
$trackedTrunk  = "refs/remotes/origin/$trunk"
# Through Invoke-NativeCapture rather than a hand-written EAP dance: that dance is exactly what this lib
# centralizes, and the lib is loaded by the time we get here.
$tracked = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'rev-parse', '--verify', '--quiet', $trackedTrunk) -DiscardStderr
$fresh   = $false
if ($tracked.ExitCode -ne 0) {
    Write-Host "Base not compared: this repo has no $trackedTrunk (no origin, or never fetched)." -ForegroundColor DarkGray
} else {
    # -DiscardStderr ON THE FETCH, and not only for tidiness: a failing git fetch echoes the remote URL,
    # which in a repo cloned over HTTPS with a credential in the URL is a secret. The message below says
    # the fetch failed and that the gap may be larger, which is everything a reader can act on.
    $fetch = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'fetch', 'origin', '--quiet') -DiscardStderr
    $fresh = ($fetch.ExitCode -eq 0)
}

# --- RESUME OR CUT? ASKED BEFORE ANYTHING IS SAID ABOUT A BASE (issue #1139) -----------------------
#
# THE BUG THIS ANSWERS. Until August 30, 2026 this script asked ONE ref -- refs/heads/$Name -- and read
# "no" as "create it". refs/heads/ is the LOCAL namespace, so on a machine that had not yet fetched a
# parked branch into a local ref the answer was no, and `git checkout -b` cut a second, unrelated branch
# of the same name at the current base. The parked branch's commits were not in it.
#
# WHY THAT IS WORSE HERE THAN AN ORDINARY LOCAL/REMOTE SLIP. The parked branch IS this workflow's
# cross-device handoff: since #900 this script pushes by default so the branch is reachable from another
# device, and the cycle-autopark Stop hook keeps it current on origin until a PR publishes it. So the
# workflow actively produces branches whose only copy is on the remote -- and the script documented as
# idempotent, the one you are told to re-run to resume, was the one that could not see them.
#
# AND NEITHER HALF OF THE RUN LOOKED WRONG. A clean run is what "idempotent" promises, and the scaffold
# written into the fork is BYTE-IDENTICAL to the one already on the parked branch, because the same
# script wrote both. What is missing is the branch's WORK, and there is nothing on screen about work.
# worktree-lane.ps1 inherited the whole failure: its step 4 delegates here with the lane as -RepoRoot,
# and its step 3 has already added that worktree DETACHED AT origin/<trunk> -- so the fork was based on
# the trunk and the lane reported 'Lane open' exactly as on a genuine new branch.
#
# IT RESUMES AT THE REMOTE TIP AND SAYS SO LOUDLY, rather than refusing and printing the git command.
# Both are honest and the report left the choice open; resuming is what wins here because this script is
# the documented resume tool for a handoff the workflow creates on its own, so a refusal would put a
# hand-typed `git branch --track` on the intended happy path. What the report actually rules out is a
# SILENT adoption -- an assignee is a claim rather than a locked door in this repo, and a script that
# quietly adopts somebody else's remote branch makes that claim unreadable. Naming it is what keeps it
# readable, so the lines below say which of the three things happened and what to type if the operator
# meant a new branch instead.
#
# THE LOCAL QUESTION GATES THE NETWORK ONE, exactly as the base check above does: refs/remotes/origin/
# $Name is a remote-TRACKING ref, read from disk and never fetched for on its own account. It is fresh
# here because the base check has just fetched wherever there was an origin to fetch from; where there
# was not, this reads whatever the last fetch left and the script stays usable offline.
$localRef  = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'rev-parse', '--verify', '--quiet', "refs/heads/$Name") -DiscardStderr
$remoteRef = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'rev-parse', '--verify', '--quiet', "refs/remotes/origin/$Name") -DiscardStderr
$branchExists   = ($localRef.ExitCode -eq 0)
$branchOnOrigin = ((-not $branchExists) -and ($remoteRef.ExitCode -eq 0))
$resuming       = ($branchExists -or $branchOnOrigin)

# --- HOW FAR BEHIND IS THE BASE? MEASURED ONLY WHEN THERE IS A BASE TO CHOOSE ----------------------
#
# SPLIT FROM THE FETCH ABOVE, AND THE ORDER IS THE POINT. The question this block answers is "what is
# the branch I am about to CUT missing", and it is unanswerable -- worse, it is false -- for a branch
# that already exists: the count is HEAD..origin/<trunk>, and on a resume HEAD is whatever the operator
# happened to be standing on, usually the trunk. Attributing the trunk's gap to a branch that was cut
# somewhere else entirely is a sentence nobody can act on. So the resume question is settled first and
# this block is skipped when the answer is yes.
#
# HEAD..origin/<trunk> RATHER THAN A TRUNK-VS-ORIGIN COMPARISON, deliberately: it answers "what is my base
# missing", which is the question, and it stays correct when HEAD is NOT the trunk -- a branch deliberately
# stacked on another branch gets the gap it actually carries instead of a reading about a trunk it was
# never cut from. In a lane worktree (detached at origin/<trunk> by worktree-lane) it reads 0, so the
# route that already handles this hazard is never warned about.
if ($tracked.ExitCode -eq 0 -and -not $resuming) {
    $rev     = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'rev-list', '--count', "HEAD..origin/$trunk") -DiscardStderr
    $revText = (($rev.Output | Out-String).Trim())
    $behind  = 0
    if ($rev.ExitCode -eq 0 -and $revText -match '^\d+$') { $behind = [int]$revText }
    if ($behind -gt 0) {
        $against = if ($fresh) { "origin/$trunk" } else { "the origin/$trunk this repo last fetched (git fetch failed -- the real gap may be larger)" }
        $staleBaseNote = "'$Name' is based on a commit $behind behind $against."
        Write-Warning $staleBaseNote
        Write-Host "  new-branch does not move HEAD for you, so this branch carries that gap -- work already merged upstream is" -ForegroundColor Yellow
        Write-Host "  invisible from here, including an issue somebody else has just closed. Bring the base up to date first" -ForegroundColor Yellow
        Write-Host "  (git pull --ff-only), or open the work as a lane, which bases it on origin/$trunk itself:" -ForegroundColor Yellow
        Write-Host "  scripts\task\worktree-lane.ps1 -Name <name>" -ForegroundColor Yellow
    } elseif ($fresh) {
        Write-Host "Base is current with origin/$trunk." -ForegroundColor DarkGray
    }
} elseif ($resuming -and $tracked.ExitCode -eq 0) {
    # GATED ON THE TRUNK REF AS WELL, so this cannot print a SECOND 'Base not compared' underneath the one
    # the missing-origin branch above already wrote. Both sentences would be true and neither would be
    # wrong; two of them in a row just read as a script that has lost track of what it is answering.
    Write-Host "Base not compared: '$Name' already exists, so nothing is being cut from a base." -ForegroundColor DarkGray
}

# Note: Test-BranchName above only catches the explicitly named hard rejects (empty/'main'/
# 'final'). Protection against e.g. backslashes, '..', or a leading hyphen in $Name does NOT rely
# on custom code here, but implicitly on git's own `check-ref-format` validation, which `git checkout
# -b` below enforces itself (with exit 128 on an invalid ref name). If you ever change the
# checkout mechanism (e.g. to `git branch` + a separate `checkout`, or to libgit2), check whether
# that implicit gate does not silently disappear.
#
# Idempotent, in three shapes: the branch exists locally -> check it out; it exists only on origin ->
# create it AT THE REMOTE TIP with tracking, which is what a resume means; neither -> create it here.
# Deliberately `git -C $repoRoot` instead of Set-Location -- this script stays composable and does
# not mutate the caller's cwd. git sometimes writes progress/errors to stderr; under
# ErrorActionPreference=Stop, PS 5.1 would promote that to a terminating error before the graceful
# $LASTEXITCODE handling (the #107 pitfall, see also open-pr.ps1) -- so run under Continue, capture
# output, and only then judge. The checkout keeps that hand-written dance rather than moving to
# Invoke-NativeCapture like the reads above: its stderr is git's own progress text, which is PRINTED
# rather than judged, and discarding or swallowing it is what the lib is for.
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    if ($branchExists) {
        $checkoutOutput = & git -C $repoRoot checkout $Name 2>&1
    } elseif ($branchOnOrigin) {
        $checkoutOutput = & git -C $repoRoot checkout -b $Name --track "origin/$Name" 2>&1
    } else {
        $checkoutOutput = & git -C $repoRoot checkout -b $Name 2>&1
    }
    $checkoutCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevEap
}
$checkoutOutput | ForEach-Object { Write-Host $_ }
if ($checkoutCode -ne 0) {
    Write-Error "git checkout of '$Name' failed."
    exit 1
}
if ($branchExists) {
    Write-Host "Branch '$Name' already existed -- checked out." -ForegroundColor Yellow
} elseif ($branchOnOrigin) {
    Write-Host "Branch '$Name' existed ONLY on origin -- resumed at the remote tip, tracking origin/$Name." -ForegroundColor Yellow
    Write-Host "  That is a RESUME, not a new branch: it carries work parked from another device or session," -ForegroundColor Yellow
    Write-Host "  and nothing was cut from this checkout's base. If you meant a NEW branch, this name is taken --" -ForegroundColor Yellow
    Write-Host "  bump the version suffix ('-v2') and run again." -ForegroundColor Yellow
} else {
    Write-Host "Branch '$Name' created and checked out." -ForegroundColor Green
}

# --- The two files the branch works in, plus the reference templates ------------------------------

# BOM-less UTF8 -- Set-Content -Encoding UTF8 always adds a BOM in Windows PowerShell 5.1, and the
# rest of the repo has no BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

# $Name rather than a fresh `git rev-parse HEAD`: the checkout above has just put HEAD there and
# errored out if it could not. Asking git again would be a second answer to a settled question.
$branch = $Name

# -Title IS THE BRANCH TITLE. The entry's H2 names the branch, and the human-readable name of
# the change is a section under it -- the one open-pr.ps1 now composes the PR title from, so what is
# typed here is what the PR is called. Give it WITHOUT a type prefix: the branch already carries the
# type and open-pr puts it in front.
$description = $Title

# THE 'Branch type' SECTION HOLDS THE PREFIX, LOWERCASE, which is what its own hint asks for ("options
# for type are: feat, fix or docs") and what the branch name already says. It used to hold the
# canonical type ('Feat'); Resolve-EntryType canonicalises case-insensitively, so both read back as the
# one type the release documents know -- which keeps the hundreds of entries carrying 'Feat' readable.
$info = Get-BranchInfo -Branch $branch
$branchType = if ($info.IsKnown) { $info.Prefix } else { '' }
if (-not $branchType) {
    $branchType = $stubFallbackType.ToLowerInvariant()
    Write-Host "Unknown branch prefix '$($info.Prefix)' - 'Branch type' set to '$branchType', adjust this by hand if needed." -ForegroundColor Yellow
}

# THE BRANCH ID, STAMPED AT CREATION. A timestamp is what the field's own hint asks for, and it is the
# one identifier available here that needs no state and cannot collide with a branch created on another
# machine. THE SECOND IS PART OF IT deliberately: two branches created in the same minute is not a
# hypothetical in a repo whose whole workflow is "notice it once, script it the second time".
$branchId = (Get-Date).ToString('yyyyMMdd-HHmmss')

# THE BRANCH'S WORKING DOCUMENT LIVES AT contributing-davekjohn/development.md, NOT IN THE REPO ROOT
# UNDER THE BRANCH'S NAME (Dave, August 6, 2026; moved under the workflow's own root folder August 14,
# 2026; merged from two files into one on August 23, 2026).
# ONE NAME PER BRANCH SINCE #1255 (September 3, 2026), where it was one fixed path. The fixed path did not
# collide on CHECKOUT, which is what the old reasoning said; it collided on MERGE, which is what it did not.
# See the block in entry-scaffold-lib.ps1 for the measurement.
$branchFiles    = Get-BranchFilePaths -Branch $branch
$branchDirPath  = Join-Path $repoRoot $branchFiles.Directory

# WHICH NAME THIS RUN WRITES, on a repo that may still hold a pre-August-23-2026 pair. The rule is the
# narrowest one that keeps a branch in flight whole: an old name is used for one reason only -- it already
# declares THIS branch, so somebody is working in it and a new document beside it would split their work in
# half. Every other state writes the current name, including a trunk whose reset files still carry the old
# ones. Resolve-BranchFilePath is deliberately NOT used here: it answers "where is the file", which is the
# readers' question, and answering the writer's question with it would keep an old name alive on every
# branch a consumer creates.
#
# THE STEP LIST AND THE ENTRY WERE TWO FILES, so there are two old names to recognise rather than one. A
# branch created before the merge has both, each declaring it; whichever is found first is where this run
# keeps writing, because a rerun that moved half of somebody's work to the new file would be the split it is
# trying to avoid.
function Get-BranchFileTargetRel {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$Current,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Legacy,
        [Parameter(Mandatory)][string]$Branch
    )
    foreach ($rel in @($Legacy)) {
        if (-not $rel) { continue }
        $path = Join-Path $RepoRoot ($rel -replace '/', '\')
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $declared = Get-BranchFileDeclaredBranch -Text ([System.IO.File]::ReadAllText($path))
        if ($declared -eq $Branch) { return $rel }
    }
    return $Current
}

# THE SHARED NAME LEADS THE LEGACY LIST (#1255), and it is the entry that matters most on the day of the
# change: every branch open right now is working in it. Without it a rerun of this script on such a branch
# would create the per-branch document beside the one holding the work and split it in half -- the exact
# failure this list exists to prevent, one rename further on.
$cycleRel  = Get-BranchFileTargetRel -RepoRoot $repoRoot -Current $branchFiles.File `
    -Legacy @($branchFiles.SharedFile, $branchFiles.LegacyCycle, $branchFiles.OlderCycle) -Branch $branch
$cyclePath = Join-Path $repoRoot ($cycleRel -replace '/', '\')

if (-not (Test-Path -LiteralPath $branchDirPath)) {
    $null = New-Item -ItemType Directory -Path $branchDirPath -Force
}

# NOTHING WRITES A TEMPLATE ANY MORE (August 23, 2026), and the reason it can stop is that the working
# document carries the guidance itself. branch/templates/ existed because the file a branch got was
# deliberately bare: the comments explaining every field lived in a reference copy beside it, which this
# script had to create and refresh in every consumer. Inbound #810 is what that arrangement cost -- an
# author met the guidance in the neighbouring file or not at all. The comments are in the document now, the
# fold strips them on the way to CHANGELOG.md, and a reference nobody has to keep in sync is one fewer thing
# that can drift.
# IDEMPOTENCY IS ONE QUESTION NOW, and that is the merge's quietest simplification. It used to be two --
# per file, because the entry and the step list could legitimately be out of step, so a rerun on a branch
# whose entry was written still had to leave the step list alone. One document cannot be half-written by
# this script: either it declares this branch or it does not.
#
# THE TEST IS THE DECLARED OWNER MEASURED AGAINST THIS BRANCH (inbound #615, reported from a consumer).
# "Is the entry filled" and "is the owner not the trunk" are BOTH true for any branch stacked on one whose
# entry has not been folded yet -- so the file was skipped, and the skip was printed under the NEW branch's
# name. The branch silently started out claiming the previous branch's work as its own: nothing failed, and
# the one line it printed said the opposite of what had happened.
#
# One comparison answers all three states. The trunk's reset state declares the trunk (write), a rerun on
# this branch declares this branch (keep), and a foreign owner declares somebody else (write, and say whose
# file was replaced). Get-BranchFileDeclaredBranch reads the heading at either level -- '# `main`
# development cycle' on the trunk, '# `feat/x-v1` development cycle' once written, and an old
# '## `feat/x` deployment' on a branch created before the merge -- so the same predicate serves every
# state, and Test-BranchChangelogIsFilled is not the idempotency test. It still owns the question it is
# named for, everywhere else.
$cycleExisting = if (Test-Path -LiteralPath $cyclePath) { [System.IO.File]::ReadAllText($cyclePath) } else { '' }
$cycleOwner    = Get-BranchFileDeclaredBranch -Text $cycleExisting
$cycleTaken    = ($cycleOwner -eq $branch)

# READ THIS BEFORE DELETING THE BLOCK BELOW AS DEAD CODE (#1255, September 3, 2026). Naming the document
# per branch removed almost every way of reaching it. The target is now this branch's own name, and a
# legacy name is chosen for one reason only -- it already declares THIS branch -- so the ordinary route in,
# a branch stacked on an unfolded one, cannot produce a foreign owner any more: the two branches write
# different files. What is left is the odd tree: a branch renamed after its document was written, or a
# document created by hand under a name that does not match it.
#
# IT STAYS, for the reason the block itself gives. What it protects is work that exists in exactly one
# place -- edits carried into a new branch by `git checkout -b` and never committed -- and the cost of
# keeping an unreachable guard is a few lines, while the cost of being wrong about "unreachable" is
# somebody's uncommitted entry. new-branch.tests.ps1 scenario (n2) measures the new guarantee (a foreign
# document is never TARGETED) rather than pretending to reach this; that is deliberate and is written up
# there.
#
# A FOREIGN OWNER IS OVERWRITTEN, EXCEPT WHERE THE OVERWRITE WOULD BE UNRECOVERABLE -- and that
# distinction is measured rather than assumed, because this repair is what creates the destructive
# path. Before it, a foreign file was kept; after it, it is written over. In the ordinary stacked case
# that costs nothing: the other branch's entry is committed on that branch, so git still holds it. What
# git does not hold is an entry edited and never committed -- `git checkout -b` carries those edits
# into the new branch, and there they exist in exactly one place. So a dirty foreign file is left
# alone and said out loud instead, which still repairs the defect that was reported: the failure there
# was the SILENCE and the wrong name, not the keeping.
#
# `git -C $repoRoot` and the EAP dance for the same two reasons every other git call in this script has
# them (see the block at the checkout above): bare `git` would read whatever directory the caller
# happened to be in, and under ErrorActionPreference=Stop PS 5.1 promotes a native command's stderr to
# a terminating error. Untracked counts as dirty, deliberately -- a file git has never seen is the
# case where the working tree is the only copy there is.
function Test-BranchFileIsDirty {
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$RelativePath)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $porcelain = & git -C $RepoRoot status --porcelain -- $RelativePath 2>$null
    } finally {
        $ErrorActionPreference = $prevEap
    }
    return [bool]($porcelain | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

# ALREADY WRITTEN IS A SKIP, NOT A STOP, and that is the one exit the merge had to convert. As a child
# process this was `exit 0` and the caller read it as success and carried on to -Park; inline, an exit would
# end the whole run and a park would silently not happen. Saying so and falling through is what it always
# meant.
if ($cycleTaken) {
    Write-Host "Development already written for '$branch' - nothing done." -ForegroundColor Yellow
    $branchFileWritten = $false
} else {
    # -Intent IS THE PARKING NOTE AND IT DOES NOT LAND IN THE ENTRY (Dave, August 6, 2026). It is a status,
    # typically written when parking (#162), and it used to become the entry BODY -- which put a progress
    # note in the text that folds verbatim into CHANGELOG.md, the defect the v3.2.0 measurement found three
    # times. It goes into the document's first phase instead -- as PLAN's opening paragraph since #908, no
    # longer above the phases, where the document's own guidance forbids branch-specific text and the CI
    # gate refuses it; the entry scaffolds with an empty body and the gate keeps refusing that until
    # somebody writes what the change does.
    $body = ''

    # THE SECTION SHAPE IS THE SHAPE, ALWAYS -- the ranking's on/off switch does not change it. An earlier
    # draft wrote the significance sections only where Test-EntrySignificanceActive said the repo ranks.
    # That produced TWO entry shapes in one system, so every reader downstream would have needed both paths
    # forever. Tier 0 unscored is harmless in a repo that never scores it -- nothing asks, nothing refuses --
    # so the switch governs only the GATES, which is the thing a repo was ever opting out of.
    $impactActive = Test-EntrySignificanceActive

    # A FOREIGN OWNER IS OVERWRITTEN, EXCEPT WHERE THE OVERWRITE WOULD BE UNRECOVERABLE -- and that
    # distinction is measured rather than assumed, because this repair is what creates the destructive path.
    # Before it, a foreign file was kept; after it, it is written over. In the ordinary stacked case that
    # costs nothing: the other branch's document is committed on that branch, so git still holds it. What git
    # does not hold is a document edited and never committed -- `git checkout -b` carries those edits into the
    # new branch, and there they exist in exactly one place. So a dirty foreign file is left alone and said
    # out loud instead, which still repairs the defect that was reported: the failure there was the SILENCE
    # and the wrong name, not the keeping.
    $cycleForeign = ($cycleOwner -and $cycleOwner -ne $trunk -and -not $cycleTaken)

    if ($cycleForeign -and (Test-BranchFileIsDirty -RepoRoot $repoRoot -RelativePath $cycleRel)) {
        Write-Warning "Kept: $cycleRel -- it holds UNCOMMITTED work belonging to '$cycleOwner', which exists nowhere else. This branch has no development document of its own yet: commit or discard that work, then rerun this script."
        $branchFileWritten = $false
    } else {
        # NO DATE IN THE ENTRY, DELIBERATELY (Dave, August 5, 2026). This runs when the BRANCH is created, so
        # any date it writes is the branch's birth date -- and the changelog records what LANDED when. The
        # entry's date is the fold's to add, from the PR's own merge timestamp, together with the PR number.
        # The CREATION stamp does belong here: it is the document's own heading, and this document is created
        # with the branch and reset with the merge.
        # THE LINK BASE IS THIS REPO'S OWN (inbound #967), not a constant. In the source repo it resolves to
        # the root and the sentence is word for word what it always said; in a consumer on the shipped
        # defaults it resolves to the workflow folder -- the same directory this document is in -- where the
        # old wording told the author to write the one link form the fold would break.
        $linkDestDirRel = ((Split-Path (Get-SeamValue -Name 'Get-ChangelogPath' `
            -Default (Get-DefaultChangelogPath -RepoRoot $repoRoot)) -Parent) -replace '\\', '/').Trim('/')
        $cycleText = ((Format-Development -Branch $branch -Intent $Intent -Id $branchId `
            -Description $description -Type $branchType -Body $body `
            -LinkDestDirRel $linkDestDirRel) -join "`n") + "`n"
        [System.IO.File]::WriteAllText($cyclePath, $cycleText, $Utf8NoBom)
        $branchFileWritten = $true
        # WHOSE FILE THIS WAS IS NAMED IN EVERY OUTCOME, and that is the reported defect's actual repair. A
        # foreign owner is the one state the old test could not distinguish from its own, so it is the one
        # state the output has to say out loud.
        if ($cycleForeign) {
            Write-Host "Replaced: $cycleRel (it held the development document of '$cycleOwner', committed on that branch)" -ForegroundColor Yellow
        } else {
            Write-Host "Created: $cycleRel" -ForegroundColor Green
        }
    }

    # SAID WHERE IT HAPPENS (inbound #817). The line above names the path a session is about to edit and,
    # until now, never mentioned that its own view of it had just been replaced. One line here turns a
    # refused write further on into a known next step, in the one place a reader is already looking at
    # exactly that file. Wording in Get-BranchFilesRereadNote, shared with the fold, which resets the same
    # document at the other end of the cycle.
    if ($branchFileWritten) { Write-Host (Get-BranchFilesRereadNote) -ForegroundColor DarkGray }

    # The rubric, printed at the moment the entry comes into existence. The scores are filled in later, by
    # whoever finishes the branch -- so this is not a prompt to act on now; it is the scale being stated
    # where the author is looking, instead of only inside a refusal further down the line. A gate that first
    # mentions the definitions when it blocks you has already let the guess happen.
    if ($impactActive) {
        $range = Get-EntrySignificanceRange
        Write-Host "  Tier sections written. Answer each tier with a score ($($range.Min)-$($range.Max)) or N/A:" -ForegroundColor Cyan
        Format-EntrySignificanceRubricLines | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
        # WHERE the reason goes, by the same argument as the rubric above it (inbound #596): the file leaves
        # one blank line on each side of the score label, so the two places look identical and only the one
        # above is read. Said here because this is the moment the author is looking and has not written yet
        # -- the gate that names the misplacement runs at the PR, by which time the half hour is spent.
        Write-Host "  Each tier's reason goes ABOVE its $(Get-EntryScoreLabel) line; anything below it is discarded." -ForegroundColor DarkGray
    }
}

# THE CREATION PUSH: make the freshly created branch reachable from another device by committing its
# development document (the plan, the intent and the entry, in one file) and pushing it -- NO PR. Push != PR:
# the PR rule stays intact and separate. git writes progress to stderr,
# which under EAP=Stop would die as a terminating NativeCommandError before the exit-code check even on
# exit 0 (the #107 pitfall) -- so every git call goes through the shared Invoke-NativeCapture
# (EAP=Continue -> run -> record $LASTEXITCODE), the same helper open-pr.ps1 uses for its push.
#
# THE DEFAULT SINCE #900 (August 26, 2026), AND IT WAS A DEFAULT QUESTION RATHER THAN A BUILD. This exact
# block ran behind -Park for nineteen days and the switch was typed SIX times in the whole history, while
# the window it exists to close was measured over the 38 merged branches carrying a readable creation
# stamp: median 22 minutes invisible on origin, mean 35, max 365, nine of them over half an hour. An
# opt-in backup is a backup nobody takes -- which is what those two figures are, side by side. Dave works
# from more than one device, so a branch that exists only locally is a branch the other device cannot see
# and will collide with.
#
# -NoPush IS THE ONLY WAY OUT, and it is deliberately not gated on anything else. A branch nobody may see
# yet is a real case; a branch nobody CAN see is the defect.
#
# UNCONDITIONAL SINCE THE MERGE. It used to be gated on the child's exit code, with a warning
# branch for "the entry step failed, so nothing was parked". There is no child any more: a failure above
# either exits or throws under EAP=Stop, so reaching this line means the files are there.
if ($Park) {
    # ACCEPTED, ANNOUNCED, IGNORED -- see .PARAMETER Park. Said out loud rather than swallowed, because a
    # consumer whose doc still names the switch should learn that it is the default now, not wonder
    # whether their run behaved differently from the one beside it.
    Write-Host "new-branch: -Park is the default since #900 -- the switch is accepted and changes nothing." -ForegroundColor DarkGray
}
if ($NoPush) {
    Write-Host "new-branch: -NoPush -- branch and document are local only, nothing is on origin." -ForegroundColor Yellow
} else {
    # ONE IMPLEMENTATION SINCE #507 (August 7, 2026). These four steps used to be written out here as
    # well as in park-branch.ps1, and the copies had drifted where it hurts a reader rather than a
    # script: both wrote `park: <branch> (work parked for later)` while committing different things, so
    # the log could not say which half of the work was safely on origin. The scope now picks the words
    # too, and the shared function owns both.
    . (Join-Path $PSScriptRoot '..\lib\park-lib.ps1')

    # NO ORIGIN, NO PUSH -- AND CREATING THE BRANCH STILL SUCCEEDS. A repo with no remote is a legitimate
    # repo, and until the push became the default nobody met this: you had asked for it, so the failure was
    # the right answer. Unasked, that same exit 1 would come out of branch CREATION. Test-GitOriginConfigured
    # carries the full reasoning; park-branch.ps1 deliberately does NOT ask this question.
    if (-not (Test-GitOriginConfigured -RepoRoot $repoRoot)) {
        Write-Host "new-branch: no 'origin' remote -- the branch and its document stay local." -ForegroundColor Yellow
    } else {
    # THE ONE DOCUMENT, since the merge (Dave, August 23, 2026). Parking exists to make work reachable from
    # another device, and both halves of what a reader needs -- the plan still in flight and the claim being
    # made -- are sections of this file now, so the pair that used to be listed here is one path. Named
    # explicitly rather than swept up, so the commit stays exactly as narrow as it was: this pushes to a
    # branch, but the pathspec discipline is the same everywhere.
        $ok = Invoke-GitPark -RepoRoot $repoRoot -Branch $Name -Scope 'BranchFiles' `
            -Paths @($cycleRel)
        if (-not $ok) { exit 1 }
    }
}

# THE REPEAT, and it is the half of the stale-base check that a reader actually reads (inbound #1046). See
# the block above the checkout for the measurement; this exists because everything between there and here
# -- the scaffold, its tier rubric, the commit, the push -- prints in between, so the warning that fired
# before HEAD moved is well off-screen by now. Last line of the run, or nothing at all.
if ($staleBaseNote) {
    Write-Warning "$staleBaseNote Bring the base up to date (git pull --ff-only) or reopen this as a lane before you build on it."
}

exit 0
