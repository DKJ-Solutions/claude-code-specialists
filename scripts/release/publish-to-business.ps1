<#
.SYNOPSIS
    Publishes the marketplace subset of this repo to the business GitHub repo that Claude
    Enterprise syncs from.

.DESCRIPTION
    THE MODEL. This repo stays the single source of truth: the plugins are developed, released and
    tagged here. The business repo is a PUBLICATION TARGET, not a second workshop -- it holds only
    what Claude needs in order to serve the plugins to colleagues, and it is overwritten from here
    every time you publish. Nobody edits it by hand; anything committed there directly is lost on
    the next run, by design.

    WHAT TRAVELS. The two things a plugin marketplace actually needs, plus the documents a reader
    of that repo would miss:

        .claude-plugin/marketplace.json   required, and required in the root
        plugins/                          the six plugin folders the manifest points at, plus
                                          agent-shared/ (the source of the generated shared blocks)
                                          and the INSTALL/UNINSTALL/README pages
        README.md, LICENSE, CHANGELOG.md  context for whoever opens the business repo
        .github/ISSUE_TEMPLATE/           the inbound path the docs link to
        .gitignore, .gitattributes        so a clone behaves the same

    WHAT DOES NOT. scripts/, .claude/, connectors/, releases/, workflow-davekjohn/, CLAUDE.md,
    CONTRIBUTING.md, SECURITY.md. That is the maintainer's half of this repo and Claude never reads
    it from the marketplace. Keeping it out is what makes the published repo ~150 files instead of
    ~370, and it is also the reason the published repo can be private without giving colleagues
    anything to be confused by.

    IT DELETES BEFORE IT COPIES. The target's working tree is emptied (except .git) and rebuilt from
    the list above, so a plugin or file REMOVED here disappears there too. A sync that only ever
    copies would leave a deleted plugin serving forever.

    IT CHECKS BEFORE IT COMMITS. Every `source` in marketplace.json must resolve to a folder with a
    .claude-plugin/plugin.json in the rebuilt tree. A marketplace whose manifest points at a folder
    that did not travel is the one failure mode that is invisible here and loud for every colleague,
    so it is a hard stop rather than a warning.

    VERSIONS ARE THE UPDATE SIGNAL. Claude only hands users a new version of a plugin when the
    `version` in its plugin.json goes up. This script does not touch versions -- bump them in the
    normal release here, then publish. The commit message it writes records the versions it carried
    so the target's history reads as a release log.

    Pure ASCII (repo convention for .ps1): Windows PowerShell 5.1 reads a BOM-less script using the
    system ANSI codepage, so a literal non-ASCII character in the source is decoded wrongly.

.PARAMETER TargetRepo
    The business repo, as owner/name or as a full git URL. owner/name is expanded to
    https://github.com/<owner>/<name>.git. Defaults to what Get-BusinessMarketplaceRepo in
    scripts/repo-config.ps1 answers -- repo data lives in that seam, not in this script -- so the
    normal run needs no arguments at all. Pass it explicitly to publish the same set to a second
    organisation.

.PARAMETER RepoRoot
    Alternative repo root. Defaults to CLAUDE_PROJECT_DIR, then the git toplevel. Exists so the
    test suite can run against a fixture, and so the script works from any directory.

.PARAMETER Message
    Commit message for the publication. Defaults to a generated one naming the source commit and
    the plugin versions carried.

.PARAMETER Branch
    Branch to publish to. Defaults to main. Claude's organization sync reads the default branch.

.PARAMETER DryRun
    Do everything up to the commit, print what would change, then stop without committing or
    pushing. Use this the first time, and after any change to the published set.

.PARAMETER KeepClone
    Do not delete the temporary clone afterwards. Its path is printed so you can inspect it.

.EXAMPLE
    ./scripts/release/publish-to-business.ps1 -DryRun

    Shows exactly which files would be added, changed and removed in the business repo.

.EXAMPLE
    ./scripts/release/publish-to-business.ps1

    Publishes. Run this after a release cut, once the version bumps are on main.

.EXAMPLE
    ./scripts/release/publish-to-business.ps1 -TargetRepo OTHER-ORG/their-plugins

    Publishes the same set to a different target, for a second organisation.
