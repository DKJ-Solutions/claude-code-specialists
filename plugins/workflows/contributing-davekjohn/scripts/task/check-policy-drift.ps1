<#
.SYNOPSIS
    Locates the documents check-policy-drift compares, so the comparison that follows misses nothing:
    a consumer's root CLAUDE.md, and the portable policy doc(s) of the plugin(s) that outrank it --
    contributing-davekjohn always, bwj-codex too when it is also enabled and installed for this repo
    (feat/plugin-policy-precedence).

.DESCRIPTION
    Dave's fixed precedence (stated in contributing-davekjohn's CONTRIBUTING-portable.md, cross-
    referenced from bwj-codex's WORKFLOW-portable.md): contributing-davekjohn outranks bwj-codex (if
    installed), which outranks the consumer's own root CLAUDE.md. A consumer's CLAUDE.md is free to
    add anything a plugin's policy is silent on; it may never assert the OPPOSITE of what an installed
    plugin's policy states.

    TELLING THE TWO APART IS A JUDGEMENT CALL ABOUT PROSE, NOT SOMETHING A SCRIPT CAN PARSE -- so this
    script does none of it. Its one job is finding the right files and printing where they are; the
    reading happens afterward, the same division of labor report-issue documents for its own
    procedure ("no script of its own... the colleague-facing translation is a judgement call, not a
    transform"). What IS deterministic here -- which plugin ids this repo actually has enabled and
    where their payload sits on this machine -- is exactly what a script should answer, so it does.

    THE ENABLE/INSTALL QUESTION IS ANSWERED THE WAY EVERY OTHER SESSION-FACING CHECK ANSWERS IT,
    reused rather than re-derived (Get-EnabledPlugins, Get-InstallRecord, Test-PluginInstalledHere --
    all in check-report-lib.ps1, the same lib check-roster-sync.ps1 and check-script-contract.ps1
    already dot-source). A consumer whose plugin resolves differently there -- a machine-wide
    install, a pinned version, CLAUDE_PLUGIN_ROOT inside a running session -- resolves the same way
    here, rather than this script inventing a second answer that can disagree with the first.

    RESOLVE-PLUGINDIR ITSELF IS NOT REUSABLE HERE, and that is worth saying rather than silently
    working around. It requires an agents/ directory at every return path (built for a roster check),
    so calling it on a WORKFLOW plugin -- contributing-davekjohn and bwj-codex both ship skills/, not
    agents/ -- would answer $null on every machine, for every workflow plugin, always. That is not a
    corner case Resolve-PluginDir happens to miss; it is a question the function was never built to
    answer. Resolve-PolicyPluginDir below carries the exact same three-step precedence
    (CLAUDE_PLUGIN_ROOT when it names this plugin, then the install record for this repo, then the
    highest cached version) with the one thing that differs -- WHICH file must be present -- taken as
    a parameter instead of hardcoded to 'agents'. Get-CachedPluginDirs already separates "is this
    plugin on this machine at all" from "does it ship what I am looking for" for the matching reason
    (see its own docstring, measured against a plugin of skills and MCP servers only); this wraps
    that separation around the one file each caller here actually needs.

    Never writes anything, anywhere. This is a locator, not a gate: it always exits 0 once the
    consumer's own CLAUDE.md could be found (the comparison can proceed even when a plugin's doc
    cannot be located -- that is printed as a finding, not enforced as a failure) and 1 only when
    CLAUDE.md itself is missing, since then there is nothing to compare against at all.

    Pure ASCII (repo convention for .ps1).

.PARAMETER RepoRootOverride
    (Fixture only.) Use this path as the consumer repo root instead of the dual-context default
    (CLAUDE_PROJECT_DIR, else the git root of the working directory).

.PARAMETER CacheRootOverride
    (Fixture only.) Use this dir as the plugin cache root instead of
    $env:USERPROFILE/.claude/plugins/cache -- lets a fixture supply a controlled bwj-codex install.

.PARAMETER UserHomeOverride
    (Fixture only.) Use this dir as the user home when resolving the settings chain and the install
    administration, instead of $env:USERPROFILE.
#>

