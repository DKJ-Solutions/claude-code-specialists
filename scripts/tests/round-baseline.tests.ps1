<#
.SYNOPSIS
    Regression tests for scripts/tests/round-baseline.measure.ps1 -- the generator that replaces a
    hand-typed round baseline table (issue #371).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Integration style -- runs the REAL measure
    script as a CHILD PROCESS against throwaway git repos in the temp directory, so nothing touches
    this working copy and the assertions see exactly what a caller redirecting stdout to a file sees
    (Sylvester #15: an in-process assertion cannot observe Write-Host, and a table that reaches the
    papers by copy/paste must be judged in the form it arrives).

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/round-baseline.tests.ps1

    What is pinned, and why each case exists:
      - The two line conventions #371 is about, in BOTH directions: a file ending in a terminator
        reports 22 terminated / 23 positions, and a file that does not reports the same number twice.
        A generator that only ever printed terminators + 1 would pass the first case and lie in the
        second.
      - The LF/CRLF size pair, driven by core.autocrlf per fixture rather than by the machine's
        global setting, so the suite gives the same verdict on a CRLF and an LF checkout.
      - The invariant that IS the issue: every row carries a non-empty 'how measured' cell. #371 was
        filed because one row said 'alle regels', which names no convention -- so an empty or
        missing third column must fail here rather than in a round's papers.
      - The refusal when the on-disk file differs from the ref, found by the script's own first smoke
        test. Asserted through the exit code, because a table that is merely accompanied by a warning
        still gets pasted.

    Fixture note: the CRLF cases use core.autocrlf=input, which normalizes the blob to LF while
    leaving the working tree as written. That is the Windows situation (blob LF, disk CRLF) without
    depending on the host's autocrlf, and it also proves the guard above does not false-positive on
    it -- git compares normalized content, so CRLF-on-disk against an LF blob is not a difference.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$MeasureSrc = Join-Path $RepoRoot 'scripts\tests\round-baseline.measure.ps1'

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

$script:fixtures = @()

function Invoke-Native {
    # Local twin of native-capture-lib's guard: a native command's stderr must not terminate the
    # suite. `git add` on a CRLF file warns about the LF replacement, which is normal chatter.
    param([string]$FilePath, [string[]]$Arguments)
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out  = & $FilePath @Arguments 2>&1
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $prev }
    return [pscustomobject]@{ Output = @($out); ExitCode = $code }
}

function New-BaselineRepo {
    <#
        A throwaway git repo holding one committed file, written from raw BYTES so the terminators
        are exactly what the test intends -- a here-string would inherit this file's own line endings
        and silently change what is being measured.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$Text,
        [ValidateSet('true', 'false', 'input')][string]$Autocrlf = 'false',
        [string]$FileName = 'README.md',
        [switch]$Crlf
    )
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("baseline-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $script:fixtures += $dir

    Invoke-Native -FilePath 'git' -Arguments @('-C', $dir, 'init', '-q')                              | Out-Null
    Invoke-Native -FilePath 'git' -Arguments @('-C', $dir, 'config', 'user.email', 'test@example.com') | Out-Null
    Invoke-Native -FilePath 'git' -Arguments @('-C', $dir, 'config', 'user.name', 'Baseline Test')     | Out-Null
    Invoke-Native -FilePath 'git' -Arguments @('-C', $dir, 'config', 'core.autocrlf', $Autocrlf)       | Out-Null
    # gpgsign off: a locked signing agent must not fail the baseline commit for a reason unrelated to the test (#1287).
    Invoke-Native -FilePath 'git' -Arguments @('-C', $dir, 'config', 'commit.gpgsign', 'false')        | Out-Null

    Add-BaselineFile -Dir $dir -FileName $FileName -Text $Text -Crlf:$Crlf
    Invoke-Native -FilePath 'git' -Arguments @('-C', $dir, 'add', '-A')                      | Out-Null
    Invoke-Native -FilePath 'git' -Arguments @('-C', $dir, 'commit', '-q', '-m', 'baseline') | Out-Null
    return $dir
}

