<#
.SYNOPSIS
    Creates (or idempotently reuses) a branch and immediately creates its changelog entry file.

.DESCRIPTION
    Core improvement: branch creation and changelog-entry creation used to be two separate manual
    steps (new-branch then new-changelog-entry.ps1) -- this script merges them into a single,
    idempotent call. Only git (checkout/checkout -b) + creating the entry; no push, no PR, nothing
    repo-specific.

    Validation runs via the shared SSOT helper Test-BranchName (scripts/lib/branch-info.ps1):
      - Hard reject (exit 1): empty name, name 'main', or a name that contains the substring
        'final'.
      - Soft warn (proceed): unknown branch prefix -- falls back further on 'Chore' (new-changelog-
        entry) resp. 'question' (open-pr), consistent with those scripts. Validation is deliberately
        delegated to the consumer's table, so extended prefixes (e.g. Shopify's style/, liquid/, ...)
        simply work without this script needing to know them.

.PARAMETER Name
    The branch name, form <prefix>/<short-name> (e.g. feat/new-plugin).

.PARAMETER Title
    (Optional) title for the changelog entry file, passed through to new-changelog-entry.ps1.
    Defaults to new-changelog-entry's own default ("TODO: title").

.PARAMETER Intent
    (Optional) the direction of the branch -- what still needs to happen and where you left off.
    Passed through to new-changelog-entry.ps1 as the recorded entry body; typically given together
    with -Park when parking a branch for later / another device (#162). Left empty, the entry falls
    back to a directional block instead of a bare TODO.

.PARAMETER Park
    (Optional switch) after creating the branch + entry, commit the changelog entry (the intent
    carrier) and push the branch to origin with `git push -u` -- NO PR. Push is not a PR: parking a
    branch on the remote makes it reachable from another device without opening a PR, so the PR rule
    stays intact and separate. Default (no -Park): unchanged behaviour -- purely local, nothing is
    committed or pushed.

.EXAMPLE
    ./scripts/task/new-branch.ps1 -Name feat/new-plugin -Title "New domain plugin"

.EXAMPLE
    ./scripts/task/new-branch.ps1 -Name feat/spotify-dashboard -Title "Spotify dashboard" -Intent "Skeleton + routing done; next: wire the API client." -Park
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$Title = "TODO: title",
    [string]$Intent = "",
    [switch]$Park
)

$ErrorActionPreference = 'Stop'

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Pre-flight (#86): this script relies ONLY on scripts\lib\branch-info.ps1 in the consumer's repo
# root (no repo-config, no gh). If that is missing -- typically on a clean consumer -- stop with a
# clear pointer instead of a raw dot-source error below.
$branchInfoPath = Join-Path $repoRoot 'scripts\lib\branch-info.ps1'
if (-not (Test-Path -LiteralPath $branchInfoPath)) {
    Write-Error "new-branch cannot run -- missing repo-owned file: $branchInfoPath (Get-BranchInfo / Test-BranchName / the branch prefix table). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward."
    exit 1
}
. $branchInfoPath

# Validation via the shared SSOT helper -- no inline repetition of the hard-reject rules.
$check = Test-BranchName -Branch $Name
if (-not $check.IsValid) {
    Write-Error "new-branch cannot run -- invalid branch name '$Name': $($check.Reason)"
    exit 1
}
if (-not $check.IsKnown) {
    Write-Warning "Unknown branch prefix in '$Name' -- new-changelog-entry falls back to 'Chore', open-pr later to label 'question'. Classify manually if needed."
}

# Note: Test-BranchName above only catches the explicitly named hard rejects (empty/'main'/
# 'final'). Protection against e.g. backslashes, '..', or a leading hyphen in $Name does NOT rely
# on custom code here, but implicitly on git's own `check-ref-format` validation, which `git checkout
# -b` below enforces itself (with exit 128 on an invalid ref name). If you ever change the
# checkout mechanism (e.g. to `git branch` + a separate `checkout`, or to libgit2), check whether
# that implicit gate does not silently disappear.
#
# Idempotent: if the branch already exists locally, just check it out; otherwise create it.
# Deliberately `git -C $repoRoot` instead of Set-Location -- this script stays composable and does
# not mutate the caller's cwd. git sometimes writes progress/errors to stderr; under
# ErrorActionPreference=Stop, PS 5.1 would promote that to a terminating error before the graceful
# $LASTEXITCODE handling (the #107 pitfall, see also open-pr.ps1) -- so run under Continue, capture
# output, and only then judge.
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $null = & git -C $repoRoot rev-parse --verify --quiet "refs/heads/$Name" 2>&1
    $existsCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevEap
}
$branchExists = ($existsCode -eq 0)

$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    if ($branchExists) {
        $checkoutOutput = & git -C $repoRoot checkout $Name 2>&1
    } else {
        $checkoutOutput = & git -C $repoRoot checkout -b $Name 2>&1
    }
    $checkoutCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevEap
}
$checkoutOutput | ForEach-Object { Write-Host $_ }
if ($checkoutCode -ne 0) {
    Write-Error "git checkout of '$Name' failed."
    exit 1
}
if ($branchExists) {
    Write-Host "Branch '$Name' already existed -- checked out." -ForegroundColor Yellow
} else {
    Write-Host "Branch '$Name' created and checked out." -ForegroundColor Green
}

