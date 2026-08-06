<#
.SYNOPSIS
    The changelog entry's own format, in one place: the scaffold strings new-changelog-entry.ps1
    WRITES and open-pr.ps1 REFUSES TO SHIP, the entry's heading levels and named sections, the impact
    table declaring how far a change reaches and what it weighs at each reach, and the ranked offset the
    fold inserts it at.

.DESCRIPTION
    Dot-source it:

        . (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

    WHY THIS FILE EXISTS AT ALL, given it holds three strings. Those three had to be known by two
    scripts that must never disagree about them: one writes the scaffold, the other blocks a PR whose
    entry still carries it. A copy in each would make the gate silently miss whatever the writer
    changed -- a drift guard that drifts, which is worse than no guard because it reports success. So
    the wording became a single source the moment the second reader appeared, exactly as CLAUDE.md
    requires for a rule living in two places.

    THE IMPACT DECLARATION JOINED IT FOR THE SAME REASON, WITH ONE MORE READER (the tier model, August 5,
    2026). How far a change reaches is written by new-changelog-entry.ps1, validated by open-pr.ps1 before a
    PR can ship, read by fold-changelog-entry.ps1 to decide where in CHANGELOG.md the entry lands, and read
    again by the release cut to decide which documents it appears in. Four scripts, one format: a copy in
    each is how a fold starts filing tier-2 work as repo-internal without anything erroring.

    THE DECLARATION IS NOW A TABLE, AND THE OLDER 'Tier: N' LINE IS STILL RECOGNISED -- this repo's standing
    "recognise both, write one" rule, because every entry already merged and every entry in a consumer's tree
    predates the table.

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
#
# TWO OF THESE ARE NO LONGER WRITTEN, ONLY RECOGNISED (Dave, August 6, 2026). Until the branch/ split the
# entry file was also the branch's to-do list, so new-changelog-entry.ps1 scaffolded it with a
# '**To do / where I left off:**' heading over a matching placeholder. branch-progress.md holds that job
# now, and an entry that still asked for a to-do list would re-create the exact confusion the split
# removes. So the writer stops writing them and the GATE KEEPS REFUSING THEM -- "recognise both, write
# one", the same rule the tier line gets. This is not politeness towards history: every consumer with a
# branch in flight has an entry carrying these strings right now, and they reach the new scripts through
# a plugin update rather than by choosing to. A gate that forgot them would wave those entries through
# into CHANGELOG.md, silently, which is the one failure mode a guard must not have.
$script:EntryScaffoldDefaults = [ordered]@{
    Title         = 'TODO: title'
    BodyHeading   = '**To do / where I left off:**'
    BodyPlaceholder = 'TODO: what this change does, for whoever reads CHANGELOG.md later.'
}

# Recognised by the gate, never written by anything, and deliberately NOT repo-configurable: it is a
# historical string, so there is nothing for a consumer to choose about it. Kept separate from the map
# above rather than folded into BodyPlaceholder because that one IS seamed -- a repo that overrode the
# placeholder would otherwise lose the legacy marker along with the default it replaced.
$script:EntryScaffoldLegacyMarkers = @(
    'TODO: what still needs to happen on this branch, and where you left off.'
)

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

function Get-FencedLineFlags {
    <#
        Returns a bool per input line: is that line inside a fenced code block? The fence MARKER itself is
        reported as fenced ($true), so a caller that skips fenced lines keeps the markers with their content
        rather than stripping them and leaving the body inside rendered as prose.

        THE ONE FENCE READER OF THIS FORMAT, and it lives here because this is the lower lib. Every markdown
        structure test in the entry format has to ask this question -- '^## ' for an entry boundary, '^---$'
        for a separator, 'Tier:' for a declaration, the impact table's header row, the three section
        headings -- and every one of them must NOT fire on text an entry body QUOTES. An entry may
        legitimately show a broken heading structure, a YAML frontmatter example, or the very format it
        introduces, and treating that as structure is the defect class this system has now paid for at
        least five times:

          * cutting v2.13.3 produced a third entry from two PRs, split a fence open, and duplicated a
            category heading in the release notes;
          * the fold would have deleted a 'Tier: 0' line out of the fence that was explaining it;
          * a quoted impact table would have disabled the reader that met it first;
          * and on the fold of PR #478 a quoted entry heading split a real entry in two, so the fragment
            above its impact table read as tier 0 and a tier-1 entry was inserted at the top of a list
            whose next six entries were tier 2.

        SO THERE IS ONE ANSWER AND ONE PLACE THAT GIVES IT. Until this change there were two named
        functions with this job -- this one and Get-FencedLineFlags in release-lib.ps1 -- plus two inline
        walks in this file. Four walks, and they were NOT equivalent: the release-lib one recognised '~~~'
        fences and the three here did not, so an entry using tilde fences had its quoted content read as
        structure by every reader in this file while release-lib's readers handled it correctly. That
        difference is exactly what "two answers that can drift" means, found by comparing them rather than
        by anything failing. The union rule wins, so the tilde form is now honoured everywhere.

        Deliberately simple: a line whose first non-space characters are ``` or ~~~ toggles the state.
        That is CommonMark's own rule for the common cases and needs no parser. Nested fences of the same
        kind are not a thing in CommonMark, and an unclosed fence leaves the tail flagged as fenced --
        which is the safe direction for every caller here, since it can only cause a missed finding, never
        a false accusation against text somebody did write.

        The name is deliberately NOT entry-specific: release-lib's readers scan a whole CHANGELOG rather
        than one entry, and they call this by exactly this name -- so moving the owner down a layer changed
        no call site in either lib.
    #>
    # Not Mandatory, and both Allow* attributes: a changelog section can legitimately be a single empty
    # line, and a Mandatory [string[]] rejects '' outright (ParameterArgumentValidationError).
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

function Get-EntryLineFlagPairs {
    <#
        Private helper: an entry split so that a caller can rewrite it line by line WITHOUT losing the
        original line endings, with the fence state already resolved. Returns an object with

          Parts   the [regex]::Split result, separators kept (odd indices are the separators)
          Fenced  one bool per CONTENT line, in order, from Get-FencedLineFlags

        WHY THIS EXISTS: the two removers below (Remove-EntryTierLine, Remove-EntryImpactTable) each used
        to walk the fences themselves while deciding what to drop. That is where two of this file's four
        fence walks lived, and it is why neither recognised '~~~'. They need the flags AND the separators,
        which is an awkward pair to derive twice -- so it is derived once, here, and both read it.

        The separators are preserved rather than normalised because the caller has already matched its
        document's own style; rewriting them would put CRLF and LF in one entry.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)
    $parts = [regex]::Split($EntryText, '(\r?\n)')
    $contents = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $parts.Count; $i += 2) { $contents.Add($parts[$i]) }
    return [pscustomobject]@{
        Parts  = $parts
        Fenced = @(Get-FencedLineFlags -Lines @($contents.ToArray()))
    }
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
    # Read off the shared flags rather than walking the fences again, so this and every other reader of the
    # format agree about where a block starts. A marker line is flagged, so it is dropped exactly as the
    # old inline 'continue' dropped it -- and a '~~~' fence is now recognised too, which it was not.
    $lines = @($EntryText -split '\r?\n')
    $fenced = Get-FencedLineFlags -Lines $lines
    $kept = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if (-not $fenced[$i]) { $kept.Add($lines[$i]) }
    }
    return ($kept -join "`n")
}

# --- The tier line -------------------------------------------------------------------------------
#
# 'Tier: N' declares how far an entry reaches. It was superseded by the impact table below on the day it
# shipped and is kept because every entry written before that carries it; it is also the FIRST key the fold
# orders CHANGELOG.md's flat list on, since August 5, 2026. The ladder (Dave, August 5, 2026):
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

function Format-EntryFoldFooter {
    <#
        Pure: the closing line the FOLD appends to an entry -- the two facts that do not exist until the
        merge. '[PR #468](https://...) <middot> merged 2026-08-05'.

        $MergedAt is the PR's own merge timestamp as gh returns it (ISO 8601, UTC). Empty or unparseable
        -> $FallbackDate is used, which the caller reads off its clock.

        WHY THE PR'S TIMESTAMP AND NOT THE CLOCK (Dave, August 5, 2026). The date used to be scaffolded
        into the entry's HEADING when the branch was created, making it the branch's birth date rather
        than the landing date -- wrong by however many days the branch lived, in the one document whose
        subject is when things landed. Moving it to the fold fixes that; reading it off the PR fixes the
        remainder, because the fold does not always run seconds after the merge. This repo has measured
        that gap: unfolded entry files were once found in the repo root the morning after their merge. A
        clock reading would have dated those a day late, and nothing in the output would have said so.

        WHY A FUNCTION RATHER THAN THREE LINES IN THE FOLD. The fold drives a live remote, so its own
        suite deliberately does not depend on a PR existing -- which would have left the one path this
        change adds untested. Same move, same reason as Get-ExistingPrRecord in pr-issues-lib.ps1: the
        part that is a pure function of an API answer becomes one, so it can be asserted without the API.
    #>
    param(
        [Parameter(Mandatory)][int]$Number,
        [Parameter(Mandatory)][string]$Url,
        [string]$MergedAt = '',
        [Parameter(Mandatory)][string]$FallbackDate
    )
    $md = [char]0x00B7
    $stamp = $FallbackDate
    if ($MergedAt) {
        # try/catch rather than a regex pre-check: gh's field is a timestamp or it is absent, and a
        # malformed one must not turn a completed fold into a failure over a cosmetic line.
        try { $stamp = ([datetime]$MergedAt).ToLocalTime().ToString('yyyy-MM-dd') } catch { $stamp = $FallbackDate }
    }
    return "[PR #$Number]($Url) $md merged $stamp"
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

        ITS CALLER MOVED, AND THAT IS THE WHOLE STORY OF THIS FUNCTION (August 5, 2026). It was written for
        the FOLD: once an entry sat under '## Tier 2 - Pull Requests', the section stated the tier, so a line
        inside the entry restating it was the same fact in two places -- the drift shape this repo has paid
        for three times. The sections are gone, so there is nothing above a folded entry stating its reach,
        and the fold now KEEPS the line: consuming it would leave the entry declaring nothing, and every
        downstream reader would take that as tier 0.

        What did not change is that the line must never travel OUTWARD. A self-assigned tier printed at a
        consumer is the same class of thing as a self-assigned score, and the line now reaches CHANGELOG.md
        where it never used to -- so this belongs on the same stripping path as Remove-EntryImpactTable, in
        the renderers that build the highlights, the per-plugin CHANGELOGs and the release cards. That wiring
        is the release side's to make; this function is unchanged and waiting for it.

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
    # The fence state comes from the one reader (Get-FencedLineFlags, via the pair helper) rather than from
    # a walk of its own -- this used to be one of this file's four separate fence walks, and the one that
    # did not recognise '~~~'. The separators are kept so the original CRLF/LF of every line survives.
    $pair = Get-EntryLineFlagPairs -EntryText $EntryText
    $parts = $pair.Parts
    $out = New-Object System.Collections.Generic.List[string]
    $removed = $false
    $n = -1
    for ($i = 0; $i -lt $parts.Count; $i++) {
        # Odd indices are the captured separators; only even ones are line content.
        if ($i % 2 -eq 1) { continue }
        $n++
        $line = $parts[$i]
        $sep = if ($i + 1 -lt $parts.Count) { $parts[$i + 1] } else { '' }
        # A fenced line (the markers included) is content, never a declaration.
        if ((-not $pair.Fenced[$n]) -and (-not $removed) -and $line -match "^$label`:") {
            $removed = $true
            continue
        }
        $out.Add($line + $sep)
    }
    $t = ($out -join '')
    if (-not $removed) { return $t }
    return [regex]::Replace($t, '(\r?\n)\1\1+', '$1$1')
}

# --- The impact table: how far a change reaches, and how much it weighs at each reach --------------
#
# ONE TABLE INSTEAD OF THREE METADATA LINES (Dave, August 5, 2026; issue #467). An entry declares its
# impact as a markdown table with THE TIER AS THE ROW and the significance as a column:
#
#     | Tier | Significance | Why |
#     |---|---|---|
#     | 2 | 5 | consumers must re-add the marketplace under its new name; installs break without it |
#     | 1 | 4 | the routine version bump stops needing a developer |
#
# WHAT THE SHAPE BUYS, beyond reading better than three colon-separated keys. The tier ladder is
# CUMULATIVE -- tier 2 implies tier 1, so a tier-2 change appears in the highlights AND in the internal
# note -- and until now that was implied by two differently-suffixed keys ('Significance' and
# 'SignificanceConsumer') that a reader had to know were audiences. As rows it is literal: the rows an
# entry has ARE the documents it appears in, and each row's number is that document's reader answering
# their own question. Filling in two rows is no longer a second judgement bolted on; it is saying out loud
# that the change reaches two audiences, which is what tier 2 already meant.
#
# IT REPLACES THE 'Tier: N' LINE rather than joining it, because the row states the tier and the same fact
# in two places is the drift this repo has paid for repeatedly. THE TIER COLUMN IS NOT THAT DUPLICATION:
# once folded, the changelog SECTION states how far the change reaches, while the column says which
# audience each SCORE belongs to. Two different jobs on the same number, which is why the table survives
# the fold whole where the old 'Tier:' line was consumed by it.
#
# 'Tier: N' IS STILL READ, AND ALWAYS WILL BE -- "recognise both, write one", this repo's standing rule
# for a format change. Entries written before this table exist are already in CHANGELOG.md and in every
# consumer's tree, and a parser that only knew the new shape would read every one of them as tier 0:
# silent, correct-looking, and wrong in the direction that empties a release. So an entry with no table
# falls back to the old line, with no score -- which is exactly what those entries have.
#
# THE FORWARD-LOOKING FRAMEWORKS DELIBERATELY DO NOT APPLY HERE, and it is worth saying so, because they
# are the first thing anyone reaches for. RICE and WSJF price work BEFORE it is done and carry effort in
# the denominator -- they answer "what do we build next". Everything scored here is already merged, so
# effort is spent and irrelevant; the only open question is how much the reader of a finished release
# document gets out of what landed. That is a magnitude, not a priority. Reach and significance is the
# same decomposition incident practice makes when it derives a priority from impact and urgency rather
# than asking for one number.
#
# IT WAS CALLED 'Happiness' FOR ONE AFTERNOON (Dave, August 5, 2026). He rejected the word as
# unprofessional and he was right about more than the word: 'happiness' names an EMOTION in the reader,
# which is not something an entry's author is in any position to assert. What they can judge is the weight
# of the change for that audience, which is what the field always measured. Renamed before it shipped;
# nothing carries the old key.
#
# 1 TO 5 AGAINST A WRITTEN RUBRIC (Get-EntrySignificanceRubric below), and the rubric is what makes this a
# measurement rather than a mood. An unanchored ordinal scale invites false precision -- the difference
# between a 3 and a 4 becomes whatever the author felt that morning -- and this repo asked for the
# opposite. Every level therefore has a definition, in the same shape severity levels, CVSS qualitative
# bands and ITIL impact levels use: a test a reader can apply to somebody else's entry and get the same
# answer. That also makes the number COMPARABLE ACROSS RELEASES, which an unanchored one could not be: a 5
# means "the reader must act" in August and in June alike, because the rubric says so rather than the
# release's own spread.
#
# Dave chose the rubric over an unanchored scale on August 5, 2026, reversing his own earlier answer the
# same day once the naming question exposed what was behind it. Recorded because the reversal IS the
# reasoning: the first answer avoided calibration on the grounds that every anchor is a second judgement
# that can drift, which is true and is the price. Without anchors there is no judgement to drift and also
# nothing to check, and an unauditable ranking published beside a release is the thing being avoided.
#
# THE 'Why' COLUMN IS REQUIRED, and the rubric does not replace it. The level says which band the change
# falls in; the why says why THIS change is in that band, which is the half a later reader can disagree
# with. It travels into the record and is never published outward -- see Remove-EntryImpactTable.
#
# NO SCAFFOLDED NUMBER, WHICH IS THE OPPOSITE CHOICE FROM THE OLD TIER DEFAULT, AND DELIBERATE. 'Tier: 0'
# had a default because 0 is a legitimate, harmless final answer -- forgetting it under-promotes, which is
# loud at the cut. A significance score has no harmless value: any number written for the author would be
# a GUESS, and this repo has measured what a guessed ranking costs. The retired highlights marker guessed
# from the branch prefix which changes a consumer would notice and put v3.2.0's single most consequential
# change -- renaming the marketplace, which breaks every existing install -- below the line, because it
# arrived on a chore/ branch. So the scaffold writes the tier-0 row and nothing else, and the cut refuses a
# release whose entries have not answered.
#
# THE HEADERS ARE NOT REPO-OWNED, for the reason the old labels were not: they are the machine-read keys
# four scripts must agree on, the same class as 'Plugins:', and the language rule keeps a technical
# identifier in its original form. WHETHER a repo ranks at all IS repo-owned (Test-EntrySignificanceActive),
# and so is the RUBRIC's wording (Get-EntrySignificanceRubric) -- the editorial half, not the key.
$script:EntryImpactHeaders   = @('Tier', 'Significance', 'Why')
$script:EntryImpactEmptyCell = '-'
$script:EntrySignificanceMin = 1
$script:EntrySignificanceMax = 5

# --- THE SHAPE THAT REPLACED THE TABLE (Dave, August 6, 2026) -------------------------------------
#
# One '#### Tier N' sub-section per reach the change claims, each carrying why it matters at that reach
# and then its score. The table is gone because it forced a rectangle onto something that is not always
# rectangular: not every change HAS a tier 1 or a tier 2, and a missing row reads as an omission while a
# missing section reads as an answer.
#
# THE KEYS STAY FIXED while the prose around them is repo-owned, exactly as the table's column headers
# were. 'Tier' in the sub-heading and 'Score:' on its own line are what four scripts parse; the routing
# question underneath is editorial and comes from Get-EntrySignificanceWording.
#
# 'Score:' ECHOES THE RETIRED 'Tier: N' LINE ON PURPOSE -- same shape, same position, one fact per line.
# A reader who knows one knows the other, and a parser for either is the same three characters of regex.
$script:EntryTierSubLevel   = 4
$script:EntryTierSubPrefix  = 'Tier'
$script:EntryScoreLabel     = 'Score:'

$script:EntrySignificanceWordingDefaults = [ordered]@{
    # One sentence per tier, printed under that tier's score, sending the author to the next one. Written
    # as a QUESTION with both answers spelled out, because the failure it prevents is silence: an author
    # who simply stops after tier 0 has not decided that colleagues get nothing out of the change, they
    # have not been asked. Tier 2 has no successor, so it carries none.
    Route0 = 'Is this change also relevant to colleagues and employers? Then continue to Tier 1. If not, stop here and move on to the next section.'
    Route1 = 'Is this change also relevant to the people who consume this product? Then continue to Tier 2. If not, stop here and move on to the next section.'
    WhyPlaceholder = 'TODO: why this change matters at this reach.'
}

function Get-EntrySignificanceWording {
    <#
        The editorial half of the Significance section -- the routing questions and the why-placeholder --
        with this repo's answers where scripts/repo-config.ps1 supplies them.

        One getter returning a map rather than three, for the reason Get-BranchFileWording gives: these are
        document prose read by a human, not markers a gate matches string-for-string, and a repo that
        translates one translates all of them.
    #>
    $out = [ordered]@{}
    foreach ($key in $script:EntrySignificanceWordingDefaults.Keys) {
        $out[$key] = $script:EntrySignificanceWordingDefaults[$key]
    }
    if (Get-Command Get-EntrySignificanceWordingOverrides -ErrorAction SilentlyContinue) {
        $override = Get-EntrySignificanceWordingOverrides
        if ($override) {
            foreach ($key in @($out.Keys)) {
                $v = $null
                if ($override -is [System.Collections.IDictionary]) {
                    if (-not $override.Contains($key)) { continue }
                    $v = $override[$key]
                } elseif ($override.PSObject.Properties[$key]) {
                    $v = $override.PSObject.Properties[$key].Value
                } else { continue }
                if ($v) { $out[$key] = $v }
            }
        }
    }
    return [pscustomobject]$out
}

function Format-EntrySignificanceSections {
    <#
        The Significance section's body as an array of LINES: one '#### Tier N' block per row, LOWEST tier
        first, each with its why, its 'Score: N' line and -- for tier 0 and 1 -- the question routing the
        author to the next tier.

        LOWEST FIRST, which is the opposite of the table it replaces. The table listed the furthest reach
        at the top because that is what decided the entry's position in the changelog. These sections are
        walked by a person filling them in, and that walk starts at tier 0: it is the one every change can
        answer, and each answer decides whether there is a next one. Ordering the document against the
        order it is written in would put the routing questions in reverse.

        Called with no rows it renders the SCAFFOLD: tier 0 alone, its why a placeholder and its score
        EMPTY. Tier 0 is the honest default claim -- reaches nobody outside this repo -- while a scaffolded
        SCORE would be a guess at a ranking, which is the failure the retired highlights marker was
        measured on.

        One formatter for the writer and any migration, so the parser below can never meet a shape nothing
        here produced.
    #>
    param($Rows = @())
    $w      = Get-EntrySignificanceWording
    $hashes = '#' * $script:EntryTierSubLevel
    $routes = @{ 0 = $w.Route0; 1 = $w.Route1 }

    $ordered = @(@($Rows) | Sort-Object -Property @{Expression = { [int]$_.Tier }; Descending = $false})
    if ($ordered.Count -eq 0) {
        $ordered = @([pscustomobject]@{ Tier = 0; Score = 0; Why = '' })
    }

    $lines = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $ordered.Count; $i++) {
        $row  = $ordered[$i]
        $tier = [int]$row.Tier
        if ($i -gt 0) { $lines.Add('') }
        $lines.Add("$hashes $($script:EntryTierSubPrefix) $tier")
        $lines.Add('')
        $why = if ($row.PSObject.Properties['Why'] -and $row.Why) { [string]$row.Why } else { $w.WhyPlaceholder }
        foreach ($line in ($why -split '\r?\n')) { $lines.Add($line) }
        $lines.Add('')
        # An unscored row writes the label with nothing after it -- a question left standing rather than a
        # number nobody chose. Get-EntryImpactFindings is what refuses it before the PR.
        $score = if ($row.PSObject.Properties['Score'] -and [int]$row.Score -gt 0) { ' ' + [string][int]$row.Score } else { '' }
        $lines.Add($script:EntryScoreLabel + $score)
        # EVERY tier 0 and tier 1 section closes with it, including one that already has its successor
        # below it (Dave: "het kopje sluit altijd af met"). An earlier draft wrote it only under the last
        # section, on the grounds that a tier whose successor exists has already been answered. That is
        # true of the author and false of the reader: the entry is walked again at the fold, at the cut and
        # in the record, and a question that disappears once answered leaves the next reader unable to see
        # that it WAS asked. Tier 2 has no successor and therefore carries none.
        if ($routes.ContainsKey($tier)) {
            $lines.Add('')
            $lines.Add($routes[$tier])
        }
    }
    return @($lines.ToArray())
}

