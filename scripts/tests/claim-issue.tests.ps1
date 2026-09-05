<#
.SYNOPSIS
    Regression tests for the claim step: the two decisions in scripts/lib/claim-issue-lib.ps1, and the
    two structural properties of scripts/task/claim-issue.ps1 that a suite can hold.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/claim-issue.tests.ps1

    NOTHING HERE TOUCHES A TRACKER, and that is why the script was built with its decisions in a lib.
    Every gh call in claim-issue.ps1 needs a live tracker, an account with write access and an issue it
    is allowed to edit -- so a suite can either assert nothing or assert the wrong thing. What it CAN
    hold is the whole judgement: which account a checkout claims under, and which of the four verdicts
    an issue gets. That is where all four refusals live, so the untestable half is reduced to two gh
    invocations and a read-back.

    THE NAMED TEST GAP, stated rather than papered over: the round trip itself -- gh accepting the
    edit, and the read-back catching an assignee GitHub silently dropped -- is exercised by hand
    against the live tracker, not here. It was exercised that way when this landed (issue #1453 was
    unassigned, re-claimed by the script, and read back), and the same reasoning applies as in
    git-identity-gate.tests.ps1: a suite that installed a keyring and a tracker would be testing gh.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\task\claim-issue.ps1'
$Lib      = Join-Path $RepoRoot 'scripts\lib\claim-issue-lib.ps1'
$IdLib    = Join-Path $RepoRoot 'scripts\lib\git-identity-lib.ps1'

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message" -ForegroundColor Red }
}

# Test-GitHubLoginShape lives in the identity lib and Resolve-ClaimAccount calls it, so both are
# loaded here -- which also asserts, by simply not throwing, that the extraction left the identity lib
# dot-sourceable on its own.
. $IdLib
. $Lib

Write-Host ''
Write-Host 'Resolve-ClaimAccount -- which account this checkout claims under' -ForegroundColor Cyan

$r = Resolve-ClaimAccount -GhAccount 'maikel-bwj' -GitUserName 'maikel-bwj'
Assert-True ($r.Account -eq 'maikel-bwj' -and -not $r.Split -and $r.Reason -eq 'gh') 'the two agree -- that account, no split'

$r = Resolve-ClaimAccount -GhAccount 'DaveKJohn' -GitUserName 'davekokbwj'
Assert-True ($r.Account -eq 'davekokbwj' -and $r.Split -and $r.Reason -eq 'split') 'the measured #1315 split -- claims by the GIT name, not the gh one'

$r = Resolve-ClaimAccount -GhAccount 'DaveKJohn' -GitUserName 'davekjohn'
Assert-True ($r.Account -eq 'DaveKJohn' -and -not $r.Split) 'GitHub logins are case-insensitive -- a case difference is ONE account'

$r = Resolve-ClaimAccount -GhAccount 'maikel-bwj' -GitUserName 'Ada Lovelace'
Assert-True ($r.Account -eq 'maikel-bwj' -and -not $r.Split) 'a display name is not an account -- no split, and the gh account stands'

$r = Resolve-ClaimAccount -GhAccount 'maikel-bwj' -GitUserName ('a' * 40)
Assert-True (-not $r.Split) '40 characters is not a GitHub login -- outside the shape, so no split'

$r = Resolve-ClaimAccount -GhAccount 'maikel-bwj' -GitUserName ('a' * 39)
Assert-True ($r.Split -and $r.Account -eq ('a' * 39)) '39 characters IS a GitHub login -- the shape boundary is walked at both edges'

$r = Resolve-ClaimAccount -GhAccount 'maikel-bwj' -GitUserName '-leading'
Assert-True (-not $r.Split) 'a leading hyphen is not a GitHub login -- no split'

$r = Resolve-ClaimAccount -GhAccount 'maikel-bwj' -GitUserName 'dou--ble'
Assert-True (-not $r.Split) 'a doubled hyphen is not a GitHub login -- no split'

