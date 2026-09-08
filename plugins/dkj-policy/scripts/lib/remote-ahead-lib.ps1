<#
.SYNOPSIS
    Composes the "'<branch>' is N commit(s) behind <remote>..." sentence a caller prints when a local ref
    has fallen behind its own remote-tracking ref -- the signal that another session or device has pushed
    work this checkout does not have.

.DESCRIPTION
    EXTRACTED FROM new-branch.ps1 (issue #1450, September 5, 2026), the ONLY place this composition
    existed until open-pr.ps1 needed the same question answered at a second door -- see that script's
    own remote-ahead gate for why a second door was needed at all. A second hand-typed copy was rejected
    on sight: what this composes is free text SOMEBODY ELSE CHOSE (a commit's %an and %s), and stripping
    the control/format characters out of it is exactly the class of subtle, security-relevant text a
    fork is free to drift from. It already had: -Utf8 on the git log call below was added earlier the
    SAME DAY (issue #1446) after an RTL-override in a commit subject passed a non-UTF-8 console's default
    decoding undetected. One definition means that fix cannot exist in one copy and not the other.

    Returns '' when there is nothing to report: no divergence, or the count could not be read. Callers
    compose their own trailing sentence (what to do about it), because new-branch and open-pr point the
    reader at two different next actions -- one a fast-forward on the happy path, the other a refusal.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script. Depends on
    Invoke-NativeCapture (native-capture-lib.ps1), which every caller of this file already loads, and on
    Get-DisplayRef (ref-print-lib.ps1), which it loads itself -- see the dot-source below.
#>

# THE STRIP HAS ONE DEFINITION, AND IT IS NOT HERE (issue #1623). This file held the tree's second copy of
# the control-and-format strip pattern -- described rather than written, because this file's own suite
# counts the literal here and expects none -- while that same suite already policed the pattern's copies
# in new-branch.ps1 and open-pr.ps1. Policing a rule across the callers while keeping a private copy in
# the lib is the shape this repo keeps repairing. Unconditional, and $PSScriptRoot-relative rather than repo-relative, so
# it resolves in the plugin mirror as well as here; release-lib.ps1 loads its two siblings the same way.
# ref-print-lib.ps1 is a leaf with no dependencies of its own, which is what makes it safe to load first.
. (Join-Path $PSScriptRoot 'ref-print-lib.ps1')

function Get-RemoteAheadNote {
    <#
        RepoRoot     -- the repo to run git in.
        LocalRef     -- the ref this checkout actually holds (e.g. 'HEAD', or "refs/heads/$Name").
        RemoteRef    -- the remote-tracking ref to compare against (e.g. "refs/remotes/origin/$Name").
        BranchLabel  -- the branch name as it should read in the sentence.
        FreshLabel   -- how to name RemoteRef when it is known to be current (a fetch just succeeded).
        StaleLabel   -- how to name it when it is not (whatever the last fetch left on disk).
        Fresh        -- which of the two labels applies.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$LocalRef,
        [Parameter(Mandatory = $true)][string]$RemoteRef,
        [Parameter(Mandatory = $true)][string]$BranchLabel,
        [Parameter(Mandatory = $true)][string]$FreshLabel,
        [Parameter(Mandatory = $true)][string]$StaleLabel,
        [Parameter(Mandatory = $true)][bool]$Fresh
    )

    $aheadProbe = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $RepoRoot, 'rev-list', '--count', "$LocalRef..$RemoteRef") -DiscardStderr
    $ahead = 0
    if ($aheadProbe.ExitCode -ne 0 -or -not ([int]::TryParse((($aheadProbe.Output -join '').Trim()), [ref]$ahead)) -or $ahead -le 0) {
        return ''
    }

    # THE SUBJECT AND THE AUTHOR ARE THE POINT, not the count -- see new-branch.ps1's own history of this
    # line for why. -Utf8 IS LOAD-BEARING (issue #1446): without it Windows PowerShell 5.1 decodes git's
    # stdout with [Console]::OutputEncoding, so on a non-UTF-8 console an RTL-override or a zero-width
    # run in someone else's commit subject passes the sanitiser below undetected.
    $tip = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $RepoRoot, 'log', '-1', '--format=%h %an: %s', $RemoteRef) -DiscardStderr -Utf8
    $tipLine = if ($tip.ExitCode -eq 0) { (($tip.Output -join ' ').Trim()) } else { '' }

    # STRIPPED BEFORE IT IS PRINTED: control and format characters go, the words stay. This is the one
    # piece of text here that somebody else wrote, and it is read by both a terminal and an agent session
    # -- an ANSI/OSC escape or an RTL override would deceive either reader, and a crafted subject wearing
    # this script's own warning prefix is an injection surface rather than a display bug.
    $tipLine = Get-DisplayRef -Ref $tipLine
    if ($tipLine.Length -gt 120) { $tipLine = $tipLine.Substring(0, 120).TrimEnd() + '...' }

    # AND THE BRANCH LABEL GOES THROUGH THE SAME STRIP (issue #1623). Two lines above, the commit subject
    # is sanitised for exactly the reason that applies word for word to the name interpolated here -- and
    # this line printed it raw, which is the sharpest instance the issue found. It is not belt-and-braces:
    # `git check-ref-format` accepts \p{Cf}, so a fetched or hand-made branch really can carry U+202E or a
    # zero-width run into this sentence, and open-pr.ps1 hands this function whatever HEAD reads as. The
    # sentence exists to tell the reader WHOSE WORK is on the other side of a divergence, so a label that
    # prints as a different name than it is defeats the whole line.
    $seenRef = if ($Fresh) { $FreshLabel } else { $StaleLabel }
    $shownLabel = Get-DisplayRef -Ref $BranchLabel
    $note = "'$shownLabel' is $ahead commit(s) behind $seenRef"
    if ($tipLine) { $note += ", whose tip is: $tipLine" }
    $note += '.'
    return $note
}
