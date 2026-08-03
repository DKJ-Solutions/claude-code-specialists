<#
.SYNOPSIS
    Drift guard for cut-release.ps1's stray-entry allowlist ($reservedRootMd).

.DESCRIPTION
    cut-release.ps1 refuses to cut a release while an "unfolded changelog entry file" sits in the
    repo root. It recognises an entry by exclusion: every root *.md that is NOT in the $reservedRootMd
    allowlist is treated as an entry. That is deliberately catch-all (so an entry with an unknown
    branch prefix is never missed), but it means every PERMANENT root doc (README, CONTRIBUTING,
    SECURITY, ...) must be listed in the allowlist -- otherwise a release falsely refuses to cut the
    moment such a doc is added. That drift once blocked a real release (CONTRIBUTING.md/SECURITY.md
    were added to the root but not to the allowlist).

    This test catches that drift automatically: every TRACKED root *.md that is not a branch-prefixed
    changelog entry (feat-/fix-/docs-/chore-*.md) must appear in cut-release.ps1's $reservedRootMd.
    Reads the allowlist straight out of the script text (cut-release.ps1 runs its guardrails on load,
    so it cannot be dot-sourced) and compares it against the actual tracked root docs via git.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/cut-release-guardrail.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot       = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$CutReleasePath = Join-Path $RepoRoot 'scripts\release\cut-release.ps1'

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

Write-Host "cut-release.ps1 -- reserved-root-md allowlist covers every permanent root doc" -ForegroundColor Cyan

# 1. Parse the allowlist literal out of the script text.
$cutReleaseText = [System.IO.File]::ReadAllText($CutReleasePath, [System.Text.Encoding]::UTF8)
$m = [regex]::Match($cutReleaseText, '\$reservedRootMd\s*=\s*@\(([^)]*)\)')
Assert-True $m.Success 'found the $reservedRootMd allowlist literal in cut-release.ps1'
$allowlist = @([regex]::Matches($m.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
Assert-True ($allowlist.Count -gt 0) 'allowlist parsed to at least one entry'

# 2. Tracked root *.md files (no directory separator = repo root), excluding branch-prefixed entries.
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $tracked = @(& git -C $RepoRoot ls-files -- '*.md' 2>$null)
} finally {
    $ErrorActionPreference = $prevEap
}
$rootMd = @($tracked | Where-Object { $_ -and ($_ -notmatch '/') })
# A branch changelog entry file is named after its branch: <prefix>-<name>.md with a known prefix.
$entryPattern = '^(feat|fix|docs|chore)-.*\.md$'
$permanentDocs = @($rootMd | Where-Object { $_ -notmatch $entryPattern })
Assert-True ($permanentDocs.Count -gt 0) 'found tracked permanent root docs to check'

# 3. Every permanent root doc must be covered by the allowlist -- otherwise a release would falsely
#    flag it as an unfolded entry and refuse to cut.
$uncovered = @($permanentDocs | Where-Object { $allowlist -notcontains $_ })
Assert-True ($uncovered.Count -eq 0) "every permanent root doc is in `$reservedRootMd (uncovered: $($uncovered -join ', '))"

Write-Host "cut-release.ps1 -- every planned file is checked before the first one is written" -ForegroundColor Cyan
# WHY THIS IS A TEXT ASSERT AND NOT A BEHAVIOUR ONE: cut-release.ps1 runs its guardrails on load (it
# refuses to be anywhere but a clean main), so it cannot be dot-sourced and the collision path cannot
# be exercised in-process -- the same constraint the allowlist check above works around.
#
# WHAT IT PROTECTS. With the highlights tier on (#417 phase 2) a cut writes THREE files, and the
# order is load-bearing: collect every target, check them all, then write. Checking each one just
# before its own write would leave a release whose developer notes exist and whose stakeholder
# document does not -- half a release, discovered by the release manager rather than by a guard, on
# an action that has already committed nothing and cannot be re-run because the first file now exists.
$planned = [regex]::Match($cutReleaseText, '(?m)^\$plannedFiles\s*=')
Assert-True $planned.Success 'cut-release.ps1 collects its write targets in $plannedFiles'
$guardLoop = [regex]::Match($cutReleaseText, '(?ms)foreach \(\$rel in \$plannedFiles\).*?Nothing was written')
Assert-True $guardLoop.Success 'the collision guard loops over that whole collection and says nothing was written'
$firstWrite = $cutReleaseText.IndexOf('Write-Utf8NoBom -Path')
Assert-True ($firstWrite -gt 0) 'found the first content write in cut-release.ps1'
Assert-True ($guardLoop.Success -and $firstWrite -gt ($guardLoop.Index + $guardLoop.Length)) `
    'the guard runs BEFORE any file is written, so a collision leaves the tree untouched'
# And the highlights pair is really in that collection -- a guard over one path would pass the asserts
# above while protecting nothing new.
$plannedBlock = [regex]::Match($cutReleaseText, '(?ms)^\$plannedFiles\s*=.*?^foreach \(\$rel in \$plannedFiles\)')
Assert-True ($plannedBlock.Success -and $plannedBlock.Value -match 'highlightsRelPath' -and $plannedBlock.Value -match 'highlightsHtmlRelPath') `
    'both highlights targets (the .md and the .html) join the collection when the tier is on'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