[CmdletBinding()]
param(
    [string]$RepoRootOverride = '',
    [string]$CacheRootOverride = '',
    [string]$UserHomeOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Get-EnabledPlugins / Get-InstallRecord / Test-PluginInstalledHere / Get-CachedPluginDirs /
# Get-UserClaudeHome / Format-SafeToken / Test-PluginNameSlug / Test-PluginMarketplaceSlug --
# $PSScriptRoot-relative sibling, like every check that reads this seam, so it resolves whether this
# file runs from the workshop root or a consumer's plugin cache.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

# Dual-context repo root, the same resolution as every other mirrored script.
$repoRoot = if ($RepoRootOverride) {
    (Resolve-Path -LiteralPath $RepoRootOverride).Path
} elseif ($env:CLAUDE_PROJECT_DIR) {
    (Resolve-Path -LiteralPath $env:CLAUDE_PROJECT_DIR).Path
} else {
    (git rev-parse --show-toplevel).Trim()
}

$cacheRoot = if ($CacheRootOverride) { $CacheRootOverride } else { Join-Path (Get-UserClaudeHome -UserHomeOverride $UserHomeOverride) '.claude\plugins\cache' }

# The Resolve-PluginDir precedence, adapted for a plugin that ships no agents/ directory -- see the
# banner above for why Resolve-PluginDir itself cannot answer this question for either plugin this
# script cares about.
function Resolve-PolicyPluginDir {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Marketplace,
        [Parameter(Mandatory)][string]$CacheRoot,
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$RequiredRelativeFile
    )

    if ($env:CLAUDE_PLUGIN_ROOT) {
        $cpr = $env:CLAUDE_PLUGIN_ROOT
        if ((Test-Path -LiteralPath $cpr -PathType Container) -and
            ((Split-Path (Split-Path $cpr -Parent) -Leaf) -eq $Name) -and
            (Test-Path -LiteralPath (Join-Path $cpr $RequiredRelativeFile) -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $cpr).Path
        }
    }

    $record = Get-InstallRecord -RepoRoot $RepoRoot
    $recId = "$Name@$Marketplace"
    if ($record.RecordsById.ContainsKey($recId)) {
        foreach ($rec in @($record.RecordsById[$recId])) {
            if (-not $rec.InstallPath) { continue }
            if (-not (Test-Path -LiteralPath $rec.InstallPath -PathType Container)) { continue }
            if (-not (Test-Path -LiteralPath (Join-Path $rec.InstallPath $RequiredRelativeFile) -PathType Leaf)) { continue }
            return (Resolve-Path -LiteralPath $rec.InstallPath).Path
        }
    }

    foreach ($v in (Get-CachedPluginDirs -Name $Name -Marketplace $Marketplace -CacheRoot $CacheRoot)) {
        if (Test-Path -LiteralPath (Join-Path $v $RequiredRelativeFile) -PathType Leaf) {
            return (Resolve-Path -LiteralPath $v).Path
        }
    }
    return $null
}

# Locates one plugin's portable-policy doc via the shared enable/install mechanism above, and reports
# WHY when it cannot. $FallbackPath is consulted only for the plugin this SCRIPT is itself shipped in
# (contributing-davekjohn): the running copy's own location is a stronger answer than a second cache
# lookup that could resolve a DIFFERENT cached version if more than one is present on this machine
# (the exact case Resolve-PluginDir's own docstring measures under "WHY STEP 2 EXISTS") -- and it is
# never a wrong answer, because this script cannot be running at all unless that copy exists.
function Resolve-PolicyDoc {
    param(
        [Parameter(Mandatory)][string]$PluginName,
        [Parameter(Mandatory)][string]$DocRelativePath,
        [Parameter(Mandatory)]$Enabled,
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$CacheRoot,
        [string]$FallbackPath = ''
    )

    $selfFound = { (Resolve-Path -LiteralPath $FallbackPath -ErrorAction SilentlyContinue) }
    $id = @($Enabled.Ids | Where-Object { $_ -match ('^' + [regex]::Escape($PluginName) + '@') }) | Select-Object -First 1

    if (-not $id) {
        $self = & $selfFound
        if ($self) {
            return [pscustomobject]@{ State = 'Found'; Path = $self.Path; Message = "'$PluginName' is not visible in the settings chain from here -- but this script is itself part of it, so its own doc (beside the running copy) is used." }
        }
        return [pscustomobject]@{ State = 'Skip'; Path = $null; Message = "'$PluginName' is not enabled for this repo -- $DocRelativePath is out of scope." }
    }

    $idShown = Format-SafeToken -Value $id
    $parts = $id.Split('@')
    $name = $parts[0]
    $marketplace = if ($parts.Count -gt 1) { $parts[1] } else { '' }

    if ((-not (Test-PluginNameSlug -Name $name)) -or (-not $marketplace) -or (-not (Test-PluginMarketplaceSlug -Marketplace $marketplace))) {
        return [pscustomobject]@{ State = 'Missing'; Path = $null; Message = "'$idShown' is not a resolvable plugin id -- $DocRelativePath was not located." }
    }

    $installRecord = Get-InstallRecord -RepoRoot $RepoRoot
    if (-not (Test-PluginInstalledHere -InstallRecord $installRecord -PluginId $id)) {
        $self = & $selfFound
        if ($self) {
            return [pscustomobject]@{ State = 'Found'; Path = $self.Path; Message = "'$idShown' has no install record for this repo -- but this script is itself the running copy of $PluginName, so its own doc (beside it) is used." }
        }
        return [pscustomobject]@{ State = 'Skip'; Path = $null; Message = "'$idShown' is enabled in $($Enabled.LayerById[$id]) but has no install record for this repo -- a session here would not load it, so $DocRelativePath is out of scope. Fix: 'claude plugin install $id --scope project'." }
    }

    $pluginDir = Resolve-PolicyPluginDir -Name $name -Marketplace $marketplace -CacheRoot $CacheRoot -RepoRoot $RepoRoot -RequiredRelativeFile $DocRelativePath
    if (-not $pluginDir) {
        $self = & $selfFound
        if ($self) {
            return [pscustomobject]@{ State = 'Found'; Path = $self.Path; Message = "'$idShown' is enabled and installed here, but no cached copy under $CacheRoot carries $DocRelativePath -- this script is itself the running copy of $PluginName, so its own doc (beside it) is used instead." }
        }
        return [pscustomobject]@{ State = 'Missing'; Path = $null; Message = "'$idShown' is enabled and installed for this repo, but no cached copy under $CacheRoot carries $DocRelativePath -- this cached version may predate the branch that added it, or the install may run on another machine." }
    }

    return [pscustomobject]@{ State = 'Found'; Path = (Join-Path $pluginDir $DocRelativePath); Message = "'$idShown' (cache $(Split-Path $pluginDir -Leaf))" }
}

