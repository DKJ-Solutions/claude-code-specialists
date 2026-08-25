<#
.SYNOPSIS
    Scaffolds the workflow's own root folder -- workflow-davekjohn/ -- in a consuming repo: the folder
    docs, the releases root the audience notes land in, and the branch dossier in its reset state.

.DESCRIPTION
    EVERYTHING PORTABLE ABOUT THE WORKFLOW GATHERS IN ONE FOLDER (Dave, August 14, 2026). A consumer
    used to receive the workflow's belongings scattered through their root -- a branch dossier from the first
    new-branch run, a releases/ tree from the first cut, a CONTRIBUTING.md if they wrote one -- while
    the conventions those files answer to travel with the plugin. This command puts the folder down in
    one move:

        workflow-davekjohn/
          README.md              what this folder is, and where each page's portable half lives
          CLAUDE.md              the working rules a Claude session needs in this folder
          CONTRIBUTING.md        this repo's answers to CONTRIBUTING-portable.md
          releases/README.md     this repo's answers to RELEASES-portable.md (the release LIST is not
                                 here -- it is at the repo root; see the closing advice)
          releases/audience/     where the cut drafts the hand-written note (kept by .gitkeep until then)
          (development-cycle.md is NOT placed -- it lives only while a branch is open)

    AND ONE FILE OUTSIDE IT (inbound #789):

        .github/workflows/branch-entry.yml   the CI gate that holds every PR to carrying a written
                                             entry, by calling the shipped check-branch-entry.ps1

    A PLUGIN INSTALL CANNOT CREATE THIS FOLDER -- an install is a clone into the plugin cache and
    writes nothing into the repo -- so the folder arrives through this command, and
    check-script-contract.ps1 (surfaced by the script-contract session hook) reports at session start
    while it is missing.

    STRICTLY ADDITIVE, NEVER OVERWRITES. Every file that already exists is left exactly as it is,
    whatever it contains -- the same rule specialists-init and adopt-config follow, and what makes a
    re-run find nothing to do. The scaffolded docs carry VUL-IN markers where only this repo can answer.

    NOTHING HERE IS EVER REWRITTEN, INCLUDING THE BRANCH DOCUMENT. Until August 23, 2026 this command also
    placed branch/templates/ and new-branch refreshed those on drift -- the one exception to "additive
    only", because they were generated references rather than anybody's writing. The merged document
    carries its own guidance, so there is no reference beside it to keep current, and the exception is gone
    with the thing it existed for.

    REFUSED IN A REPO THAT PUBLISHES PLUGINS (.claude-plugin/marketplace.json present). The source repo
    of this workflow deliberately keeps its CONTRIBUTING.md and releases/ at its root -- it is the
    product's home, not a consumer -- and only its branch dossier lives in the folder (Dave,
    August 14, 2026). Scaffolding the full folder there would build the layout its owner declined.

.PARAMETER Apply
    Write the files. Without it the command is a DRY RUN that prints exactly what it would create and
    touches nothing -- the same default adopt-config uses, and for the same reason: the first run of a
    command that adds files to your repo should show you the list.

.EXAMPLE
    .\scripts\task\adopt-workflow-folder.ps1
    .\scripts\task\adopt-workflow-folder.ps1 -Apply
#>

[CmdletBinding()]
param(
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Dual-context repo root: a consumer running the plugin mirror gets it from CLAUDE_PROJECT_DIR, the
# workshop root copy falls back to the git root. Same resolution as every other mirrored script.
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# A repo that publishes plugins is a workflow SOURCE, not a consumer, and its docs deliberately live at
# its root -- see the header. This is the same one-file test the source-repo guard uses for the same
# distinction, and it is what keeps this refusal out of every genuine consumer's way.
if (Test-Path -LiteralPath (Join-Path $repoRoot '.claude-plugin\marketplace.json') -PathType Leaf) {
    Write-Host 'REFUSED: this repo publishes plugins, so it is a workflow source rather than a consumer.' -ForegroundColor Red
    Write-Host 'The source keeps its CONTRIBUTING.md and releases/ at the repo root by its own decision'
    Write-Host '(Dave, August 14, 2026) -- only the branch dossier lives in workflow-davekjohn/ there,'
    Write-Host 'and new-branch creates that on its own. Nothing was written.'
    exit 1
}

# The scaffolded branch files come from the same formatters new-branch and the fold call, so this
# command cannot write a shape of its own. repo-config.ps1 first and optional, exactly as new-branch
# loads it: it only supplies wording overrides here, and every string has a built-in default.
$repoConfig = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfig -PathType Leaf) {
    try { . $repoConfig } catch { Write-Warning "scripts/repo-config.ps1 failed to load ($($_.Exception.Message)) -- the built-in wording is used." }
}
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
# Get-SeamValue + the computed defaults (issue #885): this scaffold reads the SAME seam definitions the
# cut, the fold and session-status now read, so the paths this folder's own docs name can never disagree
# with where the workflow actually reads and writes.
. (Join-Path $PSScriptRoot '..\lib\seam-lib.ps1')

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$nl = "`n"

