<#
.SYNOPSIS
    Claim a GitHub issue for THIS checkout before any work on it starts -- under the account its
    commits will name, and refusing where the issue is closed, missing, or already somebody else's.

.DESCRIPTION
    THE RULE THIS IMPLEMENTS ALREADY EXISTED; NOTHING PERFORMED IT. Chris's persona body ("Picking up
    an issue -- claim it before you work it") and dkj-policy/CONTRIBUTING.md both prescribe
    `gh issue edit <n> --add-assignee @me`, and both leave it to a session to remember, to type, and
    to read the result of. This script is that step, so that "fix issue 1234" cannot begin before the
    tracker says who is on it.

    WHY THE TRACKER IS WHERE THIS HAS TO HAPPEN. It is the only thing two sessions share. The same
    owner may be running a second machine and a colleague may be working the same board; neither
    session sees the other's branch or intent, so an unassigned issue is indistinguishable from an
    untouched one -- which is how the same work gets built twice and discovered at the merge.

    THREE THINGS THE DOCUMENTED ONE-LINER GETS WRONG, and each is a refusal below:

      1. `@me` CAN NAME THE WRONG ACCOUNT. It resolves through the GitHub API, so it binds to whatever
         gh is authenticated as -- while the branch a second session correlates the claim with carries
         the git identity. Measured (issue #1315): gh acting as DaveKJohn on a checkout committing as
         davekokbwj put the wrong account on #1314. This script never sends `@me`: it resolves the
         account from both reads and claims by NAME, which is what check-git-identity.ps1's own report
         already instructs. See Resolve-ClaimAccount.

      2. IT SUCCEEDS SILENTLY ON A CLOSED ISSUE. So the claim gives a session every signal of having
         taken ownership of work that is already finished. That is the case new-branch.ps1's stale-base
         block records: a branch cut, committed, pushed and PR'd against an issue another session had
         closed by a merged PR four minutes earlier. Nothing downstream catches it, because every gate
         reads the branch and the branch is fine.

      3. IT ADDS, SO IT NEVER TELLS YOU THE ISSUE IS TAKEN. `--add-assignee` on an issue somebody else
         holds puts you beside them and reports success. Reading the claim is a separate command that
         the rule names and nobody runs; here it is one step with the write.

    IT WRITES ONE THING AND NOTHING ELSE. An assignee on one issue. No branch, no checkout, no commit,
    no label, no comment -- opening the branch is new-branch.ps1's job and stays a separate decision,
    because the branch name is a judgement about the work and this step has not read the work yet.

    THE VERDICT IS TESTED AND THE COMMANDS ARE NOT (scripts/lib/claim-issue-lib.ps1). Everything here
    around the two library calls is a gh round-trip a suite cannot run; the decisions are pure, so they
    are where the refusals live.

    Dual-context: run the root copy in this repo, the plugin mirror in a consumer.

    Pure ASCII, per this repo's script-layer convention.

.PARAMETER Issue
    The issue to claim. Accepts a bare number (1234), a hash-prefixed one (#1234), or the issue's own
    URL -- all three are what a person has in their hand at that moment, and requiring one spelling
    would only teach the caller to strip characters this script can strip itself.

.PARAMETER DryRun
    Read and judge, write nothing. Prints the verdict it would act on, so a caller can see who holds
    an issue without taking it.

.PARAMETER RootOverride
    Repo root to resolve repo-config.ps1 in, for the test suite. A consumer never types this: the root
    is resolved dual-context like every other shared script.

.EXAMPLE
    ./scripts/task/claim-issue.ps1 1234

.EXAMPLE
    ./scripts/task/claim-issue.ps1 '#1234' -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Issue,
    [switch]$DryRun,
    [string]$RootOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Repo root -- dual context: a consumer running the shared plugin mirror gets it from
# CLAUDE_PROJECT_DIR, a run inside this repo from git itself.
$repoRoot = if ($RootOverride) { $RootOverride } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\git-identity-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\claim-issue-lib.ps1')

# --- WHICH ISSUE ----------------------------------------------------------------------------------
#
# The three spellings a caller actually has: 1234, #1234, and the URL they just copied out of the
# browser. A URL is reduced to its trailing path segment rather than pattern-matched against
# github.com, because a self-hosted tracker is somebody else's host and the number is in the same
# place either way.
$raw = $Issue.Trim().TrimStart('#')
if ($raw -match '/([0-9]+)/?$') { $raw = $Matches[1] }
if ($raw -notmatch '^[0-9]+$') {
    Write-Host "[ERROR] '$Issue' is not an issue number." -ForegroundColor Red
    Write-Host '        Give the number (1234), the number with a hash (#1234), or the issue URL.' -ForegroundColor Red
    exit 1
}
$number = $raw

# --- WHICH REPO -----------------------------------------------------------------------------------
#
# Get-RepoName pins the tracker explicitly, which matters in a worktree or when the run starts from a
# directory other than the checkout: gh would otherwise resolve the repo from the CURRENT directory,
# and a claim landing on the wrong tracker is a silent failure of exactly the kind this script exists
# to remove. Read defensively, like every other shared script reads repo-config.ps1 -- that file
# belongs to the consumer, and a fault in it must not take this step down. Without it, gh's own
# resolution stands and is said out loud.
$repoName = ''
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    try {
        . $configPath
        if (Get-Command Get-RepoName -ErrorAction SilentlyContinue) { $repoName = [string](Get-RepoName) }
    } catch {
        $repoName = ''
    }
}
$repoArgs = if ($repoName) { @('--repo', $repoName) } else { @() }

Write-Host "== claim-issue #$number$(if ($DryRun) {' -DryRun'}) -- $(if ($repoName) { $repoName } else { 'repo per gh (no Get-RepoName)' }) ==" -ForegroundColor Cyan

# --- WHO THIS CHECKOUT IS -------------------------------------------------------------------------
$identity = Resolve-ClaimAccount -GhAccount (Get-ActiveGhAccount) -GitUserName (Get-GitUserName -RepoRoot $repoRoot)

if ($identity.Reason -eq 'split') {
    # Not an error here, and deliberately not: check-git-identity.ps1 owns that report and the
    # SessionStart hook has already made it. What this step owes the reader is which of the two names
    # it is about to write, and why that is the git one.
    Write-Host "  [split identity] gh acts as '$($identity.GhAccount)', git commits as '$($identity.GitUserName)'." -ForegroundColor Yellow
    Write-Host "                   Claiming as '$($identity.Account)' -- the account the branch will name." -ForegroundColor Yellow
}

# --- WHAT THE TRACKER SAYS ------------------------------------------------------------------------
#
# -DiscardStderr because this output is parsed: gh writes its progress and its warnings to stderr, and
# merged in they are not JSON. The failure branch below therefore says what it can from the exit code
# rather than quoting gh, which is the trade native-capture-lib names.
#
# BOUNDED, LIKE EVERY OTHER NETWORK CALL IN THIS FAMILY (issue #1639). All three `gh` calls in this
# script were unbounded while every sibling script bounded its own, and the cost lands hardest here:
# the claim is the FIRST step of an issue-driven assignment (#1485), so a stall at this line is a
# session that never starts, with nothing printed to say why. The failure mode is not hypothetical on
# this surface -- #1628's measurement is a checkout where `gh` returned exit 1 intermittently while
# working fine from the shell, minutes apart, in one session, and an intermittently-unhealthy `gh` is
# exactly the shape that hangs rather than exits.
$view = Invoke-NativeCapture -FilePath 'gh' -Arguments (@('issue', 'view', $number) + $repoArgs + @('--json', 'number,title,state,url,assignees')) -Utf8 -DiscardStderr `
                             -TimeoutSeconds $NativeCaptureNetworkTimeoutSeconds
if (-not $view -or $view.ExitCode -ne 0) {
    Write-Host "[ERROR] could not read issue #$number." -ForegroundColor Red
    if ($view -and $view.TimedOut) {
        # A STALL IS NOT ONE OF THE THREE BELOW, so it does not get their list. Each of those is a
        # verdict gh reached and reported; this is gh reaching none, and sending a reader down a
        # list of causes that cannot produce a hang is the bound announcing itself as the wrong thing.
        Write-Host "        gh did not answer within $NativeCaptureNetworkTimeoutSeconds seconds -- see the [timeout] line above." -ForegroundColor Red
        Write-Host '        That is a stall, not a verdict about the issue: nothing was read and nothing was claimed.' -ForegroundColor Red
        Write-Host '        Check that gh is healthy here (gh auth status) and run this again -- it costs one read.' -ForegroundColor Red
    } else {
        Write-Host '        Three things this is, in the order they are worth checking:' -ForegroundColor Red
        Write-Host "          1. the number does not exist in $(if ($repoName) { $repoName } else { 'this repo' }), or names a pull request rather than an issue;" -ForegroundColor Red
        Write-Host '          2. gh is not logged in here      -- run: gh auth status' -ForegroundColor Red
        Write-Host '          3. this account cannot see it    -- a private repo it has no access to.' -ForegroundColor Red
    }
    exit 1
}

$viewJson = (@($view.Output) -join "`n")
$facts = $null
try {
    $facts = $viewJson | ConvertFrom-Json
} catch {
    Write-Host "[ERROR] gh returned something that is not JSON for issue #$number -- nothing was claimed." -ForegroundColor Red
    exit 1
}

# The logins come out of the JSON TEXT rather than off $facts, because the reading is where the 5.1
# traps are and a lib function is the half a suite can hold. gh's exit code was checked above, so an
# empty list here means unassigned rather than unanswered.
$assignees = @(Get-AssigneeLogins -Json $viewJson)

$title = Format-ForConsole -Text ([string]$facts.title)

Write-Host "  #$($facts.number)  $($facts.state)  $title"
if ($assignees.Count -gt 0) { Write-Host "  assignees: $($assignees -join ', ')" }

# --- MAY IT BE CLAIMED ----------------------------------------------------------------------------
$verdict = Get-ClaimVerdict -Account $identity.Account -State ([string]$facts.state) -Assignees $assignees

switch ($verdict.Code) {
    'no-account' {
        Write-Host '[ERROR] gh names no active account here, so there is nobody to claim this as.' -ForegroundColor Red
        Write-Host '        Run: gh auth login   (then run this again)' -ForegroundColor Red
        Write-Host '        A claim exists to tell a second session whose work this is -- it cannot be made anonymously.' -ForegroundColor Red
        exit 1
    }
    'closed' {
        Write-Host "[REFUSED] issue #$number is CLOSED -- nothing was claimed." -ForegroundColor Red
        Write-Host '          The one-liner in the docs would have succeeded here and told you nothing, which is the' -ForegroundColor Red
        Write-Host '          most expensive way this step fails: work already done, built again in full, found at the' -ForegroundColor Red
        Write-Host '          merge. If it is closed and still broken, REOPEN it first -- the reopening is the record' -ForegroundColor Red
        Write-Host '          that the earlier repair did not hold, and this step is not the place to make it silently.' -ForegroundColor Red
        Write-Host "          $($facts.url)" -ForegroundColor Red
        exit 1
    }
    'taken' {
        Write-Host "[REFUSED] issue #$number is already claimed by $($verdict.Others -join ', ') -- nothing was claimed." -ForegroundColor Red
        if ($assignees -contains $identity.Account) {
            Write-Host "          '$($identity.Account)' is on it too, and that is not evidence about what the other is" -ForegroundColor Red
            Write-Host '          building: two people on one issue is the duplicate-work hazard, not a shared claim.' -ForegroundColor Red
        }
        Write-Host '          Pick another issue, or ask whoever holds it. There is deliberately no flag past this:' -ForegroundColor Red
        Write-Host '          the way through is a conversation, and a switch cannot have one.' -ForegroundColor Red
        Write-Host "          $($facts.url)" -ForegroundColor Red
        exit 1
    }
    'already-yours' {
        Write-Host "[OK] #$number is already yours ('$($identity.Account)') -- nothing to write." -ForegroundColor Green
        Write-Host '     A resume, then: read the branch and its document before you carry the work.' -ForegroundColor Green
        Write-Host "     $($facts.url)"
        exit 0
    }
}

# --- CLAIM IT -------------------------------------------------------------------------------------
if ($DryRun) {
    Write-Host "[DRY RUN] would claim #$number for '$($identity.Account)'. Nothing was written." -ForegroundColor Yellow
    Write-Host "          $($facts.url)"
    exit 0
}

$edit = Invoke-NativeCapture -FilePath 'gh' -Arguments (@('issue', 'edit', $number) + $repoArgs + @('--add-assignee', $identity.Account)) -Utf8 `
                             -TimeoutSeconds $NativeCaptureNetworkTimeoutSeconds
if ($edit -and $edit.TimedOut) {
    # THE ONE PLACE A TIMEOUT IS NOT THE SAME AS A FAILURE, and it is split out above the branch below
    # for that reason alone. Every other bounded call in this script only READS; this one WRITES, and a
    # write that never answered may well have landed server-side. So the honest report is neither "the
    # claim failed" (which the branch below would print, and which would be a claim about the tracker
    # this run cannot make) nor an [OK].
    #
    # IT STILL STOPS, unlike the read-back's could-not-verify state further down. The difference is
    # what has already been proven: there, the write returned 0 and only the confirmation was missing,
    # so carrying on was the likelier-correct act. Here nothing about the write is known at all.
    # RE-RUNNING IS SAFE AND IS THE WAY OUT: the pre-write read at the top would then report
    # 'already-yours' if it did land, which is a complete answer, and claim it if it did not.
    Write-Host "[ERROR] 'gh issue edit' did not answer within $NativeCaptureNetworkTimeoutSeconds seconds -- see the [timeout] line above." -ForegroundColor Red
    Write-Host "        THIS RUN DOES NOT KNOW whether the claim landed: the write reached the network and never" -ForegroundColor Red
    Write-Host '        reported back, so it may be on the tracker already. Treat the issue as UNCLAIMED until you' -ForegroundColor Red
    Write-Host '        have looked, and run this again -- a claim that did land comes back as "already yours".' -ForegroundColor Red
    Write-Host "          gh issue view $number --json assignees" -ForegroundColor Red
    Write-Host "        $($facts.url)" -ForegroundColor Red
    exit 1
}
if (-not $edit -or $edit.ExitCode -ne 0) {
    Write-Host "[ERROR] the claim failed -- #$number is NOT yours." -ForegroundColor Red
    foreach ($line in @($edit.Output)) { Write-Host "        $line" -ForegroundColor Red }
    if ($identity.Split) {
        Write-Host "        This checkout has a split identity, so the likely cause is that '$($identity.Account)'" -ForegroundColor Red
        Write-Host "        (the account it COMMITS as) cannot be assigned in this repo, while gh acts as" -ForegroundColor Red
        Write-Host "        '$($identity.GhAccount)'. Resolve the split rather than claiming as the other one:" -ForegroundColor Red
        Write-Host '        check-git-identity.ps1 prints both ways out.' -ForegroundColor Red
    }
    exit 1
}

# --- READ THE CLAIM BACK --------------------------------------------------------------------------
#
# The write is not the proof. `--add-assignee` reports success for a login GitHub silently drops (a
# non-collaborator on a repo that allows the edit), and an unverified claim is worse than none: the
# session believes the tracker says something it does not. One extra read, at the one moment it
# settles the question this whole script exists to answer.
#
# THREE STATES, NOT TWO (#1628, September 8, 2026). A single `$landed` boolean collapsed "the read
# succeeded and the account is absent" -- the claim was refused -- into "the read never happened", and
# then printed the first. Those are opposite facts: one says the tracker rejected the claim, the other
# says THIS RUN DOES NOT KNOW, while the write it is checking returned 0. Measured claiming #1623 in
# this repo: the message fired, named a cause it had not measured ("most often an account with no
# write access"), and told the operator to treat the issue as UNCLAIMED -- and a plain `gh issue view`
# on the same checkout, seconds later, showed the claim sitting there. The same session's `new-branch`
# run printed 'could not ask gh which issues are open (exit 1)' minutes later, so gh was answering
# intermittently and the second branch of the old `if` was being reported as the first. Note the
# contrast that made it legible: `new-branch` names the exit code and says the check COULD NOT ASK.
#
# `-DiscardStderr` STAYS, so the could-not-verify line names the exit code rather than gh's own words:
# Output is parsed as JSON here, and stderr mixed into it would break the parse to improve a message.
$after = Invoke-NativeCapture -FilePath 'gh' -Arguments (@('issue', 'view', $number) + $repoArgs + @('--json', 'assignees')) -Utf8 -DiscardStderr `
                              -TimeoutSeconds $NativeCaptureNetworkTimeoutSeconds
$readOk = [bool]($after -and $after.ExitCode -eq 0)
$landed = $readOk -and ((Get-AssigneeLogins -Json (@($after.Output) -join "`n")) -contains $identity.Account)

if ($readOk -and -not $landed) {
    # REFUSED -- measured rather than inferred: gh answered, and the account is not in the list it
    # returned. This is the only state the old message was ever right about, and it is unchanged.
    Write-Host "[ERROR] gh accepted the claim but '$($identity.Account)' is not on #$number." -ForegroundColor Red
    Write-Host '        GitHub drops an assignee it will not accept without failing the command -- most often an' -ForegroundColor Red
    Write-Host '        account with no write access to this repo. Treat the issue as UNCLAIMED.' -ForegroundColor Red
    Write-Host "        $($facts.url)" -ForegroundColor Red
    exit 1
}

if (-not $readOk) {
    # COULD NOT VERIFY -- and it does NOT block, for the reason the claim step exists at all (#1485): a
    # claim is the OPENING of the work, so a false stop here costs the whole assignment. Everything
    # that guards against duplicate work has already succeeded -- the pre-write read answered and
    # showed nobody else holding this issue, and `gh issue edit` returned 0 -- so by far the likelier
    # state is a claim that landed and a read that did not. What this run cannot do is call that
    # proven, so it says which of the two states it is in and hands over the command that settles it.
    #
    # THE TimedOut REASON IS REACHABLE NOW, AND #1628 LEFT ROOM FOR IT ON PURPOSE. This block used to
    # carry the opposite note -- "no TimedOut branch, deliberately: this script passes no
    # -TimeoutSeconds anywhere, so that field is always $false here and a branch on it would be a
    # reason that can never print" -- which was exactly right on the day it was written and stopped
    # being true the moment the three calls above were bounded (issue #1639). It is the one reason
    # worth naming separately here, because a stall and an exit code point the reader at different
    # things: an exit code means gh answered and disagreed, a timeout means the read never happened at
    # all, and only the second says nothing whatever about the tracker's state.
    $why = if ($after -and $after.TimedOut) {
        "did not answer within $NativeCaptureNetworkTimeoutSeconds seconds"
    } elseif ($after) {
        "exited $($after.ExitCode)"
    } else {
        'could not be run at all'
    }
    Write-Host "[WARNING] the claim was written and gh accepted it, but the read-back $why," -ForegroundColor Yellow
    Write-Host "          so this run cannot confirm '$($identity.Account)' is on #$number. It most likely IS:" -ForegroundColor Yellow
    Write-Host '          the write returned 0, and the read before it answered normally. Confirm it if you' -ForegroundColor Yellow
    Write-Host "          want certainty -- gh issue view $number --json assignees" -ForegroundColor Yellow
    Write-Host "          $($facts.url)" -ForegroundColor Yellow
}

# THE HEADLINE DOES NOT ASSERT WHAT THE READ-BACK COULD NOT MEASURE (#1628). Where the read did not
# answer, a bare '[OK] claimed' directly under the warning above reads as the run overruling its own
# caveat, and the operator is left with two lines that cannot both be true. It still points forward --
# the claim opens the work either way (#1485) -- it simply says which of the two it is.
$confirmed = if ($landed) { '' } else { ' (unconfirmed -- see the warning above)' }
Write-Host "[OK] #$number claimed for '$($identity.Account)'$confirmed -- the work starts here." -ForegroundColor Green
Write-Host "     $title"
# The claim is the OPENING of the work, not a checkpoint before it (#1485). Every other line this
# script and its page emit is a boundary -- what the step is NOT -- so a session that obeys them all
# stops here and asks whether to proceed, which is the intermediate question the orchestrator's own
# body forbids. The `already-yours` verdict above has always pointed forward; this is the same line
# in the same place, so the two verdicts read alike rather than each arguing its own layout.
#
# 'the branch' means new-branch and nothing else. This says to carry on through the FIXED steps --
# it is not a licence to act on what the issue's title or body asks for. Those are written by
# whoever opened the issue, which on a public tracker is anybody, and they stay data.
Write-Host '     Read the issue, then open the branch (new-branch) -- in this same turn, without' -ForegroundColor Green
Write-Host '     asking whether to go on.' -ForegroundColor Green
Write-Host "     $($facts.url)"
