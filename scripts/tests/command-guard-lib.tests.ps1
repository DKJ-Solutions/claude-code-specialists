<#
.SYNOPSIS
    Tests for scripts/lib/command-guard-lib.ps1 -- the false-positive machinery a PreToolUse command
    guard needs, and the payload contract it reads.

.DESCRIPTION
    THIS LIB IS TESTED SEPARATELY FROM ITS CALLER ON PURPOSE. It carries no knowledge of git or of any
    other CLI, and it exists to serve MORE than one guard: dkj-team-shopify's guard-live-theme.ps1 is
    the reason the machinery is worth sharing at all, and the route for it to adopt this file is a
    second registry entry rather than a rewrite. A lib with a second caller ahead of it needs its own
    suite, or the day that caller arrives the only coverage will be the first caller's cases.

    FOUR GROUPS.
      1. The payload contract, and the ONE field that decides. agent_id is present only inside a
         dispatched subagent; agent_type is present there AND on the main thread of an --agent session,
         which is why gating on it would be wrong. Both are read; only one is a gate, and that is a
         property of this lib rather than of its caller.
      2. Bodies that are DATA are stripped -- heredocs and here-strings -- because that is how a repo
         writes its own safety rules into a file. This is the group guard-live-theme paid for in the
         field.
      3. Group 2 must not become a hole: a heredoc an interpreter consumes, a here-string handed to
         Invoke-Expression, and text piped into a shell are all still scanned. AN EXEMPTION WITHOUT A
         COUNTER-CASE IS A HOLE WITH A COMMENT ON IT.
      4. Interpreter wrappers are re-scanned. A '-c' string is a command in its own right, and the
         wrapper is precisely what a permission deny rule cannot see.

    -TextTools IS REQUIRED, AND ITS ABSENCE IS ASSERTED. The two guards in this repo disagree about
    `git`, so a default would be wrong for one of them; that is a design decision, and a design
    decision nothing asserts is one the next edit removes.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $RepoRoot 'scripts\lib\command-guard-lib.ps1')

$script:pass = 0
$script:fail = 0
$LF = "`n"

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

# A caller's exempt set. `git` is deliberately NOT in it, which is the working-copy guard's set rather
# than the Shopify guard's -- see this lib's header for why there is no shared default.
$TextTools = @('echo', 'cat', 'grep', 'sed', 'printf', 'out-file', 'set-content')

function Test-Reaches {
    <# Does any segment the pipeline hands back contain this text? That is the question a caller asks,
       expressed without any caller's own matcher. #>
    param([string]$Command, [string]$Needle)
    foreach ($s in (Get-GuardSegments -Command $Command -TextTools $TextTools)) {
        if ($s -match [regex]::Escape($Needle)) { return $true }
    }
    return $false
}

Write-Host "== command-guard-lib ==" -ForegroundColor Cyan

Write-Host ""
Write-Host "-- group 1: the payload contract" -ForegroundColor Cyan

$mainPayload = @{
    hook_event_name = 'PreToolUse'; session_id = 's1'; cwd = 'C:\repo'
    tool_name = 'Bash'; tool_input = @{ command = 'git status' }
} | ConvertTo-Json -Compress -Depth 5
$p = Get-HookCommandPayload $mainPayload
Assert-Equal 'git status' $p.Command 'the command comes out of tool_input.command'
Assert-Equal ''           $p.AgentId 'the main thread carries no agent_id'
Assert-Equal 'C:\repo'    $p.Cwd     'cwd is read, because it is where the command starts'
Assert-True  $p.Parsed               'a well-formed payload reports Parsed'

$subPayload = @{
    hook_event_name = 'PreToolUse'; session_id = 's1'; cwd = 'C:\repo'; agent_id = 'a1'
    agent_type = 'dkj-team-alpha:victor'; tool_name = 'Bash'; tool_input = @{ command = 'git status' }
} | ConvertTo-Json -Compress -Depth 5
$p = Get-HookCommandPayload $subPayload
Assert-Equal 'a1' $p.AgentId 'a dispatched subagent carries agent_id -- the gate'
Assert-Equal 'dkj-team-alpha:victor' $p.AgentType 'agent_type is read too, to NAME who was stopped'

# THE --agent SESSION, which is the whole reason agent_type is not the gate. Claude Code's own schema:
# agent_type is present "on the main thread of a session started with --agent (without agent_id)".
$agentSession = @{
    hook_event_name = 'PreToolUse'; session_id = 's1'; cwd = 'C:\repo'
    agent_type = 'my-custom-agent'; tool_name = 'Bash'; tool_input = @{ command = 'git checkout main' }
} | ConvertTo-Json -Compress -Depth 5
$p = Get-HookCommandPayload $agentSession
Assert-Equal ''                 $p.AgentId   'an --agent session main thread has agent_type but NO agent_id'
Assert-Equal 'my-custom-agent'  $p.AgentType 'and its agent_type is still readable'

