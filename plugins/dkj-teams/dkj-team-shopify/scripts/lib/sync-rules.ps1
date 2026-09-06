<#
.SYNOPSIS
    The pure rules the Shopify pre-task sync is built on: where to measure from, whose content a
    path has held, who wins a file -- and the body of the PR that reports all of it.

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

    THE THIRD HALF, ADDED ON INBOUND #1000, IS NOT A QUERY: New-SyncPrBody composes what the sync PR says
    about itself. It sits here for the same reason the queries do -- it is decided entirely by data in
    hand, so the suite can walk it without running a sync -- and it fails in the same silent direction: a
    body that omits a verdict class reads as a complete report of what a third party did.

    THE FOURTH HALF, ADDED ON INBOUND #1021, IS THE ONLY ONE THAT DOES NOT MEASURE AGAINST THE TRUNK.
    Get-SyncBranchNamesFromRefs and Get-SyncPredecessorReport ask whether a PREVIOUS run's branch is
    still standing, because every rule above is complete only while somebody then merges the branch a run
    produces. Its banner further down says what four unmerged branches in seven days looked like from the
    inside, which was: like four normal successful runs.

    THE FIFTH HALF, ADDED ON INBOUND #1382, IS THE SECOND ONE THAT COMPOSES RATHER THAN QUERIES:
    New-SyncLogEntry renders the SAME rows New-SyncPrBody renders, into the durable record a repo keeps
    in its own tree. It reuses Get-SyncPrBodySection and Get-SyncFileKind rather than composing a second
    time -- two composers side by side drift, and the direction they drift in is the silent one above: a
    record that omits a verdict class still reads as complete.

    THE MERGED-PR PROOF IS NOT HERE, AND WAS, until issue #1194. Whether a merged PR proves THIS ref or
    only its recycled name was repaired here (inbound #1190) and in the workflow plugin's prune-merged.ps1
    (#1191) on the same day, independently, and the two copies had already diverged over the comparer
    their map is keyed with. It now lives once, in scripts/lib/merged-pr-lib.ps1, which BOTH plugins
    mirror; sync-main.ps1 dot-sources it beside this file and calls Get-MergedPrTipsFromTsv and
    Test-RefMergedByPr. It is deliberately not dot-sourced from here -- see the dependency-free note
    below, which is a property of this file rather than of the rule.

    DEPENDENCY-FREE, AND DELIBERATELY NOT A READER OF scripts/repo-config.ps1. That file is read by
    dkj-team-shopify's live-theme guard on EVERY command, inside a 'try { . $configPath } catch { return
    $answers }' -- so a fault in anything it pulls in makes that catch fire and the guard continues with
    no live theme id, which is a hole in the one rule that cannot self-declare. The seam answers are
    therefore read by the SCRIPT and passed in as parameters. Every function here takes everything it
    needs from its caller.

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
        The default subject pattern that recognises a previous sync commit -- a .NET regex, not
        git's '--grep', which the lookup no longer uses.

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

        AND THE SEAM CANNOT NARROW AWAY A BODY LINE, WHICH IS WHY THAT ONE IS HANDLED IN THE LOOKUP
        ITSELF. '--grep' is line-oriented over the whole message, so no pattern can distinguish "the
        subject starts with sync" from "a body line starts with sync" -- and any commit that merely
        DISCUSSES a sync, a merge commit carrying the merged subject in its body included, matches.
        No looseness the seam can remove is involved: '^sync' alone picks the same wrong commit.
        So Get-SyncReferencePoint does not use '--grep' at all -- it reads the subject as its own
        field and applies this pattern to that. See its own note for the measurement.
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
        default to "sync everything". WHAT A MISSING FLOOR COSTS IS ONE UNREPORTED CONFLICT, NOT A
        WHOLESALE OVERWRITE, and this docstring used to state the second -- the consequence the time window
        had before inbound #807 replaced it with the content rule. The floor decides no file's winner now:
        Get-SyncFileVerdict consults it in exactly ONE cell, live's content is foreign AND the trunk moved
        the same path, and there it can only ever escalate to a human. So without a floor that
        both-sides-moved case is decided as 'take-live' instead of reported -- the conflict is taken
        silently, which is the failure this refusal exists to stop, arriving as a green run.

        '--no-merges' IS LOAD-BEARING, NOT TIDINESS, and it is the repair for the worst version of that
        same failure -- the one that arrives green while a floor IS reported. '--grep' matches any line
        of a commit message, and a sync branch merged with a merge commit carries the sync commit's own
        subject in its BODY:

            merge: sync/live-2026-08-20 (#27)

            sync: mirror the overlay in sections/media-with-text.liquid from live into main

        So the merge matches the pattern. Right after a sync PR lands that merge is HEAD, the floor
        becomes HEAD, Test-MainTouchedSince answers $false for every path, and every both-sides-moved
        conflict is taken as 'take-live' rather than reported -- with 'Reference point: <sha> (the
        previous sync commit)' printed above it. The seam cannot help: no --grep pattern separates a
        subject from a body line.

        Measured in a consumer on 2026-08-21 (inbound #801): the next sync was about to delete 41 lines
        of translations across two locale files, revert two '| raw' removals, and resurrect 23 locale
        files a commit had deliberately dropped -- 31 files over three merged PRs. Skipping merges can
        only move the floor BACKWARD, onto the sync commit the merge brought in, and backward is the
        protective direction; the regression suite pins both halves.

        BUT '--no-merges' IS NECESSARY AND NOT SUFFICIENT, AND THIS DOCSTRING USED TO CLAIM OTHERWISE.
        It said '--no-merges' separates a subject from a body line. It does not -- it removes merge
        commits and nothing else. An ORDINARY single-parent commit whose body happens to open a line
        with 'sync' still matches '--grep' and still becomes the floor, and a commit message that
        merely DISCUSSES the sync script is enough to do it. Inbound #819 measured it in the consumer
        that had just taken the '--no-merges' repair: the floor landed on a 'fix:' commit whose body
        line read 'sync-main.tests.ps1 goes from 20 to 32 asserts', 48 minutes newer than the real
        previous sync -- 5 commits in floor..HEAD instead of 13, so eight commits of trunk work read
        as untouched and were about to be overwritten by live. Same green run, same failure mode; the
        flag had narrowed the hole rather than closed it. Of the three false positives in that repo's
        history, '--no-merges' caught one.

        Re-measured in THIS repo the same day, where it is starker: the source repo has ZERO commits
        with a sync subject -- it runs no live-theme sync -- and the '--grep' lookup still answered a
        commit, subject 'fix: the Shopify pre-task sync decides by content provenance...', six such
        false positives in 2,012 commits. The truthful answer here is 'no sync commit, fall through to
        the tag', which is what the subject-anchored lookup now gives.

        SO THE PATTERN IS MATCHED AGAINST THE SUBJECT FIELD, AND '--grep' IS GONE. '--no-merges' stays:
        a merge's own subject is 'merge:' while its body carries the sync subject, so it is already
        excluded by the anchoring -- keeping the flag costs nothing and keeps the intent legible.
        The seam is untouched: Get-SyncDefaultReferencePattern and the -Pattern parameter mean exactly
        what they did; only WHERE the pattern is applied changed.

        AND THE PREFILTER WAS DELIBERATELY NOT KEPT, though it would have been correct. Every subject
        is a line of its own message, so '--grep=$Pattern' is a strict superset of the subject match
        and could have narrowed the scan first. It would also make correctness depend on git's POSIX
        basic regex and .NET's engine agreeing about a pattern a CONSUMER supplies through the seam --
        a pattern .NET matches and git's BRE does not would be filtered out before the subject was ever
        read, and the failure would be a floor that is silently too recent. Measured here at 2,012
        commits: the full subject scan costs 94 ms against the old query's 48 ms. 46 ms is not worth a
        second regex engine in the correctness path.
    #>
    param(
        [string]$Ref = 'HEAD',
        [string]$Pattern = (Get-SyncDefaultReferencePattern)
    )

    # The pattern is applied to the SUBJECT FIELD, not through '--grep'. See the note above: '--grep'
    # is line-oriented over the whole message, so the match has to happen outside it. Reading the
    # subject as its own field is the only way to ask the question the rule actually means.
    $sync = Invoke-SyncGitQuiet log --no-merges '--format=%H%x09%s' $Ref |
        Where-Object { $_ -and (($_ -split "`t", 2)[1] -match $Pattern) } |
        Select-Object -First 1
    if ($sync) { return @{ Ref = [string]($sync -split "`t", 2)[0]; Kind = 'sync' } }

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

function Convert-GitQuotedPath {
    <#
    .SYNOPSIS
        A path exactly as git printed it -- C-quoted when it carries a byte above 0x7F -- as the correct
        .NET string, decided by the bytes on the wire rather than by the console code page.

    .DESCRIPTION
        WHY THIS EXISTS, AND WHY THE PREVIOUS FIX WAS ONLY HALF OF ONE (inbound #821, August 21, 2026).
        git quotes a path containing a high byte by default: 'sections/cafe.liquid' with an accent comes
        out as '"sections/caf\303\251.liquid"'. The repair that shipped for that was
        'core.quotePath=false', which makes git emit the RAW UTF-8 bytes instead -- and PowerShell then
        decodes those bytes with [Console]::OutputEncoding, i.e. with whatever console code page the run
        happened to inherit. Measured on git 2.54:

            core.quotePath=true   ->  "sections/caf\303\251.liquid"   (pure ASCII on the wire)
            core.quotePath=false  ->  sections/caf<C3><A9>.liquid     (raw bytes, decoder-dependent)

        On cp850 -- the default OEM console on a Dutch Windows box -- the second form decodes to two
        wrong characters, the path then matches nothing the mirror walk produced, and the sync reaches
        the exact failure the flag was added to prevent: the trunk's copy reads as a path live does not
        have while live's IDENTICAL file reads as content the trunk has never held. Foreign, taken, the
        trunk's version overwritten. The flag fixed the quoting half and left the decoding half.

        SO THE WIRE IS HELD TO ASCII INSTEAD, and this function does the decoding, where no environment
        can reach it: every candidate code page agrees on bytes below 0x80, so the string arrives intact
        however the console is configured, and the escapes are unpacked into bytes here and read as UTF-8
        once. Quoting is FORCED ON at the call site ('-c core.quotePath=true') rather than left to git's
        default, because a repo is free to set core.quotepath in its own config and would otherwise put
        the answer back at the mercy of the decoder.

        THE UNQUOTED FORM PASSES THROUGH UNTOUCHED, which is what makes this safe to apply to every line:
        git quotes only when it must, so an ordinary ASCII path is not wrapped in quotes and is returned
        as it came. A path that is not quoted needs no decoding by definition -- there is nothing above
        0x7F in it.

        Escapes handled: the octal '\NNN' form git uses for high bytes, plus the C escapes it uses for a
        quote, a backslash and the control characters (\a \b \f \n \r \t \v). A backslash before anything
        else is kept as a literal backslash -- git would have escaped it if it meant one, and swallowing
        it would silently shorten a Windows-shaped path.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Path)

    if ($Path.Length -lt 2 -or $Path[0] -ne '"' -or $Path[$Path.Length - 1] -ne '"') { return $Path }

    $inner = $Path.Substring(1, $Path.Length - 2)
    $bytes = New-Object System.Collections.Generic.List[byte]
    $i = 0
    while ($i -lt $inner.Length) {
        $c = $inner[$i]
        if ($c -ne '\') {
            # A quoted path is ASCII by construction, so this cast is the whole story for every real
            # line. The UTF-8 fallback is for a character that cannot be one byte -- unreachable from
            # git and cheap to be right about, rather than a silent truncation if it ever is.
            if ([int][char]$c -lt 0x80) { $bytes.Add([byte][char]$c) }
            else { foreach ($b in [System.Text.Encoding]::UTF8.GetBytes([string]$c)) { $bytes.Add($b) } }
            $i++
            continue
        }
        $i++
        if ($i -ge $inner.Length) { $bytes.Add(0x5C); break }
        $e = $inner[$i]
        if ($e -ge '0' -and $e -le '7') {
            # Exactly three octal digits, which is the only form git writes. Fewer than three left means
            # this is not one of git's escapes, so the backslash is kept literally rather than guessed at.
            if (($i + 2) -lt $inner.Length -and
                $inner[$i + 1] -ge '0' -and $inner[$i + 1] -le '7' -and
                $inner[$i + 2] -ge '0' -and $inner[$i + 2] -le '7') {
                $bytes.Add([byte][Convert]::ToInt32($inner.Substring($i, 3), 8))
                $i += 3
            } else {
                $bytes.Add(0x5C)
            }
            continue
        }
        switch ($e) {
            '"'     { $bytes.Add(0x22); $i++ }
            '\'     { $bytes.Add(0x5C); $i++ }
            'a'     { $bytes.Add(0x07); $i++ }
            'b'     { $bytes.Add(0x08); $i++ }
            'f'     { $bytes.Add(0x0C); $i++ }
            'n'     { $bytes.Add(0x0A); $i++ }
            'r'     { $bytes.Add(0x0D); $i++ }
            't'     { $bytes.Add(0x09); $i++ }
            'v'     { $bytes.Add(0x0B); $i++ }
            default { $bytes.Add(0x5C) }
        }
    }

    return [System.Text.Encoding]::UTF8.GetString($bytes.ToArray())
}

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

# --- THE PR BODY -----------------------------------------------------------------------------------
# The one thing the sync produces that a HUMAN reads, and the only record that drift was ever inspected
# in a repo whose policy is that the sync PR does not wait for a review (inbound #1000). It lives here
# rather than in the task script for the same reason every query above does: it is decided by data in
# hand, so a suite can walk it without running a sync.
#
# WHY THE KIND IS SPELLED OUT PER FILE AND NOT LEFT TO THE STATUS LETTER. Inbound #1000 measured the
# failure in a consumer's own sync PR #350: the body was a flat file list, so nothing in it recorded that
# live had made 'templates/page.back-to-school.json' DISAPPEAR. A reader of a flat list cannot tell a
# deletion from an edit, and a deletion is the one that needs a second look -- so 'gone from live' is
# written out in words. "The diff shows what came in" is true and is not a record: the diff of a sync
# branch shows what was TAKEN, never what live no longer has.
function Get-SyncFileKind {
    <#
    .SYNOPSIS
        The status letter as words, measured against the trunk exactly as Get-SyncFileVerdict measures it.
    #>
    param([Parameter(Mandatory = $true)][ValidateSet('M', 'A', 'D')][string]$Status)

    switch ($Status) {
        'M' { return 'changed on live' }
        'A' { return 'new on live' }
        default { return 'gone from live' }
    }
}

function New-SyncPrBody {
    <#
    .SYNOPSIS
        The default body for the sync PR: what was TAKEN from live and what was HELD BACK, each file with
        its kind and its reason.

    .DESCRIPTION
        Rows are the classified objects the sync builds -- Status ('M'/'A'/'D'), Path and Reason. Both
        halves are listed, because each answers a question the other cannot: the taken half is what a
        third party wrote and the diff also shows, the held-back half is what the rule suppressed and
        nothing else records at all.

        FILES ARE GROUPED BY REASON rather than repeated one reason per line. Every file in a verdict
        class carries the same sentence, so a 31-file sync would otherwise print the same clause 31 times
        and bury the paths -- the shape the report the PR exists for cannot afford.

        The order of the groups, and of the files inside one, is the caller's order. Nothing is sorted
        here: the sync walks the mirror in a fixed order and a body that reorders it stops lining up with
        the console output the operator just read.
    #>
    param(
        [object[]]$Take = @(),
        [object[]]$Keep = @(),
        [string]$Intro = 'Third-party drift from the live theme.'
    )

    $lines = @($Intro)

    $lines += Get-SyncPrBodySection -Rows $Take -Heading 'Taken from live' -EmptyText 'Nothing was taken from live.'
    $lines += Get-SyncPrBodySection -Rows $Keep -Heading 'Held back, the trunk wins' -EmptyText 'Nothing was held back by the content rule.'

    return (($lines -join "`n") + "`n")
}

function Get-SyncPrBodySection {
    <#
    .SYNOPSIS
        One half of the body: a bold heading with its count, then the files grouped under their reason.
    #>
    param(
        [object[]]$Rows = @(),
        [Parameter(Mandatory = $true)][string]$Heading,
        [Parameter(Mandatory = $true)][string]$EmptyText
    )

    $rows = @($Rows | Where-Object { $_ })
    if ($rows.Count -eq 0) { return @('', $EmptyText) }

    $out = @('', "**$Heading ($($rows.Count))**")
    # Insertion-ordered grouping, so the body follows the caller's order rather than a hashtable's. An
    # ordered dictionary is the whole trick; Group-Object would sort and lose it.
    $groups = New-Object System.Collections.Specialized.OrderedDictionary
    foreach ($r in $rows) {
        $reason = [string]$r.Reason
        if (-not $groups.Contains($reason)) { $groups[$reason] = New-Object System.Collections.ArrayList }
        [void]$groups[$reason].Add($r)
    }
    foreach ($reason in @($groups.Keys)) {
        $out += @('', "*$reason*", '')
        foreach ($r in $groups[$reason]) {
            $out += "- $(Get-SyncFileKind -Status ([string]$r.Status)) -- ``$($r.Path)``"
        }
    }
    return $out
}

# ===================================================================================================
# THE FIFTH HALF (inbound #1382): THE SAME ROWS, RENDERED A SECOND TIME, FOR A RECORD THAT STAYS
#
# THE PR BODY IS NOT A RECORD. It is composed once, read at the merge, and then it lives on GitHub and
# nowhere the tree can index -- which matters most in the one repo family whose standing rule is that a
# sync PR does NOT wait for review, so that body is the entire review moment. A sync branch is otherwise
# the only branch that owes nothing durable at all: the entry gate exempts the prefix, nothing folds, and
# the changelog stays clean by design. This makes it symmetric -- a sync owes a SYNC-LOG entry where it
# owes no changelog entry.
#
# A SECOND RENDERING, NEVER A SECOND MEASUREMENT. It takes the rows the run already classified and hands
# them to Get-SyncPrBodySection and Get-SyncFileKind -- the same two functions New-SyncPrBody uses. Two
# composers side by side is the duplication that drifts: the moment a verdict class is added, one of them
# learns about it and the other keeps reporting a complete-looking record that omits it. There is one
# definition of what a row looks like in words, and it has two outputs.
#
# THE HEADING NAMES THE BRANCH, NOT THE PR. The entry is written and committed ON the sync branch, before
# any pull request exists -- and the default seam answer (Get-ShopifySyncMerges $false) means the run
# stops at the push and never learns a number at all. The branch name is the PR's head ref, so
# 'gh pr list --head <branch> --state all' completes the trail; a PR field would be blank on the common
# path, which is worse than a field that is not there.
function New-SyncLogEntry {
    <#
    .SYNOPSIS
        One sync-log entry: a dated heading naming the branch, then what was taken and what was held
        back, each file with its kind and its reason.

    .DESCRIPTION
        Rows are the same classified objects New-SyncPrBody receives -- Status ('M'/'A'/'D'), Path and
        Reason -- and both halves are listed for the same reason they are there: the taken half is what
        a third party wrote, the held-back half is what the rule suppressed and nothing else records.

        NEWEST AT THE TOP is the caller's job, not this function's. This returns one entry; sync-main
        prepends it. The entry therefore opens with its own '## ' heading and ends with a blank line, so
        concatenating two of them needs no separator logic at the call site.

        THE DATE IS A PARAMETER rather than read from the clock here, so the suite can walk it and so the
        entry carries the run's own date rather than whatever moment this line happened to execute at.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Branch,
        [Parameter(Mandatory = $true)][string]$Date,
        [object[]]$Take = @(),
        [object[]]$Keep = @()
    )

    $lines = @("## $Date -- ``$Branch``")

    $lines += Get-SyncPrBodySection -Rows $Take -Heading 'Taken from live' -EmptyText 'Nothing was taken from live.'
    $lines += Get-SyncPrBodySection -Rows $Keep -Heading 'Held back, the trunk wins' -EmptyText 'Nothing was held back by the content rule.'

    return (($lines -join "`n") + "`n`n")
}

# THE PREPEND IS HERE AND THE FILE I/O IS NOT, and the split is this file's own rationale applied: the
# risk in writing a log is not the writing, it is deciding WHERE in the existing text the new entry goes.
# That decision is a string in and a string out, so it is testable without a sync -- and it fails in the
# silent direction, producing a well-formed file with the entry in the wrong place or the old content
# duplicated. sync-main.ps1 keeps the part that touches a disk.
function Add-SyncLogEntry {
    <#
    .SYNOPSIS
        The sync log's full new text: this entry prepended to whatever the file already held.

    .DESCRIPTION
        NEWEST AT THE TOP, UNDER WHATEVER MASTHEAD THE FILE CARRIES. The masthead is defined as
        everything above the first '## ' line, so a repo can put any title, pointer or preamble at the
        top of its log without this function needing to recognise any of it. A file with no '## ' line
        yet has no entries, and the entry goes after whatever is there.

        LF THROUGHOUT, whatever the existing file holds. This runs on Windows and the log is read on
        GitHub; a file that gains CRLF halfway makes every later entry show up as a whole-file diff.
    #>
    param(
        [string]$Existing = '',
        [Parameter(Mandatory = $true)][string]$Entry
    )

    $normalized = ([string]$Existing -replace "`r`n", "`n")
    $lines      = @($normalized -split "`n")
    $anchor     = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -like '## *') { $anchor = $i; break }
    }

    # '-gt 0' AND '-eq 0' ARE TWO ARMS ON PURPOSE, and this is the trap the function exists to contain.
    # '$lines[0..($anchor - 1)]' with an anchor of 0 is '$lines[0..-1]', which PowerShell reads as "index
    # 0 through the LAST index" and hands back the whole file -- so a log with no masthead would be
    # duplicated rather than prepended to, silently, and only on that one shape.
    if ($anchor -gt 0) {
        # The head is joined without its final newline, so the one put back here is the one the split ate.
        return (($lines[0..($anchor - 1)] -join "`n")) + "`n" + $Entry + (($lines[$anchor..($lines.Count - 1)] -join "`n"))
    }
    if ($anchor -eq 0) { return $Entry + ($lines -join "`n") }
    if ($normalized.Trim()) { return $normalized.TrimEnd("`n") + "`n`n" + $Entry }
    return $Entry
}

