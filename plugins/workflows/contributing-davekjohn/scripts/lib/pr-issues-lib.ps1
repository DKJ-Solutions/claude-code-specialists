<#
.SYNOPSIS
    Helpers for what a Pull Request's own machinery has to read: the issue-closing contract (the
    -Resolves gate in open-pr.ps1) and the check ordering behind ship-pr.ps1's merge wait.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\pr-issues-lib.ps1')

    Why this exists: PRs #341, #342 and #343 each repaired issues and each referenced them as a
    PLAIN mention (`#332`) instead of a closing keyword (`Closes #332`). GitHub only auto-closes on
    the keyword, and the manual `gh issue close` was skipped all three times -- so eight repaired
    findings sat OPEN while the changelog said they were done. The instance was cleaned up by hand;
    this lib is the class being closed (Dave's standing rule: build the gate, not just the fixes).

    The second group (Get-CheckWaitReport and its three helpers) arrived for the same reason from the
    other end: ship-pr.ps1 drives `gh pr checks --watch` against a live remote, and issue #831 asked
    for the wait to SAY which check governed it. The query cannot be tested and the selection can, so
    the selection lives here -- see that function's own header for the measurement behind it.

    Everything here is a PURE function of its input -- no git, no gh, no filesystem -- so the suite
    (scripts/tests/pr-issues.tests.ps1) can assert the whole decision table without a live remote.
    The parts that cannot be pure (asking GitHub which issues are still open, and asking it for the
    check timestamps) stay in the callers.

    Shared with the plugin mirror (registered in scripts/lib/shared-scripts-lib.ps1), because
    open-pr.ps1 and ship-pr.ps1 are both mirrored and dot-source this file.

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
    #
    # THE DASH CLASS IS COMPOSED FROM CODE POINTS, so this source stays pure ASCII. That is the repo's
    # rule for the script layer, not a style choice: Windows PowerShell 5.1 reads a BOM-less .ps1 as the
    # system ANSI code page, so a literal U+2013 written here decodes as TWO CP1252 characters -- and it
    # does so silently, because a mis-decoded string is still a string. Inside a character class that
    # does not throw, it WIDENS the class, which is a wrong answer rather than a failure. These two
    # patterns are therefore double-quoted so the composed variable interpolates; neither carries a '$'
    # of its own, so nothing else does. check-plugin-integrity's [script-ascii] check holds every .ps1
    # in the tree to this, and scripts/tests/pr-issues.tests.ps1 exercises both dashes so a silent
    # regression in this composition cannot pass the gate.
    $dashes = '-' + [char]0x2013 + [char]0x2014
    $scrubbed = [regex]::Replace($scrubbed, "(?i)\b(pull\s*requests|PRs)\s*(#\s*\d+)(\s*(?:[$dashes,]|and|to|through)\s*#\s*\d+)+", ' ')
    $scrubbed = [regex]::Replace($scrubbed, "(?i)\b(pull\s*requests?|PRs?)\s*(#\s*\d+)(\s*(?:[$dashes]|to|through)\s*#\s*\d+)+", ' ')
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

function Get-PrCreateFailureReason {
    <#
    .SYNOPSIS
        The reason `gh pr create` gave for failing, out of its captured output -- or '' when it gave none.

    .DESCRIPTION
        open-pr.ps1 replaced gh's own message with a fixed guess: "Creating the PR failed (is gh logged
        in?)". Measured in a consumer (inbound #1077) on a run where gh had just listed PRs, pushed and
        read the issue list in the same invocation -- so the one hypothesis the loudest line offered was
        the one thing that was demonstrably fine, while gh's actual answer ("No commits between main and
        <branch>") sat above it and got read as noise.

        THE LAST NON-EMPTY LINE IS THE REASON, and that is a fact about gh rather than a guess: it writes
        its progress line first ("Creating pull request for X into main in ...") and its failure last. A
        run that printed nothing at all -- gh missing, killed, or silent -- returns '', which is the one
        case where a hint about the environment is all the caller has.

        PURE, so the caller's message can be asserted without a remote. Same move and same reason as
        Get-ExistingPrRecord above it: the part that is a pure function of a command's answer becomes one.
    #>
    param([AllowNull()][string[]]$OutputLines)

    if ($null -eq $OutputLines) { return '' }
    $reason = ''
    foreach ($line in ($OutputLines | Where-Object { $_ -ne $null } | ForEach-Object { ([string]$_).Trim() })) {
        # Walked forwards and kept, rather than walked backwards: '@()' of a single string and of an
        # array behave differently enough under 5.1 that indexing from the end is the shape this repo has
        # already been bitten by. Keeping the last match needs no index at all.
        if ($line) { $reason = $line }
    }
    return $reason
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

function Format-CheckDuration {
    <#
    .SYNOPSIS
        A whole number of seconds as 'Xm YYs', or 'Ys' below a minute. '' for a negative input.

    .DESCRIPTION
        The shape every duration in this repo's release notes and measurements is already written in
        ('8m 37s', '14m 05s'), so a wait this script reports can be read next to those without anyone
        converting units. Seconds are zero-padded above a minute for the same reason: '9m 8s' and
        '9m 58s' do not line up in a column, '9m 08s' and '9m 58s' do.

        A negative input returns '' rather than a nonsense string, so a caller with nothing measured
        can concatenate unconditionally instead of branching. Zero returns '0s', because 0s is a real
        and (per issue #831) the MEDIAN answer here -- an empty string there would read as unmeasured.
    #>
    param([int]$Seconds)

    if ($Seconds -lt 0) { return '' }
    if ($Seconds -lt 60) { return "${Seconds}s" }
    return ('{0}m {1:d2}s' -f [int][math]::Floor($Seconds / 60), ($Seconds % 60))
}

function ConvertTo-CheckTimestamp {
    <#
    .SYNOPSIS
        One gh timestamp field as a UTC [datetime], or $null when it is absent or unreadable.

    .DESCRIPTION
        Deliberately accepts BOTH shapes, because which one arrives depends on the edition rather than
        on the payload: Windows PowerShell 5.1's ConvertFrom-Json converts an ISO-8601 string to a
        [datetime] on its own, while other editions can hand the string straight through. A caller that
        assumed either one would work on one machine and mis-read the ordering on the next -- and a
        mis-read ordering is exactly the defect the caller exists to correct.

        Parsed with InvariantCulture and AdjustToUniversal, so two checks are compared on the same clock
        regardless of the machine's locale. Returns $null rather than throwing: an unreadable timestamp
        means this record cannot take part in the ordering, which the caller handles.

        THE ZERO TIME IS UNREADABLE, and it is the third shape rather than a corner case. `gh pr checks
        --json completedAt` serialises a check that has NOT FINISHED YET as `0001-01-01T00:00:00Z` -- not
        as null, not as an empty string. Both branches below turn that into a real [datetime], which is
        not $null, so the caller's own "$null -eq $done" guard did not fire and the arithmetic after it
        ran against the floor of the type. Measured as issue #977 in a consumer repo: the [int] cast in
        Get-CheckWaitReport overflowed on -63,923,427,029 seconds and killed a ship-pr run AFTER it had
        printed `CI green.` and BEFORE the merge -- the PR unmerged, the entry unfolded, every check
        green. The wait step is the one place in the script that is guaranteed to be racing GitHub, so
        any check that registers while --watch is returning is in that window.

        Tested on the YEAR rather than on equality with [datetime]::MinValue, because the two are not the
        same test. A MinValue of Kind Unspecified sent through ToUniversalTime lands NEAR the floor and
        not on it -- clamped back to MinValue where the machine's offset is positive, shifted UP by the
        offset where it is negative -- so an equality test would hold in Amsterdam and miss in New York.
        No CI check ran in year 1.
    #>
    param($Value)

    if ($null -eq $Value) { return $null }

    $stamp = $null
    if ($Value -is [datetime]) {
        $stamp = $Value.ToUniversalTime()
    } else {
        $text = [string]$Value
        if (-not $text.Trim()) { return $null }
        try {
            $stamp = [datetime]::Parse(
                $text,
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::AdjustToUniversal)
        } catch {
            return $null
        }
    }

    if ($stamp.Year -le 1) { return $null }
    return $stamp
}

function ConvertTo-CheckSeconds {
    <#
    .SYNOPSIS
        A [timespan] between two check timestamps as a whole number of seconds an [int] can hold, or -1
        when it cannot -- the value Get-CheckWaitReport and Format-CheckDuration both read as unmeasured.

    .DESCRIPTION
        ROUND FIRST, RANGE-CHECK, CAST LAST. Exists because the reverse order was written twice, at both
        arithmetic sites in Get-CheckWaitReport, and `[int][math]::Round(...)` throws on an out-of-range
        double before any guard on the next line can look at it -- so the sanity check that WAS there
        ("if ($ran -lt 0) { $ran = -1 }") was unreachable by construction (issue #977).

        ConvertTo-CheckTimestamp above closes the door that defect actually came through, and this closes
        the class: a payload carrying a readable but absurd timestamp (a far-future completedAt) is still
        a span no [int] holds, from the same untrusted field, and it would reach the same cast. Returning
        -1 keeps the failure in the vocabulary the callers already speak, so a duration this cannot
        render is simply left out of the line instead of aborting the run that was printing it.
    #>
    param([timespan]$Span)

    $seconds = [math]::Round($Span.TotalSeconds)
    if ($seconds -lt 0 -or $seconds -gt [int]::MaxValue) { return -1 }
    return [int]$seconds
}

function Get-CheckWaitReport {
    <#
    .SYNOPSIS
        One line saying WHICH check governed a PR's merge wait and for how long, from a
        `gh pr checks --json` payload. $null when the payload cannot answer that.

    .DESCRIPTION
        ship-pr.ps1 waits for every check a PR has and reads the exit code. That is deliberate and does
        not change here -- but it made the wait invisible: a run printed gh's own table and nothing
        about the ordering, so learning which check had held it up meant opening the Actions page
        afterwards. Measured over n=100 paired runs in the source repo (issue #831), the non-required
        check governs the wait 23% of the time at a median cost of 0s -- a different answer from the one
        two individual observations had suggested, and the reason those two became a policy question at
        all is that nobody could see the ordinary case. This report is the ordinary case, printed.

        THE SELECTION IS THE PART THAT NEEDS A TEST, not the query -- the same split as
        Get-ExistingPrRecord above, for the same reason: the caller drives a live remote and no suite
        can reach it, while this can.

        IT NAMES NO CHECK OF ITS OWN. The governing check is whichever one finished LAST in the payload,
        and 'required' comes from `gh pr checks --required`, i.e. from the repo's own ruleset. A
        hardcoded name here would be a claim about a consumer's CI that this script cannot keep, which
        is what the step-3 comment in ship-pr.ps1 has said since it was written.

        Degrades to $null rather than guessing: empty or unparseable JSON, no record carrying a name, or
        no record with a readable completedAt. Without -RequiredNamesJson the line omits the
        required/not-required label entirely, because an unknown answer stated either way is worse than
        an unstated one.

    .PARAMETER ChecksJson
        `gh pr checks <pr> --json name,startedAt,completedAt` output (state/bucket may ride along).

    .PARAMETER RequiredNamesJson
        `gh pr checks <pr> --required --json name` output. Optional.

    .PARAMETER WaitedSeconds
        The wall-clock this script itself spent on step 3. Negative means unmeasured, and is then left
        out of the line rather than reported as zero.
    #>
    param(
        [string]$ChecksJson,
        [string]$RequiredNamesJson = '',
        [int]$WaitedSeconds = -1
    )

    if (-not $ChecksJson -or -not $ChecksJson.Trim()) { return $null }

    try { $parsed = $ChecksJson | ConvertFrom-Json } catch { return $null }

    # Assign first, wrap second -- 5.1 hands a parsed JSON array to the pipeline as ONE object.
    $records = @(@($parsed) | Where-Object { $_ -and $_.name })
    if ($records.Count -eq 0) { return $null }

    $finished = @()
    foreach ($r in $records) {
        $done = ConvertTo-CheckTimestamp -Value $r.completedAt
        if ($null -eq $done) { continue }

        $ran = -1
        $began = ConvertTo-CheckTimestamp -Value $r.startedAt
        if ($null -ne $began) { $ran = ConvertTo-CheckSeconds -Span ($done - $began) }
        $finished += [pscustomobject]@{ Name = [string]$r.name; Completed = $done; Ran = $ran }
    }
    if ($finished.Count -eq 0) { return $null }

    $governing = @($finished | Sort-Object -Property Completed -Descending)[0]

    $required = @()
    if ($RequiredNamesJson -and $RequiredNamesJson.Trim()) {
        try {
            # ASSIGN FIRST, WRAP SECOND -- the same 5.1 rule the ChecksJson parse above already follows,
            # and this parse did not until August 26, 2026. Inlined as
            # `@(@($RequiredNamesJson | ConvertFrom-Json) | ...)` it collapsed the whole payload into ONE
            # element, whose `.name` member-enumerates to every name at once: two required checks became
            # the single bogus string 'a b', so `-contains` never matched and the label read ', NOT
            # required' for a check that was required. It survived unseen because this repo's ruleset
            # requires exactly ONE check, and a one-element JSON array is handed through as the object
            # itself -- so the only shape anybody ran was the one shape that happens to work. Measured
            # both ways when Get-MergeBlockVerdict below hit the identical trap.
            $parsedRequired = $RequiredNamesJson | ConvertFrom-Json
            $required = @(@($parsedRequired) |
                Where-Object { $_ -and $_.name } |
                ForEach-Object { [string]$_.name })
        } catch {
            $required = @()
        }
    }

    $parts = @()
    if ($WaitedSeconds -ge 0) { $parts += "waited $(Format-CheckDuration -Seconds $WaitedSeconds)" }

    $label = ''
    $isRequired = $false
    if ($required.Count -gt 0) {
        $isRequired = $required -contains $governing.Name
        $label = if ($isRequired) { ', required' } else { ', NOT required' }
    }

    $ran = if ($governing.Ran -ge 0) { Format-CheckDuration -Seconds $governing.Ran } else { 'duration unknown' }
    $parts += "'$($governing.Name)' finished last and governed the merge ($ran$label)"

    # What waiting on a non-required check actually cost on THIS run: the gap between it and the last
    # required check to finish. Stated only when both halves are known -- a figure assembled from a
    # guess is the defect this whole report exists to correct.
    if ($required.Count -gt 0 -and -not $isRequired) {
        $lastRequired = @($finished |
            Where-Object { $required -contains $_.Name } |
            Sort-Object -Property Completed -Descending)
        if ($lastRequired.Count -gt 0) {
            $excess = ConvertTo-CheckSeconds -Span ($governing.Completed - $lastRequired[0].Completed)
            if ($excess -gt 0) {
                $parts += "$(Format-CheckDuration -Seconds $excess) after the last required check ('$($lastRequired[0].Name)')"
            }
        }
    }

    return ($parts -join '; ')
}

function Format-CheckNameList {
    <#
    .SYNOPSIS
        A list of check names as readable prose: "'a'", "'a' and 'b'", "'a', 'b' and 'c'". '' when empty.

    .DESCRIPTION
        Exists because Get-MergeBlockVerdict's Reason is read by a human in a terminal at the moment a
        merge either happens or does not, so a bare PowerShell array rendering ('System.Object[]', or a
        space-joined run of names) is the wrong output for the one line that explains the decision.

        Quoted per name rather than around the whole list, so a check name containing a space cannot be
        mistaken for two. Empty in, empty out -- a caller with nothing to name concatenates it
        unconditionally instead of branching, the same tolerance Format-CheckDuration already applies.
    #>
    param([string[]]$Names)

    $clean = @(@($Names) | Where-Object { $_ -and ([string]$_).Trim() } | ForEach-Object { "'$_'" })
    if ($clean.Count -eq 0) { return '' }
    if ($clean.Count -eq 1) { return $clean[0] }
    return (($clean[0..($clean.Count - 2)] -join ', ') + ' and ' + $clean[-1])
}

function Get-CheckOutcome {
    <#
    .SYNOPSIS
        One `gh pr checks --json` record reduced to 'pass', 'fail', 'pending' or 'unknown'.

    .DESCRIPTION
        Reads `bucket` first and `state` as the fallback, because which one a payload carries depends on
        what the caller asked for rather than on the check: `bucket` is a gh convenience field and
        `state` is the API's own word. A caller that asked for both gets the cheaper read; one that asked
        for only the second still gets an answer.

        'unknown' is a real answer and NOT a synonym for 'pass'. A record whose outcome cannot be read is
        a check nobody has proved green, and the only caller of this function is deciding whether a merge
        is safe -- so it needs the difference. That is also why the fail list is generous: cancelled,
        timed out and startup-failed are all "not green", and treating any of them as passing would let a
        merge through on a check that never ran.

        NEUTRAL and SKIPPED map to 'pass' because GitHub itself does not let either block a merge, and
        EXPECTED maps to 'pending' because it means a status that is awaited and has not arrived.
    #>
    param($Record)

    if ($null -eq $Record) { return 'unknown' }

    # A field the caller never asked gh for is absent, and absent is not empty under Set-StrictMode --
    # so ask the object whether it carries the property before reading it.
    $bucket = ''
    if ($Record.PSObject.Properties['bucket']) { $bucket = ([string]$Record.bucket).Trim().ToLowerInvariant() }
    switch ($bucket) {
        'pass'     { return 'pass' }
        'skipping' { return 'pass' }
        'fail'     { return 'fail' }
        'cancel'   { return 'fail' }
        'pending'  { return 'pending' }
    }

    $state = ''
    if ($Record.PSObject.Properties['state']) { $state = ([string]$Record.state).Trim().ToUpperInvariant() }
    switch ($state) {
        'SUCCESS'         { return 'pass' }
        'NEUTRAL'         { return 'pass' }
        'SKIPPED'         { return 'pass' }
        'FAILURE'         { return 'fail' }
        'ERROR'           { return 'fail' }
        'CANCELLED'       { return 'fail' }
        'TIMED_OUT'       { return 'fail' }
        'ACTION_REQUIRED' { return 'fail' }
        'STARTUP_FAILURE' { return 'fail' }
        'IN_PROGRESS'     { return 'pending' }
        'QUEUED'          { return 'pending' }
        'PENDING'         { return 'pending' }
        'WAITING'         { return 'pending' }
        'REQUESTED'       { return 'pending' }
        'EXPECTED'        { return 'pending' }
    }

    return 'unknown'
}

function Get-MergeBlockVerdict {
    <#
    .SYNOPSIS
        Whether a failing CI run actually blocks the merge -- i.e. whether what failed is a check the
        repo's ruleset REQUIRES. Returns Blocked / Reason / FailedRequired / FailedOther.

    .DESCRIPTION
        ship-pr.ps1 waits for every check a PR has and used to read the exit code of
        `gh pr checks --watch` as its verdict. That exit code is non-zero when ANY check fails, and the
        comment above it justified the refusal with "branch protection blocks the merge until green" --
        which is true only of a REQUIRED check. So the script was stricter than the ruleset it exists to
        respect, and on August 26, 2026 that difference was the whole chain: `claude-review` went red on
        every PR (issue #942) while `lint-en-tests`, the only check the `main` ruleset requires, was
        green. GitHub reported those PRs as MERGEABLE / UNSTABLE -- its own word for "mergeable, with a
        non-required check failing" -- and the script read it as BLOCKED (issue #943).

        THE WAIT IS UNCHANGED, and deliberately so. Issue #831 measured over n=100 paired runs that the
        non-required check governs the wait 23% of the time at a median cost of 0s, and Dave's answer
        (August 24, 2026) was to keep the wait and make it legible instead. Waiting on a non-required
        check costs seconds; REFUSING on one costs the merge for as long as that workflow is broken, and
        nobody had measured that. So only the verdict moves here, which is also why this takes the
        issue's second direction rather than its first: switching the WATCH to `--required` would have
        stopped waiting on a pending non-required check too, a second change with no measurement behind
        it.

        THE SELECTION IS THE PART THAT NEEDS A TEST, not the query -- the same split as
        Get-CheckWaitReport and Get-ExistingPrRecord above, for the same reason: the caller drives a live
        remote no suite can reach, while this can be handed a payload.

        READ THE PAYLOAD, NEVER AN EXIT CODE. Measured on PR #937 (August 26, 2026):
        `gh pr checks 937 --json name,bucket,state` returns exit 0 while reporting `claude-review` as
        `fail`. JSON mode carries the outcome in the records and not in the exit status, so a caller that
        read the exit code of the JSON call would conclude everything passed.

        AND THE UNREADABLE CASE REFUSES. Without a readable required-check list this cannot tell a
        ruleset that requires nothing from one whose required checks have not reported yet, so it keeps
        the old behaviour rather than guessing: a script that lets a merge through on an unread ruleset
        is a worse defect than the one being repaired. `gh pr checks --required` prints nothing and exits
        non-zero where a ruleset requires nothing, which is exactly that case.

    .PARAMETER RequiredChecksJson
        `gh pr checks <pr> --required --json name,bucket,state` output. The verdict is made from this and
        from nothing else.

    .PARAMETER ChecksJson
        `gh pr checks <pr> --json name,bucket,state` output, i.e. every check. Optional, and used only to
        NAME the not-required checks that failed -- never for the verdict. Left out, the verdict is
        identical and the reason simply does not list them.
    #>
    param(
        [string]$RequiredChecksJson,
        [string]$ChecksJson = ''
    )

    $unreadable = [pscustomobject]@{
        Blocked        = $true
        Reason         = 'the required-check list could not be read, so which checks this ruleset requires is unknown -- refusing on the CI failure, exactly as before'
        FailedRequired = @()
        FailedOther    = @()
    }

    if (-not $RequiredChecksJson -or -not $RequiredChecksJson.Trim()) { return $unreadable }
    try { $parsedRequired = $RequiredChecksJson | ConvertFrom-Json } catch { return $unreadable }

    # Assign first, wrap second -- 5.1 hands a parsed JSON array to the pipeline as ONE object.
    $requiredRecords = @(@($parsedRequired) | Where-Object { $_ -and $_.name })
    if ($requiredRecords.Count -eq 0) { return $unreadable }

    $failedRequired = @()
    $unfinishedRequired = @()
    $requiredNames = @()
    foreach ($r in $requiredRecords) {
        $name = [string]$r.name
        $requiredNames += $name
        switch (Get-CheckOutcome -Record $r) {
            'fail'    { $failedRequired += $name }
            'pending' { $unfinishedRequired += $name }
            'unknown' { $unfinishedRequired += $name }
        }
    }
    $failedRequired = @($failedRequired | Sort-Object -Unique)
    $unfinishedRequired = @($unfinishedRequired | Sort-Object -Unique)
    $requiredNames = @($requiredNames | Sort-Object -Unique)

    if ($failedRequired.Count -gt 0) {
        $it = if ($failedRequired.Count -eq 1) { 'it' } else { 'they' }
        return [pscustomobject]@{
            Blocked        = $true
            Reason         = "the ruleset REQUIRES $(Format-CheckNameList -Names $failedRequired), and $it failed"
            FailedRequired = $failedRequired
            FailedOther    = @()
        }
    }

    if ($unfinishedRequired.Count -gt 0) {
        $has = if ($unfinishedRequired.Count -eq 1) { 'has' } else { 'have' }
        return [pscustomobject]@{
            Blocked        = $true
            Reason         = "the required check $(Format-CheckNameList -Names $unfinishedRequired) $has not finished, or its state could not be read -- so the merge is not green"
            FailedRequired = @()
            FailedOther    = @()
        }
    }

    # Every required check passed, so the merge is not blocked. What remains is naming what DID fail,
    # which is presentation only -- an unreadable payload here costs the reader some detail and cannot
    # change the verdict above it.
    $failedOther = @()
    if ($ChecksJson -and $ChecksJson.Trim()) {
        try {
            # Assign first, wrap second -- see the note in Get-CheckWaitReport above.
            $parsedAll = $ChecksJson | ConvertFrom-Json
            $failedOther = @(@($parsedAll) |
                Where-Object { $_ -and $_.name } |
                Where-Object { $requiredNames -notcontains [string]$_.name } |
                Where-Object { (Get-CheckOutcome -Record $_) -eq 'fail' } |
                ForEach-Object { [string]$_.name })
        } catch {
            $failedOther = @()
        }
        $failedOther = @($failedOther | Sort-Object -Unique)
    }

    $what = if ($failedOther.Count -gt 0) {
        $them = if ($failedOther.Count -eq 1) { 'it' } else { 'them' }
        "$(Format-CheckNameList -Names $failedOther) failed, and the ruleset does not require $them"
    } else {
        'what failed is not a check the ruleset requires'
    }
    return [pscustomobject]@{
        Blocked        = $false
        Reason         = "every required check passed ($(Format-CheckNameList -Names $requiredNames)); $what"
        FailedRequired = @()
        FailedOther    = $failedOther
    }
}

function Get-FailedCheckRunRefs {
    <#
    .SYNOPSIS
        The failing records of a `gh pr checks --json` payload that name a GitHub Actions run, as
        { Name; RunId; JobId }, in payload order. Empty when nothing failed or nothing is readable.

    .DESCRIPTION
        ONE PARSE, TWO QUESTIONS. Get-FailedCheckRunIds below asks whether the RUN behind a failing
        check ever started (#1044); Get-AuthoredFailureNote's caller asks what the JOB said about why
        it went red (#1103). Both keys sit in the same field -- the `link`, whose Actions form is
        `https://github.com/<owner>/<repo>/actions/runs/<runId>/job/<jobId>` -- so they are read here
        once rather than by two parsers that would drift apart.

        A LINK THAT IS NOT AN ACTIONS RUN IS SKIPPED, DELIBERATELY, and that restraint is inherited
        rather than new: a commit status posted by an external service links wherever that service
        likes and has no run, no job and no annotations, so a key scraped out of such a URL would
        address something else entirely. A link that names a run but no job is KEPT, with an empty
        JobId -- the run question can still be asked of it, and the annotation question simply is not.

        Failing is read through Get-CheckOutcome, so 'cancel', 'timed out' and 'startup failure' come
        along for the same reason they do in the verdict above -- none of them is green.

    .PARAMETER ChecksJson
        `gh pr checks <pr> --json name,bucket,state,link` output. Anything that will not parse yields
        an empty list: every caller of this is a diagnostic, and a diagnostic degrades rather than
        throws.
    #>
    param([string]$ChecksJson)

    if (-not $ChecksJson -or -not $ChecksJson.Trim()) { return @() }
    try { $parsed = $ChecksJson | ConvertFrom-Json } catch { return @() }

    # Assign first, wrap second -- 5.1 hands a parsed JSON array to the pipeline as ONE object; the
    # same trap the two parses in Get-MergeBlockVerdict walked into.
    $records = @(@($parsed) | Where-Object { $_ })

    # A plain array rather than a generic List, and that is measured rather than stylistic: in 5.1
    # `@($list)` on a `List[object]` holding PSCustomObjects throws ArgumentException, while the same
    # wrap on the `List[string]` Get-FailedCheckRunIds builds below is fine. Two or three records is
    # not a size that needed a List anyway.
    $refs = @()
    foreach ($r in $records) {
        if ((Get-CheckOutcome -Record $r) -ne 'fail') { continue }
        if (-not $r.PSObject.Properties['link']) { continue }
        $link = [string]$r.link
        if ($link -notmatch '/actions/runs/(\d+)') { continue }
        # Read before the second -match: $Matches is overwritten by it, not extended.
        $runId = $Matches[1]
        $jobId = ''
        if ($link -match '/actions/runs/\d+/job/(\d+)') { $jobId = $Matches[1] }
        $name = ''
        if ($r.PSObject.Properties['name']) { $name = [string]$r.name }
        $refs += [pscustomobject]@{ Name = $name; RunId = $runId; JobId = $jobId }
    }
    return @($refs)
}

function Get-FailedCheckRunIds {
    <#
    .SYNOPSIS
        The GitHub Actions run ids behind the FAILING records of a `gh pr checks --json` payload, in
        the order they appear and without duplicates. Empty when nothing failed or nothing is readable.

    .DESCRIPTION
        The lookup key for Get-StalledRunNote below. `gh pr checks` reports a check, not the run that
        produced it, and the fact that separates "the job never started" from "a check went red" lives
        on the RUN -- so the caller needs an id before it can ask.

        THE READING MOVED UP TO Get-FailedCheckRunRefs (#1103) AND THE ANSWER DID NOT CHANGE WITH IT.
        The link form, the external-status skip and the failing-outcome rule are all that function's
        now; this is the run-shaped view of it, and what it still owns is the DEDUPE -- two failing
        checks from one run are one question about that run, and asking it twice would print the note
        twice.

    .PARAMETER ChecksJson
        `gh pr checks <pr> --json name,bucket,state,link` output. Anything that will not parse yields
        an empty list, because this only ever costs the caller a diagnostic line it can do without.
    #>
    param([string]$ChecksJson)

    $ids = New-Object System.Collections.Generic.List[string]
    foreach ($ref in @(Get-FailedCheckRunRefs -ChecksJson $ChecksJson)) {
        if (-not $ids.Contains($ref.RunId)) { $ids.Add($ref.RunId) | Out-Null }
    }
    return @($ids)
}

function Get-StalledRunNote {
    <#
    .SYNOPSIS
        One sentence for the operator when a workflow run FAILED TO START rather than failed -- i.e.
        when no job in it executed a single step. '' when something did run, which is the ordinary case
        and the case the caller's existing wording already covers.

    .DESCRIPTION
        Inbound #1044, measured August 28, 2026 in a consumer repo: GitHub Actions stopped starting
        jobs because an account payment had failed, every run ended in ~4s with zero steps, and
        ship-pr.ps1 reported it as

            CI did not pass for PR #N (exit 1) -- NOT merged: <verdict reason>.
            Fix CI and re-run, or merge manually once green.

        Every word of that is true and together they point at the wrong thing. "CI did not pass" reads
        as *a check ran and went red*, so the operator goes to their own code; the actual state was
        that nothing ran, which no branch can repair and no re-run will change. One PR was merged by
        hand as a result -- the habit this workflow exists to prevent.

        THE MERGE DECISION IS UNCHANGED, and deliberately. Refusing on an unreadable required-check
        list is the conservative half of #943 and stays exactly as it was: this adds no state to
        Get-MergeBlockVerdict and cannot let a merge through. What moves is the DIAGNOSIS handed to
        the operator alongside the refusal.

        WHY THE STEP COUNT AND NOT THE ANNOTATION. The reason text ("recent account payments have
        failed or your spending limit needs to be increased") sits on the check-run annotation, two API
        levels down and absent from the ordinary run page -- which is what made the state expensive to
        recognise. This does not go fetch it, for two reasons. The annotation is one CAUSE of a run
        that never started (a spending limit, Actions disabled for the org, and no runner able to take
        the job all produce the same shape), while "no step ran" is the FACT that makes "fix your code"
        wrong in every one of them. And the report measured the empty state two ways -- an empty jobs
        array and jobs with zero steps -- so the entry point to the annotation is not the same in both.
        Both shapes are recognised here; the note names the one command that prints the reason.

        A RUN THAT HAS NOT FINISHED IS NOT STALLED. A job still queued also has no steps, so a payload
        whose status is anything but 'completed' returns ''. ship-pr only reaches this after --watch,
        where that cannot happen -- asserted anyway, because "cannot happen" is how the premise this
        repo keeps replacing was justified.

    .PARAMETER RunJson
        `gh run view <runId> --json conclusion,status,url,jobs` output. Unreadable in, '' out: this is
        a diagnostic and must never be the reason a refusal cannot be printed.

    .PARAMETER RunId
        The run id, so the note can name the command that prints the reason. Optional; left out, the
        note ends after the URL it read from the payload.
    #>
    param(
        [string]$RunJson,
        [string]$RunId = ''
    )

    if (-not $RunJson -or -not $RunJson.Trim()) { return '' }
    try { $run = $RunJson | ConvertFrom-Json } catch { return '' }
    if ($null -eq $run) { return '' }

    # A field gh was never asked for is absent, and absent is not empty under Set-StrictMode -- the
    # same guard Get-CheckOutcome applies, for the same reason.
    $status = ''
    if ($run.PSObject.Properties['status']) { $status = ([string]$run.status).Trim().ToLowerInvariant() }
    if ($status -and $status -ne 'completed') { return '' }

    if (-not $run.PSObject.Properties['jobs']) { return '' }
    $jobs = @($run.jobs | Where-Object { $_ })

    $what = ''
    if ($jobs.Count -eq 0) {
        $what = 'the run created no job at all'
    } else {
        $ran = @($jobs | Where-Object {
            $_.PSObject.Properties['steps'] -and @($_.steps | Where-Object { $_ }).Count -gt 0
        })
        if ($ran.Count -gt 0) { return '' }
        $what = if ($jobs.Count -eq 1) {
            'its one job executed no step'
        } else {
            "none of its $($jobs.Count) jobs executed a step"
        }
    }

    $url = ''
    if ($run.PSObject.Properties['url']) { $url = ([string]$run.url).Trim() }

    $note = "The run did not FAIL, it never started: $what, so nothing was tested -- this is not a check that went red, and re-running the branch will not change it."
    $note += ' The cause is outside this repository (a failed account payment or a reached spending limit, Actions disabled for the org, or no runner able to take the job) and the reason text is not on the run page.'
    if ($RunId) {
        $note += " Print it with: gh run view $RunId"
    } elseif ($url) {
        $note += " The run is at $url"
    }
    return $note
}

function Get-AuthoredFailureNote {
    <#
    .SYNOPSIS
        The sentence a failing workflow wrote about ITSELF, read from a check run's annotations:
        `<title> -- <message>`, with the check name prefixed where the title does not already carry
        it. '' when the job left no authored diagnosis behind, which is the ordinary case and the
        case the caller's existing wording already covers.

    .DESCRIPTION
        Issue #1103, and the seven threads before it -- #891, #913, #942, #962, #966, #974, #1055.
        `claude-review` is advisory in this repo, so ship-pr merges past it and prints "a check FAILED
        but the merge is not blocked ... nothing here fixes it". Both halves are true, and together
        they hand the reader a red mark and an invitation to go and chase it. What the chaser meets is
        the action's own `##[error]Claude result reported subtype success with is_error:true`, which
        names nothing, and a log tail that ends somewhere unrelated to the cause -- so the same
        signature keeps arriving as a NEW issue against a run whose own diagnostic step had already
        printed the answer. #966 is the expensive one: it was filed against a log reading
        `api_error_status: 429`, inferred an expired OAuth token instead, and concluded that a secret
        needed rotating.

        So the reason is fetched and printed where the operator already is. It adds no information the
        run did not carry -- the same move claude-code-review.yml itself made when it put its reason in
        an annotation rather than only in a log body.

        THE SELECTION RULE, AND WHY IT IS NOT A CHECK NAME. A failure annotation carrying a TITLE was
        written by somebody: the Actions runner emits its own with an EMPTY title ("Process completed
        with exit code 1", "Action failed with error: ..."), while `::error title=X::Y` is a sentence a
        workflow author chose to leave for exactly this reader. "Titled failure annotation" therefore
        needs no maintenance and works in a consumer repo whose workflows this repo has never seen,
        where a rule keyed on the name `claude-review` would report nothing at all.

        WARNINGS ARE NOT READ, and the first titled failure wins. `annotation_level` is failure /
        warning / notice; a run is being explained here because it went RED, and the Node-20
        deprecation warning riding along on every job of this repo is not why. Annotations arrive in
        the order the job emitted them, and a workflow that diagnoses itself does so before the
        runner's exit noise.

        BOUNDED, BECAUSE THIS IS FREE TEXT A WORKFLOW PRODUCED AND IT IS BEING PASTED INTO A CONSOLE:
        the message is cut to its FIRST LINE and 500 characters. Not the 300 claude-code-review.yml
        used to write its own annotation under -- that bounded the REASON it appends, and the
        headline explaining what the status means sits in front of it, so relaying at 300 would keep
        only the headline, which is the part a reader could already guess from the check being red.
        That workflow now budgets its reason against THIS bound instead (#1116), which is a change in
        it and not in here: nothing below knows or needs a workflow that does so.

    .PARAMETER AnnotationsJson
        `gh api repos/<owner>/<repo>/check-runs/<jobId>/annotations` output. Unreadable in, '' out: a
        diagnostic must never be the reason the line beside it cannot be printed.

    .PARAMETER CheckName
        The check the annotations belong to, so the note names it. Optional; left out, the note is the
        authored sentence alone.
    #>
    param(
        [string]$AnnotationsJson,
        [string]$CheckName = ''
    )

    if (-not $AnnotationsJson -or -not $AnnotationsJson.Trim()) { return '' }
    try { $parsed = $AnnotationsJson | ConvertFrom-Json } catch { return '' }
    if ($null -eq $parsed) { return '' }

    # Assign first, wrap second -- see the note in Get-FailedCheckRunRefs above.
    foreach ($a in @(@($parsed) | Where-Object { $_ })) {
        # A field gh was never handed is absent, and absent is not empty under Set-StrictMode.
        if (-not $a.PSObject.Properties['annotation_level']) { continue }
        if (([string]$a.annotation_level).Trim().ToLowerInvariant() -ne 'failure') { continue }

        $title = ''
        if ($a.PSObject.Properties['title']) { $title = ([string]$a.title).Trim() }
        if (-not $title) { continue }

        $message = ''
        if ($a.PSObject.Properties['message']) { $message = ([string]$a.message).Trim() }
        $message = @($message -split "`r?`n")[0]
        # 500, NOT the 300 claude-code-review.yml once wrote its own annotation under, and measured
        # rather than guessed. That 300 bounded the REASON it appends; the headline explaining what
        # the status means sits in front of it, so relaying at 300 cuts the sentence in half and
        # keeps only the half a reader could guess from the red mark. Measured on run 33267175141:
        # 400 characters, ending "resets Aug 31, 7am (UTC)".
        #
        # THAT NUMBER READ 460 UNTIL ISSUE #1116 CHECKED IT. The same run's note, put back through
        # this function, is 400: a 55-character title, the 4-character separator and a 341-character
        # message. The bound was never in question, but the measurement defending it was wrong by 60
        # -- and a comment that cites a run id invites exactly this check, which is the argument for
        # citing one.
        #
        # AND THE 300 IS GONE, in the other direction from the one it looks like -- #1116 again. The
        # workflow now budgets its reason against THIS number rather than against one of its own, so
        # the annotation this repo emits is never one its own relay has to cut. That is a repair in
        # the specific party, not here: raising a generic bound because one verbose workflow needs
        # the room would spend it in every consuming repo. Nothing in this function changed for it,
        # and nothing here depends on that workflow existing.
        #
        # THE RELAY DOES NOT VOUCH FOR WHAT IT RELAYS, and that is the point of the rule -- issue
        # #1112. That measured note ended with a reset time roughly 2.5 DAYS later than the moment
        # the quota actually came back. Nothing is added here to caveat it: this function repeats
        # what an author wrote and cannot know which authors are reliable, so a hedge here would
        # hedge every workflow in every consuming repo. An over-claiming sentence is repaired in the
        # workflow that writes it, which is where #1112 was repaired.
        if ($message.Length -gt 500) { $message = $message.Substring(0, 500).TrimEnd() + '...' }

        # NAMED ONCE. A workflow that titles its own annotation usually leads with the job name --
        # `::error title=claude-review -- out of quota::` is exactly what this repo writes -- and
        # prefixing that again produces "claude-review: claude-review -- ...". The check name is here
        # for the payloads that do NOT carry it, so it is added only where it is missing.
        $note = if ($CheckName -and $title -notlike "$CheckName*") { "${CheckName}: $title" } else { $title }
        if ($message) { $note += " -- $message" }
        return $note
    }

    return ''
}
