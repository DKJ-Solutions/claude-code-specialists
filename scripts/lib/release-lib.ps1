<#
.SYNOPSIS
    Pure release helpers (version determination + CHANGELOG transformation + release-notes
    building), separate from git/filesystem orchestration.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

    Supplies Get-NextVersion, Get-BumpType, Get-LockstepVersion, Get-PluginManifestPaths,
    Get-PullRequestEntries, Get-PullRequestEntriesByTier, Convert-ChangelogForRelease,
    Build-ReleaseNotes, Get-ReleaseTierHeading, Test-ReleaseBumpEarned, and for the
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
    Releases). Every tier section is emptied down to its intro in the process.

    THE TIER MODEL (August 5, 2026). CHANGELOG.md holds ONE ENTRY SECTION PER TIER -- how far a change
    reaches, declared per entry on the branch and stated by the section once folded. Three things follow
    from it here: Split-Changelog parses N sections instead of one, Build-ReleaseNotes groups by tier
    before it groups by category, and Test-ReleaseBumpEarned answers whether the pending tiers justify
    the bump somebody is asking for. A repo with no tier split declares a single section and travels
    every one of those paths as a one-tier case, so there is no second model to maintain.

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

# The changelog's TIER SECTIONS (the tier model, August 5, 2026): Get-ChangelogTierSections, and with it
# Resolve-EntryTier for a caller that still needs to read a raw entry. Unlike branch-info above, this
# sibling is NOT repo-owned -- it travels in the same mirror as this file -- so the dot-source is
# unconditional in every location it can run from.
#
# WHY THE SECTIONS LIVE THERE AND NOT HERE. The fold needs the same answer, and it reaches this lib only
# where the repo happens to have a copy in its own root (see that script's guarded dot-source), while it
# always has entry-scaffold-lib. Putting the map here would have meant two definitions of one fact -- the
# exact thing this repo keeps repairing -- so the map went to the lib both scripts can reach and this one
# reads it from there.
. (Join-Path $PSScriptRoot 'entry-scaffold-lib.ps1')

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

function Test-ReleaseBumpEarned {
    <#
        Pure: does the pending work justify the bump being asked for? Returns an object with

          Earned          $true when the bump may be cut
          EarnedBump      the bump the pending tiers WARRANT: 'minor', 'patch', or $null when nothing
                          may be released at all. Never 'major' -- see below.
          MajorAvailable  $true when this major line has had enough minors for a major to be allowed
          Reason          why not, ready to print; '' when Earned
          Counts          tier -> number of pending entries, for the message
          Active          $false when this repo declares no tier split, so nothing was judged

        EarnedBump DELIBERATELY NEVER SAYS 'major', even when one would be permitted. The pending
        entries cannot warrant a major -- what earns it is the ten minors behind it, which is a
        milestone somebody decides to mark rather than a size the work adds up to. Reporting 'major'
        as the bump this work warrants would nudge a routine tier-1 change into one. So the two facts
        are reported separately: what the work warrants, and whether a major is available at all.

        THE RULES (Dave, August 5, 2026), and each answers a question the version number was already
        supposed to answer but nothing enforced:

          any release   at least one entry of tier 1 or higher. A release consisting entirely of
                        repo-internal work has nobody to announce it to -- and cutting one spends a
                        version number, a tag and three documents on that.
          minor         at least one TIER-2 entry. "A minor is cut when a consumer actually notices
                        something" was already the written rule here; this makes the entries prove it,
                        which also means the highlights document always has a reader by construction.
          major         at least $MinMinorsForMajor minors cut in the current major line, on top of the
                        general minimum. A major is a RECAP of those minors, so what earns it is their
                        accumulation rather than any single pending change -- which is why a tier-2 entry
                        is deliberately NOT required here. Read off the minor component of
                        $CurrentVersion: within major 3 the minors are 3.1 .. 3.10, so the component IS
                        the count of minors cut in that line.

        OFF WHEN THE REPO HAS NO TIER SPLIT, and that is what keeps this safe to share. A repo with one
        entry section has no tier information at all, so every entry reads as tier 0 and a gate would
        refuse every release it ever cuts -- a shared script silently imposing a model the repo never
        adopted. One declared tier therefore means "not applicable" rather than "nothing qualifies".
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('major', 'minor', 'patch')][string]$BumpType,
        # Array of objects with Tier and Entries -- what Get-PullRequestEntriesByTier returns.
        [AllowEmptyCollection()]$TierGroups = @(),
        [Parameter(Mandatory)][string]$CurrentVersion,
        [int]$MinMinorsForMajor = 10
    )
    $groups = @($TierGroups)
    $counts = @{}
    foreach ($g in $groups) { $counts[[int]$g.Tier] = @($g.Entries | Where-Object { $_ -and $_.Trim() }).Count }

    $result = [pscustomobject]@{
        Earned         = $true
        EarnedBump     = $BumpType
        MajorAvailable = $false
        Reason         = ''
        Counts         = $counts
        Active         = ($groups.Count -gt 1)
    }
    if (-not $result.Active) { return $result }

    $notable = 0
    foreach ($tier in $counts.Keys) { if ($tier -ge 1) { $notable += $counts[$tier] } }
    $consumerFacing = if ($counts.ContainsKey(2)) { $counts[2] } else { 0 }

    if ($CurrentVersion -notmatch '^\d+\.(\d+)\.\d+$') { throw "CurrentVersion '$CurrentVersion' is not X.Y.Z." }
    $minorsSoFar = [int]$Matches[1]

    # What the pending set warrants, computed once and reported whether or not it matches what was asked
    # -- so a refusal can name the bump that WOULD work instead of only what will not.
    $result.MajorAvailable = ($minorsSoFar -ge $MinMinorsForMajor)
    $result.EarnedBump = if ($notable -eq 0) {
        $null
    } elseif ($consumerFacing -gt 0) {
        'minor'
    } else {
        'patch'
    }

    $tier0 = if ($counts.ContainsKey(0)) { $counts[0] } else { 0 }
    if ($notable -eq 0) {
        $result.Earned = $false
        $result.Reason = "nothing pending reaches beyond this repo: $tier0 entry/entries, all tier 0. A release needs at least one tier-1 entry (something a colleague on this project gets out of it) or a tier-2 one (something a consumer notices)."
        return $result
    }
    if ($BumpType -eq 'minor' -and $consumerFacing -eq 0) {
        $result.Earned = $false
        $result.Reason = "a minor is what a consumer notices, and nothing pending is tier 2 ($notable tier-1 entry/entries, $tier0 tier-0). Cut a patch, or raise the tier of the entry that a consumer does notice."
        return $result
    }
    if ($BumpType -eq 'major' -and $minorsSoFar -lt $MinMinorsForMajor) {
        $result.Earned = $false
        $result.Reason = "a major recaps the minors before it, and this major line has had $minorsSoFar of them (v$CurrentVersion) -- $MinMinorsForMajor is the threshold. Cut the minor this work earns instead."
        return $result
    }
    return $result
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

