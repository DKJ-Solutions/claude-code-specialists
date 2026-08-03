<#
.SYNOPSIS
    Regression tests for the shared-workflow-scripts mechanics (issue #81): shared-scripts-lib.ps1,
    the generator/drift check, and the repo invariant that every plugin mirror is in sync with its source.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Exit code 0 if everything passes, 1 on a failure.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/shared-scripts.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

Write-Host "Get-SharedScriptPairs" -ForegroundColor Cyan
$pairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)
Assert-True ($pairs.Count -ge 1) 'at least one shared script registered'
$fold = $pairs | Where-Object { $_.Name -eq 'fold-changelog-entry' }
Assert-True ($null -ne $fold) 'fold-changelog-entry is in the register'
Assert-True ($fold.SourceRel -like 'scripts\*') 'source is repo-root-relative under scripts\'
Assert-True ($fold.MirrorRel -like 'plugins\*') 'mirror lives under the plugin'
# Explicit -- the generic loops further down already cover these two implicitly, but a missing
# pair in the register would then slip through silently instead of giving a targeted failure.
$newChangelogPair = $pairs | Where-Object { $_.Name -eq 'new-changelog-entry' }
Assert-True ($null -ne $newChangelogPair) 'new-changelog-entry is in the register'
$newBranchPair = $pairs | Where-Object { $_.Name -eq 'new-branch' }
Assert-True ($null -ne $newBranchPair) 'new-branch is in the register'

Write-Host "Repo invariant: every mirror in sync with its source" -ForegroundColor Cyan
foreach ($pair in $pairs) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    $mirror = Get-NormalizedScriptContent -Path $pair.MirrorPath
    Assert-True ($null -ne $src) "source exists: $($pair.SourceRel)"
    Assert-True ($null -ne $mirror) "mirror exists: $($pair.MirrorRel)"
    Assert-Equal $src $mirror "in sync: $($pair.Name)"
}

Write-Host "Dual-context resolution guarded in every source" -ForegroundColor Cyan
# The whole mirror mechanism relies on a shared script resolving its repo root dual-context.
# If CLAUDE_PROJECT_DIR disappears from a source, the consumer call breaks silently -- this catches
# that. Exception: a dot-sourced LIB (issue #114's check-report-lib) is not itself a standalone
# entry point -- it never resolves a repo root; it is reached via a $PSScriptRoot-relative
# dot-source from a caller that already resolved one, so this invariant does not apply to it.
# The lib exception is declared in the REGISTRY (LibOnly), not in a list kept here. This used to be a
# hand-written array of names, which meant every new shared lib arrived as a failing assert about an
# invariant that does not apply to it -- and the fix was to edit a second literal that nothing tied to
# the registration. Registering a lib now carries its own exception.
$libOnlyPairs = @($pairs | Where-Object { $_.LibOnly } | ForEach-Object { $_.Name })
Assert-True ($libOnlyPairs.Count -ge 1) 'the registry declares at least one dot-sourced lib (LibOnly)'
# Two ways to satisfy the invariant since inbound #203: resolve CLAUDE_PROJECT_DIR inline, or delegate
# to check-report-lib's shared Resolve-CheckRoot (which the two sync checks now do, so they can also
# report HOW the root was resolved). A bare '-match CLAUDE_PROJECT_DIR' would still pass on the two
# checks purely because their COMMENTS name the env var -- the assertion has to look for an actual
# call, otherwise it silently stops guarding anything the day the code moves out.
foreach ($pair in ($pairs | Where-Object { $libOnlyPairs -notcontains $_.Name })) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    $inline   = $src -match '\$env:CLAUDE_PROJECT_DIR'
    $delegate = $src -match 'Resolve-CheckRoot\s+-Override'
    Assert-True ($inline -or $delegate) "$($pair.Name): source resolves the repo root dual-context (inline `$env:CLAUDE_PROJECT_DIR or Resolve-CheckRoot)"
}

# The invariant moves with the behavior: check-report-lib now OWNS the dual-context resolution for the
# scripts that delegate, so the env var has to be read there for real. Without this, dropping it from
# Resolve-CheckRoot would leave every delegating check silently non-dual-context while the loop above
# stayed green on the delegation alone.
$reportLibSrc = Get-NormalizedScriptContent -Path (($pairs | Where-Object { $_.Name -eq 'check-report-lib' }).SourcePath)
Assert-True ($reportLibSrc -match 'function Resolve-CheckRoot') 'check-report-lib defines Resolve-CheckRoot (the shared dual-context resolver)'
Assert-True ($reportLibSrc -match '\$env:CLAUDE_PROJECT_DIR') 'check-report-lib really reads $env:CLAUDE_PROJECT_DIR (not only the delegating callers)'

Write-Host "Get-NormalizedScriptContent" -ForegroundColor Cyan
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-test-$PID.ps1")
[System.IO.File]::WriteAllText($tmp, "line1`r`nline2`r`n", (New-Object System.Text.UTF8Encoding $false))
try {
    $norm = Get-NormalizedScriptContent -Path $tmp
    Assert-Equal "line1`nline2`n" $norm 'CRLF is LF-normalized'
} finally {
    Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
}
Assert-Equal $null (Get-NormalizedScriptContent -Path (Join-Path $RepoRoot 'does-not-exist-xyz.ps1')) 'missing file -> $null'

Write-Host "build-shared-scripts.ps1 -Check -- repo in sync" -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\sync\build-shared-scripts.ps1') -Check | Out-Null
Assert-Equal 0 $LASTEXITCODE 'generator -Check green on the repo'

