<#
.SYNOPSIS
    Scaffolds the workflow's own root folder -- contributing-davekjohn/ -- in a consuming repo: the folder
    docs, the releases root the audience notes land in, and the branch dossier in its reset state.

.DESCRIPTION
    EVERYTHING PORTABLE ABOUT THE WORKFLOW GATHERS IN ONE FOLDER (Dave, August 14, 2026). A consumer
    used to receive the workflow's belongings scattered through their root -- a branch dossier from the first
    new-branch run, a releases/ tree from the first cut, a CONTRIBUTING.md if they wrote one -- while
    the conventions those files answer to travel with the plugin. This command puts the folder down in
    one move:

        contributing-davekjohn/
          README.md              what this folder is, and where each page's portable half lives
          CONTRIBUTING.md        this repo's answers to CONTRIBUTING-portable.md, plus the session rules for
                                 this folder -- one page since #886, not two
          releases/README.md     this repo's answers to RELEASES-portable.md (the release LIST is a
                                 second file beside it, not this one; see the closing advice)
          (releases/audience/ is NOT placed -- the first cut creates it when it writes the note there)
          (<branch>.md is NOT placed -- one per branch, living only while that branch is open)

    AND IT ANSWERS ONE SEAM, FOR A FRESH ADOPTION ONLY (issue #1150). Get-ReleaseNoteRoot's shared
    fallback is 'releases/notes' at the repo root, and it deliberately does not move -- a repo that
    answers nothing must keep meaning what it meant yesterday. That argument is about a consumer who
    ALREADY has notes on disk, and it does not reach a repo this command scaffolded a minute ago: there
    the scaffolded docs named one destination while the cut wrote to another, so one clean adoption plus
    one clean release left the note outside the folder the adoption had just built. So where -- and ONLY
    where -- this repo defines no answer AND has no note of its own at that fallback, the run writes the
    answer into scripts/repo-config.ps1 rather than printing it as an instruction. Any repo with notes
    already at the fallback keeps them and is told what to do instead; nothing is ever moved.

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
    of this workflow arranges that folder by hand -- it is the product's home, not a consumer -- so
    scaffolding it there would write a layout over one its owner composed deliberately.
    AND ITS ANSWER DIFFERS FROM WHAT THIS COMMAND WRITES, in one way worth knowing before copying it:
    the source has NO root CONTRIBUTING.md, keeping that floor in its CLAUDE.md instead (Dave,
    August 27, 2026), while the page scaffolded below assumes a consumer has one. That is the source's
    own housekeeping rather than the model -- see CONTRIBUTING-portable.md, which recommends the root
    page and says why.

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


# The scaffolded branch files come from the same formatters new-branch and the fold call, so this
# command cannot write a shape of its own. repo-config.ps1 first and optional, exactly as new-branch
# loads it: it only supplies wording overrides here, and every string has a built-in default.
$repoConfig = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfig -PathType Leaf) {
    try { . $repoConfig } catch { Write-Warning "scripts/repo-config.ps1 failed to load ($($_.Exception.Message)) -- the built-in wording is used." }
}
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
# Get-SeamValue + the computed defaults (issue #885): this scaffold reads the SAME seam definitions the
# cut and the fold now read, so the paths this folder's own docs name can never disagree
# with where the workflow actually reads and writes.
. (Join-Path $PSScriptRoot '..\lib\seam-lib.ps1')

