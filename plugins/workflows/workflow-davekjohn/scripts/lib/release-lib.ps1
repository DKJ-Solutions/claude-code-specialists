<#
.SYNOPSIS
    Pure release helpers (version determination + CHANGELOG transformation + release-notes
    building), separate from git/filesystem orchestration.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

    Supplies Get-NextVersion, Get-BumpType, Get-LockstepVersion, Get-PluginManifestPaths,
    Get-PullRequestEntries, Get-PullRequestEntriesByTier, Convert-ChangelogForRelease,
    Build-ReleaseNotes, Get-ReleaseTierHeading, Test-ReleaseBumpEarned, Get-EntryPlugins and
    Get-MarketplaceName. These functions are deliberately pure (string/value in, string/value out)
    so they can be tested separately without running a release -- scripts/release/cut-release.ps1
    uses them, and the tests cover them.

    The per-plugin CHANGELOG and RELEASE.md builders were retired on August 8, 2026; the retirement
    note further down says why. Get-EntryPlugins survives them: the `Plugins:` line still records
    which plugins an entry touched, and the release notes still read it.

    THE FLAT CHANGELOG (Dave, August 5, 2026). CHANGELOG.md is an intro followed by ONE H2 PER CHANGE,
    with no section headings at all -- the three '## Tier N - Pull Requests' sections and the
    '## Latest Release' block are gone. Four things follow from it in this file, and they are the whole
    of this change:

      * Split-Changelog parses no sections. The head is everything above the first entry heading; the
        entries are the H2 blocks below it. There is no seam left to ask which headings count.
      * The TIER COMES FROM THE ENTRY, not from the heading above it. Get-PullRequestEntriesByTier reads
        each entry's impact table (falling back to the older 'Tier: N' line), which is why the fold stopped
        consuming either -- the entry is the only carrier now.
      * THE CATEGORY GROUPING IS GONE, and with it Format-CategorizedEntries, the category labels and the
        Get-ReleaseCategoryTitles seam. A release document is a ranked list of changes, exactly as the
        changelog is; the type of each change is stated inside it, under its own '### Type of change'
        section, rather than inferred from a heading field and turned into a heading of its own.
      * A CUT WRITES NO RELEASE BLOCK. It empties the changelog down to its intro, and that intro's
        pointer to the repo's release history is the only thing left saying where releases live. Which
        also moved the internal note's inbound link: it is now the Version cell of the history overview's
        row -- see Set-ReleaseInternalNoteLink.

    A CONSUMER MID-MIGRATION HAS A MIXED DOCUMENT, and this file reads only the new shape's structure.
    That is deliberate rather than an oversight: an entry's own '### ' sections and a pre-format '### '
    entry heading are indistinguishable, so a parser that accepted both would read every entry as four.
    The tier DECLARATION is still read in both shapes (table or 'Tier: N'), which is the half that can be
    recognised without ambiguity.

    ENTRY HEADINGS ARE RE-LEVELLED AS A WHOLE, not on their first line. An entry now carries H3 sections
    of its own, so shifting only the heading would put '### Type of change' at the same level as the entry
    above it -- one entry rendering as four. Format-RankedEntries shifts every non-fenced heading in the
    block by the same delta.

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
    section, a reference line) reaches its file again on the next release, so editing it does
    propagate. The per-plugin CHANGELOG INTRO was the one that did not: it was written only for a
    file that did not exist yet, so the four existing CHANGELOGs kept an intro naming the retired
    marketplace long after the rename had swept it out of 59 files. "Leave history alone" was the
    right instinct applied to the wrong text -- the entries below the intro were history, the intro
    was a live statement about the present mechanism.

    THE RULE OUTLIVES THE FILES IT WAS LEARNED ON, which is why it stays here after those documents
    were retired on August 8, 2026: for the next template added below, ask whether the string is
    rewritten on every release, and if it is not, it needs a gate rather than a good intention.
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
# callers that never resolve a repo root. Get-ReleaseChangeTypes probes for the function instead of
# assuming it, and states its fallback -- see there.
$branchInfoSibling = Join-Path $PSScriptRoot 'branch-info.ps1'
if (Test-Path -LiteralPath $branchInfoSibling) { . $branchInfoSibling }

# THE ENTRY FORMAT (the flat changelog, August 5, 2026): Get-EntryHeadingLevel and Get-EntrySectionLevel
# for the heading levels this file parses and re-levels, Resolve-EntryImpact + Get-EntryImpactScore for the
# tier and the significance it reads out of each entry, and Remove-EntryImpactTable +
# Remove-EntryTierLine for the documents that travel outward. Unlike branch-info above, this sibling is
# NOT repo-owned -- it travels in the same mirror as this file -- so the dot-source is unconditional in
# every location it can run from.
#
# WHY THE FORMAT LIVES THERE AND NOT HERE. The fold needs the same answers, and it reaches this lib only
# where the repo happens to have a copy in its own root (see that script's guarded dot-source), while it
# always has entry-scaffold-lib. Defining the format here would have meant two definitions of one fact --
# the exact thing this repo keeps repairing -- so it lives in the lib both scripts can reach and this one
# reads it from there. Get-ChangelogTierSections used to be read here too and is retired: a flat document
# has no sections, so there is no map left to agree about.
. (Join-Path $PSScriptRoot 'entry-scaffold-lib.ps1')

