<#
.SYNOPSIS
    The source-repo guard: refuse a shared script that is running from a copy outside the repo it is
    maintained in, when that repo holds its own copy of the very same script.

.DESCRIPTION
    WHY THIS EXISTS, MEASURED THREE TIMES ON AUGUST 12, 2026. Every skill page prints
    '${CLAUDE_PLUGIN_ROOT}/scripts/...', which is the only path that resolves for a consumer -- and the
    harness expands it to the reader's own plugin cache BEFORE the page is read. So in the repo these
    scripts are maintained in, the command in front of you looks authoritative and points at the last
    RELEASED mirror, which lags this tree by however many merges have landed since. Measured against
    mirror 4.5.0:

      * new-branch scaffolded the retired three-tier ladder instead of Tier 0 + the repo's audience tier,
        and rewrote branch/templates/branch_template_changelog.md back into the pre-audience shape;
      * session-status reported no release note under releases/notes/ and printed an EMPTY
        "what the last release left open" block;
      * and a third instance was produced by the session that built this guard, on its own first command.

    Not one of the three errored. Both failures produce a plausible result, and both land on the commands
    that START a piece of work, so a wrong answer propagates into everything downstream. The prose repair
    shipped first (a sentence beside every printed command, plus the measurement in scripts/README.md);
    this is the mechanism behind it.

    THE TEST IS NOT "AM I IN THE PLUGIN CACHE". It is: does the repo being operated on hold its own copy
    of the script now running? That question needs no knowledge of where plugin caches live, survives a
    harness that relocates them, and answers itself correctly for a consumer -- who has no copy, and is
    therefore never refused. Three conditions, all of which must hold:

      1. the running script sits OUTSIDE the repo root. Its own in-repo mirror under plugins/*/scripts/
         is deliberately allowed: lint check 8 holds that byte-identical to the source, so running it is
         not the staleness this guard is about;
      2. the repo publishes plugins at all -- it has a .claude-plugin/marketplace.json. This is the
         condition that keeps a consumer out of it. A consumer who happens to carry an abandoned vendored
         copy under scripts/ would otherwise be refused on the strength of a file they no longer use;
      3. that local copy actually exists, at the same path below scripts/ as the running script.

    WHAT DELIBERATELY DOES NOT CARRY THE GUARD, and it is a gap rather than an oversight (Dave,
    August 12, 2026): check-roster-sync.ps1 and check-script-contract.ps1. Both SessionStart hooks invoke
    those two from '${CLAUDE_PLUGIN_ROOT}/scripts/sync/', by design, against the current repo -- so a
    refusal there would fail every session start in the source repo. Measured before choosing the scope
    rather than discovered afterwards. The two scripts read a lagging registry in this repo and nothing
    reports it; closing that needs the hooks to pass an explicit bypass, which is more surface than the
    defect warrants today.

    THE LIB MUST TRAVEL WITH THE MIRROR, and that is not a nicety: the guard only ever fires from inside
    the copy that a reader wrongly ran, so a guard that stayed behind in the source tree could never fire
    at all. It is registered in shared-scripts-lib.ps1 as a LibOnly pair for exactly that reason.

    Dot-source it $PSScriptRoot-relative and guarded, so a tree that does not carry it degrades to the
    behaviour of the day before rather than throwing:

        $guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
        if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

    Supplies:
      - Resolve-GuardRepoRoot  -- the repo being operated on: CLAUDE_PROJECT_DIR, else the git root.
      - Get-OwnCopyPath        -- the repo-relative path to run instead, or $null when all is well.
      - Assert-OwnCopy         -- the same question as a gate: prints the refusal and exits 1.
#>

function Resolve-GuardRepoRoot {
    <#
        The repo being operated on, resolved the way every other shared script resolves it:
        CLAUDE_PROJECT_DIR when the harness set it, otherwise the git root of the current directory.
        Returns $null when neither answers, which switches the guard off -- a guard that cannot tell
        which repo it is in must not refuse anything.
    #>
    if ($env:CLAUDE_PROJECT_DIR -and (Test-Path -LiteralPath $env:CLAUDE_PROJECT_DIR -PathType Container)) {
        return (Resolve-Path -LiteralPath $env:CLAUDE_PROJECT_DIR).ProviderPath
    }
    try {
        $top = & git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $top) {
            $p = ([string]$top).Trim()
            if ($p -and (Test-Path -LiteralPath $p -PathType Container)) {
                return (Resolve-Path -LiteralPath $p).ProviderPath
            }
        }
    } catch { }
    return $null
}

function Get-OwnCopyPath {
    <#
        .SYNOPSIS
            The repo-relative path of the local copy that should have been run, or $null when the script
            already IS the local copy (or when the question does not apply).

        .PARAMETER ScriptPath
            The full path of the running entry point -- pass $PSCommandPath from the caller.

        .PARAMETER RepoRoot
            (Optional) the repo being operated on. Resolved via Resolve-GuardRepoRoot when omitted, which
            is what every caller does; the parameter exists so the test suite can point it at a fixture.
    #>
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [string]$RepoRoot
    )

    if (-not $ScriptPath) { return $null }
    if (-not $PSBoundParameters.ContainsKey('RepoRoot') -or -not $RepoRoot) { $RepoRoot = Resolve-GuardRepoRoot }
    if (-not $RepoRoot) { return $null }

    # Normalised with a trailing separator on the root, so a sibling directory whose name merely STARTS
    # with the root's name ('...\repo-two' beside '...\repo') cannot read as being inside it.
    $sep      = [System.IO.Path]::DirectorySeparatorChar
    $rootFull = $RepoRoot.TrimEnd('\', '/') + $sep
    $scriptFull = $ScriptPath
    try { $scriptFull = (Resolve-Path -LiteralPath $ScriptPath -ErrorAction Stop).ProviderPath } catch { }

    # 1. Inside the repo -- including its own plugins/*/scripts/ mirror, which check 8 holds identical.
    if ($scriptFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) { return $null }

    # 2. Only a repo that publishes plugins can be the repo a shared script is maintained in. This is the
    #    condition that leaves every consumer alone.
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.claude-plugin\marketplace.json') -PathType Leaf)) {
        return $null
    }

    # 3. The same path below 'scripts', taken from the RUNNING script rather than passed in by each caller
    #    -- a per-caller string is one rename away from pointing at the wrong file, and it would be a
    #    string no test reads. The LAST 'scripts' segment is the right one: a mirror path carries two
    #    ('plugins\workflows\<p>\scripts\task\x.ps1'), and the one that matters is the innermost.
    $parts = $scriptFull -split '[\\/]+'
    $idx = -1
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($parts[$i] -ieq 'scripts') { $idx = $i }
    }
    if ($idx -lt 0 -or $idx -ge ($parts.Count - 1)) { return $null }
    $relative = ($parts[($idx + 1)..($parts.Count - 1)] -join $sep)

    $localFull = Join-Path (Join-Path $RepoRoot 'scripts') $relative
    if (-not (Test-Path -LiteralPath $localFull -PathType Leaf)) { return $null }

    return ('scripts' + $sep + $relative)
}

