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
    Build-PluginChangelogSection, Build-PluginChangelogIntro and Add-PluginChangelogSection, plus
    Get-MarketplaceName. Also Build-PluginReleaseCard: the
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

    SHARPENED August 3, 2026 -- "only future output changed" is true of every template here EXCEPT
    one, and the exception cost four consumer-facing files. A template that appends (a release
    section, a reference line, a card that is fully regenerated) reaches its file again on the next
    release, so editing it does propagate. The per-plugin CHANGELOG INTRO is the one that does not:
    Add-PluginChangelogSection writes it only for a file that does not exist yet, so the four
    existing CHANGELOGs kept an intro naming the retired marketplace long after the rename had swept
    it out of 59 files. "Leave history alone" was the right instinct applied to the wrong text -- the
    entries below the intro are history, the intro is a live statement about the present mechanism.
    Repaired by extracting Build-PluginChangelogIntro as the single source and gating the existing
    files against it (check 17 in check-plugin-integrity.ps1). The general rule, for the next
    template added here: ask whether the string is rewritten on every release, and if it is not, it
    needs a gate rather than a good intention.
#>

# The branch types (Feat/Fix/Docs/Chore) have a single source in branch-info.ps1; Build-ReleaseNotes
# reads them via Get-BranchTypes instead of its own copy.
#
# DOT-SOURCED FROM THE SAME FOLDER ONLY WHEN THAT FOLDER HAS IT, and that condition is the whole point
# since this lib became shared (#417). branch-info.ps1 is REPO-OWNED -- the prefix table differs per
# repo -- so it does not travel into the plugin mirror, while this file does. In the workshop root the
# two are siblings and this dot-source is what it always was; from the mirror the sibling is absent and
# the caller (cut-release.ps1) has already dot-sourced the CONSUMER's branch-info from its repo root,
# which puts Get-BranchTypes in scope for the functions below.
#
# Guarded rather than removed, because release-lib is also loaded directly by its own tests and by
# callers that never resolve a repo root. Get-ReleaseCategories probes for the function instead of
# assuming it, and states its fallback -- see there.
$branchInfoSibling = Join-Path $PSScriptRoot 'branch-info.ps1'
if (Test-Path -LiteralPath $branchInfoSibling) { . $branchInfoSibling }

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