# THE PLUGIN SET: which plugins this repo publishes, and where each one's folder is. Unconditional for
# the same reason as the sibling above -- it travels in this mirror, so it is present wherever this file
# is. Get-PluginManifestPaths below is a thin wrapper over it, and Get-TouchedPlugins reads the same
# roots rather than matching a path shape.
. (Join-Path $PSScriptRoot 'plugin-tree-lib.ps1')

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
          Active          $false when no pending entry declared its impact at all, so nothing was judged

        EarnedBump DELIBERATELY NEVER SAYS 'major', even when one would be permitted. The pending
        entries cannot warrant a major -- what earns it is the ten minors behind it, which is a
        milestone somebody decides to mark rather than a size the work adds up to. Reporting 'major'
        as the bump this work warrants would nudge a routine tier-1 change into one. So the two facts
        are reported separately: what the work warrants, and whether a major is available at all.

        THE RULES (Dave, August 5, 2026), and each answers a question the version number was already
        supposed to answer but nothing enforced:

          any release   nothing. A release made entirely of tier-0 work is a PATCH -- publishing to no
                        audience is what a patch is for (Dave, August 7, 2026). This used to refuse
                        outright, on the grounds that such a release "has nobody to announce it to";
                        the answer is that it announces nothing, which is allowed.
          minor         at least one entry of TIER 1 or higher -- something an audience beyond this
                        repo's own developers gets out of it. It used to demand a tier-2 entry, so tier-1 work
                        earned only a patch. Loosened deliberately: the version here speaks to all
                        stakeholders, not to consumers alone. What keeps it honest is that the DOCUMENTS
                        follow the tier and not the bump -- a tier-1-only minor writes the internal note
                        and no consumer document, so nobody outside is handed an empty document.
          major         at least $MinMinorsForMajor minors cut in the current major line, on top of the
                        general minimum. A major is a RECAP of those minors, so what earns it is their
                        accumulation rather than any single pending change -- which is why a tier-2 entry
                        is deliberately NOT required here. Read off the minor component of
                        $CurrentVersion: within major 3 the minors are 3.1 .. 3.10, so the component IS
                        the count of minors cut in that line.

        OFF WHEN NO PENDING ENTRY DECLARED ITS IMPACT, and that is what keeps this safe to share. A repo
        that never adopted the model writes entries with no impact table and no 'Tier:' line; every one of
        them reads as tier 0, so a gate would refuse every release that repo ever cuts -- a shared script
        silently imposing a model nobody there chose.

        THE TEST USED TO BE THE NUMBER OF TIER SECTIONS, and it had to change with them (August 5, 2026).
        Counting groups worked while the changelog declared its tiers as headings: one section meant no tier
        information. A flat changelog has no sections, so an unadopted repo and an adopting one both produce
        exactly one group -- tier 0 -- and the old line would have read every repo as not adopting, silently
        switching the gate off in the same change that made the tier the document's primary ordering.

        SO THE SIGNAL IS 'Declared', WHICH IS A MEASUREMENT RATHER THAN A FLAG. Get-PullRequestEntriesByTier
        counts, per group, how many entries actually STATED their reach. None anywhere means nothing was
        adopted, and nothing is judged. At least one means the repo is using the model, and an all-tier-0
        release is then refused on purpose -- which is the whole point of the gate, and is why "declared
        tier 0" must not be confused with "declared nothing". -SkipTierGate in cut-release.ps1 is the escape
        valve for the repo mid-adoption whose one declared entry happens to be tier 0.
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('major', 'minor', 'patch')][string]$BumpType,
        # Array of objects with Tier, Entries and Declared -- what Get-PullRequestEntriesByTier returns.
        [AllowEmptyCollection()]$TierGroups = @(),
        [Parameter(Mandatory)][string]$CurrentVersion,
        [int]$MinMinorsForMajor = 10
    )
    $groups = @($TierGroups)
    $counts = @{}
    $anyDeclared = $false
    foreach ($g in $groups) {
        $counts[[int]$g.Tier] = @($g.Entries | Where-Object { $_ -and $_.Trim() }).Count
        # PSObject.Properties, not a bare property read: a caller (or a test) building groups by hand
        # without the Declared field would otherwise make this throw under a strict caller, or read $null
        # as 0 and switch the gate off -- the silent direction.
        if ($g.PSObject.Properties['Declared'] -and [int]$g.Declared -gt 0) { $anyDeclared = $true }
    }

    $result = [pscustomobject]@{
        Earned         = $true
        EarnedBump     = $BumpType
        MajorAvailable = $false
        Reason         = ''
        Counts         = $counts
        Active         = $anyDeclared
    }
    if (-not $result.Active) { return $result }

    # TIER 1 OR HIGHER, counted as one number rather than per tier. A separate tier-2 count stood here
    # until August 12, 2026, assigned and read nowhere: it was load-bearing while a minor REQUIRED a
    # tier-2 entry, and the rule became "tier 1 or higher -> minor" on August 7 without the variable
    # going with it. Written as >= 1 rather than against the audience tier deliberately, so this reads
    # correctly in a tier-1 repo and a tier-2 repo alike with neither having to translate it.
    $notable = 0
    foreach ($tier in $counts.Keys) { if ($tier -ge 1) { $notable += $counts[$tier] } }

    if ($CurrentVersion -notmatch '^\d+\.(\d+)\.\d+$') { throw "CurrentVersion '$CurrentVersion' is not X.Y.Z." }
    $minorsSoFar = [int]$Matches[1]

    # What the pending set warrants, computed once and reported whether or not it matches what was asked
    # -- so a refusal can name the bump that WOULD work instead of only what will not.
    # THE BUMP FOLLOWS THE HIGHEST TIER PENDING (Dave, August 7, 2026), and the rule is one sentence:
    #
    #   tier 0 only            -> patch. Nobody outside this repo notices, which is what a patch IS.
    #   tier 1 or higher       -> minor. Something beyond this repo's own developers got something.
    #
    # TWO THINGS CHANGED HERE, AND BOTH LOOSEN THE LADDER BY ONE STEP.
    #
    # A TIER-0-ONLY RELEASE IS NOW ALLOWED, where it used to be refused outright ("nothing pending reaches
    # beyond this repo... a release needs at least one tier-1 entry"). That refusal read the absence of an
    # audience as a reason not to publish; Dave's answer is that publishing to no audience is precisely what
    # a patch is for. The version still moves, the record is still written, and no announcement is owed.
    #
    # AND TIER 1 NOW EARNS A MINOR, where it used to earn a patch and a minor demanded tier 2. Weighed
    # explicitly: it means a release can bump the minor with nothing in it for a consumer, which is the
    # opposite of what a minor usually promises. Dave chose it knowing that -- the version speaks to ALL
    # stakeholders here, colleagues included, not to consumers alone. What keeps that honest is that the
    # DOCUMENTS still follow the tier rather than the bump: a tier-1-only release writes the internal note
    # and no consumer document, so nobody outside is handed a document with nothing in it. See the tier-2
    # trigger in cut-release.ps1, which keys on a tier-2 entry rather than on this bump type for exactly
    # that reason.
    $result.MajorAvailable = ($minorsSoFar -ge $MinMinorsForMajor)
    $result.EarnedBump = if ($notable -gt 0) { 'minor' } else { 'patch' }

    # BOTH minor AND major, and that second one is a defect this file's own suite caught on the first run.
    # The refusal was written for 'minor' alone, which let a MAJOR through on tier-0-only work -- a bigger
    # claim than the one being refused beside it. A major recaps the minors behind it, but it still has to
    # be a release, and a release of nothing but repo-internal work is a patch whatever its history.
    $tier0 = if ($counts.ContainsKey(0)) { $counts[0] } else { 0 }
    if (@('minor', 'major') -contains $BumpType -and $notable -eq 0) {
        $result.Earned = $false
        $result.Reason = "a $BumpType is what somebody outside this repo's own developers gets something out of, and everything pending is tier 0 ($tier0 entry/entries). Cut a patch, or raise the tier of the entry that a colleague or a consumer does notice."
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
        The plugin manifest paths, derived from plugins[].source in the marketplace JSON. Pure (does
        not touch disk): input is the raw JSON text + the repo root, output is an array of full
        manifest paths.

        A WRAPPER SINCE plugin-tree-lib.ps1 EXISTS, and kept under this name because it is what the
        release cut and the lint gate call. The derivation itself -- including the containment check
        that stops a source pointing outside the repo -- moved to Get-PluginRoots, which answers the
        same question with the plugin's NAME and ROOT alongside the manifest path. Four other places
        needed those two fields and were each deriving them from a path shape instead.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$MarketplaceJson
    )
    foreach ($p in (Get-PluginRoots -RepoRoot $RepoRoot -MarketplaceJson $MarketplaceJson)) {
        $p.ManifestPath
    }
}

# --- MOVED, NOT DELETED: Get-FencedLineFlags now lives in entry-scaffold-lib.ps1 -------------------
#
# The three readers below (Split-EntryBlocks, Split-Changelog, Set-EntryHeadingLevel) still call it by
# exactly that name, and it is in scope here because this file dot-sources entry-scaffold-lib
# unconditionally, at the top.
#
# WHY IT MOVED DOWN A LAYER RATHER THAN THE OTHER ONE MOVING UP. There were four fence walks in the two
# libs -- this named function, a second named one in entry-scaffold-lib, and two inline walks inside its
# removers -- and they were not equivalent: only this one recognised '~~~' fences. So an entry using tilde
# fences had its quoted content read as STRUCTURE by every reader in that file while the readers here
# handled it correctly. One question, one answer, and it has to sit in the lib that owns the entry format,
# because the dependency can only run this way: the fold and entry-scaffold-lib's own suite load that lib
# standalone, while nothing loads this one without it.
#
# The name deliberately did not gain an 'Entry' prefix on the way down: the readers here scan a whole
# CHANGELOG rather than one entry, so a name claiming otherwise would be wrong at three call sites -- and
# keeping it meant the move changed no call site in either lib.

# --- MOVED, NOT DELETED: Get-EntryHeadingPattern and Split-EntryBlocks -----------------------------
#
# Both now live in entry-scaffold-lib.ps1, on August 10, 2026, and the readers below still call them by
# exactly those names -- they are in scope because this file dot-sources that lib unconditionally, at the
# top, exactly as with Get-FencedLineFlags above.
#
# WHY THEY MOVED DOWN A LAYER. The fold needs the entry-boundary rule too, and it deliberately does not
# load this file: its header rejects pulling three thousand lines of release machinery into a script that
# runs immediately after a merge and directly on the trunk. The dependency can only run one way -- the
# fold and entry-scaffold-lib's own suite load that lib standalone, while nothing loads this one without
# it -- so a rule both the cut and the fold read has to sit down there. Inbound #561 is the defect that
# forced the question: the two scripts shared an assumption about what an H2 means and only one of them
# checked it.

