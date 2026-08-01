<#
.SYNOPSIS
    Integrity check for the davekjohns-workshop marketplace: validates the manifests, the
    agent-def frontmatter and the internal links before a change lands via a PR on main.
.DESCRIPTION
    This repo's lint gate (invoked by scripts/release/open-pr.ps1). Read-only -- changes nothing.
    Checks the following; every finding is an error:

      1. .claude-plugin/marketplace.json: valid JSON; every plugins[].source points to an
         existing folder with a .claude-plugin/plugin.json.
      2. every <plugin>/.claude-plugin/plugin.json: valid JSON with a non-empty 'name'.
      3. every <plugin>/agents/*.md: frontmatter contains 'name:', 'id:' and 'group:'.
      3b. every <plugin>/manuals/*-manual.md: frontmatter contains 'id:' and 'group:', and the
         file name <group>-<id>-manual.md matches that frontmatter (the portable manual that the
         corresponding agent def reads in via ${CLAUDE_PLUGIN_ROOT}/manuals/).
      3c. every <plugin>/personas/*-persona.md: frontmatter contains 'id:' and 'group:', and the
         file name <group>-<id>-persona.md matches that frontmatter. Personas (orchestrator +
         main-loop specialists) DELIBERATELY have no agent def -- they run in the main loop, not
         as a subagent -- and are therefore left alone by check 6's agent-def<->manual link.
      4. dead relative links AND broken anchors in README.md, CHANGELOG.md, CLAUDE.md,
         CONTRIBUTING.md, every .claude/extensions/*.md, every <plugin>/skills/*/SKILL.md, every
         <plugin>/manuals/*-manual.md, every <plugin>/personas/*-persona.md, every releases/**/*.md,
         every <plugin>/RELEASE.md, claude-code-plugins/claude-specialists/README.md (the family
         README) and QUICKSTART.md, claude-code-plugins/claude-specialists/connectors/README.md, and
         every plugin's own claude-code-plugins/claude-specialists/<plugin>/CHANGELOG.md (#103).
         Checked: (a) the linked
         file exists, and (b) if the link
         has a #anchor, that anchor exists as a heading in the target file (GitHub slug rules).
         External http(s)/mailto links are skipped.
      5. every scripts/**/*.ps1 parses without error (catches syntax errors in the orchestration
         itself, which would otherwise only break at execution time).
      6. specialists-system integrity: per plugin, every '<group>-<id>' is unique across the
         agent defs, every agent def has a valid 'name:' + a corresponding manuals/<g>-<id>-manual.md
         which it also names, and conversely every manual has an agent def (no orphan manual).
      7. shared agent-def blocks: every <!-- BEGIN/END shared:NAME --> region in an agent def still
         equals its canonical source in agent-shared/<name>.md (see scripts/agents/build-agent-defs.ps1)
         -- a hand-edit inside the sentinels or a forgotten rebuild is thus caught at the gate.
      8. shared workflow scripts: every plugin mirror of a repo-agnostic script (issue #81) is
         still LF-identical to its root source -- a hand-edit in the mirror or a forgotten
         scripts/sync/build-shared-scripts.ps1 is thus caught at the gate.
      9. RELEASE.md per plugin (Model A, plugin-carried): every plugin folder has a RELEASE.md, and
         the 'vX.Y.Z' it contains equals the 'version' in that plugin's plugin.json. Only
         cut-release.ps1 changes both files together, so an ordinary feature PR can never trip this
         -- a mismatch/missing file means the card was not (re)generated.
     10. marked "all skills" enumerations: an opt-in <!-- skills:all --> ... <!-- /skills:all -->
         span (character-based, so it also wraps inline running prose, not just a bullet list on
         its own lines; scanned in every file from check 4's $linkFiles, with fenced ```-code blocks
         masked out first so a literal example of the marker syntax in a fence is not itself read as
         a live marker) must contain the exact set of backtick-quoted names -- no more, no fewer --
         against the canonical skillset read from every <plugin>/skills/<name>/SKILL.md 'name:'
         frontmatter across ALL plugin folders (not just 'specialists'). A BEGIN without a matching
         END, an END without a matching BEGIN, AND a stray extra END inside an already-open span
         (e.g. a pasted-in duplicate '/skills:all') are all hard errors -- symmetric in both
         directions, EXCEPT when a marker sits inside a fenced example (masked out before matching,
         so it is never seen at all, paired or not). Deliberately opt-in (no generic prose scan): a
         doc with zero spans passes without warning.
     11. printed lifecycle commands: every 'claude plugin install|update|uninstall' that carries an
         @-target (i.e. is an instruction someone RUNS, not prose discussing the command) must carry
         '--scope project' -- or, for 'uninstall' only, '--scope local' (inbound #315: that is the only
         command that removes a record a session start left at local scope). install/update must have
         'claude plugin marketplace update' or a link
         to 'staying-up-to-date' within 12 lines above or 6 below. Both flags fail SILENTLY when
         missing -- a scopeless install writes a machine-wide record and reports success (#274/#279),
         a stale cache serves the previous version and reports success (#282/#284) -- which is why
         three adoption rounds in a row found this same class of doc defect. The @-target is what
         makes a generic scan viable here where check 10 had to be opt-in: measured 11 targeted
         instructions against 13 bare mentions. History is excluded permanently and on purpose
         (CHANGELOG.md root + per-plugin, releases/**, RELEASE.md, root entry files): it records what
         was true then and is never rewritten. The unit is the enclosing inline-code span (a printed
         command wraps across lines), computed over check 10's fence-masked text so a ```-fence
         cannot throw off backtick pairing; inside a fence the unit is the physical line.
     12. printed install-record queries: a fenced block that READS installed_plugins.json in code (names
         the file and parses it) must select 'projectPath', 'scope', 'version' AND 'gitCommitSha'. This is
         the class behind all three findings of adoption round v8 rather than any one of them: the query
         every document points a reader at could not distinguish the release from main after it (#313),
         one record from two (#315), or 'project' from 'local' (#314) -- so it printed a green that
         under-determined the state it claimed to prove. projectPath is required rather than assumed: a
         query without it reports records beyond this repo, which is the 'claude plugin list' mistake
         these same docs warn against. A fenced JSON snippet illustrating the file's shape is NOT a
         subject (it names the fields but is not a command anyone reads a verdict off) -- the same
         mention-versus-use discriminator check 11 makes with its @-target. Shares check 11's scan set,
         so history is excluded identically. Matching is case-insensitive, since PowerShell property
         access is and a working query must not be reported as broken.

    Exit code: 0 = no errors. 1 = at least one error (usable as a gate in open-pr.ps1).
.EXAMPLE
    ./scripts/lint/check-plugin-integrity.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$errors = New-Object System.Collections.Generic.List[string]

function Add-Error([string]$Msg) { $script:errors.Add($Msg) }

# Write-Coverage: the shared, non-counting [COVERAGE] line (issue #221), so every category below states
# how many items it examined and an empty one announces itself instead of passing in silence. Only that
# function is used from this lib; its counting report helpers (Write-Info/Write-Failure) stay unused and
# would in fact be wrong here -- this script's $errors is a List[string], not an int counter -- exactly
# the deliberate, documented non-collision check-consumer-drift.ps1 already relies on.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

function Test-JsonFile {
    param([string]$Path)
    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        return ($raw | ConvertFrom-Json)
    } catch {
        Add-Error "[JSON] $($Path.Replace($RepoRoot, '.')) is not valid JSON: $($_.Exception.Message)"
        return $null
    }
}

Write-Host "== check-plugin-integrity -- $RepoRoot ==" -ForegroundColor Cyan

# --- 1. marketplace.json + the plugins it references ------------------------------------------------
$marketplacePath = Join-Path $RepoRoot '.claude-plugin\marketplace.json'
if (-not (Test-Path -LiteralPath $marketplacePath)) {
    Add-Error "[marketplace] .claude-plugin/marketplace.json is missing."
} else {
    $mp = Test-JsonFile -Path $marketplacePath
    if ($mp) {
        if (-not ($mp.PSObject.Properties.Name -contains 'plugins') -or -not $mp.plugins) {
            Add-Error "[marketplace] marketplace.json has no 'plugins' list."
        } else {
            # Containment (Sean's advice): a source that points outside the repo via an absolute
            # or ..-path is always wrong -- what is registered here gets published.
            # Deliberately mirrored on Get-PluginManifestPaths in scripts/lib/release-lib.ps1 (which
            # throws; this lint collects) -- if you change the containment rule, change both.
            $rootPrefix = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
            foreach ($p in $mp.plugins) {
                $src = $p.source
                if (-not $src) { Add-Error "[marketplace] plugin '$($p.name)' is missing a 'source'."; continue }
                $pluginDir = (Join-Path $RepoRoot ($src -replace '/', '\')).TrimEnd('\')
                $resolvedDir = $null
                try { $resolvedDir = [System.IO.Path]::GetFullPath($pluginDir) } catch {}
                if (-not $resolvedDir -or -not ($resolvedDir + '\').StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    Add-Error "[marketplace] plugin '$($p.name)': source '$src' points outside the repo."
                } elseif (-not (Test-Path -LiteralPath $pluginDir -PathType Container)) {
                    Add-Error "[marketplace] plugin '$($p.name)': source folder '$src' does not exist."
                } elseif (-not (Test-Path -LiteralPath (Join-Path $pluginDir '.claude-plugin\plugin.json'))) {
                    Add-Error "[marketplace] plugin '$($p.name)': '$src' contains no .claude-plugin/plugin.json."
                }
            }
        }
    }
}

# --- 2. every plugin.json: valid JSON with a name ----------------------------------------------------
Get-ChildItem -Path $RepoRoot -Recurse -Filter 'plugin.json' -File |
    Where-Object { $_.FullName -match '\.claude-plugin\\plugin\.json$' } | ForEach-Object {
        $pj = Test-JsonFile -Path $_.FullName
        if ($pj -and (-not ($pj.PSObject.Properties.Name -contains 'name') -or -not $pj.name)) {
            Add-Error "[plugin] $($_.FullName.Replace($RepoRoot, '.')) is missing a non-empty 'name'."
        }
    }

# --- 3. agent-def frontmatter: name/id/group ---------------------------------------------------------
# Each of checks 3/3b/3c/4/5/7/8/9 discovers its own file set and would report NOTHING if that set came
# back empty -- a tree that moved, a renamed directory, or a bad merge would read as a clean gate. Every
# one of them therefore closes with a [COVERAGE] line (issue #221): the verdict never travels without
# the count behind it. Applied to all of them on purpose -- a partial rollout recreates exactly the
# asymmetry that let check-consumer-drift's persona section state a clean verdict over 0 comparisons.
$agentDefs = @(Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-agent.md' -File |
    Where-Object { $_.FullName -match '\\agents\\' })
$agentDefs | ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        foreach ($key in 'name', 'id', 'group') {
            if (-not [regex]::IsMatch($text, "(?m)^$key`:\s*\S")) {
                Add-Error "[agent-def] $rel is missing '$key`:' in the frontmatter."
            }
        }
    }
Write-Coverage -Category 'agent-def' -Checked $agentDefs.Count `
    -Note $(if ($agentDefs.Count -eq 0) { 'no */agents/*-agent.md anywhere under the repo root -- the plugin tree is not where this check looked' } else { '' })

# --- 3b. manual frontmatter: id/group + file name <group>-<id>-manual.md -----------------------------
$manuals = @(Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-manual.md' -File |
    Where-Object { $_.FullName -match '\\manuals\\' })
$manuals | ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        foreach ($key in 'id', 'group') {
            if (-not [regex]::IsMatch($text, "(?m)^$key`:\s*\S")) {
                Add-Error "[manual] $rel is missing '$key`:' in the frontmatter."
            }
        }
        if ($_.BaseName -match '^(\d{2})-(\d{2})-manual$') {
            $fnG = $Matches[1]; $fnI = $Matches[2]
            $mI = [regex]::Match($text, '(?m)^id:\s*(\S+)\s*$')
            $mG = [regex]::Match($text, '(?m)^group:\s*(\S+)\s*$')
            if ($mI.Success -and $mI.Groups[1].Value.Trim() -ne $fnI) {
                Add-Error "[manual] $rel`: file-name id '$fnI' != frontmatter 'id: $($mI.Groups[1].Value.Trim())'."
            }
            if ($mG.Success -and $mG.Groups[1].Value.Trim() -ne $fnG) {
                Add-Error "[manual] $rel`: file-name group '$fnG' != frontmatter 'group: $($mG.Groups[1].Value.Trim())'."
            }
        } else {
            Add-Error "[manual] $rel`: file name does not follow the <group>-<id>-manual pattern."
        }
    }
Write-Coverage -Category 'manual' -Checked $manuals.Count `
    -Note $(if ($manuals.Count -eq 0) { 'no */manuals/*-manual.md found -- every specialist playbook is either missing or somewhere this check does not look' } else { '' })

# --- 3c. persona frontmatter: id/group + file name <group>-<id>-persona.md ----------------------------
# Personas (Chris/Derek/Rendall etc.) run in the MAIN LOOP, not as a subagent, so they deliberately
# have no agent def. They live in <plugin>/personas/ as a portable template that the bootstrap
# skill copies to a consumer's repo layer (.claude/extensions/<g>-<id>-extension.md). Check 6
# (agent-def<->manual link) therefore ignores them; here we validate their frontmatter + file name
# on their own (mirrors 3b).
$personas = @(Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-persona.md' -File |
    Where-Object { $_.FullName -match '\\personas\\' })
$personas | ForEach-Object {
        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        foreach ($key in 'id', 'group') {
            if (-not [regex]::IsMatch($text, "(?m)^$key`:\s*\S")) {
                Add-Error "[persona] $rel is missing '$key`:' in the frontmatter."
            }
        }
        if ($_.BaseName -match '^(\d{2})-(\d{2})-persona$') {
            $fnG = $Matches[1]; $fnI = $Matches[2]
            $mI = [regex]::Match($text, '(?m)^id:\s*(\S+)\s*$')
            $mG = [regex]::Match($text, '(?m)^group:\s*(\S+)\s*$')
            if ($mI.Success -and $mI.Groups[1].Value.Trim() -ne $fnI) {
                Add-Error "[persona] $rel`: file-name id '$fnI' != frontmatter 'id: $($mI.Groups[1].Value.Trim())'."
            }
            if ($mG.Success -and $mG.Groups[1].Value.Trim() -ne $fnG) {
                Add-Error "[persona] $rel`: file-name group '$fnG' != frontmatter 'group: $($mG.Groups[1].Value.Trim())'."
            }
        } else {
            Add-Error "[persona] $rel`: file name does not follow the <group>-<id>-persona pattern."
        }
    }
Write-Coverage -Category 'persona' -Checked $personas.Count `
    -Note $(if ($personas.Count -eq 0) { 'no */personas/*-persona.md found -- the main-loop specialists appear in no always-on listing, so nothing else would report their absence' } else { '' })

# --- 4. dead relative links + broken anchors ---------------------------------------------------------
# Scanned files: README.md, CHANGELOG.md, CLAUDE.md, CONTRIBUTING.md, the repo lenses (the seam
# .claude/specialists/, its pre-seam and legacy locations), every <plugin>/skills/*/SKILL.md, every
# <plugin>/manuals/*-manual.md, every releases/**/*.md and the connectors README. For every relative
# link it is checked (a) that the linked file exists, and (b) if the link has a #anchor: that anchor
# exists as a heading in the target file (GitHub slug rules). External http(s)/mailto links are skipped.

function Test-FenceDelimiterLine {
    # A single source for what counts as a fenced-code-block delimiter line, so the fence syntax
    # (currently ``` -- three-plus backticks, optionally indented) only ever needs to change in ONE
    # place. Shared by Get-HeadingSlugs (below) and Get-FenceMaskedText (check 10): both need to
    # toggle "am I inside a fence" per line, and a later fence-syntax change (tildes, four
    # backticks, ...) must not risk drifting between two independent hardcoded patterns.
    param([string]$Line)
    return [bool]($Line -match '^\s*```')
}

function ConvertTo-GhSlug {
    # Converts a heading text to a GitHub anchor slug.
    param([string]$Text)
    $t = [regex]::Replace($Text, '\[([^\]]*)\]\([^)]*\)', '$1')  # [text](url) -> text
    $t = $t -replace '[`*_]', ''                                  # strip inline code/emphasis markers
    $t = $t.ToLowerInvariant()
    $t = [regex]::Replace($t, '[^\p{L}\p{N} \-]', '')             # only letter/digit/space/hyphen
    $t = $t.Trim() -replace ' ', '-'
    return $t
}

function Get-HeadingSlugs {
    # Collects the anchor slugs of all headings in a markdown file (with GitHub duplicate suffixes).
    param([string]$Path)
    $slugs = New-Object System.Collections.Generic.HashSet[string]
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $slugs }
    $lines = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) -split "`r?`n"
    $counts = @{}
    $inFence = $false
    foreach ($line in $lines) {
        if (Test-FenceDelimiterLine -Line $line) { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        if ($line -match '^#{1,6}\s+(.*)$') {
            $base = ConvertTo-GhSlug -Text $Matches[1]
            if (-not $base) { continue }
            if (-not $counts.ContainsKey($base)) { $counts[$base] = 0; $slug = $base }
            else { $counts[$base] = $counts[$base] + 1; $slug = "$base-$($counts[$base])" }
            [void]$slugs.Add($slug)
        }
    }
    return $slugs
}

function Test-IsChangelogEntryFile {
    # A changelog entry file (new-changelog-entry.ps1) opens with the compact entry heading
    # '### <title> <midDot> <type> <midDot> <date>' -- an H3. Permanent root docs (README, CHANGELOG,
    # CONTRIBUTING, SECURITY, ...) open with an H1. Same structural signature fold-changelog-entry.ps1
    # keys off, deliberately restated rather than imported: dot-sourcing that script would RUN it, and
    # a lint gate must not invoke a release action to answer a question. The shared thing is the entry
    # FORMAT, owned by new-changelog-entry.ps1; both readers derive from it.
    param([Parameter(Mandatory = $true)][string]$Path)
    foreach ($line in [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        return ($line -match '^###\s')
    }
    return $false
}

$linkFiles = @()
foreach ($root in 'README.md', 'CHANGELOG.md', 'CLAUDE.md', 'CONTRIBUTING.md') {
    $p = Join-Path $RepoRoot $root
    if (Test-Path -LiteralPath $p) { $linkFiles += $p }
}
# The specialists handbook lives next to the lenses (at family level) -- validate its links too.
$handbook = Join-Path $RepoRoot '.claude\plugins\claude-specialists\README.md'
if (Test-Path -LiteralPath $handbook) { $linkFiles += $handbook }
# The family-level docs of the specialists family (claude-code-plugins/claude-specialists/*.md) and
# every plugin's own CHANGELOG.md (the consumer-facing card that cut-release.ps1 updates) did not yet
# belong to the scan set -- added (#103).
#
# ENUMERATED, NOT NAMED, AND THAT IS THE POINT. This was a hardcoded list of two ('README.md',
# 'QUICKSTART.md') until UNINSTALL.md was written beside them and no gate saw it: not the dead-link
# scan, not check 11 (printed lifecycle commands), not check 12 (the install-record query) -- all three
# derive their scan set from $linkFiles. A brand-new consumer-facing page, printing exactly the class of
# command those two checks exist to police, was invisible on the run that introduced it.
#
# The same gap is what #103 closed by ADDING the two names, which is why naming a third would have been
# repeating the fix rather than closing the class: the list is only ever correct until the next document
# is written, and nothing announces the omission. This directory holds the family's consumer-facing
# pages and nothing else, so its own *.md IS the set -- non-recursive on purpose, since the per-plugin
# subdirectories are gathered by their own rules below (CHANGELOG.md here, RELEASE.md and SKILL.md
# further down) and would otherwise be picked up twice.
$linkFiles += (Get-ChildItem -Path (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists') -Filter '*.md' -File |
    Select-Object -ExpandProperty FullName)
# The connectors README (claude-code-plugins/claude-specialists/connectors/) did not yet belong to
# the scan set either -- added alongside CONTRIBUTING.md (#159 follow-up, spotted by Edith).
$connectorsReadme = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\connectors\README.md'
if (Test-Path -LiteralPath $connectorsReadme) { $linkFiles += $connectorsReadme }
$linkFiles += (Get-ChildItem -Path (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists') -Recurse -Filter 'CHANGELOG.md' -File |
    Where-Object { $_.FullName -notmatch '\\connectors\\' } |
    Select-Object -ExpandProperty FullName)
# The repo lenses live in the seam (.claude/specialists/, the canonical location since #253), on the
# pre-seam plugin path, or on the legacy path -- scan all of them, wherever they are.
#
# THIS IS THE CATEGORY THAT DISAPPEARS ON A TEARDOWN, which is why it is counted separately from the
# scan total below. `if (Test-Path)` per directory is correct -- a consumer has one layout, not four --
# but it also means all four being absent contributes zero files and says nothing. Green, and checking
# nothing (issue #221). Right after a deliberate teardown, wrong after a bad merge or a wrong path, and
# a silent skip cannot tell those apart.
$lensLinkFiles = @()
foreach ($extDir in @(
    (Join-Path $RepoRoot '.claude\specialists\lenses'),
    (Join-Path $RepoRoot '.claude\specialists'),
    (Join-Path $RepoRoot '.claude\plugins\claude-specialists\specialists'),
    (Join-Path $RepoRoot '.claude\extensions'))) {
    if (Test-Path -LiteralPath $extDir) {
        $lensLinkFiles += (Get-ChildItem -Path $extDir -Filter '*.md' -File | Select-Object -ExpandProperty FullName)
    }
}
$linkFiles += $lensLinkFiles
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter 'SKILL.md' -File |
    Where-Object { $_.FullName -match '\\skills\\' } | Select-Object -ExpandProperty FullName)
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-manual.md' -File |
    Where-Object { $_.FullName -match '\\manuals\\' } | Select-Object -ExpandProperty FullName)
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*-persona.md' -File |
    Where-Object { $_.FullName -match '\\personas\\' } | Select-Object -ExpandProperty FullName)
$releasesDir = Join-Path $RepoRoot 'releases'
if (Test-Path -LiteralPath $releasesDir) {
    $linkFiles += (Get-ChildItem -Path $releasesDir -Recurse -Filter '*.md' -File | Select-Object -ExpandProperty FullName)
}
# Every plugin-carried RELEASE.md card (check 9) links to the full notes and its own
# CHANGELOG.md -- those links need to be validated too.
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter 'RELEASE.md' -File |
    Select-Object -ExpandProperty FullName)
# Root changelog ENTRY files (<branch-name>.md), added to close the window in #234. This is the whole
# fix, and it is small because the gap was structural rather than subtle: an entry file's text lives
# outside every scanned path while the PR is open, and only enters a scanned file at FOLD time --
# which happens directly on main, past every PR gate. So the sequence was: CI green on the PR (text in
# an unscanned file) -> the fold introduces the error on main -> nothing reviews the fold, because it
# is one of the two sanctioned direct-on-main actions -> the next full gate run is cut-release.ps1,
# which refuses to release. That is how v2.13.0 was blocked by a changelog sentence.
#
# Scanning them here means the PR gate sees exactly the text the fold will paste into CHANGELOG.md,
# so the error surfaces where it can still be reviewed. Their links are validated at ROOT position,
# which is correct twice over: the entry file sits in the root now, and CHANGELOG.md -- where it is
# headed -- is in the root too, so a relative link that resolves here resolves there.
#
# Note this covers check 10 (the skills:all spans) as well, since that check reuses this same set --
# and check 10 is precisely what #234 tripped over.
$linkFiles += @(Get-ChildItem -Path $RepoRoot -Filter '*.md' -File |
    Where-Object { Test-IsChangelogEntryFile -Path $_.FullName } |
    Select-Object -ExpandProperty FullName)

Write-Coverage -Category 'link-scan' -Checked $linkFiles.Count `
    -Note $(if ($linkFiles.Count -eq 0) { 'the scan set is empty -- no dead link anywhere could be found, which is not the same as there being none' } else { '' })
Write-Coverage -Category 'link-scan/lenses' -Checked $lensLinkFiles.Count `
    -Note $(if ($lensLinkFiles.Count -eq 0) { 'no repo-lens file in the seam, its pre-seam location, or the legacy path -- expected after a deliberate teardown, otherwise the lens tree has moved or been lost' } else { '' })

$linkRegex = [regex]'\[(?:[^\]]*)\]\(([^)]+)\)'
$slugCache = @{}
foreach ($lf in $linkFiles) {
    $content = [System.IO.File]::ReadAllText($lf, [System.Text.Encoding]::UTF8)
    # Exclude code: fenced (```...```) and inline (`...`). Link-like text inside code is
    # illustration, not a real link -- otherwise e.g. a `[..](#anchor)` example would get validated.
    $scan = [regex]::Replace($content, '(?s)```.*?```', '')
    $scan = [regex]::Replace($scan, '`[^`]*`', '')
    # Persona templates are destined for .claude/extensions/ of a consuming repo; their relative
    # links need to resolve THERE, not at the source location in the plugin. So validate them as if
    # the file were already at that destination (this repo mirrors the consumer layout).
    if ($lf -match '\\personas\\.*-persona\.md$') {
        $dir = Join-Path $RepoRoot '.claude\extensions'
    } else {
        $dir = Split-Path -Parent $lf
    }
    $rel = $lf.Replace($RepoRoot, '.')
    foreach ($m in $linkRegex.Matches($scan)) {
        $target = $m.Groups[1].Value.Trim()
        if ($target -match '^(https?:|mailto:)') { continue }

        $parts = $target -split '#', 2
        $pathPart = $parts[0]
        $anchor = if ($parts.Count -gt 1) { $parts[1] } else { $null }

        # Determine target file: empty pathPart = this same file (pure #anchor).
        if (-not $pathPart) {
            $targetFile = $lf
        } else {
            $resolved = Join-Path $dir ($pathPart -replace '/', '\')
            if (-not (Test-Path -LiteralPath $resolved)) {
                Add-Error "[link] $rel -> dead link '$target' (expected file does not exist)."
                continue
            }
            $targetFile = $resolved
        }

        # Anchor validation: only meaningful for an existing .md target file.
        if ($anchor -and $targetFile -match '\.md$' -and (Test-Path -LiteralPath $targetFile -PathType Leaf)) {
            $full = (Resolve-Path -LiteralPath $targetFile).Path
            if (-not $slugCache.ContainsKey($full)) { $slugCache[$full] = Get-HeadingSlugs -Path $full }
            if (-not $slugCache[$full].Contains($anchor)) {
                Add-Error "[anchor] $rel -> '$target' (anchor '#$anchor' does not exist as a heading in the target file)."
            }
        }
    }
}

# --- 5. PowerShell scripts must parse -----------------------------------------------------------------
# Catches syntax errors before they land on main. The pure logic of a script can be tested
# separately, but a parse error in the orchestration itself would only break at execution time --
# this check pulls that forward, to the PR gate. Scanned: scripts/**/*.ps1 AND the scripts a plugin
# carries -- <plugin>/skills/**/*.ps1 (e.g. specialists-init's bootstrap) and
# <plugin>/scripts/**/*.ps1 (the shared SSOT home, issue #81). Made unique so a path that hits both
# filters is not parsed twice.
$psScripts = @()
$psScripts += (Get-ChildItem -Path (Join-Path $RepoRoot 'scripts') -Recurse -Filter '*.ps1' -File)
$psScripts += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*.ps1' -File |
    Where-Object { $_.FullName -match '\\skills\\' -or $_.FullName -match '\\claude-code-plugins\\.+\\scripts\\' })
$psScripts = @($psScripts | Sort-Object -Property FullName -Unique)
$psScripts | ForEach-Object {
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$parseErrors) | Out-Null
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        $rel = $_.FullName.Replace($RepoRoot, '.')
        Add-Error "[parse] $rel`: $($parseErrors[0].Message)"
    }
}
Write-Coverage -Category 'parse' -Checked $psScripts.Count `
    -Note $(if ($psScripts.Count -eq 0) { 'no .ps1 found under scripts/ or in any plugin -- a syntax error anywhere could not have been seen' } else { '' })

# --- 6. specialists-system integrity -------------------------------------------------------------------
# This repo is the source of the specialists system, so the agent-def<->manual link must be at
# least as strict here as for a consumer. Per plugin (folder with agents/ and manuals/):
#   6a. every '<group>-<id>' is unique across all agent defs; every agent def has a valid 'name:'
#       (Claude Code call name), a corresponding manuals/<g>-<id>-manual.md in the same plugin, and
#       names that manual in its text.
#   6b. no orphan manual: every manuals/<g>-<id>-manual.md has an agents/<g>-<id>-agent.md.
# (The roster->lens link is already covered by the dead-link scan above, since that scans CLAUDE.md.)

$idOwner = @{}
$agentDefs | ForEach-Object {
        $rel = $_.FullName.Replace($RepoRoot, '.')
        if ($_.BaseName -notmatch '^(\d{2})-(\d{2})-agent$') {
            Add-Error "[specialist] $rel does not follow the <group>-<id>-agent.md pattern."
            return
        }
        $g = $Matches[1]; $id = $Matches[2]; $key = "$g-$id"
        if ($idOwner.ContainsKey($key)) {
            Add-Error "[specialist] ${rel}: duplicate id '$key' (already claimed by $($idOwner[$key]))."
        } else {
            $idOwner[$key] = $rel
        }

        $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $nm = [regex]::Match($text, '(?m)^name:\s*(\S+)\s*$')
        if ($nm.Success -and ($nm.Groups[1].Value.Trim() -notmatch '^[a-z0-9-]+$')) {
            Add-Error "[specialist] ${rel}: 'name: $($nm.Groups[1].Value.Trim())' must consist of lowercase letters/digits/hyphens (Claude Code call name)."
        }

        $pluginRoot = Split-Path (Split-Path $_.FullName -Parent) -Parent
        $manualBase = "$g-$id-manual"
        $manualPath = Join-Path $pluginRoot ("manuals\$manualBase.md")
        if (-not (Test-Path -LiteralPath $manualPath -PathType Leaf)) {
            Add-Error "[specialist] ${rel}: corresponding manual 'manuals/$manualBase.md' is missing in the same plugin."
        } elseif ($text -notmatch [regex]::Escape("manuals/$manualBase.md")) {
            Add-Error "[specialist] ${rel}: agent def does not name its manual 'manuals/$manualBase.md'."
        }
    }

$manuals | ForEach-Object {
        if ($_.BaseName -match '^(\d{2})-(\d{2})-manual$') {
            $g = $Matches[1]; $id = $Matches[2]
            $pluginRoot = Split-Path (Split-Path $_.FullName -Parent) -Parent
            $agentPath = Join-Path $pluginRoot ("agents\$g-$id-agent.md")
            if (-not (Test-Path -LiteralPath $agentPath -PathType Leaf)) {
                $rel = $_.FullName.Replace($RepoRoot, '.')
                Add-Error "[specialist] ${rel}: orphan manual -- no corresponding agents/$g-$id-agent.md in the same plugin."
            }
        }
    }
Write-Coverage -Category 'specialist' -Checked ($agentDefs.Count + $manuals.Count) `
    -Note $(if (($agentDefs.Count + $manuals.Count) -eq 0) { 'neither an agent def nor a manual was found -- the agent-def/manual coupling could not be checked in either direction' } else { '' })

