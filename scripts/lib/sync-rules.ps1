<#
.SYNOPSIS
    The pure rules the Shopify pre-task sync is built on: where to measure from, whose content a
    path has held, and who wins a file.

.DESCRIPTION
    Separated from scripts/task/sync-main.ps1 on purpose, and it is not tidiness. The risk in a sync is
    not the policy -- it is one sentence either way -- it is the QUERIES that decide when the policy
    fires. Every one of them is testable only if it can be loaded without running a sync, so they live
    here and scripts/tests/sync-rules.tests.ps1 exercises them against a fixture repository.

    THE POLICY CHANGED ON AUGUST 21, 2026 (inbound #807) AND THIS FILE IS IN TWO HALVES BECAUSE OF IT.
    The first half is the TIME window -- Get-SyncReferencePoint and Test-MainTouchedSince -- which used to
    decide who won a file and now only escalates a both-sides-changed case to a human. The second half,
    under "THE CONTENT RULE" below, is what decides now. Read that banner first: it says why a floor
    cannot answer the question the rule is asking, which is the reason the first half was demoted rather
    than repaired.

    DEPENDENCY-FREE, AND DELIBERATELY NOT A READER OF scripts/repo-config.ps1. That file is read by
    team-shopify's live-theme guard on EVERY command, inside a 'try { . $configPath } catch { return
    $answers }' -- so a fault in anything it pulls in makes that catch fire and the guard continues with
    no live theme id, which is a hole in the one rule that cannot self-declare. The seam answers are
    therefore read by the SCRIPT and passed in as parameters. Both functions here take everything they
    need from their caller.

    Pure ASCII, per this repo's script-layer convention.
#>

# Best-effort git call whose stderr may be swallowed. Under $ErrorActionPreference = 'Stop', Windows
# PowerShell 5.1 turns any stderr line from a native executable into a terminating NativeCommandError --
# and 'git log' over a path that has never existed writes to stderr while being a perfectly ordinary
# "no" answer. So the preference is lowered for the duration of the call rather than the caller having
# to wrap every query in a try.
#
# PASS A PATHSPEC BY SPLATTING AN ARRAY, NEVER BY WRITING '--' INLINE. A bare '--' typed into a native
# call does not reach git, so the pathspec behind it is read as a revision. For a path still in HEAD git
# disambiguates and the bug is invisible; for a path the trunk has DELETED it errors to stderr, which
# this wrapper swallows by design -- so the caller gets a silent $null and the losing answer.
# Test-MainTouchedSince already builds its arguments as an array for exactly this reason (inbound #801).
function Invoke-SyncGitQuiet {
    $ErrorActionPreference = 'Continue'
    git @args 2>$null
}

function Get-SyncDefaultReferencePattern {
    <#
    .SYNOPSIS
        The default --grep pattern that recognises a previous sync commit.

    .DESCRIPTION
        '^[Ss]ync' rather than '^sync', and the capital is measured rather than defensive. The two
        Shopify consumers that wrote this script before it shipped spell their sync commits differently:
        one writes 'sync: live theme drift <date>', the other has written 'Sync main with live theme
        (<store>)' and 'Sync <files> from live (in-flight third-party edit)' since May 2026 -- capital
        S, no colon, six of them in that history. A pattern that matches one finds NOTHING in the other,
        falls through to the tag lookup, finds nothing there either in a repo with no tags, and aborts
        on the FIRST run, before the rule has ever protected anything.

        WHY THE DEFAULT IS THE UNION AND NOT THE LOOSEST THING THAT WORKS. Looseness is not free here:
        Get-SyncReferencePoint takes the MOST RECENT match, so a pattern that matches more commits can
        only move the floor FORWARD, and a floor that is too recent protects fewer files. That is the
        direction that loses work. This pattern is exactly the two spellings in use and nothing else,
        and a repo whose history says something else narrows it through the seam rather than by editing
        this file.

        AND THE SEAM CANNOT NARROW AWAY A MERGE COMMIT, WHICH IS WHY THAT ONE IS HANDLED IN THE LOOKUP
        ITSELF. '--grep' is line-oriented over the whole message, so no pattern can distinguish "the
        subject starts with sync" from "a body line starts with sync" -- and a merge commit carries the
        merged commit's subject in its body. Get-SyncReferencePoint passes '--no-merges' for that;
        see its own note.
    #>
    return '^[Ss]ync'
}

function Get-SyncReferencePoint {
    <#
    .SYNOPSIS
        The commit the exclusion rule measures from: the previous sync, else the newest tag, else
        nothing.

    .DESCRIPTION
        Returns a hashtable with two fields, because which of the two rules answered is worth printing:

            Ref   the commit-ish to measure from
            Kind  'sync' or 'tag'

        A tag-based floor is usually far older than a sync-based one and therefore far MORE protective,
        so an operator who sees 'tag' knows the window is wide rather than that something went wrong.

        RETURNS $null WHEN THERE IS NO REFERENCE POINT AT ALL, and the caller must refuse rather than
        default to "sync everything". Without a floor every file looks untouched by the trunk and the
        exclusion rule silently passes everything through -- which is precisely the failure it exists to
        stop, arriving as a green run.

        '--no-merges' IS LOAD-BEARING, NOT TIDINESS, and it is the repair for the worst version of that
        same failure -- the one that arrives green while a floor IS reported. '--grep' matches any line
        of a commit message, and a sync branch merged with a merge commit carries the sync commit's own
        subject in its BODY:

            merge: sync/live-2026-08-20 (#27)

            sync: mirror the overlay in sections/media-with-text.liquid from live into main

        So the merge matches the pattern. Right after a sync PR lands that merge is HEAD, the floor
        becomes HEAD, Test-MainTouchedSince answers $false for every path, and the rule keeps NOTHING
        back -- with 'Reference point: <sha> (the previous sync commit)' printed above it. The seam
        cannot help: no --grep pattern separates a subject from a body line, and --no-merges does.

        Measured in a consumer on 2026-08-21 (inbound #801): the next sync was about to delete 41 lines
        of translations across two locale files, revert two '| raw' removals, and resurrect 23 locale
        files a commit had deliberately dropped -- 31 files over three merged PRs. Skipping merges can
        only move the floor BACKWARD, onto the sync commit the merge brought in, and backward is the
        protective direction; the regression suite pins both halves.
    #>
    param(
        [string]$Ref = 'HEAD',
        [string]$Pattern = (Get-SyncDefaultReferencePattern)
    )

    $sync = Invoke-SyncGitQuiet log -1 --no-merges --format=%H "--grep=$Pattern" $Ref |
        Where-Object { $_ } | Select-Object -First 1
    if ($sync) { return @{ Ref = [string]$sync; Kind = 'sync' } }

    $tag = Invoke-SyncGitQuiet describe --tags --abbrev=0 $Ref |
        Where-Object { $_ } | Select-Object -First 1
    if ($tag) { return @{ Ref = [string]$tag; Kind = 'tag' } }

    return $null
}

function Test-MainTouchedSince {
    <#
    .SYNOPSIS
        Has this branch touched $Path since $Since? The core of the exclusion rule.

    .DESCRIPTION
        The rule it serves is one line:

            Has the trunk touched this file since the last sync? Then the TRUNK wins. Otherwise LIVE
            wins.

        That single line covers all three ways a wholesale live pull destroys work, which is why there
        is one rule and not three:
          * CHANGED on the trunk  -- the trunk carries a fix that is not live yet; live's older copy
                                     must not overwrite it.
          * ADDED on live         -- the trunk deliberately DELETED the file; live's copy must not
                                     resurrect it.
          * MISSING on live       -- the trunk ADDED a file that is not pushed yet; the pull must not
                                     delete it.

        THE RISK IS IN THIS QUERY, NOT IN THE RULE, and that is why it is a named function with tests of
        its own. It must answer $true for a path the trunk has REMOVED, which is not obvious: a deletion
        is also a touch. 'git log -- <path>' does answer that, because a pathspec searches history
        rather than the current tree -- but that is exactly the kind of assumption to pin with a test
        instead of to hope for. It is also the case the first implementation of this rule got wrong.

        WHY IT MATTERS MORE ONCE A REPO ADOPTS A CHANGELOG. In a repo where work merges into the trunk
        before it reaches live, "merged but not live yet" is a DESIGNED state rather than an accident --
        it is what an entry sitting in CHANGELOG.md means. Every such entry names work a wholesale sync
        would have reverted, so the two halves of this marketplace interact: adopting the changelog model
        makes the naive sync strictly more dangerous.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Since,
        [Parameter(Mandatory = $true)][string]$Path
    )

    # Arrays plus splatting because of the '--' pitfall: a bare '--' written inline into a native call
    # does not reach git, and the pathspec is then read as a revision.
    $logArgs = @('log', '--oneline', "$Since..HEAD", '--', $Path)
    $touched = Invoke-SyncGitQuiet @logArgs | Where-Object { $_ }
    return [bool]$touched
}

# ----------------------------------------------------------------------------------------------------
# THE CONTENT RULE (inbound #807, August 21, 2026). What decides who wins a file, in place of the clock.
#
# WHY THE TIME WINDOW HAD TO GO, and it is not an off-by-one. The question the exclusion rule wants
# answered is "is the trunk's version newer than live's". A floor cannot answer it, because nothing
# pushes the trunk TO live except the per-file release step ('--only'), and a deletion cannot be pushed
# that way at all -- so the trunk's changes are permanently invisible to live and sink below the floor as
# soon as one more sync commit lands. After that, every future sync tries to overwrite them again,
# forever. In a repo that has adopted the changelog model this is not an edge case: "merged but not live
# yet" is a DESIGNED state, and every pending entry names work a wholesale sync would revert.
#
# THE RULE THAT REPLACED IT. Has this path ever held live's content in the trunk's own history? Then the
# trunk wins. Otherwise live wins -- and if the trunk also changed it, nobody wins and a human looks.
#
# THE FLOOR SURVIVES, DEMOTED. Its only remaining job is to notice that live's content is foreign AND the
# trunk changed the same path recently -- both sides moved -- and refuse. A wrong floor then costs an
# extra conflict report rather than silent data loss, which is a far better failure mode for the piece of
# this that is hardest to get right.
# ----------------------------------------------------------------------------------------------------

function Get-GitRawBlobId {
    <#
    .SYNOPSIS
        git's own object id for a byte stream: SHA1('blob ' + length + NUL + bytes).

    .DESCRIPTION
        PURELY AN OPTIMISATION, AND WHAT IT BUYS IS PROCESS COUNT. The sync has to decide which of live's
        several hundred files differ from the trunk at all. Through 'git cat-file' that is one process per
        file, and on Windows that is the difference between a second and well over a minute -- slow enough
        that somebody starts skipping the step, which is how the sync got dangerous in the first place.

        So the comparison runs in two stages. Stage one is this function against 'git ls-tree -r HEAD',
        entirely in .NET with no subprocess: identical ids mean identical files, which is true of most of
        the tree. Only the remainder -- the genuinely changed files PLUS the ones differing in CR bytes
        alone -- pays for the CR-normalised comparison.

        It has to agree with 'git hash-object --no-filters' exactly, or stage one would report files as
        unchanged that are not, which is the worst failure shape here: a silent skip. The suite asserts it
        against real git output rather than against itself.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]]$Bytes)

    $header = [System.Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)" + [char]0)
    $buf = New-Object byte[] ($header.Length + $Bytes.Length)
    [System.Array]::Copy($header, 0, $buf, 0, $header.Length)
    if ($Bytes.Length -gt 0) { [System.Array]::Copy($Bytes, 0, $buf, $header.Length, $Bytes.Length) }
    $sha = [System.Security.Cryptography.SHA1]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($buf)) -replace '-', '').ToLower()
    } finally { $sha.Dispose() }
}