function Split-Changelog {
    <#
        Private helper: parses CHANGELOG.md into its parts. Returns an object with

          Nl       the newline style the document uses
          Head     everything above the first entry heading -- the title and the intro
          Entries  every entry block, in document order

        Throws when the document holds no entry: a cut with no entries produces a release note
        describing nothing.

        NO SECTIONS AT ALL (Dave, August 5, 2026). This parsed two sections, then N of them, and now none.
        The document is an intro followed by one H2 per change, so the only boundary is the first entry
        heading -- and that is derived STRUCTURALLY rather than read from a seam. Everything the seam
        version needed goes with it: the '## Releases' / '## Latest Release' lookup and its fatal throw,
        the per-section intro, the section index that let either order be valid, and the "which headings
        count" question itself. There is no name to look up, so there is nothing to mismatch.

        THE ORDER OF THE ENTRIES IS THE FOLD'S RANKING, and this function must not sort. The fold placed
        each entry at its ranked position when it landed, because that is the only moment it could -- the
        cut empties this list, so document order at cut time IS the order the release documents inherit.
        Re-sorting here would be a second opinion formed from the same numbers, and one that could differ
        (PowerShell's Sort-Object is not stable), which is exactly the reproducibility the two-moment
        design exists to guarantee.

        TRAILING BLANKS ARE STRIPPED FROM THE HEAD, and that is a correctness fix rather than tidiness. The
        head as read ends with the blank line separating it from the first heading; the caller adds its own
        separator, so each cut left one more blank than the last. Measured over three consecutive cuts:
        2, 3, 4. It renders identically in markdown, which is exactly why it would have gone on growing --
        nothing looks wrong until a reader opens the raw file years in.
    #>
    param([Parameter(Mandatory)][string]$Content)

    $usesCRLF = $Content.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }
    $lines = $Content -split "`r?`n"

    # Fence-aware: an intro that quotes an entry heading inside a fence -- this repo's own changelog
    # documents the entry format, so it does -- would otherwise put the intro/entries boundary in the
    # middle of a code block.
    $headingRx = Get-EntryHeadingPattern
    $fenced = Get-FencedLineFlags -Lines $lines
    $firstEntry = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ((-not $fenced[$i]) -and $lines[$i] -match $headingRx) { $firstEntry = $i; break }
    }

    if ($firstEntry -lt 0) {
        throw "No changelog entries in CHANGELOG.md -- nothing to release. (An entry is an H$(Get-EntryHeadingLevel) block below the intro; the fold puts them there.)"
    }

    $head = if ($firstEntry -gt 0) { @($lines[0..($firstEntry - 1)]) } else { @() }
    while ($head.Count -gt 0 -and $head[-1].Trim() -eq '') { $head = @($head[0..($head.Count - 2)]) }

    $entries = @(Split-EntryBlocks -Lines @($lines[$firstEntry..($lines.Count - 1)]) -Nl $nl)
    if ($entries.Count -eq 0) {
        throw "No changelog entries in CHANGELOG.md -- nothing to release."
    }

    # A LEFTOVER SECTION HEADING IS NOT AN ENTRY, AND THIS REFUSAL IS WHY (August 5, 2026). Every '## '
    # below the intro is read as one change now, and a document still carrying the pre-flat shape has
    # headings at exactly that level. Measured on both of them before this guard existed: a consumer's
    # '## Pull Requests' parsed as ONE entry swallowing all of their real ones and '## Releases' as a
    # second, so their whole release history was published outward as a "change" and then deleted from
    # CHANGELOG.md -- and nothing refused, because blocks like that declare no impact and the bump gate
    # therefore reads the repo as never having adopted the model and reports itself inactive. Silent,
    # correct-looking, and it loses data on a repo that never asked for the change; a shared script reaches
    # a consumer through a plugin update rather than by their choosing.
    #
    # THE TEXT IS SHARED WITH THE FOLD SINCE AUGUST 10, 2026 (inbound #561). It was written here first,
    # and the fold -- which makes the same assumption about what an H2 means -- had no check at all: it
    # wrote the entry above the section heading and reported success. Get-PreFlatChangelogRefusal in
    # entry-scaffold-lib.ps1 now owns the diagnosis and the migration advice; this call supplies only the
    # clause that differs, which is what each script is about to DO to a block it cannot read.
    #
    # Still named per offending block, and still BEFORE anything is written, so a cut stops with the
    # document intact.
    $refusal = Get-PreFlatChangelogRefusal -Content $Content -Consequence 'these would be released as changes -- and the cut empties this file, which would remove them'
    if ($refusal) { throw $refusal }

    return [pscustomobject]@{
        Nl      = $nl
        Head    = $head
        Entries = @($entries)
    }
}

function Get-PullRequestEntries {
    <# Returns the entry blocks to be released, in document order (which is the fold's ranked order). Use
       Get-PullRequestEntriesByTier where the tier matters. #>
    param([Parameter(Mandatory)][string]$Content)
    return @((Split-Changelog -Content $Content).Entries)
}

function Get-PullRequestEntriesByTier {
    <#
        The pending entries PER TIER, highest tier first: an array of objects with

          Tier      the tier as an int
          Heading   the heading a generated release document gives that tier ('Tier 2 - consumers')
          Entries   its entry blocks, in document order
          Declared  how many of those entries actually DECLARED their impact

        Its own function beside the flat Get-PullRequestEntries because the two callers want genuinely
        different things and neither should derive the other:

          the flat list  -- the per-plugin CHANGELOGs and the RELEASE.md cards, which select on the
                            'Plugins:' line and do not care how far a change reaches;
          per tier       -- the release notes (one section per tier), the consumer document (tier 2 only) and the
                            cut's bump gate (which tiers are pending at all).

        THE TIER NOW COMES FROM THE ENTRY, which is the reversal this change is about. It used to come from
        the changelog SECTION an entry sat in, and this function's own header said deriving it from the
        entry was "impossible on purpose" because the fold removed the 'Tier:' line the moment the section
        took over stating it. With the sections gone that sentence inverted: the fold consumes nothing, the
        entry carries its impact table (or the older line) into the changelog, and Resolve-EntryImpact reads
        it here.

        GROUPED ON THE HIGHEST TIER AN ENTRY CLAIMS, so the groups stay DISJOINT -- exactly as the sections
        were. The ladder is cumulative in terms of which DOCUMENTS an entry reaches, and that is the
        caller's business: the development note renders every group, the consumer document takes tier 2 only. An
        entry appearing in two groups here would put it twice in the record.

        Declared IS NOT BOOKKEEPING -- it is what tells an adopting repo from one that never heard of tiers.
        An entry with no table and no 'Tier:' line reads as tier 0 exactly like a declared tier-0 entry, and
        Test-ReleaseBumpEarned has to be able to tell those apart or it refuses every release a
        non-adopting consumer ever cuts. Counted here because this is where the resolve already happens.
    #>
    param([Parameter(Mandatory)][string]$Content)

    $entries = @((Split-Changelog -Content $Content).Entries)
    $byTier = @{}
    $declared = @{}
    foreach ($e in $entries) {
        $impact = Resolve-EntryImpact -EntryText $e
        $tier = [int]$impact.Tier
        if (-not $byTier.ContainsKey($tier)) {
            $byTier[$tier] = New-Object System.Collections.Generic.List[string]
            $declared[$tier] = 0
        }
        $byTier[$tier].Add($e)
        if ($impact.Declared) { $declared[$tier]++ }
    }

    # Highest tier first: the order the model reads in, and the order the release notes are written in.
    # Sorted rather than trusted to the hashtable, which has no order of its own.
    $out = @()
    foreach ($tier in @($byTier.Keys | Sort-Object -Descending)) {
        $out += [pscustomobject]@{
            Tier     = $tier
            Heading  = (Get-ReleaseTierHeading -Tier $tier)
            Entries  = @($byTier[$tier].ToArray())
            Declared = $declared[$tier]
        }
    }
    return @($out)
}

