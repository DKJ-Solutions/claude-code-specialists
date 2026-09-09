<#
.SYNOPSIS
    Tests for plugins/dkj-policy/hooks/guard-working-copy.ps1 -- the PreToolUse hook that refuses a
    dispatched subagent the git commands which discard the dispatching session's working copy.

.DESCRIPTION
    THE JUDGEMENT IS NOT TESTED HERE. It is a pure function with a suite of its own
    (working-copy-guard-lib.tests.ps1, 92 cases in-process). What needs a real invocation is
    everything this file adds on top: the gate, the exit codes, the refusal text, and the two ways it
    deliberately fails OPEN.

    FIVE GROUPS.
      1. THE GATE, which is the whole design. #1669 raised the objection against itself -- a hook
         cannot tell the DevOps specialist's legitimate `git checkout` from a dispatched reviewer's
         illegitimate one. It can: agent_id is present only inside a subagent. Both directions are
         asserted on the SAME command, because that is the claim: identical text, opposite verdicts.
      2. agent_type IS NOT THE GATE. Claude Code's schema says it is present on the main thread of an
         --agent session, without agent_id. A payload shaped like that must pass, or the guard would
         refuse the main thread of every such session. No incident produced this case; the vendor's
         own field documentation did, which is why it is asserted rather than trusted.
      3. The two deliberate fail-OPEN paths: a payload that cannot be read, and a missing lib. Both
         mean "cannot tell", and answering that with a block would refuse the orchestrator's own git
         commands the moment the contract moves or an install breaks. The prose block still stands
         under both.
      4. The refusal TEXT, because a sentence nothing asserts is a sentence the next edit removes --
         the reason guard-live-theme.tests.ps1 gives for asserting its own. Three things have to be in
         it: the read-only alternatives, that a need for another state is a sentence in a deliverable
         rather than a command, and that authoring the rule is already exempt.
      5. THE FAST PATH'S COUNTER-CASE. The hook string-tests the raw payload for "agent_id" before
         loading any lib, because it fires on every Bash call and 8089 of the 9084 in this repo's
         transcripts are the main thread's (675 ms -> 437 ms). A command whose own TEXT contains that
         string must still be judged as the main thread -- the fast path may only ever cause more
         work, never a different verdict.

    Pure ASCII (repo convention for .ps1).
#>
# 'Continue', not 'Stop': the guard writes its refusal to stderr, and PowerShell 5.1 turns native
# stderr from a child process into a terminating NativeCommandError when the preference is 'Stop'.
# That stderr IS the expected output of a blocking case, so it must not end the run.
$ErrorActionPreference = 'Continue'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Guard    = Join-Path $RepoRoot 'plugins\dkj-policy\hooks\guard-working-copy.ps1'
# Fixture paths carry $PID: the test gate is a throttled PARALLEL scheduler, so two runs at one fixed
# temp path tear down each other's tree mid-assert.
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "guard-working-copy-$PID-$([guid]::NewGuid().ToString('n'))"

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red }
}

function New-Payload {
    <# The shape the harness sends, built rather than typed. #>
    param([string]$Command, [string]$AgentId = '', [string]$AgentType = '', [string]$Cwd = 'C:\work\myrepo')
    $p = @{
        hook_event_name = 'PreToolUse'; session_id = 's1'; cwd = $Cwd
        tool_name = 'Bash'; tool_use_id = 'tu1'; tool_input = @{ command = $Command }
    }
    if ($AgentId)   { $p.agent_id   = $AgentId }
    if ($AgentType) { $p.agent_type = $AgentType }
    return ($p | ConvertTo-Json -Compress -Depth 5)
}

function Invoke-Guard {
    <# Returns @{ Code; Out }. CLAUDE_PROJECT_DIR is set per call, because the guard reads it to know
       which tree it is protecting. #>
    param([string]$Payload, [string]$Root = 'C:\work\myrepo', [string]$GuardPath = $null)
    if (-not $GuardPath) { $GuardPath = $Guard }
    $prev = $env:CLAUDE_PROJECT_DIR
    $env:CLAUDE_PROJECT_DIR = $Root
    try {
        $out = $Payload | & powershell -NoProfile -ExecutionPolicy Bypass -File $GuardPath 2>&1
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = (($out | ForEach-Object { "$_" }) -join "`n") }
    } finally {
        if ($null -eq $prev) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prev }
    }
}