# WHERE THIS REPO KEEPS ITS RELEASE LIST, read rather than assumed. The pages below name that path, and
# naming the default where a repo has repointed the seam would send its reader to a file that is not
# theirs -- the same mistake cut-release's missing-file warning was repaired for (August 4, 2026). Read
# through the shared seam reader, so a repo that defines nothing gets the same computed default the cut
# itself would fall back to -- 'releases/README.md' cannot be assumed here any more (issue #885, group E):
# this script already refused above for a repo that publishes plugins, so every caller reaching this line
# is a consumer, and the computed default for a consumer is now inside this very folder.
#
# history.md, NOT README.md -- 'workflow-davekjohn/releases/README.md' is ALREADY this folder's seam-ANSWERS
# page (the $releasesReadme target below). The list and the answers are two different kinds of document in
# this repo's own root (README.md holds the answers, root releases/README.md holds the list) purely because
# they sit at different directory levels; folded into the SAME directory they need different names, or the
# scaffold below would be asked to write two documents to one path.
$historyRelPath = Get-SeamValue -Name 'Get-ReleaseHistoryPath' -Default (Get-DefaultReleaseHistoryPath -RepoRoot $repoRoot)
Assert-WorkflowIsolatedSeamPath -RepoRoot $repoRoot -RelativePath $historyRelPath -SeamName 'Get-ReleaseHistoryPath'
# WHERE THIS REPO KEEPS ITS CHANGELOG (issue #885, group A). Same reasoning: the scaffold below has to
# name the same path the cut/fold/session-status seam resolves to, not a literal that can drift from it.
$changelogRel = Get-SeamValue -Name 'Get-ChangelogPath' -Default (Get-DefaultChangelogPath -RepoRoot $repoRoot)
Assert-WorkflowIsolatedSeamPath -RepoRoot $repoRoot -RelativePath $changelogRel -SeamName 'Get-ChangelogPath'

# --- What the folder contains ---------------------------------------------------------------------
# One list, each entry a repo-relative path plus the content it gets WHEN ABSENT. The docs name their
# portable halves in code rather than linking them, the same choice DEVELOPMENT-portable.md explains: the
# portable pages live in the plugin install, and a relative link into a plugin cache is a path that is
# wrong on every machine but this one.

$folderReadme = @(
    '# `workflow-davekjohn/` -- the workflow''s own folder in this repo',
    '',
    'Everything portable about the `workflow-davekjohn` workflow gathers here, so the workflow occupies',
    'one folder in this repo''s root instead of scattering through it. The conventions themselves travel',
    'with the plugin as portable pages, readable in your plugin install or in the source repo. Three are',
    'unconditional -- `CONTRIBUTING-portable.md`, `DEVELOPMENT-portable.md` and',
    '`RELEASES-portable.md` -- and each page in this folder is this repo''s own set of answers to one of',
    'them. A fourth, `TICKETWORK-portable.md`, applies only where work arrives from somebody else''s',
    'tracker; skip it if yours does not.',
    '',
    '| here | what it holds |',
    '|---|---|',
    '| [`CLAUDE.md`](CLAUDE.md) | the working rules a Claude session needs in this folder |',
    '| [`CONTRIBUTING.md`](CONTRIBUTING.md) | this repo''s answers to the contribution cycle |',
    '| `development-cycle.md` | the branch''s own document, present only while a branch is open: its plan, and the DEPLOY section that folds into the changelog |',
    '| [`CHANGELOG.md`](CHANGELOG.md) | this folder''s own pending-changes list, isolated from any changelog you already keep at your repo root |',
    '| [`releases/`](releases/) | this repo''s release answers, the release LIST and the published audience notes |',
    '',
    'Scaffolded by the `adopt-workflow-folder` skill; strictly additive, so everything here past the',
    'VUL-IN markers is this repo''s own writing.'
)