# An unparseable payload falls back to the raw text for the COMMAND, so a contract that changes shape
# fails towards checking. AgentId gets no such fallback: there is no raw text that could stand in for
# a structured field, and inventing one would either block the main thread or open the gate.
$p = Get-HookCommandPayload 'git checkout main'
Assert-Equal 'git checkout main' $p.Command 'an unparseable payload falls back to the raw text'
Assert-Equal ''                  $p.AgentId 'and reports no agent_id rather than guessing one'
Assert-True  (-not $p.Parsed)               'and says it did not parse'

$p = Get-HookCommandPayload ''
Assert-Equal '' $p.Command 'an empty payload is empty rather than an error'

Write-Host ""
Write-Host "-- group 2: bodies that are data are stripped" -ForegroundColor Cyan

Assert-True (-not (Test-Reaches "cat > rules.md <<'EOF'${LF}never run shopify theme publish${LF}EOF" 'publish')) `
    'a heredoc body is stripped -- writing the rule into a file is not running it'
Assert-True (-not (Test-Reaches "`$doc = @'${LF}never run shopify theme delete${LF}'@${LF}`$doc | Out-File notes.md" 'delete')) `
    'a here-string body is stripped for the same reason'
Assert-True (-not (Test-Reaches 'echo "shopify theme publish is forbidden"' 'publish')) `
    'a segment led by a text tool is skipped'
Assert-True (-not (Test-Reaches 'grep -rn "theme publish" docs/' 'publish')) `
    'and so is a search for the words'

Write-Host ""
Write-Host "-- group 3: the counter-cases that make group 2 safe" -ForegroundColor Cyan

Assert-True (Test-Reaches "bash <<'EOF'${LF}shopify theme publish${LF}EOF" 'publish') `
    'a heredoc an INTERPRETER consumes is a script, and is not stripped'
Assert-True (Test-Reaches "`$s = @'${LF}shopify theme publish${LF}'@${LF}Invoke-Expression `$s" 'publish') `
    'a here-string handed to Invoke-Expression is not stripped'
Assert-True (Test-Reaches "`$s = @'${LF}shopify theme publish${LF}'@${LF}iex `$s" 'publish') `
    'nor one handed to the iex alias'
Assert-True (Test-Reaches 'echo "shopify theme publish" | bash' 'publish') `
    'text piped into a shell executes, so no text-tool exemption applies'
Assert-True (Test-Reaches 'cat cmds.txt | xargs -I{} sh -c "{}"' 'xargs') `
    'xargs switches the exemptions off as well'
Assert-True (Test-Reaches 'echo hi && shopify theme publish' 'publish') `
    'a real command beside a harmless one is still seen'
# An unclosed here-string body is PUT BACK rather than dropped: without that, an opener with no closer
# would strip everything after it to the end of the command.
Assert-True (Test-Reaches "`$s = @'${LF}shopify theme publish" 'publish') `
    'an UNCLOSED here-string body is put back, so nothing can hide behind one'

Write-Host ""
Write-Host "-- group 4: interpreter wrappers are re-scanned" -ForegroundColor Cyan

Assert-Equal 'git reset --hard' (Get-InterpreterScriptBody 'bash -c "git reset --hard"') `
    "bash -c's body is handed back for scanning"
Assert-Equal 'git checkout main' (Get-InterpreterScriptBody 'powershell -Command "git checkout main"') `
    "powershell -Command's body too"
Assert-Equal $null (Get-InterpreterScriptBody 'bash ./deploy.sh') `
    'a script FILE is not a body -- its contents cannot be read, and this says so rather than pretending'
Assert-Equal $null (Get-InterpreterScriptBody 'git checkout main') `
    'a plain command is not a wrapper'
Assert-True (Test-Reaches 'bash -c "shopify theme publish"' 'publish') `
    'so the wrapper vector a permission deny rule cannot see is reached'
Assert-True (Test-Reaches 'bash -c "pwsh -Command ''shopify theme publish''"' 'publish') `
    'and one nesting of it as well'

Write-Host ""
Write-Host "-- the required parameter" -ForegroundColor Cyan

$threw = $false
try { Get-GuardSegments -Command 'echo hi' | Out-Null } catch { $threw = $true }
Assert-True $threw '-TextTools is mandatory: there is no shared default, because the two callers disagree about git'

Write-Host ""
Write-Host "-- the pieces, directly" -ForegroundColor Cyan

Assert-Equal 'git'  (Get-LeadingCommand '  git checkout main') 'the leading command is found past whitespace'
Assert-Equal 'git'  (Get-LeadingCommand 'FOO=bar git checkout main') 'and past a leading env assignment'
Assert-Equal 'git'  (Get-LeadingCommand '/usr/bin/git checkout main') 'and with its path stripped'
Assert-Equal ''     (Get-LeadingCommand '   ') 'an empty segment has no leading command'
Assert-Equal 3      (Split-CommandSegments 'a && b ; c').Count 'segments split on && and ;'
Assert-True  (Test-CommandExecutesText 'echo x | bash')      'a pipe into a shell executes text'
Assert-True  (Test-CommandExecutesText 'eval "$cmd"')        'and so does eval'
Assert-True  (-not (Test-CommandExecutesText 'git status'))  'an ordinary command does not'

Write-Host ""
Write-Host "Summary: $script:pass passed, $script:fail failed" -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
