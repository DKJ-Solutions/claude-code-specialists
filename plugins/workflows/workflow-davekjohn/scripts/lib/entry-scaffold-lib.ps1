<#
.SYNOPSIS
    The changelog entry's own format, in one place: the scaffold strings new-branch.ps1
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
    2026). How far a change reaches is written by new-branch.ps1, validated by open-pr.ps1 before a
    PR can ship, read by fold-changelog-entry.ps1 to decide where in CHANGELOG.md the entry lands, and read
    again by the release cut to decide which documents it appears in. Four scripts, one format: a copy in
    each is how a fold starts filing tier-2 work as repo-internal without anything erroring.

    THE DECLARATION IS NOW A TABLE, AND THE OLDER 'Tier: N' LINE IS STILL RECOGNISED -- this repo's standing
    "recognise both, write one" rule, because every entry already merged and every entry in a consumer's tree
    predates the table.

    REPO-OWNED, WITH BUILT-IN DEFAULTS (#410). Each string comes from an OPTIONAL function in the
    consumer's scripts/repo-config.ps1 -- Get-EntryTitlePlaceholder, Get-EntryBodyHeading,
    Get-EntryBodyPlaceholder -- probed with Get-Command and falling back to the English value
    new-branch.ps1 used to hardcode. A consumer that defines none of them is unaffected.
    (Get-EntryFallbackType is deliberately NOT here: it is a changelog TYPE, not scaffold prose --
    'Chore' is a legitimate final value, so it can never be evidence of an unedited entry.)

    Pure ASCII (repo convention for .ps1).
#>

# The English fallbacks, and the ONLY copy of them. new-branch.ps1 held these literals until
# the gate needed the same list; it now reads them from here.
#
# TWO OF THESE ARE NO LONGER WRITTEN, ONLY RECOGNISED (Dave, August 6, 2026). Until the branch/ split the
# entry file was also the branch's to-do list, so new-branch.ps1 scaffolded it with a
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
    'TODO: what still needs to happen on this branch, and where you left off.',
    # Retired with the dossier form (August 6, 2026): the tier sub-sections were scaffolded with a visible
    # why-placeholder under their guidance comment, and now carry the comment alone. Still refused, for the
    # reason all of these are -- every branch in flight, here and in every consumer, has one in its entry
    # right now, and a gate that forgot it would wave exactly those into CHANGELOG.md.
    'TODO: why this change matters at this reach.'
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
# orders CHANGELOG.md's flat list on, since August 5, 2026. The ladder as it stood then (Dave, August 5,
# 2026 -- tiers 1 and 2 REDEFINED on August 12, 2026 by the ONE AUDIENCE TIER block below, which wins
# wherever the two disagree):
#
#   Tier 0 -- nobody outside this repo's own developers notices. Docs, config, repo-internal work.
#   Tier 1 -- then "a colleague working on this project"; NOW management and the employer/commissioner.
#             A colleague maintaining the repo is tier 0's audience, not tier 1's.
#   Tier 2 -- then "a consumer of the product"; NOW the subscriber of a service. The webshop worked
#             example separates them: its customers buy a product and never read a release note, so the
#             old wording sent that repo to 2 and the current model sends it to 1.
#
# The ladder was CUMULATIVE then -- tier 2 implied tier 1, so a tier-2 entry appeared in both documents.
# Since August 12, 2026 no tier implies another; the cumulative reading survives only in entries written
# before that date, which every parser here must still read.
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

# --- ONE AUDIENCE TIER PER REPO (Dave, August 12, 2026; inbound #620) -----------------------------
#
# Tier 1 and tier 2 stopped being two rungs of one ladder and became two KINDS of audience, of which a
# repo has exactly one: 1 is management and the employer/commissioner, 2 is the subscriber of a service.
# A webshop's customers buy a product and never read a release note, so its audience is 1; a repo that IS
# the service somebody subscribes to answers 2. Tier 0 -- the people maintaining the repo -- is always
# asked for, in every repo, and is not part of this question.
#
# WHAT THIS DOES *NOT* CHANGE: Get-EntryTierMax stays 2, and every validator above and below keeps using
# it. That separation is the whole safety of the change. The MAX says which tier NUMBERS are valid to
# READ -- and a tier-1 repo must still read a tier-2 entry, because 97 entries in this repo's record and
# every entry in a consumer's tree were written under the cumulative model. The AUDIENCE says which tiers
# this repo ASKS ABOUT when it scaffolds and when it judges completeness. Collapsing the two would make
# one repo's history unreadable to the other, silently, which is the direction that empties a release.
function Get-EntryAudienceTier {
    <#
        The one audience tier this repo asks its entries about -- Get-ReleaseAudienceTier's answer -- or
        $null where the repo has stated none.

        PROBED, NEVER REQUIRED, and $null is a real answer rather than a failure: it means "ask about every
        tier the model has", which is exactly what this system did before the knob existed. That default is
        deliberate and it is the opposite of the reading the policy invites. "The correct tier is enabled
        once the audience is clear" is about a repo's own preparation, not about what an unconfigured script
        should do -- and treating absence as "enable nothing" would switch the audience tier off in every
        consumer the moment they take the plugin update, with nothing erroring and a release document going
        out empty. Absent therefore means UNCHANGED.

        A value outside the model is ignored rather than honoured, for the reason every override here is:
        a seam returning 7 would otherwise have the scaffolder write a section no validator accepts, and a
        gate that refuses every entry in the repo is worse than a gate nobody configured.
    #>
    if (-not (Get-Command Get-ReleaseAudienceTier -ErrorAction SilentlyContinue)) { return $null }
    $v = & Get-ReleaseAudienceTier
    if ($null -eq $v) { return $null }
    if ("$v" -notmatch '^\d+$') { return $null }
    $t = [int]$v
    # 1 is the floor, not 0: tier 0 is asked for unconditionally, so naming it here would say nothing.
    if ($t -lt 1 -or $t -gt $script:EntryTierMax) { return $null }
    return $t
}

function Get-EntryAskedTiers {
    <#
        The tiers an entry in THIS repo is asked to answer, lowest first: tier 0 plus the audience tier --
        or every tier the model has, where no audience is stated.

        ONE ANSWER, THREE READERS, which is why it is a function rather than three inline expressions. The
        scaffolder writes these sections, the routing question under each one points at the NEXT of them,
        and the completeness gate asks for exactly these. Three copies of that arithmetic is how a
        scaffolder starts writing a section its own gate does not ask about.
    #>
    $audience = Get-EntryAudienceTier
    if ($null -eq $audience) { return @(0..$script:EntryTierMax) }
    return @(0, $audience)
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
        the renderers that build the consumer document, the per-plugin CHANGELOGs and the release cards. That wiring
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
# CUMULATIVE -- tier 2 implies tier 1, so a tier-2 change appears in the consumer document AND in the internal
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
# a GUESS, and this repo has measured what a guessed ranking costs. The retired remove-before-publishing marker guessed
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
# BOLD SINCE THE DOSSIER FORM (Dave, August 6, 2026), and the plain form is still read. 'Score:' sat as bare
# prose in a section that is otherwise all prose, so it did not read as the field it is; '**Score:**' does.
# The KEY did not change -- only its decoration -- which is why the pattern below strips the asterisks
# rather than listing two labels: every entry in CHANGELOG.md and in every consumer's tree carries the
# plain form right now, and they meet the new parser through a plugin update rather than by choosing to.
$script:EntryScoreKey       = 'Score'
$script:EntryScoreLabel     = '**Score:**'

# ALL THREE TIERS ARE ALWAYS IN THE DOCUMENT, AND 'N/A' IS HOW A TIER SAYS IT IS NOT REACHED (Dave,
# August 7, 2026). This replaces "the sections an entry has ARE the documents it appears in": tier 1 and
# tier 2 used to be commented out and uncommenting one was the claim. They are now always present, each
# answered -- a score from the rubric, or 'N/A' with a line saying why the change reaches nobody there.
#
# WHY THE ANSWER IS BETTER THAN THE ABSENCE, which is the whole trade. An absent section and an unfinished
# one look identical, so the gate could not tell "this change reaches no consumer" from "nobody has got to
# tier 2 yet" -- and those need opposite responses. An N/A with a reason is a decision on the page; a blank
# is a question nobody answered. It also leaves the reasoning behind a NEGATIVE claim in the record, which
# the absence model threw away entirely.
#
# A 'Yes/No' FIELD WAS WEIGHED AND DROPPED the same day. Dave's own draft carried
# '**Significant to this tier as well?** Yes/No | **Score:**', and it says the reach twice: a score and a
# yes are one fact, free to contradict each other, which is the drift this file exists to prevent. The
# score alone answers it -- a number means yes, N/A means no.
$script:EntryScoreNotApplicable = 'N/A'

function Get-EntryScoreLabel {
    <# The label a WRITER puts on the score line ('**Score:**'). #>
    return $script:EntryScoreLabel
}

function Get-EntryScoreNotApplicable {
    <# The literal a tier writes when the change does not reach it ('N/A'). Machine-read by four scripts,
       so it is stated once and is deliberately NOT repo-configurable -- the same class as 'Tier' and
       'Plugins:'. A repo that translated it would make its own entries unreadable to its own fold. #>
    return $script:EntryScoreNotApplicable
}

function Get-EntryTierSectionMarker {
    <#
        The heading one tier's section is written under ('#### Tier 2').

        A HELPER RATHER THAN A THIRD HAND-BUILT STRING. The formatter that WRITES the section, the scaffold
        gate that points AT one, and the ranking-gate refusal that asks for a missing one all need the same
        heading -- and a refusal telling an author to add a heading the formatter spells differently is
        worse than no advice at all. The regex readers build their own pattern from the same two variables,
        which is as close to one source as a matcher and a writer can get.
    #>
    param([Parameter(Mandatory)][int]$Tier)
    return ('#' * $script:EntryTierSubLevel) + " $($script:EntryTierSubPrefix) $Tier"
}

function Get-EntryScorePattern {
    <#
        The regex that reads a score line, capturing the value: '**Score:** 3' and the plain 'Score: 3'
        alike, with or without a value after it.

        ONE PATTERN, BUILT FROM THE KEY, so the two decorations can never become two separately-maintained
        literals. The asterisks are optional on each side independently rather than as a pair -- a
        half-bolded '**Score:' costs the entry its ranking if it is not read, and reading it costs nothing.
    #>
    return '^\s*(?:\*\*)?' + [regex]::Escape($script:EntryScoreKey) + ':(?:\*\*)?\s*(\S*)\s*$'
}

$script:EntrySignificanceWordingDefaults = [ordered]@{
    # One question per tier, printed under that tier's score, sending the author to the next one. Written
    # as a QUESTION with both answers spelled out, because the failure it prevents is silence: an author
    # who simply stops after tier 0 has not decided that colleagues get nothing out of the change, they
    # have not been asked. Tier 2 has no successor, so it carries none.
    #
    # LINE ARRAYS, NOT SENTENCES, because these are rendered into a comment block whose width is part of the
    # form -- see Format-EntryGuidanceComment. A single long string produced one 130-column line in a file
    # whose every other comment line stops around 78, which is exactly the sort of difference that gets
    # "tidied" by hand and then reported as template drift by the lint. The break is stated here, once.
    # THE 'IF NOT' HALF NAMES AN ACTION NOW (Dave, August 7, 2026). It used to say "stop here", then
    # briefly "leave tier 1 and 2 empty" -- and that second wording contradicted the tier guidance below,
    # which asked for a reason and an N/A. One instruction per case: an unreached tier is ANSWERED, because
    # a blank cannot be told apart from an unfinished one and the gate has to tell those apart.
    # THE QUESTIONS STATE THE POST-#620 DEFINITION (inbound #640, August 13, 2026). They used to ask about
    # "colleagues and employers" (tier 1) and "customers and users" (tier 2) -- the pre-#620 ladder, which
    # inverts the answer for exactly the case the audience model is built on: a webshop's customers are
    # literally "customers and users", yet its audience is 1, because they buy a product and never read a
    # release note. One consumer answered the knob wrong from these strings before they were repaired.
    Route0 = @(
        'Is this change also relevant to management and the employer/commissioner? Then continue to Tier 1.',
        'If not, say so there in one line and put N/A in its Score.'
    )
    Route1 = @(
        'Is this change also relevant to a subscriber of the service? Then continue to Tier 2.',
        'If not, say so there in one line and put N/A in its Score.'
    )
    # The two openers of the template's commented-out tiers. Template-only prose, kept beside the questions
    # they follow rather than inside Add-TemplateTierPrompt, so a repo that translates the form translates
    # all of it from one place.
    Uncomment1 = 'UNCOMMENT Tier 1 if management and the employer/commissioner get something out of this change.'
    Uncomment2 = 'UNCOMMENT Tier 2 as well if a subscriber of the service notices it.'
}

# RECOGNISED, NEVER WRITTEN -- the one-line forms of the two questions above, as they stood for the day
# between the sub-sections shipping and the dossier form breaking them over two lines. Read-EntryTierSections
# filters them out of the Why for the reason it filters the current ones: this repo's own form text must
# never be read back as the author's reason and published as it. Deliberately not repo-configurable, like
# every other historical string here -- a repo that translated the questions translated the CURRENT ones.
$script:EntrySignificanceRetiredRoutes = @(
    'Is this change also relevant to colleagues and employers? Then continue to Tier 1. If not, stop here and move on to the next section.',
    'Is this change also relevant to the people who consume this product? Then continue to Tier 2. If not, stop here and move on to the next section.',
    # The pre-#640 first lines (retired August 13, 2026): they carried the pre-#620 audience definition.
    # Their second line is unchanged and still current, so only the questions themselves retire here.
    'Is this change also relevant to colleagues and employers? Then continue to Tier 1.',
    'Is this change also relevant to customers and users? Then continue to Tier 2.'
)

$script:EntryGuidanceDefaults = [ordered]@{
    # One block per field, written as an HTML comment ABOVE the place the answer goes. Borrowed from this
    # repo's own .github/ISSUE_TEMPLATE/inbound-improvement.md, whose fields each say what a good answer
    # looks like without occupying the line the answer is written on (Dave, August 6, 2026).
    #
    # THE VISIBLE 'TODO:' STAYS UNDERNEATH, and that is the half deliberately NOT borrowed. Replacing it
    # with a comment would make an unfinished entry render as an EMPTY section rather than as a visible
    # TODO -- the gate still catches it in the source, but the gate has a -Force, and past that point the
    # defect ships invisibly instead of obviously. Guidance goes in the comment; the prompt stays in view.
    # THE THREE BRANCH FIELDS ARE SHARED BY BOTH FILES, and that is why they live here rather than in
    # Get-BranchFileWording beside the rest of the progress file's prose. The dossier form puts the same
    # three sections at the top of branch-changelog.md AND branch-progress.md; two copies of the heading
    # and the hint is the drift shape this repo keeps paying for, and here it would be visible on every
    # branch -- two files, side by side, disagreeing about what to write in the same box.
    #
    # WRITTEN AS COMPLETE COMMENT LINES rather than as text to be wrapped in one. Format-EntryGuidanceComment
    # passes a block through untouched when it is already a comment, because these four are Dave's own
    # one-liners and their spacing is not derivable from a rule -- '<!-- Short' has a space after the marker
    # and '<!--unique' does not. The templates are the spec, so the literal is the honest representation.
    # THE HINT FOLLOWED THE SECTION'S JOB (#506, August 7, 2026). It read '<!-- Short description of
    # branch-->' while the section was called 'Branch description'; it is the PR title now, and a hint that
    # still said "description" would send the next author to write a paragraph into a field that becomes a
    # one-line title. Dave's one-liners are the spec here, so this stays one line in the same register --
    # and the templates are REGENERATED from it rather than edited beside it.
    Description = @('<!-- Short title of the change -- also the PR title, so no feat:/fix:/docs: prefix-->')
    Id          = @('<!--unique ID for branch like a timestamp of the moment this branch is created-->')
    Type        = @('<!-- options for type are: feat, fix or docs-->')
    # Translated on Dave's word (August 7, 2026): it closed in Dutch, and this line is script-generated
    # document content that travels to consumers in the plugin cache -- the one layer .claude/rules/
    # language-layers.md is explicit about. The template followed from here rather than the other way
    # round, which is the sanctioned direction: change the format, and Get-BranchTemplates regenerates it.
    PullRequest = @('<!-- link to the PR in github when branch is merged to main and the date this happened-->')
    What = @(
        'What the change DOES, for someone reading CHANGELOG.md months from now --',
        'not a report of what you did on the branch. Name what is different afterwards,',
        'and where a decision was measured rather than assumed, say what was measured.'
    )
    # 'ABOVE the Score line' IS LOAD-BEARING, NOT STYLE (inbound #596). The parser takes everything up to
    # the score as the reason and discards what follows, and the scaffold leaves one blank line on EACH side
    # of that line -- so the two places read identically and only one is read. Measured in a consumer: three
    # tiers answered, all three written underneath, all three refused, and finding out why took reading
    # entry-scaffold-lib.ps1 line by line. The gate names the misplacement now; this is the half that gets
    # said BEFORE the author writes rather than after, which is the same argument new-branch already makes
    # for printing the rubric at scaffold time.
    Tier = @(
        'Why the change matters AT THIS REACH specifically. A reason that would read the',
        'same under every tier is a sign the tier is wrong. Write it ABOVE the Score line --',
        'everything below that line is discarded. Then Score: 1-5 against the rubric',
        'new-branch printed when it wrote this file.'
    )
    # TIER 0 IS THE ONE TIER THAT IS ALWAYS REACHED -- every change matters to the people maintaining this
    # repo, if only a little -- so it is the only one with no N/A to offer. Tiers 1 and 2 get the extra
    # paragraph, which is why this is a second block rather than a longer version of the one above.
    TierOptional = @(
        'Why the change matters AT THIS REACH specifically. A reason that would read the',
        'same under every tier is a sign the tier is wrong. Write it ABOVE the Score line --',
        'everything below that line is discarded. Then Score: 1-5 against the rubric',
        'new-branch printed when it wrote this file.',
        '',
        'If it has no significance at this reach at all, then explain shortly why and insert N/A in Score.',
        'That reason goes above the Score line too.'
    )
}

function Get-EntryGuidance {
    <#
        The per-field guidance blocks, as an object of string arrays -- this repo's answers where
        scripts/repo-config.ps1 supplies them via Get-EntryGuidanceOverrides.

        A repo that wants none can return empty arrays: Format-EntryGuidanceComment renders nothing for an
        empty block, so the scaffold is exactly what it was before this existed.
    #>
    $out = [ordered]@{}
    foreach ($key in $script:EntryGuidanceDefaults.Keys) { $out[$key] = $script:EntryGuidanceDefaults[$key] }
    if (Get-Command Get-EntryGuidanceOverrides -ErrorAction SilentlyContinue) {
        $override = Get-EntryGuidanceOverrides
        if ($override) {
            foreach ($key in @($out.Keys)) {
                $v = $null
                if ($override -is [System.Collections.IDictionary]) {
                    if (-not $override.Contains($key)) { continue }
                    $v = $override[$key]
                } elseif ($override.PSObject.Properties[$key]) {
                    $v = $override.PSObject.Properties[$key].Value
                } else { continue }
                if ($null -ne $v) { $out[$key] = @($v) }
            }
        }
    }
    return [pscustomobject]$out
}

function Format-EntryGuidanceComment {
    <#
        One guidance block as HTML comment LINES, or @() when the block is empty.

        MULTI-LINE WITH THE MARKERS ON THEIR OWN LINES, deliberately: the stripper below removes whole
        lines, so a comment sharing a line with content would either survive with its content or take the
        content with it. Keeping the two apart is what makes the removal exact rather than clever.

        A BLOCK THAT IS ALREADY A COMPLETE ONE-LINE COMMENT IS PASSED THROUGH UNTOUCHED. Four of the fields
        carry Dave's own hand-written one-liners, whose spacing is not derivable from any rule -- one has a
        space after the marker and the next does not -- so wrapping them again would both double the markers
        and normalise away the exact bytes the templates are held to. Remove-EntryHtmlComments strips a
        single-line comment just as happily as a block, so nothing downstream can tell the two apart.
    #>
    param([AllowEmptyCollection()][string[]]$Lines = @())
    $body = @($Lines | Where-Object { $null -ne $_ })
    if ($body.Count -eq 0) { return @() }
    if ($body.Count -eq 1) {
        $only = ([string]$body[0]).Trim()
        if ($only.StartsWith('<!--') -and $only.EndsWith('-->')) { return @([string]$body[0]) }
    }
    $out = @('<!--')
    # An empty guidance line stays EMPTY rather than becoming five spaces: trailing whitespace is
    # invisible in an editor, survives every diff, and is the kind of thing a byte-exact template check
    # then reports as drift for a reason nobody can see.
    foreach ($line in $body) { $out += $(if ($line) { '     ' + $line } else { '' }) }
    $out += '-->'
    return $out
}

function Remove-EntryHtmlComments {
    <#
        Removes whole-line HTML comments from an entry block -- the guidance the scaffold writes above each
        field -- leaving everything else, including the line endings, exactly as it was.

        THE FOLD CALLS THIS, WHICH IS WHY THE GUIDANCE CAN BE GENEROUS. An author who replaces the TODO
        underneath and leaves the comment standing has done nothing wrong: the comment is the form, not the
        answer, and the form does not belong in CHANGELOG.md. Stripping it at the fold means nobody has to
        remember to delete it, which is the whole reason this is safe to add -- a guidance block that had to
        be tidied by hand would just be a second thing the scaffold gate has to police.

        FENCE-AWARE, for the reason every reader here is: an entry documenting this mechanism shows a
        comment inside a fence, and this very entry does.

        ONLY WHOLE-LINE COMMENTS. A comment sharing a line with prose is somebody's inline note in their own
        sentence; removing the line would take their sentence with it, and removing only the comment would
        leave a dangling fragment. Multi-line blocks are handled by tracking the open marker, so the shape
        Format-EntryGuidanceComment writes is removed entirely.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $pair = Get-EntryLineFlagPairs -EntryText $EntryText
    $parts = $pair.Parts
    $out = New-Object System.Collections.Generic.List[string]
    $inComment = $false
    $any = $false
    $n = -1
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($i % 2 -eq 1) { continue }
        $n++
        $line = $parts[$i]
        $sep = if ($i + 1 -lt $parts.Count) { $parts[$i + 1] } else { '' }
        $t = $line.Trim()

        if ($pair.Fenced[$n]) {
            $inComment = $false
        } elseif ($inComment) {
            $any = $true
            if ($t.EndsWith('-->')) { $inComment = $false }
            continue
        } elseif ($t.StartsWith('<!--')) {
            $any = $true
            # A single-line comment opens and closes on the same line; anything else opens a block.
            if (-not $t.EndsWith('-->')) { $inComment = $true }
            continue
        }
        $out.Add($line + $sep)
    }
    $t = ($out -join '')
    if (-not $any) { return $t }
    return [regex]::Replace($t, '(\r?\n)\1\1+', '$1$1')
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
        first, each with its why, its 'Score: N' line and -- for every tier except the LAST one written --
        the question routing the author to the next tier.

        LOWEST FIRST, which is the opposite of the table it replaces. The table listed the furthest reach
        at the top because that is what decided the entry's position in the changelog. These sections are
        walked by a person filling them in, and that walk starts at tier 0: it is the one every change can
        answer, and each answer decides whether there is a next one. Ordering the document against the
        order it is written in would put the routing questions in reverse.

        Called with no rows it renders the SCAFFOLD: the tiers Get-EntryAskedTiers names -- tier 0 plus this
        repo's one audience tier, or every tier the model has where no audience is stated -- each with its
        guidance comment standing where the why goes and its score EMPTY. Tier 0 is the honest default claim
        -- reaches nobody outside this repo
        -- while a scaffolded SCORE would be a guess at a ranking, which is the failure the retired
        remove-before-publishing marker was measured on.

        THE VISIBLE 'TODO:' UNDER THE GUIDANCE IS GONE (Dave, August 6, 2026), which reverses the rule this
        format carried the day before -- "guidance in the comment, the prompt stays in view". It went because
        the dossier form removed every other visible placeholder with it, and one lone TODO in a file of
        comment blocks reads as leftover rather than as a prompt. What replaces it as the gate is not a
        string but a MEASUREMENT: Get-EntryScaffoldFindings now reports a section that is still EMPTY once
        the comments are stripped, which catches the untouched entry the placeholder used to catch AND the
        one whose placeholder was deleted rather than answered. Strictly more, and nothing to keep in sync.

        One formatter for the writer and any migration, so the parser below can never meet a shape nothing
        here produced.
    #>
    param(
        $Rows = @(),
        [switch]$WithGuidance
    )
    $w = Get-EntrySignificanceWording
    # EVERY TIER THIS REPO ASKS ABOUT IS WRITTEN, AND EACH IS ANSWERED (Dave, August 7, 2026; narrowed to
    # one audience tier on August 12, 2026). The scaffold once emitted tier 0 alone with 1 and 2 offered as a
    # commented-out block; then all three as real sections; now tier 0 plus the ONE audience tier this repo
    # has, because tier 1 and tier 2 are two kinds of reader rather than two rungs. Get-EntryAskedTiers is
    # the single answer to "which ones", and where a repo has stated no audience it returns all of them --
    # so an unconfigured consumer gets exactly the file it got yesterday.
    #
    # A caller passing rows (a migration, a rewrite) gets exactly its own rows back, so nothing invents a
    # tier for an entry written under an older model and nothing DROPS one either: an entry that answered
    # all three keeps all three, which is what makes 97 existing entries re-renderable.
    $ordered = @(@($Rows) | Sort-Object -Property @{Expression = { [int]$_.Tier }; Descending = $false})
    if ($ordered.Count -eq 0) {
        $ordered = @(Get-EntryAskedTiers | ForEach-Object {
            [pscustomobject]@{ Tier = $_; Score = 0; Why = '' }
        })
    }

    # THE ROUTING QUESTIONS GO WITH THE GUIDANCE (Dave, August 7, 2026), which is the half of this worth
    # stating out loud, because it reverses his own decision of the day before. They were added so an author
    # who stops at tier 0 has DECIDED there is nothing above it rather than never having been asked -- and
    # they are comments, so the working file is where they did that work. Taking them out means the ladder
    # is now something you learn from branch/templates/ or from CONTRIBUTING.md rather than from the file in
    # front of you. He was shown both shapes side by side and chose this one; recorded here so the next
    # reader meets the trade rather than only the result.
    #
    # KEYED ON WHAT IS ACTUALLY WRITTEN, NOT ON A FIXED PAIR, and that had to change with the audience knob
    # (August 12, 2026). It used to be the literal @{ 0 = Route0; 1 = Route1 }, which in a tier-2 repo would
    # print "continue to Tier 1" above a file whose next section is Tier 2 -- form text sending the author to
    # a heading that is not there. Each written tier except the LAST gets the question that routes to its
    # successor, and the wording key follows the TARGET: Route0's own text says "continue to Tier 1" and
    # Route1's says "continue to Tier 2", so the question routing to tier T is Route<T-1>. The names stay as
    # they are for that reason -- they are a consumer-overridable seam, and every repo that has translated
    # one translated it by these keys.
    $routes = @{}
    if ($WithGuidance) {
        for ($r = 0; $r -lt $ordered.Count - 1; $r++) {
            $target = [int]$ordered[$r + 1].Tier
            $key = "Route$($target - 1)"
            if ($w.PSObject.Properties[$key] -and $w.$key) { $routes[[int]$ordered[$r].Tier] = $w.$key }
        }
    }

    $lines = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $ordered.Count; $i++) {
        $row  = $ordered[$i]
        $tier = [int]$row.Tier
        if ($i -gt 0) { $lines.Add('') }
        $lines.Add((Get-EntryTierSectionMarker -Tier $tier))
        $lines.Add('')
        # THE GUIDANCE COMMENT STANDS WHERE THE WHY GOES on an unanswered section, and nothing else does --
        # no placeholder line underneath it. A row that already carries a why is a migration or a rewrite of
        # a finished entry, and prefixing somebody's written answer with a form instruction would be noise
        # in exactly the document they just finished, so there the comment is what goes.
        $answered = [bool]($row.PSObject.Properties['Why'] -and $row.Why)
        if ($answered) {
            foreach ($line in ([string]$row.Why -split '\r?\n')) { $lines.Add($line) }
            $lines.Add('')
        } elseif ($WithGuidance) {
            # Tier 0 cannot be N/A -- see $script:EntryGuidanceDefaults.TierOptional -- so it gets the
            # block without that paragraph, and every tier above it gets the one that offers the way out.
            $g = Get-EntryGuidance
            $block = if ($tier -eq 0) { @($g.Tier) } else { @($g.TierOptional) }
            foreach ($line in (Format-EntryGuidanceComment -Lines $block)) { $lines.Add($line) }
            if ($block.Count -gt 0) { $lines.Add('') }
        }
        # An unanswered section in a WORKING file is the heading, one blank line, and the score label -- the
        # blank is where the reason goes. Not two blanks: the guidance used to occupy that space, and leaving
        # its surrounding whitespace behind is the shape that reads as "something was deleted here".
        # THREE THINGS THIS LINE CAN SAY, matching what the parser reads back: a number, 'N/A' for a tier
        # the change reaches nobody at, or nothing at all -- a question left standing rather than a number
        # nobody chose. Get-EntryImpactFindings is what refuses the third before the PR.
        $score = ''
        if ($row.PSObject.Properties['NotApplicable'] -and $row.NotApplicable) {
            $score = ' ' + $script:EntryScoreNotApplicable
        } elseif ($row.PSObject.Properties['Score'] -and [int]$row.Score -gt 0) {
            $score = ' ' + [string][int]$row.Score
        }
        $lines.Add($script:EntryScoreLabel + $score)
        # EVERY SECTION THAT HAS A SUCCESSOR CLOSES WITH IT, including one whose successor is already
        # answered below it (Dave: "het kopje sluit altijd af met"). An earlier draft wrote it only under the
        # last section, on the grounds that a tier whose successor exists has already been answered. That is
        # true of the author and false of the reader: the entry is walked again at the fold, at the cut and
        # in the record, and a question that disappears once answered leaves the next reader unable to see
        # that it WAS asked. The LAST written tier has no successor and therefore carries none -- which used
        # to be a statement about tier 2 specifically, and is now about whichever audience tier this repo
        # asked for.
        #
        # AS AN HTML COMMENT (Dave, August 6, 2026). It is form text, not the author's answer, and it was
        # the last piece of form that travelled all the way into CHANGELOG.md and the development notes.
        # The fold strips comments, so the writer still sees it and the record never does.
        if ($routes.ContainsKey($tier)) {
            $lines.Add('')
            foreach ($line in (Format-EntryGuidanceComment -Lines @($routes[$tier]))) { $lines.Add($line) }
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
    # BAND 1 ASKS WHAT IS PREVENTED (Dave, #509, August 7, 2026). It read 'cosmetic or preventative --
    # nothing changes for them today', and the second half invited the sentence the rubric exists to
    # prevent: PR #503's entry scored its tier 0 with "Nothing changes here" -- technically inside the band,
    # and worth nothing to a reader a year later. A preventative change is the one case where the value is
    # ENTIRELY in what did not happen, so that is the one thing the band has to ask for. The other four
    # bands describe something the reader can observe; this one describes an absence, and an absence has to
    # be named or it is indistinguishable from having nothing to say.
    #
    # THE OBVIOUS ALTERNATIVE WAS REJECTED, and it is worth knowing why before anyone builds it. Dave asked
    # whether tier 0 scoring below tier 1 should be refused at all -- if nothing changes for this repo's own
    # developers, how can it change for anyone further out? The general claim does not hold, and PR #503 is
    # the counterexample: the defect existed ONLY outside this repo (consumers had no branch/templates/;
    # this repo always did), so it was worth 4 to a consumer and almost nothing here. The tiers are not
    # nested audiences -- a consumer is not a colleague of this project. That gate would have refused a
    # correct entry. The instinct behind it IS already encoded, correctly, one level down: tier 0 is the one
    # tier that cannot be N/A, because every change reaches this repo's own developers at least a little.
    # The floor is a score of 1, not nothing -- and band 1 now asks what that 1 buys.
    [pscustomobject]@{ Score = 1; Test = 'cosmetic, or prevents a failure that has not happened yet -- then name the failure, because that is the only part a later reader can use' }
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

function Get-EntryTierReasonText {
    <#
        Private: the author's own reason out of a tier section's raw lines -- this format's guidance
        comments and its retired routing questions removed, whatever survives trimmed.

        THE GUIDANCE AND THE ROUTING QUESTION ARE THIS FORMAT'S OWN PROSE, not the author's answer, so
        neither may become the Why -- it would otherwise be published as the reason the change matters.

        BOTH FORMS ARE FILTERED. They are HTML comments since August 6, 2026 (stripped here by the shared
        remover), and they were bare prose before that -- so an entry written on either side of that change
        reads back the same. Same "recognise both" rule the three declaration shapes get.

        AND BOTH LINE-BREAKINGS OF THEM. The questions became two-line arrays when the dossier form fixed
        the comment width, so the one-line sentences they replaced no longer appear in the wording at all --
        and an entry carrying one as bare prose would have had this repo's own form text read back as the
        author's reason and published as it. @() flattens the arrays into individual lines, which is exactly
        the granularity the comparison needs.

        ONE HELPER FOR BOTH SIDES OF THE SCORE LINE, and that is why it exists rather than staying inline
        (inbound #596). Read-EntryTierSections collects the lines above '**Score:**' into Why and the lines
        below it into WhyBelowScore, and both need exactly the filtering above: a guidance comment sitting
        below the score would otherwise read back as a misplaced reason, and the gate would accuse an entry
        nobody had written in yet of having put its answer in the wrong place -- on every consumer, from
        their first branch. Two copies of the filter is how that divergence starts.
    #>
    param([AllowEmptyString()][AllowEmptyCollection()][string[]]$Lines = @())

    $w = Get-EntrySignificanceWording
    $routes = @(@($w.Route0) + @($w.Route1) + @($script:EntrySignificanceRetiredRoutes)) |
        Where-Object { $_ }
    $text = Remove-EntryHtmlComments -EntryText (@($Lines) -join "`n")
    return (@(($text -split '\r?\n') | Where-Object {
        $t = $_.Trim()
        if (-not $t) { return $false }
        foreach ($r in $routes) { if ($t -eq ([string]$r).Trim()) { return $false } }
        return $true
    }) -join "`n").Trim()
}

function Read-EntryTierSections {
    <#
        Private: the '#### Tier N' sub-sections in an already-defenced, already-split entry. Returns an
        object with Rows (the shape the table produces -- Tier, Score, Why, Raw, Error -- plus
        NotApplicable and WhyBelowScore, which only the section shape can carry) and Errors.
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
    $scoreRx = Get-EntryScorePattern
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
        # TWO LISTS, BECAUSE THE SCORE LINE SPLITS THE SECTION AND ONLY ONE SIDE IS THE REASON. The lines
        # below '**Score:**' were read and discarded until inbound #596: the loop runs to the next heading
        # either way, so the text was already in hand at the point the gate said there was none. Keeping it
        # is what lets the refusal tell "you wrote nothing" apart from "you wrote it one line too low" --
        # the second is the easy mistake, because the scaffold leaves a single blank line on BOTH sides of
        # the score and nothing says which one is read.
        $whyLines = New-Object System.Collections.Generic.List[string]
        $belowScoreLines = New-Object System.Collections.Generic.List[string]
        $scoreCell = $null
        while ($i -lt $Lines.Count) {
            $line = $Lines[$i]
            if ($line -match ('^\s*#{1,' + $script:EntryTierSubLevel + '}\s')) { break }
            if ($null -eq $scoreCell -and $line -match $scoreRx) { $scoreCell = $Matches[1] }
            elseif ($null -eq $scoreCell) { $whyLines.Add($line) }
            else { $belowScoreLines.Add($line) }
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

        # THREE STATES, NOT TWO. A tier is scored (a number), declared unreached ('N/A'), or unanswered
        # (nothing) -- and the last two must not collapse into one, because a blank is a question nobody
        # answered while an N/A is a decision somebody made. NotApplicable carries that apart; Score stays 0
        # for both so every existing caller that only reads the number keeps its fail-safe behaviour.
        $score = 0
        $notApplicable = $false
        if ($scoreCell -and $scoreCell -ne $script:EntryImpactEmptyCell) {
            if ($scoreCell -eq $script:EntryScoreNotApplicable) {
                $notApplicable = $true
            } elseif ($scoreCell -notmatch '^\d+$') {
                $errs += "'$($script:EntryScoreLabel) $scoreCell' under tier $tier is neither a number nor '$($script:EntryScoreNotApplicable)' -- write $($range.Min) to $($range.Max), or '$($script:EntryScoreNotApplicable)' with a line saying why the change reaches nobody there."
            } elseif ([int]$scoreCell -lt $range.Min -or [int]$scoreCell -gt $range.Max) {
                $errs += "'$($script:EntryScoreLabel) $scoreCell' under tier $tier is outside the rubric -- write $($range.Min) to $($range.Max)."
            } else {
                $score = [int]$scoreCell
            }
        }

        # What the filtering itself is for, and why it is a shared helper, is written at
        # Get-EntryTierReasonText -- the reasoning moved there with the code, so whoever edits it next
        # reads it rather than finding it at a call site.
        $why = Get-EntryTierReasonText -Lines @($whyLines)

        # WhyBelowScore is diagnosis, never content. Nothing publishes it and nothing counts it as an
        # answer -- the gates read it only to name the actual defect, and the reason still has to move
        # above the score line before the entry passes. Additive, so every existing reader keeps taking
        # the properties it already names; the legacy table path below sets no such property at all,
        # which is why both gates ask whether it is there before reading it.
        $whyBelowScore = Get-EntryTierReasonText -Lines @($belowScoreLines)

        $rows.Add([pscustomobject]@{
            Tier          = $tier
            Score         = $score
            NotApplicable = $notApplicable
            Why           = $why
            WhyBelowScore = $whyBelowScore
            Raw           = $raw
            Error         = $null
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
                    From the section shape only, two more: NotApplicable, and WhyBelowScore -- text found
                    UNDER the score line, which is a misplaced reason rather than an answer. A caller that
                    reads either must ask whether the property is there: the table and 'Tier: N' shapes
                    cannot produce them.
          Tier      the highest tier any row declares -- the entry's reach, and the same number the old
                    'Tier: N' line carried. 0 when nothing usable is declared, so a caller that ignores
                    Error still fails safe towards the harmless end rather than crashing.
          Declared  $true when the reach was actually stated (a table with rows, or a 'Tier:' line).
          Errors    every row-level complaint, ready to print; empty when the table parses.
          Shape     WHICH of the three shapes was read: 'sections', 'table', 'line', or 'none' when the
                    entry declares no impact at all. Table stays $true for the first two, because every
                    existing caller asks it "is there a declaration" rather than "which one".

        WHY THE SHAPE IS RECORDED AND NOT MERELY DETECTED. A gate that reads three shapes has to give
        advice in ONE of them, and until this property existed it could not tell which one it was looking
        at: Get-EntryImpactFindings asked a section-shaped entry to "fill in the third column" of a table
        that this very shape replaced. WhyBelowScore was the nearest thing to a discriminator and does not
        reach far enough -- it lives on a ROW, so the one refusal that fires when a tier has no row at all
        had nothing to read. The property is additive, so nothing that already ignores it changes.

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
        Shape    = 'none'
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
        $result.Shape = 'sections'
        $result.Rows = @($sections.Rows)
        $result.Errors = @($sections.Errors)
        $declared = @($sections.Rows | Where-Object { $null -eq $_.Error })
        if ($declared.Count -gt 0) {
            $result.Declared = $true
            # THE REACH IS THE HIGHEST TIER THAT IS ACTUALLY SCORED (Dave, August 7, 2026). It used to be
            # the highest tier with a SECTION, which was right while tier 1 and 2 were commented out and
            # uncommenting one was the claim. All three sections are always present now, so their presence
            # says nothing -- an 'N/A' row is a tier explicitly declaring it reaches nobody, and counting it
            # would file every entry as tier 2 and publish repo-internal work to consumers.
            #
            # An UNANSWERED row (no score, no N/A) does not count either, and that is the fail-safe
            # direction: forgetting to answer under-promotes, which Get-EntryImpactFindings then reports by
            # name, while the reverse would be silent and would reach people outside this repo.
            $reaching = @($declared | Where-Object { -not $_.NotApplicable -and [int]$_.Score -gt 0 })
            if ($reaching.Count -gt 0) {
                $result.Tier = (@($reaching | ForEach-Object { [int]$_.Tier }) | Measure-Object -Maximum).Maximum
            }
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
        # 'line' only where a 'Tier: N' line was actually found -- an entry with no declaration of any kind
        # keeps 'none', so a caller can tell "wrote it the old way" from "wrote nothing".
        if ($legacy.Declared) { $result.Shape = 'line' }
        if ($legacy.Error) { $result.Errors = @($legacy.Error) }
        return $result
    }

    $result.Table = $true
    $result.Shape = 'table'
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

        THE LADDER IS CHECKED AS A LADDER. An entry claiming tier 2 appears in the consumer document AND in the
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

    # EVERY REFUSAL BELOW IS WORDED IN THE SHAPE THE ENTRY ACTUALLY USES (inbound: the gate telling a
    # section-shaped entry to "fill in the third column"). Three shapes are read and one is written, so
    # advice given in the wrong one sends an author looking for a table that this format replaced -- and
    # the author is the one person who cannot check the claim, because the file in front of them has no
    # columns to count.
    #
    # THE TEST IS "IS IT A TABLE", NOT "IS IT THE CURRENT SHAPE", and that asymmetry is deliberate. A real
    # table HAS the columns, so its own wording is the accurate one and keeps it -- "recognise both, write
    # one" applies to the advice as much as to the parsing. The 'Tier: N' line and an entry with no
    # declaration at all get the SECTION wording instead of a third variant: neither has anywhere to put a
    # score, so the only move that resolves the refusal is to write the shape this format writes.
    $isTable = ($impact.Shape -eq 'table')

    # THE TIERS AN ENTRY OWES ARE THE ONES THIS REPO ASKS ABOUT (August 12, 2026), and no longer every rung
    # from 1 up to the reach. Where a repo has named its one audience tier, that is the only one owed; where
    # it has named none, Get-EntryAskedTiers returns all of them and this is 1..$impact.Tier exactly as it
    # was. Tier 0 is excluded here for the reason stated above -- it is never ranked -- and its reason is
    # still required, by Get-EntryScaffoldFindings, which walks the rows rather than the ladder.
    #
    # TOLERANT IN THE ONE DIRECTION THAT MATTERS: a tier this repo does not ask about but the author
    # answered anyway is simply not examined here. That is not laxity, it is the only behaviour that does not
    # turn correct work into a blockage -- the 6 entries pending in this repo when the knob landed each
    # carried all three tiers, written under the cumulative model, and a gate that started refusing an EXTRA
    # answered tier would have converted six finished dossiers into six PRs that cannot be opened. Their
    # reasons are still checked; only the completeness ladder narrowed.
    foreach ($tier in @(Get-EntryAskedTiers | Where-Object { $_ -ge 1 -and $_ -le $impact.Tier })) {
        $row = @(@($impact.Rows) | Where-Object { [int]$_.Tier -eq $tier })
        # THE LADDER CANNOT BE SKIPPED, and 'N/A' is the new way to try (August 7, 2026). A tier declaring
        # it reaches nobody, UNDER one that is scored, says a change consumers notice gives this project's
        # colleagues nothing -- which is the half-claim the cumulative ladder exists to rule out. Reported
        # as its own finding rather than as "no significance", because the author did answer: they answered
        # something that cannot be true alongside the tier above it.
        if ($row.Count -gt 0 -and $row[0].NotApplicable) {
            $findings += "tier $tier says '$(Get-EntryScoreNotApplicable)' while tier $($impact.Tier) is scored -- the ladder is cumulative, so a change that reaches tier $($impact.Tier) reaches tier $tier too. Score it, or drop the claim at tier $($impact.Tier)."
            continue
        }
        if ($row.Count -eq 0) {
            # $($impact.Tier), not "$impact.Tier": the second interpolates the OBJECT and then appends the
            # literal '.Tier', so the message read "reaches tier @{Table=True; Rows=System.Object[]...}".
            # Caught by this file's own smoke test; it is the one PowerShell interpolation trap that
            # produces valid output nobody would ever write on purpose.
            $add = if ($isTable) {
                "add a '| $tier | <$($range.Min)-$($range.Max)> | <why> |' row"
            } else {
                "add a '$(Get-EntryTierSectionMarker -Tier $tier)' section with its reason and a '$($script:EntryScoreLabel) <$($range.Min)-$($range.Max)>' line"
            }
            $findings += "this entry reaches tier $($impact.Tier), so it also reaches tier $tier -- $add. The ladder is cumulative: a change consumers notice is also a change this project's colleagues get something out of."
            continue
        }
        if ([int]$row[0].Score -le 0) {
            $where = if ($isTable) { "in that row's second column" } else { "on that tier's $($script:EntryScoreLabel) line" }
            $findings += "tier $tier has no significance -- write a whole number from $($range.Min) to $($range.Max) against the rubric $where."
            continue
        }
        if (-not $row[0].Why) {
            # THE SAME MISDIAGNOSIS LIVES HERE, and this gate is the one that refuses a RELEASE. #596 was
            # reported against the scaffold gate, but the emptiness is read from the same row, so a reason
            # written below its score reaches the cut with the same unactionable wording -- days later,
            # when whoever wrote it is no longer the one reading the refusal.
            $below = if ($row[0].PSObject.Properties['WhyBelowScore']) { [string]$row[0].WhyBelowScore } else { '' }
            if ($below) {
                $findings += "tier $tier scores $($row[0].Score) and its reason sits BELOW the $($script:EntryScoreLabel) line, where nothing reads it -- move the text above that line. Everything up to the score is the reason; everything after it is discarded."
            } else {
                $fill = if ($isTable) { 'fill in the third column' } else { "write it above that tier's $($script:EntryScoreLabel) line" }
                $findings += "tier $tier scores $($row[0].Score) with no 'Why' -- $fill. The rubric says which band; the why says why THIS change is in it, and that is the half a later reader can check."
            }
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

        THE DOCUMENTS THAT TRAVEL OUTWARD STRIP IT: the consumer document, the per-plugin CHANGELOGs and the
        release cards. A self-assigned number printed at a consumer is a marketing claim, and this repo has
        measured what a published guess costs -- the retired remove-before-publishing marker is in release-lib's history
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
        each release card, 17 in the per-plugin CHANGELOG and 16 in the consumer draft, in exactly the
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
    #
    # THIS SECTION'S RETIRED NAMES, NOT EVERY SECTION'S (August 7, 2026). It read the flattened list, which
    # answers "is this a heading we know" -- a different question from "does this heading open the
    # significance block". While every retired name happened to belong to a section no other document
    # carried, the two questions gave the same answer and the shortcut was invisible. Renaming
    # 'Branch description' to 'Branch title' broke that coincidence: this remover would have accepted an
    # entry's empty TITLE heading as the significance block's and deleted it. Ask the section, not the set.
    $headings = @((Get-EntrySectionHeadings)['Significance']) + @(Get-EntrySectionRetiredNames -Key 'Significance') |
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
        per-plugin CHANGELOG and 16 in the consumer draft, in exactly the documents that travel to a
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

# THE SECTIONS THAT ARE ADMINISTRATION RATHER THAN CONTENT, for a reader who has no branch. Four of the
# six: the title (which IS the heading by the time a renderer gets here), the creation timestamp, the
# prefix, and the PR link. 'What' is the substance and 'Significance' has its own remover above -- a
# self-assigned score is a different objection from branch administration, and collapsing the two would
# make one switch answer two questions.
$script:EntryAdminSectionKeys = @('Description', 'Id', 'Type', 'PullRequest')

function Get-EntryAdminSectionKeys {
    <# The section keys a document written for someone outside this repo drops. Stated once so the remover
       and its suite cannot disagree about which four, and so adding a seventh section forces a decision
       here rather than silently defaulting to "publish it". #>
    return @($script:EntryAdminSectionKeys)
}

function Remove-EntryAdminSections {
    <#
        Removes the branch-administration sections -- heading and body -- from an entry block, leaving the
        substance and the entry's own heading standing.

        WHY THIS EXISTS AT ALL, because the stripping it completes was never absent: it was aimed one level
        up. Convert-EntryHeadingToTitle drops the PR number, the type and the date from an entry's HEADING,
        which is where all three lived until August 6, 2026. The branch dossier then moved that metadata into
        named '###' sections, and nothing followed it down. So the heading rewrite kept working perfectly and
        the same facts arrived one line lower: measured on the v4.2.0 consumer draft, 133 of 396 lines -- 34%
        -- were these four sections, with 'Branch title' printed directly beneath the heading it had just
        become. Duplicated, in the one document written for someone who is paying for the product.

        The intent was never in doubt, which is what makes this a defect rather than a change of mind:
        Convert-EntryHeadingToTitle's own header says this document's reader "has no PR numbers", and the
        draft shipped seven.

        RETIRED NAMES ARE REMOVED TOO, and here that matters more than it does for a reader. A reader that
        misses an old name returns nothing and the caller usually notices; a REMOVER that misses one leaves
        the section standing in the document that travels outward -- silent, and in front of the wrong
        audience. CHANGELOG.md and every consumer's tree are full of 'Type of change' and
        'Branch description' right now. Recognise both, write one.

        Fence-aware through the shared reader, and this function needs it more than most: the entry that
        introduces it quotes these very headings inside a fence to show what is dropped. Same inherited
        assumption as Remove-EntryTierSections about a fence INSIDE a dropped section -- none of these four
        sections holds one by construction (a title, a timestamp, one word, a link).
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $headings = Get-EntrySectionHeadings
    $names = @()
    foreach ($key in (Get-EntryAdminSectionKeys)) {
        $names += @($headings[$key]) + @(Get-EntrySectionRetiredNames -Key $key)
    }
    $names = @($names | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
    if ($names.Count -eq 0) { return $EntryText }

    $hashes = '#' * $script:EntrySectionLevel
    $headRx = '^\s*' + $hashes + '\s+(' + ((@($names | ForEach-Object { [regex]::Escape($_) })) -join '|') + ')\s*$'
    # Any heading at this level or shallower closes the section: the next '###', or the next entry.
    $closeRx = '^\s*#{1,' + $script:EntrySectionLevel + '}\s'

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
            $inSection = $false
        } else {
            if ($line -match $headRx) { $inSection = $true; $any = $true; continue }
            if ($inSection) {
                if ($line -match $closeRx) { $inSection = $false }
                else { continue }
            }
        }
        $out.Add($line + $sep)
    }
    $t = ($out -join '')
    if (-not $any) { return $t }
    return [regex]::Replace($t, '(\r?\n)\1\1+', '$1$1')
}

function Get-ImpactInsertOffset {
    <#
        Pure: where in a changelog tier SECTION a new entry with $Score belongs -- a character offset into
        $SectionText, always at an entry boundary ('### ' at line start) or at its very end.

        THE FOLD IS WHAT KEEPS CHANGELOG.md ORDERED, and it has to be, because the cut EMPTIES the tier
        sections. There is no later moment at which the pending list could be sorted: the release documents
        read the section in document order, so whatever order the fold leaves behind IS the order the notes
        and the consumer document inherits. That is also what makes the ordering reproducible across the two moments
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
# THE ENTRY IS THE BRANCH'S OWN DOSSIER, AND IT FOLDS INTO CHANGELOG.md AS IT STANDS (Dave, August 6,
# 2026). The file used to be the changelog block and nothing else: its H2 was the change's title, and three
# sections answered what it does, what it weighs and what type it is. It now opens with the BRANCH -- '##
# `feat/x` changelog' -- and carries the branch's own identity above the description, because the two files
# a branch works in are a matched pair and both say whose they are.
#
# THE SIX SECTIONS, IN THE ORDER THEY ARE WRITTEN:
#
#   Branch title         the human-readable name of the change -- what the heading used to carry
#   Branch ID            a unique stamp, written by the scaffolder at creation
#   Branch type          feat / fix / docs / chore, from the branch prefix
#   What does the ...    the description a reader of CHANGELOG.md arrives for
#   Significance         one '#### Tier N' sub-section per reach the change claims
#   Pull Request         filled by the fold, from the merge itself
#
# DAVE CHOSE THE VERBATIM ROUTE over having the fold derive a slimmer block from this one (August 6, 2026,
# asked and answered before any of it was built). So CHANGELOG.md receives exactly this shape, branch line
# and all, and the release documents inherit it. The alternative -- a fold that reads the dossier and emits
# a different document -- was declined: it would put a SECOND definition of the entry format inside the
# fold, which is the drift shape this repo has paid for in the fence readers, the scaffold wording and the
# tier sections. One shape, written once, read everywhere.
#
# THE ORDER IS LOAD-BEARING, not presentation. The lint's split-entry rule asks whether a block's FIRST
# named section is the first of these, which is how a stray heading at the entry's own level is caught --
# so a reordering here changes what that gate means. Get-EntryFirstSectionKey states it once.
# AND IT IS 'Branch title', NOT 'Branch description', SINCE AUGUST 7, 2026 (Dave, #506). The field is what
# the change is CALLED -- in this file, in CHANGELOG.md, in the release documents, and since the same day in
# the PR title, which open-pr.ps1 now composes from it rather than taking on the command line. "Description"
# undersold that, and it read as a synonym of the 'What does the change...' section two rows below it, which
# genuinely is the description. The KEY stays 'Description': it is machine-read, every caller names it, and
# renaming a key to match a heading is how a rename stops being cosmetic.
$script:EntrySectionDefaults = [ordered]@{
    Description  = 'Branch title'
    Id           = 'Branch ID'
    Type         = 'Branch type'
    What         = 'What does the change on this branch bring to main?'
    Significance = 'Significance'
    PullRequest  = 'Pull Request'
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
# KEYED BY SECTION, NOT A FLAT LIST, since the branch dossier renamed two more of them (August 6, 2026).
# A flat list answers "is this heading one we know", which is all the lint needs; a READER needs to know
# WHICH section an old name is the old name OF, or Get-EntrySectionBody -Key 'Type' finds nothing in the
# hundreds of entries that say 'Type of change'. Both questions are answered from this one map, so a name
# retired for one reader cannot be forgotten by the other.
$script:EntryRetiredSectionNames = [ordered]@{
    Description  = @('Branch description')
    What         = @('What does this change do?')
    Significance = @('Who is this for')
    Type         = @('Type of change')
}

function Get-EntrySectionRetiredNames {
    <# The retired headings of ONE section, oldest names included -- @() where that section never had one. #>
    param([Parameter(Mandatory)][string]$Key)
    if ($script:EntryRetiredSectionNames.Contains($Key)) { return @($script:EntryRetiredSectionNames[$Key]) }
    return @()
}

function Get-EntryRetiredSectionHeadings {
    <# Section headings that were once written and are still recognised, flattened across every section. A
       name-matcher accepts these alongside Get-EntrySectionHeadings' values; a WRITER must never use them. #>
    $out = @()
    foreach ($key in $script:EntryRetiredSectionNames.Keys) { $out += @($script:EntryRetiredSectionNames[$key]) }
    return @($out)
}

function Get-EntryFirstSectionKey {
    <# The key of the section an entry must OPEN with ('Description'). Stated once because the lint's
       split-entry rule keys on it: a block whose first named section is not this one has been cut in two by
       a stray heading at the entry's own level. Read off the order of the map rather than written out, so
       reordering the sections cannot leave that gate testing the wrong one. #>
    return @($script:EntrySectionDefaults.Keys)[0]
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

# --- MOVED DOWN FROM release-lib.ps1: the entry-boundary readers ----------------------------------
#
# Get-EntryHeadingPattern and Split-EntryBlocks used to live in release-lib.ps1. They moved here on
# August 10, 2026 for the SAME reason Get-FencedLineFlags did, and that reason is a dependency
# direction rather than a preference: the fold and this file's own suite load this lib STANDALONE,
# while nothing loads release-lib without it. So an answer both the cut and the fold need can only
# live down here. release-lib calls both by exactly these names and is unchanged -- it dot-sources
# this file unconditionally, at the top.
#
# WHAT MADE THE MOVE NECESSARY rather than tidy: Get-PreFlatChangelogRefusal below is that shared
# answer (inbound #561), and it cannot be written without a splitter. Leaving the splitter up in
# release-lib would have meant either the fold loading three thousand lines of release machinery
# immediately after a merge and directly on the trunk -- which its own header rejects, by name -- or a
# second boundary rule written beside the first, free to disagree with it about where the intro ends.
#
# The names deliberately did not gain an 'Entry' prefix on the way down: these readers scan a whole
# CHANGELOG rather than one entry, so a name claiming otherwise would be wrong at every call site --
# and keeping them meant the move changed no call site in either lib.

function Get-EntryHeadingPattern {
    <#
        The anchored regex that matches an entry's OWN heading and nothing else -- '^##\s' while the entry
        level is 2. Built from Get-EntryHeadingLevel so the parser, the splitter and the re-leveller cannot
        end up looking for different things.

        THE EXACT LEVEL, NOT A RANGE, and that is the one decision in this whole file that cannot be
        loosened. An entry carries H3 sections of its own ('### What does this change do?'), so a pattern
        accepting H3 as well would read every entry as four. It is safe as an exact match for the mirror
        image of the same reason: '^##' followed by '\s' cannot match '### ', because the third character
        is a '#'.
    #>
    return '^#{' + (Get-EntryHeadingLevel) + '}\s'
}

function Split-EntryBlocks {
    <#
        Turns a run of lines into entry blocks. A new block starts at every entry heading
        (Get-EntryHeadingPattern); '---' separators between entries are skipped.

        BOTH of those tests must ignore FENCED CODE BLOCKS. An entry body may legitimately quote markdown
        -- a broken heading structure, a YAML frontmatter example -- and without fence awareness the
        parser reads that quoted text as structure. Measured while cutting v2.13.3: an entry that quoted
        a '### #242 ...' line inside a ``` fence produced a THIRD entry from two PRs, split the fence
        open, and duplicated '## Fixes' in the generated notes. Caught by -NoPush before it shipped.
        Fourth instance of the same defect class in one day (#227, #235, and the teardown's VUL-IN test):
        a matcher satisfied by a MENTION rather than a use.

        Its own function since the changelog gained one section per tier, and kept now that the sections
        are gone: the entry-boundary rule and the fence handling are one answer and belong in one place.
        No longer private -- Get-PreFlatChangelogRefusal below and release-lib's Split-Changelog are both
        callers, which is what brought it down here.
    #>
    param(
        [AllowEmptyCollection()][string[]]$Lines = @(),
        [Parameter(Mandatory)][string]$Nl
    )
    $headingRx = Get-EntryHeadingPattern
    $fenced = Get-FencedLineFlags -Lines $Lines
    $entries = @()
    $cur = $null
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $ln = $Lines[$i]
        if ((-not $fenced[$i]) -and $ln -match $headingRx) {
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

function Get-ChangelogEntryBlocks {
    <#
        Every entry block in a CHANGELOG.md, in document order -- the intro above the first entry heading
        dropped. An empty array when the document holds no entry at all, which is a legitimate state here
        rather than a failure: a repo whose pending list is empty has an intro and nothing else, and the
        first fold after a release lands in exactly that document.

        THE BOUNDARY IS DERIVED, NOT CONFIGURED, and it is fence-aware for the reason every reader in this
        file is: this repo's own changelog intro QUOTES an entry heading inside a fence to document the
        format, so a boundary walk blind to fences puts the intro/list split in the middle of a code block.

        Split out of release-lib's Split-Changelog so the fold can ask the same question without loading
        release-lib. That function keeps its own richer answer (the newline style and the intro text, which
        only the cut needs) and now shares this one's boundary rule instead of restating it.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Content)

    $nl = if ($Content.Contains("`r`n")) { "`r`n" } else { "`n" }
    $lines = @($Content -split "`r?`n")
    $headingRx = Get-EntryHeadingPattern
    $fenced = Get-FencedLineFlags -Lines $lines
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ((-not $fenced[$i]) -and $lines[$i] -match $headingRx) {
            return @(Split-EntryBlocks -Lines @($lines[$i..($lines.Count - 1)]) -Nl $nl)
        }
    }
    return @()
}

function Get-PreFlatChangelogRefusal {
    <#
        The refusal a script owes a consumer whose CHANGELOG.md still carries the PRE-FLAT shape, or '' when
        the document is fine. Pure: text in, text out, nothing written and nothing thrown -- the caller
        decides whether to throw it, print it, or exit on it.

        WHY IT IS SHARED, AND IT IS A MEASURED CONSUMER DEFECT (inbound #561, August 10, 2026). Two scripts
        make the same assumption -- that every H2 below the intro is one change -- and only ONE of them
        checked it. The cut refused, by name, before writing anything. The fold did not: it took the first
        '^## ' it found as the top of the list, which in a pre-flat document is the SECTION heading, and
        inserted the entry above it. Measured in a consumer on 2026-08-09, exit 0 and no warning:

            Folded and reset: branch/branch-changelog.md (tier 1, significance 3 -- placed above 2 existing entries)
            CHANGELOG.md updated.

        The "2 existing entries" were their two section headings, and the entry landed outside the section
        it belonged in -- visible only to somebody who opened the file afterwards. Two scripts with the same
        assumption owe their consumer the same guardrail, so the text lives once and both read it.

        THE CONSEQUENCE CLAUSE IS THE CALLER'S, and that is the only part that varies: the cut EMPTIES this
        file, so a section heading read as a change is published outward and then deleted, while the fold
        WRITES INTO it, so the entry lands in the wrong place. Same diagnosis, same migration advice,
        different thing about to go wrong -- so that one sentence is a parameter rather than a second copy
        of the whole message.

        Test-EntryDeclaresShape is the discriminator and it is exact rather than a heuristic -- see its
        header. A document with no entries at all yields no findings: there is nothing to misread.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content,
        # What this particular caller is about to do to the blocks it cannot read. One sentence, no
        # trailing period -- it is spliced into the sentence below.
        [Parameter(Mandatory)][string]$Consequence
    )

    $level = Get-EntryHeadingLevel
    $blocks = @(Get-ChangelogEntryBlocks -Content $Content)
    $notEntries = @($blocks | Where-Object { -not (Test-EntryDeclaresShape -EntryText $_) })
    if ($notEntries.Count -eq 0) { return '' }

    $names = @($notEntries | ForEach-Object { "'" + (($_ -split "`r?`n")[0]) + "'" })
    return ("CHANGELOG.md carries $($notEntries.Count) H$level block(s) that declare " +
        "neither an entry's named sections nor a change type: $($names -join ', '). Every " +
        "H$level below the intro is read as one change, so $Consequence. That is what a pre-flat " +
        "CHANGELOG.md looks like to this parser: a section heading ('## Pull Requests', " +
        "'## Tier N - Pull Requests', '## Releases') sits at the level an entry now occupies. Migrate the " +
        "document first: drop the section headings, promote each entry to H$level, and " +
        "give it the three named sections. An entry written before this format is fine as it is -- it " +
        "declares its type in its heading.")
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
    <# One section's full heading line, e.g. '### Branch type'. One formatter, so the writer and the
       parser cannot disagree about the level or the spacing. #>
    param([Parameter(Mandatory)][ValidateSet('Description', 'Id', 'Type', 'What', 'Significance', 'PullRequest')][string]$Key)
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

        THE SECTION'S RETIRED NAMES ARE ACCEPTED ALONGSIDE ITS CURRENT ONE, and that is not politeness
        towards history: 'Type of change' became 'Branch type' and 'What does this change do?' became the
        branch-facing question, while CHANGELOG.md and every consumer's tree are full of entries carrying the
        old names. A reader that knew only the new one would find no type on any of them and file the lot
        under nothing -- silent, correct-looking, and wrong. Recognise both, write one.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$EntryText,
        [Parameter(Mandatory)][ValidateSet('Description', 'Id', 'Type', 'What', 'Significance', 'PullRequest')][string]$Key
    )
    $names = @(@((Get-EntrySectionHeadings)[$Key]) + @(Get-EntrySectionRetiredNames -Key $Key) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($names.Count -eq 0) { return '' }
    $body = Get-EntryTextOutsideFences -EntryText $EntryText
    $lines = @($body -split '\r?\n')
    $rx = '^#{' + $script:EntrySectionLevel + '}\s+(?:' +
        ((@($names) | ForEach-Object { [regex]::Escape([string]$_) }) -join '|') + ')\s*$'

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

function Test-EntryHasSection {
    <#
        Pure: does this entry carry the named section at all, under its current heading or a retired one?

        ABSENT AND EMPTY ARE DIFFERENT QUESTIONS, and conflating them produced a false accusation on the
        first run of the emptiness gate. Get-EntrySectionAnswer returns '' for both, so a gate built on it
        alone reported the title section (then called 'Branch description') as unanswered on every
        pre-dossier entry -- entries that never
        had that section, because their title was the heading. Every branch in flight carries one, so that
        is two dozen refusals for writing an entry correctly under the format that was current at the time.

        A MISSING SECTION IS NOT THIS GATE'S BUSINESS. Whether an entry's structure is right is the lint's
        question (check 13, which knows both shapes); whether the author answered the questions in front of
        them is this one's.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$EntryText,
        [Parameter(Mandatory)][ValidateSet('Description', 'Id', 'Type', 'What', 'Significance', 'PullRequest')][string]$Key
    )
    $names = @(@((Get-EntrySectionHeadings)[$Key]) + @(Get-EntrySectionRetiredNames -Key $Key) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($names.Count -eq 0) { return $false }
    $rx = '(?m)^#{' + $script:EntrySectionLevel + '}\s+(?:' +
        ((@($names) | ForEach-Object { [regex]::Escape([string]$_) }) -join '|') + ')\s*$'
    return [bool]([regex]::IsMatch((Get-EntryTextOutsideFences -EntryText $EntryText), $rx))
}

function Get-EntrySectionAnswer {
    <#
        Pure: what the AUTHOR wrote under a section -- its body with the guidance comments stripped and the
        result trimmed. '' means the section is still empty, whatever form text is standing in it.

        THE DISTINCTION IS THE WHOLE POINT, and it only became necessary with the dossier form. A scaffolded
        section is a heading with a comment under it and nothing else; Get-EntrySectionBody returns that
        comment, which is not nothing, so a caller asking "has this been answered" would get yes for every
        untouched entry in the repo. The fold strips those comments, so the section that looked answered
        lands in CHANGELOG.md blank -- found by asking the question the gate actually needs answered rather
        than the one the reader already had.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$EntryText,
        [Parameter(Mandatory)][ValidateSet('Description', 'Id', 'Type', 'What', 'Significance', 'PullRequest')][string]$Key
    )
    $raw = Get-EntrySectionBody -EntryText $EntryText -Key $Key
    if (-not $raw) { return '' }
    return (Remove-EntryHtmlComments -EntryText $raw).Trim()
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

    # THE ANSWER, NOT THE BODY, and the difference is the guidance comment sitting above it. Reading the raw
    # body made the FIRST non-empty line the type -- which since the dossier form is
    # '<!-- options for type are: feat, fix or docs-->', so every new entry declared its type to be that
    # sentence. It parsed, it was Declared, and the only thing that caught it was a test asserting the
    # canonical value: a repo without Get-BranchTypes reachable would have published the comment as a change
    # type into its release documents without a single complaint.
    $section = Get-EntrySectionAnswer -EntryText $EntryText -Key 'Type'
    if ($section) {
        $result.Raw = $section
        $result.Declared = $true
        # The first non-empty line, stripped of the bold/backtick decoration somebody may reasonably add.
        $first = @($section -split '\r?\n' | Where-Object { $_.Trim() })[0]
        $result.Type = ($first -replace '[*`_]', '').Trim()
        # CANONICALISED CASE-INSENSITIVELY, because the two shapes of this section disagree about case. The
        # dossier form's 'Branch type' holds the branch PREFIX ('feat') -- that is what its hint asks for and
        # what the scaffolder writes from Get-BranchInfo -- while 'Type of change' held the canonical type
        # ('Feat'), and CHANGELOG.md is full of those. Matching exactly would have reported every new entry
        # as carrying a type this repo does not produce, which is a refusal at the PR for writing down
        # exactly what the form asked for.
        $canonical = @($known | Where-Object {
            $_ -and ([string]$_).ToLowerInvariant() -eq $result.Type.ToLowerInvariant()
        })
        if ($canonical.Count -gt 0) { $result.Type = [string]$canonical[0] }
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

function Add-EntrySection {
    <#
        Private: one section of the entry -- the H3 heading, its guidance comment directly underneath, and
        the value (if any) under that. Appends to the caller's list.

        THE COMMENT SITS TIGHT AGAINST THE HEADING, with no blank line between them, and that is the
        template's shape rather than a preference: a hint belongs to the heading it explains, and the blank
        line goes after the pair. The progress file spaces two of its sections the other way, which is why
        this is per-file layout stated at the call site rather than a rule derived here.

        A HELPER RATHER THAN SIX COPIES. The sections differ only in their three inputs, and the blank lines
        between them are exactly the kind of difference nobody notices until two of them disagree and a
        byte-exact template check reports drift for a reason no one can see.

        -WithGuidance IS OFF BY DEFAULT, AND ONLY THE TEMPLATE TURNS IT ON (Dave, August 7, 2026). The file
        a branch actually gets carries no comments at all: the templates under branch/templates/ are the
        reference you consult, and duplicating that reference into every working file made the thing you
        write in mostly form text. What the working file keeps is the questions themselves -- the headings --
        which is the part that has to be answered rather than read.
    #>
    param(
        [Parameter(Mandatory)]$Lines,
        [Parameter(Mandatory)][string]$Key,
        [AllowEmptyString()][string]$Value = '',
        [switch]$WithGuidance
    )
    $Lines.Add((Get-EntrySectionHeading -Key $Key))
    if ($WithGuidance) {
        $all = Get-EntryGuidance
        $guidance = @()
        if ($all.PSObject.Properties[$Key]) { $guidance = @($all.PSObject.Properties[$Key].Value) }
        foreach ($line in (Format-EntryGuidanceComment -Lines $guidance)) { $Lines.Add($line) }
    }
    if ($Value) {
        $Lines.Add('')
        foreach ($line in ($Value -split '\r?\n')) { $Lines.Add($line) }
    }
    $Lines.Add('')
}

function Format-EntryBlock {
    <#
        The whole entry as an array of LINES: the H2 branch heading, then the six H3 sections in order.

        THE HEADING NAMES THE BRANCH, NOT THE CHANGE (Dave, August 6, 2026) -- '## `feat/x` changelog', the
        same heading branch-progress.md carries with its own suffix, because the two files are a matched
        pair. What the heading used to hold now has a section of its own: 'Branch title'. This whole
        file is still pasted verbatim into CHANGELOG.md at the merge, so that is what lands there; Dave was
        offered a fold that derives a slimmer block instead and declined it, on the record, before this was
        built. See $script:EntrySectionDefaults for the reasoning.

        ONE FORMATTER FOR THE WRITER AND THE MIGRATION, which is why it takes pieces rather than assembling
        prose. new-branch.ps1 calls it with empty fields and no rows; a migration calls it with real
        ones. Two assemblers would drift, and the parser reads what this writes.

        $TitleSuffix is for the copy under branch/templates/, which marks itself '(template)' so it cannot be
        mistaken for a real entry -- by a reader or by a gate. Empty for the file a branch actually gets.
    #>
    param(
        [AllowEmptyString()][string]$Branch = '',
        [string]$Description = '',
        [string]$Id = '',
        [string]$Type = '',
        [string]$Body = '',
        $ImpactRows = @(),
        [string]$TitleSuffix = '',
        [switch]$Template
    )
    # -Template renders the copy under branch/templates/: it marks its heading and it is the ONLY rendering
    # that carries the guidance comments. Kept as one switch rather than two knobs because those two facts
    # are the same fact -- "this is the reference, not somebody's working file" -- and a caller that set one
    # without the other would produce a file that is neither.
    if ($Template -and -not $TitleSuffix) { $TitleSuffix = (Get-BranchFileWording).TemplateMarker }
    # Each line appended on its own statement, NOT as @(<expr>, '') -- the comma operator binds looser than
    # '+', so `@(('#'*2) + ' ' + $Title, '')` concatenates the string with the ARRAY ($Title, '') and joins
    # it with a space. That produced '## A real title ' with a trailing space and no blank line after it,
    # which is well-formed markdown and therefore invisible until a parser expecting the blank line fails.
    # Measured on this function's first run.
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add((Format-BranchFileHeadingLine -Branch $Branch -Title (Get-BranchFileWording).ChangelogTitle `
        -Level $script:EntryHeadingLevel -Suffix $TitleSuffix))
    $lines.Add('')

    Add-EntrySection -Lines $lines -Key 'Description' -Value $Description -WithGuidance:$Template
    Add-EntrySection -Lines $lines -Key 'Id'          -Value $Id          -WithGuidance:$Template
    Add-EntrySection -Lines $lines -Key 'Type'        -Value $Type        -WithGuidance:$Template
    Add-EntrySection -Lines $lines -Key 'What'        -Value $Body        -WithGuidance:$Template

    # Significance carries no guidance of its own: its '#### Tier N' sub-sections each carry theirs, and a
    # hint above a section whose every part is already annotated is one the reader has to read twice.
    $lines.Add((Get-EntrySectionHeading -Key 'Significance'))
    $lines.Add('')
    foreach ($line in (Format-EntrySignificanceSections -Rows $ImpactRows -WithGuidance:$Template)) { $lines.Add($line) }
    $lines.Add('')

    # WRITTEN EMPTY AND FILLED BY THE FOLD. The section exists from the start so the form is complete on the
    # page, but the two facts in it -- the number and the merge date -- do not exist until the merge, and a
    # hand-written one would be a second copy of something nobody has yet.
    Add-EntrySection -Lines $lines -Key 'PullRequest' -WithGuidance:$Template
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
        field, which is what new-branch.ps1 wrote for as long as that shape existed. A leftover
        section heading carries neither, and cannot -- it is a heading with prose under it.

        Deliberately NOT keyed on the '#NN' the fold prepends: the fold cannot reach gh on a manual merge
        and then writes a legitimate entry with no number, saying so on the console. A gate keying on the
        number would report the fold's own documented output as a defect.

        FENCE-AWARE through the readers it calls, for the reason every reader here is: an entry documenting
        this format quotes these headings inside a fence, and the entry for this very change does.

        THREE OF THE SIX SECTIONS PROVE NOTHING, AND THAT IS NEW (August 6, 2026). The dossier form gave
        branch-progress.md the same title, 'Branch ID' and 'Branch type' headings the entry
        carries -- deliberately, they are one pair of files -- so a predicate matching ANY named section
        started answering $true for the step list. Measured immediately: the scaffold gate then judged a
        freshly written step list as an unfinished ENTRY and reported its empty description. That is the
        exact confusion the two-file split was made to remove, reappearing inside the discriminator.

        So only the sections an entry ALONE has count: the 'what does it bring' question, the significance
        block and the pull-request section -- WITH THEIR OWN RETIRED NAMES, and no others.

        THAT LAST CLAUSE IS A REPAIR, not a restatement (August 7, 2026). This read every retired name in the
        format's history, justified as "'Type of change' and the rest were written when there was one file,
        so a step list cannot be carrying one". True of every name in that list on the day it was written,
        and it stopped being true the moment 'Branch description' was retired in favour of 'Branch title':
        that name dates from AFTER the split, so the step lists of that fortnight -- on every branch in
        flight here and in every consumer -- carry it. A blanket retired list would have read those step
        lists as entries again. Retired names are inherited per section now, so a name can only ever prove
        what its own section proves. Nothing is lost by dropping 'Type of change' from this set: an entry old
        enough to carry it carries 'What does this change do?' and 'Who is this for' as well, both still here.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $body = Get-EntryTextOutsideFences -EntryText $EntryText
    $lines = @($body -split '\r?\n')
    $entryOnlyKeys = @('What', 'Significance', 'PullRequest')
    $headings = @($entryOnlyKeys | ForEach-Object {
        @((Get-EntrySectionHeadings)[$_]) + @(Get-EntrySectionRetiredNames -Key $_)
    })
    foreach ($heading in $headings) {
        if (-not $heading) { continue }
        $rx = '^#{' + $script:EntrySectionLevel + '}\s+' + [regex]::Escape([string]$heading) + '\s*$'
        foreach ($line in $lines) {
            if ($line -match $rx) { return $true }
        }
    }
    # THE TYPE FALLBACK IS FOR THE HEADING FIELD, NOT FOR THE SECTION. Resolve-EntryType reads the section
    # first, and 'Branch type' is one of the three a step list also carries -- so on a step list it would
    # report Declared and undo the whole distinction above. Where that section is present its answer proves
    # nothing, and the entry-only sections have already had their say.
    $currentType = (Get-EntrySectionHeadings)['Type']
    if ($currentType) {
        $typeRx = '^#{' + $script:EntrySectionLevel + '}\s+' + [regex]::Escape([string]$currentType) + '\s*$'
        foreach ($line in $lines) {
            if ($line -match $typeRx) { return $false }
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

        AND SINCE THE DOSSIER FORM IT ALSO MEASURES EMPTINESS, which is the half that replaced the markers
        rather than joining them (Dave, August 6, 2026). The scaffold no longer writes a visible 'TODO:'
        anywhere: every field is a heading with a guidance COMMENT under it, so an untouched entry has empty
        sections rather than recognisable text. A gate that only matched strings would have gone quiet on
        exactly the entry it exists to stop -- silently, reporting success, which is this repo's worst
        failure mode for a guard.

        WHAT IS MEASURED IS STRICTLY MORE THAN WHAT THE MARKERS CAUGHT. An empty section is reported whether
        the author never touched it OR deleted the placeholder instead of answering it, and the comments are
        stripped first so leaving the guidance standing is not mistaken for an answer -- which it must not
        be, because the fold strips those comments and the section would land in CHANGELOG.md blank.

        THE STRING MARKERS STAY, and not out of sentiment: every branch in flight, here and in every
        consumer, carries an entry written by the older scaffolder right now, and those reach this gate
        through a plugin update rather than by choosing to. Recognise both, write one.
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

    # THE EMPTINESS HALF. Only judged on an entry that actually uses the named sections -- a pre-format entry
    # has none of them, and reporting all of it as unanswered would refuse every branch whose entry predates
    # this shape. Test-EntryDeclaresShape is the same discriminator the parser uses, so the two cannot
    # disagree about which shape they are looking at.
    if (Test-EntryDeclaresShape -EntryText $EntryText) {
        # PullRequest is deliberately absent: the fold fills it, so it is empty by design until the merge.
        # Id and Type are written by the scaffolder itself, so an empty one is a scaffolder fault rather
        # than an author's, and refusing the author for it would be pointing at the wrong person.
        # ONLY A SECTION THE ENTRY ACTUALLY HAS. An entry written before the dossier form carries no
        # title section at all -- its title WAS the heading -- and reporting the absence would refuse every
        # branch in flight for having been correct under the format of the day. See Test-EntryHasSection.
        foreach ($key in @('Description', 'What')) {
            if (-not (Test-EntryHasSection -EntryText $EntryText -Key $key)) { continue }
            if (-not (Get-EntrySectionAnswer -EntryText $EntryText -Key $key)) {
                $findings += [pscustomobject]@{
                    Label  = 'an unanswered section'
                    Marker = Get-EntrySectionHeading -Key $key
                }
            }
        }
        # Every tier the entry claims owes a reason, tier 0 included -- which is where the retired
        # why-placeholder used to be caught. Get-EntryImpactFindings asks this of tiers 1 and up only,
        # because its subject is the RANKING and tier 0 is never ranked; the reason is still content.
        $impact = Resolve-EntryImpact -EntryText $EntryText
        foreach ($row in @($impact.Rows)) {
            if ($row.Error) { continue }
            if (-not $row.Why) {
                # A REASON ON THE WRONG SIDE OF THE SCORE IS NOT A MISSING REASON (inbound #596), and
                # saying which of the two it is IS the repair. The refusal is correct either way -- the
                # fold would publish that tier empty -- but 'no reason' is the one thing an author looking
                # at three written paragraphs can see is untrue, so the natural next move is to distrust
                # the gate rather than to move the text. Measured there: three tiers, all three answered,
                # all three reported as unanswered, and it took reading this file line by line to find out
                # why. The data to tell them apart was already in hand; it just was not being kept.
                $below = if ($row.PSObject.Properties['WhyBelowScore']) { [string]$row.WhyBelowScore } else { '' }
                $findings += [pscustomobject]@{
                    Label  = if ($below) {
                        "a tier whose reason sits BELOW its $($script:EntryScoreLabel) line -- move it above"
                    } else {
                        'a tier with no reason'
                    }
                    Marker = Get-EntryTierSectionMarker -Tier ([int]$row.Tier)
                }
            }
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
# THE SPLIT IS THE POINT. The root entry file did both jobs: new-branch.ps1 scaffolded it with
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
    # The branch name is prepended to these by Format-BranchFileHeader -- '# `feat/x` progress' -- so they
    # are the suffix rather than the whole title. Lowercase for that reason.
    ChangelogTitle = 'changelog'
    ProgressTitle  = 'progress'
    BranchLabel    = 'Branch'
    StepsHeading   = 'Steps'
    NotesHeading   = 'Where I left off'
    FirstStep      = 'TODO: the first step of this branch'
    # The marker the copies under branch/templates/ carry in their heading, so neither a reader nor a gate
    # can mistake one for a real branch file. Not merely cosmetic: a template opens with the same H2 a
    # written entry does, which is the signature the fold and the lint key on.
    TemplateMarker = '(template)'
    # THE THREE BRANCH FIELDS ARE NOT HERE. They are sections of the entry now and both files write them
    # from Get-EntrySectionHeadings + Get-EntryGuidance -- see $script:EntryGuidanceDefaults for why one
    # source rather than two. The keys that used to hold them (TitleHeading, IdGuidance, ...) are gone
    # rather than left pointing at nothing, so a consumer overriding one gets a script-contract failure
    # instead of a silently ignored setting.
    StepsGuidance  = @(
        'The plan for this branch. Every step must be resolved before the PR: open-pr and',
        'ship-pr both refuse while anything is still "- [ ]", and there is no -Force.',
        '',
        '  - [ ] not done yet',
        '  - [x] done',
        '  - [~] dropped -- why it turned out not to be needed',
        '',
        'The dropped mark exists so nobody is pushed into ticking a box for work they did',
        'not do. It keeps its line and its reason, which is the half worth reading later.'
    )
    NotesGuidance  = @(
        'For picking this branch up again -- tomorrow, or on another machine after a park.',
        'What is done, what you were in the middle of, and anything you decided but have',
        'not written down anywhere else yet.'
    )
    ChangelogReset = @(
        'This file carries the changelog entry of the branch you are on -- the finished description that',
        'folds into `CHANGELOG.md` at the merge. It is written when a branch is created and returns to this',
        'state once the entry has been folded, so what you see here is the empty state, not a lost entry.'
    )
    ProgressReset  = @(
        'This file carries the step list of the branch you are on. It is written when a branch is created',
        'and returns to this state after the merge.'
    )
    # THE OPENING SENTENCE OF THE TRUNK WARNING, AND IT IS A SEAM BECAUSE IT WAS THE ONE FRAGMENT THAT WAS
    # NOT (inbound #562, August 10, 2026). Format-BranchFileHeader used to build this line itself, so a
    # consumer who had translated everything else got a document whose FIRST sentence was still English:
    #
    #   > **You are on `main`.** Schrijf hier nog niet -- maak eerst een branch.
    #
    # Exactly the case these knobs exist for -- the rest of the sentence is repo-owned language, and the
    # only way out was forking new-branch.ps1, which is the duplication #410 had just removed.
    #
    # '{0}' IS REPLACED BY THE TRUNK NAME, and by a plain string replace rather than -f / [string]::Format.
    # A seam value is hand-written, so a stray '{' in somebody's translation would make a format string
    # throw at scaffold time; a replace cannot fail. The placeholder is OPTIONAL for the same reason it is
    # useful: a translation needs the trunk name in a different position than English does, and one that
    # leaves it out simply does not repeat the name -- the heading directly above already carries it.
    #
    # AN EMPTY OVERRIDE KEEPS THIS DEFAULT, like every other key here -- see Get-BranchFileWording's
    # fail-safe. So there is no way to drop the sentence through the seam, only to replace it. The first
    # draft of this change claimed there was, and the test written to prove it is what disproved it.
    TrunkWarningLead = '**You are on `{0}`.**'
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
        it into a document: new-branch.ps1 refuses to scaffold on the trunk, the reset template
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

        UNDER workflow-davekjohn/ SINCE AUGUST 14, 2026 (Dave): everything portable about the workflow
        gathers in that one root folder instead of scattering through the consumer's root, and the
        branch dossier is its first resident. No dual-read of the old root 'branch/' location,
        deliberately: new-branch creates the new directory on the first branch (New-Item -Force makes
        the parents), and a repo still carrying a root branch/ from before removes it by hand -- Dave's
        call when the move was decided, over a fallback that would have kept two possible locations
        alive in every reader of this function.
    #>
    return [pscustomobject]@{
        Directory = 'workflow-davekjohn/branch'
        Changelog = 'workflow-davekjohn/branch/branch-changelog.md'
        Progress  = 'workflow-davekjohn/branch/branch-progress.md'
    }
}

function Get-BranchFileWording {
    <#
        The prose inside the two branch files -- this repo's answers where repo-config.ps1 gives them,
        the English defaults otherwise.

        ONE GETTER RETURNING A MAP, unlike Get-EntryScaffoldWording's three separate ones, and the
        difference is deliberate rather than inconsistency. Those three are each read by a GATE that
        must match the writer string-for-string, so each is its own contract with its own name. These
        are document prose read by nobody but the reader of the file; a repo translating one translates
        all of them, and one seam function per string would be one script-contract entry per string for
        a single act. (This sentence said 'these nine' until August 10, 2026, when it was thirteen and
        gaining a fourteenth -- a count of the keys directly below it goes stale every time one is added,
        and buys a reader nothing that reading the map does not.)

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

function Format-BranchFileHeadingLine {
    <#
        The heading line both branch files open with -- '## `feat/x` changelog', '# `main` progress'.

        ONE FORMATTER FOR FOUR CALLERS, because the two files and their two states all write this line and
        Get-BranchFileDeclaredBranch READS it back. The branch name is the file's only machine-read fact
        outside the step marks, so the writer and the reader agreeing about the backticks is not a nicety.

        THE BRANCH IS NAMED IN THE HEADING, not on a line below it (Dave, August 6, 2026). The heading has
        to say which branch this file belongs to anyway, so a separate '**Branch:**' line was the same fact
        written twice -- and Get-BranchFileDeclaredBranch reads the heading now, with the old line kept as a
        fallback for the branches already carrying one.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Branch,
        [Parameter(Mandatory)][string]$Title,
        [int]$Level = 2,
        [string]$Suffix = ''
    )
    $shown = if ($Branch) { $Branch } else { Get-BranchTrunkName }
    $line = ('#' * $Level) + ' `' + $shown + '` ' + $Title
    if ($Suffix) { $line += ' ' + $Suffix }
    return $line
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
    # THE RESET STATE IS AN H1 AND A WRITTEN FILE IS AN H2, and that difference is load-bearing rather than
    # cosmetic: Test-IsChangelogEntryFile decides "is there an entry here" on the heading level, so the
    # trunk's own empty file can never be folded as if it were a change, and folding twice is impossible
    # rather than merely unlikely. This formatter serves the RESET, hence Level 1.
    $lines.Add((Format-BranchFileHeadingLine -Branch $shown -Title $Title -Level 1))
    if ($shown -eq $trunk) {
        $lines.Add('')
        $lines.Add('')
        # THE LEAD COMES FROM THE WORDING TOO (inbound #562). It was built here, inline, which made it the
        # one fragment of these two documents a consumer could not translate. '{0}' is replaced rather than
        # formatted -- see the TrunkWarningLead default for why a hand-written seam value must not be handed
        # to a format string. A lead that is empty leaves the two warning lines standing on their own, which
        # is a legitimate answer: the heading above already names the trunk.
        $lead = [string]$Wording.TrunkWarningLead
        if ($lead) { $lead = $lead.Replace('{0}', $trunk) + ' ' }
        $lines.Add('> ' + $lead + $Wording.TrunkWarning[0])
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
    $lines.Add(('#' * $script:EntrySectionLevel) + ' ' + $w.StepsHeading)
    $lines.Add('')
    $lines.Add('_(' + $w.ScaffoldNote + ')_')
    return @($lines.ToArray())
}

function Add-BranchProgressSection {
    <#
        Private: one of the progress file's OWN sections -- Steps and Where I left off. Heading, a blank
        line, the guidance comment, then the body. Appends to the caller's list.

        THE BLANK BEFORE THE COMMENT IS WHAT SEPARATES THESE TWO FROM THE THREE BRANCH FIELDS ABOVE THEM,
        which sit tight against their heading (Add-EntrySection). That is the template's shape and it reads
        as one: a one-line hint belongs to its heading, a block of prose stands on its own. Not derived from
        the line count -- the changelog's 'What' section is a block sitting tight -- so it is stated per call
        site rather than guessed.

        THE HORIZONTAL RULES ARE GONE with the dossier form. They separated five H2 sections; the sections
        are H3 now and their headings do that work, while a '---' between every pair turned a short file
        into a ruled form.
    #>
    param(
        [Parameter(Mandatory)]$Lines,
        [Parameter(Mandatory)][string]$Heading,
        [AllowEmptyCollection()][string[]]$Guidance = @(),
        [AllowEmptyCollection()][string[]]$Body = @()
    )
    $Lines.Add(('#' * $script:EntrySectionLevel) + ' ' + $Heading)
    $rendered = @(Format-EntryGuidanceComment -Lines $Guidance)
    if ($rendered.Count -gt 0) {
        $Lines.Add('')
        foreach ($line in $rendered) { $Lines.Add($line) }
    }
    $body = @(@($Body) | Where-Object { $null -ne $_ })
    if ($body.Count -gt 0) {
        $Lines.Add('')
        foreach ($line in $body) { $Lines.Add($line) }
    }
    $Lines.Add('')
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

        THE THREE BRANCH FIELDS ARE NOT HERE, AND THAT IS THE POINT (Dave, August 7, 2026). Description, ID
        and type briefly appeared at the top of BOTH files, on the reasoning that the pair should say whose
        it is. He removed them from this one: the same information in two places is the drift this repo
        keeps paying for, and here it would be visible on every branch -- two files, side by side, free to
        disagree about the same three boxes. **The heading already carries the identifier**, which is also
        the only thing any script reads out of this file besides the step marks.

        So this file is exactly what its name says: the plan, and where you left off.

        -Template renders the copy under branch/templates/: it marks its heading '(template)', carries the
        guidance comments, and omits the scaffolded first step. The step is the one thing the template must
        NOT show, because a template is read as an example -- and an example whose first line is somebody
        else's TODO gets copied in.
    #>
    param(
        [Parameter(Mandatory)][string]$Branch,
        [string]$Intent = '',
        [switch]$Template
    )
    $w = Get-BranchFileWording
    $suffix = if ($Template) { $w.TemplateMarker } else { '' }
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add((Format-BranchFileHeadingLine -Branch $Branch -Title $w.ProgressTitle `
        -Level $script:EntryHeadingLevel -Suffix $suffix))
    $lines.Add('')

    # THE SCAFFOLDED STEP STAYS IN THE FILE A BRANCH ACTUALLY GETS (Dave, August 6, 2026), asked and answered
    # when the template dropped it. Without it a fresh branch reaches a PR with no plan at all and the
    # step-list gate has nothing to refuse -- Get-BranchProgressFindings reports only steps somebody wrote,
    # and "no step list at all" is a deliberately permitted state for the one-commit typo fix. One open step
    # is what makes the gate bite on the ordinary branch while leaving that case alone.
    $steps = @()
    if (-not $Template) { $steps = @((Get-BranchProgressMarks).Open + $w.FirstStep) }
    $stepsGuidance = if ($Template) { $w.StepsGuidance } else { @() }
    $notesGuidance = if ($Template) { $w.NotesGuidance } else { @() }
    Add-BranchProgressSection -Lines $lines -Heading $w.StepsHeading -Guidance $stepsGuidance -Body $steps
    $note = if ($Intent) { @($Intent -split '\r?\n') } else { @() }
    Add-BranchProgressSection -Lines $lines -Heading $w.NotesHeading -Guidance $notesGuidance -Body $note

    return @($lines.ToArray())
}

$script:BranchTemplateDir         = 'workflow-davekjohn/branch/templates'
$script:BranchTemplateBranchToken = '<prefix>/<short-name>'

function Get-BranchTemplates {
    <#
        The copy-paste templates under workflow-davekjohn/branch/templates/, as objects with Path
        (repo-relative) and Content (exactly what that file must contain).

        WHY THEY ARE GENERATED RATHER THAN WRITTEN, and why a lint check reads this same function. A
        template beside a scaffolder that writes the same shape is TWO SOURCES OF ONE FORMAT, which is the
        drift this repo keeps paying for -- the entry-scaffold wording, the fence readers, the tier
        sections. The entry format changed three times in one day while these templates were being added;
        a hand-written copy would have been wrong before it was committed.

        So the content comes from the same formatters the scaffolder calls, and check-plugin-integrity.ps1
        holds the files on disk to it. The templates are then genuinely a convenience -- something to look
        at and paste from -- without being a second definition of anything.

        BOTH TEMPLATES NAME A PLACEHOLDER BRANCH rather than a real one, because they belong to no branch,
        and both mark their heading '(template)'. That marker is not decoration: a written entry and a
        template now open with the same H2, which is the signature Test-IsChangelogEntryFile keys on.

        THE TRAILING BYTES ARE PART OF THE FILE and are set here rather than left to the join, because the
        lint holds these two to the byte with only CRLF normalised.

        BOTH END WITH A NEWLINE (Dave, August 7, 2026). The progress template ended on its last '-->' with
        no terminator at all -- an accident of the editor it was designed in, faithfully reproduced here
        while the templates were being treated as the spec, and then repaired on his word. A file without a
        final newline is the one whose next diff shows a line nobody edited, and git says so out loud every
        time ("\ No newline at end of file"). The changelog template keeps the blank line before its
        terminator, which is its author's spacing rather than an accident.
    #>
    $nl = "`n"
    $token = $script:BranchTemplateBranchToken
    # -Template is what carries the guidance comments AND the '(template)' marker -- see Format-EntryBlock.
    # These two calls are the only place in the system that passes it, which is the whole point: the
    # reference lives here, and the file a branch gets is the bare form.
    # RETIRED WITH THE COMMENTED-OUT TIERS (August 7, 2026): Add-TemplateTierPrompt used to splice a
    # '<!-- UNCOMMENT Tier 1 ... -->' block in here, because the template showed the whole form while the
    # scaffold showed tier 0 alone. All three tiers are real sections in both now -- the answer inside each
    # is the claim, not its presence -- so there is nothing left to splice and the function is gone rather
    # than left standing with no caller.
    $changelog = Format-EntryBlock -Branch $token -Template
    $progress  = Format-BranchProgressScaffold -Branch $token -Template
    return @(
        [pscustomobject]@{
            Path    = "$($script:BranchTemplateDir)/branch_template_changelog.md"
            Content = (($changelog -join $nl).TrimEnd("`n")) + $nl + $nl + $nl
        },
        [pscustomobject]@{
            Path    = "$($script:BranchTemplateDir)/branch_template_progress.md"
            Content = (($progress -join $nl).TrimEnd("`n")) + $nl
        }
    )
}

function Get-BranchFileDeclaredBranch {
    <#
        Pure: the branch a branch file says it belongs to -- the name in its '**Branch:** `x`' line -- or
        '' when the file has no such line.

        THIS IS THE IDEMPOTENCY TEST, and it is why the branch line is in the document rather than only in
        the scaffolder's head. new-branch.ps1 may be run twice on the same branch (it is, by
        new-branch, which is itself idempotent), and the second run must not overwrite a step list somebody
        has been ticking off. Comparing the declared branch against HEAD answers that exactly: the trunk
        name means the file is still in its reset state and is ours to write, any other name means it is
        already someone's working file.

        The label is read from the wording rather than hardcoded, so a repo that translated it can still be
        recognised -- a predicate that only knows the English label would read every file in a translated
        repo as unscaffolded and overwrite it.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    # TWO SHAPES, ONE WRITTEN. The branch is named in the file's H1 -- '# `feat/x` progress' -- since
    # August 6, 2026, because that heading has to say which branch this is anyway and a second line
    # repeating it is one fact in two places. Before that it was a '**Branch:** `feat/x`' line, and every
    # branch in flight still carries one, here and in every consumer.
    #
    # The heading wins where both are present: it is the one a writer edits.
    #
    # BOTH LEVELS, because the reset state is an H1 and a written file is an H2 -- the difference the fold
    # keys on to tell an empty trunk file from an entry. This predicate must read them BOTH: it is the
    # idempotency test, and a scaffolded H2 file it could not read would come back as '' and be overwritten,
    # taking a step list somebody had been ticking off with it. An H1-only regex was correct for exactly the
    # few hours in which both files opened with one.
    $headingRx = '^#{1,2}\s+`([^`]+)`'
    $label = (Get-BranchFileWording).BranchLabel
    $lineRx = '^\*\*' + [regex]::Escape([string]$label) + ':\*\*\s*`([^`]+)`\s*$'

    $fallback = ''
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match $headingRx) { return $Matches[1] }
        if ((-not $fallback) -and $line -match $lineRx) { $fallback = $Matches[1] }
    }
    return $fallback
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

        AND COMMENT-AWARE, FOR THE SAME REASON AND A SHARPER CASE. The Steps section's own guidance shows
        all three marks as examples -- '- [ ] not done yet' among them -- inside an HTML comment. Reading
        those as steps meant a freshly scaffolded list reported FOUR open steps: its own real one plus three
        the form was using to explain itself. Worse than noise, because the three cannot be resolved: they
        come back with the next scaffold, so the only way past the gate is to delete the instructions.
        Measured the moment the guidance comments and this gate first met.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    $marks = Get-BranchProgressMarks
    $body = Remove-EntryHtmlComments -EntryText (Get-EntryTextOutsideFences -EntryText $Text)
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
