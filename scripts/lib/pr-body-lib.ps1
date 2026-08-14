<#
.SYNOPSIS
    Helpers for assembling and updating a Pull Request body from a changelog entry.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\pr-body-lib.ps1')

    Why this exists: open-pr.ps1 fills a fresh PR body by replacing the TEMPLATE PLACEHOLDER with the
    changelog entry's description. That works exactly once. On a resumed branch -- one whose PR is
    already open -- the placeholder is long gone, replaced by the previous description, so refreshing a
    rewritten entry needs a different operation: replace the section under a heading, leaving every
    other part of the body alone.

    Both functions here are PURE functions of their input -- no git, no gh, no filesystem -- so the
    suite (scripts/tests/pr-body.tests.ps1) can assert them without a remote. That split is not a
    nicety: open-pr.ps1 drives a live remote and carries a documented test gap, and the defect found in
    ship-pr.ps1 on August 4, 2026 was in an inline parse rather than in the orchestration the gap note
    excused. Anything in those scripts that is a pure function of text belongs here for that reason.

    Shared with the plugin mirror (registered in scripts/lib/shared-scripts-lib.ps1), because
    open-pr.ps1 is itself mirrored and dot-sources this file.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Get-EntryDescription {
    <#
    .SYNOPSIS
        The body of a changelog entry: everything after its compact '### title - type - date' heading.

    .DESCRIPTION
        The description open-pr.ps1 puts under "What does this change do?", extracted here so the fresh
        path and the refresh path read it the SAME way. It lived inline in open-pr.ps1 until August 4,
        2026; adding a second reader would have meant a second copy of the same rule, which is how this
        repo's accumulation bugs start.

        Only the FIRST '### ' line counts as the heading. An entry routinely contains further '###' or
        deeper headings in its own prose, and treating a later one as the boundary would silently cut the
        description short -- returning something plausible rather than failing, which is the worst shape.

        Returns '' when there is no heading, or nothing after it. The caller decides what that means:
        open-pr.ps1 leaves the placeholder in place rather than writing an empty description.
    #>
    param([string]$EntryText)

    if (-not $EntryText) { return '' }

    $lines = $EntryText -split "\r?\n"
    $h3 = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^###\s') { $h3 = $i; break }
    }
    if ($h3 -lt 0 -or ($h3 + 1) -ge $lines.Count) { return '' }

    return (($lines[($h3 + 1)..($lines.Count - 1)]) -join "`n").Trim()
}

