<#
.SYNOPSIS
    Cuts a repo-wide release directly on main: bumps all plugin versions in lockstep,
    generates release notes in releases/development/, puts a reference in CHANGELOG.md under
    ## Releases, updates the overview table in releases/README.md, commits that on main, and sets +
    pushes the git tag vX.Y.Z.

.DESCRIPTION
    A release here is a *recorded moment*: all plugins get the same version number
    (lockstep, repo-wide) and the state is tagged as vX.Y.Z. This script itself publishes nothing
    to GitHub Releases -- only a git tag, release notes in releases/, and a reference in
    CHANGELOG.md. For a Minor/Major bump, publishing a GitHub Release is a manual follow-up step
    the release manager takes afterward, per the cut-release skill's closing checklist; a Patch
    bump skips that step entirely (tag only).

    A release deliberately does NOT run via a branch + PR. Like the fold commit, the release
    commit is an allowed direct-on-main action (the second exception to "everything via branch +
    PR" -- see the safety rules). The script therefore runs on main itself and is started ONLY at
    Dave's explicit request.

    Steps (all on main):
    SHARED, WITH THE REPO'S OWN ANSWERS IN THE SEAM (issue #417). This script is mirrored into the
    plugin, so a consumer runs it rather than forking it. Everything that legitimately differs per
    repo is read from the OPTIONAL functions in scripts/repo-config.ps1, and every fallback is what
    this script did before it was shared: Get-ReservedRootMd (which root docs are permanent),
    Get-ReleaseNotesGrouping (notes per major or per minor), Get-ReleaseLiveMarker (the "currently
    live" suffix, none here), Get-ReleasePluginTier (whether steps 3b/3c and the lockstep bump run at
    all), Get-ReleaseCategoryTitles (the category labels) and -- since phase 2 -- the three highlights
    knobs (Get-ReleaseHighlightsBumps, Get-ReleaseHighlightsStakeholderTypes,
    Get-ReleaseHighlightsWording), which are all empty in this repo: its release audience is
    developers, so it generates no stakeholder document. See step 3d.

    Steps (all on main):
      1. Guardrails: clean main, no unfolded entry files in the root, lint gate green.
      2. Determines the current version -- the lockstep value from every
         <plugin>/.claude-plugin/plugin.json where this repo publishes plugins, otherwise the newest
         vX.Y.Z tag -- then the new version (-Version or -Bump) and the bump type.
      3. Generates releases/development/<X>.x/<X.Y.Z>.md from the ## Pull Requests entries
         (grouped by branch type), adds a row to releases/README.md, puts a reference in
         CHANGELOG.md under ## Releases and empties the Pull-Requests section, and bumps all
         plugin.json's.
      3b. Writes, per plugin, the entries with a matching 'Plugins:' line (derived by the fold
          from the PR files) into <plugin>/CHANGELOG.md -- the consumer-facing history that
          travels along with the plugin cache. Root-relative links are rewritten to absolute
          GitHub URLs in the process.
      3c. Writes/overwrites, for EVERY plugin (not just the touched ones -- the version bumps
          lockstep), <plugin>/RELEASE.md: a short card naming the release it describes, with or
          without its own entries this time, plus links to the full notes and its own CHANGELOG.md.
          Model A (plugin-carried), deliberately without a session-start hook. The card states what
          it describes rather than where the reader is -- it is written at cut time and cannot know
          which commit a consumer will install from (inbound #384).
      3d. Writes, for a bump type the seam names in Get-ReleaseHighlightsBumps, a second
          stakeholder-facing rendering of the same release: releases/highlights/<dir>/<X.Y.Z>.md plus
          a print-ready .html of it. Written for NON-DEVELOPERS, so the categories the seam does not
          call stakeholder-facing land under an explicit "remove before publishing" marker the
          release manager cuts by hand. Skipped entirely in this repo (empty seam = tier off).
      4. Commits that directly to main (release: vX.Y.Z) and sets an annotated tag vX.Y.Z.
      5. Pushes main + the tag (unless -NoPush).

.PARAMETER Version
    Explicit new version X.Y.Z (e.g. "1.1.0"). Use this OR -Bump.

.PARAMETER Bump
    Bump the current version automatically: major | minor | patch. Use this OR -Version.

.PARAMETER Title
    Short description of the release as a whole (1 sentence, optional) -- goes into the notes +
    the table row.

.PARAMETER SummaryFile
    Path to a markdown file whose content is placed in the release notes between the -Title line and
    the generated per-PR entries, followed by a horizontal rule.

    FOR A MILESTONE RELEASE, where the point is the arc across many releases rather than the diff since
    the last one. -Title is one sentence and the entries are per-PR, so neither can carry "here is what
    changed between 2.2.0 and 2.16.0" -- and hand-editing a generated file afterwards is not a
    repeatable release, which is the whole reason this script exists.

    The file may live outside the repo (a scratch path is fine, and is the expected case): its canonical
    home becomes the generated notes file itself, so keeping a second copy under releases/ purely to
    feed this parameter would duplicate content for no gain. A missing or empty file is a hard stop --
    an empty one would otherwise produce an ordinary release while the operator believes they cut a
    milestone.

.PARAMETER NoPush
    Everything locally (commit + tag) but do not push main/tag -- for inspection beforehand.

.PARAMETER SkipLint
    Deliberately skip the lint gate (escape valve).

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Version 1.0.0 -Title "First official release"

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Bump minor -NoPush

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Bump major -Title "A new milestone" -SummaryFile ..\summary.md -NoPush
    # Milestone release: the authored summary opens the notes, the pending entries follow it.
#>
[CmdletBinding()]
param(
    [string]$Version,
    [ValidateSet('major', 'minor', 'patch')][string]$Bump,
    [string]$Title = '',
    [string]$SummaryFile = '',
    [switch]$NoPush,
    [switch]$SkipLint
)
$ErrorActionPreference = 'Stop'

# Repo root -- dual context, the same contract every shared script here follows (#81): if a consumer
# runs the plugin mirror, CLAUDE_PROJECT_DIR supplies its repo root; in the workshop root (or outside
# a session) it falls back to the git root. This is what lets the root copy and the mirror stay
# byte-identical, which the shared-scripts drift lint enforces.
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }
Set-Location $repoRoot

# Pre-flight, before the dot-sources below turn a missing file into a raw path-not-found (#86, the
# same guard open-pr.ps1 carries). Both files are REPO-OWNED and live in the consumer's root.
$needed = @('scripts\repo-config.ps1', 'scripts\lib\branch-info.ps1')
$absent = @($needed | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_)) })
if ($absent.Count -gt 0) {
    Write-Error ("cut-release cannot run -- missing repo-owned configuration in the repo root ($repoRoot):`n  " + ($absent -join "`n  ") + "`n`nCreate them (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward.")
    exit 1
}

