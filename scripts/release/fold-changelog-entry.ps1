<#
Folds one or more changelog entry files (<branch-name>.md in the repo root) into a section of
CHANGELOG.md, and then removes the entry files.

WHICH section is repo-owned: repo-config.ps1's Get-ChangelogHeading names the literal heading line
('## Pull Requests' in this workshop, '## [Unreleased]' on a Keep-a-Changelog consumer). It used to
be hardcoded, which made this script stop outright on any repo naming its section differently
(issue #178). The function is OPTIONAL -- a consumer without it falls back to '## Pull Requests', so
every existing consumer keeps working unchanged.

In fold-all mode (no -Branch) only files that are actually changelog entries are folded: an entry
opens with the '### <title> <midDot> <type> <midDot> <date>' H3 heading, so repo-root meta docs
(CONTRIBUTING.md, SECURITY.md, ...) that open with an H1 are left untouched. -Branch mode targets
exactly the named entry and is unaffected.

The entry file is already compact (heading `### title - type - date` with middot separation,
followed by the description) -- matching the CHANGELOG format. When folding, fold only adds
'#NN - ' at the front of the title and, as the last line, the link `[PR #NN](url)`. The PR number +
url are fetched via `gh pr list` (on -Branch, or in fold-all mode derived from the file name) --
that can only happen after opening the PR. If no PR is found (e.g. a manual merge without a PR),
no number/url is added and the heading stays without #NN.

Usage:
  .\scripts\release\fold-changelog-entry.ps1 -Branch feat/new-plugin
  .\scripts\release\fold-changelog-entry.ps1              # folds all present entry files
  .\scripts\release\fold-changelog-entry.ps1 -RepoRoot C:\path\to\worktree   # explicit root (#101)
  .\scripts\release\fold-changelog-entry.ps1 -Branch feat/x -Push            # fold, commit and push

Run this on main, right after merging a branch.

COMMITTING IS OPT-IN (-Commit, or -Push which implies it). Without either, the fold is left on disk for
you to commit -- the behaviour this script always had. With them it makes the commit itself, naming
CHANGELOG.md and the entry files as the commit's pathspec so nothing else can be swept in: this commit
lands directly on the main branch under one of the two named exceptions to "never commit directly", and
an exception only stays safe while it stays the size it was granted at.
#>

param(
    [string]$Branch,
    # #101: explicit override of the repo root, for a consumer that runs the fold from a
    # temporary/detached worktree (e.g. a ship-pr.ps1 that checks out main elsewhere) and wants to
    # write to that tree instead of whatever CLAUDE_PROJECT_DIR/git-root would resolve to. Default
    # (omitted): unchanged behavior below.
    [string]$RepoRoot,
    # Commit the fold. OFF BY DEFAULT, deliberately: this commit lands directly on the main branch,
    # which is one of the two named exceptions to "never commit directly" -- so it has to be asked for,
    # exactly like teardown.ps1 requires -Apply before it removes anything.
    #
    # The scope limit the exception grants is enforced by git rather than by care: the commit names its
    # paths, so CHANGELOG.md and the entry files this run folded are the only things that can end up in
    # it, whatever else is lying around in the tree or already staged.
    [switch]$Commit,
    # Push the fold commit. Implies -Commit. Separate because a fold commit sitting unpushed on main is
    # its own silent half-state -- the repo looks folded locally and unfolded to everyone else -- and
    # that is precisely the class of half-finished state this repo keeps finding the expensive way.
    [switch]$Push
)

$ErrorActionPreference = "Stop"

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
# -RepoRoot (#101), when supplied, wins over both -- see the param comment above. Note: PowerShell
# variable names are case-insensitive, so $RepoRoot (the param) and $repoRoot (used below) are the
# same variable; the guard below only computes the dual-context fallback when it is still empty.
if (-not $repoRoot) {
    $repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }
}
Set-Location $repoRoot

# Pre-flight (#86): fold relies on scripts\repo-config.ps1 in the consumer's repo root. If that is
# missing -- typically on a clean consumer -- stop with a clear pointer instead of a raw
# dot-source error on the . (dot-source) line below.
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "fold-changelog cannot run -- missing repo-owned file: $configPath (Get-RepoName / Get-RepoBlobUrl / Get-LintScript). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward."
    exit 1
}

# Repo name from the repo root's local repo-config (single source), no longer hardcoded.
# Deliberately from $repoRoot and not $PSScriptRoot: from the plugin mirror, $PSScriptRoot points
# to the plugin cache, while repo-config always lives in the consumer's repo root.
. (Join-Path $repoRoot 'scripts\repo-config.ps1')
$repo = Get-RepoName