function Get-PrDescription {
    <#
    .SYNOPSIS
        What a PR body should carry from an entry: the answer onwards, without the entry's front matter.

    .DESCRIPTION
        THE PR BODY IS NOT THE WHOLE DOSSIER (Dave, August 9, 2026). Get-EntryDescription returns
        everything after the entry's own heading, which is right for the fold -- CHANGELOG.md receives the
        dossier verbatim, front matter and all, and that was chosen deliberately. It is wrong for a PR,
        where the first three sections are answered by the page around the body:

          Branch title  -> IS the PR title, composed from this same section and shown above the body
          Branch ID     -> a creation timestamp; nothing a reviewer can act on
          Branch type   -> the PR's label, and the prefix of the title one line up

        So a reviewer opened a PR and met three restatements before the first sentence about the change.
        The trailing 'Pull Request' section goes for the mirror-image reason: the FOLD fills it, from the
        merge -- in a PR body it is a heading with nothing under it, every time, by construction.

        WHAT IS KEPT is the answer and the Significance sections. Significance is not front matter: it is
        the author saying how far the change reaches and what it is worth to each audience, which is
        exactly what a reviewer is deciding about.

        RETURNS '' WHEN THE 'What' SECTION IS ABSENT, and the caller falls back to Get-EntryDescription.
        That is the whole back-compat story: a pre-dossier entry has no such section (its description sat
        straight under the heading), and every consumer with a branch in flight is in that position --
        they reach this code through a plugin update rather than by choosing to. Returning '' rather than
        guessing keeps the old path exactly as it was.

        FENCE-AWARE, like every reader of this format: an entry documenting the entry format quotes these
        headings inside a fence, and the entry for this very change does. A fenced '### Significance'
        would otherwise cut the description off mid-sentence -- plausible output rather than a failure,
        which is the worst shape.

        Section names come from Get-EntrySectionHeadings / Get-EntrySectionRetiredNames when the
        scaffold lib is loaded (open-pr dot-sources both), so a repo that renamed or translated a heading
        is read by its own names. Probed with Get-Command rather than required, because this file is
        dot-sourced on its own by its suite -- the English defaults are the fallback, not a second
        definition: they are the same strings that lib ships.

    .PARAMETER EntryText
        The full text of the changelog entry file.
    #>
    param([string]$EntryText)

    if (-not $EntryText) { return '' }

    $whatNames = @('What does the change on this branch bring to main?', 'What does this change do?')
    $endNames  = @('Pull Request')
    if (Get-Command -Name Get-EntrySectionHeadings -ErrorAction SilentlyContinue) {
        $headings = Get-EntrySectionHeadings
        $whatNames = @($headings['What'])
        $endNames  = @($headings['PullRequest'])
        if (Get-Command -Name Get-EntrySectionRetiredNames -ErrorAction SilentlyContinue) {
            $whatNames += @(Get-EntrySectionRetiredNames -Key 'What')
            $endNames  += @(Get-EntrySectionRetiredNames -Key 'PullRequest')
        }
    }
    $whatNames = @($whatNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $endNames  = @($endNames  | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($whatNames.Count -eq 0) { return '' }

    $toPattern = {
        param($names)
        '^#{2,4}\s+(?:' + ((@($names) | ForEach-Object { [regex]::Escape([string]$_) }) -join '|') + ')\s*$'
    }
    $whatRx = & $toPattern $whatNames
    $endRx  = if ($endNames.Count -gt 0) { & $toPattern $endNames } else { $null }

    $lines = $EntryText -split "\r?\n"
    $start = -1
    $end = $lines.Count
    $inFence = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        $line = $lines[$i].TrimEnd()
        if ($start -lt 0) {
            if ($line -match $whatRx) { $start = $i }
            continue
        }
        if ($endRx -and $line -match $endRx) { $end = $i; break }
    }

    if ($start -lt 0 -or ($start + 1) -ge $end) { return '' }
    $slice = @($lines[($start + 1)..($end - 1)])

    # PROMOTED ONE LEVEL (Dave, August 9, 2026). In the entry file the sections are H3 and the tiers H4,
    # because the entry itself is an H2 -- it is one block among many in CHANGELOG.md. A PR body is not:
    # it is a document of its own, whose own title is the heading GitHub prints above it. Carrying the
    # entry's levels across left the body starting at H2 with tiers at H4, which reads as a fragment of
    # something larger, and it is:
    #
    #   in the entry / CHANGELOG.md          in a PR body
    #   ## `fix/x` changelog                 (the PR title, not part of the body)
    #   ### What does the change...          # What does the change...
    #   ### Significance                     ## Significance
    #   #### Tier 0                          ### Tier 0
    #
    # CHANGELOG.md and the release documents are untouched: this shifts the COPY that goes into the PR,
    # at the one point where that copy is made. The record keeps the levels the fold and the renderers
    # depend on.
    #
    # Fence-aware for the reason the boundary search above is, and floored at 1 -- a heading cannot be
    # promoted past H1, and a body that already starts at H1 is returned as it is rather than mangled.
    $inFence = $false
    $promoted = foreach ($line in $slice) {
        if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence; $line; continue }
        if ($inFence) { $line; continue }
        $m = [regex]::Match($line, '^(#+)(\s+\S.*)$')
        if ($m.Success -and $m.Groups[1].Value.Length -gt 1) {
            ('#' * ($m.Groups[1].Value.Length - 1)) + $m.Groups[2].Value
        } else {
            $line
        }
    }

    return ((@($promoted)) -join "`n").Trim()
}

