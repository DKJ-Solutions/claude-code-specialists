<#
.SYNOPSIS
    Integrity check for the claude-code-specialists marketplace: validates the manifests, the
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
      4. dead relative links AND broken anchors in every ROOT *.md (README.md, CHANGELOG.md, CLAUDE.md,
         CONTRIBUTING.md, SECURITY.md, plugins/INSTALL.md, plugins/UNINSTALL.md and any unfolded changelog entry file
         -- globbed, never named), every .claude/extensions/*.md, every <plugin>/skills/*/SKILL.md, every
         <plugin>/manuals/*-manual.md, every <plugin>/personas/*-persona.md, every releases/**/*.md,
         every <plugin>/RELEASE.md, connectors/README.md, and
         every plugin's own plugins/<plugin>/CHANGELOG.md (#103).
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

     13. entry-heading levels: an entry is an H2 with three named H3 sections, and a body heading may be
         neither. At or above the entry's own level it becomes a SEPARATE entry the moment the fold pastes
         it into CHANGELOG.md -- one declaring no impact, so filed as an undeclared tier 0 -- or, at H1,
         climbs above every entry in the document (seen in v2.13.2). At the SECTION level it truncates the
         section it lands in, and if it is a misspelling of a real section heading the entry silently loses
         that declaration and the tier/significance gates read nothing. Every level comes from
         entry-scaffold-lib.ps1 rather than being written out here. Judged in every unfolded root entry
         file (line 1 skipped, so a pre-format H3 entry still passes) and in CHANGELOG.md below its intro,
         where the intro/entries boundary is derived structurally exactly as Split-Changelog derives it.
     14. encoding: scripts/maintenance/fix-mojibake.ps1 -Check is run as the gate. WHICH files it walks
         is repo-owned since issue #413 -- Get-MojibakePaths in scripts/repo-config.ps1 names them, here
         every *.md in the root, every *.md under plugins/, and every note under releases/. A UTF-8
         character read as ANSI and written back changes the text with no error -- and in an entry
         heading the separator IS the field delimiter, so cut-release.ps1 stops being able to read the
         entry type.
     15. unbound output samples: a fenced block with no language (or 'text') is something the reader
         COMPARES against, so something near it must say what the capture is bound to -- a version, a
         date, a platform, a repo state, or a hedge. Four of test round v11's nine findings were this
         one shape. Blocks tagged powershell/json/jsonc are commands to RUN and are left alone; so are
         blocks containing box drawing, which are drawn rather than captured.
     16. measured figures in prose: check 15's subject one step outside a fence -- a byte count or file
         size in the consumer-facing docs is a measurement of somebody's machine, and the surrounding
         paragraphs must say whose (round v12 filed exactly this as #374).
     17. per-plugin CHANGELOG intro: the header above each plugins/<plugin>/CHANGELOG.md's first
         '## vX.Y.Z' heading must still match what Build-PluginChangelogIntro (scripts/lib/release-lib.ps1)
         generates, with the marketplace name read from marketplace.json. cut-release.ps1 writes that
         header ONLY for a CHANGELOG that does not exist yet, so it is never refreshed -- which is how all
         four files kept naming the retired marketplace after the rename swept it out of 59 others.
         Compared whitespace-normalized (content, not line wrapping); everything below the first version
         heading is history and deliberately not examined, as in checks 11 and 12.
     18. shared-script parameters vs. their skill: every parameter of a mirrored entry point must be named
         in the skill that documents it (the mapping lives in the shared-scripts registry, beside the
         registration). A consumer has only the mirror and its page, so a parameter the page never names
         does not exist for them -- including the escape valve they need when something goes wrong. This is
         a repair: the fold skill told consumers to commit by hand for two days after the script gained
         -Commit/-Push, and four more were found the same way, -Bump and -NoPush among them. Parameters are
         read via the PowerShell parser (a regex missed an attributed one). Per-script exemptions are
         declared in the registry; an entry point declaring no skill at all is reported in the coverage
         line rather than as an error, since writing a missing skill is separate work.

    Exit code: 0 = no errors. 1 = at least one error (usable as a gate in open-pr.ps1).
.EXAMPLE
    ./scripts/lint/check-plugin-integrity.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$errors = New-Object System.Collections.Generic.List[string]

# EVERY FINDING GOES THROUGH HERE, and that is load-bearing rather than tidy. Until August 6, 2026 the
# checks below were split between this function and sixteen bare '$errors += "..."' lines. On a List[T],
# '+=' does not append -- it rebuilds the whole thing as a fixed-size Object[] and rebinds $errors to it,
# after which EVERY later Add-Error throws "the collection is of a fixed size" and the run dies mid-scan.
# It never fired because the ordering hid it: all Add-Error callers happened to sit above the first '+=',
# so the array only ever came into being after the last one. The first check added below that line found
# it immediately. Adding a finding must not depend on where in the file you add it.
function Add-Error([string]$Msg) { $script:errors.Add($Msg) }

# Write-Coverage: the shared, non-counting [COVERAGE] line (issue #221), so every category below states
# how many items it examined and an empty one announces itself instead of passing in silence. Only that
# function is used from this lib; its counting report helpers (Write-Info/Write-Failure) stay unused and
# would in fact be wrong here -- this script's $errors is a List[string], not an int counter -- exactly
# the deliberate, documented non-collision check-consumer-drift.ps1 already relies on.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

# release-lib supplies the pure helpers this gate reads the release layer through: Get-MarketplaceName,
# Get-PluginManifestPaths and Split-Changelog. It used to name Build-PluginChangelogIntro and check 17 here
# instead; both went with the per-plugin CHANGELOG and RELEASE.md on August 8, 2026, and this line outlived
# them by one day -- a comment naming a deleted function as the reason for an import, which is the same
# class of drift check 20 below was widened for.
#
# Dot-sourced here with the other lib rather than mid-file, so every import this gate depends on is visible
# in one place. release-lib deliberately sets no strict mode of its own, so it cannot loosen this script's
# Set-StrictMode -Version Latest.
. (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

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
    # A changelog entry file (new-branch.ps1) opens with its own heading; permanent root docs
    # (README, CHANGELOG, CONTRIBUTING, SECURITY, ...) open with an H1. Same structural signature
    # fold-changelog-entry.ps1 keys off, and BOTH levels are accepted for the same reason it accepts
    # them: an entry file lives only on a branch, so a branch created before August 5, 2026 still
    # carries the older H3 shape, and the fold promotes it as it lands.
    #
    # THE LEVEL IS READ FROM THE FORMAT LIB, NOT RESTATED, and that repair is the point. This function
    # used to hardcode '^###\s' with a comment explaining that restating it was deliberate, because
    # importing meant dot-sourcing the fold script -- which would RUN a release action to answer a
    # lint question. That reasoning was sound and its conclusion went stale the moment the entry format
    # moved into entry-scaffold-lib.ps1, a pure lib this file already loads through release-lib.ps1.
    # Measured August 5, 2026: entries had been H2 since the format changed and this copy still looked
    # for H3, so the gate recognised NO entry file at all -- check 13 below silently judged nothing and
    # reported clean, and check 11 stopped excluding entry files from its scan set. Exactly the
    # duplicated-fact failure the rest of this file exists to prevent, in the helper that answers
    # "what is an entry".
    param([Parameter(Mandatory = $true)][string]$Path)
    $entryLevel = Get-EntryHeadingLevel
    $rx = '^#{' + $entryLevel + ',' + ($entryLevel + 1) + '}\s'
    foreach ($line in [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        return ($line -match $rx)
    }
    return $false
}

$linkFiles = @()
# EVERY ROOT *.md, ENUMERATED AND NOT NAMED, AND THAT IS THE POINT. This used to be a hardcoded list
# of four root documents PLUS a glob over the family directory that held QUICKSTART.md, UNINSTALL.md and
# the family README. Both halves were the same class of bug seen twice: the family glob replaced a
# hardcoded list of two ('README.md', 'QUICKSTART.md') that had gone stale the moment UNINSTALL.md was
# written beside them and no gate saw it -- not the dead-link scan, not check 11 (printed lifecycle
# commands), not check 12 (the install-record query), all three of which derive their scan set from
# $linkFiles. A brand-new consumer-facing page, printing exactly the class of command those two checks
# exist to police, was invisible on the run that introduced it.
#
# #405 moved those three documents INTO the root, which would have left the remaining named list as the
# only rule over the exact directory the class of defect lives in -- so the root gets the glob the family
# directory had, for the same reason: a list is only ever correct until the next document is written, and
# nothing announces the omission. Non-recursive on purpose; every subdirectory is gathered by its own rule
# below and would otherwise be picked up twice.
#
# This also subsumes the root changelog ENTRY files added in #234 (see the note further down on why they
# belong here) and picks up SECURITY.md, which no rule had ever covered.
$linkFiles += @(Get-ChildItem -Path $RepoRoot -Filter '*.md' -File |
    Select-Object -ExpandProperty FullName)
# AND THE SAME GLOB OVER plugins/, FOR THE SAME REASON, because that is where those three documents now
# live. ADOPTION.md, QUICKSTART.md and UNINSTALL.md moved out of the root, and the rules below reach into
# plugins/ only for CHANGELOG.md, SKILL.md, manuals and personas -- so a document sitting directly in
# plugins/ matched NO rule and left the scan set without a word. Measured on the move: all three went dark
# at once, every one of their own outbound links unvalidated, while the run still reported clean. That is
# the omission this file's root glob exists to prevent, arriving through the other side. Non-recursive on
# purpose, exactly as above: every subdirectory is gathered by its own rule below.
#
# GUARDED BY Test-Path, unlike the root glob, because $RepoRoot always exists and plugins/ does not: a
# consumer has no plugins/ at all, and neither does a lint fixture that never creates one. Without the
# guard Get-ChildItem raises ItemNotFound there -- which is how the first version of this line broke the
# test suite in a place that had nothing to do with links.
$pluginsRootDir = Join-Path $RepoRoot 'plugins'
if (Test-Path -LiteralPath $pluginsRootDir) {
    $linkFiles += @(Get-ChildItem -Path $pluginsRootDir -Filter '*.md' -File |
        Select-Object -ExpandProperty FullName)
}
# AND THE THIRD, ARRIVING THE SAME WAY: branch/ -- the entry and the step list. They used to be root *.md
# and were therefore covered by the root glob; the branch/ split moved them one level down. Same omission
# as the plugins/ one above and worth stating separately rather than merging the two comments, because
# these two documents went dark in the same week for two unrelated reasons -- which is the actual lesson
# about this scan set: a file leaves it by MOVING, and nothing reports that it has.
#
# RECURSIVE here, unlike the two globs above, because branch/ has a subdirectory: templates/. Those files
# are prose somebody pastes from, so a dead link in one is copied forward into every branch that uses it.
$branchDirForLinks = Join-Path $RepoRoot ((Get-BranchFilePaths).Directory)
if (Test-Path -LiteralPath $branchDirForLinks) {
    $linkFiles += @(Get-ChildItem -Path $branchDirForLinks -Recurse -Filter '*.md' -File |
        Select-Object -ExpandProperty FullName)
}
# The specialists handbook lives next to the lenses (at family level) -- validate its links too.
$handbook = Join-Path $RepoRoot '.claude\plugins\claude-specialists\README.md'
if (Test-Path -LiteralPath $handbook) { $linkFiles += $handbook }
# Every plugin's own CHANGELOG.md (the consumer-facing card that cut-release.ps1 updates) did not yet
# belong to the scan set -- added (#103).
# The connectors README (connectors/) did not yet belong to
# the scan set either -- added alongside CONTRIBUTING.md (#159 follow-up, spotted by Edith).
$connectorsReadme = Join-Path $RepoRoot 'connectors\README.md'
if (Test-Path -LiteralPath $connectorsReadme) { $linkFiles += $connectorsReadme }
$linkFiles += (Get-ChildItem -Path (Join-Path $RepoRoot 'plugins') -Recurse -Filter 'CHANGELOG.md' -File |
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
# THE AGENT DEFS, THE SHARED BLOCKS, AND THE TWO CONFIG-ADJACENT DOC LAYERS (#481). Every category above
# names a shape of file, and four kinds of markdown matched none of them: */agents/*.md (26 files),
# plugins/agent-shared/*.md (11), .github/**/*.md (2) and .claude/rules/*.md (1). Agent defs are the
# glaring one -- they are the largest single body of prose this repo ships, they are payload, and their
# links had never been read by anything. Measured on the day this was added: one genuinely dead link had
# been sitting in an agent def, plus the location-dependent CLAUDE.md links repaired alongside it.
#
# Manuals and personas already have a rule each, so this is the same family finally covered in full. Each
# directory is guarded, for the reason the plugins/ glob is: a consumer has some of these and not others.
foreach ($payloadSpec in @(
    @{ Dir = 'plugins';        Recurse = $true;  Filter = '*.md'; Match = '\\agents\\' },
    @{ Dir = 'plugins\agent-shared'; Recurse = $false; Filter = '*.md'; Match = $null },
    @{ Dir = '.github';        Recurse = $true;  Filter = '*.md'; Match = $null },
    @{ Dir = '.claude\rules';  Recurse = $false; Filter = '*.md'; Match = $null })) {
    $payloadDir = Join-Path $RepoRoot $payloadSpec.Dir
    if (-not (Test-Path -LiteralPath $payloadDir)) { continue }
    $found = if ($payloadSpec.Recurse) {
        Get-ChildItem -Path $payloadDir -Recurse -Filter $payloadSpec.Filter -File
    } else {
        Get-ChildItem -Path $payloadDir -Filter $payloadSpec.Filter -File
    }
    if ($payloadSpec.Match) { $found = @($found | Where-Object { $_.FullName -match $payloadSpec.Match }) }
    $linkFiles += @($found | Select-Object -ExpandProperty FullName)
}
$releasesDir = Join-Path $RepoRoot 'releases'
if (Test-Path -LiteralPath $releasesDir) {
    $linkFiles += (Get-ChildItem -Path $releasesDir -Recurse -Filter '*.md' -File | Select-Object -ExpandProperty FullName)
}
# Every plugin-carried RELEASE.md card (check 9) links to the full notes and its own
# CHANGELOG.md -- those links need to be validated too.
$linkFiles += (Get-ChildItem -Path $RepoRoot -Recurse -Filter 'RELEASE.md' -File |
    Select-Object -ExpandProperty FullName)
# Root changelog ENTRY files (<branch-name>.md) are covered by the root *.md glob at the top of this
# set, no longer by a rule of their own -- but WHY they must be in it is worth keeping, because the glob
# does not say it. Added to close the window in #234: the gap was structural rather than subtle, since an
# entry file's text lives outside every scanned path while the PR is open and only enters a scanned file
# at FOLD time -- which happens directly on main, past every PR gate. So the sequence was: CI green on the
# PR (text in an unscanned file) -> the fold introduces the error on main -> nothing reviews the fold,
# because it is one of the two sanctioned direct-on-main actions -> the next full gate run is
# cut-release.ps1, which refuses to release. That is how v2.13.0 was blocked by a changelog sentence.
#
# Scanning them means the PR gate sees exactly the text the fold will paste into CHANGELOG.md, so the
# error surfaces where it can still be reviewed. Their links are validated at ROOT position, which is
# correct twice over: the entry file sits in the root, and CHANGELOG.md -- where it is headed -- is in the
# root too, so a relative link that resolves here resolves there. Checks 11 and 12 exclude them again by
# name, since an entry file is history in the making (see $lifecycleFiles below).
#
# Note this covers check 10 (the skills:all spans) as well, since that check reuses this same set --
# and check 10 is precisely what #234 tripped over.

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
    # HTML comments too, for the same reason as code: nothing in one is a rendered link. This became a
    # real finding the moment the entry format grew guidance comments -- one of them shows the closing
    # line the fold writes, '[PR #NN](url) - merged <date>', and the scanner reported 'url' as dead.
    # Illustrating a link is not publishing one.
    $scan = [regex]::Replace($scan, '(?s)<!--.*?-->', '')
    # Persona templates are destined for .claude/extensions/ of a consuming repo; their relative
    # links need to resolve THERE, not at the source location in the plugin. So validate them as if
    # the file were already at that destination (this repo mirrors the consumer layout).
    #
    # THE CHANGELOG ENTRY IS THE SECOND CASE OF THE SAME RULE (August 6, 2026). Its text is pasted
    # verbatim into CHANGELOG.md at the repo root, so its links have to resolve THERE -- and until the
    # branch/ split they did by construction, because the entry file itself sat in the root. Moving it one
    # level down turned every root-relative link in an entry into a dead one: measured on the first entry
    # written after the move, with five more of the same shape already pending in CHANGELOG.md. Validating
    # it where the file sits would force authors to write '../' links that break the moment they land.
    #
    # THE STEP LIST IS DELIBERATELY NOT INCLUDED, though it sits in the same directory. It never travels:
    # it is read where it lies and reset in place, so 'where the file sits' IS its destination, and the
    # ordinary '../' convention every other nested document here follows is the correct one for it.
    $entryRelForLinks = ((Get-BranchFilePaths).Changelog -replace '/', '\')
    if ($lf -match '\\personas\\.*-persona\.md$') {
        $dir = Join-Path $RepoRoot '.claude\extensions'
    } elseif ($lf.EndsWith('\' + $entryRelForLinks)) {
        $dir = $RepoRoot
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
#
# The plugin-scripts half is anchored on the plugins root rather than matched as a path segment (#405).
# 'plugins' is not a distinctive name: it is also the leaf of .claude/plugins/, so a segment match would
# widen this check to anything a consumer's plugin layer happens to carry. The old segment name
# ('claude-code-plugins') was unique enough to get away with it; this one is not.
$psScripts = @()
$pluginsRoot = Join-Path $RepoRoot 'plugins'
$psScripts += (Get-ChildItem -Path (Join-Path $RepoRoot 'scripts') -Recurse -Filter '*.ps1' -File)
$psScripts += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*.ps1' -File |
    Where-Object {
        $_.FullName -match '\\skills\\' -or
        ($_.FullName.StartsWith($pluginsRoot + '\') -and $_.FullName -match '\\scripts\\')
    })
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
#
# THE PERSONAS ARE HELD TO THE SAME RULE, and this check has to walk exactly what the generator writes
# or the gate goes quiet on half of them. The generator gained the personas because the two specialists
# whose craft IS a way of working ship as personas rather than agent defs; a gate that kept looking only
# at agents/ would have let a hand-edit inside a persona's sentinels stand, which is the one failure
# this check exists to prevent. Both collections are built from the same two filters as there.
. (Join-Path $PSScriptRoot '..\lib\agent-shared-lib.ps1')
$agentSharedDir = Get-AgentSharedDir -RepoRoot $RepoRoot
# The outer @() is load-bearing, not decoration: Sort-Object returns a SCALAR for a single-element
# collection, and $scalar.Count then throws under StrictMode. The real repo has 30 of these so it would
# never have shown up here -- it surfaced in the fixtures, which are one agent def and no persona.
$sharedBlockFiles = @(@($agentDefs) + @($personas) | Sort-Object FullName)
$sharedBlockFiles | ForEach-Object {
        $raw = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $rel = $_.FullName.Replace($RepoRoot, '.')
        $sharedProblems = New-Object System.Collections.Generic.List[string]
        $expanded = Expand-AgentDefShared -Content $raw -SharedDir $agentSharedDir -Problems $sharedProblems
        foreach ($p in $sharedProblems) { Add-Error "[shared] ${rel}: $p" }
        if ($expanded -ne ($raw -replace "`r`n", "`n")) {
            Add-Error "[shared] ${rel}: shared block deviates from the source -- run scripts/agents/build-agent-defs.ps1."
        }
    }
Write-Coverage -Category 'shared' -Checked $sharedBlockFiles.Count `
    -Note $(if ($sharedBlockFiles.Count -eq 0) { 'no agent def or persona to expand, so no shared block could be compared with its source' } else { 'agent defs AND personas -- the generator writes both, so the gate walks both. A persona is where the specialists whose craft is itself a way of working live, which is exactly where a process block must not be allowed to drift' })

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

# RETIRED, AUGUST 8, 2026 -- check 9 ("RELEASE.md present per plugin + version match").
# It held each plugin's RELEASE.md card against its plugin.json version, on the reasoning that both
# only ever change together via cut-release.ps1, so a mismatch could only be a forgotten regeneration
# or a hand-edit. Correct, and now moot: the cards are gone. A plugin's version has one statement
# again -- plugin.json -- so there is no second copy for a check to compare it with.

# --- 10. marked "all skills" enumerations vs. the canonical skillset -----------------------------------
# A prose bullet list that claims to enumerate "all skills" is a maintenance trap: it silently
# drifts as skills are added/removed, and a generic prose scan over-detects (tested and rejected --
# 147 hits repo-wide, including INSTALL.md's deliberately incomplete illustrative list, which
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
# match), not line-based. The real-world enumerations this exists for (e.g. the root README's
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

# Canonical skillset: every plugins/<plugin>/skills/<name>/SKILL.md
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
$skillsRoot = Join-Path $RepoRoot 'plugins'
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
#     claude plugin install specialists@claude-code-specialists --scope project
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
    # branch/ is the same subject at its new address. Both files: the entry is history in the making, and
    # the step list is a scratch pad that never travels anywhere -- neither is a document a consumer reads
    # a lifecycle command off, which is what this check judges.
    if ($rel -match ('^' + [regex]::Escape((Get-BranchFilePaths).Directory) + '\\')) { return $false }
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

# --- 13. entry heading levels: a body heading cannot become an entry, nor a section of one ---------------
# THE DEFECT, and it is this repo's own, four times in one day. An entry body used a sub-heading at the
# entry's own level, so the two became siblings: after the fold, CHANGELOG.md carried headings with no PR
# number, and the release renderer split an entry on every one of them -- emitting extra "entries" with no
# number, no type and no Plugins line. Rendall's lens already warned about it (seen in v2.13.2, where a
# body heading rendered as a release category). The warning did not stop it, which is the argument for a
# gate rather than a sharper sentence: the rule is exactly checkable, so nobody should have to remember it.
#
# EVERY LEVEL IS READ FROM THE FORMAT LIB (entry-scaffold-lib.ps1, via release-lib.ps1), because the levels
# moved on August 5, 2026 and a hardcoded copy would have gone stale exactly the way this file's own
# Test-IsChangelogEntryFile did. An entry heading is an H2; its three named sections are H3.
#
# WHAT IS NOW WRONG, AND WHY EACH HALF IS A REAL DEFECT RATHER THAN A STYLE RULE:
#   - a heading AT OR ABOVE the entry's own level in a body. An H2 becomes a SEPARATE ENTRY -- Split-Changelog
#     splits on exactly that level -- and the phantom carries no impact table, so it reads as an undeclared
#     tier 0 and gets its own block in the record. An H1 climbs above every entry in the document.
#   - a SECTION-LEVEL heading that is not one of the entry's declared sections. This half is new with the
#     format, and it is not cosmetic: Get-EntrySectionBody ends a section at the next heading of that level
#     or above, so a stray H3 truncates whichever section it lands in -- and a MISTYPED section heading
#     ('Who is this For') is the same shape, silently costing the entry the very declaration the tier and
#     significance gates read. Use '#### ' or bold for a sub-heading; fix the spelling for a section.
#
# TWO PLACES, because they catch it at two different moments:
#   - the root ENTRY FILES, which is where the author can still fix it on the PR. Line 1 is the entry's own
#     heading and is skipped whatever its level -- a pre-format H3 entry file is legitimate, and the fold
#     promotes it as it lands.
#   - CHANGELOG.md below its intro, which is what cut-release actually parses. This half also catches damage
#     that arrived through the fold -- the one write that happens directly on main, past every PR gate (the
#     #234 lesson).
# Fence-aware in both, via the same Get-FenceMaskedText the other checks use: an entry that QUOTES a heading
# inside a code fence is discussing structure, not creating it -- the mention-versus-use question this file
# has now answered four times, and this repo's own changelog and entry files do exactly that.
$ehChecked = 0
$ehEntryLevel   = Get-EntryHeadingLevel
$ehSectionLevel = Get-EntrySectionLevel
# The current names PLUS the retired ones. Without the second half this check reports every entry
# written before a heading was renamed as a MISSPELLED section -- its most alarming finding, and its
# least true. Measured when 'Who is this for' became 'Significance': 24 pending entries in this repo's
# own CHANGELOG.md, all accused at once, which is how a check gets switched off rather than heeded.
$ehSectionNames = @((Get-EntrySectionHeadings).Values) + @(Get-EntryRetiredSectionHeadings)
# At or above the entry's own level: '#' .. '##' while an entry is an H2.
$ehTooHighRx = '^#{1,' + $ehEntryLevel + '}\s'
$ehSectionRx = '^#{' + $ehSectionLevel + '}\s+(.+?)\s*$'

function Test-IsDeclaredSectionHeading([string]$Line) {
    # $true when the line is a section heading whose text is one this repo declares. The comparison is
    # exact, deliberately: 'Who is this For' differing only in case is the mistyped-heading case this
    # exists to catch, and the parser it protects matches exactly too.
    $m = [regex]::Match($Line, $ehSectionRx)
    if (-not $m.Success) { return $false }
    return ($ehSectionNames -ccontains $m.Groups[1].Value)
}

# THE ENTRY IS IN branch/ SINCE THE SPLIT (August 6, 2026), so scanning only the root would leave this
# check with nothing to judge on every branch -- and it would still report [OK], because "no unfolded entry
# file" is a legitimate state between merges. A check that goes quiet for the right-looking reason is worse
# than one that errors. Both locations are walked, for the same "recognise both" reason the fold walks both.
#
# AND THE STEP LIST IS EXCLUDED BY NAME, which it never had to be before (Dave, August 6, 2026). Both branch
# files open with an H2 in the dossier form, so the structural test alone -- which is the only thing that
# tells an entry from a root doc -- now says yes to branch-progress.md as well. It is not an entry: its
# sections are 'Steps' and 'Where I left off', so every branch would have collected two [entry-heading]
# errors for a file that is doing exactly what it should. Excluded by PATH rather than by inspecting its
# headings, because the path is what makes it not an entry; the heading names are just how it shows.
#
# The fold needed no such repair: it reaches branch-changelog.md by path and only ever applies the
# structural test to loose *.md in the ROOT, where the step list has never lived.
$entryFilesForHeadings = @(Get-ChildItem -Path $RepoRoot -Filter '*.md' -File |
    Where-Object { Test-IsChangelogEntryFile -Path $_.FullName })
$branchPathsForHeadings = Get-BranchFilePaths
$branchDirForHeadings = Join-Path $RepoRoot $branchPathsForHeadings.Directory
$progressForHeadings = Join-Path $RepoRoot ($branchPathsForHeadings.Progress -replace '/', '\')
if (Test-Path -LiteralPath $branchDirForHeadings) {
    $entryFilesForHeadings += @(Get-ChildItem -Path $branchDirForHeadings -Filter '*.md' -File |
        Where-Object { $_.FullName -ne $progressForHeadings } |
        Where-Object { Test-IsChangelogEntryFile -Path $_.FullName })
}
foreach ($ef in $entryFilesForHeadings) {
    $ehChecked++
    $rel = $ef.FullName.Substring($RepoRoot.Length).TrimStart('\', '/')
    $masked = Get-FenceMaskedText -Text ([System.IO.File]::ReadAllText($ef.FullName, [System.Text.Encoding]::UTF8))
    $ehLines = $masked -split "`r?`n"
    for ($i = 1; $i -lt $ehLines.Count; $i++) {
        $line = $ehLines[$i]
        if ($line -match $ehTooHighRx) {
            $lvl = ($line -replace '^(#+).*$', '$1')
            Add-Error "[entry-heading] ${rel}:$($i + 1): a '$lvl ' heading in an entry body, at or above the entry's own level. An entry heading is an H$ehEntryLevel, so an H$ehEntryLevel here becomes a SEPARATE entry the moment the fold pastes this file into CHANGELOG.md -- one that declares no impact and therefore reads as an undeclared tier 0 -- and an H1 climbs above every entry in the document. Use '$('#' * ($ehSectionLevel + 1)) ' or bold instead."
        } elseif (($line -match $ehSectionRx) -and -not (Test-IsDeclaredSectionHeading $line)) {
            Add-Error "[entry-heading] ${rel}:$($i + 1): '$($Matches[1])' is at the level of the entry's named sections but is not one of them ($($ehSectionNames -join ', ')). A section ends at the next heading of this level or above, so this truncates whichever section it sits in -- and if it is a misspelling of a real section heading, the entry silently loses that declaration and the tier/significance gates read nothing. Use '$('#' * ($ehSectionLevel + 1)) ' for a sub-heading, or correct the spelling."
        }
    }
}

$clForHeadings = Join-Path $RepoRoot 'CHANGELOG.md'
if (Test-Path -LiteralPath $clForHeadings) {
    $clMasked = Get-FenceMaskedText -Text ([System.IO.File]::ReadAllText($clForHeadings, [System.Text.Encoding]::UTF8))
    $clLines = $clMasked -split "`r?`n"
    # THE BOUNDARY IS STRUCTURAL NOW, not a heading name. It used to be '## Pull Requests' to '## Releases',
    # matched in both spellings and in either order; the flat document has no section headings at all, so the
    # intro simply ends at the first entry heading -- the same rule Split-Changelog derives it by, which is
    # what keeps the gate and the parser looking at one document.
    #
    # A changelog with no entry at all is not judged and not an error: that is the normal state of the file
    # between a release and the next merge, and check 13's subject is the entries.
    $clFirstEntry = -1
    for ($i = 0; $i -lt $clLines.Count; $i++) {
        if ($clLines[$i] -match ('^#{' + $ehEntryLevel + '}\s')) { $clFirstEntry = $i; break }
    }
    if ($clFirstEntry -ge 0) {
        $ehChecked++
        $clRealLines = (([System.IO.File]::ReadAllText($clForHeadings, [System.Text.Encoding]::UTF8)) -split "`r?`n")
        # WHICH SECTION A WHOLE ENTRY OPENS WITH, and there is more than one right answer -- which is the
        # repair this rule needed when the dossier form put the title section in front (August 6, 2026).
        # A current entry opens with that; the entries ALREADY in CHANGELOG.md open with the description
        # question, under its current name or its retired one. Testing only the newest opener would have
        # reported every one of the pending entries as a split entry: two dozen false accusations, which is
        # how a check gets switched off rather than heeded -- measured on this very gate when
        # 'Who is this for' was renamed.
        # AND THE FIRST SECTION'S OWN RETIRED NAMES BELONG HERE TOO (August 7, 2026). 'What' had them from the
        # start; the opening section did not need them until it was renamed, and the moment it was, all six
        # pending entries were reported as split -- the very failure the paragraph above describes, reappearing
        # one section to the left. A rename is not a one-line change while any reader knows only the new name.
        $ehOpeners = @(
            (Get-EntrySectionHeadings)[(Get-EntryFirstSectionKey)]
            (Get-EntrySectionHeadings)['What']
        ) + @(Get-EntrySectionRetiredNames -Key (Get-EntryFirstSectionKey)) +
            @(Get-EntrySectionRetiredNames -Key 'What') | Where-Object { $_ }
        $ehWhatHeading = $ehOpeners[0]

        # WHAT DISTINGUISHES AN ENTRY FROM A BODY HEADING, since markdown gives no marker for it. Every H2
        # here is read as one change, so a stray body heading becomes a phantom entry: no impact table, so an
        # undeclared tier 0, with its own block in the record. The rule is structural rather than a guess, and
        # it is TWO rules because there are two legitimate entry shapes:
        #
        #   - an entry with sections: its FIRST declared section must be the first one ('$ehWhatHeading').
        #     A stray heading dropped inside a formatted entry splits the three sections across two blocks,
        #     so the phantom's first section is whichever one followed it -- never the first.
        #   - an entry with NO sections: only a pre-format entry, which carries its type as a heading field
        #     instead. Resolve-EntryType answers that, reading the section where there is one and the heading
        #     where there is not -- the same reader the release documents use, so the gate cannot disagree
        #     with them about what an entry declares.
        #
        # THAT PAIR IS WHAT MAKES IT COMPLETE, and neither half is complete alone. A stray heading placed
        # between the entry heading and its first section keeps all three sections in ITS block and passes the
        # first rule -- but it leaves the real entry above it with none, and a current-format heading carries
        # no type field, so the second rule reports that one. The error lands on the entry rather than on the
        # stray, which is why the message names both possibilities instead of asserting which it found.
        #
        # NOT KEYED ON THE '#NN' THE FOLD PREPENDS, deliberately, though it would be the obvious test: the
        # fold cannot reach gh on a manual merge and then writes a legitimate entry with no number and no PR
        # footer, stating so on the console. A gate keying on the number would report the fold's own
        # documented output as a defect.
        $clStarts = @()
        for ($i = $clFirstEntry; $i -lt $clLines.Count; $i++) {
            if ($clLines[$i] -match ('^#{' + $ehEntryLevel + '}\s')) { $clStarts += $i }
        }
        for ($b = 0; $b -lt $clStarts.Count; $b++) {
            $from = $clStarts[$b]
            $to = if ($b + 1 -lt $clStarts.Count) { $clStarts[$b + 1] - 1 } else { $clLines.Count - 1 }
            $firstDeclared = $null
            for ($i = $from + 1; $i -le $to; $i++) {
                if (Test-IsDeclaredSectionHeading $clLines[$i]) {
                    $firstDeclared = ([regex]::Match($clLines[$i], $ehSectionRx)).Groups[1].Value
                    break
                }
            }
            if ($null -ne $firstDeclared) {
                if ($ehOpeners -cnotcontains $firstDeclared) {
                    Add-Error "[entry-heading] CHANGELOG.md:$($from + 1): this H$ehEntryLevel's first named section is '$firstDeclared' rather than '$ehWhatHeading'. Every H$ehEntryLevel here is read as one change, so an entry whose sections do not start at the beginning is one that has been SPLIT -- almost certainly by a body sub-heading written at the entry's own level, which the release documents then file as a separate change declaring no impact. Demote that sub-heading to '$('#' * ($ehSectionLevel + 1)) '."
                }
            } else {
                $blockText = (@($clRealLines[$from..([Math]::Min($to, $clRealLines.Count - 1))]) -join "`n")
                if (-not (Resolve-EntryType -EntryText $blockText).Declared) {
                    Add-Error "[entry-heading] CHANGELOG.md:$($from + 1): this H$ehEntryLevel declares neither its named sections nor a change type. Every H$ehEntryLevel here is read as one change, and this one tells the release documents nothing -- it is either a body sub-heading written at the entry's own level (demote it to '$('#' * ($ehSectionLevel + 1)) ') or a real entry whose sections were absorbed by such a heading directly below it."
                }
            }
        }

        for ($i = $clFirstEntry; $i -lt $clLines.Count; $i++) {
            $line = $clLines[$i]
            if ($line -match '^#\s') {
                Add-Error "[entry-heading] CHANGELOG.md:$($i + 1): an H1 below the intro. It comes from an entry body and climbs above every entry in the document -- and in the generated release notes it renders above the tier heading it belongs under. Demote it to '$('#' * ($ehSectionLevel + 1)) '."
            } elseif (($line -match $ehSectionRx) -and -not (Test-IsDeclaredSectionHeading $line)) {
                Add-Error "[entry-heading] CHANGELOG.md:$($i + 1): '$($Matches[1])' sits at the level of an entry's named sections but is not one of them ($($ehSectionNames -join ', ')). A section ends at the next heading of this level or above, so this truncates the section it sits in -- and a misspelled section heading costs that entry its declaration silently. Demote it to '$('#' * ($ehSectionLevel + 1)) ', or correct the spelling."
            }
        }
    }
}

Write-Coverage -Category 'entry-heading' -Checked $ehChecked `
    -Note $(if ($entryFilesForHeadings.Count -eq 0) { 'no unfolded entry in branch/ or the root, so only CHANGELOG.md was judged -- normal between merges' } else { "$($entryFilesForHeadings.Count) unfolded entry file(s) plus CHANGELOG.md" })

# --- 13b. the branch/ templates still match what the scaffolder writes -------------------------------------
# A template beside a scaffolder that writes the same shape is TWO SOURCES OF ONE FORMAT. This repo has paid
# for that shape repeatedly -- the scaffold wording, the fence readers, the tier sections -- and the entry
# format changed THREE TIMES on the day these templates were added, so a hand-maintained copy would have gone
# stale before it was committed.
#
# The templates are therefore generated from the same formatters new-branch.ps1 calls, and this holds
# the files on disk to Get-BranchTemplates. Compared with line endings normalised: whether the working copy
# checked out CRLF is not a property of the format.
$btChecked = 0
$btMissing = 0
foreach ($tpl in (Get-BranchTemplates)) {
    $btChecked++
    $tplPath = Join-Path $RepoRoot ($tpl.Path -replace '/', '\')
    if (-not (Test-Path -LiteralPath $tplPath)) {
        $btMissing++
        Add-Error "[branch-template] $($tpl.Path) is missing. It is generated from the same formatters the scaffolder uses -- see Get-BranchTemplates in scripts/lib/entry-scaffold-lib.ps1."
        continue
    }
    $onDisk   = ([System.IO.File]::ReadAllText($tplPath, [System.Text.Encoding]::UTF8)) -replace "`r`n", "`n"
    $expected = $tpl.Content -replace "`r`n", "`n"
    if ($onDisk -ne $expected) {
        Add-Error "[branch-template] $($tpl.Path) no longer matches what the scaffolder writes. It is a copy-paste convenience, not a second definition of the format -- regenerate it from Get-BranchTemplates rather than editing it by hand."
    }
}
Write-Coverage -Category 'branch-template' -Checked $btChecked `
    -Note $(if ($btMissing -gt 0) { "$btMissing missing" } else { 'held against the formatters the scaffolder calls, so the template cannot drift from the file a branch actually gets' })

# --- 14. mojibake: a double-encoded character is a silent content change -----------------------------------
# MEASURED HERE, August 1, 2026, and it nearly shipped. Demoting four headings in CHANGELOG.md with
# Get-Content + WriteAllLines mangled 35 separators into 105 double-encoded sequences: Windows PowerShell
# 5.1's Get-Content reads a BOM-less UTF-8 file as ANSI, so a middot (U+00B7, bytes C2 B7) comes back as two
# characters, and writing that back as UTF-8 stores the mangled pair. Nothing errors -- the file stays valid
# UTF-8, it just says something else.
#
# WHY THIS IS A GATE AND NOT A CONVENTION. The middot IS the field delimiter in an entry heading
# ('### #NN <middot> title <middot> type <middot> date'), so cut-release.ps1 could no longer read the entry
# TYPE: eleven entries fell into a catch-all category instead of Features/Fixes/Documentation. It was caught
# by inspecting the generated notes before pushing (-NoPush), i.e. by one person looking carefully at the
# right moment -- which is precisely the thing not to rely on. Third repo to meet this class
# (smartwatchbanden -> life-hub -> here), and life-hub's own tool documents a v2.1.0 release that needed a
# manual fix for the same reason.
#
# The detector is the repair tool itself, run rather than restated: one source for "what does damage look
# like", so what the repair can fix and what the gate can see cannot drift apart.
#
# THAT SHARED SOURCE WAS ONCE SHARED BLINDNESS (August 2, 2026). While the tool worked off a hand-written
# table of known sequences, this gate inherited its coverage exactly -- and the table held only the
# single-layer form of most characters. 517 doubly-encoded runs across four files, three of them inside
# this check's own stated scope, were reported here as "No findings" for as long as they existed, and the
# damage rode into the v3.1.0 release notes and the consumer-facing RELEASE.md card. The tool now peels by
# the inverse operation instead of by enumeration, which is what makes this line an assertion again.
$mjChecked = 0
$mjScript = Join-Path $RepoRoot 'scripts\maintenance\fix-mojibake.ps1'
if (Test-Path -LiteralPath $mjScript) {
    # -Check reports and changes nothing; exit 1 = damage found. Run as a child process because the script
    # calls exit itself, and a lint gate must not be terminated by the tool it consults.
    #
    # Via Invoke-NativeCapture, not a bare '2>&1'. The first version used the bare form and this repo's own
    # shared-scripts guard caught it: under ErrorActionPreference=Stop a native command's stderr line
    # becomes a terminating NativeCommandError before the exit code is ever read (the #107 pitfall), so the
    # gate would have died on the tool's own output instead of reporting it.
    . (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
    $mjRun = Invoke-NativeCapture -FilePath 'powershell' -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $mjScript, '-Check')
    $mjOut = $mjRun.Output
    $mjCode = $mjRun.ExitCode
    $mjChecked = 1
    if ($mjCode -ne 0) {
        foreach ($line in @($mjOut | Where-Object { $_ -match '\[mojibake\]' })) {
            Add-Error ("[mojibake] " + ($line -replace '^\s*\[mojibake\]\s*', '') + " -- a UTF-8 character was read as ANSI and written back, so the file's text changed without any error. In an entry heading the separator IS the field delimiter, so cut-release.ps1 stops being able to read the entry type. Repair with scripts/maintenance/fix-mojibake.ps1; avoid it by never reading a non-ASCII file with bare Get-Content.")
        }
        if (@($mjOut | Where-Object { $_ -match '\[mojibake\]' }).Count -eq 0) {
            Add-Error "[mojibake] scripts/maintenance/fix-mojibake.ps1 -Check exited $mjCode without naming a file -- the mojibake gate could not complete, so nothing is asserted about encoding."
        }
    }
} else {
    Add-Error "[mojibake] scripts/maintenance/fix-mojibake.ps1 is missing -- the encoding gate cannot run."
}

# THE COUNT IS FILES, NOT TOOL RUNS. It used to report 'checked 1' -- true of the invocation and useless
# as coverage, since the one number a reader wants here is how much was looked at. The tool states it on
# its own closing line; parsed rather than re-derived, so the gate cannot claim a scope the tool did not
# walk. A run that does not state it falls back to naming that, instead of quietly reporting 1.
$mjFiles = 0
if ($mjChecked -eq 1) {
    $mjMatch = [regex]::Match(($mjOut -join "`n"), '(\d+)\s+file\(s\)\s+examined')
    if ($mjMatch.Success) { $mjFiles = [int]$mjMatch.Groups[1].Value }
}
Write-Coverage -Category 'mojibake' -Checked $mjFiles `
    -Note $(if ($mjChecked -eq 0) {
        'the repair tool is absent, so no file was examined for double-encoded characters'
    } elseif ($mjFiles -eq 0) {
        'the repair tool ran but did not state how many files it examined, so this count is not evidence of scope'
    } else {
        'the set this repo names in Get-MojibakePaths (scripts/repo-config.ps1): every *.md in the root (the changelog and the root docs), every *.md in branch/ (the entry whose text is pasted into CHANGELOG.md, and the step list), plus every *.md under plugins/ and every note under releases/. Peeled by the inverse round trip rather than matched against a table of known sequences'
    })

# --- 15. unbound output samples: an expectation that cannot hold everywhere -------------------------------
# THE CLASS TEST ROUND v11 KEPT PRODUCING. Four of its nine findings were one shape: a captured sample
# handed to the reader as a fixed expectation, without saying what the capture was bound to.
#   #358  the bootstrap's 'Done:' line, captured in a repo that already had the script scaffolds, so the
#         third pair was inverted for the fresh repo the section was written for
#   #359  a CLI error string that CLI 2.1.220 no longer emits -- and whose replacement suggests a
#         different command than the procedure
#   #360  a byte baseline that was the LF figure, on a platform where every round measures the CRLF one
#   #361  a sender header the reader was told to look for, which no bootstrapped repo emits
# Individually four documentation fixes. Together a rule nobody was holding: an expectation is only
# checkable if the reader can tell when it does not apply to them.
#
# WHY THIS CAN BE A GATE AT ALL, where "is this prose accurate" cannot. The distinction it needs is
# already in the markup. A fenced block carrying a language (powershell, json, jsonc) is something to
# RUN; a fenced block with no language, or 'text', is something to COMPARE AGAINST -- and only the second
# kind can go stale under the reader. Measured before building: 34 fenced blocks across the two
# consumer-facing documents, of which exactly 4 are the second kind, and those 4 are precisely the
# findings above plus one instance the round missed. A check with a four-item haystack does not need a
# heuristic.
#
# AND IT MUST NOT BECOME A CHECK THAT PASSES BY BEING IGNORED. A fuzzy gate gets an opt-out pasted over
# every finding and then reports green while asserting nothing -- the exact failure mode of the mojibake
# table one check up. So the escape hatch is a visible marker that has to name a reason, and the coverage
# line below reports how many samples were examined rather than how many times the check ran.
$sampleChecked = 0
# THE CONSUMER-FACING SET, DECLARED ONCE. Checks 15 and 16 hold the same class of defect on the same three
# documents and differ only in where they look (inside a fence, or in the prose around it). Two copies of
# this list would drift the moment a fourth document joins -- which is check 16's own subject arriving in
# its source, so it is one variable shared by both.
# ADOPTION.md joined in #408, which is this comment's own warning arriving: the page renamed out from
# under 'QUICKSTART.md' carries every captured sample and measured figure these two checks exist for,
# and the new short QUICKSTART.md carried almost none. Listing only the old name would have left both
# checks reporting green over the document that actually holds their subject.
#
# THE TWO ARE ONE FILE AGAIN -- plugins/INSTALL.md, the short page as its first half -- so the set is
# three entries, not four. Note what the merge did to the failure mode this comment describes: while
# they were separate, naming the wrong one silently halved the coverage. Now there is one page and no
# wrong one to name, which is worth more than the entry it saved.
$consumerDocs = @(
    'plugins\INSTALL.md',
    'plugins\UNINSTALL.md',
    'README.md'
)
# What counts as saying "here is what this is bound to". A version or a year pins the capture in time; the
# hedges pin it to a condition. Deliberately not 'measured' on its own -- that says the author saw it,
# which is exactly what was true of all four findings.
$bindingMarker = '(\d+\.\d+\.\d+)|(\b(19|20)\d{2}\b)|version-bound|varies|may differ|will differ|depends on|illustrative|not a fixed string|fresh repo|already present|whatever the phrasing|on Windows|CRLF'
# The opt-out has to NAME something. '(?!-->)' is the whole point: without it, the empty marker
# '<!-- unbound-sample: -->' satisfies '\S' on the comment terminator itself, and the escape hatch
# becomes a way to switch the check off rather than a way to record an exception.
$sampleOptOut  = '<!--\s*unbound-sample:\s*(?!-->)\S'
# A NAMED DOCUMENT THAT IS NOT THERE IS A FINDING, NOT A SKIP -- and this is the repair for how the
# defect above stayed invisible rather than for the defect itself. Both loops below open their file with
# a 'Test-Path ... { continue }', so a stale entry in the list costs coverage and says nothing: checks 15
# and 16 simply examine less and still report green. Measured on the move into plugins/: expected-output
# went 5 -> 1 and measured-figure 11 -> 0 in one commit, with no error anywhere, and it surfaced only
# because somebody happened to read the coverage line.
#
# Validated ONCE here rather than inside each loop, so a missing document is reported once instead of
# per reader -- two findings for one cause read as two causes.
foreach ($rel in $consumerDocs) {
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $rel))) {
        Add-Error "[consumer-doc] '$rel' is named in the consumer-facing set but does not exist -- checks 15 and 16 skip it in silence, so their coverage is lower than it looks. Either the document moved (update the list) or it is gone (drop the entry)."
    }
}
foreach ($rel in $consumerDocs) {
    $full = Join-Path $RepoRoot $rel
    if (-not (Test-Path -LiteralPath $full)) { continue }
    $lines = [System.IO.File]::ReadAllLines($full, [System.Text.Encoding]::UTF8)
    $open = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch '^```') { continue }
        if ($open -lt 0) { $open = $i; continue }
        $close = $i
        $lang = ($lines[$open] -replace '^```', '').Trim().ToLowerInvariant()
        $open2 = $open; $open = -1
        # A block with a language is a command to run, not an expectation to match.
        if ($lang -ne '' -and $lang -ne 'text') { continue }
        # AND A DIAGRAM IS DRAWN, NOT CAPTURED. The class is text a tool emitted, which can therefore
        # emit something else tomorrow; a directory tree is authored by the writer and goes stale only
        # when the writer changes it. The seam diagram in README.md was this check's first false
        # positive, and box drawing is what separates the two without a judgement call. Named here and
        # in the coverage line rather than left as a silent narrowing -- an exclusion nobody can see is
        # how a gate quietly stops covering what it claims.
        # Built from codepoints, never written as literal box-drawing characters. This file is read by
        # Windows PowerShell 5.1, which takes a BOM-less UTF-8 script as ANSI -- writing the range
        # literally mangled it into a broken character class on the first run, which is check 14's own
        # subject arriving in check 15's source.
        $body = if ($close -gt $open2 + 1) { ($lines[($open2 + 1)..($close - 1)] -join "`n") } else { '' }
        $boxDrawing = '[' + [char]0x2500 + '-' + [char]0x257F + ']'
        if ($body -match $boxDrawing) { continue }
        $sampleChecked++
        # The window: the paragraph that introduces the sample, and the prose that follows it. Bounded
        # rather than section-wide on purpose -- a version number three screens away in another
        # subsection is not something the reader of THIS block is going to connect to it.
        # THE SAMPLE'S OWN BODY IS NOT CONTEXT. Caught by the first test written against this check: a
        # block whose text happened to contain 'already present' satisfied the binding with its own
        # content, so the very sample under examination vouched for itself. The binding has to be
        # something the DOCUMENT says about the sample, never something the sample says.
        $from = [Math]::Max(0, $open2 - 5)
        $to   = [Math]::Min($lines.Count - 1, $close + 14)
        $before = if ($open2 -gt $from) { ($lines[$from..($open2 - 1)] -join "`n") } else { '' }
        $after  = if ($to -gt $close) { ($lines[($close + 1)..$to] -join "`n") } else { '' }
        $context = $before + "`n" + $after
        if ($context -match $sampleOptOut) { continue }
        if ($context -notmatch $bindingMarker) {
            Add-Error "[expected-output] ${rel}:$($open2 + 1) -- a fenced block with no language is a sample the reader compares against, and nothing near it says what the capture is bound to (a CLI version, a date, a platform, a repo state, or a hedge such as 'varies' / 'illustrative'). Four of test round v11's nine findings were exactly this. Name the binding, or mark the block deliberate with '<!-- unbound-sample: <reason> -->'."
        }
    }
}
Write-Coverage -Category 'expected-output' -Checked $sampleChecked `
    -Note 'captured output samples in the consumer-facing docs -- language-less or text-tagged fenced blocks, i.e. the ones a reader compares against rather than runs. Two kinds are deliberately not examined and both are stated rather than assumed: blocks tagged powershell/json/jsonc (commands to run) and blocks containing box drawing (diagrams, which are drawn rather than captured)'

# --- 16. A measured figure in prose names what it was measured on -----------------------------------------
# CHECK 15'S SUBJECT, ONE STEP OUTSIDE ITS REACH. Check 15 holds captured samples inside fenced blocks,
# because a fence is a markup boundary a gate can see. Test round v12 found the same defect class in
# running prose, where there is no fence:
#   #374  "never literally clean" -- true of a user-scope declaration, written as true of every reader
#   ---   the same over-generalisation one section down, carrying three byte figures from a single machine
#         (~/.claude/settings.json at 22 bytes) on a profile where that file had never existed
# The figures were accurate when captured. What was missing is the sentence saying whose machine they came
# from, and without it a reader whose own numbers differ cannot tell whether they mis-installed or the page
# is stale. Round v12's step-0 table came back fully clean against a page that said clean was impossible.
#
# WHY THIS ONE IS GATEABLE WHERE "IS THIS PROSE ACCURATE" IS NOT. It does not judge the claim; it judges
# whether a binding is present near a figure whose SHAPE is unambiguous. A byte count or a file size is
# always a measurement of something -- there is no authored, non-measured reason to write "939,860 bytes"
# -- so the haystack needs no heuristic to identify. Measured before building, exactly as check 15 was:
# 9 figures across 8 lines in the three consumer-facing documents. A haystack that small is enumerable, and
# the check was run against it before the rule was written rather than after.
#
# THE WINDOW IS THE PARAGRAPH NEIGHBOURHOOD, NOT A LINE COUNT. A figure in a table row is bound by the
# paragraph introducing the table, which sits an arbitrary number of rows above; a figure in prose is bound
# by its own sentence. Both are "the block this line is in, plus the block either side", so that is the
# window -- it adapts to a 3-row table and a 12-row one without a magic number, and it stops at a blank
# line rather than wandering into an unrelated subsection.
#
# 'measured' IS DELIBERATELY NOT A BINDING, for the same reason check 15 rejects it: it says the author saw
# the number, which was true of every finding this check exists for. The binding has to pin the figure to a
# time, a version, a platform, or a stated condition.
$figureChecked = 0
# A digit immediately before the unit is what makes this a measurement rather than a word. 'byte-identical'
# carries no leading number and is therefore not a figure, which is the distinction the leading \d makes.
$figurePattern = '\d[\d,]*(\.\d+)?\s*(bytes?|KB|MB|GB)\b'
# What counts as pinning a figure down: a year or a date, a test round, a semver, a named machine state, or
# an explicit hedge. Kept close to check 15's list so the two gates teach the writer one habit, not two.
$figureBinding = '(\b(19|20)\d{2}\b)|(round v\d+)|(\d+\.\d+\.\d+)|virgin|fresh profile|clean machine|before adoption|a profile that|varies|may differ|will differ|depends on|illustrative|approximately|roughly'
$figureOptOut  = '<!--\s*unbound-figure:\s*(?!-->)\S'
foreach ($rel in $consumerDocs) {
    $full = Join-Path $RepoRoot $rel
    if (-not (Test-Path -LiteralPath $full)) { continue }
    $lines = [System.IO.File]::ReadAllLines($full, [System.Text.Encoding]::UTF8)
    # Fenced blocks belong to check 15. Counting them here would double-report the same sample and would
    # also flag command output that is deliberately verbatim.
    $inFence = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^```') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        if ($lines[$i] -notmatch $figurePattern) { continue }
        $figureChecked++
        # The block this line sits in ...
        $bStart = $i; while ($bStart -gt 0 -and $lines[$bStart - 1].Trim() -ne '') { $bStart-- }
        $bEnd = $i; while ($bEnd -lt $lines.Count - 1 -and $lines[$bEnd + 1].Trim() -ne '') { $bEnd++ }
        # ... plus the block before it (an intro paragraph above a table) ...
        $pEnd = $bStart - 1; while ($pEnd -gt 0 -and $lines[$pEnd].Trim() -eq '') { $pEnd-- }
        $pStart = $pEnd; while ($pStart -gt 0 -and $lines[$pStart - 1].Trim() -ne '') { $pStart-- }
        # ... and the block after it (a note below a table saying which column came from where).
        $nStart = $bEnd + 1; while ($nStart -lt $lines.Count -and $lines[$nStart].Trim() -eq '') { $nStart++ }
        $nEnd = $nStart; while ($nEnd -lt $lines.Count - 1 -and $lines[$nEnd + 1].Trim() -ne '') { $nEnd++ }
        $from = [Math]::Max(0, $pStart)
        $to   = [Math]::Min($lines.Count - 1, $nEnd)
        $context = ($lines[$from..$to] -join "`n")
        if ($context -match $figureOptOut) { continue }
        if ($context -notmatch $figureBinding) {
            Add-Error "[measured-figure] ${rel}:$($i + 1) -- a byte count or file size in prose is a measurement of somebody's machine, and nothing in the surrounding paragraphs says whose (a date, a test round, a CLI version, a named profile state, or a hedge such as 'varies' / 'approximately'). Round v12 filed exactly this as #374: a reader whose own number differs cannot tell whether they mis-installed or the page went stale. Name the binding, or mark it deliberate with '<!-- unbound-figure: <reason> -->'."
        }
    }
}
Write-Coverage -Category 'measured-figure' -Checked $figureChecked `
    -Note 'byte counts and file sizes in the PROSE of the consumer-facing docs -- the same staleness class as check 15, outside a fence where no markup marks it. Figures inside fenced blocks are deliberately not counted here: those are check 15''s, and counting them twice would report one sample as two'

# RETIRED, AUGUST 8, 2026 -- check 17 ("the per-plugin CHANGELOG intro still matches its template").
# It existed because that intro was write-once: it reached a file at creation and was never rewritten,
# so all four per-plugin CHANGELOGs kept naming the retired marketplace long after the rename had swept
# it out of 59 files. The check was the right repair for a real defect. The files it guarded are gone,
# and with them the write-once text -- see the retirement note in scripts/lib/release-lib.ps1. The
# LESSON survives in that file's header, because it is about the next template, not about these.
# --- Check 18: a shared script's parameters appear in the skill that documents it -----------------------
# A consumer has exactly two things: the plugin mirror of a script, and the skill that describes it. So a
# parameter the skill never names is, for them, a parameter that does not exist -- including the escape
# valve they need when something goes wrong.
#
# THIS IS A REPAIR, NOT A PRECAUTION. Measured August 4, 2026: the fold-changelog skill told every consumer
# to commit the fold BY HAND for two days after the script gained -Commit/-Push, because that improvement
# had been written into this repo's lens instead. Looking for siblings found three more -- cut-release's
# -NoPush and -SkipLint, and new-internal-note's -RepoRoot -- and -NoPush is the one inspection step before
# a release is pushed, the step that catches the '##-climbs-out-of-its-category' defect. The cause is
# structural: a parameter is added to a script, its reason goes into a lens or a commit message, and the
# skill follows nobody.
#
# The Skill mapping and the per-parameter exemptions live in the registry
# (scripts/lib/shared-scripts-lib.ps1), next to the registration, for the reason its own LibOnly comment
# gives: a second hand-written list is one a newly shared script falls out of silently.
$skillParamChecked = 0
$skillDocumented = 0
$skillGaps = @()
foreach ($pair in $sharedPairs) {
    if ($pair.LibOnly) { continue }
    # A missing SOURCE is check 8's finding, not this one's -- it already says so, and there are no
    # parameters to read anyway. Skipping keeps this check quiet against a minimal fixture (where none of
    # the registered scripts exist) instead of reporting every skill as absent.
    if (-not (Test-Path -LiteralPath $pair.SourcePath)) { continue }
    # $null = LibOnly/not applicable; '' = an entry point declaring it has no skill. Only the second is
    # reportable, and it is reported as coverage rather than as an error: writing a missing skill is its
    # own piece of work, and failing the gate over it would block every unrelated PR until someone did.
    if ([string]::IsNullOrEmpty($pair.Skill)) { $skillGaps += $pair.Name; continue }

    # SkillRel, not a hardcoded 'plugins\specialists\...' path. The registry derives it from the
    # mirror, so a script that moves to another plugin takes its page lookup with it. Measured on
    # August 8, 2026 during the workflow split: with the path hardcoded here, all nine moved entry
    # points reported their existing skill as a typo.
    $skillPath = Join-Path $repoRoot $pair.SkillRel
    if (-not (Test-Path -LiteralPath $skillPath)) {
        Add-Error "[skill-param] $($pair.SourceRel) names skill '$($pair.Skill)' in the shared-scripts registry, but $($pair.SkillRel -replace '\\', '/') does not exist. Either the skill was renamed or moved to another plugin (update the registry) or the mapping is a typo."
        continue
    }
    $skillText = Get-Content -LiteralPath $skillPath -Raw
    $params = Get-ScriptParameterNames -Path $pair.SourcePath
    foreach ($p in $params) {
        if ($pair.SkillParamsExempt -contains $p) { continue }
        $skillParamChecked++
        # Matched as '-Name' on a word boundary: that is how a reader would type it, and it avoids
        # crediting a bare prose mention of the word.
        if ($skillText -notmatch ('-' + [regex]::Escape($p) + '\b')) {
            Add-Error "[skill-param] $($pair.SourceRel): parameter -$p is documented nowhere in the '$($pair.Skill)' skill, so a consumer who has the mirror plus that page cannot know it exists. Add it, or -- if a consumer genuinely never types it -- register it in SkillParamsExempt with the reason."
        }
    }
    $skillDocumented++
}
$gapNote = if ($skillGaps.Count -gt 0) { " NOT covered, because they declare no skill in the registry: $($skillGaps -join ', ')." } else { '' }
Write-Coverage -Category 'skill-param' -Checked $skillParamChecked `
    -Note "parameters of the $skillDocumented shared entry point(s) that name a documenting skill, held against that skill's text -- a consumer has only the mirror and its page, so an undocumented parameter does not exist for them. Read via the PowerShell parser, not a regex, which missed an attributed parameter when this was first measured. Exemptions are declared per script in the registry.$gapNote"