$r = Resolve-ClaimAccount -GhAccount '' -GitUserName 'maikel-bwj'
Assert-True ($r.Account -eq '' -and $r.Reason -eq 'none') 'gh logged out -- there is nobody to claim as, and it says so rather than falling back to the git name'

$r = Resolve-ClaimAccount -GhAccount '  maikel-bwj  ' -GitUserName '  maikel-bwj  '
Assert-True ($r.Account -eq 'maikel-bwj' -and -not $r.Split) 'both values are trimmed -- whitespace is not a second account'

Write-Host ''
Write-Host 'Get-ClaimVerdict -- may this issue be claimed' -ForegroundColor Cyan

$v = Get-ClaimVerdict -Account 'maikel-bwj' -State 'OPEN' -Assignees @()
Assert-True ($v.Action -eq 'claim' -and $v.Code -eq 'open-unassigned') 'open and unassigned -- claim it'

$v = Get-ClaimVerdict -Account 'maikel-bwj' -State 'OPEN' -Assignees $null
Assert-True ($v.Action -eq 'claim') 'a null assignee list is an unassigned issue, not a crash'

$v = Get-ClaimVerdict -Account 'maikel-bwj' -State 'CLOSED' -Assignees @()
Assert-True ($v.Action -eq 'refuse' -and $v.Code -eq 'closed') 'CLOSED is refused -- the refusal the documented one-liner cannot make'

$v = Get-ClaimVerdict -Account 'maikel-bwj' -State 'closed' -Assignees @()
Assert-True ($v.Code -eq 'closed') 'the state is compared case-insensitively -- gh and the REST API disagree on case'

$v = Get-ClaimVerdict -Account 'maikel-bwj' -State 'CLOSED' -Assignees @('maikel-bwj')
Assert-True ($v.Code -eq 'closed') 'closed beats already-yours -- your own name on finished work is still finished work'

$v = Get-ClaimVerdict -Account 'maikel-bwj' -State 'OPEN' -Assignees @('DaveKJohn')
Assert-True ($v.Action -eq 'refuse' -and $v.Code -eq 'taken' -and $v.Others -contains 'DaveKJohn') 'somebody else holds it -- refused, and the message can name them'

$v = Get-ClaimVerdict -Account 'maikel-bwj' -State 'OPEN' -Assignees @('maikel-bwj', 'DaveKJohn')
Assert-True ($v.Code -eq 'taken' -and $v.Others.Count -eq 1 -and $v.Others[0] -eq 'DaveKJohn') 'a co-assignment is refused too, and Others carries only the other party'

$v = Get-ClaimVerdict -Account 'maikel-bwj' -State 'OPEN' -Assignees @('maikel-bwj')
Assert-True ($v.Action -eq 'skip' -and $v.Code -eq 'already-yours') 'already yours -- a resume, so nothing to write and no error'

$v = Get-ClaimVerdict -Account 'maikel-bwj' -State 'OPEN' -Assignees @('MAIKEL-BWJ')
Assert-True ($v.Code -eq 'already-yours') 'your own login in another case is still you'

$v = Get-ClaimVerdict -Account '' -State 'OPEN' -Assignees @()
Assert-True ($v.Action -eq 'refuse' -and $v.Code -eq 'no-account') 'no account -- a claim cannot be made anonymously, even on a perfectly claimable issue'

$v = Get-ClaimVerdict -Account 'maikel-bwj' -State 'OPEN' -Assignees @('DaveKJohn')
Assert-True ($v.Others -is [array]) 'Others is always an array -- a single other assignee must not arrive as a bare string'

Write-Host ''
Write-Host 'Get-AssigneeLogins -- reading gh JSON without trusting its shape' -ForegroundColor Cyan

Assert-True ((Get-AssigneeLogins -Json '{"assignees":[{"login":"maikel-bwj"}]}') -contains 'maikel-bwj') 'the ordinary payload -- one assignee'

$l = Get-AssigneeLogins -Json '{"assignees":[{"login":"a"},{"login":"b"}]}'
Assert-True ($l.Count -eq 2 -and $l[0] -eq 'a' -and $l[1] -eq 'b') 'two assignees, in order'

