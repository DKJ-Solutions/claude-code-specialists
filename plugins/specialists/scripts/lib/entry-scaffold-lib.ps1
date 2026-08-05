<#
.SYNOPSIS
    The changelog entry's own format, in one place: the scaffold strings new-changelog-entry.ps1
    WRITES and open-pr.ps1 REFUSES TO SHIP, the 'Tier: N' line that declares an entry's impact, and
    the changelog sections those tiers are folded into.

.DESCRIPTION
    Dot-source it:

        . (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

    WHY THIS FILE EXISTS AT ALL, given it holds three strings. Those three had to be known by two
    scripts that must never disagree about them: one writes the scaffold, the other blocks a PR whose
    entry still carries it. A copy in each would make the gate silently miss whatever the writer
    changed -- a drift guard that drifts, which is worse than no guard because it reports success. So
    the wording became a single source the moment the second reader appeared, exactly as CLAUDE.md
    requires for a rule living in two places.

    THE TIER LINE JOINED IT FOR THE SAME REASON, WITH ONE MORE READER (the tier model, August 5,
    2026). 'Tier: N' is written by new-changelog-entry.ps1, validated by open-pr.ps1 before a PR can
    ship, and read-then-REMOVED by fold-changelog-entry.ps1, which uses it to pick which of the
    changelog's three tier sections the entry lands in. Three scripts, one format: a copy in each is
    how a fold starts filing tier-2 work under repo-internal without anything erroring.

    REPO-OWNED, WITH BUILT-IN DEFAULTS (#410). Each string comes from an OPTIONAL function in the
    consumer's scripts/repo-config.ps1 -- Get-EntryTitlePlaceholder, Get-EntryBodyHeading,
    Get-EntryBodyPlaceholder -- probed with Get-Command and falling back to the English value
    new-changelog-entry.ps1 used to hardcode. A consumer that defines none of them is unaffected.
    (Get-EntryFallbackType is deliberately NOT here: it is a changelog TYPE, not scaffold prose --
    'Chore' is a legitimate final value, so it can never be evidence of an unedited entry.)

    Pure ASCII (repo convention for .ps1).
#>

# The English fallbacks, and the ONLY copy of them. new-changelog-entry.ps1 held these literals until
# the gate needed the same list; it now reads them from here.
$script:EntryScaffoldDefaults = [ordered]@{
    Title         = 'TODO: title'
    BodyHeading   = '**To do / where I left off:**'
    BodyPlaceholder = 'TODO: what still needs to happen on this branch, and where you left off.'
}

function Get-EntryScaffoldWording {
    <#
        Returns the scaffold wording as an object with Title, BodyHeading and BodyPlaceholder --
        this repo's answers where repo-config.ps1 gives them, the English defaults otherwise.

        The caller is expected to have dot-sourced repo-config.ps1 already (both callers do, for other
        reasons); this function only PROBES, it does not load it. That keeps it usable from a test that
        wants the bare defaults, by simply not defining the getters.

        An override that is present but EMPTY is ignored rather than honoured. A getter returning ''
        would otherwise blank a marker, and a blank marker matches every entry ever written -- so the
        gate would refuse every PR in the repo, which is the worst possible failure for a guard whose
        whole job is to be trusted.
    #>
    $out = [ordered]@{}
    $map = @{
        Title           = 'Get-EntryTitlePlaceholder'
        BodyHeading     = 'Get-EntryBodyHeading'
        BodyPlaceholder = 'Get-EntryBodyPlaceholder'
    }
    foreach ($key in @('Title', 'BodyHeading', 'BodyPlaceholder')) {
        $value = $script:EntryScaffoldDefaults[$key]
        $getter = $map[$key]
        if (Get-Command $getter -ErrorAction SilentlyContinue) {
            $v = & $getter
            if ($v) { $value = $v }
        }
        $out[$key] = $value
    }
    return [pscustomobject]$out
}

function Get-EntryTextOutsideFences {
    <#
        Pure: the entry's text with every fenced code block removed, for a caller that wants to match
        STRUCTURE rather than a mention of it.

        ITS OWN FUNCTION BECAUSE TWO READERS NEEDED THE SAME STRIPPING. The scaffold gate needs it
        because an entry may legitimately quote the scaffold while documenting this very mechanism --
        this repo's own docs do -- and the tier reader needs it for exactly the same reason, one
        mechanism later. This repo has measured the cost of the alternative four times in one day: a
        matcher satisfied by a MENTION rather than a use.

        Deliberately simple: pair up ``` runs and drop what is between them. An unclosed fence
        swallows the tail, which is the safe direction for both callers -- it can only cause a missed
        finding, never a false accusation against text somebody did write.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)
    $kept = New-Object System.Collections.Generic.List[string]
    $inFence = $false
    foreach ($line in ($EntryText -split '\r?\n')) {
        if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
        if (-not $inFence) { $kept.Add($line) }
    }
    return ($kept -join "`n")
}

# --- The tier line -------------------------------------------------------------------------------
#
# 'Tier: N' declares how far an entry reaches, and the changelog is split into one section per tier.
# The ladder (Dave, August 5, 2026):
#
#   Tier 0 -- nobody outside this repo's own developers notices. Docs, config, repo-internal work.
#   Tier 1 -- a colleague working on this project gets something out of it.
#   Tier 2 -- a consumer of the product notices it.
#
# CUMULATIVE, NOT THREE BOXES: tier 2 implies tier 1, so a tier-2 entry appears in both the internal
# note and the highlights. That is what keeps 'tier' one axis of impact instead of three categories
# somebody has to choose between.
#
# THE LABEL IS NOT REPO-OWNED, unlike the four scaffold strings above, and that is deliberate rather
# than an omission. 'Tier:' is a machine-read metadata key -- the same class as the 'Plugins:' line
# the fold writes, and the same class the language rule calls a technical identifier that keeps its
# original form. The three scripts that read it must agree on the literal; a translated key would
# make an entry unreadable to the fold in the repo that translated it.
#
# THE DEFAULT IS THE HARMLESS END, AND THAT IS THE WHOLE SAFETY ARGUMENT. An entry with no tier line
# is tier 0, so forgetting to classify cannot promote work into a consumer-facing document. It has a
# cost -- a release cannot be cut out of tier-0 work alone -- but that cost is LOUD: the cut refuses
# and names the entries. The reverse default would be silent, and would be wrong in the one direction
# that reaches people outside this repo.
$script:EntryTierLabel   = 'Tier'
$script:EntryTierDefault = 0
$script:EntryTierMax     = 2

function Get-EntryTierLabel {
    <# The literal metadata key ('Tier'), so no caller writes it out for itself. #>
    return $script:EntryTierLabel
}

function Get-EntryTierMax {
    <# The highest tier the model has (2). Read by the writer, the validator and the fold. #>
    return $script:EntryTierMax
}

function Format-EntryTierLine {
    <# The single line an entry carries, e.g. 'Tier: 0'. One formatter, so the writer and the parser
       below cannot disagree about the spacing. #>
    param([int]$Tier = $script:EntryTierDefault)
    return "$($script:EntryTierLabel): $Tier"
}

function Resolve-EntryTier {
    <#
        Pure: reads the tier an entry declares. Returns an object with

          Tier      the tier as an int -- the default (0) when nothing is declared OR when what is
                    declared cannot be honoured, so a caller that ignores Error still fails safe
                    towards the harmless end rather than crashing.
          Declared  $true when a 'Tier:' line was found outside fenced code.
          Raw       exactly what stood after the colon, for quoting back at the author.
          Error     $null when all is well; otherwise the reason, ready to print.

        AN OBJECT RATHER THAN AN INT, and the reason is the failure this has to make impossible. A
        'Tier: 5' or a 'Tier: two' that silently read back as 0 would file the change as repo-internal
        -- correct-looking output, wrong document, and nothing to notice. So the malformed case is
        reported instead of absorbed, and open-pr.ps1 refuses the PR over it while the branch is still
        the only thing affected.

        FENCE-AWARE, and the FIRST match outside a fence wins. An entry documenting the tier model
        writes 'Tier: 2' inside a fence -- this file's own repo does it in the docs shipped with this
        change -- and a parser that cannot tell a quote from a declaration gets disabled by whoever
        hits it first.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $result = [pscustomobject]@{
        Tier     = $script:EntryTierDefault
        Declared = $false
        Raw      = ''
        Error    = $null
    }

    $body = Get-EntryTextOutsideFences -EntryText $EntryText
    $rx = '(?m)^' + [regex]::Escape($script:EntryTierLabel) + ':[ \t]*(.*?)[ \t]*$'
    $m = [regex]::Match($body, $rx)
    if (-not $m.Success) { return $result }

    $result.Declared = $true
    $result.Raw = $m.Groups[1].Value

    if ($result.Raw -notmatch '^\d+$') {
        $result.Error = "'$($script:EntryTierLabel): $($result.Raw)' is not a tier -- write a whole number from 0 to $($script:EntryTierMax)."
        return $result
    }
    $value = [int]$result.Raw
    if ($value -lt 0 -or $value -gt $script:EntryTierMax) {
        $result.Error = "tier $value does not exist -- the tiers are 0 to $($script:EntryTierMax)."
        return $result
    }
    $result.Tier = $value
    return $result
}

function Remove-EntryTierLine {
    <#
        Removes the 'Tier:' line (and the blank line it leaves behind) from an entry block.

        THE FOLD CONSUMES THE LINE RATHER THAN CARRYING IT (Dave, August 5, 2026). Once the entry sits
        under '## Tier 2 - Pull Requests', the section states the tier -- and a line inside the entry
        restating it would be the same fact in two places, which is the drift shape this repo has paid
        for three times. So the line's whole life is the branch: written when the entry is created,
        read when it is folded, gone afterwards.

        Same shape as Remove-EntryPluginsLine in release-lib.ps1, deliberately: both strip one
        bookkeeping line and collapse the double blank it leaves. It lives HERE rather than there
        because the fold reaches release-lib only when the repo happens to have it (see that
        dot-source's guard), while this lib travels with the fold itself.

        FENCE-AWARE, AND ONLY THE FIRST DECLARATION IS REMOVED -- which is not symmetry with the reader
        for its own sake but the case that arrived immediately. The changelog entry for the change that
        introduced this model quotes 'Tier: 0' inside a fence to explain the format; a blind regex would
        have deleted that line out of the fence while folding, silently damaging the one entry that
        documents the mechanism. Removing exactly what Resolve-EntryTier READ is the only behaviour
        that cannot surprise: what the fold consumed is what the fold acted on.

        The line ending is preserved rather than normalised: the caller has already matched the
        changelog's own style, and rewriting it here would put CRLF and LF in one entry.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)
    $label = [regex]::Escape($script:EntryTierLabel)
    # Split KEEPING the separators, so the original CRLF/LF of every line survives the round trip.
    $parts = [regex]::Split($EntryText, '(\r?\n)')
    $out = New-Object System.Collections.Generic.List[string]
    $inFence = $false
    $removed = $false
    for ($i = 0; $i -lt $parts.Count; $i++) {
        # Odd indices are the captured separators; only even ones are line content.
        if ($i % 2 -eq 1) { continue }
        $line = $parts[$i]
        $sep = if ($i + 1 -lt $parts.Count) { $parts[$i + 1] } else { '' }
        if ($line -match '^\s*```') {
            $inFence = -not $inFence
        } elseif ((-not $inFence) -and (-not $removed) -and $line -match "^$label`:") {
            $removed = $true
            continue
        }
        $out.Add($line + $sep)
    }
    $t = ($out -join '')
    if (-not $removed) { return $t }
    return [regex]::Replace($t, '(\r?\n)\1\1+', '$1$1')
}

# --- Where a folded entry goes: the changelog's tier sections -------------------------------------
#
# The other half of the tier line. The line says which tier an entry is; this says which SECTION that
# tier is filed under, and the two live in one file for the reason this lib exists at all: the writer,
# the validator, the fold and the release cut must not be able to disagree about either.
#
# THE DEFAULT HEADING'S ONLY COPY IS HERE. It used to be stated three times -- fold-changelog-entry.ps1
# as a local literal, release-lib.ps1 inside a regex, and repo-config.ps1 as the seam's value -- which
# is the arithmetic this repo keeps paying for: three copies, one of which is edited. All three now read
# this resolver.
$script:DefaultChangelogHeading = '## Pull Requests'

function Resolve-ChangelogTierSections {
    <#
        Pure: normalises whatever a repo's seam returns into an ordered list of

          Tier     the tier as an int
          Heading  the literal '## ' heading line that tier's entries are folded under

        in the order the sections appear in the document. $TierHeadings may be an ordered dictionary,
        a plain hashtable, or $null/empty; empty means "this repo has no tier split", and the result is
        the single tier-0 section named by $FallbackHeading -- which is exactly the behaviour the fold
        had before tiers existed, expressed as a one-entry map rather than as a separate code path.

        A LIST OF OBJECTS RATHER THAN THE DICTIONARY ITSELF, and that is a bug this prevents rather
        than a style choice. [ordered]@{ 2 = '## ...' } is an OrderedDictionary, whose indexer takes
        BOTH a key and a POSITIONAL INDEX -- and the positional overload wins for an integer, so
        $map[2] returns the THIRD VALUE rather than the value for key 2. In a map ordered 2, 1, 0 that
        hands every tier its neighbour's heading, entries get filed under the wrong section, and nothing
        errors. Measured on the first run of this very function, one screen below the comment warning
        about it: the enumerator is used here precisely so no caller -- including this one -- can reach
        for the indexer.

        A plain hashtable has no order of its own, so it is sorted highest tier first -- the order this
        model reads in, and a defined answer rather than PowerShell's internal bucket order.
    #>
    param(
        $TierHeadings = $null,
        [string]$FallbackHeading = ''
    )
    if (-not $FallbackHeading) { $FallbackHeading = $script:DefaultChangelogHeading }

    $sections = New-Object System.Collections.Generic.List[pscustomobject]
    if ($TierHeadings) {
        # GetEnumerator, never the indexer -- see the docstring. DictionaryEntry gives Key and Value
        # together, so there is no second lookup that could resolve differently.
        $pairs = @()
        foreach ($entry in $TierHeadings.GetEnumerator()) {
            $heading = [string]$entry.Value
            if (-not $heading) { continue }
            $pairs += [pscustomobject]@{ Tier = [int]$entry.Key; Heading = $heading.Trim() }
        }
        # An unordered hashtable gets a defined order rather than an arbitrary one; an OrderedDictionary
        # keeps the order it was declared in, because that order IS the repo's answer about the document.
        if ($TierHeadings -is [hashtable]) { $pairs = @($pairs | Sort-Object Tier -Descending) }
        foreach ($p in $pairs) { $sections.Add($p) }
    }
    if ($sections.Count -eq 0) {
        $sections.Add([pscustomobject]@{ Tier = 0; Heading = $FallbackHeading })
    }
    return @($sections.ToArray())
}

function Get-ChangelogTierSections {
    <#
        This repo's tier sections, read from the seam: Get-ChangelogTierHeadings where the repo defines
        it, otherwise a single section from the legacy Get-ChangelogHeading, otherwise the built-in
        default. Returns what Resolve-ChangelogTierSections returns.

        PROBED WITH Get-Command RATHER THAN TAKEN AS A PARAMETER, the same pattern
        Get-ReleaseCategories uses for Get-BranchTypes: every caller has already dot-sourced the
        consumer's repo-config for other reasons, and threading two seam values through four call sites
        that never look at them is how a signature grows without buying anything.

        BOTH SEAMS ARE READ, newest first -- the repo's own "recognise both, write one" rule. A consumer
        whose repo-config predates the tier model keeps folding into its single section with no change
        and no warning, because one section IS a valid answer here rather than a legacy special case.
    #>
    $map = $null
    if (Get-Command Get-ChangelogTierHeadings -ErrorAction SilentlyContinue) {
        $map = Get-ChangelogTierHeadings
    }
    $fallback = ''
    if (Get-Command Get-ChangelogHeading -ErrorAction SilentlyContinue) {
        $configured = Get-ChangelogHeading
        if ($configured) { $fallback = ([string]$configured).Trim() }
    }
    return Resolve-ChangelogTierSections -TierHeadings $map -FallbackHeading $fallback
}

function Get-EntryScaffoldFindings {
    <#
        Pure: given an entry file's text, returns the scaffold markers it still contains -- an array of
        objects with Marker (the literal string found) and Label (which of the three it is). Empty array
        means the entry has been written rather than merely scaffolded.

        WHY A SUBSTRING MATCH AND NOT A WHOLE-LINE ONE. The measured case (v3.2.0, three entries) was
        not an untouched scaffold: the author kept the body heading and appended a status behind it --
        "**To do / where I left off:** done -- lint gate green". That is a progress note, and it read as
        one in the release notes and in the per-plugin CHANGELOGs that travel to consumers. A whole-line
        match would have passed all three.

        FENCED CODE IS EXCLUDED, for the same reason the entry-heading check excludes it: an entry may
        legitimately quote the scaffold inside a fence while documenting this very mechanism -- this
        repo's own docs do -- and a guard that cannot tell a quote from the real thing gets disabled.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$EntryText,
        [Parameter(Mandatory)][pscustomobject]$Wording
    )
    $body = Get-EntryTextOutsideFences -EntryText $EntryText

    $findings = @()
    foreach ($p in @(
        @{ Label = 'the placeholder title';   Marker = $Wording.Title },
        @{ Label = 'the scaffold body heading'; Marker = $Wording.BodyHeading },
        @{ Label = 'the fallback body';       Marker = $Wording.BodyPlaceholder }
    )) {
        if (-not $p.Marker) { continue }
        if ($body.Contains($p.Marker)) {
            $findings += [pscustomobject]@{ Label = $p.Label; Marker = $p.Marker }
        }
    }
    return $findings
}