# --- Check 20: a document claiming how many sections an entry has is held to the scaffolder ---------------
# Numbered 20 and not 19: the consumer-doc guard above carries no numbered header of its own, but the suite
# already calls it check 19, and two checks answering to one number is how a finding gets discussed as the
# wrong one.
# ISSUE #508 MEASURED THE PROBLEM: the entry format is described in about ten hand-maintained places against
# two that cannot drift (the templates, held by check 13b, and the scaffolder itself). Two documents were
# found stale during a sweep that was actively looking, one of them consumer-facing.
#
# THE RULE WAS CHOSEN BY MEASUREMENT, NOT BY REASONING, and three earlier candidates were rejected by it:
#
#   >=2 section NAMES together, one of them retired          -> 6 findings on the tree, ALL SIX FALSE
#   the same, minus units that mark the name as history      -> 3 findings, 2 false
#   fenced skeleton blocks only                              -> 0 findings, but covers 1 of 3 known drifts
#   a claimed section COUNT vs the scaffolder's              -> 4 claims, 3 correct, 1 genuinely stale
#
# The name-matching candidates fail on a collision nobody would predict: 'What does this change do?' and
# 'Type of change' are RETIRED entry sections and, at the same time, LIVE headings of
# .github/pull_request_template.md. So a name-matcher accuses two correct documents of being stale for
# describing the PR body accurately -- and a check that is born red with an exemption list is the shape
# this repo was already bitten by (Get-RosterIgnoredIds).
#
# A COUNT HAS NONE OF THAT. It is a fact the scaffolder owns, stated in a form that cannot mean anything
# else, and both recorded drifts made exactly this claim -- "three named `###` sections" -- while the
# scaffolder had moved to six. So this judges the one thing a document says about the shape that is
# checkable without judging its prose, which is the same line checks 15 and 16 draw.
#
# THE LEVEL MARKER IS REQUIRED IN THE TREE PASS, and that is what keeps the haystack honest across ~200
# files. (The one place it is not required is CHANGELOG.md's intro, a dozen lines with its own pass -- the
# block below states what that costs and why it costs nothing there.) Without it the pattern matches
# "one section apart", "two sections went in the same movement", "one section per tier" -- ordinary prose
# about anything, 18 disagreements of which 17 were noise. Requiring the '###' (backticked or not) between
# the number and the word narrows it to four claims in the whole tree, which is a haystack small enough to
# read by hand -- and it was, before this was written.
#
# History is excluded exactly as checks 11 and 12 exclude it: CHANGELOG.md's ENTRIES and the per-plugin
# copies, the release notes, RELEASE.md, and the branch working files, which are history in the making.
# branch/README.md is deliberately NOT excluded -- it is a document ABOUT the shape, which is precisely this
# check's subject.
#
# AND NEITHER IS CHANGELOG.md'S INTRO (August 8, 2026). It went out with the rest of that file on the history
# grounds above, and this repo had already written down why that reasoning does not reach the intro:
# release-lib.ps1 was bitten by it on the per-plugin CHANGELOGs and recorded the lesson one screen above the
# code -- "the entries below the intro were history, the intro was a live statement about the present
# mechanism". A cut empties this document down to that intro and carries it through verbatim, so it is the
# one piece of prose in the repo that no release ever rewrites and no reviewer ever opens. Measured on the
# day this was written: it claimed THREE sections while the scaffolder wrote six, and had done so since
# August 6 -- two days, one release, and a consumer-facing highlights page in between.
#
# TWO THINGS KEPT IT OUT OF REACH, and repairing either one alone leaves it unchecked:
#
#   1. the file was excluded, so nothing read the intro at all;
#   2. the pattern would have walked past it anyway -- the intro wrote "three named sections" with no '###'
#      in the sentence, and it wrote it ACROSS A LINE BREAK.
#
# So the head is judged by its own pass, with the level marker OPTIONAL, and the matching for both passes
# moves from per-line to whole-text. Both were chosen by measuring rather than by argument:
#
#   strict, per line, over the scanned tree   -> 4 claims   (what this check did)
#   strict, whole text, over the scanned tree -> 4 claims   (identical -- the 3 extra it finds sit in the
#                                                            history this check already excludes)
#   loose, whole text, over the whole tree    -> 50 claims  (the documented noise -- 46 of them)
#   loose, whole text, over the intro alone   -> 1 claim    (the real one, before and after the repair)
#
# The marker therefore keeps earning its place everywhere it was measured to earn it, and nowhere else: it
# guards ~200 files against 46 false hits, while the intro is a dozen lines this repo owns, where relaxing it
# costs nothing and is the whole difference between catching the drift and not. Whole-text matching changes
# nothing about what the tree pass reports -- it only closes the blind spot where a reflowed sentence hides a
# claim, which is a formatting accident no author would think of as a bypass.
$scExpected = @((Get-EntrySectionHeadings).Keys).Count
$scLevel = Get-EntrySectionLevel
$scWords = @{ 'one' = 1; 'two' = 2; 'three' = 3; 'four' = 4; 'five' = 5; 'six' = 6; 'seven' = 7; 'eight' = 8; 'nine' = 9; 'ten' = 10 }
$scNumRx = '(?<n>\d+|one|two|three|four|five|six|seven|eight|nine|ten)'
$scMarkerRx = "``?#{$scLevel}``?\s+"
$scClaimRx = "(?i)${scNumRx}\s+(?:named\s+)?${scMarkerRx}section"
$scHeadClaimRx = "(?i)${scNumRx}\s+(?:named\s+)?(?:${scMarkerRx})?section"

