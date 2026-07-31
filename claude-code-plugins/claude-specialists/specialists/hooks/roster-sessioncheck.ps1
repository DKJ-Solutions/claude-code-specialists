<#
.SYNOPSIS
    SessionStart hook of the specialists plugin: on session start it checks whether this repo's
    roster (the specialists table in CLAUDE.md) and repo lenses are in sync with the agents of the
    enabled plugins, and surfaces a blocking-signal summary if a specialist is missing.

.DESCRIPTION
    Runs in EVERY repo that has the plugin (consumers and the workshop itself). Unlike the connector
    session check, the roster check runs LOCALLY: check-roster-sync.ps1 reads this repo's own settings
    chain (~/.claude/settings.json, .claude/settings.json, .claude/settings.local.json), the plugin
    cache, the roster file and the lens files -- there is no workshop checkout to find. The hook simply
    runs the mirrored check script that ships in the plugin
    (${CLAUDE_PLUGIN_ROOT}/scripts/sync/check-roster-sync.ps1) against the current repo.

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

    Why hooks.json matches "startup|resume|clear|compact" and not just "startup" (July 28, 2026):
    a SessionStart hook's stdout is added to Claude's context, and that injected text does NOT survive
    a compaction on its own -- the documented way to keep it is to let the hook run again, which it
    only does for the sources its matcher names. Startup-only therefore meant every report here went
    silent after the first /compact or /resume and never came back. 'fork' is deliberately left out: a
    forked session inherits the parent's context, so re-running would only duplicate the report. The
    cost was measured before widening it -- all three hooks together take ~4.6s, less than the
    compaction they now run alongside. hooks.json is JSON and cannot carry a comment, which is why
    this reasoning lives here.

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

    # [BOOTSTRAP] rides along outside the signal list (issue #225). The check emits it INSTEAD of the
    # per-specialist drift when the repo has never been set up, so it arrives on an exit-0 run with no
    # [ERROR] lines at all -- and it gets its own verdict below, because "roster in sync" would be a
    # bald-faced lie for a repo that has no roster. Kept out of $signals on purpose: nothing is wrong
    # with the plugin install, so this must not read as a failure. Same shape as [ORPHANS] here and
    # [UNREGISTERED]/[INVENTORY] in connector-sessioncheck.
    $bootstrapLines = @($out | Where-Object { $_ -cmatch '\[BOOTSTRAP\]' })

    # [NOTHING-ENABLED] rides along the same way (inbound #294). THE DEFECT: this hook reported "roster
    # in sync with the enabled plugins" for a repo with 0 lenses and 0 roster rows, in the very session
    # that had loaded four of its skills and all three of its hooks -- because the check read
    # enabledPlugins from .claude/settings.json only and the enable lived in settings.local.json. With
    # nothing enabled the [BOOTSTRAP] branch cannot fire either (it requires at least one enabled
    # plugin), so the run reached the exit-0 branch below and printed the single most reassuring line
    # this hook owns for the least configured repo it had ever seen.
    #
    # The chain fix in check-roster-sync.ps1 removes the cause; this branch removes the FAILURE SHAPE.
    # "Nothing was enabled, so nothing was compared" is a third state, distinct from drift and from a
    # healthy roster, and it has to be able to say so on its own -- otherwise the next way of arriving
    # at zero enabled plugins (a typo in a plugin id, an enable that moved to a layer nobody reads yet)
    # silently reproduces the same false green. Same reasoning as [BOOTSTRAP]: not an error, because a
    # repo that deliberately enables nothing is not broken -- but never "in sync" either.
    $nothingEnabledLines = @($out | Where-Object { $_ -cmatch '\[NOTHING-ENABLED\]' })

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
        # [NOTHING-ENABLED] rides along here too, for the one state that reaches this branch: a settings
        # layer that does not parse is an [ERROR], and if the readable layers then enable nothing the run
        # arrives with both markers. Without this line the headline would claim "a specialist is missing
        # from the roster/lenses" about a run that compared nothing at all -- the same species of
        # misdescription this whole change is about, one branch over.
        foreach ($line in $nothingEnabledLines) { Write-Host "  $($line.Trim())" }
        if (-not $completed -or $code -ne 1) {
            Write-Host "  (note: the check did not run to completion (exit $code) -- the list above may be partial.)"
        }
        # The remediation used to name 'scripts/sync/check-roster-sync.ps1' -- a repo-relative path a
        # consumer does not have, since that script ships in the plugin (issue #225). Naming the skill
        # is both correct everywhere and the thing a reader can actually act on.
        Write-Host '  (run the sync-roster skill to stage the catch-up.)'
    } elseif ($bootstrapLines.Count -gt 0) {
        # Its own verdict, not folded under the in-sync line and not under drift: "not set up yet" is a
        # different situation from both, with a different action. This is the branch that replaces the
        # 38 [ERROR] lines a fresh consumer used to get from this check alone.
        Write-Host 'roster-sessioncheck: the plugin is enabled but this repo has not been set up yet:'
        foreach ($line in $bootstrapLines) { Write-Host "  $($line.Trim())" }
    } elseif ($nothingEnabledLines.Count -gt 0) {
        # Deliberately worded as what the check DID, not as a verdict about the repo: the honest answer
        # is that nothing was compared. A reader who did expect a plugin here now has the one fact that
        # explains it (which files were consulted), instead of a green line that hides the question.
        Write-Host 'roster-sessioncheck: no plugin is enabled for this repo -- the roster was not checked:'
        foreach ($line in $nothingEnabledLines) { Write-Host "  $($line.Trim())" }
    } elseif ($code -eq 0) {
        Write-Host 'roster-sessioncheck: roster in sync with the enabled plugins.'
        # The in-sync line is literally true -- no specialist is missing -- but an orphan left behind is
        # still something to know, and it would otherwise be swallowed by exactly that reassurance.
        foreach ($line in $orphanLines) { Write-Host "  $($line.Trim())" }
        if ($orphanLines.Count -gt 0) {
            Write-Host '  (run the sync-roster skill to stage the catch-up.)'
        }
    } else {
        Write-Host "roster-sessioncheck: the roster check could not complete (exit $code)."
    }
} catch {
    Write-Host ('roster-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