# THE RUBRIC -- the definition of each level, and the reason the number is a measurement. Every band is
# written as a TEST rather than a feeling ("must act", "noticed within a day"), so two people scoring the
# same change land on the same band and a reviewer can disagree with a specific claim instead of with a
# vibe.
#
# AN ARRAY OF PAIRS, NOT A MAP KEYED BY THE SCORE, and that is a bug this shape prevents rather than a
# style choice -- the very bug the retired Resolve-ChangelogTierSections was measured on, walked
# into again here on the first run. [ordered]@{ 5 = '...' } is an OrderedDictionary, whose indexer takes
# BOTH a key and a POSITIONAL INDEX, and the positional overload WINS for an integer. So $rubric[5] asks
# for the sixth element of a five-element map and throws -- and on a map with more levels than that it
# would not throw at all, it would silently return a neighbouring band's text. Pairs have no indexer to
# reach for.
$script:EntrySignificanceRubricDefaults = @(
    [pscustomobject]@{ Score = 5; Test = 'the reader must act -- a breaking change, a required migration, or a long-standing blocker that is now gone' }
    [pscustomobject]@{ Score = 4; Test = 'materially changes how they work; they notice within a day without being told' }
    [pscustomobject]@{ Score = 3; Test = 'a clear improvement, noticed the moment they touch that part' }
    [pscustomobject]@{ Score = 2; Test = 'small; noticed if somebody points it out' }
    [pscustomobject]@{ Score = 1; Test = 'cosmetic or preventative -- nothing changes for them today' }
)

function Get-EntrySignificanceRange {
    <# The scale, as an object with Min and Max (1 and 5). Read by the writer, the validator and the
       gates, so the bounds are stated once. #>
    return [pscustomobject]@{ Min = $script:EntrySignificanceMin; Max = $script:EntrySignificanceMax }
}

