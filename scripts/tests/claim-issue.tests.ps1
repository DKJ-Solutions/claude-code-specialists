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

# ISSUE #1858. The class was '[\x00-\x1F\x7F]' until then -- C0 and DEL -- so every hazard below
# reached the terminal untouched, none of it carrying a byte under 0x80. The asserts are per code
# point rather than one sweep because they fail for different reasons: C1 is a second CONTROL range
# the old class simply did not reach, while the rest are \p{Cf}, which is a different category and
# which `git check-ref-format` accepts in a branch name to this day (#1617's own measurement).
$t = Format-ForConsole -Text ('a' + [char]0x9B + 'b')
Assert-True ($t -eq 'a b') 'a C1 control (0x9B, read as CSI by some terminals) becomes a space -- it is above 0x7F and the old class stopped there'

$t = Format-ForConsole -Text ('report' + [char]0x202E + 'gnp.txt')
Assert-True ($t -eq 'report gnp.txt') 'a RIGHT-TO-LEFT OVERRIDE cannot reorder the line it sits on -- the Trojan-Source shape #1858 was filed for'

$t = Format-ForConsole -Text ('a' + [char]0x2066 + 'b' + [char]0x2069 + 'c')
Assert-True ($t -eq 'a b c') 'the bidi isolates go too, both halves of the pair'

$t = Format-ForConsole -Text ('ad' + [char]0x200B + 'min')
Assert-True ($t -eq 'ad min') 'a zero-width space becomes a visible space rather than vanishing -- two words are never welded into one that reads as a different title'

$t = Format-ForConsole -Text ([char]0xFEFF + 'title')
Assert-True ($t -eq ' title') 'and nothing is trimmed or collapsed: a title is quoted evidence, which is why this is NOT Get-DisplayRef'

$t = Format-ForConsole -Text 'Ordinary title -- with punctuation! 100% (v2)'
Assert-True ($t -eq 'Ordinary title -- with punctuation! 100% (v2)') 'printable text survives the widening exactly as written'

# THE DRIFT PIN'S LOCAL HALF. pr-issues.tests.ps1 asserts WHICH libs type this class and that they
# agree; this asserts there is ONE definition inside this one, the same shape that suite uses for
# Format-AuthoredText. A second -replace here would be a strip that could drift from its own docstring.
$libText = [System.IO.File]::ReadAllText($Lib)
Assert-True ([regex]::Matches($libText, [regex]::Escape("-replace '[\p{Cc}\p{Cf}]', ' '")).Count -eq 1) 'ONE definition inside this lib -- Format-ForConsole, which the title, the commit subjects and the branch names all go through'

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

# THE READ-BACK'S THREE STATES (#1628). The defect was one boolean standing for two opposite facts --
# "gh answered and said no" and "gh never answered" -- with the refusal message printed for both. It is
# a WRONG MESSAGE on a path no behavioural test here reaches, so the shape is what a suite can hold:
# the refusal must be gated on the read having succeeded, and the unverified path must exist and must
# not exit. A later edit collapsing them back would restore a false stop on a claim that landed.
#
# THE PATTERN NO LONGER PINS THE CLOSING BRACKET (#1679), and the loosening is deliberate rather than
# convenient: #1628's subject is that $readOk is its OWN value, computed from whether gh answered, and
# separate from what gh said. It was never that the expression has exactly two terms. #1679 added a
# third -- a capture that came back short is also gh not having answered -- and the old regex refused
# it by requiring `0)` immediately, which would have made this suite argue for the defect. The
# ShortRead half is pinned exactly, in its own block further down, so nothing is left unasserted.
Assert-True ($body -match '\$readOk\s*=\s*\[bool\]\(\$after\s+-and\s+\$after\.ExitCode\s+-eq\s+0') 'whether the read-back answered is its own value, separate from what it said'
Assert-True ($body -match 'if\s*\(\$readOk\s+-and\s+-not\s+\$landed\)') 'the "not on the issue" refusal fires only where the read actually answered'
Assert-True ($body -notmatch 'if\s*\(-not\s+\$landed\)\s*\{') 'no branch keys the refusal off $landed alone -- that is the collapse itself'
Assert-True ($body -match 'if\s*\(-not\s+\$readOk\)') 'a read that did not answer has its own branch'

