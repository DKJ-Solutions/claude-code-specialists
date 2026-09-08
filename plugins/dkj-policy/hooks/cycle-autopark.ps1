<#
.SYNOPSIS
    Stop hook of the contributing plugin: after every turn, put the branch's development cycle on
    origin -- unless a PR has already published it.

.DESCRIPTION
    WHY A HOOK AND NOT A SKILL (issue #900). What another device needs from a branch in flight is the
    PLAN, which phase is running and where the last session stopped, and all three live in
    development.md. Keeping that document current on the remote is not a thing anybody remembers
    to do: `park` and `new-branch -Park` between them produced SIX commits in the whole history, while
    the median merged branch sat invisible on origin for 22 minutes and the worst for 365. By this
    repo's own rule -- what has to happen without anyone asking for it is a hook, what somebody invokes
    is a script in a skill -- the creation push belongs in new-branch and this belongs here.

    THE HOOK IS DELIBERATELY THIN. Every bound, every refusal and every measurement lives in
    park-cycle.ps1, which this invokes with -Quiet: the DEPLOY-lock check that makes it a no-op once a
    PR exists, the trunk guard, the one-document pathspec, and the no-amend/no-force rule. Same shape
    as the two SessionStart hooks beside it, and for the same reason -- a hook that reimplemented any
    of that would be a second answer to a question that already has one.

    -Quiet IS WHAT KEEPS THIS INVISIBLE. A turn that did not touch the document prints nothing at all,
    so the common case adds no line to the session; a push reports itself, because a commit made on
    somebody's behalf should be visible in the transcript that caused it.

    AND THE CHILD'S stderr IS PART OF THE REPORT (issue #1600). This captured stdout only, which is the
    ordinary shape and was wrong here for one reason: a refused push is this workflow's earliest signal
    that a second session is on the same branch, and the sentence naming that -- Get-GitPushFailureMessage's,
    written through Write-Error by Invoke-GitPark -- is on stderr. So the one turn where this hook has
    something urgent to say was the one turn whose most useful line it dropped. park-cycle.ps1 now says
    it on stdout as well, in its own voice and with the other side's author and subject; this capture is
    the second half of that repair, so no future line of the child's can be lost to the stream it chose.
    Measured on feat/plugin-version-overview, September 8, 2026: two sessions ran the same pre-PR review
    in full, each finding real defects the other missed.

    ALWAYS EXITS 0, and never blocks. A Stop hook that fails is a hook that interrupts the work it was
    added to protect, and nothing this does is important enough to strand a turn: the worst outcome of
    a silent failure is a document one turn stale on the remote.

    Read-only with respect to the working tree: it commits and pushes the one document park-cycle
    resolves, and changes nothing else.

    Matcher note: no matcher -- Stop carries none, unlike the SessionStart hooks beside it, which match
    "startup|resume|clear|compact" so their report survives a compaction.

.PARAMETER ScriptOverride
    (Optional, for tests) Use this park-cycle path instead of the ${CLAUDE_PLUGIN_ROOT} one.

.PARAMETER RepoRootOverride
    (Optional, for tests) Passed through to park-cycle.ps1 as the tree to act on.
#>
param(
    [string]$ScriptOverride = '',
    [string]$RepoRootOverride = ''
)

Set-StrictMode -Version Latest

try {
    if ($ScriptOverride) {
        $parkScript = $ScriptOverride
    } elseif ($env:CLAUDE_PLUGIN_ROOT) {
        $parkScript = Join-Path $env:CLAUDE_PLUGIN_ROOT 'scripts\task\park-cycle.ps1'
    } else {
        $parkScript = $null
    }

    # Silent when the script is not there, unlike the session checks, which say so. Those run once at a
    # session start and their notice is the only sign the plugin is half-installed; this runs on every
    # turn, so the same notice would become a line per turn saying nothing new.
    if (-not $parkScript -or -not (Test-Path -LiteralPath $parkScript -PathType Leaf)) { exit 0 }

    $parkArgs = @('-Quiet')
    if ($RepoRootOverride) { $parkArgs += @('-RepoRoot', $RepoRootOverride) }

    # 2>&1 MERGES THE CHILD'S stderr INTO WHAT IS CAPTURED -- see the paragraph in the header for why
    # that one stream carried the line this hook exists to deliver. Windows PowerShell 5.1 wraps each
    # merged stderr line in an ErrorRecord rather than handing over a string, so ToString() below is
    # load-bearing and not defensive: a bare Write-Host of the record prints its own formatting instead
    # of the sentence. $ErrorActionPreference is left alone deliberately -- this file sets no EAP, so it
    # runs at the default 'Continue' and a NativeCommandError cannot terminate the capture the way it
    # would inside the workflow scripts (the #96/#97/#107 pitfall, which is what native-capture-lib.ps1
    # exists for; a hook this thin does not dot-source a lib to run one child).
    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $parkScript @parkArgs 2>&1)
    foreach ($line in $out) {
        if ($null -eq $line) { continue }
        $text = $line.ToString()
        if ($text.Trim()) { Write-Host $text }
    }
} catch {
    # Swallowed on purpose -- see the always-exits-0 paragraph. The message is dropped rather than
    # printed: a hook that reports its own plumbing on every turn is noise, and park-cycle run by hand
    # says everything this could.
}

exit 0