function Get-CrStrippedBytes {
    <#
    .SYNOPSIS
        The same byte stream with every CR (0x0D) removed, so CRLF and LF hash alike.

    .DESCRIPTION
        WITHOUT THIS THE CONTENT RULE MISFIRES, AND IT MISFIRES IN THE LOSING DIRECTION. The Shopify CLI
        writes each file with the line endings LIVE holds, live holds both, and a git index is typically
        all-LF: measured at 37 of 712 files in one consumer, coming back differing in nothing but CR
        bytes. Compared raw, those 37 look like content live has that the trunk has never held -- which is
        the definition of third-party drift under this rule -- so the sync would capture 37 files of pure
        noise and overwrite the trunk with every one.

        The wholesale version handled the same problem by staging everything ('git add -A' collapses it),
        which works only because it then compares through the index. This comparison happens out of tree,
        so it normalises explicitly.

        BYTES, NOT TEXT: theme assets include binaries (fonts, images), and a text read in Windows
        PowerShell 5.1 mangles every byte above 0x7F. Stripping CR from a binary is harmless here because
        BOTH sides are stripped, so equal binaries still compare equal.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]]$Bytes)

    $out = New-Object System.Collections.Generic.List[byte]
    foreach ($b in $Bytes) { if ($b -ne 13) { $out.Add($b) } }
    # THE LEADING ',' IS LOAD-BEARING. PowerShell unwraps a zero-length array on return, so a file whose
    # content is empty (or is nothing but CR bytes) came back as $null and the next call failed its
    # Mandatory bind. Found by the consumer's suite, which then compared $null to $null and reported a
    # PASS -- a vacuous green, which is worse than the error it was hiding. Both cases are asserted
    # against git's real empty-blob id here, so a wrong answer cannot agree with itself.
    return ,$out.ToArray()
}