# The unverified branch must stay non-blocking and must name what it measured. Its whole reason for
# existing is that a false stop costs the assignment (#1485), so an `exit` added to it would be the
# defect back in a new spelling -- and a message that does not name the exit code is the old one's
# other half: a cause asserted rather than measured.
$unverified = if ($body -match '(?s)if\s*\(-not\s+\$readOk\)\s*\{(.*?)\n\}') { $Matches[1] } else { '' }
Assert-True ($unverified -ne '') 'the unverified branch is findable as a block'

# THE 'DOES IT BLOCK' ASSERT READS CODE, NOT PROSE, and that distinction was measured rather than
# anticipated (#1639). The assert below is about an `exit` STATEMENT; run over the raw block it also
# matched the word "exit" inside a comment -- and the comment that tripped it was a correct one,
# explaining that a stall and an exit code point the reader at different things. A test that a true
# comment can fail teaches the next author to write a worse comment, so the comment lines come off
# first and the assert keeps exactly the subject it always had.
function Get-CodeOnly {
    param([string]$Block)
    return (($Block -split "`n" | Where-Object { $_ -notmatch '^\s*#' }) -join "`n")
}

Assert-True ((Get-CodeOnly -Block $unverified) -notmatch '\bexit\b') 'the unverified read does NOT block -- the write returned 0 and the claim most likely landed'
Assert-True ($unverified -match '\[WARNING\]') 'it reports as a warning, not as the refusal it is not'
Assert-True ($unverified -match 'exited \$\(\$after\.ExitCode\)') 'it names the exit code it actually measured'
Assert-True ($unverified -match [regex]::Escape('$after.TimedOut')) 'and it names a TIMEOUT as its own reason, which #1639 made reachable -- a stall says nothing about the tracker, where an exit code says gh answered and disagreed'

# --- a short read is not gh disagreeing (#1679) ---------------------------------------------------
# THE READ-BACK'S OWN GUARD, and the one assert that pins WHY. $readOk used to ask the exit code alone,
# so a -Utf8 capture that came back empty at exit 0 made $landed false and sent the run down the
# REFUSED branch -- "Treat the issue as UNCLAIMED", exit 1 -- on a claim that had in fact landed. The
# fix is that the short read joins the could-not-verify state, which already exists and does not block.
Write-Host ''
Write-Host 'A short read is not a refusal (#1679)' -ForegroundColor Cyan

Assert-True ($body -match [regex]::Escape('$readOk = [bool]($after -and $after.ExitCode -eq 0 -and -not $after.ShortRead)')) `
    'the read-back folds ShortRead into $readOk, so a truncated capture cannot reach the REFUSED branch'
Assert-True ($unverified -match [regex]::Escape('$after.ShortRead')) `
    'and the could-not-verify branch names it as its own reason -- the exit code is 0 there, so "exited 0" would be the misleading half'
Assert-True ($unverified.IndexOf('$after.ShortRead') -lt $unverified.IndexOf('exited $($after.ExitCode)')) `
    'named BEFORE the exit-code arm, or it could never print'
Assert-True ($body -match [regex]::Escape('if ($view.ShortRead)')) `
    'the pre-write read separates a truncated capture from gh returning non-JSON -- same verdict, different thing to go and check'

# --- the network bound on every gh call (#1639) ---------------------------------------------------
# ALL THREE CALLS WERE UNBOUNDED while every sibling script bounded its own, and the reason was a stale
# comment on the shared value: it opened "THE BOUND A GIT NETWORK CALL PASSES" and listed three sites,
# by which time six files read it and two passed it to `gh`. So a `gh`-only script read the policy as
# somebody else's. The claim is the FIRST step of an issue-driven assignment (#1485), so a stall here
# is a session that never starts with nothing printed to say why.
Write-Host ''
Write-Host 'The network bound (#1639)' -ForegroundColor Cyan