Write-Host "Pre-flight (#86): missing repo-config stops with a clear pointer" -ForegroundColor Cyan
# Run every source against an EMPTY repo root (via CLAUDE_PROJECT_DIR) -- without repo-config/branch-info
# the pre-flight should stop with a pointer instead of a raw dot-source error. Child process, because
# the scripts call 'exit' themselves.
$pfDir = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-preflight-$PID")
New-Item -ItemType Directory -Path $pfDir -Force | Out-Null
$prevPd = $env:CLAUDE_PROJECT_DIR
$prevEap = $ErrorActionPreference
$vfDir = $null
try {
    $env:CLAUDE_PROJECT_DIR = $pfDir
    # Continue, not Stop: the child writes its pointer via Write-Error to stderr; with 2>&1,
    # Windows PowerShell 5.1 would treat that as a terminating NativeCommandError and abort this test.
    $ErrorActionPreference = 'Continue'
    # The CHILD PROCESS itself already renders Write-Error to plain stderr lines at its own
    # (non-interactive) console width, BEFORE that text is ever captured here -- a word like
    # 'branch-info.ps1' can coincidentally split exactly at the hyphen wrap boundary
    # ('branch-'\n'info.ps1'), which would make a bare -match below fail flakily, purely depending
    # on the (arbitrary) temp-path length. Stripping newlines before the match restores the
    # original continuous text -- no functional change, only deterministic matching.
    function Test-OutputContains { param([string]$Text, [string]$Pattern) return (($Text -replace "`r?`n", '') -match $Pattern) }

    $foldSrc = ($pairs | Where-Object { $_.Name -eq 'fold-changelog-entry' }).SourcePath
    $foldOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $foldSrc 2>&1 | Out-String)
    $foldCode = $LASTEXITCODE
    Assert-Equal 1 $foldCode 'fold stops (exit 1) without repo-config'
    Assert-True (Test-OutputContains $foldOut 'repo-config') 'fold names repo-config in the pointer'
    $prSrc = ($pairs | Where-Object { $_.Name -eq 'open-pr' }).SourcePath
    $prOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $prSrc -Title 'fix: preflight-test' 2>&1 | Out-String)
    $prCode = $LASTEXITCODE
    Assert-Equal 1 $prCode 'open-pr stops (exit 1) without repo-config/branch-info'
    Assert-True (Test-OutputContains $prOut 'branch-info') 'open-pr names branch-info in the pointer'

    # new-changelog-entry and new-branch rely ONLY on branch-info.ps1 (no repo-config, no gh --
    # lighter than fold/open-pr), so no VUL-IN follow-up scenario for these two: their only pre-flight
    # check is the bare existence check on branch-info.ps1 below.
    $nceSrc = ($pairs | Where-Object { $_.Name -eq 'new-changelog-entry' }).SourcePath
    $nceOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $nceSrc -Title 'fix: preflight-test' 2>&1 | Out-String)
    $nceCode = $LASTEXITCODE
    Assert-Equal 1 $nceCode 'new-changelog-entry stops (exit 1) without branch-info'
    Assert-True (Test-OutputContains $nceOut 'branch-info') 'new-changelog-entry names branch-info in the pointer'
    $nbSrc = ($pairs | Where-Object { $_.Name -eq 'new-branch' }).SourcePath
    $nbOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $nbSrc -Name 'feat/preflight-test' 2>&1 | Out-String)
    $nbCode = $LASTEXITCODE
    Assert-Equal 1 $nbCode 'new-branch stops (exit 1) without branch-info'
    Assert-True (Test-OutputContains $nbOut 'branch-info') 'new-branch names branch-info in the pointer'

    # Second scenario: scaffolds PRESENT but not yet filled in (VUL-IN) -> also stops with a pointer.
    # Minimal scaffolds (repo-config with VUL-IN + an empty branch-info so open-pr's existence check
    # succeeds and the placeholder check is reached).
    $vfDir = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-vulin-$PID")
    New-Item -ItemType Directory -Path (Join-Path $vfDir 'scripts\lib') -Force | Out-Null
    $Utf8 = New-Object System.Text.UTF8Encoding $false
    $rcVulin = @'
$script:RepoName = 'VUL-IN/repo'
function Get-RepoName { return $script:RepoName }
function Get-RepoBlobUrl { return "https://github.com/$($script:RepoName)/blob/main/" }
$script:LintScript = 'VUL-IN'
function Get-LintScript { return $script:LintScript }
'@
    $biVulin = @'
