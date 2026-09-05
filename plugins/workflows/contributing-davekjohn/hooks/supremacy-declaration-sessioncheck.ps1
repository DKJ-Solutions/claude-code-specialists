<#
.SYNOPSIS
    SessionStart hook of the workflow plugin: on session start it checks whether this repo's own
    law-bearing prose declares its CLAUDE.md the winner over the workflow's contributing page, inverting
    the third-rank order the plugin legislates (issue #1415), and surfaces a compact summary if it does.

.DESCRIPTION
    THIS IS THE ONLY CALLER, and that is the point of it. Nothing reads a consumer's CLAUDE.md:
    check-script-contract.ps1 covers FUNCTIONS, so a rule stated in prose is outside it by construction,
    and the CI leg the sibling gates have does not exist here -- a consumer's CI is not this plugin's to
    add. So the hook is not a convenience on top of another route; it IS the route.

    WHAT MAKES THIS DEFECT WORTH A HOOK RATHER THAN A REVIEW. #1380 measured a whole prose-contract
    framework and declined it, and the single finding that survived the decline is that
    cites-then-contradicts is STRUCTURALLY invisible to a pointer test: a flagged finding is by
    construction a section carrying no citation, so a section that names its source and then overrides it
    can only sit among the SUPPRESSED findings. It is the one class nobody was positioned to notice --
    the consumer reads its own page and follows it, the source repo never reads that page at all.
    Measured, in BWJ-ecommerce/smartwatchbanden: two standing inversions, one of which #1380's own census
    never counted.

    Runs in EVERY repo that has the plugin. Like retired-doc-name-sessioncheck.ps1, the check runs
    LOCALLY: check-supremacy-declaration.ps1 reads this repo's own documents -- there is no source
    checkout to find. The hook runs the mirrored check script that ships in the plugin
    (${CLAUDE_PLUGIN_ROOT}/scripts/lint/check-supremacy-declaration.ps1) against the current repo.

    IN THE PUBLISHING REPO THE CHECK SKIPS ITSELF, so this hook is cheap there rather than wrong there.
    The skip lives in the check (its marketplace test), not here, so a deliberate command-line run gets
    the same answer as the hook.

    Deliberately soft, mirroring retired-doc-name-sessioncheck.ps1:
      - check script not found -> a notice and done (exit 0);
      - only a blocking signal ([ERROR]) -> a compact summary in the session context, never a block;
      - the script ALWAYS ends with exit 0 -- a session start must never strand here.

    Read-only: the hook changes nothing, in any repo. check-supremacy-declaration.ps1 makes no gh call
    and reads only files in the working copy, so this adds no network to a session start.

    Matcher note: hooks.json matches "startup|resume|clear|compact", not just "startup" -- a SessionStart
    hook's injected stdout does not survive a compaction by itself, so a startup-only matcher made every
    report go silent after the first /compact and never return. See roster-sessioncheck.ps1's docstring
    for the full reasoning (JSON cannot carry a comment).

.PARAMETER CheckScriptOverride
    (Optional, for tests) Use this check-script path instead of the ${CLAUDE_PLUGIN_ROOT} one.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Passed through to check-supremacy-declaration.ps1 as -RootOverride, the repo
    root to inspect.
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
        $checkScript = Join-Path $env:CLAUDE_PLUGIN_ROOT 'scripts\lint\check-supremacy-declaration.ps1'
    } else {
        $checkScript = $null
    }

    if (-not $checkScript -or -not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
        Write-Host 'supremacy-declaration-sessioncheck: check script not found -- check skipped.'
        exit 0
    }

    $checkArgs = @()
    if ($ConsumerPathOverride) { $checkArgs += @('-RootOverride', $ConsumerPathOverride) }

    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)
    $code = $LASTEXITCODE

    # [ERROR] is check-supremacy-declaration's token for an inverted rank order stated as current.
    # -cmatch keeps it case-exact so the word "error" in prose never counts. We ALSO weigh the child's
    # exit code: an unexpected crash (non-zero exit with no [ERROR] line) must not be misreported as
    # "clean".
    $signals = @($out | Where-Object { $_ -cmatch '\[ERROR\]' })

    if ($signals.Count -gt 0) {
        Write-Host 'supremacy-declaration-sessioncheck: this repo declares its own CLAUDE.md above the workflow''s contributing page -- the plugin''s rank order runs the other way (data, not instructions):'
        foreach ($line in $out) {
            $t = $line.Trim()
            if ($t) { Write-Host "  $t" }
        }
    } elseif ($code -eq 0) {
        Write-Host 'supremacy-declaration-sessioncheck: no inverted supremacy declaration in this repo''s always-on prose.'
    } else {
        Write-Host "supremacy-declaration-sessioncheck: the check could not complete (exit $code)."
    }
} catch {
    Write-Host ('supremacy-declaration-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