# PER CALL, NOT PER FILE (#1853). This was a whole-file count of the bound compared with a whole-file
# count of the gh calls, which was EXACT for as long as gh was the only thing in this script bounded --
# and stopped being so the moment the parked-fix scan added a bounded `git fetch`. The old shape then
# failed on a script where every gh call was in fact bounded, which is a test arguing against the rule
# it exists to hold. The intent is unchanged and is now measured directly: each gh invocation is read on
# its own, so a fourth one added later and left unbounded still fails, and a bounded call to something
# else no longer can.
$calls = [regex]::Matches($body, "Invoke-NativeCapture\s+(?:-Utf8\s+)?-FilePath\s+'(?<cmd>[a-z]+)'")
$ghCalls = 0
$unbounded = @()
for ($i = 0; $i -lt $calls.Count; $i++) {
    if ($calls[$i].Groups['cmd'].Value -ne 'gh') { continue }
    $ghCalls++
    # THE INVOCATION, NOT THE REST OF THE FILE: a PowerShell call ends at the first line that does not
    # end in a backtick continuation, so reading to there is what keeps a neighbouring call's bound from
    # being counted for this one.
    $tail = $body.Substring($calls[$i].Index)
    $statement = ''
    foreach ($line in ($tail -split "`r?`n")) {
        $statement += $line + "`n"
        if ($line -notmatch '`\s*$') { break }
    }
    if ($statement -notmatch [regex]::Escape('-TimeoutSeconds $NativeCaptureNetworkTimeoutSeconds')) {
        $unbounded += ($statement -split "`n")[0].Trim()
    }
}
Assert-True ($ghCalls -ge 3) "the three gh calls are still here (found $ghCalls)"
Assert-True ($unbounded.Count -eq 0) "every gh call carries the shared bound -- $ghCalls call(s), $($unbounded.Count) unbounded"
Assert-True ($body -match [regex]::Escape('$NativeCaptureNetworkTimeoutSeconds')) 'and it is the SHARED value, not a number typed in here'

# THE READ AND THE READ-BACK REPORT A STALL AS A STALL. The pre-write read's failure branch offers a
# list of three causes gh reached a verdict for; a hang is none of them, so sending a reader down that
# list would be the bound announcing itself as the wrong thing.
Assert-True ($body -match [regex]::Escape('if ($view -and $view.TimedOut)')) 'the pre-write read distinguishes a stall from the three verdicts it otherwise lists'

# THE WRITE IS THE ONE TIMEOUT THAT IS NOT A FAILURE, and it gets its own branch above the failure one.
# `gh issue edit` changes the tracker, so a write that reached the network and never answered may have
# landed -- reporting "the claim failed" there would be a claim about the tracker this run cannot make.
$editTimeout = if ($body -match '(?s)if\s*\(\$edit\s+-and\s+\$edit\.TimedOut\)\s*\{(.*?)\n\}') { $Matches[1] } else { '' }
Assert-True ($editTimeout -ne '') 'the write has a timeout branch of its own, ahead of the failure branch'
Assert-True ($editTimeout -match 'DOES NOT KNOW') 'it says the run does not know whether the claim landed, rather than that it failed'
Assert-True ((Get-CodeOnly -Block $editTimeout) -match '\bexit\b') 'and it DOES stop -- unlike the read-back, nothing about this write is known'
Assert-True ($editTimeout -match 'already yours') 'while naming the safe way out: re-running reports an already-landed claim as already yours'
# The failure branch must not swallow the timeout case by running first.
Assert-True ($body.IndexOf('$edit.TimedOut') -lt $body.IndexOf('the claim failed')) 'the timeout branch is tested BEFORE the generic failure branch, or it could never be reached'

# ...and the closing verdict must not contradict the warning it sits under: an unconditional
# '[OK] claimed' there asserts exactly what the read-back failed to establish.
Assert-True ($body -match '\$confirmed\s*=\s*if\s*\(\$landed\)') 'the headline distinguishes a confirmed claim from an unconfirmed one'
Assert-True ($body -match "claimed for '\`$\(\`$identity\.Account\)'\`$confirmed") 'and the OK line carries that distinction rather than asserting the claim landed'

# The title is the one field on the issue that a stranger writes, and this script prints it twice.
Assert-True ($body -notmatch '\$\(\$facts\.title\)') 'the issue title is never printed straight from the tracker'

# The defect #1485 measured is a SILENCE, so nothing behavioural can catch its return: a fresh claim
# that prints only its verdict passes every test above, and the session that reads it stops and asks.
# Both sibling verdicts point forward; a later edit trimming either one is what this holds.
Assert-True ($body -match 'open the branch \(new-branch\)') 'the fresh-claim verdict says what follows a successful claim'
Assert-True ($body -match 'read the branch and its document') 'the already-yours verdict still says what follows a resume'

