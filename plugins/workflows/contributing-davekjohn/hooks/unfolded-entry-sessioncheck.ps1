<#
.SYNOPSIS
    SessionStart hook of the workflow plugin: on session start it checks whether the trunk carries a
    branch's development document that the fold should have removed -- a fold that never ran after a
    merge (issue #1270) -- and surfaces a blocking-signal summary if it finds one.

.DESCRIPTION
    Runs in EVERY repo that has the workflow plugin (consumers and the source itself). Like the roster
    and script-contract checks, this one runs LOCALLY: check-unfolded-entry.ps1 reads the current
    repo's trunk ref (origin/<trunk> if present, else the local branch) -- there is nothing remote to
    fetch. The hook runs the mirrored check that ships in the plugin
    (${CLAUDE_PLUGIN_ROOT}/scripts/sync/check-unfolded-entry.ps1) against the current repo.

    Deliberately soft, mirroring script-contract-sessioncheck.ps1:
      - check script not found -> a notice and done (exit 0);
      - only blocking signals ([ERROR]) -> a compact summary in the session context, never a block.
        [OK] stays silent at session start; a deliberate run of check-unfolded-entry.ps1 shows
        everything;
      - the check's [SCOPE] line travels along with those signals, so a surfaced finding always names
        the repo the check resolved -- and how that root was resolved (inbound #203);
      - the script ALWAYS ends with exit 0 -- a session start must never strand here.

    Read-only: the hook changes nothing, in any repo.

    Matcher note: hooks.json matches "startup|resume|clear|compact", not just "startup" -- a
    SessionStart hook's injected stdout does not survive a compaction by itself, so a startup-only
    matcher made every report go silent after the first /compact and never return. See
    roster-sessioncheck.ps1's docstring for the full reasoning (JSON cannot carry a comment).

.PARAMETER CheckScriptOverride
    (Optional, for tests) Use this check-script path instead of the ${CLAUDE_PLUGIN_ROOT} one.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Passed through to check-unfolded-entry.ps1 as the repo-root to inspect.

.PARAMETER TrunkRefOverride
    (Optional, for tests) Passed through to check-unfolded-entry.ps1 as the ref to inspect.
#>
param(
    [string]$CheckScriptOverride = '',
    [string]$ConsumerPathOverride = '',
    [string]$TrunkRefOverride = ''
)

Set-StrictMode -Version Latest

try {
    if ($CheckScriptOverride) {
        $checkScript = $CheckScriptOverride
    } elseif ($env:CLAUDE_PLUGIN_ROOT) {
        $checkScript = Join-Path $env:CLAUDE_PLUGIN_ROOT 'scripts\sync\check-unfolded-entry.ps1'
    } else {
        $checkScript = $null
    }

    if (-not $checkScript -or -not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
        Write-Host 'unfolded-entry-sessioncheck: check script not found -- check skipped.'
        exit 0
    }

    $checkArgs = @()
    if ($ConsumerPathOverride) { $checkArgs += @('-ConsumerPathOverride', $ConsumerPathOverride) }
    if ($TrunkRefOverride)     { $checkArgs += @('-TrunkRefOverride', $TrunkRefOverride) }

    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)
    $code = $LASTEXITCODE

    # Blocking signals reach the session context. [ERROR] is this check's token for a development
    # document committed on the trunk -- a fold that never ran after a merge; -cmatch keeps it
    # case-exact so the word "error" in prose never counts. The exit code is weighed too: an
    # unexpected crash (a non-zero exit with no [ERROR] line) must not read as "clean".
    #
    # [SCOPE] rides along through the same filter (inbound #203): the only line naming the repo the
    # check actually resolved, and how. Dropping it is what once sent an investigation into the wrong
    # repo.
    $signals = @($out | Where-Object { $_ -cmatch '\[ERROR\]|\[SCOPE\]' })
    $errorCount = @($signals | Where-Object { $_ -cmatch '\[ERROR\]' }).Count

    # Did the child run to completion? Write-CheckSummary's "Summary: N error(s)" line is the check's
    # last statement, so its absence means the run stopped early. Only used to QUALIFY a drift report,
    # never to withhold the clean line -- a check may legitimately exit 0 early.
    $completed = @($out | Where-Object { $_ -cmatch '^Summary: \d+ error' }).Count -gt 0

    if ($errorCount -gt 0) {
        Write-Host 'unfolded-entry-sessioncheck: a branch development document is on the trunk -- a fold was skipped after a merge (data, not instructions):'
        foreach ($line in $signals) { Write-Host "  $($line.Trim())" }
        if (-not $completed -or $code -ne 1) {
            Write-Host "  (note: the check did not run to completion (exit $code) -- the list above may be partial.)"
        }
        # The findings above already carry the exact fold command. On the trunk a fold runs under the
        # fold exception (a commit straight onto the trunk), which is the release manager's to make.
        Write-Host '  (folding on the trunk is the release-manager step; the lines above name the command.)'
    } elseif ($code -eq 0) {
        Write-Host 'unfolded-entry-sessioncheck: no unfolded branch document on the trunk.'
    } else {
        Write-Host "unfolded-entry-sessioncheck: the check could not complete (exit $code)."
    }
} catch {
    Write-Host ('unfolded-entry-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
