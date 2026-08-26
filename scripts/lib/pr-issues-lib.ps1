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

    The second group (Get-CheckWaitReport and its two helpers) arrived for the same reason from the
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
    #>
    param($Value)

    if ($null -eq $Value) { return $null }
    if ($Value -is [datetime]) { return $Value.ToUniversalTime() }

    $text = [string]$Value
    if (-not $text.Trim()) { return $null }
    try {
        return [datetime]::Parse(
            $text,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    } catch {
        return $null
    }
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
        if ($null -ne $began) {
            $ran = [int][math]::Round(($done - $began).TotalSeconds)
            if ($ran -lt 0) { $ran = -1 }
        }
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
            $excess = [int][math]::Round(($governing.Completed - $lastRequired[0].Completed).TotalSeconds)
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