# --- THE FOURTH PICKUP SIGNAL: A FIX PARKED ON A BRANCH WITH NO PR (#1853) ------------------------
#
# The four functions below are the pure half of a check whose other half is git. Same split, and the
# same reason, as everything above: the git calls need a checkout with a remote, other people's
# branches on it and a fetch that reaches the network, so a suite can either assert nothing or assert
# the wrong thing. The pattern, the two parses and the report are pure, and they carry every decision
# the check makes about what is worth saying.

Write-Host ''
Write-Host 'Get-IssueMentionPattern -- the three spellings, and the one that must not match (#1853)' -ForegroundColor Cyan

Assert-True ((Get-IssueMentionPattern -Issue 0) -eq '') 'issue 0 yields no pattern, so the caller scans nothing'
Assert-True ((Get-IssueMentionPattern -Issue -3) -eq '') 'a negative number yields no pattern either'

$pat1853 = Get-IssueMentionPattern -Issue 1853
# .NET's regex is a superset of POSIX ERE for these constructs, so the pattern git will be handed can
# be exercised here directly. THREE SPELLINGS, and each is a real shape this workflow writes.
Assert-True ('fixed here rather than left filed (#1853, inside scope)' -cmatch $pat1853) 'a body reference (#1853) matches'
Assert-True ('fix(1853): repair the pickup check' -cmatch $pat1853) 'the conventional-commit scope (1853) matches'
Assert-True ('park: fix/1853-parked-fix-scan (the branch files only)' -cmatch $pat1853) 'a branch name in a subject (/1853-) matches -- the only shape a freshly parked branch has'
Assert-True ('#1853' -cmatch $pat1853) 'a reference at the very end of the message matches'

# THE NOISE THIS EXISTS TO KEEP OUT, and the assert that would fail if the trailing class were dropped.
Assert-True (-not ('closes #18530 at last' -cmatch $pat1853)) 'a LONGER number starting with these digits does not match'
Assert-True (-not ('fix(18530): something else' -cmatch $pat1853)) 'nor does it in the commit scope'
Assert-True (-not ('release 1853 items shipped' -cmatch $pat1853)) 'a bare number with no #, ( or / is not a reference'
Assert-True (-not ('fix(1852): the neighbour' -cmatch $pat1853)) 'a different issue does not match'

Write-Host ''
Write-Host 'ConvertFrom-CommitScanLog -- reading git log without trusting its shape (#1853)' -ForegroundColor Cyan

$US = [string][char]0x1F
Assert-True (@(ConvertFrom-CommitScanLog -Text '').Count -eq 0) 'empty input is an empty array, not a crash'
Assert-True (@(ConvertFrom-CommitScanLog -Text "   `n  ").Count -eq 0) 'whitespace-only input yields nothing'

$twoLines = "abc1234${US}fix(1853): repair it`ndef5678${US}park: fix/1853-x (the branch files only)"
$parsedTwo = @(ConvertFrom-CommitScanLog -Text $twoLines)
Assert-True ($parsedTwo.Count -eq 2) 'two log lines become two records'
Assert-True ($parsedTwo[0].Sha -eq 'abc1234') 'the sha is the field before the separator'
Assert-True ($parsedTwo[0].Subject -eq 'fix(1853): repair it') 'the subject is the field after it'

# A LINE WITH NO SEPARATOR IS SKIPPED rather than becoming a commit with no sha -- git writes progress
# and hints that a caller not discarding stderr would otherwise hand in here.
$withNoise = "warning: some git hint`nabc1234${US}fix(1853): repair it"
Assert-True (@(ConvertFrom-CommitScanLog -Text $withNoise).Count -eq 1) 'a line carrying no separator is skipped'
Assert-True (@(ConvertFrom-CommitScanLog -Text "${US}subject with no sha").Count -eq 0) 'a record with an empty sha is skipped too'

# THE COUNT ON THE SPLIT IS LOAD-BEARING: a subject may contain anything, and without the 2 the tail
# after a second separator would be silently dropped.
$oddSubject = "abc1234${US}fix: a | b`tc: d${US}tail"
$parsedOdd = @(ConvertFrom-CommitScanLog -Text $oddSubject)
Assert-True ($parsedOdd.Count -eq 1) 'a subject containing pipes, tabs and colons is one record'
Assert-True ($parsedOdd[0].Subject -eq "fix: a | b`tc: d${US}tail") 'and everything after the FIRST separator is kept, tail included'

