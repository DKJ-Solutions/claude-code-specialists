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
      - Write-Coverage                               -- ONE non-counting [COVERAGE] line per category
                                                          stating how many items it examined, so a
                                                          verdict is never read without its coverage
                                                          and an empty category announces itself
                                                          instead of passing in silence (issue #221).
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
      - Get-SettingsChainPaths / Get-EnabledPlugins    -- WHICH plugins this repo has enabled, read
                                                          from the same settings chain Claude Code
                                                          honors instead of settings.json alone
                                                          (inbound #294). Single source for the
                                                          bootstrap, check-roster-sync and
                                                          check-connectors.
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

function Write-Coverage {
    <# ONE [COVERAGE] line stating how many items a category actually examined -- so a verdict is
       never read without its coverage (issue #221).

       THE DEFECT THIS EXISTS FOR, measured 2026-07-30. check-consumer-drift's persona section ended
       with "Persona drift is INFORMATIONAL: 0 drifted." Run against a repo holding no lens files at
       all, it printed exactly that: a clean verdict over four personas it never compared. "0 drifted
       out of 0 compared" and "0 drifted out of 4 compared" were the same sentence, and the reader had
       no way to tell a torn-down repo from a healthy one. A gate that iterates a category and finds it
       empty must SAY the category was empty; the alternative is not a false pass, it is worse -- a
       true statement that reads as a different, false one.

       Right for a deliberate teardown, wrong for an accidental loss: a silent skip cannot distinguish
       an operator's removal from a bad merge or a wrong path, and the one line it costs is what keeps
       the gate honest.

       [COVERAGE] is a NON-COUNTING token, like [OK]/[SKIP]/[SCOPE]: coverage is context about the
       run, not a finding about the repo, so it must never move an exit code or a signal count. A
       category that is legitimately empty is not an error -- it is a fact the reader needs.

       -Of is optional: pass it when the category has a known denominator (4 personas exist, 0 were
       compared), omit it when the count IS the whole story (57 files scanned). -Note carries the
       reason an empty category is empty, which is the part a reader cannot infer from a zero. #>
    param(
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][int]$Checked,
        [int]$Of = -1,
        [string]$Note = ''
    )
    $what = if ($Of -ge 0) { "checked $Checked of $Of" } else { "checked $Checked" }
    $msg = "[$Category] $what"
    if ($Note) { $msg += " -- $Note" }
    # An empty category is the case this helper exists to make visible, so it is the one that does not
    # blend into the dark-gray run chatter.
    $color = if ($Checked -eq 0) { 'Yellow' } else { 'DarkGray' }
    Write-Host "  $msg" -ForegroundColor $color
}

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

# --- Which plugins are enabled here? (inbound #294) ----------------------------------------------
# THE DEFECT THIS EXISTS FOR, measured 2026-07-31 against 3.0.5. Three places read 'enabledPlugins'
# from .claude/settings.json and nothing else, while Claude Code honors a CHAIN of settings files --
# and this plugin's own settings proposal points the reader at the other end of it ("Copy desired
# blocks to .claude/settings.json (or settings.local.json)"). One blind spot, three symptoms, in both
# directions at once:
#
#   1. FALSE GREEN. roster-sessioncheck reported "roster in sync with the enabled plugins" for
#      DaveKJohn/life-hub while that repo had 0 lenses, 0 roster rows and no '@'-import -- in the very
#      session that loaded four of its skills and all three of its hooks. The check saw 0 enabled
#      plugins, so the [BOOTSTRAP] branch could not fire and the run fell through to the exit-0
#      "in sync" verdict. That is the one sentence roster-sessioncheck.ps1 says in as many words it
#      must never print: "roster in sync would be a bald-faced lie for a repo that has no roster."
#      Same class as the gap #225 closed, reached through a different door.
#   2. SILENT SKIP. bootstrap.ps1 placed 19 lenses instead of 24 and said nothing about the 5 it
#      never considered, because 'specialists-lifehub' was enabled in a file it did not read. The
#      closing count was consistent with what the bootstrap DECIDED and not with what the consumer has
#      switched on -- and the docstring's "without settings, only its own plugin" does not cover this
#      case at all: there ARE settings, they are one file over.
#   3. FALSE ALARM. check-connectors reported "plugin is NOT (or no longer) enabled" for that same
#      repo in that same session. Literally true about settings.json, false about the session.
#
# The pair is what makes this worth a shared helper rather than three local fixes: the identical
# blindness yields a reassuring lie in one check and a spurious error in another, so a reader who
# cross-references them learns to trust neither.
#
# WHY THE USER LAYER IS IN. A plugin enabled at user scope IS loaded in every session, so a repo that
# does not roster it genuinely has drift -- excluding that layer would rebuild the same false green one
# level up. Verified before including it that this widens nothing silently on the machine this was
# measured on: ~/.claude/settings.json carries 'enabledPlugins' as an EMPTY object, so the chain reads
# exactly as before there. Every finding names the layer it came from, so an enable arriving from
# outside the repo is diagnosable instead of mysterious.
#
# WHY PER-KEY PRECEDENCE. The layers are merged per plugin id (local > project > user), not
# wholesale-replaced, and an explicit 'false' in a higher layer therefore switches off an enable from a
# lower one. Claude Code's merge semantics for this particular map are not documented, and the
# measurement cannot distinguish the two (life-hub's settings.json had no key at all). Per-key was
# chosen deliberately because it errs in the safe direction for these three callers: it never LOSES an
# enable, so the worst case is a visible, actionable drift report -- never the false green that is the
# whole reason this helper exists.

function Get-SettingsChainPaths {
    <# The settings files that can carry 'enabledPlugins', LOWEST precedence FIRST -- so a caller that
       walks this list in order and lets each layer overwrite the previous one ends up with Claude
       Code's precedence (local > project > user) for free.

       -UserHomeOverride is for fixtures. The user layer otherwise resolves from $env:USERPROFILE (the
       convention the rest of these scripts use for the plugin cache, and the variable the connector
       test already redirects to point a child process at a throwaway home), falling back to $HOME so
       the plugin's non-Windows consumers resolve something sensible rather than a path rooted in the
       empty string. #>
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [string]$UserHomeOverride = ''
    )
    $userHome = if ($UserHomeOverride) { $UserHomeOverride }
                elseif ($env:USERPROFILE) { $env:USERPROFILE }
                elseif ($HOME) { $HOME }
                else { '' }

    $chain = @()
    if ($userHome) {
        $chain += [pscustomobject]@{
            Label = 'user ~/.claude/settings.json'
            Path  = (Join-Path $userHome '.claude\settings.json')
        }
    }
    $chain += [pscustomobject]@{
        Label = '.claude/settings.json'
        Path  = (Join-Path $RepoRoot '.claude\settings.json')
    }
    $chain += [pscustomobject]@{
        Label = '.claude/settings.local.json'
        Path  = (Join-Path $RepoRoot '.claude\settings.local.json')
    }
    return $chain
}

function Get-EnabledPlugins {
    <# Read the enable state for $RepoRoot from the whole settings chain and report both the answer and
       how it was reached. Never throws on a malformed file: an unreadable layer is reported as such and
       the rest of the chain still counts, because a typo in one file must not silently turn a
       drift check into a green one.

       Returns:
         Ids            -- the enabled plugin ids ('<name>@<marketplace>') after precedence, sorted
                           ORDINALLY (see the sort below -- a culture-dependent order would make this
                           check's output depend on the machine it runs on).
         LayerById      -- hashtable id -> the layer label that DECIDED its value (for messages).
         Layers         -- per layer: Label, Path, Exists, Readable, HasKey, TrueCount.
         AnyFileExists  -- did any layer's file exist at all?
         AnyKeyFound    -- did any existing layer carry an 'enabledPlugins' key? A present-but-empty
                           key is a real answer ("nothing is enabled here"), and deliberately
                           distinguished from "no file and no key anywhere", which is a repo that was
                           never configured.
         Unreadable     -- labels of layers that exist but did not parse.
         Consulted      -- labels of the layers that exist (what a message should claim was checked).
         Summary        -- ready-made 'a, b and c' phrasing of Consulted, or 'no settings file' when
                           the chain is empty, so the three callers word this identically. #>
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [string]$UserHomeOverride = ''
    )

    $decided = @{}          # id -> $true/$false, last layer to speak wins
    $decidedBy = @{}        # id -> layer label
    $layers = @()
    $unreadable = @()
    $consulted = @()
    $anyKey = $false

    foreach ($layer in (Get-SettingsChainPaths -RepoRoot $RepoRoot -UserHomeOverride $UserHomeOverride)) {
        $exists = Test-Path -LiteralPath $layer.Path -PathType Leaf
        $readable = $false
        $hasKey = $false
        $trueCount = 0

        if ($exists) {
            $consulted += $layer.Label
            try {
                $parsed = Get-Content -LiteralPath $layer.Path -Raw -Encoding UTF8 | ConvertFrom-Json
                $readable = $true
                # Deliberately NOT '$parsed.PSObject.Properties.Name -contains ...', the idiom used
                # everywhere else in this repo. Under Set-StrictMode -Version Latest that member
                # enumeration THROWS on an object with no properties at all ("The property 'Name' cannot
                # be found on this object") -- and a settings.json holding exactly '{ }' is an ordinary
                # consumer state, not a corrupt file. Measured 2026-07-31 against a throwaway consumer:
                # the old inline reader hit this too, where $ErrorActionPreference = 'Stop' turned it into
                # a dead check reported as "could not complete"; routing it through this function's catch
                # merely relabelled it as "does not parse", which is worse -- a confident false statement
                # about the file instead of an obvious failure. Filtering the properties per item touches
                # no member on the (possibly empty) collection itself.
                $epProp = @($parsed.PSObject.Properties | Where-Object { $_.Name -eq 'enabledPlugins' })
                if ($epProp.Count -gt 0) {
                    $hasKey = $true
                    $anyKey = $true
                    # '"enabledPlugins": null' is a present key that enables nothing -- same reasoning:
                    # report it as an answer, do not throw reaching into it.
                    $epValue = $epProp[0].Value
                    if ($null -ne $epValue) {
                        foreach ($prop in @($epValue.PSObject.Properties)) {
                            $decided[$prop.Name] = ($prop.Value -eq $true)
                            $decidedBy[$prop.Name] = $layer.Label
                            if ($prop.Value -eq $true) { $trueCount++ }
                        }
                    }
                }
            } catch {
                $unreadable += $layer.Label
            }
        }

        $layers += [pscustomobject]@{
            Label     = $layer.Label
            Path      = $layer.Path
            Exists    = $exists
            Readable  = $readable
            HasKey    = $hasKey
            TrueCount = $trueCount
        }
    }

    # ORDINAL sort, not Sort-Object's culture-aware default. Measured while writing the test for this
    # helper: under the invariant/en-US collation Sort-Object puts 'specialists@...' before
    # 'specialists-lifehub@...' because punctuation carries a lower weight, while an ordinal comparison
    # orders '-' (0x2D) before '@' (0x40). Either order is defensible; a check whose output order depends
    # on the machine's culture is not, since this list drives both the report order and the order the
    # bootstrap walks its plugins in.
    $ids = [string[]]@($decided.Keys | Where-Object { $decided[$_] })
    if ($ids.Count -gt 1) { [array]::Sort($ids, [System.StringComparer]::Ordinal) }

    $summary = if ($consulted.Count -eq 0) {
        'no settings file'
    } elseif ($consulted.Count -eq 1) {
        $consulted[0]
    } else {
        (($consulted[0..($consulted.Count - 2)]) -join ', ') + ' and ' + $consulted[-1]
    }

    return [pscustomobject]@{
        Ids           = $ids
        LayerById     = $decidedBy
        Layers        = $layers
        AnyFileExists = @($layers | Where-Object { $_.Exists }).Count -gt 0
        AnyKeyFound   = $anyKey
        Unreadable    = $unreadable
        Consulted     = $consulted
        Summary       = $summary
    }
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
       who format their roster differently -- a bigger risk than the residual noise this leaves.

       WHERE THAT LIMITATION STOPPED BEING COSMETIC (issue #227, July 29, 2026): the bootstrap writes
       '@.claude/plugins/<family>/<plugin>/01-01-extension.md' into CLAUDE.md, and that path contains
       the token, so the import LINE satisfied Test-InRoster and Chris counted as rostered with no
       roster row in the file at all -- measured as 18 ids missing after a bootstrap instead of 19. The
       decision above is unchanged: the fix is NOT in this pattern. check-roster-sync.ps1 strips
       '^\s*@' lines from the roster text before reading it, which is safe precisely because an
       '@'-import is never a roster row under ANY formatting convention -- the property the rejected
       table-shape rule could not claim. If a future case needs more than that, weigh it against this
       carve-out rather than reopening option 2 from scratch: the useful question is whether the
       offending text has a writer that is knowably not the roster author. #>
    param(
        # Omit to get the generic 'any <group>-<id> token' pattern (the orphan-scan's use, matching
        # every token in the roster text). Pass a specific id (e.g. '05-15') to get a pattern that
        # matches only that literal token (Test-InRoster's use) -- same boundary, single source.
        [string]$Id = ''
    )
    $body = if ($Id) { [regex]::Escape($Id) } else { '\d{2}-\d{2}' }
    return "(?<![\d-])$body(?!\d)"
}

function Get-SeamPaths {
    <# THE SEAM (issue #221): the single place a consumer's whole specialist surface lives, so a
       teardown is "remove one directory and one line" instead of hand-editing a roster woven through
       CLAUDE.md. One source for the literal strings, because the bootstrap WRITES them and the
       teardown MATCHES them -- the pair that must never drift apart.

         .claude/specialists/SPECIALISTS.md   the inclusion: body import, lens import, roster slot
         .claude/specialists/lenses/          every <group>-<id>-extension.md, flat (ids are unique
                                              family-wide, so no per-plugin subdirectory is needed)

       ImportLine is what goes into CLAUDE.md, forward-slashed: an '@'-import path is not a filesystem
       path, and it must read identically on every platform. Verified against the memory reference:
       imports nest to a maximum of four hops, and the seam spends two (CLAUDE.md -> SPECIALISTS.md ->
       body/lens), so a lens may still import something of its own. #>
    param([Parameter(Mandatory = $true)][string]$RepoRoot)
    $dir = Join-Path $RepoRoot '.claude\specialists'
    return [pscustomobject]@{
        Dir        = $dir
        LensDir    = Join-Path $dir 'lenses'
        Inclusion  = Join-Path $dir 'SPECIALISTS.md'
        ImportLine = '@.claude/specialists/SPECIALISTS.md'
        RelDir     = '.claude/specialists'
    }
}

function Get-OrchestratorNote {
    <# The explanatory note the bootstrap writes above the orchestrator import(s), as ONE source for the
       writer and both removers (inbound #271).

       WHY THIS MOVED HERE. The note is a single sentence wrapped over TWO lines: a fixed head and a tail
       that names where the imports point. Both cleanup paths -- the teardown, and the bootstrap's own
       [tidy] guard -- matched the HEAD only, by re-typing that literal. So every teardown left the tail
       behind and the next bootstrap wrote a fresh two-line note above the orphan. Measured over two
       cycles in DaveKJohn/life-hub on 2026-07-30: 1 orphan tail after the first teardown, 2 after the
       second, and CLAUDE.md +4 lines from a round trip that should have returned to zero.

       THE INVISIBILITY WAS THE WORSE HALF. Every counter in the documented verification -- and the
       regression test written for the earlier accumulation bug -- keys on the head, so it read 0 after a
       teardown and 1 after a bootstrap: exactly the healthy values, at every step, while the file grew.
       Same failure class as the 1 -> 2 -> 3 accumulation fixed after smartwatchbanden, moved one line
       down into the only line nothing checked. The lesson already written above that fix --
       "idempotence has to cover everything the script WRITES, not just the line it happens to look
       for" -- was true of the note itself, and this is the second time it had to be learned.

       So the shape of the fix is the same as Get-SeamPaths': the pair that must never drift apart gets
       one definition. A literal mirrored by hand in two scripts is what created this bug.

       Head is an exact literal. Tail is a REGEX, because the tail interpolates a path that differs per
       consumer and per layout (the seam names the seam dir; the pre-seam form names the plugin path).
       It stays anchored on the distinctive generated clauses, so the existing rule holds unchanged: a
       consumer who reworded or translated the note has AUTHORED that text, and neither remover touches
       it. #>
    [pscustomobject]@{
        Head        = 'The orchestrator (Chris) is always loaded -- portable body from plugin install and repo lens'
        # Either generated tail, and nothing else. Deliberately not '^from ' alone: that would match a
        # sentence an owner happened to start with the same word.
        TailPattern = "^from\s.*(that file carries the body import, the lens import and this repo's roster\.|routes on-demand to specialists in\s)"
    }
}

function Test-IsOrchestratorNoteLine {
    <# Is this line part of the note block the bootstrap writes? Head or either tail. Trimmed, so an
       indentation change in a consumer's editor does not hide it from the remover. #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Line)
    $note = Get-OrchestratorNote
    $t = $Line.Trim()
    if ($t -eq $note.Head) { return $true }
    return [bool]($t -match $note.TailPattern)
}

function Get-LensDirCandidates {
    <# The ordered directories a repo lens for $PluginName may live in, most canonical first:
         0. .claude/specialists/lenses/                  -- THE SEAM (#221); where writers write for a
                                                            FRESH consumer. Plugin-independent on
                                                            purpose: one directory holds the lenses of
                                                            every enabled plugin, since <group>-<id> is
                                                            unique family-wide.
         1. .claude/plugins/<Get-LensFamily>/<plugin>/   -- the pre-seam standard; still written for a
                                                            consumer that already has a lens tree there,
                                                            because the bootstrap never relocates a file
                                                            the repo owner owns.
         2. .claude/plugins/<other-family>/<plugin>/     -- what a pre-#179 bootstrap left behind
                                                            (the marketplace name as family). Read
                                                            but never written, so a consumer that was
                                                            bootstrapped before the fix keeps working
                                                            without a migration.
         3. .claude/extensions/                          -- the legacy pre-plugin-path location.
       Readers should walk this list; writers should ask Get-LensWriteDir, which picks between the seam
       and an existing tree. $PluginName is assumed slug-validated by the caller (Test-PluginNameSlug)
       before it becomes a path segment. #>
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$PluginName
    )
    $family = Get-LensFamily
    $pluginsRoot = Join-Path $RepoRoot '.claude\plugins'
    $dirs = @((Get-SeamPaths -RepoRoot $RepoRoot).LensDir)
    $dirs += (Join-Path (Join-Path $pluginsRoot $family) $PluginName)
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

function Get-LensWriteDir {
    <# Where a writer (the bootstrap) should PUT a lens. The seam for a fresh consumer; the existing
       tree for one that already has lenses somewhere.

       WHY NOT ALWAYS THE SEAM: the bootstrap is strictly additive and never relocates a file the repo
       owner owns. Writing seam lenses next to a legacy tree would split the surface in two, which is
       worse than either layout alone -- the teardown would then have to reason about both at once, and
       a reader would find half a roster in each. Migrating is the owner's act, documented in the family
       README, and once they have moved the files this function follows them automatically because the
       legacy tree is gone.

       Returns the seam lens dir when no *-extension.md exists in ANY candidate directory, else the
       first candidate directory that actually holds one. #>
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$PluginName
    )
    foreach ($dir in (Get-LensDirCandidates -RepoRoot $RepoRoot -PluginName $PluginName)) {
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { continue }
        $found = @(Get-ChildItem -LiteralPath $dir -Filter '*-extension.md' -File -ErrorAction SilentlyContinue)
        if ($found.Count -gt 0) { return $dir }
    }
    return (Get-SeamPaths -RepoRoot $RepoRoot).LensDir
}