function Get-MarketplaceName {
    <#
        The marketplace's own name, read from 'name' in the marketplace JSON. Pure (does not touch
        disk): input is the raw JSON text.

        Exists so that the two places needing this name -- cut-release.ps1, which writes it into a
        new per-plugin CHANGELOG intro, and check 17 of check-plugin-integrity.ps1, which holds the
        existing intros against that same text -- read one field through one function instead of
        each carrying a literal. A literal in either place is what let the retired name survive the
        rename in four consumer-facing files.
    #>
    param([Parameter(Mandatory)][string]$MarketplaceJson)
    $marketplace = $MarketplaceJson | ConvertFrom-Json
    if (-not ($marketplace.PSObject.Properties.Name -contains 'name') -or -not $marketplace.name) {
        throw "marketplace.json has no non-empty 'name'."
    }
    return [string]$marketplace.name
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

    # BOTH release headings are recognised, and that is a migration guarantee rather than leniency.
    # A repo that switches Get-ReleaseHistoryMode to 'latest' still has '## Releases' in its changelog
    # until the next cut rewrites it -- and the throw below is fatal, so a reader that knew only the new
    # spelling would break every consumer at the one moment it is hardest to debug. Same shape as the
    # legacy slot heading in check-consumer-drift: recognise both, write one.
    $prIdx = -1; $relIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+Pull Requests\s*$') { $prIdx = $i }
        elseif ($lines[$i] -match '^##\s+(Releases|Latest Release)\s*$') { $relIdx = $i }
    }
    if ($prIdx -lt 0) { throw "Could not find '## Pull Requests' in CHANGELOG.md." }
    if ($relIdx -lt 0) { throw "Could not find '## Releases' or '## Latest Release' in CHANGELOG.md." }

    # EITHER ORDER IS VALID (August 4, 2026). This used to throw unless the release heading came after
    # Pull Requests, which was the only layout that existed while that section was an accumulating
    # archive -- an archive belongs at the bottom. Once it holds a single block the question it answers,
    # "which version is current?", belongs at the top instead. Both layouts are supported rather than
    # swapped, because a consumer's changelog keeps whatever order it already has and no cut should
    # silently reorder someone's document.
    #
    # ReleasesFirst travels in the result so the caller can rebuild in the order it found, rather than
    # re-deriving it from indices it no longer has.
    $releasesFirst = ($relIdx -lt $prIdx)
    $firstIdx  = [Math]::Min($prIdx, $relIdx)
    $secondIdx = [Math]::Max($prIdx, $relIdx)

    # Everything above the FIRST of the two headings is the document's own head -- title and intro.
    #
    # TRAILING BLANKS ARE STRIPPED, and that is a correctness fix rather than tidiness. The head as read
    # ends with the blank line separating it from the heading; Convert-ChangelogForRelease then adds its
    # own separator, so each cut left one more blank than the last. Measured over three consecutive cuts:
    # 2, 3, 4. It renders identically in markdown, which is exactly why it would have gone on growing --
    # nothing looks wrong until a reader opens the raw file years in.
    $head = if ($firstIdx -gt 0) { @($lines[0..($firstIdx - 1)]) } else { @() }
    while ($head.Count -gt 0 -and $head[-1].Trim() -eq '') { $head = @($head[0..($head.Count - 2)]) }

    # Each section runs from its own heading to the next heading, or to the end of the file for the
    # second one. Computed from the two indices rather than assuming which is which.
    $prFrom = $prIdx + 1
    $prTo   = if ($prIdx -eq $firstIdx) { $secondIdx - 1 } else { $lines.Count - 1 }
    $prBody = if ($prFrom -le $prTo) { @($lines[$prFrom..$prTo]) } else { @() }
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

    $relFrom = $relIdx + 1
    $relTo   = if ($relIdx -eq $firstIdx) { $secondIdx - 1 } else { $lines.Count - 1 }
    $relBody = if ($relFrom -le $relTo) { @($lines[$relFrom..$relTo]) } else { @() }
    $relFirst = -1
    for ($i = 0; $i -lt $relBody.Count; $i++) { if ($relBody[$i] -match '^###\s') { $relFirst = $i; break } }
    $relIntroLines = if ($relFirst -gt 0) { @($relBody[0..($relFirst - 1)]) } elseif ($relFirst -eq 0) { @() } else { $relBody }
    $existingReleases = if ($relFirst -ge 0) { @($relBody[$relFirst..($relBody.Count - 1)]) } else { @() }

    return [pscustomobject]@{
        Nl               = $nl
        Head             = $head
        PrIntro          = $prIntro
        Entries          = $entries
        RelIntroLines    = $relIntroLines
        ExistingReleases = $existingReleases
        ReleasesFirst    = $releasesFirst
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

        $LiveMarker (optional, #417) is the "this is the version currently live" suffix some repos
        keep on the newest release row. Given, it is STRIPPED from wherever it currently sits and
        appended to the new block's heading -- moving it, which is the only correct behaviour for a
        marker that means "the live one". Empty (the default, and this workshop's setting), the
        marker is neither written nor stripped and the output is byte-for-byte what it always was.
        Repo-owned because the answer is a property of the repo: a marketplace has no live stage,
        a theme repo pushing to a live storefront does.

        $HistoryMode (August 4, 2026) decides whether this section accumulates:

          'all'    -- every release keeps a block, under '## Releases'. The behaviour since the start,
                      and the default, so a consumer that never sets it sees no change.
          'latest' -- only the newest release keeps a block, under '## Latest Release', followed by a
                      pointer to wherever the repo keeps its full list ($HistoryRelPath).

        The measured reason for 'latest' being wanted at all: in this workshop the accumulating section
        had grown to 434 of the changelog's 1,062 lines -- 41% -- across 72 blocks that each said no more
        than "see the notes". Every one of those 72 versions was ALSO listed in releases/README.md, with a
        date, a type and a descriptive title: the same coverage, checked in both directions, and richer
        per row. So the section was not a long list but a poorer copy of a better one.
    #>
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date,
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][string]$NotesRelPath,
        [string]$LiveMarker = '',
        [ValidateSet('all', 'latest')][string]$HistoryMode = 'all',
        [string]$HistoryRelPath = 'releases/README.md'
    )
    $emDash = [char]0x2014
    if ($LiveMarker) {
        # Escaped, then applied to the whole document: the marker sits on the previous release's
        # heading, which lives in $s.ExistingReleases after the split, and stripping it there rather
        # than before would mean re-parsing a list this function only passes through.
        $Content = [regex]::Replace($Content, '[ \t]*' + [regex]::Escape($LiveMarker), '')
    }
    $s = Split-Changelog -Content $Content
    $nl = $s.Nl

    $liveSuffix = if ($LiveMarker) { " $LiveMarker" } else { '' }
    if ($HistoryMode -eq 'latest') {
        # NO '###' HEADING IN THIS MODE, deliberately: under a section that holds exactly one release by
        # definition, a per-version heading names what the heading above it already said. The version
        # moves onto a bold line instead, which reads the same and stops the document from carrying an
        # empty level of structure.
        #
        # Set-ReleaseInternalNoteLink recognises BOTH shapes for this reason -- the heading in 'all'
        # mode, this line in 'latest' -- so the two functions cannot disagree about where a release
        # block starts.
        $block = @(
            "**v$Version** $emDash $Date $emDash $Type$liveSuffix",
            '',
            "See [$NotesRelPath]($NotesRelPath) for the full release notes."
        )
    } else {
        $block = @(
            "### [v$Version] - $Date $emDash $Type$liveSuffix",
            '',
            "See [$NotesRelPath]($NotesRelPath) for the full release notes."
        )
    }

    if ($HistoryMode -eq 'latest') {
        # Written fresh every cut rather than carried over: in this mode the intro's whole job is to say
        # "this is one release, the rest is over there", and a carried-over intro would still be the
        # accumulating section's wording. The pointer is the only part a repo varies, so it is the only
        # part interpolated.
        $relIntro = @(
            "The most recent release $emDash every earlier one is listed in",
            "[$HistoryRelPath]($HistoryRelPath), with its date, type and title."
        )
    } elseif (($s.RelIntroLines -join "`n") -match 'No releases recorded') {
        $relIntro = @(
            "The recorded versions of the marketplace $emDash newest at the top. Every release bumps all",
            'plugin versions in lockstep and points to the full notes in `releases/development/`.'
        )
    } else {
        $relIntro = @($s.RelIntroLines | Where-Object { $_ -ne '' })
    }

    # The two sections, each built once, then emitted in the order the document already had. Building
    # them separately is what makes the order a single decision at the end rather than two divergent
    # code paths that have to be kept saying the same thing.
    $prSection = @()
    $prSection += '## Pull Requests'
    $prSection += ''
    $prSection += ($s.PrIntro | Where-Object { $_ -ne '' })

    $relSection = @()
    $relSection += $(if ($HistoryMode -eq 'latest') { '## Latest Release' } else { '## Releases' })
    $relSection += ''
    $relSection += $relIntro
    $relSection += ''
    $relSection += $block
    # In 'latest' mode the previous blocks are dropped rather than pushed down -- that IS the mode. They
    # are not lost: the repo's history file carries every one of them, which is the precondition for
    # turning this on at all.
    if ($HistoryMode -ne 'latest' -and $s.ExistingReleases.Count -gt 0) {
        $relSection += ''
        $relSection += '---'
        $relSection += ''
        $relSection += $s.ExistingReleases
    }

    # $s.Head is everything above the first of the two headings, so it no longer carries either of them
    # -- both are written here, which is what lets the order be chosen rather than inherited.
    $out = @()
    $out += $s.Head
    $out += ''
    if ($s.ReleasesFirst) {
        $out += $relSection
        $out += ''
        $out += $prSection
    } else {
        $out += $prSection
        $out += ''
        $out += $relSection
    }

    return (($out -join $nl).TrimEnd() + $nl)
}