function Get-EntrySignificanceRubric {
    <#
        The scale's definitions: an array of objects with Score (int) and Test (string), highest first --
        the order it reads in and the order the gates print it in.

        REPO-OWNED VIA Get-EntrySignificanceRubricLevels, probed with Get-Command like every other prose
        knob in this file (#410's class). A rubric is the one part of this mechanism a repo genuinely
        might have to differ on: "the reader must act" means something different to a marketplace than to
        a storefront, and a repo whose consumers are non-technical needs its own wording. The HEADERS stay
        fixed while the rubric moves, which is the right split -- the key is machine-read, the definition
        is editorial.

        The override is accepted as a hashtable or ordered dictionary keyed by score, because that is the
        natural way to write one in a config file -- but it is read with GetEnumerator, never the indexer,
        for the reason in the comment above the defaults. A level the override omits keeps its built-in
        text rather than leaving a hole, so a repo can retune one band without restating five; a level
        whose override is empty is ignored, the same fail-safe Get-EntryScaffoldWording uses, because a
        blank rubric would make a gate print nothing exactly where it promises the definitions.
    #>
    $levels = [ordered]@{}
    foreach ($pair in $script:EntrySignificanceRubricDefaults) {
        # String keys throughout: an OrderedDictionary keyed by [int] is the trap documented above.
        $levels[[string]$pair.Score] = $pair.Test
    }
    if (Get-Command Get-EntrySignificanceRubricLevels -ErrorAction SilentlyContinue) {
        $override = Get-EntrySignificanceRubricLevels
        if ($override) {
            foreach ($entry in $override.GetEnumerator()) {
                $text = [string]$entry.Value
                if ($text) { $levels[[string]$entry.Key] = $text }
            }
        }
    }
    $out = @()
    foreach ($entry in $levels.GetEnumerator()) {
        $out += [pscustomobject]@{ Score = [int]$entry.Key; Test = [string]$entry.Value }
    }
    # Sorted rather than trusted: an override may introduce a level the defaults did not have, and it
    # arrives at the end of the dictionary regardless of its number.
    return @($out | Sort-Object Score -Descending)
}

function Format-EntrySignificanceRubricLines {
    <#
        The rubric as printable lines ('  5  the reader must act -- ...'), highest first.

        ITS OWN FUNCTION BECAUSE THREE READERS PRINT IT: the scaffold writer (so the author sees the scale
        at the moment the entry is created), open-pr.ps1 and cut-release.ps1 (so a refusal states the test
        the entry failed rather than only that it failed). A gate that says "write a number from 1 to 5"
        without saying what the numbers mean is asking for the guess this model exists to avoid.
    #>
    return @(Get-EntrySignificanceRubric | ForEach-Object { '  ' + $_.Score + '  ' + $_.Test })
}

function Test-EntrySignificanceActive {
    <#
        Does this repo rank its entries at all? $true unless it says otherwise.

        THE SECTION-COUNT HEURISTIC DIED WITH THE SECTIONS (August 5, 2026), and replacing it was not
        optional. This used to answer "off where there is no tier split", reading the changelog's section map
        and treating one section as "this repo never adopted tiers". That test had a real basis while the map
        existed -- the sections WERE the repo's declaration of which tiers it files. The flat changelog has no
        map -- and the resolver that read it is retired further down this file -- so keeping the old line
        would have read every repo as not ranking: the scaffold's table, both validators
        and the cut's significance gate would all have switched themselves off, silently, in the same commit
        that made the ranking the document's only ordering. Nothing would have errored.

        SO THE DEFAULT IS ON, WITH AN EXPLICIT OPT-OUT, which is also the consistent answer: the entry's
        section structure became unconditional in the same change, on the grounds that two entry shapes in one
        system need both paths in every reader forever. A repo that has not adopted the model is not harmed by
        being on -- its entries are tier 0, and tier 0 is asked for no score (Get-EntryImpactFindings), so
        every gate stays quiet by itself rather than by a flag.

        The seam is Get-EntrySignificanceEnabled in the consumer's scripts/repo-config.ps1, probed with
        Get-Command like every other optional knob. Returning $false there switches off the scaffold's table,
        both validators and the cut's gate together, because a half-adopted ranking (required but never read)
        is worse than neither. It does NOT switch off the fold's ORDERING: with the sections gone that
        ordering is what the three headings used to say, so it is structure rather than a preference.

        Test-ReleaseBumpEarned's own Active flag in release-lib.ps1 keys off the same retired section map and
        needs the same repair; it is left to the change that reworks the release side, because the answer
        there is about which release documents exist rather than about scoring.
    #>
    if (Get-Command Get-EntrySignificanceEnabled -ErrorAction SilentlyContinue) {
        return [bool](Get-EntrySignificanceEnabled)
    }
    return $true
}

function Format-EntryImpactTable {
    <#
        The impact table as an array of LINES -- header, separator, then one row per entry in $Rows
        (objects with Tier, and optionally Score and Why), highest tier first.

        Called with no rows it renders the SCAFFOLD: the header and a single tier-0 row with both value
        cells empty ('-'). That is the unedited entry's honest claim -- reaches nobody outside this repo,
        nothing to rank -- and it is exactly what the old 'Tier: 0' default said, in the shape that now
        carries it. RAISING THE TIER IS ADDING A ROW, so the rows an entry has are the claims it makes and
        there is no way to claim a reach without also saying what it is worth there.

        One formatter, so the writer, the parser and the gates cannot disagree about the cell padding.
    #>
    param($Rows = @())
    $empty = $script:EntryImpactEmptyCell
    $lines = @('| ' + ($script:EntryImpactHeaders -join ' | ') + ' |')
    $lines += '|' + (@($script:EntryImpactHeaders | ForEach-Object { '---' }) -join '|') + '|'
    $ordered = @(@($Rows) | Sort-Object -Property @{Expression = { [int]$_.Tier }; Descending = $true})
    if ($ordered.Count -eq 0) {
        $ordered = @([pscustomobject]@{ Tier = 0; Score = 0; Why = '' })
    }
    foreach ($row in $ordered) {
        $score = if ($row.PSObject.Properties['Score'] -and [int]$row.Score -gt 0) { [string][int]$row.Score } else { $empty }
        $why = if ($row.PSObject.Properties['Why'] -and $row.Why) { [string]$row.Why } else { $empty }
        $lines += "| $([int]$row.Tier) | $score | $why |"
    }
    return $lines
}

function Read-EntryTierSections {
    <#
        Private: the '#### Tier N' sub-sections in an already-defenced, already-split entry. Returns an
        object with Rows (the same shape the table produces -- Tier, Score, Why, Raw, Error) and Errors.
        Both empty means the entry carries no sections at all, which is what sends Resolve-EntryImpact on
        to the older shapes.

        AN OBJECT RATHER THAN A [ref] PARAMETER, and that is a bug fix rather than taste. The first version
        took `[ref]$result.Errors` -- a reference to a property of a pscustomobject -- and assigning through
        it silently wrote to a copy: every malformed section parsed, reported nothing, and the entry fell
        through to the legacy reader as an undeclared tier 0. Exactly the class of failure this parser
        exists to prevent, in the parser itself. Caught by the three malformed-input tests on their first
        run; a [ref] over a plain variable would have worked, but returning the pair cannot go wrong at all.

        Reporting the faults rather than absorbing them keeps the symmetry with the table: the gates above
        were written against ITS failures, and a shape that reported its own differently would slip past
        every one of them.

        WHAT COUNTS AS A FAULT, and each of these is a way to be silently wrong rather than merely untidy:

          * a heading that is not a whole number ('#### Tier two', '#### Tier 1a') -- it would otherwise be
            no section at all, so the reach it states would vanish;
          * a score outside the rubric's range, or one that is not a number;
          * the same tier declared twice, which leaves two different answers to one question.

        A MISSING SCORE IS NOT A FAULT HERE. It is a row with Score 0, exactly as an empty table cell was,
        and Get-EntryImpactFindings is what decides whether that blocks -- one place, so the fold can go
        ahead and say so out loud while the release cut refuses.
    #>
    param(
        # BOTH Allow* attributes, like Get-FencedLineFlags: the array is a document split on newlines, so
        # most of it is blank lines, and a [string[]] without AllowEmptyString rejects the whole call on
        # the first one (ParameterArgumentValidationErrorEmptyStringNotAllowed). Measured on the first run.
        [AllowEmptyString()][AllowEmptyCollection()][string[]]$Lines = @()
    )
    $hashes  = '#' * $script:EntryTierSubLevel
    $headRx  = '^\s*' + $hashes + '\s+' + [regex]::Escape($script:EntryTierSubPrefix) + '\s+(\S+)\s*$'
    $scoreRx = '^\s*' + [regex]::Escape($script:EntryScoreLabel) + '\s*(\S*)\s*$'
    $range   = Get-EntrySignificanceRange

    $rows = New-Object System.Collections.Generic.List[pscustomobject]
    $errs = @()
    $seen = @{}

    $i = 0
    while ($i -lt $Lines.Count) {
        if ($Lines[$i] -notmatch $headRx) { $i++; continue }
        $raw      = $Lines[$i].Trim()
        $tierCell = $Matches[1]
        $i++

        # The section runs to the next heading of ANY level -- the next tier, the next '###' section, or the
        # next entry. Anything deeper than this level would be a sub-heading of this section and is kept.
        $whyLines = New-Object System.Collections.Generic.List[string]
        $scoreCell = $null
        while ($i -lt $Lines.Count) {
            $line = $Lines[$i]
            if ($line -match ('^\s*#{1,' + $script:EntryTierSubLevel + '}\s')) { break }
            if ($null -eq $scoreCell -and $line -match $scoreRx) { $scoreCell = $Matches[1] }
            elseif ($null -eq $scoreCell) { $whyLines.Add($line) }
            $i++
        }

        if ($tierCell -notmatch '^\d+$') {
            $errs += "significance section '$raw' does not name a tier -- write a whole number from 0 to $(Get-EntryTierMax)."
            continue
        }
        $tier = [int]$tierCell
        if ($tier -gt (Get-EntryTierMax)) {
            $errs += "significance section '$raw' names tier $tier, which this model has no meaning for -- the highest is $(Get-EntryTierMax)."
            continue
        }
        if ($seen.ContainsKey($tier)) {
            $errs += "significance section '$raw' declares tier $tier a second time -- one section per tier, or two answers stand for one question."
            continue
        }
        $seen[$tier] = $true

        $score = 0
        if ($scoreCell -and $scoreCell -ne $script:EntryImpactEmptyCell) {
            if ($scoreCell -notmatch '^\d+$') {
                $errs += "'$($script:EntryScoreLabel) $scoreCell' under tier $tier is not a number -- write $($range.Min) to $($range.Max)."
            } elseif ([int]$scoreCell -lt $range.Min -or [int]$scoreCell -gt $range.Max) {
                $errs += "'$($script:EntryScoreLabel) $scoreCell' under tier $tier is outside the rubric -- write $($range.Min) to $($range.Max)."
            } else {
                $score = [int]$scoreCell
            }
        }

        # The routing question is this format's own prose, not the author's answer, so it must not become
        # the Why -- it would otherwise be published as the reason the change matters.
        $w = Get-EntrySignificanceWording
        $routes = @($w.Route0, $w.Route1) | Where-Object { $_ }
        $why = (@($whyLines | Where-Object {
            $t = $_.Trim()
            if (-not $t) { return $false }
            foreach ($r in $routes) { if ($t -eq ([string]$r).Trim()) { return $false } }
            return $true
        }) -join "`n").Trim()

        $rows.Add([pscustomobject]@{
            Tier  = $tier
            Score = $score
            Why   = $why
            Raw   = $raw
            Error = $null
        })
    }

    return [pscustomobject]@{ Rows = @($rows.ToArray()); Errors = @($errs) }
}

function Resolve-EntryImpact {
    <#
        Pure: reads an entry's impact declaration. Returns an object with

          Table     $true when an impact table was found outside fenced code.
          Rows      one object per data row -- Tier (int), Score (int, 0 when the cell is empty or '-'),
                    Why (string, '' when empty), Raw (the row as written), Error ($null or the reason).
          Tier      the highest tier any row declares -- the entry's reach, and the same number the old
                    'Tier: N' line carried. 0 when nothing usable is declared, so a caller that ignores
                    Error still fails safe towards the harmless end rather than crashing.
          Declared  $true when the reach was actually stated (a table with rows, or a 'Tier:' line).
          Errors    every row-level complaint, ready to print; empty when the table parses.

        THREE SHAPES ARE READ, ONE IS WRITTEN. In order: the '#### Tier N' sub-sections (current), the
        impact table (August 5-6, 2026), and the 'Tier: N' line (before that). That is not legacy
        tolerance, it is correctness for the entries that already exist -- CHANGELOG.md holds all three
        right now, every consumer's tree holds at least one, and they reach each new parser through a
        plugin update rather than by choosing to. A parser that knew only the newest shape would read all
        the others as tier 0: silent, correct-looking, and wrong in the direction that empties a release.

        FENCE-AWARE, AND THE FIRST TABLE OUTSIDE A FENCE WINS. An entry documenting this mechanism quotes
        the table inside a fence -- the entry for this very change does, and so does this file -- and a
        parser that cannot tell a quote from a declaration gets disabled by whoever hits it first.

        A ROW'S FAULTS ARE REPORTED, NOT ABSORBED, the same choice Resolve-EntryTier made and for the same
        failure: a '| 2 | 9 | ... |' that silently read back as unscored would sink the entry to the bottom
        of the document it matters most in, with correct-looking output and nothing to notice.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $result = [pscustomobject]@{
        Table    = $false
        Rows     = @()
        Tier     = 0
        Declared = $false
        Errors   = @()
    }

    $body = Get-EntryTextOutsideFences -EntryText $EntryText
    $lines = @($body -split '\r?\n')

    # SHAPE 1, the current one: '#### Tier N' sub-sections. Tried first, so an entry that carries both --
    # a migration, or an entry documenting the change from one to the other outside a fence -- is read as
    # what it IS rather than as what it describes.
    $sections = Read-EntryTierSections -Lines $lines
    # ERRORS COUNT AS "this entry used the section shape" just as rows do. An entry whose every section is
    # malformed has zero rows, and falling through on that would send it to the legacy reader, which finds
    # nothing and returns an undeclared tier 0 -- the complaints discarded, the defect invisible.
    if (@($sections.Rows).Count -gt 0 -or @($sections.Errors).Count -gt 0) {
        $result.Table = $true
        $result.Rows = @($sections.Rows)
        $result.Errors = @($sections.Errors)
        $declared = @($sections.Rows | Where-Object { $null -eq $_.Error })
        if ($declared.Count -gt 0) {
            $result.Declared = $true
            $result.Tier = (@($declared | ForEach-Object { [int]$_.Tier }) | Measure-Object -Maximum).Maximum
        }
        return $result
    }

    $headerPattern = '^\s*\|\s*' + [regex]::Escape($script:EntryImpactHeaders[0]) + '\s*\|\s*' +
        [regex]::Escape($script:EntryImpactHeaders[1]) + '\s*\|'

    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $headerPattern) { $start = $i; break }
    }

    if ($start -lt 0) {
        # Neither shape: the pre-table one. Read what those entries do carry.
        $legacy = Resolve-EntryTier -EntryText $EntryText
        $result.Tier = $legacy.Tier
        $result.Declared = $legacy.Declared
        if ($legacy.Error) { $result.Errors = @($legacy.Error) }
        return $result
    }

    $result.Table = $true
    $range = Get-EntrySignificanceRange
    $rows = New-Object System.Collections.Generic.List[pscustomobject]
    $errors = @()
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        if ($line -notmatch '^\|') { break }
        # The separator row ('|---|---|---|'), in whatever dashes-and-colons form somebody wrote it.
        if ($line -match '^\|[\s\-:|]+\|?$') { continue }

        $cells = @($line.Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
        $raw = $line
        if ($cells.Count -lt 2) {
            $errors += "impact row '$raw' has fewer than two columns -- write | <tier> | <significance> | <why> |."
            continue
        }
        $tierCell = $cells[0]
        if ($tierCell -notmatch '^\d+$') {
            $errors += "impact row '$raw' does not start with a tier -- write a whole number from 0 to $(Get-EntryTierMax)."
            continue
        }
        $tier = [int]$tierCell
        if ($tier -lt 0 -or $tier -gt (Get-EntryTierMax)) {
            $errors += "impact row '$raw' declares tier $tier, which does not exist -- the tiers are 0 to $(Get-EntryTierMax)."
            continue
        }

        $scoreCell = $cells[1]
        $score = 0
        if ($scoreCell -and $scoreCell -ne $script:EntryImpactEmptyCell) {
            if ($scoreCell -notmatch '^\d+$') {
                $errors += "tier $tier's significance '$scoreCell' is not a score -- write a whole number from $($range.Min) to $($range.Max) against the rubric."
            } elseif ([int]$scoreCell -lt $range.Min -or [int]$scoreCell -gt $range.Max) {
                $errors += "tier $tier's significance $scoreCell is off the scale -- it runs from $($range.Min) to $($range.Max)."
            } else {
                $score = [int]$scoreCell
            }
        }

        $why = if ($cells.Count -ge 3) { $cells[2] } else { '' }
        if ($why -eq $script:EntryImpactEmptyCell) { $why = '' }

        $rows.Add([pscustomobject]@{ Tier = $tier; Score = $score; Why = $why; Raw = $raw })
    }

    $result.Rows = @($rows.ToArray() | Sort-Object -Property @{Expression = 'Tier'; Descending = $true})
    $result.Errors = @($errors)
    if ($result.Rows.Count -gt 0) {
        $result.Declared = $true
        $max = 0
        foreach ($row in $result.Rows) { if ($row.Tier -gt $max) { $max = $row.Tier } }
        $result.Tier = $max
    }
    return $result
}