# --- RETIRED, AUGUST 5, 2026: the release block's wording (inbound #462) --------------------------
#
# $script:ChangelogReleaseWordingDefaults and Get-ChangelogReleaseWordingLines held four strings a
# release wrote into CHANGELOG.md: the two intros for the release section, the "see the full notes"
# pointer line, and the sentence repointing that line at the internal note. All four described the
# release BLOCK, and CHANGELOG.md no longer has one -- a cut now empties the document down to its intro
# and writes nothing else. Four strings with nothing to write them into is not a seam, it is dead config,
# which this repo's own rule says to remove rather than leave returning values nothing reads.
#
# WHAT THE CONSUMER WHO ASKED FOR #462 LOSES, stated rather than glossed over: that inbound issue was
# from a non-English repo, and it made these strings repo-owned precisely because they were the most
# visible generated output in the file. The capability is not being taken away from them -- the OUTPUT is
# gone. What replaced it, the intro paragraph's own pointer to the release history, is hand-written prose
# in a file the repo owns outright, so it needs no seam to be in their language: it simply is.
#
# The Get-ChangelogReleaseWording seam in scripts/repo-config.ps1 retires with them. A consumer that
# still defines it is unaffected -- nothing calls it, so it is dead code in that repo's seam, and its
# next cut behaves exactly as this repo's does.

function Convert-ChangelogForRelease {
    <#
        Empties CHANGELOG.md down to its intro: the head is kept, every entry block the release just
        consumed is removed, and nothing is written in their place. Pure string in/out.

        IT WRITES NO RELEASE BLOCK, and that is the change rather than a simplification of it (Dave,
        August 5, 2026). This function used to rebuild one section per tier plus a '## Releases' or
        '## Latest Release' block carrying the version, the date, the type and a pointer to the notes. All
        of it is gone, and with it $Version, $Date, $Type, $NotesRelPath, $LiveMarker, $HistoryMode,
        $HistoryRelPath, $TierSections and $Wording -- the whole parameter list except the content, because
        every one of them existed to describe a block that no longer exists.

        THE MEASURED REASON, and it is worth keeping because the first half of it has already been acted on
        once. The accumulating section had grown to 434 of the changelog's 1,062 lines -- 41% -- across 72
        blocks that each said no more than "see the notes", while releases/README.md listed every one of
        those 72 versions with a date, a type and a descriptive title: the same coverage, verified in both
        directions, and richer per row. 'latest' mode cut that to a single block in August 2026; this
        removes the last one. What answers "which version is current" is the release history itself, which
        the intro points at in one line -- hand-written prose in a file the repo owns, so it needs no seam
        and cannot go stale at a cut that no longer touches it.

        THE INTRO IS NOT REGENERATED, which is the property that makes the above safe. It is the head as
        the document already had it, passed through verbatim -- so whatever a repo says about itself up
        there survives every cut, in whatever language it wrote it.
    #>
    param([Parameter(Mandatory)][string]$Content)
    $s = Split-Changelog -Content $Content
    return ((@($s.Head) -join $s.Nl).TrimEnd() + $s.Nl)
}

function Set-ReleaseInternalNoteLink {
    <#
        Point the release history overview's row for $Version at the INTERNAL note. Pure string in/out,
        and idempotent: run twice and the second call changes nothing.

        WHY THIS IS A SEPARATE STEP RATHER THAN PART OF THE CUT (August 4, 2026). The internal note does
        not exist when cut-release.ps1 runs: that script commits AND tags in one motion, while the internal
        note needs the developer notes as its input and is therefore written afterwards, by hand, landing
        through a branch + PR. A cut that linked straight to it would put a DEAD RELATIVE LINK inside the
        release tag -- caught by the lint gate's dead-link scan, and uncorrectable afterwards because the
        tag is immutable. Generating an empty skeleton at cut time was considered and rejected earlier for
        the mirror-image reason: that puts an empty document inside the tag instead.

        So the cut writes the DEVELOPER link, which always exists, and new-internal-note.ps1 calls this the
        moment the real note is created -- in the same PR that adds it, so the two never disagree.

        WHAT MOVED (Dave, August 5, 2026): the target document, not the mechanism. This used to rewrite the
        notes line inside CHANGELOG.md's release block, and that block is gone -- which would have left the
        internal note with no inbound link anywhere, since the history overview's rows point at the
        development notes. Left alone it would not have ERRORED either: this function returns its input
        unchanged when it finds nothing, so the step would simply have gone quiet, which is the failure
        shape this repo keeps paying for. The link therefore moved to the one place that still lists
        releases -- the overview's Version cell.

        WHY THE VERSION CELL RATHER THAN A FOURTH COLUMN. The row's reader is a colleague looking for what a
        release was worth, which is tier 1's audience and therefore the internal note's. A new column would
        have changed the table's shape, and that shape is matched by $script:OverviewTableHeaderRe, which
        three readers share -- including cut-release.ps1's row inserter and the new-major guardrail. One
        cell, only on new rows, and 72 existing rows keep pointing where they always did.

        Returns the content unchanged (no throw) when the row cannot be found: this runs after a successful
        release, and failing there would make a completed release look broken over a link. The caller
        reports what happened.
    #>
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Version,
        # Both paths are relative to the overview file's own folder, exactly as the rows are written --
        # 'internal/3.x/3.6.0.md', not 'releases/internal/...'. $DevRelPath is what the cut wrote and is
        # accepted so the caller does not have to reconstruct it; it is only used to recognise the row.
        [Parameter(Mandatory)][string]$InternalRelPath,
        [string]$DevRelPath = ''
    )

    $usesCRLF = $Content.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }

    # The row's own shape: '| [3.6.0](<target>) | <date> | <type> | <title> |'. Anchored on the VERSION
    # inside the link text, so an overview holding every release ever cut cannot have an older row
    # rewritten by a call meant for the newest -- the same anchoring the changelog version needed.
    #
    # THE TARGET IS MATCHED AS 'anything', not as $DevRelPath, and that is what makes this idempotent
    # rather than once-only: a second call finds the row already pointing at the internal note and the
    # comparison below returns early. Matching only the dev path would make the second call a no-op by
    # accident (nothing matched) instead of by decision, and those two look identical from the outside.
    $v = [regex]::Escape($Version)
    $rowRx = '(?m)^(\|\s*)\[' + $v + '\]\(([^)]*)\)'
    $m = [regex]::Match($Content, $rowRx)
    if (-not $m.Success) { return $Content }
    if ($m.Groups[2].Value -eq $InternalRelPath) { return $Content }   # already pointed there

    $replacement = $m.Groups[1].Value + '[' + $Version + '](' + $InternalRelPath + ')'
    # Replace exactly the ONE match, by offset, rather than with a regex replace: a version string can
    # legitimately appear again further down (a row in an older major line, a sentence in the prose), and
    # a global replace would rewrite those too.
    $out = $Content.Substring(0, $m.Index) + $replacement + $Content.Substring($m.Index + $m.Length)
    return ($out.TrimEnd() + $nl)
}

# --- MOVED, NOT DELETED: Get-TouchedPlugins now lives in plugin-tree-lib.ps1 ------------------------
#
# It is in scope here regardless, because this file dot-sources that lib unconditionally at the top --
# so release-lib's own callers and its test suite reach it under exactly the same name as before.
#
# WHY IT MOVED. It went from matching a path shape to reading the plugin roots, which made it a function
# about the plugin tree rather than about a release. Keeping it here would have forced the fold script to
# dot-source THIS file to reach it -- and this file pulls in entry-scaffold-lib, three thousand lines,
# for a function that walks a list of strings. The fold runs immediately after a merge, directly on the
# trunk, so what it loads is worth being deliberate about. Moving one pure function down a layer costs
# nothing and lets the fold depend on a dependency-free lib instead.

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
        entry block. That line drives the per-plugin selection in cut-release.ps1, but is repo
        administration and should not be visible in a document written for a consumer; the root
        CHANGELOG and the development notes do show it.

        ITS CALLER IS THE CONSUMER DOCUMENT, since August 10, 2026 -- Format-RankedEntries under
        -StripAdminSections. It had none for two days: the per-plugin CHANGELOG it was written for was
        retired on August 8 and this function was deliberately kept because the line it strips still
        existed. That reasoning turned out to be right for the wrong reason -- what wanted it was not the
        line surviving but a reader who should not see it, and that reader was already being handed it.
    #>
    param([Parameter(Mandatory)][string]$EntryText)
    $t = [regex]::Replace($EntryText, '(?m)^Plugins:[^\r\n]*(\r?\n)?', '')
    return [regex]::Replace($t, '(\r?\n)\1\1+', '$1$1')
}

