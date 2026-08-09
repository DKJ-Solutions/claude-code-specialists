<#
.SYNOPSIS
    One answer to "which plugins does this repo publish, and where do they live".

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\plugin-tree-lib.ps1')

    THE MARKETPLACE IS THE ONLY PLACE THAT KNOWS. A repo that publishes plugins declares them in
    .claude-plugin/marketplace.json -- a name and a repo-relative source per plugin -- and every other
    statement about the set is a copy of that one. Before this lib there were five such copies, each
    with its own failure mode:

      * a hand-maintained list of four agents/ directories in check-consumer-drift.ps1, which had
        already drifted: specialists-ecomm was listed under agents and NOT under personas, so a
        consumer's drift check silently never covered that group's personas. Item 4 of the README's
        'Adding a new team' checklist existed only to keep that list current by hand;
      * a regex '^plugins/([a-z0-9][a-z0-9-]*)/' in Get-TouchedPlugins, which had to carry an explicit
        exception for the one sibling directory that is plugin SOURCE but not a plugin;
      * a path segment index, ($p.Mirror -split '[\\/]')[1], in the shared-scripts registry;
      * three Split-Path calls upward from a plugin.json in cut-release.ps1;
      * Join-Path <pluginsRoot> <name> in check-connectors.ps1.

    All five encode the same two assumptions -- that a plugin folder is named after the plugin, and
    that it sits exactly one level under plugins/ -- and neither is a fact about plugins. They are
    facts about one particular layout, which this repo has already changed twice.

    Pure where it can be: Get-PluginRoots takes the JSON text and returns objects, so it is testable
    without a tree. Get-RepoPluginRoots is the one function that touches disk, and it returns an empty
    set rather than throwing when there is no marketplace.json -- a consumer that publishes nothing is
    not a broken repo, it is the normal case.

    EVERY $PluginRoots PARAMETER ACCEPTS $null AND RE-WRAPS WITH @(), and that is load-bearing rather
    than defensive habit. An empty set is the ORDINARY input here -- a repo that publishes no plugins --
    and PowerShell unrolls an empty array on the way through a call, so Get-RepoPluginRoots's @() arrives
    at the next function as $null and a [Parameter(Mandatory)] rejects it even behind
    AllowEmptyCollection. Measured the first time the fold ran against a fixture with no
    marketplace.json: 'Cannot bind argument to parameter PluginRoots because it is null'. This repo has
    paid for the same unrolling before -- the "outer @() is load-bearing" notes in
    check-plugin-integrity.ps1 and build-agent-defs.ps1, and the follow-up commit that made the widened
    collections survive a single-element repo. Same trap, one layer down: a function whose empty case is
    normal must not be able to fail on it.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.

    No dependencies, deliberately. One caller runs at SessionStart -- check-connectors.ps1, via the
    connector-sessioncheck hook -- where pulling a heavyweight lib in to resolve a handful of paths is a
    cost paid on every single session. The other reason is the fold: fold-changelog-entry.ps1 needs
    Get-TouchedPlugins and runs immediately after a merge, directly on the trunk, and reaching it
    through release-lib would load three thousand lines of entry-scaffold-lib behind it.

    Pure ASCII (repo convention for .ps1).
#>