# ===================================================================================================
# THE FOURTH HALF (inbound #1021): DOES A PREVIOUS RUN'S BRANCH STILL STAND?
#
# Everything above measures this run against the trunk. That is complete only while somebody then MERGES
# the branch a run produces -- and the seam's default (Get-ShopifySyncMerges $false) deliberately stops
# before the merge so a human looks at third-party drift first. Stopping only works while the looking
# happens. A sync branch pushed and never merged leaves the trunk unchanged, so the next run re-measures
# against the same trunk, re-captures the same drift onto a new branch, and so does the one after it.
#
# MEASURED IN A CONSUMER (BWJ-ecommerce/xoxowildhearts, 2026-08-28): four branches in seven days, the
# newest a strict superset of all three predecessors, two of them byte-identical duplicates of each
# other, and a dry run naming the fifth. Nothing errored at any point -- each new branch looks exactly
# like a normal successful run, which is the whole difficulty. The exclusion rule was working correctly
# throughout: it declined 31 files whose content the repo had held before. The gap is downstream of it.
#
# AND THE SCRIPT ALREADY READ ITS OWN OUTPUT, WHICH IS WHY THIS IS TWO PURE FUNCTIONS AND NOT A NEW
# QUERY. The branch-naming loop in sync-main.ps1 checks refs/heads/<branch> and
# refs/remotes/origin/<branch> before settling on a name -- so it SEES the predecessor and draws no
# conclusion from it. The '-2' suffix in that measurement is the predecessor being noticed and
# discarded. What was missing was never the lookup; it was a verdict on what the lookup found.
# ===================================================================================================