function Get-PrTitle {
    <#
    .SYNOPSIS
        The PR title, composed: '<branch type>: <the entry's Branch title>'. '' when there are no words.

    .DESCRIPTION
        THE TITLE IS DERIVED, NOT TYPED (Dave, #506 + #505, August 7, 2026). It used to be given twice --
        once to new-branch.ps1, which writes it into the entry, and again to open-pr.ps1 -Title at the end
        of the branch -- with nothing holding the two together. One of them is what CHANGELOG.md and the
        release documents carry; the other is what the PR is called; and which one a reader met depended on
        where they were standing.

        The type half is the same repair from the other side. Derek's manual has always said the title reads
        '<branch-type>: ...', and measured on August 7, 2026 the last FIVE merged PRs (#499-#503) all
        violated it -- a rule that lives in a document, is never measured, and is therefore silently broken.
        Composing it here means it cannot be omitted and cannot contradict the branch: the type comes off the
        branch prefix, which is the same source as the PR's label and the entry's own type section.

        PURE, and given the words rather than the entry text, so this stays a function of two strings. The
        caller reads the section (Get-EntrySectionAnswer -Key 'Description'), which is the reader that
        already knows about retired heading names -- duplicating that here would be a second definition of
        where the title lives.

        THE FIRST NON-EMPTY LINE WINS, with its inner whitespace collapsed. A title is one line by nature and
        the section is free-form markdown; a two-line answer would otherwise reach `gh pr create --title`
        with a newline in it.

        NO PREFIX IS STRIPPED, deliberately. A title already reading 'fix: ...' would compose to
        'fix: fix: ...', and the guard for that is three lines. Measured before leaving it out: of every entry
        in CHANGELOG.md and the release record, NOT ONE title carries a type prefix -- the convention has
        always been to write the words alone. Building the strip would be guarding a defect that has never
        happened, and a stripper that guesses at prefixes is how a legitimate title like 'sync-roster: ...'
        gets mangled. Named here rather than repaired: if it ever does happen, this is the note to come back to.

        THE WORDS MAY COME FROM A PRE-SPLIT ENTRY'S HEADING, which is why the caller passes them rather than
        this reading the section itself. An entry written before the dossier form has NO title section at
        all -- its title WAS the heading -- and every consumer with such a branch in flight receives these
        scripts through a plugin update rather than by choosing to. Refusing them would turn a branch that worked
        yesterday into a stop at the PR. Recognise both, write one.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Prefix,
        [Parameter(Mandatory)][AllowEmptyString()][string]$TitleWords
    )

    $words = ''
    foreach ($line in ($TitleWords -split "\r?\n")) {
        if (-not [string]::IsNullOrWhiteSpace($line)) { $words = $line.Trim(); break }
    }
    $words = [regex]::Replace($words, '\s+', ' ')
    if (-not $words) { return '' }

    # AN EMPTY PREFIX YIELDS THE WORDS ALONE, which is how the caller says "this branch's prefix is not one
    # of ours": open-pr passes '' for an unknown prefix, warns about it, and labels the PR 'question'.
    # Putting that unknown word in front of the title would state a type no table backs.
    if ([string]::IsNullOrWhiteSpace($Prefix)) { return $words }
    return ($Prefix.Trim() + ': ' + $words)
}

function Update-PrBodySection {
    <#
    .SYNOPSIS
        Replaces the content under one heading of a PR body, leaving the rest of the body untouched.

    .DESCRIPTION
        The section runs from the heading line to the next heading AT THE SAME LEVEL OR HIGHER, or to the
        end of the body. Same-level-or-higher rather than "the next heading of any kind" is the whole
        subtlety: a description may contain its own deeper headings, and stopping at the first of those
        would leave half the old description stranded below the new one -- a body that reads as though it
        says two things.

        THE LEVEL RULE ALONE IS NOT ENOUGH WHEN THE SECTION IS AN H1 (inbound #598), and that is what
        -StopAtHeading is for. At level 1 "the same level or higher" can only ever match another H1, so
        every '##' section that follows is by definition nested inside the description and gets replaced
        along with it. Measured in a consumer: a template whose description sits under an H1 lost its one
        repo-specific section -- heading, guidance and both checkboxes -- on every -RefreshBody, reported
        as "updated the description" and nothing else.

        The reasoning above stays right, which is why this is an extra boundary rather than a different
        one: a description CAN contain its own deeper headings, so the level rule cannot simply be
        loosened to "the next heading of any kind". What the caller knows and this function cannot is
        which headings belong to the FORM rather than to the description -- so it passes them in.

        Fenced code is skipped when looking for the boundary, because a description explaining this
        mechanism will contain a '##' inside a fence. Not hypothetical: this repo's own entry for this
        feature does.

        Returns the body UNCHANGED and reports it via -Changed when the heading is absent or the content
        already matches, so a caller can skip the API call entirely rather than publishing a no-op edit.

    .PARAMETER Body
        The current PR body.

    .PARAMETER Heading
        The literal heading line, e.g. '## What does this change do?'. Matched at the start of a line,
        whole-line, so a heading quoted mid-sentence elsewhere in the body cannot be mistaken for it.

    .PARAMETER Content
        The replacement content for that section, without the heading.

    .PARAMETER StopAtHeading
        Extra literal heading lines that also end the section, whatever their level -- the form's own
        later headings. NARROWING ONLY: the section ends at the EARLIEST of these and the level rule, so
        passing them can shorten what is replaced and never lengthen it. That is what makes the parameter
        safe to add to a shared function -- a caller that passes nothing gets byte-identical behaviour to
        before, and one that passes a heading the body does not contain gets the same.

    .PARAMETER Changed
        [ref] set to $true when the returned body differs from the input.
    #>
    param(
        [string]$Body,
        [Parameter(Mandatory)][string]$Heading,
        [string]$Content,
        [string[]]$StopAtHeading = @(),
        [ref]$Changed
    )

    if ($null -ne $Changed) { $Changed.Value = $false }
    if (-not $Body) { return $Body }

    # EMPTY CONTENT IS A NO-OP, NOT AN INSTRUCTION TO CLEAR THE SECTION. There is no reason to want a
    # blank description, while there are several ways to arrive here with nothing: an entry with no body,
    # a heading that did not parse, or a failed read upstream. On August 4, 2026 exactly that shape --
    # a string operation quietly yielding nothing -- published an EMPTY PR body by hand, so the rule is
    # that this function cannot be the thing that removes text without putting text back. Caught by its
    # own suite before it shipped.
    if (-not $Content -or -not $Content.Trim()) { return $Body }

    $nl = if ($Body.Contains("`r`n")) { "`r`n" } else { "`n" }
    $lines = $Body -split "\r?\n"

    # The heading's own level, so the boundary search knows what counts as "the next section".
    $level = ([regex]::Match($Heading, '^(#+)')).Groups[1].Value.Length
    if ($level -eq 0) { return $Body }

    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimEnd() -eq $Heading.TrimEnd()) { $start = $i; break }
    }
    if ($start -lt 0) { return $Body }

    # Where the section ends: the EARLIEST of two boundaries, ignoring anything inside a fence --
    #   1. the next heading at $level or shallower (the original rule, right for a nested description);
    #   2. any heading the caller named in -StopAtHeading, at whatever level (the form's own sections,
    #      which an H1 description would otherwise swallow whole -- inbound #598).
    # Whichever comes first wins, so the second can only ever shorten the section.
    $stops = @(@($StopAtHeading) | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.TrimEnd() })
    $end = $lines.Count
    $inFence = $false
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        $m = [regex]::Match($lines[$i], '^(#+)\s')
        if (-not $m.Success) { continue }
        if ($m.Groups[1].Value.Length -le $level) { $end = $i; break }
        if ($stops -contains $lines[$i].TrimEnd()) { $end = $i; break }
    }

    $before = if ($start -gt 0) { $lines[0..($start - 1)] } else { @() }
    $after  = if ($end -lt $lines.Count) { $lines[$end..($lines.Count - 1)] } else { @() }

    $middle = @($Heading.TrimEnd())
    if ($Content) { $middle += ($Content.Trim() -split "\r?\n") }
    # One blank line before the next section, and only when there IS a next section.
    if ($after.Count -gt 0) { $middle += '' }

    $rebuilt = (@($before) + $middle + @($after)) -join $nl
    if ($rebuilt -ne $Body -and $null -ne $Changed) { $Changed.Value = $true }
    return $rebuilt
}