$script:BranchTypeOrder = @()
$script:BranchPrefixTable = @{}
function Get-BranchTypes { return $script:BranchTypeOrder }
function Get-BranchPrefix { param([string]$Branch) if ($Branch -match '/') { return ($Branch -split '/')[0] } return ($Branch -split '-')[0] }
function Get-BranchInfo { param([string]$Branch) [pscustomobject]@{ Branch = $Branch; Prefix = (Get-BranchPrefix $Branch); IsKnown = $false; Label = $null; Type = $null; SafeName = ($Branch -replace '/', '-') } }
'@
    [System.IO.File]::WriteAllText((Join-Path $vfDir 'scripts\repo-config.ps1'), $rcVulin, $Utf8)
    [System.IO.File]::WriteAllText((Join-Path $vfDir 'scripts\lib\branch-info.ps1'), $biVulin, $Utf8)
    $env:CLAUDE_PROJECT_DIR = $vfDir
    $foldV = (& powershell -NoProfile -ExecutionPolicy Bypass -File $foldSrc 2>&1 | Out-String)
    $foldVCode = $LASTEXITCODE
    Assert-Equal 1 $foldVCode 'fold stops (exit 1) on an unfilled VUL-IN scaffold'
    Assert-True ($foldV -match 'VUL-IN') 'fold names VUL-IN in the pointer'
    $prV = (& powershell -NoProfile -ExecutionPolicy Bypass -File $prSrc -Title 'fix: vulin-test' 2>&1 | Out-String)
    $prVCode = $LASTEXITCODE
    Assert-Equal 1 $prVCode 'open-pr stops (exit 1) on an unfilled VUL-IN scaffold'
    Assert-True ($prV -match 'VUL-IN') 'open-pr names VUL-IN in the pointer'
} finally {
    $ErrorActionPreference = $prevEap
    if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
    else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    Remove-Item -Path $pfDir -Recurse -Force -ErrorAction SilentlyContinue
    if ($vfDir) { Remove-Item -Path $vfDir -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host "native-command stderr pitfall -- centralized in Invoke-NativeCapture (#107, #114 item 1)" -ForegroundColor Cyan
# The push/gh calls used to die on 'remote:'/status stderr: under ErrorActionPreference=Stop,
# PS 5.1 promotes native stderr to a terminating NativeCommandError, before the exit-code check.
# That guard now lives in exactly one place -- the shared Invoke-NativeCapture helper.
# (a) Mechanism proof: the bare pattern breaks, the capture pattern does not -- on a real native
# command (cmd.exe echoes to stderr and gives exit 0). NB: .ps1 is pure ASCII, so no diacritics.
$naiveThrew = $false
try {
    $prevE = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
    & cmd /c 'echo remote: something 1>&2 & exit 0' 2>&1 | Out-Null
    $ErrorActionPreference = $prevE
} catch { $naiveThrew = $true; $ErrorActionPreference = 'Stop' }
Assert-True $naiveThrew 'bare pattern (native stderr under EAP=Stop) is indeed terminating'

$fixThrew = $false; $fixCode = $null
try {
    $prevE = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
    $prevInner = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $out = & cmd /c 'echo remote: something 1>&2 & exit 0' 2>&1
    $fixCode = $LASTEXITCODE
    $ErrorActionPreference = $prevInner
    $out | Out-Null
    $ErrorActionPreference = $prevE
} catch { $fixThrew = $true }
Assert-True (-not $fixThrew) 'capture pattern (EAP=Continue around the call) is NOT terminating'
Assert-Equal 0 $fixCode 'capture pattern reads the real exit code (0) of the command'

# (b) The helper behaves: run it FROM a caller scope that is EAP=Stop (exactly like the real
# scripts) against a native command that writes stderr AND returns exit 0. It must not throw, must
# capture the merged output, read the real exit code, and restore the caller's EAP afterwards. This
# also proves the FilePath/Arguments design (over a scriptblock): the EAP override only takes effect
# because the command runs inside the helper's own scope.
. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')
$prevEapNc = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
$ncThrew = $false; $ncResult = $null
try { $ncResult = Invoke-NativeCapture -FilePath 'cmd' -Arguments @('/c', 'echo remote: hi 1>&2 & exit 0') } catch { $ncThrew = $true }
Assert-True (-not $ncThrew) 'Invoke-NativeCapture does not throw on native stderr under caller EAP=Stop'
Assert-Equal 0 $ncResult.ExitCode 'Invoke-NativeCapture reads the real exit code (0)'
Assert-True ((($ncResult.Output | Out-String)) -match 'remote: hi') 'Invoke-NativeCapture captures merged stderr by default'
Assert-Equal 'Stop' $ErrorActionPreference 'Invoke-NativeCapture restores the caller EAP after running'
$ncNonZero = Invoke-NativeCapture -FilePath 'cmd' -Arguments @('/c', 'exit 3')
Assert-Equal 3 $ncNonZero.ExitCode 'Invoke-NativeCapture surfaces a non-zero exit code'
$ncDiscard = Invoke-NativeCapture -FilePath 'cmd' -Arguments @('/c', 'echo keep-stdout& echo drop-stderr 1>&2& exit 0') -DiscardStderr
$ncDiscardText = ($ncDiscard.Output | Out-String)
Assert-True ($ncDiscardText -match 'keep-stdout') '-DiscardStderr keeps stdout'
Assert-True (-not ($ncDiscardText -match 'drop-stderr')) '-DiscardStderr drops stderr (so it cannot pollute JSON)'
$ErrorActionPreference = $prevEapNc

# (c) Regression guard: the #107 protection must stay CENTRALIZED. The helper itself carries the
# EAP=Continue -> capture $LASTEXITCODE -> restore dance, and every native-command call site reaches
# for the helper rather than re-deriving a bare 'git push'/'gh' under EAP=Stop.
# (The live push against a real remote is exercised by the offline fixture below, not here.)
$ncLibSrc = ($pairs | Where-Object { $_.Name -eq 'native-capture-lib' }).SourcePath
$ncLibText = [System.IO.File]::ReadAllText($ncLibSrc)
Assert-True ($ncLibText -match "ErrorActionPreference = 'Continue'") 'native-capture-lib runs the command under EAP=Continue'
Assert-True ($ncLibText -match '\$code = \$LASTEXITCODE') 'native-capture-lib records $LASTEXITCODE right after the command'
Assert-True ($ncLibText -match '2>&1') 'native-capture-lib merges stderr by default (2>&1)'
Assert-True ($ncLibText -match '2>\$null') 'native-capture-lib discards stderr on -DiscardStderr (2>$null)'
Assert-True ($ncLibText -match '\$ErrorActionPreference = \$prevEap') 'native-capture-lib restores EAP (finally)'

$openPrSrc = ($pairs | Where-Object { $_.Name -eq 'open-pr' }).SourcePath
$openPrText = [System.IO.File]::ReadAllText($openPrSrc)
Assert-True ($openPrText -match "Invoke-NativeCapture -FilePath 'git' -Arguments @\('push'") 'open-pr runs the push via Invoke-NativeCapture'
Assert-True ($openPrText -match "Invoke-NativeCapture -FilePath 'gh' -Arguments \(@\('pr', 'create'") 'open-pr runs gh pr create via Invoke-NativeCapture'
Assert-True (-not ($openPrText -match "ErrorActionPreference = 'Continue'")) 'open-pr no longer re-derives the EAP dance inline (centralized in the helper)'

Write-Host "native-command stderr pitfall -- repo-wide guard over every call site" -ForegroundColor Cyan
# Why this is here on top of (c). The assertions above name call sites BY HAND -- open-pr's push,
# its gh pr create. They prove those two did not regress; they say nothing about the next one. A new
# script (or a new line in an existing one) can reach for a bare `git ... 2>$null` under EAP=Stop and
# every test above stays green, because no test is looking there. That is not hypothetical: the same
# class of bug was found four times in the smartwatchbanden consumer on July 29, 2026 -- once in the
# consumer's own ship-pr fork (a successful `git fetch` killed the run right before the fold step),
# and three more that nobody had noticed at all: `lint-brain` fell over the moment -Path pointed
# outside a git repo, `switch-account` died on `gh auth status` before it could switch anything, and
# `archive-and-remove-theme` plus `rename-specialist` made their own clear error messages
# unreachable. Each was a call site that no per-site assertion covered. A rule this repo enforces by
# convention is worth enforcing by scan.
#
# Two forms count as protected, and only these two:
#   1. the call sits inside a function that sets EAP=Continue first (what Invoke-NativeCapture does);
#   2. the statement sits inside a try/catch, so the terminating ErrorRecord is caught and the script
#      picks its own fallback deliberately.
# A file that never sets EAP=Stop is not at risk and is skipped.

$nativeExeAlternation = 'git|gh|npm|node|powershell|shopify'
# Single quotes on purpose: inside a double-quoted PowerShell string '\$null' is not an escape but a
# backslash followed by the VARIABLE $null, which interpolates to an empty string -- the pattern then
# quietly stops matching the very thing it is meant to catch.
$nativeRedirectRx = [regex]('\b(' + $nativeExeAlternation + ')\b[^\r\n]*\s2>(&1|\$null)')

function Get-UnprotectedNativeRedirects {
    <#
        Return one string per unprotected call site ("<relative path>:<line> (<scope>) -- <code>").
        $Files are scanned as text; the try-depth is tracked with a plain brace balance, which is
        coarse but ample for these scripts -- and the fixture below fails loudly if it ever becomes
        so lax that it stops finding a real violation.
    #>
    param([System.IO.FileInfo[]]$Files, [string]$BasePath)
    $found = New-Object System.Collections.Generic.List[string]
    foreach ($sf in $Files) {
        $lines = @(Get-Content -LiteralPath $sf.FullName -Encoding UTF8)
        $rel = $sf.FullName
        if ($BasePath -and $rel.StartsWith($BasePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $rel = $rel.Substring($BasePath.Length).TrimStart('\')
        }
        if (-not ($lines -match "^\s*\`$ErrorActionPreference\s*=\s*['`"]Stop['`"]")) { continue }

        $inBlockComment = $false
        $currentFn = ''
        $fnHasContinue = $false
        $balance = 0
        $tryStack = New-Object System.Collections.Generic.List[int]
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $trim = $line.Trim()

            # Skip block comments: the .DESCRIPTION of these very scripts DOCUMENTS the pitfall and
            # therefore contains a literal `2>$null` that is prose, not a call.
            if ($trim -like '<#*') { $inBlockComment = $true }
            if ($inBlockComment) {
                if ($trim -like '*#>*') { $inBlockComment = $false }
                continue
            }
            if ($trim.StartsWith('#')) { continue }

            $balanceBefore = $balance
            $hasTry = ($trim -match '\btry\s*\{')
            $balance += ([regex]::Matches($line, '\{').Count - [regex]::Matches($line, '\}').Count)

            if ($trim -match '^function\s+([\w-]+)') {
                $currentFn = $Matches[1]
                $fnHasContinue = $false
            } elseif ($trim -match "^\`$ErrorActionPreference\s*=\s*['`"]Continue['`"]") {
                if ($currentFn) { $fnHasContinue = $true }
            } elseif ($nativeRedirectRx.IsMatch($line)) {
                $inTry = ($tryStack.Count -gt 0) -or $hasTry
                if (-not (($currentFn -and $fnHasContinue) -or $inTry)) {
                    $scope = if ($currentFn) { "function '$currentFn'" } else { 'top-level' }
                    $found.Add("${rel}:$($i + 1) ($scope) -- $trim")
                }
            }

            if ($hasTry) { $tryStack.Add($balanceBefore) }
            while ($tryStack.Count -gt 0 -and $balance -le $tryStack[$tryStack.Count - 1]) {
                $tryStack.RemoveAt($tryStack.Count - 1)
            }
        }
    }
    return $found
}

# The scan covers the whole repo: the workshop's own scripts/ AND the plugin payload (hooks/,
# skills/, and every plugin's scripts/ mirror). The tests themselves are excluded -- they exercise
# the bare pattern on purpose, in (a) above.
$scanFiles = @(Get-ChildItem -Path $RepoRoot -Recurse -File -Filter '*.ps1' |
    Where-Object { $_.FullName -notmatch '\\(\.git|node_modules)\\' -and $_.DirectoryName -notlike '*\scripts\tests*' })
Assert-True ($scanFiles.Count -ge 10) "the scan sees a plausible number of scripts (found: $($scanFiles.Count))"

$unprotected = @(Get-UnprotectedNativeRedirects -Files $scanFiles -BasePath $RepoRoot)
Assert-Equal 0 $unprotected.Count 'no unprotected native stderr redirect anywhere in the repo'
foreach ($u in $unprotected) { Write-Host "         $u" -ForegroundColor Red }

# A guard that can no longer find anything is not a guard. Run the same scan over a fixture holding
# all four shapes side by side, so an over-eager try/catch exemption turns this red instead of
# silently exonerating the whole repo.
$guardFixture = Join-Path ([System.IO.Path]::GetTempPath()) "native-guard-fixture-$PID"
New-Item -ItemType Directory -Force -Path $guardFixture | Out-Null
try {
    $badSrc = @'
$ErrorActionPreference = 'Stop'
$x = git rev-parse --show-toplevel 2>$null
'@
    $goodFnSrc = @'
$ErrorActionPreference = 'Stop'
function Invoke-GitQuiet {
    $ErrorActionPreference = 'Continue'
    git @args 2>$null
}
'@
    $goodTrySrc = @'
$ErrorActionPreference = 'Stop'
try {
    $x = git rev-parse --show-toplevel 2>$null
} catch {
    $x = $null
}
'@
    $noStopSrc = @'
$y = git status --porcelain 2>$null
'@
    [System.IO.File]::WriteAllText((Join-Path $guardFixture 'bad.ps1'), $badSrc)
    [System.IO.File]::WriteAllText((Join-Path $guardFixture 'good-function.ps1'), $goodFnSrc)
    [System.IO.File]::WriteAllText((Join-Path $guardFixture 'good-try.ps1'), $goodTrySrc)
    [System.IO.File]::WriteAllText((Join-Path $guardFixture 'no-stop.ps1'), $noStopSrc)

    $fixtureHits = @(Get-UnprotectedNativeRedirects -Files @(Get-ChildItem -Path $guardFixture -File -Filter '*.ps1') -BasePath $guardFixture)
    $fixtureText = ($fixtureHits -join "`n")
    Assert-Equal 1 $fixtureHits.Count 'the scan finds exactly the one unprotected call site'
    Assert-True ($fixtureText -match 'bad\.ps1:2') 'the bare top-level call is the one reported'
    Assert-True (-not ($fixtureText -match 'good-function')) 'an EAP=Continue wrapper is exonerated'
    Assert-True (-not ($fixtureText -match 'good-try')) 'a try/catch is exonerated'
    Assert-True (-not ($fixtureText -match 'no-stop')) 'a script without EAP=Stop is not at risk'
} finally {
    Remove-Item -Path $guardFixture -Recurse -Force -ErrorAction SilentlyContinue
}

# Sweep guard (after the v1.12.0 breakage): the other release scripts that mutate native git/gh must
# not carry the #107 pitfall. cut-release.ps1 now routes its git mutations through the same shared
# Invoke-NativeCapture helper (#114 follow-up) instead of a bare 'git add' under a hand-rolled
# EAP=Continue block -- so the guard asserts it reaches for the helper and no longer re-derives the
# inline dance.
$cutSrc = Join-Path $RepoRoot 'scripts\release\cut-release.ps1'
$cutText = [System.IO.File]::ReadAllText($cutSrc)
Assert-True ($cutText -match "Invoke-NativeCapture -FilePath 'git' -Arguments @\('add', '-A'\)") 'cut-release runs git add via Invoke-NativeCapture'
Assert-True ($cutText -match "Invoke-NativeCapture -FilePath 'git' -Arguments @\('push', 'origin', 'main'\)") 'cut-release runs git push via Invoke-NativeCapture'
Assert-True (-not ($cutText -match "(?m)^\s*git add -A\s*$")) 'cut-release no longer runs a bare inline git add'
Assert-True (-not ($cutText -match "ErrorActionPreference = 'Continue'")) 'cut-release no longer re-derives the EAP dance inline (centralized in the helper)'

$foldSrc = ($pairs | Where-Object { $_.Name -eq 'fold-changelog-entry' }).SourcePath
$foldText = [System.IO.File]::ReadAllText($foldSrc)
Assert-True ($foldText -match "Invoke-NativeCapture -FilePath 'gh' -Arguments @\('pr', 'list'") 'fold runs gh pr list via Invoke-NativeCapture'
Assert-True ($foldText -match '-DiscardStderr') 'fold discards gh pr list stderr (-DiscardStderr) so it cannot pollute the JSON'
Assert-True (-not ($foldText -match "gh pr list.*2>\`$null")) 'fold no longer re-derives the inline 2>$null discard (centralized in the helper)'
# #103 (Victor #4): gh pr list supplies 'files' just as well as gh pr view -- the second gh
# roundtrip has been dropped. Regression guard: the --json list carries 'files' along (now as an
# argument-array element), and a real 'gh pr view' call (as opposed to an explanatory code comment
# naming the old approach) has not returned.
Assert-True ($foldText -match "'--json', 'number,url,files'") 'fold already requests files in the gh pr list call'
Assert-True (-not ($foldText -match '(?m)^\s*\$\w+\s*=\s*gh pr view')) 'fold no longer runs a separate gh pr view call (merged, #103)'

Write-Host "open-pr + fold-changelog-entry: repo-config-driven overrides (#101)" -ForegroundColor Cyan
# Shared fixture: a fake 'gh' on PATH (Sylvester's pattern -- a fake gh.cmd + a local bare git
# remote), so both the open-pr and fold-RepoRoot scenarios below run for real (real git repo,
# real script invocation) but fully offline and deterministically -- no dependency on a real `gh`
# being installed/authenticated on the machine running the suite.
$fakeBin = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-fakegh-$PID")
$prArgsCapture = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-gh-args-$PID.txt")
$prBodyCapture = Join-Path ([System.IO.Path]::GetTempPath()) ("shared-scripts-gh-body-$PID.md")
$prFixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("openpr-fixture-$PID")
$prBareRemote  = Join-Path ([System.IO.Path]::GetTempPath()) ("openpr-remote-$PID.git")
$foldTarget  = Join-Path ([System.IO.Path]::GetTempPath()) ("fold-reporoot-target-$PID")
$foldDecoy   = Join-Path ([System.IO.Path]::GetTempPath()) ("fold-reporoot-decoy-$PID")
$foldDefault = Join-Path ([System.IO.Path]::GetTempPath()) ("fold-reporoot-default-$PID")
$prBranch = 'feat/openpr-101-test'
$foldBranch = 'chore/fold-reporoot-test'
$Utf8NoBomTest = New-Object System.Text.UTF8Encoding $false
$prevPath1 = $env:PATH
$prevPd = $env:CLAUDE_PROJECT_DIR
$prevLoc = (Get-Location).Path
$prevEapShared = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'  # native git/gh calls below -- #107 pitfall guard

    # --- Fake gh on PATH ---
    # 'pr create' captures its full argument list + a copy of the --body-file content (read BEFORE
    # open-pr.ps1's own finally removes the temp file) and prints a fake PR URL. 'pr list' (used by
    # fold, not by open-pr) returns an empty JSON array, i.e. "no PR found" -- both exit 0.
    New-Item -ItemType Directory -Path $fakeBin -Force | Out-Null
    $ghImpl = @'
if ($args -contains 'issue' -and $args -contains 'list') {
    # The resolves gate asks which issues are open. GH_OPEN_ISSUES lets a scenario decide; unset
    # means "no open issues", which is what every pre-gate scenario expects.
    # GH_FAIL_ISSUE_LIST simulates an unreachable/erroring gh for the degraded-path scenario.
    if ($env:GH_FAIL_ISSUE_LIST) { [Console]::Error.WriteLine('fake gh: issue list unavailable'); exit 1 }
    if ($env:GH_OPEN_ISSUES) { Write-Output $env:GH_OPEN_ISSUES } else { Write-Output '[]' }
    exit 0
}
if ($args -contains 'create') {
    if ($env:GH_ARGS_CAPTURE) {
        [System.IO.File]::WriteAllText($env:GH_ARGS_CAPTURE, ($args -join "`n"), [System.Text.Encoding]::UTF8)
    }
    $bfIdx = [array]::IndexOf($args, '--body-file')
    if ($bfIdx -ge 0 -and $env:GH_BODY_CAPTURE) {
        $bodyPath = $args[$bfIdx + 1]
        if (Test-Path -LiteralPath $bodyPath) {
            Copy-Item -LiteralPath $bodyPath -Destination $env:GH_BODY_CAPTURE -Force
        }
    }
    Write-Output 'https://github.com/fake/repo/pull/999'
    exit 0
} elseif ($args -contains 'list') {
    Write-Output '[]'
    exit 0
} else {
    exit 1
}
'@
    [System.IO.File]::WriteAllText((Join-Path $fakeBin 'gh-impl.ps1'), $ghImpl, $Utf8NoBomTest)
    $ghCmd = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0gh-impl.ps1`" %*`r`nexit /b %ERRORLEVEL%`r`n"
    [System.IO.File]::WriteAllText((Join-Path $fakeBin 'gh.cmd'), $ghCmd, $Utf8NoBomTest)
    $env:PATH = "$fakeBin;$env:PATH"

    Write-Host "  open-pr: default path (regression) vs. override path" -ForegroundColor DarkCyan
    # A real (throwaway) git repo + a local bare remote, so open-pr's own 'git push -u origin
    # <branch>' succeeds without touching a real remote.
    New-Item -ItemType Directory -Path $prBareRemote -Force | Out-Null
    git init --bare --quiet $prBareRemote 2>&1 | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $prFixtureRoot '.github') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $prFixtureRoot 'scripts\lib') -Force | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'scripts\lib\branch-info.ps1') -Destination (Join-Path $prFixtureRoot 'scripts\lib\branch-info.ps1') -Force
    $prEntryContent = @'
### Open-PR 101 test - Feat - 2026-07-21

This is the test description text.
'@
    [System.IO.File]::WriteAllText((Join-Path $prFixtureRoot 'feat-openpr-101-test.md'), $prEntryContent, $Utf8NoBomTest)

    Set-Location $prFixtureRoot
    git init --quiet 2>&1 | Out-Null
    git config user.email 'tycho@test.local' 2>&1 | Out-Null
    git config user.name 'Tycho Test' 2>&1 | Out-Null
    git remote add origin $prBareRemote 2>&1 | Out-Null
    git add -A 2>&1 | Out-Null
    git commit --quiet -m 'initial' 2>&1 | Out-Null
    git branch -M main 2>&1 | Out-Null
    git push --quiet -u origin main 2>&1 | Out-Null
    git checkout --quiet -b $prBranch 2>&1 | Out-Null

    $env:CLAUDE_PROJECT_DIR = $prFixtureRoot
    $env:GH_ARGS_CAPTURE = $prArgsCapture
    $env:GH_BODY_CAPTURE = $prBodyCapture

    # Scenario A: default path -- no repo-config overrides defined (today's behavior, unchanged).
    Copy-Item -Path (Join-Path $RepoRoot 'scripts\repo-config.ps1') -Destination (Join-Path $prFixtureRoot 'scripts\repo-config.ps1') -Force
    Copy-Item -Path (Join-Path $RepoRoot '.github\pull_request_template.md') -Destination (Join-Path $prFixtureRoot '.github\pull_request_template.md') -Force
    Remove-Item -Path $prArgsCapture, $prBodyCapture -Force -ErrorAction SilentlyContinue
    $codeA = $null
    (& powershell -NoProfile -ExecutionPolicy Bypass -File $openPrSrc -Title 'feat-openpr-101-test' -SkipLint -SkipTests 2>&1 | Out-String) | Out-Null
    $codeA = $LASTEXITCODE
    Assert-Equal 0 $codeA 'default path: open-pr exits 0'
    $argsA = if (Test-Path $prArgsCapture) { Get-Content -Path $prArgsCapture -Raw } else { '' }
    $bodyA = if (Test-Path $prBodyCapture) { Get-Content -Path $prBodyCapture -Raw } else { '' }
    Assert-True ($argsA -ne '') 'default path: fake gh pr create was invoked'
    Assert-True ($argsA -notmatch '--assignee') 'default path: no --assignee passed (no repo-config override)'
    Assert-True ($argsA -notmatch '--milestone') 'default path: no --milestone passed (no repo-config override)'
    Assert-True ($bodyA -match 'This is the test description text\.') 'default path: description filled in from the changelog entry'
    Assert-True ($bodyA -notmatch '<!-- Short description of what changes and why') 'default path: description placeholder was replaced'
    Assert-True ($bodyA -match '- \[x\] `feat/`') 'default path: type-of-change box ticked'
    Assert-True ($bodyA -match '- \[x\] Changelog entry file created') 'default path: changelog-entry checklist item ticked'
    Assert-True ($bodyA -match '- \[x\] Requested by Dave') 'default path: approval checklist item ticked (default pattern)'

    # Scenario B: override path -- repo-config defines all four optional #101 functions.
    $rcOverride = @'
$script:RepoName = 'DaveKJohn/claude-code-specialists'
function Get-RepoName { return $script:RepoName }
function Get-RepoBlobUrl { return "https://github.com/$($script:RepoName)/blob/main/" }
$script:LintScript = 'scripts\lint\check-plugin-integrity.ps1'
function Get-LintScript { return $script:LintScript }
function Get-PrDescriptionPlaceholder { return @('<!-- CUSTOM PLACEHOLDER TEXT -->') }
function Get-PrApprovalPattern { return '^- \[ \] Custom approval line' }
function Get-PrAssignee { return 'octocat' }
function Get-PrMilestone { return 'v9.9.9' }
'@
    [System.IO.File]::WriteAllText((Join-Path $prFixtureRoot 'scripts\repo-config.ps1'), $rcOverride, $Utf8NoBomTest)
    $templateOverride = @'
## What does this change do?
<!-- CUSTOM PLACEHOLDER TEXT -->

## Type of change
- [ ] `feat/` custom marker

## Checklist
- [ ] Changelog entry file created (`<branch-name>.md` in the repo root)

## Explicit approval
- [ ] Custom approval line here
'@
    [System.IO.File]::WriteAllText((Join-Path $prFixtureRoot '.github\pull_request_template.md'), $templateOverride, $Utf8NoBomTest)
    Remove-Item -Path $prArgsCapture, $prBodyCapture -Force -ErrorAction SilentlyContinue
    (& powershell -NoProfile -ExecutionPolicy Bypass -File $openPrSrc -Title 'feat-openpr-101-test' -SkipLint -SkipTests 2>&1 | Out-String) | Out-Null
    $codeB = $LASTEXITCODE
    Assert-Equal 0 $codeB 'override path: open-pr exits 0'
    $argsB = if (Test-Path $prArgsCapture) { Get-Content -Path $prArgsCapture -Raw } else { '' }
    $bodyB = if (Test-Path $prBodyCapture) { Get-Content -Path $prBodyCapture -Raw } else { '' }
    Assert-True ($argsB -match '--assignee') 'override path: --assignee passed through to gh pr create'
    Assert-True ($argsB -match 'octocat') 'override path: assignee value from Get-PrAssignee used'
    Assert-True ($argsB -match '--milestone') 'override path: --milestone passed through to gh pr create'
    Assert-True ($argsB -match 'v9\.9\.9') 'override path: milestone value from Get-PrMilestone used'
    Assert-True ($bodyB -notmatch '<!-- CUSTOM PLACEHOLDER TEXT -->') 'override path: custom description placeholder was replaced (override function actually used)'
    Assert-True ($bodyB -match 'This is the test description text\.') 'override path: description still filled in from the changelog entry'
    Assert-True ($bodyB -match '- \[x\] Custom approval line') 'override path: custom approval pattern (Get-PrApprovalPattern) ticked the custom checklist line'

    # --- Scenario C: the resolves gate, wired into open-pr (not just its decision table) ----------
    # pr-issues.tests.ps1 asserts the table; this asserts the WIRING -- that the gate actually runs,
    # blocks BEFORE the push/gh call, and that the closing keyword reaches the PR body. The gate is
    # the answer to PRs #341-#343, where eight repaired findings stayed open after the merge.
    Write-Host "  open-pr: the resolves gate" -ForegroundColor DarkCyan
    # Back to the default repo-config + template, so this scenario is not read through scenario B's
    # custom markers.
    Copy-Item -Path (Join-Path $RepoRoot 'scripts\repo-config.ps1') -Destination (Join-Path $prFixtureRoot 'scripts\repo-config.ps1') -Force
    Copy-Item -Path (Join-Path $RepoRoot '.github\pull_request_template.md') -Destination (Join-Path $prFixtureRoot '.github\pull_request_template.md') -Force
    $gateEntry = @'
### Open-PR 101 test - Feat - 2026-07-21

This is the test description text. It repairs the thing reported in #332.
'@
    [System.IO.File]::WriteAllText((Join-Path $prFixtureRoot 'feat-openpr-101-test.md'), $gateEntry, $Utf8NoBomTest)
    $env:GH_OPEN_ISSUES = '[{"number":332},{"number":340}]'

    # C1: an open issue is mentioned and no decision is declared -> BLOCKED, and nothing reached gh.
    Remove-Item -Path $prArgsCapture, $prBodyCapture -Force -ErrorAction SilentlyContinue
    $gateOutRaw = (& powershell -NoProfile -ExecutionPolicy Bypass -File $openPrSrc -Title 'feat-openpr-101-test' -SkipLint -SkipTests 2>&1 | Out-String)
    $gateCode = $LASTEXITCODE
    # Whitespace-normalized before matching. The child renders Write-Error at ITS OWN console buffer
    # width, so with this repo's path length the wrap can land mid-phrase -- 'resolves\n gate:' -- and
    # a literal substring assert then fails on one machine and passes on another. Exactly the wrap
    # hazard this suite already documents for the #86 pre-flight pointers a few scenarios up; found
    # here by a copy-edit pass that reproduced it consistently at width 120 while it passed at
    # another width.
    $gateOut = ($gateOutRaw -replace '\s+', ' ')
    Assert-Equal 1 $gateCode 'resolves gate: open-pr exits 1 when an open issue is mentioned without a decision'
    # The gate must have actually CHECKED. Without this, the degraded path ("cannot check, not
    # blocking") satisfies every other assert in this scenario while the gate never blocks -- which
    # is exactly what a ConvertFrom-Json bug did here: 5.1 hands a parsed JSON array to the pipeline
    # as one object, the [int] cast threw, and the failure was swallowed as "cannot check".
    Assert-True ($gateOut -notmatch 'cannot check') 'resolves gate: it really checked (did not fall back to the degraded path)'
    Assert-True ($gateOut -match 'resolves gate') 'resolves gate: the error names the gate'
    Assert-True ($gateOut -match '#332') 'resolves gate: the error names the blocking issue'
    Assert-True (-not (Test-Path $prArgsCapture)) 'resolves gate: no PR was created while blocked'

    # C2: -NoResolves is the deliberate way past it, and it closes nothing.
    Remove-Item -Path $prArgsCapture, $prBodyCapture -Force -ErrorAction SilentlyContinue
    (& powershell -NoProfile -ExecutionPolicy Bypass -File $openPrSrc -Title 'feat-openpr-101-test' -SkipLint -SkipTests -NoResolves 2>&1 | Out-String) | Out-Null
    Assert-Equal 0 $LASTEXITCODE 'resolves gate: -NoResolves lets the PR through'
    $bodyNo = if (Test-Path $prBodyCapture) { Get-Content -Path $prBodyCapture -Raw } else { '' }
    Assert-True ($bodyNo -ne '') 'resolves gate: -NoResolves still creates the PR'
    Assert-True ($bodyNo -notmatch 'Closes #') 'resolves gate: -NoResolves writes no closing keyword'

    # C3: -Resolves writes one closing line per issue into the body that reaches gh.
    Remove-Item -Path $prArgsCapture, $prBodyCapture -Force -ErrorAction SilentlyContinue
    # Passed exactly as ship-pr.ps1 passes it: one string, over `powershell -File`. This IS the hop
    # where an [int[]] parameter silently became 332340 (comma read as a thousands separator), so the
    # assert below that BOTH numbers come out is the regression guard for that trap.
    (& powershell -NoProfile -ExecutionPolicy Bypass -File $openPrSrc -Title 'feat-openpr-101-test' -SkipLint -SkipTests -Resolves '332,340' 2>&1 | Out-String) | Out-Null
    Assert-Equal 0 $LASTEXITCODE 'resolves gate: -Resolves lets the PR through'
    $bodyRes = if (Test-Path $prBodyCapture) { Get-Content -Path $prBodyCapture -Raw } else { '' }
    Assert-True ($bodyRes -match '(?m)^Closes #332$') 'resolves gate: the body closes #332'
    Assert-True ($bodyRes -match '(?m)^Closes #340$') 'resolves gate: the body closes #340'
    Assert-True ($bodyRes -match 'This is the test description text') 'resolves gate: the description survives alongside the closing block'
    Assert-True ($bodyRes -notmatch '332340') 'resolves gate: the comma list did NOT collapse into one number (the -File thousands-separator trap)'

    # C4: the cry-wolf guard, end to end. An entry that only cites PRs must NOT block -- a gate that
    # fires on every branch gets routinely bypassed, which is how it would silently stop working.
    $prOnlyEntry = @'
### Open-PR 101 test - Feat - 2026-07-21

This follows the shape PRs #341-#343 established, see https://github.com/o/r/pull/343.
'@
    [System.IO.File]::WriteAllText((Join-Path $prFixtureRoot 'feat-openpr-101-test.md'), $prOnlyEntry, $Utf8NoBomTest)
    Remove-Item -Path $prArgsCapture, $prBodyCapture -Force -ErrorAction SilentlyContinue
    (& powershell -NoProfile -ExecutionPolicy Bypass -File $openPrSrc -Title 'feat-openpr-101-test' -SkipLint -SkipTests 2>&1 | Out-String) | Out-Null
    Assert-Equal 0 $LASTEXITCODE 'resolves gate: an entry citing only PRs does not block'
    Assert-True (Test-Path $prArgsCapture) 'resolves gate: that PR was created'

    # C5: an unreachable gh must WARN, not wedge -- the deliberate escape hatch. GH_FAIL_ISSUE_LIST
    # makes the issue query fail while the rest of the fake gh keeps working.
    [System.IO.File]::WriteAllText((Join-Path $prFixtureRoot 'feat-openpr-101-test.md'), $gateEntry, $Utf8NoBomTest)
    $env:GH_FAIL_ISSUE_LIST = '1'
    Remove-Item -Path $prArgsCapture, $prBodyCapture -Force -ErrorAction SilentlyContinue
    # Same whitespace normalization as C1, for the same console-width wrap reason.
    $degradedOut = ((& powershell -NoProfile -ExecutionPolicy Bypass -File $openPrSrc -Title 'feat-openpr-101-test' -SkipLint -SkipTests 2>&1 | Out-String) -replace '\s+', ' ')
    Assert-Equal 0 $LASTEXITCODE 'resolves gate: a failing issue query does not block the PR'
    Assert-True ($degradedOut -match 'resolves gate cannot check') 'resolves gate: it says out loud that it could not check'
    Remove-Item Env:\GH_FAIL_ISSUE_LIST -ErrorAction SilentlyContinue
    Remove-Item Env:\GH_OPEN_ISSUES -ErrorAction SilentlyContinue
    [System.IO.File]::WriteAllText((Join-Path $prFixtureRoot 'feat-openpr-101-test.md'), $prEntryContent, $Utf8NoBomTest)

    Write-Host "  fold-changelog-entry: -RepoRoot override vs. default path" -ForegroundColor DarkCyan
    $changelogSkeleton = @'
# Changelog

## Pull Requests

## Releases
'@
    $rcMinimal = @'
$script:RepoName = 'DaveKJohn/claude-code-specialists'
function Get-RepoName { return $script:RepoName }
'@
    $targetEntryContent = @'
### Fold RepoRoot Test - Chore - 2026-07-21

Testing the -RepoRoot parameter.
'@
    $decoyChangelog = @'
# Changelog

## Pull Requests
DECOY-MARKER-MUST-STAY

## Releases
'@
    $decoyEntryContent = @'
### DECOY entry - must not be touched - Chore - 2026-07-21

Decoy body.
'@
    $defaultEntryContent = @'
### Fold Default Path Test - Chore - 2026-07-21

Testing the default (no -RepoRoot) path.
'@

    # Scenario C: -RepoRoot wins over the ambient CLAUDE_PROJECT_DIR (a decoy tree) -- the decoy
    # tree's CHANGELOG.md and entry file must come out byte-identical, unfolded/unremoved.
    New-Item -ItemType Directory -Path (Join-Path $foldTarget 'scripts') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $foldTarget 'CHANGELOG.md'), $changelogSkeleton, $Utf8NoBomTest)
    [System.IO.File]::WriteAllText((Join-Path $foldTarget 'scripts\repo-config.ps1'), $rcMinimal, $Utf8NoBomTest)
    [System.IO.File]::WriteAllText((Join-Path $foldTarget 'chore-fold-reporoot-test.md'), $targetEntryContent, $Utf8NoBomTest)

    New-Item -ItemType Directory -Path (Join-Path $foldDecoy 'scripts') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $foldDecoy 'CHANGELOG.md'), $decoyChangelog, $Utf8NoBomTest)
    [System.IO.File]::WriteAllText((Join-Path $foldDecoy 'scripts\repo-config.ps1'), $rcMinimal, $Utf8NoBomTest)
    [System.IO.File]::WriteAllText((Join-Path $foldDecoy 'chore-fold-reporoot-test.md'), $decoyEntryContent, $Utf8NoBomTest)

    $env:CLAUDE_PROJECT_DIR = $foldDecoy  # ambient context -- -RepoRoot must win over this
    (& powershell -NoProfile -ExecutionPolicy Bypass -File $foldSrc -Branch $foldBranch -RepoRoot $foldTarget 2>&1 | Out-String) | Out-Null
    $rrCode = $LASTEXITCODE
    Assert-Equal 0 $rrCode '-RepoRoot: fold exits 0'
    $targetChangelogAfter = Get-Content -Path (Join-Path $foldTarget 'CHANGELOG.md') -Raw
    Assert-True ($targetChangelogAfter -match 'Fold RepoRoot Test') "-RepoRoot: the TARGET tree's CHANGELOG.md received the folded entry"
    Assert-True (-not (Test-Path (Join-Path $foldTarget 'chore-fold-reporoot-test.md'))) '-RepoRoot: the entry file was removed from the TARGET tree'
    $decoyChangelogAfter = Get-Content -Path (Join-Path $foldDecoy 'CHANGELOG.md') -Raw
    Assert-Equal $decoyChangelog $decoyChangelogAfter "-RepoRoot: the DECOY (ambient CLAUDE_PROJECT_DIR) tree's CHANGELOG.md is untouched"
    Assert-True (Test-Path (Join-Path $foldDecoy 'chore-fold-reporoot-test.md')) "-RepoRoot: the DECOY tree's entry file still exists (not removed)"
    $decoyEntryAfter = Get-Content -Path (Join-Path $foldDecoy 'chore-fold-reporoot-test.md') -Raw
    Assert-Equal $decoyEntryContent $decoyEntryAfter "-RepoRoot: the DECOY tree's entry file content is unchanged"

    # Scenario D: default path (regression) -- no -RepoRoot, falls back to CLAUDE_PROJECT_DIR
    # exactly like before #101.
    New-Item -ItemType Directory -Path (Join-Path $foldDefault 'scripts') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $foldDefault 'CHANGELOG.md'), $changelogSkeleton, $Utf8NoBomTest)
    [System.IO.File]::WriteAllText((Join-Path $foldDefault 'scripts\repo-config.ps1'), $rcMinimal, $Utf8NoBomTest)
    [System.IO.File]::WriteAllText((Join-Path $foldDefault 'chore-fold-reporoot-test.md'), $defaultEntryContent, $Utf8NoBomTest)
    $env:CLAUDE_PROJECT_DIR = $foldDefault
    (& powershell -NoProfile -ExecutionPolicy Bypass -File $foldSrc -Branch $foldBranch 2>&1 | Out-String) | Out-Null
    $defCode = $LASTEXITCODE
    Assert-Equal 0 $defCode 'default path (no -RepoRoot): fold exits 0'
    $defChangelogAfter = Get-Content -Path (Join-Path $foldDefault 'CHANGELOG.md') -Raw
    Assert-True ($defChangelogAfter -match 'Fold Default Path Test') 'default path (no -RepoRoot): CLAUDE_PROJECT_DIR tree received the folded entry'
    Assert-True (-not (Test-Path (Join-Path $foldDefault 'chore-fold-reporoot-test.md'))) 'default path (no -RepoRoot): entry file removed'
} finally {
    $ErrorActionPreference = $prevEapShared
    Set-Location -Path $prevLoc
    if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue } else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    Remove-Item Env:\GH_ARGS_CAPTURE -ErrorAction SilentlyContinue
    Remove-Item Env:\GH_BODY_CAPTURE -ErrorAction SilentlyContinue
    $env:PATH = $prevPath1
    Remove-Item -Path $fakeBin -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $prArgsCapture, $prBodyCapture -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $prFixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $prBareRemote -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $foldTarget -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $foldDecoy -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $foldDefault -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