function Get-EntryImpactScore {
    <#
        The significance a resolved impact declares for one tier -- 0 when that tier has no row, or its
        cell was empty. A helper rather than a caller-side loop because four call sites want it and each
        one written by hand is a chance to reach for a row by position.
    #>
    param(
        [Parameter(Mandatory)]$Impact,
        [Parameter(Mandatory)][int]$Tier
    )
    foreach ($row in @($Impact.Rows)) {
        if ([int]$row.Tier -eq $Tier) { return [int]$row.Score }
    }
    return 0
}

function Get-EntryImpactFindings {
    <#
        Pure: what is wrong with an entry's impact declaration -- an array of strings, each ready to print.
        Empty means the entry has said everything its own reach commits it to.

        ONE FUNCTION FOR BOTH GATES, and that is the whole reason it exists rather than living in one of
        them. open-pr.ps1 needs it while the branch is still the only thing affected, and cut-release.ps1
        needs it because a missing score is Dave's chosen refusal point (August 5, 2026) -- the branch may
        merge without one, the release may not be cut. Two gates, one definition of "wrong", or they drift
        and the earlier one starts passing what the later one refuses.

        THE LADDER IS CHECKED AS A LADDER. An entry claiming tier 2 appears in the highlights AND in the
        internal note, so it owes a row for tier 1 as well -- and being asked for it is the point rather
        than a chore, because "reaches consumers" without "and here is what colleagues get out of it" is
        half a claim. Every tier from 1 up to the declared reach needs a row, a score and a why.

        TIER 0 OWES NOTHING. It appears only in the record, which is complete and chronological and never
        sorted, so there is no position for a score to decide.

        AN ENTRY WITH NO TABLE AT ALL IS NOT FAULTED FOR THAT, only for what its tier then requires. That
        keeps every pre-table entry in CHANGELOG.md readable rather than retroactively broken -- but it does
        NOT excuse a tier-1 entry from having a score, because the ranking has to be able to place it.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $impact = Resolve-EntryImpact -EntryText $EntryText
    $findings = @(@($impact.Errors) | Where-Object { $_ })
    $range = Get-EntrySignificanceRange

    # A TABLE THAT DOES NOT PARSE IS REPORTED AND NOTHING ELSE IS, deliberately. A cell the scale has no
    # meaning for already reads back as unscored, so the completeness checks below would pile a second
    # complaint ("tier 2 has no significance") on top of the first ("tier 2's significance 9 is off the
    # scale") and describe one mistake twice. Measured on the first run of this function: a single bad cell
    # produced three findings. Fix what is unreadable, run again, then hear what is missing.
    if ($findings.Count -gt 0) { return $findings }

    for ($tier = 1; $tier -le $impact.Tier; $tier++) {
        $row = @(@($impact.Rows) | Where-Object { [int]$_.Tier -eq $tier })
        if ($row.Count -eq 0) {
            # $($impact.Tier), not "$impact.Tier": the second interpolates the OBJECT and then appends the
            # literal '.Tier', so the message read "reaches tier @{Table=True; Rows=System.Object[]...}".
            # Caught by this file's own smoke test; it is the one PowerShell interpolation trap that
            # produces valid output nobody would ever write on purpose.
            $findings += "this entry reaches tier $($impact.Tier), so it also reaches tier $tier -- add a '| $tier | <$($range.Min)-$($range.Max)> | <why> |' row. The ladder is cumulative: a change consumers notice is also a change this project's colleagues get something out of."
            continue
        }
        if ([int]$row[0].Score -le 0) {
            $findings += "tier $tier has no significance -- write a whole number from $($range.Min) to $($range.Max) against the rubric in that row's second column."
            continue
        }
        if (-not $row[0].Why) {
            $findings += "tier $tier scores $($row[0].Score) with no 'Why' -- fill in the third column. The rubric says which band; the why says why THIS change is in it, and that is the half a later reader can check."
        }
    }
    return $findings
}

function Remove-EntryImpactTable {
    <#
        Removes the impact table (and the blank line it leaves behind) from an entry block.

        WHERE THIS RUNS, AND WHERE IT DELIBERATELY DOES NOT. The table survives the FOLD whole whenever any
        row carries a score, because the cut EMPTIES the changelog's tier sections -- a score consumed at
        the fold would not exist when the release documents are built days later, and the ordering could not
        be reproduced without re-estimating it. The record therefore keeps the table, and the development
        notes are the last place each ranking's justification survives.

        THE DOCUMENTS THAT TRAVEL OUTWARD STRIP IT: the highlights, the per-plugin CHANGELOGs and the
        release cards. A self-assigned number printed at a consumer is a marketing claim, and this repo has
        measured what a published guess costs -- the retired highlights marker is in release-lib's history
        for exactly that. The number does its work by deciding the order and then gets out of the way.

        The fold also calls it for an UNSCORED table -- a tier-0 entry's scaffold row, which is a question
        nobody was asked rather than content -- so such an entry folds clean.

        Fence-aware, and only the FIRST table is removed, exactly like Remove-EntryTierLine and for the case
        that arrived immediately: the entry documenting this mechanism quotes the table inside a fence, and a
        blind matcher would delete it out of the fence while rendering.

        THE SECTION HEADING GOES WITH THE TABLE, and forgetting that shipped an empty section into every
        outward-facing entry (August 6, 2026). Under the pre-#467 format the declaration was a bare 'Tier: N'
        line with nothing above it, so removing the line was the whole job. The impact table lives under its
        own '### Who is this for' heading, and that heading exists to introduce the table -- the entry format
        is explicit that the table IS the answer rather than prose beside it, so a stripped table leaves a
        question with no answer under it. Measured while cutting v3.6.0 with -NoPush: 17 empty sections in
        each release card, 17 in the per-plugin CHANGELOG and 16 in the highlights draft, in exactly the
        documents that travel to consumers in the plugin cache. The record was correct throughout, which is
        why nothing upstream noticed -- the development notes keep the table, so they keep the heading too.

        THE HEADING ONLY GOES WHEN THE SECTION IS ACTUALLY EMPTY, checked rather than assumed. The convention
        says that section holds the table and nothing else, but a strip that deletes a heading on the
        strength of a convention would delete a reader's prose the first time somebody wrote some. So the
        lines between the heading and the next one must all be blank, and the heading text comes from
        Get-EntrySectionHeadings rather than a literal -- a repo that translates its section headings
        translates this behaviour with them.

        The line endings of everything kept are preserved rather than normalised -- the caller has already
        matched its document's style.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $headerPattern = '^\s*\|\s*' + [regex]::Escape($script:EntryImpactHeaders[0]) + '\s*\|\s*' +
        [regex]::Escape($script:EntryImpactHeaders[1]) + '\s*\|'

    # Fence state from the one reader, separators kept -- see Remove-EntryTierLine above for why this is no
    # longer a walk of its own.
    $pair = Get-EntryLineFlagPairs -EntryText $EntryText
    $parts = $pair.Parts
    $out = New-Object System.Collections.Generic.List[string]
    $inTable = $false
    $done = $false
    $any = $false
    $n = -1
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($i % 2 -eq 1) { continue }
        $n++
        $line = $parts[$i]
        $sep = if ($i + 1 -lt $parts.Count) { $parts[$i + 1] } else { '' }

        if ($pair.Fenced[$n]) {
            # Entering or inside a fence: a table cannot continue across it, so a quoted block cannot be
            # read as the tail of a real one. Kept for the reason every fenced line is kept.
            $inTable = $false
        } elseif (-not $done) {
            if (-not $inTable -and $line -match $headerPattern) {
                $inTable = $true; $any = $true; continue
            }
            if ($inTable) {
                if ($line.Trim() -match '^\|') { continue }
                # First non-row line ends the table; it is kept, and no later table is touched.
                $inTable = $false
                $done = $true
            }
        }
        $out.Add($line + $sep)
    }
    $t = ($out -join '')
    if (-not $any) { return $t }
    $t = [regex]::Replace($t, '(\r?\n)\1\1+', '$1$1')
    return (Remove-EmptyImpactSection -EntryText $t)
}