# THE SOURCE OF *THIS* WORKFLOW arranges that folder by hand -- see the header -- so this command refuses
# there. It sits below the dot-sources because the test it needs lives in seam-lib, and it still runs
# before anything is written: loading a lib changes nothing on disk.
#
# NARROWED, ISSUE #998 (August 27, 2026). This used to be the bare one-file test -- does this repo have a
# .claude-plugin/marketplace.json -- which answers "does this repo publish plugins", not "is this repo the
# source of this workflow". Under Dave's own one-product-one-repository rule the next product gets its own
# marketplace, so this refusal was on course to turn away a genuine consumer from the one command that
# scaffolds the folder it needs, with a message telling it that it arranges that folder by hand. It does
# not. Test-IsWorkflowSourceRepo reads the manifest now, so only the repo that publishes this workflow is
# refused.
if (Test-IsWorkflowSourceRepo -RepoRoot $repoRoot) {
    Write-Host 'REFUSED: this repo publishes this workflow, so it is its source rather than a consumer.' -ForegroundColor Red
    Write-Host 'The source arranges contributing-davekjohn/ by hand, and its answer differs from what this'
    Write-Host 'command writes: it keeps NO root CONTRIBUTING.md at all (Dave, August 27, 2026), while the'
    Write-Host 'page scaffolded here assumes you have one. Nothing was written.'
    exit 1
}

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
# history.md, NOT README.md -- 'contributing-davekjohn/releases/README.md' is ALREADY this folder's seam-ANSWERS
# page (the $releasesReadme target below). The list and the answers are two different kinds of document in
# this repo's own root (README.md holds the answers, root releases/README.md holds the list) purely because
# they sit at different directory levels; folded into the SAME directory they need different names, or the
# scaffold below would be asked to write two documents to one path.
$historyRelPath = Get-SeamValue -Name 'Get-ReleaseHistoryPath' -Default (Get-DefaultReleaseHistoryPath -RepoRoot $repoRoot)
Assert-WorkflowIsolatedSeamPath -RepoRoot $repoRoot -RelativePath $historyRelPath -SeamName 'Get-ReleaseHistoryPath'
# WHERE THIS REPO KEEPS ITS CHANGELOG (issue #885, group A). Same reasoning: the scaffold below has to
# name the same path the cut/fold seam resolves to, not a literal that can drift from it.
$changelogRel = Get-SeamValue -Name 'Get-ChangelogPath' -Default (Get-DefaultChangelogPath -RepoRoot $repoRoot)
Assert-WorkflowIsolatedSeamPath -RepoRoot $repoRoot -RelativePath $changelogRel -SeamName 'Get-ChangelogPath'