# $repoRoot, not $PSScriptRoot: from the plugin mirror $PSScriptRoot points into the plugin cache,
# while repo-config and branch-info always live in the consumer's repo root. branch-info is dot-sourced
# HERE rather than left to release-lib, because release-lib travels into the mirror and its sibling
# branch-info does not -- Get-ReleaseCategories probes for Get-BranchTypes and finds what we load here.
. (Join-Path $repoRoot 'scripts\lib\branch-info.ps1')
. (Join-Path $repoRoot 'scripts\repo-config.ps1')

# Plugin-owned libraries, from $PSScriptRoot: these travel WITH this script, so the sibling is the
# right one in both locations.
. (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')
# Shared native-capture helper (#114): the #107 EAP=Continue -> capture -> $LASTEXITCODE dance for
# the git mutations in the final block lives here in one tested place.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# --- The repo's own answers, read once (#417) -----------------------------------------------------
# Every one of these is OPTIONAL in the script contract, and every fallback is what this script did
# before it was shared -- so a consumer that defines none of them gets the unchanged behaviour.
function Get-SeamValue {
    <# Calls an optional repo-config function, or returns $Default when the repo does not define it. #>
    param([Parameter(Mandatory)][string]$Name, $Default)
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return (& $Name) }
    return $Default
}

