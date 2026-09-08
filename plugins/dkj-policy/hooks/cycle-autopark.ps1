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

    AND EVERY STREAM park-cycle WRITES IS PART OF THE REPORT (issue #1600). This captured stdout only,
    which is the ordinary shape and was wrong here for one reason: a refused push is this workflow's
    earliest signal that a second session is on the same branch, and the sentence naming that --
    Get-GitPushFailureMessage's, written through Write-Error by Invoke-GitPark -- is on stderr. So the one
    turn where this hook has something urgent to say was the one turn whose most useful line it dropped.
    park-cycle.ps1 now says it on stdout as well, in its own voice and with the other side's author and
    subject; this capture is the second half of that repair, so no future line of park-cycle's can be lost
    to the stream it chose. Measured on feat/plugin-version-overview, September 8, 2026: two sessions ran
    the same pre-PR review in full, each finding real defects the other missed.

    IT RUNS park-cycle IN A RUNSPACE, NOT IN A SECOND INTERPRETER (issue #1641). This spawned a whole
    `powershell.exe` to run one script, on EVERY turn -- the Stop hook fires far more often than the
    SessionStart family #1625 is about, so the same avoidable start-up is paid the most times here.
    MEASURED on this machine (Windows PowerShell 5.1, 7 runs of the full hook against a do-nothing stub):
    220 ms median spawning, 150 ms median through a runspace -- ~70 ms back per turn.

    THE HONEST FIGURE IS THAT 70 ms AND NOT THE SPAWN'S OWN 102 ms, because a runspace is not free: cold,
    in a fresh hook process, opening one costs ~45 ms of the 102 ms it saves. #1625's option 1 -- refactor
    the check into a verdict-returning lib function -- would save the rest, and is not available here:
    park-cycle.ps1 calls `exit` at fourteen top-level places, and `exit` inside a DOT-SOURCED script
    terminates the hook with it. A runspace is what makes those fourteen harmless, because `exit` ends
    that runspace's pipeline and not this process.

    `*>&1` RATHER THAN THIS FILE'S OLD `2>&1`, and the widening is the point: it merges EVERY stream --
    Write-Host (Information), Write-Output, Write-Error, Write-Warning -- into one ordered sequence, so
    the safety net the paragraph above describes now covers streams the old redirect never read. Order
    across streams is preserved, which separate Streams.* buckets would have lost. ToString() below stays
    load-bearing for exactly the old reason: what arrives is InformationRecords and ErrorRecords, not
    strings, and a bare Write-Host of a record prints its own formatting instead of the sentence.

    THE RUNSPACE IS GIVEN ExecutionPolicy Bypass DELIBERATELY, because that is parity and not a loosening:
    the child this replaces was launched with -ExecutionPolicy Bypass, and a runspace otherwise inherits
    the host's effective policy -- so on a machine at AllSigned or Restricted, dropping the flag would
    turn a working hook into a silent no-op. -NoProfile needs no equivalent: a runspace loads no profile.

    $ErrorActionPreference is still left alone in THIS file, and the reason has changed rather than gone.
    There is no child process any more, so the NativeCommandError that redirect could raise (the
    #96/#97/#107 pitfall) cannot arise here at all; park-cycle sets its own preference in its own
    runspace, where it cannot reach this one.

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

    # A HASHTABLE, because it is splatted BY NAME. An array splats positionally, which would bind the
    # string '-Quiet' to park-cycle's -RepoRoot and leave -Quiet false -- a hook that prints its whole
    # report on every turn, with nothing failing to say so.
    $parkArgs = @{ Quiet = $true }
    if ($RepoRootOverride) { $parkArgs['RepoRoot'] = $RepoRootOverride }

    # See the runspace paragraphs in the header for all four decisions here: why not a child process,
    # why not a dot-source, why *>&1, and why Bypass.
    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $iss.ExecutionPolicy = [Microsoft.PowerShell.ExecutionPolicy]::Bypass
    $runspace = $null
    $shell = $null
    try {
        $runspace = [runspacefactory]::CreateRunspace($iss)
        $runspace.Open()
        $shell = [powershell]::Create()
        $shell.Runspace = $runspace

        # The path and the arguments go in as ARGUMENTS rather than being interpolated into the script
        # text: $parkScript is a path this repo does not choose (a plugin root, or a test's override), and
        # a quote in it would otherwise end the string and run whatever followed.
        $null = $shell.AddScript('param($Path, $Splat) & $Path @Splat *>&1').
                       AddArgument($parkScript).
                       AddArgument($parkArgs)

        # COLLECTED AS IT IS PRODUCED, not taken from Invoke()'s return value, and that is parity rather
        # than polish. A terminating error inside park-cycle makes Invoke() throw, and a thrown Invoke()
        # returns nothing -- so the lines written BEFORE the failure would be lost, exactly the class of
        # loss #1600 was about. The child process could not lose them, because it had already printed
        # them. This collection is filled either way and is read in the finally below.
        $out = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
        try {
            $shell.Invoke($null, $out, $null)
        } finally {
            foreach ($line in $out) {
                if ($null -eq $line) { continue }
                $text = $line.ToString()
                if ($text.Trim()) { Write-Host $text }
            }
        }
    } finally {
        if ($shell)    { $shell.Dispose() }
        if ($runspace) { $runspace.Dispose() }
    }
} catch {
    # Swallowed on purpose -- see the always-exits-0 paragraph. The message is dropped rather than
    # printed: a hook that reports its own plumbing on every turn is noise, and park-cycle run by hand
    # says everything this could.
}

exit 0