function Convert-RootRelativeLinks {
    <#
        Rewrites repo-root-relative markdown links with the given prefix; external (http/mailto),
        anchor (#), absolute (/) and ../ links are left alone. The engine behind Build-ReleaseNotes.
        It had a second caller until August 8, 2026 -- the per-plugin CHANGELOG link rewriter, which
        went with the documents it wrote.
    #>
    param(
        [Parameter(Mandatory)][string]$EntryText,
        [Parameter(Mandatory)][string]$Prefix
    )
    return [regex]::Replace($EntryText, '\]\((?!https?:|mailto:|#|/|\.\./)([^)]+)\)', "](${Prefix}`$1)")
}

# --- MOVED, NOT DELETED: Get-ReleaseChangeTypes now lives in entry-scaffold-lib.ps1 ----------------
#
# Convert-EntryHeadingToTitle below still calls it by exactly that name, and it is in scope because this
# file dot-sources entry-scaffold-lib unconditionally, at the top.
#
# IT MOVED FOR THE SAME REASON THE FENCE READER DID, and the same way: Resolve-EntryType in that lib needs
# it to RECOGNISE a type field in a pre-format heading, and the dependency can only run downward. Leaving
# it here meant that function had to make do with Get-BranchTypes alone -- which is repo-owned and
# therefore absent from the plugin mirror, so in a consumer the known-type list was EMPTY and every bullet
# new-internal-note.ps1 took from a historical heading silently lost its type.
#
# Recognition and validation are different questions and now use different lists: this one (the repo's
# table, or the canonical four) recognises, while only the repo's own table may accuse an author of a
# wrong type. See Resolve-EntryType's header.

function Set-EntryHeadingLevel {
    <#
        Pure: shifts EVERY heading in an entry block so the entry's own heading sits at $EntryLevel, and
        its inner sections move with it. Returns the block with LF newlines.

        WHY THE WHOLE BLOCK AND NOT JUST THE FIRST LINE. Until August 5, 2026 an entry was a heading plus
        prose, so re-levelling meant rewriting one line -- and the renderer did exactly that, with a '^'
        anchored to the start of the block. An entry now carries three H3 sections of its own
        ('### What does this change do?' and its siblings), so shifting only the heading would leave those
        sections at the level of the ENTRY above them: one entry rendering as four, in well-formed markdown
        that no parser would complain about.

        SHIFTED BY A DELTA, NOT SET TO A LEVEL. Every non-fenced heading moves by the same amount, which
        preserves the structure inside the entry whatever it is -- an H4 sub-heading in a body stays one
        level below the section it is in. Setting levels absolutely would need this function to know which
        headings are which, and it does not need to know.

        FENCE-AWARE, for the reason every parser in this file is: an entry documenting the entry format
        quotes these headings inside a fence -- this repo's own changelog does -- and shifting a quoted
        heading corrupts the example.

        A DELTA OF 0 RETURNS THE BLOCK UNCHANGED apart from the newline normalisation, so a document that
        renders entries at their native level pays nothing.

        THE DELTA IS MEASURED FROM THE BLOCK, NOT ASSUMED, and that is a repair rather than a refinement
        (August 5, 2026). It used to be '$EntryLevel - Get-EntryHeadingLevel' -- the shift needed by a block
        that is ALREADY at the canonical level, which every caller here happens to pass, since they read
        entries straight out of CHANGELOG.md. Handed a block that is already deeper the function therefore
        computed the wrong delta and, for the exact case of normalising one BACK to canonical, computed
        zero and silently returned the block untouched. Its own contract above promises "so the entry's own
        heading sits at $EntryLevel", which is what it now does.
        Measured on new-internal-note.ps1, which reads entries out of the developer notes (where they sit
        one level deeper, under the tier headings) and normalises them so the section readers can find
        anything: every bullet came out without its type, because the block handed to Resolve-EntryType had
        never been shifted and its sections were still one level below where that reader looks.

        A BLOCK WITH NO HEADING AT ALL is returned normalised and otherwise untouched -- there is nothing to
        measure from, and inventing a level would be worse than leaving prose alone.

        CLAMPED AT H6, which markdown has no level beyond. Reached only by a deeply nested body in a deeply
        nested document; clamping keeps the line a heading rather than turning it into literal '#######'
        text, which is what markdown renders past six.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$EntryText,
        [Parameter(Mandatory)][int]$EntryLevel
    )
    $lines = @(($EntryText -replace "`r`n", "`n") -split "`n")
    $fencedForLevel = Get-FencedLineFlags -Lines $lines
    $ownLevel = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($fencedForLevel[$i]) { continue }
        $hm = [regex]::Match($lines[$i], '^(#{1,6})\s')
        if ($hm.Success) { $ownLevel = $hm.Groups[1].Value.Length; break }
    }
    if ($ownLevel -eq 0) { return ($lines -join "`n") }
    $delta = $EntryLevel - $ownLevel
    if ($delta -eq 0) { return ($lines -join "`n") }

    $fenced = Get-FencedLineFlags -Lines $lines
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($fenced[$i]) { continue }
        $m = [regex]::Match($lines[$i], '^(#{1,6})(\s.*)$')
        if (-not $m.Success) { continue }
        $level = [Math]::Max(1, [Math]::Min(6, $m.Groups[1].Value.Length + $delta))
        $lines[$i] = ('#' * $level) + $m.Groups[2].Value
    }
    return ($lines -join "`n")
}

function Format-RankedEntries {
    <#
        Pure: renders entry blocks as ONE FLAT LIST, separated by '---', each re-levelled so its heading
        sits at $EntryLevel. Output is pure LF; $Entries may arrive CRLF (from the root CHANGELOG) and are
        normalized here.

        IT REPLACES Format-CategorizedEntries, AND THE DELETION IS THE POINT (Dave, August 5, 2026). That
        function grouped entries under category headings -- 'Features', 'Fixes', 'Documentation',
        'Maintenance', 'Other' -- derived from the branch type it parsed out of each entry's heading. Three
        things were wrong with that, and they compounded:

          * the branch prefix does not predict what a change is worth, which this repo measured: the single
            most consequential change for a consumer at v3.2.0 arrived on a chore/ branch;
          * so the grouping put a document's most important change third, under whichever label its prefix
            produced -- and the ranking added in #467 could only reorder the categories, not escape them;
          * and the type was INFERRED from a heading field, which is exactly the positional parse that
            silently broke when the merge date left the heading.

        The type is now STATED inside each entry, under its own section, so nothing is lost by not grouping
        on it -- and the reader meets the changes in the order they matter instead of in alphabetical-ish
        category order. Get-ReleaseCategories' label map and the Get-ReleaseCategoryTitles seam retire.

        $RankByTier: which tier's row orders the output. 0 -- the default -- means keep the arrival order,
        which for entries read out of CHANGELOG.md is the ranked order the FOLD already left there. A
        document is ordered by what ITS OWN reader gets out of each change, and the reader is named by the
        tier, so this is a tier number rather than an audience word: the internal note ranks on tier 1, the
        consumer document on tier 2.

        $BareTitles reduces each entry heading to its title (Convert-EntryHeadingToTitle) -- for the
        consumer document, whose reader has no branch and no PR number.

        $StripSignificance removes the impact table AND the older 'Tier: N' line. For the documents that
        travel OUTWARD only; the record keeps both. See Remove-EntryImpactTable for why the two differ.

        $StripAdminSections removes the four branch-administration sections and the 'Plugins:' line. It is
        the same objection as $BareTitles -- this reader has no branch and no PR number -- applied to where
        that metadata actually lives since August 6, 2026. Deliberately a SECOND switch rather than folded
        into $BareTitles: that one reduces a heading and is safe on any document, while this deletes named
        sections and must never reach the record.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Entries,
        [int]$EntryLevel = 2,
        [switch]$BareTitles,
        [int]$RankByTier = 0,
        [switch]$StripSignificance,
        [switch]$StripAdminSections
    )
    $items = @()
    $index = -1
    foreach ($e in $Entries) {
        $index++
        # THE SCORE IS READ BEFORE ANYTHING IS STRIPPED, because the strip below deletes the table it lives
        # in. That is what lets -StripSignificance and -RankByTier compose -- the consumer document needs both, and
        # in the other order they would rank an unscored pile. The same trap the retired renderer was
        # measured on with -BareTitles and the type.
        $rank = 0
        if ($RankByTier -gt 0) {
            $rank = Get-EntryImpactScore -Impact (Resolve-EntryImpact -EntryText $e) -Tier $RankByTier
        }
        $text = if ($BareTitles) { Convert-EntryHeadingToTitle -EntryText $e } else { $e }
        if ($StripSignificance) {
            # BOTH declarations, and the second is new here. While the changelog had tier sections the fold
            # consumed the 'Tier: N' line, so it could never reach a rendered document; the fold now carries
            # it, which puts a self-assigned tier on the path to a consumer's plugin cache unless it is
            # dropped here -- the same class of thing as a self-assigned score.
            $text = Remove-EntrySignificanceDeclaration -EntryText $text
            $text = Remove-EntryTierLine -EntryText $text
        }
        # STRICTLY AFTER Convert-EntryHeadingToTitle ABOVE, and that order is the whole trick: the heading
        # rewrite READS the 'Branch title' section this strip deletes. Reversed, the consumer document would
        # list every change as '`fix/x` changelog' -- the same read-before-strip trap -RankByTier and
        # -StripSignificance already document one case of, met a third time.
        if ($StripAdminSections) {
            $text = Remove-EntryAdminSections -EntryText $text
            # ITS FIRST PRODUCTION CALLER SINCE AUGUST 8, 2026, when the per-plugin CHANGELOG it was written
            # for was retired and the function was deliberately kept. Its own header names this reader: the
            # line is repo administration that drives the cut's plugin selection, and the record shows it.
            $text = Remove-EntryPluginsLine -EntryText $text
        }
        $items += [pscustomobject]@{
            Text  = (Set-EntryHeadingLevel -EntryText $text.Trim() -EntryLevel $EntryLevel)
            Rank  = $rank
            Order = $index
        }
    }

    if ($RankByTier -gt 0) {
        # SORTED ON (score desc, arrival asc) -- the second key is not decoration. PowerShell's Sort-Object
        # is NOT a stable sort, so on a five-point scale, where ties are the common case, sorting on the
        # score alone would let equal-scoring entries come out in a different order from one run to the
        # next. That would make a regenerated release document differ from the one already published, with
        # nothing having changed. The arrival index makes the result total.
        $items = @($items | Sort-Object -Property @{Expression = 'Rank'; Descending = $true}, @{Expression = 'Order'; Descending = $false})
    }

    return (@($items | ForEach-Object { $_.Text }) -join "`n`n---`n`n")
}