function Remove-EmptyImpactSection {
    <#
        Removes the impact table's section heading once the table under it is gone, leaving the blank line
        that separated it from the paragraph above -- so '...text / blank / ### Who is this for / blank /
        ### Type of change' becomes '...text / blank / ### Type of change'.

        Only called by Remove-EntryImpactTable, and only when that function actually removed something. It is
        its own function for the reason the removers above are: the "what counts as this section" question
        has one answer, and a caller that re-derived it could disagree with the writer.

        A SECTION HOLDING ANYTHING BUT BLANK LINES IS LEFT ALONE, including the heading. That is the whole
        safety of this: the strip is entitled to remove what it put there, not to decide that somebody
        else's prose under the same heading was surplus.

        Fence-aware on both halves, for the same reason every reader in this file is: an entry that quotes
        the section heading inside a fence -- the entries documenting this format do -- must not have the
        quoted copy taken out of the fence, and a heading inside a fence must not be read as the boundary
        that ends the section either.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    # THE CURRENT HEADING AND EVERY RETIRED ONE. The key was 'Who' until the section became 'Significance'
    # hours after this function was written, and an [ordered] lookup on a key that no longer exists returns
    # $null rather than throwing -- so the guard below took the early exit and this function silently did
    # nothing, restoring the empty-section defect it had just been written to fix. Caught by its own tests;
    # it would otherwise have reached a consumer's plugin cache exactly as the original did.
    #
    # The retired names matter for the same reason they matter to the lint: an entry written under the old
    # heading still carries a table, and stripping that table has to take the old heading with it or the
    # hole simply moves to the older entries.
    $headings = @((Get-EntrySectionHeadings)['Significance']) + @(Get-EntryRetiredSectionHeadings) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if (@($headings).Count -eq 0) { return $EntryText }
    $headingRx = '^#{' + (Get-EntrySectionLevel) + '}\s+(?:' +
        ((@($headings) | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\s*$'

    $pair = Get-EntryLineFlagPairs -EntryText $EntryText
    $parts = $pair.Parts
    $lineAt = @()
    for ($i = 0; $i -lt $parts.Count; $i += 2) { $lineAt += $i }

    $start = -1
    for ($n = 0; $n -lt $lineAt.Count; $n++) {
        if ((-not $pair.Fenced[$n]) -and $parts[$lineAt[$n]] -match $headingRx) { $start = $n; break }
    }
    if ($start -lt 0) { return $EntryText }

    # Walk to the next heading of any level; anything non-blank on the way means the section has content.
    $end = $lineAt.Count
    for ($n = $start + 1; $n -lt $lineAt.Count; $n++) {
        $line = $parts[$lineAt[$n]]
        if ((-not $pair.Fenced[$n]) -and $line -match '^#{1,6}\s') { $end = $n; break }
        if ($line.Trim() -ne '') { return $EntryText }
    }

    $kept = New-Object System.Collections.Generic.List[string]
    for ($n = 0; $n -lt $lineAt.Count; $n++) {
        if ($n -ge $start -and $n -lt $end) { continue }
        $i = $lineAt[$n]
        $sep = if ($i + 1 -lt $parts.Count) { $parts[$i + 1] } else { '' }
        $kept.Add($parts[$i] + $sep)
    }
    return ($kept -join '')
}

function Remove-EntryTierSections {
    <#
        Removes the '#### Tier N' sub-sections -- heading, why, score and routing question -- from an entry
        block, leaving the '### Significance' heading above them standing.

        THE HEADING GOES TOO WHEN NOTHING IS LEFT UNDER IT, via the same Remove-EmptyImpactSection the
        table remover calls. That behaviour was measured on the shape this one replaces: leaving the heading
        standing shipped a named question with no answer under it into 17 sections per release card, 17 per
        per-plugin CHANGELOG and 16 in the highlights draft, in exactly the documents that travel to a
        consumer. The sub-sections inherit the finding because they inherit the position -- they ARE the
        section's content, so removing them empties it in precisely the same way.

        EVERY section is removed, not just the first -- unlike the table remover, which stops after one. A
        table appeared once by construction; tiers come in threes, and stopping at the first would publish
        the other two at a consumer, which is the exact thing this stripping exists to prevent.

        Fence-aware through the shared reader, for the reason every reader here is: an entry documenting
        this format quotes these headings, and this repo's own README does.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $hashes = '#' * $script:EntryTierSubLevel
    $headRx = '^\s*' + $hashes + '\s+' + [regex]::Escape($script:EntryTierSubPrefix) + '\s+\S+\s*$'

    $pair = Get-EntryLineFlagPairs -EntryText $EntryText
    $parts = $pair.Parts
    $out = New-Object System.Collections.Generic.List[string]
    $inSection = $false
    $any = $false
    $n = -1
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($i % 2 -eq 1) { continue }
        $n++
        $line = $parts[$i]
        $sep = if ($i + 1 -lt $parts.Count) { $parts[$i + 1] } else { '' }

        if ($pair.Fenced[$n]) {
            # A fence cannot sit inside a section being dropped without its opening marker having been
            # dropped too, so reaching one means the section ended at a heading we already honoured.
            $inSection = $false
        } else {
            if ($line -match $headRx) { $inSection = $true; $any = $true; continue }
            if ($inSection) {
                # Any heading at this level or shallower closes the section -- the next tier, the next
                # '###', or the next entry. It is kept; only the sub-sections themselves go.
                if ($line -match ('^\s*#{1,' + $script:EntryTierSubLevel + '}\s')) { $inSection = $false }
                else { continue }
            }
        }
        $out.Add($line + $sep)
    }
    $t = ($out -join '')
    if (-not $any) { return $t }
    $t = [regex]::Replace($t, '(\r?\n)\1\1+', '$1$1')
    return (Remove-EmptyImpactSection -EntryText $t)
}

function Remove-EntrySignificanceDeclaration {
    <#
        Strips whatever shape this entry declared its significance in -- the '#### Tier N' sub-sections, the
        impact table, or both if a migrating entry carries both.

        ONE ENTRY POINT FOR THE OUTWARD-FACING RENDERERS, which is the whole reason it exists. Those
        renderers ask one question -- "take the self-assigned numbers out before a consumer sees them" --
        and they must not have to know which of three shapes this particular entry used. release-lib calls
        this; the two removers underneath it stay separate because each is independently testable and the
        table one is still the only thing that understands a table.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)
    return (Remove-EntryImpactTable -EntryText (Remove-EntryTierSections -EntryText $EntryText))
}

function Get-ImpactInsertOffset {
    <#
        Pure: where in a changelog tier SECTION a new entry with $Score belongs -- a character offset into
        $SectionText, always at an entry boundary ('### ' at line start) or at its very end.

        THE FOLD IS WHAT KEEPS CHANGELOG.md ORDERED, and it has to be, because the cut EMPTIES the tier
        sections. There is no later moment at which the pending list could be sorted: the release documents
        read the section in document order, so whatever order the fold leaves behind IS the order the notes
        and the highlights inherit. That is also what makes the ordering reproducible across the two moments
        days apart, with nothing re-estimated -- the numbers are read from the file both times, and the
        second reader does not sort at all.

        INSERT-ONLY, NEVER A RE-SORT, and that is a safety property rather than an optimisation. This
        function serves a commit that lands DIRECTLY ON THE MAIN BRANCH under one of this repo's two named
        exceptions. A re-sort would have the fold rewrite the position of entries it did not write, so a bug
        could scramble a section; an insert can only ever misplace the one entry being folded, which is
        visible in the diff and one edit to repair.

        HIGHEST FIRST, AND A TIE KEEPS THE NEWER ENTRY ON TOP. The list is written newest-first, so equal
        ranks preserve exactly what the fold did before ranking existed.

        AN UNSCORED ENTRY ($Score 0 -- a tier-0 entry, one from before the table, or a repo with the ranking
        off) SINKS TO THE BOTTOM OF ITS OWN TIER, and that is a reversal of what this function did when it
        was written: it had an early return sending any score of 0 to the top of the section. The reason it
        had to go is symmetry with the entries it ranks against. The loop below reads an entry ALREADY in the
        changelog that declares no score as 0 and therefore sorts it below everything scored at its tier -- so
        the early return meant the SAME entry ranked differently depending on which side of the fold it was
        on, top while it was being inserted and bottom forever after. 0 is the lowest rank, not the absence of
        one. Nothing is lost by sinking: open-pr reports a missing score and the cut refuses over it by name.

        RANKED ON (TIER, SIGNIFICANCE) SINCE THE SECTIONS WENT (Dave, August 5, 2026). While CHANGELOG.md had
        one section per tier, the section answered "how far" and this only had to order within it. There is one
        flat list now, so the tier is the FIRST key: consumer-facing work leads, repo-internal work sinks, and
        the significance decides the order inside each tier. That is what the three section headings used to
        communicate visually, kept as an ordering rather than as structure.

        $EntryPattern is the heading shape an entry starts with -- '(?m)^## ' for the current format. It is a
        parameter rather than a constant because a document mid-migration still holds pre-format '### '
        entries, and the caller knows which it is looking at.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$SectionText,
        [int]$Score = 0,
        [int]$Tier = 0,
        [string]$EntryPattern = '(?m)^## '
    )
    # DECLARING TIER 0 IS NOT THE SAME AS DECLARING NOTHING, and conflating them was a real bug here: an
    # early return sent everything with tier 0 and no score to the TOP of the list, so a repo-internal change
    # led the document. There WAS an -Undeclared switch for that second case, returning the top; it is gone,
    # because in a flat list there is no such thing as an unplaced entry. An entry that declares nothing is
    # tier 0 -- the documented default and the harmless end -- and the loop below already lands it at the top
    # of the tier-0 run, which is the newest-first answer without promoting it past work that declared more.
    # Keeping a switch no caller passes would have preserved the wrong answer for the day somebody reached
    # for it.
    # FENCE-AWARE, LIKE EVERY OTHER READER OF THIS FORMAT -- and this function was the one that was not.
    # Measured on the fold of PR #477, in the document PR #476 had just created: that entry quotes
    # '## #475 <midDot> ...' inside a ```text fence, as the worked example of the format it introduces. A
    # plain regex over the text reads that quoted heading as an entry boundary, which does two things and
    # neither errors:
    #
    #   * it SPLITS the real entry in two. The fragment above the fence holds no impact table -- the table
    #     sits further down, under '### Who is this for' -- so it reads as tier 0, score 0;
    #   * the loop below then meets that tier-0 fragment FIRST, and any entry of tier 1 or higher is
    #     inserted above it: at the very top of the document. Which is what happened -- a tier-1 entry led
    #     a list whose next six entries were tier 2.
    #
    # Well-formed markdown either way, and the console line even reported it ("placed above 8 existing
    # entries" in a document that had 7). The fourth-plus instance of one defect class in this file's
    # history: a matcher satisfied by a MENTION rather than a use. Split-EntryBlocks in release-lib.ps1
    # already handled it; this ranker did not, because it was written when entries could not contain
    # headings of their own.
    #
    # Done by LINE rather than by character offset, because Get-FencedLineFlags answers per line and the
    # offsets have to be rebuilt from the same split to stay in step with it. The newline width is added
    # back per line from the original text, so a CRLF document is not silently shifted by one byte per
    # line -- the root CHANGELOG is CRLF here.
    $rxLine = [regex]($EntryPattern -replace '^\(\?m\)', '')
    $srcLines = @($SectionText -split "`r?`n")
    $fenced = Get-FencedLineFlags -Lines $srcLines
    $entryStarts = @()
    $offset = 0
    for ($i = 0; $i -lt $srcLines.Count; $i++) {
        if ((-not $fenced[$i]) -and $rxLine.IsMatch($srcLines[$i])) { $entryStarts += $offset }
        $offset += $srcLines[$i].Length
        # The separator this line ended with, taken from the source rather than assumed.
        if ($offset -lt $SectionText.Length) {
            if ($SectionText.Substring($offset, 1) -eq "`r") { $offset += 2 } else { $offset += 1 }
        }
    }
    if ($entryStarts.Count -eq 0) { return $SectionText.Length }

    for ($i = 0; $i -lt $entryStarts.Count; $i++) {
        $start = $entryStarts[$i]
        $end = if ($i + 1 -lt $entryStarts.Count) { $entryStarts[$i + 1] } else { $SectionText.Length }
        $block = $SectionText.Substring($start, $end - $start)
        $impact = Resolve-EntryImpact -EntryText $block
        $existingTier = [int]$impact.Tier
        $existingScore = Get-EntryImpactScore -Impact $impact -Tier $existingTier

        # An entry ALREADY in the changelog that declares no score -- one written before the table existed --
        # reads as 0 and therefore sorts below everything scored at its tier. Same fail-safe direction as
        # everywhere else here, and it cannot stop a fold: that entry is already merged, and refusing now
        # would block an unrelated branch over somebody else's line.
        #
        # '-le' on the deciding comparison, not '-lt': an equal rank puts the NEW entry above its equals,
        # which preserves the newest-first order the list already had. '-lt' would push it below them,
        # silently reversing that order for every tie -- and ties are the common case on a five-point scale.
        if ($existingTier -lt $Tier) { return $start }
        if ($existingTier -eq $Tier -and $existingScore -le $Score) { return $start }
    }
    return $SectionText.Length
}
# --- The entry's own shape: one H2 per change, with named sections ---------------------------------
#
# ONE HEADING PER CHANGE, AND THE DOCUMENT HAS NO OTHERS (Dave, August 5, 2026). CHANGELOG.md used to open
# with '## Latest Release' and three '## Tier N - Pull Requests' sections, with each change an '### ' inside
# one of them. All four are gone. A change IS the '## ' heading now -- '## #475 <midDot> A significance score
# per entry' -- and inside it three named '### ' sections answer the three questions a reader actually
# arrives with:
#
#   ### What does this change do?    the description, which used to be a bare paragraph under the heading
#   ### Who is this for              the impact table -- the tiers this change reaches, each with a score
#   ### Type of change               Feat / Fix / Docs / Chore, which used to be a middot field in the heading
#
# WHY THE TYPE MOVED OUT OF THE HEADING. It was the second-to-last middot field, then (when the merge date
# left) a field matched by content against the known branch types. Both were parses of a heading that was
# doing three jobs at once. As its own section it is stated rather than inferred, and the heading is reduced
# to what a reader scans: the PR number and the title.
#
# 'Significance', AND IT IS SUB-SECTIONS RATHER THAN A TABLE (Dave, August 6, 2026). It was
# 'Who is this for' holding an impact table, one row per tier. The table went because it forced a shape onto
# something that is not always rectangular: NOT EVERY CHANGE HAS A TIER 1 OR A TIER 2, and a table makes the
# absence of a row look like an omission rather than an answer. As '#### Tier N' sub-sections, a change that
# reaches nobody outside this repo simply has one section -- which is a complete statement, not a gap.
#
# The heading also stopped naming an audience, because the section no longer answers "who": each sub-section
# names its own audience by its number, and what the section as a whole carries is how much the change WEIGHS
# for each of them.
#
# THE HEADINGS ARE REPO-OWNED, unlike the impact table's column keys. That split follows the one this file
# already makes: a machine-read KEY stays fixed ('Tier', 'Significance', 'Plugins:'), while text a reader
# SEES belongs to the repo that owns the document -- the same #410 reasoning that made the entry stubs and
# the category labels configurable. These are read back by the parser, so a repo that translates them
# translates both halves at once, which is why they come from one resolver rather than being written twice.
$script:EntrySectionDefaults = [ordered]@{
    What         = 'What does this change do?'
    Significance = 'Significance'
    Type         = 'Type of change'
}

