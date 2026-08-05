<#
.SYNOPSIS
    The changelog entry's own format, in one place: the scaffold strings new-changelog-entry.ps1
    WRITES and open-pr.ps1 REFUSES TO SHIP, the 'Tier: N' line that declares how far an entry reaches,
    the significance scores that order the documents that tier reaches, and the changelog sections those
    tiers are folded into.

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

# THE RUBRIC -- the definition of each level, and the reason the number is a measurement. Every band is
# written as a TEST rather than a feeling ("must act", "noticed within a day"), so two people scoring the
# same change land on the same band and a reviewer can disagree with a specific claim instead of with a
# vibe.
#
# AN ARRAY OF PAIRS, NOT A MAP KEYED BY THE SCORE, and that is a bug this shape prevents rather than a
# style choice -- the very bug Resolve-ChangelogTierSections warns about further down this file, walked
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

        OFF WHERE THERE IS NO TIER SPLIT, which is what keeps this safe to share -- the same reasoning as
        Test-ReleaseBumpEarned's Active flag. A repo with one entry section has no tier information, so no
        entry can ever reach tier 1, nothing is required of it, and a document with one section has no
        cross-category ordering to gain. Rather than imposing a model such a repo never adopted, the whole
        mechanism reports itself inactive.

        The seam is Get-EntrySignificanceEnabled in the consumer's scripts/repo-config.ps1, probed with
        Get-Command like every other optional knob -- for the repo that HAS adopted tiers and does not want
        the ranking. Returning $false there switches off the scaffold's table, both validators and the cut's
        gate together, because a half-adopted ranking (required but never read) is worse than neither.
    #>
    param($TierSections = $null)
    if (Get-Command Get-EntrySignificanceEnabled -ErrorAction SilentlyContinue) {
        return [bool](Get-EntrySignificanceEnabled)
    }
    $sections = if ($null -ne $TierSections) { @($TierSections) } else { @(Get-ChangelogTierSections) }
    return ($sections.Count -gt 1)
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

        FALLS BACK TO 'Tier: N', and that fallback is not legacy tolerance -- it is correctness for the
        entries that already exist. Every entry in CHANGELOG.md and in every consumer's tree predates this
        table, and reading them as tier 0 would silently empty a release. So no table means: read the old
        line, report no scores, and let the gates decide whether scores were required.

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
    $headerPattern = '^\s*\|\s*' + [regex]::Escape($script:EntryImpactHeaders[0]) + '\s*\|\s*' +
        [regex]::Escape($script:EntryImpactHeaders[1]) + '\s*\|'

    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $headerPattern) { $start = $i; break }
    }

    if ($start -lt 0) {
        # No table: the pre-table shape. Read what those entries do carry.
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

        The line endings of everything kept are preserved rather than normalised -- the caller has already
        matched its document's style.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$EntryText)

    $headerPattern = '^\s*\|\s*' + [regex]::Escape($script:EntryImpactHeaders[0]) + '\s*\|\s*' +
        [regex]::Escape($script:EntryImpactHeaders[1]) + '\s*\|'

    # Split KEEPING the separators, so the original CRLF/LF of every kept line survives the round trip.
    $parts = [regex]::Split($EntryText, '(\r?\n)')
    $out = New-Object System.Collections.Generic.List[string]
    $inFence = $false
    $inTable = $false
    $done = $false
    $any = $false
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($i % 2 -eq 1) { continue }
        $line = $parts[$i]
        $sep = if ($i + 1 -lt $parts.Count) { $parts[$i + 1] } else { '' }

        if ($line -match '^\s*```') {
            $inFence = -not $inFence
            $inTable = $false
        } elseif (-not $inFence -and -not $done) {
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
    return [regex]::Replace($t, '(\r?\n)\1\1+', '$1$1')
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

        HIGHEST FIRST, AND A TIE KEEPS THE NEWER ENTRY ON TOP. The section is written newest-first, so equal
        scores preserve exactly what the fold did before ranking existed. An UNSCORED entry ($Score 0 -- a
        tier-0 section, an entry from before the table, or a repo with the ranking off) returns the offset
        the fold has always used: the top of the section. Nothing is ranked that was not asked to be.

        $Tier names which row to compare against, because a section's entries are ordered by what THAT
        section's reader gets out of them.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$SectionText,
        [int]$Score = 0,
        [int]$Tier = 1
    )
    $entryStarts = @([regex]::Matches($SectionText, '(?m)^### ') | ForEach-Object { $_.Index })
    if ($entryStarts.Count -eq 0) { return $SectionText.Length }
    # Unranked: the top of the section, below whatever intro precedes the first entry. Byte-identical to
    # the behaviour before this function existed.
    if ($Score -le 0) { return $entryStarts[0] }

    for ($i = 0; $i -lt $entryStarts.Count; $i++) {
        $start = $entryStarts[$i]
        $end = if ($i + 1 -lt $entryStarts.Count) { $entryStarts[$i + 1] } else { $SectionText.Length }
        $block = $SectionText.Substring($start, $end - $start)
        $existing = Get-EntryImpactScore -Impact (Resolve-EntryImpact -EntryText $block) -Tier $Tier
        # An unscored entry ALREADY in the changelog -- one written before the table existed -- reads as 0
        # and therefore sorts below everything scored, the same fail-safe direction as everywhere else here.
        # It cannot stop a fold: that entry is already merged, and refusing now would block an unrelated
        # branch over somebody else's line.
        #
        # '-le', not '-lt': an equal score puts the NEW entry above its equals, which preserves the
        # newest-first order the section already had. '-lt' would push it below them, silently reversing
        # that order for every tie -- and ties are the common case on a five-point scale.
        if ($existing -le $Score) { return $start }
    }
    return $SectionText.Length
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