$folderClaude = @(
    '# Working in `workflow-davekjohn/`',
    '',
    'This folder belongs to the `workflow-davekjohn` plugin''s way of working, and it is the LAYER ON TOP',
    'of your repo''s own `CLAUDE.md`. That page states what holds in your repo whether or not this plugin',
    'is installed; this one carries the workflow''s own mechanics, and where the two disagree this page',
    'wins -- the same split `CONTRIBUTING.md` below makes over your root one. Keeping the two apart is',
    'what makes an uninstall a folder you remove rather than an operating guide you untangle.',
    '',
    'The rules a session needs in this folder:',
    '',
    '- `development-cycle.md` belongs to the **current branch**, and exists only while one is open.',
    '  `new-branch` creates it, the fold removes it at the merge, so the trunk carries no copy -- if you',
    '  are looking at this folder and the file is not there, that is the trunk in its normal state.',
    '- It has two halves and they are read by different things. **PLAN / CREATE / TEST** carry the steps,',
    '  and they gate the PR and the merge (`- [x]` done, `- [~]` dropped with the reason on the line).',
    '  The fourth phase, **`## `<branch>` DEPLOY`**, IS the changelog entry: it folds **verbatim** into',
    '  `CHANGELOG.md` at the merge, so write its links relative to the repo ROOT rather than to this',
    '  folder. A checkbox inside that section is prose, not a step, and no gate reads it as one.',
    '- The HTML comments in it are the form, not somebody''s notes: they say what a good answer looks',
    '  like, and the fold strips them on the way to `CHANGELOG.md`. Leaving one standing is not a defect.',
    ('- **`CHANGELOG.md` here is this folder''s own** -- isolated from any `CHANGELOG.md` you already keep'),
    '  at your repo root, which this workflow never reads and never writes. A change may end up recorded',
    '  in both, in each one''s own shape; that duplication is accepted rather than resolved, so the',
    '  plugin never has to guess at the shape of a file it does not own.',
    ('- `releases/README.md` here states this repo''s release ANSWERS, and IS the release LIST the cut'),
    ('  inserts its row into (at `' + $historyRelPath + '`) -- a history that stays with the repo that cut'),
    '  it. `releases/audience/` is where the cut drafts the hand-written note; `releases/development/`,',
    '  `releases/github/` and `releases/internal/` hold the generated documents.',
    '',
    '<!-- VUL-IN: rules specific to this repo, if this folder gains any. -->'
)

$folderContributing = @(
    '# Contributing -- the workflow''s layer',
    '',
    'This page sits ON TOP of the repo''s own root `CONTRIBUTING.md`, which describes the standard',
    'workflow that holds before any plugin is consulted. **Where the two disagree, this page wins**:',
    'the root page stays meaningful in a repo without the plugin, and everything the',
    '`workflow-davekjohn` plugin owns is stated here, in the folder that travels with it.',
    '',
    'The contribution cycle itself -- a branch, its development cycle, the PR gates, the significance model --',
    'is the plugin''s `CONTRIBUTING-portable.md`, which travels with `workflow-davekjohn` and is not',
    'restated here. This page holds only what the portable half leaves to each repo.',
    '',
    '## Specific to this repo',
    '',
    '<!-- VUL-IN: this repo''s answers. The seam values in force (branch prefixes, trunk name, audience',
    '     tier, merge method, note root), who approves what, and anything the portable cycle leaves',
    '     open. scripts/repo-config.ps1 is where the machine-read answers live; this page is the prose',
    '     for a person. -->'
)

$releasesReadme = @(
    '# Releases',
    '',
    'The release model -- the tiers, what a release must earn, which documents a cut writes -- is the',
    'plugin''s `RELEASES-portable.md`. This page is this repo''s answers to it.',
    '',
    '<!-- VUL-IN: the seam answers in force here: Get-ReleaseNoteRoot, Get-ReleaseHistoryPath,',
    '     Get-ReleaseAudienceTier, Get-ReleaseConsumerBumps, Get-ReleaseNotesGrouping -- state what this',
    '     repo chose and why, so a reader does not have to open scripts/repo-config.ps1 to learn it. -->',
    '',
    ('**The release LIST is not on THIS page** -- it lives beside it, at `' + $historyRelPath + '`,'),
    'which is where `Get-ReleaseHistoryPath` points. Two different documents even though both are now',
    'inside this folder: this page is your hand-written ANSWERS to the seam (prose, decisions), rewritten',
    'only by you; the list is machine-appended, one row per release, and never touched by hand except to',
    'start it. Kept apart for the same reason `releases/README.md` and this page are apart in the source',
    'repo -- a document somebody edits and a document a script owns should never share a path.',
    '',
    ('That file is **not** scaffolded, deliberately: see the closing advice of `adopt-workflow-folder` for'),
    'what it has to contain before your first cut, and why a half-written one would be worse than none.'
)