Assert-True ((Get-AssigneeLogins -Json '{"assignees":[]}').Count -eq 0) 'an unassigned issue is an empty array'
Assert-True ((Get-AssigneeLogins -Json '{"number":7}').Count -eq 0) 'a payload with no assignees field at all -- empty, not a throw'
Assert-True ((Get-AssigneeLogins -Json 'not json').Count -eq 0) 'unparseable JSON is empty rather than an exception'
Assert-True ((Get-AssigneeLogins -Json '').Count -eq 0) 'empty input is empty'

# Victor's finding: under Set-StrictMode -Version Latest a dot-read of an ABSENT property throws, and
# the previous inline loop did exactly that. This is the assert that keeps it out.
Assert-True ((Get-AssigneeLogins -Json '{"assignees":[{"id":"X"},{"login":"maikel-bwj"}]}') -contains 'maikel-bwj') 'an assignee record with no login is skipped, not fatal -- the rest is still read'

Assert-True ((Get-AssigneeLogins -Json '{"assignees":[{"login":"a"},{"login":"a"}]}').Count -eq 1) 'a repeated login is counted once'
Assert-True ((Get-AssigneeLogins -Json '{"assignees":[{"login":"  a  "}]}')[0] -eq 'a') 'logins are trimmed'

Write-Host ''
Write-Host 'Format-ForConsole -- tracker text is written by strangers' -ForegroundColor Cyan

$t = Format-ForConsole -Text ("Fix the thing" + [char]27 + "[2K" + [char]27 + "[A")
Assert-True ($t -notmatch [char]27) 'an ANSI escape in an issue title never reaches the terminal'
Assert-True ($t -like 'Fix the thing*') 'the printable half of the title survives verbatim'

$t = Format-ForConsole -Text ("one" + [char]10 + "two")
Assert-True ($t -eq 'one two') 'a newline becomes a space -- a title cannot forge a second output line'

$t = Format-ForConsole -Text ("a" + [char]0 + "b")
Assert-True ($t -eq 'a b') 'a control character becomes a space rather than vanishing -- two words cannot be glued into one'

Assert-True ((Format-ForConsole -Text '') -eq '') 'an empty title is an empty string, not a crash'

Write-Host ''
Write-Host 'claim-issue.ps1 -- the properties a suite can hold' -ForegroundColor Cyan

$body = Get-Content -LiteralPath $Script -Raw

# THE REGRESSION THIS SUITE EXISTS TO PREVENT. The whole reason this script is not the documented
# one-liner is that '@me' binds to gh's account rather than to the one the commits will name (#1315).
# A later edit "simplifying" the identity resolution back to '@me' would pass every behavioural test
# above -- they never run the script -- and reintroduce the exact defect in one line.
Assert-True ($body -match "'--add-assignee',\s*\`$identity\.Account") 'the claim is written by NAME, from the resolved identity'
Assert-True ($body -notmatch "--add-assignee'\s*,\s*'@me'") "the script never sends '@me' as the assignee"

# The write is not the proof: gh reports success for a login GitHub silently drops. Two issue views
# is what a read-back looks like from here -- the facts before, the assignees after.
Assert-True ((([regex]::Matches($body, "'issue',\s*'view'")).Count) -ge 2) 'the claim is read back after the write, not assumed from the exit code'

# The title is the one field on the issue that a stranger writes, and this script prints it twice.
Assert-True ($body -notmatch '\$\(\$facts\.title\)') 'the issue title is never printed straight from the tracker'

foreach ($path in @($Script, $Lib, $IdLib)) {
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errors)
    Assert-True (@($errors).Count -eq 0) "$(Split-Path -Leaf $path) parses without error"
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "claim-issue.tests: $($script:pass) passed, $($script:fail) FAILED" -ForegroundColor Red
    exit 1
}
Write-Host "claim-issue.tests: $($script:pass) passed, 0 failed" -ForegroundColor Green
exit 0
