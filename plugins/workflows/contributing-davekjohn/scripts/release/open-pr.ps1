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
    the DEPLOY section of development.md. So the sentence is written once, at `new-branch -Title`, and the PR, the
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
         (the DEPLOY section of development.md, an older branch/ pair, or the pre-split
         <SafeName>.md in the repo root), which always
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

    Link gate (inbound #806): a relative link in the entry must resolve FROM THE REPO ROOT, because that
    is where the entry's text lands -- it is folded verbatim into CHANGELOG.md, two directories up from the
    file the author is editing. So a link that is correct in front of you is dead the moment it moves, and
    the natural instinct produces exactly that: a consumer merged two '../../scripts/...' links that landed
    at the root pointing outside the repo, with every gate green because their linter validated them where
    the file sat. Refused HERE and not in the fold, which is where the report asked for it: a defect
    decidable before the merge is caught while the branch is still the only thing affected, whereas
    refusing an already-merged branch's fold leaves an unfolded entry on the trunk with main looking
    finished. The message names the root-relative form rather than only the dead one, because a finding
    that says "does not exist" sends the author to add another '../'. Not -Force-able, as with the tier
    gate: there is no legitimate dead link, and the fix the message spells out is one line.

    Title gate (#936, August 26, 2026): the entry's title must not already carry the branch's own type
    prefix. The type is composed in from the branch name, so a title typed as 'fix: ...' on a fix/ branch
    becomes 'fix: fix: ...' -- which is what PR #934 opened as, printed as a DarkGray progress line that no
    gate read. Refused rather than stripped, because those same words are the entry's Pull Request section
    and travel verbatim into CHANGELOG.md and the release documents: correcting the title here would repair
    the copy a reviewer sees and keep the copy that lasts. Bounded to exactly this branch's prefix and not
    to any '<word>:', so a legitimate 'sync-roster: ...' cannot be accused -- the fear of that stripper is
    why the guard was left out until the defect it predicted arrived. -Force-able, as the scaffold gate is
    and the link gate is not: this refuses text somebody wrote, and a consumer whose seam names an unusual
    prefix should get a warning rather than a wedge.

    Label gate (inbound #1221, September 2, 2026): the label this PR would be given has to exist in the
    repository. It used to be handed to `gh pr create --label` unchecked, so gh was the one to discover
    it does not exist -- and gh refuses the whole create, after every gate above has run and the branch
    has been pushed. Measured in a consumer whose 'bug' and 'enhancement' labels had been deleted
    org-wide because the issue TYPE now carries that classification: the seam table was correct the day
    before and nothing in the consumer changed. One `gh label list` answers it, and it runs BEFORE the
    lint and test gates so the author who has to go and create a label hears it in seconds. Create path
    only (an existing PR keeps its own labels and is never sent one), not -Force-able as the link and
    impact gates are not, and a query that fails or returns nothing readable leaves the old behaviour
    rather than blocking. The refusal names the label, the prefix that produced it, the seam file that
    maps them and the labels that do exist -- see Get-MissingLabelNote for why neither substituting nor
    dropping the label is the kindness it looks like.

    Lint gate (guardrail for main): before the push, scripts/lint/check-plugin-integrity.ps1 runs.
    If that finds errors (invalid marketplace/plugin manifests, missing agent-def frontmatter,
    dead links), the branch is NOT pushed and NO PR is opened. Use -SkipLint to deliberately skip
    the gate (escape valve).

    Test gate (a lesson from PR #54, where a red suite only surfaced on CI): after the lint, ALL
    test suites run (scripts/tests/*.tests.ps1), exactly as CI does. A failing suite blocks the
    push and the PR. Use -SkipTests to deliberately skip this gate (escape valve).

    BOTH GATES SAY WHEN THE CHECKOUT MOVED WHILE THEY RAN (issue #1145). They read the WORKING TREE
    for a minute or more, and this checkout is not private to them: ship-pr backgrounds itself so the
    session can get on with something else, and that session runs maintenance commands beside it --
    new-branch.ps1 cuts a branch, worktree-lane.ps1 moves the tree. Measured on PR #1144 -- one suite
    of 55 red inside the gate, green standalone on the same commit seconds later, while
    prune-merged.ps1 held the trunk in the same checkout; that script stopped taking it in #1147, and
    the class it belongs to did not go with it. So each gate is asked
    afterwards whether the tree held still (Get-GateTreeMovedNote): a RED then says it is not
    trustworthy instead of reading as a real defect, and a GREEN is reported but NOT recorded as gate
    evidence. Neither is a refusal -- a red still blocks the push, and the remedy is to re-run.

    Resolves gate (a lesson from PRs #341-#343): a PR that repairs an issue must say so with a
    CLOSING KEYWORD, or the issue stays open after the merge. Those three PRs each referenced their
    issues as a plain mention (`#332`), GitHub therefore auto-closed nothing, and the manual
    `gh issue close` was skipped three times running -- leaving eight repaired findings OPEN while
    the changelog said they were done. So the decision is now forced rather than remembered:
      - `-Resolves '331,332'` writes a `## Resolved issues` block with one `Closes #<n>` per issue
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

    THE QUOTES IN THE EXAMPLES ARE LOAD-BEARING, and they were missing until August 20, 2026 -- three
    .EXAMPLE lines across this script and ship-pr.ps1 read `-Resolves 331,332` and could not run. Called
    DIRECTLY from a PowerShell prompt, `331,332` is parsed as an array before binding, and a script FILE
    with [CmdletBinding()] refuses an array for a [string] parameter: "Cannot process argument
    transformation on parameter 'Resolves'". (A scriptblock coerces it to '331 332' instead, which is why
    this is easy to miss when probing the behaviour rather than the file.) So the type choice above does
    exactly what it was chosen for -- it fails loudly instead of silently -- and the price is that every
    example has to carry its quotes. The shipped skill pages always did.

.PARAMETER NoResolves
    Declare that this PR closes no issue. The deliberate way past the resolves gate.

.PARAMETER Force
    Ship an entry the content gates object to -- the escape valve for the scaffold gate, for the rare entry
    that legitimately quotes that wording outside a fence, and for the title gate, for the rare title that
    legitimately opens with this repo's own type name. Warns instead of blocking.
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

.PARAMETER GatesOnly
    Run this repo's lint and test gates against the working tree and stop there -- no branch check, no
    push, no PR. Exit 0 when both are green, 1 when either is not. It writes nothing to the working
    tree and nothing to GitHub; the one thing it does record is gate evidence, below.

    IT EXISTS FOR THE COMMITS THAT ARE MADE ON THE TRUNK (issue #1156, August 30, 2026). Three changes
    land directly on `main` under named exceptions -- the fold, the release commit, and the release
    notes -- and the first two are made by scripts that gate themselves. The third is typed by hand, and
    `cut-release`'s step 4 told its reader to run the gates "exactly as open-pr would have run them for
    you". They cannot: this script refuses on `main` several hundred lines before it reaches a gate.

    So the instruction was right and unreachable, and what a reader does with an unreachable instruction
    is rebuild it. That hand-rolled invocation is the actual hazard, and it is quiet rather than loud --
    it misses `Get-TestCommands`, so a consumer whose suites are not all PowerShell has the rest of them
    skipped without a word, and it hardcodes a lint script instead of reading `Get-LintScript`. This
    flag runs the same `Invoke-WorkflowGates` the PR path runs, through the same seams, so the answer it
    gives is the answer the PR would have given.

    NOT AN ESCAPE VALVE, and the opposite of one: it adds a place the gates can run, it removes none.
    `-SkipLint` / `-SkipTests` still work here and still mean what they mean everywhere else. A green
    run also records gate evidence like any other, so a later `open-pr` on the identical tree skips what
    this already proved.
.EXAMPLE
    ./scripts/release/open-pr.ps1

.EXAMPLE
    ./scripts/release/open-pr.ps1 -Resolves '331,332'
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
    [switch]$RefreshBody,
    [switch]$GatesOnly
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
    Write-Error ("open-pr cannot run -- missing repo-owned configuration in the repo root ($repoRoot):`n  " + ($absent -join "`n  ") + "`n`nThese files are repo-specific and belong in the consumer's repo root:`n  scripts\repo-config.ps1      -- Get-RepoName / Get-RepoBlobUrl / Get-LintScript`n  scripts\lib\branch-info.ps1  -- the repo-owned branch-prefix table`n`nCreate them (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the source repo as a model) and run again afterward.")
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

# Gate evidence: what the gates already proved, and against which exact working state. Same
# not-repo-owned, travels-with-the-payload reasoning as the three libs above.
. (Join-Path $PSScriptRoot '..\lib\gate-lib.ps1')

# WHAT IS BEHIND THE PLAN (issue #1026). park-cycle already takes this measurement, on the device holding
# the work, and writes it into a commit body -- where the reader who could act on it never looks. open-pr
# is that reader, and it had no way to ask the question. Same not-repo-owned, travels-with-the-payload
# reasoning as the libs above; park-lib needs only the native-capture helper, loaded further up.
. (Join-Path $PSScriptRoot '..\lib\park-lib.ps1')

# Pre-flight (#86): an unfilled scaffold (repo-config still at VUL-IN) would otherwise only fail
# further down with an unclear gh error. Stop here with a clear pointer.
if ($repo -match 'VUL-IN' -or (Get-LintScript) -match 'VUL-IN') {
    Write-Error "open-pr cannot run -- scripts\repo-config.ps1 still contains VUL-IN placeholders. Fill in Get-RepoName and Get-LintScript with this repo's values and run again."
    exit 1
}

# -GatesOnly: the gates, and nothing else (issue #1156). Placed HERE deliberately -- after both
# pre-flights, which are exactly the conditions the gates need (repo-config present, and filled in
# rather than still at VUL-IN), and BEFORE the branch check just below it, which is the one thing
# standing between a trunk commit and its gates. Everything below this point is about a branch, a push
# or a PR, and none of it applies.
#
# Invoke-WorkflowGates is the same function the PR path calls further down, with only the two strings
# that describe the consequence differing. That is the whole point of the flag: a second way to reach
# the gates that cannot reach a different verdict.
if ($GatesOnly) {
    # SAY WHAT IS BEING IGNORED, rather than dropping it. Everything below this block is about a
    # branch, a push or a PR, so a PR-shaped parameter passed alongside -GatesOnly has no effect --
    # and a flag that quietly does nothing is the same class of failure as the invocation this whole
    # change exists to replace. Named, not refused: the run is still exactly what was asked for.
    $ignored = @()
    if ($Title)       { $ignored += '-Title' }
    if ($Body)        { $ignored += '-Body' }
    if ($Resolves)    { $ignored += '-Resolves' }
    if ($NoResolves)  { $ignored += '-NoResolves' }
    if ($Force)       { $ignored += '-Force' }
    if ($RefreshBody) { $ignored += '-RefreshBody' }
    if ($ignored.Count -gt 0) {
        Write-Warning ("-GatesOnly runs the gates and nothing else, so these were ignored: " + ($ignored -join ', ') + ".")
    }

    if (-not (Invoke-WorkflowGates -RepoRoot $repoRoot -SkipLint:$SkipLint -SkipTests:$SkipTests -Context 'the gate run' -FailureConsequence 'nothing else ran, nothing was written')) {
        exit 1
    }
    Write-Host "gates green -- nothing was pushed and no PR was opened (-GatesOnly)." -ForegroundColor Green
    exit 0
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq 'main') { Write-Error "You are on main; a PR is created from a branch."; exit 1 }

# Resolved BEFORE the gates (it is a pure function of the branch name), because the resolves gate
# below needs the entry-file path and the label logic further down needs the same object.
$info = Get-BranchInfo -Branch $branch

# Dot-sourced HERE rather than inside the scaffold gate below, because resolving the entry's path now
# needs the lib too. One load, at the first point anything requires it.
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
# AND THE SEAM READER, for the link gate's base (inbound #967). $PSScriptRoot-relative like the lib above:
# this is workflow machinery that travels with the script, not a repo answer -- the repo's answer is the
# optional Get-ChangelogPath in its own repo-config.ps1, which is already loaded.
. (Join-Path $PSScriptRoot '..\lib\seam-lib.ps1')

# THE ENTRY LIVES IN branch/ SINCE THE SPLIT (Dave, August 6, 2026), with the root <SafeName>.md still
# accepted as the fallback. Both exist in the wild simultaneously: a branch created before the split
# carries the root form, and consumers receive these scripts through a plugin update rather than by
# choosing to. Preferring the new path and falling back to the old one is what lets a branch cut over
# mid-flight without this gate suddenly finding no entry -- which would not merely warn, it would let a
# scaffolded entry through, since a gate with nothing to read reports nothing.
$branchFiles = Get-BranchFilePaths
# Resolve- rather than Get-, because the file may still carry its pre-August-19-2026 name on a branch
# that was created before the rename -- exactly the mid-flight cut-over the paragraph above describes,
# one rename further on.
$entryPath = Join-Path $repoRoot (Resolve-BranchFilePath -Kind Deployment -RepoRoot $repoRoot)
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
    # THE ENTRY IS A SECTION OF THE BRANCH DOCUMENT, so the head is dropped here, once, at the read --
    # Get-DevelopmentEntryText. Every reader below is entry-shaped and would otherwise be handed the
    # plan as well: the description would come back as the guidance comment, and the scaffold gate would
    # accuse the step list of being an unfinished entry.
    $entryText = Get-DevelopmentEntryText -Text ([System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8))

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

    # Get-EntryPrTitle, which knows BOTH places the title has lived: the first line of the 'Pull Request'
    # section since August 16, 2026, and the 'Branch title'/'Branch description' section before that. It
    # reads the ANSWER rather than the raw body, so a guidance comment left standing above it cannot end up
    # in the PR title, and it skips the two lines the fold appends underneath.
    $titleWords = Get-EntryPrTitle -EntryText $entryText

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
    # EITHER SECTION COUNTS AS HAVING ONE. A new entry carries 'Pull Request' and no 'Branch title', so
    # asking after the old key alone would send every new entry down the pre-split fallback and title its
    # PR from the branch heading -- plausible-looking, and hiding the empty title the gate below exists to
    # report.
    $hasTitleSection = (Test-EntryHasSection -EntryText $entryText -Key 'Description') -or
                       (Test-EntryHasSection -EntryText $entryText -Key 'PullRequest')
    if (-not $titleWords -and -not $hasTitleSection) {
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
# -Utf8 because 'body' is in the field list (issue #907): the record this builds carries the existing
# PR's prose, and -RefreshBody then compares against it. number and url would not have cared.
$prLookup = Invoke-NativeCapture -Utf8 -FilePath 'gh' -Arguments @('pr', 'list', '--head', $branch, '--base', 'main', '--state', 'open', '--json', 'number,url,body', '--limit', '1', '--repo', $repo) -DiscardStderr
if ($prLookup.ExitCode -ne 0) {
    Write-Warning "could not ask gh whether '$branch' already has an open PR (exit $($prLookup.ExitCode)) - continuing as if it has none."
} else {
    # The parse itself lives in pr-issues-lib.ps1 (Get-ExistingPrRecord) so the 5.1 array-flattening
    # pitfall it navigates is covered by pr-issues.tests.ps1 -- this script drives a live remote and
    # cannot be. It returns $null for anything it cannot read, which is the same "no existing PR" the
    # failed-query branch above assumes.
    $existingPr = Get-ExistingPrRecord -Json ($prLookup.Output -join "`n")
}

# ALREADY MERGED IS ITS OWN OUTCOME, AND IT IS THE ANSWER TO A QUESTION THE LOOKUP ABOVE CANNOT ASK.
# '--state open' is the right filter for "is there a PR to update", and it was the only one until
# inbound #1077: for a branch whose PR is MERGED it answers "none", so this script took the create path
# and GitHub refused with 'No commits between main and <branch>'. What the reader then saw was a
# PowerShell error naming gh authentication, on a branch that was in fact completely finished.
#
# THE STATE IS NOT EXOTIC, which is why it earns a query of its own rather than a better error message:
# a second session, a hand-merge on github.com, or simply re-running ship-pr all produce it -- and the
# local branch survives a merge, because --delete-branch-on-merge removes the remote one only.
#
# BEFORE THE GATES, THE PUSH AND THE CREATE, deliberately: there is nothing to lint, nothing to push and
# nothing to open for a branch whose work has landed. Exit 0 rather than 1 -- nothing failed, and the
# run's only news is good. ship-pr reads the same state for itself in its step 2, because both scripts
# are runnable on their own and neither may depend on the other having looked.
#
# A FAILED QUERY IS STILL NOT AN ANSWER, same as above: it leaves $mergedPr null and the run continues
# exactly as it did before this block existed.
if (-not $existingPr) {
    $mergedLookup = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--head', $branch, '--base', 'main', '--state', 'merged', '--json', 'number,url', '--limit', '1', '--repo', $repo) -DiscardStderr
    if ($mergedLookup.ExitCode -eq 0) {
        $mergedPr = Get-ExistingPrRecord -Json ($mergedLookup.Output -join "`n")
        if ($mergedPr) {
            Write-Host "PR #$($mergedPr.number) for '$branch' is already merged -- nothing to open. $($mergedPr.url)" -ForegroundColor Green
            Write-Host "A follow-up cycle on the same subject gets its own branch -- name it with a -v2 suffix by hand." -ForegroundColor DarkGray
            exit 0
        }
    }
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
    # What the branch itself mentions: the WHOLE development document (always present on a branch) plus a
    # -Body the caller supplied, since either can carry the reference. Deliberately not narrowed to the
    # DEPLOY section the way the two gates are -- an issue named in a step is a mention of that issue, and
    # this is the one reader of this file whose subject is the branch rather than the entry.
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
# moves the entry into CHANGELOG.md, and the next release moves it on into the changelog notes and
# into every per-plugin CHANGELOG.md that travels to consumers in the plugin cache. By then the place
# a reviewer would look is the one place it no longer is -- CHANGELOG.md's Pull Requests section is
# empty after a cut. Held against all 70 archived notes: one older instance, then three in one day, so
# this is a real rate rather than a one-off.
#
# NOT -SkipLint-able and deliberately its own gate: it costs one read of a file already in hand, needs
# no gh and no subprocess, and refusing it is a content decision rather than a tooling one. -Force is
# the escape valve, for the rare entry that legitimately quotes the wording outside a fence.
if (Test-Path -LiteralPath $entryPath) {
    # The DEPLOY section only, for the reason stated at the first read of this file above: the plan sitting
    # over it would be accused of being an unfinished entry.
    $entryText = Get-DevelopmentEntryText -Text ([System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8))
    $scaffoldFindings = @(Get-EntryScaffoldFindings -EntryText $entryText -Wording (Get-EntryScaffoldWording))
    if ($scaffoldFindings.Count -gt 0) {
        # Repo-relative, not the bare leaf. Every branch's document is called development.md, so a
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
    $progressRel  = Resolve-BranchFilePath -Kind Cycle -RepoRoot $repoRoot
    $progressPath = Join-Path $repoRoot $progressRel
    if (Test-Path -LiteralPath $progressPath) {
        # ONE READ FOR BOTH GATES BELOW. The step gate asks whether the plan is finished and the backing
        # gate asks what is behind it -- two questions about the same document, and reading it twice would
        # let them answer over two different versions of it if anything wrote in between.
        $progressText = [System.IO.File]::ReadAllText($progressPath, [System.Text.Encoding]::UTF8)
        $stepFindings = @(Get-BranchProgressFindings -Text $progressText)
        if ($stepFindings.Count -gt 0) {
            # THE REMEDY COMES WITH THE FINDING (inbound #1081). This block used to print one shared
            # paragraph under both labels, and it was only true for one of them: an author who met
            # 'still the scaffolded step' and followed the marks it offered was refused again, by the
            # same gate, printing the same lines that had just failed. Get-BranchProgressFindings owns
            # the sentence now -- one composer for the two callers that print these.
            $stepDetail = ($stepFindings | ForEach-Object { "  - $($_.Label): $($_.Line)`n      $($_.Remedy)" }) -join "`n"
            Write-Error @"
step-list gate: $progressRel still has unresolved steps - nothing pushed, no PR opened.

$stepDetail

A branch reaches a PR when its own plan is finished, and each finding above says what resolves it. A
dropped step keeps its line and its reason, which is the half worth reading later. There is no -Force for
this gate, and none is needed: every finding here has an act that clears it.
"@
            exit 1
        }

        # BACKING GATE (issue #1026): a finished plan with nothing behind it does not become a PR.
        #
        # WHAT WAS MEASURED. PR #1025 merged an entry describing two new rules in a manual whose edit was
        # never committed: the branch's whole diff was this document, the fold then removed it, and the
        # merge delivered a changelog entry and nothing else. Every gate was green -- the four that read
        # this document are satisfied by an entry with no content behind it, because none of them reads
        # the diff.
        #
        # AND THE SIGNAL ALREADY EXISTED, in the wrong place. park-cycle's backing note (#960/#976) named
        # the count, named the state and gave the instruction that would have prevented the merge -- in a
        # COMMIT BODY, which is right for the reader on a second device and invisible to the session that
        # is holding the uncommitted file and about to open the PR. This gate is that same measurement,
        # from the same function, delivered to the reader who can still act on it.
        #
        # THE CONDITION IS THE PARK NOTE'S ALARM, asked of the same function rather than spelled again --
        # Get-BranchBackingFinding in park-lib. Deliberately just as narrow: a plan that CLAIMS to be
        # complete with nothing committed on the branch to show for it. 'Any resolved step with no commit
        # behind it' would fire on nearly every early branch, and a gate that fires on almost every run is
        # one nobody reads by the time it matters.
        #
        # -Force-ABLE, unlike the step gate above. There IS a legitimate case: a branch whose whole
        # deliverable is the changelog entry. Rare rather than impossible, so the valve is a warning; no
        # valve is a wedged author.
        $tally   = Get-BranchProgressTally -Text $progressText
        $backing = Get-GitParkBacking -RepoRoot $repoRoot -Trunk (Get-BranchTrunkName) -Paths @($progressRel)
        $backingFinding = Get-BranchBackingFinding -Steps $tally -Backing $backing

        if ($backingFinding) {
            # THE TWO KINDS ARE DIFFERENT FAULTS AND GET DIFFERENT ANSWERS. Work uncommitted HERE is this
            # session's own omission, repairable in one command, and it is what #1025 was -- so it refuses.
            # 'NotInThisCheckout' means the work is not on this machine at all, which open-pr cannot tell
            # from a branch that legitimately ships only its entry; that one is said out loud and allowed,
            # because refusing it would wedge the cross-device flow #960 exists to serve.
            $stateLine = "$($backingFinding.Resolved) of $($backingFinding.Total) step(s) resolved; nothing else committed on this branch"

            if ($backingFinding.Kind -eq 'NotInThisCheckout') {
                Write-Warning @"
backing gate: $stateLine, and nothing is uncommitted here either.

The plan reads as FINISHED and this PR would carry $progressRel alone -- the fold removes that file, so
the merge would deliver a changelog entry and no content. If the work is on another machine, let that
checkout commit and push first. Opening the PR anyway is what you are doing now.
"@
            } elseif ($Force) {
                Write-Warning "backing gate: $stateLine, and $($backingFinding.Uncommitted) file(s) are uncommitted here - but -Force was given."
            } else {
                Write-Error @"
backing gate: the plan reads as FINISHED and $($backingFinding.Uncommitted) file(s) are uncommitted - nothing pushed, no PR opened.

  $stateLine
  $($backingFinding.Uncommitted) file(s) uncommitted in this working copy, besides $progressRel

This PR would carry that document alone. The fold removes it at the merge, so what would land is a
changelog entry describing work that never arrived -- which is how PR #1025 shipped a manual edit that
only ever existed in a working copy.

The work is not missing; it is right here, uncommitted. Commit it and run again:

  git status
  git add -A && git commit

If this branch really does ship its entry alone, run with -Force.
"@
                exit 1
            }
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

    # Link gate: the entry's relative links have to resolve from WHERE ITS TEXT LANDS (inbound #806) --
    # the directory of the changelog the fold writes into. The entry is folded verbatim into that file, so
    # where the two directories differ a link that is right in the file being typed in is dead the moment
    # it moves, and the natural instinct produces exactly that form.
    #
    # THE BASE IS THE SEAM'S ANSWER AND NOT THE REPO ROOT (inbound #967). #806's repair hard-coded the root,
    # which was true of every repo then and stopped being true when #914 made Get-ChangelogPath
    # isolate-by-default: a consumer's CHANGELOG.md sits in the workflow folder now -- the SAME directory the
    # entry is written in -- so this gate refused the link form that is correct after the fold and demanded
    # the one that is dead. Met in BWJ-ecommerce/xoxowildhearts, whose own doc lint measures from the folder,
    # so its two gates disagreed and its entries avoided relative markdown links entirely.
    #
    # READ THE SAME WAY THE FOLD READS IT, which is the only thing that makes this gate's answer true:
    # Get-SeamValue over the repo's own optional Get-ChangelogPath, with Get-DefaultChangelogPath as the
    # computed default. Any other derivation would be a second definition of the destination, free to
    # disagree with the one script that actually writes there.
    #
    # AND WITHOUT Assert-WorkflowIsolatedSeamPath, deliberately, which the fold and the cut both call right
    # after this read. That assert REFUSES, and its subject is provenance rather than links -- adding it here
    # would gate every PR in every consumer on a question about a file this script neither reads nor writes.
    # The fold still asks it at the point it matters, so nothing is skipped; what is declined is a new
    # refusal arriving on the PR path under the heading of a link repair.
    $changelogRel = Get-SeamValue -Name 'Get-ChangelogPath' -Default (Get-DefaultChangelogPath -RepoRoot $repoRoot)
    $destDirRel = ((Split-Path $changelogRel -Parent) -replace '\\', '/').Trim('/')
    #
    # HERE RATHER THAN IN THE FOLD, which is where #806 asked for it, and the reason is the fold's own
    # doctrine on the same kind of fault: a defect decidable BEFORE the merge is refused while the branch is
    # still the only thing affected, because refusing an already-merged branch's fold leaves an unfolded
    # entry on the trunk with main looking finished -- the silent half-state this repo has measured. The
    # fold says that in those words about a missing significance score. A fold-time REWRITE is declined for
    # a second reason: the fold copies the entry verbatim on purpose, and an author whose link is silently
    # corrected writes the same link again into the next document, where nothing corrects it.
    #
    # NOT -Force-able, for the same reason as the impact gate above: -Force exists for text somebody
    # legitimately wrote, and there is no legitimate dead link. Getting past this is a one-line edit the
    # message spells out, not a judgement call -- which is what makes the absence of an escape valve fair.
    $linkFindings = @(Get-EntryLinkFindings -EntryText $entryText -RepoRoot $repoRoot -DestDirRel $destDirRel)
    if ($linkFindings.Count -gt 0) {
        $detail = ($linkFindings | ForEach-Object {
            if ($_.Suggested) { "  $($_.Target)  ->  write it as: $($_.Suggested)" }
            else { "  $($_.Target)  (resolves from nowhere -- check the path)" }
        }) -join "`n"
        # THE MESSAGE NAMES THE TWO DIRECTORIES IT ACTUALLY COMPARED, rather than restating the convention.
        # It used to say 'the repo root' and 'contributing-davekjohn/branch/', and both went wrong in their
        # own way: the first was the seam's old default (inbound #967) and the second was where the entry
        # sat before it became a section of the cycle document -- so on the shipped defaults this refusal
        # named two paths, neither of which was in play.
        $entryDirRel = ((Get-BranchFilePaths).Directory -replace '\\', '/').Trim('/')
        $destShown  = if ($destDirRel)  { "$destDirRel/" }  else { 'the repo root' }
        $entryShown = if ($entryDirRel) { "$entryDirRel/" } else { 'the repo root' }
        # SAME DIRECTORY IS A DIFFERENT SENTENCE, because there the advice is not 'drop the ../' -- a link
        # that reads correctly in front of the author already resolves at the destination and produces no
        # finding at all. Everything listed above is then a plain typo, and saying otherwise would send
        # somebody hunting a base mismatch that cannot exist.
        $why = if ($destDirRel -eq $entryDirRel) {
            @"
The entry's text is copied VERBATIM into $changelogRel, which sits in $destShown - the same directory as the
file you are editing. So each path is written exactly as it reads here, and a link listed above resolves from
neither that directory nor the repo root: it is a typo rather than the wrong base.
"@
        } else {
            @"
The entry's text is copied VERBATIM into $changelogRel, so its relative links have to resolve FROM
$destShown - not from $entryShown, where the file you are editing sits. A link that looks right in front of
you is the failure this catches, so do not add another '../': write each path as it reads from $destShown.
"@
        }
        Write-Error @"
link gate: $(Split-Path $entryPath -Leaf) carries relative link(s) that will be dead once the entry is folded - nothing pushed, no PR opened.

$detail
$why
Correct the link(s) and run again.
"@
        exit 1
    }

    # Title gate (#936): the entry's title must not already carry the branch's own type prefix.
    #
    # THE DEFECT ITS OWN COMMENT PREDICTED. Get-PrTitle composes '<branch type>: <the entry's words>' and
    # strips nothing, with a paragraph explaining that the strip was left out because no title in
    # CHANGELOG.md or the release record had ever carried a prefix -- and inviting whoever met the case to
    # come back to it. PR #934 was that case: 'fix: fix: the no-tier fallback drops the whole audience
    # paragraph', from a -Title given with the prefix already on it.
    #
    # REFUSED HERE RATHER THAN STRIPPED THERE, because the entry outlives the PR title. The same line is the
    # folded entry's 'Pull Request' section, so it travels verbatim into CHANGELOG.md and on into the release
    # documents. A silent strip would repair the copy a reviewer sees for a day and keep the copy consumers
    # read; refusing sends the author to the entry, which is the only edit that fixes both. Same doctrine as
    # the link gate above, which declined a fold-time rewrite for the same reason.
    #
    # NOTHING ELSE WOULD HAVE CAUGHT IT. open-pr prints the composed title as a DarkGray progress line and
    # carries on; no gate read it. #934's doubled title was noticed by eye in ship-pr's own output, which is
    # not a gate.
    #
    # BOUNDED TO THIS BRANCH'S PREFIX, in Get-PrTitlePrefixFinding -- deliberately not any '<word>:', which
    # would mangle a legitimate 'sync-roster: ...'. The fear of that stripper is what kept the guard out from
    # August 7 to August 26, 2026, and the bound is what answers it.
    #
    # -Force-ABLE, unlike the link and impact gates and like the scaffold gate it most resembles. This
    # refuses TEXT SOMEBODY WROTE, and a title that legitimately opens with this repo's own type name
    # followed by a colon is rare rather than impossible -- a consumer whose seam names an unusual prefix is
    # where it would surface. An escape valve there is a warning; no escape valve is a wedged consumer.
    $titlePrefix = Get-PrTitlePrefixFinding -Prefix $(if ($info.IsKnown) { $info.Prefix } else { '' }) -TitleWords $titleWords
    if ($titlePrefix) {
        $entryRel = $entryPath.Substring($repoRoot.Length).TrimStart('\', '/')
        if ($Force) {
            Write-Warning "title gate: the title in $entryRel already starts with '$titlePrefix', so the PR reads '$prTitle' - but -Force was given."
        } else {
            Write-Error @"
title gate: the title in $entryRel already carries its own type prefix - nothing pushed, no PR opened.

  the title reads:  $titlePrefix ...
  the PR would be:  $prTitle

The type comes off the BRANCH NAME and is put in front for you, so the title is written as words alone.
Drop the '$titlePrefix' from the title and run again.

Worth knowing why this is refused rather than quietly corrected: those same words are the entry's Pull
Request section, which the fold copies verbatim into CHANGELOG.md and the next release copies on into
releases/. Stripping it here would fix the PR title and leave the line that lasts.

If the title really does begin with that word, ship it with -Force.
"@
            exit 1
        }
    }
}

# --- LABEL GATE: THE LABEL THIS PR WOULD BE GIVEN HAS TO EXIST (inbound #1221) --------------------
#
# THE DEFECT. The branch prefix's label went straight to `gh pr create --label` and gh was the one to
# discover it does not exist. gh refuses the whole create, so no PR is opened -- and by then every gate
# above has run and the branch is on origin:
#
#     could not add label: 'bug' not found
#
# Measured in BWJ-ecommerce/smartwatchbanden on September 1, 2026, where 'bug' and 'enhancement' had
# been deleted org-wide because the issue TYPE now carries that classification. The seam table was
# correct the day before and nothing in the consumer changed, which is why this is a gate and not a
# better error message: any repo that renames or retires a label breaks the same way.
#
# WHY IT IS WORTH A ROUND TRIP: WHEN THE FAILURE LANDS, not that it lands. Everything expensive has
# already happened, the remedy is outside this script (create a label, or edit the seam table), and the
# state left behind is a pushed branch with no PR -- which reads exactly like a parked branch.
#
# BEFORE THE LINT AND TEST GATES, not merely before the push. One `gh label list` is the cheapest
# network call in this script and the suites are the most expensive thing in it, so the author who has
# to go and create a label hears it in seconds rather than after the suites.
#
# THE CREATE PATH ONLY. An existing PR keeps its own labels and `--label` is never sent on that path,
# so a repo that retired a label after the PR was opened must not be blocked from updating it.
#
# NOT -Force-ABLE, like the link and impact gates: -Force exists for text somebody legitimately wrote,
# and a label that does not exist is a fact about the repository rather than a judgement about prose.
# Waving it through could only relocate the failure to after the push, which is the state this gate
# exists to prevent.
#
# AND IT DOES NOT FALL BACK -- see Get-MissingLabelNote's own header for why neither substituting nor
# dropping the label is the kindness it looks like.
$label = ''
if (-not $existingPr) {
    # RESOLVED HERE rather than at the create call, where it sat until this gate existed. The warning
    # for an unknown prefix moved with it, which is where it belongs anyway: it is about the label that
    # is about to be checked.
    if ($info.IsKnown) {
        $label = $info.Label
    } else {
        $label = 'question'
        Write-Warning "Unknown branch prefix '$($info.Prefix)' - label 'question' set; classify the PR manually."
    }

    # -Utf8 because a label name is DATA and routinely carries an emoji or an accent (#907), and
    # -DiscardStderr because gh's own progress is not the answer -- the exit code and the payload are.
    # --limit is load-bearing: `gh label list` defaults to 30, and a truncated list would refuse a PR
    # over a label that exists but did not fit.
    $labelLookup = Invoke-NativeCapture -Utf8 -FilePath 'gh' -Arguments @('label', 'list', '--json', 'name', '--limit', '500', '--repo', $repo) -DiscardStderr
    # A FAILED OR UNREADABLE QUERY IS NOT AN ANSWER, and it deliberately does not block -- the same
    # reasoning the existing-PR lookup gives. An old gh with no --json, a network hiccup or a repo with
    # no labels at all leaves the behaviour this script always had: gh judges the label at the create.
    $repoLabels = @()
    if ($labelLookup.ExitCode -ne 0) {
        Write-Warning "label gate: could not ask gh which labels $repo has (exit $($labelLookup.ExitCode)) - continuing, so 'gh pr create' is again the one that judges '$label', after the push."
    } else {
        $repoLabels = @(Get-LabelNames -Json ($labelLookup.Output -join "`n"))
        if ($repoLabels.Count -eq 0) {
            Write-Warning "label gate: gh returned no readable label for $repo - continuing, so 'gh pr create' is again the one that judges '$label', after the push."
        }
    }

    if ($repoLabels.Count -gt 0) {
        $labelNote = Get-MissingLabelNote -Labels $repoLabels -Label $label `
                                          -Prefix $(if ($info.IsKnown) { $info.Prefix } else { '' }) `
                                          -SeamPath 'scripts\lib\branch-info.ps1' -Repo $repo
        if ($labelNote) {
            Write-Error "label gate: $labelNote`n`nNothing pushed, no PR opened."
            exit 1
        }
        Write-Host "label gate: label '$label' exists in $repo." -ForegroundColor DarkGray
    }
}

# THE GATES BELOW CONSULT WHAT THEY ALREADY PROVED (August 16, 2026). ship-pr.ps1 calls this script,
# so a branch opened in one step and shipped in a later one used to run both gates twice on a commit
# nothing had touched -- measured at 249s of excess on 28.3% of 293 merged PRs, and routed around by
# hand with -SkipLint -SkipTests on every run. That flag is correct only while the commit is
# unchanged, and nothing checked that; the repair is to make the unchanged case not need it.
#
# BOTH GATES MOVED TO Invoke-WorkflowGates (gate-lib.ps1) on August 30, 2026, issue #1156 -- the same
# move Invoke-TestSuiteGate made for its inner loop on August 7, one step further out. This script is
# the ONE documented way to run the gates, and it refuses on `main` six hundred lines ABOVE this point,
# so the release-notes commit -- made standing on the trunk -- had no reachable route to them at all.
# -GatesOnly (handled near the top, right after the pre-flights) is that route, and what it runs is
# THIS function rather than a second copy of it: the whole value of the flag is that the two cannot
# describe the tree differently.
if (-not (Invoke-WorkflowGates -RepoRoot $repoRoot -SkipLint:$SkipLint -SkipTests:$SkipTests -Context 'the PR' -FailureConsequence 'branch not pushed, no PR opened')) {
    exit 1
}

# git push writes its 'remote:' progress to stderr, which under EAP=Stop would die as a terminating
# NativeCommandError before the exit-code check even though git gave exit 0 (the #96/#97/#107
# pitfall). Invoke-NativeCapture runs it under EAP=Continue and hands back output + $LASTEXITCODE.
#
# AND IT IS BOUNDED (inbound #1179). This is the push that hung: measured on DAVE-KOK-BWJ, git spawned
# `git credential-manager get`, that child opened a prompt nothing was listening to, and the call never
# returned -- with the lint + test gate directly above it already paid for and about to be discarded.
# The lib now also runs every child with GIT_TERMINAL_PROMPT=0 and GCM_INTERACTIVE=never, which is what
# closes the measured cause; the bound is what makes ANY other stall here report itself instead of
# reading as "still pushing". The gate above is exactly why this call is worth bounding and not merely
# guarding: a hang at this line is the most expensive hang in the script.
$push = Invoke-NativeCapture -FilePath 'git' -Arguments @('push', '-u', 'origin', $branch) `
                             -TimeoutSeconds $NativeCaptureNetworkTimeoutSeconds
$push.Output | ForEach-Object { Write-Host $_ }
if ($push.ExitCode -ne 0) {
    if ($push.TimedOut) {
        Write-Error "git push did not answer within $NativeCaptureNetworkTimeoutSeconds seconds -- see the [timeout] lines above. The branch is NOT on origin and no PR was opened; the gates passed, so re-running after fixing the credential costs only the gate time."
    } else {
        Write-Error "git push failed."
    }
    exit 1
}

# --- Which template lines are the description placeholder ------------------------------------------
# #101: the description placeholder(s) are overridable via an optional repo-config function, so a
# consumer with its own PR template text does not need a wrapper. Guard via Get-Command so a
# repo-config.ps1 that does not define it (this repo's own, and every existing consumer) keeps exactly
# today's behavior. Which of the two sources the list came from is kept for the warning further down:
# "your repo-config answered this" and "the built-in list answered this" send the reader to different
# files, and that is the first thing they need in order to repair it.
#
# RESOLVED HERE, ABOVE BOTH PATHS, since issue #865. It used to sit inside the create path, which was
# enough while only that path needed it -- but -RefreshBody now has to know where the placeholder sits
# in order to tell a description heading from a form heading (see below), and a second copy of this
# resolution is how this repo's accumulation bugs start.
$descPlaceholderSource = 'the built-in list'
$descPlaceholders = if (Get-Command -Name Get-PrDescriptionPlaceholder -ErrorAction SilentlyContinue) {
    $descPlaceholderSource = 'Get-PrDescriptionPlaceholder in scripts/repo-config.ps1'
    @(Get-PrDescriptionPlaceholder)
} else {
    # RECOGNISE SIX, WRITE ONE (#538) -- the list itself moved to pr-body-lib.ps1 on August 10, 2026
    # (#573). It was three literals inside this script, which meant nothing outside it could read them:
    # the reference template the plugin now ships could not be held against the list that has to
    # recognise it, and that gap IS the defect #573 reported.
    @(Get-PrDescriptionPlaceholderDefaults)
}

# --- Already open? Then the push was the update, and there is nothing to create -------------------
# Exits 0 on purpose: this is a SUCCESSFUL outcome, and ship-pr.ps1 reads that exit code to decide
# whether to go on to the CI watch and the merge. Returning non-zero here (or letting the duplicate
# `gh pr create` fail) is what made ship-pr unusable on a resumed branch.
#
# Title and label are left untouched -- see the note in .DESCRIPTION. TWO things may still edit the body,
# and both are collected into ONE `gh pr edit` below rather than sent separately, because two calls would
# be two PR updates (and two notifications) for one run:
#
#   1. -RefreshBody, which rewrites the description section from the entry. OPT-IN, because a body may
#      have been edited on github.com and refreshing unasked would overwrite that.
#   2. A -Resolves the existing body does not yet carry. NOT a matter of taste: if this run declares an
#      issue closed and the declaration never reaches the body, GitHub closes nothing at the merge, and
#      ship-pr.ps1's step 6 reads the same body back and confirms the same silence. That is the #341-#343
#      failure arrived at from the other side, so the block is APPENDED rather than skipped.
#      Add-ResolvesBlock is idempotent per issue, so an already-declared number is not duplicated.
#
# THE ORDER IS THE WHOLE POINT, AND IT USED TO BE THE OTHER WAY ROUND (#919, August 26, 2026). These two
# edits are SEQUENTIAL on one variable, not independent: the second consumes the first one's output. With
# the resolves block appended FIRST, the refresh below then replaced it -- because a template carrying no
# headings makes the description the body's LEADING section, whose only boundary is the form's own later
# headings, and a form with none of those means the leading section is the whole body. Measured on PR
# #916: the run printed the lost-section warning, exited 0, and published a body closing nothing. Had it
# merged there, the issue would have stayed open -- the #341-#343 failure reached through the door built
# to prevent it.
#
# REFRESH FIRST, THEN APPEND, and no new knowledge of stops or heading levels is needed for it:
# Add-ResolvesBlock is idempotent per issue, so appending after the rewrite is a no-op where the block
# survived and restores it where it did not. The comment that used to stand here claimed both were
# "computed against the SAME starting body", which is what the code below now actually does per edit --
# each is compared to the body as it went IN, so "nothing to do" still means no API call at all rather
# than a no-op edit.
if ($existingPr) {
    $currentBody = [string]$existingPr.body
    $newBody = $currentBody
    $edits = @()

    if ($RefreshBody) {
        # THE DESCRIPTION IS THE SECTION THE PLACEHOLDER SITS IN, and the template says which that is.
        # A heading ABOVE the placeholder is the description's own -- Update-PrBodySection replaces the
        # content under it. Every heading BELOW the placeholder belongs to the form and is a boundary the
        # description must stop at. Where the placeholder comes before any heading there is no
        # description heading at all: the description is the body's LEADING section, and every heading in
        # the template is a boundary.
        #
        # WHY THE PLACEHOLDER DECIDES IT AND NOT "the first heading" (issue #865). Until August 24, 2026
        # this repo's template opened with an H1 and the two answers agreed, so the first heading was
        # taken as the description's. That H1 went with #865 -- the DEPLOY section it mirrored stopped
        # naming its own answer on August 23 -- and under the new shape "the first heading" is wrong in
        # the one direction that matters: in a template of "<placeholder>" + "## Checklist", it would
        # name the checklist as the description and overwrite it on every refresh. The placeholder's
        # position was always the real rule; it was simply never the one being read.
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
        # The leading section has the mirror-image problem and the same answer: nothing is shallower than
        # no heading either, so -StopAtHeading is its ONLY boundary.
        #
        # Fence-aware, like every other reader of markdown here: a template explaining its own shape can
        # quote a heading inside a fence, and that is a quotation rather than a section.
        $descHeading = ''
        $templateStops = @()
        $templateForHeading = Join-Path $repoRoot ".github\pull_request_template.md"
        $templateFound = Test-Path -LiteralPath $templateForHeading
        if ($templateFound) {
            $tplFence = $false
            $tplSeenPlaceholder = $false
            $tplAbove = @()
            $tplBelow = @()
            foreach ($tplLine in @(Get-Content -LiteralPath $templateForHeading -Encoding UTF8)) {
                if ($tplLine -match '^\s*(```|~~~)') { $tplFence = -not $tplFence; continue }
                if ($tplFence) { continue }
                if ($descPlaceholders -contains $tplLine) { $tplSeenPlaceholder = $true; continue }
                if ($tplLine -match '^#{1,6}\s+\S') {
                    if ($tplSeenPlaceholder) { $tplBelow += $tplLine.TrimEnd() } else { $tplAbove += $tplLine.TrimEnd() }
                }
            }
            # THE LAST heading above the placeholder, not the first: with several, the placeholder sits
            # under the nearest one. The ones before it are the form's too, and they are already
            # protected -- Update-PrBodySection starts at the heading it is given, so nothing above it is
            # touched. A template with no placeholder at all leaves $tplAbove holding every heading, and
            # the last of those is still the closest thing to a description section there is; the create
            # path's warning is what tells the reader the placeholder is missing.
            if ($tplAbove.Count -gt 0) { $descHeading = $tplAbove[$tplAbove.Count - 1] }
            $templateStops = @($tplBelow)
        }
        if (-not $templateFound) {
            # A MISSING template is not the same as a heading-less one, and it keeps today's answer: with
            # no template there is no form, no boundary and no evidence about what the body's shape is
            # meant to be, so nothing is rewritten. The branch is pushed and the PR is open, which is the
            # outcome the caller asked for -- a warning rather than a failure.
            Write-Warning "-RefreshBody: .github/pull_request_template.md was not found - the description was left as it is."
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
            #
            # NOT REACHED WHERE THE TEMPLATE CARRIES NO HEADING, and it does not need to be: the leading
            # section starts at the top of the body, so a legacy heading sitting there is inside what was
            # replaced rather than something to search for. That is why #865 added no string to this list
            # even though it retired one -- the shape it retired is covered by the shape that replaced it.
            if (-not $refreshed -and $descHeading) {
                # Every heading this repo has published a PR under, newest first. The H2 form of the
                # 'bring to main?' wording is on the list because it was live for a single day -- long
                # enough for open PRs to carry it, which is the only thing that decides membership here.
                # ITS H1 FORM JOINED IT ON AUGUST 19, 2026, when the template followed the entry section to
                # 'deploy to main?'. That one was live for thirteen days at the level the template actually
                # carries, so it is the likeliest heading an open PR is sitting under right now.
                foreach ($legacyHeading in @(
                    '# What does the change on this branch bring to main?',
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
                $edits += if ($descHeading) { "the description under '$($descHeading.Trim())'" } else { 'the description (the body leads with it)' }
            } else {
                Write-Host "-RefreshBody: the PR description already matches the entry - nothing sent." -ForegroundColor DarkGray
            }
        }
    }

    # AND THE CLOSING BLOCK GOES ON LAST, AFTER ANY REFRESH (#919) -- see the ordering note above this
    # `if`. Compared against the body as it went INTO this call rather than against $currentBody, which is
    # what the old position could get away with because nothing had touched $newBody yet: from here a
    # refresh may already have changed it, and comparing to the starting body would credit this edit with
    # the refresh's change and announce a closing keyword that was never added.
    if ($resolveIssues.Count -gt 0) {
        $beforeResolves = $newBody
        $newBody = Add-ResolvesBlock -Body $newBody -Issues $resolveIssues
        if ($newBody -ne $beforeResolves) {
            $edits += "closing keyword(s) for $(($resolveIssues | ForEach-Object { "#$_" }) -join ', ')"
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

# $label WAS RESOLVED BY THE LABEL GATE, above the push (inbound #1221) -- it used to be resolved here,
# one line before the create, which is exactly why an unknown label could only be discovered by gh after
# the branch had been pushed. The unknown-prefix warning moved up with it.

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

        # $descPlaceholders / $descPlaceholderSource are resolved once above both paths -- see the block
        # before the "Already open?" branch. #101's approval pattern is still resolved here, because only
        # this path ticks boxes.
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
    if ($create.ExitCode -ne 0) {
        # GH'S OWN MESSAGE IS THE REASON; THE LOGIN HINT IS A SUFFIX (inbound #1077). This line used to
        # be the fixed guess "Creating the PR failed (is gh logged in?)", printed as the loudest thing on
        # screen under gh's actual answer -- and on the run that was measured, gh had just listed PRs,
        # pushed and read the issue list in the same invocation. The one hypothesis offered was the one
        # thing that was demonstrably fine, and it sent the reader to gh auth status, then to their token,
        # then to their network. The hint is kept for the case it is still the best available answer: a gh
        # that printed nothing at all.
        $reason = Get-PrCreateFailureReason -OutputLines $create.Output
        if ($reason) {
            Write-Error "Creating the PR failed: $reason"
        } else {
            Write-Error "Creating the PR failed and gh printed no reason (exit $($create.ExitCode)) -- is gh logged in?"
        }
        exit 1
    }
} finally {
    Remove-Item -Path $bodyFile -Force -ErrorAction SilentlyContinue
}
Write-Host "PR created for '$branch'." -ForegroundColor Green