# THE ONE FILE THIS COMMAND PLACES OUTSIDE THE FOLDER, and it is deliberate (inbound #789). The branch
# entry is a convention the plugin ships every reader of, while nothing enforced it: open-pr refuses to
# push an unwritten entry and ship-pr refuses to merge on an unresolved step, but both are LOCAL, and a
# branch pushed by hand or a PR opened in the GitHub UI meets neither. Both existing consumers therefore
# wrote a CI gate from scratch, against the same convention, and both had already drifted from it. So the
# gate ships as a script and this places the six lines that call it. Precedent for a plugin placing a
# workflow: adopt-shopify-floor writes .github/workflows/theme-check.yml.
#
# IT TRACKS main RATHER THAN A TAG, which is the one choice here worth arguing. A pinned gate keeps
# enforcing the shape it was pinned at -- and the entry's own path has moved twice already, so a stale pin
# does not fail loudly, it fails the wrong way: refusing branches that do carry an entry at the current
# path. Tracking the tip means the gate follows the convention it enforces. A consumer who needs
# reproducibility over currency pins a tag and accepts owning the bump.
$entryGateWorkflow = @(
    '# Every PR into the trunk carries a WRITTEN changelog entry.',
    '#',
    '# The check itself is not in this file: it is check-branch-entry.ps1, shipped by the',
    '# workflow-davekjohn plugin, which calls the same two functions open-pr calls locally. That is the',
    '# point -- there is one definition of "written" in the system, and this is not a second one. A gate',
    '# hand-written in shell is a second definition, free to drift from the fold that reads the first.',
    '#',
    '# WHY THE HEAD REF IS PASSED EXPLICITLY: a pull_request checkout is a detached merge commit, so',
    '# ''git rev-parse --abbrev-ref HEAD'' answers ''HEAD'' there. The script refuses rather than guessing.',
    '#',
    '# WHY WINDOWS: the shared scripts target Windows PowerShell 5.1, which is what ''shell: powershell'' is.',
    '#',
    '# WHICH BRANCHES OWE NOTHING: answer Get-EntryGateExemptPrefixes in scripts/repo-config.ps1. It',
    '# defaults to ''sync'' -- a mirror branch carries somebody else''s work, so it has nothing to declare.',
    '#',
    '# THE PINNED REF is deliberately a moving branch: a pinned gate enforces the shape it was pinned at,',
    '# and the entry path has moved twice. Pin a tag instead if you would rather own the bump.',
    'name: Branch entry',
    '',
    'permissions:',
    '  contents: read',
    '',
    'on:',
    '  pull_request:',
    '    branches: [main]',
    '',
    'jobs:',
    '  branch-entry:',
    '    runs-on: windows-latest',
    '    steps:',
    '      - uses: actions/checkout@v4',
    '',
    '      - name: Fetch the shared workflow scripts',
    '        uses: actions/checkout@v4',
    '        with:',
    '          repository: DaveKJohn/claude-code-specialists',
    '          ref: main',
    '          path: .workflow-scripts',
    '',
    '      - name: Changelog entry written',
    '        shell: powershell',
    '        env:',
    '          CLAUDE_PROJECT_DIR: ${{ github.workspace }}',
    '        run: |',
    '          powershell -NoProfile -ExecutionPolicy Bypass -File .workflow-scripts/plugins/workflows/workflow-davekjohn/scripts/lint/check-branch-entry.ps1 -Branch "${{ github.head_ref }}"',
    '          exit $LASTEXITCODE'
)

