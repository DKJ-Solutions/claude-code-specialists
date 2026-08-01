<#
.SYNOPSIS
    Repairs double-encoded characters (mojibake) in text files.

.DESCRIPTION
    Replaces known mojibake sequences -- UTF-8 that was once read as Windows-1252 and then saved as
    UTF-8 again -- with the correct character. Targeted replacements only: correctly encoded characters
    (em dash, arrow, accents) are left alone. Idempotent.

    HOW THE DAMAGE HAPPENS, because knowing this is what prevents it. Windows PowerShell 5.1's
    Get-Content reads a BOM-less UTF-8 file as ANSI unless told otherwise, so a middot (U+00B7, bytes
    C2 B7) comes back as two characters. Writing that back as UTF-8 stores the mangled pair. One
    Get-Content-plus-write round trip is enough, and nothing errors -- the file stays valid UTF-8, it
    just says something else.

    Measured here on August 1, 2026: demoting four headings in CHANGELOG.md with
    Get-Content + WriteAllLines mangled 35 separators, and because the separator IS the field delimiter
    in an entry heading, cut-release.ps1 could no longer read the entry TYPE. Eleven entries fell into a
    catch-all category instead of Features/Fixes/Documentation. Caught by inspecting the notes before
    pushing (-NoPush), which is exactly what that flag is for.

    Prevention, in order of preference: (1) use the Read/Edit tooling or
    [System.IO.File]::ReadAllText(<path>, [Text.Encoding]::UTF8) -- never bare Get-Content -- when a
    file may hold non-ASCII; (2) let the lint gate catch it (check 14 in
    scripts/lint/check-plugin-integrity.ps1); (3) run this script.

    THIS SOURCE IS PURE ASCII, via [char]0x.. codepoints, so the repair tool cannot itself be mangled
    by the very round trip it repairs. That is not decoration -- a mojibake table written as literal
    characters corrupts on the first careless edit and then silently repairs nothing.

    WHY THE TABLE REPEATS TO A FIXPOINT. Text can have been through the mangle twice; the middot from a
    changelog heading then comes out as four characters rather than two. A single pass peels one layer
    and leaves a remainder that matches no rule -- which is what cost life-hub a manual fix in PR #106
    at its v2.1.0. Two things solve it: the peel rule for the outer layer (0xC3,0x201A -> 0xC2) and
    repeating the whole table until nothing changes. Termination is guaranteed: every replacement makes
    the text strictly shorter.

    A UTF-8 BOM on the file is preserved; a file without one does not gain one.

    Ported from life-hub (scripts/maintenance/fix-mojibake.ps1), which took it from smartwatchbanden.
    This is the third repo to need it, which is the argument for the gate beside it rather than for
    remembering to run it.

.PARAMETER Path
    Files to repair. Without it: the root docs that carry the separator (CHANGELOG.md, README.md,
    CLAUDE.md, releases/README.md) plus every per-plugin CHANGELOG.md and RELEASE.md.

.PARAMETER Check
    Report only, change nothing, exit 1 if any file would change -- for a gate or a dry run.

.EXAMPLE
    ./scripts/maintenance/fix-mojibake.ps1

.EXAMPLE
    ./scripts/maintenance/fix-mojibake.ps1 -Check
