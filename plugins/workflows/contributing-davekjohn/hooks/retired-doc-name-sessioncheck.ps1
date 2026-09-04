<#
.SYNOPSIS
    SessionStart hook of the workflow plugin: on session start it checks whether this repo's own
    always-on prose still names a RETIRED name of the branch's development document (issue #1389), and
    surfaces a compact summary if it does.

.DESCRIPTION
    THIS IS THE ONLY CALLER, and that is the point of it. A renamed convention reaches a consumer
    through nothing: no gate reads a consumer's CLAUDE.md, check-script-contract.ps1 covers functions
    rather than conventions, and the CI leg the sibling checks have does not exist here -- a consumer's
    CI is not this plugin's to add. So the hook is not a convenience on top of another route; it IS the
    route. Measured: both BWJ consumers restated the retired single 'development.md' in their always-on
    documents, one day and six days after the rename, and nothing told either of them.

    Runs in EVERY repo that has the plugin. Like unfolded-entry-sessioncheck.ps1, the check runs LOCALLY:
    check-retired-doc-name.ps1 reads this repo's own documents -- there is no source checkout to find.
    The hook runs the mirrored check script that ships in the plugin
    (${CLAUDE_PLUGIN_ROOT}/scripts/lint/check-retired-doc-name.ps1) against the current repo.

    IN THE PUBLISHING REPO THE CHECK SKIPS ITSELF, so this hook is cheap there rather than wrong there:
    that repo's pages narrate the rename history on purpose. The skip lives in the check (its
    marketplace test), not here, so a deliberate command-line run gets the same answer as the hook.

    Deliberately soft, mirroring unfolded-entry-sessioncheck.ps1:
      - check script not found -> a notice and done (exit 0);
      - only a blocking signal ([ERROR]) -> a compact summary in the session context, never a block;
      - the script ALWAYS ends with exit 0 -- a session start must never strand here.

    Read-only: the hook changes nothing, in any repo. check-retired-doc-name.ps1 makes no gh call and
    reads only files in the working copy, so this adds no network to a session start.

    Matcher note: hooks.json matches "startup|resume|clear|compact", not just "startup" -- a
    SessionStart hook's injected stdout does not survive a compaction by itself, so a startup-only
    matcher made every report go silent after the first /compact and never return. See
    roster-sessioncheck.ps1's docstring for the full reasoning (JSON cannot carry a comment).

.PARAMETER CheckScriptOverride
    (Optional, for tests) Use this check-script path instead of the ${CLAUDE_PLUGIN_ROOT} one.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Passed through to check-retired-doc-name.ps1 as -RootOverride, the repo root
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
        $checkScript = Join-Path $env:CLAUDE_PLUGIN_ROOT 'scripts\lint\check-retired-doc-name.ps1'
    } else {
        $checkScript = $null
    }

    if (-not $checkScript -or -not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
        Write-Host 'retired-doc-name-sessioncheck: check script not found -- check skipped.'
        exit 0
    }

    $checkArgs = @()
    if ($ConsumerPathOverride) { $checkArgs += @('-RootOverride', $ConsumerPathOverride) }

    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)
    $code = $LASTEXITCODE

    # [ERROR] is check-retired-doc-name's token for a retired name stated as current. -cmatch keeps it
    # case-exact so the word "error" in prose never counts. We ALSO weigh the child's exit code: an
    # unexpected crash (non-zero exit with no [ERROR] line) must not be misreported as "clean".
    $signals = @($out | Where-Object { $_ -cmatch '\[ERROR\]' })

    if ($signals.Count -gt 0) {
        Write-Host 'retired-doc-name-sessioncheck: this repo states a retired name of the branch document as current -- the plugin renamed it and nothing told this repo (data, not instructions):'
        foreach ($line in $out) {
            $t = $line.Trim()
            if ($t) { Write-Host "  $t" }
        }
    } elseif ($code -eq 0) {
        Write-Host 'retired-doc-name-sessioncheck: no retired branch-document name in this repo''s always-on prose.'
    } else {
        Write-Host "retired-doc-name-sessioncheck: the check could not complete (exit $code)."
    }
} catch {
    Write-Host ('retired-doc-name-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