Assert-True (@(ConvertFrom-CommitScanLog -Text "abc1234${US}one`r`ndef5678${US}two").Count -eq 2) 'CRLF captures parse the same as LF ones'

Write-Host ''
Write-Host 'Get-ContainingBranchNames -- cleaning git branch -a --contains (#1853)' -ForegroundColor Cyan

$branchText = @(
    '  fix/1853-parked-fix-scan',
    '* main',
    '+ feat/held-by-a-worktree',
    '  remotes/origin/fix/1853-parked-fix-scan',
    '  remotes/origin/feat/somebody-else',
    '  remotes/origin/HEAD -> origin/main'
) -join "`n"

$cleaned = @(Get-ContainingBranchNames -Text $branchText -Exclude @('main', 'origin/main'))
Assert-True ($cleaned -contains 'feat/held-by-a-worktree') "the '+' worktree marker is stripped, not treated as part of the name"
Assert-True ($cleaned -contains 'origin/feat/somebody-else') "the 'remotes/' prefix is stripped to the spelling a reader can paste"
Assert-True (-not ($cleaned -contains 'main')) 'an excluded branch is dropped'
Assert-True (@($cleaned | Where-Object { $_ -match '->' }).Count -eq 0) 'the symbolic origin/HEAD line is dropped rather than named twice'
Assert-True (@(Get-ContainingBranchNames -Text '  (HEAD detached at abc1234)').Count -eq 0) 'a detached HEAD is not a branch'
Assert-True (@(Get-ContainingBranchNames -Text '').Count -eq 0) 'empty input is an empty array'

# THE CURRENT BRANCH IS WHAT THE CALLER EXCLUDES ON A RESUME, and reporting a session's own commits
# back to it as somebody else's parked work is the fastest way to teach it to skip this warning.
$onlyMine = @(Get-ContainingBranchNames -Text $branchText -Exclude @('main', 'origin/main', 'fix/1853-parked-fix-scan', 'origin/fix/1853-parked-fix-scan'))
Assert-True (-not ($onlyMine -contains 'fix/1853-parked-fix-scan')) 'the current branch is excludable in its local spelling'
Assert-True (-not ($onlyMine -contains 'origin/fix/1853-parked-fix-scan')) 'and in its remote one'

# CASE-SENSITIVELY, because git refs are: 'Main' and 'main' are two branches, and dropping the wrong
# one would hide real parked work.
Assert-True (@(Get-ContainingBranchNames -Text '  Main' -Exclude @('main')) -contains 'Main') "exclusion is case-sensitive, as git refs are"

$dupText = "  feat/x`n  feat/x`n  remotes/origin/a"
$deduped = @(Get-ContainingBranchNames -Text $dupText)
Assert-True ($deduped.Count -eq 2) 'a name listed twice appears once'
Assert-True ($deduped[0] -eq 'feat/x' -and $deduped[1] -eq 'origin/a') 'and the order is sorted, so two runs print the same line'

# THE LOCAL/REMOTE FOLD. A checkout holding a local copy of a parked branch gets both spellings from
# `git branch -a --contains`, and they are ONE piece of work -- counting both inflates the single
# number this report exists to give.
$twinText = "  feat/x`n  remotes/origin/feat/x`n  remotes/origin/other"
$folded = @(Get-ContainingBranchNames -Text $twinText)
Assert-True ($folded.Count -eq 2) 'a local branch and its own remote-tracking twin count once'
Assert-True ($folded -contains 'origin/feat/x') 'and the REMOTE spelling is the one kept -- it is the address that is true for anybody'
Assert-True (-not ($folded -contains 'feat/x')) 'so the bare local name is folded away'
Assert-True (@(Get-ContainingBranchNames -Text "  feat/local-only") -contains 'feat/local-only') 'a branch with no twin keeps its own name'
# A SECOND REMOTE IS NOT A TWIN: a local branch tracking 'upstream' is indistinguishable here from two
# unrelated branches sharing a name, so the fold deliberately only knows 'origin/'.
$otherRemote = @(Get-ContainingBranchNames -Text "  feat/x`n  remotes/upstream/feat/x")
Assert-True ($otherRemote.Count -eq 2) 'a non-origin remote folds nothing -- it cannot be told from two unrelated branches'

Write-Host ''
Write-Host 'Format-ParkedFixReport -- what is worth saying, and what is not (#1853)' -ForegroundColor Cyan

