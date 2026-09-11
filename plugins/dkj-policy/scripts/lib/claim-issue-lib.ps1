<#
.SYNOPSIS
    The two decisions claim-issue.ps1 makes -- WHICH account this checkout claims under, and WHETHER
    the issue in front of it may be claimed at all.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\claim-issue-lib.ps1')

    WHY THE DECISIONS ARE HERE AND THE COMMANDS ARE NOT. Everything claim-issue.ps1 does around these
    two functions is a `gh` round-trip, which a suite cannot run: it needs a live tracker, an account
    with write access, and an issue it is allowed to edit. The decisions are pure -- names in, verdict
    out -- so they are the half that CAN be tested, and they are the half that carries every refusal
    this step exists for. A test that could only cover the happy path is what let the split-identity
    hole stand (consumer-check-lib.tests.ps1's own lesson), so the pure half is deliberately as wide
    as it can be made and the impure half as thin.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.

    Pure ASCII, per this repo's script-layer convention.
#>

function Format-ForConsole {
    <#
        .SYNOPSIS
            Strip control characters out of tracker-supplied text before it is printed.

        .DESCRIPTION
            An issue title is written by whoever opened the issue, and on a public tracker that is
            anybody. Echoed verbatim it reaches the terminal as control characters -- an ANSI escape
            run can move the cursor, repaint what is already on screen, or hide the lines around it,
            which in THIS script would be repainting a refusal. Display only, never execution, and the
            operator has to point the run at that exact number; the reason to strip anyway is that the
            output of this step is what a session then decides on.

            C0 (00-1F) and DEL (7F) go, tab included -- a tab in a title is a layout accident rather
            than content. Everything printable stays exactly as written, because a title is quoted
            evidence and a mangled one is worse than a blunt one. Each character becomes a space
            rather than vanishing, so a title cannot be made to read as a different sentence by
            deleting the separator between two words.

            IT IS IN THIS LIB RATHER THAN IN THE SCRIPT so that it can be tested at all: a lib is
            dot-sourceable and claim-issue.ps1 is not. Same reasoning as the two decisions below.
    #>
    param([string]$Text)
    if (-not $Text) { return '' }
    return ([regex]::Replace($Text, '[\x00-\x1F\x7F]', ' '))
}

function Get-AssigneeLogins {
    <#
        .SYNOPSIS
            The logins in a `gh issue view --json assignees` payload, as a string array. An EMPTY array
            for empty input, unparseable JSON, or a payload carrying no readable login.

        .DESCRIPTION
            THE SAME MOVE AND THE SAME REASONING AS Get-LabelNames in pr-issues-lib.ps1, whose docstring
            names both 5.1 parse traps this hits. The caller drives a live remote and cannot be covered
            by a suite; parsing the answer is a pure function of the JSON text and can be, so it lives
            here.

            A FIELD gh WAS NEVER ASKED FOR IS ABSENT RATHER THAN EMPTY, and under
            Set-StrictMode -Version Latest a dot-read of an absent property THROWS. So every record is
            probed for 'login' before it is read -- an assignee record without one (schema drift, a
            ghost account, a future gh) is skipped rather than crashing the run mid-way, which in this
            script would mean an unhandled exception where a clean refusal belongs.

            EMPTY IS "COULD NOT BE ASKED" AND NOT "UNASSIGNED", which is why the caller checks gh's
            exit code BEFORE it reaches this function. Read the other way round, a failed query would
            present as a free issue and this whole step would hand out claims on other people's work.

            The payload here is an OBJECT with an 'assignees' array, not the bare array Get-LabelNames
            reads -- `gh issue view --json assignees` wraps it -- so the wrapper is unwrapped first and
            probed for exactly the same reason each record is.
    #>
    param([string]$Json)

    if (-not $Json -or -not $Json.Trim()) { return @() }
    try { $parsed = $Json | ConvertFrom-Json } catch { return @() }
    if ($null -eq $parsed) { return @() }
    if (-not $parsed.PSObject.Properties['assignees']) { return @() }

    $logins = New-Object System.Collections.Generic.List[string]
    foreach ($record in @(@($parsed.assignees) | Where-Object { $_ })) {
        if (-not $record.PSObject.Properties['login']) { continue }
        $login = ([string]$record.login).Trim()
        if ($login -and -not $logins.Contains($login)) { $logins.Add($login) | Out-Null }
    }
    return @($logins)
}

function Resolve-ClaimAccount {
    <#
        .SYNOPSIS
            Which GitHub account this checkout should put on an issue.

        .DESCRIPTION
            NOT '@me', AND THAT IS THE WHOLE POINT OF THIS FUNCTION. '@me' resolves through the GitHub
            API, so it binds to whatever gh is authenticated as -- while the branch a second session
            correlates the claim WITH carries the git identity. A machine can hold both (a personal
            login on the tracker, a work account on the commits), and then '@me' claims under one name
            while every commit lands under the other: nothing errors and the claim answers the wrong
            question. Measured on DAVE-KOK-BWJ, September 3, 2026 (issue #1315): gh authenticated as
            DaveKJohn while git config user.name read davekokbwj, so claiming #1314 with the documented
            idiom put the wrong account on it and it had to be corrected by hand.

            check-git-identity.ps1 already REPORTS that state, and its report ends with the instruction
            this function implements: "claim by NAME rather than with @me". So on a split checkout the
            answer is the GIT name -- the tracker is made to agree with the commits, because the commits
            are the half nothing can rewrite afterwards.

            THE LOGIN-SHAPE GUARD IS WHY THIS IS SAFE IN A NORMAL REPO. 'git config user.name' is free
            text and usually holds a display name ("Ada Lovelace"), which is not an account and cannot
            be assigned to anything. A value that fails GitHub's own username rule is therefore no
            evidence of a split at all, and the gh account stands -- the same guard, for the same
            reason, that keeps check-git-identity.ps1 silent in every consumer that spells its name
            normally.

        .PARAMETER GhAccount
            The account gh acts as (Get-ActiveGhAccount). '' when gh is absent or logged out.

        .PARAMETER GitUserName
            'git config user.name' for this checkout (Get-GitUserName). '' when unset.

        .OUTPUTS
            Account     -- the login to claim under, or '' when there is no account to claim as.
            GhAccount   -- as read.
            GitUserName -- as read.
            Split       -- $true when the two are provably different accounts.
            Reason      -- 'none' (nothing to claim as) | 'gh' (the two agree, or git names a person)
                           | 'split' (they differ; Account is the git one).
    #>
    param(
        [string]$GhAccount = '',
        [string]$GitUserName = ''
    )

    $gh  = if ($GhAccount) { $GhAccount.Trim() } else { '' }
    $git = if ($GitUserName) { $GitUserName.Trim() } else { '' }

    if (-not $gh) {
        return [pscustomobject]@{
            Account = ''; GhAccount = ''; GitUserName = $git; Split = $false; Reason = 'none'
        }
    }

    # A name that is not login-shaped names a PERSON, so it is not a second account and there is
    # nothing to be split about. GitHub logins are case-insensitive, so a difference in case is the
    # same account and must not be read as two.
    $split = (Test-GitHubLoginShape -Value $git) -and ($git -ine $gh)

    [pscustomobject]@{
        Account     = if ($split) { $git } else { $gh }
        GhAccount   = $gh
        GitUserName = $git
        Split       = $split
        Reason      = if ($split) { 'split' } else { 'gh' }
    }
}

function Get-ClaimVerdict {
    <#
        .SYNOPSIS
            Whether the issue in front of this checkout may be claimed, and what to do about it.

        .DESCRIPTION
            FOUR THINGS CAN BE WRONG, AND THEY ARE ORDERED BY WHAT THEY COST TO GET WRONG.

              1. NO ACCOUNT. gh is absent or logged out, so there is nobody to claim as. Reported
                 rather than worked around: a step whose whole job is to say who is working cannot
                 proceed anonymously.

              2. THE ISSUE IS CLOSED, and this is the refusal the step was built for. 'gh issue edit
                 <n> --add-assignee' SUCCEEDS SILENTLY on a closed issue -- so the claim rule's own
                 idiom gives a session every signal of having taken ownership of work that is already
                 done. Measured (the block at new-branch.ps1's stale-base refusal): a branch was cut,
                 committed, pushed and PR'd against an issue a second session had closed by a merged PR
                 FOUR MINUTES earlier, and the duplicate was found only when the PR sat without a
                 check suite. That is the most expensive of the four and it is the one nothing else
                 catches, because every gate downstream reads the branch and the branch is fine.

              3. SOMEBODY ELSE HOLDS IT. The tracker is the only thing two sessions share -- the same
                 owner on a second machine, a colleague on the same board -- so an assignee that is
                 not this checkout's own account stops the work. Not a judgement call and no valve:
                 the way past it is talking to whoever holds it, which a flag cannot do.

                 A CO-ASSIGNMENT STOPS IT TOO, including one this account is part of. Two people on
                 one issue is exactly the duplicate-work hazard the claim rule exists for, and being
                 one of the two is no evidence about what the other is building.

              4. NOTHING IS WRONG AND IT IS ALREADY YOURS. A resume -- a crash, a '--continue', a
                 second run on the same number. The claim is idempotent, so this is a skip rather
                 than an error: re-claiming would be a write that changes nothing, and reporting it
                 as a failure would teach a session to stop reading the output.

        .PARAMETER Account
            The login this checkout claims under (Resolve-ClaimAccount's Account).

        .PARAMETER State
            The issue's state as the tracker reports it -- 'OPEN' or 'CLOSED'. Compared
            case-insensitively, because 'gh --json state' and the REST API disagree on case.

        .PARAMETER Assignees
            The logins already on the issue. Empty or $null for an unassigned issue.

        .OUTPUTS
            Action -- 'claim' (write it) | 'skip' (already yours, nothing to write) | 'refuse'.
            Code   -- 'open-unassigned' | 'already-yours' | 'no-account' | 'closed' | 'taken'.
            Others -- the assignees that are not this account, for the message. Always an array.
    #>
    param(
        [string]$Account = '',
        [string]$State = '',
        [AllowNull()][string[]]$Assignees = @()
    )

    $others = @(@($Assignees) | Where-Object { $_ -and ([string]$_).Trim() -and ($_ -ine $Account) })
    $mine   = (@(@($Assignees) | Where-Object { $_ -and ($_ -ieq $Account) }).Count -gt 0)

    if (-not $Account) {
        return [pscustomobject]@{ Action = 'refuse'; Code = 'no-account'; Others = $others }
    }
    if ($State -ieq 'CLOSED') {
        return [pscustomobject]@{ Action = 'refuse'; Code = 'closed'; Others = $others }
    }
    if ($others.Count -gt 0) {
        return [pscustomobject]@{ Action = 'refuse'; Code = 'taken'; Others = $others }
    }
    if ($mine) {
        return [pscustomobject]@{ Action = 'skip'; Code = 'already-yours'; Others = $others }
    }
    return [pscustomobject]@{ Action = 'claim'; Code = 'open-unassigned'; Others = $others }
}

# --- THE FOURTH PICKUP SIGNAL: A FIX ALREADY PUSHED ON A BRANCH WITH NO PR (issue #1853) ----------
#
# THE THREE SIGNALS ABOVE ALL READ 'UNTOUCHED' IN ONE SHAPE. Get-ClaimVerdict reads the issue's state
# and its assignees; Get-TargetIssueWarnings (pr-issues-lib.ps1) resolves an issue to a PULL REQUEST.
# Measured September 11, 2026: a session claimed #1847 -- OPEN, unassigned, correctly -- read the code,
# wrote the one-line fix, ran the lint gate and committed, and only then did open-pr.ps1's remote-ahead
# gate show that commit f686b0af on origin/feat/1842-unify-prio-labels-bwj had already made the
# identical repair and said so in its own message. Nothing earlier could have seen it: that branch is
# PARKED, so there was no PR for the PR-shaped check to find, and nothing had closed the issue.
#
# SO THE FOURTH SIGNAL IS THE COMMIT MESSAGE, which is where a parked fix announces itself and the only
# place it does. The functions below are the pure half of that read -- the pattern, the two parses, and
# the report -- with the git calls in claim-issue.ps1 for the same reason the gh calls are: a suite
# cannot run them.
#
# ADVISORY BY CONSTRUCTION, like Get-TargetIssueWarnings and for the same reason (#1485): the claim is
# the OPENING of the work, so a false stop here costs the whole assignment. An issue can be legitimately
# named in a commit on a branch that does not fix it -- the same run that produced this measurement saw
# open-pr warn about four such mentions, all correct as context -- so this reports and never refuses.

function Get-IssueMentionPattern {
    <#
        .SYNOPSIS
            The POSIX extended regex that finds a commit message naming this issue, for `git log -E
            --grep=`. '' for a non-positive number, which the caller reads as "nothing to scan".

        .DESCRIPTION
            THREE SPELLINGS, BECAUSE THIS WORKFLOW WRITES ALL THREE and a pattern that knows only one
            misses the commit that matters most. #1853's own proposal was hash-only ('#<n>'), and the
            commit it was measured against is 'fix(1842): apply the parallel review findings', whose
            issue number is in the CONVENTIONAL COMMIT SCOPE with no hash at all -- so hash-only would
            have found that branch's prose and not its subject lines.

              - '#1853'   -- a body reference, which is how one branch cites an issue it is not named for
              - '(1853)'  -- the scope of 'type(scope): subject', which is how it cites the one it is
              - '/1853-'  -- the branch name inside a commit SUBJECT, which is the one shape a PARKED
                             branch always has: new-branch.ps1's own creation commit is
                             'park: fix/1853-parked-fix-scan (the branch files only)', and a branch that
                             never got further than being cut has no other commit to be found by.

            THE TRAILING CLASS IS WHAT KEEPS #18530 OUT. '([^0-9]|$)' requires the number to end where it
            ends, so a longer number that merely starts with these digits does not match -- the trap a
            bare '#1853' walks straight into, and it gets noisier as a tracker grows. There is
            deliberately no LEADING boundary beyond the three characters themselves: each one IS the
            boundary, and demanding another would drop '(#1853)'.

            NOT '\b': git's grep engines are POSIX, where '\b' works under the GNU implementation and is
            undefined elsewhere -- exactly the kind of thing that behaves on the machine it was written
            on. This lib is mirrored into every consumer's plugin cache, so "here" is not the only place
            it runs.

        .PARAMETER Issue
            The issue number. Non-positive -> ''.
    #>
    param([int]$Issue = 0)

    if ($Issue -le 0) { return '' }
    # The backtick escapes '$' for PowerShell's string parser only -- what reaches git is a literal '$',
    # the regex end anchor.
    return "(#|\(|/)$Issue([^0-9]|`$)"
}

function ConvertFrom-CommitScanLog {
    <#
        .SYNOPSIS
            The commits in a 'git log --format=%H%x1f%s' capture, as records with Sha and Subject. An
            EMPTY array for empty input or a capture carrying no readable line.

        .DESCRIPTION
            THE UNIT SEPARATOR (0x1F) IS THE FIELD DELIMITER, and that is the whole reason the format
            string is what it is: a commit subject is free text written by anybody with push access, and
            every printable delimiter a reader might reach for -- a tab, a pipe, a colon -- appears in
            real subjects in this repo. 0x1F cannot, because git strips control characters out of the
            subject line it produces.

            A LINE WITHOUT A SEPARATOR IS SKIPPED rather than guessed at. git writes progress and hints
            to stderr, and a caller that did not discard it would otherwise turn one of those lines into
            a commit with no sha. Same treatment Get-AssigneeLogins gives a record with no login, and for
            the same reason: this runs inside the step that OPENS an assignment, where an unhandled parse
            is a session that never starts.

            THE SUBJECT IS NOT STRIPPED HERE. The caller prints it and the caller runs it through
            Format-ForConsole, which keeps the one control-character policy in one place instead of two.

        .PARAMETER Text
            The capture, as one string or as the caller's joined line array.
    #>
    param([string]$Text)

    if (-not $Text -or -not $Text.Trim()) { return @() }

    # [string[]] IS LOAD-BEARING, NOT DECORATION. The overload that takes a count is
    # Split(String[], Int32, StringSplitOptions), and PowerShell's @() builds an Object[] -- which binds
    # to no overload at all. It does not fail at this line either: 5.1 reports it as an ArgumentException
    # at the `return` below, which sends a reader looking at the wrong statement entirely. The [char]
    # overload is not the way out: it takes no count, so a subject containing a second separator would
    # split into three fields and lose its tail.
    $sep = [string[]]@([string][char]0x1F)
    # List[psobject] AND NOT List[object], WHICH IS A 5.1 TRAP RATHER THAN A PREFERENCE. Windows
    # PowerShell 5.1 throws ArgumentException ("argument types do not match") when the array
    # subexpression @() wraps a List[object] -- whatever the list actually holds, a string included --
    # and it reports the fault at the `return @($records)` line, which sends a reader looking at the
    # wrong statement entirely. List[psobject] and List[string] both wrap cleanly, which is why the
    # three sibling functions in this file never met it. Measured here, 5.1.26100.9444.
    $records = New-Object 'System.Collections.Generic.List[psobject]'
    foreach ($line in ($Text -split "`r?`n")) {
        if (-not $line -or -not $line.Trim()) { continue }
        $parts = $line.Split($sep, 2, [System.StringSplitOptions]::None)
        if ($parts.Count -lt 2) { continue }
        $sha = $parts[0].Trim()
        if (-not $sha) { continue }
        $records.Add([pscustomobject]@{ Sha = $sha; Subject = $parts[1].Trim() }) | Out-Null
    }
    return @($records)
}

function Get-ContainingBranchNames {
    <#
        .SYNOPSIS
            The branch names in a 'git branch -a --contains <sha>' capture, cleaned and with the caller's
            own refs dropped. An EMPTY array when nothing survives.

        .DESCRIPTION
            WHAT IT DROPS, AND WHY EACH ONE WOULD BE NOISE:

              - THE MARKERS. '* ' is the checked-out branch and '+ ' is one held by another worktree;
                both are decoration on the name rather than part of it.
              - 'remotes/'. git prints a remote branch as 'remotes/origin/foo' HERE and as 'origin/foo'
                everywhere else in this workflow. The short spelling is the one a reader can paste.
              - A SYMBOLIC REF ('origin/HEAD -> origin/main'). It points at a branch already in the list,
                so keeping it names the same branch twice under a name nobody checks out.
              - A DETACHED HEAD ('(HEAD detached at abc1234)'). Not a branch, and the parenthesis is how
                git says so even where the words inside it are translated.
              - -Exclude, which the caller fills with the trunk and the CURRENT branch. The trunk because
                the log that produced the sha already excluded it, so a match there is not parked work;
                the current branch because on a resume the session's OWN commits name the issue, and
                reporting a session's work back to it as somebody else's is the fastest way to teach it
                to stop reading this warning.
              - A LOCAL BRANCH WHOSE OWN REMOTE-TRACKING TWIN IS ALSO LISTED. `git branch -a --contains`
                names both 'feat/x' and 'origin/feat/x' when a checkout holds a local copy of a parked
                branch, and they are one piece of work, not two -- so counting both would inflate the
                one number this report exists to give ("how many places is this already being worked").
                The REMOTE spelling is the one kept, because it is the address that is true for anybody
                reading over your shoulder; a branch that exists only locally keeps its own name, having
                no twin to fold into.

            SORTED AND DEDUPED, so two runs on one repo print the same line in the same order -- a
            warning a reader cannot diff against the last one is a warning they read once.

        .PARAMETER Text
            The capture, as one string or as the caller's joined line array.

        .PARAMETER Exclude
            Branch names to drop, in the short spelling ('main', 'origin/main', 'fix/x'). Compared
            CASE-SENSITIVELY, because git refs are: 'Main' and 'main' are two branches.
    #>
    param(
        [string]$Text,
        [AllowNull()][string[]]$Exclude = @()
    )

    if (-not $Text -or -not $Text.Trim()) { return @() }
    $drop = @(@($Exclude) | Where-Object { $_ -and ([string]$_).Trim() } | ForEach-Object { ([string]$_).Trim() })

    $names = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($Text -split "`r?`n")) {
        $name = ([string]$line).Trim()
        if (-not $name) { continue }
        $name = ($name -replace '^[*+]\s*', '').Trim()
        if (-not $name) { continue }
        if ($name.StartsWith('(')) { continue }
        if ($name -match '\s->\s') { continue }
        if ($name.StartsWith('remotes/')) { $name = $name.Substring('remotes/'.Length).Trim() }
        if (-not $name) { continue }
        if ($drop -ccontains $name) { continue }
        if (-not $names.Contains($name)) { $names.Add($name) | Out-Null }
    }

    # THE LOCAL/REMOTE FOLD, AFTER the whole list is known -- it cannot be decided one line at a time,
    # because git prints the local copy before the remote one and the twin is not yet in hand. Only a
    # 'remotes/' entry can be a twin, which is why the suffix is matched against the cleaned list rather
    # than against the raw text: 'origin/feat/x' folds 'feat/x' away, and a remote called anything else
    # ('upstream/feat/x') folds nothing, because a local branch tracking a second remote is a case this
    # cannot tell apart from two unrelated branches sharing a name.
    $remoteSuffixes = @{}
    foreach ($n in $names) {
        if ($n -match '^origin/(.+)$') { $remoteSuffixes[$Matches[1]] = $true }
    }
    $folded = @($names | Where-Object { -not $remoteSuffixes.ContainsKey($_) })

    return @($folded | Sort-Object)
}

function Format-ParkedFixReport {
    <#
        .SYNOPSIS
            The warning lines for the off-trunk commits naming this issue. An EMPTY array when there are
            none, which is the caller's signal to print nothing at all.

        .DESCRIPTION
            GROUPED BY BRANCH, BECAUSE THE BRANCH IS WHAT THE READER ACTS ON. A commit-first listing
            repeats the branch name under every commit and buries the one fact that decides what happens
            next -- how many places this issue is already being worked, and which. A commit appearing on
            two branches is listed under both: that is not duplication, it is the answer to "which of
            these do I look at", and both are true.

            A FINDING WHOSE BRANCHES WERE ALL EXCLUDED is dropped HERE rather than printed as a commit
            floating in no branch. The caller hands in what it measured; the decision about what is worth
            saying stays in the half a suite can hold.

            CAPPED AT -MaxCommitsPerBranch, and the cap is what keeps this a warning rather than a wall.
            A branch cut for this issue writes its number into EVERY commit subject -- 'fix(1853): ...'
            is the convention -- so a week-old branch matches thirty times and would push the closing
            advice off the screen it was written for. The overflow line names the count, so nothing is
            silently hidden; the reader who wants all of them has the branch name and one git command.

            IT SAYS WHAT IT DOES NOT KNOW, in the closing lines, because this check cannot tell a fix
            from a mention and must not sound as though it can. The reader's next act is to look at the
            branch; the warning's whole job is to make that cost one command instead of a whole
            assignment.

            THE STALENESS NOTE IS NOT HERE, deliberately. "I found nothing" and "I could not refresh the
            refs I looked at" are different sentences, and a failed fetch must not be able to read as a
            clean scan -- so the caller prints that one whether or not this returns anything.

        .PARAMETER Issue
            The issue being claimed, for the lead line.

        .PARAMETER Findings
            Records with Sha, Subject and Branches (a string array). Anything else is ignored.

        .PARAMETER MaxCommitsPerBranch
            How many commits to list under one branch before the overflow line. Below 1 is treated as 1:
            a branch worth naming is worth one example, and a cap of zero would print a branch with
            nothing under it.

        .OUTPUTS
            String[] -- the lines in print order, with no colour and no prefix. The caller writes them.
    #>
    param(
        [int]$Issue = 0,
        [AllowNull()][object[]]$Findings = @(),
        [int]$MaxCommitsPerBranch = 3
    )

    $real = @(@($Findings) | Where-Object {
        $_ -and $_.PSObject.Properties['Branches'] -and (@(@($_.Branches) | Where-Object { $_ }).Count -gt 0)
    })
    if ($real.Count -eq 0) { return @() }
    $cap = if ($MaxCommitsPerBranch -lt 1) { 1 } else { $MaxCommitsPerBranch }

    # ORDERED, not a hashtable: PowerShell's plain @{} has no defined key order, so two runs over the
    # same repo would print the same branches in a different sequence and a reader could not diff one
    # warning against the last.
    $byBranch = [ordered]@{}
    foreach ($f in $real) {
        $sha = ([string]$f.Sha)
        $short = if ($sha.Length -gt 8) { $sha.Substring(0, 8) } else { $sha }
        $subject = if ($f.PSObject.Properties['Subject']) { ([string]$f.Subject).Trim() } else { '' }
        foreach ($branch in @(@($f.Branches) | Where-Object { $_ })) {
            $key = [string]$branch
            if (-not $byBranch.Contains($key)) { $byBranch[$key] = (New-Object System.Collections.Generic.List[string]) }
            $byBranch[$key].Add("$short  $subject".TrimEnd()) | Out-Null
        }
    }

    $branchNames = @($byBranch.Keys | Sort-Object)
    $lines = New-Object System.Collections.Generic.List[string]
    $commitWord = if ($real.Count -eq 1) { 'commit' } else { 'commits' }
    $branchWord = if ($branchNames.Count -eq 1) { 'branch' } else { 'branches' }
    $lines.Add("parked-fix scan: #$Issue is named by $($real.Count) $commitWord on $($branchNames.Count) $branchWord off the trunk --") | Out-Null
    foreach ($branch in $branchNames) {
        $commits = @($byBranch[$branch])
        $lines.Add("  $branch") | Out-Null
        foreach ($c in @($commits | Select-Object -First $cap)) { $lines.Add("      $c") | Out-Null }
        if ($commits.Count -gt $cap) { $lines.Add("      ... and $($commits.Count - $cap) more naming #$Issue") | Out-Null }
    }
    $lines.Add('  A branch with no pull request is invisible to every other pickup check, so READ THOSE') | Out-Null
    $lines.Add('  COMMITS before you write anything. This cannot tell a fix from a mention and does not') | Out-Null
    $lines.Add('  claim to -- the claim stands either way.') | Out-Null
    return @($lines)
}