# RECOGNISED, NEVER WRITTEN -- the section headings this format has retired. Measured the moment
# 'Who is this for' became 'Significance': all 24 entries pending in CHANGELOG.md carry the old name, and
# the lint's section check reported every one of them as a MISSPELLED heading, which is its most alarming
# finding ("costs that entry its declaration silently"). Twenty-four false accusations is how a check gets
# switched off. Every consumer's changelog and every branch in flight is in the same position, and they
# reach the renamed heading through a plugin update rather than by choosing to.
#
# Deliberately not repo-configurable: these are historical strings, so there is nothing to choose about
# them, and a repo that translated the heading translated the CURRENT one -- their old name lives in their
# own documents, which is why a name-matcher accepts the seam's value AND these.
$script:EntryRetiredSectionHeadings = @(
    'Who is this for'
)

function Get-EntryRetiredSectionHeadings {
    <# Section headings that were once written and are still recognised. A name-matcher accepts these
       alongside Get-EntrySectionHeadings' values; a WRITER must never use them. #>
    return @($script:EntryRetiredSectionHeadings)
}

# The heading levels, stated once. An entry is an H2 and its sections are H3 -- in the entry FILE and in
# CHANGELOG.md alike, which is new: the file used to carry H3 entries that the fold pasted in unchanged, and
# the release renderers re-levelled them per document. One level everywhere means the file a contributor
# writes looks exactly like the block that lands.
$script:EntryHeadingLevel  = 2
$script:EntrySectionLevel  = 3

function Get-EntryHeadingLevel {
    <# The number of '#' an entry's own heading carries (2). Read by the writer, the fold's file test and
       the renderers, so no caller counts hashes for itself. #>
    return $script:EntryHeadingLevel
}

function Get-EntrySectionLevel {
    <# The number of '#' an entry's inner sections carry (3). #>
    return $script:EntrySectionLevel
}

function Get-EntrySectionHeadings {
    <#
        The three section headings as an ordered map, key -> heading TEXT (no leading hashes): What, Who,
        Type. This repo's answers where repo-config.ps1 overrides them, the English defaults otherwise.

        REPO-OWNED VIA Get-EntrySectionHeadingOverrides, probed with Get-Command like every other prose knob
        here. The seam's name differs from this function's deliberately: repo-config backs each seam with a
        function of that name, and a same-named reader would be replaced by the config's version the moment
        it is dot-sourced -- the collision this file documents on $RepoRoot/$repoRoot, one scope up.

        An override that is present but EMPTY is ignored, the same fail-safe Get-EntryScaffoldWording uses.
        A blank heading would make the parser look for '### ' with nothing after it, which matches the start
        of every section in the document -- so the type reader would return the first section's body and the
        entry would be filed under a type nobody wrote.
    #>
    $out = [ordered]@{}
    foreach ($key in $script:EntrySectionDefaults.Keys) { $out[$key] = $script:EntrySectionDefaults[$key] }
    if (Get-Command Get-EntrySectionHeadingOverrides -ErrorAction SilentlyContinue) {
        $override = Get-EntrySectionHeadingOverrides
        if ($override) {
            foreach ($entry in $override.GetEnumerator()) {
                $text = [string]$entry.Value
                if ($text) { $out[[string]$entry.Key] = $text.Trim() }
            }
        }
    }
    return $out
}

function Get-EntrySectionHeading {
    <# One section's full heading line, e.g. '### Type of change'. One formatter, so the writer and the
       parser cannot disagree about the level or the spacing. #>
    param([Parameter(Mandatory)][ValidateSet('What', 'Significance', 'Type')][string]$Key)
    $headings = Get-EntrySectionHeadings
    return ('#' * $script:EntrySectionLevel) + ' ' + $headings[$Key]
}

function Get-EntrySectionBody {
    <#
        Pure: the text under one of an entry's named sections, trimmed -- '' when the section is absent or
        empty.

        FENCE-AWARE, and the FIRST occurrence outside a fence wins, for the reason every reader in this file
        is: an entry documenting this format quotes these headings inside a fence, and the entry for this
        very change does. A section ends at the next heading of ANY level, so a '#### ' sub-heading inside a
        body is kept while the next '### ' or '## ' closes it.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$EntryText,
        [Parameter(Mandatory)][ValidateSet('What', 'Significance', 'Type')][string]$Key
    )
    $wanted = (Get-EntrySectionHeadings)[$Key]
    if (-not $wanted) { return '' }
    $body = Get-EntryTextOutsideFences -EntryText $EntryText
    $lines = @($body -split '\r?\n')
    $rx = '^#{' + $script:EntrySectionLevel + '}\s+' + [regex]::Escape($wanted) + '\s*$'

    $from = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $rx) { $from = $i + 1; break }
    }
    if ($from -lt 0) { return '' }

    $kept = @()
    for ($i = $from; $i -lt $lines.Count; $i++) {
        # Any heading at this level or above closes the section; a deeper one is content.
        if ($lines[$i] -match ('^#{1,' + $script:EntrySectionLevel + '}\s')) { break }
        $kept += $lines[$i]
    }
    return (($kept -join "`n").Trim())
}

function Get-ReleaseChangeTypes {
    <#
        The change types the repo's branch table produces -- 'Feat', 'Fix', 'Docs', 'Chore' here. Read from
        Get-BranchTypes in the consumer's own scripts/lib/branch-info.ps1 where the caller has dot-sourced
        it; absent, it falls back to the four canonical types.

        THE FALLBACK IS THE POINT, not a convenience. branch-info.ps1 is repo-owned and deliberately does
        not travel into the plugin mirror, so 'absent' is the ORDINARY case in a consumer rather than an
        edge one -- and the readers below need a list to recognise a type field with, not merely to validate
        against. Measured: while this returned only Get-BranchTypes' answer, new-internal-note.ps1 running
        in a consumer lost the type off every bullet it took from a historical heading, printing the title
        alone with no error.

        IT LIVES HERE, IN THE LIB THAT OWNS THE ENTRY FORMAT, because two of its three readers are here --
        Resolve-EntryType, for the pre-format heading fallback, and the internal note's recogniser through
        it -- and the dependency can only run downward: the fold and this file's own suite load this lib
        standalone. It used to sit in release-lib.ps1, whose Convert-EntryHeadingToTitle still calls it by
        this same name, unchanged, through that file's dot-source of this one.

        NO 'Other' HERE. That was the catch-all CATEGORY LABEL of the retired Get-ReleaseCategories -- a
        thing this repo printed, never a value a branch table produces -- so a heading field reading 'Other'
        is a title by construction rather than by a special case.

        Probed with Get-Command rather than taken as a parameter, the same pattern teardown.ps1 uses for
        Get-RosterIdTokenPattern.
    #>
    if (Get-Command Get-BranchTypes -ErrorAction SilentlyContinue) { return @(Get-BranchTypes) }
    return @('Feat', 'Fix', 'Docs', 'Chore')
}

function Resolve-EntryType {
    <#
        Pure: the changelog type an entry declares under '### Type of change'. Returns an object with

          Type      the type as written, trimmed -- '' when nothing usable is declared.
          Declared  $true when the section was found with a value.
          Raw       exactly what the section contained, for quoting back at the author.
          Error     $null when all is well; otherwise the reason, ready to print.

        VALIDATED AGAINST THE REPO'S OWN BRANCH TYPES where those are reachable (Get-BranchTypes, which the
        callers dot-source for other reasons). A type the repo does not produce is reported rather than
        absorbed: the release documents group nothing by it any more, but a typo'd type still reaches the
        record and the per-plugin changelogs, where nobody looks again.

        THE FIRST LINE IS THE TYPE, and anything after it is ignored rather than refused. 'Feat' with a
        sentence of justification under it is a reasonable thing to write, and refusing it would make the
        gate an editor.

        FALLS BACK TO THE HEADING for an entry written before this format -- '### Title <midDot> Feat' or the
        older '### Title <midDot> Feat <midDot> 2026-08-03'. Every entry in this repo's history and in every
        consumer's tree carries the type there, and reading them as typeless would file the lot under a
        catch-all. Recognise both, write one.

        RECOGNITION AND VALIDATION USE DIFFERENT LISTS, and conflating them was a measured defect. Both used
        to read Get-BranchTypes and nothing else, so where that function is absent the known-type list was
        EMPTY -- which is right for validation (with no table of its own, a repo has nothing to judge a type
        against) and wrong for recognition (with no list, no heading field can be identified as the type at
        all). branch-info.ps1 is repo-owned and therefore does NOT travel into the plugin mirror, so the
        absent case is the ordinary one in a consumer: new-internal-note.ps1 running there lost the type off
        every bullet it took from a historical heading, silently, printing the title alone. Recognition now
        uses Get-ReleaseChangeTypes -- which probes the repo's table and falls back to the canonical four --
        while validation still only fires where the repo's own table is reachable.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $result = [pscustomobject]@{
        Type     = ''
        Declared = $false
        Raw      = ''
        Error    = $null
    }

    # Two lists, two jobs -- see the header. $repoTypes is empty where the repo has no table of its own, and
    # only that list may accuse an author of a wrong type; $known always has something to recognise with.
    $repoTypes = @()
    if (Get-Command Get-BranchTypes -ErrorAction SilentlyContinue) { $repoTypes = @(Get-BranchTypes) }
    $known = @(Get-ReleaseChangeTypes)

    $section = Get-EntrySectionBody -EntryText $EntryText -Key 'Type'
    if ($section) {
        $result.Raw = $section
        $result.Declared = $true
        # The first non-empty line, stripped of the bold/backtick decoration somebody may reasonably add.
        $first = @($section -split '\r?\n' | Where-Object { $_.Trim() })[0]
        $result.Type = ($first -replace '[*`_]', '').Trim()
        if ($repoTypes.Count -gt 0 -and $repoTypes -notcontains $result.Type) {
            $result.Error = "'$($result.Type)' is not a change type this repo produces -- use one of: $($repoTypes -join ', ')."
        }
        return $result
    }

    # Pre-format fallback: the type as a middot field in the heading.
    $md = [char]0x00B7
    $bodyOutside = Get-EntryTextOutsideFences -EntryText $EntryText
    $headingLine = @($bodyOutside -split '\r?\n' | Where-Object { $_ -match '^#{2,6}\s' })
    if ($headingLine.Count -gt 0 -and $known.Count -gt 0) {
        $fields = @(($headingLine[0] -replace '^#+\s+', '') -split "\s*$md\s*")
        # The LAST matching field wins, which resolves an entry whose title IS a type name
        # ('## #12 <midDot> Fix <midDot> Fix') -- the same rule the retired heading parser used.
        for ($i = $fields.Count - 1; $i -ge 0; $i--) {
            $candidate = $fields[$i].Trim()
            if ($known -contains $candidate) {
                $result.Type = $candidate
                $result.Declared = $true
                $result.Raw = $candidate
                return $result
            }
        }
    }
    return $result
}

