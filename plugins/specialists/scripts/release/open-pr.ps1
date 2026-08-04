<#
.SYNOPSIS
    Push the current branch and open a Pull Request to main -- or update the PR it already has.

.DESCRIPTION
    Pushes the current branch to origin and creates a PR to main via the GitHub CLI. Guardrail:
    refuses if you are on main. Uses .github/pull_request_template.md as the starting point for
    the PR body unless you supply -Body yourself (NOTE: gh pr create --fill fills the body with
    the full commit history since main, not with the template -- so don't use that if you want
    the checklist template).

    RESUMABLE: if the branch ALREADY has an open PR, the gates and the push still run and the
    `gh pr create` is skipped -- the push is what updates an existing PR, so this exits 0 with the
    PR number instead of failing. Before this, `gh pr create` was unconditional and returned a
    non-zero exit code on a duplicate, which made the whole of ship-pr.ps1 unusable on a branch whose
    PR had been opened in an earlier session: step 1 died and steps 2-6 (CI watch, merge, fold,
    issue verification) never ran, so the merge and the fold had to be done by hand -- exactly the
    five-step sequence ship-pr exists to remove. Measured August 4, 2026 on PR #457.

    Title and body are deliberately LEFT ALONE when a PR already exists. The body may have been
    edited on github.com since it was opened, and silently overwriting a reviewer's or the author's
    edits with a freshly generated template is a worse failure than a stale title: the title is
    visible on the PR, an overwritten body is gone. Retitle with `gh pr edit` if you want it changed.

    ONE exception, and it APPENDS rather than replaces: a -Resolves this run declares that the existing
    body does not already carry is added to it. Skipping that would drop the declaration on the floor --
    GitHub closes what the body says at merge time, so the issue would stay open and ship-pr.ps1's
    step 6 would read the same body back and confirm the same silence. That is the #341-#343 failure
    reached from the other direction, so it is repaired here rather than left to the author. A failed
    append is a hard stop (exit 1), because the branch is pushed by then and merging it would publish
    the loss.

    Auto-fill (if you do NOT supply -Body): the script fills in the template itself as much as
    possible, so the PR never lands on github.com as an empty form:
      1. The correct "Type of change" box is ticked based on the branch prefix (the same source
         as the label -- the `<prefix>/` rule in the template).
      2. "What does this change do?" is filled with the description from the changelog entry file
         (<SafeName>.md in the repo root), which always exists on the branch. So you never have to
         type anything twice.
      3. The two checklist items that are always true at that point are ticked: "Changelog entry
         file created" (exists, since it was just read) and "Requested by Dave" (the script only
         runs at Dave's request). The remaining checklist items stay empty -- those are human
         judgement checks the script cannot honestly verify.
      If you do supply -Body, it is used literally (override).

      The description placeholder(s) and the approval-checklist pattern used for steps 2 and 3 are
      configurable per repo (#101): if scripts\repo-config.ps1 defines the optional
      Get-PrDescriptionPlaceholder / Get-PrApprovalPattern functions, those are used; otherwise the
      script falls back to this repo's own template markers (current behavior, unchanged) -- so a
      consumer whose PR template uses different marker text can point at its own markers without a
      wrapper script.

    Optional assignee/milestone (#101): if scripts\repo-config.ps1 defines Get-PrAssignee and/or
    Get-PrMilestone (both optional), a non-empty return value is passed to `gh pr create` as
    --assignee / --milestone. Not defined, or an empty return value: the flag is simply omitted
    (current behavior, unchanged).

    ALWAYS sets a GitHub label based on the branch prefix (every PR has a label). The
    prefix-to-label table lives in scripts/lib/branch-info.ps1 (shared with the other scripts) and
    follows the main categories of the PR template. Unknown prefix -> label 'question' + warning
    (= needs further classification).

    Scaffold gate (measured at v3.2.0): the branch's changelog entry must no longer carry the wording
    new-changelog-entry.ps1 scaffolded it with -- the placeholder title, the "to do / where I left off"
    heading or the fallback body (whatever this repo configured them to be; entry-scaffold-lib.ps1 is the
    single source, shared with the script that writes them). Three of v3.2.0's twenty-one entries kept
    that heading with a status appended, and it reached the release notes and the per-plugin CHANGELOGs
    that travel to consumers. The window closes at the merge and closes INVISIBLY, because by then the
    text has moved out of CHANGELOG.md's Pull Requests section into files nobody re-reads. Fenced code is
    excluded, so an entry documenting this mechanism is not accused of it. Use -Force to ship anyway.

    Lint gate (guardrail for main): before the push, scripts/lint/check-plugin-integrity.ps1 runs.
    If that finds errors (invalid marketplace/plugin manifests, missing agent-def frontmatter,
    dead links), the branch is NOT pushed and NO PR is opened. Use -SkipLint to deliberately skip
    the gate (escape valve).

    Test gate (a lesson from PR #54, where a red suite only surfaced on CI): after the lint, ALL
    test suites run (scripts/tests/*.tests.ps1), exactly as CI does. A failing suite blocks the
    push and the PR. Use -SkipTests to deliberately skip this gate (escape valve).

    Resolves gate (a lesson from PRs #341-#343): a PR that repairs an issue must say so with a
    CLOSING KEYWORD, or the issue stays open after the merge. Those three PRs each referenced their
    issues as a plain mention (`#332`), GitHub therefore auto-closed nothing, and the manual
    `gh issue close` was skipped three times running -- leaving eight repaired findings OPEN while
    the changelog said they were done. So the decision is now forced rather than remembered:
      - `-Resolves 331,332` writes a `## Resolved issues` block with one `Closes #<n>` per issue
        (one per line, because GitHub does not distribute a single keyword over a list -- a comma
        form would close the first and silently leave the rest open);
      - `-NoResolves` declares "this PR closes no issue" and is the deliberate way past the gate;
      - neither, while the changelog entry mentions an issue that is currently OPEN -> the gate
        BLOCKS before the lint, the tests, and the push. PR references (`PR #341`, `/pull/341`) are
        not counted, so citing the PR you follow on from does not trip it.
    A `-Body` you supply that already carries a closing keyword satisfies the gate on its own, and so
    does the body of an ALREADY OPEN PR for this branch -- otherwise resuming such a branch would be
    blocked for not repeating a decision that is already published on the PR, where GitHub will honour
    it at the merge regardless of what this run declares. If the
    open/closed state cannot be determined (gh unavailable or failing), the gate WARNS and lets the PR
    through -- wedging the PR flow on a network hiccup would be worse than the slip it guards against.
    The decision table lives in scripts/lib/pr-issues-lib.ps1 and is covered by
    scripts/tests/pr-issues.tests.ps1.

.PARAMETER Title
    PR title, e.g. "feat: new domain plugin" or "fix: broken agent-def frontmatter".

.PARAMETER Body
    (Optional) PR description. Default: the filled-in .github/pull_request_template.md.

.PARAMETER Resolves
    (Optional) Issue numbers this PR resolves, as a string: -Resolves '331,332' (a leading '#' and
    spaces or semicolons as separators are fine too). Each number gets its own `Closes #<n>` line in
    the PR body, so GitHub closes them when the PR merges.

    A STRING and not an [int[]] on purpose: `powershell -File` (how ship-pr.ps1 and the test fixtures
    call this script) never builds an array from the command line -- '332,340' would arrive as one
    string and be cast to the single number 332340, reading the comma as a thousands separator. That
    is silent, not an error, so the parameter takes the raw text and
    ConvertTo-IssueNumberList parses it.

.PARAMETER NoResolves
    Declare that this PR closes no issue. The deliberate way past the resolves gate.

.PARAMETER Force
    Ship an entry that still carries its scaffold wording -- the escape valve for the scaffold gate,
    for the rare entry that legitimately quotes that wording outside a fence. Warns instead of blocking.
    Deliberately separate from -SkipLint/-SkipTests: those skip a tool, this overrules a content
    judgement, and conflating them would let a routine "skip the slow suites" also wave prose through.

.EXAMPLE
    ./scripts/release/open-pr.ps1 -Title "feat: new domain plugin"

.EXAMPLE
    ./scripts/release/open-pr.ps1 -Title "fix: the pre-flight reads commits" -Resolves 331,332
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Title,
    [string]$Body = '',
    [switch]$SkipLint,
    [switch]$SkipTests,
    [string]$Resolves = '',
    [switch]$NoResolves,
    [switch]$Force
)
$ErrorActionPreference = 'Stop'

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Pre-flight (#86): the shared scripts rely on two repo-owned files in the consumer's repo root.
# If they are missing -- typically on a clean consumer where they have not yet been created --
# stop with a clear pointer instead of a raw dot-source error (the path-not-found you would
# otherwise get on the . (dot-source) lines below).
$needed = @('scripts\repo-config.ps1', 'scripts\lib\branch-info.ps1')
$absent = @($needed | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_)) })
if ($absent.Count -gt 0) {
    Write-Error ("open-pr cannot run -- missing repo-owned configuration in the repo root ($repoRoot):`n  " + ($absent -join "`n  ") + "`n`nThese files are repo-specific and belong in the consumer's repo root:`n  scripts\repo-config.ps1      -- Get-RepoName / Get-RepoBlobUrl / Get-LintScript`n  scripts\lib\branch-info.ps1  -- the repo-owned branch-prefix table`n`nCreate them (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward.")
    exit 1
}

# Repo-owned config + shared branch lib from the repo root (single source). Deliberately from
# $repoRoot and not $PSScriptRoot: from the plugin mirror, $PSScriptRoot points to the plugin
# cache, while repo-config/branch-info always live in the consumer's repo root.
. (Join-Path $repoRoot 'scripts\repo-config.ps1')
. (Join-Path $repoRoot 'scripts\lib\branch-info.ps1')
$repo = Get-RepoName

# Shared native-capture helper (#114 item 1). $PSScriptRoot-relative, not $repoRoot: like
# check-report-lib.ps1 this lib is not repo-owned -- it travels with the SAME plugin/mirror payload
# as this script (registered in scripts\lib\shared-scripts-lib.ps1), so it resolves from the
# workshop root, a consumer's plugin cache, or the plugin mirror tree alike.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# The resolves-gate decision table. Same not-repo-owned, travels-with-the-payload reasoning as the
# line above (registered in shared-scripts-lib.ps1 for the mirror + drift lint).
. (Join-Path $PSScriptRoot '..\lib\pr-issues-lib.ps1')

# Pre-flight (#86): an unfilled scaffold (repo-config still at VUL-IN) would otherwise only fail
# further down with an unclear gh error. Stop here with a clear pointer.
if ($repo -match 'VUL-IN' -or (Get-LintScript) -match 'VUL-IN') {
    Write-Error "open-pr cannot run -- scripts\repo-config.ps1 still contains VUL-IN placeholders. Fill in Get-RepoName and Get-LintScript with this repo's values and run again."
    exit 1
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq 'main') { Write-Error "You are on main; a PR is created from a branch."; exit 1 }

# Resolved BEFORE the gates (it is a pure function of the branch name), because the resolves gate
# below needs the entry-file path and the label logic further down needs the same object.
$info = Get-BranchInfo -Branch $branch
$entryPath = Join-Path $repoRoot ($info.SafeName + '.md')

# --- Does this branch already have an open PR? ----------------------------------------------------
# Asked ONCE, here, because two later steps need the answer: the resolves gate (an existing body's
# closing keywords count as a declaration) and the create step (which is skipped, since the push is
# what updates an existing PR). Before the gates rather than after, so the gate reads the same facts
# it decides on.
#
# A FAILED QUERY IS NOT AN ANSWER, and it deliberately does not block: treat it as "no existing PR"
# and let the flow continue. The worst case is the behaviour this script had all along -- a duplicate
# `gh pr create` refused by gh with its own message -- whereas blocking here would wedge the whole PR
# flow on a network hiccup. Same reasoning as the resolves gate's undeterminable-state branch.
#
# --base main IS LOAD-BEARING, not symmetry with the create below. Without it the query answers "does
# this branch have an open PR anywhere", and a consumer running stacked PRs (branch -> branch -> main)
# would get the wrong one: this script would skip creating the PR to main, and ship-pr.ps1 would then
# find and MERGE the stacked PR into its intermediate base instead. GitHub allows one open PR per
# (head, base) pair, so with the base pinned there is at most one answer -- which is also why --limit 1
# cannot hide a second candidate.
$existingPr = $null
$prLookup = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--head', $branch, '--base', 'main', '--state', 'open', '--json', 'number,url,body', '--limit', '1', '--repo', $repo) -DiscardStderr
if ($prLookup.ExitCode -ne 0) {
    Write-Warning "could not ask gh whether '$branch' already has an open PR (exit $($prLookup.ExitCode)) - continuing as if it has none."
} else {
    # The parse itself lives in pr-issues-lib.ps1 (Get-ExistingPrRecord) so the 5.1 array-flattening
    # pitfall it navigates is covered by pr-issues.tests.ps1 -- this script drives a live remote and
    # cannot be. It returns $null for anything it cannot read, which is the same "no existing PR" the
    # failed-query branch above assumes.
    $existingPr = Get-ExistingPrRecord -Json ($prLookup.Output -join "`n")
}

# --- Resolves gate --------------------------------------------------------------------------------
# Runs FIRST, before lint/tests/push: a forgotten closing keyword should not cost the author forty
# test suites before it is reported, and nothing has left the machine yet at this point.
$resolveList = @(ConvertTo-IssueNumberList -Value $Resolves)
$resolveIssues = @()
if (-not $NoResolves -or $resolveList.Count -gt 0) {
    # What the branch itself mentions: the changelog entry (always present on a branch) plus a
    # -Body the caller supplied, since either can carry the reference.
    $mentionText = ''
    if (Test-Path $entryPath) {
        $mentionText = [System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)
    }
    if ($Body) { $mentionText = $mentionText + "`n" + $Body }

    # The open-issue list, fetched ONCE and used for both the gate verdict and the typo check below.
    # It used to be two near-identical query blocks, each carrying its own copy of the 5.1 flatten
    # trick -- a second hand-copied instance of a subtle workaround, which is the accumulation shape
    # this repo already paid for twice (#275, #331). Returns $null when it cannot be determined.
    function Get-OpenIssueNumbers {
        param([string]$Repo)
        # --limit 1000, not 200: an issue past the page boundary would read as "not open" and let the
        # gate pass in silence, which is the one outcome this whole feature exists to prevent.
        $q = Invoke-NativeCapture -FilePath 'gh' -Arguments @('issue', 'list', '--repo', $Repo, '--state', 'open', '--limit', '1000', '--json', 'number') -DiscardStderr
        if ($q.ExitCode -ne 0) {
            Write-Warning "could not ask gh which issues are open (exit $($q.ExitCode)) -- the resolves gate cannot check and will not block."
            return $null
        }
        try {
            # ASSIGN the parse result first, THEN wrap it in @(). Windows PowerShell 5.1 emits a
            # parsed JSON array as a SINGLE pipeline object, so `@(... | ConvertFrom-Json)` collects
            # one element that IS the whole Object[] -- and `$_.number` on an array does member
            # enumeration, handing the [int] cast an Object[] that throws. Assigning first gives @()
            # a real array to flatten. That throw was swallowed as "cannot check", so the gate
            # silently never blocked while every pure unit test stayed green; only the wiring fixture
            # caught it.
            $parsed = ($q.Output -join "`n") | ConvertFrom-Json
            return @(@($parsed) | ForEach-Object { [int]$_.number })
        } catch {
            Write-Warning "could not parse the open-issue list from gh ($($_.Exception.Message)) -- the resolves gate cannot check and will not block."
            return $null
        }
    }

    # Which mentioned numbers are OPEN issues right now. $null = could not determine, which the
    # decision table treats as "do not block" (it only warns).
    $openMentions = $null
    $openAll = $null
    $mentions = @(Get-IssueMentions -Text $mentionText)
    if ($mentions.Count -gt 0 -or $resolveList.Count -gt 0) {
        $openAll = Get-OpenIssueNumbers -Repo $repo
        if ($null -ne $openAll) {
            $openMentions = @($mentions | Where-Object { $openAll -contains $_ })
        }
    }

    # The body the gate judges: what the caller supplied, PLUS the body of an already open PR for this
    # branch. Without that second half, resuming such a branch would be blocked for not repeating a
    # `Closes #<n>` that is already on the PR -- and GitHub honours the body it has at merge time, not
    # what this run declares, so the gate would be demanding a decision it cannot change. Kept separate
    # from $Body on purpose: $Body being empty is what triggers the template auto-fill further down, and
    # folding a fetched body into it would silently suppress that.
    $gateBody = $Body
    if ($existingPr) { $gateBody = ($gateBody + "`n" + $existingPr.body) }

    $decision = Get-ResolvesDecision -Resolves $resolveList -NoResolves:$NoResolves -Body $gateBody -OpenMentions $openMentions
    if (-not $decision.Allowed) {
        $list = ($decision.Blocked | ForEach-Object { "#$_" }) -join ', '
        $flag = '-Resolves ' + (($decision.Blocked | ForEach-Object { "$_" }) -join ',')
        Write-Error @"
resolves gate: this branch mentions open issue(s) $list, but the PR declares neither -Resolves nor -NoResolves - nothing pushed, no PR opened.

A plain mention does not close anything: GitHub only auto-closes on a closing keyword, so without this the issue stays open after the merge (exactly what happened to eight findings across PRs #341-#343).

Pick one:
  $flag   -- this PR resolves them; each gets its own 'Closes #<n>' line in the body
  -NoResolves        -- this PR resolves none of them (they are cited as context)

Both are honest answers; the gate only refuses to guess.
"@
        exit 1
    }
    $resolveIssues = @($decision.Issues)

    # Mentioned, open, and covered by nothing the author declared. Reported, never blocking: closing
    # one of two mentioned issues is a legitimate choice, but leaving the second unmentioned in the
    # output is how the original slip happened.
    if (@($decision.Undeclared).Count -gt 0) {
        Write-Warning ("resolves gate: open issue(s) " + ((@($decision.Undeclared) | ForEach-Object { "#$_" }) -join ', ') + " are mentioned on this branch but are NOT closed by this PR. If that is deliberate (cited as context), nothing to do -- they simply stay open.")
    }

    # A number passed to -Resolves that is not an open issue is worth a word but not a block: it may
    # be a closed issue being re-reported, or a typo the author should see. Reuses the single query.
    if ($resolveList.Count -gt 0 -and $null -ne $openAll) {
        $notOpen = @($resolveIssues | Where-Object { $openAll -notcontains $_ })
        if ($notOpen.Count -gt 0) {
            Write-Warning ("-Resolves names issue(s) that are not open right now: " + (($notOpen | ForEach-Object { "#$_" }) -join ', ') + " -- check for a typo. The closing keyword is written anyway (harmless on an already-closed issue).")
        }
    }
}

# Scaffold gate: an entry that still carries its scaffold wording must not become a PR.
#
# MEASURED, AND IT HAD ALREADY SHIPPED. At v3.2.0 three of the twenty-one entries (#424, #425, #426)
# still carried "**To do / where I left off:**" -- not untouched scaffolds, but the heading kept with a
# status appended behind it ("done -- lint gate green"). A progress note, correct on the branch and
# wrong the moment it is published.
#
# WHY THIS GATE AND NOT THE LINT ONE. The window closes at the merge, and it closes INVISIBLY: the fold
# moves the entry into CHANGELOG.md, and the next release moves it on into releases/development/ and
# into every per-plugin CHANGELOG.md that travels to consumers in the plugin cache. By then the place
# a reviewer would look is the one place it no longer is -- CHANGELOG.md's Pull Requests section is
# empty after a cut. Held against all 70 archived notes: one older instance, then three in one day, so
# this is a real rate rather than a one-off.
#
# NOT -SkipLint-able and deliberately its own gate: it costs one read of a file already in hand, needs
# no gh and no subprocess, and refusing it is a content decision rather than a tooling one. -Force is
# the escape valve, for the rare entry that legitimately quotes the wording outside a fence.
if (Test-Path -LiteralPath $entryPath) {
    . (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
    $entryText = [System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)
    $scaffoldFindings = @(Get-EntryScaffoldFindings -EntryText $entryText -Wording (Get-EntryScaffoldWording))
    if ($scaffoldFindings.Count -gt 0) {
        $entryRel = Split-Path $entryPath -Leaf
        $detail = ($scaffoldFindings | ForEach-Object { "  - $($_.Label): '$($_.Marker)'" }) -join "`n"
        if ($Force) {
            Write-Warning "scaffold gate: $entryRel still carries scaffold wording, but -Force was given:`n$detail"
        } else {
            Write-Error @"
scaffold gate: $entryRel still carries the wording new-changelog-entry.ps1 scaffolded it with - nothing pushed, no PR opened.

$detail

That text describes what was still TO DO on the branch. It is about to become permanent: the fold pastes
this entry into CHANGELOG.md, and the next release copies it into releases/ and into every per-plugin
CHANGELOG.md that travels to consumers - where nobody will look for it again.

Rewrite the body to say what the change DOES, then run again. Keeping it as-is is -Force.
"@
            exit 1
        }
    }
}

# Lint gate: catch invalid manifests/frontmatter/dead links before they land on main via a PR.
# The lint script is repo-specific (via repo-config); errors block (exit code 1). -SkipLint
# deliberately skips the gate.
if (-not $SkipLint) {
    $lintPath = Join-Path $repoRoot (Get-LintScript)
    if (Test-Path $lintPath) {
        Write-Host "lint gate: integrity check for the PR..." -ForegroundColor Cyan
        & powershell -NoProfile -ExecutionPolicy Bypass -File $lintPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "lint gate found errors - branch not pushed, no PR opened. Fix the errors, or run with -SkipLint to skip the gate."
            exit 1
        }
    } else {
        Write-Warning "lint script not found at '$lintPath' - lint gate skipped."
    }
}

# Test gate: all suites, exactly as CI -- a red suite should already block here, not only at the
# PR (a lesson from PR #54). -SkipTests is the deliberate escape valve.
if (-not $SkipTests) {
    $testsDir = Join-Path $repoRoot 'scripts\tests'
    if (Test-Path $testsDir) {
        Write-Host "test gate: running all test suites for the PR..." -ForegroundColor Cyan
        $testFailed = $false
        $suites = @(Get-ChildItem -Path $testsDir -Filter '*.tests.ps1' -File)
        if ($suites.Count -eq 0) {
            Write-Warning "no *.tests.ps1 suites found in scripts/tests - test gate had nothing to run."
        }
        $suites | ForEach-Object {
            Write-Host "== $($_.Name) ==" -ForegroundColor Cyan
            & powershell -NoProfile -ExecutionPolicy Bypass -File $_.FullName
            if ($LASTEXITCODE -ne 0) { $testFailed = $true }
        }
        if ($testFailed) {
            Write-Error "test gate found failing suites - branch not pushed, no PR opened. Fix the tests, or run with -SkipTests to skip the gate."
            exit 1
        }
    } else {
        Write-Warning "scripts/tests not found - test gate skipped."
    }
}

# git push writes its 'remote:' progress to stderr, which under EAP=Stop would die as a terminating
# NativeCommandError before the exit-code check even though git gave exit 0 (the #96/#97/#107
# pitfall). Invoke-NativeCapture runs it under EAP=Continue and hands back output + $LASTEXITCODE.
$push = Invoke-NativeCapture -FilePath 'git' -Arguments @('push', '-u', 'origin', $branch)
$push.Output | ForEach-Object { Write-Host $_ }
if ($push.ExitCode -ne 0) { Write-Error "git push failed."; exit 1 }

# --- Already open? Then the push was the update, and there is nothing to create -------------------
# Exits 0 on purpose: this is a SUCCESSFUL outcome, and ship-pr.ps1 reads that exit code to decide
# whether to go on to the CI watch and the merge. Returning non-zero here (or letting the duplicate
# `gh pr create` fail) is what made ship-pr unusable on a resumed branch.
#
# Title, body and label are left untouched -- see the note in .DESCRIPTION. The ONE exception is a
# -Resolves the existing body does not yet carry, and it is not a matter of taste: if this run
# declares an issue closed and the declaration never reaches the body, GitHub closes nothing at the
# merge and ship-pr.ps1's step 6 reads the same body back and confirms the same silence. That is the
# #341-#343 failure precisely, arrived at from the other side -- so the block is APPENDED rather
# than skipped. Add-ResolvesBlock is idempotent per issue, so an already-declared number is not
# duplicated and a run with nothing to add writes nothing at all.
if ($existingPr) {
    if ($resolveIssues.Count -gt 0) {
        $updatedBody = Add-ResolvesBlock -Body ([string]$existingPr.body) -Issues $resolveIssues
        if ($updatedBody -ne [string]$existingPr.body) {
            $editFile = Join-Path ([System.IO.Path]::GetTempPath()) "open-pr-resolves-$PID.md"
            [System.IO.File]::WriteAllText($editFile, $updatedBody, (New-Object System.Text.UTF8Encoding $false))
            try {
                $edit = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'edit', "$($existingPr.number)", '--body-file', $editFile, '--repo', $repo)
                $edit.Output | ForEach-Object { Write-Host $_ }
                if ($edit.ExitCode -ne 0) {
                    Write-Error "PR #$($existingPr.number) is open and the branch was pushed, but appending the closing keyword(s) for $(($resolveIssues | ForEach-Object { "#$_" }) -join ', ') FAILED (exit $($edit.ExitCode)). Do not merge yet: without them in the body GitHub closes nothing. Add the 'Closes #<n>' line(s) by hand, or rerun."
                    exit 1
                }
                Write-Host "Appended the closing keyword(s) for $(($resolveIssues | ForEach-Object { "#$_" }) -join ', ') to PR #$($existingPr.number)." -ForegroundColor Green
            } finally {
                Remove-Item -Path $editFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "PR #$($existingPr.number) was already open for '$branch' - the push above updated it." -ForegroundColor Green
    Write-Host "  $($existingPr.url)"
    Write-Host "Title and body left as they are; retitle with 'gh pr edit' if you want them changed." -ForegroundColor DarkGray
    exit 0
}

if ($info.IsKnown) {
    $label = $info.Label
} else {
    $label = 'question'
    Write-Warning "Unknown branch prefix '$($info.Prefix)' - label 'question' set; classify the PR manually."
}

if (-not $Body) {
    $templatePath = Join-Path $repoRoot ".github\pull_request_template.md"
    if (Test-Path $templatePath) {
        $templateLines = Get-Content -Path $templatePath -Encoding UTF8

        # Description from the changelog entry file <SafeName>.md: everything after the compact
        # ###-heading line ("### title - type - date"). This file always exists on the branch.
        # $entryPath was resolved before the gates, alongside $info.
        $desc = ''
        if (Test-Path $entryPath) {
            $entryLines = Get-Content -Path $entryPath -Encoding UTF8
            $h3Idx = -1
            for ($i = 0; $i -lt $entryLines.Count; $i++) {
                if ($entryLines[$i] -match '^###\s') { $h3Idx = $i; break }
            }
            if ($h3Idx -ge 0 -and ($h3Idx + 1) -lt $entryLines.Count) {
                $desc = (($entryLines[($h3Idx + 1)..($entryLines.Count - 1)]) -join "`n").Trim()
            }
        }

        # Tick / fill in what the script deterministically knows:
        #   - the "Type of change" box whose line contains `<prefix>/`;
        #   - the placeholder under "What does this change do?" -> the description;
        #   - "Changelog entry file created": true as soon as <SafeName>.md exists (just read);
        #   - "Requested by Dave": always true -- this script only runs at Dave's request.
        # The remaining checklist items stay empty on purpose: human judgement checks.
        # Each of the three string matches is BILINGUAL: it accepts both the legacy Dutch template
        # strings AND the new English ones, so a consumer whose PR template is still Dutch keeps working.
        $prefixPattern = '^- \[ \] `' + [regex]::Escape($info.Prefix) + '/`'
        $entryExists = Test-Path $entryPath

        # #101: the description placeholder(s) and the approval-checklist pattern are overridable
        # via optional repo-config functions, so a consumer with its own PR template text does not
        # need a wrapper. Guard via Get-Command so a repo-config.ps1 that does not define these
        # (the workshop's own, and every existing consumer) keeps exactly today's behavior.
        $descPlaceholders = if (Get-Command -Name Get-PrDescriptionPlaceholder -ErrorAction SilentlyContinue) {
            @(Get-PrDescriptionPlaceholder)
        } else {
            @(
                '<!-- Korte beschrijving van wat er verandert en waarom. -->',
                '<!-- Short description of what changes and why. -->'
            )
        }
        $approvalPattern = if (Get-Command -Name Get-PrApprovalPattern -ErrorAction SilentlyContinue) {
            Get-PrApprovalPattern
        } else {
            '^- \[ \] (Aangevraagd door Dave|Requested by Dave)'
        }

        $filled = foreach ($line in $templateLines) {
            if ($line -match $prefixPattern) {
                $line -replace '^- \[ \]', '- [x]'
            } elseif ($desc -and ($descPlaceholders -contains $line)) {
                $desc
            } elseif ($entryExists -and $line -match '^- \[ \] Changelog entry(-bestand aangemaakt| file created)') {
                $line -replace '^- \[ \]', '- [x]'
            } elseif ($line -match $approvalPattern) {
                $line -replace '^- \[ \]', '- [x]'
            } else {
                $line
            }
        }
        $Body = ($filled -join "`n")
    }
}

# The closing block goes in LAST, so it lands on both paths -- the auto-filled template and a -Body
# supplied by the caller. Add-ResolvesBlock is idempotent per issue: a number the body already
# closes is not repeated.
if ($resolveIssues.Count -gt 0) {
    $Body = Add-ResolvesBlock -Body $Body -Issues $resolveIssues
    Write-Host ("resolves gate: the PR body closes " + (($resolveIssues | ForEach-Object { "#$_" }) -join ', ') + " on merge.") -ForegroundColor Green
} else {
    Write-Host "resolves gate: this PR closes no issue." -ForegroundColor DarkGray
}

# Body via a temp file: --body $Body would let PowerShell 5.1 mangle embedded quotes on native
# commands, causing gh to read the body as separate arguments.
$bodyFile = Join-Path ([System.IO.Path]::GetTempPath()) "open-pr-body-$PID.md"
[System.IO.File]::WriteAllText($bodyFile, $Body, (New-Object System.Text.UTF8Encoding $false))

# #101: optional assignee/milestone via repo-config. Not defined, or an empty return value: the
# flag is simply omitted -- current behavior, unchanged (the workshop defines neither). Collected
# as a splatted array of EXTRA args (kept separate from the fixed `gh pr create ...` call below) so
# the #107 stderr-capture guard keeps its literal, single-line `gh pr create ... 2>&1` shape.
$assignee = if (Get-Command -Name Get-PrAssignee -ErrorAction SilentlyContinue) { "$(Get-PrAssignee)".Trim() } else { '' }
$milestone = if (Get-Command -Name Get-PrMilestone -ErrorAction SilentlyContinue) { "$(Get-PrMilestone)".Trim() } else { '' }
$extraGhArgs = @()
if ($assignee) { $extraGhArgs += @('--assignee', $assignee) }
if ($milestone) { $extraGhArgs += @('--milestone', $milestone) }

try {
    # gh writes some of its progress/URL to stderr; Invoke-NativeCapture runs it under EAP=Continue
    # so a stderr line cannot become a terminating error before the exit-code check (#107, the same
    # pitfall as the push above). The optional assignee/milestone args are appended to the fixed
    # argument list. The temp body file is cleaned up in finally, whether or not gh succeeds.
    $create = Invoke-NativeCapture -FilePath 'gh' -Arguments (@('pr', 'create', '--base', 'main', '--head', $branch, '--title', $Title, '--body-file', $bodyFile, '--label', $label, '--repo', $repo) + $extraGhArgs)
    $create.Output | ForEach-Object { Write-Host $_ }
    if ($create.ExitCode -ne 0) { Write-Error "Creating the PR failed (is gh logged in?)."; exit 1 }
} finally {
    Remove-Item -Path $bodyFile -Force -ErrorAction SilentlyContinue
}
Write-Host "PR created for '$branch'." -ForegroundColor Green
