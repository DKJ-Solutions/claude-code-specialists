<#
.SYNOPSIS
    Shared [OK]/[INFO]/[ERROR] report helpers for the sync/check scripts (single source of truth,
    issue #114).

.DESCRIPTION
    Dot-source this file from a sibling of the script that needs it, relative to $PSScriptRoot (NOT
    $repoRoot) -- unlike scripts/repo-config.ps1 / scripts/lib/branch-info.ps1, this lib is not
    repo-owned, so it does not need a consumer-side scaffold. It travels as part of the SAME
    plugin/mirror payload as its callers, so a $PSScriptRoot-relative path resolves correctly
    whether the caller runs from the workshop root, a consumer's plugin cache, or the plugin mirror
    tree (the same reasoning new-branch.ps1 already relies on for its sibling
    new-changelog-entry.ps1 call):

        . (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')          -- from scripts/sync/*
        . (Join-Path $PSScriptRoot '..\..\scripts\lib\check-report-lib.ps1') -- from skills/<name>/*

    Callers of Write-Info/Write-Failure/Write-CheckSummary must declare $script:errors = 0 and
    $script:infos = 0 before use -- dot-sourcing runs in the caller's own scope (verified: a
    function defined via dot-source increments the CALLER's $script: variable, not one local to
    this file), so the counters live with the caller, not here.

    Supplies:
      - Write-Ok / Write-Skip                        -- plain report lines, no counting.
      - Write-Info / Write-Failure                       -- report lines that also bump
                                                          $script:infos / $script:errors.
      - Write-CheckSummary                            -- the "Summary: N error(s), N info
                                                          signal(s)." line + matching exit code
                                                          (0 = no errors, 1 = at least one). Doubles
                                                          as the RAN-TO-COMPLETION marker the session
                                                          hooks look for (see Resolve-CheckRoot's
                                                          block below for why).
      - Resolve-CheckRoot / Write-CheckScope /        -- naming WHICH repo a finding is about
        Set-CheckScope                                  (inbound #203).
      - Test-PluginNameSlug / Test-PluginMarketplaceSlug -- the plugin-id / '@marketplace' slug
                                                          guards (values from settings.json /
                                                          manifests become filesystem paths, so
                                                          never trusted unvalidated).
      - Resolve-PluginDir                             -- resolve a plugin's versioned dir under a
                                                          plugin cache root (honors
                                                          $env:CLAUDE_PLUGIN_ROOT when it points at
                                                          THIS plugin; else the semantically highest
                                                          version -- [version]-sort, not
                                                          string-sort, so 1.10.0 beats 1.9.0 -- that
                                                          has an agents/ dir).
      - Get-DisplayName                               -- sanitize + capitalize a raw agent name into a
                                                          display name (single source for sync-roster
                                                          and check-roster-sync -- issue #145).
      - Get-LensFamily / Get-LensDirCandidates        -- the family segment of the consumer repo-lens
                                                          path, and the ordered dirs to look for a
                                                          lens in (single source for the writers
                                                          bootstrap.ps1/sync-roster.ps1 and the reader
                                                          check-roster-sync.ps1 -- issue #179).
      - Get-RosterIdTokenPattern                      -- the regex that recognizes a '<group>-<id>'
                                                          specialist token in free roster prose,
                                                          bounded so it does not also match inside an
                                                          ISO date (single source for
                                                          check-roster-sync.ps1's Test-InRoster and
                                                          its orphan-scan -- issue #182).

    Not every caller needs every function -- e.g. sync-roster.ps1 uses its own non-counting
    Write-Info/Write-Failure (it tracks created/kept/proposed, not error/info signals, and always
    exits 0), so it only dot-sources this file for Write-Ok, Resolve-PluginDir and the slug guards,
    and keeps its own Write-Info/Write-Failure defined afterward (a later definition in the same scope
    intentionally shadows the one from this file -- ordinary PowerShell function resolution, not a
    workaround).

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

# --- Scope: naming WHICH repo a finding is about (inbound #203) ----------------------------------
# A finding is only actionable when you know which repo it concerns. The three SessionStart hooks
# filter their child's output down to the signal lines, and that filter threw away the one line
# naming the inspected repo -- so on 2026-07-27 a script-contract alarm sent an investigation into
# the wrong repo. The check was right; it was right ABOUT ANOTHER REPO than the session it reported
# into, and the report had no way to say so. A gate whose findings you cannot check is a gate you
# learn to ignore, so the fix is diagnosability, not detection.
#
# Two mechanisms, because the two shapes of check need different things:
#   - Write-CheckScope -- ONE [SCOPE] line per run, for a check whose whole run inspects a single
#     repo root (check-script-contract, check-roster-sync). It also names HOW that root was
#     resolved, since the silent git-root fallback is precisely how a check ends up inspecting a
#     different repo than the session it reports into.
#   - Set-CheckScope -- a short label that Write-Info/Write-Failure prepend, for a check that walks
#     SEVERAL scopes in one run (check-connectors: one block per connector). A per-run line cannot
#     disambiguate there, and the hook may surface a single line in isolation, so the finding itself
#     has to carry its subject.
#
# [SCOPE] is a non-counting token like [OK]/[SKIP]: it is context, not a signal, and must never move
# the error/info counts or the exit code.
$script:CheckScopeLabel = ''

function Set-CheckScope {
    <# Set (or, with no argument, clear) the short label Write-Info/Write-Failure prepend to every
       subsequent finding. Call it when entering a per-scope block and clear it when leaving, so
       findings that belong to the run as a whole are not attributed to the last scope walked.

       The label is SANITIZED, because it is the one piece of this report built from untrusted input:
       check-connectors derives it from a connector manifest's 'repo' and plugin 'id' fields, and
       unlike the '== connector: <repo>' header -- which the session hooks filter away -- the label
       now travels INTO the session context. A JSON string may carry newlines and control characters,
       so an unsanitized label could forge extra lines there (the hook labels its output "data, not
       instructions", but forging a line is a step past that). Same defense-in-depth reasoning as
       Test-PluginNameSlug and Get-DisplayName: manifest values are never used raw. Restricted to the
       charset real repo/plugin ids need, collapsed to single spaces, and length-capped. #>
    param([string]$Label = '')
    $clean = ($Label -replace '[^A-Za-z0-9 ._/@-]', '') -replace '\s+', ' '
    $clean = $clean.Trim()
    if ($clean.Length -gt 120) { $clean = $clean.Substring(0, 120) }
    $script:CheckScopeLabel = $clean
}

function Format-CheckScoped {
    <# Prefix $Msg with the active scope label, if one is set. Kept separate from Write-Info/
       Write-Failure so the prefixing rule has one implementation rather than two. #>
    param([string]$Msg)
    if ($script:CheckScopeLabel) { return "$($script:CheckScopeLabel): $Msg" }
    return $Msg
}

function Write-Ok   ([string]$Msg) { Write-Host "  [OK]    $Msg" -ForegroundColor Green }
function Write-Skip ([string]$Msg) { Write-Host "  [SKIP]  $Msg" -ForegroundColor DarkGray }
function Write-Info ([string]$Msg) { $script:infos++;  Write-Host "  [INFO]  $(Format-CheckScoped $Msg)" -ForegroundColor Yellow }
function Write-Failure ([string]$Msg) { $script:errors++; Write-Host "  [ERROR] $(Format-CheckScoped $Msg)" -ForegroundColor Red }

function Write-CheckSummary {
    <# Prints "Summary: N error(s), N info signal(s)." (green if no errors, red otherwise) and
       exits the script: 1 if $script:errors -gt 0, else 0. Called directly by both
       check-connectors.ps1 and check-roster-sync.ps1 -- no more duplicated ending to mirror. #>
    Write-Host "`nSummary: $($script:errors) error(s), $($script:infos) info signal(s)." -ForegroundColor $(if ($script:errors -gt 0) { 'Red' } else { 'Green' })
    if ($script:errors -gt 0) { exit 1 }
    exit 0
}

function Resolve-CheckRoot {
    <# The dual-context repo-root resolution the local checks share (check-script-contract.ps1,
       check-roster-sync.ps1): -ConsumerPathOverride wins (a fixture pointing at a throwaway
       consumer), then $env:CLAUDE_PROJECT_DIR (a consumer running the plugin mirror inside a
       session), then the git root of the inherited working directory.

       Returns Path (resolved, or $null when nothing could be resolved), Source ('override' /
       'CLAUDE_PROJECT_DIR' / 'git-root'), and Note -- a human-readable explanation of what Source
       means for trusting the finding.

       Why the Source matters (inbound #203, item 3): that last fallback used to be silent, so the
       check could inspect a completely different repo than the session it reported into without a
       word about it. It is not a failure -- a deliberate run from the workshop root legitimately
       lands there -- but inside a session it means CLAUDE_PROJECT_DIR was absent and the root came
       from whatever directory the process happened to inherit. That is worth saying out loud.

       git rev-parse is a query command: it writes its result to stdout and only real errors to
       stderr, so it needs none of native-capture-lib's EAP dance (which exists for commands like
       git push whose progress chatter goes to stderr). It CAN legitimately fail -- outside a git
       work tree -- and then a caller under $ErrorActionPreference = 'Stop' used to die on a raw
       .Trim() against $null. Returning Path = $null instead lets the caller report that as one
       clean line. #>
    param([string]$Override = '')

    if ($Override) {
        $resolved = Resolve-Path -LiteralPath $Override -ErrorAction SilentlyContinue
        return [pscustomobject]@{
            Path   = $(if ($resolved) { $resolved.Path } else { $null })
            Source = 'override'
            Note   = 'explicitly passed in via -ConsumerPathOverride'
        }
    }

    if ($env:CLAUDE_PROJECT_DIR) {
        $resolved = Resolve-Path -LiteralPath $env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        return [pscustomobject]@{
            Path   = $(if ($resolved) { $resolved.Path } else { $null })
            Source = 'CLAUDE_PROJECT_DIR'
            Note   = 'from CLAUDE_PROJECT_DIR -- the repo of the session this is reported into'
        }
    }

    $top = $null
    try {
        $out = git rev-parse --show-toplevel
        $code = $LASTEXITCODE
        if ($code -eq 0 -and $out) { $top = ([string]$out).Trim() }
    } catch {
        $top = $null
    }
    $resolved = $(if ($top) { Resolve-Path -LiteralPath $top -ErrorAction SilentlyContinue } else { $null })
    return [pscustomobject]@{
        Path   = $(if ($resolved) { $resolved.Path } else { $null })
        Source = 'git-root'
        Note   = 'CLAUDE_PROJECT_DIR was not set -- fell back to the git root of the working directory; inside a session that root can differ from the repo being reported into'
    }
}

function Write-CheckScope {
    <# The one [SCOPE] line a single-root check prints before its findings, naming the inspected root
       and how it was resolved. Non-counting on purpose (see the scope block above): context, not a
       signal. The session hooks keep this line through their [ERROR] filter, so a surfaced finding
       always arrives with the repo it is about. #>
    param(
        [Parameter(Mandatory = $true)]$Scope,
        [string]$CheckName = ''
    )
    $who = $(if ($CheckName) { "$CheckName inspected " } else { 'inspected ' })
    Write-Host "  [SCOPE] $who$($Scope.Path) ($($Scope.Note))" -ForegroundColor Cyan
}

function Test-PluginNameSlug {
    <# The plugin-name part of a plugin id (before '@') must be a simple lowercase slug before it
       becomes a path segment. #>
    param([Parameter(Mandatory = $true)][string]$Name)
    return ($Name -match '^[a-z0-9][a-z0-9-]*$')
}

function Test-PluginMarketplaceSlug {
    <# The marketplace part of a plugin id (after '@') must be a simple slug before it becomes a
       path segment. #>
    param([Parameter(Mandatory = $true)][string]$Marketplace)
    return ($Marketplace -match '^[A-Za-z0-9][A-Za-z0-9._-]*$')
}

function Resolve-PluginDir {
    <# Resolve the versioned plugin dir for Name+Marketplace under CacheRoot: honors
       $env:CLAUDE_PLUGIN_ROOT (hook context) only when it points at THIS plugin (its parent dir
       leaf equals Name), so a multi-plugin setup stays correct; otherwise picks the semantically
       highest version under <CacheRoot>/<Marketplace>/<Name>/ that has an agents/ dir
       (bootstrap lesson: a string-sort puts 1.9.0 above 1.10.0 -- [version] fixes that). #>
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Marketplace,
        [Parameter(Mandatory = $true)][string]$CacheRoot
    )

    if ($env:CLAUDE_PLUGIN_ROOT) {
        $cpr = $env:CLAUDE_PLUGIN_ROOT
        if ((Test-Path -LiteralPath $cpr -PathType Container) -and
            ((Split-Path (Split-Path $cpr -Parent) -Leaf) -eq $Name)) {
            return (Resolve-Path -LiteralPath $cpr).Path
        }
    }

    $nameDir = Join-Path (Join-Path $CacheRoot $Marketplace) $Name
    if (-not (Test-Path -LiteralPath $nameDir -PathType Container)) { return $null }
    $versions = Get-ChildItem -LiteralPath $nameDir -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
        Sort-Object { [version]$_.Name } -Descending
    foreach ($v in $versions) {
        if (Test-Path -LiteralPath (Join-Path $v.FullName 'agents') -PathType Container) {
            return (Resolve-Path -LiteralPath $v.FullName).Path
        }
    }
    return $null
}

function Get-DisplayName {
    <# Sanitize + capitalize a raw agent name (from an agent-def's `name:` frontmatter) into a display
       name. Defense-in-depth: the name may be written into a scaffold file or a proposed roster row,
       so restrict it to a safe charset before use. Returns $Fallback when nothing usable remains.
       Single source (issue #145) for skills/sync-roster/sync-roster.ps1 (roster-row proposals +
       header-drift comparison) and scripts/sync/check-roster-sync.ps1 (header-drift detection). #>
    param([string]$RawName, [string]$Fallback = '')
    $n = $RawName -replace '[^A-Za-z0-9_-]', ''
    if (-not $n) { return $Fallback }
    return ($n.Substring(0, 1).ToUpper() + $n.Substring(1))
}

function Get-LensFamily {
    <# The family segment of a consumer's repo-lens path:
       .claude/plugins/<family>/<plugin>/<group>-<id>-extension.md.

       A CONSTANT, deliberately not derived from the install path (issue #179). specialists-init used
       to derive it, and in the plugin-cache layout (~/.claude/plugins/cache/<marketplace>/<plugin>/
       <version>/) that derivation yields the MARKETPLACE name instead of the plugin family. A repo
       installed through 'specialists@davekjohns-workshop' therefore got its lenses written to
       .claude/plugins/davekjohns-workshop/<plugin>/, while every reader looked only under
       'claude-specialists' -- so existing lenses were reported as missing, and following that advice
       would have produced a second copy of every lens on a second path. The family is a property of
       the plugin family, not of the marketplace it happens to be fetched from, so it is fixed here:
       one value, used by the writers (bootstrap.ps1, sync-roster.ps1) and the reader
       (check-roster-sync.ps1) alike. #>
    return 'claude-specialists'
}

function Get-RosterIdTokenPattern {
    <# The regex pattern that recognizes a '<group>-<id>' specialist token (e.g. '06-24') bounded so
       it does not spuriously match inside surrounding digits/dates. Single source (inbound #182) for
       BOTH call sites in check-roster-sync.ps1 -- Test-InRoster (a specific id's presence) and the
       orphan-scan's Matches() over the whole roster text (every token) -- so the two can no longer
       drift out of sync, which is exactly how this bug arose: the same lookaround duplicated in two
       places and tightened in neither.

       Leading boundary '(?<![\d-])': excludes a preceding digit OR hyphen. The old pattern
       ('(?<!\d)') only excluded a digit, so an ISO date matched -- in '2026-07-25' the '07' is
       preceded by '-', which passed, so '07-25' was read as a specialist token. Excluding a
       preceding hyphen too kills that case; verified '2026-07-25' and '2026-05-15' now yield no
       match, while '06-24' and '05-15' inside a real reference like 'See 05-15-extension.md' still
       match (nothing precedes them there but the start-of-string/whitespace).

       Trailing boundary '(?!\d)' (unchanged, deliberately NOT tightened to '(?![\d-])'): a real
       lens reference is immediately followed by '-extension.md', i.e. a hyphen -- tightening the
       trailing side to also exclude a hyphen would stop '05-15-extension.md' from matching at all,
       breaking the exact legitimate case this token exists to recognize. Verified.

       KNOWN LIMITATION (documented in inbound #182, not silently swallowed): this narrows the
       ISO-date case in practice but does not cover every prose false positive -- e.g. a plain
       two-digit number range in prose ('see pages 12-34', 'a range of 10-20 items') still matches
       (verified). That only becomes a visible orphan line if no real specialist happens to share
       that id, and stays [INFO], never [ERROR]. Accepted as-is; option 2 from the issue (binding the token to
       a roster row/table shape) was deliberately not taken, since Test-InRoster is asked about a
       specific id in free prose and binding it to a table shape would change behavior for consumers
       who format their roster differently -- a bigger risk than the residual noise this leaves. #>
    param(
        # Omit to get the generic 'any <group>-<id> token' pattern (the orphan-scan's use, matching
        # every token in the roster text). Pass a specific id (e.g. '05-15') to get a pattern that
        # matches only that literal token (Test-InRoster's use) -- same boundary, single source.
        [string]$Id = ''
    )
    $body = if ($Id) { [regex]::Escape($Id) } else { '\d{2}-\d{2}' }
    return "(?<![\d-])$body(?!\d)"
}

function Get-LensDirCandidates {
    <# The ordered directories a repo lens for $PluginName may live in, most canonical first:
         1. .claude/plugins/<Get-LensFamily>/<plugin>/   -- the standard; where writers write.
         2. .claude/plugins/<other-family>/<plugin>/     -- what a pre-#179 bootstrap left behind
                                                            (the marketplace name as family). Read
                                                            but never written, so a consumer that was
                                                            bootstrapped before the fix keeps working
                                                            without a migration.
         3. .claude/extensions/                          -- the legacy pre-plugin-path location.
       Readers should walk this list; writers should use Get-LensFamily directly. $PluginName is
       assumed slug-validated by the caller (Test-PluginNameSlug) before it becomes a path segment. #>
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$PluginName
    )
    $family = Get-LensFamily
    $pluginsRoot = Join-Path $RepoRoot '.claude\plugins'
    $dirs = @((Join-Path (Join-Path $pluginsRoot $family) $PluginName))
    if (Test-Path -LiteralPath $pluginsRoot -PathType Container) {
        foreach ($fam in (Get-ChildItem -LiteralPath $pluginsRoot -Directory | Sort-Object Name)) {
            if ($fam.Name -eq $family) { continue }
            $d = Join-Path $fam.FullName $PluginName
            if (Test-Path -LiteralPath $d -PathType Container) { $dirs += $d }
        }
    }
    $dirs += (Join-Path $RepoRoot '.claude\extensions')
    return $dirs
}