function Get-GitStoredBlobId {
    <#
    .SYNOPSIS
        git's stored object id for <rev>:<path>, or '' when that path does not exist at that rev.

    .DESCRIPTION
        WHY THIS READS AN ID AND NOT THE BYTES, which is a repair rather than a preference. The consumer's
        first version of this lib read content with 'git cat-file blob <rev>:<path> > $tmp' and read the
        file back, and its own comment claimed the temp file avoided PowerShell's text decoding. It does
        the opposite: '>' in PowerShell IS the pipeline, so it decodes the native command's stdout to text
        and re-encodes it on write, mangling high bytes and rewriting line endings. Every blob it returned
        was corrupt, so the provenance check answered $false for content that WAS ours -- which sends a
        file to take-live and overwrites the trunk. Its test suite caught it; reading the code did not,
        because the comment read as though the problem had been handled.

        An object id is ASCII hex, so there is nothing for a text decode to damage. And git has already
        done the hashing, so this is cheaper than reading content ever was.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Rev,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $id = Invoke-SyncGitQuiet rev-parse "$($Rev):$($Path)" | Where-Object { $_ } | Select-Object -First 1
    if (-not $id) { return '' }
    $id = ([string]$id).Trim()
    if ($id -notmatch '^[0-9a-f]{40}$') { return '' }
    return $id
}