#>
[CmdletBinding()]
param(
    [string] $TargetRepo,

    [string] $RepoRoot,

    [string] $Message,

    [string] $Branch = 'main',

    [switch] $DryRun,

    [switch] $KeepClone
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Shared native-capture helper (#114): Windows PowerShell 5.1 promotes a native command's stderr to a
# terminating NativeCommandError under EAP=Stop -- and git clone/push write their progress to stderr,
# so every git call below runs through this one tested guard instead of a raw `& git 2>&1`.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# ---------------------------------------------------------------- the published set

# Top-level paths that travel to the business repo. Files or folders, repo-root-relative.
# A path that does not exist here is skipped with a warning rather than failing the run: the
# optional documents are allowed to disappear, the required ones are checked separately below.
#
# INSTALL.md AND UNINSTALL.md ARE ABSENT ON PURPOSE, and the way they are absent is the point (inbound
# #664, August 14, 2026). They used to travel by sitting inside 'plugins', which is published whole --
# so there was no entry to remove and no list that could express the choice. They now live at the repo
# root instead, which puts them outside every published path without anything having to remember them.
# An exclusion list was the obvious alternative and was declined: a list is silent about the third
# plumbing page somebody adds later, while a folder boundary refuses it by construction. Same reasoning
# that put connectors/ at the root.
#
# What a colleague on this marketplace still needs is plugins/ADOPTION.md -- the bootstrap, the roster
# and the lenses -- and that travels with 'plugins' exactly as before.
$PublishedPaths = @(
    '.claude-plugin/marketplace.json'
    'plugins'
    'README.md'
    'LICENSE'
    'CHANGELOG.md'
    '.github/ISSUE_TEMPLATE'
    '.gitignore'
    '.gitattributes'
)

# Without these the marketplace does not work at all.
$RequiredPaths = @(
    '.claude-plugin/marketplace.json'
    'plugins'
)

# ---------------------------------------------------------------- helpers

function Resolve-RepoRoot {
    param([string] $Explicit)

    if ($Explicit) { return (Resolve-Path -LiteralPath $Explicit).Path }
    if ($env:CLAUDE_PROJECT_DIR) { return (Resolve-Path -LiteralPath $env:CLAUDE_PROJECT_DIR).Path }

    $top = Invoke-NativeCapture -FilePath 'git' -Arguments @('rev-parse', '--show-toplevel') -DiscardStderr
    if ($top.ExitCode -eq 0 -and $top.Output) { return (Resolve-Path -LiteralPath ("$($top.Output)".Trim())).Path }

    throw 'Cannot determine the repo root. Pass -RepoRoot, or run from inside the repo.'
}

function Resolve-TargetUrl {
    param([string] $Value)

    if ($Value -match '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$') {
        return "https://github.com/$Value.git"
    }
    return $Value
}

function Invoke-Git {
    <# Runs git via the shared native-capture guard and throws on a non-zero exit. #>
    param(
        [string]   $WorkingDirectory,
        [string[]] $Arguments,
        [switch]   $Quiet
    )

    $r = Invoke-NativeCapture -FilePath 'git' -Arguments (@('-C', $WorkingDirectory) + $Arguments)
    # Stringified before anything touches it: on 5.1 the merged stderr lines arrive as ErrorRecords,
    # and callers substring the returned lines (the name-status grouping in the report).
    $output = @($r.Output | ForEach-Object { "$_" })
    if ($r.ExitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed:`n$($output -join [Environment]::NewLine)"
    }
    if (-not $Quiet -and $output) { $output | ForEach-Object { Write-Verbose $_ } }
    return $output
}

function Get-JsonField {
    <#
        A field from a ConvertFrom-Json object, or $null when it is absent.

        NOT DECORATION. Set-StrictMode -Version Latest makes a missing property a TERMINATING error,
        so a bare $plugin.source on a malformed entry throws before the check that exists to explain
        it can report anything -- and the reader gets "The property 'source' cannot be found on this
        object" instead of the named problem. Measured on Windows PowerShell 5.1: a missing property,
        a missing top-level key and .Count on a non-array all threw rather than returning $null. On
        7.4.6, where this script was first tested, the same three are silent, which is why the gap
        survived a test that specifically covered a malformed manifest.
    #>
    param($Object, [string] $Name)

    if ($null -eq $Object) { return $null }
    if ($Object.PSObject.Properties.Name -notcontains $Name) { return $null }
    return $Object.$Name
}

function Get-PluginVersions {
    <# name/version for every plugin the manifest names, in manifest order. #>
    param([string] $Root)

    $manifestPath = Join-Path $Root '.claude-plugin/marketplace.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

    # A malformed manifest is REPORTED rather than crashed on, and reported by the integrity check
    # further down rather than here: this function only prints what is about to travel, so a missing
    # field costs it a '?' and nothing else.
    $result = @()
    foreach ($plugin in @(Get-JsonField -Object $manifest -Name 'plugins')) {
        $source = Get-JsonField -Object $plugin -Name 'source'
        $version = '?'
        if ($source) {
            $pluginJson = Join-Path $Root (Join-Path $source '.claude-plugin/plugin.json')
            if (Test-Path -LiteralPath $pluginJson) {
                $declared = Get-JsonField -Object (Get-Content -LiteralPath $pluginJson -Raw | ConvertFrom-Json) -Name 'version'
                if ($declared) { $version = $declared }
            }
        }
        $result += [pscustomobject]@{
            Name    = (Get-JsonField -Object $plugin -Name 'name')
            Source  = $source
            Version = $version
        }
    }
    return $result
}

function Assert-MarketplaceIntegrity {
    <#
        Every source in the manifest must resolve, inside the given tree, to a folder holding a
        .claude-plugin/plugin.json. Throws with the full list of failures rather than the first.
    #>
    param([string] $Root)

    $manifestPath = Join-Path $Root '.claude-plugin/marketplace.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "The published tree has no .claude-plugin/marketplace.json."
    }

    try {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    } catch {
        throw "marketplace.json is not valid JSON: $($_.Exception.Message)"
    }

    foreach ($field in @('name', 'owner', 'plugins')) {
        if ($manifest.PSObject.Properties.Name -notcontains $field) {
            throw "marketplace.json is missing the required field '$field'."
        }
    }

    $problems = @()
    foreach ($plugin in @(Get-JsonField -Object $manifest -Name 'plugins')) {
        # Read through the helper, not as $plugin.name: under StrictMode a bare property access on an
        # entry that lacks the field throws, so these two branches would be unreachable and the raw
        # error would replace the message they exist to give.
        $name   = Get-JsonField -Object $plugin -Name 'name'
        $source = Get-JsonField -Object $plugin -Name 'source'
        if (-not $name)   { $problems += 'a plugin entry has no name'; continue }
        if (-not $source) { $problems += "${name}: no source"; continue }

        $dir = Join-Path $Root $source
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
            $problems += "${name}: source '$source' did not travel"
            continue
        }
        $pluginJson = Join-Path $dir '.claude-plugin/plugin.json'
        if (-not (Test-Path -LiteralPath $pluginJson -PathType Leaf)) {
            $problems += "${name}: no .claude-plugin/plugin.json in '$source'"
        }
    }

    if ($problems.Count -gt 0) {
        # Printed rather than folded into the exception: PowerShell renders a multi-line error
        # message on one line, and the whole point of this check is that you can read the list.
        Write-Host ''
        Write-Host 'The published tree is not a valid marketplace:'
        foreach ($problem in $problems) { Write-Host "  - $problem" }
        Write-Host ''
        throw "$($problems.Count) problem(s) found -- nothing was committed or pushed."
    }

    return $manifest
}

# ---------------------------------------------------------------- run

$root = Resolve-RepoRoot -Explicit $RepoRoot

# The publication target is repo data, so it lives in scripts/repo-config.ps1 (Get-RepoName's file)
# rather than in this script. Optional function with a fallback, like Get-InternalNoteWording: the
# dot-source is guarded so a fixture root without a repo-config still runs (the tests pass
# -TargetRepo), and -TargetRepo stays as the override for a second organisation.
if (-not $TargetRepo) {
    $repoConfig = Join-Path $root 'scripts\repo-config.ps1'
    if (Test-Path -LiteralPath $repoConfig -PathType Leaf) { . $repoConfig }
    if (Get-Command Get-BusinessMarketplaceRepo -ErrorAction SilentlyContinue) {
        $TargetRepo = Get-BusinessMarketplaceRepo
    }
    if (-not $TargetRepo) {
        throw ('No publication target: pass -TargetRepo, or define Get-BusinessMarketplaceRepo in ' +
               'scripts\repo-config.ps1 (owner/name of the business repo this marketplace publishes to).')
    }
}

$url = Resolve-TargetUrl -Value $TargetRepo

Write-Host "Source     : $root"
Write-Host "Target     : $url ($Branch)"

foreach ($required in $RequiredPaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $required))) {
        throw "This does not look like the marketplace repo: '$required' not found under $root."
    }
}

$shaResult = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $root, 'rev-parse', '--short', 'HEAD') -DiscardStderr
$sourceSha = if ($shaResult.ExitCode -eq 0 -and $shaResult.Output) { "$($shaResult.Output)".Trim() } else { 'unknown' }

$dirtyResult = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $root, 'status', '--porcelain') -DiscardStderr
if ($dirtyResult.ExitCode -eq 0 -and $dirtyResult.Output) {
    Write-Warning 'The source repo has uncommitted changes. They WILL be published as-is.'
}

$versions = Get-PluginVersions -Root $root
Write-Host ''
Write-Host 'Plugins to publish:'
foreach ($v in $versions) {
    Write-Host ("  {0,-20} v{1}" -f $v.Name, $v.Version)
}
Write-Host ''

# --- clone (or initialise) the target

$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("publish-marketplace-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $temp -Force | Out-Null

$cloned = $false
try {
    Invoke-Git -WorkingDirectory (Get-Location).Path -Arguments @('clone', '--depth', '1', '--branch', $Branch, $url, $temp) -Quiet | Out-Null
    $cloned = $true
    Write-Host "Cloned the target at $Branch."
} catch {
    # A clone can fail for two very different reasons and they must not be confused. An empty repo
    # (or a missing branch) is the normal first-publication case and we continue from a fresh
    # history. Anything that smells of credentials or a missing repo is a hard stop: treating it as
    # "empty" would look like it worked right up until the push, and then fail with the same
    # unhelpful message.
    $reason = $_.Exception.Message
    $authPatterns = @(
        'could not read Username'
        'Authentication failed'
        'Permission denied'
        'Repository not found'
        'repository .* not found'
        'HTTP 40[13]'
        'terminal prompts disabled'
        'Support for password authentication was removed'
    )
    foreach ($pattern in $authPatterns) {
        if ($reason -match $pattern) {
            Write-Host ''
            Write-Host "Could not reach $url."
            Write-Host 'git said:'
            Write-Host "  $($reason -split "`n" | Select-Object -First 3)"
            Write-Host ''
            Write-Host 'This is a credentials or access problem, not an empty repo. Check that:'
            Write-Host '  - the repo exists and you can open it in the browser'
            Write-Host '  - you are authenticated as an account with write access to it'
            Write-Host '    (gh auth login, or a Personal Access Token with repo scope)'
            throw 'Aborted before touching anything.'
        }
    }

    Write-Host "Could not clone $Branch (empty repo, or the branch does not exist yet) -- starting a fresh history."
    # init + symbolic-ref rather than `git init -b`: -b needs git >= 2.28, and a fresh history is the
    # one path that only runs on a machine nobody has tried before.
    Invoke-Git -WorkingDirectory $temp -Arguments @('init') -Quiet | Out-Null
    Invoke-Git -WorkingDirectory $temp -Arguments @('symbolic-ref', 'HEAD', "refs/heads/$Branch") -Quiet | Out-Null
    Invoke-Git -WorkingDirectory $temp -Arguments @('remote', 'add', 'origin', $url) -Quiet | Out-Null
}

try {
    # --- empty the working tree, keeping .git

    Get-ChildItem -LiteralPath $temp -Force |
        Where-Object { $_.Name -ne '.git' } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }

    # --- copy the published set

    $skipped = @()
    foreach ($relative in $PublishedPaths) {
        $from = Join-Path $root $relative
        if (-not (Test-Path -LiteralPath $from)) { $skipped += $relative; continue }

        $to = Join-Path $temp $relative
        $parent = Split-Path -Parent $to
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        if (Test-Path -LiteralPath $from -PathType Container) {
            Copy-Item -LiteralPath $from -Destination $to -Recurse -Force
        } else {
            Copy-Item -LiteralPath $from -Destination $to -Force
        }
    }
    if ($skipped.Count -gt 0) {
        Write-Warning ("Not present in the source, so not published: " + ($skipped -join ', '))
    }

    # --- check what we built before we hand it to anyone

    $manifest = Assert-MarketplaceIntegrity -Root $temp
    # @() around both counts: under StrictMode .Count on an empty pipeline result or on a single
    # (non-array) JSON value is a terminating error, not 0 or 1.
    $gitDirPrefix = (Join-Path $temp '.git') + [System.IO.Path]::DirectorySeparatorChar
    $fileCount = @(Get-ChildItem -LiteralPath $temp -Recurse -File -Force |
                   Where-Object { -not $_.FullName.StartsWith($gitDirPrefix) }).Count
    $pluginCount = @(Get-JsonField -Object $manifest -Name 'plugins').Count
    Write-Host ("Built '{0}': {1} plugins, {2} files." -f (Get-JsonField -Object $manifest -Name 'name'), $pluginCount, $fileCount)

    # --- stage and report

    Invoke-Git -WorkingDirectory $temp -Arguments @('add', '-A') -Quiet | Out-Null

    $staged = Invoke-Git -WorkingDirectory $temp -Arguments @('diff', '--cached', '--stat') -Quiet
    if (-not $staged) {
        Write-Host ''
        Write-Host 'The business repo already matches this source. Nothing to publish.'
        return
    }

    Write-Host ''
    Write-Host 'Changes to publish:'
    $summary = Invoke-Git -WorkingDirectory $temp -Arguments @('diff', '--cached', '--name-status') -Quiet
    $byStatus = $summary | Group-Object { $_.Substring(0, 1) }
    foreach ($group in $byStatus) {
        $label = switch ($group.Name) {
            'A'     { 'added' }
            'M'     { 'changed' }
            'D'     { 'removed' }
            default { $group.Name }
        }
        Write-Host ("  {0,-8} {1}" -f $label, $group.Count)
    }
    Write-Host ''
    $staged | Select-Object -Last 1 | ForEach-Object { Write-Host "  $_" }

    if ($DryRun) {
        Write-Host ''
        Write-Host 'Dry run: nothing committed, nothing pushed.'
        if ($KeepClone) { Write-Host "Clone kept at: $temp" }
        return
    }

    # --- commit and push

    if (-not $Message) {
        $versionList = ($versions | ForEach-Object { "$($_.Name) $($_.Version)" }) -join ', '
        $Message = "publish: marketplace from $sourceSha ($versionList)"
    }

    Invoke-Git -WorkingDirectory $temp -Arguments @('-c', 'user.name=marketplace-publisher',
                                                    '-c', 'user.email=publisher@localhost',
                                                    'commit', '-m', $Message) -Quiet | Out-Null

    if ($cloned) {
        Invoke-Git -WorkingDirectory $temp -Arguments @('push', 'origin', $Branch) -Quiet | Out-Null
    } else {
        Invoke-Git -WorkingDirectory $temp -Arguments @('push', '-u', 'origin', $Branch) -Quiet | Out-Null
    }

    Write-Host ''
    Write-Host "Published to $url ($Branch)."
    Write-Host "Commit message: $Message"
    Write-Host ''
    Write-Host 'Claude picks this up on the next organization sync. Colleagues see the new version'
    Write-Host 'in their next session or after a plugin refresh.'
} finally {
    if ($KeepClone) {
        Write-Host "Clone kept at: $temp"
    } elseif (Test-Path -LiteralPath $temp) {
        Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}