function Split-EntryBlocks {
    <#
        Private helper: turns the lines of one entry section into entry blocks. A new block starts at
        every '### ' heading; '---' separators between entries are skipped.

        BOTH of those tests must ignore FENCED CODE BLOCKS. An entry body may legitimately quote markdown
        -- a broken heading structure, a YAML frontmatter example -- and without fence awareness the
        parser reads that quoted text as structure. Measured while cutting v2.13.3: an entry that quoted
        a '### #242 ...' line inside a ``` fence produced a THIRD entry from two PRs, split the fence
        open, and duplicated '## Fixes' in the generated notes. Caught by -NoPush before it shipped.
        Fourth instance of the same defect class in one day (#227, #235, and the teardown's VUL-IN test):
        a matcher satisfied by a MENTION rather than a use.

        Pulled out of Split-Changelog when the changelog gained one section per tier: the same splitting
        now runs once per section, and a copy per section is how the fence handling starts differing
        between tiers.
    #>
    param(
        [AllowEmptyCollection()][string[]]$Lines = @(),
        [Parameter(Mandatory)][string]$Nl
    )
    $fenced = Get-FencedLineFlags -Lines $Lines
    $entries = @()
    $cur = $null
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $ln = $Lines[$i]
        if ((-not $fenced[$i]) -and $ln -match '^###\s') {
            if ($null -ne $cur) { $entries += (($cur -join $Nl).Trim()) }
            $cur = @($ln)
        } elseif ($null -ne $cur) {
            if ((-not $fenced[$i]) -and $ln -match '^---\s*$') { continue }
            $cur += $ln
        }
    }
    if ($null -ne $cur) { $entries += (($cur -join $Nl).Trim()) }
    return @($entries)
}

function Split-Changelog {
    <#
        Private helper: parses CHANGELOG.md into its parts. Returns an object with

          Nl                the newline style the document uses
          Head              everything above the first section heading -- title and intro
          TierSections      one object per entry section found, IN DOCUMENT ORDER: Tier, Heading,
                            Intro (lines), Entries (blocks), Index (the heading's line number)
          Entries           every entry block, all sections concatenated in document order
          RelIntroLines     the release section's intro
          ExistingReleases  the release blocks already there
          ReleaseIndex      the release heading's line number
          ReleasesFirst     $true when the release section comes before the first entry section

        Throws if the release section is missing, if no entry section is found, or if no section holds
        an entry to release.

        ONE SECTION PER TIER (the tier model, August 5, 2026). This used to parse exactly two sections
        -- '## Pull Requests' and the release block -- and the generalisation is deliberately to N entry
        sections rather than to three: which sections exist is the repo's answer (Get-ChangelogTierSections),
        a repo with no tier split declares one, and that single-section case is then this same code path
        rather than a legacy branch beside it.

        WHICH HEADINGS COUNT IS READ FROM THE SEAM, NOT MATCHED BY SHAPE. A heading regex like
        '^##\s+Tier \d' would have been shorter and would have quietly disagreed with the fold the first
        time a repo named its sections anything else -- and the fold is what put the entries there.
    #>
    param(
        [Parameter(Mandatory)][string]$Content,
        # The tier sections to look for. Omitted, they come from the seam via Get-ChangelogTierSections
        # -- the same pattern Get-ReleaseCategories uses for Get-BranchTypes, and the same reason: every
        # real caller has dot-sourced the consumer's repo-config already, while a test wants to state its
        # own sections without defining seam functions.
        $TierSections = $null
    )

    $usesCRLF = $Content.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }
    $lines = $Content -split "`r?`n"

    if (-not $TierSections) { $TierSections = @(Get-ChangelogTierSections) }
    $TierSections = @($TierSections)

    # BOTH release headings are recognised, and that is a migration guarantee rather than leniency.
    # A repo that switches Get-ReleaseHistoryMode to 'latest' still has '## Releases' in its changelog
    # until the next cut rewrites it -- and the throw below is fatal, so a reader that knew only the new
    # spelling would break every consumer at the one moment it is hardest to debug. Same shape as the
    # legacy slot heading in check-consumer-drift: recognise both, write one.
    $relIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+(Releases|Latest Release)\s*$') { $relIdx = $i }
    }
    if ($relIdx -lt 0) { throw "Could not find '## Releases' or '## Latest Release' in CHANGELOG.md." }

    # Locate each declared entry section. A section the changelog does not have is recorded as absent
    # rather than invented: Convert-ChangelogForRelease rebuilds only what was there, so a cut never adds
    # a heading the repo has not adopted and never reorders the document.
    $found = @()
    foreach ($sec in $TierSections) {
        $pattern = '^' + [regex]::Escape($sec.Heading) + '\s*$'
        $idx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match $pattern) { $idx = $i } }
        if ($idx -ge 0) { $found += [pscustomobject]@{ Tier = [int]$sec.Tier; Heading = $sec.Heading; Index = $idx } }
    }
    if ($found.Count -eq 0) {
        $names = ($TierSections | ForEach-Object { "'$($_.Heading)'" }) -join ', '
        throw "Could not find any entry section in CHANGELOG.md -- looked for $names (from Get-ChangelogTierHeadings, or the legacy Get-ChangelogHeading, in scripts/repo-config.ps1)."
    }

    # Every section boundary, sorted: each section runs from its own heading to the next one, or to the
    # end of the file for the last. Derived from the actual line numbers rather than from an assumption
    # about which section comes first -- which is what lets the release block sit above the entries or
    # below them (both layouts are valid; see below).
    $boundaries = @(@($found | ForEach-Object { $_.Index }) + @($relIdx) | Sort-Object)
    function Get-SectionEnd {
        param([int]$HeadingIndex)
        foreach ($b in $boundaries) { if ($b -gt $HeadingIndex) { return $b - 1 } }
        return ($lines.Count - 1)
    }

    # EITHER ORDER IS VALID (August 4, 2026). This used to throw unless the release heading came after
    # Pull Requests, which was the only layout that existed while that section was an accumulating
    # archive -- an archive belongs at the bottom. Once it holds a single block the question it answers,
    # "which version is current?", belongs at the top instead. Both layouts are supported rather than
    # swapped, because a consumer's changelog keeps whatever order it already has and no cut should
    # silently reorder someone's document.
    #
    # ReleasesFirst travels in the result so a caller can rebuild in the order it found, rather than
    # re-deriving it from indices it no longer has.
    $firstIdx = $boundaries[0]
    $releasesFirst = ($relIdx -eq $firstIdx)

    # Everything above the FIRST section heading is the document's own head -- title and intro.
    #
    # TRAILING BLANKS ARE STRIPPED, and that is a correctness fix rather than tidiness. The head as read
    # ends with the blank line separating it from the heading; Convert-ChangelogForRelease then adds its
    # own separator, so each cut left one more blank than the last. Measured over three consecutive cuts:
    # 2, 3, 4. It renders identically in markdown, which is exactly why it would have gone on growing --
    # nothing looks wrong until a reader opens the raw file years in.
    $head = if ($firstIdx -gt 0) { @($lines[0..($firstIdx - 1)]) } else { @() }
    while ($head.Count -gt 0 -and $head[-1].Trim() -eq '') { $head = @($head[0..($head.Count - 2)]) }

    $tierResult = @()
    $allEntries = @()
    foreach ($sec in ($found | Sort-Object Index)) {
        $from = $sec.Index + 1
        $to = Get-SectionEnd -HeadingIndex $sec.Index
        $body = if ($from -le $to) { @($lines[$from..$to]) } else { @() }

        # Fence-aware here too: a '###' quoted inside a fence in the section intro would otherwise be
        # read as the first entry, putting the intro/entries boundary in the middle of a code block.
        $bodyFenced = Get-FencedLineFlags -Lines $body
        $firstEntry = -1
        for ($i = 0; $i -lt $body.Count; $i++) { if ((-not $bodyFenced[$i]) -and $body[$i] -match '^###\s') { $firstEntry = $i; break } }

        $intro = if ($firstEntry -gt 0) { @($body[0..($firstEntry - 1)]) } elseif ($firstEntry -eq 0) { @() } else { $body }
        $entryLines = if ($firstEntry -ge 0) { @($body[$firstEntry..($body.Count - 1)])  } else { @() }
        $entries = @(Split-EntryBlocks -Lines $entryLines -Nl $nl)

        $tierResult += [pscustomobject]@{
            Tier    = $sec.Tier
            Heading = $sec.Heading
            Index   = $sec.Index
            Intro   = @($intro)
            Entries = $entries
        }
        $allEntries += $entries
    }

    # AN EMPTY TIER SECTION IS NORMAL; ALL OF THEM EMPTY IS NOT. Most releases have nothing pending in at
    # least one tier -- that is the model working, not a defect -- so the throw is on the total. It stays
    # fatal because a cut with no entries produces a release note describing nothing.
    if ($allEntries.Count -eq 0) {
        throw "No changelog entries in any tier section of CHANGELOG.md -- nothing to release."
    }

    $relFrom = $relIdx + 1
    $relTo   = Get-SectionEnd -HeadingIndex $relIdx
    $relBody = if ($relFrom -le $relTo) { @($lines[$relFrom..$relTo]) } else { @() }
    $relFirst = -1
    for ($i = 0; $i -lt $relBody.Count; $i++) { if ($relBody[$i] -match '^###\s') { $relFirst = $i; break } }
    $relIntroLines = if ($relFirst -gt 0) { @($relBody[0..($relFirst - 1)]) } elseif ($relFirst -eq 0) { @() } else { $relBody }
    $existingReleases = if ($relFirst -ge 0) { @($relBody[$relFirst..($relBody.Count - 1)]) } else { @() }

    return [pscustomobject]@{
        Nl               = $nl
        Head             = $head
        TierSections     = $tierResult
        Entries          = @($allEntries)
        RelIntroLines    = $relIntroLines
        ExistingReleases = $existingReleases
        ReleaseIndex     = $relIdx
        ReleasesFirst    = $releasesFirst
    }
}

function Get-PullRequestEntries {
    <# Returns the entry blocks to be released (### ... + body + PR link), every tier section
       concatenated in document order. Use Get-PullRequestEntriesByTier where the tier matters. #>
    param(
        [Parameter(Mandatory)][string]$Content,
        $TierSections = $null
    )
    return @((Split-Changelog -Content $Content -TierSections $TierSections).Entries)
}

function Get-PullRequestEntriesByTier {
    <#
        The pending entries PER TIER, in document order: an array of objects with Tier, Heading and
        Entries. Its own function beside the flat Get-PullRequestEntries because the two callers want
        genuinely different things and neither should derive the other:

          the flat list  -- the per-plugin CHANGELOGs and the RELEASE.md cards, which select on the
                            'Plugins:' line and do not care how far a change reaches;
          per tier       -- the release notes (grouped by tier), the highlights (tier 2 only) and the
                            cut's bump gate (which tiers are pending at all).

        Deriving the tier from the entries themselves is impossible on purpose: the fold removes the
        'Tier:' line once the section states the tier, so the section IS the answer.
    #>
    param(
        [Parameter(Mandatory)][string]$Content,
        $TierSections = $null
    )
    return @((Split-Changelog -Content $Content -TierSections $TierSections).TierSections)
}

# --- The release block's wording in the repo's own CHANGELOG.md (inbound #462) --------------------
#
# The four strings a release writes into a file the REPO owns. They were hardcoded English here, which
# is right for an English repo and wrong for any other -- and the changelog block is the most visible
# output of the lot, sitting at the top of the file. Exactly the #410 class this repo has now solved
# three times over: the entry stubs (Get-Entry*), the internal note (Get-InternalNoteWording) and the
# category labels (Get-ReleaseCategoryTitles) are all repo-owned for this reason. This was the one
# output left behind, and it was left behind because it lives in a lib rather than in a script.
#
# THE DEFAULTS ARE UNCHANGED, deliberately -- the seam's whole contract is that a consumer defining
# nothing gets exactly what this repo produced before it existed, byte for byte. That includes the word
# "marketplace" in AllIntro, which is wrong for a consumer that is not one: a repo in that position
# overrides the key, and the script contract's [INFO] line names the default so it is a thing they were
# told rather than a thing they discovered at release time.
#
# TOKENS RATHER THAN INTERPOLATION, because an override is written in a config file that has none of
# these values in scope. {history} {notes} {internal} {dev} carry the paths; {emdash} carries the one
# character this pure-ASCII file cannot hold as a literal.
$script:ChangelogReleaseWordingDefaults = @{
    LatestIntro = @(
        'The most recent release {emdash} every earlier one is listed in',
        '[{history}]({history}), with its date, type and title.'
    )
    AllIntro = @(
        'The recorded versions of the marketplace {emdash} newest at the top. Every release bumps all',
        'plugin versions in lockstep and points to the full notes in `releases/development/`.'
    )
    NotesLine = @(
        'See [{notes}]({notes}) for the full release notes.'
    )
    InternalNoteLine = @(
        'See [{internal}]({internal}) for what this release is worth. The full per-PR record is in [{dev}]({dev}).'
    )
}

function Get-ChangelogReleaseWordingLines {
    <#
        One wording entry as an array of LINES: the repo's override where it has one, the English
        default otherwise, with every {token} filled in.

        An override may be written as an array of lines or as a single string containing newlines --
        both normalize to lines here, so a repo is not made to guess which shape the caller wanted.
    #>
    param(
        [Parameter(Mandatory)][string]$Key,
        [hashtable]$Wording = $null,
        [hashtable]$Tokens = @{}
    )
    $lines = $script:ChangelogReleaseWordingDefaults[$Key]
    if ($Wording -and $Wording.ContainsKey($Key) -and $Wording[$Key]) { $lines = $Wording[$Key] }
    $lines = @(@($lines) | ForEach-Object { [string]$_ -split "`r?`n" })
    foreach ($t in $Tokens.Keys) {
        $needle = '{' + $t + '}'
        $value  = [string]$Tokens[$t]
        $lines  = @($lines | ForEach-Object { $_.Replace($needle, $value) })
    }
    return $lines
}

function Convert-ChangelogForRelease {
    <#
        Empties EVERY tier section down to its own intro and puts a short REFERENCE
        '### [v<Version>] - <Date> - <Type>' at the top of '## Releases' to the release-notes file
        ($NotesRelPath). Pure string in/out.

        The sections are the ones the repo declares (Get-ChangelogTierSections, overridable via
        $TierSections for a test), and only the ones the document actually had are written back -- a cut
        neither invents a heading the repo has not adopted nor changes the order they sit in.

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
        [string]$HistoryRelPath = 'releases/README.md',
        $TierSections = $null,
        [hashtable]$Wording = $null
    )
    $emDash = [char]0x2014
    if ($LiveMarker) {
        # Escaped, then applied to the whole document: the marker sits on the previous release's
        # heading, which lives in $s.ExistingReleases after the split, and stripping it there rather
        # than before would mean re-parsing a list this function only passes through.
        $Content = [regex]::Replace($Content, '[ \t]*' + [regex]::Escape($LiveMarker), '')
    }
    $s = Split-Changelog -Content $Content -TierSections $TierSections
    $nl = $s.Nl

    $liveSuffix = if ($LiveMarker) { " $LiveMarker" } else { '' }
    # The pointer line under the release heading, from the seam (#462). Built once and used by both
    # shapes below, because the two differ in their HEADING and never in this line -- writing it twice
    # is two places for one sentence to be changed in one of them.
    $notesLines = Get-ChangelogReleaseWordingLines -Key 'NotesLine' -Wording $Wording `
        -Tokens @{ notes = $NotesRelPath; emdash = $emDash }
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
            ''
        ) + $notesLines
    } else {
        $block = @(
            "### [v$Version] - $Date $emDash $Type$liveSuffix",
            ''
        ) + $notesLines
    }

    if ($HistoryMode -eq 'latest') {
        # Written fresh every cut rather than carried over: in this mode the intro's whole job is to say
        # "this is one release, the rest is over there", and a carried-over intro would still be the
        # accumulating section's wording. The pointer is the only part a repo varies, so it is the only
        # part interpolated.
        $relIntro = Get-ChangelogReleaseWordingLines -Key 'LatestIntro' -Wording $Wording `
            -Tokens @{ history = $HistoryRelPath; emdash = $emDash }
    } elseif (($s.RelIntroLines -join "`n") -match 'No releases recorded') {
        $relIntro = Get-ChangelogReleaseWordingLines -Key 'AllIntro' -Wording $Wording `
            -Tokens @{ emdash = $emDash }
    } else {
        $relIntro = @($s.RelIntroLines | Where-Object { $_ -ne '' })
    }

    # Each section built once, then emitted in the order the document already had. Building them
    # separately is what makes the order a single decision at the end rather than divergent code paths
    # that have to be kept saying the same thing.
    #
    # ONE BLOCK PER TIER SECTION, and only for the sections that were actually there: the parser records
    # which it found, and a heading the repo has not adopted is not conjured up by a release. Each is
    # emptied down to its own intro, exactly as the single section always was -- the intro is a live
    # statement about what the section is for, the entries are what the release just consumed.
    # $sectionLines, NOT $block: $block above holds the release REFERENCE built earlier in this function,
    # and reusing the name here silently replaced it with the last tier's lines -- the changelog came out
    # with no '**vX.Y.Z** ... See [notes]' block at all and a tier section duplicated in its place.
    # Measured on the first run. Same class as the $RepoRoot/$repoRoot collision documented in
    # fold-changelog-entry.ps1, and just as invisible: the output is well-formed markdown either way.
    $prSections = @()
    foreach ($sec in $s.TierSections) {
        $sectionLines = @($sec.Heading, '')
        $sectionLines += @($sec.Intro | Where-Object { $_ -ne '' })
        $prSections += [pscustomobject]@{ Index = $sec.Index; Lines = $sectionLines }
    }

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

    # $s.Head is everything above the FIRST section heading, so it carries none of them -- every heading
    # is written here, which is what lets the order be inherited from the document rather than assumed.
    #
    # SORTED ON THE LINE NUMBER EACH SECTION WAS FOUND AT, which generalises the old two-way
    # ReleasesFirst switch: with one section per tier there is no longer a pair to swap, and the only
    # answer that cannot silently reorder somebody's changelog is the order the file already had.
    $ordered = @($prSections + @([pscustomobject]@{ Index = $s.ReleaseIndex; Lines = $relSection }) |
        Sort-Object Index)

    $out = @()
    $out += $s.Head
    foreach ($sec in $ordered) {
        $out += ''
        $out += $sec.Lines
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
        [Parameter(Mandatory)][string]$DevRelPath,
        [hashtable]$Wording = $null
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

    # From the seam like the three strings Convert-ChangelogForRelease writes (#462) -- this sentence
    # lands in the same block of the same repo-owned file, so leaving it hardcoded would have made the
    # block half-configurable, which is the worse of the two states.
    #
    # JOINED TO ONE LINE on purpose: this function REPLACES a single line and compares against it for
    # idempotence, so a multi-line override is flattened rather than quietly breaking both.
    $replacement = (Get-ChangelogReleaseWordingLines -Key 'InternalNoteLine' -Wording $Wording `
        -Tokens @{ internal = $InternalRelPath; dev = $DevRelPath; emdash = ([char]0x2014) }) -join ' '

    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        # Stop at the next block or section rather than running to the end of the file: a notes line
        # belonging to the NEXT release must not be rewritten with this version's paths.
        if ($lines[$i] -match '^#{2,3}\s' -or $lines[$i] -match '^---\s*$') { break }
        if ($lines[$i] -eq $replacement) { return $Content }   # already pointed there
        # THE LINE IS FOUND BY ITS SHAPE, NOT BY ITS WORDS. This used to anchor on '^See [', which is
        # the English default's opening -- so a repo that overrode NotesLine would have had its link
        # silently never moved, the exact failure this function's own header warns about. Inside a
        # release block the notes line is the only line carrying a markdown link, which is true in every
        # language: the heading above it has none, and the loop stops at the next block.
        if ($lines[$i] -match '\]\(') {
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

        $OnlyTypes IS GONE (August 5, 2026). It restricted the output to named categories, and it
        existed for exactly one caller: the highlights tier, which rendered the same entry set twice --
        the "stakeholder" categories in one section and the remainder under a remove-before-publishing
        marker. The tier model replaced that split with the entries' own tier declaration, so the second
        rendering, the marker and its two seam knobs all went; this parameter went with them rather than
        staying as a tested feature with no caller, which this repo has elsewhere called dead code
        guarding nothing.

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
        [switch]$BareTitles,
        # WHICH TIER'S ROW ORDERS THE OUTPUT (issue #467). 0 -- the default -- means unranked: the
        # canonical category order and the arrival order within it, byte-identical to before this existed.
        # A document is ordered by what ITS OWN reader gets out of each change, and the reader is named by
        # the tier, so this is a tier number rather than an audience word: the internal note ranks on tier
        # 1, the highlights on tier 2.
        [int]$RankByTier = 0,
        # Remove the impact table from the rendered entries. For the documents that travel OUTWARD only;
        # the record keeps it. See Remove-EntryImpactTable for why the two differ.
        [switch]$StripSignificance
    )
    $md = [char]0x00B7
    $cats = Get-ReleaseCategories
    $catHashes = '#' * $CategoryLevel
    $entryHashes = '#' * ($CategoryLevel + 1)

    $grouped = @{}
    $index = -1
    foreach ($e in $Entries) {
        $index++
        $heading = ($e -split "`r?`n")[0]
        $t = 'Other'
        $parts = @(($heading -replace '^#+\s+', '') -split "\s*$md\s*")
        # THE TYPE IS FOUND BY WHAT IT IS, NOT BY WHERE IT SITS (August 5, 2026). This read
        # `$parts[$parts.Count - 2]` -- the second-to-last field -- which was only ever correct because a
        # trailing date happened to follow the type. When the merge date moved out of the heading to the
        # entry's closing line, that positional read would have made EVERY entry's type 'Other': no
        # error, no empty output, just one giant catch-all category in the release notes. Matching the
        # field against the known types instead is right for a heading with a trailing date and one
        # without, so the two shapes need no mode flag and history keeps parsing.
        #
        # The LAST matching field wins, which resolves the one collision this can have: an entry whose
        # title is itself exactly a type name ('### #12 <md> Fix <md> Fix'). Fields are middot-separated,
        # so an ordinary title containing the word cannot match -- only a field equal to it.
        for ($p = $parts.Count - 1; $p -ge 0; $p--) {
            $cand = $parts[$p].Trim()
            if ($cats.Order -contains $cand) { $t = $cand; break }
        }
        if (-not $grouped.ContainsKey($t)) { $grouped[$t] = New-Object System.Collections.Generic.List[pscustomobject] }
        # THE SCORE IS READ BEFORE ANYTHING IS STRIPPED, for exactly the reason the type is: a later pass
        # deletes the table it lives in. Reading it here also means -StripSignificance and -RankByTier
        # compose -- the highlights need both, and doing them in the other order would rank an unscored
        # pile, which is the same class of bug -BareTitles was measured on in this function.
        $rank = 0
        if ($RankByTier -gt 0) {
            $rank = Get-EntryImpactScore -Impact (Resolve-EntryImpact -EntryText $e) -Tier $RankByTier
        }
        # The type has been read by now, so reducing the heading is safe from here on.
        $text = if ($BareTitles) { Convert-EntryHeadingToTitle -EntryText $e } else { $e }
        if ($StripSignificance) { $text = Remove-EntryImpactTable -EntryText $text }
        $grouped[$t].Add([pscustomobject]@{
            Text  = ($text.Trim() -replace "`r`n", "`n")
            Rank  = $rank
            Order = $index
        })
    }

    # WHICH CATEGORY COMES FIRST. Unranked: the canonical order from Get-ReleaseCategories, which is what
    # this always did. Ranked: the category holding the highest-scoring entry leads, so the most
    # consequential change in the release is genuinely at the top of the document rather than third under
    # whichever heading its branch prefix produced -- while the reader keeps the grouping. Dave's choice
    # (August 5, 2026) over sorting only within a category, which preserves the structure but not the
    # promise, and over dropping the headings, which delivers the promise and costs the grouping.
    #
    # THE CANONICAL ORDER IS THE TIE-BREAK, so two categories whose best entry scores the same still come
    # out in a defined order rather than a hash-table one.
    $order = @($cats.Order | Where-Object { $grouped.ContainsKey($_) })
    if ($RankByTier -gt 0) {
        $ranked = @()
        $position = -1
        foreach ($cat in $order) {
            $position++
            $best = 0
            foreach ($item in $grouped[$cat]) { if ($item.Rank -gt $best) { $best = $item.Rank } }
            $ranked += [pscustomobject]@{ Cat = $cat; Best = $best; Canonical = $position }
        }
        $order = @($ranked | Sort-Object -Property @{Expression = 'Best'; Descending = $true}, @{Expression = 'Canonical'; Descending = $false} |
            ForEach-Object { $_.Cat })
    }

    $sections = @()
    foreach ($cat in $order) {
        $label = if ($cats.Title.ContainsKey($cat)) { $cats.Title[$cat] } else { $cat }
        $items = @($grouped[$cat].ToArray())
        if ($RankByTier -gt 0) {
            # SORTED ON (score desc, arrival asc) -- the second key is not decoration. PowerShell's
            # Sort-Object is NOT a stable sort, so on a five-point scale, where ties are the common case,
            # sorting on the score alone would let equal-scoring entries come out in a different order
            # from one run to the next. That would make a regenerated release document differ from the one
            # already published, with nothing having changed. The arrival index makes the result total.
            $items = @($items | Sort-Object -Property @{Expression = 'Rank'; Descending = $true}, @{Expression = 'Order'; Descending = $false})
        }
        $rendered = @($items | ForEach-Object {
            [regex]::Replace($_.Text, '^#{2,6}\s', "$entryHashes ")
        })
        $body = ($rendered -join "`n`n---`n`n")
        $sections += "$catHashes $label`n`n$body"
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
    # -StripSignificance, and NOT ranked (issue #467). This file ships INSIDE the plugin, so it travels to
    # every consumer's plugin cache -- exactly the outward direction a self-assigned score must not take.
    # It is not ranked because its entries are a per-PLUGIN selection cutting across all tiers, so there is
    # no single audience whose score would order it; the release's own documents are where the ordering
    # question has an answer.
    $body = Format-CategorizedEntries -Entries $Entries -CategoryLevel 3 -StripSignificance
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
        # -StripSignificance for the same reason as the plugin CHANGELOG above: this card ships inside the
        # plugin and is read by consumers. Unranked for the same reason too -- a per-plugin selection has
        # no one audience.
        $body = (Format-CategorizedEntries -Entries $converted -CategoryLevel 2 -StripSignificance).Trim()
    } else {
        $body = "No changes to this plugin in this release $emDash see the full notes."
    }

    $footer = "---`n`n" +
        "Full workshop notes: [$notesRelPath]($notesUrl)`n" +
        "Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)`n"

    return ($header + $body + "`n`n" + $footer)
}

