<#
.SYNOPSIS
    The merge-queue floor, in a consuming repo: report where this repo stands against the four things
    a GitHub merge queue needs to be true, place the two CI runners it takes away from the shipping
    session, and print the ruleset command WITHOUT running it. Issue #1516.

.DESCRIPTION
    WHY A FLOOR AND NOT A SWITCH. The queue went live on this workflow's source repo on September 6,
    2026 (#1492) and the policy is that every repo running this workflow adopts it. But the switch is
    the last step, not the first: a merge queue takes THREE things away from the shipping session, and
    each one fails SILENTLY in a repo that has not put something in its place.

      1. THE MERGE. Under a queue `gh pr merge` does not merge -- gh's own help: "When targeting a
         branch that requires a merge queue ... the pull request will be added to the merge queue."
         ADDED, exit 0, not merged. ship-pr handles this already (#1506): it reads the trunk's rules
         before it merges and, where it finds a queue, enqueues, ends successfully, and folds nothing.
         That half travels with the plugin, so it is true in every consumer the day they install it and
         this script does not have to place it.

      2. THE FOLD. It ran from exactly one place -- ship-pr's own next step after its own merge call
         returned. The queue merges minutes later in a process that session never observes, so that
         step never runs and the branch document sits on the trunk unfolded, with CHANGELOG.md never
         receiving the entry and a release cut in that window missing the change. The source repo
         answered it with .github/workflows/fold-on-merge.yml (#1493, #1507). A consumer has no such
         file, and nothing tells them: ship-pr's enqueue arm PROMISES one.

      3. THE RESOLVES VERIFICATION. verify-resolved-issues.ps1 is ship-pr's step 6, and it went the
         same way for the same reason (#1511). The closing itself is not at risk -- GitHub honours a
         body's keywords on a queue merge exactly as on any other -- but the verification is, and so is
         the repair when a keyword missed, which is the case the script was built for.

    AND ONE PREREQUISITE HAS TO BE TRUE BEFORE THE SWITCH IS FLIPPED AT ALL (#1325): every workflow
    carrying a REQUIRED check context must trigger on `merge_group`. A required workflow without it
    never runs for a queue entry, so its check never reports -- and GitHub's own warning is that the
    merge then fails. That is a TOTAL MERGE OUTAGE on the trunk, not a degradation, and it is invisible
    until the first merge after the switch.

    SO THE ORDER MATTERS AND THIS SCRIPT KEEPS IT: report point 4 (the trigger) and points 2-3 (the
    runners) first, and the switch last. A run that placed the switch first would be the outage.

    IT NEVER FLIPS THE SETTING, AND THAT IS A RULE RATHER THAN A LIMITATION. A ruleset is a
    repo-settings change: irreversible in the sense that matters (it changes what every contributor's
    merge does, immediately, for everybody) and outward-facing. This workflow's own constitution puts
    that class in the owner's hands, so the run composes the exact `gh api` call and stops. Reading the
    rules needs only a token that can read them; writing them needs one that can administer the repo,
    and a script that quietly held the second would be a different kind of tool.

    STRICTLY ADDITIVE, NEVER OVERWRITES, DRY RUN BY DEFAULT -- the same three properties
    adopt-workflow-folder and adopt-config are trusted on, and for the same reason: the first run of a
    command that adds files to your repo should show you the list. A workflow file that is already
    there is left exactly as it is, whatever it contains.

    REFUSED IN THE REPO THAT PUBLISHES THIS WORKFLOW. The source arranges its own runners by hand --
    they are the originals these are derived from, they call its in-repo scripts rather than a
    checked-out mirror, and its fold runner holds a credential decision no scaffold should assert on
    somebody's behalf. Same refusal, same reasoning and the same test (Test-IsWorkflowSourceRepo) as
    adopt-workflow-folder's.

    RUN IT FROM THE ROOT OF THE CONSUMING REPO:

        powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/adopt-merge-queue.ps1"
        powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/adopt-merge-queue.ps1" -Apply

    Exit 0 while the queue is off and the floor is merely unbuilt -- that is a to-do, not a defect.
    Exit 1 when the queue is ACTIVE on the trunk and a piece of the floor is missing, because that is a
    live defect: entries are being stranded, or merges are about to stop.

    Pure ASCII, per this repo's script-layer convention.

.PARAMETER Apply
    Write the runner workflows this repo does not have. Without it the command is a DRY RUN that prints
    exactly what it would create and touches nothing.

.PARAMETER RulesJsonOverride
    A file holding a `gh api repos/<repo>/rules/branches/<trunk>` payload, read instead of calling gh.
    For the test suite, which has to reach the queue-is-active arm without a network or a trunk. A
    consumer never types it.

.EXAMPLE
    .\scripts\task\adopt-merge-queue.ps1
    .\scripts\task\adopt-merge-queue.ps1 -Apply
#>

[CmdletBinding()]
param(
    [switch]$Apply,
    [string]$RulesJsonOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Dual-context repo root: a consumer running the plugin mirror gets it from CLAUDE_PROJECT_DIR, the
# source's root copy falls back to the git root. Same resolution as every other mirrored script.
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# repo-config.ps1 first and optional, exactly as adopt-workflow-folder loads it: it supplies the repo
# slug (Get-RepoName) and any trunk override, and every read below has a fallback.
$repoConfig = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfig -PathType Leaf) {
    try { . $repoConfig } catch { Write-Warning "scripts/repo-config.ps1 failed to load ($($_.Exception.Message)) -- the built-in defaults are used." }
}

. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\seam-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\pr-issues-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# THE SOURCE OF *THIS* WORKFLOW arranges its runners by hand -- see the header -- so this command
# refuses there. Below the dot-sources because the test lives in seam-lib, and still before anything is
# written: loading a lib changes nothing on disk.
if (Test-IsWorkflowSourceRepo -RepoRoot $repoRoot) {
    Write-Host 'REFUSED: this repo publishes this workflow, so it is its source rather than a consumer.' -ForegroundColor Red
    Write-Host 'Its fold-on-merge.yml and verify-resolved.yml are the ORIGINALS these are derived from:'
    Write-Host 'they call its in-repo scripts rather than a checked-out mirror, and the fold runner carries'
    Write-Host 'a push-credential decision no scaffold should make on somebody else''s behalf. Nothing was'
    Write-Host 'written.'
    exit 1
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$nl = "`n"

# THE TRUNK IS READ, NOT ASSUMED. Every string below names it -- the workflow triggers, the rules
# endpoint, the ruleset payload -- and a repo that renamed its trunk would otherwise be handed a floor
# built for a branch it does not have. Get-BranchTrunkName reads the optional Get-TrunkBranchName seam
# and falls back to 'main'.
$trunk = Get-BranchTrunkName

# THE SOURCE OF THE SHARED SCRIPTS the placed runners call. Both files check the plugin's own tree out
# beside the consumer's, exactly as adopt-workflow-folder's branch-entry.yml does, and for the same
# reason: there is ONE definition of the fold and of the resolves check in this system, and a runner
# that carried a hand-written copy would be a second one, free to drift from the first.
$sharedRepo = 'DKJ-Solutions/claude-code-specialists'
$sharedRef  = 'main'
$sharedPath = '.workflow-scripts'
$pluginDir  = "$sharedPath/plugins/dkj-policy/scripts"

# --- What the trunk's own rules say -----------------------------------------------------------------
# READ, NEVER WRITTEN, and read once: both questions below (is there a queue, and which contexts are
# required) come off the same payload, which is the same economy ship-pr's step 0b makes.
#
# AN UNREADABLE PAYLOAD IS NOT "NO QUEUE", and this script must not collapse the two any more than
# ship-pr does. A consumer whose token cannot read a ruleset, or who is offline, gets a report that says
# the question was not answered -- and it still reports and places everything that does not depend on
# the answer, because the floor is worth building either way.
$rulesJson = ''
$rulesSource = ''
if ($RulesJsonOverride) {
    if (Test-Path -LiteralPath $RulesJsonOverride -PathType Leaf) {
        $rulesJson = [System.IO.File]::ReadAllText($RulesJsonOverride)
        $rulesSource = "the payload in $RulesJsonOverride"
    }
} else {
    $repoSlug = ''
    if (Get-Command -Name 'Get-RepoName' -ErrorAction SilentlyContinue) { $repoSlug = [string](Get-RepoName) }
    if (-not $repoSlug) {
        # No seam answer: ask gh what repo this checkout is. A consumer that has not answered
        # Get-RepoName yet is exactly the fresh adoption this command is for, so refusing here would
        # gate the floor on a seam that has nothing to do with it.
        $slugRead = Invoke-NativeCapture -FilePath 'gh' -DiscardStderr -Arguments @('repo', 'view', '--json', 'nameWithOwner', '--jq', '.nameWithOwner')
        if ($slugRead.ExitCode -eq 0) { $repoSlug = ($slugRead.Output -join '').Trim() }
    }
    if ($repoSlug) {
        # -DiscardStderr because this output is PARSED: a gh warning merged into it would break the
        # ConvertFrom-Json and cost the read. Same reasoning as ship-pr's own rules call.
        $rulesRead = Invoke-NativeCapture -FilePath 'gh' -DiscardStderr -Arguments @('api', "repos/$repoSlug/rules/branches/$trunk")
        if ($rulesRead.ExitCode -eq 0) {
            $rulesJson = $rulesRead.Output -join "`n"
            $rulesSource = "gh api repos/$repoSlug/rules/branches/$trunk"
        }
    }
}

$queueVerdict = Get-MergeQueueVerdict -BranchRulesJson $rulesJson
$queueReadable = $queueVerdict.Readable
$queueActive = ($queueVerdict.Readable -and $queueVerdict.Active)

# The REQUIRED check contexts, off the same payload. Get-DirectPushBlockingRules already collects them
# -- it reads them so its own refusal can name what the remote would have named -- so asking it here
# adds no parsing of its own and cannot disagree with what ship-pr reads.
$requiredContexts = @()
if ($queueReadable) {
    foreach ($rec in (Get-DirectPushBlockingRules -BranchRulesJson $rulesJson).Blocking) {
        $requiredContexts += @($rec.Contexts)
    }
    $requiredContexts = @($requiredContexts | Sort-Object -Unique)
}

# --- Which workflow carries which required check ----------------------------------------------------
function Get-WorkflowFacts {
    <#
        One record per .github/workflows/*.yml: its path, the job keys and job names it declares, and
        whether its `on:` block carries a merge_group trigger.

        THE TRIGGER IS MATCHED AS A KEY OF THE `on:` BLOCK, not as the word anywhere in the file. Every
        paragraph of reasoning about a queue names `merge_group` too, so a substring test would report a
        workflow as ready on the strength of a comment about it -- which is the exact silent state this
        whole command exists to prevent. Same property merge-queue-prereq.tests.ps1 asserts on the
        source's own ci.yml, and deliberately the same regex shape.

        A CHECK CONTEXT IS A JOB, NOT A FILE, which is why the job keys are collected at all. GitHub
        names an Actions check after the job's `name:` where it has one and after its key otherwise
        (measured on this workflow's source: the required context `lint-en-tests` is the key of a job
        in ci.yml that declares no name). Both are collected, and a context matching neither is
        reported as unmatched rather than guessed at -- an unmatched context is a real answer here,
        because a required check may come from something other than Actions.
    #>
    param([Parameter(Mandatory)][string]$WorkflowDir)

    $facts = @()
    if (-not (Test-Path -LiteralPath $WorkflowDir -PathType Container)) { return @() }
    foreach ($f in @(Get-ChildItem -LiteralPath $WorkflowDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in @('.yml', '.yaml') })) {
        $text = [System.IO.File]::ReadAllText($f.FullName)

        $onBlock = [regex]::Match($text, '(?ms)^on:\r?\n(?<body>(?:[ \t]+\S[^\r\n]*\r?\n)+)')
        $hasMergeGroup = $onBlock.Success -and ($onBlock.Groups['body'].Value -match '(?m)^\s{2}merge_group:')
        $onPullRequest = $onBlock.Success -and ($onBlock.Groups['body'].Value -match '(?m)^\s{2}pull_request:')

        # The jobs block runs to the end of the file: `jobs:` is conventionally last, and a top-level key
        # after it would end the match at that key's own column-0 line.
        $jobsBlock = [regex]::Match($text, '(?ms)^jobs:\r?\n(?<body>(?:(?:[ \t]+[^\r\n]*|\s*)\r?\n)+)')
        $ids = @()
        if ($jobsBlock.Success) {
            foreach ($m in [regex]::Matches($jobsBlock.Groups['body'].Value, '(?m)^\s{2}(?<key>[A-Za-z0-9_.\-]+):\s*$')) {
                $ids += $m.Groups['key'].Value
            }
            foreach ($m in [regex]::Matches($jobsBlock.Groups['body'].Value, '(?m)^\s{4}name:\s*(?<name>\S[^\r\n]*)$')) {
                $ids += ($m.Groups['name'].Value.Trim().Trim('''"'))
            }
        }

        $facts += [pscustomobject]@{
            Name          = $f.Name
            Rel           = ".github/workflows/$($f.Name)"
            JobIds        = @($ids | Sort-Object -Unique)
            HasMergeGroup = $hasMergeGroup
            OnPullRequest = $onPullRequest
        }
    }
    return @($facts)
}

$workflowDir = Join-Path $repoRoot '.github\workflows'
$workflows = Get-WorkflowFacts -WorkflowDir $workflowDir

# --- The two runners, consumer-shaped ---------------------------------------------------------------
# DERIVED FROM THE SOURCE'S OWN, NOT COPIED. Two things differ, both of them structural rather than
# stylistic: the scripts are reached through a checkout of the plugin's tree instead of the repo's own
# (there is one definition of the fold in this system and this must not become a second), and
# CLAUDE_PROJECT_DIR is set so those mirrored scripts judge the CONSUMER's tree rather than the checked
# out one. The reasoning paragraphs are the source's, kept, because a runner whose "why" was stripped is
# the first thing a later sweep deletes as dead configuration.
$foldRunner = @(
    '# Folds a queue-merged PR''s changelog entry, since the session that ships it never sees the merge.',
    '#',
    '# WHAT THIS CLOSES. fold-changelog-entry.ps1 runs from exactly one place -- ship-pr.ps1, as the',
    '# shipping session''s own next step after its own merge call returns. A merge queue merges the PR',
    '# itself, minutes later, in a process that session never observes, so that step never runs: the',
    ('# branch''s development document sits on the trunk unfolded, the changelog never receives the entry,'),
    '# and a release cut in that window misses the change. This workflow is the fold running from the one',
    '# place that always sees a queue merge: a push to the trunk. It also catches a PR merged from the',
    '# GitHub UI, which skips the fold for the same reason.',
    '#',
    '# IT ADDS NO RULE OF ITS OWN, AND NO SECOND DETECTOR. It runs the plugin''s check-unfolded-entry.ps1',
    '# unchanged, and only when THAT finds a leftover does it call the plugin''s fold-changelog-entry.ps1.',
    '# Both are reached through a checkout of the plugin''s own tree rather than copied here, so there is',
    '# one definition of "a written entry stranded on the trunk" in the system instead of two.',
    '#',
    '# THE PUSH NEEDS A CREDENTIAL YOU HAVE TO CREATE -- FOLD_PUSH_TOKEN, AND THIS FILE DOES NOT WORK',
    '# WITHOUT IT. A merge_queue rule blocks every direct push to the trunk unless the pushing actor is a',
    '# listed bypass actor, and the default GITHUB_TOKEN pushes as the GitHub Actions app, which cannot be',
    '# added to that list (an Integration bypass actor has to be an app installed on the org, and that one',
    '# is not administered by yours). So this job checks out with a fine-grained personal access token',
    '# belonging to somebody who already bypasses the ruleset -- scoped to this repository only, and to',
    '# Contents: Read and write only. It is a STANDING credential, valid from anywhere until it expires,',
    '# and actions/checkout writes it into the workspace git config, so every step of this job holds it.',
    '# That is why nothing else is ever added to this job. Rotate it before it expires or this job starts',
    '# failing its push with no code-level cause.',
    '#',
    '# READ THE FOLD STEP''S OWN LAST LINES BEFORE CONCLUDING ANYTHING FROM A RED RUN. Two entirely',
    '# different things turn this job red -- the fold refusing, and the fold succeeding and its push being',
    '# rejected by the ruleset -- and only the log tells them apart.',
    '#',
    '# NO CONCURRENCY CANCELLATION. This job WRITES: cancelling a fold in progress is exactly the silent',
    '# skip it exists to close, so every push gets its own run and none is dropped.',
    '#',
    '# WINDOWS: the shared scripts target Windows PowerShell 5.1, which is what ''shell: powershell'' is.',
    'name: Fold on merge',
    '',
    '# contents: read, deliberately -- the actual push authenticates as FOLD_PUSH_TOKEN, wired into the',
    '# checkout step below, and never touches this block. pull-requests: read is not optional: the fold''s',
    '# own PR lookup needs it, and declaring any permissions block at all sets every unlisted scope to none.',
    'permissions:',
    '  contents: read',
    '  pull-requests: read',
    '',
    'on:',
    '  push:',
    ('    branches: [' + $trunk + ']'),
    '',
    'concurrency:',
    '  group: fold-on-merge-${{ github.sha }}',
    '  cancel-in-progress: false',
    '',
    'jobs:',
    '  fold-on-merge:',
    '    runs-on: windows-latest',
    '    steps:',
    '      - uses: actions/checkout@v5',
    '        with:',
    '          token: ${{ secrets.FOLD_PUSH_TOKEN }}',
    '',
    '      - name: Fetch the shared workflow scripts',
    '        uses: actions/checkout@v5',
    '        with:',
    ('          repository: ' + $sharedRepo),
    ('          ref: ' + $sharedRef),
    ('          path: ' + $sharedPath),
    '',
    '      # continue-on-error is deliberate: the check exits non-zero on a genuine FIND, which is the',
    '      # case this job exists to act on, not a step failure. The fold step below tells that apart',
    '      # from a real crash in the detector rather than folding blind on an outcome it cannot explain.',
    '      - name: Is there an unfolded changelog entry on the trunk?',
    '        id: check',
    '        shell: powershell',
    '        continue-on-error: true',
    '        env:',
    '          CLAUDE_PROJECT_DIR: ${{ github.workspace }}',
    '        run: |',
    ('          powershell -NoProfile -ExecutionPolicy Bypass -File ' + $pluginDir + '/lint/check-unfolded-entry.ps1 -Branch ' + $trunk + ' *>&1 | Tee-Object -FilePath check-output.txt'),
    '          exit $LASTEXITCODE',
    '',
    '      - name: Fold it (every leftover this push may carry)',
    '        if: ${{ steps.check.outcome == ''failure'' }}',
    '        shell: powershell',
    '        env:',
    '          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}',
    '          GH_REPO: ${{ github.repository }}',
    '          CLAUDE_PROJECT_DIR: ${{ github.workspace }}',
    '        run: |',
    '          # The check''s own known-good signature is what tells "a leftover was found" apart from',
    '          # "the script crashed for some other reason" -- both exit non-zero, and only one of them',
    '          # is safe to act on.',
    '          $checkOutput = Get-Content check-output.txt -Raw',
    '          if ($checkOutput -notmatch ''\[ERROR\] the trunk carries'') {',
    '            Write-Error "check-unfolded-entry.ps1 exited non-zero for a reason other than a reported leftover -- refusing to fold blind. Its output:`n$checkOutput"',
    '            exit 1',
    '          }',
    '',
    '          # Commit-metadata identity only -- who authored the commit. It is independent of the',
    '          # push''s credential (FOLD_PUSH_TOKEN, wired in by the checkout step above): a ruleset',
    '          # bypass is checked against the pushing token''s identity, not the commit author.',
    '          git config user.name "github-actions[bot]"',
    '          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"',
    ('          powershell -NoProfile -ExecutionPolicy Bypass -File ' + $pluginDir + '/release/fold-changelog-entry.ps1 -Commit -Push *>&1 | Tee-Object -FilePath fold-output.txt'),
    '          $foldExitCode = $LASTEXITCODE',
    '',
    '          # The two scripts read the same trunk a moment apart and must agree: the check found a',
    '          # leftover, so the fold reporting nothing to fold is a real disagreement between them.',
    '          $foldOutput = Get-Content fold-output.txt -Raw',
    '          if ($foldOutput -match ''No entry files found to fold'') {',
    '            Write-Error "check-unfolded-entry.ps1 reported a leftover but fold-changelog-entry.ps1 found nothing to fold -- the two disagree, which should not happen. Its output:`n$foldOutput"',
    '            exit 1',
    '          }',
    '          exit $foldExitCode'
)

$resolvesRunner = @(
    '# Verifies the issues a merged PR declared it closes -- from the merge, since the shipping session',
    '# no longer sees one.',
    '#',
    '# WHAT THIS CLOSES. verify-resolved-issues.ps1 is ship-pr.ps1''s step 6: it reads a merged PR''s body',
    '# back out and checks that every issue declared there with a closing keyword is actually CLOSED,',
    '# closing the ones that are not. It ran from exactly one place -- the shipping session, right after',
    '# its own merge call returned. A merge queue takes that call away: ship-pr enqueues and exits, and',
    '# the merge lands minutes later in a process that session never observes.',
    '#',
    '# THE CLOSING ITSELF IS NOT AT RISK. GitHub honours a body''s keywords on a queue merge exactly as on',
    '# any other. What is lost is the VERIFICATION that it happened, and the REPAIR when a keyword missed',
    '# -- which is the case the script was built for: a body carrying a plain mention instead of a keyword',
    '# closes nothing, and nobody finds out.',
    '#',
    '# ITS OWN WORKFLOW, NOT A STEP IN fold-on-merge.yml, AND THAT IS THE SECURITY ARGUMENT. That job',
    '# checks out with a standing personal access token that actions/checkout writes into the workspace,',
    '# so every step of it holds that credential. Adding issues: write there would put a standing',
    '# credential and issue-write in one job. Here they never meet: this job checks out with the default',
    '# job-scoped GITHUB_TOKEN, which expires in about an hour and is unusable outside this run.',
    '#',
    '# THE SECOND REASON FOR ITS OWN FILE IS COVERAGE. The fold runner acts only when a leftover entry is',
    '# on the trunk, because an entry is what a fold needs. This check has to run for EVERY merge --',
    '# including one carrying no changelog entry at all -- so it resolves its PRs from the push itself.',
    '#',
    '# NO CONCURRENCY CANCELLATION: this job ACTS, so letting a later push supersede an in-flight run',
    '# would drop the verification of whatever the earlier push carried. Two runs overlapping is harmless',
    '# -- the second finds every issue already closed and says so.',
    '#',
    '# WINDOWS: the shared scripts target Windows PowerShell 5.1, which is what ''shell: powershell'' is.',
    'name: Verify resolved issues',
    '',
    'permissions:',
    '  contents: read',
    '  pull-requests: read',
    '  # THE ONE WIDENING, and the whole of it: without this scope the repair is a 403 and this job is a',
    '  # reporter. Granted on the job-scoped GITHUB_TOKEN only.',
    '  issues: write',
    '',
    'on:',
    '  push:',
    ('    branches: [' + $trunk + ']'),
    '',
    'concurrency:',
    '  group: verify-resolved-${{ github.sha }}',
    '  cancel-in-progress: false',
    '',
    'jobs:',
    '  verify-resolved:',
    '    runs-on: windows-latest',
    '    steps:',
    '      # persist-credentials: false -- this job reads and calls the API, and never pushes. Nothing',
    '      # here needs a git credential left in the workspace.',
    '      - uses: actions/checkout@v5',
    '        with:',
    '          persist-credentials: false',
    '',
    '      - name: Fetch the shared workflow scripts',
    '        uses: actions/checkout@v5',
    '        with:',
    ('          repository: ' + $sharedRepo),
    ('          ref: ' + $sharedRef),
    ('          path: ' + $sharedPath),
    '',
    '      # THE EVENT''S VALUES ARRIVE THROUGH env:, NOT THROUGH ${{ }} INSIDE run:. Interpolating an',
    '      # expression into a shell body substitutes it as TEXT before the shell parses the line, which',
    '      # is the standard Actions script-injection shape. These are SHAs and a repository name GitHub',
    '      # computes itself, so there is nothing to inject today -- the point is that this file should',
    '      # not have to be re-argued if a later edit reaches for a branch name or a PR title.',
    '      - name: Verify the issues this push''s pull requests declared they close',
    '        shell: powershell',
    '        env:',
    '          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}',
    '          GH_REPO: ${{ github.repository }}',
    '          PUSH_BEFORE: ${{ github.event.before }}',
    '          PUSH_SHA: ${{ github.sha }}',
    '          CLAUDE_PROJECT_DIR: ${{ github.workspace }}',
    '        run: |',
    ('          powershell -NoProfile -ExecutionPolicy Bypass -File ' + $pluginDir + '/release/verify-pushed-merges.ps1 `'),
    ('            -Before $env:PUSH_BEFORE -Sha $env:PUSH_SHA -Trunk ' + $trunk + ' -Repo $env:GH_REPO'),
    '          exit $LASTEXITCODE'
)

$targets = @(
    @{ Rel = '.github/workflows/fold-on-merge.yml';   Content = (($foldRunner -join $nl) + $nl);     What = 'the fold, which the queue takes away from the shipping session' },
    @{ Rel = '.github/workflows/verify-resolved.yml'; Content = (($resolvesRunner -join $nl) + $nl); What = 'the resolves verification, which the queue takes away too' }
)

# --- Report ------------------------------------------------------------------------------------------
Write-Host "== adopt-merge-queue -- $repoRoot ==" -ForegroundColor Cyan
if (-not $Apply) { Write-Host '  DRY RUN -- nothing is written. Re-run with -Apply to place the files below.' -ForegroundColor Yellow }
Write-Host ''

$liveDefects = 0

# 1. THE TRIGGER, FIRST, because it is the one that is an OUTAGE rather than a gap. It is also the one
#    piece of the floor this command cannot place: the workflow carrying your required check is yours,
#    and adding a trigger to it is an edit to somebody else's file rather than an addition beside it.
Write-Host '-- 1. the merge_group trigger on every REQUIRED check --' -ForegroundColor Cyan
if (-not $queueReadable) {
    Write-Host "  [skip]    the trunk's rules could not be read, so which checks are REQUIRED is unknown." -ForegroundColor DarkGray
    Write-Host '            Every workflow below is listed with its trigger so you can judge it yourself.' -ForegroundColor DarkGray
    foreach ($w in $workflows | Where-Object { $_.OnPullRequest }) {
        $mark = if ($w.HasMergeGroup) { 'has merge_group' } else { 'NO merge_group' }
        Write-Host "            $($w.Rel) -- $mark" -ForegroundColor DarkGray
    }
} elseif ($requiredContexts.Count -eq 0) {
    Write-Host "  [gap]     no required status check on '$trunk'. A queue with nothing required certifies nothing:" -ForegroundColor Yellow
    Write-Host '            every entry merges unverified, which is weaker than what you have today.' -ForegroundColor Yellow
    Write-Host '            Make your CI check required on the trunk before switching a queue on.' -ForegroundColor Yellow
} else {
    foreach ($ctx in $requiredContexts) {
        $owner = @($workflows | Where-Object { $_.JobIds -contains $ctx })
        if ($owner.Count -eq 0) {
            Write-Host "  [note]    required check '$ctx' matches no job in .github/workflows/ -- it comes from" -ForegroundColor Yellow
            Write-Host '            somewhere else (another app, or a job name this reader cannot see). If it IS an' -ForegroundColor Yellow
            Write-Host '            Actions job, that workflow needs the merge_group trigger too.' -ForegroundColor Yellow
            continue
        }
        foreach ($w in $owner) {
            if ($w.HasMergeGroup) {
                Write-Host "  [ok]      required check '$ctx' -> $($w.Rel), which triggers on merge_group." -ForegroundColor Green
            } elseif ($queueActive) {
                $liveDefects++
                Write-Host "  [ERROR]   required check '$ctx' -> $($w.Rel), which does NOT trigger on merge_group," -ForegroundColor Red
                Write-Host "            and a queue is ACTIVE on '$trunk'. That check never reports for a queue entry," -ForegroundColor Red
                Write-Host '            so every merge fails. Add to its on: block, at two spaces of indent:' -ForegroundColor Red
                Write-Host '              merge_group:' -ForegroundColor Red
            } else {
                Write-Host "  [gap]     required check '$ctx' -> $($w.Rel), which does NOT trigger on merge_group." -ForegroundColor Yellow
                Write-Host '            Inert today; a TOTAL MERGE OUTAGE the moment a queue is switched on. Add to its' -ForegroundColor Yellow
                Write-Host '            on: block, at two spaces of indent:' -ForegroundColor Yellow
                Write-Host '              merge_group:' -ForegroundColor Yellow
            }
        }
    }
}
Write-Host ''

# 2 + 3. THE TWO RUNNERS. These this command CAN place: they are new files beside yours, not edits to
#        one of them, which is the same line adopt-workflow-folder draws.
Write-Host '-- 2. the two runners a queue takes away from the shipping session --' -ForegroundColor Cyan
$created = 0
$kept = 0
foreach ($t in $targets) {
    $abs = Join-Path $repoRoot ($t.Rel -replace '/', '\')
    if (Test-Path -LiteralPath $abs) {
        $kept++
        Write-Host "  [exists]  $($t.Rel) -- left as it is" -ForegroundColor DarkGray
        continue
    }
    if ($queueActive -and -not $Apply) { $liveDefects++ }
    $created++
    if ($Apply) {
        $dir = Split-Path -Parent $abs
        if (-not (Test-Path -LiteralPath $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force }
        [System.IO.File]::WriteAllText($abs, $t.Content, $Utf8NoBom)
        Write-Host "  [created] $($t.Rel) -- $($t.What)" -ForegroundColor Green
    } else {
        $marker = if ($queueActive) { '[MISSING]' } else { '[create] ' }
        $colour = if ($queueActive) { 'Red' } else { 'Green' }
        Write-Host "  $marker $($t.Rel) -- $($t.What)" -ForegroundColor $colour
    }
}
if ($created -gt 0) {
    Write-Host ''
    Write-Host '  THE FOLD RUNNER NEEDS A SECRET YOU HAVE TO CREATE: FOLD_PUSH_TOKEN.' -ForegroundColor Yellow
    Write-Host '  A merge_queue rule blocks every direct push to the trunk, and the default GITHUB_TOKEN' -ForegroundColor Yellow
    Write-Host '  cannot be given a bypass. Create a fine-grained PAT owned by somebody who already bypasses' -ForegroundColor Yellow
    Write-Host '  the ruleset, scoped to this repository and to Contents: Read and write, and store it as' -ForegroundColor Yellow
    Write-Host '  the repository secret FOLD_PUSH_TOKEN. Without it the fold commits and its push is' -ForegroundColor Yellow
    Write-Host '  rejected -- which is the same merged-but-unfolded state, reached one step later.' -ForegroundColor Yellow
}
Write-Host ''

# 4. THE SWITCH, LAST, AND NEVER PULLED HERE.
Write-Host '-- 3. the queue itself --' -ForegroundColor Cyan
if (-not $queueReadable) {
    Write-Host "  [skip]    the trunk's rules could not be read here -- no gh, no network, or a token that" -ForegroundColor DarkGray
    Write-Host '            cannot read rulesets. That is not "no queue": nothing above assumed either way.' -ForegroundColor DarkGray
    Write-Host "            Read it yourself with:  gh api repos/<owner>/<repo>/rules/branches/$trunk --jq '[.[].type]'" -ForegroundColor DarkGray
} elseif ($queueActive) {
    Write-Host "  [ok]      a merge_queue rule is active on '$trunk' ($rulesSource)." -ForegroundColor Green
} else {
    Write-Host "  [gap]     no merge_queue rule on '$trunk'. Every repo running this workflow adopts one:" -ForegroundColor Yellow
    Write-Host '            it is the only remedy for the staleness race that converges, because a queue tests' -ForegroundColor Yellow
    Write-Host '            each PR against the PROJECTED merge rather than against the base it was branched' -ForegroundColor Yellow
    Write-Host '            from. Switch it on in Settings -> Rules -> Rulesets, on the ruleset that already' -ForegroundColor Yellow
    Write-Host "            protects '$trunk', by adding the 'Require merge queue' rule." -ForegroundColor Yellow
    Write-Host '' -ForegroundColor Yellow
    Write-Host '            THIS COMMAND WILL NOT DO IT FOR YOU, and that is deliberate: a ruleset changes what' -ForegroundColor Yellow
    Write-Host '            every contributor''s merge does, immediately, for everybody. It is the repo owner''s' -ForegroundColor Yellow
    Write-Host '            act. Do points 1 and 2 above FIRST -- flipping this with a required check that has' -ForegroundColor Yellow
    Write-Host '            no merge_group trigger is a total merge outage on the first merge afterwards.' -ForegroundColor Yellow
}
Write-Host ''

if ($Apply) {
    Write-Host "Done: $created runner(s) created, $kept left as they were." -ForegroundColor Green
} else {
    Write-Host "Would create $created runner(s); $kept already exist. Re-run with -Apply." -ForegroundColor Yellow
}

# EXIT 1 ONLY ON A LIVE DEFECT, and the distinction is the whole point of the two vocabularies above. A
# '[gap]' is work not yet done on a repo whose merges are fine today; an '[ERROR]' is a queue that is
# already running against a floor that is not there -- entries being stranded on the trunk, or merges
# about to stop. Exiting 1 on the first would make an honest to-do list read as a broken repo, which is
# how a report earns being ignored.
if ($liveDefects -gt 0) {
    Write-Host "$liveDefects live defect(s): the queue on '$trunk' is ACTIVE and the floor under it is incomplete." -ForegroundColor Red
    exit 1
}
exit 0