# CHANGELOG.md (issue #885, group A): this folder's own pending-changes list, isolated from any
# CHANGELOG.md the consumer already keeps at their root -- the workflow never reads or writes that one
# again. Deliberately GENERIC prose rather than this repo's own evolved intro (which cites this repo's
# own dates and links): a fresh consumer gets the shape the mechanism actually requires, nothing this
# repo has accumulated. The release-list link is relative to THIS file's own location (inside the
# folder), computed from $historyRelPath rather than assumed, because a repo that repointed the seam
# outside the folder needs '../' where one that left it alone needs none.
$historyRelFromFolder = if ($historyRelPath -like 'workflow-davekjohn/*') {
    $historyRelPath.Substring('workflow-davekjohn/'.Length)
} else {
    "../$historyRelPath"
}
$changelogIntro = @(
    '# Changelog',
    '',
    'Everything merged since the last release, newest first: one `##` per change, and under it the',
    'sections your own `CONTRIBUTING.md` names for your audience tier. The mechanism itself -- the',
    'branch document a change is written in, the fold that moves it here, and what the release cut does',
    'with this list -- is the plugin''s `CONTRIBUTING-portable.md`, which travels with `workflow-davekjohn`',
    'and is not restated here.',
    '',
    ('This file is emptied down to this intro at every release; what was in it moves into that'),
    ('release''s own documents instead. See [`' + $historyRelPath + '`](' + $historyRelFromFolder + ')'),
    'for the list of releases actually cut.'
)

$targets = @(
    @{ Rel = '.github/workflows/branch-entry.yml'; Content = (($entryGateWorkflow -join $nl) + $nl) },
    @{ Rel = 'workflow-davekjohn/README.md';           Content = (($folderReadme -join $nl) + $nl) },
    @{ Rel = 'workflow-davekjohn/CLAUDE.md';           Content = (($folderClaude -join $nl) + $nl) },
    @{ Rel = 'workflow-davekjohn/CONTRIBUTING.md';     Content = (($folderContributing -join $nl) + $nl) },
    @{ Rel = 'workflow-davekjohn/releases/README.md';  Content = (($releasesReadme -join $nl) + $nl) },
    @{ Rel = $changelogRel;                            Content = (($changelogIntro -join $nl) + $nl) },
    # git tracks no empty directory, and the audience root must exist before the first cut writes into
    # it -- the same reason this repo's own releases tree once carried an invisible empty folder.
    @{ Rel = 'workflow-davekjohn/releases/audience/.gitkeep'; Content = '' }
    # NO development-cycle.md, AND THAT IS THE ADOPTION'S HALF OF THE LIFETIME RULE (Dave, August 23, 2026).
    # This placed the document in its reset state so a consumer's first look at the folder was also their
    # reference for what a branch gets. The document is branch-lifetime now -- new-branch creates it, the
    # fold removes it -- so placing one here would put a file on their trunk that their own first fold then
    # deletes, and it would be the only thing in this list that is not permanently theirs. What it used to
    # buy, a reader seeing the whole form at once, is DEVELOPMENT-portable.md's job; that page travels
    # with every plugin update, which a file scaffolded once never does.
)
# NO branch/templates/ ANY MORE. The reference copies of the two branch files were placed here because the
# working files deliberately carried no guidance; the merged document carries its own, so the reference and
# the thing you write in are the same file. A consumer adopting the folder today gets one fewer directory
# and nothing less to read.

# --- Place (or list) ------------------------------------------------------------------------------
Write-Host "== adopt-workflow-folder -- $repoRoot ==" -ForegroundColor Cyan
if (-not $Apply) { Write-Host '  DRY RUN -- nothing is written. Re-run with -Apply to place the files below.' -ForegroundColor Yellow }