function Set-ReleaseInternalNoteLink {
    <#
        Point the changelog's release block for $Version at the INTERNAL note, keeping the developer
        notes as a secondary reference. Pure string in/out, and idempotent: run twice and the second
        call changes nothing.

        WHY THIS IS A SEPARATE STEP RATHER THAN PART OF THE CUT (August 4, 2026). The internal note does
        not exist when cut-release.ps1 writes the changelog: that script commits AND tags in one motion,
        while the internal note needs the developer notes as its input and is therefore written
        afterwards, by hand, landing through a branch + PR. A cut that linked straight to it would put a
        DEAD RELATIVE LINK inside the release tag -- caught by the lint gate's dead-link scan, and
        uncorrectable afterwards because the tag is immutable. Generating an empty skeleton at cut time
        was considered and rejected earlier for the mirror-image reason: that puts an empty document
        inside the tag instead.

        So the cut writes the developer link, which always exists, and new-internal-note.ps1 calls this
        the moment the real note is created -- in the same PR that adds it, so the two never disagree.

        Returns the content unchanged (no throw) when the block or its notes line cannot be found: this
        runs after a successful release, and failing there would make a completed release look broken
        over a cosmetic line. The caller reports what happened.
    #>
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$InternalRelPath,
        [Parameter(Mandatory)][string]$DevRelPath
    )

    $usesCRLF = $Content.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }
    $lines = $Content -split "`r?`n"

    # Find the block for this version, then the first notes line under it. Anchored on the version so a
    # changelog in 'all' mode -- where several blocks sit under one another -- cannot have an older block
    # rewritten by a call meant for the newest.
    #
    # BOTH BLOCK SHAPES are matched: the '### [vX.Y.Z]' heading that 'all' mode writes, and the bold
    # '**vX.Y.Z**' line that 'latest' mode writes instead (a section holding exactly one release needs no
    # per-version heading). One function reading both is what keeps this in step with
    # Convert-ChangelogForRelease rather than needing to be told which mode produced the file.
    $v = [regex]::Escape($Version)
    $headingRx = '^(###\s+\[v' + $v + '\]|\*\*v' + $v + '\*\*)'
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match $headingRx) { $start = $i; break } }
    if ($start -lt 0) { return $Content }

    $replacement = "See [$InternalRelPath]($InternalRelPath) for what this release is worth. The full per-PR record is in [$DevRelPath]($DevRelPath)."

    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        # Stop at the next block or section rather than running to the end of the file: a notes line
        # belonging to the NEXT release must not be rewritten with this version's paths.
        if ($lines[$i] -match '^#{2,3}\s' -or $lines[$i] -match '^---\s*$') { break }
        if ($lines[$i] -eq $replacement) { return $Content }   # already pointed there
        if ($lines[$i] -match '^See \[') {
            $lines[$i] = $replacement
            return (($lines -join $nl).TrimEnd() + $nl)
        }
    }
    return $Content
}