function Get-SyncBranchNamesFromRefs {
    <#
    .SYNOPSIS
        The branch names in 'git ls-remote --heads' output that sit under a given branch prefix.

    .DESCRIPTION
        ANCHORED ON 'refs/heads/<prefix>', NEVER ON THE PREFIX ALONE. Two things fall out of that. A
        'tooling/sync-live-something' branch cannot report itself as its own predecessor, because the
        match is on the whole ref rather than on a substring of it. And the prefix is the CALLER's, which
        is the half that matters upstream: Get-ShopifySyncBranchPrefix is a seam whose README says it is
        "yours to set because it has to line up with whatever your PR guardrails and CI exempt". A
        consumer who answered it 'theme-drift/' and got a scan hardcoded to 'sync/' would have a guard
        that finds nothing and never fires -- the same always-silent failure this function exists to end,
        wearing the opposite face.

        WHY ls-remote AND NOT THE LOCAL refs/remotes/origin/* THE NAMING LOOP READS. A tracking ref is
        only as fresh as the last fetch, and a predecessor pushed from another machine has no local ref
        at all. The naming loop can afford that -- a name collision it misses is caught by git on the
        push -- but a predecessor it misses is exactly the branch that stacks.

        WHAT IS DROPPED, and each of them appears in real output: blank lines, git's warning and progress
        lines (no tab, so no ref), and '^{}' peeled refs. A line is read as '<sha> TAB <ref>' because
        that is ls-remote's format; a ref containing a tab is not representable in it.

        PURE: it parses text. The caller runs git.

    .PARAMETER Lines
        The raw output lines of 'git ls-remote --heads origin'.

    .PARAMETER Prefix
        The sync branch prefix, as the seam answered it -- 'sync/live-' by default. Whitespace-only is
        refused rather than treated as a match-everything wildcard: "every branch is a sync branch" is
        never the correct answer, and returning nothing instead would leave the guard inert in silence.
    #>
    param(
        [string[]]$Lines = @(),
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Prefix
    )

    if (-not $Prefix.Trim()) {
        throw "Get-SyncBranchNamesFromRefs: the branch prefix is whitespace. It decides which branches count as this sync's own, so an empty one has no safe reading."
    }

    $anchor = 'refs/heads/' + $Prefix
    $names  = New-Object System.Collections.ArrayList

    foreach ($line in @($Lines)) {
        if ($null -eq $line) { continue }
        $text = [string]$line
        $tab  = $text.IndexOf("`t")
        if ($tab -lt 0) { continue }
        $ref = $text.Substring($tab + 1).Trim()
        if (-not $ref) { continue }
        if ($ref.EndsWith('^{}')) { continue }
        # Ordinal, because git refs are case-sensitive and a prefix differing only in case names a
        # different branch. Erring toward "not a predecessor" here is the same direction the report below
        # errs in, and for the same reason.
        if (-not $ref.StartsWith($anchor, [System.StringComparison]::Ordinal)) { continue }
        $name = $ref.Substring('refs/heads/'.Length)
        if ($name -and -not $names.Contains($name)) { [void]$names.Add($name) }
    }

    return @($names)
}

function Get-SyncPredecessorReport {
    <#
    .SYNOPSIS
        Per standing sync branch: whether this run's take set covers every path that branch captured,
        and which paths it does not.

    .DESCRIPTION
        SUPERSESSION IS MEASURED ON PATHS, NEVER ON CONTENT, and that is stated rather than assumed. Each
        run writes live's CURRENT bytes, so a path both runs captured is fresher in this one by
        construction -- which is what makes a path-level answer sound for the ordinary case. The case it
        does not cover: a path a third party REVERTED on live between the two runs is no longer drift, so
        this run never captures it, and it lands in Uncovered. That is correct output rather than a miss --
        the predecessor holds a version of that file which nothing else does, and the operator has to
        decide. It is also exactly what an override on the caller's refusal exists for.

        CASE-SENSITIVE PATH COMPARISON, chosen for its failure direction rather than for correctness on
        Windows. Ordinal matching can report a covered path as uncovered where two spellings differ only
        in case; the cost is a supersession this run declines to claim, so nobody is told to close a PR.
        Case-insensitive matching fails the other way -- it would call a path covered that this run never
        wrote, and closing the predecessor on that verdict loses the only copy of the drift. Git itself is
        case-sensitive, so the strict reading is also the true one.

        PURE: it compares two sets of strings. The caller runs git to build both.

    .PARAMETER Predecessors
        One object per standing branch, each carrying 'Branch' (the name) and 'Paths' (what it captured).

    .PARAMETER TakePaths
        The paths THIS run has decided to take.
    #>
    param(
        [object[]]$Predecessors = @(),
        [string[]]$TakePaths = @()
    )

    $taken = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($p in @($TakePaths)) {
        if ($null -ne $p -and ([string]$p).Trim()) { [void]$taken.Add(([string]$p).Trim()) }
    }

    $out = New-Object System.Collections.ArrayList

    foreach ($pred in @($Predecessors | Where-Object { $_ })) {
        $paths = @(@($pred.Paths) |
            Where-Object { $null -ne $_ -and ([string]$_).Trim() } |
            ForEach-Object { ([string]$_).Trim() })
        $uncovered = New-Object System.Collections.ArrayList
        foreach ($path in $paths) {
            if (-not $taken.Contains($path)) { [void]$uncovered.Add($path) }
        }

        # A PREDECESSOR THAT CAPTURED NOTHING IS NOT SUPERSEDED, and the report has to say so. An empty
        # path set makes the covers-everything test vacuously true, which would present a branch this run
        # knows nothing about as safely replaceable by it. It reaches here from a branch whose diff
        # against the trunk could not be read -- a ref that vanished between the ls-remote and the diff,
        # or a clone without its objects -- so "unknown" is the honest verdict and Superseded stays false.
        [void]$out.Add([pscustomobject]@{
            Branch     = [string]$pred.Branch
            Captured   = $paths.Count
            Uncovered  = @($uncovered)
            Superseded = ($paths.Count -gt 0 -and $uncovered.Count -eq 0)
        })
    }

    return @($out)
}
