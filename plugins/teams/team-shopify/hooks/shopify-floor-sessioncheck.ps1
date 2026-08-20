<#
.SYNOPSIS
    SessionStart hook of the Shopify team: says when the live-theme guard is only half armed, and when
    a second, hand-written guard is still registered beside the shipped one.

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

    THE SECOND FINDING: TWO GUARDS DOING ONE JOB (inbound #777). Both consumers of this plugin wrote
    this guard themselves before it shipped here, and a plugin refresh does not replace a repo's own
    file -- it registers a second hook beside it. So a repo that did the right thing by inbound #769
    is rewarded with two PreToolUse guards firing on every command, and nothing anywhere said so,
    because that refresh happened INSIDE one version: no bump, and no changelog surfaced at install.
    The two findings are independent and either can fire alone, which is why the config-file check
    below gates only the first one.

    Read-only: it dot-sources the repo's own config in a child scope, parses the repo's settings, and
    prints. It writes nothing.

    Pure ASCII (repo convention for .ps1).
#>

$ErrorActionPreference = 'Stop'

$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'

# NO CONFIG FILE, NO ID FINDING -- but the duplicate-guard finding below still runs. See the
# .DESCRIPTION: the bootstrap owns the "you have no repo-config.ps1" message, and a repo can perfectly
# well be running a hand-written guard without ever having run the bootstrap.
$hasConfig = Test-Path -LiteralPath $configPath -PathType Leaf

# StrictMode OFF in a child scope, exactly as the guard reads it -- a consumer's config is written on
# the assumption that its runtime callers do not set it, and this check must not be the one that
# disagrees with the guard about what the repo answered.
$liveId = ''
if ($hasConfig) {
    $liveId = & {
        Set-StrictMode -Off
        try { . $args[0] } catch { return '' }
        if (Get-Command Get-ShopifyLiveThemeId -ErrorAction SilentlyContinue) { return [string](Get-ShopifyLiveThemeId) }
        return ''
    } $configPath
}

$liveId = ([string]$liveId).Trim()

# A NON-NUMERIC ANSWER COUNTS AS NO ANSWER, exactly as the guard beside this file now reads it -- the
# two must not be able to disagree about what "answered" means. A theme id is numeric, so anything else
# is a placeholder that was never filled in, and treating it as an answer would silence this very
# message while the id half of rule 3 stayed inert. Since adopt-shopify-floor writes the seam block
# with a 'VUL-IN' placeholder in it, that is a path a consumer can actually walk.
if ($liveId -and $liveId -notmatch '^\d+$') { $liveId = '' }

if ($hasConfig -and -not $liveId) {
    Write-Host ("[ERROR] team-shopify: the live-theme guard is armed for publish, delete and an " +
        "'--allow-live' push, but this repo has not said which theme is live -- so a push aimed at live " +
        "BY ID is not recognised and passes. Add Get-ShopifyLiveThemeId to scripts/repo-config.ps1, " +
        "returning the live theme's numeric id (shopify theme list names it) -- or run the " +
        "'adopt-shopify-floor' skill, which writes the block for you. The guard reads it on every " +
        "command; nothing needs restarting.")
}

# --- The second finding: a hand-written guard still registered beside the shipped one --------------
# WHY THIS BELONGS HERE (inbound #777). Both consumers of this plugin wrote this guard themselves before
# it shipped, and a plugin refresh does not replace a repo's own file -- it registers a SECOND hook
# beside it. Two PreToolUse guards then fire on every Bash call, agree on their verdict, and block the
# same command twice. Nothing anywhere said so, because the refresh happened inside one version: no
# version bump, no changelog surfaced at install.
#
# THE TEST IS PRECISE RATHER THAN BROAD. The plugin registers its own hook through its own hooks.json,
# never through the consumer's settings -- so a PreToolUse command in .claude/settings*.json naming
# guard-live-theme is, by construction, a second one. A command reaching into the plugin cache is
# excluded: that is somebody wiring the SHIPPED copy by hand, which is one guard, not two.
$dupes = @()
foreach ($rel in @('.claude\settings.json', '.claude\settings.local.json')) {
    $settingsPath = Join-Path $repoRoot $rel
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) { continue }
    # A SETTINGS FILE THIS CANNOT PARSE IS SKIPPED, NOT REPORTED. Somebody else's broken JSON is
    # somebody else's message, and a session start is not where this check gets to editorialise about a
    # file it only came to read.
    try { $json = Get-Content -LiteralPath $settingsPath -Raw -ErrorAction Stop | ConvertFrom-Json } catch { continue }
    if (-not $json.hooks) { continue }
    # -contains against the property NAMES, not .Contains() on them: a single-property object hands back
    # a bare string there, whose .Contains() is a substring test that answers true for the wrong reason.
    if (-not ($json.hooks.PSObject.Properties.Name -contains 'PreToolUse')) { continue }
    foreach ($matcher in @($json.hooks.PreToolUse)) {
        foreach ($h in @($matcher.hooks)) {
            $c = [string]$h.command
            if (-not $c) { continue }
            if ($c -notmatch 'guard-live-theme') { continue }
            if ($c -match 'CLAUDE_PLUGIN_ROOT' -or $c -match 'marketplaces') { continue }
            $dupes += $rel
        }
    }
}

if ($dupes.Count -gt 0) {
    $where = (($dupes | Sort-Object -Unique) -join ' and ')
    Write-Host ("[ERROR] team-shopify: a second live-theme guard is registered in $where, so two " +
        "PreToolUse hooks run one job on every command. The plugin registers its own through its own " +
        "hooks.json -- yours is the extra one. The shipped guard is the superset (it matches " +
        "Bash|PowerShell where a hand-written one usually matches Bash only), so converging is a " +
        "safety improvement rather than housekeeping: remove your PreToolUse entry and your own " +
        "script, and keep your test suite pointed at the shipped copy. Your existing authorisation " +
        "marker keeps working -- any marker ending in 'LIVE-PUSH-AUTHORIZED' is accepted. See " +
        "'Converging off a hand-written guard' in the team-shopify README.")
}

exit 0
