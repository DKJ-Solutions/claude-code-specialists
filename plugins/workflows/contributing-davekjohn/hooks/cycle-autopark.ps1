<#
.SYNOPSIS
    Stop hook of the contributing plugin: after every turn, put the branch's development cycle on
    origin -- unless a PR has already published it.

.DESCRIPTION
    WHY A HOOK AND NOT A SKILL (issue #900). What another device needs from a branch in flight is the
    PLAN, which phase is running and where the last session stopped, and all three live in
    development-cycle.md. Keeping that document current on the remote is not a thing anybody remembers
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

    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $parkScript @parkArgs)
    foreach ($line in $out) { if ($line -and $line.ToString().Trim()) { Write-Host $line } }
} catch {
    # Swallowed on purpose -- see the always-exits-0 paragraph. The message is dropped rather than
    # printed: a hook that reports its own plumbing on every turn is noise, and park-cycle run by hand
    # says everything this could.
}

exit 0
