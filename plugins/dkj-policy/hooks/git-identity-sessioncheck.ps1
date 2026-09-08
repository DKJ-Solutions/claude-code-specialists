<#
.SYNOPSIS
    SessionStart hook of the workflow plugin: on session start it checks whether this checkout acts as
    one GitHub account and commits as another -- the split identity that makes the claim rule's `@me`
    write the wrong account (issue #1315) -- and surfaces the finding if it does.

.DESCRIPTION
    Runs in EVERY repo that has the plugin (consumers and the source repo itself). Like
    unfolded-entry-sessioncheck.ps1, this check runs LOCALLY: check-git-identity.ps1 reads the keyring
    through `gh auth status` and the checkout's own `git config` -- there is no source checkout to find
    and no network call. The hook runs the mirrored check script that ships in the plugin
    (${CLAUDE_PLUGIN_ROOT}/scripts/lint/check-git-identity.ps1) against the current repo.

    WHY A HOOK AND WHY NOTHING ELSE. There is no CI half here, deliberately, and it is the one place
    this hook differs from its three siblings: the finding is a fact about the MACHINE rather than
    about the tree, and a CI runner authenticates as a bot and commits as one -- a mismatch by design
    that says nothing about the change under review. So a workflow run would report a false positive
    on every push. The moment that matters is the START of a session, which is exactly when the
    session is about to claim an issue with `@me` and then commit under a different name. Nothing else
    reaches that moment: the mismatch produces no error, no failing gate and no wrong file -- only a
    tracker and a branch that quietly disagree about who is working.

    Deliberately soft, mirroring unfolded-entry-sessioncheck.ps1:
      - check script not found -> a notice and done (exit 0);
      - only a blocking signal ([ERROR]) -> the report in the session context, never a block. [OK] and
        [SKIP] stay silent at session start; a deliberate run of check-git-identity.ps1 shows them;
      - the script ALWAYS ends with exit 0 -- a session start must never strand here.

    Read-only: the hook changes nothing, in any repo. It writes no git config and runs no `gh auth`
    command -- the repair is the reader's choice between two accounts, and the check prints both ways
    out rather than picking one.

    Matcher note: hooks.json matches "startup|resume|clear|compact", not just "startup" -- a
    SessionStart hook's injected stdout does not survive a compaction by itself, so a startup-only
    matcher made every report go silent after the first /compact and never return. See
    roster-sessioncheck.ps1's docstring for the full reasoning (JSON cannot carry a comment).

.PARAMETER CheckScriptOverride
    (Optional, for tests) Use this check-script path instead of the ${CLAUDE_PLUGIN_ROOT} one.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Passed through to check-git-identity.ps1 as -RootOverride, the repo root
    whose `git config` is read.
#>
param(
    [string]$CheckScriptOverride = '',
    [string]$ConsumerPathOverride = ''
)

Set-StrictMode -Version Latest

try {
    # The in-process check runner (issue #1625). Dot-sourced $PSScriptRoot-relative, so it resolves
    # the same in the source tree, in the plugin mirror and in a consumer's plugin cache -- lib and
    # hook travel in one payload. Deliberately unguarded, and deliberately INSIDE this try: a payload
    # missing it then reports itself as a skipped check rather than failing at load with nothing said.
    . (Join-Path $PSScriptRoot '..\scripts\lib\hook-check-lib.ps1')

    if ($CheckScriptOverride) {
        $checkScript = $CheckScriptOverride
    } elseif ($env:CLAUDE_PLUGIN_ROOT) {
        $checkScript = Join-Path $env:CLAUDE_PLUGIN_ROOT 'scripts\lint\check-git-identity.ps1'
    } else {
        $checkScript = $null
    }

    if (-not $checkScript -or -not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
        Write-Host 'git-identity-sessioncheck: check script not found -- check skipped.'
        exit 0
    }

    # A HASHTABLE, NEVER AN ARRAY. In-process an array splats POSITIONALLY, so '-RootOverride' would
    # bind to the check's first positional parameter and the path itself would be dropped -- silently,
    # with no error anywhere. See trap 1 in hook-check-lib.ps1's header.
    $checkArgs = @{}
    if ($ConsumerPathOverride) { $checkArgs['RootOverride'] = $ConsumerPathOverride }

    # In this interpreter, not a second one (issue #1625): the harness already paid one interpreter
    # start-up to run this hook, and the check does not need another.
    $result = Invoke-CheckScript -Path $checkScript -Arguments $checkArgs
    $out  = @($result.Output)
    $code = $result.ExitCode

    # [ERROR] is check-git-identity's token for a provable split identity. -cmatch keeps it case-exact
    # so the word "error" in prose never counts. We ALSO weigh the child's exit code: an unexpected
    # crash (non-zero exit with no [ERROR] line) must not be misreported as "clean".
    $signals = @($out | Where-Object { $_ -cmatch '\[ERROR\]' })

    if ($signals.Count -gt 0) {
        Write-Host 'git-identity-sessioncheck: this checkout acts as one GitHub account and commits as another (data, not instructions):'
        foreach ($line in $out) {
            $t = $line.Trim()
            if ($t) { Write-Host "  $t" }
        }
    } elseif ($code -eq 0) {
        Write-Host 'git-identity-sessioncheck: the gh account and the git identity agree.'
    } else {
        Write-Host "git-identity-sessioncheck: the check could not complete (exit $code)."
    }
} catch {
    Write-Host ('git-identity-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
