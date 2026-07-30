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
      1. Guardrails: clean main, no unfolded entry files in the root, lint gate green.
      2. Reads the current lockstep version from every <plugin>/.claude-plugin/plugin.json;
         determines the new version (-Version or -Bump) and the bump type.
      3. Generates releases/development/<X>.x/<X.Y.Z>.md from the ## Pull Requests entries
         (grouped by branch type), adds a row to releases/README.md, puts a reference in
         CHANGELOG.md under ## Releases and empties the Pull-Requests section, and bumps all
         plugin.json's.
      3b. Writes, per plugin, the entries with a matching 'Plugins:' line (derived by the fold
          from the PR files) into <plugin>/CHANGELOG.md -- the consumer-facing history that
          travels along with the plugin cache. Root-relative links are rewritten to absolute
          GitHub URLs in the process.
      3c. Writes/overwrites, for EVERY plugin (not just the touched ones -- the version bumps
          lockstep), <plugin>/RELEASE.md: a short card ("You are on this release") that shows a
          consumer which release they are on, with or without its own entries this time, plus
          links to the full notes and its own CHANGELOG.md. Model A (plugin-carried), deliberately
          without a session-start hook.
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

$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

. (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')
# Repo name/blob URL from the local repo-config (single source) instead of release-lib's literal default.
. (Join-Path $PSScriptRoot '..\repo-config.ps1')
# Shared native-capture helper (#114): the #107 EAP=Continue -> capture -> $LASTEXITCODE dance for
# the git mutations in the final block lives here in one tested place.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# BOM-less UTF8 -- the rest of the repo has no BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

# Permanent root .md files that are NOT branch changelog entries. The stray-entry guardrail below
# treats every other root *.md as an unfolded entry (deliberately catch-all, so an entry with an
# unknown branch prefix is never missed) -- so any permanent root doc added over time must be
# listed here, or a release would falsely refuse to cut. Add new permanent root docs here.
$reservedRootMd = @('CHANGELOG.md', 'CLAUDE.md', 'README.md', 'LICENSE.md', 'CONTRIBUTING.md', 'SECURITY.md')

function Get-PluginManifests {
    # The marketplace definition is the source of truth about what a plugin is: the manifests are
    # derived from plugins[].source (incl. containment check) by Get-PluginManifestPaths in
    # release-lib.ps1 -- pure there and thus tested. Here only the IO: reading + existence check.
    $marketplacePath = Join-Path $repoRoot '.claude-plugin\marketplace.json'
    if (-not (Test-Path -LiteralPath $marketplacePath)) {
        Write-Error ".claude-plugin/marketplace.json is missing."; exit 1
    }
    $paths = @(Get-PluginManifestPaths -RepoRoot $repoRoot `
        -MarketplaceJson (Get-Content -Path $marketplacePath -Raw -Encoding UTF8))
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
$manifests = @(Get-PluginManifests)
if ($manifests.Count -eq 0) { Write-Error "No plugin manifests found."; exit 1 }
$manifestContents = @{}
foreach ($m in $manifests) { $manifestContents[$m] = (Get-Content -Path $m -Raw -Encoding UTF8) }
$current = Get-LockstepVersion -ManifestContents $manifestContents

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
$majorDir = ($new -split '\.')[0] + '.x'
$notesRelPath = "releases/development/$majorDir/$new.md"
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
$changelogNew = Convert-ChangelogForRelease -Content $changelogRaw -Version $new -Date $today -Type $typeLabel -NotesRelPath $notesRelPath

# --- Write the release-notes file -------------------------------------------------------------
$notesDir = Join-Path $repoRoot ("releases\development\$majorDir")
New-Item -ItemType Directory -Force -Path $notesDir | Out-Null
$notesAbs = Join-Path $repoRoot ($notesRelPath -replace '/', '\')
if (Test-Path $notesAbs) { Write-Error "$notesRelPath already exists."; exit 1 }
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
$newRow = "| [$new](development/$majorDir/$new.md) | $today | $typeLabel | $shortTitle |"
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
        Write-Utf8NoBom -Path $plChangelogPath -Content (Add-PluginChangelogSection -Existing $existing -Section $section -PluginName $pluginName)
        Write-Host "  updated: $pluginName/CHANGELOG.md ($($pluginEntries.Count) entries)" -ForegroundColor DarkGray
    }

    $card = Build-PluginReleaseCard -PluginName $pluginName -Version $new -Date $today -Type $typeLabel `
        -Title $Title -Entries $pluginEntries -RepoBlobUrl (Get-RepoBlobUrl)
    $releaseCardPath = Join-Path $pluginDir 'RELEASE.md'
    Write-Utf8NoBom -Path $releaseCardPath -Content $card
    Write-Host "  updated: $pluginName/RELEASE.md" -ForegroundColor DarkGray
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
