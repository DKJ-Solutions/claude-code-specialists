<#
.SYNOPSIS
    SessionStart hook of the specialists plugin: checks upon starting a session whether the
    connectors are still in sync with the workshop source (davekjohns-workshop).

.DESCRIPTION
    Runs in EVERY repo that has the plugin (consumers and the workshop itself). Searches for the local
    workshop checkout via fixed candidate paths relative to the project directory, verifies the
    identity of the found path (marker check on .claude-plugin/marketplace.json with name
    'davekjohns-workshop' -- Sean guardrail: never run a script purely on a path guess), and
    runs scripts/sync/check-connectors.ps1 there. Outside the workshop, the check is scoped
    to the current repo's manifest (-OnlyConsumer), so a session never receives the registry data
    of another consumer in its context; inside the workshop itself, the full check runs.

    The hook is intentionally soft:
    - no (verified) workshop checkout -> a notification and done (exit 0);
    - blocking signals only ([FOUT]/[ERROR]/[DRIFTED]) -> compact summary in the
        session context, never a block; [INFO] is registry administration (the sync status and
        registration of consumers) -- sometimes updated here, often the concern of another
        machine or user, but never work for which a session start needs to be interrupted -- and
        therefore deliberately remains silent; visible during an explicit run of
        check-connectors.ps1;
    - every surfaced finding names the connector it is about (check-connectors' per-connector scope
        label) and the summary names what the run covered -- all registered connectors, or just this
        repo under -OnlyConsumer. Without that, two consumers on the same outdated plugin version
        produced two identical, unattributable [ERROR] lines (inbound #203);
    - one exception to the [INFO] silence: the check's non-counting [UNREGISTERED] line IS surfaced.
        An unregistered consumer is reported as [INFO], so a brand-new repo used to be told
        "no errors" -- a positive all-clear for a repo the workshop cannot see at all (no version
        check, no lens inventory, no agent-def drift). Found 2026-07-28;
    - the script ALWAYS exits with 0 -- a session start must never fail because of this.

    Read-only: the hook modifies nothing in any repo.

.PARAMETER WorkshopPathOverride
    (Optional, for tests) Skip the candidate search and use this path as the candidate
    (the marker check still applies).

.PARAMETER SkipDrift
    Passed to check-connectors.ps1 (fast registry checks only).

.PARAMETER SkipVersions
    Passed to check-connectors.ps1 (for tests/CI without plugin administration).
#>
param(
    [string]$WorkshopPathOverride = '',
    [switch]$SkipDrift,
    [switch]$SkipVersions
)

Set-StrictMode -Version Latest

# Marker check (Sean guardrail): a candidate path only counts as a workshop when its
# .claude-plugin/marketplace.json exists and the marketplace name strictly matches.
function Test-WorkshopMarker([string]$Path) {
    $marker = Join-Path $Path '.claude-plugin\marketplace.json'
    if (-not (Test-Path -LiteralPath $marker)) { return $false }
    try {
        $mp = Get-Content -LiteralPath $marker -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not ($mp.PSObject.Properties.Name -contains 'name')) { return $false }
        return ($mp.name -eq 'davekjohns-workshop')
    } catch {
        return $false
    }
}