# --- 7. shared agent-def blocks in sync with their source ---------------------------------------------
# Verbatim-shared bullets (e.g. the inbound rule, 19/19) are maintained in ONE place in
# agent-shared/<name>.md and filled into the agent defs between <!-- BEGIN/END shared:NAME -->
# sentinels (built via scripts/agents/build-agent-defs.ps1). Here we guard that every marked
# region still equals its source -- this catches a hand-edit inside the sentinels or a forgotten
# rebuild.
. (Join-Path $PSScriptRoot '..\lib\agent-shared-lib.ps1')
$agentSharedDir = Get-AgentSharedDir -RepoRoot $RepoRoot
$agentDefs | ForEach-Object {
        $raw = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        $sharedProblems = New-Object System.Collections.Generic.List[string]
        $expanded = Expand-AgentDefShared -Content $raw -SharedDir $agentSharedDir -Problems $sharedProblems
        foreach ($p in $sharedProblems) { Add-Error "[shared] ${rel}: $p" }
        if ($expanded -ne ($raw -replace "`r`n", "`n")) {
            Add-Error "[shared] ${rel}: shared block deviates from the source -- run scripts/agents/build-agent-defs.ps1."
        }
    }
Write-Coverage -Category 'shared' -Checked $agentDefs.Count `
    -Note $(if ($agentDefs.Count -eq 0) { 'no agent def to expand, so no shared block could be compared with its source' } else { '' })

# --- 8. shared workflow scripts in sync with their source ----------------------------------------------
# Repo-agnostic scripts are shared with consumers as a plugin mirror (issue #81): the root copy is
# the tested source, the plugin mirror is what a consumer runs. Here we guard that every mirror is
# still LF-identical to its source -- this catches a hand-edit in the mirror or a forgotten rebuild
# (scripts/sync/build-shared-scripts.ps1) before it lands on main via a PR.
. (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')
$sharedPairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)
foreach ($pair in $sharedPairs) {
    $src = Get-NormalizedScriptContent -Path $pair.SourcePath
    if ($null -eq $src) {
        Add-Error "[shared-script] source is missing: $($pair.SourceRel)."
        continue
    }
    $mirror = Get-NormalizedScriptContent -Path $pair.MirrorPath
    if ($null -eq $mirror) {
        Add-Error "[shared-script] mirror is missing: $($pair.MirrorRel) -- run scripts/sync/build-shared-scripts.ps1."
    } elseif ($src -ne $mirror) {
        Add-Error "[shared-script] $($pair.MirrorRel) deviates from $($pair.SourceRel) -- run scripts/sync/build-shared-scripts.ps1."
    }
}
Write-Coverage -Category 'shared-script' -Checked $sharedPairs.Count `
    -Note $(if ($sharedPairs.Count -eq 0) { 'the source/mirror pair list is empty -- a mirror could not have been found out of sync, however far it had drifted' } else { '' })

