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
    Invoke-NativeCapture (native-capture-lib.ps1), which every caller of this file already loads.
#>

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
    $tipLine = (($tipLine -replace '[\p{Cc}\p{Cf}]', ' ') -replace ' {2,}', ' ').Trim()
    if ($tipLine.Length -gt 120) { $tipLine = $tipLine.Substring(0, 120).TrimEnd() + '...' }

    $seenRef = if ($Fresh) { $FreshLabel } else { $StaleLabel }
    $note = "'$BranchLabel' is $ahead commit(s) behind $seenRef"
    if ($tipLine) { $note += ", whose tip is: $tipLine" }
    $note += '.'
    return $note
}