# The two patterns that define where a release row lands, in ONE place because three readers depend on
# them agreeing: Get-OverviewTargetMajor and Get-OverviewSectionHeading below, and the inserter in
# cut-release.ps1. A hand-copied second instance of either is how this repo's accumulation bugs start.
$script:OverviewTableHeaderRe = [regex]"(?m)^\| Version \| Date \| Type \| Title \|\r?\n\|[-| ]+\|\r?\n"
$script:OverviewMajorHeadingRe = '(?m)^(#{3,4})\s+(\d+)\.x\s*$'

function Get-OverviewSectionHeading {
    <# The literal major-section heading a new row would land under ('#### 3.x'), or $null when the
       overview carries no table. Pure string in, string out.

       Exists so a caller can QUOTE that heading back at the reader -- cut-release.ps1's new-major refusal
       shows the section to add, and it must be shown at the level the document actually uses. Before this,
       that message hardcoded '###' twice, which was already wrong for a page nesting its list one deeper.
       Same match as Get-OverviewTargetMajor, from the same shared pattern, so the level and the number
       can never disagree. #>
    param([Parameter(Mandatory)][string]$ReadmeContent)
    $hm = $script:OverviewTableHeaderRe.Match($ReadmeContent)
    if (-not $hm.Success) { return $null }
    $sections = [regex]::Matches($ReadmeContent.Substring(0, $hm.Index), $script:OverviewMajorHeadingRe)
    if ($sections.Count -eq 0) { return $null }
    $last = $sections[$sections.Count - 1]
    return ($last.Groups[1].Value + ' ' + $last.Groups[2].Value + '.x')
}