function Format-EntryBlock {
    <#
        The whole entry as an array of LINES: the H2 heading, then the three H3 sections in order.

        ONE FORMATTER FOR THE WRITER AND THE MIGRATION, which is why it takes pieces rather than assembling
        prose. new-changelog-entry.ps1 calls it with a placeholder body and no rows; a migration calls it
        with real ones. Two assemblers would drift, and the parser reads what this writes.

        $Title carries no type and no date. The fold prepends '#NN <midDot> ' to it after the merge, and
        appends the PR/merge line at the end of the block -- the two facts that do not exist until then.
    #>
    param(
        [Parameter(Mandatory)][string]$Title,
        [string]$Type = '',
        [string]$Body = '',
        $ImpactRows = @()
    )
    # Each line appended on its own statement, NOT as @(<expr>, '') -- the comma operator binds looser than
    # '+', so `@(('#'*2) + ' ' + $Title, '')` concatenates the string with the ARRAY ($Title, '') and joins
    # it with a space. That produced '## A real title ' with a trailing space and no blank line after it,
    # which is well-formed markdown and therefore invisible until a parser expecting the blank line fails.
    # Measured on this function's first run.
    $heading = ('#' * $script:EntryHeadingLevel) + ' ' + $Title.Trim()
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add($heading)
    $lines.Add('')
    $lines.Add((Get-EntrySectionHeading -Key 'What'))
    $lines.Add('')
    foreach ($line in ($Body -split '\r?\n')) { $lines.Add($line) }
    $lines.Add('')
    $lines.Add((Get-EntrySectionHeading -Key 'Significance'))
    $lines.Add('')
    foreach ($line in (Format-EntrySignificanceSections -Rows $ImpactRows)) { $lines.Add($line) }
    $lines.Add('')
    $lines.Add((Get-EntrySectionHeading -Key 'Type'))
    $lines.Add('')
    $lines.Add($Type)
    return @($lines.ToArray())
}

# --- RETIRED, AUGUST 5, 2026: the changelog's tier sections ---------------------------------------
#
# $script:DefaultChangelogHeading, Resolve-ChangelogTierSections and Get-ChangelogTierSections answered
# one question -- which '## ' heading a merged entry is filed under -- for the three readers that had to
# agree about it: the fold, release-lib's parser and the release cut. CHANGELOG.md has no section
# headings any more. An entry IS an H2 and the document is an intro plus a ranked list of them, so the
# question has no subject: there is no heading to name, and therefore nothing for three readers to
# disagree about.
#
# WHAT REPLACED IT IS NOT A DIFFERENT ANSWER BUT A STRUCTURAL ONE. The fold derives the intro/list
# boundary from the first entry heading (Get-EntryHeadingLevel), and release-lib's Split-Changelog does
# the same. Both are exact-level matches, which is safe for the reason Get-EntryHeadingPattern there
# spells out: '^##' followed by whitespace cannot match an entry's own '### ' sections.
#
# THE SEAMS GO WITH THEM: Get-ChangelogTierHeadings and the older single-section Get-ChangelogHeading
# (issue #178) in the consumer's scripts/repo-config.ps1 are no longer read by anything. A consumer that
# still defines either is unaffected -- nothing calls them, so they are dead code in that repo's seam,
# and its next fold and cut behave exactly as this repo's do.
#
# Test-EntrySignificanceActive above used to infer "does this repo rank" from the number of sections this
# returned, and that is the one place the retirement was NOT a pure deletion; see its header for why the
# default had to become on rather than off.

function Test-EntryDeclaresShape {
    <#
        Pure: does this block actually look like an ENTRY? $true when it declares its named sections (any
        one of the three headings, outside fences) or a change type (the Type section, or the pre-format
        type field in its heading, via Resolve-EntryType).

        WHY THIS EXISTS, AND IT IS A MEASURED CONSUMER DEFECT RATHER THAN TIDINESS (August 5, 2026). With
        the changelog flat, every '## ' below the intro is read as one change. A consumer whose CHANGELOG.md
        still carries the pre-flat shape has section headings at exactly that level -- '## Pull Requests',
        '## Tier 2 - Pull Requests', '## Releases' -- and the updated shared scripts reach them through a
        plugin update rather than by their choosing. Measured against both shapes:

          * the single-section consumer: '## Pull Requests' parses as ONE entry swallowing all of their real
            entries, and '## Releases' as a second one -- so their entire release history is published into
            the release notes and the per-plugin CHANGELOGs as a "change", and then DELETED from
            CHANGELOG.md, because the cut keeps only the intro;
          * the consumer who had adopted the tier sections: three entries named after the three headings.

        AND NOTHING REFUSED. Every one of those blocks declares no impact, so Test-ReleaseBumpEarned reads
        the repo as never having adopted the model and reports itself INACTIVE -- correctly, by its own
        rule -- which means the release proceeds. Silent, correct-looking, and it loses data.

        SO THE PARSER REFUSES INSTEAD, and this predicate is the test it refuses on. The discriminator is
        exact rather than a heuristic: the format has two legitimate shapes and both declare something. A
        current entry carries the three named sections; a pre-format entry carries its type as a heading
        field, which is what new-changelog-entry.ps1 wrote for as long as that shape existed. A leftover
        section heading carries neither, and cannot -- it is a heading with prose under it.

        Deliberately NOT keyed on the '#NN' the fold prepends: the fold cannot reach gh on a manual merge
        and then writes a legitimate entry with no number, saying so on the console. A gate keying on the
        number would report the fold's own documented output as a defect.

        FENCE-AWARE through the readers it calls, for the reason every reader here is: an entry documenting
        this format quotes these headings inside a fence, and the entry for this very change does.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $body = Get-EntryTextOutsideFences -EntryText $EntryText
    $lines = @($body -split '\r?\n')
    foreach ($heading in (Get-EntrySectionHeadings).Values) {
        if (-not $heading) { continue }
        $rx = '^#{' + $script:EntrySectionLevel + '}\s+' + [regex]::Escape([string]$heading) + '\s*$'
        foreach ($line in $lines) {
            if ($line -match $rx) { return $true }
        }
    }
    return [bool](Resolve-EntryType -EntryText $EntryText).Declared
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

    $checks = @(
        @{ Label = 'the placeholder title';   Marker = $Wording.Title },
        @{ Label = 'the scaffold body heading'; Marker = $Wording.BodyHeading },
        @{ Label = 'the fallback body';       Marker = $Wording.BodyPlaceholder }
    )
    # The strings the scaffolder used to write, still refused. See $script:EntryScaffoldLegacyMarkers.
    foreach ($legacy in $script:EntryScaffoldLegacyMarkers) {
        $checks += @{ Label = 'a retired scaffold placeholder'; Marker = $legacy }
    }

    $findings = @()
    foreach ($p in $checks) {
        if (-not $p.Marker) { continue }
        if ($body.Contains($p.Marker)) {
            $findings += [pscustomobject]@{ Label = $p.Label; Marker = $p.Marker }
        }
    }
    return $findings
}

# --- THE branch/ DIRECTORY: two files per branch, both with a reset state -------------------------
#
# Dave, August 6, 2026. A branch's working files live in ONE known directory instead of a file named
# after the branch in the repo root, and there are TWO of them because they answer two different
# questions for two different readers:
#
#   branch/branch-changelog.md   what the change DOES     -- for whoever reads CHANGELOG.md later
#   branch/branch-progress.md    what still MUST HAPPEN   -- for whoever is working on the branch
#
# THE SPLIT IS THE POINT. The root entry file did both jobs: new-changelog-entry.ps1 scaffolded it with
# a body heading that literally read '**To do / where I left off:**', and open-pr's scaffold gate
# refused to ship while that heading survived. So one file was today's to-do list AND tomorrow's
# changelog prose, which is why "replace this whole block before the PR" had to be a written
# instruction rather than something the format made obvious. Two files make it obvious.
#
# WHY FIXED NAMES RATHER THAN ONE PER BRANCH, which looks like it should collide the moment two
# branches exist. It cannot: git already tracks these files per branch, so each branch carries its own
# version of the same path and a checkout swaps them. The per-branch filename was solving a problem
# version control had already solved, and it cost a repo root that filled up with other people's work.
#
# THE RESET STATE IS WHAT LIVES ON THE TRUNK, and it is load-bearing rather than cosmetic. Both reset
# files open with an H1, so Test-IsChangelogEntryFile in the fold ignores them exactly as it ignores
# CONTRIBUTING.md -- while a FILLED branch-changelog.md opens with the entry's own H2 and is folded.
# One structural test, no new flag, and the trunk state cannot be mistaken for an unfolded entry.
#
# AND THE FILLED CHANGELOG FILE IS NOTHING BUT THE ENTRY BLOCK -- no header, no branch line, no
# warning. That is deliberate and it is Dave's requirement restated: the file must be copy-pasteable
# into CHANGELOG.md in one go. Anything wrapped around the entry would have to be stripped by whoever
# pastes it, which is the manual step the format exists to remove. The branch name therefore lives in
# branch-progress.md, the file that has room for it.

$script:BranchFileDefaults = [ordered]@{
    ChangelogTitle = 'Branch changelog'
    ProgressTitle  = 'Branch progress'
    BranchLabel    = 'Branch'
    StepsHeading   = 'Steps'
    NotesHeading   = 'Where I left off'
    FirstStep      = 'TODO: the first step of this branch'
    NotesPlaceholder = 'TODO: what has been done so far, and what you were in the middle of.'
    ChangelogReset = @(
        'This file carries the changelog entry of the branch you are on -- the finished description that',
        'folds into `CHANGELOG.md` at the merge. It is written when a branch is created and returns to this',
        'state once the entry has been folded, so what you see here is the empty state, not a lost entry.'
    )
    ProgressReset  = @(
        'This file carries the step list of the branch you are on. It is written when a branch is created',
        'and returns to this state after the merge.'
    )
    TrunkWarning   = @(
        'Do not work in this file yet -- create a branch first.',
        'Anything written here on the trunk belongs to no branch, will not be folded, and is in the way',
        'of the next person who does create one.'
    )
    ScaffoldNote   = 'filled in when a branch is created'
}

function Get-BranchTrunkName {
    <#
        The trunk this repo merges into, 'main' unless the consumer says otherwise via an OPTIONAL
        Get-TrunkBranchName in scripts/repo-config.ps1.

        It is here rather than inline because THREE things need the same answer and one of them writes
        it into a document: new-changelog-entry.ps1 refuses to scaffold on the trunk, the reset template
        below names the trunk in its warning, and the fold writes that template back. A literal 'main'
        in each is the shape where a consumer on 'master' gets a correct refusal and a document that
        tells them the wrong branch name.
    #>
    if (Get-Command Get-TrunkBranchName -ErrorAction SilentlyContinue) {
        $v = Get-TrunkBranchName
        if ($v) { return [string]$v }
    }
    return 'main'
}