function Assert-OwnCopy {
    <#
        .SYNOPSIS
            Get-OwnCopyPath as a gate: on a finding, print the refusal and exit 1.

        .DESCRIPTION
            A REFUSAL RATHER THAN A WARNING, decided by Dave on August 12, 2026 after both measured
            failures turned out to be silent. A warning can be read past, and the two things it would
            have warned about -- a scaffolded file in a retired shape, and a status block quietly empty --
            are precisely the kind that look finished.

            It names the local path to run instead, because a refusal whose remedy the reader has to
            derive is a refusal they will work around.
    #>
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [string]$RepoRoot
    )
    # NOT $args: that is an automatic variable, and assigning to it inside a function is the kind of thing
    # that works until something in the call chain reads the real one.
    $callArgs = @{ ScriptPath = $ScriptPath }
    if ($PSBoundParameters.ContainsKey('RepoRoot') -and $RepoRoot) { $callArgs['RepoRoot'] = $RepoRoot }
    $own = Get-OwnCopyPath @callArgs
    if (-not $own) { return }

    Write-Host ''
    Write-Host 'REFUSED: this repo maintains the script you are running, and you ran a copy from outside it.' -ForegroundColor Red
    Write-Host ''
    Write-Host ("  you ran:  {0}" -f $ScriptPath) -ForegroundColor Yellow
    Write-Host ("  run this: {0}" -f $own) -ForegroundColor Green
    Write-Host ''
    Write-Host 'The copy you ran is a RELEASED snapshot, so it lags this tree by however many merges have'
    Write-Host 'landed since the last release. Measured on August 12, 2026: new-branch scaffolded a retired'
    Write-Host 'entry shape and session-status printed an empty "still open" block, neither with any error.'
    Write-Host 'The reasoning is in scripts/README.md.'
    Write-Host ''
    exit 1
}
