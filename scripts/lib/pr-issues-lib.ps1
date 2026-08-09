<#
.SYNOPSIS
    Helpers for the issue-closing contract of a Pull Request (the -Resolves gate in open-pr.ps1).

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\pr-issues-lib.ps1')

    Why this exists: PRs #341, #342 and #343 each repaired issues and each referenced them as a
    PLAIN mention (`#332`) instead of a closing keyword (`Closes #332`). GitHub only auto-closes on
    the keyword, and the manual `gh issue close` was skipped all three times -- so eight repaired
    findings sat OPEN while the changelog said they were done. The instance was cleaned up by hand;
    this lib is the class being closed (Dave's standing rule: build the gate, not just the fixes).

    Everything here is a PURE function of its input -- no git, no gh, no filesystem -- so the suite
    (scripts/tests/pr-issues.tests.ps1) can assert the whole decision table without a live remote.
    The one part that cannot be pure (asking GitHub which issues are still open) stays in the caller.

    Shared with the plugin mirror (registered in scripts/lib/shared-scripts-lib.ps1), because
    open-pr.ps1 is itself mirrored and dot-sources this file.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

# GitHub's own closing keywords, as accepted in a PR body. Kept in one place so the writer
# (New-ResolvesBlock) and the recogniser (Test-HasClosingKeyword) cannot drift apart -- a
# hand-mirrored literal is exactly what produced the accumulation bugs this repo keeps finding.
$script:PrClosingKeywords = @(
    'close', 'closes', 'closed',
    'fix', 'fixes', 'fixed',
    'resolve', 'resolves', 'resolved'
)

function Get-PrClosingKeywords {
    <# The closing keywords GitHub honours in a PR body, lowercase. #>
    return $script:PrClosingKeywords
}

function Remove-MarkdownCodeSpans {
    <#
    .SYNOPSIS
        Blanks out fenced code blocks and inline code spans, so a reference inside them is not read
        as a live reference.

    .DESCRIPTION
        This is not a convenience -- it is what makes the recognisers AGREE WITH GITHUB. GitHub does
        not autolink `#332` inside a code span or fence, and a closing keyword only closes something
        it can link, so text inside backticks closes nothing there either.

        The bug that forced this: a document explaining the gate necessarily writes the pattern it is
        explaining. This repo's own changelog entry for the gate contains the literal
        "`Closes #331, #332`" as prose about GitHub's comma behaviour -- and open-pr.ps1 copies the
        whole entry body verbatim into the PR body. Without this stripping, the recogniser read that
        example as a real declaration: the PR would report "closes #331", and ship-pr.ps1's
        post-merge step would then force-close #331 with a comment crediting a PR that has nothing to
        do with it. Documenting a feature must not trigger it.

        Replaced with a run of '|' of the same length -- not removed, and deliberately not spaces.
        Removal would let the text on either side join into a new match, and SPACES would leave a
        keyword and a reference looking adjacent across the gap: 'Closes `x` #332' would blank to
        'Closes     #332' and read as a live declaration, while GitHub (which needs the keyword
        immediately before the reference) closes nothing there. '|' is neither a word character nor
        whitespace, so it blocks that false adjacency without hiding a reference that follows it
        directly.
    #>
    param([string]$Text)

    if (-not $Text) { return '' }

    $out = $Text
    # Fences first (``` ... ``` and ~~~ ... ~~~), then inline spans of any backtick run length.
    $out = [regex]::Replace($out, '(?ms)^[ \t]*(```|~~~).*?^[ \t]*\1[ \t]*$', { '|' * $args[0].Length })
    $out = [regex]::Replace($out, '(`+)[^`]*?\1', { '|' * $args[0].Length })
    return $out
}

function ConvertTo-IssueNumberList {
    <#
    .SYNOPSIS
        Parses a caller-supplied issue list ('331,332', '#331 #332') into a sorted unique int array.

    .DESCRIPTION
        Why the callers take a STRING and not an [int[]]: an [int[]] parameter is unusable across
        `powershell -File`, which is how ship-pr.ps1 invokes open-pr.ps1 and how the test fixtures
        run it. That parser hands every token over as a string and never builds an array, so
        `-Resolves 332,340` arrives as the single string '332,340' -- which PowerShell then casts to
        an int by reading the comma as a THOUSANDS SEPARATOR, yielding 332340. Not an error: a
        silently wrong single issue number, measured on Windows PowerShell 5.1 while building this
        gate. `-Resolves 332 340` is no better (it binds only the first token).

        So parsing is done here, deliberately, and it is liberal about the separator (comma,
        whitespace, semicolon) and about a leading '#'. Anything that is not a positive number is
        ignored, so a stray word cannot become issue 0.
    #>
    param([string]$Value)

    if (-not $Value) { return @() }

    $numbers = New-Object System.Collections.Generic.List[int]
    foreach ($m in [regex]::Matches($Value, '\d+')) {
        $n = 0
        if ([int]::TryParse($m.Value, [ref]$n) -and $n -gt 0) { $numbers.Add($n) }
    }
    return @($numbers | Sort-Object -Unique)
}

function Get-IssueMentions {
    <#
    .SYNOPSIS
        The issue numbers a text mentions, as a sorted unique int array.

    .DESCRIPTION
        Finds `#<n>` and `.../issues/<n>` references. Deliberately EXCLUDES pull-request
        references, because a changelog entry routinely cites the PR it follows on from
        ("as PR #341 established for this class") and treating those as issues would make the
        gate cry wolf on almost every branch:
          - `PR #341` / `pull request #341` (the prose form),
          - `PRs #341-#343` / `PRs #341, #342 and #343` (a PLURAL head followed by a list), and
          - `.../pull/341` (the link form).
        A bare `#341` IS returned: from the text alone it is indistinguishable from an issue, and
        the caller resolves the ambiguity by asking GitHub which numbers are open issues.

        Where the two error directions collide, this errs toward RETURNING a number. A missed mention
        means the gate never fires, which is the silent-open-issue bug the gate exists to prevent; a
        surplus mention only means the gate asks a question the author answers once. That is why the
        list scrub below requires a plural head -- see the comment on it.
    #>
    param([string]$Text)

    if (-not $Text) { return @() }

    # A reference inside backticks is not a live reference on GitHub either.
    $scrubbed = Remove-MarkdownCodeSpans -Text $Text

    # Blank out the forms that are demonstrably PRs before scanning for mentions, so a single
    # regex pass cannot pick them up again. ORDER MATTERS: the multi-number forms go first, because
    # scrubbing 'PRs #341' out of 'PRs #341-#343' would leave a bare '-#343' behind, which the
    # mention pass then reads as an issue -- a false positive the suite caught.
    #
    # The comma/'and' continuation is accepted ONLY after a PLURAL head ('PRs', 'pull requests').
    # After a singular head it is not: in 'PR #341 and #332' nothing marks #332 as a PR, and
    # swallowing it made a real open issue invisible to the gate (found in review). A dash range or
    # 'to'/'through' IS unambiguous, so that continuation is scrubbed after either head.
    $scrubbed = [regex]::Replace($scrubbed, '(?i)\b(pull\s*requests|PRs)\s*(#\s*\d+)(\s*(?:[-–—,]|and|to|through)\s*#\s*\d+)+', ' ')
    $scrubbed = [regex]::Replace($scrubbed, '(?i)\b(pull\s*requests?|PRs?)\s*(#\s*\d+)(\s*(?:[-–—]|to|through)\s*#\s*\d+)+', ' ')
    $scrubbed = [regex]::Replace($scrubbed, '(?i)\bpull\s*requests?\s*#\s*\d+', ' ')
    $scrubbed = [regex]::Replace($scrubbed, '(?i)\bPRs?\s*#\s*\d+', ' ')
    $scrubbed = [regex]::Replace($scrubbed, '(?i)/pull/\d+', ' ')

    $numbers = New-Object System.Collections.Generic.List[int]

    # The lookbehind excludes only a word character, NOT '/'. It used to exclude '/' as well, which
    # silently dropped every number after the first in a slash-separated list ('#334/#329/#335'
    # yielded 334 alone) -- found in review, and precisely the failure mode the gate is built to
    # prevent. URL forms are already handled: /pull/<n> is scrubbed above and /issues/<n> is matched
    # separately below, so '/' needs no guard here.
    foreach ($m in [regex]::Matches($scrubbed, '(?<!\w)#(\d+)\b')) {
        $numbers.Add([int]$m.Groups[1].Value)
    }
    foreach ($m in [regex]::Matches($scrubbed, '(?i)/issues/(\d+)\b')) {
        $numbers.Add([int]$m.Groups[1].Value)
    }

    return @($numbers | Sort-Object -Unique)
}

function Test-HasClosingKeyword {
    <#
    .SYNOPSIS
        $true when a text already carries a GitHub closing keyword against an issue number.

    .DESCRIPTION
        Lets a hand-written -Body that already says `Closes #332` satisfy the gate on its own,
        instead of forcing the author to repeat the decision as a parameter. Matches the keyword
        immediately before the reference, which is the only form GitHub itself honours -- so this
        recogniser cannot report a body as closing something GitHub will leave open.
    #>
    param([string]$Text)

    if (-not $Text) { return $false }
    # Code spans stripped first: GitHub does not link a reference inside backticks, so it closes
    # nothing there -- and a doc explaining this gate has to write the pattern it explains.
    $clean = Remove-MarkdownCodeSpans -Text $Text
    $kw = (Get-PrClosingKeywords) -join '|'
    return [bool][regex]::IsMatch($clean, "(?i)\b($kw)\s*:?\s+(#\d+|https?://\S+/issues/\d+)")
}

function Get-ClosedIssueNumbers {
    <#
    .SYNOPSIS
        The issue numbers a text closes via a closing keyword, as a sorted unique int array.

    .DESCRIPTION
        The counterpart of Test-HasClosingKeyword: not "does it close something" but "which ones".
        Used to report, after a merge, exactly which issues GitHub was asked to close -- so the
        verification step checks the same set the body actually declared, never a set assembled
        a second time (a second tally is how the #275 preview/apply drift started).
    #>
    param([string]$Text)

    if (-not $Text) { return @() }
    # Same code-span stripping as Test-HasClosingKeyword, and for the same reason: this function
    # decides which issues ship-pr.ps1 will force-close after a merge, so a prose example must never
    # reach it. Without this, the gate's own changelog entry made it credit a close to the wrong PR.
    $clean = Remove-MarkdownCodeSpans -Text $Text
    $kw = (Get-PrClosingKeywords) -join '|'
    $numbers = New-Object System.Collections.Generic.List[int]

    foreach ($m in [regex]::Matches($clean, "(?i)\b($kw)\s*:?\s+#(\d+)\b")) {
        $numbers.Add([int]$m.Groups[2].Value)
    }
    foreach ($m in [regex]::Matches($clean, "(?i)\b($kw)\s*:?\s+https?://\S+/issues/(\d+)\b")) {
        $numbers.Add([int]$m.Groups[2].Value)
    }

    return @($numbers | Sort-Object -Unique)
}

function Get-ExistingPrRecord {
    <#
    .SYNOPSIS
        The first PR record in a `gh pr list --json number,url,body` payload, or $null when there is none.

    .DESCRIPTION
        open-pr.ps1 asks gh whether the current branch already has an open PR, and the answer decides
        two things: whether an existing body's closing keywords count as a declaration, and whether
        `gh pr create` runs at all. Parsing it lives HERE, as a pure function of the JSON text, because
        the caller drives a live remote and cannot be covered by a suite -- while this can.

        THE PARSE IS THE PART THAT NEEDS A TEST, not the query. Windows PowerShell 5.1 hands a parsed
        JSON array to the pipeline as a SINGLE object, so `@($text | ConvertFrom-Json)` collects one
        element that IS the whole Object[]; and indexing the result with [0] returns $null on an empty
        list rather than failing, which is a wrong answer that looks like a right one. Both shapes have
        already cost this repo a silent bug (see Get-OpenIssueNumbers's caller). So: assign first, wrap
        second, and require a `number` before believing a record.

        Returns $null for empty input, an empty list, unparseable JSON, or records without a number --
        every one of which the caller must treat as "no existing PR", never as an error.
    #>
    param([string]$Json)

    if (-not $Json -or -not $Json.Trim()) { return $null }

    try {
        $parsed = $Json | ConvertFrom-Json
    } catch {
        return $null
    }

    return (@($parsed) | Where-Object { $_ -and $_.number } | Select-Object -First 1)
}

function New-ResolvesBlock {
    <#
    .SYNOPSIS
        The markdown block that makes GitHub close the given issues when the PR merges.

    .DESCRIPTION
        ONE closing keyword per issue, one per line. This is not a style choice: GitHub does not
        distribute a single keyword over a list, so `Closes #331, #332` closes only #331 and leaves
        the second silently open -- the exact failure mode this whole gate exists to prevent.
        Returns '' for an empty set, so a caller can append unconditionally.

    .PARAMETER Issues
        The issue numbers this PR closes. Non-positive numbers are ignored; duplicates collapse.

    .PARAMETER Level
        The heading level of the block, defaulting to 2 -- what every body carried before the PR body's
        headings were promoted (Dave, August 9, 2026). It is a PARAMETER rather than a constant because
        the block must be a SIBLING of the description, not a child of it, and that is not decoration:
        -RefreshBody replaces the description section by scanning forward to the next heading at the
        description's level or shallower. A body whose description is H1 with a '## Resolved issues'
        under it would have its closing keywords SWALLOWED by the next refresh -- the block deleted,
        GitHub closing nothing at the merge, which is the #341-#343 failure arriving through the door
        that was built to prevent it. Add-ResolvesBlock reads the level off the body rather than making
        the caller state it, so a consumer whose template is still H2 keeps an H2 block.
    #>
    param(
        [int[]]$Issues,
        [ValidateRange(1, 6)][int]$Level = 2
    )

    $unique = @($Issues | Where-Object { $_ -gt 0 } | Sort-Object -Unique)
    if ($unique.Count -eq 0) { return '' }

    $lines = @((('#' * $Level) + ' Resolved issues'), '')
    foreach ($n in $unique) { $lines += "Closes #$n" }
    return ($lines -join "`n")
}

function Add-ResolvesBlock {
    <#
    .SYNOPSIS
        Appends the closing block to a PR body, separated by a blank line.

    .DESCRIPTION
        Idempotent per issue: a number the body already closes is not added a second time, so
        re-running against an already-annotated body is a no-op rather than a duplicate block.

        THE BLOCK MATCHES THE BODY'S OWN TOP LEVEL, read off its first heading outside a fence. Derived
        rather than passed, because this is called from three places on two paths (a fresh auto-filled
        template, a caller-supplied -Body, and an already-open PR's published body) and each of those can
        legitimately differ: this repo's template is H1 since August 9, 2026, a consumer's is still H2,
        and a hand-written -Body is whatever its author wrote. Reading the answer off the text is the
        only form that is right for all three without a knob anyone has to remember to set.

        Why it matters is in New-ResolvesBlock's -Level: a block deeper than the description is inside
        it, and the next -RefreshBody deletes it along with the description it replaces.
    #>
    param(
        [string]$Body,
        [int[]]$Issues
    )

    $already = @(Get-ClosedIssueNumbers -Text $Body)
    $missing = @($Issues | Where-Object { $_ -gt 0 -and $already -notcontains $_ } | Sort-Object -Unique)

    $level = 2
    $inFence = $false
    foreach ($line in ($Body -split "\r?\n")) {
        if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        $m = [regex]::Match($line, '^(#+)\s+\S')
        if ($m.Success) { $level = [Math]::Min(6, $m.Groups[1].Value.Length); break }
    }

    $block = New-ResolvesBlock -Issues $missing -Level $level
    if (-not $block) { return $Body }
    if (-not $Body) { return $block }

    return ($Body.TrimEnd() + "`n`n" + $block + "`n")
}

function Get-ResolvesDecision {
    <#
    .SYNOPSIS
        The gate's verdict: may this PR be opened, and with which closing block?

    .DESCRIPTION
        The whole decision table in one pure function, so the suite can assert every branch of it
        without a remote. The caller supplies what only it can know -- the explicit parameters, the
        body, and (optionally) which of the mentioned numbers GitHub reports as OPEN issues.

        Verdicts:
          - Explicit -Resolves          -> Allowed, Issues = those numbers.
          - Explicit -NoResolves        -> Allowed, Issues = @() (the author declared "closes nothing").
          - Body already closes issues  -> Allowed, Issues = the numbers the body declares.
          - Open issues mentioned, no decision -> BLOCKED, naming them.
          - Nothing open mentioned      -> Allowed, Issues = @() (nothing to decide).

    .PARAMETER OpenMentions
        The mentioned numbers that are OPEN issues right now. $null means "could not be determined"
        (gh unavailable or failing), which deliberately does NOT block: a gate that wedges the PR
        flow on a network hiccup would be worse than the bookkeeping slip it guards against. The
        caller warns in that case.
    #>
    param(
        [int[]]$Resolves = @(),
        [switch]$NoResolves,
        [string]$Body = '',
        [int[]]$OpenMentions = $null
    )

    $explicit = @($Resolves | Where-Object { $_ -gt 0 } | Sort-Object -Unique)
    $open = if ($null -eq $OpenMentions) { $null } else { @($OpenMentions | Where-Object { $_ -gt 0 } | Sort-Object -Unique) }

    # Undeclared = mentioned, open, and not covered by the decision. It never blocks -- deciding to
    # close only one of two mentioned issues is legitimate -- but it is REPORTED, because the whole
    # point of the gate is that an open issue never passes in silence. Found in review: a -Resolves
    # naming one of two open mentions used to make the second invisible, a partial recurrence of the
    # exact failure this gate was built for.
    function Get-Undeclared {
        param([int[]]$Declared)
        if ($null -eq $open) { return @() }
        return @($open | Where-Object { $Declared -notcontains $_ })
    }

    if ($explicit.Count -gt 0) {
        return [pscustomobject]@{
            Allowed    = $true
            Issues     = $explicit
            Reason     = 'explicit -Resolves'
            Blocked    = @()
            Undeclared = @(Get-Undeclared -Declared $explicit)
        }
    }

    if ($NoResolves) {
        return [pscustomobject]@{
            Allowed    = $true
            Issues     = @()
            Reason     = 'explicit -NoResolves'
            Blocked    = @()
            # Deliberately empty: -NoResolves IS the answer for every mentioned issue, so repeating
            # them as "undeclared" would turn an explicit decision back into a nag.
            Undeclared = @()
        }
    }

    $fromBody = @(Get-ClosedIssueNumbers -Text $Body)
    if ($fromBody.Count -gt 0) {
        return [pscustomobject]@{
            Allowed    = $true
            Issues     = $fromBody
            Reason     = 'the body already carries closing keywords'
            Blocked    = @()
            Undeclared = @(Get-Undeclared -Declared $fromBody)
        }
    }

    if ($null -eq $open) {
        return [pscustomobject]@{
            Allowed    = $true
            Issues     = @()
            Reason     = 'the open-issue state could not be determined -- not blocking'
            Blocked    = @()
            Undeclared = @()
        }
    }

    if ($open.Count -gt 0) {
        return [pscustomobject]@{
            Allowed    = $false
            Issues     = @()
            Reason     = 'open issues are mentioned but the PR declares neither -Resolves nor -NoResolves'
            Blocked    = $open
            Undeclared = @()
        }
    }

    return [pscustomobject]@{
        Allowed    = $true
        Issues     = @()
        Reason     = 'no open issue is mentioned'
        Blocked    = @()
        Undeclared = @()
    }
}