function Test-EntryShapeClaims {
    <#
        Reports every claim in $Text that disagrees with the scaffolder, and returns how many claims it
        read -- so an empty file and a clean one stay distinguishable in the coverage line.

        Matching is over the WHOLE text rather than line by line, so '\s+' spans the line break a markdown
        reflow puts in the middle of the sentence. The line number is then derived from the match offset
        rather than from a loop counter, which is the only bookkeeping that change costs.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$Rel,
        [Parameter(Mandatory)][string]$Rx
    )
    $seen = 0
    foreach ($m in [regex]::Matches($Text, $Rx)) {
        $raw = $m.Groups['n'].Value.ToLowerInvariant()
        $claimed = if ($scWords.ContainsKey($raw)) { $scWords[$raw] } else { [int]$raw }
        $seen++
        if ($claimed -ne $scExpected) {
            $lineNo = 1 + ([regex]::Matches($Text.Substring(0, $m.Index), "`n")).Count
            Add-Error "[entry-shape] ${Rel}:${lineNo}: says an entry has $claimed '$('#' * $scLevel)' sections, and the scaffolder writes $scExpected. The shape has one source (Get-EntrySectionHeadings); a document that states a count is stating a fact it does not own, so either the prose is stale or the format moved without this page. Naming the sections is fine -- the COUNT is what is held here."
        }
    }
    return $seen
}

