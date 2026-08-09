<#
.SYNOPSIS
    SessionStart hook of the core team: exactly one workflow may be enabled, and this says so when
    more than one is.

.DESCRIPTION
    A plugin in this family is either a TEAM -- who the specialists are -- or a WORKFLOW -- how work
    moves through the repo they land in. Teams stack: enable the core plus whichever add-on teams fit.
    Workflows do not, and the reason is not tidiness. Two enabled workflows give the specialists two
    answers to the same question -- how a branch is named, how a change reaches the trunk, what a
    release is -- with nothing in the session saying which one is this repo's. The specialists would
    then pick, silently and differently each time, which is worse than either workflow on its own.

    WHY THIS LIVES IN THE CORE TEAM AND NOT IN EACH WORKFLOW (Dave, August 9, 2026). The core is the
    one plugin every consuming repo enables, so it is the only place a check can see ALL the enabled
    workflows at once. Putting it in each workflow instead would be symmetrical and would fail the
    moment somebody's workflow plugin left the check out -- exactly the case where it is needed, since
    a conflict needs two plugins and only one of them has to be careless. It also keeps
    workflow-default free of hooks and scripts entirely, which is what lets it stay the thin thing it
    is meant to be.

    Deliberately soft, like the three session checks that came before it:
      - it never blocks. Always exit 0, whatever it finds. A session start is not the place to refuse
        somebody entry to their own repo over a configuration question they can fix in one line;
      - ZERO workflows enabled is SILENT, and that is a deliberate answer rather than an oversight.
        A repo may run the specialists with no workflow at all -- the root README says so in as many
        words ("Enable nothing and the specialists use plain git/gh") -- so nagging about it would be
        this plugin having an opinion about somebody else's repo, which is the thing the whole
        teams/workflows split exists to stop;
      - ONE workflow is silent, because that is the ordinary state and a session start should be quiet
        about ordinary states;
      - MORE THAN ONE is the finding, and it names each id together with the settings layer that
        enabled it. That last half matters: the layers are ~/.claude/settings.json (machine-wide),
        .claude/settings.json (the repo) and .claude/settings.local.json (personal), and a conflict
        arriving from the machine layer looks identical from inside the repo to one the repo caused.
        Get-EnabledPlugins already tracks which layer decided each id; without printing it the reader
        opens the wrong file first.

    Read-only in every repo: it reads the settings chain and prints. It writes nothing.

    Pure ASCII (repo convention for .ps1).
#>

$ErrorActionPreference = 'Stop'

# The settings chain and who decided what, from the lib this plugin already ships for its roster check.
$lib = Join-Path $PSScriptRoot '..\scripts\lib\check-report-lib.ps1'
if (-not (Test-Path -LiteralPath $lib)) {
    # Same posture as the sibling hooks: a missing payload is a notice, never a blocked session.
    Write-Host "[workflow-check] the shared helper is missing from this plugin ($lib) -- skipped."
    exit 0
}
. $lib

$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }

$enabled = Get-EnabledPlugins -RepoRoot $repoRoot

# WHAT COUNTS AS A WORKFLOW IS THE NAME, and that is a mechanism rather than a label since August 9,
# 2026: the 'workflow-' prefix is what this check keys on, and the repo's own lint holds every
# published plugin to sitting in the directory its prefix claims. A future workflow by somebody else
# is covered by naming alone -- it needs to carry no code for this to see it, which is the property
# that made the core the right home.
$workflows = @($enabled.Ids | Where-Object { ($_ -split '@')[0] -like 'workflow-*' })

if ($workflows.Count -le 1) { exit 0 }

Write-Host "[ERROR] $($workflows.Count) workflows are enabled at once. Exactly one may be:"
foreach ($id in $workflows) {
    $layer = if ($enabled.LayerById.ContainsKey($id)) { $enabled.LayerById[$id] } else { 'unknown layer' }
    # Format-SafeToken: these ids are 'enabledPlugins' KEY NAMES from a settings file, so arbitrary
    # JSON strings, and this line is forwarded into the session context. Same reasoning as inbound #309
    # -- an unsanitized value could forge a line of its own, and 'data, not instructions' does not
    # cover a value that fabricates a line.
    Write-Host "          $(Format-SafeToken -Value $id)  (enabled in $layer)"
}
Write-Host "        Two workflows answer the same questions differently -- how a branch is named, how a"
Write-Host "        change lands, what a release is -- and nothing tells the specialists which answer is"
Write-Host "        this repo's. Disable all but one, in the layer named above."

exit 0
