<#
.SYNOPSIS
    The two pure queries the Shopify pre-task sync is built on: where to measure from, and who wins a
    file.

.DESCRIPTION
    Separated from scripts/task/sync-main.ps1 on purpose, and it is not tidiness. The risk in a sync is
    not the policy -- "the trunk wins what the trunk touched" is one sentence -- it is the two QUERIES
    that decide when the policy fires. Both are testable only if they can be loaded without running a
    sync, so they live here and scripts/tests/sync-rules.tests.ps1 exercises them against a fixture
    repository.

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