function Get-PluginRoots {
    <#
        Pure: the plugin set as declared in the marketplace JSON. Input is the raw JSON text plus the
        repo root; output is one object per plugin with

            Name          the plugin's name, as the marketplace declares it
            Source        the source string exactly as written (e.g. './plugins/teams/team-alpha')
            RelativeRoot  the plugin root relative to the repo, backslash-separated, no leading '.\'
            Root          the plugin root as a full path
            ManifestPath  <Root>\.claude-plugin\plugin.json, as a full path

        Throws on a missing plugins list, a missing source, and -- containment, Sean's advice -- on a
        source that leaves the repo root by an absolute path or a '..' segment. The version bump and
        the mirror writer both act on these paths, so a source pointing outside the repo has to stop
        here rather than one layer further down.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$MarketplaceJson
    )
    $marketplace = $MarketplaceJson | ConvertFrom-Json
    if (-not ($marketplace.PSObject.Properties.Name -contains 'plugins') -or -not $marketplace.plugins) {
        throw "marketplace.json has no 'plugins' list."
    }
    $fullRoot = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\')
    $rootPrefix = $fullRoot + '\'
    foreach ($p in $marketplace.plugins) {
        if (-not $p.source) { throw "plugin '$($p.name)' is missing a 'source'." }
        # An absolute source is by definition outside the repo convention -- report explicitly
        # instead of the confusing Join-Path/GetFullPath error that would otherwise roll out.
        if ([System.IO.Path]::IsPathRooted($p.source)) {
            throw "plugin '$($p.name)': source '$($p.source)' points outside the repo (absolute path)."
        }
        $root = $null
        try {
            $root = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $p.source))
        } catch {
            throw "plugin '$($p.name)': source '$($p.source)' is not a valid path."
        }
        $root = $root.TrimEnd('\')
        if (-not ($root + '\').StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "plugin '$($p.name)': source '$($p.source)' points outside the repo ($root)."
        }
        [pscustomobject]@{
            Name         = [string]$p.name
            Source       = [string]$p.source
            RelativeRoot = $root.Substring($fullRoot.Length).TrimStart('\')
            Root         = $root
            ManifestPath = Join-Path $root '.claude-plugin\plugin.json'
        }
    }
}

function Get-MarketplacePath {
    <# Where a repo declares its plugins, if it declares any. #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    return (Join-Path $RepoRoot '.claude-plugin\marketplace.json')
}

function Get-RepoPluginRoots {
    <#
        Get-PluginRoots against the repo's own marketplace.json. The one function here that reads disk.

        RETURNS AN EMPTY SET WHEN THERE IS NO marketplace.json, rather than throwing. Every caller but
        the release cut runs in consumers too, and a consumer that publishes no plugins is the ordinary
        case -- not a misconfiguration. A malformed marketplace.json still throws, because that IS one.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    $path = Get-MarketplacePath -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return @() }
    $json = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    return @(Get-PluginRoots -RepoRoot $RepoRoot -MarketplaceJson $json)
}