$notesGrouping = Get-SeamValue -Name 'Get-ReleaseNotesGrouping' -Default 'major'
$liveMarker    = Get-SeamValue -Name 'Get-ReleaseLiveMarker'    -Default ''
# The computed fallback is a fact, not a guess: no marketplace manifest means there are no plugins to
# version or card. Stated in repo-config here anyway, because in this repo the answer is load-bearing.
$pluginTier    = Get-SeamValue -Name 'Get-ReleasePluginTier' `
    -Default (Test-Path -LiteralPath (Join-Path $repoRoot '.claude-plugin\marketplace.json'))

# The highlights tier (#417 phase 2). All three default to empty, which is the tier switched OFF --
# what this script did for its whole life as a workshop-only file, so nothing changes here.
$highlightsBumps = @(Get-SeamValue -Name 'Get-ReleaseHighlightsBumps' -Default @())
$highlightsTypes = @(Get-SeamValue -Name 'Get-ReleaseHighlightsStakeholderTypes' -Default @())
# Merged over release-lib's English defaults rather than replacing them, so a consumer that renames
# one string does not have to restate the other two (same pattern as Get-ReleaseCategoryTitles).
$highlightsWording = @{
    DevBlockComment = 'Remove this block before sharing the highlights with non-developers.'
    DevBlockHeading = 'For developers only -- remove before publishing'
    HtmlLang        = 'en'
}
$wordingOverride = Get-SeamValue -Name 'Get-ReleaseHighlightsWording' -Default @{}
if ($wordingOverride) { foreach ($k in $wordingOverride.Keys) { $highlightsWording[$k] = $wordingOverride[$k] } }

# BOM-less UTF8 -- the rest of the repo has no BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

# Permanent root .md files that are NOT branch changelog entries. The stray-entry guardrail below
# treats every other root *.md as an unfolded entry (deliberately catch-all, so an entry with an
# unknown branch prefix is never missed) -- so any permanent root doc added over time must be listed,
# or a release would falsely refuse to cut.
#
# THE LIST MOVED TO THE SEAM IN #417 and no longer lives here. It had gone stale three times, each
# time blocking a release over a document nobody had failed to fold (#165, then QUICKSTART.md +
# UNINSTALL.md in #405, then ADOPTION.md in #408) -- and once this script is shared, which root docs
# a repo has is by definition not something the script can know. The fallback below is the workshop's
# own list, so a consumer that defines nothing still gets the behaviour this script always had.
$reservedRootMd = @(Get-SeamValue -Name 'Get-ReservedRootMd' -Default @(
    'CHANGELOG.md', 'CLAUDE.md', 'README.md', 'LICENSE.md', 'CONTRIBUTING.md', 'SECURITY.md',
    'QUICKSTART.md', 'ADOPTION.md', 'UNINSTALL.md'))

$script:marketplaceJsonText = $null
function Get-MarketplaceJsonText {
    # THE one read of marketplace.json, shared by the two things derived from it: which plugins exist,
    # and what the marketplace is called. Cached rather than re-read per caller -- two reads of one
    # file during a release that also WRITES files is exactly how the two answers start disagreeing,
    # and a function whose comment promises a single read has to deliver one.
    if ($null -eq $script:marketplaceJsonText) {
        $marketplacePath = Join-Path $repoRoot '.claude-plugin\marketplace.json'
        if (-not (Test-Path -LiteralPath $marketplacePath)) {
            Write-Error ".claude-plugin/marketplace.json is missing."; exit 1
        }
        $script:marketplaceJsonText = (Get-Content -Path $marketplacePath -Raw -Encoding UTF8)
    }
    return $script:marketplaceJsonText
}

function Get-PluginManifests {
    # The marketplace definition is the source of truth about what a plugin is: the manifests are
    # derived from plugins[].source (incl. containment check) by Get-PluginManifestPaths in
    # release-lib.ps1 -- pure there and thus tested. Here only the IO: reading + existence check.
    $paths = @(Get-PluginManifestPaths -RepoRoot $repoRoot `
        -MarketplaceJson (Get-MarketplaceJsonText))
    foreach ($manifest in $paths) {
        if (-not (Test-Path -LiteralPath $manifest)) {
            $pluginName = Split-Path (Split-Path (Split-Path $manifest -Parent) -Parent) -Leaf
            Write-Error "Plugin '$pluginName' is listed in marketplace.json but is missing its manifest ($manifest)."; exit 1
        }
    }
    $paths
}

