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

    .PARAMETER Changed
        [ref] set to $true when the returned body differs from the input.
    #>
    param(
        [string]$Body,
        [Parameter(Mandatory)][string]$Heading,
        [string]$Content,
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

    # Where the section ends: the next heading at $level or shallower, ignoring anything inside a fence.
    $end = $lines.Count
    $inFence = $false
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        $m = [regex]::Match($lines[$i], '^(#+)\s')
        if ($m.Success -and $m.Groups[1].Value.Length -le $level) { $end = $i; break }
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
