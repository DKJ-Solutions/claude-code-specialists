<#
.SYNOPSIS
    Pre-task sync for a Shopify consumer: mirror the live theme into the trunk WITHOUT letting live
    overwrite the trunk's own work (inbound #787, rewritten on inbound #807).

.DESCRIPTION
    A live theme has no locking, no merge and no conflict detection. Third parties edit it through the
    theme editor and the last write wins, silently -- so work in a Shopify repo starts by mirroring live
    into the trunk. A WHOLESALE pull, which is the obvious implementation, knows nothing about what the
    trunk has done since and therefore overwrites it.

    WHY IT SHIPS RATHER THAN BEING WRITTEN PER REPO. Two Shopify consumers wrote this script
    independently, and the first version of it DESTROYED WORK -- one of them recorded the same wholesale
    procedure reverting merged work three times in one week. The exposed party is the next consumer, who
    has no sibling repo to copy from and no reason to suspect that the obvious implementation of "mirror
    live" is the one that eats their unpushed work. The guard got its floor in 4.16.0
    (adopt-shopify-floor); this is the higher-risk half of the same problem.

    THE RULE CHANGED ON AUGUST 21, 2026 (inbound #807), AND THE OLD ONE WAS THE WRONG MEASUREMENT RATHER
    THAN A BUGGY ONE. It read: "has the trunk touched this file since the last sync? then the trunk
    wins". Two failures, and only the first is repairable:

      1. The floor was read with 'git log --grep', which matches ANY LINE of a message. A merge commit
         for a sync branch carries the sync commit's subject in its BODY, so the pattern matched the
         MERGE and the floor landed on HEAD. With the floor at HEAD nothing counts as touched-since and
         the rule passed every file straight through -- the exact no-floor failure it exists to prevent,
         arriving as a GREEN run. Repaired in Get-SyncReferencePoint in two steps: '--no-merges' first
         (inbound #801), and then -- because that removes only the MERGE commits, while any ordinary
         commit whose body opens a line with 'sync' still won -- by matching the pattern against the
         commit SUBJECT rather than through '--grep' at all (inbound #819).
      2. Deeper, and not fixable by repairing the floor: nothing pushes the trunk TO live except the
         per-file release step, and a deletion cannot be pushed that way at all -- so the trunk's changes
         are permanently invisible to live and sink below the floor as soon as one more sync commit
         lands. After that every future sync tries to overwrite them again, forever. In a repo that has
         adopted the changelog model this is not an edge case: "merged but not live yet" is a DESIGNED
         state, and every pending entry names work a wholesale sync would revert.

    SO CONTENT DECIDES NOW, NOT TIME:

        Has this path ever held live's content in the trunk's history? Then the trunk wins. Otherwise
        live wins -- and if the trunk also changed it, nobody wins and a human looks.

    Measured both ways in a consumer before it was built; the numbers are in Test-LiveContentIsOurs. The
    floor survives, demoted: its only remaining job is to notice that live's content is foreign AND the
    trunk changed the same path recently -- both sides moved -- and refuse. A wrong floor now costs an
    extra conflict report, never silent data loss.

    THREE STRUCTURAL CHANGES MAKE IT UNABLE TO DESTROY WORK RATHER THAN MERELY UNLIKELY TO:

      * LIVE IS PULLED INTO A MIRROR OUTSIDE THE REPO, not over the working tree, and the tree is written
        only for the files whose verdict is take-live. The wholesale version pulled over the tree first
        and then restored what it should not have taken -- so every bug in the rule was a bug that had
        ALREADY overwritten the file, and any failure between the pull and the restore left the damage
        standing. Not theoretical: the run that found the floor bug died at 'git checkout -b' with 31
        files staged.
      * IT NEVER DELETES. A path the trunk has and live does not is either a file the trunk added and
        never pushed, or one a third party deleted on live -- indistinguishable, and deleting is the
        irreversible option. It is reported, not acted on.
      * THE BRANCH NAME IS DECIDED BEFORE THE PULL. A name that cannot be created is a reason to stop
        while the tree is still clean, not after several hundred files have been written.

    -DryRun does everything except write: the full verdict table, nothing touched, and it is safe on a
    dirty tree because it writes nothing at all. Run it first.

    Steps:
      1. Refuse unless the working tree is clean (-DryRun is exempt: it writes nothing).
      2. Switch to the trunk and fast-forward from origin.
      3. Read the conflict-check reference point -- BEFORE the pull, on the state the pull is about to
         change.
      4. Decide the sync branch's name, before anything is pulled.
      5. Pull the live theme into a mirror outside the repo, then decide a verdict per differing path.
      6. Write, commit and push ONLY the paths whose verdict is take-live. Whether it then merges is a
         seam answer, and the default is NO.

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

.PARAMETER DryRun
    Report the verdict for every differing path and write nothing at all: no branch, no commit, no push,
    and the working tree is not touched. Safe on a dirty tree, deliberately -- a dirty tree is exactly
    when somebody wants to ask "what would the sync do to this?", and refusing there would make the
    check unavailable at the one moment it is worth running.

.PARAMETER MirrorPath
    Use an existing live mirror instead of pulling one, for rehearsing the rule offline and for the test
    suite. The mirror is read and never modified.

.PARAMETER KeepMirror
    Do not delete the pulled mirror afterwards. A refused run keeps it regardless, because the conflict
    report names files inside it.

.PARAMETER StopBeforeMerge
    Push the sync branch and stop, even where Get-ShopifySyncMerges says to merge. The escape valve only
    runs in the safe direction: there is no switch that forces a merge the seam has not asked for.

.PARAMETER ChecksTimeoutMinutes
    How long to wait for CI on the sync PR before giving up and leaving it unmerged. Only used when the
    seam says to merge. Default: 15.

.EXAMPLE
    powershell -NoProfile -File scripts/task/sync-main.ps1 -DryRun

.EXAMPLE
    powershell -NoProfile -File scripts/task/sync-main.ps1
#>
[CmdletBinding()]
param(
    [string]$Store = '',
    [switch]$DryRun,
    [string]$MirrorPath = '',
    [switch]$KeepMirror,
    [switch]$StopBeforeMerge,
    [int]$ChecksTimeoutMinutes = 15,
    [string]$RootOverride = '',
    # RETIRED, AND ACCEPTED ONLY TO REFUSE IT BY NAME. -SkipPull meant "run the rule over whatever is
    # already in the working tree", which cannot mean anything now that the pull goes to a mirror and the
    # tree is written only for take-live paths. Left in the signature because PowerShell's own error for
    # an unknown parameter names the parameter and nothing else, and a consumer whose notes still carry
    # the old flag deserves to be told what replaced it.
    [switch]$SkipPull
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($SkipPull) {
    Write-Host '-SkipPull was retired when the pull moved into a mirror outside the repo (inbound #807).' -ForegroundColor Red
    Write-Host '  It meant "run the rule over the working tree", and the rule no longer reads the tree.'
    Write-Host '  Use -DryRun to see every verdict without writing anything, or -MirrorPath <dir> to run'
    Write-Host '  against a mirror you already have. Nothing was changed.'
    exit 1
}

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

# THE DIRECTORIES A SHOPIFY PULL WRITES, and this is a constant rather than a seam on purpose: the set is
# defined by the platform, not by the repo. Naming them explicitly is what keeps anything else in the
# mirror -- and everything of the repo's own (scripts/, CLAUDE.md, the workflow folder) -- out of the
# comparison and therefore out of any commit. A repo whose theme does not sit at the root is out of
# scope for this script rather than a knob nobody has asked for.
$ThemeDirs = @('assets', 'blocks', 'config', 'layout', 'locales', 'sections', 'snippets', 'templates')

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
$merges       = ([bool]$seam.Merges) -and (-not $StopBeforeMerge) -and (-not $DryRun)

Write-Host ''
Write-Host "=== pre-task sync  |  store: $store  theme: $liveId ===" -ForegroundColor Cyan
if ($DryRun) { Write-Host 'DRY RUN -- nothing will be written.' -ForegroundColor Magenta }

# --- 1. clean tree ---------------------------------------------------------------------------------
# A DRY RUN IS EXEMPT, AND THAT IS THE POINT OF IT. It writes nothing, checks nothing out and pulls into
# a mirror, so it is safe on a dirty tree -- and a dirty tree is exactly when somebody wants to ask what
# the sync would do to it. Refusing there would make the safety check unavailable at the one moment it is
# worth running, which is how safety checks stop being run.
if (-not $DryRun) {
    $dirty = @(& git status --porcelain | Where-Object { $_ })
    if ($dirty.Count -gt 0) {
        Write-Host 'Working tree is not clean. Commit or stash first -- a sync must not carry your work into it:' -ForegroundColor Red
        $dirty | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        Write-Host '(-DryRun works on a dirty tree: it writes nothing.)' -ForegroundColor Yellow
        exit 1
    }
}

# --- 2. the trunk, fast-forwarded ------------------------------------------------------------------
if ($DryRun) {
    $onBranch = ([string](& git rev-parse --abbrev-ref HEAD)).Trim()
    Write-Host ''
    Write-Host "[1/6] dry run -- staying on $onBranch, checking out and pulling nothing." -ForegroundColor Yellow
} else {
    Write-Host ''
    Write-Host "[1/6] $trunk, fast-forward from origin ..." -ForegroundColor Yellow
    & git checkout $trunk | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "Could not switch to $trunk." -ForegroundColor Red; exit 1 }
    & git pull --ff-only
    if ($LASTEXITCODE -ne 0) { Write-Host "Could not fast-forward $trunk from origin." -ForegroundColor Red; exit 1 }
}

# --- 3. the reference point, read before the pull --------------------------------------------------
# Reading it afterwards would be reading it off a tree that already contains live's version of
# everything, which is the one ordering mistake that makes the check useless while looking fine.
Write-Host ''
Write-Host '[2/6] the conflict-check reference point ...' -ForegroundColor Yellow
$ref = Get-SyncReferencePoint -Ref 'HEAD' -Pattern $pattern
if (-not $ref) {
    Write-Host "No reference point found: no commit matching $pattern and no tag." -ForegroundColor Red
    Write-Host '  It no longer decides who wins a file -- content does -- but it is what notices that BOTH' -ForegroundColor Red
    Write-Host '  sides changed the same path, and without it such a conflict would be taken silently.' -ForegroundColor Red
    Write-Host '  Tag the current state, or sync by hand this once.' -ForegroundColor Red
    exit 1
}
$since = $ref.Ref
if ($ref.Kind -eq 'tag') {
    Write-Host "      $since (a TAG -- no sync commit found, so the window is wider and more is flagged)."
} else {
    Write-Host "      $since (the previous sync commit)."
}

# --- 4. the branch name, decided BEFORE anything is pulled -----------------------------------------
# Before, not after: the wholesale version worked this out at the very end and died on a collision with
# 31 files already staged. The stamp comes from the clock rather than from the trunk's last commit, which
# is a repair of its own -- on a day after the last commit the old stamp produced a name that already
# existed. Remote refs are checked too, because a sync branch that is pushed but not merged is the
# ordinary state of this workflow.
Write-Host ''
Write-Host '[3/6] naming the sync branch ...' -ForegroundColor Yellow
$stamp  = (Get-Date -Format 'yyyy-MM-dd')
$branch = "$branchPrefix$stamp"
$n = 1
while (
    @(Invoke-SyncGitQuiet @('rev-parse', '--verify', '--quiet', "refs/heads/$branch")).Where({ $_ }).Count -gt 0 -or
    @(Invoke-SyncGitQuiet @('rev-parse', '--verify', '--quiet', "refs/remotes/origin/$branch")).Where({ $_ }).Count -gt 0
) {
    $n++
    $branch = "$branchPrefix$stamp-$n"
    if ($n -gt 20) { Write-Host "Twenty sync branches already exist for $stamp. Something is wrong; stopping." -ForegroundColor Red; exit 1 }
}
Write-Host "      $branch"

# --- 5. live, into a MIRROR outside the repo --------------------------------------------------------
Write-Host ''
Write-Host '[4/6] mirroring live ...' -ForegroundColor Yellow
$mirror = $MirrorPath
$pulledMirror = $false
if (-not $mirror) {
    $mirror = Join-Path ([System.IO.Path]::GetTempPath()) ('live-mirror-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
    New-Item -ItemType Directory -Path $mirror -Force | Out-Null
    $pulledMirror = $true
    & shopify theme pull --store $store --theme $liveId --path $mirror
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'The Shopify pull failed. Nothing was touched.' -ForegroundColor Red
        if (-not $KeepMirror) { Remove-Item -LiteralPath $mirror -Recurse -Force -ErrorAction SilentlyContinue }
        exit 1
    }
} else {
    if (-not (Test-Path -LiteralPath $mirror)) { Write-Host "MirrorPath does not exist: $mirror" -ForegroundColor Red; exit 1 }
    Write-Host "      using the mirror given: $mirror"
}

try {
    # --- which paths differ at all ------------------------------------------------------------------
    # Two stages, for process count rather than correctness -- see Get-GitRawBlobId. Stage one is pure
    # .NET against 'git ls-tree'; only what survives it pays for a git call.
    #
    # 'ls-tree -r HEAD' IS READ IN ITS DEFAULT FORMAT, not through '--format'. The format option arrived
    # in git 2.36 and this script has no reason to require it: the default line is
    # '<mode> SP <type> SP <oid> TAB <path>', and the tab is what makes a path with spaces safe to split.
    #
    # A PATH WITH A HIGH BYTE FAILS IN THE LOSING DIRECTION, so how it is read off git matters. git's
    # default is to quote any path with a byte above 0x7F -- 'assets/cafe.js' with an accent comes out as
    # '"assets/caf\303\251.js"', measured against git 2.54 -- and that string matches no key the mirror
    # walk produces. The trunk's copy then reads as a path live does not have (kept, correctly) while
    # live's identical file reads as one the trunk has never held: foreign, taken, and the trunk's version
    # overwritten.
    #
    # 'core.quotePath=false' WAS THE FIRST REPAIR AND IT WAS HALF OF ONE (inbound #821, August 21, 2026).
    # It makes git emit the raw UTF-8 bytes instead -- and PowerShell decodes those with
    # [Console]::OutputEncoding, i.e. with whatever console code page the run inherited. On cp850, the
    # default OEM console here, they decode to two wrong characters and the comparison lands in exactly
    # the failure above. The flag fixed the quoting and moved the same bug into the decoder, where it is
    # invisible: the answer depended on who launched the run.
    #
    # SO QUOTING IS FORCED **ON** AND THE ESCAPES ARE UNPACKED HERE. Quoted, the wire is pure ASCII, where
    # every candidate code page agrees -- Convert-GitQuotedPath (sync-rules.ps1) turns the escapes back
    # into bytes and reads them as UTF-8 once, so no environment can reach the answer. 'true' rather than
    # git's default, because a repo may set core.quotepath in its own config and would otherwise put the
    # decoder back in charge. The same treatment goes on 'check-ignore', whose output is a path for the
    # same reason.
    Write-Host ''
    Write-Host "[5/6] comparing live against $trunk ..." -ForegroundColor Yellow

    $headBlobs = @{}
    foreach ($line in (& git -c core.quotePath=true ls-tree -r HEAD)) {
        if (-not $line) { continue }
        $tab = $line.IndexOf("`t")
        if ($tab -lt 0) { continue }
        $meta = ($line.Substring(0, $tab) -split '\s+')
        if ($meta.Count -lt 3) { continue }
        $headBlobs[(Convert-GitQuotedPath -Path $line.Substring($tab + 1))] = $meta[2]
    }

    $mirrorPaths = @{}
    foreach ($d in $ThemeDirs) {
        $dir = Join-Path $mirror $d
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        foreach ($f in (Get-ChildItem -LiteralPath $dir -Recurse -File)) {
            $rel = $f.FullName.Substring($mirror.Length).TrimStart('\', '/') -replace '\\', '/'
            $mirrorPaths[$rel] = $f.FullName
        }
    }
    Write-Host "      live: $($mirrorPaths.Count) file(s) across the theme director(ies) present"

    # GITIGNORED PATHS ARE NOT THE SYNC'S BUSINESS. config/settings_data.json is the obvious one: a repo
    # that ignores the live theme's settings would otherwise see it arrive as a brand-new foreign file on
    # every single run and capture it forever.
    #
    # THE PATHS GO IN AS ARGUMENTS, NOT THROUGH '--stdin', AND THAT IS MEASURED. 'git check-ignore
    # --stdin <paths>' answers 'fatal: cannot specify pathnames with --stdin' and exits 128, which this
    # wrapper swallows -- so the whole filter silently reports nothing ignored. Feeding real stdin is not
    # available either: Windows PowerShell 5.1 does not connect a pipeline to a native executable's stdin
    # here, and it has no '<' redirect ("The '<' operator is reserved for future use"). Both forms were
    # tried against git 2.54 before this loop was written. Batched because a whole theme's worth of paths
    # would otherwise approach the command-line length limit.
    $ignored = @{}
    $allPaths = @($mirrorPaths.Keys)
    for ($i = 0; $i -lt $allPaths.Count; $i += 200) {
        $batch = @($allPaths[$i..([Math]::Min($i + 199, $allPaths.Count - 1))])
        if ($batch.Count -eq 0) { continue }
        # Quoted on the wire and unpacked here, the same way ls-tree is read above and for the same
        # reason -- a raw high byte would be decoded by the inherited console code page (inbound #821).
        foreach ($hit in @(Invoke-SyncGitQuiet @(@('-c', 'core.quotePath=true', 'check-ignore', '--') + $batch))) {
            if ($hit) { $ignored[(Convert-GitQuotedPath -Path ([string]$hit).Trim())] = $true }
        }
    }
    if ($ignored.Count -gt 0) { Write-Host "      $($ignored.Count) of them are gitignored here and are left alone" }

    $differing = @()
    foreach ($rel in ($mirrorPaths.Keys | Sort-Object)) {
        if ($ignored.ContainsKey($rel)) { continue }
        $bytes = [System.IO.File]::ReadAllBytes($mirrorPaths[$rel])
        if ($headBlobs.ContainsKey($rel)) {
            # Stage one: byte-identical to what the trunk stores.
            if ($headBlobs[$rel] -eq (Get-GitRawBlobId -Bytes $bytes)) { continue }
            # Stage two: identical once CR bytes are ignored -- the line-ending case, measured at 37 of
            # 712 files in one consumer. Compared against the trunk's STORED id, never against bytes read
            # back through the PowerShell pipeline; that read is what corrupted the first version of this.
            if ($headBlobs[$rel] -eq (Get-GitRawBlobId -Bytes (Get-CrStrippedBytes -Bytes $bytes))) { continue }
            $differing += [pscustomobject]@{ Status = 'M'; Path = $rel; Bytes = $bytes; Source = $mirrorPaths[$rel] }
        } else {
            $differing += [pscustomobject]@{ Status = 'A'; Path = $rel; Bytes = $bytes; Source = $mirrorPaths[$rel] }
        }
    }
    # Paths the trunk has under a theme directory that live does not.
    foreach ($rel in ($headBlobs.Keys | Sort-Object)) {
        $top = ($rel -split '/')[0]
        if ($ThemeDirs -notcontains $top) { continue }
        if ($mirrorPaths.ContainsKey($rel)) { continue }
        if ($ignored.ContainsKey($rel)) { continue }
        $differing += [pscustomobject]@{ Status = 'D'; Path = $rel; Bytes = (New-Object byte[] 0); Source = '' }
    }

    if ($differing.Count -eq 0) {
        Write-Host ''
        Write-Host "No differences at all -- $trunk already matches live." -ForegroundColor Green
        exit 0
    }
    Write-Host "      $($differing.Count) path(s) differ (line-ending-only differences already excluded)"

    # --- the verdict per path -----------------------------------------------------------------------
    Write-Host ''
    Write-Host '[6/6] applying the rule ...' -ForegroundColor Yellow
    $take = @(); $keep = @(); $conflict = @()
    foreach ($f in $differing) {
        if ($f.Status -eq 'D') {
            $v = Get-SyncFileVerdict -Status 'D' -LiveContentIsOurs $false
        } else {
            $ours    = Test-LiveContentIsOurs -Path $f.Path -LiveBytes $f.Bytes -Ref 'HEAD'
            # The floor is only consulted where it can still change the answer: live's content is foreign.
            $touched = if ($ours) { $false } else { Test-MainTouchedSince -Since $since -Path $f.Path }
            $v = Get-SyncFileVerdict -Status $f.Status -LiveContentIsOurs $ours -MainTouchedSinceFloor $touched
        }
        $row = [pscustomobject]@{ Status = $f.Status; Path = $f.Path; Source = $f.Source; Reason = $v.Reason }
        switch ($v.Action) {
            'take-live' { $take     += $row }
            'conflict'  { $conflict += $row }
            default     { $keep     += $row }
        }
    }

    Write-Host ''
    Write-Host "  held back ($trunk wins): $($keep.Count)" -ForegroundColor Green
    foreach ($r in $keep) { Write-Host ("    [{0}] {1,-46} {2}" -f $r.Status, $r.Path, $r.Reason) -ForegroundColor DarkGray }
    Write-Host "  to take from live:       $($take.Count)" -ForegroundColor Cyan
    foreach ($r in $take) { Write-Host ("    [{0}] {1,-46} {2}" -f $r.Status, $r.Path, $r.Reason) -ForegroundColor Cyan }
    if ($conflict.Count -gt 0) {
        Write-Host "  CONFLICTS:               $($conflict.Count)" -ForegroundColor Red
        foreach ($r in $conflict) { Write-Host ("    [{0}] {1,-46} {2}" -f $r.Status, $r.Path, $r.Reason) -ForegroundColor Red }
    }

    if ($conflict.Count -gt 0) {
        Write-Host ''
        Write-Host 'REFUSING TO SYNC. Both sides changed the paths above, so taking either would lose the' -ForegroundColor Red
        Write-Host 'other. Nothing has been written. Compare them by hand and merge deliberately:' -ForegroundColor Red
        foreach ($r in $conflict) {
            $mirrorFile = Join-Path $mirror ($r.Path -replace '/', '\')
            Write-Host "  git diff --no-index -- `"$($r.Path)`" `"$mirrorFile`"" -ForegroundColor Yellow
        }
        # The mirror is what those commands read, so a refused run keeps it whatever the switch says.
        $KeepMirror = $true
        exit 1
    }

    if ($take.Count -eq 0) {
        Write-Host ''
        Write-Host "No third-party drift. Everything live holds differently is a version this repo has had" -ForegroundColor Green
        Write-Host "before -- $trunk has simply moved on. Nothing to sync, nothing written." -ForegroundColor Green
        exit 0
    }

    if ($DryRun) {
        Write-Host ''
        Write-Host "DRY RUN -- would put the $($take.Count) file(s) above on $branch. Nothing written." -ForegroundColor Magenta
        exit 0
    }

    # --- the sync branch: write ONLY what was decided, commit, push ---------------------------------
    Write-Host ''
    Write-Host "Third-party drift on $($take.Count) file(s); putting it on $branch." -ForegroundColor Cyan
    & git checkout -b $branch | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "Could not create $branch. Nothing written." -ForegroundColor Red; exit 1 }

    foreach ($r in $take) {
        $dest = Join-Path $repoRoot ($r.Path -replace '/', '\')
        $destDir = Split-Path -Parent $dest
        if ($destDir -and -not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item -LiteralPath $r.Source -Destination $dest -Force
    }

    $paths = @($take | ForEach-Object { $_.Path })
    Invoke-SyncGitQuiet @(@('add', '--') + $paths) | Out-Null

    $msg = "sync: mirror in-flight third-party edits from live ($($take.Count) file(s))"
    & git commit --quiet -m $msg -- @paths
    if ($LASTEXITCODE -ne 0) { Write-Host 'Commit failed.' -ForegroundColor Red; exit 1 }

    & git push -u origin $branch
    if ($LASTEXITCODE -ne 0) { Write-Host "Push failed. The commit is local on $branch." -ForegroundColor Red; exit 1 }

    if (-not $merges) {
        Write-Host ''
        Write-Host 'Done -- and deliberately NOT merged.' -ForegroundColor Green
        Write-Host 'Open the PR, look at what the third parties changed, and merge it yourself:' -ForegroundColor Green
        Write-Host "  gh pr create --base $trunk --head $branch --title `"$msg`"" -ForegroundColor Cyan
        if ($keep.Count -gt 0) {
            Write-Host ''
            Write-Host "Put these $($keep.Count) exclusion(s) in the PR body -- the diff shows what came in," -ForegroundColor Yellow
            Write-Host '  never what was held back:' -ForegroundColor Yellow
            foreach ($r in $keep) { Write-Host "  $($r.Path) -- $($r.Reason)" -ForegroundColor Yellow }
        }
        exit 0
    }

    # --- the merging variant ------------------------------------------------------------------------
    # Only reached where Get-ShopifySyncMerges says so. It uses nothing but 'gh': a consumer on either
    # workflow plugin, or on neither, gets the same behaviour, and Get-PrMergeMethod is read defensively
    # above rather than required.
    $body = if ($keep.Count -gt 0) {
        "Third-party drift from the live theme.`n`nHeld back by the content rule ($($keep.Count)):`n" +
        (($keep | ForEach-Object { "- ``$($_.Path)`` -- $($_.Reason)" }) -join "`n")
    } else {
        'Third-party drift from the live theme. Nothing was held back by the content rule.'
    }

    & gh pr create --base $trunk --head $branch --title $msg --body $body
    if ($LASTEXITCODE -ne 0) { Write-Host 'Could not open the PR. The branch is pushed; open it by hand.' -ForegroundColor Red; exit 1 }

    $pr = ([string](& gh pr view $branch --json number --jq '.number')).Trim()
    Write-Host "Sync PR #$pr opened; waiting up to $ChecksTimeoutMinutes min for CI." -ForegroundColor Cyan

    $deadline = (Get-Date).AddMinutes($ChecksTimeoutMinutes)
    while ((Get-Date) -lt $deadline) {
        # The same stderr wrapper the lib carries for git, for the same reason: '2>$null' on a native
        # executable under EAP=Stop turns every stderr line into a terminating NativeCommandError, and
        # 'gh pr checks' writes to stderr while a run is still pending -- which is exactly the state this
        # loop exists to sit through.
        $prevEap = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $states = @(gh pr checks $pr --json state --jq '.[].state' 2>$null | Where-Object { $_ })
        } finally { $ErrorActionPreference = $prevEap }
        if ($states.Count -eq 0) { Start-Sleep -Seconds 15; continue }
        $bad = @($states | Where-Object { $_ -notin @('SUCCESS', 'NEUTRAL', 'SKIPPED', 'PENDING', 'QUEUED', 'IN_PROGRESS') })
        if ($bad.Count -gt 0) {
            Write-Host "CI failed on sync PR #$pr ($($bad -join ', ')) -- NOT merged." -ForegroundColor Red
            Write-Host '  In a Shopify repo this is usually theme-check over a third party''s edit. Fix it as its own' -ForegroundColor Red
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
    exit 0
}
finally {
    if ($pulledMirror -and -not $KeepMirror -and (Test-Path -LiteralPath $mirror)) {
        Remove-Item -LiteralPath $mirror -Recurse -Force -ErrorAction SilentlyContinue
    } elseif ($pulledMirror -and $KeepMirror) {
        Write-Host ''
        Write-Host "Mirror kept at: $mirror" -ForegroundColor Yellow
    }
}