# --- Guardrails: on main, clean, no unfolded entries ---------------------------------------
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne 'main') { Write-Error "A release is cut directly on main; you are on '$branch'."; exit 1 }
if ((git status --porcelain)) { Write-Error "Working tree not clean -- commit/stash first."; exit 1 }

$strayEntries = Get-ChildItem -Path $repoRoot -Filter '*.md' -File |
    Where-Object { $reservedRootMd -notcontains $_.Name } |
    Select-Object -ExpandProperty Name
if ($strayEntries.Count -gt 0) {
    Write-Error "There are still unfolded changelog entry files in the root: $($strayEntries -join ', '). Fold them first (fold-changelog-entry.ps1)."
    exit 1
}

# --- Determine version + bump type ------------------------------------------------------------
# WHERE THE CURRENT VERSION COMES FROM depends on the plugin tier, and the two sources are not
# interchangeable (#417). With plugins, the manifests ARE the record and Get-LockstepVersion also
# proves they agree -- a disagreement is a defect this must not paper over. Without them there is no
# manifest to read, so the newest reachable tag is the record, which is what a repo with no plugins
# has always used. Deliberately not "tag if the manifests are missing": in this repo a manifest that
# vanished would then silently downgrade to a tag read, and the lockstep check would go with it.
$manifests = @()
$marketplaceName = ''
if ($pluginTier) {
    $manifests = @(Get-PluginManifests)
    if ($manifests.Count -eq 0) { Write-Error "No plugin manifests found."; exit 1 }
    # Read once, outside the per-plugin loop that consumes it: the name is a property of the marketplace,
    # not of the plugin, so re-deriving it per plugin would invite four answers to a one-answer question.
    $marketplaceName = Get-MarketplaceName -MarketplaceJson (Get-MarketplaceJsonText)
    $manifestContents = @{}
    foreach ($m in $manifests) { $manifestContents[$m] = (Get-Content -Path $m -Raw -Encoding UTF8) }
    $current = Get-LockstepVersion -ManifestContents $manifestContents
} else {
    $latestTag = @(git tag --list 'v*' --sort=-v:refname) | Select-Object -First 1
    if ($latestTag) {
        $current = ($latestTag -replace '^v', '')
    } elseif ($Version) {
        # First release in a repo with neither manifests nor tags: -Version says what it is, and
        # 0.0.0 exists only so the bump-type label below has something to compare against.
        $current = '0.0.0'
    } else {
        Write-Error "This repo publishes no plugins (Get-ReleasePluginTier is false) and carries no vX.Y.Z tag, so there is no current version to bump from. Pass -Version <X.Y.Z> for the first release."
        exit 1
    }
}

if ($Version) {
    if ($Version -notmatch '^\d+\.\d+\.\d+$') { Write-Error "-Version must have the form X.Y.Z (e.g. 1.0.0)."; exit 1 }
    $new = $Version
} elseif ($Bump) {
    $new = Get-NextVersion -Current $current -BumpKind $Bump
} else {
    Write-Error "Provide -Version <X.Y.Z> or -Bump <major|minor|patch>. Current version: $current."
    exit 1
}
if ($new -eq $current) { Write-Error "New version ($new) equals the current one -- nothing to bump."; exit 1 }

$bumpType = Get-BumpType -From $current -To $new
$typeLabel = @{ major = 'Major'; minor = 'Minor'; patch = 'Patch' }[$bumpType]
$tagName = "v$new"
if ((git tag --list $tagName)) { Write-Error "Tag $tagName already exists."; exit 1 }