# Pre-flight (#86): an unfilled scaffold (repo-config still at VUL-IN) would otherwise only fail
# further down with an unclear gh error. Stop here with a clear pointer.
if ($repo -match 'VUL-IN') {
    Write-Error "fold-changelog cannot run -- scripts\repo-config.ps1 still contains VUL-IN placeholders. Fill in Get-RepoName with this repo's value and run again."
    exit 1
}

# The 'Plugins:' detection relies on Get-TouchedPlugins from scripts\lib\release-lib.ps1 (#103,
# Victor #3) -- but release-lib.ps1 is deliberately NOT mirrored to the plugin (workshop-specific
# tooling, see scripts\lib\shared-scripts-lib.ps1), unlike this fold script itself. In the
# workshop root it simply exists; in a consumer repo running the plugin mirror it is missing, and
# the Plugins line is omitted -- functionally the same as before, since
# plugins/<plugin>/ paths do not exist there anyway.
$releaseLibPath = Join-Path $repoRoot 'scripts\lib\release-lib.ps1'
$canDetectPlugins = Test-Path -LiteralPath $releaseLibPath
if ($canDetectPlugins) { . $releaseLibPath }

# Shared native-capture helper (#114 item 1). $PSScriptRoot-relative, not $repoRoot: like
# check-report-lib.ps1 this lib is not repo-owned -- it travels with the SAME plugin/mirror payload
# as this script (registered in scripts\lib\shared-scripts-lib.ps1), so it resolves from the
# workshop root, a consumer's plugin cache, or the plugin mirror tree alike.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# BOM-less UTF8 -- Set-Content -Encoding UTF8 always adds a BOM in Windows PowerShell 5.1,
# and the rest of the repo (CHANGELOG.md etc.) has no BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Test-IsChangelogEntryFile {
    # A changelog entry file (created by new-changelog-entry.ps1) always opens with the compact
    # entry heading '### <title> <midDot> <type> <midDot> <date>' -- an H3. Repo-root meta docs
    # (CONTRIBUTING.md, SECURITY.md, a future CODE_OF_CONDUCT.md, ...) open with an H1 ('# ...').
    # Fold-all mode keys off this structural signature so it only ever folds a genuine entry, never
    # whatever other *.md happens to sit in the repo root. Deliberately independent of the branch-
    # prefix table: consumer-extended prefixes (Shopify's style/, liquid/, ...) still fold, since an
    # entry from any prefix is written in this same format. The denylist below stays as a cheap
    # first filter; this is the actual gate.
    param([Parameter(Mandatory = $true)][string]$Path)
    foreach ($line in [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        return ($line -match '^###\s')
    }
    return $false
}

if ($Branch) {
    # Explicit target: the caller named the branch, so trust it and fold exactly that entry file.
    $entryFiles = @(($Branch -replace '/', '-') + ".md")
}
else {
    # Fold-all: never fold a file that is not an actual changelog entry (structural gate above).
    $reserved = @("CHANGELOG.md", "CLAUDE.md", "README.md")
    $entryFiles = Get-ChildItem -Path $repoRoot -Filter "*.md" -File |
        Where-Object { $reserved -notcontains $_.Name } |
        Where-Object { Test-IsChangelogEntryFile -Path $_.FullName } |
        Select-Object -ExpandProperty Name
}

if ($entryFiles.Count -eq 0) {
    Write-Host "No entry files found to fold." -ForegroundColor Yellow
    exit 0
}

$changelogPath = Join-Path $repoRoot "CHANGELOG.md"

# The section heading to fold into: repo-owned and OPTIONAL (issue #178). Get-Command-guarded exactly
# like open-pr.ps1 does for its optional repo-config functions, so a consumer whose repo-config
# predates this contract simply gets the workshop default instead of a crash.
#
# The local name is $foldHeading, NOT $changelogHeading: repo-config.ps1 backs Get-ChangelogHeading
# with $script:ChangelogHeading, and PowerShell variable names are case-insensitive -- at script
# top-level the local and script scopes are the same, so assigning $changelogHeading here would
# overwrite the dot-sourced value before the function is ever called, and the configured heading
# would silently read back as the default. Sibling of the $RepoRoot/$repoRoot collision documented
# at the top of this file.
$foldHeading = '## Pull Requests'
if (Get-Command Get-ChangelogHeading -ErrorAction SilentlyContinue) {
    $configured = Get-ChangelogHeading
    if ($configured) { $foldHeading = $configured.Trim() }
}
$headingPattern = '(?m)^' + [regex]::Escape($foldHeading) + '\s*?$'

# What this run actually folded -- the source for both the commit message and the committed pathspec.
$folded = @()