# RETIRED, AUGUST 8, 2026: Build-PluginChangelogSection, Build-PluginChangelogIntro,
# Add-PluginChangelogSection and Build-PluginReleaseCard -- the four builders of the per-plugin
# CHANGELOG.md and RELEASE.md card.
#
# They existed to give a consumer a history and a version card INSIDE the plugin cache, on the
# reasoning that the cache is all a consumer has. Measured before removing them: the marketplace
# source is a git clone of the WHOLE repo, so every consumer already holds the root CHANGELOG.md
# and the full releases/ tree at ~/.claude/plugins/marketplaces/<marketplace>/. The ten files these
# functions wrote came to 11,684 lines of second copy -- and a copy that could disagree with the
# original, which is precisely what lint checks 9 and 17 were built to police. Both checks are gone
# with the functions: there is nothing left to hold against anything.
#
# One repository, one product, one changelog. Decision by Dave, August 8, 2026.
#
# Convert-EntryLinksForPluginChangelog went with them (its only callers were these), while
# Format-RankedEntries did NOT -- the release notes and the consumer document still uses it.

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

function Get-RelativeLinkPath {
    <#
        Pure: the relative link from one repo-relative directory to a repo-relative file, both with
        forward slashes -- 'audience/4.x/4.9.0.md' from 'releases' to 'releases/audience/4.x/4.9.0.md',
        and '../../releases/development/4.x/4.9.0.md' from 'workflow-davekjohn/releases' to that file.

        WHY IT EXISTS (August 14, 2026). cut-release.ps1 built the history-table row with
        `-replace '^releases/'`, which is correct only while the history README sits directly in
        releases/ -- its own comment said a repo answering the seam with a root outside that directory
        "would need a '../' here, which no repo has yet asked for". The workflow folder is that ask:
        a consumer's history lives at workflow-davekjohn/releases/README.md while the generated
        development notes stay at the repo root. Same class as the v4.6.0 dead-row bug, caught before
        shipping this time rather than after.

        [System.IO.Path]::GetRelativePath does not exist on the .NET Framework Windows PowerShell 5.1
        runs on -- the same reason cut-release's collision guard keeps repo-relative strings.
    #>
    param(
        [AllowEmptyString()][string]$FromDir = '',
        [Parameter(Mandatory)][string]$To
    )
    # NOT $from/$to: PowerShell variable names are case-INsensitive, so '$to = @(...)' would assign to
    # the [string]-typed parameter $To itself -- and the type constraint coerces the segment array back
    # into one space-joined string, whose [0] is then a single character. Measured on this function's
    # first test run.
    $fromParts = @($FromDir -split '/' | Where-Object { $_ })
    $toParts   = @($To -split '/' | Where-Object { $_ })
    $i = 0
    while ($i -lt $fromParts.Count -and $i -lt $toParts.Count -and $fromParts[$i] -ceq $toParts[$i]) { $i++ }
    $parts = @()
    for ($u = $i; $u -lt $fromParts.Count; $u++) { $parts += '..' }
    if ($i -lt $toParts.Count) { $parts += @($toParts[$i..($toParts.Count - 1)]) }
    return ($parts -join '/')
}