# --- Guardrail: a NEW MAJOR needs its own overview section before the row can land ----------------
# Placed here, with the other guardrails, because it must stop the run BEFORE anything is written: the
# row insertion happens after the notes file already exists, and failing there would leave a release
# half-cut. Get-OverviewTargetMajor (release-lib, tested) answers where the row would actually go.
#
# The failure this prevents is silent, not loud: the inserter matches the FIRST table header, so on a
# major bump a 'v3.0.0' row is filed neatly under '### 2.x' and nothing errors. And it has never been
# hit, because the grouping-by-major arrived in v2.0.1 -- one release after the only major ever cut.
# Rare plus silent is the worst combination for a manual step, which is why this speaks up instead.
$newMajor = ($new -split '\.')[0]
$relReadmePath = Join-Path $repoRoot 'releases\README.md'
if (Test-Path -LiteralPath $relReadmePath) {
    $targetMajor = Get-OverviewTargetMajor -ReadmeContent (Get-Content -LiteralPath $relReadmePath -Raw -Encoding UTF8)
    if ($null -ne $targetMajor -and $targetMajor -ne $newMajor) {
        # The message must state what is actually KNOWN, not assume a direction. The mismatch is
        # reachable both ways, and the two ways need different remedies:
        #   newMajor > target -- the usual case: a new major whose section does not exist yet.
        #   newMajor < target -- the section exists but is not on top, because a HIGHER major was opened
        #     already. Saying "has no '### 2.x' section yet" there would be plainly false, and a
        #     guardrail that misdescribes the repo teaches people to bypass it.
        $advice = if ([int]$newMajor -lt [int]$targetMajor) {
            "'### $newMajor.x' does exist, but '### $targetMajor.x' sits above it, so that is where the row goes.`n" +
            "Releasing an older major after a newer one has been opened needs a decision this script will not make for`n" +
            "you: either move the row by hand after cutting, or reconsider the version."
        } else {
            "Add the section first -- directly under '## Overview', ABOVE '### $targetMajor.x':`n`n" +
            "### $newMajor.x`n`n| Version | Date | Type | Title |`n|---|---|---|---|`n`n" +
            "Then run this again. Opening a new major's section is a deliberate milestone moment, which is why it`n" +
            "is not done for you."
        }
        Write-Error @"
This release is v$new, but a new row in releases/README.md would be filed under '### $targetMajor.x'
(the first table in the overview). Nothing was written.

$advice
"@
        exit 1
    }
}

# --- Lint gate ----------------------------------------------------------------------------------
if (-not $SkipLint) {
    $lintPath = Join-Path $PSScriptRoot '..\lint\check-plugin-integrity.ps1'
    if (Test-Path $lintPath) {
        Write-Host "check-plugin-integrity: integrity check for the release..." -ForegroundColor Cyan
        & powershell -NoProfile -ExecutionPolicy Bypass -File $lintPath
        if ($LASTEXITCODE -ne 0) { Write-Error "check-plugin-integrity found errors -- release aborted. Fix them, or run with -SkipLint."; exit 1 }
    } else {
        Write-Warning "check-plugin-integrity.ps1 not found -- lint gate skipped."
    }
}

# --- Build content (before the write actions, so a parse error leaves nothing behind) --------
# The notes folder: '<X>.x' per major (this workshop) or '<X.Y>' per minor, from the seam (#417).
# $notesDirName is used for the path, the README row link and the directory creation below, so the
# scheme is answered once rather than three times.
$notesDirName = if ($notesGrouping -eq 'minor') {
    $p = $new -split '\.'; "$($p[0]).$($p[1])"
} else {
    ($new -split '\.')[0] + '.x'
}
$notesRelPath = "releases/development/$notesDirName/$new.md"
$today = (Get-Date -Format 'yyyy-MM-dd')

$changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
$changelogRaw = Get-Content -Path $changelogPath -Raw -Encoding UTF8
$entries = @(Get-PullRequestEntries -Content $changelogRaw)