function Add-BaselineFile {
    param([string]$Dir, [string]$FileName, [string]$Text, [switch]$Crlf)
    $body = if ($Crlf) { $Text -replace "`n", "`r`n" } else { $Text }
    [System.IO.File]::WriteAllBytes((Join-Path $Dir $FileName), [System.Text.Encoding]::ASCII.GetBytes($body))
}

function Invoke-Measure {
    # Always over the -File hop, never dot-run: that is the hop where a comma-separated -Path has to
    # survive, and $args is left alone because it is an automatic variable.
    param([string]$Dir, [string[]]$ExtraArgs = @())
    $psArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $MeasureSrc, '-RepoPath', $Dir) + $ExtraArgs
    return Invoke-Native -FilePath 'powershell' -Arguments $psArgs
}

function Get-Row {
    # The value cell of the row whose measure column matches $Pattern, or $null.
    param([string[]]$Output, [string]$Pattern)
    foreach ($line in $Output) {
        if ($line -notmatch '^\|') { continue }
        $cells = @(($line.Trim('|') -split '\|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -ge 3 -and $cells[0] -match $Pattern) {
            return [pscustomobject]@{ Measure = $cells[0]; Value = $cells[1]; How = $cells[2] }
        }
    }
    return $null
}

function Get-DataRows {
    param([string[]]$Output)
    $rows = @()
    foreach ($line in $Output) {
        if ($line -notmatch '^\|') { continue }
        if ($line -match '^\|\s*-{2,}') { continue }
        $cells = @(($line.Trim('|') -split '\|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -lt 3) { continue }
        if ($cells[0] -eq 'measure') { continue }
        $rows += ,[pscustomobject]@{ Measure = $cells[0]; Value = $cells[1]; How = $cells[2] }
    }
    return $rows
}

Write-Host ''
Write-Host 'round-baseline.measure.ps1' -ForegroundColor Cyan

# ---------------------------------------------------------------------------------------------------
Write-Host 'A file ending in a terminator reports both conventions, and they differ by one' -ForegroundColor Cyan
#      The #371 case itself: 22 terminators is 22 lines by one convention and 23 line positions by the
#      other. v12's table printed 23 under the label 'alle regels' and left the reader to guess.
#      22 lines, every third one empty, closed by a terminator: 22 terminators, 15 non-empty lines --
#      which is the real fixture's shape, so the numbers below are the ones a round actually reads.
$text22 = ((1..22 | ForEach-Object { if ($_ % 3 -eq 0) { '' } else { "line $_" } }) -join "`n") + "`n"
$dir1   = New-BaselineRepo -Label 'crlf22' -Text $text22 -Autocrlf 'input' -Crlf
$r1     = Invoke-Measure -Dir $dir1
Assert-True ($r1.ExitCode -eq 0)                                        'exits 0 on a clean fixture'
$terminated1 = Get-Row -Output $r1.Output -Pattern 'lines, terminated'
$positions1  = Get-Row -Output $r1.Output -Pattern 'line positions'
Assert-True ($terminated1 -and $terminated1.Value -eq '**22**')         'terminated lines: 22'
Assert-True ($positions1  -and $positions1.Value  -eq '**23**')         'line positions: 23'
Assert-True ($terminated1.How -match 'Get-Content')                     'the terminated row names the command that returns it'
Assert-True ($positions1.How  -match 'editor')                          'the positions row names the editor gutter it comes from'

# ---------------------------------------------------------------------------------------------------
Write-Host 'The CRLF pair is measured, and the delta is tied to the conversion count' -ForegroundColor Cyan
#      v12's own table asserted this relation in prose ('core.autocrlf=true maakt van 22 LF's een
#      CRLF'), which is what let the reporter of #371 prove the line count. Now it is computed.
$blob1  = Get-Row -Output $r1.Output -Pattern 'size, repo side'
$disk1  = Get-Row -Output $r1.Output -Pattern 'size, on disk'
$delta1 = Get-Row -Output $r1.Output -Pattern 'size delta'
$blobN  = [int](($blob1.Value -replace '[^\d]', ''))
$diskN  = [int](($disk1.Value -replace '[^\d]', ''))
Assert-True ($diskN - $blobN -eq 22)                                    'disk exceeds the blob by exactly the 22 CRLF conversions'
Assert-True ($delta1.Value -eq '**22 bytes**')                          'the delta row reports those 22 bytes'
Assert-True ($delta1.How -match 'CRLF conversion')                      'the delta row explains itself by the conversion count'
Assert-True ($blob1.How -match 'cat-file -s')                           'the blob row names the git command it came from'
Assert-True ($disk1.How -match 'CRLF on disk' -and $disk1.How -match 'core\.autocrlf=input') `
                                                                        'the disk row names the eol on disk and the autocrlf in force'

# ---------------------------------------------------------------------------------------------------
Write-Host 'A file with NO closing terminator reports the same number twice' -ForegroundColor Cyan
#      The direction a naive 'terminators + 1' gets wrong: here there is no empty last position, so
#      both conventions agree and the table must not invent a difference.
$dir2 = New-BaselineRepo -Label 'noeol' -Text "alpha`nbravo`ncharlie" -Autocrlf 'false'
$r2   = Invoke-Measure -Dir $dir2
$terminated2 = Get-Row -Output $r2.Output -Pattern 'lines, terminated'
$positions2  = Get-Row -Output $r2.Output -Pattern 'line positions'
Assert-True ($r2.ExitCode -eq 0)                                        'no-trailing-newline: exits 0'
Assert-True ($terminated2.Value -eq '**3**')                            'no-trailing-newline: 3 terminated lines (2 terminators + the last line)'
Assert-True ($positions2.Value  -eq '**3**')                            'no-trailing-newline: 3 positions, not 4'
Assert-True ($positions2.How -match 'does NOT end with a terminator')   'no-trailing-newline: and the row says why the two agree'

# ---------------------------------------------------------------------------------------------------
Write-Host 'An LF checkout reports a zero delta and says why' -ForegroundColor Cyan
#      A round on a non-Windows checkout must not read the zero as a failed measurement.
$delta2 = Get-Row -Output $r2.Output -Pattern 'size delta'
Assert-True ($delta2.Value -eq '**0 bytes**')                           'LF on disk: delta 0'
Assert-True ($delta2.How -match 'LF on disk too')                       'LF on disk: named as LF rather than left at 0'

# ---------------------------------------------------------------------------------------------------
Write-Host 'The Measure-Object row carries its empty-line caveat' -ForegroundColor Cyan
#      Three of the six rows in v12's table were about a figure that is correct under one convention
#      only; this is the one that already had its caveat, and it must not be lost in the port.
$dir3 = New-BaselineRepo -Label 'blanks' -Text "one`n`ntwo`n`n`nthree`n" -Autocrlf 'false'
$r3   = Invoke-Measure -Dir $dir3
$m3   = Get-Row -Output $r3.Output -Pattern 'Measure-Object'
$t3   = Get-Row -Output $r3.Output -Pattern 'lines, terminated'
Assert-True ($t3.Value -eq '**6**')                                     'blank lines: 6 terminated lines'
Assert-True ($m3.Value -eq '**3**')                                     'blank lines: Measure-Object counts only the 3 non-empty ones'
Assert-True ($m3.How -match 'skips empty lines')                        'blank lines: the caveat travels with the figure'
$m1 = Get-Row -Output $r1.Output -Pattern 'Measure-Object'
Assert-True ($m1.Value -eq '**15**')                                    'the 22-line fixture reports 15, the figure the real papers carry'

# ---------------------------------------------------------------------------------------------------
Write-Host 'EVERY row names how it was measured -- the invariant #371 is about' -ForegroundColor Cyan
#      The defect was a row reading 'alle regels': a value with no convention behind it. A row whose
#      third cell is empty (or missing) must fail here, in CI, and not in a consumer's papers.
$rows3 = Get-DataRows -Output $r3.Output
Assert-True ($rows3.Count -ge 8)                                        'the table has all its rows'
$blankHow  = @($rows3 | Where-Object { -not $_.How })
$blankVal  = @($rows3 | Where-Object { -not $_.Value })
Assert-True ($blankHow.Count -eq 0)                                     'no row has an empty how-measured cell'
Assert-True ($blankVal.Count -eq 0)                                     'no row has an empty value cell'
$vague = @($rows3 | Where-Object { $_.How.Length -lt 12 })
Assert-True ($vague.Count -eq 0)                                        'no how-measured cell is a bare label like "all lines"'

# ---------------------------------------------------------------------------------------------------
Write-Host 'The repo rows come from git, and the header says what was measured' -ForegroundColor Cyan
$commits3 = Get-Row -Output $r3.Output -Pattern 'commits on'
$headRow3 = Get-Row -Output $r3.Output -Pattern '^`HEAD`$'
$shortSha = (Invoke-Native -FilePath 'git' -Arguments @('-C', $dir3, 'rev-parse', '--short', 'HEAD')).Output[0].Trim()
Assert-True ($commits3.Value -eq '**1**')                               'commits: 1 on a single-commit fixture'
Assert-True ($commits3.How -match 'non-shallow')                        'commits: the row says the clone is not shallow'
Assert-True ($headRow3 -and $headRow3.Value -eq "**``$shortSha``**")     'HEAD: the short sha git itself reports'
Assert-True (@($r3.Output | Where-Object { $_ -match 'generated by scripts/tests/round-baseline\.measure\.ps1' }).Count -eq 1) `
                                                                        'the block says it is generated, so nobody retypes it'
Assert-True (@($r3.Output | Where-Object { $_ -match 'working tree: clean' }).Count -eq 1) `
                                                                        'the provenance line reports the state of the tree'

# ---------------------------------------------------------------------------------------------------
Write-Host 'It refuses when the file on disk is not the file in the ref' -ForegroundColor Cyan
#      The hole this script's own smoke test found: blob rows from the ref, disk rows from the
#      worktree. An exit 0 with a warning is not enough -- the table gets pasted either way.
$dir4 = New-BaselineRepo -Label 'mismatch' -Text "alpha`nbravo`n" -Autocrlf 'false'
Add-BaselineFile -Dir $dir4 -FileName 'README.md' -Text "alpha`nbravo`ncharlie`n"
$r4 = Invoke-Measure -Dir $dir4
Assert-True ($r4.ExitCode -ne 0)                                        'worktree mismatch: non-zero exit'
Assert-True (@($r4.Output | Where-Object { $_ -match 'differs from its content in' }).Count -ge 1) `
                                                                        'worktree mismatch: and it says which way the two disagree'
Assert-True (@($r4.Output | Where-Object { $_ -match '^\| size' }).Count -eq 0) `
                                                                        'worktree mismatch: no table is printed at all'

# ---------------------------------------------------------------------------------------------------
Write-Host 'A CRLF working tree is NOT mistaken for that mismatch' -ForegroundColor Cyan
#      The guard above compares normalized content on purpose. If it compared bytes, every Windows
#      round -- the only kind this family runs -- would be refused, and the guard would be worse than
#      the defect it prevents. Fixture 1 is exactly that case and it exited 0 above; assert the table
#      it produced is complete rather than trusting the exit code alone.
Assert-True (@($r1.Output | Where-Object { $_ -match '^\| size, on disk' }).Count -eq 1) `
                                                                        'CRLF tree: the disk row is present'
Assert-True (@($r1.Output | Where-Object { $_ -match 'differs from its content in' }).Count -eq 0) `
                                                                        'CRLF tree: and nothing was refused'

# ---------------------------------------------------------------------------------------------------
Write-Host 'Bad input fails with a pointer instead of a stack trace' -ForegroundColor Cyan
$r5 = Invoke-Measure -Dir (Join-Path ([System.IO.Path]::GetTempPath()) "baseline-nope-$PID")
Assert-True ($r5.ExitCode -ne 0)                                        'missing checkout: non-zero exit'
Assert-True (@($r5.Output | Where-Object { $_ -match 'No such checkout' }).Count -ge 1) `
                                                                        'missing checkout: named as such'

$plain = Join-Path ([System.IO.Path]::GetTempPath()) "baseline-plain-$PID"
if (Test-Path -LiteralPath $plain) { Remove-Item -Recurse -Force -LiteralPath $plain }
New-Item -ItemType Directory -Path $plain -Force | Out-Null
$script:fixtures += $plain
$r6 = Invoke-Measure -Dir $plain
Assert-True ($r6.ExitCode -ne 0)                                        'not a git checkout: non-zero exit'
Assert-True (@($r6.Output | Where-Object { $_ -match 'not a git checkout' }).Count -ge 1) `
                                                                        'not a git checkout: named as such'

$r7 = Invoke-Measure -Dir $dir3 -ExtraArgs @('-Path', 'ABSENT.md')

Assert-True ($r7.ExitCode -ne 0)                                        'absent -Path: non-zero exit'
Assert-True (@($r7.Output | Where-Object { $_ -match 'does not exist in' }).Count -ge 1) `
                                                                        'absent -Path: named as such'

# ---------------------------------------------------------------------------------------------------
Write-Host 'A comma-separated -Path survives the -File hop, and every row says which file' -ForegroundColor Cyan
#      Two things in one case. A round measuring two files must not produce two rows called 'lines,
#      terminated' -- and the list has to arrive as two paths rather than as the single filename
#      'README.md,SECOND.md', which is exactly what a [string[]] parameter would have received here.
$dir8 = New-BaselineRepo -Label 'multi' -Text "alpha`n" -Autocrlf 'false'
Add-BaselineFile -Dir $dir8 -FileName 'SECOND.md' -Text "one`ntwo`nthree`n"
Invoke-Native -FilePath 'git' -Arguments @('-C', $dir8, 'add', '-A')                    | Out-Null
Invoke-Native -FilePath 'git' -Arguments @('-C', $dir8, 'commit', '-q', '-m', 'second') | Out-Null
$r8 = Invoke-Measure -Dir $dir8 -ExtraArgs @('-Path', 'README.md,SECOND.md')
Assert-True ($r8.ExitCode -eq 0)                                        'two files: exits 0'
$named8 = @($r8.Output | Where-Object { $_ -match '^\| lines, terminated' })
Assert-True ($named8.Count -eq 2)                                       'two files: two terminated-lines rows'
Assert-True (@($named8 | Where-Object { $_ -match 'README\.md' }).Count -eq 1 -and
             @($named8 | Where-Object { $_ -match 'SECOND\.md' }).Count -eq 1) `
                                                                        'two files: each row names its own file'
$second8 = @($r8.Output | Where-Object { $_ -match '^\| lines, terminated .*SECOND\.md' })
Assert-True ($second8.Count -eq 1 -and $second8[0] -match '\*\*3\*\*')  'two files: the second file gets its own 3 lines'

# ---------------------------------------------------------------------------------------------------
Write-Host 'A shallow clone is reported rather than counted as history' -ForegroundColor Cyan
#      The commit count is the one row a shallow clone silently falsifies -- v12's table names
#      'a non-shallow clone' in its how-measured cell precisely because of that.
$shallow = Join-Path ([System.IO.Path]::GetTempPath()) "baseline-shallow-$PID"
if (Test-Path -LiteralPath $shallow) { Remove-Item -Recurse -Force -LiteralPath $shallow }
$src     = ($dir8 -replace '\\', '/')
$cloned  = Invoke-Native -FilePath 'git' -Arguments @('clone', '-q', '--depth', '1', "file:///$src", $shallow)
if ($cloned.ExitCode -eq 0) {
    $script:fixtures += $shallow
    #  Deliberately NOT setting core.autocrlf here. The first version of this case set it to false
    #  after cloning, and the measure script refused the fixture -- correctly: the checkout had
    #  already written the working tree under the host's autocrlf, so flipping the config afterwards
    #  makes git compare bytes and read the file as modified. Whatever the host's setting is, a clone
    #  is internally consistent with it, and these three assertions do not depend on the eol.
    $r9 = Invoke-Measure -Dir $shallow
    Assert-True ($r9.ExitCode -eq 0)                                    'shallow clone: still produces a table'
    Assert-True (@($r9.Output | Where-Object { $_ -match 'SHALLOW clone' }).Count -ge 1) `
                                                                        'shallow clone: the commits row says the count is a fetch depth'
    Assert-True (@($r9.Output | Where-Object { $_ -match 'shallow: yes' }).Count -eq 1) `
                                                                        'shallow clone: and the provenance line says so too'
} else {
    Write-Host '  [SKIP] shallow clone: git clone --depth over file:// unavailable here' -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------------------------------
foreach ($f in $script:fixtures) { Remove-Item -Recurse -Force -LiteralPath $f -ErrorAction SilentlyContinue }

Write-Host ''
Write-Host "Result: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