# --- 9. RELEASE.md present per plugin + version match --------------------------------------------------
# Model A (plugin-carried, see CHANGELOG/#115-like inbound issue): cut-release.ps1 writes this
# card on EVERY release for EVERY plugin (lockstep version), even a plugin not touched this time.
# Because RELEASE.md and plugin.json only change together -- via cut-release.ps1 -- an ordinary
# feature PR can never trip this; only a forgotten regeneration or hand-edit gets caught.
$pluginManifests = @(Get-ChildItem -Path $RepoRoot -Recurse -Filter 'plugin.json' -File |
    Where-Object { $_.FullName -match '\.claude-plugin\\plugin\.json$' })
$pluginManifests | ForEach-Object {
        $pluginDir = Split-Path (Split-Path $_.FullName -Parent) -Parent
        $pluginName = Split-Path $pluginDir -Leaf
        $pj = Test-JsonFile -Path $_.FullName
        if (-not $pj) { return }
        if (-not ($pj.PSObject.Properties.Name -contains 'version') -or -not $pj.version) {
            Add-Error "[release-card] $pluginName/.claude-plugin/plugin.json is missing a non-empty 'version' -- required for the lockstep RELEASE.md card."
            return
        }
        $pjVersion = $pj.version
        $releasePath = Join-Path $pluginDir 'RELEASE.md'
        if (-not (Test-Path -LiteralPath $releasePath -PathType Leaf)) {
            Add-Error "[release-card] $pluginName is missing RELEASE.md -- run scripts/release/cut-release.ps1 (that regenerates the card for every plugin)."
            return
        }
        $releaseText = [System.IO.File]::ReadAllText($releasePath, [System.Text.Encoding]::UTF8)
        $vm = [regex]::Match($releaseText, '(?m)^#\s+Release\s+v(\d+\.\d+\.\d+)\s*$')
        if (-not $vm.Success) {
            Add-Error "[release-card] $pluginName/RELEASE.md: no '# Release vX.Y.Z' heading found -- regenerate via cut-release.ps1."
        } elseif ($vm.Groups[1].Value -ne $pjVersion) {
            Add-Error "[release-card] $pluginName/RELEASE.md carries v$($vm.Groups[1].Value), but plugin.json says v$pjVersion -- run cut-release.ps1 again."
        }
    }
