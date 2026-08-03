<#
.SYNOPSIS
    Shared helper to run a native command safely and capture its output + exit code (single source
    of truth, issue #114 item 1).

.DESCRIPTION
    Dot-source this file from a sibling of the script that needs it, relative to $PSScriptRoot (NOT
    $repoRoot) -- like scripts/lib/check-report-lib.ps1 and unlike scripts/repo-config.ps1 /
    scripts/lib/branch-info.ps1, this lib is not repo-owned, so it does not need a consumer-side
    scaffold. It travels as part of the SAME plugin/mirror payload as its callers (registered in
    scripts/lib/shared-scripts-lib.ps1), so a $PSScriptRoot-relative path resolves correctly whether
    the caller runs from the workshop root, a consumer's plugin cache, or the plugin mirror tree:

        . (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')   -- from scripts/release/*

    Why this exists (the #96/#97/#107 lesson, in one place):
      Windows PowerShell 5.1 promotes a native command's stderr lines to a TERMINATING
      NativeCommandError when $ErrorActionPreference is 'Stop'. A command that writes progress to
      stderr -- git push's 'remote:' lines, gh's status/URL lines -- would then kill the script
      BEFORE its $LASTEXITCODE could be judged, even when the command itself returned exit 0. The
      lesson: never rely on stderr-as-error, always on $LASTEXITCODE. This helper centralizes the
      save-EAP -> Continue -> run -> record $LASTEXITCODE -> restore dance so that reasoning lives
      in exactly one tested place instead of being re-derived at every call site.

    The native command runs INSIDE this function's own scope, where EAP is set to 'Continue'. That
    is deliberate: a scriptblock passed in by the caller would keep the caller's script scope (where
    EAP is usually 'Stop') as its resolution scope, so an EAP override here would not reach it --
    passing FilePath/Arguments and invoking here is what makes the guard actually take effect.

    Usage:
        $r = Invoke-NativeCapture -FilePath 'git' -Arguments @('push', '-u', 'origin', $branch)
        $r.Output | ForEach-Object { Write-Host $_ }
        if ($r.ExitCode -ne 0) { Write-Error 'git push failed.'; exit 1 }

        # -DiscardStderr keeps stderr out of the captured output (e.g. so it cannot pollute JSON):
        $r = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--json', 'number') -DiscardStderr

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Invoke-NativeCapture {
    <#
        Run $FilePath with $Arguments under $ErrorActionPreference = 'Continue' and return a
        pscustomobject with:
          - Output   : the command's output. By default stderr is merged in (2>&1) so a caller can
                       echo full progress; with -DiscardStderr stderr is dropped (2>$null) so it
                       cannot pollute a machine-readable stdout (e.g. gh --json).
          - ExitCode : $LASTEXITCODE recorded immediately after the command ran.
        EAP is always restored (finally), whether the command succeeds, fails, or throws.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [switch]$DiscardStderr
    )

    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        if ($DiscardStderr) {
            $output = & $FilePath @Arguments 2>$null
        } else {
            $output = & $FilePath @Arguments 2>&1
        }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevEap
    }

    return [pscustomobject]@{ Output = $output; ExitCode = $code }
}
