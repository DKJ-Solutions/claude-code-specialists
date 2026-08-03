<#
Creates the changelog entry file for the current branch in the repo root:
<branch-name-with-hyphens>.md, with branch name, date, and branch type already filled in.

Usage:
  .\scripts\release\new-changelog-entry.ps1 -Title "Short title of the change"

Branch type is derived from the branch prefix via the shared table in
scripts/lib/branch-info.ps1 (feat/fix/docs/chore).
Unknown prefix -> falls back to "Chore" with a warning, adjust it yourself in the file.

Optional -Intent: the direction of the branch -- what still needs to happen and where you left
off. Typically given when parking a branch for later (see new-branch.ps1 -Park). If it is given it
becomes the recorded entry body; if it is left empty the body falls back to a directional block
instead of a bare one-line TODO, so a forgotten -Intent still leaves a "what is next / where was
I" prompt rather than an empty placeholder (#162).

Internal handoff from new-branch.ps1: that script invokes this file as a child process without
-Title/-Intent, and passes them instead via the environment variables CLAUDE_NEWBRANCH_TITLE and
CLAUDE_NEWBRANCH_INTENT. Reason: free text (e.g. copied from an external issue/PR title) as a
standalone CLI argument across a native process boundary is an injection primitive
(quotes/backslashes can break the child process's argv reconstruction); environment variable
values do not go through argv requoting. If -Title/-Intent is given explicitly (standalone use), it
always wins; only when the param is at its own default AND the env var is set is the env var used.
#>

param(
    [string]$Title = "TODO: title",
    [string]$Intent = ""
)

$ErrorActionPreference = "Stop"

# See the handoff explanation above: only adopt it if the param is still at its own default, so
# an explicit -Title (standalone use) always keeps precedence.
if ($Title -eq "TODO: title" -and $env:CLAUDE_NEWBRANCH_TITLE) {
    $Title = $env:CLAUDE_NEWBRANCH_TITLE
}
# Same injection-safe env-var handoff for the optional intent; the env var is only the fallback
# while -Intent is still at its own (empty) default, so an explicit -Intent always wins.
if ($Intent -eq "" -and $env:CLAUDE_NEWBRANCH_INTENT) {
    $Intent = $env:CLAUDE_NEWBRANCH_INTENT
}

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Pre-flight (#86): this script relies ONLY on scripts\lib\branch-info.ps1 in the consumer's repo
# root (no repo-config, no gh -- lighter than fold/open-pr). If that is missing -- typically on a
# clean consumer -- stop with a clear pointer instead of a raw dot-source error below.
$branchInfoPath = Join-Path $repoRoot 'scripts\lib\branch-info.ps1'
if (-not (Test-Path -LiteralPath $branchInfoPath)) {
    Write-Error "new-changelog-entry cannot run -- missing repo-owned file: $branchInfoPath (Get-BranchInfo / the branch prefix table). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward."
    exit 1
}

# BOM-less UTF8 -- Set-Content -Encoding UTF8 always adds a BOM in Windows PowerShell 5.1,
# and the rest of the repo has no BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq "main") {
    Write-Host "You are on main - create a branch first." -ForegroundColor Red
    exit 1
}

. $branchInfoPath

$info = Get-BranchInfo -Branch $branch
$branchType = $info.Type
if (-not $branchType) {
    $branchType = "Chore"
    Write-Host "Unknown branch prefix '$($info.Prefix)' - 'Branch type' set to 'Chore', adjust this by hand if needed." -ForegroundColor Yellow
}

$fileName = $info.SafeName + ".md"
$filePath = Join-Path $repoRoot $fileName

if (Test-Path $filePath) {
    Write-Host "Entry file '$fileName' already exists - nothing done." -ForegroundColor Yellow
    exit 0
}

$today = Get-Date -Format "yyyy-MM-dd"
$midDot = [char]0x00B7

# Body: an explicit -Intent (typically when parking the branch for later / another device) becomes
# the recorded body; otherwise it falls back to a directional block instead of a bare one-line
# TODO, so a forgotten -Intent still prompts for "what is next / where was I" (#162). Either way
# this is a scaffold: whoever finishes the branch replaces the body with the final description
# before the PR (open-pr and fold-changelog-entry read exactly this text).
if ($Intent -ne "") {
    $body = $Intent
} else {
    $body = "TODO: what still needs to happen on this branch, and where you left off."
}

# Compact heading, matching the CHANGELOG format (fold will later add only '#NN <midDot> ' at
# the front and the '[PR #NN](url)' link at the end -- those only exist after the PR is opened).
$template = @"
### $Title $midDot $branchType $midDot $today

**To do / where I left off:**

$body
"@

[System.IO.File]::WriteAllText($filePath, $template, $Utf8NoBom)
Write-Host "Created: $fileName" -ForegroundColor Green