Assert-True (@(Format-ParkedFixReport -Issue 1853 -Findings @()).Count -eq 0) 'no findings means no lines at all, not an empty header'

$noBranches = @([pscustomobject]@{ Sha = 'abc'; Subject = 'x'; Branches = @() })
Assert-True (@(Format-ParkedFixReport -Issue 1853 -Findings $noBranches).Count -eq 0) 'a finding whose branches were all excluded is dropped, not printed as a commit in no branch'

$oneFinding = @([pscustomobject]@{ Sha = 'f686b0af3fda'; Subject = 'fix(1842): apply the parallel review findings'; Branches = @('origin/feat/1842-unify-prio-labels-bwj') })
$oneReport = @(Format-ParkedFixReport -Issue 1847 -Findings $oneFinding)
Assert-True ($oneReport.Count -gt 0) 'a real finding produces a report'
Assert-True ($oneReport[0] -match '1 commit on 1 branch') 'the lead line counts in the singular for one of each'
Assert-True (@($oneReport | Where-Object { $_ -match 'origin/feat/1842-unify-prio-labels-bwj' }).Count -eq 1) 'the branch is named once, as its own line'
Assert-True (@($oneReport | Where-Object { $_ -match 'f686b0af  fix\(1842\)' }).Count -eq 1) 'the commit is abbreviated to 8 characters and keeps its subject'
Assert-True (@($oneReport | Where-Object { $_ -match 'cannot tell a fix from a mention' }).Count -eq 1) 'the report says what it does not know, so it cannot be read as a verdict'

# GROUPED BY BRANCH, which is the unit the reader acts on. A commit on two branches belongs under both:
# that is the answer to "which of these do I look at", not duplication.
$shared = @([pscustomobject]@{ Sha = 'aaaaaaaa11'; Subject = 'fix(1853): one'; Branches = @('origin/feat/b', 'origin/feat/a') })
$sharedReport = @(Format-ParkedFixReport -Issue 1853 -Findings $shared)
Assert-True ($sharedReport[0] -match '1 commit on 2 branches') 'the lead line counts commits and branches separately'
$branchLines = @($sharedReport | Where-Object { $_ -match '^  origin/feat/' })
Assert-True ($branchLines.Count -eq 2) 'a commit on two branches is listed under both'
Assert-True ($branchLines[0] -match 'origin/feat/a') 'and the branches come out sorted'

# THE CAP IS WHAT KEEPS THIS A WARNING RATHER THAN A WALL: a branch cut for this issue writes its
# number into every commit subject, so a week-old one matches dozens of times.
$many = @(1..5 | ForEach-Object { [pscustomobject]@{ Sha = "sha00000$_"; Subject = "fix(1853): step $_"; Branches = @('origin/fix/1853-x') } })
$capped = @(Format-ParkedFixReport -Issue 1853 -Findings $many -MaxCommitsPerBranch 2)
Assert-True (@($capped | Where-Object { $_ -match '^      sha00000' }).Count -eq 2) 'only the capped number of commits is listed'
Assert-True (@($capped | Where-Object { $_ -match 'and 3 more naming #1853' }).Count -eq 1) 'the overflow is named rather than silently hidden'
Assert-True ($capped[0] -match '5 commits on 1 branch') 'and the lead line still counts all of them'

$capZero = @(Format-ParkedFixReport -Issue 1853 -Findings $many -MaxCommitsPerBranch 0)
Assert-True (@($capZero | Where-Object { $_ -match '^      sha00000' }).Count -eq 1) 'a cap below 1 still shows one example -- a branch with nothing under it says nothing'

Write-Host ''
Write-Host 'The parked-fix scan inside claim-issue.ps1 (#1853)' -ForegroundColor Cyan

# The block a suite can hold: everything between its own heading and the verdict switch it sits above.
$scan = if ($body -match '(?s)# --- IS THE FIX ALREADY SITTING ON A BRANCH \(issue #1853\).*?\n(.*?)\nswitch \(\$verdict\.Code\)') { $Matches[1] } else { '' }
Assert-True ($scan -ne '') 'the scan block is present, above the verdict switch'