# WHERE THE HAND-WRITTEN RELEASE NOTE WILL LAND (issue #1150), resolved here for the same reason the two
# seams above are: the pages below name this path, and naming a destination the cut does not use sends
# their reader to a directory nothing will ever write. Get-ReleaseNoteRoot was the one root that escaped
# that rule -- the docs asserted 'releases/audience/' flatly while the fallback wrote to the repo root.
#
# THIS IS THE ONE SEAM THIS COMMAND ANSWERS, and the narrowness is the whole safety argument. adopt-config
# never places a 'decide' record, because copying the source's answer would assert something about a repo
# it merely found. That reasoning does not hold here: this run CREATES the folder, so for a repo with no
# answer and no notes it is not describing a tree, it is making one. Three conditions, all required --
# repo-config.ps1 exists to append to, the seam is unanswered, and no note sits at the fallback -- so the
# only repo that gets an answer written is the one that cannot have anything to lose by it.
$noteRootFallback  = 'releases/notes'
$workflowFolder    = Get-WorkflowFolderName -RepoRoot $repoRoot
$noteRootIsolated  = "$workflowFolder/releases/audience"
$noteRootAnswered  = [bool](Get-Command -Name 'Get-ReleaseNoteRoot' -ErrorAction SilentlyContinue)
# A DIRECTORY IS NOT A NOTE, and the difference is measurable rather than pedantic: cut-release created a
# stray releases/notes/<X>.x/ at every cut for a fortnight while writing the note elsewhere (see its own
# comment at the note write). Git tracks no empty directory, so such a tree appears in no commit and would
# read here as "this repo has notes" if existence were the test. Markdown files are the test.
$noteRootHasNotes  = $false
$fallbackAbs = Join-Path $repoRoot ($noteRootFallback -replace '/', '\')
if (Test-Path -LiteralPath $fallbackAbs -PathType Container) {
    # Streamed, not collected: Select-Object -First 1 stops the enumeration, while wrapping the call in
    # @() would walk the whole tree first to answer a question that one file settles.
    $noteRootHasNotes = $null -ne (Get-ChildItem -LiteralPath $fallbackAbs -Filter '*.md' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)
}
$repoConfigExists  = Test-Path -LiteralPath $repoConfig -PathType Leaf
$writeNoteRootSeam = (-not $noteRootAnswered) -and (-not $noteRootHasNotes) -and $repoConfigExists
# COERCED TO A STRING AND FALLBACK-GUARDED. This value comes out of a function in somebody else's file,
# so it can be $null or empty however carefully the contract is worded -- and every use below is a string
# operation that would throw under this script's strict mode rather than report anything useful.
$noteRootRelPath   = if ($noteRootAnswered) { [string](Get-ReleaseNoteRoot) }
                     elseif ($writeNoteRootSeam) { $noteRootIsolated }
                     else { $noteRootFallback }
if ([string]::IsNullOrWhiteSpace($noteRootRelPath)) { $noteRootRelPath = $noteRootFallback }
$noteRootRelPath = ($noteRootRelPath -replace '\\', '/').TrimEnd('/')
# How the folder README names it: folder-relative while it is inside the folder, and repo-root-relative
# with the fact said out loud while it is not -- a reader of that page is standing in the folder.
$noteRootDisplay = if ($noteRootRelPath -eq $workflowFolder -or $noteRootRelPath.StartsWith("$workflowFolder/")) {
    '`' + $noteRootRelPath.Substring([Math]::Min($workflowFolder.Length + 1, $noteRootRelPath.Length)) + '/`'
} else {
    '`' + $noteRootRelPath + '/` at your repo root'
}

# --- What the folder contains ---------------------------------------------------------------------
# One list, each entry a repo-relative path plus the content it gets WHEN ABSENT. The docs name their
# portable halves in code rather than linking them, the same choice DEVELOPMENT-portable.md explains: the
# portable pages live in the plugin install, and a relative link into a plugin cache is a path that is
# wrong on every machine but this one.

$folderReadme = @(
    '# `contributing-davekjohn/` -- the workflow''s own folder in this repo',
    '',
    'Everything portable about the `contributing-davekjohn` workflow gathers here, so the workflow occupies',
    'one folder in this repo''s root instead of scattering through it. The conventions themselves travel',
    'with the plugin as portable pages, readable in your plugin install or in the source repo. There are',
    'three -- `CONTRIBUTING-portable.md`, `DEVELOPMENT-portable.md` and `RELEASES-portable.md` -- and each',
    'page in this folder is this repo''s own set of answers to one of them. Ticket work -- the layer before',
    'a branch, in a repo whose work arrives from somebody else''s tracker -- is step 1 of the first of',
    'those; skip that section if nothing reaches you that way.',
    '',
    '| here | what it holds |',
    '|---|---|',
    '| [`CONTRIBUTING.md`](CONTRIBUTING.md) | this repo''s answers to the contribution cycle |',
    '| `<branch>.md` | the branch''s own document, one per branch and present only while that branch is open: its plan, and the DEPLOY section that folds into the changelog |',
    '| [`CHANGELOG.md`](CHANGELOG.md) | this folder''s own pending-changes list, isolated from any changelog you already keep at your repo root |',
    # The third item is conditional for the same reason the sentence further down is (issue #1150): the
    # hand-written notes are only in this folder where the note-root seam points into it, and claiming
    # them here regardless is how a scaffolded page ends up describing a tree the repo does not have.
    ('| [`releases/`](releases/) | this repo''s release answers, the release LIST' + $(if ($noteRootRelPath.StartsWith("$workflowFolder/")) { ' and the published audience notes' } else { ' (the hand-written notes are at `' + $noteRootRelPath + '/`, outside this folder)' }) + ' |'),
    '',
    'Scaffolded by the `adopt-workflow-folder` skill; strictly additive, so everything here past the',
    'VUL-IN markers is this repo''s own writing.'
)

# ONE PAGE SINCE AUGUST 26, 2026 (#886), WHERE THERE WERE TWO. This array used to have a sibling,
# $folderClaude, scaffolding a CLAUDE.md beside it: one page layered over the consumer's root
# CONTRIBUTING.md and the other over their root CLAUDE.md, and each said so about itself. Dave merged the
# source repo's pair for that reason -- "that should be the center of this folder" -- so the scaffold
# follows, and the session rules that lived in the other page are folded in below.
#
# AN EXISTING ADOPTER KEEPS THEIR CLAUDE.md, and that is not a gap to repair here. This scaffold never
# overwrites, so a consumer who already ran it has both files and this change reaches them not at all --
# the "right owner, wrong reach" shape the technical writer's lens records for PR #734. Removing their
# file is theirs to do; nothing here breaks while they have it.
$folderContributing = @(
    '# Contributing -- the workflow''s layer, and the centre of this folder',
    '',
    'This page sits ON TOP of your repo''s own root `CONTRIBUTING.md` AND its root `CLAUDE.md`. Those two',
    'describe what holds in your repo whether or not this plugin is installed; this one carries the',
    'workflow''s own mechanics, and where they disagree this page wins. Keeping them apart is what makes an',
    'uninstall a folder you remove rather than an operating guide you untangle.',
    '',
    'The contribution cycle itself -- a branch, its development document, the PR gates, the significance model --',
    'is the plugin''s `CONTRIBUTING-portable.md`, which travels with `contributing-davekjohn` and is not',
    'restated here. This page holds only what the portable half leaves to each repo.',
    '',
    '## The rules a session needs in this folder',
    '',
    '- `<branch>.md` belongs to the **branch it is named after**, and exists only while that branch is open. One per branch since #1255 and named after the branch alone since #1335: a shared name collided on every merge, and a conflicting pull request gets no check suite at all.',
    '  `new-branch` creates it, the fold removes it at the merge, so the trunk carries no copy -- if you',
    '  are looking at this folder and the file is not there, that is the trunk in its normal state.',
    '- **Four `##` headings and never a fifth** -- PLAN, CREATE, TEST, DEPLOY are its whole top level, and',
    '  a section needing its own heading goes in as a `###` under whichever of the four owns it. Nothing',
    '  branch-specific belongs above `## PLAN` either: that region is the scaffolder''s generic guidance,',
    '  identical in every branch document. No gate reads a heading, so both are on you.',
    '- **PLAN / CREATE / TEST** carry the steps, and they gate the PR and the merge (`- [x]` done,',
    '  `- [~]` dropped with the reason on the line). The fourth phase, the DEPLOY section, IS the changelog',
    '  entry: it folds **verbatim** into `CHANGELOG.md` at the merge, so write its links relative to the',
    '  repo ROOT rather than to this folder. A checkbox inside that section is prose, not a step, and no',
    '  gate reads it as one.',
    '- The HTML comments in it are the form, not somebody''s notes: they say what a good answer looks',
    '  like, and the fold strips them on the way to `CHANGELOG.md`. Leaving one standing is not a defect.',
    ('- **`CHANGELOG.md` here is this folder''s own** -- isolated from any `CHANGELOG.md` you already keep'),
    '  at your repo root, which this workflow never reads and never writes. A change may end up recorded',
    '  in both, in each one''s own shape; that duplication is accepted rather than resolved, so the',
    '  plugin never has to guess at the shape of a file it does not own.',
    ('- `releases/README.md` here states this repo''s release ANSWERS, and is NOT the release LIST.'),
    ('  That list is the separate `' + $historyRelPath + '`, where the cut inserts one row per release --'),
    '  a history that stays with the repo that cut it, and the one document here that nothing scaffolds:',
    '  see this command''s closing advice for what it has to contain before your first cut. A row added by',
    ('  hand to `releases/README.md` is a row the cut will never see. ' + $noteRootDisplay + ' is where'),
    '  the cut drafts the hand-written note -- it appears at the first cut that writes one, since git',
    '  tracks no empty directory; `releases/changelog/`, `releases/github/` and `releases/internal/`',
    '  hold the generated documents.',
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
    'start it. The source repo carries exactly this pair in exactly this folder since August 27, 2026, when',
    'its own release list moved in beside its answers page -- a document somebody edits and a document a',
    'script owns should never share a path.',
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
    '# contributing-davekjohn plugin, which calls the same two functions open-pr calls locally. That is the',
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
    '      - uses: actions/checkout@v5',
    '',
    '      - name: Fetch the shared workflow scripts',
    '        uses: actions/checkout@v5',
    '        with:',
    '          repository: DKJ-Solutions/claude-code-specialists',
    '          ref: main',
    '          path: .workflow-scripts',
    '',
    '      - name: Changelog entry written',
    '        shell: powershell',
    '        env:',
    '          CLAUDE_PROJECT_DIR: ${{ github.workspace }}',
    '        run: |',
    '          powershell -NoProfile -ExecutionPolicy Bypass -File .workflow-scripts/plugins/workflows/contributing-davekjohn/scripts/lint/check-branch-entry.ps1 -Branch "${{ github.head_ref }}"',
    '          exit $LASTEXITCODE'
)

# CHANGELOG.md (issue #885, group A): this folder's own pending-changes list, isolated from any
# CHANGELOG.md the consumer already keeps at their root -- the workflow never reads or writes that one
# again. Deliberately GENERIC prose rather than this repo's own evolved intro (which cites this repo's
# own dates and links): a fresh consumer gets the shape the mechanism actually requires, nothing this
# repo has accumulated. The release-list link is relative to THIS file's own location (inside the
# folder), computed from $historyRelPath rather than assumed, because a repo that repointed the seam
# outside the folder needs '../' where one that left it alone needs none.
$historyRelFromFolder = if ($historyRelPath -like 'contributing-davekjohn/*') {
    $historyRelPath.Substring('contributing-davekjohn/'.Length)
} else {
    "../$historyRelPath"
}
#
# THE HEADING LEVEL IS COMPOSED, NEVER TYPED (inbound #1098). This sentence said `##` while the fold has
# written `###` ever since the levels shifted, so the one piece of prose a consumer ever reads ABOUT their
# own changelog contradicted the entry three lines below it. Nothing breaks, which is why it survived: no
# gate compares the intro against the constant, and the first person to notice is somebody debugging why
# their hand-written `##` entry did not fold. Reading Get-EntryHeadingLevel (dot-sourced above) is what
# stops the sentence drifting from the constant again -- and it also answers the repo that legitimately
# overrode the level, which a corrected literal would not.
$entryHashes = '#' * (Get-EntryHeadingLevel)
$changelogIntro = @(
    '# Changelog',
    '',
    ('Everything merged since the last release, newest first: one `' + $entryHashes + '` per change, and under it the'),
    'sections your own `CONTRIBUTING.md` names for your audience tier. The mechanism itself -- the',
    'branch document a change is written in, the fold that moves it here, and what the release cut does',
    'with this list -- is the plugin''s `CONTRIBUTING-portable.md`, which travels with `contributing-davekjohn`',
    'and is not restated here.',
    '',
    ('This file is emptied down to this intro at every release; what was in it moves into that'),
    ('release''s own documents instead. See [`' + $historyRelPath + '`](' + $historyRelFromFolder + ')'),
    'for the list of releases actually cut.'
)

$targets = @(
    @{ Rel = '.github/workflows/branch-entry.yml'; Content = (($entryGateWorkflow -join $nl) + $nl) },
    @{ Rel = 'contributing-davekjohn/README.md';           Content = (($folderReadme -join $nl) + $nl) },
    @{ Rel = 'contributing-davekjohn/CONTRIBUTING.md';     Content = (($folderContributing -join $nl) + $nl) },
    @{ Rel = 'contributing-davekjohn/releases/README.md';  Content = (($releasesReadme -join $nl) + $nl) },
    @{ Rel = $changelogRel;                            Content = (($changelogIntro -join $nl) + $nl) }
    # NO releases/audience/.gitkeep ANY MORE (issue #1150). It was placed on the stated ground that "the
    # audience root must exist before the first cut writes into it", and that premise is false: the cut
    # creates the note's own parent directory before writing it (cut-release.ps1, at the note write --
    # added there in August 2026 precisely because Write-Utf8NoBom is a bare WriteAllText and makes no
    # directories). So the file bought nothing the cut needed, and what it did buy was the contradiction
    # this issue reported -- an empty committed directory asserting a destination the unanswered seam did
    # not use. The seam answer above replaces it: the destination is now stated where the cut reads it
    # rather than implied by a placeholder, and the directory appears when there is a note to put in it.
    #
    # NO <branch>.md, AND THAT IS THE ADOPTION'S HALF OF THE LIFETIME RULE (Dave, August 23, 2026).
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

# --- The one seam this run may answer (issue #1150) ------------------------------------------------
# APPENDED, NEVER MERGED, and never over a function that is already there -- the same two rules
# adopt-config places a record under, for the same reason: the file belongs to this repo, and an
# inserter hunting for "the right place" in it would be rewriting somebody else's file on a guess.
#
# EVERY BRANCH BELOW PRINTS, including the ones that write nothing. A run that silently declined to
# answer the seam is indistinguishable from one that never considered it, and the difference is the
# whole subject of this issue -- the reader has to be able to tell "your notes stay where they are"
# from "nobody thought about your notes".
$noteRootSeamAnswer = @(
    '',
    # EVERY CONCATENATED ELEMENT IS PARENTHESISED, and it is load-bearing rather than style: inside an
    # array literal PowerShell binds the comma tighter than the '+', so an unwrapped 'a' + $x + 'b' becomes
    # THREE elements and -join $nl then writes them as three lines. This block generates PowerShell source,
    # so that mistake does not fail here -- it ships a repo-config.ps1 with an unterminated string in it.
    ('# --- Answered by adopt-workflow-folder.ps1 when it scaffolded ' + $workflowFolder + '/ ---'),
    'function Get-ReleaseNoteRoot {',
    '    <#',
    '        Where the hand-written release note is written and read back from.',
    '',
    ('        Written by adopt-workflow-folder.ps1 rather than left to the shared ''' + $noteRootFallback + ''' fallback,'),
    '        because at the moment that folder was scaffolded this repo defined no answer AND had no note',
    '        of its own at that fallback -- so there was nothing here for this answer to move, and leaving',
    '        it unanswered would have put the notes outside the folder the adoption had just built.',
    '',
    '        This is this repo''s file now. Edit it freely; nothing overwrites a function already here.',
    '    #>',
    ('    ''' + $noteRootIsolated + ''''),
    '}'
)

if ($writeNoteRootSeam) {
    if ($Apply) {
        # APPENDED WITH AppendAllText RATHER THAN REWRITTEN, and the difference is not style. Reading the
        # file and writing it back re-encodes it: ReadAllText strips a byte-order mark and a NoBom write
        # does not put it back, so a consumer whose repo-config.ps1 carries one -- which on a .ps1 is the
        # FIX rather than the defect, since Windows PowerShell 5.1 otherwise decodes it as the system ANSI
        # code page -- would have it silently removed by a command that was only meant to add a function.
        # Appending leaves every existing byte exactly where it is.
        $existingConfig = [System.IO.File]::ReadAllText($repoConfig)
        $appendix = (($noteRootSeamAnswer -join $nl) + $nl)
        if ($existingConfig.Length -gt 0 -and -not $existingConfig.EndsWith("`n")) { $appendix = $nl + $appendix }
        [System.IO.File]::AppendAllText($repoConfig, $appendix, $Utf8NoBom)
        Write-Host "  [answered] Get-ReleaseNoteRoot -> '$noteRootIsolated' in scripts/repo-config.ps1" -ForegroundColor Green
    } else {
        Write-Host "  [answer]   Get-ReleaseNoteRoot -> '$noteRootIsolated' in scripts/repo-config.ps1" -ForegroundColor Green
    }
} elseif ($noteRootAnswered) {
    Write-Host "  [seam]     Get-ReleaseNoteRoot is already answered here ('$noteRootRelPath') -- left as it is" -ForegroundColor DarkGray
} elseif ($noteRootHasNotes) {
    Write-Host "  [seam]     Get-ReleaseNoteRoot left UNANSWERED -- you already have notes at $noteRootFallback/" -ForegroundColor Yellow
} else {
    Write-Host '  [seam]     Get-ReleaseNoteRoot left unanswered -- this repo has no scripts/repo-config.ps1' -ForegroundColor Yellow
}

Write-Host ''
if ($Apply) {
    Write-Host "Done: $created file(s) created, $kept left as they were." -ForegroundColor Green
} else {
    Write-Host "Would create $created file(s); $kept already exist. Re-run with -Apply." -ForegroundColor Yellow
}

# --- What only this repo can answer, said out loud rather than left to be discovered ---------------
# One 'decide' seam points the release machinery at the folder. Since issue #1150 this run ANSWERS it
# where it safely can -- see the seam block above for the three conditions -- so what is printed below
# is a report of what happened to it rather than an instruction in every case. Where it was left
# unanswered the cut keeps writing hand-written notes to the shared default at the repo root, which is a
# working state but not the one this folder is for.

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
if ($writeNoteRootSeam) {
    $verb = if ($Apply) { 'is now' } else { 'will be' }
    Write-Host "Get-ReleaseNoteRoot $verb answered here: $noteRootIsolated." -ForegroundColor Cyan
    Write-Host 'WRITTEN RATHER THAN PRINTED AS AN INSTRUCTION (issue #1150), and only because this repo had' -ForegroundColor DarkGray
    Write-Host 'no answer and no note at the shared fallback. Its contract record explains why the shared' -ForegroundColor DarkGray
    Write-Host 'DEFAULT still stays ''releases/notes'' -- a repo that answers nothing must keep meaning what it' -ForegroundColor DarkGray
    Write-Host 'meant yesterday -- and that argument is about a repo with notes already on disk, which this' -ForegroundColor DarkGray
    Write-Host 'one is not. Repoint it if you would rather keep your notes somewhere else; nothing here is' -ForegroundColor DarkGray
    Write-Host 'rewritten by a later run.' -ForegroundColor DarkGray
} elseif ($noteRootAnswered) {
    Write-Host "Get-ReleaseNoteRoot was already answered here ($noteRootRelPath) and was left alone." -ForegroundColor Cyan
    Write-Host 'Your answer always wins over this command''s, exactly as adopt-config never overwrites one.' -ForegroundColor DarkGray
} else {
    Write-Host "Get-ReleaseNoteRoot is UNANSWERED, so your cut writes hand-written notes to $noteRootFallback/" -ForegroundColor Yellow
    Write-Host 'at your repo root -- outside the folder this command just scaffolded. That is a working state,' -ForegroundColor Yellow
    Write-Host 'not the one this folder is for. To move it, in scripts/repo-config.ps1:' -ForegroundColor Yellow
    Write-Host "  Get-ReleaseNoteRoot     -> '$noteRootIsolated'"
    if ($noteRootHasNotes) {
        Write-Host ''
        Write-Host "  AND MOVE THE NOTES YOU ALREADY HAVE. This run refused to answer the seam for you because" -ForegroundColor Yellow
        Write-Host "  $noteRootFallback/ holds at least one note: repointing the seam without moving them makes the" -ForegroundColor Yellow
        Write-Host "  cut report 'no release note was found', which reads as a repo that has never cut one."
    }
}
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

# THE TWO GENERATED NOTE ROOTS #914 MOVED, WHICH HAD NO WARNING AT ALL (issue #955, August 27, 2026).
# Both sibling seams above got an explicit re-adoption note when #885 isolated them; #914 did the same
# thing to these two on August 26 and nothing followed it, so a consumer's next cut would start two
# fresh trees inside the folder beside the history already sitting at their root -- no error, no
# warning, nowhere in the adoption or the cut.
#
# WHAT IT COST, MEASURED RATHER THAN IMAGINED. djcylow-react had run every adoption skill on every
# bump and still carried 39 files under releases/development/ and 2 under releases/github/ at its repo
# root. They found it themselves and repaired it with git mv (their PR #158), and their own
# repo-config.ps1 now records that nothing in the plugin migrated the files and nothing warned that it
# had to. That note is this block: the next consumer should not have to write it a second time.
#
# GET-RELEASEINTERNALNOTESROOT IS DELIBERATELY NOT HERE. For a consumer it has resolved inside the
# folder since #885 -- it never had a root answer to split away from, so there is nothing to warn
# about. Two roots, not three, and the issue's own third seam name is the retired alias of the first.
#
# RESOLVED BUT NOT ASSERTED, on purpose. The cut already runs Assert-WorkflowIsolatedSeamPath over both
# of these; adding a second refusal here would turn an informational adoption run into one that can
# exit 1 on a seam the reader has not been told about yet, which is the opposite of what this block is.
$changelogNotesRel = Get-SeamValue -Name 'Get-ReleaseChangelogNotesRoot', 'Get-ReleaseDevelopmentNotesRoot' `
    -Default (Get-DefaultReleaseChangelogNotesRoot -RepoRoot $repoRoot)
$githubNotesRel = Get-SeamValue -Name 'Get-ReleaseGithubNotesRoot' `
    -Default (Get-DefaultReleaseGithubNotesRoot -RepoRoot $repoRoot)

Write-Host ''
Write-Host 'THE TWO GENERATED NOTE ROOTS ARE ALSO ISOLATED BY DEFAULT NOW (issue #914):' -ForegroundColor Cyan
Write-Host "  Get-ReleaseChangelogNotesRoot -> $changelogNotesRel"
Write-Host "  Get-ReleaseGithubNotesRoot    -> $githubNotesRel"

# The pre-isolation answers, asked of the same lookup the cut's own tolerance uses rather than listed
# again here -- so a name added there is warned about here without this block learning it separately.
$strandedNoteRoots = @()
foreach ($seamName in @('Get-ReleaseChangelogNotesRoot', 'Get-ReleaseGithubNotesRoot')) {
    foreach ($legacyRel in @(Get-PreIsolationSeamPath -SeamName $seamName)) {
        $legacyAbs = Join-Path $repoRoot ($legacyRel -replace '/', '\')
        if (Test-Path -LiteralPath $legacyAbs -PathType Container) {
            $count = @(Get-ChildItem -LiteralPath $legacyAbs -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue).Count
            $strandedNoteRoots += [pscustomobject]@{ Seam = $seamName; Rel = $legacyRel; Count = $count }
        }
    }
}

if ($strandedNoteRoots.Count) {
    Write-Host ''
    Write-Host 'RE-ADOPTING AN EXISTING CONSUMER, READ THIS: a generated-notes tree is still sitting at' -ForegroundColor Yellow
    Write-Host 'your repo root, where these two seams pointed before #914 isolated them:' -ForegroundColor Yellow
    foreach ($s in $strandedNoteRoots) {
        Write-Host ("  $($s.Rel)/  -- $($s.Count) .md file(s), read by $($s.Seam) until 4.20.0") -ForegroundColor Yellow
    }
    Write-Host 'Your next cut writes into the isolated paths named above instead, and leaves that tree' -ForegroundColor Yellow
    Write-Host 'behind silently -- two brand-new, empty-looking trees beside your real history. Nothing' -ForegroundColor Yellow
    Write-Host 'in the plugin moves the files for you. Two honest answers: git mv the tree onto the' -ForegroundColor Yellow
    Write-Host 'isolated path so the computed default is right again, or define the seam in' -ForegroundColor Yellow
    Write-Host 'scripts/repo-config.ps1 to keep pointing at your root tree. The cut accepts that root' -ForegroundColor Yellow
    Write-Host 'answer for these two seams specifically (issue #956), so repointing is not a fight with' -ForegroundColor Yellow
    Write-Host 'the isolation guard.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'And if your Get-MojibakePaths copy predates August 14, 2026, re-adopt it: the old copy still'
Write-Host 'names the retired root branch/ location, so the moved files sit outside its coverage.'