# -SummaryFile: an authored milestone block, read here rather than passed as a string, because a
# multi-page summary does not survive a command line. Deliberately NOT required to live in the repo:
# its canonical home becomes the generated notes file, and keeping a second copy under releases/ just
# to feed this parameter would be the duplication this repo removes elsewhere.
$summaryText = ''
if ($SummaryFile) {
    if (-not (Test-Path -LiteralPath $SummaryFile -PathType Leaf)) {
        Write-Error "-SummaryFile '$SummaryFile' does not exist. Nothing was written."
        exit 1
    }
    $summaryText = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $SummaryFile).Path, [System.Text.Encoding]::UTF8)
    if (-not $summaryText.Trim()) {
        # An empty file is a mistake worth stopping on: it would silently produce an ordinary release
        # while the operator believes they cut a milestone.
        Write-Error "-SummaryFile '$SummaryFile' is empty. Nothing was written."
        exit 1
    }
}

$notesContent = Build-ReleaseNotes -Entries $entries -Version $new -Date $today -Type $typeLabel -Title $Title -Summary $summaryText
$changelogNew = Convert-ChangelogForRelease -Content $changelogRaw -Version $new -Date $today -Type $typeLabel -NotesRelPath $notesRelPath -LiveMarker $liveMarker

# The highlights pair, built here with everything else so a failure leaves no half-written release
# behind. $cutHighlights is off unless the seam names THIS bump type: the tier exists for the release
# a stakeholder is told about, and a patch is generally not that release.
$cutHighlights = $highlightsBumps -contains $bumpType
$highlightsRelPath = "releases/highlights/$notesDirName/$new.md"
$highlightsHtmlRelPath = "releases/highlights/$notesDirName/$new.html"
if ($cutHighlights) {
    $highlightsContent = Build-HighlightsNotes -Entries $entries -Version $new -Date $today `
        -Type $typeLabel -Title $Title -StakeholderTypes $highlightsTypes `
        -DevBlockComment $highlightsWording.DevBlockComment -DevBlockHeading $highlightsWording.DevBlockHeading
    $highlightsHtml = ConvertTo-ReleaseHtml -Markdown $highlightsContent -Version "v$new" -Lang $highlightsWording.HtmlLang
}