function Get-OverviewTargetMajor {
    <# Which '<n>.x' section of the release history a new row would land in, or $null when the
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
       any other way would be a second, drifting definition of the same thing.

       BOTH '###' AND '####' ARE ACCEPTED, and that tolerance is the point rather than laxness. The
       heading level is a function of how deeply the release list is nested in its page, which is a
       LAYOUT decision the repo owns: a flat page puts the list at '###', while a page that files it
       under a repo-specific section heading nests it one deeper. This repo moved from the first shape to
       the second on August 4, 2026. Pinning one level would mean a purely cosmetic edit silently
       DISABLES the guardrail -- this function would find nothing, return $null, and cut-release.ps1's
       check is written as "if a target was found and it differs", so no target means no refusal. A
       guardrail that switches itself off when a heading gains a '#' is worse than none, because the
       document still reads as though it is protected. #>
    param([Parameter(Mandatory)][string]$ReadmeContent)
    $hm = $script:OverviewTableHeaderRe.Match($ReadmeContent)
    if (-not $hm.Success) { return $null }
    $before = $ReadmeContent.Substring(0, $hm.Index)
    $sections = [regex]::Matches($before, $script:OverviewMajorHeadingRe)
    if ($sections.Count -eq 0) { return $null }
    # Group 2, not 1: group 1 is the '#' run (see Get-OverviewSectionHeading, which needs it).
    return $sections[$sections.Count - 1].Groups[2].Value
}