function Get-PluginRootByName {
    <#
        The one plugin with this name, or $null. Name comparison is ORDINAL and case-sensitive: a
        plugin name is a path segment on a case-sensitive filesystem and an install id, so 'Specialists'
        is a different plugin from 'specialists' -- Get-TouchedPlugins has always taken that position
        (its -cmatch, Sean's advice) and it is stated once here instead.
    #>
    param(
        [AllowNull()][AllowEmptyCollection()][object[]]$PluginRoots = @(),
        [Parameter(Mandatory)][string]$Name
    )
    foreach ($p in @($PluginRoots)) {
        if ([string]::Equals($p.Name, $Name, [System.StringComparison]::Ordinal)) { return $p }
    }
    return $null
}

function Get-PluginNameForPath {
    <#
        Which plugin does this repo-relative path belong to? Returns the plugin name, or $null when the
        path is under no plugin root at all.

        This replaces the depth-and-name regex it was extracted from, and it answers a question that
        regex could only approximate. Two things fall out rather than needing to be written:

          * plugins/agent-shared/ is not a plugin, so it is not matched -- no name has to be excluded
            by hand. Under the previous shape the excluded sibling had to be rewritten every time the
            layout moved (it named connectors/ until August 3, 2026, by which point connectors/ had
            left plugins/ entirely and the real sibling went uncounted);
          * a plugin root at any depth matches, so plugins/teams/team-alpha/ works without this
            function knowing that 'teams' exists.

        Accepts either separator in $Path, since callers hand it both: gh supplies forward slashes and
        Get-ChildItem supplies backslashes. The comparison is ordinal and case-sensitive for the reason
        given at Get-PluginRootByName; the longest matching root wins, so a plugin nested inside
        another plugin's directory would still be attributed to the inner one.
    #>
    param(
        [AllowNull()][AllowEmptyCollection()][object[]]$PluginRoots = @(),
        [Parameter(Mandatory)][AllowEmptyString()][string]$Path
    )
    if (-not $Path) { return $null }
    $needle = ($Path -replace '/', '\').TrimStart('.', '\')
    $best = $null
    foreach ($p in @($PluginRoots)) {
        $prefix = $p.RelativeRoot.TrimEnd('\') + '\'
        if ($needle.StartsWith($prefix, [System.StringComparison]::Ordinal)) {
            if (-not $best -or $p.RelativeRoot.Length -gt $best.RelativeRoot.Length) { $best = $p }
        }
    }
    if ($best) { return $best.Name }
    return $null
}

function Get-TouchedPlugins {
    <#
        Pure: derives the touched plugin names from a list of PR file paths (repo-root-relative, as
        gh pr list --json files supplies -- $Files here are already flat path strings, not the gh
        objects themselves), against the plugin roots the marketplace declares. Returns a sorted,
        deduplicated array of plugin names (empty if nothing touches a plugin). Separately testable
        rather than inline in fold-changelog-entry.ps1 (#103, Victor #3).

        IT ASKS THE MARKETPLACE NOW, INSTEAD OF MATCHING A PATH SHAPE. This used to be the regex
        '^plugins/([a-z0-9][a-z0-9-]*)/' with 'agent-shared' excluded by name, and the comment above it
        recorded that the excluded sibling had already had to be rewritten once: it named connectors/
        until August 3, 2026, by which point connectors/ had moved to the repo root -- so the exclusion
        was guarding nothing while the real sibling, agent-shared/, went uncounted. That is the failure
        mode of encoding a layout in a pattern. Reading the roots removes both halves at once:
        agent-shared/ is not in the marketplace so it cannot match, and a plugin at any depth does.

        LIVED IN release-lib.ps1 UNTIL AUGUST 9, 2026, where a note now points here. It reads plugin
        roots, so it belongs beside them -- and the fold script, which is its one caller, can now reach
        it without dot-sourcing a lib that pulls three thousand more lines in behind it.

        $PluginRoots comes from Get-RepoPluginRoots, which returns an empty set in a repo with no
        marketplace.json -- so a consumer folds without a 'Plugins:' line, which is the right answer
        there rather than a degraded one.
    #>
    param(
        [string[]]$Files = @(),
        [AllowNull()][AllowEmptyCollection()][object[]]$PluginRoots = @()
    )
    $touched = @()
    foreach ($f in @($Files)) {
        $name = Get-PluginNameForPath -PluginRoots $PluginRoots -Path $f
        if ($name -and $touched -notcontains $name) { $touched += $name }
    }
    return @($touched | Sort-Object)
}

function Get-PluginSubdirs {
    <#
        The <Leaf> directory of every plugin that has one -- e.g. every 'agents' directory across the
        whole set, as full paths. Existence-filtered, because not every plugin carries every kind.

        Exists so the consumer-drift check stops keeping a hand-written list of directories per kind.
        That list is where the measured asymmetry lived.

        Existence-filtered because not every plugin carries every kind: measured August 9, 2026, one of
        the five ships personas/ and three ship skills/.
    #>
    param(
        [AllowNull()][AllowEmptyCollection()][object[]]$PluginRoots = @(),
        [Parameter(Mandatory)][string]$Leaf
    )
    $out = @()
    foreach ($p in @($PluginRoots)) {
        $dir = Join-Path $p.Root $Leaf
        if (Test-Path -LiteralPath $dir -PathType Container) { $out += $dir }
    }
    return @($out)
}