# --- Write the release-notes file -------------------------------------------------------------
# EVERY target is checked before ANY of them is written. With the highlights tier on there are three
# files, and stopping halfway through would leave a release whose notes exist and whose stakeholder
# document does not -- discovered by the release manager rather than by this guard.
# Kept as REPO-RELATIVE paths and joined per check: the message has to name the file the way the repo
# does, and [System.IO.Path]::GetRelativePath does not exist in the .NET Framework that Windows
# PowerShell 5.1 runs on -- it would throw here instead of reporting the collision it was written for.
$plannedFiles = @($notesRelPath)
if ($cutHighlights) { $plannedFiles += @($highlightsRelPath, $highlightsHtmlRelPath) }
foreach ($rel in $plannedFiles) {
    if (Test-Path -LiteralPath (Join-Path $repoRoot ($rel -replace '/', '\'))) {
        Write-Error "$rel already exists. Nothing was written."
        exit 1
    }
}
$notesAbs = Join-Path $repoRoot ($notesRelPath -replace '/', '\')

$notesDir = Join-Path $repoRoot ("releases\development\$notesDirName")
New-Item -ItemType Directory -Force -Path $notesDir | Out-Null
Write-Utf8NoBom -Path $notesAbs -Content $notesContent
Write-Host "  created: $notesRelPath ($($entries.Count) entries)" -ForegroundColor DarkGray

# --- Update the releases/README.md overview table ------------------------------------------------
# The overview table header is English ("Version | Date | Type | Title", #114 follow-up), so
# $headerRe below matches that; a new row is inserted right after it. The overview is grouped by
# major version (### 2.x, ### 1.x, ... newest first), each group its own table with this same
# header; $headerRe.Match returns the FIRST match, so the row always lands in the top (current
# major) table -- correct for every minor/patch bump. A brand-new major starts a new top section
# manually first (a deliberate milestone moment), after which its table becomes the insertion target.
$relReadme = Join-Path $repoRoot 'releases\README.md'
$shortTitle = if ($Title) { $Title } else { "$typeLabel release" }
$newRow = "| [$new](development/$notesDirName/$new.md) | $today | $typeLabel | $shortTitle |"
if (Test-Path $relReadme) {
    $rm = Get-Content -Path $relReadme -Raw -Encoding UTF8
    $rmNl = if ($rm.Contains("`r`n")) { "`r`n" } else { "`n" }
    $headerRe = [regex]"(?m)^\| Version \| Date \| Type \| Title \|\r?\n\|[-| ]+\|\r?\n"
    $hm = $headerRe.Match($rm)
    if ($hm.Success) {
        $at = $hm.Index + $hm.Length
        $rm = $rm.Substring(0, $at) + $newRow + $rmNl + $rm.Substring($at)
        Write-Utf8NoBom -Path $relReadme -Content $rm
        Write-Host "  updated: releases/README.md" -ForegroundColor DarkGray
    } else {
        Write-Warning "Overview table not found in releases/README.md -- add the row manually: $newRow"
    }
} else {
    Write-Warning "releases/README.md is missing -- row not added: $newRow"
}

Write-Utf8NoBom -Path $changelogPath -Content $changelogNew

# --- Per-plugin CHANGELOG + RELEASE.md card (consumer-facing; travel along with the plugin cache) -
# A combined loop per plugin (#103, Victor #7; previously two separate $manifests loops): both
# steps share the same $pluginEntries selection (Get-EntryPlugins filter + Remove-EntryPluginsLine),
# so determine that once per plugin instead of twice. The CHANGELOG step writes ONLY if the plugin
# actually has entries this release; the RELEASE.md step deliberately runs over EVERY plugin -- the
# version bumps lockstep, so even a plugin not touched this time must show the new version
# (Build-PluginReleaseCard then shows the "no changes" block instead of failing). RELEASE.md is a
# snapshot (not a history like CHANGELOG.md), so overwriting is exactly right there.
#
# The loop is over $manifests, which is EMPTY when the seam says this repo publishes no plugins
# (#417) -- so no extra `if` is needed here and the block simply does nothing. Stated rather than
# left to be inferred: an empty collection doing nothing is correct, but silent.
foreach ($m in $manifests) {
    $pluginDir = Split-Path (Split-Path $m -Parent) -Parent
    $pluginName = Split-Path $pluginDir -Leaf
    # The Plugins: line is internal administration (drove the selection here) -- strip it before
    # an entry lands in consumer-facing content.
    $pluginEntries = @($entries | Where-Object { @(Get-EntryPlugins -EntryText $_) -contains $pluginName })
    $pluginEntries = @($pluginEntries | ForEach-Object { Remove-EntryPluginsLine -EntryText $_ })

    if ($pluginEntries.Count -gt 0) {
        $convertedEntries = @($pluginEntries | ForEach-Object { Convert-EntryLinksForPluginChangelog -EntryText $_ -RepoBlobUrl (Get-RepoBlobUrl) })
        $section = Build-PluginChangelogSection -Entries $convertedEntries -Version $new -Date $today
        $plChangelogPath = Join-Path $pluginDir 'CHANGELOG.md'
        $existing = if (Test-Path -LiteralPath $plChangelogPath) { Get-Content -Path $plChangelogPath -Raw -Encoding UTF8 } else { '' }
        Write-Utf8NoBom -Path $plChangelogPath -Content (Add-PluginChangelogSection -Existing $existing -Section $section -PluginName $pluginName -MarketplaceName $marketplaceName)
        Write-Host "  updated: $pluginName/CHANGELOG.md ($($pluginEntries.Count) entries)" -ForegroundColor DarkGray
    }

    $card = Build-PluginReleaseCard -PluginName $pluginName -Version $new -Date $today -Type $typeLabel `
        -Title $Title -Entries $pluginEntries -RepoBlobUrl (Get-RepoBlobUrl)
    $releaseCardPath = Join-Path $pluginDir 'RELEASE.md'
    Write-Utf8NoBom -Path $releaseCardPath -Content $card
    Write-Host "  updated: $pluginName/RELEASE.md" -ForegroundColor DarkGray
}

# --- 3d. The highlights pair (stakeholder-facing; only for the bump types the seam names) ---------
# Content and collision were both settled above, so this block is pure IO. It writes NOTHING when the
# tier is off, which is every release in this repo -- see the seam for why the answer here is empty.
if ($cutHighlights) {
    New-Item -ItemType Directory -Force -Path (Join-Path $repoRoot "releases\highlights\$notesDirName") | Out-Null
    Write-Utf8NoBom -Path (Join-Path $repoRoot ($highlightsRelPath -replace '/', '\')) -Content $highlightsContent
    Write-Host "  created: $highlightsRelPath (highlights -- edit before publishing)" -ForegroundColor DarkGray
    Write-Utf8NoBom -Path (Join-Path $repoRoot ($highlightsHtmlRelPath -replace '/', '\')) -Content $highlightsHtml
    Write-Host "  created: $highlightsHtmlRelPath (open in a browser -> Ctrl+P -> save as PDF)" -ForegroundColor DarkGray
}

# --- Bump plugin versions (regex on the version line -- preserves the JSON formatting) -----------
foreach ($m in $manifests) {
    $raw = Get-Content -Path $m -Raw -Encoding UTF8
    $bumped = [regex]::Replace($raw, '("version"\s*:\s*")\d+\.\d+\.\d+(")', "`${1}$new`$2", 1)
    Write-Utf8NoBom -Path $m -Content $bumped
    $pluginName = Split-Path (Split-Path (Split-Path $m -Parent) -Parent) -Leaf
    Write-Host "  bumped: $pluginName/.claude-plugin/plugin.json -> $new" -ForegroundColor DarkGray
}

# --- Commit + tag directly on main ---------------------------------------------------------
# Native git writes chatter to stderr (the LF->CRLF warning from `git add`, `remote:` on push).
# Under ErrorActionPreference=Stop, PowerShell 5.1 would promote that to a terminating
# NativeCommandError before the $LASTEXITCODE checks -- the pitfall that broke cutting v1.12.0 on
# `git add` (#107). Invoke-NativeCapture (#114) runs each git call under EAP=Continue and hands back
# output + exit code, so we rely purely on $LASTEXITCODE; the captured chatter is echoed so the
# release run stays as verbose as before.
$add = Invoke-NativeCapture -FilePath 'git' -Arguments @('add', '-A')
$add.Output | ForEach-Object { Write-Host $_ }
if ($add.ExitCode -ne 0) { Write-Error "git add failed."; exit 1 }

$commit = Invoke-NativeCapture -FilePath 'git' -Arguments @('commit', '-m', "release: v$new")
$commit.Output | ForEach-Object { Write-Host $_ }
if ($commit.ExitCode -ne 0) { Write-Error "git commit failed."; exit 1 }

$tag = Invoke-NativeCapture -FilePath 'git' -Arguments @('tag', '-a', $tagName, '-m', "Release $tagName")
$tag.Output | ForEach-Object { Write-Host $_ }
if ($tag.ExitCode -ne 0) { Write-Error "git tag failed."; exit 1 }

if ($NoPush) {
    Write-Host ""
    Write-Host "Release v$new recorded locally on main (commit + tag $tagName), not pushed." -ForegroundColor Green
    Write-Host "Push it yourself when ready:" -ForegroundColor Cyan
    Write-Host "  git push origin main; git push origin $tagName"
    exit 0
}

$pushMain = Invoke-NativeCapture -FilePath 'git' -Arguments @('push', 'origin', 'main')
$pushMain.Output | ForEach-Object { Write-Host $_ }
if ($pushMain.ExitCode -ne 0) { Write-Error "git push of main failed."; exit 1 }

$pushTag = Invoke-NativeCapture -FilePath 'git' -Arguments @('push', 'origin', $tagName)
$pushTag.Output | ForEach-Object { Write-Host $_ }
if ($pushTag.ExitCode -ne 0) { Write-Error "git push of the tag failed."; exit 1 }

Write-Host ""
Write-Host "Done: v$new has been cut ($current -> $new, $typeLabel), committed on main and tagged as $tagName. Recorded." -ForegroundColor Green