function Get-BranchFilePaths {
    <#
        The two branch files' repo-relative paths and the directory holding them, as ONE object.

        FORWARD SLASHES, deliberately: these strings are handed to git (pathspecs, ls-files comparison)
        as often as to Join-Path, and Join-Path on Windows accepts '/' while git's own output never uses
        '\'. The one place that needs the backslash form converts at the boundary, which is where the
        fold already does it for the legacy root entries.

        Not repo-configurable, and that is the same call CHANGELOG.md's own name gets: this is the
        FORMAT the shared scripts read, not prose about it. A consumer renaming the directory would be
        renaming the interface between four scripts, which is what a fork is for. The WORDING inside the
        files is configurable -- see Get-BranchFileWording -- because that is language, and language is
        the thing #410 established a repo owns.
    #>
    return [pscustomobject]@{
        Directory = 'branch'
        Changelog = 'branch/branch-changelog.md'
        Progress  = 'branch/branch-progress.md'
    }
}

function Get-BranchFileWording {
    <#
        The prose inside the two branch files -- this repo's answers where repo-config.ps1 gives them,
        the English defaults otherwise.

        ONE GETTER RETURNING A MAP, unlike Get-EntryScaffoldWording's three separate ones, and the
        difference is deliberate rather than inconsistency. Those three are each read by a GATE that
        must match the writer string-for-string, so each is its own contract with its own name. These
        nine are document prose read by nobody but the reader of the file; a repo translating one
        translates all of them, and nine seam functions to translate a template would be nine entries in
        the script contract for one act.

        A key present but EMPTY is ignored, the same fail-safe Get-EntryScaffoldWording uses: an empty
        heading would produce a document with a blank line where its title should be, and nothing would
        report it.
    #>
    $out = [ordered]@{}
    foreach ($key in $script:BranchFileDefaults.Keys) { $out[$key] = $script:BranchFileDefaults[$key] }
    if (Get-Command Get-BranchFileWordingOverrides -ErrorAction SilentlyContinue) {
        $overrides = Get-BranchFileWordingOverrides
        if ($overrides) {
            foreach ($key in @($out.Keys)) {
                # Two containers to support, because a seam is hand-written: a hashtable is what a
                # consumer reaches for, an ordered dictionary is what copying the block above produces.
                $v = $null
                if ($overrides -is [System.Collections.IDictionary]) {
                    if (-not $overrides.Contains($key)) { continue }
                    $v = $overrides[$key]
                } elseif ($overrides.PSObject.Properties[$key]) {
                    # A pscustomobject cannot be indexed by string in PS 5.1 -- $o['Key'] returns $null
                    # silently, which would read as "override absent" for every key a consumer set.
                    $v = $overrides.PSObject.Properties[$key].Value
                } else { continue }
                if ($v) { $out[$key] = $v }
            }
        }
    }
    return [pscustomobject]$out
}

function Format-BranchFileHeader {
    <#
        Private: the H1, the branch line and -- on the trunk only -- the warning under it. Both files
        open with exactly this, which is what makes them one recognisable pair rather than two documents
        that happen to live in a directory.

        THE WARNING IS KEYED ON THE BRANCH BEING THE TRUNK, not on the file being in its reset state,
        and those come apart in the case worth catching: someone runs `git checkout -b` by hand instead
        of new-branch, so the files are still reset while HEAD is on a real branch. Keying on the trunk
        keeps the warning off that person's screen -- they are allowed to work here -- while the empty
        step list still says the scaffold never ran.

        Returns a string ARRAY rather than the List it builds, and the callers append its lines to their
        own list. Returning the List itself does not work: PowerShell unrolls a returned collection, so
        `$lines = Format-BranchFileHeader ...` hands the caller an object[] -- fixed-size -- and every
        subsequent .Add() throws. Measured on this function's first run.
    #>
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Branch,
        [Parameter(Mandatory)][pscustomobject]$Wording
    )
    $trunk = Get-BranchTrunkName
    $shown = if ($Branch) { $Branch } else { $trunk }
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# ' + $Title)
    $lines.Add('')
    $lines.Add('**' + $Wording.BranchLabel + ':** `' + $shown + '`')
    if ($shown -eq $trunk) {
        $lines.Add('')
        $lines.Add('> **You are on `' + $trunk + '`.** ' + $Wording.TrunkWarning[0])
        foreach ($line in @($Wording.TrunkWarning | Select-Object -Skip 1)) { $lines.Add('> ' + $line) }
    }
    return @($lines.ToArray())
}

function New-BranchFileLines {
    <#
        Private: a fresh line list already carrying the shared header. Every branch file starts this way,
        and having the three formatters call ONE helper is what keeps them from drifting apart on the
        blank line after the header -- the kind of difference that is invisible until a diff shows two
        files disagreeing about their own shape.
    #>
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Branch,
        [Parameter(Mandatory)][pscustomobject]$Wording
    )
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in (Format-BranchFileHeader -Title $Title -Branch $Branch -Wording $Wording)) {
        $lines.Add($line)
    }
    # `,$lines`, not `$lines`: PowerShell unrolls a returned collection, so a bare return would hand the
    # caller a fixed-size object[] and its next .Add() would throw. The leading comma wraps the List in a
    # one-element array, and it is that outer array PowerShell unrolls -- leaving the List intact.
    return ,$lines
}

function Format-BranchChangelogReset {
    <#
        branch/branch-changelog.md in its empty state -- what lives on the trunk, and what the fold
        writes back once the entry has landed in CHANGELOG.md.

        Opens with an H1 so the fold's own entry test skips it. That is the whole back-pressure: a reset
        file cannot be folded twice, and a release cannot mistake it for work somebody forgot to fold.
    #>
    param([string]$Branch = '')
    $w = Get-BranchFileWording
    $lines = New-BranchFileLines -Title $w.ChangelogTitle -Branch $Branch -Wording $w
    $lines.Add('')
    foreach ($line in @($w.ChangelogReset)) { $lines.Add($line) }
    return @($lines.ToArray())
}

function Format-BranchProgressReset {
    <#
        branch/branch-progress.md in its empty state. Same shape as the changelog reset, plus the empty
        step list -- so the file a reader opens on the trunk already shows them what it will look like
        once it is theirs.
    #>
    param([string]$Branch = '')
    $w = Get-BranchFileWording
    $lines = New-BranchFileLines -Title $w.ProgressTitle -Branch $Branch -Wording $w
    $lines.Add('')
    foreach ($line in @($w.ProgressReset)) { $lines.Add($line) }
    $lines.Add('')
    $lines.Add('## ' + $w.StepsHeading)
    $lines.Add('')
    $lines.Add('_(' + $w.ScaffoldNote + ')_')
    return @($lines.ToArray())
}

function Format-BranchProgressScaffold {
    <#
        branch/branch-progress.md as it is written when a branch is created: the branch's own name, an
        open first step, and a place to record where you left off.

        THE STEP LIST IS A CHECKBOX LIST because that is the form the requirement was given in -- work
        is ticked off, and the list is done when nothing is open. Since August 6, 2026 that IS a gate:
        open-pr.ps1 and ship-pr.ps1 refuse while a step is unresolved (Get-BranchProgressFindings), so
        the placeholder written here is deliberately one open step -- you cannot reach a PR without
        having stated your own.

        -Intent, when given, becomes the "where I left off" note rather than the first step: parking a
        branch records what HAS happened, and a step list scaffolded with someone's status text as its
        only entry would read as an instruction to do it again.
    #>
    param(
        [Parameter(Mandatory)][string]$Branch,
        [string]$Intent = ''
    )
    $w = Get-BranchFileWording
    $lines = New-BranchFileLines -Title $w.ProgressTitle -Branch $Branch -Wording $w
    # H2 as a literal, NOT ('#' * $script:EntryHeadingLevel). Both happen to be 2 today, and reusing the
    # entry's level would silently move this file's sections the day the changelog's entry level changes
    # -- a coupling between two formats that have nothing to do with each other. This file's own shape is
    # H1 title, H2 sections, and it owns that.
    $lines.Add('')
    $lines.Add('## ' + $w.StepsHeading)
    $lines.Add('')
    $lines.Add((Get-BranchProgressMarks).Open + $w.FirstStep)
    $lines.Add('')
    $lines.Add('## ' + $w.NotesHeading)
    $lines.Add('')
    if ($Intent) {
        foreach ($line in ($Intent -split '\r?\n')) { $lines.Add($line) }
    } else {
        $lines.Add($w.NotesPlaceholder)
    }
    return @($lines.ToArray())
}

function Get-BranchFileDeclaredBranch {
    <#
        Pure: the branch a branch file says it belongs to -- the name in its '**Branch:** `x`' line -- or
        '' when the file has no such line.

        THIS IS THE IDEMPOTENCY TEST, and it is why the branch line is in the document rather than only in
        the scaffolder's head. new-changelog-entry.ps1 may be run twice on the same branch (it is, by
        new-branch, which is itself idempotent), and the second run must not overwrite a step list somebody
        has been ticking off. Comparing the declared branch against HEAD answers that exactly: the trunk
        name means the file is still in its reset state and is ours to write, any other name means it is
        already someone's working file.

        The label is read from the wording rather than hardcoded, so a repo that translated it can still be
        recognised -- a predicate that only knows the English label would read every file in a translated
        repo as unscaffolded and overwrite it.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $label = (Get-BranchFileWording).BranchLabel
    $rx = '^\*\*' + [regex]::Escape([string]$label) + ':\*\*\s*`([^`]+)`\s*$'
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match $rx) { return $Matches[1] }
    }
    return ''
}

$script:BranchProgressMarks = [ordered]@{
    Open    = '- [ ] '
    Done    = '- [x] '
    Dropped = '- [~] '
}

function Get-BranchProgressMarks {
    <# The three step marks, as one object: Open, Done, Dropped. One owner, because the writer of the
       scaffold, the gate that refuses an open step and the README that teaches the convention all have
       to mean the same three strings. #>
    return [pscustomobject]$script:BranchProgressMarks
}

function Get-BranchProgressFindings {
    <#
        Pure: the reasons this step list is not finished, as an array of objects with Label and Line.
        Empty means every step has been resolved -- ticked or deliberately dropped.

        TWO KINDS OF FINDING, and the second is what stops the gate from being a formality:

          * an OPEN step ('- [ ] ') -- work that was written down and has not been resolved;
          * a step still carrying the SCAFFOLD's placeholder text, ticked or not. Ticking the
            scaffolded first step without replacing it is the exact shape the entry's own scaffold gate
            was measured on at v3.2.0 (author keeps the stub, appends a status), and here it would be
            worse: it reports a plan as finished that was never written.

        '- [~] ' IS THE SANCTIONED WAY PAST A STEP THAT TURNED OUT NOT TO BE NEEDED, and it exists
        because the alternative is worse than no gate. A plan legitimately grows items that stop making
        sense; with only two marks available the gate teaches people to tick boxes for work they did not
        do, and then it reports success. A dropped step keeps its line and its reason on the page, which
        is the half that is actually worth reading later.

        FENCE-AWARE, like every reader of this format: a step list may quote the convention it follows --
        this repo's own README does -- and a guard that cannot tell a quote from a real step gets
        switched off by the first person it accuses wrongly.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    $marks = Get-BranchProgressMarks
    $body = Get-EntryTextOutsideFences -EntryText $Text
    $placeholder = (Get-BranchFileWording).FirstStep

    $findings = @()
    foreach ($line in ($body -split '\r?\n')) {
        $trimmed = $line.TrimStart()
        if ($trimmed.StartsWith($marks.Open)) {
            $findings += [pscustomobject]@{ Label = 'still open'; Line = $trimmed }
        } elseif ($placeholder -and $trimmed.Contains($placeholder)) {
            # Reached only for a ticked or dropped line, since an open one is already reported above --
            # so this says "resolved, but it still says what the scaffold wrote", which is the lie.
            $findings += [pscustomobject]@{ Label = 'still the scaffolded step'; Line = $trimmed }
        }
    }
    return $findings
}

function Test-BranchChangelogIsFilled {
    <#
        Pure: does branch/branch-changelog.md hold an actual entry, or is it still (back) in its reset
        state? True means there is an entry here -- the file opens with the entry heading level.

        THE SAME STRUCTURAL TEST THE FOLD USES, and on purpose: the fold decides "is this an entry" by
        the first non-blank line's heading level, so a second predicate answering the same question a
        different way is how a release cut and a fold start disagreeing about whether work is pending.
        Both levels are accepted for the reason Test-IsChangelogEntryFile accepts both -- an entry
        written before the flat format is still an entry.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $entryLevel  = Get-EntryHeadingLevel
    $legacyLevel = $entryLevel + 1
    $rx = '^#{' + $entryLevel + ',' + $legacyLevel + '}\s'
    foreach ($line in ($Text -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        return ($line -match $rx)
    }
    return $false
}