# Entry creation as a CHILD process: new-changelog-entry.ps1 can internally do `exit 0` (entry
# already exists) or `exit 1` (on main) -- as a child process that exit does not kill this script,
# only the child. Sibling shared script relative to $PSScriptRoot (both scripts travel together as
# a mirror pair, see scripts/lib/shared-scripts-lib.ps1). `checkout`/`checkout -b` above has already
# switched HEAD, so new-changelog-entry derives the right branch itself from HEAD.
#
# $Title and $Intent as standalone CLI arguments across this native process boundary are injection
# primitives: free text (e.g. plausibly copied from an external issue/PR title) with `"`/backslashes
# can break the child process's argv reconstruction. Therefore they are NOT passed here as
# `-Title $Title`, but via environment variables -- environment variable values do not go through
# argv requoting, so the injection disappears. `finally` also cleans up the vars on an error, so
# nothing leaks to a subsequent process in the same session.
try {
    $env:CLAUDE_NEWBRANCH_TITLE = $Title
    $env:CLAUDE_NEWBRANCH_INTENT = $Intent
    $entryScript = Join-Path $PSScriptRoot '..\release\new-changelog-entry.ps1'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $entryScript
    $entryCode = $LASTEXITCODE
} finally {
    Remove-Item Env:CLAUDE_NEWBRANCH_TITLE -ErrorAction SilentlyContinue
    Remove-Item Env:CLAUDE_NEWBRANCH_INTENT -ErrorAction SilentlyContinue
}

# -Park (opt-in): make the freshly created branch reachable from another device by committing its
# changelog entry (the intent carrier) and pushing it -- NO PR. Only when the entry step succeeded;
# on a non-zero entry code we do not park, and fall through to the exit below. Push != PR: the PR
# rule stays intact and separate (see the .PARAMETER Park note). git writes progress to stderr,
# which under EAP=Stop would die as a terminating NativeCommandError before the exit-code check
# even on exit 0 (the #107 pitfall) -- so every git call goes through the shared Invoke-NativeCapture
# (EAP=Continue -> run -> record $LASTEXITCODE), the same helper open-pr.ps1 uses for its push.
if ($Park -and $entryCode -eq 0) {
    . (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

    # The entry file for this branch (branch-info is already dot-sourced above): <SafeName>.md.
    $parkInfo  = Get-BranchInfo -Branch $Name
    $parkEntry = Join-Path $repoRoot ($parkInfo.SafeName + '.md')

    if (Test-Path -LiteralPath $parkEntry) {
        $addRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'add', '--', $parkEntry)
        $addRes.Output | ForEach-Object { Write-Host $_ }
        if ($addRes.ExitCode -ne 0) { Write-Error "park: staging the changelog entry failed."; exit 1 }
    }

    # Everything below is scoped to the entry pathspec (`-- $parkEntry`), so a park commits ONLY the
    # changelog entry: any content the caller already staged for their own next commit is left
    # exactly as it was (staged, uncommitted), not swept into the park commit.
    #
    # Commit only if the entry path actually has staged changes: a re-park of an already-committed
    # entry stages nothing (`git diff --cached --quiet -- <path>` -> exit 0), and we then just push
    # the existing commit rather than failing on an empty commit.
    $diffRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'diff', '--cached', '--quiet', '--', $parkEntry)
    if ($diffRes.ExitCode -ne 0) {
        # The commit message goes via `git commit -F <file>`, not `-m "...$Name..."`: a branch name
        # may legally carry a `"` (git check-ref-format allows it, and Test-BranchName does not
        # restrict characters), which embedded in an -m argument would break native argv
        # reconstruction (the quoting lesson). A message file sidesteps argv entirely -- the same
        # pattern open-pr.ps1 uses for the PR body. Cleaned up in finally, whether or not git succeeds.
        $msgFile = Join-Path ([System.IO.Path]::GetTempPath()) "new-branch-park-msg-$PID.txt"
        [System.IO.File]::WriteAllText($msgFile, "park: $Name (work parked for later)", (New-Object System.Text.UTF8Encoding $false))
        try {
            $commitRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'commit', '-F', $msgFile, '--', $parkEntry)
            $commitRes.Output | ForEach-Object { Write-Host $_ }
            if ($commitRes.ExitCode -ne 0) { Write-Error "park: committing the changelog entry failed."; exit 1 }
        } finally {
            Remove-Item -Path $msgFile -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "park: nothing new to commit (entry already committed) -- pushing as-is." -ForegroundColor Yellow
    }

    $pushRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'push', '-u', 'origin', $Name)
    $pushRes.Output | ForEach-Object { Write-Host $_ }
    if ($pushRes.ExitCode -ne 0) { Write-Error "park: git push failed (is 'origin' configured and reachable?)."; exit 1 }
    Write-Host "Branch '$Name' parked on origin (pushed, no PR)." -ForegroundColor Green
} elseif ($Park) {
    # -Park was requested but the entry step did not succeed -- do not commit/push, and say why
    # rather than falling through silently.
    Write-Warning "park: skipped -- the changelog entry step exited $entryCode, so nothing was committed or pushed."
}

exit $entryCode