Write-Host '== check-policy-drift: locating the documents to compare ==' -ForegroundColor Cyan
Write-Host "  repo: $repoRoot"

# --- The consumer's own policy -----------------------------------------------------------------------
$claudeMdPath = Join-Path $repoRoot 'CLAUDE.md'
if (-not (Test-Path -LiteralPath $claudeMdPath -PathType Leaf)) {
    Write-Host ''
    Write-Host "  [MISSING] no root CLAUDE.md at $claudeMdPath -- there is nothing here for a plugin's policy to be compared against." -ForegroundColor Red
    Write-Host ''
    Write-Host 'Nothing to read. Stopping here.' -ForegroundColor Yellow
    exit 1
}
Write-Host "  [FOUND] consumer policy: $claudeMdPath" -ForegroundColor Green

$enabled = Get-EnabledPlugins -RepoRoot $repoRoot -UserHomeOverride $UserHomeOverride

# --- contributing-davekjohn's policy: always in scope --------------------------------------------------
# The 'beside me' fallback: this script sits at <plugin>/scripts/task/, so the doc is two levels up.
$contributingFallback = Join-Path $PSScriptRoot '..\..\CONTRIBUTING-portable.md'
$contributing = Resolve-PolicyDoc -PluginName 'contributing-davekjohn' -DocRelativePath 'CONTRIBUTING-portable.md' `
    -Enabled $enabled -RepoRoot $repoRoot -CacheRoot $cacheRoot -FallbackPath $contributingFallback
switch ($contributing.State) {
    'Found'   { Write-Host "  [FOUND] contributing-davekjohn policy (always in scope): $($contributing.Path) -- $($contributing.Message)" -ForegroundColor Green }
    'Skip'    { Write-Host "  [SKIP] $($contributing.Message)" -ForegroundColor Yellow }
    'Missing' { Write-Host "  [MISSING] $($contributing.Message)" -ForegroundColor Yellow }
}

# --- bwj-codex's policy: only when it is enabled AND installed for this repo -------------------------
$bwj = Resolve-PolicyDoc -PluginName 'bwj-codex' -DocRelativePath 'WORKFLOW-portable.md' `
    -Enabled $enabled -RepoRoot $repoRoot -CacheRoot $cacheRoot
switch ($bwj.State) {
    'Found'   { Write-Host "  [FOUND] bwj-codex policy (in scope -- enabled and installed here): $($bwj.Path) -- $($bwj.Message)" -ForegroundColor Green }
    'Skip'    { Write-Host "  [SKIP] $($bwj.Message)" -ForegroundColor DarkGray }
    'Missing' { Write-Host "  [MISSING] $($bwj.Message)" -ForegroundColor Yellow }
}

Write-Host ''
Write-Host 'Read every [FOUND] document above in full, then compare the consumer policy against each' -ForegroundColor Cyan
Write-Host 'plugin policy, statement by statement, for genuine contradictions -- not merely a topic the' -ForegroundColor Cyan
Write-Host 'plugin is silent on, and not detail the consumer added on its own. Report each contradiction:' -ForegroundColor Cyan
Write-Host 'the consumer claim (quoted, file + location), the plugin claim it conflicts with (quoted, file' -ForegroundColor Cyan
Write-Host '+ location), and a one-line statement of which side wins (always the plugin -- the precedence' -ForegroundColor Cyan
Write-Host 'contributing-davekjohn/CONTRIBUTING-portable.md states) and what the consumer text should say' -ForegroundColor Cyan
Write-Host 'instead. Report "no contradictions found" when that is the outcome. This is a finding, never an' -ForegroundColor Cyan
Write-Host 'edit -- the consumer file is never touched.' -ForegroundColor Cyan
exit 0