#>
param(
    [string[]]$Path,
    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

if (-not $Path -or @($Path).Count -eq 0) {
    $Path = @(
        (Join-Path $repoRoot 'CHANGELOG.md')
        (Join-Path $repoRoot 'README.md')
        (Join-Path $repoRoot 'CLAUDE.md')
        (Join-Path $repoRoot 'releases\README.md')
    )
    # Every plugin's own CHANGELOG.md and RELEASE.md: cut-release.ps1 writes entry text into both, so
    # damage in the root changelog propagates there on the next release.
    $pluginRoot = Join-Path $repoRoot 'claude-code-plugins'
    if (Test-Path -LiteralPath $pluginRoot) {
        $Path += @(Get-ChildItem -LiteralPath $pluginRoot -Recurse -File -Include 'CHANGELOG.md', 'RELEASE.md' |
            Select-Object -ExpandProperty FullName)
    }
    $Path = @($Path | Where-Object { Test-Path -LiteralPath $_ })
}

# Build a string from codepoints, so this source stays ASCII-only.
function C([int[]]$cp) { -join ($cp | ForEach-Object { [char]$_ }) }

# Mojibake sequence -> correct character.
$map = [ordered]@{
    (C 0xF0, 0x178, 0x2019, 0xA1) = [System.Char]::ConvertFromUtf32(0x1F4A1)  # bulb emoji
    (C 0xE2, 0x20AC, 0x201D)      = (C 0x2014)  # em dash
    (C 0xE2, 0x20AC, 0x201C)      = (C 0x2013)  # en dash
    (C 0xE2, 0x20AC, 0xA6)        = (C 0x2026)  # ellipsis
    (C 0xE2, 0x2020, 0x2019)      = (C 0x2192)  # arrow right
    (C 0xE2, 0x2020, 0x90)        = (C 0x2190)  # arrow left
    (C 0xE2, 0x2020, 0x201D)      = (C 0x2194)  # arrow left-right
    (C 0xC3, 0xA9)                = (C 0xE9)    # e acute
    (C 0xC3, 0xB3)                = (C 0xF3)    # o acute
    (C 0xC3, 0xAB)                = (C 0xEB)    # e diaeresis
    (C 0xC3, 0xA1)                = (C 0xE1)    # a acute
    (C 0xC3, 0xAD)                = (C 0xED)    # i acute
    (C 0xC3, 0xB6)                = (C 0xF6)    # o diaeresis
    (C 0xC3, 0x2030)              = (C 0xC9)    # E acute
    (C 0xC2, 0xA7)                = (C 0xA7)    # section sign
    (C 0xC2, 0xB7)                = (C 0xB7)    # MIDDOT -- the field separator in an entry heading
    (C 0xC3, 0x201A)              = (C 0xC2)    # outer layer of a doubly-encoded 0xC2 sequence
}

function Repair-Text([string]$Text) {
    <# The table to a fixpoint. Returns the repaired text and the replacement count. #>
    $n = 0
    $changed = $true
    while ($changed) {
        $changed = $false
        foreach ($k in $map.Keys) {
            $v = $map[$k]
            $c = ($Text.Length - $Text.Replace($k, '').Length) / $k.Length
            if ($c -gt 0) {
                $Text = $Text.Replace($k, $v)
                $n += [int]$c
                $changed = $true
            }
        }
    }
    return [pscustomobject]@{ Text = $Text; Count = $n }
}

$total = 0
$dirty = 0

foreach ($file in $Path) {
    if (-not (Test-Path -LiteralPath $file)) { Write-Error "File not found: $file"; exit 1 }
    # Separator-insensitive: git rev-parse --show-toplevel returns forward slashes while the paths above
    # are built with Join-Path (backslashes), so a naive StartsWith never matched and every finding named
    # an absolute path.
    $rel = $file
    $rootNorm = ($repoRoot -replace '/', '\').TrimEnd('\')
    $fileNorm = $file -replace '/', '\'
    if ($fileNorm.StartsWith($rootNorm, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $fileNorm.Substring($rootNorm.Length).TrimStart('\')
    }

    # Respect the file's own BOM (this repo is largely BOM-less).
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $encOut = New-Object System.Text.UTF8Encoding $hasBom

    $before = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
    $r = Repair-Text -Text $before

    if ($r.Text -ne $before) {
        $dirty++
        $total += $r.Count
        if ($Check) {
            Write-Host "  [mojibake] ${rel}: $($r.Count) double-encoded sequence(s)" -ForegroundColor Red
        } else {
            [System.IO.File]::WriteAllText($file, $r.Text, $encOut)
            Write-Host "  repaired: $rel ($($r.Count) replacement(s))" -ForegroundColor Green
        }
    }
}

if ($Check) {
    if ($dirty -gt 0) {
        Write-Host "mojibake check: $total double-encoded sequence(s) across $dirty file(s) -- run scripts/maintenance/fix-mojibake.ps1 to repair." -ForegroundColor Red
        exit 1
    }
    Write-Host "mojibake check: clean ($($Path.Count) file(s) examined)." -ForegroundColor Green
    exit 0
}

if ($total -eq 0) {
    Write-Host "Nothing to repair ($($Path.Count) file(s) examined)." -ForegroundColor Green
} else {
    Write-Host "Repaired $total sequence(s) across $dirty file(s)." -ForegroundColor Cyan
}
exit 0