function Get-TouchedPlugins {
    <#
        Pure: derives the touched plugin names from a list of PR file paths (repo-root-relative,
        as gh pr list --json files supplies -- $Files here are already flat path strings, not the
        gh objects themselves). Only paths under plugins/<plugin>/ count. -cmatch (Sean's advice):
        -match is case-insensitive and would silently widen the lowercase character class; plugin
        folder names are always lowercase slugs. Returns a sorted, deduplicated array of plugin names
        (empty if nothing touches a plugin). Pulled out to here (#103, Victor #3) so the detection
        is separately testable, instead of inline logic in fold-changelog-entry.ps1.

        THE EXCLUDED SIBLING CHANGED WITH THE LAYOUT (#405). Under the old two-level layout the one
        non-plugin directory sitting beside the plugins was connectors/, so that was the name excluded
        here. Flattening moved connectors/ to the repo ROOT -- where it no longer matches this pattern
        at all -- and moved agent-shared/ IN, beside the plugins. So the exclusion follows the
        directory rather than the name: agent-shared is plugin SOURCE (its generator writes the shared
        blocks into plugin agent defs) but is not itself a plugin, and a release must not report it as
        one. Keeping 'connectors' here instead would have been dead code guarding nothing while the
        real sibling went uncounted.
    #>
    param([string[]]$Files = @())
    $touched = @()
    foreach ($f in $Files) {
        if ($f -cmatch '^plugins/([a-z0-9][a-z0-9-]*)/') {
            if ($Matches[1] -ne 'agent-shared' -and $touched -notcontains $Matches[1]) { $touched += $Matches[1] }
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
        [string]$RepoBlobUrl = 'https://github.com/DaveKJohn/claude-code-specialists/blob/main/'
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

        BOTH HALVES ARE REPO-OWNED, AND BOTH ARE PROBED RATHER THAN ASSUMED (#417). This lib is shared
        now, so it cannot hardcode either one:

          Order  -- from Get-BranchTypes in the consumer's own scripts/lib/branch-info.ps1, which the
                    caller has dot-sourced. Absent (release-lib loaded standalone, e.g. by its own
                    tests), it falls back to the four canonical types below.
          Title  -- from the OPTIONAL Get-ReleaseCategoryTitles in the consumer's scripts/repo-config.ps1.
                    Absent, the English map below applies, which is what this function always returned.

        The Title knob exists because a type with no label already degrades to the type name itself
        (see Format-CategorizedEntries), and for a non-English repo that is the wrong word rather than
        a missing one -- the same reason the entry-stub wording became repo-owned in #410. A consumer
        that does not define it is unaffected.

        Probed with Get-Command rather than taken as a parameter, so the four Build-* functions that
        reach this through Format-CategorizedEntries do not each have to thread two arguments they
        never look at. Same pattern as teardown.ps1's Get-RosterIdTokenPattern probe.
    #>
    $order = if (Get-Command Get-BranchTypes -ErrorAction SilentlyContinue) {
        @(Get-BranchTypes) + 'Other'
    } else {
        @('Feat', 'Fix', 'Docs', 'Chore', 'Other')
    }
    $titles = @{
        Feat  = 'Features'
        Fix   = 'Fixes'
        Docs  = 'Documentation'
        Chore = 'Maintenance'
        Other = 'Other'
    }
    if (Get-Command Get-ReleaseCategoryTitles -ErrorAction SilentlyContinue) {
        $override = Get-ReleaseCategoryTitles
        # Merged over the defaults rather than replacing them, so a repo that renames one category
        # does not have to restate the other four -- and 'Other' keeps a label whatever happens.
        if ($override) { foreach ($k in $override.Keys) { $titles[$k] = $override[$k] } }
    }
    return [pscustomobject]@{
        Order = $order
        Title = $titles
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

        $OnlyTypes restricts the output to those categories, in the canonical order; the entries of
        every other category are dropped rather than reported. Empty (the default) = every category,
        which is what this function always did. It exists for the highlights tier (#417 phase 2),
        which renders the SAME entry set twice -- the stakeholder categories in one document section
        and the remainder in another -- and must classify both halves by the one rule that already
        reads a type from a heading. Filtering the entries before the call instead would mean a second
        copy of that parsing, which is how the two halves start disagreeing about what a 'Docs' entry is.

        $BareTitles reduces each entry heading to its title (Convert-EntryHeadingToTitle) -- for the
        highlights tier, whose reader has no branch and no PR number. IT MUST HAPPEN HERE rather than
        in the caller, and that is not a style preference: the type this function groups on is read FROM
        that heading, so a caller that stripped it first would hand over entries whose type is gone and
        get one undifferentiated 'Other' pile. Measured, not reasoned about -- the first version of the
        highlights builder did exactly that and every category collapsed into Other.
    #>
    param(
        [Parameter(Mandatory)][string[]]$Entries,
        [int]$CategoryLevel = 2,
        [string[]]$OnlyTypes = @(),
        [switch]$BareTitles
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
        # The type has been read by now, so reducing the heading is safe from here on.
        $text = if ($BareTitles) { Convert-EntryHeadingToTitle -EntryText $e } else { $e }
        $grouped[$t].Add(($text.Trim() -replace "`r`n", "`n"))
    }

    $sections = @()
    foreach ($cat in $cats.Order) {
        if ($OnlyTypes.Count -gt 0 -and $OnlyTypes -notcontains $cat) { continue }
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

function Build-PluginChangelogIntro {
    <#
        The intro header of a per-plugin CHANGELOG: the title plus the paragraph saying what the file
        is and where the full history lives. Pure string in/out.

        ITS OWN FUNCTION BECAUSE THIS TEXT IS WRITE-ONCE, AND WRITE-ONCE TEXT DRIFTS SILENTLY.
        Add-PluginChangelogSection emits it only when the CHANGELOG does not exist yet, so an
        existing file's intro is never rewritten -- editing the template below reaches future
        plugins and no current one. Measured August 3, 2026: after the rename swept the old
        marketplace name out of 59 files, all four per-plugin CHANGELOGs still opened by naming it,
        because their intro had been written once at creation and no gate looked at it. Check 17 in
        check-plugin-integrity.ps1 now holds those files against THIS function, which is only
        trustworthy while the text has exactly one source -- hence the extraction.

        $MarketplaceName is a parameter rather than a literal for the same reason one level up: the
        name's authority is 'name' in .claude-plugin/marketplace.json, and a copy of it here is a
        copy that can go stale. The caller reads it there and passes it; the gate reads the same
        field, so the two agree by construction instead of by upkeep.
    #>
    param(
        [Parameter(Mandatory)][string]$PluginName,
        [Parameter(Mandatory)][string]$MarketplaceName
    )
    $emDash = [char]0x2014
    return "# Changelog $emDash $PluginName`n`n" +
        "Consumer-facing history of this plugin: per release, the changes that touched this`n" +
        "plugin. Automatically appended by ``cut-release.ps1`` of the marketplace repo`n" +
        "($MarketplaceName); the full repository history lives there in ``CHANGELOG.md`` and`n" +
        "``releases/``.`n`n"
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
        [Parameter(Mandatory)][string]$PluginName,
        [Parameter(Mandatory)][string]$MarketplaceName
    )
    if (-not $Existing) {
        $intro = Build-PluginChangelogIntro -PluginName $PluginName -MarketplaceName $MarketplaceName
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
        [string]$RepoBlobUrl = 'https://github.com/DaveKJohn/claude-code-specialists/blob/main/'
    )
    $majorDir = ($Version -split '\.')[0] + '.x'
    $notesRelPath = "releases/development/$majorDir/$Version.md"
    $notesUrl = "$RepoBlobUrl$notesRelPath"

    # WHAT THE CARD CAN KNOW, AND WHAT IT CANNOT (inbound #384). This line used to read "You are on
    # this release." -- written at cut time, about a reader the card has never met. Round v13 measured
    # it false in the ordinary case: the payload came from `main`, three commits past the tag whose
    # number the card and plugin.json both carried. And it contradicted the reader's own correct
    # conclusion, because the adoption page's tag comparison had just told them they were on `main` and
    # not on the release. So the card now states what it describes and hands the "where am I" question
    # to the check that can answer it.
    #
    # ADOPTION.md, not QUICKSTART.md: the page was renamed on August 3, 2026 (inbound #408) and the
    # detailed "Staying up to date" section went with it. QUICKSTART.md still exists and still carries
    # that anchor, deliberately -- the archived release notes and the older per-plugin CHANGELOGs link
    # to it and are not rewritten -- but a card generated from here points at the page that holds the
    # measurement.
    $backtick = [char]0x60
    $adoptionUrl = $RepoBlobUrl + 'ADOPTION.md#staying-up-to-date'
    $mainRef = "$backtick" + 'main' + "$backtick"
    $titleLine = if ($Title) { "$Title`n`n" } else { '' }
    $header = "# Release v$Version`n`n" +
        "**Date:** $Date  `n**Type:** $Type`n`n" +
        "${titleLine}This card describes v$Version, the version your plugin manifest carries. Whether it is " +
        "the code you are running is a separate question: the documented update path installs from $mainRef, " +
        "so a $mainRef that has moved past the tag reports this same number. " +
        "[The version is not the code]($adoptionUrl) in ADOPTION.md is the check.`n`n"

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

function Get-OverviewTargetMajor {
    <# Which '### <n>.x' section of releases/README.md a new row would land in, or $null when the
       overview carries no table at all. Pure string in, string out.

       WHY THIS EXISTS. The row inserter finds the FIRST '| Version | Date | Type | Title |' header and
       inserts directly after it -- correct for every minor and patch, because the current major's table
       sits at the top. A NEW MAJOR has no table yet, so its row lands under the PREVIOUS major's
       heading: a v3.0.0 row filed under '### 2.x'. Not a crash -- a quietly wrong overview, in the one
       document whose whole job is to say which release is which.

       Never caught before because it cannot have been: the grouping-by-major was introduced in v2.0.1,
       one release AFTER the only major this repo ever cut. So a major has never met this structure.

       The answer is the LAST section heading before the first table header, not simply the first
       heading in the file: that is precisely the section the inserter will write into, and deriving it
       any other way would be a second, drifting definition of the same thing. #>
    param([Parameter(Mandatory)][string]$ReadmeContent)
    $headerRe = [regex]"(?m)^\| Version \| Date \| Type \| Title \|\r?\n\|[-| ]+\|\r?\n"
    $hm = $headerRe.Match($ReadmeContent)
    if (-not $hm.Success) { return $null }
    $before = $ReadmeContent.Substring(0, $hm.Index)
    $sections = [regex]::Matches($before, '(?m)^###\s+(\d+)\.x\s*$')
    if ($sections.Count -eq 0) { return $null }
    return $sections[$sections.Count - 1].Groups[1].Value
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

# ==================================================================================================
# THE HIGHLIGHTS TIER (#417 phase 2)
# ==================================================================================================
#
# A SECOND, STAKEHOLDER-FACING RENDERING OF THE SAME RELEASE -- not a second changelog. The tier was
# built in a consumer repo and stayed there while cut-release.ps1 was two files; phase 1 shared the
# script, this is the half that was still missing. The rule it carries is older than the sharing
# (Dave, July 13, 2026): HIGHLIGHTS IS WRITTEN FOR NON-DEVELOPERS. So the generated document puts the
# stakeholder categories first and the remainder under an explicit "remove before publishing" marker.
#
# THE TOOL MARKS THE CUT, IT DOES NOT MAKE IT. What a stakeholder should read is an editorial
# judgement, and a generator that silently dropped the developer half would be making that judgement
# on the release manager's behalf -- while also hiding the fact that there was anything to decide. So
# the block is written out, labelled, and left to be deleted by hand.
#
# ONE DELIBERATE DIFFERENCE FROM THE SOURCE THIS WAS PORTED FROM: there, both halves render their
# categories at '##', which puts the developer categories at the same level as the marker heading that
# is supposed to contain them -- so the block reads as ended rather than as nested. Here the marker sits
# at '##' and its categories one level under it, which is what Format-CategorizedEntries's
# -CategoryLevel was already for. The consumer's generated highlights therefore gain a level of nesting
# they did not have; nothing else about them changes.
#
# MARKDOWN ONLY -- THE TIER PRODUCES NO HTML, AND THAT IS A DECISION RATHER THAN AN OMISSION (Dave,
# August 3, 2026, the same day it was ported). The source generated a self-contained, print-ready
# .html beside the .md, and ConvertTo-ReleaseHtml + Format-InlineMarkdown were ported with it and then
# removed the same day: it is not wanted anywhere. The renderer was also the weakest part of the port --
# a partial markdown subset that passed links through as literal '[text](url)' -- so the thing that
# needed the most explaining is now simply gone. A reader who wants a PDF renders the markdown with a
# tool built for it. Do not reintroduce an HTML step here without asking.

function Convert-EntryHeadingToTitle {
    <#
        Reduces a folded entry's heading to its bare title: '### #426 <md> Some title <md> Feat <md>
        2026-08-03' -> '### Some title'. Pure string in, string out; a heading that does not carry the
        metadata shape is returned unchanged.

        FOR THE HIGHLIGHTS TIER ONLY, and that is the whole reason it exists as a separate function
        rather than an option on the renderers. The PR number, the branch type and the merge date are
        internal administration: precise, useful in the developer notes, and noise in a document whose
        reader does not have a branch. The developer notes keep them, so this never runs there.

        The trailing two middot fields (type, date) and a leading '#NN' field are dropped; everything
        between them is the title and is rejoined with the middot, so a title that legitimately
        contains one survives. Only the FIRST line is touched -- the body may contain anything.
    #>
    param([Parameter(Mandatory)][string]$EntryText)
    $md = [char]0x00B7
    $lines = $EntryText -split "(`r?`n)", 2
    $heading = $lines[0]
    $hm = [regex]::Match($heading, '^(#+)\s+(.*)$')
    if (-not $hm.Success) { return $EntryText }

    $parts = @($hm.Groups[2].Value -split "\s*$md\s*")
    # Fewer than three fields means there is no (title, type, date) triple to strip -- leave it alone
    # rather than guess which of the two remaining fields was the title.
    if ($parts.Count -lt 3) { return $EntryText }
    $first = if ($parts[0] -match '^#\d+$') { 1 } else { 0 }
    $last = $parts.Count - 3
    if ($last -lt $first) { return $EntryText }
    $title = (@($parts[$first..$last]) -join " $md ").Trim()
    if (-not $title) { return $EntryText }

    $rest = if ($lines.Count -gt 1) { ($lines[1] + $lines[2]) } else { '' }
    return "$($hm.Groups[1].Value) $title$rest"
}

function Build-HighlightsNotes {
    <#
        Builds the highlights document (releases/highlights/<dir>/<X.Y.Z>.md) from the same entry
        blocks the developer notes are built from. Pure string out, hard LF -- a new standalone file,
        like Build-ReleaseNotes.

        $StakeholderTypes names the branch types a non-developer reader is the audience for; every
        OTHER category present lands in the developer-only block below the marker. Empty = every
        category is stakeholder-facing, so no marker block is written at all (a repo that wants the
        second document but not the split).

        $DevBlockComment and $DevBlockHeading are the consumer's own words for that marker -- the
        #410 class: a document written for this repo's stakeholders is written in their language, and
        a hardcoded English heading in a Dutch release note is the wrong word rather than a missing
        one.

        The entries arrive with their internal heading metadata intact and keep it until the renderer
        has read the type off it -- hence -BareTitles on Format-CategorizedEntries rather than a strip
        pass here; see that function for what stripping too early costs. Links are rewritten first, at
        the same depth the developer notes use (both documents sit three folders down).
    #>
    param(
        [Parameter(Mandatory)][string[]]$Entries,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date,
        [Parameter(Mandatory)][string]$Type,
        [string]$Title = '',
        [string[]]$StakeholderTypes = @(),
        [string]$DevBlockComment = 'Remove this block before sharing the highlights with non-developers.',
        [string]$DevBlockHeading = 'For developers only -- remove before publishing',
        [string]$LinkPrefix = '../../../'
    )
    $linked = @($Entries | ForEach-Object { Convert-RootRelativeLinks -EntryText $_ -Prefix $LinkPrefix })

    if ($StakeholderTypes.Count -gt 0) {
        $stake = Format-CategorizedEntries -Entries $linked -CategoryLevel 2 -OnlyTypes $StakeholderTypes -BareTitles
        # The developer half is "everything not named", derived rather than configured: a branch type
        # added later is then stakeholder-facing only if somebody says so, and shows up in the block
        # that gets reviewed either way. The reverse default would hide it.
        $cats = Get-ReleaseCategories
        $devTypes = @($cats.Order | Where-Object { $StakeholderTypes -notcontains $_ })
        $dev = Format-CategorizedEntries -Entries $linked -CategoryLevel 3 -OnlyTypes $devTypes -BareTitles
    } else {
        $stake = Format-CategorizedEntries -Entries $linked -CategoryLevel 2 -BareTitles
        $dev = ''
    }

    $rocket = [char]::ConvertFromUtf32(0x1F680)
    $titleLine = if ($Title) { "$Title`n`n" } else { '' }
    $header = "# Release notes v$Version $rocket`n`n**Date:** $Date  `n**Type:** $Type`n`n$titleLine"

    if ($dev.Trim()) {
        $marker = "<!-- $DevBlockComment -->`n## $DevBlockHeading"
        $body = if ($stake.Trim()) { "$stake`n`n---`n`n$marker`n`n$dev" } else { "$marker`n`n$dev" }
    } else {
        $body = $stake
    }
    return ($header + $body + "`n")
}