$created = 0
$kept = 0
foreach ($t in $targets) {
    $abs = Join-Path $repoRoot ($t.Rel -replace '/', '\')
    if (Test-Path -LiteralPath $abs) {
        $kept++
        Write-Host "  [exists]  $($t.Rel) -- left as it is" -ForegroundColor DarkGray
        continue
    }
    $created++
    if ($Apply) {
        $dir = Split-Path -Parent $abs
        if (-not (Test-Path -LiteralPath $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force }
        [System.IO.File]::WriteAllText($abs, $t.Content, $Utf8NoBom)
        Write-Host "  [created] $($t.Rel)" -ForegroundColor Green
    } else {
        Write-Host "  [create]  $($t.Rel)" -ForegroundColor Green
    }
}

Write-Host ''
if ($Apply) {
    Write-Host "Done: $created file(s) created, $kept left as they were." -ForegroundColor Green
} else {
    Write-Host "Would create $created file(s); $kept already exist. Re-run with -Apply." -ForegroundColor Yellow
}

# --- What only this repo can answer, said out loud rather than left to be discovered ---------------
# One 'decide' seam points the release machinery at the folder; without it the cut keeps writing hand-
# written notes to the shared default at the repo root, which is a working state but not the one this
# folder is for. And one 'copy' seam has a stale copy in every repo that adopted before the folder
# existed.

# RE-ADOPTION MIGRATION NOTE (issue #885): the one transition this run cannot do for you, because it
# is prose in somebody else's file. Same shape as this repo's own releases/README.md migration advice
# ("if it carries a release list from before this split, move that list").
if (Test-Path -LiteralPath (Join-Path $repoRoot 'CHANGELOG.md') -PathType Leaf) {
    Write-Host ''
    Write-Host 'YOUR ROOT CHANGELOG.md EXISTS, so read this before your next merge:' -ForegroundColor Yellow
    Write-Host "  Any entry PENDING there right now (not yet released) will NOT be picked up by the next"
    Write-Host "  fold or cut -- both now read $changelogRel instead. Carry a genuinely pending entry over"
    Write-Host "  by hand, or it ships in neither list."
}

Write-Host ''
Write-Host 'Next, in scripts/repo-config.ps1 (a ''decide'' seam -- see adopt-config):' -ForegroundColor Cyan
Write-Host "  Get-ReleaseNoteRoot     -> 'workflow-davekjohn/releases/audience'"
Write-Host ''
Write-Host 'DELIBERATELY NOT IN THAT LIST: its own contract record explains why the shared DEFAULT stays' -ForegroundColor DarkGray
Write-Host '''releases/notes'' rather than moving with the folder -- a repo that answers nothing must keep' -ForegroundColor DarkGray
Write-Host 'meaning what it meant yesterday, and only the repo can say whether its notes already live' -ForegroundColor DarkGray
Write-Host 'somewhere else. The line above is how THIS run isolates a fresh adoption: written explicitly,' -ForegroundColor DarkGray
Write-Host 'once, rather than by a default that would move under an existing consumer''s feet.' -ForegroundColor DarkGray
Write-Host ''
Write-Host "Get-ReleaseHistoryPath IS ALREADY ISOLATED BY DEFAULT NOW (issue #885): $historyRelPath." -ForegroundColor Cyan
Write-Host 'RE-ADOPTING AN EXISTING CONSUMER, READ THIS: your next cut starts a NEW list here, beside' -ForegroundColor Yellow
Write-Host 'whatever history already sits at your root releases/README.md -- the same duplication-accepted' -ForegroundColor Yellow
Write-Host 'trade the changelog seam makes, deliberately (Dave, August 25, 2026): rather two lists than any' -ForegroundColor Yellow
Write-Host 'chance of writing into a file this workflow does not own. Repoint the seam back to your existing' -ForegroundColor Yellow
Write-Host 'root file instead if you would rather keep one list.' -ForegroundColor Yellow
Write-Host ''
Write-Host "AND THAT FILE IS YOURS TO CREATE, before your first cut: $historyRelPath" -ForegroundColor Cyan
Write-Host '  It needs a section heading naming your first major and a table header under it:'
Write-Host ''
Write-Host '    #### 1.x'
Write-Host ''
Write-Host '    | Version | Date | Type | Title |'
Write-Host '    |---|---|---|---|'
Write-Host ''
Write-Host 'THIS COMMAND DOES NOT SCAFFOLD IT, and that is a decision rather than an omission (inbound'
Write-Host '#786). A file that exists with a table but no <major>.x heading reads as DONE to cut-release:'
Write-Host 'the row lands in it, while the guardrail that refuses to file a v2 row under a 1.x heading is'
Write-Host 'silently off, because that check skips when it finds no section. Same reasoning that keeps'
Write-Host 'adopt-shopify-floor from writing a VUL-IN stub -- a hole with a comment on it is worse than an'
Write-Host 'absent file. And the major in that heading is a version decision this command cannot make for'
Write-Host 'you. Missing altogether, the cut is not silent: it warns'
Write-Host "  ""$historyRelPath is missing -- row not added: <the row>"""
Write-Host 'and cuts the release anyway, so the cost of forgetting is one row you add by hand.'
Write-Host ''
Write-Host 'And if your Get-MojibakePaths copy predates August 14, 2026, re-adopt it: the old copy still'
Write-Host 'names the retired root branch/ location, so the moved files sit outside its coverage.'
