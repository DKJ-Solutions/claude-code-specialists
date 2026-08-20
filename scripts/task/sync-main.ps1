<#
.SYNOPSIS
    Pre-task sync for a Shopify consumer: mirror the live theme into the trunk WITHOUT letting live
    overwrite the trunk's own work (inbound #787).

.DESCRIPTION
    A live theme has no locking, no merge and no conflict detection. Third parties edit it through the
    theme editor and the last write wins, silently -- so work in a Shopify repo starts by mirroring live
    into the trunk. A WHOLESALE pull, which is the obvious implementation, knows nothing about what the
    trunk has done since and therefore overwrites it. This script is that step with the one rule that
    fixes it:

        Has the trunk touched this file since the last sync? Then the TRUNK wins. Otherwise LIVE wins.

    WHY IT SHIPS RATHER THAN BEING WRITTEN PER REPO. Two Shopify consumers wrote this script
    independently, and the first version of it DESTROYED WORK -- one of them recorded the same wholesale
    procedure reverting merged work three times in one week. The exposed party is the next consumer, who
    has no sibling repo to copy from and no reason to suspect that the obvious implementation of "mirror
    live" is the one that eats their unpushed work. The guard got its floor in 4.16.0
    (adopt-shopify-floor); this is the higher-risk half of the same problem.

    Steps:
      1. Refuse unless the working tree is clean.
      2. Switch to the trunk and fast-forward from origin.
      3. Read the exclusion rule's reference point -- BEFORE the pull, on the state the pull is about to
         change.
      4. Pull the live theme into the repo.
      5. 'git add -A', which collapses the CLI's line-ending rewrites. The Shopify CLI writes each file
         with the line endings LIVE holds, live holds both, so files come back reported as modified with
         ZERO changed lines -- measured at 37 of 712 tracked files in one consumer. Staging costs nothing
         for exactly those and leaves only real content standing. Read the drift after it, never off the
         raw 'git status'.
      6. Apply the exclusion rule: anything the trunk has touched since the reference point is restored
         to the trunk's version and kept OUT of the sync.
      7. Commit what is left on a sync branch and push it. Whether it then merges is a seam answer, and
         the default is NO.

    IT STOPS BEFORE THE MERGE BY DEFAULT, and that is a decision rather than caution. The whole point of
    the step is a moment where somebody LOOKS at what third parties changed on live before it becomes
    the base of new branches; auto-merging removes exactly the review the step exists to add. The two
    consumers this came from answer it differently, which is why it is a seam
    (Get-ShopifySyncMerges) instead of a hardcoded choice.

    WHAT IT NEVER DOES: it does not push to live, publish a theme, or delete one. It reads from live and
    writes to git. team-shopify's PreToolUse guard covers those three acts independently and is not
    weakened here.

    SEAM ANSWERS IT READS, all from the consumer's own scripts/repo-config.ps1 and all read defensively
    -- an absent function falls back to the default named beside it:

      Get-ShopifyLiveThemeId          which theme is live. REQUIRED; the script refuses to guess.
      Get-ShopifyStoreDomain          the store the pull reads from. REQUIRED for the same reason.
      Get-ShopifySyncReferencePattern the --grep pattern that recognises a sync commit.
                                      Default: the union of the two spellings in use ('^[Ss]ync').
      Get-ShopifySyncBranchPrefix     the drift branch's prefix. Default: 'sync/live-'.
      Get-ShopifySyncMerges           $true to open the PR and merge it once CI is green.
                                      Default: $false -- push, then stop.
      Get-TrunkBranchName             the trunk. Default: 'main'.
      Get-PrMergeMethod               only read when Get-ShopifySyncMerges is true. Default: 'merge'.

    Pure ASCII, per this repo's script-layer convention.

.PARAMETER Store
    Store domain to pull from, overriding Get-ShopifyStoreDomain. For a repo whose seam is not answered
    yet, or a one-off against a second store.

.PARAMETER SkipPull
    Skip the Shopify pull and run the exclusion rule over whatever is already in the working tree. For
    rehearsing the rule without touching the network; not for normal use. It also downgrades the
    clean-tree refusal to a warning, because the two would otherwise contradict each other -- a refusal
    on a dirty tree guarantees the tree never holds what this switch says it holds. Anything of yours
    left uncommitted is then read as third-party drift, which is what the warning says.