foreach ($file in $entryFiles) {
    $filePath = Join-Path $repoRoot $file
    if (-not (Test-Path $filePath)) {
        Write-Host "Entry file '$file' not found - skipped." -ForegroundColor Yellow
        continue
    }

    $entryContent = (Get-Content -Path $filePath -Raw -Encoding UTF8).TrimEnd()
    $changelogContent = Get-Content -Path $changelogPath -Raw -Encoding UTF8

    $usesCRLF = $changelogContent.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }
    $entryContent = ($entryContent -replace "`r`n", "`n") -replace "`n", $nl

    # The entry file is already compact ("### <title> <midDot> <type> <midDot> <date>" +
    # description), matching the CHANGELOG format. Fold only adds '#NN <midDot> ' at the front of
    # the title and the PR link at the end. The PR number only exists after the merge; we fetch it
    # via the branch -- from -Branch, or in fold-all mode derived from the file name
    # (<prefix>-<rest>.md -> <prefix>/<rest>).
    $midDot = [char]0x00B7
    $branchForPr = $Branch
    if (-not $branchForPr) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $branchForPr = $base -replace '^([^-]+)-', '$1/'
    }
    # gh can write messages to stderr; Invoke-NativeCapture runs it under EAP=Continue so that
    # cannot become a terminating error before the graceful exit-code handling below (#107).
    # -DiscardStderr (2>$null) keeps stderr out of the captured JSON. 'files' is simply included in
    # --json (Victor #4, #103) -- gh pr list supplies that field just as well as gh pr view, so the
    # second gh call (previously gh pr view --json files) has been dropped: one PR lookup suffices
    # for both the number/url and the touched files.
    $prList = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--head', $branchForPr, '--state', 'all', '--json', 'number,url,files', '--limit', '1', '--repo', $repo) -DiscardStderr
    $ghCode = $prList.ExitCode
    $prJson = $prList.Output
    if ($ghCode -ne 0) { Write-Host "  (gh pr list returned exit code $ghCode -- PR-number enrichment skipped; run gh manually for the reason.)" -ForegroundColor DarkYellow }
    $prs = if ($ghCode -eq 0 -and $prJson) { @($prJson | ConvertFrom-Json) } else { @() }
    if ($prs.Count -ge 1) {
        $num = $prs[0].number
        $entryContent = ([regex]'(?m)^### ').Replace($entryContent, "### #$num $midDot ", 1)

        # Deriving touched plugins from the PR files (automation-first): paths under
        # plugins/<plugin>/ become a 'Plugins:' line, which
        # cut-release.ps1 later uses to update the per-plugin CHANGELOGs. The detection itself
        # lives in the pure Get-TouchedPlugins (release-lib.ps1, #103) -- only the guard is here;
        # 'files' already came along with the gh pr list call above, so no separate gh roundtrip
        # is needed anymore.
        if ($canDetectPlugins) {
            $paths = @($prs[0].files | ForEach-Object { $_.path })
            $touched = @(Get-TouchedPlugins -Files $paths)
            if ($touched.Count -gt 0) {
                $entryContent = $entryContent.TrimEnd() + "$nl$nl" + ('Plugins: ' + ($touched -join ', '))
            }
        }

        $entryContent = $entryContent.TrimEnd() + "$nl$nl[PR #$num]($($prs[0].url))"
    }
    else {
        Write-Host "  No PR found for '$branchForPr' - entry without PR number/url." -ForegroundColor Yellow
    }

    $headingMatch = [regex]::Match($changelogContent, $headingPattern)
    if (-not $headingMatch.Success) {
        Write-Host "Could not find the '$foldHeading' heading in CHANGELOG.md - stopping. (The heading comes from Get-ChangelogHeading in scripts\repo-config.ps1; set it to the section this repo folds into.)" -ForegroundColor Red
        exit 1
    }
    $afterHeader = $headingMatch.Index + $headingMatch.Length

    # Insert after any intro paragraph: at the top of the section, but below its intro text. The
    # section ends at whichever comes first after the heading -- the first ###-entry already in it, or
    # the next ##-section. Deriving the boundary structurally (issue #178) rather than looking for a
    # literal '## Releases' keeps this correct on a Keep-a-Changelog consumer too, where the sections
    # below '## [Unreleased]' are the released versions ('## [vX.Y.Z] - ...'), not a Releases block.
    $nextSection = ([regex]'(?m)^## ').Match($changelogContent, $afterHeader)
    $sectionEnd = if ($nextSection.Success) { $nextSection.Index } else { $changelogContent.Length }
    $firstEntry = ([regex]'(?m)^### ').Match($changelogContent, $afterHeader)
    $insertPos = if ($firstEntry.Success -and $firstEntry.Index -lt $sectionEnd) { $firstEntry.Index } else { $sectionEnd }

    $entryBlock = "$entryContent$nl$nl---$nl$nl"
    $changelogContent = $changelogContent.Substring(0, $insertPos) + $entryBlock + $changelogContent.Substring($insertPos)

    Write-Utf8NoBom -Path $changelogPath -Content $changelogContent
    Remove-Item -Path $filePath -Force
    Write-Host "Folded and removed: $file" -ForegroundColor Green
    # Captured per iteration rather than read back afterwards. $num in particular survives from one loop
    # pass to the next, so an entry whose PR lookup found nothing would otherwise inherit the previous
    # entry's number -- into a commit message, where a wrong PR reference is worse than none.
    $folded += [pscustomobject]@{
        File   = $file
        Branch = $branchForPr
        Pr     = $(if ($prs.Count -ge 1) { $prs[0].number } else { $null })
    }
}

