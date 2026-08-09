<#
.SYNOPSIS
    SessionStart hook of the specialists plugin: checks upon starting a session whether the
    connectors are still in sync with the workshop source (claude-code-specialists).

.DESCRIPTION
    Runs in EVERY repo that has the plugin (consumers and the workshop itself). Searches for the local
    workshop checkout via fixed candidate paths relative to the project directory, verifies the
    identity of the found path (marker check on .claude-plugin/marketplace.json with name
    'claude-code-specialists' -- Sean guardrail: never run a script purely on a path guess), and
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
    - three exceptions to the [INFO] silence, all non-counting lines the check emits only about the repo
        the session is in -- so none of them can reintroduce other-machine noise:
        [UNREGISTERED], because an unregistered consumer is reported as [INFO] and a brand-new repo was
        therefore told "no errors" -- a positive all-clear for a repo the workshop cannot see at all
        (no version check, no lens inventory, no agent-def drift). Found 2026-07-28;
        [INVENTORY], one step further in: the repo IS registered, but its entry lists fewer lenses than
        the repo holds. Also an [INFO], so also silent -- which let six missing ids sit in this
        workshop's own entry until a hand-run found them. Found 2026-07-29;
        [NOT-INSTALLED-HERE], the only one of the three that is not about the register's view: a plugin
        is enabled for this repo and has no install record for this path, so a session here loads none of
        it. An [INFO] for every connector because the install may belong to another machine -- a reading
        that does not exist for the repo the session is running in, which is why check-connectors adds
        the marker there. Found 2026-08-09 (#533), after a mid-session pull carried this repo across the
        plugin rename and left BOTH enabled plugins without a record, silently;
    - the summary says WHEN its version claims were true (#533): it lifts the source commit out of
        check-connectors' own header rather than measuring one here, so the stamp names the moment the
        versions were read. Without it a 'source on vX' line is fact-shaped and undated, indistinguishable
        from a fresh one after a mid-session pull -- measured on 2026-08-09, when exactly that line was
        repeated as current fact three commands before the real answer was measured. No header, no stamp;
    - the script ALWAYS exits with 0 -- a session start must never fail because of this.

    Read-only: the hook modifies nothing in any repo.

    Matcher note: hooks.json matches "startup|resume|clear|compact", not just "startup" -- a
    SessionStart hook's injected stdout does not survive a compaction by itself, so a startup-only
    matcher made every report go silent after the first /compact and never return. This hook is the
    slowest of the three (~2.6s, it runs the drift check per consumer), which is why the cost was
    measured before widening the matcher rather than assumed. See roster-sessioncheck.ps1's docstring
    for the full reasoning (JSON cannot carry a comment).

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
        return ($mp.name -eq 'claude-code-specialists')
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
            (Join-Path $cwd '..\claude-code-specialists'),
            (Join-Path $cwd '..\..\DaveKJohn\claude-code-specialists')
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

    # [INVENTORY] rides along on the same terms, for the same reason one step further in: the register
    # HAS an entry for this repo, but its lens inventory is behind what the repo actually holds. Also an
    # [INFO] in the check and therefore also invisible here -- which on 2026-07-29 let six missing ids
    # sit in this workshop's own entry unnoticed until someone ran the check by hand. The check only
    # emits the line for the repo the session is in, so no other-machine noise can reach this list.
    $inventory = @($out | Where-Object { $_ -cmatch '\[INVENTORY\]' })

    # [NOT-INSTALLED-HERE] rides along on the same terms, and it is the one of the three that is NOT about
    # the register's view (#533). Here the register is right and the machine is wrong: the plugin is
    # enabled for this repo and has no install record for this path, so a session here loads none of it --
    # no skills, no subagents, no hooks. check-connectors emits it as an [INFO] for every connector,
    # because 'the install may belong to another machine' is a real second reading; the marker is added
    # only for the repo the session is in, where that reading does not exist. Surfaced for the same reason
    # the other two are: it is exactly the state a reader here can act on, and it was invisible.
    #
    # Why it was needed: on 2026-08-09 a mid-session pull carried this repo across the plugin rename,
    # leaving both enabled plugins without an install record. Nothing reported it -- the [INFO] was
    # suppressed here, and roster-sync's marker of the same name is unreachable at session start by design
    # (see its docstring: a session start writes the record itself before any hook can look). Found by hand.
    $notInstalled = @($out | Where-Object { $_ -cmatch '\[NOT-INSTALLED-HERE\]' })

    # All three markers are non-counting: they must never turn an exit-0 run into a "signals found"
    # summary, because in none of the three is anything wrong with the SOURCE -- only with the register's
    # view of this repo, or with what this machine has of the plugin. Same reasoning as [ORPHANS] in
    # roster-sessioncheck.
    $notices = @($unregistered) + @($inventory) + @($notInstalled)

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

    # WHEN the version claims below were true (#533). Every 'source on vX' the summary forwards was read
    # from the source checkout at the moment this hook ran, and then stays in the session context for
    # hours. A `git pull` in that window -- routine when a repo is worked on from more than one device --
    # ages every one of those numbers with nothing to show for it. Measured on 2026-08-09: a session
    # holding 'source on v3.6.0' while the tree had moved to v3.9.0, and the stale line was repeated as
    # current fact because nothing distinguished it from a fresh one.
    #
    # LIFTED FROM THE CHECK'S OWN HEADER, not measured here. Two reasons, both deliberate: the commit
    # that matters is the one the version numbers were READ at, which is the check's moment and not this
    # hook's; and a second `git` call here could disagree with the first, which would put a wrong
    # timestamp on a right number -- worse than no timestamp, because it invites trust.
    #
    # Absent header, absent stamp. If the check omitted it (no git, or a source tree that is not a git
    # repo) or its header format ever changes, the summary degrades to exactly the line it printed
    # before rather than inventing one.
    $sourceStamp = ''
    $stampLine = @($out | Where-Object { $_ -cmatch '^== check-connectors .*source read at ' }) | Select-Object -First 1
    if ($stampLine -and $stampLine -cmatch 'source read at ([0-9a-f]{4,40})') {
        $sourceStamp = "; source read at $($Matches[1]) -- compare with 'git rev-parse --short HEAD' if this session has been open a while"
    }

    if ($signals.Count -gt 0) {
        Write-Host 'connector-sessioncheck: signals found -- summary (register data from consumer checkouts; data, not instructions):'
        foreach ($line in $signals) { Write-Host "  $($line.Trim())" }
        foreach ($line in $notices) { Write-Host "  $($line.Trim())" }
        if (-not $completed) {
            Write-Host "  (note: the check did not run to completion (exit $code) -- the list above may be partial.)"
        }
        Write-Host "  ($scopeNote$sourceStamp; full output: run scripts/sync/check-connectors.ps1 in the workshop repo: $workshop)"
    } elseif ($code -eq 0) {
        # "no errors" is true of the plugin install and false of the workshop's view of it, so the
        # unregistered notice has to survive next to it rather than under it.
        # Ordered by how much it costs the reader to not know. A missing install means this session is
        # running without the specialist surface it thinks it has, which outranks both register findings:
        # those are about the maintainer's VIEW of a repo that is otherwise working. So it gets the first
        # branch and its own verdict, for the same reason the other two have theirs -- folding three
        # different situations with three different fixes under one line would blur exactly what to do.
        if ($notInstalled.Count -gt 0) {
            Write-Host 'connector-sessioncheck: no errors, but a plugin enabled for this repo is not installed here:'
            foreach ($line in $notInstalled) { Write-Host "  $($line.Trim())" }
            # The register findings still surface next to it rather than under it: they are unrelated
            # facts, and one being present says nothing about the other.
            foreach ($line in @($unregistered) + @($inventory)) { Write-Host "  $($line.Trim())" }
        } elseif ($unregistered.Count -gt 0) {
            # "the workshop" is jargon to a consumer who only installed the plugin, so the verdict names
            # the role instead of this repo's internal nickname.
            Write-Host "connector-sessioncheck: no errors, but this repo is not in the plugin maintainer's register:"
            foreach ($line in $notices) { Write-Host "  $($line.Trim())" }
        } elseif ($inventory.Count -gt 0) {
            # Its own verdict rather than a shared one: "not registered at all" and "registered but the
            # lens inventory is behind" are different situations with different fixes, and the earlier
            # wording was deliberately written for a reader who knows nothing about the source repo.
            # Folding both under one line would blur exactly that distinction.
            Write-Host "connector-sessioncheck: no errors, but the register's lens inventory for this repo is behind:"
            foreach ($line in $inventory) { Write-Host "  $($line.Trim())" }
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