.PARAMETER StopBeforeMerge
    Push the sync branch and stop, even where Get-ShopifySyncMerges says to merge. The escape valve only
    runs in the safe direction: there is no switch that forces a merge the seam has not asked for.

.PARAMETER ChecksTimeoutMinutes
    How long to wait for CI on the sync PR before giving up and leaving it unmerged. Only used when the
    seam says to merge. Default: 15.

.EXAMPLE
    powershell -NoProfile -File scripts/task/sync-main.ps1

.EXAMPLE
    powershell -NoProfile -File scripts/task/sync-main.ps1 -SkipPull
#>
[CmdletBinding()]
param(
    [string]$Store = '',
    [switch]$SkipPull,
    [switch]$StopBeforeMerge,
    [int]$ChecksTimeoutMinutes = 15,
    [string]$RootOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

. (Join-Path $PSScriptRoot '..\lib\sync-rules.ps1')

# Dual-context repo root: a consumer running the plugin mirror gets it from CLAUDE_PROJECT_DIR, the
# source root copy falls back to the git root. Same resolution as every other mirrored script, which is
# what lets both copies stay byte-identical.
$repoRoot = if ($RootOverride) { $RootOverride } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# A repo that publishes plugins is this script's SOURCE, not a Shopify store: there is no live theme
# here to mirror. Same one-file test adopt-shopify-floor uses for the same distinction.
if (-not $RootOverride -and (Test-Path -LiteralPath (Join-Path $repoRoot '.claude-plugin\marketplace.json') -PathType Leaf)) {
    Write-Host 'REFUSED: this repo publishes plugins, so it is this script''s source rather than a Shopify consumer.' -ForegroundColor Red
    Write-Host 'There is no live theme here to mirror. Nothing was changed.'
    exit 1
}

Set-Location -LiteralPath $repoRoot

# --- The seam answers ------------------------------------------------------------------------------
# Read in a child scope with StrictMode OFF and inside a try, exactly as team-shopify's live-theme guard
# reads the same file. The reason is the same: repo-config.ps1 belongs to the consumer, so a fault in it
# must degrade to defaults rather than take this script down with it.
$seam = & {
    Set-StrictMode -Off
    $answers = @{
        LiveThemeId = ''; StoreDomain = ''; Pattern = ''; BranchPrefix = ''
        Merges = $false; Trunk = ''; MergeMethod = ''
    }
    $configPath = Join-Path $args[0] 'scripts\repo-config.ps1'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { return $answers }
    try { . $configPath } catch { return $answers }
    if (Get-Command Get-ShopifyLiveThemeId          -ErrorAction SilentlyContinue) { $answers.LiveThemeId  = [string](Get-ShopifyLiveThemeId) }
    if (Get-Command Get-ShopifyStoreDomain          -ErrorAction SilentlyContinue) { $answers.StoreDomain  = [string](Get-ShopifyStoreDomain) }
    if (Get-Command Get-ShopifySyncReferencePattern -ErrorAction SilentlyContinue) { $answers.Pattern      = [string](Get-ShopifySyncReferencePattern) }
    if (Get-Command Get-ShopifySyncBranchPrefix     -ErrorAction SilentlyContinue) { $answers.BranchPrefix = [string](Get-ShopifySyncBranchPrefix) }
    if (Get-Command Get-ShopifySyncMerges           -ErrorAction SilentlyContinue) { $answers.Merges       = [bool](Get-ShopifySyncMerges) }
    if (Get-Command Get-TrunkBranchName             -ErrorAction SilentlyContinue) { $answers.Trunk        = [string](Get-TrunkBranchName) }
    if (Get-Command Get-PrMergeMethod               -ErrorAction SilentlyContinue) { $answers.MergeMethod  = [string](Get-PrMergeMethod) }
    return $answers
} $repoRoot

$liveId = ([string]$seam.LiveThemeId).Trim()
# A NON-NUMERIC ANSWER COUNTS AS NO ANSWER -- the same rule the guard applies, and for the same reason: a
# 'VUL-IN' left behind in the seam block reads as answered to anything testing for emptiness.
if ($liveId -notmatch '^\d+$') {
    Write-Host 'Get-ShopifyLiveThemeId does not answer with a theme id -- refusing to guess which theme is live.' -ForegroundColor Red
    Write-Host "  Run 'shopify theme list' and answer it in scripts/repo-config.ps1 (see the adopt-shopify-floor skill)."
    exit 1
}

$store = if ($Store) { $Store } else { ([string]$seam.StoreDomain).Trim() }
if (-not $store -or $store -match 'VUL-IN') {
    Write-Host 'No store domain: Get-ShopifyStoreDomain is unanswered and -Store was not given.' -ForegroundColor Red
    Write-Host '  Answering the seam is the durable fix; -Store gets you through this run.'
    exit 1
}

$trunk        = if (([string]$seam.Trunk).Trim())        { ([string]$seam.Trunk).Trim() }        else { 'main' }
$pattern      = if (([string]$seam.Pattern).Trim())      { ([string]$seam.Pattern).Trim() }      else { Get-SyncDefaultReferencePattern }
$branchPrefix = if (([string]$seam.BranchPrefix).Trim()) { ([string]$seam.BranchPrefix).Trim() } else { 'sync/live-' }
$mergeMethod  = if (([string]$seam.MergeMethod).Trim())  { ([string]$seam.MergeMethod).Trim() }  else { 'merge' }
$merges       = ([bool]$seam.Merges) -and (-not $StopBeforeMerge)

# --- 1. clean tree ---------------------------------------------------------------------------------
# WITH -SkipPull THIS WARNS INSTEAD OF REFUSING, and the two halves have to agree or the switch is a
# contradiction: -SkipPull means "the tree already holds what the pull would have produced", and a
# refusal on a dirty tree guarantees it never does. So the check keeps its teeth on the normal path --
# where uncommitted work would be committed as somebody else's drift -- and steps aside on the rehearsal
# path, loudly, because that is the one case where a dirty tree is the input rather than a mistake.
$dirty = @(& git status --porcelain | Where-Object { $_ })
if ($dirty.Count -gt 0) {
    if (-not $SkipPull) {
        Write-Host "Working tree is not clean. Commit or stash first -- a sync must not carry your work into it:" -ForegroundColor Red
        $dirty | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        exit 1
    }
    Write-Host "-SkipPull with $($dirty.Count) uncommitted change(s): treating the current worktree as what a" -ForegroundColor Yellow
    Write-Host "pull would have produced. Anything of YOURS in here is about to be read as third-party drift." -ForegroundColor Yellow
}

# --- 2. the trunk, fast-forwarded ------------------------------------------------------------------
& git checkout $trunk | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "Could not switch to $trunk." -ForegroundColor Red; exit 1 }
& git pull --ff-only
if ($LASTEXITCODE -ne 0) { Write-Host "Could not fast-forward $trunk from origin." -ForegroundColor Red; exit 1 }

