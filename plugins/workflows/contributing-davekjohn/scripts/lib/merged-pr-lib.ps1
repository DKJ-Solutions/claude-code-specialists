<#
.SYNOPSIS
    The merged-PR proof, as one source: was THIS ref merged, or only a branch that once wore its name?

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\merged-pr-lib.ps1')

    A MERGED PR PROVES A NAME, NOT A REF. That is the defect class this file owns, and it was repaired
    twice on September 1, 2026 in two neighbouring scripts that did not know about each other:
    sync-main.ps1's standing-predecessor guard (inbound #1190) and prune-merged.ps1's proof (b)
    (inbound #1191). Both repairs were correct and both were the same mechanism, so by the end of that
    day the mechanism existed in two shapes -- and the copies had ALREADY diverged, over the one thing
    the map has to get right (issue #1194). See Get-MergedPrTips for which guard was missing from which.

    THE TRANSPORT IS THE CALLER'S, THE MAP AND THE TEST ARE NOT. Each caller reaches gh differently for
    a reason it documents at its own call site -- sync-main.ps1 asks for '--jq ... @tsv' because a
    tab-separated row is a stronger filter against a gh status line leaking into data it compares refs
    against, and prune-merged.ps1 asks for plain JSON because ConvertFrom-Json is already in the shell
    and needs no quoting through PowerShell into gh on Windows. Neither reason travels to the other, so
    neither transport is shared. What IS shared is everything after it: the normalising, the shape
    validation, the comparer the map is keyed with, and the two-part test. Get-MergedPrTips takes pairs;
    Get-MergedPrTipsFromTsv is the tab-separated transport on top of it.

    PURE: it parses text and compares strings. The caller runs gh and git.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Dependency-free -- it dot-sources nothing, so a caller can load it before or after anything else.
    Pure ASCII (repo convention for .ps1).
#>

function Get-MergedPrTips {
    <#
    .SYNOPSIS
        Name/tip pairs from a merged-PR listing, as a lookup from branch name to the tip commits that
        branch carried when a PR of that name was merged.

    .DESCRIPTION
        A BRANCH NAME IS NOT AN IDENTITY, and that is the whole reason this returns tips rather than the
        list of names both callers replaced. Branch names get recycled -- sync branch names are
        date-stamped, and deleteBranchOnMerge frees ANY name the moment its PR lands -- so a second
        branch of the same name is a genuine, unmerged branch wearing a merged one's name. Matching on
        the bare name reads it as merged. Measured in a consumer on September 1, 2026:
        'sync/live-2026-09-01' merged as PR #141 and deleted, re-created the same day with open PR #159.
        The sync guard reported '1 found on origin, all merged' and pushed a '-2' branch onto the pile it
        exists to prevent (#1190); prune-merged printed 'merged PR' and force-deleted the standing one
        (#1191). One defect, two scripts, opposite losses.

        SO A NAME MAY HOLD SEVERAL TIPS: a recycled name merged twice has two, and each is a real proof
        for the branch that ended on it.

        THE TIP IS 'headRefOid', NEVER 'mergeCommit.oid'. Both reports proposed the merge commit and it
        would never match anything: a squash or a rebase merge writes a NEW commit onto the trunk, so
        mergeCommit.oid is not a commit the head branch ever pointed at, and every branch would read as
        unproven forever. headRefOid is what the head ref held at the moment the PR merged, which is the
        one thing a still-standing ref can be compared against.

        AND IT ANSWERS THE CASE THE BARE NAME WAS ADDED FOR, which is why both callers keep their
        ancestry half as well rather than instead. A merge-commit PR leaves the branch an ancestor of the
        trunk and ancestry settles it. A squash or rebase merge does not -- and on a repo WITHOUT
        delete_branch_on_merge that ref lingers at exactly headRefOid, so this test still recognises it.
        What it no longer does is accept a ref that has MOVED since that merge, which is both the reused
        name above and a branch somebody pushed one more commit to.

        WHAT IS DROPPED, and each of them appears in real output: a null pair, a pair with no name, a
        pair whose tip is empty (@tsv writes a null headRefOid as an empty field, and a JSON row can
        carry a null too), and any tip that is not an object name.

    .PARAMETER Pairs
        The rows, each an object or hashtable with a Name and a Tip. Anything else is dropped.
    #>
    param([object[]]$Pairs = @())

    # ORDINAL, because git refs are case-sensitive and a hashtable's default comparer is not. A name
    # differing only in case names a different branch, and reading the two as one would let a merged
    # 'Sync/live-x' vouch for a standing 'sync/live-x'.
    #
    # THIS IS THE GUARD THE SECOND COPY WAS MISSING (issue #1194). sync-rules.ps1 keyed its map this way
    # and said why; prune-merged.ps1 used a bare '@{}', which is the default comparer, so the two copies
    # disagreed about the one question the map exists to answer -- while both were one day old. That is
    # the argument for this file, made from the inside: a mechanism living twice does not stay one
    # mechanism, and the divergence lands on the guard that is easiest to leave out, because nothing
    # fails without it today.
    $tips = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)

    foreach ($pair in @($Pairs)) {
        if ($null -eq $pair) { continue }
        $name = ([string]$pair.Name).Trim()
        $tip  = ([string]$pair.Tip).Trim().ToLowerInvariant()
        if (-not $name) { continue }
        # A tip that is not an object name is not a tip. Liberal on length (a sha256 repo names 64) and
        # exact on the comparison in Test-RefMergedByPr, so anything odd fails toward 'not merged'.
        if ($tip -notmatch '^[0-9a-f]{7,64}$') { continue }
        if (-not $tips.ContainsKey($name)) { $tips[$name] = New-Object System.Collections.ArrayList }
        if (-not $tips[$name].Contains($tip)) { [void]$tips[$name].Add($tip) }
    }

    return $tips
}

function Get-MergedPrTipsFromTsv {
    <#
    .SYNOPSIS
        Get-MergedPrTips for the tab-separated transport -- one '<name> TAB <sha>' row per merged PR.

    .DESCRIPTION
        THE SHAPE IS THE FILTER, which is why this transport exists beside the object one rather than
        being folded into it. A gh status or progress line carries no tab and so cannot survive
        '<name> TAB <sha>' -- a stronger filter than the name-only parse it replaced, where any stray
        word was a candidate row. Its caller discards stderr for the same reason.

        TAB RATHER THAN A SPACE: a ref name cannot contain one, so no name is ever split by one of its
        own characters. It also keeps the jq expression free of double quotes, which is one less thing
        for the argument quoting between PowerShell and the CLI to have to get right.

        Everything after the split is Get-MergedPrTips's: blanks, a missing name and a tip that is not an
        object name are dropped there, once, for both transports.

    .PARAMETER Lines
        The raw output lines of 'gh pr list --state merged --json headRefName,headRefOid --jq ".[] |
        [.headRefName, .headRefOid] | @tsv"', one '<name> TAB <sha>' row each.
    #>
    param([string[]]$Lines = @())

    $pairs = @()
    foreach ($line in @($Lines)) {
        if ($null -eq $line) { continue }
        $text = ([string]$line).Trim()
        if (-not $text) { continue }
        $tab = $text.IndexOf("`t")
        if ($tab -lt 1) { continue }
        $pairs += [pscustomobject]@{
            Name = $text.Substring(0, $tab)
            Tip  = $text.Substring($tab + 1)
        }
    }

    return Get-MergedPrTips -Pairs $pairs
}

function Test-RefMergedByPr {
    <#
    .SYNOPSIS
        Whether a merged PR proves THIS ref was merged -- its name AND the commit it points at now.

    .DESCRIPTION
        BOTH HALVES, OR THE ANSWER IS NO. The name says a PR of that name once merged; the tip says it
        was this ref. Only the pair is a proof, and requiring the pair is the whole repair in inbound
        #1190 and #1191 -- see Get-MergedPrTips for what the name alone cost in each.

        AN UNKNOWN TIP READS AS 'NOT MERGED'. So an empty tip -- a rev-parse that failed, a ref that
        vanished between the ls-remote and the read -- is never a pass. Both callers err toward doing
        nothing on it, in the direction their own risk points: sync-main REFUSES the run and names its
        override, prune-merged KEEPS the branch. Neither can afford a false pass.

        THE NAME COMPARISON IS ORDINAL, THE TIP COMPARISON IS NOT, and both are decided here rather than
        by the caller. Get-MergedPrTips keys the map with an ordinal comparer, so ContainsKey answers
        case-sensitively for the ref name; a tip is hex and both sides are lowercased, so its case is not
        a question. A caller that matched tips with its own '-contains' would have been case-insensitive
        without meaning to be -- harmless on hex, and exactly the kind of accident that stops being
        harmless once a second copy exists.

        PURE: it compares strings. The caller runs git to find the tip.

    .PARAMETER Name
        The branch name, exactly as the ref names it.

    .PARAMETER Tip
        The commit that ref points at now. Empty means unknown, which is not merged.

    .PARAMETER MergedTips
        The lookup Get-MergedPrTips returned. $null means gh could not answer, which is not merged.
    #>
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Name,
        [string]$Tip = '',
        $MergedTips = $null
    )

    if ($null -eq $MergedTips) { return $false }
    $tip = ([string]$Tip).Trim().ToLowerInvariant()
    if (-not $tip) { return $false }
    if (-not $MergedTips.ContainsKey($Name)) { return $false }

    foreach ($known in @($MergedTips[$Name])) {
        if (([string]$known).Trim().ToLowerInvariant() -eq $tip) { return $true }
    }

    return $false
}

function Test-MergedPrNameKnown {
    <#
    .SYNOPSIS
        Whether ANY merged PR carried this branch name, whatever tip it carried.

    .DESCRIPTION
        THE MIDDLE ANSWER, and it exists so a caller can tell 'the lookup came up empty' from 'the lookup
        came up FULL and belonged to somebody else's work'. prune-merged.ps1 prints a different sentence
        for the second (inbound #1191): "no merged PR" would be a true statement that reads as an absence,
        when what happened is that a previous branch of this name merged and the name was recycled -- and
        that is exactly the branch whose loss the script used to cause, so it is the one case worth naming
        in its output.

        IT IS NOT A PROOF, and it must never be used as one -- which is why it is a separate function
        with its own name rather than a second return value of Test-RefMergedByPr, where a caller reading
        the truthy half would have a name-only match back. Test-RefMergedByPr is the proof; this answers
        only which sentence to print once that one has said no.

    .PARAMETER Name
        The branch name, exactly as the ref names it.

    .PARAMETER MergedTips
        The lookup Get-MergedPrTips returned. $null means gh could not answer, which knows no names.
    #>
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Name,
        $MergedTips = $null
    )

    if ($null -eq $MergedTips) { return $false }
    return [bool]$MergedTips.ContainsKey($Name)
}