Write-Coverage -Category 'release-card' -Checked $pluginManifests.Count `
    -Note $(if ($pluginManifests.Count -eq 0) { 'no .claude-plugin/plugin.json found -- there is no plugin here whose card and version could be compared' } else { '' })

# --- 10. marked "all skills" enumerations vs. the canonical skillset -----------------------------------
# A prose bullet list that claims to enumerate "all skills" is a maintenance trap: it silently
# drifts as skills are added/removed, and a generic prose scan over-detects (tested and rejected --
# 147 hits repo-wide, including QUICKSTART.md's deliberately incomplete illustrative list, which
# would permanently false-positive). Instead this is opt-in: an author wraps the enumeration in
#     <!-- skills:all -->
#     - `skill-name`
#     ...
#     <!-- /skills:all -->
# and only spans between those sentinels are checked -- a doc with zero spans passes silently
# (that absence of warning is deliberate, not an oversight). Reuses check 4's $linkFiles set
# rather than its own file list (single source for "which docs matter").
#
# Extraction is CHARACTER-based (offset of the end of the BEGIN match to the start of the END
# match), not line-based. The real-world enumerations this exists for (e.g. the family README's
# "only the skills (...) remain available there" sentence) are inline running prose, not a bullet
# list on its own lines -- a line-based span could only mark that by putting a sentinel on its own
# line mid-paragraph, which breaks the paragraph in rendered markdown (an HTML comment is an HTML
# block that interrupts a paragraph). Character-based extraction lets the author wrap the sentinels
# tightly around just the enumeration itself, inline, e.g. `(...skills <!-- skills:all -->(`a`,
# `b`)<!-- /skills:all --> remain...`, with the same code path serving both the inline form and a
# block bullet-list form. AUTHOR CONDITION, because of this: every backtick-quoted token anywhere
# inside the span counts as a claimed name -- so the span must be wrapped tightly enough to contain
# ONLY skill names, nothing else in backticks (e.g. NOT the three SessionStart hook names in that
# same README sentence, which sit outside the parenthesized skill list and so outside the span).
#
# A literal example of the marker syntax in a doc (e.g. Tessa's convention writeup) must NOT be
# read as a live marker itself -- otherwise the syntax could only ever be described, never shown.
# Get-FenceMaskedText below masks fenced ```-code blocks with same-length whitespace before the
# BEGIN/END scan runs, so an example fence is invisible to it (an unpaired BEGIN inside a fence is
# therefore also invisible -- not reported, because the scan never sees it at all, not because it
# is special-cased). Deliberately fences only, not inline single-backtick code: a real span's own
# claimed names are themselves single-backtick-delimited (the `` `skill-name` `` bullets), so
# masking every inline-code run would erase the very names a real span exists to list -- there is
# no way to tell "backtick pair is an inline-code escape" from "backtick pair is a claimed skill
# name" at the character level. A fence is therefore the ONLY supported way to show the bare marker
# text without it being read as live; showing it in inline code is not an escape and stays in scope
# (Tessa documents the fence form as the convention, not inline code).
function Get-FenceMaskedText {
    # Masks fenced ```-code blocks with SAME-LENGTH whitespace (newlines untouched), so the caller
    # can keep using character offsets into the RETURNED text to derive correct line numbers -- the
    # length and every newline position stay identical to the input, only non-newline characters
    # inside a fence become spaces. Uses the SAME fence-toggle detection (Test-FenceDelimiterLine,
    # flip a boolean per line) that Get-HeadingSlugs already uses above -- one shared pattern, not
    # two independently hardcoded ones. It cannot reuse Get-HeadingSlugs's RESULT directly, though:
    # that function drops fenced lines outright (fine there -- it never reports a line number),
    # whereas this needs a same-shape mask, not a shorter string.
    param([string]$Text)
    $parts = [regex]::Split($Text, '(\r\n|\r|\n)')
    $inFence = $false
    for ($k = 0; $k -lt $parts.Length; $k += 2) {
        $isFenceLine = Test-FenceDelimiterLine -Line $parts[$k]
        if ($isFenceLine) { $inFence = -not $inFence }
        if ($isFenceLine -or $inFence) {
            $parts[$k] = ($parts[$k] -replace '.', ' ')
        }
    }
    return -join $parts
}

# Canonical skillset: every claude-code-plugins/claude-specialists/<plugin>/skills/<name>/SKILL.md
# (exact depth -- plugin, then 'skills', then exactly one skill-name folder, then the file -- so a
# deeper file such as a level-3 progressive-disclosure skills/<name>/references/SKILL.md, should
# that pattern ever appear, is not mistaken for a top-level skill), across ALL plugin folders (not
# just 'specialists' -- specialists-shopify/skills/start-task counts too). The name is read from the
# frontmatter 'name:' (the authoritative Claude Code call name, /plugin:name) rather than the folder
# name; as of this writing every skill's folder name happens to equal its frontmatter name, so this
# made no observable difference here, but frontmatter is the real source of truth if the two ever
# diverge. Falls back to the folder name only if 'name:' is missing from the frontmatter, so a
# future skill without that line does not silently drop out of the canonical set (not a new failure
# mode: the frontmatter's own presence/shape is check 3's domain, not this one's).
$skillCanonicalList = New-Object System.Collections.Generic.List[string]
$skillsRoot = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists'
if (Test-Path -LiteralPath $skillsRoot) {
    Get-ChildItem -Path $skillsRoot -Recurse -Filter 'SKILL.md' -File |
        Where-Object { $_.FullName -match '\\skills\\[^\\]+\\SKILL\.md$' } | ForEach-Object {
            $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
            $nm = [regex]::Match($text, '(?m)^name:\s*(\S+)\s*$')
            if ($nm.Success) {
                $skillCanonicalList.Add($nm.Groups[1].Value.Trim())
            } else {
                $skillCanonicalList.Add((Split-Path (Split-Path $_.FullName -Parent) -Leaf))
            }
        }
}
$skillCanonicalSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($n in $skillCanonicalList) { [void]$skillCanonicalSet.Add($n) }

$skillBeginRegex = [regex]'<!--\s*skills:all\s*-->'
$skillEndRegex = [regex]'<!--\s*/skills:all\s*-->'
$skillSpanCount = 0
foreach ($lf in $linkFiles) {
    $content = [System.IO.File]::ReadAllText($lf, [System.Text.Encoding]::UTF8)
    # Masked, not raw: a fenced example of the marker syntax must not be read as a live marker (see
    # Get-FenceMaskedText above). Same length + same newline positions as $content, so offsets
    # derived from it (line numbers, substrings) still point at the right place; a genuine span is
    # never inside a fence -- if it were, masking would make it invisible, not "found but wrong".
    $maskedContent = Get-FenceMaskedText -Text $content
    $rel = $lf.Replace($RepoRoot, '.')
    # Every END match that actually closes a valid span is recorded here by its offset, so the
    # sweep after the loop (below) can tell an END that legitimately paired with a BEGIN apart from
    # one that did not -- a stray END before any BEGIN, or a SECOND END pasted inside an
    # already-open span (the main loop below only ever consumes the FIRST END after a BEGIN, so a
    # duplicate further down would otherwise just sit there as silent, unchecked prose instead of
    # being reported).
    $consumedEndIndices = New-Object System.Collections.Generic.HashSet[int]
    $searchStart = 0
    while ($searchStart -le $maskedContent.Length) {
        $beginMatch = $skillBeginRegex.Match($maskedContent, $searchStart)
        if (-not $beginMatch.Success) { break }
        $beginLineNo = 1 + [regex]::Matches($maskedContent.Substring(0, $beginMatch.Index), "`n").Count
        $spanStart = $beginMatch.Index + $beginMatch.Length
        $endMatch = $skillEndRegex.Match($maskedContent, $spanStart)
        if (-not $endMatch.Success) {
            # Unpaired marker is a hard error, never a silent pass -- same principle as the
            # BEGIN-without-END guard in agent-shared-lib.ps1's Expand-AgentDefShared (check 7): a
            # typo'd sentinel must not read as "no span here". Keep scanning past it (rather than
            # abandoning the whole file) so a later, well-formed pair further down still gets
            # checked instead of being silently skipped because an earlier marker was malformed.
            # (A BEGIN inside a fence never reaches this branch at all -- it was masked to
            # whitespace before the match, so $skillBeginRegex simply never sees it there.)
            Add-Error "[skill-list] ${rel}: '<!-- skills:all -->' at line $beginLineNo has no matching '<!-- /skills:all -->'."
            $searchStart = $spanStart
            continue
        }
        [void]$consumedEndIndices.Add($endMatch.Index)
        $skillSpanText = $maskedContent.Substring($spanStart, $endMatch.Index - $spanStart)
        $skillFoundNames = [regex]::Matches($skillSpanText, '`([^`\r\n]+)`') | ForEach-Object { $_.Groups[1].Value }
        $skillFoundSet = New-Object System.Collections.Generic.HashSet[string]
        foreach ($n in $skillFoundNames) { [void]$skillFoundSet.Add($n) }
        $skillMissing = @($skillCanonicalSet | Where-Object { -not $skillFoundSet.Contains($_) } | Sort-Object)
        $skillExtra = @($skillFoundSet | Where-Object { -not $skillCanonicalSet.Contains($_) } | Sort-Object)
        if ($skillMissing.Count -gt 0) {
            Add-Error "[skill-list] ${rel}: <!-- skills:all --> span at line $beginLineNo is missing: $($skillMissing -join ', ')."
        }
        if ($skillExtra.Count -gt 0) {
            Add-Error "[skill-list] ${rel}: <!-- skills:all --> span at line $beginLineNo lists name(s) that are not a known skill: $($skillExtra -join ', ')."
        }
        $skillSpanCount++
        $searchStart = $endMatch.Index + $endMatch.Length
    }
    # Symmetric sweep: the loop above only ever walks forward from a BEGIN, so an END that sits
    # BEFORE any BEGIN (a lone orphan) or a SECOND END inside an already-open span (only the first
    # one after a BEGIN gets consumed above) is never visited by it at all -- it would otherwise
    # vanish into ordinary, unchecked prose instead of being reported. Every END match in the
    # (already fence-masked) text that was NOT recorded as a real span's closer above is therefore
    # a hard error here, mirroring the BEGIN-without-END error the same way.
    foreach ($m in $skillEndRegex.Matches($maskedContent)) {
        if ($consumedEndIndices.Contains($m.Index)) { continue }
        $endLineNo = 1 + [regex]::Matches($maskedContent.Substring(0, $m.Index), "`n").Count
        Add-Error "[skill-list] ${rel}: '<!-- /skills:all -->' at line $endLineNo has no matching '<!-- skills:all -->'."
    }
}
if ($skillSpanCount -eq 0) {
    Write-Host "  [skill-list] 0 <!-- skills:all --> span(s) found -- opt-in, so this is a pass." -ForegroundColor DarkGray
} else {
    Write-Host "  [skill-list] checked $skillSpanCount <!-- skills:all --> span(s) against $($skillCanonicalSet.Count) canonical skill(s)." -ForegroundColor DarkGray
}

# --- 11. printed lifecycle commands carry their flags --------------------------------------------------
# THE CLASS THIS CLOSES. Three adoption rounds in a row (v3, v4, v5) found the same kind of defect and
# nothing else: a doc place printing a command, a count or a step that no longer holds. v3 was the
# adoption path plus three reporting errors, v4 was inbound #279 + #280, v5 was all four of its findings
# -- and three of the five repairs in 3.0.3 were of that kind too. Four doc fixes close four instances;
# the instances came back every round. This closes the half of the class a regex can actually decide:
# a printed `claude plugin install|update|uninstall` must carry `--scope project`, and install/update
# must have the marketplace refresh named nearby. Both are things a reader COPIES, and both fail
# silently when wrong -- a scopeless install writes a machine-wide record with no projectPath and
# reports success (inbound #274/#279), a stale cache reports success with a plausible version number
# (inbound #282/#284).
#
# THE TWO RULES REST ON DIFFERENT FOOTING, AND THE COMMENT SAYS SO RATHER THAN FLATTENING IT. The scope
# rule and the refresh-next-to-INSTALL rule each rest on a measured silent failure. The
# refresh-next-to-UPDATE half does not: measured 2026-07-31 (CLI 2.1.220) right after v3.0.4, with the
# cached clone verifiably still on the pre-release commit, a bare project-scoped update moved
# 3.0.3 -> 3.0.4 AND advanced the clone itself during the run -- so `update` refreshed for itself, and
# the older claim that skipping the refresh makes an update serve the previous version did not survive
# testing. The rule is kept anyway (Dave, 2026-07-31): the refresh is idempotent, it is one command, and
# a stale cache is invisible by construction, so the docs should keep naming it. What changed is the
# wording -- prudence, not a mechanism claim. Keeping that distinction visible here is the point: this
# check exists because doc claims drifted from measured reality, and it must not become an instance of
# that itself.
#
# THE DISCRIMINATOR, and it is the whole reason this can be a generic scan where check 10 could not be.
# A command with an explicit @-TARGET is an instruction someone runs:
#     claude plugin install specialists@davekjohns-workshop --scope project
#     claude plugin update <plugin>@<marketplace> --scope project
# A BARE mention is prose discussing the command, and demanding flags there would be nonsense:
#     "`claude plugin update` has the same default", "Because `claude plugin update` pins the cache"
# Measured over the scan set before this check was written: 10 targeted, 13 bare. That separation is
# what keeps this from becoming the 147-hit over-detection that made check 10 opt-in instead.
#
# HISTORY IS EXCLUDED, deliberately and permanently: CHANGELOG.md (root and per-plugin), releases/**,
# every RELEASE.md card, and the root changelog ENTRY files. Those record what was true at the time and
# are never rewritten -- the same principle the teardown's own audit applies when it excludes history
# from its scan. specialists/CHANGELOG.md:162 proves the need: it prints a targeted install with no
# scope flag, correctly, because that is what the release it describes actually said.
#
# SPANS, NOT LINES. A printed command wraps across a newline in running prose -- the teardown SKILL's
# `claude plugin uninstall <plugin>@<marketplace>` carries its `--scope project` on the NEXT line, inside
# the same inline-code span. A line-based check calls that a violation (it did, on the first probe run).
# So the unit is the enclosing inline-code span where there is one, and the rest of the physical line
# otherwise (which is the right unit inside a fenced block, where one command is one line).
#
# And the spans are computed over the FENCE-MASKED text, reusing check 10's Get-FenceMaskedText. Without
# that, a ```-fence delimiter throws off backtick pairing for the whole rest of the file: the regex
# cannot start a span on the first two backticks of a ``` run, starts one on the third, and closes it on
# the first backtick of the CLOSING fence -- after which every real inline span downstream is paired one
# position out. That is what made the wrapped uninstall above look flagless on the second run, and it is
# a silent misread rather than an error, so it is worth naming here. Masking keeps offsets and newline
# positions identical, so a span found in the mask indexes straight back into the real text.
#
# PRESENCE, NOT ORDER. The refresh window reaches 12 lines back and 6 forward, so a doc that names the
# refresh in the sentence just below the block still passes. Whether the refresh is described BEFORE the
# install in reading order is a judgement about prose, not something this regex should pretend to make;
# the check guarantees the step is named in the same instruction context, and a reviewer judges the rest.
# THE SCOPE RULE IS VERB-SPECIFIC, and `uninstall` is the exception rather than a loophole in it. For
# `install`/`update`, `project` is the only correct value and the rule rests on a measured silent failure
# (#274/#279). For `uninstall` it does not: a record sitting at `scope=local` is what a SESSION START
# leaves behind -- enabling a plugin is enough for one to create a record, and to flip an existing
# `project` record to `local`, with no command run (inbound #314) -- and `claude plugin uninstall ...
# --scope project` REFUSES to remove such a record ("Plugin ... is installed in local scope, not
# project", inbound #315). Demanding `project` on every printed uninstall would therefore make this gate
# reject the only command that does the job, i.e. it would enforce the very assumption round v8 disproved:
# that `project` is the only scope a consumer can be in. So `uninstall` accepts `project` OR `local`, and
# the other two verbs keep the stricter rule. Widening this to install/update would be wrong: nothing
# measured says a `local` install is ever what a reader wants.
$lcCmdRegex     = [regex]'claude\s+plugin\s+(?<verb>install|update|uninstall)\b'
$lcTargetRegex  = [regex]'(?:<plugin>@<marketplace>|[A-Za-z0-9_.\-]+@[A-Za-z0-9_.\-]+)'
$lcSpanRegex    = [regex]'(?s)`[^`]+`'
$lcScopeRegex   = [regex]'--scope\s+project'
$lcScopeUninstallRegex = [regex]'--scope\s+(?:project|local)'
$lcRefreshRegex = [regex]'claude\s+plugin\s+marketplace\s+update|staying-up-to-date'

$lifecycleFiles = @($linkFiles | Where-Object {
    $rel = $_.Substring($RepoRoot.Length).TrimStart('\', '/')
    if ($rel -eq 'CHANGELOG.md') { return $false }
    if ($rel -match '\\CHANGELOG\.md$') { return $false }
    if ($rel -match '(^|\\)RELEASE\.md$') { return $false }
    if ($rel -match '^releases\\') { return $false }
    # A root <branch-name>.md entry file is history in the making; same reasoning as CHANGELOG.md.
    if (($rel -notmatch '\\') -and (Test-IsChangelogEntryFile -Path $_)) { return $false }
    return $true
})

$lcEnforced = 0
$lcBare = 0
foreach ($lf in ($lifecycleFiles | Sort-Object -Unique)) {
    $rel = $lf.Substring($RepoRoot.Length).TrimStart('\', '/')
    $content = [System.IO.File]::ReadAllText($lf, [System.Text.Encoding]::UTF8)
    $lcLines = $content -split "`r?`n"
    $lcMasked = Get-FenceMaskedText -Text $content
    # Inline-code spans, once per file, found in the MASKED text and read out of the real one.
    $spans = @($lcSpanRegex.Matches($lcMasked) | ForEach-Object {
        [pscustomobject]@{ Start = $_.Index; End = ($_.Index + $_.Length) }
    })
    foreach ($m in $lcCmdRegex.Matches($content)) {
        # Inside a fence the mask has whitespace where the real text has the command, and there the unit
        # is the physical line -- a fenced command is one line, and its own backticks (if any) are not
        # span delimiters.
        $inFence = ($lcMasked[$m.Index] -ne $content[$m.Index])
        $cmdText = $null
        $cmdStart = -1
        if (-not $inFence) {
            foreach ($s in $spans) {
                if ($m.Index -ge $s.Start -and $m.Index -lt $s.End) {
                    $cmdText = $content.Substring($s.Start, $s.End - $s.Start)
                    $cmdStart = $s.Start
                    break
                }
            }
        }
        if (-not $cmdText) {
            $eol = $content.IndexOfAny([char[]]@("`r", "`n"), $m.Index)
            if ($eol -lt 0) { $eol = $content.Length }
            $cmdText = $content.Substring($m.Index, $eol - $m.Index)
            $cmdStart = $m.Index
        }
        # Everything after THIS match's verb decides whether this is an instruction or a mention. The
        # offset is derived from the match position, not from IndexOf($verb) in the span: a span holding
        # two commands with the same verb would otherwise judge the second one on the first one's tail.
        # Clamped: a malformed span whose closing backtick lands mid-command would otherwise throw and
        # take the whole gate down over a typo in a doc. An empty tail simply reads as "no target".
        $verbEnd = [Math]::Min([Math]::Max(0, ($m.Groups['verb'].Index + $m.Groups['verb'].Length) - $cmdStart), $cmdText.Length)
        $afterVerb = $cmdText.Substring($verbEnd)
        # THIS command's arguments only: from its own verb up to the next lifecycle command, or the end
        # of the span/line. Both rules below judge that slice rather than the whole span, because a span
        # can hold two commands -- and then the second would borrow the first one's `--scope project`
        # and read as correct while a reader copies a scopeless line (Victor, on this check's own code).
        $nextCmd = [regex]::Match($afterVerb, 'claude\s+plugin\s+(?:install|update|uninstall)\b')
        $cmdArgs = if ($nextCmd.Success) { $afterVerb.Substring(0, $nextCmd.Index) } else { $afterVerb }
        if (-not $lcTargetRegex.IsMatch($cmdArgs)) { $lcBare++; continue }
        $lcEnforced++
        $lineNo = 1 + [regex]::Matches($content.Substring(0, $m.Index), "`n").Count
        $verb = $m.Groups['verb'].Value
        $scopeOk = if ($verb -eq 'uninstall') { $lcScopeUninstallRegex.IsMatch($cmdArgs) } else { $lcScopeRegex.IsMatch($cmdArgs) }
        if (-not $scopeOk) {
            $wanted = if ($verb -eq 'uninstall') { "'--scope project' (or '--scope local', the only way to remove a record a session start left at local scope -- inbound #314/#315)" } else { "'--scope project'" }
            Add-Error "[lifecycle] ${rel}:${lineNo}: printed 'claude plugin $verb' with an @-target but no $wanted. All three default to --scope user, which writes a machine-wide record with no projectPath and reports success (inbound #274/#279). Add the flag, or drop the @-target if this line is discussing the command rather than telling a reader to run it."
        }
        if ($verb -ne 'uninstall' -and -not $lcRefreshRegex.IsMatch(($lcLines[[Math]::Max(0, $lineNo - 13)..[Math]::Min($lcLines.Count - 1, $lineNo + 5)] -join "`n"))) {
            Add-Error "[lifecycle] ${rel}:${lineNo}: printed 'claude plugin $verb' with an @-target, but neither 'claude plugin marketplace update' nor a link to 'staying-up-to-date' appears within 12 lines above or 6 below. The marketplace is a cached clone and a stale one reports success with a plausible version number, so the refresh belongs next to a printed install/update. Measured for 'install' on 2026-07-30 (it served the previous version); a bare 'update' refreshed the clone for itself on 2026-07-31, so for that verb this is prudence rather than a measured failure. Quoting a command as the SUBJECT of prose rather than as an instruction? Elide the target as '...', the repo's convention."
        }
    }
}
Write-Coverage -Category 'lifecycle' -Checked $lcEnforced `
    -Note $(if ($lcEnforced -eq 0) { 'no printed lifecycle command with an @-target anywhere in the scan set -- nothing to enforce, which is not the same as the docs being right' } else { "$lcBare bare mention(s) skipped as discussion; history (CHANGELOG.md, releases/, RELEASE.md, entry files) excluded" })

# --- Check 12: a printed install-record query must name the fields that disambiguate the state -----
# THE CLASS, and why this is a gate rather than three doc fixes. Round v8 produced three findings that
# read as unrelated and are one: the family's own verification query -- the thing every document points a
# reader at to answer "what am I actually running?" -- printed a green that UNDER-DETERMINED the state it
# claimed to prove. It could not distinguish
#   - the release from `main` after it            (#313: `version` reads 3.0.8 on both; only gitCommitSha
#                                                  differs, and that field was printed nowhere),
#   - one record from two                         (#315: the prescribed repair install ADDS a record, and
#                                                  the line count was the only signal),
#   - `project` from `local`                      (#314: which is what a session start leaves behind).
# Three instances closed by three doc edits would have been the fourth adoption round in a row to close
# instances of a class that came back. This closes the half a regex can decide: whether the query a doc
# PRINTS still selects every field a reader needs to tell those states apart. Sibling of check 11 in
# footing and in shape -- both hold a copied instruction to what was measured rather than to itself -- and
# it shares check 11's scan set, so history is excluded here for the same reason.
#
# THE DISCRIMINATOR: the block must READ the administration IN CODE (it names installed_plugins.json and
# parses it). That is what separates an instruction someone copies from a doc merely discussing the file --
# the same mention-versus-use question check 11 answers with the @-target, and the third time this repo has
# had to answer it (see the MENTION vs USE rule in Sylvester's lens). A JSON snippet ILLUSTRATING a record
# is therefore out of scope even though it names the same fields: it teaches the file's shape, it is not a
# command whose output someone reads a verdict off.
#
# projectPath IS ONE OF THE REQUIRED FIELDS, not part of the discriminator, and that is deliberate: a query
# that reads the administration WITHOUT filtering on projectPath is exactly the `claude plugin list` mistake
# both documents spend a paragraph warning about -- it reports records beyond this repo and so cannot carry
# a verdict about this one. A doc printing that would be reproducing the very defect it warns against.
#
# Matching is case-INSENSITIVE on purpose. The reader copies these to run them, and PowerShell property
# access is case-insensitive, so `$_.Version` is as correct as `$_.version`; demanding the JSON file's exact
# casing would report a working query as broken. Erring this way can only miss a miscased field, never
# invent a finding -- the same direction check 11 and Get-RecordShape both chose.
$irRequiredFields = @('projectPath', 'scope', 'version', 'gitCommitSha')

$irChecked = 0
$irMentions = 0
foreach ($lf in ($lifecycleFiles | Sort-Object -Unique)) {
    $rel = $lf.Substring($RepoRoot.Length).TrimStart('\', '/')
    $content = [System.IO.File]::ReadAllText($lf, [System.Text.Encoding]::UTF8)
    $irLines = $content -split "`r?`n"
    # Fenced blocks, walked with the SHARED fence-toggle primitive (Test-FenceDelimiterLine) that
    # Get-HeadingSlugs and Get-FenceMaskedText already use -- one fence notion in this file, not a third
    # hand-rolled one. The mask itself is no use here: it replaces a fence's contents with whitespace, and
    # this check needs exactly those contents.
    $inFence = $false
    $blockBody = @()
    $blockLine = 0
    for ($i = 0; $i -lt $irLines.Count; $i++) {
        if (Test-FenceDelimiterLine -Line $irLines[$i]) {
            if (-not $inFence) {
                $inFence = $true
                $blockBody = @()
                $blockLine = $i + 2   # 1-based line of the first line INSIDE the fence
            } else {
                $inFence = $false
                $body = ($blockBody -join "`n")
                if ($body -match 'installed_plugins\.json' -and $body -match 'ConvertFrom-Json') {
                    $irChecked++
                    $missing = @($irRequiredFields | Where-Object { $body -notmatch [regex]::Escape($_) })
                    if ($missing.Count -gt 0) {
                        Add-Error "[record-query] ${rel}:${blockLine}: a printed query that reads installed_plugins.json does not name $(($missing | ForEach-Object { "'$_'" }) -join ', '). A reader runs this to answer 'what am I actually running?', and without every one of $(($irRequiredFields | ForEach-Object { "'$_'" }) -join ', ') the output cannot carry that verdict: 'version' cannot tell the release from main after it (inbound #313), the record COUNT is the only signal of the stray second record a repair install leaves (#315), 'scope' is what a session start silently flips to 'local' (#314), and without 'projectPath' the query reports records beyond this repo -- the 'claude plugin list' mistake these same docs warn about. Add the field, or move the snippet out of a fenced code block if it is illustrating the file's shape rather than telling a reader to run it."
                    }
                } elseif ($body -match 'installed_plugins\.json') {
                    $irMentions++
                }
            }
            continue
        }
        if ($inFence) { $blockBody += $irLines[$i] }
    }
}
# The skip count belongs in BOTH branches, which the test suite established rather than the design: an
# empty scan that had skipped an illustration reads identically to one that saw nothing about the file at
# all, and those are different states. "Nothing to enforce" plus "and one block was deliberately not
# judged" is the honest pair -- the same reasoning as the [COVERAGE] rule itself (issue #221).
$irSkipNote = "$irMentions fenced block(s) naming the file without parsing it skipped as illustration"
Write-Coverage -Category 'record-query' -Checked $irChecked `
    -Note $(if ($irChecked -eq 0) { "no printed query reads installed_plugins.json anywhere in the scan set -- nothing to enforce, which is not the same as the docs being right ($irSkipNote)" } else { "$irSkipNote; history excluded as in check 11" })

# --- Report ---------------------------------------------------------------------------------------------
if ($errors.Count -eq 0) {
    Write-Host "  No findings." -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary: 0 error(s)." -ForegroundColor Cyan
    exit 0
}
foreach ($e in $errors) { Write-Host "  $e" -ForegroundColor Red }
Write-Host ""
Write-Host "Summary: $($errors.Count) error(s)." -ForegroundColor Cyan
exit 1