function Test-LiveContentIsOurs {
    <#
    .SYNOPSIS
        Has this path EVER held live's exact content in this branch's history? The query the rule turns on.

    .DESCRIPTION
        If live's bytes are bytes THIS REPO has held for that path before, live is holding an older version
        of our own file and the trunk has moved on: the trunk wins, and it does not matter how long ago it
        moved. If live's bytes appear nowhere in our history for that path, somebody outside this repo
        wrote them, and that is the drift the sync exists to capture.

        MEASURED BOTH WAYS IN A CONSUMER BEFORE IT WAS BUILT (2026-08-21, inbound #807), which is the only
        reason to trust it. A rule that is safe by capturing nothing is useless, so the false-negative half
        matters more than the headline:

          * Against live that day: 31 differing files, ALL 31 content that repo has held. The rule captures
            zero, correctly -- there was no third-party drift, only the trunk having moved forward. The
            time rule captured all 31 and was about to revert three merged PRs.
          * Replayed over every 'from live' commit in that repo's history: 10 of 11 real third-party drift
            files come back foreign and are captured. The 11th reverted a single trailing blank line, so
            dropping it is harmless rather than a loss.

        COST: one 'git rev-parse' per commit that touched the path, until a match. Bounded by that path's
        own history, which in a theme repo is single digits.

        '--follow' IS DELIBERATELY NOT USED. It would chase renames and could match content out of a
        DIFFERENT path's history, making live's copy of file B read as ours because file A once held those
        bytes. Under-matching here is safe (the file reads as foreign, so a human sees it); over-matching
        is not.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]]$LiveBytes,
        [string]$Ref = 'HEAD'
    )

    # TWO CANDIDATE IDS, AND BOTH ARE NEEDED. The comparison is against git's STORED object ids, which are
    # text and therefore safe to read (see Get-GitStoredBlobId). Where the index is all-LF a stored blob's
    # id is the id of its LF content, and live's CR-stripped bytes hash to the same thing when the text is
    # the same -- that is the CRLF case, and it is the common one. But all-LF is a measured property of a
    # repo rather than a guarantee, so the RAW id is compared too: if some blob ever went in with CRLF
    # intact, the raw form matches it. Neither matching means the file reads as foreign and a human sees
    # it, which is the safe direction and the reason this compares fewer forms than full normalisation.
    $rawId      = Get-GitRawBlobId -Bytes $LiveBytes
    $strippedId = Get-GitRawBlobId -Bytes (Get-CrStrippedBytes -Bytes $LiveBytes)

    # ARRAY PLUS SPLATTING FOR THE '--', the pitfall this file's header names, and here it was not
    # theoretical. Written inline as 'log --format=%H $Ref -- $Path' the '--' never reaches git, so git
    # reads the path as a revision. For a path still in HEAD it disambiguates and the bug is invisible;
    # for a path the trunk has DELETED it errors to stderr, Invoke-SyncGitQuiet swallows it, and the
    # function sees no history and answers "foreign" -- restoring live's copy over a deliberate deletion.
    # Measured in the consumer: 23 deleted locale files about to be resurrected. The 'A' case is the one
    # that needs the '--', and the 'A' case is where getting it wrong undoes a deliberate deletion.
    $logArgs = @('log', '--format=%H', $Ref, '--', $Path)
    $commits = @(Invoke-SyncGitQuiet @logArgs | Where-Object { $_ })
    foreach ($c in $commits) {
        $stored = Get-GitStoredBlobId -Rev "$c" -Path $Path
        if (-not $stored) { continue }
        if ($stored -eq $rawId -or $stored -eq $strippedId) { return $true }
    }
    return $false
}

