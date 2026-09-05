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
