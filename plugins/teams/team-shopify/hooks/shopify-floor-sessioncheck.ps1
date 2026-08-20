<#
.SYNOPSIS
    SessionStart hook of the Shopify team: says when the live-theme guard is only half armed.

.DESCRIPTION
    The guard beside this file has three rules. Two of them need nothing from the repo -- a theme
    publish and a theme delete are refused whatever the configuration. The third, a push aimed at the
    LIVE theme, has two triggers and only one of them is self-declaring:

      '--allow-live'  is the author saying so in the command, and always blocks.
      the live THEME ID  can only be recognised where the repo has said which id that is.

    So a repo that never answered Get-ShopifyLiveThemeId has a guard that blocks publish, delete and
    an --allow-live push, and lets 'shopify theme push --theme <the live id>' through. That is the one
    combination worth a line at session start, and the reason is the shape of the failure rather than
    its likelihood: the guard is INSTALLED, so it reads as protection, and the gap is invisible from
    inside the repo. A check that goes quiet for the right-looking reason is worse than one that
    speaks.

    WHY THIS IS AN [ERROR] AND NOT AN [INFO]. The session-check hooks in this family forward [ERROR]
    to the transcript and keep everything else for a deliberate run. An [INFO] here would be written
    for nobody. It is still not a refusal -- see the exit code below.

    IT NEVER BLOCKS. Always exit 0, whatever it finds, like every other session check in this family:
    a session start is not the place to refuse somebody entry to their own repo over a configuration
    question they can answer in three lines.

    SILENT IN THE ORDINARY CASE, both of them. A repo that answered the id gets nothing, and so does a
    repo with no scripts/repo-config.ps1 at all -- the specialists-init bootstrap is what creates that
    file, and a repo that has not run it already gets the one message naming its actual state. Adding
    a second would be noise on top of it.

    Read-only: it dot-sources the repo's own config in a child scope and prints. It writes nothing.

    Pure ASCII (repo convention for .ps1).
#>

$ErrorActionPreference = 'Stop'

$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'

# NO CONFIG FILE, NO FINDING. See the .DESCRIPTION: the bootstrap owns that message.
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { exit 0 }

# StrictMode OFF in a child scope, exactly as the guard reads it -- a consumer's config is written on
# the assumption that its runtime callers do not set it, and this check must not be the one that
# disagrees with the guard about what the repo answered.
$liveId = & {
    Set-StrictMode -Off
    try { . $args[0] } catch { return '' }
    if (Get-Command Get-ShopifyLiveThemeId -ErrorAction SilentlyContinue) { return [string](Get-ShopifyLiveThemeId) }
    return ''
} $configPath

if (([string]$liveId).Trim()) { exit 0 }

Write-Host ("[ERROR] team-shopify: the live-theme guard is armed for publish, delete and an " +
    "'--allow-live' push, but this repo has not said which theme is live -- so a push aimed at live " +
    "BY ID is not recognised and passes. Add Get-ShopifyLiveThemeId to scripts/repo-config.ps1, " +
    "returning the live theme's numeric id (shopify theme list names it). The guard reads it on every " +
    "command; nothing needs restarting.")

exit 0