function Get-SyncFileVerdict {
    <#
    .SYNOPSIS
        What happens to one differing path: 'keep-trunk', 'take-live' or 'conflict'.

    .DESCRIPTION
        The whole decision as one pure function, so the suite can walk every cell instead of trusting a
        read-through of the loop that calls it.

        Status is measured against the trunk: 'M' both sides have it and differ, 'A' live has it and the
        trunk does not, 'D' the trunk has it and live does not.

                                          live content is OURS          live content is FOREIGN
          M  both have it, differs        keep-trunk                    take-live, or conflict *
          A  only live has it             keep-trunk (no resurrection)  take-live
          D  only the trunk has it        keep-trunk (never delete)     keep-trunk (never delete)

        * the only place the floor is still consulted, and it can only ever escalate to a human: live's
          content is foreign AND the trunk has changed this path since the floor, so BOTH sides moved.
          Taking either would lose the other, so nothing is decided -- the caller refuses and reports.
          This is why a wrong floor now costs extra conflict reports instead of silent data loss.

        WHY 'D' IS UNCONDITIONAL. A path the trunk has and live does not is either a file the trunk added
        that was never pushed, or a file a third party deleted on live. The first must be kept, the second
        is indistinguishable from it, and "delete it here too" is the irreversible option. So the sync
        NEVER deletes; it reports. That is a deliberate narrowing of the wholesale rule, which deleted
        such a file whenever it happened to sit below the floor.
    #>
    param(
        [Parameter(Mandatory = $true)][ValidateSet('M', 'A', 'D')][string]$Status,
        [Parameter(Mandatory = $true)][bool]$LiveContentIsOurs,
        [bool]$MainTouchedSinceFloor = $false
    )

    if ($Status -eq 'D') {
        return [pscustomobject]@{ Action = 'keep-trunk'; Reason = 'only the trunk has this file; a sync never deletes' }
    }

    if ($LiveContentIsOurs) {
        if ($Status -eq 'A') {
            return [pscustomobject]@{ Action = 'keep-trunk'; Reason = 'the trunk deleted this file and live holds our old copy, so it is not resurrected' }
        }
        return [pscustomobject]@{ Action = 'keep-trunk'; Reason = 'live holds a version this repo has had before; the trunk has moved on since' }
    }

    if ($Status -eq 'M' -and $MainTouchedSinceFloor) {
        return [pscustomobject]@{ Action = 'conflict'; Reason = 'live has foreign content AND the trunk changed this path since the last sync -- both sides moved, so neither is taken' }
    }

    return [pscustomobject]@{ Action = 'take-live'; Reason = 'content this repo has never held for this path: a third party wrote it on live' }
}