try {
    Write-Host "== guard-working-copy ==" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "-- group 1: the gate -- identical text, opposite verdicts" -ForegroundColor Cyan

    foreach ($cmd in @('git checkout main', 'git stash', 'git reset --hard HEAD',
                       'git checkout HEAD -- scripts/lib/gate-lib.ps1', 'git clean -fd')) {
        Assert-Equal 0 (Invoke-Guard (New-Payload -Command $cmd)).Code                    "main thread may run: $cmd"
        Assert-Equal 2 (Invoke-Guard (New-Payload -Command $cmd -AgentId 'a1')).Code      "a dispatched subagent may not: $cmd"
    }

    foreach ($cmd in @('git status --short', 'git diff main...HEAD', 'git stash list', 'git log --oneline')) {
        Assert-Equal 0 (Invoke-Guard (New-Payload -Command $cmd -AgentId 'a1')).Code      "a subagent may still read: $cmd"
    }

    Write-Host ""
    Write-Host "-- group 2: agent_type is NOT the gate" -ForegroundColor Cyan

    # An --agent session's main thread: agent_type present, agent_id absent. It must pass.
    Assert-Equal 0 (Invoke-Guard (New-Payload -Command 'git checkout main' -AgentType 'my-custom-agent')).Code `
        'an --agent session main thread (agent_type, no agent_id) is NOT a subagent'
    # And with both, it is a subagent.
    Assert-Equal 2 (Invoke-Guard (New-Payload -Command 'git checkout main' -AgentId 'a1' -AgentType 'my-custom-agent')).Code `
        'with agent_id beside it, the same payload IS a subagent'

    Write-Host ""
    Write-Host "-- group 3: the two deliberate fail-OPEN paths" -ForegroundColor Cyan

    Assert-Equal 0 (Invoke-Guard 'git checkout main').Code `
        'a payload that is not JSON at all is treated as the main thread'
    Assert-Equal 0 (Invoke-Guard '{"hook_event_name":"PreToolUse"').Code `
        'and so is a truncated one'
    Assert-Equal 0 (Invoke-Guard (New-Payload -Command '')).Code `
        'an empty command is allowed rather than erroring'

    # A copy of the hook with no lib beside it: a broken install must not brick every shell command.
    New-Item -ItemType Directory -Force -Path (Join-Path $Fixture 'hooks') | Out-Null
    $orphan = Join-Path $Fixture 'hooks\guard-working-copy.ps1'
    Copy-Item -LiteralPath $Guard -Destination $orphan
    $r = Invoke-Guard (New-Payload -Command 'git checkout main' -AgentId 'a1') -GuardPath $orphan
    Assert-Equal 0 $r.Code 'a MISSING lib fails open rather than blocking every command'
    Assert-True ($r.Out -match 'the working-copy guard is OFF for this call') `
        'and says so on stderr, so the hole is visible rather than silent'

    Write-Host ""
    Write-Host "-- group 4: the refusal text" -ForegroundColor Cyan

    $r = Invoke-Guard (New-Payload -Command 'git stash' -AgentId 'a1' -AgentType 'dkj-team-alpha:victor')
    Assert-Equal 2 $r.Code 'the refusal blocks'
    Assert-True ($r.Out -match 'BLOCKED \(guard-working-copy\)') 'and names itself'
    Assert-True ($r.Out -match 'dkj-team-alpha:victor')          'and names WHICH specialist was stopped'
    Assert-True ($r.Out -match 'git diff <ref>\.\.\.HEAD')       'and offers the read-only alternative'
    Assert-True ($r.Out -match 'git worktree add')               'and says a second checkout is not blocked'
    Assert-True ($r.Out -match 'a sentence in your') `
        'and says a genuine need for another state is a sentence in the deliverable, not a command'
    Assert-True ($r.Out -match 'no marker or flag that') `
        'and says plainly that nothing authorises it -- unlike guard-live-theme, this has no escape'
    Assert-True ($r.Out -match 'WRITING THIS RULE INTO A FILE') `
        'and tells an AUTHOR that writing the rule is already exempt'

    # Without agent_type there is still a refusal, and it still reads as a sentence.
    $r = Invoke-Guard (New-Payload -Command 'git stash' -AgentId 'a1')
    Assert-True ($r.Out -match 'a dispatched subagent') 'with no agent_type the refusal still names the caller generically'

    Write-Host ""
    Write-Host "-- group 5: the fast path may cause more work, never a different verdict" -ForegroundColor Cyan

    # The pre-gate is a string test on the raw payload. A command whose own text contains the key must
    # still be judged by the real parse -- which says main thread.
    Assert-Equal 0 (Invoke-Guard (New-Payload -Command 'grep -rn ''"agent_id":'' plugins/ && git checkout main')).Code `
        'a main-thread command whose TEXT contains the agent_id key is still the main thread'
    Assert-Equal 2 (Invoke-Guard (New-Payload -Command 'grep -rn ''"agent_id":'' plugins/ && git checkout main' -AgentId 'a1')).Code `
        'and the same command from a subagent is still refused'
} finally {
    Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Summary: $script:pass passed, $script:fail failed" -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