function Get-LostBodyHeadings {
    <#
    .SYNOPSIS
        The headings present in a PR body that are absent from the version about to replace it.

    .DESCRIPTION
        THE SIGNAL A SILENT SECTION LOSS NEEDS (inbound #598). -RefreshBody deleted a whole template
        section along with the description and reported only "the description was updated" -- so the
        recovery depended on somebody running 'gh pr view' days later and noticing. A green PR with a
        complete-LOOKING body is exactly the state in which nobody re-reads the form.

        THE SUBJECT IS A HEADING THAT DISAPPEARED, NOT A BODY THAT GOT SHORTER, and that choice is the
        whole reason this is checkable rather than noisy. A refresh legitimately shrinks a body every time
        the new description is shorter than the old one, so a size rule would fire on the common case and
        be switched off within a week. A section that was there and is now gone is never something this
        script intends.

        Pure and level-agnostic, and fence-aware for the same reason every other reader here is: a body
        explaining the form quotes the form's headings, and a quotation is not a section.

        Returns an array of the lost heading lines, in the order the old body had them. Empty means
        nothing was lost -- which after #598's fix is the expected answer, so this survives as a tripwire
        for the next shape nobody predicted rather than as a routine condition.
    #>
    param(
        [AllowEmptyString()][string]$Before,
        [AllowEmptyString()][string]$After
    )

    $headings = {
        param([string]$text)
        if (-not $text) { return @() }
        $inFence = $false
        return @($text -split "\r?\n" | ForEach-Object {
            if ($_ -match '^\s*(```|~~~)') { $inFence = -not $inFence; return }
            if (-not $inFence -and $_ -match '^#{1,6}\s+\S') { $_.TrimEnd() }
        })
    }

    $kept = @(& $headings $After)
    return @(@(& $headings $Before) | Where-Object { $kept -notcontains $_ })
}

function Get-PrDescriptionPlaceholderDefaults {
    <#
    .SYNOPSIS
        The template placeholder lines open-pr.ps1 replaces with the entry's description, when the repo
        defines no Get-PrDescriptionPlaceholder of its own.

    .DESCRIPTION
        RECOGNISE FOUR, WRITE ONE. The last is what this family's template carries now (the entry path
        moved under workflow-davekjohn/ on August 14, 2026); the older
        strings stay because a consumer's PR template is THEIR file, and this script must not silently
        stop filling it in because the template it ships beside moved on. An unrecognised placeholder is
        a PR body with no description at all -- the outcome this list exists to prevent.

        MOVED OUT OF open-pr.ps1 ON AUGUST 10, 2026, and the move is the point rather than tidiness
        (#573). While the list lived inline in the script, nothing else in the repo could read it -- so
        the reference template shipped with the plugin could not be held against it, and a reference
        whose placeholder open-pr does not recognise is exactly the defect that issue reported from a
        consumer: twelve merged PRs with no description, found by diffing templates months later.
        A gate needs the list; the list therefore lives where a gate can reach it.

        Ordered oldest first, with the written one last, so Get-PrTemplateCanonicalPlaceholder can take
        it from the end rather than by repeating the string.
    #>
    return @(
        '<!-- Korte beschrijving van wat er verandert en waarom. -->',
        '<!-- Short description of what changes and why. -->',
        "<!-- Filled from branch/branch-changelog.md. Opening a PR by hand? Paste that file's body here. -->",
        "<!-- Filled from workflow-davekjohn/branch/branch-changelog.md. Opening a PR by hand? Paste that file's body here. -->"
    )
}

function Get-PrTemplateCanonicalPlaceholder {
    <#
    .SYNOPSIS
        The single placeholder line a NEW template should carry -- the one of the recognised set that is
        written rather than merely accepted.

    .DESCRIPTION
        Taken from the end of the recognised list rather than written out again here, so the reference
        template and the matcher cannot disagree about it. That is the whole mechanism: a second literal
        would be free to drift, and drift between those two is the defect #573 was filed about.
    #>
    $defaults = @(Get-PrDescriptionPlaceholderDefaults)
    return $defaults[$defaults.Count - 1]
}

function Get-PrTemplateReference {
    <#
    .SYNOPSIS
        The canonical PR-template body this family ships as a reference, as an array of lines.

    .DESCRIPTION
        TWO LINES, AND THE SECOND ONE IS THE CONTRACT. Everything open-pr.ps1 needs from a PR template
        is here: a first heading (any level -- that is the one -RefreshBody replaces the description
        under) and a placeholder line the matcher recognises. The placeholder is taken from
        Get-PrTemplateCanonicalPlaceholder rather than written out, so the reference cannot ship a line
        the matcher would walk past.

        WHY IT IS ONLY TWO LINES, kept here because the next repo to ask should re-run the measurement
        rather than inherit the answer. This family's template carried a "Type of change" block and a
        six-item checklist until August 9, 2026. Measured over 60 PRs before anything was removed:
        "Type of change" had exactly one of four boxes ticked every single time -- a fact the entry
        already states under '### Branch type', and which the GitHub label takes from Get-BranchInfo
        rather than from the tick -- while of the checklist two items were ticked 60/60 (by this script)
        and two were ticked 0/60 by anyone, ever, though both were already enforced by gates that block
        the PR. A box that is always ticked and a box that is never ticked carry the same information.
        So the rule is "keep what is neither restated by the entry nor proven by a gate", and in this
        repo nothing survived it. IN YOURS SOMETHING MAY: the consumer that reported #573 re-ran the
        same measurement over their own 60 PRs and found one box of eight that genuinely varied -- a
        preview-URL approval, on a repo whose result has to be judged by eye, which no gate can prove.
        They kept it, correctly. The measurement travels; the answer does not.

        NO '## Specific to this repo' SLOT IS PRE-WRITTEN, unlike CONTRIBUTING-portable.md, and the
        difference is what the file is: a contributing guide is read once, while every heading in a PR
        template is repeated in every PR body forever. An empty slot would be a permanent empty section
        in your PR list. Add one when you have something to put in it.
    #>
    return @(
        '# What does the change on this branch bring to main?',
        (Get-PrTemplateCanonicalPlaceholder)
    )
}