# IT RUNS ONLY WHERE THERE IS SOMETHING TO SAVE. Gated on the verdict, so a closed or taken issue --
# both of which exit in the switch below -- pays nothing for an answer it would not use, while a RESUME
# ('skip') gets it, which is the case Chris's own body calls picking up.
Assert-True ($scan -match "\`$verdict\.Action\s+-eq\s+'claim'") 'the scan runs on a fresh claim'
Assert-True ($scan -match "\`$verdict\.Action\s+-eq\s+'skip'") 'and on a resume, where the other session is the only trace there is'

# ADVISORY, NEVER A REFUSAL (#1485): a claim that blocks costs the whole assignment, and this check
# cannot tell a fix from a mention. An `exit` added here would be that rule broken in one line, on a
# path no behavioural test can reach.
Assert-True ($scan -notmatch '(?m)^\s*exit\s') 'nothing in the scan exits -- the claim stands whatever it finds'
Assert-True ($scan -notmatch 'REFUSED') 'and it never speaks in the refusal vocabulary'

# THE NETWORK CALL IS BOUNDED like every other one in this family (#1639): a stall here is a session
# that never starts, which is precisely what the claim step exists to prevent.
Assert-True ($scan -match "(?s)'fetch'.*?-TimeoutSeconds\s+\`$NativeCaptureNetworkTimeoutSeconds") 'the fetch is bounded'
Assert-True ($scan -match '\$staleNote') 'a fetch that did not answer is reported rather than read as a clean scan'

# AND THE FETCH KEEPS STDERR, which is this family's standing decision rather than this script's taste
# (#1313): a git call to a remote writes everything to stderr, git redacts the credential out of it
# itself, and nothing here parses the capture -- so discarding it would remove git's own reason from the
# one failure path a reader cannot diagnose from an exit code. The two reads below it DO parse and keep
# the flag, so the assert is on the fetch statement alone rather than on the block.
$fetchCall = if ($scan -match "(?s)(\`$fetch\s*=\s*Invoke-NativeCapture.*?)\n\s*if\s*\(") { $Matches[1] } else { '' }
Assert-True ($fetchCall -ne '') 'the fetch statement is findable'
Assert-True ($fetchCall -notmatch '-DiscardStderr') "the fetch keeps git's own diagnosis (#1313), unlike the two reads that parse"
Assert-True ($scan -match '\$staleDetail') 'and those lines are actually printed -- keeping stderr and never showing it is the same loss one step later'

# BOTH UNTRUSTED FIELDS GO THROUGH THE ONE SANITISER. A commit subject and a ref name come from the
# same place -- anyone who can push -- and the branch name was the half printed raw.
Assert-True ($scan -match '(?s)Subject\s*=\s*\(Format-ForConsole') 'the commit subject is stripped before printing'
Assert-True ($scan -match '(?s)Branches\s*=\s*@\(\$branches\s*\|\s*ForEach-Object\s*\{\s*Format-ForConsole') 'and so is every branch name'

# WITHOUT A TRUNK REF TO SUBTRACT, `git log --all` reports the issue's own merged repair on the trunk --
# the noise that teaches a reader to skip the warning. So: no trunk ref, no scan.
Assert-True ($scan -match '\$trunkRefs\.Count\s+-gt\s+0') 'the scan is skipped where no trunk ref could be verified'
Assert-True ($scan -match "'--not'") 'and the trunk is subtracted from the log it reads'
Assert-True ($scan -match '\$currentBranch') "the session's own branch is excluded, so a resume is not warned about itself"

# THE CONTAINMENT LOOP IS BOUNDED, and Format-ParkedFixReport's display cap does NOT bound it -- that
# one trims what is PRINTED, after every commit has already paid for its own ancestry walk. A branch
# whose every subject carries the number (the convention is `fix(<n>): ...`) is the shape that runs
# away, and one issue in this repo's history is named by 21 commits.
Assert-True ($scan -match '\$maxContainmentReads\s*=\s*[0-9]+') 'the per-commit containment reads have a stated ceiling'
Assert-True ($scan -match 'Select-Object\s+-First\s+\$maxContainmentReads') 'and the loop actually honours it'
Assert-True ($scan -match 'were resolved to a branch') 'a truncation says so -- a cap a reader cannot see is the defect this check exists to remove, one layer in'
# $matches is a PowerShell automatic variable; assigning to it inside a script that also uses -match
# is the kind of collision that produces a wrong answer rather than an error.
Assert-True ($scan -notmatch '\$matches\s*=') 'the match list does not shadow the automatic $Matches'

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
