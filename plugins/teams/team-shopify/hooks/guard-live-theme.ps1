<#
.SYNOPSIS
    PreToolUse hook: deterministically blocks a write action against the LIVE Shopify theme.

.DESCRIPTION
    Reads the hook JSON from stdin, takes the command out of tool_input.command, and blocks (exit 2)
    when that command is:

      1. a theme PUBLISH -- always. Publishing makes a theme the live customer-facing theme, and no
         marker in a command line can stand in for a human deciding to do that.
      2. a theme DELETE -- always, unless this repo has answered Get-ShopifyThemeDeleteMarker AND the
         command carries that marker. Default (seam unanswered) is the original rule, absolute: what is
         deleted cannot be un-deleted, and whether a preview theme is really spent is a judgement rather
         than a cleanup step. A delete aimed at the LIVE theme id is refused even with the marker.
      3. a theme PUSH aimed at LIVE -- unless explicitly authorised. Aimed at live means the command
         carries '--allow-live' or this repo's own live theme id.

    WHY THIS SHIPS WITH THE TEAM RATHER THAN BEING BUILT PER REPO (inbound #769). Two Shopify
    consumers of this plugin independently built this same guard, and the second had to learn the
    false-positive lesson below from scratch while the first still carries it. The plugin stated the
    rule in prose in three manuals; prose does not stop a command.

    WHAT THIS CLOSES THAT PERMISSIONS CANNOT. A permission rule matches a command PREFIX, so a deny
    entry for the CLI never sees the same command wrapped in a shell invocation -- and a settings file
    that allows both the CLI and a 'powershell -Command "..."' wrapper leaves the exact forbidden
    command reachable by wrapping it. This hook reads the whole command string, and its matcher covers
    both the Bash and the PowerShell tool for that reason.

    ------------------------------------------------------------------------------------------------
    MENTIONING A RULE IS NOT PERFORMING IT, AND THAT LESSON COST THE REPORTING CONSUMER TWO BLOCKED
    COMMANDS ON ITS FIRST DAY. Their first version matched the forbidden words anywhere in the command
    string, and it blocked, in order: the heredoc that wrote the rule into their CLAUDE.md, and the
    perl one-liner that later edited that sentence. Neither would have touched the store. A guard that
    makes its own rule impossible to write down is a guard somebody eventually switches off, which is
    worse than no guard, so the matching asks WHERE the words sit rather than whether they occur:

      - HEREDOC BODIES are stripped. 'cat > file <<EOF ... EOF' writes data and the body never runs.
        UNLESS an interpreter is consuming it ('bash <<EOF'), in which case the body IS a script and
        nothing is stripped.
      - TEXT TOOLS are skipped. A segment whose leading command is grep, sed, perl, awk, cat, echo,
        git and friends is handling text rather than running the CLI. UNLESS the command pipes into an
        interpreter or uses eval/xargs -- 'echo "..." | bash' really does execute, and that override
        is the whole reason the exemption is safe to have.
      - EVERYTHING ELSE is matched per shell segment, so a real command after a heredoc, after a
        semicolon, or inside a wrapper is still caught.

    Every one of those exemptions has a counter-case in the suite, because an exemption without one is
    a hole with a comment on it.

    THE RESIDUAL LIMIT, STATED RATHER THAN HIDDEN. A text tool asked to execute -- 'perl -e' with a
    system() call, say -- is exempted by the rule above and is not caught. That is a deliberate trade:
    the vector needs somebody to go out of their way, while the false positives it would otherwise
    cause happen in ordinary work every time a repo documents its own safety rules.
    ------------------------------------------------------------------------------------------------

    WHAT IT NEEDS FROM THE REPO, AND WHAT IT DOES WITHOUT IT. Two optional functions in the consuming
    repo's scripts/repo-config.ps1:

      Get-ShopifyLiveThemeId     the live theme's numeric id. Absent, the id half of rule 3 cannot
                                 fire -- '--allow-live' still blocks, and a push aimed at live BY ID
                                 passes. That is a real hole, so it is not left silent: the
                                 SessionStart check beside this file reports it once per session.
      Get-ShopifyLivePushMarker  the exact authorisation marker. Absent, any marker ending in
                                 'LIVE-PUSH-AUTHORIZED' is accepted, which is what both existing
                                 consumers already write ('SWB-...' and 'XOXO-...'). Recognise both,
                                 write one.
      Get-ShopifyThemeDeleteMarker  the marker that authorises a THEME DELETE. Absent -- the default --
                                 rule 2 is absolute and no marker exists that could pass it, which is
                                 how this hook behaved before the seam and therefore what an unstated
                                 seam has to keep meaning. Answered, a delete carrying that exact marker
                                 is allowed, EXCEPT one aimed at the live theme id, which is refused
                                 unconditionally. Answering it with the same string as the push marker
                                 also leaves the capability off: see the note beside $DELETE_MARKER.

    AUTHORISING THE DELIBERATE LIVE PUSH. Add the marker as a shell comment to that exact push
    command: '... --allow-live # LIVE-PUSH-AUTHORIZED'. It is a comment in both shells, so it changes
    nothing about what runs, and the hook sees it in the command string.

    WHY A MARKER AND NOT AN ENVIRONMENT VARIABLE. The hook runs as its own process and does not
    inherit an inline env prefix, so a variable would either not arrive or would have to be set
    session-wide -- which is exactly the state that makes a stray push dangerous. A marker authorises
    ONE command, visibly, in the transcript, where a reviewer can see it.

    UNTOUCHED (exit 0): every form of 'theme pull' including --live, since reading is how a pre-task
    sync works; pushes to an unpublished preview theme; and every other command.

    SCOPE. This covers the CLI vector reached through the Bash and PowerShell tools. A publish issued
    through a Shopify MCP connector is a different vector and is NOT covered here -- that one is held
    by the MCP server's own permission prompt.

    Exit codes (PreToolUse contract): 2 = block and send stderr to Claude; 0 = allow.

    Pure ASCII (repo convention for .ps1): Windows PowerShell 5.1 reads a BOM-less script as ANSI.
    Tested by scripts/tests/guard-live-theme.tests.ps1 in the source repo -- change one, run the other.
#>
$ErrorActionPreference = 'Stop'

# --- What the repo answers, if it answers ---------------------------------------------------------
# Dot-sourced in a CHILD scope with StrictMode explicitly OFF: a consumer's repo-config.ps1 is written
# on the assumption that its runtime callers do not set it. Both values have a safe fallback, so a repo
# with no config file at all still gets rules 1 and 2 and the --allow-live half of rule 3.
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$config = & {
    Set-StrictMode -Off
    $answers = @{ LiveThemeId = ''; Marker = ''; DeleteMarker = '' }
    $configPath = Join-Path $args[0] 'scripts\repo-config.ps1'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { return $answers }
    try { . $configPath } catch { return $answers }
    if (Get-Command Get-ShopifyLiveThemeId       -ErrorAction SilentlyContinue) { $answers.LiveThemeId  = [string](Get-ShopifyLiveThemeId) }
    if (Get-Command Get-ShopifyLivePushMarker    -ErrorAction SilentlyContinue) { $answers.Marker       = [string](Get-ShopifyLivePushMarker) }
    if (Get-Command Get-ShopifyThemeDeleteMarker -ErrorAction SilentlyContinue) { $answers.DeleteMarker = [string](Get-ShopifyThemeDeleteMarker) }
    return $answers
} $repoRoot

$LIVE_ID = ([string]$config.LiveThemeId).Trim()
# A NON-NUMERIC ANSWER COUNTS AS NO ANSWER, and this is the counter-case to the seam block that
# adopt-shopify-floor now writes into a consumer's repo-config.ps1. A Shopify theme id is numeric, so
# anything else is a placeholder somebody left behind -- and accepting one would be worse than an absent
# function: the SessionStart check reads a non-empty answer as ANSWERED, so a 'VUL-IN' left in place
# would silence the report while the id half of rule 3 stayed inert. A hole with a comment on it, which
# is the exact failure this guard's own README warns about. Rejecting it here keeps the two in agreement:
# unanswered to the guard is unanswered to the check.
if ($LIVE_ID -and $LIVE_ID -notmatch '^\d+$') { $LIVE_ID = '' }
# THE DEFAULT MARKER IS A SUFFIX RATHER THAN A FULL STRING, which is what makes this work in both
# existing consumers without either of them configuring anything: they write
# 'SWB-LIVE-PUSH-AUTHORIZED' and 'XOXO-LIVE-PUSH-AUTHORIZED', and both end in the default. A repo that
# wants only its own spelling accepted sets the seam.
$MARKER = if (([string]$config.Marker).Trim()) { ([string]$config.Marker).Trim() } else { 'LIVE-PUSH-AUTHORIZED' }

# THE DELETE MARKER HAS NO DEFAULT, AND THAT ASYMMETRY WITH $MARKER ABOVE IS THE WHOLE DESIGN.
# A push marker needs a fallback because both existing consumers already write one and rule 3 has to keep
# working unconfigured. Nobody writes a delete marker, because until now no marker could authorise a
# delete at all -- so a default here would hand every consumer a capability they never asked for, on the
# next plugin update, silently. An unstated seam has to mean UNCHANGED, and unchanged for a delete is
# 'always denied'. So: empty answer -> the capability is off -> rule 2 stays exactly as it was.
#
# WHICH MAKES THIS OPT-IN PER REPO, deliberately. A repo that wants a session to be able to clear away
# its own spent preview themes says so, in its own words, once. Everyone else keeps the old rule and
# never reads this comment.
$DELETE_MARKER = ([string]$config.DeleteMarker).Trim()

# ONE MARKER MAY NOT DO TWO JOBS. If a repo answers both seams with the same string, the delete
# capability is refused rather than granted: the push marker is written on live-push commands as a matter
# of routine (it is in that repo's own step-by-step), so accepting it here would mean every documented
# live push doubles as a standing authorisation to delete. That is the opposite of a marker authorising
# ONE command visibly. Failing safe costs a repo one word of config; failing open costs it a theme.
if ($DELETE_MARKER -and $DELETE_MARKER.ToLower() -eq $MARKER.ToLower()) { $DELETE_MARKER = '' }

# Commands that read or write text rather than run the store CLI. A segment led by one of these is
# handling the words, not obeying them.
$TEXT_TOOLS = @(
    'grep', 'egrep', 'fgrep', 'rg', 'sed', 'perl', 'awk', 'cat', 'echo', 'printf', 'head', 'tail',
    'less', 'more', 'jq', 'git', 'findstr', 'tee', 'diff', 'wc', 'sort', 'uniq', 'tr', 'cut'
)

# Interpreters: a heredoc they read is a script, and a pipe into them executes what came before.
$INTERPRETERS = 'bash|sh|zsh|dash|ksh|pwsh|powershell|python|python3|node|ruby|perl'

$raw = [Console]::In.ReadToEnd()
$cmd = ''
try {
    $j = $raw | ConvertFrom-Json
    if ($j.tool_input -and $j.tool_input.command) { $cmd = [string]$j.tool_input.command }
} catch { }
# AN UNPARSEABLE PAYLOAD FALLS BACK TO THE RAW TEXT rather than to an empty string, so a hook contract
# that changes shape fails towards CHECKING instead of towards allowing. Asserted in the suite.
if (-not $cmd) { $cmd = [string]$raw }

function Remove-HeredocBodies([string]$text) {
    if ($text -notmatch '<<') { return $text }

    $lines = $text -split "`r?`n"
    $out = New-Object System.Collections.Generic.List[string]
    $terminator = $null

    foreach ($line in $lines) {
        if ($null -ne $terminator) {
            if ($line.Trim() -eq $terminator) { $terminator = $null }
            continue
        }

        $out.Add($line)

        # An opener looks like:  <<EOF | <<-EOF | <<'EOF' | <<"EOF"
        $m = [regex]::Match($line, '<<-?\s*(?:''([^'']+)''|"([^"]+)"|([A-Za-z_][A-Za-z0-9_]*))')
        if (-not $m.Success) { continue }

        # An interpreter consuming the heredoc means the body IS a script: keep it and match it.
        $before = $line.Substring(0, $m.Index)
        if ($before -match "(^|[;&|]|\s)($INTERPRETERS|eval)\b") { return $text }

        $terminator = ($m.Groups[1].Value + $m.Groups[2].Value + $m.Groups[3].Value)
    }

    return ($out -join "`n")
}

function Get-LeadingCommand([string]$segment) {
    $s = $segment.Trim()
    # Drop leading env assignments (FOO=bar cmd ...) and a leading subshell/brace opener.
    while ($s -match '^\(?\{?\s*[A-Za-z_][A-Za-z0-9_]*=[^\s]*\s+(.*)$') { $s = $Matches[1].Trim() }
    $s = $s -replace '^[\(\{\s]+', ''
    if ($s -match '^([^\s]+)') { return ($Matches[1] -replace '.*[\\/]', '').ToLower() }
    return ''
}

$scan = Remove-HeredocBodies $cmd

# A pipe into an interpreter, an eval or an xargs means text somewhere in this command is about to be
# executed. When that is in play, no segment gets the text-tool exemption.
$executesText = ($scan -match "\|\s*($INTERPRETERS)\b") -or ($scan -match '\beval\b') -or ($scan -match '\bxargs\b')

# Split into shell segments so that a real command next to a harmless one is still seen.
$segments = [regex]::Split($scan, '(?:\|\||&&|[;|\r\n])')

$authorised = $scan.ToLower().Contains($MARKER.ToLower())
# Computed on the whole command rather than per segment, exactly like $authorised above: a marker is a
# comment on the command line, and which segment it trails is not something a reader should have to
# reason about. Empty $DELETE_MARKER can never match, which is what keeps the capability off.
$deleteAuthorised = $DELETE_MARKER -and $scan.ToLower().Contains($DELETE_MARKER.ToLower())

function Deny([string]$msg) {
    [Console]::Error.WriteLine("BLOCKED (guard-live-theme): $msg")
    exit 2
}

foreach ($segment in $segments) {
    if (-not $segment.Trim()) { continue }

    if (-not $executesText) {
        $lead = Get-LeadingCommand $segment
        if ($TEXT_TOOLS -contains $lead) { continue }
    }

    $lc = $segment.ToLower()

    if ($lc -match 'shopify\s+theme\s+publish') {
        Deny "a theme publish is never allowed from here. Publishing makes a theme the live customer-facing theme, and that is the store owner's own keystroke rather than something a session decides -- run it yourself if that is what you want."
    }

    if ($lc -match 'shopify\s+theme\s+delete') {
        # THE LIVE THEME IS NEVER DELETABLE, marker or not, and this check comes FIRST so no
        # authorisation path can reach past it. Shopify itself refuses to delete a published theme, so
        # this is belt-and-braces -- and it is worth the two lines precisely because it is the one
        # outcome nothing else in this file could undo.
        if ($LIVE_ID -and $lc.Contains($LIVE_ID.ToLower())) {
            Deny "delete aimed at the LIVE theme ($LIVE_ID) is refused unconditionally -- no marker authorises this one. If the intent was a spent preview theme, check the id against 'shopify theme list'."
        }

        if ($DELETE_MARKER) {
            if ($deleteAuthorised) {
                [Console]::Error.WriteLine("guard-live-theme: theme delete allowed (delete marker present).")
                exit 0
            }
            Deny "a theme delete needs this repo's own authorisation. Confirm the theme is spent -- its work merged and, if it was ever pushed, already live -- then add the marker '# $DELETE_MARKER' to this exact command. The live theme is refused even with it."
        }

        Deny "a theme delete is never allowed from here. What is deleted cannot be un-deleted, and whether a preview theme is really spent is a judgement rather than a cleanup step -- run the command yourself once you have confirmed nothing on it is still needed. (A repo that wants sessions to clear away their own spent preview themes can answer Get-ShopifyThemeDeleteMarker in scripts/repo-config.ps1; unanswered, this rule stays absolute.)"
    }

    $aimedAtLive = ($lc -match '--allow-live') -or ($LIVE_ID -and $lc.Contains($LIVE_ID.ToLower()))
    if ($lc -match 'shopify\s+theme\s+push' -and $aimedAtLive) {
        if ($authorised) {
            [Console]::Error.WriteLine("guard-live-theme: live push allowed (authorisation marker present).")
            exit 0
        }
        $idPart = if ($LIVE_ID) { "$LIVE_ID / --allow-live" } else { '--allow-live' }
        Deny "push to the live theme ($idPart) blocked. If this IS the deliberate live push this repo's own rules describe, add the marker '# $MARKER' to this exact command. Preview pushes and every form of pull are not blocked."
    }
}

exit 0