$scFiles = @($linkFiles | Where-Object {
    $rel = $_.Substring($RepoRoot.Length).TrimStart('\', '/')
    if ($rel -eq 'CHANGELOG.md') { return $false }
    if ($rel -match '\\CHANGELOG\.md$') { return $false }
    if ($rel -match '(^|\\)RELEASE\.md$') { return $false }
    if ($rel -match '^releases\\') { return $false }
    if (($rel -notmatch '\\') -and (Test-IsChangelogEntryFile -Path $_)) { return $false }
    # The two branch working files only -- NOT the whole directory. The entry is history in the making and
    # the step list is a scratch pad; branch/README.md is the convention itself and is checked.
    #
    # SEPARATORS ARE NORMALISED, and leaving that out was caught by this check on its first run:
    # Get-BranchFilePaths returns forward slashes ('branch/branch-progress.md') while $rel is built from a
    # Windows path, so the two never compared equal and the exclusion did nothing. The step list of the very
    # branch that added this check was then reported for QUOTING a stale count while explaining it.
    $scBranchFiles = @((Get-BranchFilePaths).Changelog, (Get-BranchFilePaths).Progress) |
        ForEach-Object { $_ -replace '/', '\' }
    if ($scBranchFiles -contains $rel) { return $false }
    return $true
})

$scChecked = 0
foreach ($sf in ($scFiles | Sort-Object -Unique)) {
    $rel = $sf.Substring($RepoRoot.Length).TrimStart('\', '/')
    $scChecked += Test-EntryShapeClaims -Rel $rel -Rx $scClaimRx `
        -Text ([System.IO.File]::ReadAllText($sf, [System.Text.Encoding]::UTF8))
}

# The intro of CHANGELOG.md, derived the way check 13 and Split-Changelog derive it: everything above the
# first entry heading, fence-masked so an intro that QUOTES an entry heading -- this one documents the entry
# format, so it does -- cannot move the boundary into the middle of a code block.
#
# A changelog with NO entry is not a special case here: the head is then the whole file, which is exactly
# right. That is the normal state between a cut and the next merge, and it is the state the intro is most
# alone in. Split-Changelog throws there, deliberately (a cut with no entries describes nothing), which is
# why the boundary is derived here rather than borrowed from it -- a gate that threw in a legitimate state
# would take the whole lint down with it.
$scChangelog = Join-Path $RepoRoot 'CHANGELOG.md'
if (Test-Path -LiteralPath $scChangelog) {
    $scClLines = (Get-FenceMaskedText -Text ([System.IO.File]::ReadAllText($scChangelog, [System.Text.Encoding]::UTF8))) -split "`r?`n"
    $scHeadEnd = $scClLines.Count
    for ($i = 0; $i -lt $scClLines.Count; $i++) {
        if ($scClLines[$i] -match ('^#{' + $ehEntryLevel + '}\s')) { $scHeadEnd = $i; break }
    }
    $scHeadText = if ($scHeadEnd -gt 0) { (@($scClLines[0..($scHeadEnd - 1)])) -join "`n" } else { '' }
    $scChecked += Test-EntryShapeClaims -Rel 'CHANGELOG.md' -Rx $scHeadClaimRx -Text $scHeadText
}

Write-Coverage -Category 'entry-shape' -Checked $scChecked `
    -Note "claim(s) about how many '$('#' * $scLevel)' sections a changelog entry has, held against the $scExpected the scaffolder writes. The rule is the COUNT and not the section NAMES, chosen by measuring four candidates against this tree: matching names accuses two correct documents, because 'What does this change do?' and 'Type of change' are retired entry sections AND live headings of the PR template. History is excluded as in checks 11 and 12; branch/README.md is not, being a document about the shape, and neither is CHANGELOG.md's INTRO -- the entries below it are history, the intro is a live statement about the present mechanism that every cut copies through verbatim, so it gets its own pass with the level marker optional"

# --- 21. The config blueprint matches what the source's own libs say right now -----------------------------
#
# The blueprint (plugins/specialists-workflow-davekjohn/blueprint/config-blueprint.json) is what a
# consumer adopts its workflow config FROM: the source's own answers, with the reasoning that produced
# them. It is generated from scripts/repo-config.ps1, scripts/lib/branch-info.ps1 and the contract
# registry -- so the moment any of those three changes, the shipped artefact describes a repo that no
# longer exists.
#
# HELD BY REGENERATING IT, not by inspecting it. The generator is the only thing that knows the answer,
# so a check that re-derived the comparison would be a second implementation free to disagree with the
# first -- the shape this repo keeps paying for. Same mechanism as the shared-scripts drift check
# (check 9): build in memory, compare, report.
#
# WHY THIS DEFECT WOULD BE INVISIBLE OTHERWISE: nothing in the repo reads the artefact. A stale one
# breaks nothing here, passes every other check, and is discovered by a consumer adopting last week's
# answers under this week's explanations -- which is worse than no blueprint, because it carries a
# citation.
#
# Run through Invoke-NativeCapture rather than a bare '2>&1', which this repo forbids and its own suite
# scans for: in Windows PowerShell 5.1 redirecting a native command's stderr wraps each line in an
# ErrorRecord and sets $? to $false even on exit code 0. Caught by shared-scripts.tests.ps1 on the first
# draft of this very check.
$bpChecked = 0
$bpScript = Join-Path $repoRoot 'scripts\sync\build-config-blueprint.ps1'
if (Test-Path -LiteralPath $bpScript -PathType Leaf) {
    $bpChecked = 1
    . (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
    $bpRun = Invoke-NativeCapture -FilePath 'powershell' -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $bpScript, '-Check')
    if ($bpRun.ExitCode -ne 0) {
        Add-Error "[config-blueprint] $(($bpRun.Output | Out-String).Trim())"
    }
}
Write-Coverage -Category 'config-blueprint' -Checked $bpChecked `
    -Note 'the shipped config blueprint, held against a fresh generation from this repo own libs and the contract registry. Regenerated rather than inspected: the generator is the only thing that knows the answer, so a second implementation here could only disagree with it. Nothing in this repo READS the artefact, which is exactly why it needs a gate -- a stale one breaks nothing here and hands a consumer last week answers under this week explanations'

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
