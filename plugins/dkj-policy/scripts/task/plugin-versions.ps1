<#
.SYNOPSIS
    Per enabled plugin: the version installed IN THIS CHECKOUT against the version the local
    marketplace clone would install, with a verdict on whether a plugin update is due. Runs in any
    checkout on any machine, reads only, takes no arguments for the default view.

.DESCRIPTION
    ANSWERS A QUESTION NO EXISTING CHECK DOES: "is the plugin version this checkout loads the same as
    the one the marketplace clone holds, and if not, which command closes the gap?" The connector
    session check goes inert on a plain consumer with no sibling source checkout: the HOOK
    (connector-sessioncheck.ps1) prints "no verified workshop checkout found -- check skipped" on its
    own early-exit path and never reaches check-connectors.ps1, whose check 4 is the version
    comparison that then never runs. So there is no version signal at all. Naming the hook rather
    than the check matters: that string is the hook's, and grepping check-connectors.ps1 for it finds
    nothing. This script needs only two things every consumer machine already has:

      1. THE INSTALL RECORD -- ~/.claude/plugins/installed_plugins.json, the record whose projectPath
         is this checkout, read via Get-InstallRecord. Its .version, .gitCommitSha and .scope are what
         the session actually loaded. NOTHING IS PERSISTED by this script and nothing here writes that
         file; the syncedVersion bookkeeping removed on July 20, 2026 is NOT reintroduced.

      2. THE MARKETPLACE CLONE -- ~/.claude/plugins/marketplaces/<marketplace>/, a git clone present
         on every machine that has added the marketplace. Its per-plugin
         .claude-plugin/plugin.json .version and its git HEAD are readable with no dev checkout beside
         it. THE CLONE ADVANCES ONLY ON `claude plugin marketplace update <marketplace>`, not on a
         push or a merge -- so its plugin.json .version is cut-granular and its HEAD sha is the finer
         truth. That is why the verdict prefers the sha and only falls back to the version.

    THE VERDICT, per plugin:
      - install sha == clone HEAD                -> up to date. The clone itself may still lag origin;
                                                   `claude plugin marketplace update <marketplace>`
                                                   refreshes it if you expect newer.
      - install sha is an ANCESTOR of clone HEAD,
        and the two version strings DIFFER          -> the clone is AHEAD of your install
                                                   -> `claude plugin update <id> --scope project`
      - install sha is an ANCESTOR of clone HEAD,
        and both sides carry the SAME version       -> unreleased work in the clone, and NO command is
                                                      handed over: `claude plugin update` arbitrates on
                                                      the version string, so it reports success and
                                                      moves nothing (measured, #1772). This is the
                                                      ordinary state of any checkout between releases,
                                                      so it is not counted as behind and is never an
                                                      [ERROR] in -Brief.
      - install sha exists but is NOT an ancestor of clone HEAD, or is unknown to the clone
                                                -> your install is ahead, or the clone is stale
                                                   -> `claude plugin marketplace update <marketplace>`
      - no sha on one side                       -> the two versions are compared instead, and the
                                                   line says a sha was not available
      - a whole side is missing                  -> cannot determine, and the line says which side

    Every enabled plugin is listed even under lockstep, so a partial or split install state is
    visible rather than hidden behind a single headline.

    Dual-context: run the root copy in this repo, the plugin mirror in a consumer.
    Pure ASCII, per this repo's script-layer convention.

.PARAMETER RootOverride
    Repo root to resolve the enable state and the install record against, for the test suite. A
    consumer never types this: the root is resolved dual-context like every other shared script.

.PARAMETER UserHomeOverride
    The home directory that '~/.claude' hangs off, for the test suite -- so a fixture can point both
    the install record and the marketplace clone at a scratch tree. A consumer never types this.

.PARAMETER Brief
    Emit one marker-prefixed line per plugin that has something to say, plus a [SUMMARY] tally, and
    nothing else -- no header, no per-plugin block, no colour. This is the shape a SessionStart hook
    can put in front of a session (#1591); a person reading the answer wants the default view.

.EXAMPLE
    ./scripts/task/plugin-versions.ps1
#>
[CmdletBinding()]
param(
    [string]$RootOverride = '',
    [string]$UserHomeOverride = '',
    [switch]$Brief
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The source-repo guard, wired the way every shared entry point wires it: a string literal names the
# lib (so scripts/tests/source-repo-guard.tests.ps1 can see the guard is present) and Assert-OwnCopy
# is called. It refuses a released copy run from inside the repo that maintains it.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Repo root -- dual context: a consumer running the shared plugin mirror gets it from
# CLAUDE_PROJECT_DIR, a run inside this repo from git itself. RootOverride is the test seam.
$repoRoot = if ($RootOverride) { $RootOverride } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\plugin-tree-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# --- small helpers ------------------------------------------------------------------------------

function Format-ShortSha {
    param([AllowNull()][string]$Sha)
    if (-not $Sha) { return '(none)' }
    if ($Sha.Length -le 12) { return $Sha }
    return $Sha.Substring(0, 12)
}

function Get-ValidatedSha {
    # A git commit sha is 7-40 hex characters. $GitCommitSha comes from installed_plugins.json and is
    # interpolated into 'git rev-parse'/'git merge-base' below -- shape-check it first (defense in
    # depth; the CLI writes that file and neither subcommand exposes a transport flag, so the risk is
    # low, but the check is cheap) and treat anything else as no sha at all, so the caller falls
    # through to the version comparison rather than handing a malformed value to git.
    param([AllowNull()][string]$Sha)
    if ($Sha -and $Sha -match '^[0-9a-f]{7,40}$') { return $Sha }
    return ''
}

function Invoke-CloneGit {
    # git run inside the marketplace clone. -DiscardStderr because the caller reads the output: git's
    # progress lines are not the answer. The exit code is what -is-ancestor / -verify are asked for.
    param([Parameter(Mandatory)][string]$CloneDir, [Parameter(Mandatory)][string[]]$GitArgs)
    return Invoke-NativeCapture -FilePath 'git' -Arguments (@('-C', $CloneDir) + $GitArgs) -DiscardStderr
}

function Resolve-Clone {
    <#
        Everything readable about one marketplace clone: its dir, whether it is there, its HEAD sha and
        date, the last-fetch time, and every plugin.json .version it carries keyed by plugin name.
        Never throws -- a missing or unparseable clone is an ordinary state a consumer can be in, and
        the verdict layer reports it.
    #>
    param([Parameter(Mandatory)][string]$Marketplace, [AllowEmptyString()][string]$UserHome)

    $dir = if ($UserHome) { Join-Path $UserHome (Join-Path '.claude' (Join-Path 'plugins' (Join-Path 'marketplaces' $Marketplace))) } else { '' }
    $info = [pscustomobject]@{
        Marketplace   = $Marketplace
        Dir           = $dir
        Exists        = [bool]($dir -and (Test-Path -LiteralPath $dir -PathType Container))
        IsGit         = $false
        Head          = ''
        HeadDate      = ''
        FetchTime     = ''
        PluginVersion = @{}
        Error         = ''
    }
    if (-not $info.Exists) { return $info }

    # A 'github'-source marketplace (this one) is cloned as a real git repo, so HEAD and ancestry are
    # available. Claude Code also fetches some marketplaces as a plain tree with the source commit in
    # a '.gcs-sha' file and no .git -- then the sha is still readable but there is no history to walk.
    $info.IsGit = (Test-Path -LiteralPath (Join-Path $dir '.git') -PathType Container)
    if ($info.IsGit) {
        $h = Invoke-CloneGit -CloneDir $dir -GitArgs @('rev-parse', 'HEAD')
        if ($h.ExitCode -eq 0) { $info.Head = (@($h.Output) -join "`n").Trim() }
        $d = Invoke-CloneGit -CloneDir $dir -GitArgs @('log', '-1', '--format=%cI', 'HEAD')
        if ($d.ExitCode -eq 0) { $info.HeadDate = (@($d.Output) -join "`n").Trim() }
    }
    if (-not $info.Head) {
        $gcs = Join-Path $dir '.gcs-sha'
        if (Test-Path -LiteralPath $gcs -PathType Leaf) {
            try { $info.Head = (Get-Content -LiteralPath $gcs -Raw -Encoding UTF8).Trim() } catch { }
        }
    }

    # Last-fetch time, cheaply: the mtime of .git/FETCH_HEAD. Absent on a clone that has never
    # fetched since it was made -- then the field stays empty and the header omits it.
    $fetchHead = Join-Path $dir '.git\FETCH_HEAD'
    if (Test-Path -LiteralPath $fetchHead -PathType Leaf) {
        try { $info.FetchTime = (Get-Item -LiteralPath $fetchHead).LastWriteTime.ToString('s') } catch { }
    }

    try {
        foreach ($r in @(Get-RepoPluginRoots -RepoRoot $dir)) {
            $v = ''
            if (Test-Path -LiteralPath $r.ManifestPath -PathType Leaf) {
                try {
                    $mj = Get-Content -LiteralPath $r.ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
                    $v = [string](Get-JsonField $mj 'version')
                } catch { $v = '' }
            }
            $info.PluginVersion[$r.Name] = $v
        }
    } catch {
        $info.Error = $_.Exception.Message
    }
    return $info
}

function Compare-Version {
    # Negative / zero / positive for a < b / a == b / a > b: exactly -1 / 0 / 1 from [version] where
    # both sides parse, otherwise the raw ordinal string comparison, whose SIGN is the answer and
    # whose magnitude is not. $null when either side is empty. Every caller tests the sign only, and
    # a future one must too.
    param([AllowEmptyString()][string]$A, [AllowEmptyString()][string]$B)
    if (-not $A -or -not $B) { return $null }
    $va = $null; $vb = $null
    if ([version]::TryParse($A, [ref]$va) -and [version]::TryParse($B, [ref]$vb)) { return $va.CompareTo($vb) }
    return [string]::CompareOrdinal($A, $B)
}

# --- read the two sides -----------------------------------------------------------------------

# One fixture knob (-UserHomeOverride) controls all three reads that hang off '~/.claude': the enable
# state's user layer, the install record, and the marketplace clone. In a real run it is '' and each
# falls back to $env:USERPROFILE / $HOME.
$enabled = Get-EnabledPlugins -RepoRoot $repoRoot -UserHomeOverride $UserHomeOverride
$ids = @($enabled.Ids)

if (-not $Brief) {
    # The header names the checkout being reported on, which is the first thing a person reading the
    # default view needs and the last thing a session start does: -Brief is read by a hook that
    # already knows which repo it is in, and an absolute path is the one thing worth not repeating
    # into a session's context on every start.
    Write-Host ""
    Write-Host "plugin-versions -- $repoRoot" -ForegroundColor Cyan
}

if ($ids.Count -eq 0) {
    if ($Brief) {
        Write-Host "[INFO] no plugins are enabled for this checkout -- nothing to compare."
        exit 0
    }
    Write-Host ""
    Write-Host "No plugins are enabled for this checkout." -ForegroundColor Yellow
    Write-Host "  Consulted: $($enabled.Summary)."
    Write-Host "  Nothing to compare. Enable a plugin in .claude/settings.json and re-run."
    exit 0
}

$userHome = Get-UserClaudeHome -UserHomeOverride $UserHomeOverride
$install = Get-InstallRecord -RepoRoot $repoRoot -UserHomeOverride $UserHomeOverride

$marketplaces = [string[]]@($ids | ForEach-Object { ($_ -split '@')[-1] } | Select-Object -Unique)
if ($marketplaces.Count -gt 1) { [array]::Sort($marketplaces, [System.StringComparer]::Ordinal) }
$clones = @{}
foreach ($mp in $marketplaces) { $clones[$mp] = Resolve-Clone -Marketplace $mp -UserHome $userHome }

# --- per plugin: build a row --------------------------------------------------------------------

$rows = New-Object System.Collections.Generic.List[object]

foreach ($id in $ids) {
    $parts = $id -split '@'
    $name = $parts[0]
    $mp = $parts[-1]
    $clone = $clones[$mp]

    $recs = @()
    if ($install.RecordsById.ContainsKey($id)) { $recs = @($install.RecordsById[$id]) }
    $pathless = @()
    if ($install.PathlessById.ContainsKey($id)) { $pathless = @($install.PathlessById[$id]) }

    # -- installed-here summary --
    $instVer = ''
    $instSha = ''
    $instScope = ''
    $instText = ''
    if ($recs.Count -eq 1) {
        $instVer = [string]$recs[0].Version
        $instSha = Get-ValidatedSha ([string]$recs[0].GitCommitSha)
        $instScope = [string]$recs[0].Scope
        $instText = "$(if ($instVer) { $instVer } else { '(no version)' })  $(Format-ShortSha $instSha)  $(if ($instScope) { $instScope } else { '(no scope)' })"
    } elseif ($recs.Count -gt 1) {
        $shown = @($recs | ForEach-Object { "$($_.Version)/$(Format-ShortSha ([string]$_.GitCommitSha))/$($_.Scope)" })
        $instText = "$($recs.Count) CONFLICTING records for this checkout: $($shown -join ' , ')"
    } elseif ($pathless.Count -ge 1) {
        $p0 = $pathless[0]
        $instText = "no record for this checkout; a $($p0.Scope)-scope record not tied to a path exists ($($p0.Version) $(Format-ShortSha ([string]$p0.GitCommitSha)))"
    } elseif (-not $install.Exists) {
        $instText = "no install administration on this machine ($($install.Path))"
    } elseif (-not $install.Readable) {
        $instText = "install administration could not be read: $($install.Error)"
    } else {
        $instText = "no install record in this checkout (enabled declaratively only)"
    }

    # -- marketplace-clone summary --
    $cloneVer = ''
    $cloneText = ''
    $cloneHasPlugin = $false
    if (-not $clone.Dir) {
        $cloneText = "cannot resolve ~/.claude (no USERPROFILE / HOME set)"
    } elseif (-not $clone.Exists) {
        $cloneText = "no marketplace clone at $($clone.Dir)"
    } elseif ($clone.PluginVersion.ContainsKey($name)) {
        $cloneHasPlugin = $true
        $cloneVer = [string]$clone.PluginVersion[$name]
        $cloneText = "$(if ($cloneVer) { $cloneVer } else { '(no version in plugin.json)' })  $(if ($clone.IsGit) { 'HEAD' } else { 'sha' }) $(Format-ShortSha $clone.Head)"
    } elseif ($clone.Error) {
        $cloneText = "the clone's marketplace.json could not be read: $($clone.Error)"
    } else {
        $cloneText = "'$name' is not listed in the clone's marketplace.json"
    }

    # -- verdict --
    $code = 'indeterminate'
    $verdict = ''
    $action = ''
    if (-not $clone.Exists -or -not $clone.Dir) {
        $verdict = "cannot determine -- no marketplace clone to compare against"
        $action = "add it once: claude plugin marketplace add <owner>/<repo>"
    } elseif (-not $cloneHasPlugin) {
        # Every other 'the clone cannot answer' branch names the command that would repair it, and
        # this one read as a dead end for want of one. A refresh is the right first move either way:
        # a plugin added upstream since the last refresh is absent from a clone that is merely
        # behind, and a clone whose marketplace.json will not parse is re-fetched by the same command.
        $verdict = if ($clone.Error) { "cannot determine -- the clone's marketplace.json could not be read" } else { "cannot determine -- '$name' is not in the clone's marketplace.json" }
        $action = "refresh the clone and re-run: claude plugin marketplace update $mp"
    } elseif ($recs.Count -gt 1) {
        $verdict = "cannot determine -- this checkout has $($recs.Count) conflicting install records"
        $action = "repair: claude plugin install $id --scope project"
    } elseif ($recs.Count -eq 0) {
        if ($pathless.Count -ge 1) {
            $verdict = "cannot determine for this checkout -- only a path-less (machine-wide) record exists"
        } else {
            $verdict = "cannot determine -- not installed in this checkout (enabled declaratively only)"
        }
        $action = "install here: claude plugin install $id --scope project"
    } elseif ($instSha -and $clone.Head) {
        if ($instSha -ieq $clone.Head) {
            $code = 'match'
            $verdict = "up to date -- your install is at the clone's HEAD"
            $action = "the clone advances only on: claude plugin marketplace update $mp"
        } elseif (-not $clone.IsGit) {
            # A non-git marketplace fetch: the shas differ but there is no history to say which way.
            # Fall back to the version comparison entirely.
            $verCmp = Compare-Version -A $instVer -B $cloneVer
            if ($null -ne $verCmp -and $verCmp -lt 0) {
                $code = 'behind'
                $verdict = "the clone is AHEAD of your install ($instVer -> $cloneVer); the clone is a non-git fetch so the commit history cannot confirm direction"
                $action = "claude plugin update $id --scope project"
            } elseif ($null -ne $verCmp -and $verCmp -gt 0) {
                $code = 'clone-behind'
                $verdict = "your install ($instVer) is AHEAD of the clone ($cloneVer)"
                $action = "claude plugin marketplace update $mp"
            } else {
                $verdict = "cannot determine -- versions match ($instVer) but the recorded shas differ and the clone is a non-git fetch with no history to compare"
                $action = "claude plugin marketplace update $mp   (then: claude plugin update $id --scope project)"
            }
        } else {
            $existsInClone = (Invoke-CloneGit -CloneDir $clone.Dir -GitArgs @('rev-parse', '-q', '--verify', "$instSha^{commit}")).ExitCode -eq 0
            if (-not $existsInClone) {
                $verCmp = Compare-Version -A $instVer -B $cloneVer
                if ($null -ne $verCmp -and $verCmp -lt 0) {
                    $code = 'behind'
                    $verdict = "your install ($instVer, $(Format-ShortSha $instSha)) is BEHIND the clone ($cloneVer) and its commit is not in the clone's history"
                    $action = "claude plugin update $id --scope project  (then re-run; if it still differs: claude plugin marketplace update $mp)"
                } else {
                    $code = 'clone-behind'
                    $verdict = "your install ($(Format-ShortSha $instSha)) is not in the clone's history -- the clone is stale, or your install predates a history rewrite"
                    $action = "claude plugin marketplace update $mp"
                }
            } else {
                $anc = (Invoke-CloneGit -CloneDir $clone.Dir -GitArgs @('merge-base', '--is-ancestor', $instSha, 'HEAD')).ExitCode -eq 0
                if ($anc) {
                    # THE VERSION STRINGS DECIDE WHETHER THERE IS ANYTHING TO RUN, and until #1772 they
                    # did not: the ancestry says the clone's commit is newer, and the action was set
                    # unconditionally to `claude plugin update`. That command arbitrates on the VERSION
                    # STRING, so where the two sides carry the same one it has nothing to compare and
                    # exits successfully without moving the install -- measured September 10, 2026 in
                    # the source repo, on dkj-policy and dkj-policy-bwj at 4.33.0 on both sides:
                    # "already at the latest version (4.33.0)". The run then reported them as behind and
                    # handed over a command that reports success and changes nothing, which is the worst
                    # shape a report can have: it looks acted on.
                    #
                    # AND IT IS THE NORMAL STATE OF EVERY CHECKOUT BETWEEN RELEASES, not an edge case.
                    # The clone tracks the source's trunk and advances on a marketplace refresh; an
                    # install sits on the last release. So the gap is UNRELEASED WORK, and no command
                    # here closes it -- the next release cut does. That is also why nothing is
                    # prescribed: an uninstall + re-install WOULD cross the boundary, but it would put a
                    # consumer on code no release has shipped, which is not what a staleness report
                    # should be nudging anyone towards, and this run has not measured that it works.
                    if ($instVer -and $cloneVer -and $instVer -ne $cloneVer) {
                        $code = 'behind'
                        $verdict = "the clone is AHEAD of your install ($instVer -> $cloneVer)"
                        $action = "claude plugin update $id --scope project"
                    } elseif ($instVer -and $cloneVer -and $instVer -eq $cloneVer) {
                        $code = 'unreleased'
                        $verdict = "your install is on the released version $instVer and the clone holds newer commits carrying that same version -- unreleased work, so there is no version gap for a plugin update to close"
                        $action = "nothing to run -- 'claude plugin update' arbitrates on the version string and reports success without moving the install (measured, #1772); this closes at the next release cut"
                    } else {
                        # A VERSION STRING MISSING ON EITHER SIDE, so the two cases above cannot be told
                        # apart: the newer commit may or may not cross a release boundary. The old
                        # wording claimed "same version string" here whenever the install had one, which
                        # was a wrong statement when it was the CLONE's plugin.json that had none.
                        $code = 'behind'
                        $missingSide = if (-not $instVer) { 'no version recorded for your install' } else { "no version in the clone's plugin.json" }
                        $verdict = "the clone is AHEAD of your install (newer commit; $missingSide, so whether that crosses a release boundary cannot be read from here)"
                        $action = "claude plugin update $id --scope project"
                    }
                } else {
                    # Present in the clone's history but not an ancestor of HEAD -- reachable after a
                    # history rewrite in the clone where the old object survives but is unreachable from
                    # HEAD. Let the version strings arbitrate direction first, exactly like the
                    # -not $existsInClone sibling branch above, rather than assuming unconditionally
                    # that the install is ahead.
                    $verCmp = Compare-Version -A $instVer -B $cloneVer
                    if ($null -ne $verCmp -and $verCmp -lt 0) {
                        $code = 'behind'
                        $verdict = "the clone is AHEAD of your install ($instVer -> $cloneVer); your install's commit is in the clone's history but not an ancestor of HEAD (history rewrite?)"
                        $action = "claude plugin update $id --scope project"
                    } else {
                        $code = 'clone-behind'
                        $verdict = "your install is AHEAD of the clone -- the clone is stale"
                        $action = "claude plugin marketplace update $mp"
                    }
                }
            }
        }
    } elseif ($instVer -and $cloneVer) {
        $cmp = Compare-Version -A $instVer -B $cloneVer
        if ($cmp -eq 0) {
            $code = 'ver-match'
            # This branch is reached whenever EITHER side lacks a sha (the outer test above is
            # '$instSha -and $clone.Head'), so attribute the gap to whichever side actually has it.
            if (-not $instSha -and -not $clone.Head) {
                $verdict = "versions match ($instVer); neither the install record nor the clone has a commit sha to compare finer"
            } elseif (-not $instSha) {
                $verdict = "versions match ($instVer); no commit sha in the install record to compare finer"
            } else {
                $verdict = "versions match ($instVer); the marketplace clone has no HEAD commit to compare finer"
            }
            $action = "if you expect newer: claude plugin marketplace update $mp"
        } elseif ($cmp -lt 0) {
            $code = 'behind'
            $verdict = "the clone is AHEAD of your install ($instVer -> $cloneVer)"
            $action = "claude plugin update $id --scope project"
        } else {
            $code = 'clone-behind'
            $verdict = "your install ($instVer) is AHEAD of the clone ($cloneVer) -- the clone is stale"
            $action = "claude plugin marketplace update $mp"
        }
    } else {
        # NAME WHICHEVER OF THE FOUR FIELDS IS ACTUALLY ABSENT, per field and not per side. This
        # branch is reached as soon as ONE field is missing on each side -- not both -- so a
        # per-side 'both empty' test leaves reachable states with nothing to say: an install record
        # carrying a version but no sha (every record written before GitCommitSha existed) against
        # a clone carrying a HEAD but no readable plugin.json version printed a bare
        # 'cannot determine -- ' with the reason missing. The row's Code and the summary counters
        # were right throughout, which is why nothing else showed it. Found by Victor on the pickup
        # of this branch; the asymmetric combination is pinned in the suite.
        $missing = @()
        if (-not $instVer)    { $missing += 'no version in the install record' }
        if (-not $instSha)    { $missing += 'no commit sha in the install record' }
        if (-not $cloneVer)   { $missing += "no version in the clone's plugin.json" }
        if (-not $clone.Head) { $missing += 'no HEAD or sha on the clone side' }
        $verdict = "cannot determine -- $($missing -join '; ')"
    }

    $rows.Add([pscustomobject]@{
        Id        = $id
        InstText  = $instText
        CloneText = $cloneText
        CloneVer  = $cloneVer
        Code      = $code
        Verdict   = $verdict
        Action    = $action
    })
}

# --- summary line first, then the per-plugin blocks ------------------------------------------

$good = @($rows | Where-Object { @('match', 'ver-match') -contains $_.Code })
$behind = @($rows | Where-Object { @('behind', 'clone-behind') -contains $_.Code })
# ITS OWN BUCKET, AND NOT FOLDED INTO EITHER NEIGHBOUR (#1772). It is not 'behind': nothing here
# closes the gap, so counting it there means every checkout between releases is told to run a command
# that does nothing. And it is not 'up to date' either: the clone genuinely holds newer commits, which
# is the fact somebody reading this report came for.
$unreleased = @($rows | Where-Object { $_.Code -eq 'unreleased' })
$unknown = @($rows | Where-Object { $_.Code -eq 'indeterminate' })
$total = $rows.Count

# --- brief mode: marker lines a session start can carry, and nothing else -----------------------

if ($Brief) {
    <#
        WHY THIS IS A MODE AND NOT A SECOND SCRIPT (#1591). On a machine with no sibling source
        checkout beside the consumer, connector-sessioncheck.ps1 has nothing to delegate to --
        check-connectors.ps1 is source-only and is not plugin-carried -- so the hook printed
        'no verified workshop checkout found -- check skipped' and a session got no version signal at
        all. That is the ordinary state of every consumer, not an edge case. This mode is what the
        hook prints there: the same rows the default view builds, reduced to one line per plugin that
        has something to say.

        THE MARKER SPLIT IS #1591'S OWN INSTRUCTION, not a preference. Only an install that is BEHIND
        its clone is an [ERROR], because it is the only verdict a reader closes with a command here
        and now. A stale CLONE is real and is deliberately NOT an error: it is the state of a cache
        this checkout does not own, it costs nothing until the next update, and a session start that
        shouts about it teaches the reader to skim the marker that does matter. Everything
        undetermined is [INFO] for the same reason -- 'cannot determine' reports this machine's
        bookkeeping, not a defect in the plugin.

        A PLUGIN THAT IS UP TO DATE EMITS NOTHING, and the [SUMMARY] line is what keeps that from
        being ambiguous: it carries the count, so silence per plugin reads as 'up to date' rather
        than as 'not examined'. Under lockstep that is most of the run, which is the whole cost
        argument for a brief mode existing.
    #>
    $behindOnly = @($rows | Where-Object { $_.Code -eq 'behind' })
    $staleClone = @($rows | Where-Object { $_.Code -eq 'clone-behind' })
    # 'unreleased' IS [INFO] BY THE SAME RULE AS A STALE CLONE, and it is the case that rule was
    # written for without knowing it: the only verdict worth an [ERROR] is the one a reader closes
    # with a command here and now, and this one has no command at all (#1772). Before the split it was
    # an [ERROR] at every session start of every checkout sitting between two releases -- the loudest
    # marker this tool has, on the most ordinary state a consumer can be in, prescribing a no-op.

    # EVERY FIELD ON A BRIEF LINE IS SANITIZED, and this mode is where that stops being optional
    # (Sebastian, on #1591). The default view above prints to a terminal somebody is reading; these
    # lines are forwarded verbatim into a session's CONTEXT by connector-sessioncheck, on the common
    # consumer path, at every start and every compaction. Two of the three fields are not the tool's
    # own words:
    #
    #   * Id is an 'enabledPlugins' KEY NAME -- an arbitrary JSON string from a settings file, which
    #     check-report-lib's own docstring names as the value class Format-SafeToken was built for
    #     (inbound #309);
    #   * Verdict and Action embed the version strings read from a per-plugin plugin.json inside a
    #     marketplace clone, which is a git clone of a THIRD-PARTY repository.
    #
    # A newline in any of them forges a line. That is not only a prompt-injection surface: the hook
    # selects the tally by matching '[SUMMARY]', so a forged 'up to date' summary smuggled inside a
    # 'behind' row's own text could SUPPRESS the real warning that a plugin needs updating. Sanitizing
    # at the point of emission closes both, and the marker vocabulary stays the tool's alone.
    #
    # TWO DIFFERENT SIBLINGS, because the Id and the verdict are not the same kind of value and the
    # id charset would wreck a sentence. Format-SuspectToken for the Id: it IS an id, so that charset
    # is exactly right, and where sanitizing altered it the reader is TOLD -- otherwise a stripped id
    # reads as a valid one, and the id is the half somebody would act on. Format-SafeProseToken for
    # the verdict and the action, which are sentences: it strips control characters, collapses the
    # whitespace (which is also what neutralizes U+2028/U+2029, per that lib's own note), and
    # SUBSTITUTES square brackets rather than deleting them -- which is the pass that closes the
    # suppression chain, because a forged '[SUMMARY] ... up to date' smuggled into a version string
    # becomes '(SUMMARY) ... up to date' and no hook counts it as a marker.
    foreach ($row in $rows) {
        $safeId = Format-SuspectToken -Value ([string]$row.Id)
        $safeVerdict = Format-SafeProseToken -Value ([string]$row.Verdict) -MaxLength 400
        $safeAction = Format-SafeProseToken -Value ([string]$row.Action) -MaxLength 200
        if ($row.Code -eq 'behind') {
            $line = "[ERROR] ${safeId}: $safeVerdict"
            if ($safeAction) { $line += " -- $safeAction" }
            Write-Host $line
        } elseif (@('clone-behind', 'unreleased', 'indeterminate') -contains $row.Code) {
            Write-Host "[INFO] ${safeId}: $safeVerdict"
        }
        # 'match' / 'ver-match': nothing to say, and the summary below says how many.
    }

    $parts = @("$($behindOnly.Count) behind")
    if ($staleClone.Count -gt 0) { $parts += "$($staleClone.Count) ahead of a stale clone" }
    if ($unreleased.Count -gt 0) { $parts += "$($unreleased.Count) on the released version with unreleased clone commits" }
    if ($unknown.Count -gt 0)    { $parts += "$($unknown.Count) undetermined" }
    $parts += "$($good.Count) up to date"
    Write-Host "[SUMMARY] $total plugin(s) enabled here: $($parts -join ', ')."
    exit 0
}

Write-Host ""
if ($good.Count -eq $total) {
    $vers = @($rows | ForEach-Object { $_.CloneVer } | Where-Object { $_ } | Sort-Object -Unique)
    if ($vers.Count -eq 1) {
        Write-Host "All $total plugin(s) up to date on $($vers[0])." -ForegroundColor Green
    } else {
        Write-Host "All $total plugin(s) match their marketplace clone (clone versions: $($vers -join ', '))." -ForegroundColor Green
    }
} elseif ($unknown.Count -eq $total) {
    # THE CONDITION IS 'ALL of them undetermined', not 'none behind' as it was until #1772. The old
    # test let this sentence fire while some rows were confirmed up to date, and it then said "none
    # confirmed up to date" at a run that had confirmed several. Pinning it to the all-undetermined
    # case keeps the missing-clone hint, which is the useful half, and stops it lying about the rest.
    Write-Host "$total plugin(s): none confirmed up to date and none confirmed behind -- $($unknown.Count) could not be determined (see below; a missing marketplace clone is the usual cause)." -ForegroundColor Yellow
} elseif ($behind.Count -eq 0) {
    $bits = @()
    if ($good.Count -gt 0)       { $bits += "$($good.Count) up to date" }
    if ($unreleased.Count -gt 0) { $bits += "$($unreleased.Count) on the released version, with unreleased commits in the clone" }
    if ($unknown.Count -gt 0)    { $bits += "$($unknown.Count) could not be determined" }
    Write-Host "$total plugin(s): $($bits -join ', ') -- nothing to update (see below)." -ForegroundColor Yellow
} else {
    $tailBits = @()
    if ($unknown.Count -gt 0)    { $tailBits += "$($unknown.Count) could not be determined" }
    if ($unreleased.Count -gt 0) { $tailBits += "$($unreleased.Count) on the released version, with unreleased commits in the clone" }
    $tail = if ($tailBits.Count -gt 0) { " ($($tailBits -join '; '))" } else { "" }
    Write-Host "$($behind.Count) of $total plugin(s) behind -- run the update command shown for each$tail." -ForegroundColor Yellow
}

# one line about each clone consulted
foreach ($mp in $marketplaces) {
    $c = $clones[$mp]
    if ($c.Exists) {
        $bits = @("$(if ($c.IsGit) { 'HEAD' } else { 'sha' }) $(Format-ShortSha $c.Head)")
        if ($c.HeadDate) { $bits += "committed $($c.HeadDate)" }
        if ($c.FetchTime) { $bits += "last fetch $($c.FetchTime)" }
        if (-not $c.IsGit) { $bits += "non-git fetch" }
        Write-Host "  clone '$mp': $($c.Dir)  [$($bits -join ', ')]" -ForegroundColor DarkGray
    } else {
        Write-Host "  clone '$mp': not present ($($c.Dir))" -ForegroundColor DarkGray
    }
}

foreach ($row in $rows) {
    Write-Host ""
    Write-Host $row.Id -ForegroundColor White
    Write-Host ("  installed here     " + $row.InstText)
    Write-Host ("  marketplace clone  " + $row.CloneText)
    $vcolor = switch ($row.Code) {
        'match'      { 'Green' }
        'ver-match'  { 'Green' }
        # Green because the colour answers "must I do something?" and the answer is no: the install is
        # on the released version and no command here moves it. The verdict text carries the rest.
        'unreleased' { 'Green' }
        'behind'     { 'Yellow' }
        default      { 'Yellow' }
    }
    Write-Host ("  verdict            " + $row.Verdict) -ForegroundColor $vcolor
    if ($row.Action) { Write-Host ("                     -> " + $row.Action) -ForegroundColor $vcolor }
}

Write-Host ""
exit 0
