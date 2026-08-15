<#
.SYNOPSIS
    SessionStart hook of the workflow plugin: reports whether an assignment is waiting in the prompt
    inbox (workflow-davekjohn/prompts/prompt.md), so a session that opens on a written prompt says so
    instead of waiting to be told.

.DESCRIPTION
    The announcing half of the prompt inbox. The requester writes their assignment in an editor rather
    than in the terminal; without this hook the file would sit there until somebody remembered it, and
    "somebody remembered it" is the failure the mechanism exists to remove.

    IT ANNOUNCES, IT DOES NOT HAND OVER. Only the FIRST LINE of the assignment reaches the session
    context -- never the body. That is the deliberate half of the design: a session that had already
    read the whole assignment would start on it, which takes away the requester's moment to say "not
    yet". The body is handed over by /prompt, on purpose, as a separate act.

    NO CHILD PROCESS. Unlike its two siblings this check spawns nothing: the whole question is "does
    one file hold anything outside its HTML comments", which the shared lib answers from a single read.
    A SessionStart hook is paid at every session in every consumer, and a powershell child would cost
    more than the check.

    Deliberately soft, like every hook in this family:
      - no repo root, no lib, no folder -> silent, exit 0;
      - the script ALWAYS ends with exit 0 -- a session start must never strand here.

    Read-only: the hook writes nothing, in any repo. /prompt places the inbox on its first run; a hook
    that created files would put a folder in the repo of everyone who merely installed the plugin.

    Matcher note: hooks.json matches "startup|resume|clear|compact", not just "startup" -- a
    SessionStart hook's injected stdout does not survive a compaction by itself, so a startup-only
    matcher made every report go silent after the first /compact and never return.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Use this directory as the repo root instead of the resolved one.
#>
param(
    [string]$ConsumerPathOverride = ''
)

Set-StrictMode -Version Latest

try {
    if ($ConsumerPathOverride) {
        $repoRoot = $ConsumerPathOverride
    } elseif ($env:CLAUDE_PROJECT_DIR) {
        $repoRoot = $env:CLAUDE_PROJECT_DIR
    } else {
        $repoRoot = (Get-Location).Path
    }

    $lib = Join-Path $PSScriptRoot '..\scripts\lib\prompt-inbox-lib.ps1'
    if (-not (Test-Path -LiteralPath $lib -PathType Leaf)) { exit 0 }
    . $lib

    $state = Get-PromptState -RepoRoot $repoRoot

    # SILENT WHEN THERE IS NO INBOX AT ALL, and that is the one place this hook parts company with its
    # siblings' "report either way" habit. Those two check something every repo with the plugin has; an
    # inbox is opt-in, created by the first /prompt run, so a repo that has never wanted one would be
    # told about a mechanism it declined at every single session start.
    if (-not $state.Exists) { exit 0 }

    if ($state.Waiting) {
        Write-Host "prompt-sessioncheck: a prompt is waiting in $($state.Paths.PromptRel), written $($state.Age) -- run /prompt to pick it up."
        Write-Host "  it opens: $($state.FirstLine)"
    } else {
        Write-Host 'prompt-sessioncheck: no prompt waiting.'
    }
} catch {
    Write-Host ('prompt-sessioncheck skipped due to an error: ' + $_.Exception.Message)
}
exit 0
