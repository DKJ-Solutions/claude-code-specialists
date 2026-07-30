<#
.SYNOPSIS
    Pure release helpers (version determination + CHANGELOG transformation + release-notes
    building), separate from git/filesystem orchestration.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

    Supplies Get-NextVersion, Get-BumpType, Get-LockstepVersion, Get-PluginManifestPaths,
    Get-PullRequestEntries, Convert-ChangelogForRelease, Build-ReleaseNotes, and for the
    per-plugin CHANGELOGs: Get-EntryPlugins, Convert-EntryLinksForPluginChangelog,
    Build-PluginChangelogSection and Add-PluginChangelogSection. Also Build-PluginReleaseCard: the
    per-plugin RELEASE.md card (Model A, plugin-carried) that shows which release the plugin is
    currently on, even if this particular release did not touch the plugin (lockstep version, the
    card may have no entries). These functions are deliberately pure (string/value in,
    string/value out) so they can be tested separately without running a release --
    scripts/release/cut-release.ps1 uses them, and the tests cover them.

    Model: the release content moves to releases/development/<X>.x/<X.Y.Z>.md; the ## Releases
    block in CHANGELOG.md becomes a short REFERENCE to that file (like life-hub, but without GitHub
    Releases). The ## Pull Requests section is emptied down to its intro in the process.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.

    Note: this file is deliberately pure ASCII (repo convention for .ps1). Non-ASCII output
    characters (middot, em-dash) are built via [char]0x.. rather than as a literal -- Windows
    PowerShell 5.1 reads a BOM-less script as ANSI and would otherwise mangle a literal.

    NOTE (Sylvester, English script-layer sweep, #114 follow-up): the DOCUMENT-GENERATING template
    strings in this file (the catTitle category labels, the "See [...] for the full release notes"
    reference line, the ## Releases / plugin-CHANGELOG intro texts, the **Date:** label) now produce
    ENGLISH CHANGELOG.md / release-notes / per-plugin-CHANGELOG content, per Dave's follow-up
    decision to also migrate this generated-content language (not just comments/console output).
    Existing history is the deliberate exception and is left untouched: already-folded CHANGELOG.md
    sections and the releases/** notes stay in whatever language they were written in -- only
    FUTURE output from these templates changed, so a mix of Dutch history and English new content is
    expected and fine.
#>

# The branch types (Feat/Fix/Docs/Chore) have a single source in branch-info.ps1; Build-ReleaseNotes
# reads them via Get-BranchTypes instead of its own copy. Same folder, so CI-safe from a bare
# checkout. No Set-StrictMode change: branch-info only defines functions + data.
. (Join-Path $PSScriptRoot 'branch-info.ps1')

function Get-NextVersion {
    <# Bumps a SemVer X.Y.Z according to $BumpKind (major|minor|patch). #>
    param(
        [Parameter(Mandatory)][string]$Current,
        [Parameter(Mandatory)][ValidateSet('major', 'minor', 'patch')][string]$BumpKind
    )
    if ($Current -notmatch '^\d+\.\d+\.\d+$') { throw "Current version '$Current' is not a valid X.Y.Z." }
    $p = $Current -split '\.'
    [int]$maj = $p[0]; [int]$min = $p[1]; [int]$pat = $p[2]
    switch ($BumpKind) {
        'major' { $maj++; $min = 0; $pat = 0 }
        'minor' { $min++; $pat = 0 }
        'patch' { $pat++ }
    }
    return "$maj.$min.$pat"
}

function Get-BumpType {
    <# Determines the bump type (major/minor/patch) from an old and new SemVer. #>
    param(
        [Parameter(Mandatory)][string]$From,
        [Parameter(Mandatory)][string]$To
    )
    if ($From -notmatch '^\d+\.\d+\.\d+$' -or $To -notmatch '^\d+\.\d+\.\d+$') { throw "From/To must be X.Y.Z." }
    $f = $From -split '\.'; $t = $To -split '\.'
    if ([int]$t[0] -ne [int]$f[0]) { return 'major' }
    if ([int]$t[1] -ne [int]$f[1]) { return 'minor' }
    return 'patch'
}

function Get-LockstepVersion {
    <#
        Determines the shared (lockstep) version from a set of plugin.json contents. Input is a
        hashtable of name/path -> raw JSON text. Throws if a version is missing or if they are not
        equal.
    #>
    param([Parameter(Mandatory)][hashtable]$ManifestContents)
    if ($ManifestContents.Count -eq 0) { throw "No plugin manifests given." }
    $versions = @{}
    foreach ($key in $ManifestContents.Keys) {
        if ($ManifestContents[$key] -match '"version"\s*:\s*"(\d+\.\d+\.\d+)"') {
            $versions[$key] = $matches[1]
        } else {
            throw "Could not find a valid 'version' (X.Y.Z) in '$key'."
        }
    }
    $distinct = @($versions.Values | Sort-Object -Unique)
    if ($distinct.Count -ne 1) {
        $detail = ($versions.GetEnumerator() | ForEach-Object { "  $($_.Key): $($_.Value)" }) -join "`n"
        throw "Plugin versions are not in lockstep (must be equal for a repo-wide release):`n$detail"
    }
    return $distinct[0]
}

function Get-PluginManifestPaths {
    <#
        Derives the plugin manifest paths from plugins[].source in the marketplace JSON -- the
        marketplace is the source of truth about what a plugin is. Pure (does not touch disk):
        input is the raw JSON text + the repo root, output is an array of full manifest paths.
        Throws on a missing plugins list, a missing source field, and (containment, Sean's advice)
        on a source that points outside the repo root via an absolute or ..-path -- the version
        bump must never write outside the repo.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$MarketplaceJson
    )
    $marketplace = $MarketplaceJson | ConvertFrom-Json
    if (-not ($marketplace.PSObject.Properties.Name -contains 'plugins') -or -not $marketplace.plugins) {
        throw "marketplace.json has no 'plugins' list."
    }
    $rootPrefix = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
    foreach ($p in $marketplace.plugins) {
        if (-not $p.source) { throw "plugin '$($p.name)' is missing a 'source'." }
        # An absolute source is by definition outside the repo convention -- report explicitly
        # instead of the confusing Join-Path/GetFullPath error that would otherwise roll out.
        if ([System.IO.Path]::IsPathRooted($p.source)) {
            throw "plugin '$($p.name)': source '$($p.source)' points outside the repo (absolute path)."
        }
        $manifest = $null
        try {
            $manifest = [System.IO.Path]::GetFullPath(
                (Join-Path $RepoRoot (Join-Path $p.source '.claude-plugin\plugin.json')))
        } catch {
            throw "plugin '$($p.name)': source '$($p.source)' is not a valid path."
        }
        if (-not $manifest.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "plugin '$($p.name)': source '$($p.source)' points outside the repo ($manifest)."
        }
        $manifest
    }
}

function Get-FencedLineFlags {
    <#
        Returns a bool per input line: is that line inside a fenced code block?

        Exists because markdown structure tests -- '^### ' for an entry heading, '^---$' for a
        separator -- must not fire on text an entry body QUOTES. An entry may legitimately show a
        broken heading structure or a YAML frontmatter example, and treating that as structure is how
        cutting v2.13.3 produced a third entry from two PRs, split a fence open, and duplicated a
        category heading in the release notes.

        The fence line ITSELF is reported as fenced ($true), so a caller that skips fenced lines keeps
        the fence markers with the content rather than stripping them and leaving the body inside
        rendered as prose.

        Deliberately simple: a line whose first non-space characters are ``` or ~~~ toggles the state.
        That is CommonMark's own rule for the common cases and needs no parser. Nested fences of the
        same kind are not a thing in CommonMark, and an unclosed fence leaves the tail flagged as
        fenced -- which is the safe direction, since it stops the parser inventing structure out of
        code.
    #>
    # Not Mandatory, and both Allow* attributes: a changelog section can legitimately be a single
    # empty line, and a Mandatory [string[]] rejects '' outright (ParameterArgumentValidationError).
    param([AllowEmptyString()][AllowEmptyCollection()][string[]]$Lines = @())
    if ($null -eq $Lines) { return @() }
    $flags = New-Object 'bool[]' $Lines.Count
    $inFence = $false
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\s*(```|~~~)') {
            $flags[$i] = $true          # the marker belongs to the block
            $inFence = -not $inFence
        } else {
            $flags[$i] = $inFence
        }
    }
    return $flags
}

function Split-Changelog {
    <#
        Private helper: parses CHANGELOG.md into its parts. Returns an object with Nl, Head
        (through the '## Pull Requests' line), PrIntro, Entries (array of entry blocks), RelIntro
        and ExistingReleases. Throws if the sections are missing or there are no entries to release.
    #>
    param([Parameter(Mandatory)][string]$Content)

    $usesCRLF = $Content.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }
    $lines = $Content -split "`r?`n"

    $prIdx = -1; $relIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+Pull Requests\s*$') { $prIdx = $i }
        elseif ($lines[$i] -match '^##\s+Releases\s*$') { $relIdx = $i }
    }
    if ($prIdx -lt 0) { throw "Could not find '## Pull Requests' in CHANGELOG.md." }
    if ($relIdx -lt 0) { throw "Could not find '## Releases' in CHANGELOG.md." }
    if ($relIdx -le $prIdx) { throw "'## Releases' does not come after '## Pull Requests' -- unexpected structure." }

    $head = $lines[0..$prIdx]

    $prBody = @($lines[($prIdx + 1)..($relIdx - 1)])
    $prFirst = -1
    # Fence-aware here too: a '###' quoted inside a fence in the section intro would otherwise be read
    # as the first entry, putting the intro/entries boundary in the middle of a code block.
    $prFenced = Get-FencedLineFlags -Lines $prBody
    for ($i = 0; $i -lt $prBody.Count; $i++) { if ((-not $prFenced[$i]) -and $prBody[$i] -match '^###\s') { $prFirst = $i; break } }
    if ($prFirst -lt 0) { throw "No changelog entries under '## Pull Requests' -- nothing to release." }

    $prIntro = if ($prFirst -gt 0) { @($prBody[0..($prFirst - 1)]) } else { @() }
    $entryLines = @($prBody[$prFirst..($prBody.Count - 1)])

    # Split entry lines into blocks: a new block starts at every '### ' heading. '---' separators
    # between entries are skipped.
    #
    # BOTH of those tests must ignore FENCED CODE BLOCKS. An entry body may legitimately quote markdown
    # -- a broken heading structure, a YAML frontmatter example -- and without fence awareness the
    # parser reads that quoted text as structure. Measured while cutting v2.13.3: an entry that quoted
    # a '### #242 ...' line inside a ``` fence produced a THIRD entry from two PRs, split the fence
    # open, and duplicated '## Fixes' in the generated notes. Caught by -NoPush before it shipped.
    # Fourth instance of the same defect class in one day (#227, #235, and the teardown's VUL-IN test):
    # a matcher satisfied by a MENTION rather than a use.
    $fenced = Get-FencedLineFlags -Lines $entryLines
    $entries = @()
    $cur = $null
    for ($i = 0; $i -lt $entryLines.Count; $i++) {
        $ln = $entryLines[$i]
        if ((-not $fenced[$i]) -and $ln -match '^###\s') {
            if ($null -ne $cur) { $entries += (($cur -join $nl).Trim()) }
            $cur = @($ln)
        } elseif ($null -ne $cur) {
            if ((-not $fenced[$i]) -and $ln -match '^---\s*$') { continue }
            $cur += $ln
        }
    }
    if ($null -ne $cur) { $entries += (($cur -join $nl).Trim()) }

    $relBody = @($lines[($relIdx + 1)..($lines.Count - 1)])
    $relFirst = -1
    for ($i = 0; $i -lt $relBody.Count; $i++) { if ($relBody[$i] -match '^###\s') { $relFirst = $i; break } }
    $relIntroLines = if ($relFirst -ge 0) { @($relBody[0..($relFirst - 1)]) } else { $relBody }
    $existingReleases = if ($relFirst -ge 0) { @($relBody[$relFirst..($relBody.Count - 1)]) } else { @() }

    return [pscustomobject]@{
        Nl               = $nl
        Head             = $head
        PrIntro          = $prIntro
        Entries          = $entries
        RelIntroLines    = $relIntroLines
        ExistingReleases = $existingReleases
    }
}

function Get-PullRequestEntries {
    <# Returns the entry blocks to be released (### ... + body + PR link) from the Pull-Requests section. #>
    param([Parameter(Mandatory)][string]$Content)
    return @((Split-Changelog -Content $Content).Entries)
}

function Convert-ChangelogForRelease {
    <#
        Empties the '## Pull Requests' section down to its intro and puts a short REFERENCE
        '### [v<Version>] - <Date> - <Type>' at the top of '## Releases' to the release-notes file
        ($NotesRelPath). Pure string in/out.
    #>
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date,
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][string]$NotesRelPath
    )
    $emDash = [char]0x2014
    $s = Split-Changelog -Content $Content
    $nl = $s.Nl

    $block = @(
        "### [v$Version] - $Date $emDash $Type",
        '',
        "See [$NotesRelPath]($NotesRelPath) for the full release notes."
    )

    $relIntroText = ($s.RelIntroLines -join "`n")
    if ($relIntroText -match 'No releases recorded') {
        $relIntro = @(
            "The recorded versions of the marketplace $emDash newest at the top. Every release bumps all",
            'plugin versions in lockstep and points to the full notes in `releases/development/`.'
        )
    } else {
        $relIntro = @($s.RelIntroLines | Where-Object { $_ -ne '' })
    }

    $out = @()
    $out += $s.Head
    $out += ''
    $out += ($s.PrIntro | Where-Object { $_ -ne '' })
    $out += ''
    $out += '## Releases'
    $out += ''
    $out += $relIntro
    $out += ''
    $out += $block
    if ($s.ExistingReleases.Count -gt 0) {
        $out += ''
        $out += '---'
        $out += ''
        $out += $s.ExistingReleases
    }

    return (($out -join $nl).TrimEnd() + $nl)
}

function Get-TouchedPlugins {
    <#
        Pure: derives the touched plugin names from a list of PR file paths (repo-root-relative,
        as gh pr list --json files supplies -- $Files here are already flat path strings, not the
        gh objects themselves). Only paths under claude-code-plugins/claude-specialists/<plugin>/
        count; the connectors folder is workshop administration and does not count (same rule as
        previously inline in fold-changelog-entry.ps1). -cmatch (Sean's advice): -match is
        case-insensitive and would silently widen the lowercase character class; plugin folder
        names are always lowercase slugs. Returns a sorted, deduplicated array of plugin names
        (empty if nothing touches a plugin). Pulled out to here (#103, Victor #3) so the detection
        is separately testable, instead of inline logic in fold-changelog-entry.ps1.
    #>
    param([string[]]$Files = @())
    $touched = @()
    foreach ($f in $Files) {
        if ($f -cmatch '^claude-code-plugins/claude-specialists/([a-z0-9][a-z0-9-]*)/') {
            if ($Matches[1] -ne 'connectors' -and $touched -notcontains $Matches[1]) { $touched += $Matches[1] }
        }
    }
    return @($touched | Sort-Object)
}

function Get-EntryPlugins {
    <#
        Reads the optional 'Plugins: a, b' line from an entry block (derived by
        fold-changelog-entry.ps1 from the PR files). Returns an array of plugin names; empty = the
        entry does not touch plugin content (workshop-internal).
    #>
    param([Parameter(Mandatory)][string]$EntryText)
    $m = [regex]::Match($EntryText, '(?m)^Plugins:\s*(.+?)\s*$')
    if (-not $m.Success) { return @() }
    return @($m.Groups[1].Value -split '\s*,\s*' | Where-Object { $_ })
}

function Remove-EntryPluginsLine {
    <#
        Removes the 'Plugins: ...' metadata line (plus the blank line left behind by it) from an
        entry block. That line drives the per-plugin selection in cut-release.ps1, but is workshop
        administration and should not be visible in the consumer-facing per-plugin CHANGELOG; the
        root CHANGELOG and the release notes do show it.
    #>
    param([Parameter(Mandatory)][string]$EntryText)
    $t = [regex]::Replace($EntryText, '(?m)^Plugins:[^\r\n]*(\r?\n)?', '')
    return [regex]::Replace($t, '(\r?\n)\1\1+', '$1$1')
}

function Convert-RootRelativeLinks {
    <#
        Rewrites repo-root-relative markdown links with the given prefix; external (http/mailto),
        anchor (#), absolute (/) and ../ links are left alone. The shared engine behind
        Build-ReleaseNotes and Convert-EntryLinksForPluginChangelog.
    #>
    param(
        [Parameter(Mandatory)][string]$EntryText,
        [Parameter(Mandatory)][string]$Prefix
    )
    return [regex]::Replace($EntryText, '\]\((?!https?:|mailto:|#|/|\.\./)([^)]+)\)', "](${Prefix}`$1)")
}

function Convert-EntryLinksForPluginChangelog {
    <#
        Rewrites repo-root-relative markdown links to absolute GitHub blob URLs, so an entry is
        also readable in a consumer's plugin cache (where the repo files do not exist).
    #>
    param(
        [Parameter(Mandatory)][string]$EntryText,
        # Live value is injected by cut-release.ps1 from repo-config (Get-RepoBlobUrl); this
        # literal is only the fallback if the function is called without -RepoBlobUrl.
        [string]$RepoBlobUrl = 'https://github.com/DaveKJohn/davekjohns-workshop/blob/main/'
    )
    return Convert-RootRelativeLinks -EntryText $EntryText -Prefix $RepoBlobUrl
}

function Get-ReleaseCategories {
    <#
        Single source of truth for the release-notes category grouping: the ordered categories (the
        canonical branch types from branch-info.ps1 + an 'Other' catch-all for an entry with an
        unknown type) and their short display labels. Shared by Build-ReleaseNotes (the full notes),
        Build-PluginChangelogSection (per-plugin CHANGELOG) and Build-PluginReleaseCard (the
        RELEASE.md card), so all three render the same categories with the same labels. Returns an
        object with Order (string[]) and Title (hashtable type -> label).
    #>
    return [pscustomobject]@{
        Order = @(Get-BranchTypes) + 'Other'
        Title = @{
            Feat  = 'Features'
            Fix   = 'Fixes'
            Docs  = 'Documentation'
            Chore = 'Maintenance'
            Other = 'Other'
        }
    }
}

function Format-CategorizedEntries {
    <#
        Pure: renders entry blocks grouped under category headings, in the canonical category order
        (Get-ReleaseCategories); a category with no entries is omitted. The type of each entry is
        read from its "### #NN <md> title <md> type <md> date" heading (the second-to-last
        middot-separated field); an unknown type falls into 'Other', so a new branch type is never
        silently dropped.

        $CategoryLevel = the number of '#' for a category heading (e.g. 2 -> '## Features'). Each
        entry's own heading is re-levelled to sit exactly one level under its category
        (CategoryLevel + 1), so the nesting stays correct whether the container is a single-release
        file ('#' title -> '##' category -> '###' entry) or a stacked CHANGELOG ('## vX' release ->
        '###' category -> '####' entry). Entries within a category are separated by '---'; only the
        entry's FIRST line (its title heading) is re-levelled -- a '#'-prefixed line inside a body
        is left alone (^ without multiline = start of the whole block). Output is pure LF; $Entries
        may arrive CRLF (from the root CHANGELOG) and are normalized here.
    #>
    param(
        [Parameter(Mandatory)][string[]]$Entries,
        [int]$CategoryLevel = 2
    )
    $md = [char]0x00B7
    $cats = Get-ReleaseCategories
    $catHashes = '#' * $CategoryLevel
    $entryHashes = '#' * ($CategoryLevel + 1)

    $grouped = @{}
    foreach ($e in $Entries) {
        $heading = ($e -split "`r?`n")[0]
        $t = 'Other'
        $parts = @(($heading -replace '^#+\s+', '') -split "\s*$md\s*")
        if ($parts.Count -ge 2) {
            $cand = $parts[$parts.Count - 2].Trim()
            if ($cats.Order -contains $cand) { $t = $cand }
        }
        if (-not $grouped.ContainsKey($t)) { $grouped[$t] = New-Object System.Collections.Generic.List[string] }
        $grouped[$t].Add(($e.Trim() -replace "`r`n", "`n"))
    }

    $sections = @()
    foreach ($cat in $cats.Order) {
        if ($grouped.ContainsKey($cat)) {
            $label = if ($cats.Title.ContainsKey($cat)) { $cats.Title[$cat] } else { $cat }
            $rendered = @($grouped[$cat].ToArray() | ForEach-Object {
                [regex]::Replace($_, '^#{2,6}\s', "$entryHashes ")
            })
            $body = ($rendered -join "`n`n---`n`n")
            $sections += "$catHashes $label`n`n$body"
        }
    }
    return ($sections -join "`n`n")
}

function Build-PluginChangelogSection {
    <#
        Builds the '## v<Version> <emDash> <Date>' block for a plugin CHANGELOG from the entries
        that touch that plugin, grouped by category ('### <Category>' -> '#### <entry>', one level
        under the '## v' release heading -- see Format-CategorizedEntries). Pure string out --
        DELIBERATELY hard LF (instead of the $nl-detection pattern that
        Split-Changelog/Convert-ChangelogForRelease use): this block is written into a NEW,
        standalone plugin-CHANGELOG.md, which has no existing newline style of its own to match --
        unlike the root CHANGELOG.md (which is CRLF and detects and keeps its own style via $nl).
        $Entries, however, come from that CRLF root CHANGELOG (via Get-PullRequestEntries) -- so
        Format-CategorizedEntries normalizes them to LF (#103, Victor #5), otherwise the CRLF inside
        an entry body would still cross the promised pure-LF output.
    #>
    param(
        [Parameter(Mandatory)][string[]]$Entries,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date
    )
    $emDash = [char]0x2014
    $body = Format-CategorizedEntries -Entries $Entries -CategoryLevel 3
    return "## v$Version $emDash $Date`n`n$body`n"
}

function Add-PluginChangelogSection {
    <#
        Adds a release section to the top of a plugin CHANGELOG (after the intro, before the first
        version heading, newest first); if no content exists yet, the full CHANGELOG including
        intro header is built. Pure string in/out.
    #>
    param(
        [string]$Existing = '',
        [Parameter(Mandatory)][string]$Section,
        [Parameter(Mandatory)][string]$PluginName
    )
    $emDash = [char]0x2014
    if (-not $Existing) {
        $intro = "# Changelog $emDash $PluginName`n`n" +
            "Consumer-facing history of this plugin: per release, the changes that touched this`n" +
            "plugin. Automatically appended by ``cut-release.ps1`` of the marketplace repo`n" +
            "(davekjohns-workshop); the full workshop history lives there in ``CHANGELOG.md`` and`n" +
            "``releases/``.`n`n"
        return ($intro + $Section.TrimEnd() + "`n")
    }
    # Tightened (#103, Victor #5): specifically matches a version heading ('## vX.Y.Z ...', exactly
    # the pattern Build-PluginChangelogSection itself writes), not just any arbitrary '## ' heading --
    # otherwise a manually added non-version heading (e.g. '## Notes') would make the insertion
    # position match incorrectly and cram the new section into the middle of it instead of before it.
    $m = [regex]::Match($Existing, '(?m)^## v\d+\.\d+\.\d+\b')
    if ($m.Success) {
        return $Existing.Substring(0, $m.Index) + $Section.TrimEnd() + "`n`n---`n`n" + $Existing.Substring($m.Index)
    }
    return ($Existing.TrimEnd() + "`n`n" + $Section.TrimEnd() + "`n")
}

function Build-PluginReleaseCard {
    <#
        Builds the full RELEASE.md card text for a plugin (Model A, plugin-carried): a consumer
        who only has the plugin cache sees immediately which release version they are on, even if
        this particular release did not touch the plugin (the version bumps lockstep, so every
        plugin gets a fresh card on every release). The body groups entries by category via
        Format-CategorizedEntries (a single-release view: '## <Category>' -> '### <entry>', like the
        full notes) after Convert-EntryLinksForPluginChangelog rewrites their links. Pure string out
        (LF newlines), so separately testable.

        $Entries is the array of entry blocks of THIS plugin for THIS release (may be empty --
        no changes simply means the "no changes" block, no error). $RepoBlobUrl is the base for
        the link to the full workshop notes (repo-root-relative, so only readable as a blob URL
        from the plugin cache); the link to its own CHANGELOG.md is deliberately kept
        folder-relative ("CHANGELOG.md") -- that file travels along with this card in the same
        plugin folder, so that link works both in this repo and in a consumer's plugin cache.
    #>
    param(
        [Parameter(Mandatory)][string]$PluginName,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date,
        [Parameter(Mandatory)][string]$Type,
        [string]$Title = '',
        [string[]]$Entries = @(),
        [string]$RepoBlobUrl = 'https://github.com/DaveKJohn/davekjohns-workshop/blob/main/'
    )
    $majorDir = ($Version -split '\.')[0] + '.x'
    $notesRelPath = "releases/development/$majorDir/$Version.md"
    $notesUrl = "$RepoBlobUrl$notesRelPath"

    $titleLine = if ($Title) { "$Title`n`n" } else { '' }
    $header = "# Release v$Version`n`n" +
        "**Date:** $Date  `n**Type:** $Type`n`n" +
        "${titleLine}You are on this release.`n`n"

    $emDash = [char]0x2014
    $realEntries = @($Entries | Where-Object { $_ -and $_.Trim() })
    if ($realEntries.Count -gt 0) {
        $converted = @($realEntries | ForEach-Object {
            Convert-EntryLinksForPluginChangelog -EntryText $_ -RepoBlobUrl $RepoBlobUrl
        })
        # Single-release view: categories at '##' -> entries at '###', exactly like the full notes.
        # (No inner '## vX -- date' line -- the card header above already states the version + date.)
        $body = (Format-CategorizedEntries -Entries $converted -CategoryLevel 2).Trim()
    } else {
        $body = "No changes to this plugin in this release $emDash see the full notes."
    }

    $footer = "---`n`n" +
        "Full workshop notes: [$notesRelPath]($notesUrl)`n" +
        "Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)`n"

    return ($header + $body + "`n`n" + $footer)
}

function Build-ReleaseNotes {
    <#
        Builds the full release notes (the releases/development/<X>.x/<X.Y.Z>.md file) from the
        entry blocks, grouped by branch type. Pure string out -- DELIBERATELY hard LF (see
        Build-PluginChangelogSection above for the same trade-off: this is a NEW, standalone file
        with no existing newline style of its own, unlike the root CHANGELOG.md which detects and
        keeps its CRLF style via $nl). $Entries come from that CRLF root CHANGELOG -- so here they
        are explicitly normalized to LF (#103, Victor #5), alongside the link rewriting below.
    #>
    param(
        [Parameter(Mandatory)][string[]]$Entries,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date,
        [Parameter(Mandatory)][string]$Type,
        [string]$Title = '',
        # An AUTHORED block placed between the one-line title and the generated entries -- for a
        # milestone release whose point is the arc across many releases rather than the diff since the
        # last one. $Title is one sentence and the entries are per-PR; neither can carry "here is what
        # changed between 2.2.0 and 2.16.0", and hand-editing a generated file is not a repeatable
        # release. Empty by default, so an ordinary release is byte-identical to before.
        [string]$Summary = '',
        # Prefix to resolve repo-root-relative links in entry bodies from the deeper location of
        # the notes file (releases/development/<X>.x/ = 3 folders deep -> '../../../').
        [string]$LinkPrefix = '../../../'
    )
    # Entries are written with repo-root-relative links; rewrite them so they resolve correctly
    # from the notes file (releases/development/<X>.x/ = 3 folders deep -> '../../../'). External
    # (http/mailto), anchor (#) and absolute (/) links are left alone, as are links that already
    # start with ../. Format-CategorizedEntries then groups the entries by category
    # ('## <Category>' -> '### <entry>') and normalizes to LF, so the CRLF of the source CHANGELOG
    # does not cross the pure-LF output.
    $linked = @($Entries | ForEach-Object { Convert-RootRelativeLinks -EntryText $_ -Prefix $LinkPrefix })
    $body = Format-CategorizedEntries -Entries $linked -CategoryLevel 2

    $titleLine = if ($Title) { "$Title`n`n" } else { '' }
    # Normalized to LF like everything else that enters this file, and separated from the generated
    # entries by a horizontal rule -- so a reader can see where the authored part stops and the
    # per-PR record begins. Without that boundary a milestone summary reads as if it were generated,
    # which is the one thing it must not be mistaken for.
    $summaryBlock = if ($Summary) {
        (($Summary -replace "`r`n", "`n").TrimEnd() + "`n`n---`n`n")
    } else { '' }
    $header = "# Release notes v$Version`n`n**Date:** $Date  `n**Type:** $Type`n`n$titleLine$summaryBlock"
    return ($header + $body + "`n")
}