# --- 3. the reference point, read before the pull --------------------------------------------------
# Reading it afterwards would be reading it off a tree that already contains live's version of
# everything, which is the one ordering mistake that makes the rule useless while looking fine.
$ref = Get-SyncReferencePoint -Ref 'HEAD' -Pattern $pattern
if (-not $ref) {
    Write-Host "No reference point found: no commit matching $pattern and no tag." -ForegroundColor Red
    Write-Host '  The exclusion rule cannot be applied without one, and running without it would silently let' -ForegroundColor Red
    Write-Host "  live overwrite $trunk. Tag the current state, or sync by hand this once." -ForegroundColor Red
    exit 1
}
$since = $ref.Ref
if ($ref.Kind -eq 'tag') {
    Write-Host "Reference point: $since (a TAG -- no sync commit found, so the window is wider and more is protected)." -ForegroundColor Cyan
} else {
    Write-Host "Reference point: $since (the previous sync commit)." -ForegroundColor Cyan
}

# --- 4. pull live ----------------------------------------------------------------------------------
if (-not $SkipPull) {
    Write-Host "Pulling live theme $liveId from $store ..." -ForegroundColor Cyan
    & shopify theme pull --store $store --theme $liveId
    if ($LASTEXITCODE -ne 0) { Write-Host 'The Shopify pull failed.' -ForegroundColor Red; exit 1 }
}

