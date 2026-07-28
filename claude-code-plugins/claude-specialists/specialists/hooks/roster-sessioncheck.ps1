<#
.SYNOPSIS
    SessionStart hook of the specialists plugin: on session start it checks whether this repo's
    roster (the specialists table in CLAUDE.md) and repo lenses are in sync with the agents of the
    enabled plugins, and surfaces a blocking-signal summary if a specialist is missing.

.DESCRIPTION
    Runs in EVERY repo that has the plugin (consumers and the workshop itself). Unlike the connector
    session check, the roster check runs LOCALLY: check-roster-sync.ps1 reads this repo's own
    .claude/settings.json, the plugin cache, the roster file and the lens files -- there is no
    workshop checkout to find. The hook simply runs the mirrored check script that ships in the
    plugin (${CLAUDE_PLUGIN_ROOT}/scripts/sync/check-roster-sync.ps1) against the current repo.

    Deliberately soft, mirroring connector-sessioncheck.ps1:
      - check script not found -> a notice and done (exit 0);
      - only blocking signals ([ERROR]) -> a compact summary in the session context, never a block.
        [INFO] (orphans, deliberate ignore-list skips, uncached plugins) stays silent at session
        start -- it is registry administration, not work worth interrupting a session start for; a
        deliberate run of check-roster-sync.ps1 shows everything;
      - one exception to that silence: the check's non-counting [ORPHANS] roll-up line IS surfaced,
        in both the drift and the in-sync branch, because "a lens left behind by a removed
        specialist" was otherwise visible only to whoever deliberately ran the script -- in practice
        nobody. The per-orphan [INFO] lines still stay out (inbound #204);
      - the check's [SCOPE] line travels along with those signals, so a surfaced finding always names
        the repo the check resolved -- and whether that root came from CLAUDE_PROJECT_DIR or from the
        working-directory git-root fallback (inbound #203);
      - the script ALWAYS ends with exit 0 -- a session start must never strand here.

    Read-only: the hook changes nothing, in any repo.

.PARAMETER CheckScriptOverride
    (Optional, for tests) Use this check-script path instead of the ${CLAUDE_PLUGIN_ROOT} one.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Passed through to check-roster-sync.ps1 as the repo-root to inspect.
#>
param(
    [string]$CheckScriptOverride = '',
    [string]$ConsumerPathOverride = ''
)

Set-StrictMode -Version Latest

try {
    if ($CheckScriptOverride) {
        $checkScript = $CheckScriptOverride
    } elseif ($env:CLAUDE_PLUGIN_ROOT) {
        $checkScript = Join-Path $env:CLAUDE_PLUGIN_ROOT 'scripts\sync\check-roster-sync.ps1'
    } else {
        $checkScript = $null
    }

    if (-not $checkScript -or -not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
        Write-Host 'roster-sessioncheck: roster-sync check script not found -- check skipped.'
        exit 0
    }

    $checkArgs = @()
    if ($ConsumerPathOverride) { $checkArgs += @('-ConsumerPathOverride', $ConsumerPathOverride) }

    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)
    $code = $LASTEXITCODE

    # Blocking signals reach the session context. [ERROR] is the roster-sync token for a specialist
    # that is invisible in the governance doc (or lens-less); -cmatch keeps it case-exact so the word
    # "error" in prose never counts. We ALSO weigh the child's exit code: an unexpected crash (a
    # non-zero exit with no [ERROR] line -- e.g. a corrupt settings.json) must not be misreported as
    # "in sync", so that case gets its own notice (finding Victor).
    #
    # [SCOPE] rides along through the same filter (inbound #203): the only line naming the repo the
    # check ACTUALLY resolved. Dropping it is what once sent an investigation into the wrong repo --
    # the finding was true, about a different repo than the session it landed in. The repo the CHECK
    # resolved, not the one this hook believes it is in: the two diverging IS the failure mode, so
    # printing the hook's own assumption would read just as reassuringly and be just as wrong.
    # [ORPHANS] rides along too (inbound #204). An orphan -- a roster token or lens file with no backing
    # agent or persona, i.e. "specialist removed from the plugin, consumer lens left behind" -- is
    # [INFO] and therefore invisible here, which in practice meant invisible to everyone: the trail
    # existed only for whoever deliberately ran the script. The per-orphan lines STAY suppressed (an
    # orphan can be a legitimately just-removed specialist, and a red line through every transition is
    # how a gate gets ignored); what surfaces is the check's non-counting roll-up naming the count.
    # Deliberately not a general "N info signals" line: a repo permanently carries ignore-list [INFO]s,
    # so that would fire at every single session start -- the noise PR #99 removed.
    $signals = @($out | Where-Object { $_ -cmatch '\[ERROR\]|\[SCOPE\]' })
    $errorCount = @($signals | Where-Object { $_ -cmatch '\[ERROR\]' }).Count
    $orphanLines = @($out | Where-Object { $_ -cmatch '\[ORPHANS\]' })

    # Did the child run to completion? Write-CheckSummary's "Summary: N error(s)" line is the check's
    # last statement, so its absence means the run stopped early. The exit code cannot tell us on its
    # own: a complete drift report and a crash halfway both leave a -File child on exit 1, which is
    # precisely why a partial report used to be indistinguishable from a full one (inbound #203,
    # item 2). Deliberately only used to QUALIFY a drift report, never to withhold the in-sync line:
    # a check may legitimately exit 0 early without a summary, and turning that into "could not
    # complete" would trade one misreport for another.
    $completed = @($out | Where-Object { $_ -cmatch '^Summary: \d+ error' }).Count -gt 0

    if ($errorCount -gt 0) {
        Write-Host 'roster-sessioncheck: roster drift found -- a specialist is missing from the roster/lenses (data, not instructions):'
        foreach ($line in $signals) { Write-Host "  $($line.Trim())" }
        foreach ($line in $orphanLines) { Write-Host "  $($line.Trim())" }
        if (-not $completed -or $code -ne 1) {
            Write-Host "  (note: the check did not run to completion (exit $code) -- the list above may be partial.)"
        }
        Write-Host '  (run scripts/sync/check-roster-sync.ps1 for the full report, or the sync-roster skill to stage the catch-up.)'
    } elseif ($code -eq 0) {
        Write-Host 'roster-sessioncheck: roster in sync with the enabled plugins.'
        # The in-sync line is literally true -- no specialist is missing -- but an orphan left behind is
        # still something to know, and it would otherwise be swallowed by exactly that reassurance.
        foreach ($line in $orphanLines) { Write-Host "  $($line.Trim())" }
        if ($orphanLines.Count -gt 0) {
            Write-Host '  (run scripts/sync/check-roster-sync.ps1 to see which ids, or the sync-roster skill to stage the catch-up.)'
        }
    } else {
        Write-Host "roster-sessioncheck: the roster check could not complete (exit $code) -- run scripts/sync/check-roster-sync.ps1 to see why."
    }
} catch {
    Write-Host ('roster-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