# The audience each tier is named after in a generated document. ONE MAP, so the release notes and any
# later reader of a tier number agree about what it means.
#
# HARDCODED ENGLISH, deliberately, and not a new seam. This file already writes English prose into the
# documents it generates -- the per-plugin CHANGELOG intro, the "no changes to this plugin" line, the
# card's footer labels, the '**Date:**' label -- and none of those is configurable. Adding a knob for
# these three words while five other strings stay fixed would be arbitrary; translating this file's
# generated prose is one question with one answer, and the day a consumer needs it, it is that whole
# question that gets a seam rather than the three words that happened to be added last.
$script:ReleaseTierAudience = @{
    2 = 'consumers'
    1 = 'colleagues'
    0 = 'developers'
}

function Get-ReleaseTierHeading {
    <# The heading text for a tier in a generated release document, e.g. 'Tier 2 - consumers'. A tier
       with no audience word in the map degrades to 'Tier <n>' rather than to a blank -- an unfamiliar
       number is readable, a dangling separator is not. #>
    param([Parameter(Mandatory)][int]$Tier)
    $audience = $script:ReleaseTierAudience[$Tier]
    if ($audience) { return "Tier $Tier - $audience" }
    return "Tier $Tier"
}

function Build-ReleaseNotes {
    <#
        Builds the full release notes (the releases/development/<X>.x/<X.Y.Z>.md file) from the
        entry blocks. Pure string out -- DELIBERATELY hard LF (see
        Build-PluginChangelogSection above for the same trade-off: this is a NEW, standalone file
        with no existing newline style of its own, unlike the root CHANGELOG.md which detects and
        keeps its CRLF style via $nl). The entries come from that CRLF root CHANGELOG -- so here they
        are explicitly normalized to LF (#103, Victor #5), alongside the link rewriting below.

        TWO SHAPES, ONE FUNCTION (the tier model, August 5, 2026):

          -TierGroups  the changelog's tier sections, each with its own entries. Renders one '## Tier
                       <n> - <audience>' section per tier IN THE ORDER GIVEN, with the category
                       grouping one level under it ('### Features' -> '#### <entry>'). This is the
                       document the tier model produces: complete, raw, and structured the way
                       CHANGELOG.md itself now is. A tier with no entries is omitted, like an empty
                       category.
          -Entries     the flat list, rendered exactly as this function always did ('## Features' ->
                       '### <entry>'). Kept because a repo with no tier split has one section and
                       therefore nothing to group by -- a single '## Tier 0' wrapper around the whole
                       document would be a level of structure that says nothing.

        Give one or the other; -TierGroups wins if both arrive.
    #>
    param(
        [AllowEmptyCollection()][string[]]$Entries = @(),
        # Array of objects with Tier and Entries -- what Get-PullRequestEntriesByTier returns.
        $TierGroups = $null,
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
    # start with ../. Format-CategorizedEntries then groups the entries by category and normalizes to
    # LF, so the CRLF of the source CHANGELOG does not cross the pure-LF output.
    if ($TierGroups) {
        $sections = @()
        foreach ($group in @($TierGroups)) {
            $groupEntries = @($group.Entries | Where-Object { $_ -and $_.Trim() })
            if ($groupEntries.Count -eq 0) { continue }
            $linked = @($groupEntries | ForEach-Object { Convert-RootRelativeLinks -EntryText $_ -Prefix $LinkPrefix })
            # Categories one level deeper than in the flat shape, so the nesting stays correct:
            # '## Tier 2 - consumers' -> '### Features' -> '#### <entry>'.
            #
            # RANKED FROM TIER 1 UP, AND DELIBERATELY NOT AT TIER 0 (issue #467). Tier 0 is the RECORD --
            # complete and chronological, which is what a record is for -- and its entries are never asked
            # for a score in the first place. The tiers above it are ordered by what the organisation gets
            # out of them, the same score CHANGELOG.md's sections are already ordered by, so this
            # inherits that order rather than forming a second opinion about it.
            #
            # THE SCORES ARE NOT STRIPPED HERE, and that is the one place they survive. The cut EMPTIES
            # the changelog's tier sections, so these notes are the last document holding the reason
            # behind each ranking; deleting it would leave every order asserted with its justification
            # thrown away. The documents that travel outward strip it -- see Build-HighlightsNotes.
            $rankByTier = if ([int]$group.Tier -ge 1) { [int]$group.Tier } else { 0 }
            $inner = Format-CategorizedEntries -Entries $linked -CategoryLevel 3 -RankByTier $rankByTier
            $sections += ("## " + (Get-ReleaseTierHeading -Tier ([int]$group.Tier)) + "`n`n" + $inner)
        }
        $body = ($sections -join "`n`n")
    } else {
        $linked = @($Entries | ForEach-Object { Convert-RootRelativeLinks -EntryText $_ -Prefix $LinkPrefix })
        $body = Format-CategorizedEntries -Entries $linked -CategoryLevel 2
    }

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
# script, phase 2 shared this half. The rule it carries is older than the sharing (Dave, July 13,
# 2026): HIGHLIGHTS IS WRITTEN FOR NON-DEVELOPERS.
#
# THE MARKER IS GONE, AND WITH IT THE GUESS IT EXISTED FOR (August 5, 2026). Until now this document
# rendered EVERY category, put the branch types a seam called "stakeholder-facing" above a "remove
# before publishing" marker, and left the release manager to delete the rest. That marker was
# explicitly a PROPOSAL rather than a verdict, because the branch prefix does not predict impact -- held
# against the 19 entries pending at v3.2.0, the single most consequential change for a consumer
# (renaming the marketplace, which breaks every existing install) arrived on a chore/ branch and landed
# below the marker.
#
# The tier model asks the author of the entry instead, at the moment they know: 'Tier: 2' means a
# consumer notices. So this document is now simply the tier-2 entries, and the two knobs that
# configured the marker (Get-ReleaseHighlightsStakeholderTypes, Get-ReleaseHighlightsWording) are
# retired. That is a smaller document AND a better-founded one: what used to be a hint for the release
# manager to correct is now a claim the entry's own author made and a reviewer saw on the PR.
#
# STILL A DRAFT TO BE EDITED, for the reason that never depended on the marker: entry bodies are
# written for developers even when the change reaches a consumer, so the selection is right and the
# prose still needs rewriting. What is gone is the deleting, not the writing.
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

        A leading '#NN' field and the trailing administrative fields are dropped; everything between
        them is the title and is rejoined with the middot, so a title that legitimately contains one
        survives. Only the FIRST line is touched -- the body may contain anything.

        WHICH TRAILING FIELDS, DECIDED BY CONTENT RATHER THAN BY COUNT (August 5, 2026). This used to
        drop exactly two -- the (type, date) pair the scaffold always wrote. Since the merge date moved
        out of the heading onto the entry's closing line, a heading has ONE trailing administrative
        field, while every entry already in this repo's history has two. Dropping a fixed number would
        have to pick which era to be right about; recognising a field by its shape -- a known branch
        type, or an ISO date -- is right for both, which is also why nothing had to be migrated.
    #>
    param([Parameter(Mandatory)][string]$EntryText)
    $md = [char]0x00B7
    $lines = $EntryText -split "(`r?`n)", 2
    $heading = $lines[0]
    $hm = [regex]::Match($heading, '^(#+)\s+(.*)$')
    if (-not $hm.Success) { return $EntryText }

    $parts = @($hm.Groups[2].Value -split "\s*$md\s*")
    $types = (Get-ReleaseCategories).Order
    $first = if ($parts[0] -match '^#\d+$') { 1 } else { 0 }

    # THE TAIL HAS A GRAMMAR, so it is matched rather than walked: at most one date, and before it at
    # most one type. Anything else is title. A greedy "keep eating administrative-looking fields" loop
    # was written first and this file's own suite caught it -- on '### #12 <md> Fix <md> Fix', an entry
    # whose title IS a type name, it ate both and returned the heading unchanged. Two types in a row
    # cannot both be the type; the grammar says so and the loop could not.
    #
    # 'Other' is excluded from the type test deliberately: it is the catch-all label this repo PRINTS,
    # never a value a branch table produces, so a field reading 'Other' is a title.
    $isMeta = {
        param($f, $kind)
        if ($kind -eq 'date') { return $f -match '^\d{4}-\d{2}-\d{2}$' }
        return ($f -ne 'Other') -and ($types -contains $f)
    }
    $last = $parts.Count - 1
    if ($last -ge $first -and (& $isMeta $parts[$last].Trim() 'date')) { $last-- }
    if ($last -ge $first -and (& $isMeta $parts[$last].Trim() 'type')) { $last-- }

    # Nothing was administration, or nothing but -- either way there is no (title + metadata) shape here,
    # so leave the heading exactly as it was rather than guess.
    if ($last -eq ($parts.Count - 1) -or $last -lt $first) { return $EntryText }
    $title = (@($parts[$first..$last]) -join " $md ").Trim()
    if (-not $title) { return $EntryText }

    $rest = if ($lines.Count -gt 1) { ($lines[1] + $lines[2]) } else { '' }
    return "$($hm.Groups[1].Value) $title$rest"
}

function Build-HighlightsNotes {
    <#
        Builds the highlights document (releases/highlights/<dir>/<X.Y.Z>.md) from the TIER-2 entries of
        the release. Pure string out, hard LF -- a new standalone file, like Build-ReleaseNotes.

        $Entries is the selection, not the whole release: the caller passes the tier-2 section's entries
        and this renders all of them. The selection lives in the caller because the tier is a property of
        the changelog SECTION an entry sits in, which only the parser knows -- the fold removed the
        'Tier:' line the moment the section took over stating it.

        AN EMPTY SELECTION RETURNS THE HEADER AND NOTHING ELSE, rather than throwing. cut-release never
        gets here with nothing (its bump gate refuses a minor with no tier-2 entry), so a throw would
        only ever fire in a test or a hand call -- and a document that says "this release has no
        highlights" is a truthful answer to a strange question, while an exception is not.

        The entries keep their heading metadata until the renderer has read the type off it -- hence
        -BareTitles on Format-CategorizedEntries rather than a strip pass here; see that function for
        what stripping too early costs. Links are rewritten first, at the same depth the developer notes
        use (both documents sit three folders down).
    #>
    param(
        [AllowEmptyCollection()][string[]]$Entries = @(),
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date,
        [Parameter(Mandatory)][string]$Type,
        [string]$Title = '',
        [string]$LinkPrefix = '../../../'
    )
    $real = @($Entries | Where-Object { $_ -and $_.Trim() })
    $linked = @($real | ForEach-Object { Convert-RootRelativeLinks -EntryText $_ -Prefix $LinkPrefix })
    # ORDERED BY THE CONSUMER SCORE, not the internal one (issue #467). This is the only document whose
    # reader is the consumer, and 'what does a consumer notice' is a different question from 'what does the
    # organisation get out of it' -- which is precisely why the two are separate documents and separate
    # scores. Ordering this one by the internal score would answer its question with a proxy.
    #
    # RE-SORTING HERE IS NOT A SECOND ESTIMATE. Both numbers were written once, by the author, on the
    # branch, and both travel in the entry; this reads the other one rather than forming a new opinion. The
    # reproducibility the two-moment problem needed is a property of the numbers being stored, not of
    # there being only one sort.
    #
    # AND THE SCORES THEMSELVES ARE STRIPPED, which is the whole reason -StripSignificance exists. A
    # self-assigned number printed at a consumer is a marketing claim, and this repo has measured what a
    # published guess costs -- the retired highlights marker is in this file's history for exactly that.
    # The number does its work by deciding the order and then gets out of the way; the reason stays in the
    # development notes, where it is auditable by the people who can check it.
    $body = if ($linked.Count -gt 0) {
        Format-CategorizedEntries -Entries $linked -CategoryLevel 2 -BareTitles -RankByTier 2 -StripSignificance
    } else {
        ''
    }

    $rocket = [char]::ConvertFromUtf32(0x1F680)
    $titleLine = if ($Title) { "$Title`n`n" } else { '' }
    $header = "# Release notes v$Version $rocket`n`n**Date:** $Date  `n**Type:** $Type`n`n$titleLine"

    return ($header + $body + "`n")
}