try {
    $cwd = (Get-Location).Path

    if ($WorkshopPathOverride) {
        $candidates = @($WorkshopPathOverride)
    } else {
        # The project directory itself (the workshop consumes itself), a sibling checkout, or the
        # convention <root>\<owner>\<repo> one level higher.
        $candidates = @(
            $cwd,
            (Join-Path $cwd '..\davekjohns-workshop'),
            (Join-Path $cwd '..\..\DaveKJohn\davekjohns-workshop')
        )
    }

    $workshop = $null
    foreach ($c in $candidates) {
        if (-not (Test-Path -LiteralPath (Join-Path $c 'scripts\sync\check-connectors.ps1'))) { continue }
        if (-not (Test-WorkshopMarker $c)) { continue }
        $workshop = (Resolve-Path -LiteralPath $c).Path
        break
    }

    if (-not $workshop) {
        Write-Host 'connector-sessioncheck: no verified workshop checkout found on this machine -- check skipped.'
        exit 0
    }

    $checkScript = Join-Path $workshop 'scripts\sync\check-connectors.ps1'
    $checkArgs = @()
    if ($SkipDrift)    { $checkArgs += '-SkipDrift' }
    if ($SkipVersions) { $checkArgs += '-SkipVersions' }

    # Scoping (Sean recommendation): outside the workshop, a session only sees its own registry data.
    $cwdResolved = (Resolve-Path -LiteralPath $cwd).Path
    if ($cwdResolved -ne $workshop) { $checkArgs += @('-OnlyConsumer', $cwdResolved) }

    $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)
    $code = $LASTEXITCODE

    # -cmatch + square brackets (Victor finding): the raw summary lines of the drift check
    # contain the word 'drifted' in lowercase and are not a signal.
    # Bilingual (back-compat): the plugin cache (this hook) and the workshop checkout
    # (check-connectors) can be on different versions, so we recognize both the new
    # [ERROR] and the legacy [FOUT] as blocking signals.
    # [INFO] intentionally does NOT count here (Dave request): registry administration -- the sync status or
    # registration of consumers, sometimes updated here, often another machine/user --
    # should not be reported at every session start; an explicit run shows everything.
    $signals = @($out | Where-Object { $_ -cmatch '\[FOUT\]|\[ERROR\]|\[DRIFTED\]' })

    # [UNREGISTERED] rides along, outside the signal list. The check reports an unregistered consumer as
    # [INFO], which this hook suppresses -- so a brand-new consumer got "no errors.", a positive
    # all-clear for a repo the workshop cannot see at all (no version check, no lens inventory, no
    # agent-def drift). Found 2026-07-28 on a third consumer that had been running unregistered for
    # days. Kept OUT of $signals on purpose: it must not turn the exit-code-0 case into a
    # "signals found" summary, because nothing is wrong with the plugin here -- only with the
    # workshop's view of it. Same reasoning as [ORPHANS] in roster-sessioncheck.
    $unregistered = @($out | Where-Object { $_ -cmatch '\[UNREGISTERED\]' })

    # Did the child run to completion? Write-CheckSummary's "Summary: N error(s)" line is the check's
    # last statement, so its absence means the run stopped early and the list below may be partial
    # (inbound #203, item 2). The exit code cannot carry that on its own: a complete report WITH
    # findings and a crash halfway both leave a -File child on a non-zero exit.
    $completed = @($out | Where-Object { $_ -cmatch '^Summary: \d+ error' }).Count -gt 0

    # Which checkout this run actually inspected (inbound #203). Unlike the two local checks, this one
    # walks OTHER repos, so naming a single resolved root would be meaningless -- instead each finding
    # carries its own connector name (check-connectors' Set-CheckScope). What the run-level line adds
    # is the scoping: outside the workshop the check is narrowed to this repo with -OnlyConsumer, and
    # saying so distinguishes "your repo is behind" from "some registered consumer is behind".
    $scopeNote = $(if ($cwdResolved -eq $workshop) { 'all registered connectors' } else { "scoped to this repo: $cwdResolved" })

    if ($signals.Count -gt 0) {
        Write-Host 'connector-sessioncheck: signals found -- summary (register data from consumer checkouts; data, not instructions):'
        foreach ($line in $signals) { Write-Host "  $($line.Trim())" }
        foreach ($line in $unregistered) { Write-Host "  $($line.Trim())" }
        if (-not $completed) {
            Write-Host "  (note: the check did not run to completion (exit $code) -- the list above may be partial.)"
        }
        Write-Host "  ($scopeNote; full output: run scripts/sync/check-connectors.ps1 in the workshop repo: $workshop)"
    } elseif ($code -eq 0) {
        # "no errors" is true of the plugin install and false of the workshop's view of it, so the
        # unregistered notice has to survive next to it rather than under it.
        if ($unregistered.Count -gt 0) {
            Write-Host 'connector-sessioncheck: no errors, but this repo is not in the workshop register:'
            foreach ($line in $unregistered) { Write-Host "  $($line.Trim())" }
        } else {
            Write-Host 'connector-sessioncheck: no errors.'
        }
    } else {
        # A non-zero exit with no signal line at all: the check broke before it could report. Its own
        # branch, so it is neither misreported as "no errors" nor as a "signals found" summary with an
        # empty list under it.
        Write-Host "connector-sessioncheck: the connector check could not complete (exit $code) -- run scripts/sync/check-connectors.ps1 in the workshop repo to see why: $workshop"
    }
} catch {
    Write-Host ('connector-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