Write-Host "CHANGELOG.md updated." -ForegroundColor Green

# --- The fold commit ------------------------------------------------------------------------------
# WHY THIS IS IN THE SCRIPT AT ALL. The fold has always ended with a hand-typed commit, and on
# August 2, 2026 that happened four times in one session -- the exact "noticed once, automated the
# second time" trigger this house works by. It is also the step where a mistake is least visible: the
# fold itself is verified by the lint gate, while the commit around it is typed from memory each time.
#
# THE SCOPE IS ENFORCED BY GIT, NOT BY CARE. 'git commit -- <paths>' commits exactly those paths and
# ignores the index, so whatever else is modified or already staged cannot ride along. That matters
# more here than anywhere else in this repo: this commit goes straight to the main branch under a named
# exception to "never commit directly", and an exception is only safe while it stays the size it was
# granted at.
if ($Push) { $Commit = $true }
if ($Commit) {
    if ($folded.Count -eq 0) {
        Write-Host "Nothing was folded, so there is nothing to commit." -ForegroundColor Yellow
        exit 0
    }
    $subjects = @($folded | ForEach-Object {
        if ($_.Pr) { "$($_.Branch) (#$($_.Pr))" } else { $_.Branch }
    })
    $message = if ($folded.Count -eq 1) {
        "chore: fold changelog entry $($subjects[0])"
    } else {
        "chore: fold $($folded.Count) changelog entries: " + ($subjects -join ', ')
    }
    # CHANGELOG.md plus the entry files -- named, and nothing else. The entry files are gone from disk
    # by now; naming a deleted path is how git is told to record the deletion.
    #
    # ONLY THE ONES GIT ALREADY KNOWS. In the normal flow the entry file was committed on the branch and
    # came to main with the merge, so it is tracked and its deletion belongs in this commit. But an entry
    # written and folded without ever being committed is untracked, and naming an untracked path makes
    # 'git commit' fail on the pathspec -- after the fold has already deleted the file, which is the
    # worst possible moment for an avoidable error. Read from the index rather than from disk, because by
    # now the file is gone from disk and still in the index, which is exactly the state that needs
    # recording.
    $entryPaths = @($folded | ForEach-Object { $_.File })
    $lsFiles = Invoke-NativeCapture -FilePath 'git' -Arguments (@('ls-files', '--') + $entryPaths)
    # git reports its own paths with forward slashes; the entry names are plain file names in the repo
    # root, so normalising both sides costs nothing and removes the one way this could silently drop a
    # deletion from the commit.
    $tracked = @($lsFiles.Output | Where-Object { $_ } | ForEach-Object { ($_ -replace '/', '\').Trim() })
    $paths = @('CHANGELOG.md') + @($entryPaths | Where-Object { $tracked -contains ($_ -replace '/', '\') })
    $untracked = @($entryPaths | Where-Object { $tracked -notcontains ($_ -replace '/', '\') })
    if ($untracked.Count -gt 0) {
        Write-Host "  (not in the commit, because git never tracked them: $($untracked -join ', ') -- they were folded and deleted all the same.)" -ForegroundColor DarkYellow
    }
    $commitRun = Invoke-NativeCapture -FilePath 'git' -Arguments (@('commit', '-m', $message, '--') + $paths)
    if ($commitRun.ExitCode -ne 0) {
        Write-Host ($commitRun.Output -join "`n") -ForegroundColor Red
        Write-Host "The fold is on disk but NOT committed (git commit exited $($commitRun.ExitCode)). Commit it by hand; do not re-run the fold, it has already removed the entry files." -ForegroundColor Red
        exit 1
    }
    Write-Host "Committed: $message" -ForegroundColor Green

    if ($Push) {
        $pushRun = Invoke-NativeCapture -FilePath 'git' -Arguments @('push')
        if ($pushRun.ExitCode -ne 0) {
            Write-Host ($pushRun.Output -join "`n") -ForegroundColor Red
            Write-Host "Committed locally but NOT pushed (git push exited $($pushRun.ExitCode)) -- the state this flag exists to avoid. Push by hand." -ForegroundColor Red
            exit 1
        }
        Write-Host "Pushed." -ForegroundColor Green
    }
}