# --- 5. stage, which collapses the line-ending noise -----------------------------------------------
& git add -A
$staged = @(& git diff --cached --name-status | Where-Object { $_ })
if ($staged.Count -eq 0) {
    Write-Host "No drift at all -- $trunk already matches live." -ForegroundColor Green
    exit 0
}

# --- 6. the exclusion rule -------------------------------------------------------------------------
$kept     = @()
$excluded = @()
foreach ($line in $staged) {
    $parts  = $line -split "`t", 2
    $status = $parts[0].Trim()
    $path   = if ($parts.Count -gt 1) { $parts[1] } else { '' }
    if (-not $path) { continue }

    if (-not (Test-MainTouchedSince -Since $since -Path $path)) {
        $kept += $path
        continue
    }

    # The trunk touched it, so the trunk wins: restore its version and keep the path out of the sync.
    # Arrays and splatting throughout, because a bare '--' written inline never reaches git.
    switch ($status) {
        'A' {
            # Live has a file the trunk deliberately deleted. Do not resurrect it.
            Invoke-SyncGitQuiet @('rm', '--cached', '--quiet', '--', $path) | Out-Null
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
            $excluded += "$path ($trunk deleted this; not restored)"
        }
        'D' {
            # The trunk has a file that is not live yet. Do not throw it away.
            Invoke-SyncGitQuiet @('restore', '--source=HEAD', '--staged', '--worktree', '--', $path) | Out-Null
            $excluded += "$path (not live yet; kept)"
        }
        default {
            # Changed, and the trunk has the newer version. Do not take live's.
            Invoke-SyncGitQuiet @('restore', '--source=HEAD', '--staged', '--worktree', '--', $path) | Out-Null
            $excluded += "$path ($trunk has a newer version; kept)"
        }
    }
}

if ($excluded.Count -gt 0) {
    Write-Host ''
    Write-Host "Excluded from this sync ($($excluded.Count)) -- $trunk has touched these since $since :" -ForegroundColor Yellow
    foreach ($e in $excluded) { Write-Host "  $e" -ForegroundColor Yellow }
}

if ($kept.Count -eq 0) {
    Write-Host ''
    Write-Host "No third-party drift; $trunk matches live on everything $trunk did not change itself." -ForegroundColor Green
    Invoke-SyncGitQuiet reset --quiet | Out-Null
    exit 0
}

# --- 7. the sync branch ----------------------------------------------------------------------------
# The stamp comes from the trunk's own last commit rather than from the clock, so a rerun on the same
# state lands on the same name. A second sync on one day gets a numbered suffix instead of a refusal:
# the drift is real either way and a name collision is a poor reason to make somebody sync by hand.
$stamp  = (& git log -1 --format=%cd --date=format:'%Y-%m-%d').Trim()
$branch = "$branchPrefix$stamp"
$n = 2
while (@(Invoke-SyncGitQuiet @('rev-parse', '--verify', '--quiet', "refs/heads/$branch")).Where({ $_ }).Count -gt 0) {
    $branch = "$branchPrefix$stamp-$n"
    $n++
}

Write-Host ''
Write-Host "Third-party drift on $($kept.Count) file(s); putting it on $branch." -ForegroundColor Cyan

& git checkout -b $branch | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "Could not create $branch." -ForegroundColor Red; exit 1 }

$msg = "sync: mirror in-flight third-party edits from live ($($kept.Count) file(s))"
& git commit -m $msg -- $kept
if ($LASTEXITCODE -ne 0) { Write-Host 'Commit failed.' -ForegroundColor Red; exit 1 }

& git push -u origin $branch
if ($LASTEXITCODE -ne 0) { Write-Host 'Push failed.' -ForegroundColor Red; exit 1 }

