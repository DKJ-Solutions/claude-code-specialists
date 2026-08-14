<#
.SYNOPSIS
    Scaffolds the workflow's own root folder -- workflow-davekjohn/ -- in a consuming repo: the folder
    docs, the releases root the audience notes land in, and the branch dossier in its reset state.

.DESCRIPTION
    EVERYTHING PORTABLE ABOUT THE WORKFLOW GATHERS IN ONE FOLDER (Dave, August 14, 2026). A consumer
    used to receive the workflow's belongings scattered through their root -- branch/ from the first
    new-branch run, a releases/ tree from the first cut, a CONTRIBUTING.md if they wrote one -- while
    the conventions those files answer to travel with the plugin. This command puts the folder down in
    one move:

        workflow-davekjohn/
          README.md              what this folder is, and where each page's portable half lives
          CLAUDE.md              the working rules a Claude session needs in this folder
          CONTRIBUTING.md        this repo's answers to CONTRIBUTING-portable.md
          releases/README.md     this repo's answers to RELEASES-portable.md + the release history table
          releases/audience/     where the cut drafts the hand-written note (kept by .gitkeep until then)
          branch/                the two branch files in their reset state, plus the generated templates

    A PLUGIN INSTALL CANNOT CREATE THIS FOLDER -- an install is a clone into the plugin cache and
    writes nothing into the repo -- so the folder arrives through this command, and
    check-script-contract.ps1 (surfaced by the script-contract session hook) reports at session start
    while it is missing.

    STRICTLY ADDITIVE, NEVER OVERWRITES. Every file that already exists is left exactly as it is,
    whatever it contains -- the same rule specialists-init and adopt-config follow, and what makes a
    re-run find nothing to do. The scaffolded docs carry VUL-IN markers where only this repo can
    answer; the branch templates are created here when absent and kept current by new-branch's own
    refresh-on-drift, which remains the one writer that may overwrite them.

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

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$nl = "`n"

# --- What the folder contains ---------------------------------------------------------------------
# One list, each entry a repo-relative path plus the content it gets WHEN ABSENT. The docs name their
# portable halves in code rather than linking them, the same choice BRANCH-portable.md explains: the
# portable pages live in the plugin install, and a relative link into a plugin cache is a path that is
# wrong on every machine but this one.

$folderReadme = @(
    '# `workflow-davekjohn/` -- the workflow''s own folder in this repo',
    '',
    'Everything portable about the `workflow-davekjohn` workflow gathers here, so the workflow occupies',
    'one folder in this repo''s root instead of scattering through it. The conventions themselves travel',
    'with the plugin as four portable pages -- `CONTRIBUTING-portable.md`, `BRANCH-portable.md`,',
    '`RELEASES-portable.md` and `TICKETWORK-portable.md`, readable in your plugin install or in the',
    'source repo -- and each page in this folder is this repo''s own set of answers to them.',
    '',
    '| here | what it holds |',
    '|---|---|',
    '| [`CLAUDE.md`](CLAUDE.md) | the working rules a Claude session needs in this folder |',
    '| [`CONTRIBUTING.md`](CONTRIBUTING.md) | this repo''s answers to the contribution cycle |',
    '| [`branch/`](branch/) | the branch dossier: the entry, the step list, the generated templates |',
    '| [`releases/`](releases/) | the release history and the published audience notes |',
    '',
    'Scaffolded by the `adopt-workflow-folder` skill; strictly additive, so everything here past the',
    'VUL-IN markers is this repo''s own writing.'
)

$folderClaude = @(
    '# Working in `workflow-davekjohn/`',
    '',
    'This folder belongs to the `workflow-davekjohn` plugin''s way of working. The rules a session needs:',
    '',
    '- The two files in `branch/` belong to the **current branch**. On the trunk they sit in their reset',
    '  state -- never write there until a branch exists (`new-branch` creates one and fills them).',
    '- `branch/branch-changelog.md` folds **verbatim** into `CHANGELOG.md` at the merge; its step list',
    '  companion gates the PR and the merge (`- [x]` done, `- [~]` dropped with the reason on the line).',
    '- `releases/README.md` lists this repo''s releases; the cut inserts its own row. `releases/audience/`',
    '  is where the cut drafts the hand-written note -- generated development notes live elsewhere.',
    '- The generated files in `branch/templates/` are references, not documents to edit: new-branch',
    '  rewrites one that has drifted.',
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
    'The contribution cycle itself -- a branch, its two files, the PR gates, the significance model --',
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
    'plugin''s `RELEASES-portable.md`. This page is this repo''s answers to it, plus the release history',
    'the cut writes its rows into.',
    '',
    '<!-- VUL-IN: the seam answers in force here: Get-ReleaseNoteRoot, Get-ReleaseHistoryPath,',
    '     Get-ReleaseAudienceTier, Get-ReleaseConsumerBumps, Get-ReleaseNotesGrouping -- state what this',
    '     repo chose and why, so a reader does not have to open scripts/repo-config.ps1 to learn it. -->',
    '',
    '## Release history',
    '',
    '<!-- VUL-IN: the cut inserts a row after the FIRST table header below. A new major opens its own',
    '     heading + table above this one, by hand -- that is a deliberate milestone moment. -->',
    '',
    '| Version | Date | Type | Title |',
    '|---|---|---|---|'
)

$branchPaths = Get-BranchFilePaths
$targets = @(
    @{ Rel = 'workflow-davekjohn/README.md';           Content = (($folderReadme -join $nl) + $nl) },
    @{ Rel = 'workflow-davekjohn/CLAUDE.md';           Content = (($folderClaude -join $nl) + $nl) },
    @{ Rel = 'workflow-davekjohn/CONTRIBUTING.md';     Content = (($folderContributing -join $nl) + $nl) },
    @{ Rel = 'workflow-davekjohn/releases/README.md';  Content = (($releasesReadme -join $nl) + $nl) },
    # git tracks no empty directory, and the audience root must exist before the first cut writes into
    # it -- the same reason this repo's own releases tree once carried an invisible empty folder.
    @{ Rel = 'workflow-davekjohn/releases/audience/.gitkeep'; Content = '' },
    @{ Rel = $branchPaths.Changelog; Content = (((Format-BranchChangelogReset) -join $nl) + $nl) },
    @{ Rel = $branchPaths.Progress;  Content = (((Format-BranchProgressReset) -join $nl) + $nl) }
)
foreach ($tpl in (Get-BranchTemplates)) {
    $targets += @{ Rel = $tpl.Path; Content = $tpl.Content }
}

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
# Two 'decide' seams point the release machinery at the folder; without them the cut keeps writing to
# the shared defaults at the repo root, which is a working state but not the one this folder is for.
# And one 'copy' seam has a stale copy in every repo that adopted before the folder existed.
Write-Host ''
Write-Host 'Next, in scripts/repo-config.ps1 (both are ''decide'' seams -- see adopt-config):' -ForegroundColor Cyan
Write-Host "  Get-ReleaseNoteRoot     -> 'workflow-davekjohn/releases/audience'"
Write-Host "  Get-ReleaseHistoryPath  -> 'workflow-davekjohn/releases/README.md'"
Write-Host 'And if your Get-MojibakePaths copy predates August 14, 2026, re-adopt it: the old copy still'
Write-Host 'names the retired root branch/ location, so the moved files sit outside its coverage.'
