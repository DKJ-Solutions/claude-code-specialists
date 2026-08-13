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

    THE TITLE IS NOT TYPED HERE -- IT IS DERIVED (Dave, #506 + #505, August 7, 2026). A fresh PR is called
    '<branch type>: <the entry's Branch title>': the type off the branch prefix, the words out of
    branch/branch-changelog.md. So the sentence is written once, at `new-branch -Title`, and the PR, the
    changelog and the release documents cannot disagree about what the change is called -- nor can the title
    lose its type prefix, which the last five PRs before this change all had (#499-#503). Get-PrTitle
    composes it; -Title is still accepted and ignored, see that parameter.

    Title and body are LEFT ALONE by default when a PR already exists. The body may have been edited on
    github.com since it was opened, and silently overwriting a reviewer's or the author's edits with a
    freshly generated template is a worse failure than a stale title: the title is visible on the PR, an
    overwritten body is gone. Retitle with `gh pr edit`; use -RefreshBody to pull the description back
    from the changelog entry when the entry was rewritten after the PR was opened -- see that parameter.

    ONE exception, and it APPENDS rather than replaces: a -Resolves this run declares that the existing
    body does not already carry is added to it. Skipping that would drop the declaration on the floor --
    GitHub closes what the body says at merge time, so the issue would stay open and ship-pr.ps1's
    step 6 would read the same body back and confirm the same silence. That is the #341-#343 failure
    reached from the other direction, so it is repaired here rather than left to the author. A failed
    append is a hard stop (exit 1), because the branch is pushed by then and merging it would publish
    the loss.

    Auto-fill (if you do NOT supply -Body): the script fills in the template itself as much as
    possible, so the PR never lands on github.com as an empty form:
      1. The template's description placeholder is replaced by the changelog entry
         (branch/branch-changelog.md, or the pre-split <SafeName>.md in the repo root), which always
         exists on the branch. So you never have to type anything twice. What goes in is the entry from
         its 'What does the change...' section onwards -- see Get-PrDescription for why the three
         sections above it and the empty one below it are left out of a PR body but kept in the fold.
      2. Anything else the template asks that this script can answer deterministically is answered:
         a "Type of change" box matching the branch prefix, a "Changelog entry written" item (true
         once the file actually HOLDS an entry -- not merely that it exists, since the branch/ split
         it exists on the trunk too) and a "Requested by Dave" item.
      If you do supply -Body, it is used literally (override).

      STEP 2 FILLS IN NOTHING FOR THIS REPO ANY MORE, AND IS KEPT DELIBERATELY (#538). Those three
      sections were removed from this repo's template on August 9, 2026, because measured over 60 PRs
      not one of their boxes had ever varied: "Type of change" had exactly one of four ticked every
      single time (a fact the entry already states under `### Branch type`, and which the LABEL takes
      from Get-BranchInfo rather than from the tick), "Requested by Dave" was ticked 60/60,
      "Changelog entry written" 60/60, and the two items the docstring used to call "human judgement
      checks the script cannot honestly verify" were ticked 0/60 -- by anyone, ever, while both were
      already enforced by gates that block this script. A box that is always ticked and a box that is
      never ticked carry the same information.
      The matching stays because a consumer's PR template is their file: every one of them still has
      those sections right now, and they receive this script through a plugin update rather than by
      choosing to. Removing the fill logic in the same breath would leave their forms blank.

      The description placeholder(s) and the approval-checklist pattern used for steps 2 and 3 are
      configurable per repo (#101): if scripts\repo-config.ps1 defines the optional
      Get-PrDescriptionPlaceholder / Get-PrApprovalPattern functions, those are used; otherwise the
      script falls back to this repo's own template markers (current behavior, unchanged) -- so a
      consumer whose PR template uses different marker text can point at its own markers without a
      wrapper script. IF YOUR TEMPLATE'S PLACEHOLDER LINE DIFFERS FROM THE THREE BUILT-IN STRINGS,
      DEFINE Get-PrDescriptionPlaceholder -- that is the seam for it, and a consumer only reaches for
      a seam it knows exists (#573). Since that same issue, a run whose template matched no
      placeholder at all warns instead of producing a PR body with no description in silence.

    Optional assignee/milestone (#101): if scripts\repo-config.ps1 defines Get-PrAssignee and/or
    Get-PrMilestone (both optional), a non-empty return value is passed to `gh pr create` as
    --assignee / --milestone. Not defined, or an empty return value: the flag is simply omitted
    (current behavior, unchanged).

    ALWAYS sets a GitHub label based on the branch prefix (every PR has a label). The
    prefix-to-label table lives in scripts/lib/branch-info.ps1 (shared with the other scripts) and
    follows the main categories of the PR template. Unknown prefix -> label 'question' + warning
    (= needs further classification).

    Scaffold gate (measured at v3.2.0): the branch's changelog entry must no longer carry the wording
    new-branch.ps1 scaffolded it with -- the placeholder title, the "to do / where I left off"
    heading or the fallback body (whatever this repo configured them to be; entry-scaffold-lib.ps1 is the
    single source, shared with the script that writes them). Three of v3.2.0's twenty-one entries kept
    that heading with a status appended, and it reached the release notes and the per-plugin CHANGELOGs
    that travel to consumers. The window closes at the merge and closes INVISIBLY, because by then the
    text has moved out of CHANGELOG.md's Pull Requests section into files nobody re-reads. Fenced code is
    excluded, so an entry documenting this mechanism is not accused of it. Use -Force to ship anyway.

    Tier gate (the tier model, August 5, 2026): the entry's 'Tier: N' line must be a tier the model has
    -- 0, 1 or 2. A LOW tier is never refused; 'Tier: 0' is a legitimate and common final answer, which
    is exactly why it is a separate gate rather than part of the scaffold one. What is refused is a value
    with no meaning ('Tier: 5', 'Tier: two'), because it reads back as the default and would file
    consumer-facing work as repo-internal without anything erroring. Not -Force-able: -Force exists for
    text somebody legitimately wrote, and there is no legitimate 'Tier: 5'. The resolved tier is printed
    either way, so an entry still sitting at the default says so before the PR rather than at the cut.

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
    ACCEPTED AND IGNORED since #506 (August 7, 2026). The PR title is composed from the branch prefix and
    the entry's 'Branch title' section; passing one here warns and changes nothing. Retitle an open PR with
    `gh pr edit`, and change a future one by editing the entry.

    NOT REMOVED, on the standing reason: every branch in flight -- here and in every consumer -- calls this
    script with -Title right now, and consumers receive the new script through a plugin update rather than
    by choosing to. A removed parameter turns all of those into "A parameter cannot be found", which is a
    stop at the end of a finished branch. Accepting it costs one warning; refusing it costs somebody's
    afternoon. An OVERRIDE was the alternative and Dave declined it in the issue: an override is a second
    source of the title, which is the whole thing this change removes.

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

.PARAMETER RefreshBody
    On a branch whose PR is ALREADY OPEN, rewrite the description section of that PR's body from the
    current changelog entry. Only that one section: the `## Resolved issues` block, anything a reviewer
    added, and any section a consumer's template carries that this script did not write (the "Type of
    change" boxes and the checklist, where those still exist) stay exactly as they are.

    WHICH heading carries the description is read from the template's FIRST heading, at any level, so
    renaming or re-levelling it needs no change here -- but a PR opened BEFORE such a change carries the
    old heading in its body, and it would then be unrefreshable. So the headings this repo has published
    under are tried as a fallback when the current one is not found.

    OPT-IN ON PURPOSE, and the default silence is the safer half: a body may have been edited on
    github.com, and refreshing on every run would overwrite those edits without being asked. So the
    switch exists for the case that actually happens -- the entry was rewritten after the PR was opened,
    which is routine on a branch that gets extended -- and it stays off otherwise.

    A no-op where there is nothing to do: no open PR, no entry description, or a body that already says
    exactly this. In the last case nothing is sent to GitHub at all, so a rerun produces no PR activity.
    Ignored on a fresh PR, where the body is generated from the template anyway.

.EXAMPLE
    ./scripts/release/open-pr.ps1

.EXAMPLE
    ./scripts/release/open-pr.ps1 -Resolves 331,332
#>
[CmdletBinding()]
param(
    [string]$Title = '',
    [string]$Body = '',
    [switch]$SkipLint,
    [switch]$SkipTests,
    [string]$Resolves = '',
    [switch]$NoResolves,
    [switch]$Force,
    [switch]$RefreshBody
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

# The PR-body helpers: Get-EntryDescription (shared by the fresh and the -RefreshBody path, so they read
# the entry the same way) and Update-PrBodySection. Same payload reasoning as the two libs above.
. (Join-Path $PSScriptRoot '..\lib\pr-body-lib.ps1')

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

# Dot-sourced HERE rather than inside the scaffold gate below, because resolving the entry's path now
# needs the lib too. One load, at the first point anything requires it.
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

# THE ENTRY LIVES IN branch/ SINCE THE SPLIT (Dave, August 6, 2026), with the root <SafeName>.md still
# accepted as the fallback. Both exist in the wild simultaneously: a branch created before the split
# carries the root form, and consumers receive these scripts through a plugin update rather than by
# choosing to. Preferring the new path and falling back to the old one is what lets a branch cut over
# mid-flight without this gate suddenly finding no entry -- which would not merely warn, it would let a
# scaffolded entry through, since a gate with nothing to read reports nothing.
$branchFiles = Get-BranchFilePaths
$entryPath = Join-Path $repoRoot $branchFiles.Changelog
if (-not (Test-Path -LiteralPath $entryPath)) {
    $entryPath = Join-Path $repoRoot ($info.SafeName + '.md')
} elseif (-not (Test-BranchChangelogIsFilled -Text ([System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)))) {
    # Present but still in its reset state: this branch never ran the scaffolder, so if a root entry
    # exists it is the real one. The reset file is not an entry and must not be read as an empty one.
    $legacyPath = Join-Path $repoRoot ($info.SafeName + '.md')
    if (Test-Path -LiteralPath $legacyPath) { $entryPath = $legacyPath }
}

# The entry's description, read ONCE here because two paths need it: the template auto-fill for a fresh
# PR, and -RefreshBody for a resumed one. Reading it twice would be two chances to read it differently.
# The same single read now also supplies the PR TITLE (#506) -- one file read, one set of facts.
$entryDescription = ''
$prTitle = ''
if (Test-Path -LiteralPath $entryPath) {
    $entryText = [System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)

    # THE PR BODY IS THE ANSWER ONWARDS, NOT THE WHOLE DOSSIER (Dave, August 9, 2026). Get-PrDescription
    # drops what the PAGE around the body already says -- the Branch title (which is this PR's title, one
    # line above), the Branch ID, the Branch type (its label) -- and the trailing 'Pull Request' section,
    # which the FOLD fills and which is therefore empty in every PR body ever produced. Significance stays:
    # how far a change reaches and what it is worth is the thing a reviewer is deciding about.
    #
    # '' MEANS "this entry has no such section", and the fallback is the previous behaviour verbatim. A
    # pre-dossier entry kept its description straight under the heading, and every consumer with a branch
    # in flight has one -- they receive this script through a plugin update rather than by choosing to.
    # CHANGELOG.md is untouched by any of this: the fold still receives the dossier verbatim, front matter
    # and all, which is what Dave chose on August 6 and what the release documents inherit.
    $entryDescription = Get-PrDescription -EntryText $entryText
    if (-not $entryDescription) { $entryDescription = Get-EntryDescription -EntryText $entryText }

    # Get-EntrySectionAnswer, not the raw section body: it strips the guidance comments, so a template
    # comment left standing above the answer cannot end up in the PR title. It also accepts the section's
    # RETIRED name, so an entry written as 'Branch description' still names its own PR.
    $titleWords = Get-EntrySectionAnswer -EntryText $entryText -Key 'Description'

    # A PRE-SPLIT ENTRY HAS NO TITLE SECTION -- ITS TITLE IS THE HEADING, and it must still be able to open
    # a PR. Such branches exist right now in every consumer, which receives this script through a plugin
    # update rather than by choosing to; refusing them would turn a branch that worked yesterday into a stop
    # at the last step. Test-EntryHasSection rather than the empty answer, because ABSENT and EMPTY are
    # different questions: an entry that HAS the section and left it blank is an author who has not written
    # the title yet, and falling back to the branch heading would hide that behind a plausible-looking PR.
    #
    # Convert-EntryHeadingToTitle does the field-dropping, which is why release-lib is loaded here rather
    # than the rule being written a second time: it already knows that a heading's leading '#NN' and its
    # trailing type/date fields are administration, decided by the SHAPE of each field rather than by
    # counting them -- the distinction that lets one rule read both eras of heading. A copy here would be
    # free to disagree with the document the fold produces from the same heading.
    if (-not $titleWords -and -not (Test-EntryHasSection -EntryText $entryText -Key 'Description')) {
        . (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')
        $headingLine = @((Convert-EntryHeadingToTitle -EntryText $entryText) -split "\r?\n")[0]
        $titleWords = ($headingLine -replace '^#+\s*', '').Trim()
    }

    # An UNKNOWN prefix is passed as '' -- see Get-PrTitle -- so the title carries a type only where the
    # branch table backs one.
    $prTitle = Get-PrTitle -Prefix $(if ($info.IsKnown) { $info.Prefix } else { '' }) -TitleWords $titleWords
}

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

# -Title IS ACCEPTED AND IGNORED (#506). Said out loud rather than silently dropped: a caller who passed a
# title has an expectation about what the PR will be called, and the one thing worse than not honouring it
# is not honouring it quietly. HERE and not at the parameter, because the answer needs the entry AND the
# existing-PR lookup: on a resumed branch the title was never going to be touched by any route.
if ($Title) {
    if ($existingPr) {
        Write-Warning "-Title is ignored since #506, and this branch already has a PR, which keeps its own title either way. Retitle with 'gh pr edit'."
    } else {
        Write-Warning "-Title is ignored since #506 - the PR title comes from the entry's title section. This PR will be called '$prTitle'; edit that section (or 'gh pr edit' afterwards) if that is wrong."
    }
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
    $entryText = [System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)
    $scaffoldFindings = @(Get-EntryScaffoldFindings -EntryText $entryText -Wording (Get-EntryScaffoldWording))
    if ($scaffoldFindings.Count -gt 0) {
        # Repo-relative, not the bare leaf. Every branch's entry is now called branch-changelog.md, so a
        # leaf-only name in the refusal tells the reader nothing about which file to open.
        $entryRel = $entryPath.Substring($repoRoot.Length).TrimStart('\', '/')
        $detail = ($scaffoldFindings | ForEach-Object { "  - $($_.Label): '$($_.Marker)'" }) -join "`n"
        if ($Force) {
            Write-Warning "scaffold gate: $entryRel is not finished, but -Force was given:`n$detail"
        } else {
            Write-Error @"
scaffold gate: $entryRel has not been written yet - nothing pushed, no PR opened.

$detail

Each line above is a field the scaffolder left for you and nothing has been put in it, wording it wrote that
is still standing, or - for a tier - an answer written one line too low. The guidance comments do not count
as an answer: the fold strips them, so a section that looks filled in on the branch lands in CHANGELOG.md
empty.

That third case is the one worth knowing before you go looking: under a tier heading, everything ABOVE the
$($script:EntryScoreLabel) line is the reason and everything below it is discarded. The scaffold leaves one
blank line on each side, so writing the reason underneath is easy to do and impossible to see - and the gate
names it above when that is what happened, instead of calling it missing.

And it is about to become permanent - the fold pastes this entry into CHANGELOG.md and the next release
copies it into releases/, where nobody will look for it again.

Answer them and run again. Shipping it as it stands is -Force.
"@
            exit 1
        }
    }

    # Step-list gate (Dave, August 5-6, 2026): "pas als alle punten zijn afgevinkt kan de branch met een PR
    # gemergd worden". The branch's step list must have nothing unresolved left in it.
    #
    # WHAT COUNTS AS RESOLVED IS TWO MARKS, NOT ONE. '- [x] ' is done; '- [~] ' is deliberately dropped,
    # with the reason kept on the line. The second exists because a plan legitimately grows items that stop
    # making sense, and a gate offering only "tick it" teaches people to tick boxes for work they did not do
    # -- which is worse than no gate, because it then reports success. A step still carrying the scaffold's
    # own placeholder is refused whether or not it is ticked, for the same reason the entry's scaffold gate
    # refuses its stubs: a ticked stub reports a plan as finished that was never written.
    #
    # DELIBERATELY NOT -Force-ABLE, unlike the scaffold gate above and like the impact gate below. -Force
    # exists for text somebody legitimately wrote and wants to keep; there is no such case here, because
    # '- [~] ' already IS the sanctioned way past a step that should not be done. Adding a second escape
    # valve would only ever be used to skip the first.
    #
    # ABSENT LIST = NO FINDING, deliberately. A branch made by hand (`git checkout -b`) rather than by
    # new-branch has its step list still in the trunk's reset state, which contains no steps at all. That
    # is the one-commit typo fix, and refusing it would make the mechanism ceremony rather than a tool.
    # What is NOT tolerated is the scaffolded list left as scaffolded -- that branch did run new-branch and
    # then ignored what it wrote.
    $progressPath = Join-Path $repoRoot (Get-BranchFilePaths).Progress
    if (Test-Path -LiteralPath $progressPath) {
        $progressRel = (Get-BranchFilePaths).Progress
        $stepFindings = @(Get-BranchProgressFindings -Text ([System.IO.File]::ReadAllText($progressPath, [System.Text.Encoding]::UTF8)))
        if ($stepFindings.Count -gt 0) {
            $marks = Get-BranchProgressMarks
            $stepDetail = ($stepFindings | ForEach-Object { "  - $($_.Label): $($_.Line)" }) -join "`n"
            Write-Error @"
step-list gate: $progressRel still has unresolved steps - nothing pushed, no PR opened.

$stepDetail

A branch reaches a PR when its own plan is finished. Resolve each step:
  $($marks.Done)done
  $($marks.Dropped)dropped, and why it turned out not to be needed

A dropped step keeps its line and its reason, which is the half worth reading later. There is no -Force
for this gate - '$($marks.Dropped.Trim())' is the way past a step that should not be done.
"@
            exit 1
        }
    }

    # Impact gate, on the same read of the same file. The entry declares how far this change reaches and how
    # much it weighs there; the fold files it under the matching changelog section and orders it within that
    # section, and the release cut refuses a bump the pending tiers have not earned. So a declaration that
    # cannot be honoured has to be caught before the entry reaches main.
    #
    # ONE RESOLVE FOR BOTH HALVES, and that is a bug this consolidation removes rather than a tidy-up. This
    # was two blocks: a tier gate reading the legacy Resolve-EntryTier and a significance gate reading the
    # table. MEASURED on the first real run -- the tier line printed "entry tier: 0 (no Tier: line -- the
    # default)" for an entry whose table declared tier 2, telling the author the exact opposite of what they
    # had written, one line above the significance reader that got it right. Two readers of one fact, which
    # is the drift this repo keeps paying for; now there is one, and it falls back to 'Tier: N' internally.
    #
    # ONLY A MALFORMED VALUE IS REFUSED, never a low one. Tier 0 and significance 1 are legitimate, common
    # and final answers -- so neither can ever be evidence of an unfinished entry, which is why this is not
    # part of the scaffold gate above. What IS refused is a value the model has no meaning for
    # ('| 5 | 3 | x |', '| 2 | 9 | x |'): it reads back as the default and would file consumer-facing work as
    # repo-internal, or sink the entry to the bottom of the document it matters most in -- correct-looking
    # and silent either way. Here it costs one cell to fix; after the merge it is an edit on main.
    #
    # MISSING rows and scores are said out loud but NOT refused, which is a split by kind of fault rather
    # than by convenience. Dave placed that refusal at the cut (August 5, 2026): the score is a judgement
    # about a finished change, and an author who has not settled it should not be blocked from merging.
    #
    # NOT -Force-able, deliberately, unlike the scaffold gate. -Force exists for text somebody legitimately
    # wrote; there is no legitimate '| 2 | 9 | x |'.
    $entryTier = Resolve-EntryImpact -EntryText $entryText
    $malformed = @(@($entryTier.Errors) | Where-Object { $_ })
    if ($malformed.Count -gt 0) {
        Write-Error @"
impact gate: $(Split-Path $entryPath -Leaf) declares an impact this model cannot read - nothing pushed, no PR opened.

$(($malformed | ForEach-Object { "  $_" }) -join "`n")

The tiers are how far a change reaches, and the release cut reads them:
  0   only this repo's own developers notice (docs, config, internal work)
  1   management and the employer/commissioner get something out of it
  2   a subscriber of the service notices it

The significance is how much it weighs for that reader, and decides where in the document it sits:
$((Format-EntrySignificanceRubricLines) -join "`n")

Correct the table and run again.
"@
        exit 1
    }
    Write-Host "  entry tier: $($entryTier.Tier)$(if (-not $entryTier.Declared) { ' (nothing declared -- the default; a release cannot be cut from tier-0 work alone)' })" -ForegroundColor DarkGray

    if (Test-EntrySignificanceActive) {
        $impact = $entryTier
        # MISSING rows and scores are said out loud, not refused: Dave placed that refusal at the cut
        # (August 5, 2026), because the score is a judgement about a finished change and an author who has
        # not settled it should not be blocked from merging over it.
        $impactFindings = @(Get-EntryImpactFindings -EntryText $entryText)
        if ($impactFindings.Count -gt 0) {
            Write-Host "  impact: not settled yet -- the release cut will refuse until it is:" -ForegroundColor DarkYellow
            $impactFindings | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkYellow }
        } elseif ($impact.Table -and @($impact.Rows | Where-Object { [int]$_.Score -gt 0 }).Count -gt 0) {
            $shown = @($impact.Rows | Where-Object { [int]$_.Score -gt 0 } | ForEach-Object { "tier $($_.Tier): $($_.Score)" })
            Write-Host "  significance -- $($shown -join ', ')" -ForegroundColor DarkGray
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
# PR (a lesson from PR #54). -SkipTests is the deliberate escape valve. A repo whose tests are not
# all PowerShell names the rest in the optional Get-TestCommands (repo-config); the shared gate
# reads it itself, so this call site stays identical to the cut's (inbound #644).
# THE LOOP ITSELF MOVED TO Invoke-TestSuiteGate (native-capture-lib.ps1) on August 7, 2026, when
# cut-release.ps1 needed the same gate -- see issue #510. Copying fifteen lines into the cut would have
# been two copies of one rule, free to drift. What stays here is the half that is open-pr's own: the
# escape valve and what a failure costs at THIS point in the chain (nothing pushed, no PR).
if (-not $SkipTests) {
    if (-not (Invoke-TestSuiteGate -TestsDir (Join-Path $repoRoot 'scripts\tests') -Context 'the PR')) {
        Write-Error "test gate found failing suites - branch not pushed, no PR opened. Fix the tests, or run with -SkipTests to skip the gate."
        exit 1
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
# Title and label are left untouched -- see the note in .DESCRIPTION. TWO things may still edit the body,
# and both are collected into ONE `gh pr edit` below rather than sent separately, because two calls would
# be two PR updates (and two notifications) for one run:
#
#   1. A -Resolves the existing body does not yet carry. NOT a matter of taste: if this run declares an
#      issue closed and the declaration never reaches the body, GitHub closes nothing at the merge, and
#      ship-pr.ps1's step 6 reads the same body back and confirms the same silence. That is the #341-#343
#      failure arrived at from the other side, so the block is APPENDED rather than skipped.
#      Add-ResolvesBlock is idempotent per issue, so an already-declared number is not duplicated.
#   2. -RefreshBody, which rewrites the description section from the entry. OPT-IN, because a body may
#      have been edited on github.com and refreshing unasked would overwrite that.
#
# Both are computed against the SAME starting body and compared to it once at the end, so "nothing to do"
# means no API call at all rather than a no-op edit.
if ($existingPr) {
    $currentBody = [string]$existingPr.body
    $newBody = $currentBody
    $edits = @()

    if ($resolveIssues.Count -gt 0) {
        $newBody = Add-ResolvesBlock -Body $newBody -Issues $resolveIssues
        if ($newBody -ne $currentBody) {
            $edits += "closing keyword(s) for $(($resolveIssues | ForEach-Object { "#$_" }) -join ', ')"
        }
    }

    if ($RefreshBody) {
        # The heading that carries the description is the FIRST heading of the PR template -- the one the
        # placeholder sits under, so the template answers this instead of a new repo-config seam a
        # consumer would have to set. If the template is missing or has no such heading there is nothing
        # to refresh, and that is a warning rather than a failure: the branch is pushed and the PR is
        # open, which is the outcome the caller asked for.
        #
        # ANY LEVEL, not '## ' (August 9, 2026). This matched two hashes exactly, from a time when every
        # template started at H2. The moment this repo's template was promoted to H1 that pattern found
        # nothing, and -RefreshBody would have degraded to its warning branch on every run -- a silent
        # loss of the whole feature, reported as "the description was left as it is", which reads like a
        # decision rather than a miss.
        # AND EVERY LATER HEADING IS THE BOUNDARY (inbound #598). Taking only the first heading was half
        # the read: the description ends where the form's next section begins, and that answer is in the
        # same file, one pass, no new seam. Without it an H1 description has no reachable boundary at all
        # -- Update-PrBodySection stops at "the same level or shallower", nothing is shallower than an H1,
        # and every '##' section below it was replaced along with the description. A consumer lost the one
        # section its template is still kept for, on every run, reported as a successful description edit.
        #
        # Fence-aware, like every other reader of markdown here: a template explaining its own shape can
        # quote a heading inside a fence, and that is a quotation rather than a section.
        $descHeading = ''
        $templateStops = @()
        $templateForHeading = Join-Path $repoRoot ".github\pull_request_template.md"
        if (Test-Path -LiteralPath $templateForHeading) {
            $tplFence = $false
            $tplHeadings = @(Get-Content -LiteralPath $templateForHeading -Encoding UTF8 | ForEach-Object {
                if ($_ -match '^\s*(```|~~~)') { $tplFence = -not $tplFence; return }
                if (-not $tplFence -and $_ -match '^#{1,6}\s+\S') { $_.TrimEnd() }
            })
            if ($tplHeadings.Count -gt 0) {
                $descHeading = $tplHeadings[0]
                if ($tplHeadings.Count -gt 1) { $templateStops = @($tplHeadings[1..($tplHeadings.Count - 1)]) }
            }
        }
        if (-not $descHeading) {
            Write-Warning "-RefreshBody: no heading found in .github/pull_request_template.md - the description was left as it is."
        } elseif (-not $entryDescription) {
            # The resolved path, not a name rebuilt from the branch: which of the two forms was actually
            # read is the first thing the reader needs in order to open the right file.
            Write-Warning "-RefreshBody: $($entryPath.Substring($repoRoot.Length).TrimStart('\', '/')) has no description under its '###' heading - the PR description was left as it is."
        } else {
            $refreshed = $false
            $newBody = Update-PrBodySection -Body $newBody -Heading $descHeading -Content $entryDescription -StopAtHeading $templateStops -Changed ([ref]$refreshed)

            # THE HEADING THIS PR WAS OPENED UNDER MAY PREDATE THE ONE THE TEMPLATE NOW CARRIES (#538).
            # $descHeading is read from the template, which is right for every PR opened since; a PR
            # opened before a rename holds the old heading in its published body, and Update-PrBodySection
            # returns the body untouched when it cannot find the heading. Without this fallback such a PR
            # becomes silently unrefreshable -- it would report "already matches the entry" while in fact
            # matching nothing, which is the worst of the three possible outcomes.
            #
            # Only tried when the first attempt changed nothing, so a body carrying the current heading is
            # never searched for a legacy one, and a genuine no-op still reports as a no-op. Each is a
            # heading this repo or a consumer has actually shipped.
            if (-not $refreshed) {
                # Every heading this repo has published a PR under, newest first. The H2 form of the
                # current wording is on the list because it was live for a single day -- long enough for
                # open PRs to carry it, which is the only thing that decides membership here.
                foreach ($legacyHeading in @(
                    '## What does the change on this branch bring to main?',
                    '## Changelog entry',
                    '## What does this change do?',
                    '## Wat doet deze wijziging?')) {
                    if ($legacyHeading -eq $descHeading.Trim()) { continue }
                    # The stops travel to this path too. A legacy H2 description is bounded by the level
                    # rule against another H2, but not against a DEEPER form section -- and being narrowing
                    # only, passing them cannot make an old-heading PR refresh any less than it does today.
                    $newBody = Update-PrBodySection -Body $newBody -Heading $legacyHeading -Content $entryDescription -StopAtHeading $templateStops -Changed ([ref]$refreshed)
                    if ($refreshed) { $descHeading = $legacyHeading; break }
                }
            }

            if ($refreshed) {
                $edits += "the description under '$($descHeading.Trim())'"
            } else {
                Write-Host "-RefreshBody: the PR description already matches the entry - nothing sent." -ForegroundColor DarkGray
            }
        }
    }

    if ($newBody -ne $currentBody) {
        # Guard before writing, from the measured instance on August 4, 2026: a hand-written refresh
        # published an EMPTY body because a failed string operation passed nothing on. A body edit must
        # never shrink to nothing, so this refuses rather than sends.
        if (-not $newBody -or -not $newBody.Trim()) {
            Write-Error "PR #$($existingPr.number) body assembly produced empty text - nothing was sent. The branch is pushed and the PR is open; the body on GitHub is unchanged."
            exit 1
        }

        # A LOST SECTION IS SAID OUT LOUD (inbound #598). The empty-body guard above catches losing
        # everything; this catches losing a PART, which is how #598 stayed invisible -- $edits reported
        # "the description" while a whole section had gone with it, and it took a 'gh pr view' days later
        # to notice. The rule and the reasoning are in Get-LostBodyHeadings; what is decided HERE is what
        # to do about it.
        #
        # A WARNING RATHER THAN A REFUSAL, deliberately. The body is a file its author may have edited by
        # hand on github.com, and refusing would leave the branch pushed with the PR body stale and no way
        # through except editing on the site. Named and loud is what the reporter could not get; blocked
        # is more than they asked for.
        $lostHeadings = @(Get-LostBodyHeadings -Before $currentBody -After $newBody)
        if ($lostHeadings.Count -gt 0) {
            Write-Warning ("PR #$($existingPr.number): $($lostHeadings.Count) section(s) present in the body are NOT in the version about to be sent:`n" +
                (($lostHeadings | ForEach-Object { "  - $_" }) -join "`n") +
                "`nThe body on GitHub is replaced anyway - check it after this run, and reinstate anything that was answered by hand.")
        }
        $editFile = Join-Path ([System.IO.Path]::GetTempPath()) "open-pr-body-edit-$PID.md"
        [System.IO.File]::WriteAllText($editFile, $newBody, (New-Object System.Text.UTF8Encoding $false))
        try {
            $edit = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'edit', "$($existingPr.number)", '--body-file', $editFile, '--repo', $repo)
            $edit.Output | ForEach-Object { Write-Host $_ }
            if ($edit.ExitCode -ne 0) {
                Write-Error "PR #$($existingPr.number) is open and the branch was pushed, but updating its body FAILED (exit $($edit.ExitCode)): $($edits -join ' + '). If a closing keyword was among the changes, do NOT merge yet - without it in the body GitHub closes nothing. Add it by hand, or rerun."
                exit 1
            }
            Write-Host "Updated PR #$($existingPr.number) body: $($edits -join ' + ')." -ForegroundColor Green
        } finally {
            Remove-Item -Path $editFile -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "PR #$($existingPr.number) was already open for '$branch' - the push above updated it." -ForegroundColor Green
    Write-Host "  $($existingPr.url)"
    if (-not $RefreshBody) {
        Write-Host "Title and body left as they are; -RefreshBody rewrites the description from the entry, and 'gh pr edit' retitles." -ForegroundColor DarkGray
    } else {
        Write-Host "Title left as it is; retitle with 'gh pr edit' if you want it changed." -ForegroundColor DarkGray
    }
    exit 0
}

if ($info.IsKnown) {
    $label = $info.Label
} else {
    $label = 'question'
    Write-Warning "Unknown branch prefix '$($info.Prefix)' - label 'question' set; classify the PR manually."
}

# A PR CANNOT BE CREATED NAMELESS, and this is the one place that has to hold. The emptiness gate above
# already refuses an entry whose title section is empty -- but -Force waves that gate through for the entry
# that legitimately quotes the scaffold wording, and an empty title would then reach `gh pr create --title ''`
# and be refused by gh with a message about a flag rather than about the entry. Checked HERE, on the create
# path only: a resumed PR keeps its own title and has already exited above.
if (-not $prTitle) {
    Write-Error ("open-pr cannot name this PR -- the entry's title section is empty ($entryPath).`n`nThe PR title is composed from the branch prefix and that section (#506), so fill it in and run again. It is what CHANGELOG.md and the release documents will call this change too.")
    exit 1
}
Write-Host "PR title (from the entry): $prTitle" -ForegroundColor DarkGray

if (-not $Body) {
    $templatePath = Join-Path $repoRoot ".github\pull_request_template.md"
    if (Test-Path $templatePath) {
        $templateLines = Get-Content -Path $templatePath -Encoding UTF8

        # Description from the changelog entry file <SafeName>.md: everything after the compact
        # ###-heading line ("### title - type - date"). This file always exists on the branch.
        # $entryPath was resolved before the gates, alongside $info.
        #
        # Read once, above, by Get-EntryDescription (pr-body-lib) rather than by an inline loop here:
        # -RefreshBody needs the SAME extraction, and a second copy of the rule is how this repo's
        # accumulation bugs start. The move also put it under test -- it now refuses to treat a LATER
        # '###' in the entry's own prose as the heading, which would have cut a description short while
        # looking perfectly plausible.
        $desc = $entryDescription

        # Tick / fill in what the script deterministically knows:
        #   - the "Type of change" box whose line contains `<prefix>/`;
        #   - the placeholder under "What does this change do?" -> the description;
        #   - "Changelog entry written": true once the entry file actually holds an entry (just read);
        #   - "Requested by Dave": always true -- this script only runs at Dave's request.
        # The remaining checklist items stay empty on purpose: human judgement checks.
        # Each of the three string matches is BILINGUAL: it accepts both the legacy Dutch template
        # strings AND the new English ones, so a consumer whose PR template is still Dutch keeps working.
        $prefixPattern = '^- \[ \] `' + [regex]::Escape($info.Prefix) + '/`'
        # NOT Test-Path any more, and that is a correctness fix rather than a rename. Since the split the
        # entry lives at a fixed path that EXISTS ON THE TRUNK in its reset state, so "the file is there"
        # stopped being evidence of anything -- it would tick the box on a branch that never wrote an
        # entry, which is the one direction a self-ticking checklist must never fail in. The test is
        # whether the file actually holds an entry, which is the same structural test the fold uses.
        $entryExists = (Test-Path -LiteralPath $entryPath) -and
            (Test-BranchChangelogIsFilled -Text ([System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)))

        # #101: the description placeholder(s) and the approval-checklist pattern are overridable
        # via optional repo-config functions, so a consumer with its own PR template text does not
        # need a wrapper. Guard via Get-Command so a repo-config.ps1 that does not define these
        # (the workshop's own, and every existing consumer) keeps exactly today's behavior.
        # Which of the two sources the list came from, kept for the warning below: "your repo-config
        # answered this" and "the built-in list answered this" send the reader to different files, and
        # that is the first thing they need in order to repair it.
        $descPlaceholderSource = 'the built-in list'
        $descPlaceholders = if (Get-Command -Name Get-PrDescriptionPlaceholder -ErrorAction SilentlyContinue) {
            $descPlaceholderSource = 'Get-PrDescriptionPlaceholder in scripts/repo-config.ps1'
            @(Get-PrDescriptionPlaceholder)
        } else {
            # RECOGNISE THREE, WRITE ONE (#538) -- the list itself moved to pr-body-lib.ps1 on
            # August 10, 2026 (#573). It was three literals right here, which meant nothing outside this
            # script could read them: the reference template the plugin now ships could not be held
            # against the list that has to recognise it, and that gap IS the defect #573 reported.
            @(Get-PrDescriptionPlaceholderDefaults)
        }
        $approvalPattern = if (Get-Command -Name Get-PrApprovalPattern -ErrorAction SilentlyContinue) {
            Get-PrApprovalPattern
        } else {
            '^- \[ \] (Aangevraagd door Dave|Requested by Dave)'
        }

        # A PLACEHOLDER THE LIST HAS NEVER SEEN IS THE ONE FAILURE THAT LOOKS LIKE SUCCESS (#573).
        # The comparison below is an exact whole-line match, so a template one word away from a
        # recognised string falls straight through to the `else` that passes the line on: the
        # description is never inserted, and the run reports success. Measured at a consumer -- 12 of
        # 60 merged PRs carried no description at all, found months later by diffing their template
        # against this repo's rather than by anything failing.
        # The asymmetry is what earns the flag: a MISSING placeholder is caught by the first person
        # who reads the PR, while a NEAR-MISS produces a body that is structurally correct and empty
        # exactly where it matters. Recorded here rather than inside the `else`, because the `else`
        # also runs for every ordinary line and cannot tell the two apart.
        $descPlaceholderMatched = $false

        $filled = foreach ($line in $templateLines) {
            if ($line -match $prefixPattern) {
                $line -replace '^- \[ \]', '- [x]'
            } elseif ($desc -and ($descPlaceholders -contains $line)) {
                $descPlaceholderMatched = $true
                $desc
            # 'written' joined the alternation with the branch/ split, which renamed the item: the file is
            # no longer *created* by the branch (it exists on the trunk in its reset state), it is written
            # into. All three spellings are accepted for the reason the two Dutch/English ones already are
            # -- a consumer's PR template is their file, and this script must not silently stop ticking an
            # item because the template it ships with moved on.
            } elseif ($entryExists -and $line -match '^- \[ \] Changelog entry(-bestand aangemaakt| file created| written)') {
                $line -replace '^- \[ \]', '- [x]'
            } elseif ($line -match $approvalPattern) {
                $line -replace '^- \[ \]', '- [x]'
            } else {
                $line
            }
        }
        $Body = ($filled -join "`n")

        # A WARNING RATHER THAN A REFUSAL, deliberately. The branch is sound, the entry is filled in
        # and the PR is worth opening; what is wrong is one line of a file this script does not own.
        # Refusing would block a consumer on a template they may not be able to edit right now, while
        # a warning turns a defect nobody could see into one nobody can miss. It names the file, the
        # strings it compared against and the seam that overrides them, because the reader of this
        # line is by definition somebody who does not know this list exists.
        # No opt-out for a template that deliberately carries no placeholder: an entry description
        # that reaches no PR body is the outcome this whole block exists to produce, so there is no
        # correct silent version of it -- and an exemption list is the shape this repo keeps getting
        # bitten by.
        if ($desc -and -not $descPlaceholderMatched) {
            Write-Warning (
                "The PR body was built from .github/pull_request_template.md, but NONE of its lines matched a description placeholder -- this PR gets no description at all.`n" +
                # $(...) around the variable, not a bare $name: a colon straight after a variable name
                # is parsed as a scope/drive qualifier, so the subexpression is what keeps the line
                # readable AND correct.
                "  Compared against $($descPlaceholderSource):`n" +
                (($descPlaceholders | ForEach-Object { "    $_" }) -join "`n") + "`n" +
                "  Fix: make the template carry one of those lines verbatim, or define Get-PrDescriptionPlaceholder in scripts/repo-config.ps1 to name your own."
            )
        }
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
    $create = Invoke-NativeCapture -FilePath 'gh' -Arguments (@('pr', 'create', '--base', 'main', '--head', $branch, '--title', $prTitle, '--body-file', $bodyFile, '--label', $label, '--repo', $repo) + $extraGhArgs)
    $create.Output | ForEach-Object { Write-Host $_ }
    if ($create.ExitCode -ne 0) { Write-Error "Creating the PR failed (is gh logged in?)."; exit 1 }
} finally {
    Remove-Item -Path $bodyFile -Force -ErrorAction SilentlyContinue
}
Write-Host "PR created for '$branch'." -ForegroundColor Green
