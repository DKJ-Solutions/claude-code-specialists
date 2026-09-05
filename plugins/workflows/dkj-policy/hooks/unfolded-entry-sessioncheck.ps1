<#
.SYNOPSIS
    SessionStart hook of the workflow plugin: on session start it checks whether the trunk carries an
    unfolded changelog entry -- a development-*.md that a merge landed but whose fold never ran
    (issue #1270) -- and surfaces a compact summary if it does.

.DESCRIPTION
    Runs in EVERY repo that has the plugin (consumers and the source repo itself). Like
    script-contract-sessioncheck.ps1, this check runs LOCALLY: check-unfolded-entry.ps1 reads this
    repo's own dkj-policy/ directory -- there is no source checkout to find. The hook runs
    the mirrored check script that ships in the plugin
    (${CLAUDE_PLUGIN_ROOT}/scripts/lint/check-unfolded-entry.ps1) against the current repo.

    WHY A HOOK AND NOT ONLY THE CI WORKFLOW. The CI workflow (.github/workflows/unfolded-entry.yml)
    catches a skipped fold regardless of who merged, but it only exists in the source repo and it does
    not reach a specialists session. Chris's lens (verify-stand-against-repo) already tells a session
    to check at start that no development-<branch>.md sits on the trunk -- "a copy sitting on main is a
    silent half-state" -- but that is a MANUAL check a session may or may not run. This automates it,
    so the session that would repair the leftover (fold it) is told at start.

    Deliberately soft, mirroring script-contract-sessioncheck.ps1:
      - check script not found -> a notice and done (exit 0);
      - only a blocking signal ([ERROR]) -> a compact summary in the session context, never a block.
        [OK] stays silent at session start; a deliberate run of check-unfolded-entry.ps1 shows it;
      - the script ALWAYS ends with exit 0 -- a session start must never strand here.

    Read-only: the hook changes nothing, in any repo. check-unfolded-entry.ps1 makes no gh call, so
    this adds no network to a session start.

    Matcher note: hooks.json matches "startup|resume|clear|compact", not just "startup" -- a
    SessionStart hook's injected stdout does not survive a compaction by itself, so a startup-only
    matcher made every report go silent after the first /compact and never return. See
    roster-sessioncheck.ps1's docstring for the full reasoning (JSON cannot carry a comment).

.PARAMETER CheckScriptOverride
    (Optional, for tests) Use this check-script path instead of the ${CLAUDE_PLUGIN_ROOT} one.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Passed through to check-unfolded-entry.ps1 as -RootOverride, the repo root
    to inspect.
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
        $checkScript = Join-Path $env:CLAUDE_PLUGIN_ROOT 'scripts\lint\check-unfolded-entry.ps1'
    } else {
        $checkScript = $null
    }

    if (-not $checkScript -or -not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
        Write-Host 'unfolded-entry-sessioncheck: check script not found -- check skipped.'
        exit 0
    }

    $checkArgs = @()
    if ($ConsumerPathOverride) { $checkArgs += @('-RootOverride', $ConsumerPathOverride) }

    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)
    $code = $LASTEXITCODE

    # [ERROR] is check-unfolded-entry's token for a written entry stranded on the trunk. -cmatch keeps
    # it case-exact so the word "error" in prose never counts. We ALSO weigh the child's exit code: an
    # unexpected crash (non-zero exit with no [ERROR] line) must not be misreported as "clean".
    $signals = @($out | Where-Object { $_ -cmatch '\[ERROR\]' })

    if ($signals.Count -gt 0) {
        Write-Host 'unfolded-entry-sessioncheck: an unfolded changelog entry is sitting on the trunk -- a merge landed but its fold never ran (data, not instructions):'
        foreach ($line in $out) {
            $t = $line.Trim()
            if ($t) { Write-Host "  $t" }
        }
    } elseif ($code -eq 0) {
        Write-Host 'unfolded-entry-sessioncheck: no unfolded changelog entry on the trunk.'
    } else {
        Write-Host "unfolded-entry-sessioncheck: the check could not complete (exit $code)."
    }
} catch {
    Write-Host ('unfolded-entry-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