if (-not $merges) {
    Write-Host ''
    Write-Host 'Done -- and deliberately NOT merged.' -ForegroundColor Green
    Write-Host 'Open the PR, look at what the third parties changed, and merge it yourself:' -ForegroundColor Green
    Write-Host "  gh pr create --base $trunk --head $branch --title `"$msg`"" -ForegroundColor Cyan
    if ($excluded.Count -gt 0) {
        Write-Host ''
        Write-Host "Put the $($excluded.Count) exclusion(s) above in the PR body. They are the part a reviewer" -ForegroundColor Yellow
        Write-Host '  cannot see from the diff -- the diff shows what came in, not what was held back.' -ForegroundColor Yellow
    }
    exit 0
}

# --- 7b. the merging variant -----------------------------------------------------------------------
# Only reached where Get-ShopifySyncMerges says so. It uses nothing but 'gh': a consumer on either
# workflow plugin, or on neither, gets the same behaviour, and Get-PrMergeMethod is read defensively
# above rather than required.
$body = if ($excluded.Count -gt 0) {
    "Third-party drift from the live theme.`n`nHeld back by the exclusion rule ($($excluded.Count)) -- $trunk has touched these since ``$since``:`n" +
    (($excluded | ForEach-Object { "- $_" }) -join "`n")
} else {
    "Third-party drift from the live theme. Nothing was held back by the exclusion rule."
}

& gh pr create --base $trunk --head $branch --title $msg --body $body
if ($LASTEXITCODE -ne 0) { Write-Host "Could not open the PR. The branch is pushed; open it by hand." -ForegroundColor Red; exit 1 }

$pr = ([string](& gh pr view $branch --json number --jq '.number')).Trim()
Write-Host "Sync PR #$pr opened; waiting up to $ChecksTimeoutMinutes min for CI." -ForegroundColor Cyan

# The same stderr wrapper the lib carries for git, for the same reason: '2>$null' on a native executable
# under EAP=Stop turns every stderr line into a terminating NativeCommandError, and 'gh pr checks' writes
# to stderr while a run is still pending -- which is exactly the state this loop exists to sit through.
function Invoke-GhQuiet {
    $ErrorActionPreference = 'Continue'
    gh @args 2>$null
}

$deadline = (Get-Date).AddMinutes($ChecksTimeoutMinutes)
while ((Get-Date) -lt $deadline) {
    $states = @(Invoke-GhQuiet pr checks $pr --json state --jq '.[].state' | Where-Object { $_ })
    if ($states.Count -eq 0) { Start-Sleep -Seconds 15; continue }
    $bad = @($states | Where-Object { $_ -notin @('SUCCESS', 'NEUTRAL', 'SKIPPED', 'PENDING', 'QUEUED', 'IN_PROGRESS') })
    if ($bad.Count -gt 0) {
        Write-Host "CI failed on sync PR #$pr ($($bad -join ', ')) -- NOT merged." -ForegroundColor Red
        Write-Host "  In a Shopify repo this is usually theme-check over a third party's edit. Fix it as its own" -ForegroundColor Red
        Write-Host "  named change, then: gh pr merge $pr --$mergeMethod" -ForegroundColor Red
        exit 1
    }
    if (@($states | Where-Object { $_ -in @('PENDING', 'QUEUED', 'IN_PROGRESS') }).Count -eq 0) { break }
    Start-Sleep -Seconds 15
}

if ((Get-Date) -ge $deadline) {
    Write-Host "CI on sync PR #$pr was not green within $ChecksTimeoutMinutes min -- NOT merged." -ForegroundColor Red
    Write-Host "  Merge it yourself once it is: gh pr merge $pr --$mergeMethod" -ForegroundColor Red
    exit 1
}

# --subject gives the merge commit the same shape as every other line in the graph. On a squash or
# rebase method gh has no merge commit to name and ignores the flag.
& gh pr merge $pr --$mergeMethod --subject "merge: $branch (#$pr)"
if ($LASTEXITCODE -ne 0) { Write-Host "The merge failed. PR #$pr is open and green; merge it by hand." -ForegroundColor Red; exit 1 }

& git checkout $trunk | Out-Null
& git pull --ff-only
Write-Host "Done -- sync PR #$pr merged into $trunk." -ForegroundColor Green