function Build-ReleaseNotes {
    <#
        Builds the full release notes (the releases/development/<X>.x/<X.Y.Z>.md file) from the
        entry blocks. Pure string out -- DELIBERATELY hard LF, because this is a NEW, standalone file
        with no existing newline style of its own, unlike the root CHANGELOG.md which detects and
        keeps its CRLF style via $nl. The entries come from that CRLF root CHANGELOG -- so here they
        are explicitly normalized to LF (#103, Victor #5), alongside the link rewriting below.

        TWO SHAPES, ONE FUNCTION (the tier model, August 5, 2026):

          -TierGroups  the pending entries grouped by tier. Renders one '## Tier <n> - <audience>'
                       section per tier IN THE ORDER GIVEN, its entries as a flat list one level under
                       it ('### <entry>'). This is the document the tier model produces: complete, raw,
                       and structured the way CHANGELOG.md itself is. A tier with no entries is omitted.
          -Entries     one flat list, entries at '##'. For a repo whose entries declare no tier at all:
                       every one reads as tier 0, and a single '## Tier 0' wrapper around the whole
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
    # start with ../. Format-RankedEntries then re-levels the entries and normalizes to LF, so the CRLF
    # of the source CHANGELOG does not cross the pure-LF output.
    if ($TierGroups) {
        $sections = @()
        foreach ($group in @($TierGroups)) {
            $groupEntries = @($group.Entries | Where-Object { $_ -and $_.Trim() })
            if ($groupEntries.Count -eq 0) { continue }
            $linked = @($groupEntries | ForEach-Object { Convert-RootRelativeLinks -EntryText $_ -Prefix $LinkPrefix })
            # Entries one level under the tier heading, their own sections one level under that:
            # '## Tier 2 - consumers' -> '### <entry>' -> '#### What does this change do?'.
            #
            # RANKED FROM TIER 1 UP, AND DELIBERATELY NOT AT TIER 0 (issue #467). Tier 0 is the RECORD --
            # complete and chronological, which is what a record is for -- and its entries are never asked
            # for a score in the first place. Unranked here means DOCUMENT ORDER, which is the order the
            # fold left CHANGELOG.md in, so tier 0 inherits a defined order rather than losing one.
            #
            # THE DECLARATIONS ARE NOT STRIPPED HERE, and this is the one document where they survive. The
            # cut EMPTIES the changelog, so these notes are the last place holding the reason behind each
            # ranking; deleting it would leave every order asserted with its justification thrown away. The
            # documents that travel outward strip it -- see Build-ConsumerNotes.
            $rankByTier = if ([int]$group.Tier -ge 1) { [int]$group.Tier } else { 0 }
            $inner = Format-RankedEntries -Entries $linked -EntryLevel 3 -RankByTier $rankByTier
            $sections += ("## " + (Get-ReleaseTierHeading -Tier ([int]$group.Tier)) + "`n`n" + $inner)
        }
        $body = ($sections -join "`n`n")
    } else {
        $linked = @($Entries | ForEach-Object { Convert-RootRelativeLinks -EntryText $_ -Prefix $LinkPrefix })
        $body = Format-RankedEntries -Entries $linked -EntryLevel 2
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

        AND SINCE THE TYPE LEFT THE HEADING ALTOGETHER, THE COMMON CASE IS NO TRAILING FIELD AT ALL:
        '## #475 <md> A significance score per entry' carries only the leading '#NN'. That case USED TO
        RETURN THE HEADING UNCHANGED -- the guard below asked whether any trailing field had been dropped,
        which is a different question from whether anything had been dropped, and with the tail empty the
        answer was no. So the consumer document, whose whole reason for calling this is that its reader
        has no PR numbers, would have kept every one of them. Caught by this file's own suite; the guard
        now asks about both ends.
    #>
    param([Parameter(Mandatory)][string]$EntryText)
    $md = [char]0x00B7
    $lines = $EntryText -split "(`r?`n)", 2
    $heading = $lines[0]
    $hm = [regex]::Match($heading, '^(#+)\s+(.*)$')
    if (-not $hm.Success) { return $EntryText }

    # THE DOSSIER HEADING NAMES THE BRANCH, AND THIS DOCUMENT'S READER HAS NO BRANCH. Since August 6, 2026
    # an entry opens with '## `feat/x` changelog' and its human-readable name lives in 'Branch title'
    # -- so for the consumer document the title IS that section. Without this the tier-2 document, the one written
    # for consumers, would list its changes as "`feat/x` changelog": no middot and no '#NN' in that heading,
    # so the field-dropping below leaves it exactly as it found it.
    #
    # SAME RULE AS THE REST OF THIS FUNCTION, applied to a new shape rather than a new rule -- the PR number,
    # the type and the date are dropped here for being internal administration, and a branch name is the
    # purest example of it. The developer notes and CHANGELOG.md keep the heading, as they keep the others.
    $branchHeading = [regex]::Match($hm.Groups[2].Value, '^`([^`]+)`\s+\S+$')
    if ($branchHeading.Success) {
        $described = Get-EntrySectionAnswer -EntryText $EntryText -Key 'Description'
        # No description, no rewrite: an entry that never filled it in keeps the branch heading, which is
        # ugly and TRUE. Inventing a title from the branch name would publish a slug as a change name.
        if ($described) {
            $title = @($described -split '\r?\n' | Where-Object { $_.Trim() })[0].Trim()
            if ($title) {
                $rest = if ($lines.Count -gt 1) { ($lines[1] + $lines[2]) } else { '' }
                return $hm.Groups[1].Value + ' ' + $title + $rest
            }
        }
        return $EntryText
    }

    $parts = @($hm.Groups[2].Value -split "\s*$md\s*")
    $types = Get-ReleaseChangeTypes
    $first = if ($parts[0] -match '^#\d+$') { 1 } else { 0 }

    # THE TAIL HAS A GRAMMAR, so it is matched rather than walked: at most one date, and before it at
    # most one type. Anything else is title. A greedy "keep eating administrative-looking fields" loop
    # was written first and this file's own suite caught it -- on '### #12 <md> Fix <md> Fix', an entry
    # whose title IS a type name, it ate both and returned the heading unchanged. Two types in a row
    # cannot both be the type; the grammar says so and the loop could not.
    #
    # 'Other' no longer needs excluding: Get-ReleaseChangeTypes returns what the branch table produces and
    # nothing else, where the retired Get-ReleaseCategories appended the catch-all LABEL this repo prints.
    # A field reading 'Other' is therefore a title by construction rather than by a special case.
    $isMeta = {
        param($f, $kind)
        if ($kind -eq 'date') { return $f -match '^\d{4}-\d{2}-\d{2}$' }
        return ($types -contains $f)
    }
    $last = $parts.Count - 1
    if ($last -ge $first -and (& $isMeta $parts[$last].Trim() 'date')) { $last-- }
    if ($last -ge $first -and (& $isMeta $parts[$last].Trim() 'type')) { $last-- }

    # NOTHING WAS ADMINISTRATION AT EITHER END -- so there is no (metadata + title) shape here and the
    # heading is left exactly as it was rather than guessed at. Both ends are tested, which is the fix:
    # asking only about the tail ($last -eq $parts.Count - 1) called a heading untouched whenever it had no
    # trailing field, which since the type moved into its own section is EVERY current entry -- so the
    # leading '#NN' this function exists to drop survived.
    if (($first -eq 0 -and $last -eq ($parts.Count - 1)) -or $last -lt $first) { return $EntryText }
    $title = (@($parts[$first..$last]) -join " $md ").Trim()
    if (-not $title) { return $EntryText }

    $rest = if ($lines.Count -gt 1) { ($lines[1] + $lines[2]) } else { '' }
    return "$($hm.Groups[1].Value) $title$rest"
}

function Build-ConsumerNotes {
    <#
        Builds the consumer document (releases/consumer/<dir>/<X.Y.Z>.md) from the TIER-2 entries of
        the release. Pure string out, hard LF -- a new standalone file, like Build-ReleaseNotes.

        $Entries is the selection, not the whole release: the caller passes the tier-2 group's entries and
        this renders all of them. The selection lives in the caller because grouping is
        Get-PullRequestEntriesByTier's job -- it already resolves every entry's declared impact once, and
        doing it again here would be a second reader of one fact.

        AN EMPTY SELECTION RETURNS THE HEADER AND NOTHING ELSE, rather than throwing. cut-release never
        gets here with nothing (its bump gate refuses a minor with no tier-2 entry), so a throw would
        only ever fire in a test or a hand call -- and a document that says "this release has nothing
        for a consumer" is a truthful answer to a strange question, while an exception is not.

        -BareTitles is passed to the renderer rather than applied here, so the score is read off each entry
        before anything about it is reduced -- see Format-RankedEntries for what stripping too early costs.
        Links are rewritten first, at the same depth the developer notes use (both documents sit three
        folders down).

        -StripAdminSections is passed for the same reason and has the same ordering constraint, one step
        sharper: the four sections it deletes include the one -BareTitles READS to build the heading. Both
        travel to the renderer so that order lives in one place rather than being re-established here.
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
    # published guess costs -- the retired remove-before-publishing marker is in this file's history for exactly that.
    # The number does its work by deciding the order and then gets out of the way; the reason stays in the
    # development notes, where it is auditable by the people who can check it.
    $body = if ($linked.Count -gt 0) {
        Format-RankedEntries -Entries $linked -EntryLevel 2 -BareTitles -RankByTier 2 -StripSignificance -StripAdminSections
    } else {
        ''
    }

    $rocket = [char]::ConvertFromUtf32(0x1F680)
    $titleLine = if ($Title) { "$Title`n`n" } else { '' }
    $header = "# Release notes v$Version $rocket`n`n**Date:** $Date  `n**Type:** $Type`n`n$titleLine"

    return ($header + $body + "`n")
}

function Build-ReleaseNoteDraft {
    <#
        The ONE hand-written release document, as a draft: a named section per reader. Pure string out.

        WHAT THIS REPLACED, AND THE MEASUREMENT THAT CHOSE THE SHAPE (Dave, August 10, 2026). There were
        two hand-written documents per release -- an internal note for the organisation and a consumer
        document -- and at every one of the twelve releases since the internal tier existed, BOTH were
        written, about the same changes. Dave proposed one. The question was whether one document can serve
        both readers, and it was answered by measuring v4.2.0's internal note (962 words) against the
        consumer writing norm's test 2 (does this describe our effort or their outcome):

          ~365 words (38%)  could appear in a consumer-facing section -- and were, in the other document,
                            rewritten in a second register. THAT is the duplication.
          ~597 words (62%)  could not, and the largest block of it -- 'what it is worth', 316 words -- is
                            not an outlier but the entire reason the organisational tier exists.

        So a BLENDED document was refused: it would have to drop the 62% or break the norm. A document with
        a NAMED SECTION PER READER keeps each register intact, writes the shared 38% once, and is one file,
        one editing pass, one publish. The consumer section is what 'what is different now' used to be, so
        that heading is gone rather than moved -- it was the duplicated half.

        THE CONSUMER SECTION IS PRE-FILLED AND THE ORGANISATIONAL ONE CANNOT BE. The tier-2 entries are a
        selection the entry authors already made, rendered exactly as the consumer document rendered them
        (bare titles, ranked on tier 2, significance and branch administration stripped). What the work is
        worth cannot be derived from a changelog, so those headings arrive empty, with the guidance in an
        HTML comment the writer deletes.

        NO CONSUMER SECTION WHERE NO ENTRY REACHED TIER 2, and that is the tier-1-only minor: the version
        moves for everyone and nobody outside is handed a section about work they cannot see. A heading with
        nothing under it is worse than no heading -- measured on the shape this replaces, where an empty
        named question shipped into every document that travelled outward.
    #>
    param(
        [AllowEmptyCollection()][string[]]$Entries = @(),
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date,
        [Parameter(Mandatory)][string]$Type,
        [string]$Title = '',
        [hashtable]$Wording = @{},
        [string]$LinkPrefix = '../../../'
    )
    # Merged over the defaults rather than replacing them, so a repo that renames one heading does not
    # have to restate the rest -- the same contract the note script's wording seam already had.
    $w = @{
        Title             = 'Release notes'
        AudienceLabel     = 'For whom'
        Audience          = 'consumers of this product, and colleagues in the organisation -- one section each'
        SectionConsumers  = 'For consumers'
        HintConsumers     = @(
            'DRAFT. These are the tier-2 entries, still in the words their authors wrote for someone',
            'reviewing a diff. Rewrite them for someone deciding whether to update: what they can now do,',
            'in the second person, most urgent first, and say plainly whether they must act. The seven',
            'tests are in the cut-release skill. Delete this comment when you are done.'
        ) -join "`n     "
        SectionValue      = 'What it is worth'
        HintValue         = @(
            'FOR THE ORGANISATION, not for the consumer -- this is the section the consumer half is not',
            'allowed to contain. The only part that cannot be generated. Think in time, risk and reduced',
            'dependence on a developer. For example: "changing an amount took five edits in code and can',
            'now be done by the team itself".'
        ) -join "`n     "
        SectionOpen       = 'What was still open at this release'
        HintOpen          = @(
            'What was deliberately left, and with whom the next step sits. "Nothing" is also an answer',
            '-- leave the heading standing with that one line.',
            'Write it as a SNAPSHOT of this release, not as a claim about the present: a document that is',
            'published does not move with reality, so a line here goes stale in hours rather than months.'
        ) -join "`n     "
    }
    foreach ($k in @($Wording.Keys)) { if ($Wording[$k]) { $w[$k] = $Wording[$k] } }

    $real = @($Entries | Where-Object { $_ -and $_.Trim() })

    $rocket = [char]::ConvertFromUtf32(0x1F680)
    $out = New-Object System.Collections.Generic.List[string]
    $out.Add("# $($w.Title) v$Version $rocket")
    $out.Add('')
    $out.Add("**Date:** $Date  ")
    $out.Add("**Type:** $Type  ")
    $out.Add("**$($w.AudienceLabel):** $($w.Audience)")
    $out.Add('')
    if ($Title) { $out.Add($Title); $out.Add('') }

    if ($real.Count -gt 0) {
        $linked = @($real | ForEach-Object { Convert-RootRelativeLinks -EntryText $_ -Prefix $LinkPrefix })
        # THE SAME SWITCHES THE CONSUMER DOCUMENT USED, called rather than re-derived: the score orders the
        # section and is then stripped, and the branch administration goes. Entries sit one level deeper
        # than before because they now live under a section heading rather than under the H1.
        $body = Format-RankedEntries -Entries $linked -EntryLevel 3 -BareTitles -RankByTier 2 `
            -StripSignificance -StripAdminSections
        $out.Add("## $($w.SectionConsumers)")
        $out.Add('')
        $out.Add("<!-- $($w.HintConsumers) -->")
        $out.Add('')
        $out.Add($body)
        $out.Add('')
    }

    $out.Add("## $($w.SectionValue)")
    $out.Add('')
    $out.Add("<!-- $($w.HintValue) -->")
    $out.Add('')
    $out.Add("## $($w.SectionOpen)")
    $out.Add('')
    $out.Add("<!-- $($w.HintOpen) -->")

    return (($out -join "`n") + "`n")
}

function Build-GitHubReleaseBody {
    <#
        The body of a GitHub Release: the release title, an optional pointer at the attached document,
        and one linked line per change that landed. Pure string out, hard LF.

        WHY THIS IS GENERATED AND THE OTHER DOCUMENTS ARE NOT (Dave, August 10, 2026). The body used to be
        a hand-written tier document, and that coupled the Release page to which tier happened to exist:
        the internal note is the body precisely BECAUSE it was the only tier written at every release,
        which is the reasoning that made a note mandatory at a patch nobody needed one for. A generated
        body cuts the dependency -- the page can be published at any release, including one with no
        hand-written document at all, and the hand-written documents become attachments rather than the
        page itself.

        THE COMPLETE LIST, EVERY TIER. This answers "what landed", which is the one question a Release
        page is read for by someone who arrived from a tag or a diff, and the tier ladder does not apply:
        a repo-internal change is still a change that landed. The tiers decide which DOCUMENT a change
        appears in; this is not one of those documents.

        AN ENTRY WITH NO PR LINK IS LISTED WITHOUT ONE, never dropped. A hand-filed entry, or one whose
        fold could not reach the PR, would otherwise vanish from the only complete list -- and it would
        vanish silently, which is the failure mode this repo keeps meeting. Same reason the title falls
        back to the entry's own heading rather than to nothing.

        IT MUST BE BUILT AT CUT TIME, which is not a preference. The cut EMPTIES CHANGELOG.md, so the
        entries this reads do not exist a moment later; there is no way to regenerate this body after the
        fact from anything but the archived notes.
    #>
    param(
        [AllowEmptyCollection()][string[]]$Entries = @(),
        [Parameter(Mandatory)][string]$Version,
        [string]$Title = '',
        [string]$NotePointer = ''
    )
    $real = @($Entries | Where-Object { $_ -and $_.Trim() })

    $items = @()
    foreach ($e in $real) {
        # The readable name, from the section that owns it -- with the entry's own heading as the fallback
        # so a nameless entry is still listed. Retired section names come along via Get-EntrySectionBody.
        $name = ''
        $described = Get-EntrySectionBody -EntryText $e -Key 'Description'
        if ($described) { $name = @($described -split '\r?\n' | Where-Object { $_.Trim() })[0].Trim() }
        if (-not $name) {
            $hm = [regex]::Match($e, '^\s*#+\s+(.*)$', 'Multiline')
            if ($hm.Success) { $name = $hm.Groups[1].Value.Trim() }
        }
        if (-not $name) { $name = 'untitled change' }

        # The link the FOLD wrote, read out of the section that holds it rather than off the whole entry:
        # an entry body may quote a PR link of its own, and the first match tree-wide would take that one.
        $url = ''
        $prBody = Get-EntrySectionBody -EntryText $e -Key 'PullRequest'
        if ($prBody) {
            $lm = [regex]::Match($prBody, '\[PR #(\d+)\]\(([^)]+)\)')
            if ($lm.Success) { $url = $lm.Groups[2].Value }
        }

        $items += if ($url) { "- [$name]($url)" } else { "- $name" }
    }

    $out = @()
    if ($Title) { $out += @($Title, '') }
    if ($NotePointer) { $out += @($NotePointer, '') }
    $out += '## What landed'
    $out += ''
    if ($items.Count -gt 0) { $out += $items } else { $out += '_No changes were pending at this release._' }

    return (($out -join "`n") + "`n")
}
