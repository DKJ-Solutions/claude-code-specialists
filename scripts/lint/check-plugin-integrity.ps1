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
         as a subagent -- so check 6 never demands one of them. It does read them in one direction:
         a persona MAY back a manual of the same id (6b), and then has to name it.
      4. dead relative links AND broken anchors in every ROOT *.md (README.md, CHANGELOG.md, CLAUDE.md,
         CONTRIBUTING.md, SECURITY.md, INSTALL.md, UNINSTALL.md and any unfolded changelog entry file
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
         which it also names, and conversely every manual is backed by an agent def OR a persona of
         the same id (no orphan manual) -- a persona-backed manual must be named by that persona.
      7. shared agent-def blocks: every <!-- BEGIN/END shared:NAME --> region in an agent def still
         equals its canonical source in teams/agent-shared/<name>.md (see scripts/agents/build-agent-defs.ps1)
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
     19. the consumer-facing document set: a document named in that list but absent from the tree is
         reported instead of skipped, because checks 15 and 16 walk the same list and a missing entry
         lowers their coverage silently.
     20. a claimed entry-section COUNT vs. what the scaffolder writes, so prose describing the changelog
         entry cannot drift from the shape a branch actually gets. The rule is the count and not the
         section names, chosen by measuring four candidates. (20b) CHANGELOG.md's intro gets its own pass
         with the level marker optional: the entries below it are history, but the intro is a live
         statement that every cut copies through verbatim, so nothing else ever reads it.
     21. the shipped config blueprint, held by REGENERATING it from this repo's own libs and comparing.
         Nothing here reads the artefact, which is exactly why it needs a gate.
     22. a runnable command in a shipped SKILL.md must not name an absolute path. The page tells a
         consumer what to run, so the path has to resolve on their machine: '${CLAUDE_PLUGIN_ROOT}/...'
         does, 'C:/Users/<the author>/...' does not. Measured after adopt-config's page shipped with both
         of its commands pointing at the author's own plugin cache, pinned to a version. The subject is
         the '-File' argument rather than paths in general, because a tree-wide rule would be born
         accusing three correct comments that quote a user path to explain a path-mangling bug.
     23. a plugin's name says which kind it is, and it must sit where that says: 'team-*' under
         plugins/teams/, 'workflow-*' under plugins/workflows/, and every plugin one or the other. The
         directory rule is DERIVED from the prefix, so a plugin matching neither has its location held
         against nothing -- an unprefixed name switches the check off for itself rather than merely
         reading untidily. (Until #886 the reason was the core's workflow-sessioncheck counting by that
         prefix; that hook was retired with workflow-default and the argument above is the one that
         survives it.)
     24. the PR template keeps the two promises open-pr makes about it: the shipped reference under
         plugins/workflows/contributing-davekjohn/templates/ byte for byte against Get-PrTemplateReference,
         and THIS repo's own .github/pull_request_template.md only to the contract (one placeholder line
         the matcher recognises). Deliberately weaker for the second, which is genuinely repo-owned: a
         byte rule would refuse a correct change the day it grows a section. A heading is no longer part
         of that contract -- see the block at the check for why open-pr stopped needing one.
     25. the consumer document does not send its reader into a tier written for somebody else -- a link
         from releases/consumer/ into the development (tier 0) or internal (tier 1) tree. LINK TARGETS
         only; a tier named in prose is check 4's declined-path territory. Two neighbouring rules (a
         score, a branch name) were measured on the same tree and declined at 4 and 3 findings, all false.
     26. no frontmatter-bearing shipped document carries a byte-order mark, read as BYTES. Every other
         reader here uses ReadAllText, which strips a BOM before any regex sees it, so a BOM is invisible
         to this gate AND to any editor a reviewer would open -- the one defect findable by neither.
         Measured: adopt-config/SKILL.md shipped with EF BB BF in 4.1.0 and was the one model-invocable
         skill of eleven missing from the agent's skill listing. The subject is the BOM and NOT "must have
         frontmatter": this repo deliberately tolerates a skill page without a 'name:' line, so demanding
         the block would be this gate inventing a policy the repo declined.
     27. the script layer is pure ASCII -- every .ps1 check 5 parses, held to the rule
         .claude/rules/language-layers.md has stated since August 19, 2026 and nothing enforced. Windows
         PowerShell 5.1 reads a BOM-less .ps1 as the system ANSI code page, so a literal non-ASCII
         character decodes as two CP1252 characters, silently, and reaches whatever the script EMITS --
         measured on a middot in entry-scaffold-lib.ps1 that came out wrong in every generated changelog
         template. Check 14 sees that damage one layer downstream, in the generated markdown; this sees
         the literal upstream. A BOM is deliberately NOT a finding: on a .ps1 it is the fix.
     28. every '@'-import target resolves. A dead markdown link costs a reader one click; a dead import
         costs the SESSION THE WHOLE DOCUMENT, because Claude Code drops one it cannot resolve without
         erroring. Reuses measure-context-lib's own parser rather than restating its three resolution
         rules. (Listed here from August 26, 2026 -- the check shipped without its line in this list.)
     29. a plugin's OWN skill enumeration: an opt-in <!-- skills:plugin --> ... <!-- /skills:plugin -->
         span, held against the skills/ of the plugin the DOCUMENT ITSELF sits in (resolved from its
         path, not named in the marker). The two ways it is not check 10: the canonical set is that one
         plugin's rather than the marketplace's, and a claim is a LINK TARGET resolving to
         skills/<one>/SKILL.md rather than any backtick-quoted token -- so a two-column table with prose
         and backticked paths in the second column needs no rewriting to be markable. Opt-in for the
         reason check 10 is: measured over all four plugins, a generic version yields 8 findings on two
         documents that never claimed to enumerate anything.

    Exit code: 0 = no errors. 1 = at least one error (usable as a gate in open-pr.ps1).
.PARAMETER SkipCheck
    (Optional) coverage categories NOT to run, e.g. -SkipCheck parse,branch-template. FOR THIS GATE'S
    OWN TEST SUITES, and for nothing else: no gate -- open-pr, cut-release, CI -- passes it, and a guard
    test holds them to that.

    WHY IT EXISTS, MEASURED. The four check-plugin-integrity-*.tests.ps1 suites run this script 110 times
    over a fixture, each run a fresh process executing all 27 checks in order to assert one. As ONE suite
    that was 194s, of which 98% was inside those child runs, and it was the test gate's whole wall clock
    -- three times the next slowest suite, so the gate cost what this one suite cost. Profiled over the
    fixture, three checks were half of every run: agent-def, parse and branch-template, none of which
    most scenarios are about.

    THE SKIP CAME FIRST AND THE SPLIT SECOND, and both were needed. Skipping took the suite from 194s to
    ~160s; splitting it into four files (August 16, 2026, issue #714) took the same 110 runs from 160s in
    one lane to ~51s across four, because the test gate parallelises per FILE. Neither removed a scenario.

    A SKIPPED CHECK IS NEVER REPORTED AS 'checked 0'. This gate deliberately makes an empty scan visible
    -- 'no agent def found' is a finding-shaped statement, because a check that examined nothing must not
    read as a check that passed. A skip therefore prints its own [SKIP] line and no coverage line at all,
    so the two states cannot be confused by a reader or by an assert.

    An unknown category is a hard error rather than a no-op, because the failure mode this parameter
    introduces is silence: a scenario that skips 'agentdef' would run the check it meant to skip, and a
    scenario asserting the ABSENCE of a finding from a check it accidentally skipped would pass while
    testing nothing.
.EXAMPLE
    ./scripts/lint/check-plugin-integrity.ps1
#>
param([string[]]$SkipCheck = @())

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
# The PR-template contract check (24) needs the placeholder list open-pr matches against, and the
# reference body it ships. Both live here rather than inline in open-pr.ps1 since August 10, 2026 (#573)
# precisely so a gate can read them -- a list no gate can reach is a list that cannot be held to
# anything, which is how a consumer merged twelve PRs with no description.
. (Join-Path $PSScriptRoot '..\lib\pr-body-lib.ps1')

# measure-context-lib supplies the '@'-import parser check 28 resolves imports with: Get-ImportLinePath,
# Resolve-ImportPath and Test-IsFenceLine. Reused rather than restated so the gate and
# scripts/maintenance/measure-always-on.ps1 cannot drift on what an import means or where it resolves from
# -- the three rules are subtle enough that two implementations would eventually disagree, and the one that
# matters resolves relative to the IMPORTING FILE rather than to the repo root. It sets no strict mode of
# its own, like every lib in that directory, so it cannot loosen this script's Set-StrictMode.
. (Join-Path $PSScriptRoot '..\lib\measure-context-lib.ps1')

# -SkipCheck, resolved once here so every wrapped block asks the same question. The list of skippable
# names is written out rather than derived from the Write-Coverage calls: deriving it would accept any
# category the file happens to mention, including one in a comment, and the whole point of validating is
# that a name nobody implemented must not pass silently. Only the three the suite needs are skippable --
# adding a fourth is a deliberate act, and the narrower the list the smaller the surface for a check to
# be switched off by accident.
$script:SkippableChecks = @('agent-def', 'parse', 'branch-template')
$script:SkippedChecks   = @()
# SPLIT ON COMMAS AS WELL AS ON ARGUMENT BOUNDARIES, because the only caller invokes this script through
# 'powershell -File', and -File does no PowerShell parsing of its arguments: '-SkipCheck a,b,c' arrives as
# the single literal string 'a,b,c'. Without the split that lands on the unknown-name refusal below --
# which is at least loud, but it would refuse the exact form the docstring's own example uses.
foreach ($s in (@($SkipCheck) -split ',')) {
    if ([string]::IsNullOrWhiteSpace($s)) { continue }
    $name = $s.Trim()
    if ($script:SkippableChecks -notcontains $name) {
        Write-Host "check-plugin-integrity: -SkipCheck '$name' is not a skippable check. Known: $($script:SkippableChecks -join ', ')." -ForegroundColor Red
        exit 2
    }
    $script:SkippedChecks += $name
}
function Test-CheckEnabled([string]$Name) { return ($script:SkippedChecks -notcontains $Name) }

# ADDING A DOT-SOURCE HERE MEANS ADDING IT TO TWO TEST FIXTURES TOO -- check-plugin-integrity-fixture.ps1
# (the one the four check-plugin-integrity-*.tests.ps1 suites share) and workflow-exclusivity.tests.ps1
# both COPY this script into a temp tree and run it for real. A lib
# they do not copy does not make one check misbehave: the script dies at this line, so every check after
# it silently never runs. Measured on the day check 24 landed -- the exclusivity suite reported four
# failures in check 23, a check that change had not touched. Still TWO fixtures after the split, not five:
# the four suites build theirs from that one shared function.

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
            #
            # A SECOND IMPLEMENTATION OF ONE SECURITY-RELEVANT RULE, DELIBERATELY, and the pointer had
            # gone stale: it named Get-PluginManifestPaths in release-lib.ps1, which since August 9,
            # 2026 holds none of this logic -- it delegates to Get-PluginRoots in plugin-tree-lib.ps1.
            # That is the copy to keep this in step with.
            #
            # WHY THIS ONE IS NOT SIMPLY A CALL TO IT. Get-PluginRoots THROWS on the first bad source,
            # because its callers write to the paths it returns and must not proceed. A lint reports
            # every finding it can and then exits non-zero, so it has to keep walking after the first
            # -- and it names a different thing per plugin (outside the repo / folder missing / no
            # manifest), where the lib has one job and one error. Two shapes of the same rule, and the
            # reason is worth stating so the next reader does not "simplify" the gate into stopping at
            # its first finding.
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

# THE PUBLISHED PLUGIN SET, for the checks below that need to know where a plugin's folder is rather
# than assuming its shape. Derived once, here, immediately after check 1 has already reported anything
# wrong with the file it comes from.
#
# SWALLOWED ON FAILURE, DELIBERATELY, and this is the one place in this script where that is right: a
# marketplace this lib refuses to parse is a finding check 1 has just added by itself, with a better
# message than a rethrow here would give. A lint reports every finding it can rather than stopping at
# the first, so the checks that need the set degrade to an empty one -- and each of those reports its
# own zero coverage through Write-Coverage, so an empty set is visible rather than silently green.
$publishedPlugins = @()
try { $publishedPlugins = @(Get-RepoPluginRoots -RepoRoot $RepoRoot) } catch { }

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
# THE GATHER ABOVE IS OUTSIDE THE SKIP, DELIBERATELY. $agentDefs is read by three later checks
# (specialist, shared, frontmatter-bom), so skipping the collection would quietly narrow THEIR scan
# instead of this one's -- a skip that changes a different check's answer is worse than no skip at all.
# Only the frontmatter validation below is what -SkipCheck agent-def turns off.
if (Test-CheckEnabled 'agent-def') {
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
} else {
    Write-Skip 'agent-def -- not run (-SkipCheck). Nothing is asserted about agent-def frontmatter in this run.'
}

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
#
# RECURSIVE SINCE AUGUST 10, 2026, AND THAT ENDS THE CLASS RATHER THAN PATCHING IT (inbound #566). This
# glob was non-recursive with the comment "every subdirectory is gathered by its own rule below" -- true of
# agent defs, skills, manuals, personas and the plugin CHANGELOGs, and false of anything else. A markdown
# file at PLUGIN level matched no rule at all, which is where a plugin's own README.md sits: the first page
# a consumer reads, its links never once validated. Measured on the day this was widened: six such files,
# five of them already in the tree (plugins\teams\README.md, plugins\workflows\README.md, both workflow
# plugin READMEs, and contributing-davekjohn\scripts\README.md) and the sixth the portable contribution guide
# added by that same change -- a consumer-facing page whose whole purpose is to be copied, and whose dead
# links would therefore be copied with it. All six were clean, so this arrives green; the point is that
# nothing would have said otherwise.
#
# THIS IS THE THIRD TIME THE SAME OMISSION HAS BEEN WRITTEN UP in this block -- the family glob, then
# plugins/, then branch/ -- each time as "a file leaves the scan set by moving, and nothing reports that it
# has". A shape-by-shape list keeps losing that race, so plugins/ is now read whole: every markdown under it
# is payload, and payload gets its links read. The rules below that also reach in here are left exactly as
# they are, because each one covers paths OUTSIDE plugins/ too; their overlap is removed by the dedupe at
# the end of this set rather than by trimming them back.
$pluginsRootDir = Join-Path $RepoRoot 'plugins'
if (Test-Path -LiteralPath $pluginsRootDir) {
    $linkFiles += @(Get-ChildItem -Path $pluginsRootDir -Recurse -Filter '*.md' -File |
        Select-Object -ExpandProperty FullName)
}
# AND THE THIRD, ARRIVING THE SAME WAY: the workflow's own root folder. The branch files used to be root
# *.md and were therefore covered by the root glob; the branch/ split moved them one level down, and the
# workflow folder (August 14, 2026) gathered them together with the audience releases and their history
# README one level further. Same omission as the plugins/ one above and worth stating separately rather
# than merging the two comments, because these documents went dark in the same week for two unrelated
# reasons -- which is the actual lesson about this scan set: a file leaves it by MOVING, and nothing
# reports that it has.
#
# THE FOLDER IS THE SEAM'S OWN Directory, and it stopped needing a Split-Path on August 23, 2026: the branch
# document sits directly in the workflow folder now, where it used to sit in a branch/ subdirectory of it. So
# the seam answers with the folder itself, and scanning it covers the branch document, releases/ and whatever
# docs the folder gains.
$workflowDirForLinks = Join-Path $RepoRoot ((Get-BranchFilePaths).Directory -replace '/', '\')
if (Test-Path -LiteralPath $workflowDirForLinks) {
    $linkFiles += @(Get-ChildItem -Path $workflowDirForLinks -Recurse -Filter '*.md' -File |
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
    (Join-Path $RepoRoot '.claude\plugins\claude-specialists\team-alpha'),
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
# plugins/teams/agent-shared/*.md (11), .github/**/*.md (2) and .claude/rules/*.md (1). Agent defs are the
# glaring one -- they are the largest single body of prose this repo ships, they are payload, and their
# links had never been read by anything. Measured on the day this was added: one genuinely dead link had
# been sitting in an agent def, plus the location-dependent CLAUDE.md links repaired alongside it.
#
# Manuals and personas already have a rule each, so this is the same family finally covered in full. Each
# directory is guarded, for the reason the plugins/ glob is: a consumer has some of these and not others.
foreach ($payloadSpec in @(
    @{ Dir = 'plugins';        Recurse = $true;  Filter = '*.md'; Match = '\\agents\\' },
    @{ Dir = 'plugins\teams\agent-shared'; Recurse = $false; Filter = '*.md'; Match = $null },
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
# because it is one of the sanctioned direct-on-main actions -> the next full gate run is
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

# DEDUPED ONCE, HERE, so that widening a rule above never has to be weighed against double-reporting.
# The rules in this set are deliberately overlapping: several name a SHAPE of file wherever it sits (SKILL.md,
# *-manual.md, */agents/*.md) while others name a PLACE and take everything in it (the root, plugins/,
# branch/, releases/). Under the previous shape-by-shape arrangement the two kinds happened not to collide,
# and that coincidence was load-bearing -- the plugins/ glob carried a comment justifying non-recursion by
# it. It is not load-bearing any more: a file gathered twice is scanned twice, every finding in it reported
# twice, and the coverage line would overcount the set. First occurrence wins, so the order the rules run in
# still decides nothing.
#
# Checks 10, 11 and 12 derive their own sets from $linkFiles, so they inherit this for free.
$linkFiles = @($linkFiles | Select-Object -Unique)

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
    # EVERY NAME, because a branch created before the merge still carries the pair and their links resolve
    # from the same place -- see Resolve-BranchFilePath.
    #
    # AND IT IS THE WHOLE DOCUMENT, NOT ONLY ITS DEPLOY SECTION (August 23, 2026). Strictly, the entry's text
    # is what folds to the root; the plan above it stays where it is. One rule for one file is the honest
    # simplification: the head is guidance comments and phase headings, which carry no links at all in the
    # scaffold, and an author who does write one in a step means the same repo-root path the section below
    # asks for. Two bases inside one document would be a rule nobody could apply while writing.
    $entryRelsForLinks = @((Get-BranchFilePaths).File, (Get-BranchFilePaths).LegacyDeployment,
        (Get-BranchFilePaths).OlderDeployment) |
        ForEach-Object { '\' + ($_ -replace '/', '\') }
    if ($lf -match '\\personas\\.*-persona\.md$') {
        $dir = Join-Path $RepoRoot '.claude\extensions'
    } elseif (@($entryRelsForLinks | Where-Object { $lf.EndsWith($_) }).Count -gt 0) {
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
                # Where the resolution base is NOT the file's own directory (the two cases above),
                # say so in the finding. Without it the message reads as "this path is wrong" while
                # the path is correct for where the file sits -- and the author's next move is to add
                # a '../' that breaks the moment the text lands at its destination. Measured on
                # August 19, 2026: three suites failed on one entry, and the message named neither
                # the base it used nor why.
                $baseNote = if ($dir -eq (Split-Path -Parent $lf)) { '' } else {
                    " This file's links resolve from '$($dir.Replace($RepoRoot, '.'))' rather than from where it sits, because its text lands there."
                }
                Add-Error "[link] $rel -> dead link '$target' (expected file does not exist).$baseNote"
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
# this check pulls that forward, to the PR gate. Scanned: scripts/**/*.ps1 AND everything a plugin
# carries -- <plugin>/skills/**/*.ps1 (e.g. specialists-init's bootstrap), <plugin>/scripts/**/*.ps1
# (the shared SSOT home, issue #81) and, since August 23, 2026, <plugin>/hooks/**/*.ps1. Made unique so
# a path that hits two filters is not parsed twice.
#
# The plugin-scripts half is anchored on the plugins root rather than matched as a path segment (#405).
# 'plugins' is not a distinctive name: it is also the leaf of .claude/plugins/, so a segment match would
# widen this check to anything a consumer's plugin layer happens to carry. The old segment name
# ('claude-code-plugins') was unique enough to get away with it; this one is not.
# THE SET IS GATHERED ONCE AND CACHED, and it stopped being check 5's private business on
# August 23, 2026. Until then the gather sat inside the skip below, on the sound reasoning that
# $psScripts was read by nothing afterwards. Check 27 now reads the same set for a different property
# of the same files, so there are two callers -- and two checks over one set must not each decide for
# themselves what the set IS, which is the second-definition drift this gate exists to catch elsewhere.
#
# CACHED RATHER THAN CALLED TWICE, because the second glob is a -Recurse over the whole repo root. Two
# walks would double the most expensive part of the cheapest check, and the lazy field keeps the
# original saving intact: with both checks off, the walk never happens at all.
#
# THE HOOKS WERE MISSING FROM IT, and that was measured on the same day rather than reasoned about: 158
# .ps1 files are tracked here and this set held 151, the seven absentees being every plugin-carried
# plugins/<kind>/<plugin>/hooks/*.ps1. So a parse error in a SessionStart hook -- the five that speak on
# every session start in this repo among them -- was not seen by this gate at all, and a hook that does
# not parse does not announce itself: the harness reports the failure and the session continues without
# whatever the hook was there to say. They are named in .claude/rules/language-layers.md as part of the
# script layer for exactly that reason, so check 27 below could not have been pointed at that layer while
# they were out. Widening it fixes both checks at once, which is the argument for one set over two.
$script:PsScriptFileCache = $null
function Get-PsScriptFiles {
    if ($null -ne $script:PsScriptFileCache) { return $script:PsScriptFileCache }
    $pluginsRoot = Join-Path $RepoRoot 'plugins'
    $found = @()
    # THE Test-Path IS NEW WITH THE SECOND CALLER, and it is not decoration. Under
    # $ErrorActionPreference = 'Stop' a Get-ChildItem on a missing directory ENDS THE RUN, and while this
    # gather sat inside check 5's skip that could only happen in a tree where 'parse' was enabled. Check
    # 27 reads the same set unconditionally, so without this line a tree with no scripts/ directory would
    # take the whole gate down instead of reporting a coverage of zero -- and a gate that dies is worse
    # than one reporting zero, which is the argument check 8's guarded read already rests on.
    $scriptsDir = Join-Path $RepoRoot 'scripts'
    if (Test-Path -LiteralPath $scriptsDir -PathType Container) {
        $found += (Get-ChildItem -Path $scriptsDir -Recurse -Filter '*.ps1' -File)
    }
    $found += (Get-ChildItem -Path $RepoRoot -Recurse -Filter '*.ps1' -File |
        Where-Object {
            $_.FullName -match '\\skills\\' -or
            ($_.FullName.StartsWith($pluginsRoot + '\') -and
                ($_.FullName -match '\\scripts\\' -or $_.FullName -match '\\hooks\\'))
        })
    $script:PsScriptFileCache = @($found | Sort-Object -Property FullName -Unique)
    return $script:PsScriptFileCache
}

$psScripts = @()
if (Test-CheckEnabled 'parse') {
    $psScripts = @(Get-PsScriptFiles)
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
} else {
    Write-Skip 'parse -- not run (-SkipCheck). Nothing is asserted about PowerShell syntax in this run.'
}

# --- 6. specialists-system integrity -------------------------------------------------------------------
# This repo is the source of the specialists system, so the agent-def<->manual link must be at
# least as strict here as for a consumer. Per plugin (folder with agents/ and manuals/):
#   6a. every '<group>-<id>' is unique across all agent defs; every agent def has a valid 'name:'
#       (Claude Code call name), a corresponding manuals/<g>-<id>-manual.md in the same plugin, and
#       names that manual in its text.
#   6b. no orphan manual: every manuals/<g>-<id>-manual.md is backed by an agents/<g>-<id>-agent.md
#       OR a personas/<g>-<id>-persona.md. A PERSONA MAY BACK A MANUAL (#1017). Being a persona says
#       where a specialist RUNS -- in the main loop rather than as a subagent -- and says nothing
#       about whether their craft has a playbook worth reading on demand. Until this changed it said
#       both, and the orchestrator paid for it: always loaded, and the one specialist whose every rule
#       had to sit on the always-on path, because the gate refused him the on-demand half the other
#       fifteen have. Where a persona backs a manual it must NAME it, for the same reason 6a makes an
#       agent def name its own -- nothing else would ever read it. A persona with no manual is the
#       normal case and is asserted about in neither direction.
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
            $agentPath   = Join-Path $pluginRoot ("agents\$g-$id-agent.md")
            $personaPath = Join-Path $pluginRoot ("personas\$g-$id-persona.md")
            $hasAgent   = Test-Path -LiteralPath $agentPath   -PathType Leaf
            $hasPersona = Test-Path -LiteralPath $personaPath -PathType Leaf
            if (-not $hasAgent -and -not $hasPersona) {
                $rel = $_.FullName.Replace($RepoRoot, '.')
                Add-Error "[specialist] ${rel}: orphan manual -- no corresponding agents/$g-$id-agent.md or personas/$g-$id-persona.md in the same plugin."
            } elseif (-not $hasAgent) {
                # Persona-backed. The naming half of 6a applies here for the same reason it does there:
                # the manual is only ever read because the body that IS loaded points at it.
                $pText = [System.IO.File]::ReadAllText($personaPath, [System.Text.Encoding]::UTF8)
                if ($pText -notmatch [regex]::Escape("manuals/$g-$id-manual.md")) {
                    $pRel = $personaPath.Replace($RepoRoot, '.')
                    Add-Error "[specialist] ${pRel}: persona backs 'manuals/$g-$id-manual.md' but does not name it, so nothing would ever read it."
                }
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
# THE ALREADY-RESOLVED SET IS PASSED IN, not resolved again here. The registry composes each mirror
# path from its plugin's root, so it needs the same answer this script derived at its top -- and
# deriving it a second time would do so OUTSIDE that guarded try/catch. Measured: with a
# marketplace.json that does not parse, the unguarded second read threw straight out of this line and
# ended the run, so checks 9 through 22 never reported and no Summary was printed. A gate that dies is
# worse than a gate that reports zero, because zero is visible in the coverage line below.
$sharedPairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot -PluginRoots $publishedPlugins)
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

# Canonical skillset: every <plugin root>/skills/<name>/SKILL.md, across ALL published plugins (not
# just the core -- an add-on team's start-task counts too). Exactly one skill-name folder between
# 'skills' and the file, so a deeper file such as a level-3 progressive-disclosure
# skills/<name>/references/SKILL.md, should that pattern ever appear, is not mistaken for a top-level
# skill.
#
# THE PLUGIN HALF IS ENFORCED NOW, WHICH IT WAS NOT (August 9, 2026). This walked everything under
# plugins/ and kept whatever matched '\skills\<one>\SKILL.md', while the comment above it claimed the
# match began at a plugin. It did not: any skills/ directory anywhere under plugins/ counted, published
# or not. Nothing was wrong in the output -- measured on the day it was changed, every skills/ directory
# under plugins/ did belong to a published plugin -- so this is a claim being made true rather than a
# defect being repaired. Worth doing because the next reader takes the comment at its word, and because
# the plugin roots are now something this gate can simply ask for.
#
# The name is read from the frontmatter 'name:' (the authoritative Claude Code call name, /plugin:name)
# rather than the folder name; as of this writing every skill's folder name happens to equal its
# frontmatter name, so this made no observable difference here, but frontmatter is the real source of
# truth if the two ever diverge. Falls back to the folder name only if 'name:' is missing from the
# frontmatter, so a future skill without that line does not silently drop out of the canonical set (not
# a new failure mode: the frontmatter's own presence/shape is check 3's domain, not this one's).
$skillCanonicalList = New-Object System.Collections.Generic.List[string]
foreach ($skillsDir in (Get-PluginSubdirs -PluginRoots $publishedPlugins -Leaf 'skills')) {
    Get-ChildItem -Path $skillsDir -Recurse -Filter 'SKILL.md' -File |
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
    # The mirror of $consumedEndIndices, added August 26, 2026 with check 29 -- see the note there. Every
    # BEGIN this walk VISITS, so the sweep below can report a second BEGIN pasted INSIDE an already-open
    # span. That case was silent here from the start: the walk jumps from a span's opener straight past
    # its END, so a nested BEGIN is never visited, and the span pairs across it as though it were prose.
    # The duplicate-END half was reported from day one; this is the same defect facing the other way, and
    # it was found by walking into it on check 29's own branch, where a run came out green for the wrong
    # reason. Born green here: 0 findings across the whole scan set at introduction.
    $visitedBeginIndices = New-Object System.Collections.Generic.HashSet[int]
    $searchStart = 0
    while ($searchStart -le $maskedContent.Length) {
        $beginMatch = $skillBeginRegex.Match($maskedContent, $searchStart)
        if (-not $beginMatch.Success) { break }
        [void]$visitedBeginIndices.Add($beginMatch.Index)
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
    foreach ($m in $skillBeginRegex.Matches($maskedContent)) {
        if ($visitedBeginIndices.Contains($m.Index)) { continue }
        $beginLineNo = 1 + [regex]::Matches($maskedContent.Substring(0, $m.Index), "`n").Count
        Add-Error ("[skill-list] ${rel}: '<!-- skills:all -->' at line $beginLineNo sits INSIDE an already-open" +
            " span, so it is not the opener of anything -- the span that swallowed it closes at the next" +
            " '<!-- /skills:all -->' and its contents were checked as one. Usually this means the marker was" +
            " written in prose above a real span; show it in a fenced block instead.")
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
#     claude plugin install team-alpha@claude-code-specialists --scope project
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

# WHERE THIS REPO'S CHANGELOG ACTUALLY LIVES, resolved once for the three checks below that need to name
# it: this lifecycle-command exclusion, the entry-heading pass (check 19) and the shape-claim pass
# (check 20b). All three said the literal 'CHANGELOG.md' until August 27, 2026, when the file moved into
# contributing-davekjohn/ and this repo answered Get-ChangelogPath to say so. A gate that keeps naming the
# old path does not fail loudly -- it silently judges a file that is not there, which is the quietest way
# for a check to stop checking.
#
# DOT-SOURCED IN A SCRIPTBLOCK, the idiom check 16 established and for its reason: repo-config is not
# loaded in this process anywhere else, and pulling two dozen repo functions into the whole lint to serve
# three checks is how a gate acquires a dependency nobody meant to give it.
#
# READ THE SAME WAY THE FOLD READS IT -- Get-SeamValue over Get-DefaultChangelogPath -- rather than with a
# literal fallback of its own. A gate whose idea of "the changelog" can differ from the fold's is a gate
# that passes a document nobody writes and never sees the one that is written.
#
# THIS ADDS seam-lib.ps1 TO THE GATE'S DEPENDENCIES, which the lint fixture has to copy alongside the
# other libs. That is stated here because the failure is loud but misleading: the dot-source fails inside
# the fixture's own copy of this script, the gate dies before check 11, and four suites report several
# dozen unrelated scenarios as broken -- the same shape the fixture's marketplace list has twice paid for.
$changelogRel = & {
    $clCfg = Join-Path $RepoRoot 'scripts\repo-config.ps1'
    if (Test-Path -LiteralPath $clCfg) { . $clCfg }
    . (Join-Path $PSScriptRoot '..\lib\seam-lib.ps1')
    Get-SeamValue -Name 'Get-ChangelogPath' -Default (Get-DefaultChangelogPath -RepoRoot $RepoRoot)
}
$changelogRelWin = $changelogRel -replace '/', '\'
$changelogFull   = Join-Path $RepoRoot $changelogRelWin

$lifecycleFiles = @($linkFiles | Where-Object {
    $rel = $_.Substring($RepoRoot.Length).TrimStart('\', '/')
    if ($rel -eq $changelogRelWin) { return $false }
    if ($rel -match '\\CHANGELOG\.md$') { return $false }
    if ($rel -match '(^|\\)RELEASE\.md$') { return $false }
    if ($rel -match '^releases\\') { return $false }
    # The moved release pages are the same history at their workflow-folder address (August 14, 2026).
    if ($rel -match '^contributing-davekjohn\\releases\\') { return $false }
    # A root <branch-name>.md entry file is history in the making; same reasoning as CHANGELOG.md.
    if (($rel -notmatch '\\') -and (Test-IsChangelogEntryFile -Path $_)) { return $false }
    # branch/ is the same subject at its new address. Both files: the entry is history in the making, and
    # the step list is a scratch pad that never travels anywhere -- neither is a document a consumer reads
    # a lifecycle command off, which is what this check judges.
    # SEPARATORS NORMALISED before the escape, the lesson check 20 already paid for: the seam answers with
    # forward slashes while $rel is built from a Windows path, and an exclusion that compares the two raw
    # matches nothing -- silently, since these files rarely carry the commands this check judges.
    # THE BRANCH DOCUMENT, NOT THE WHOLE WORKFLOW FOLDER (August 23, 2026). This used to exclude everything
    # under the branch directory, which WAS only branch files; the seam's Directory is the workflow folder
    # itself now, so the same expression would wave through the folder's README, CLAUDE.md and
    # CONTRIBUTING.md -- three documents that print lifecycle commands and are exactly what this check is for.
    $lcBranchDoc = @((Get-BranchFilePaths).File, (Get-BranchFilePaths).LegacyCycle,
        (Get-BranchFilePaths).LegacyDeployment, (Get-BranchFilePaths).OlderCycle,
        (Get-BranchFilePaths).OlderDeployment) | ForEach-Object { $_ -replace '/', '\' }
    if ($lcBranchDoc -contains $rel) { return $false }
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
# AND THE AUDIENCE TIER'S HEADING, which became one of these on August 23, 2026 by moving up a level. It is
# not a named SECTION of the entry -- Get-EntrySectionHeadings deliberately does not list it, because it is
# the tier writer's business -- but it now sits at the section level, so a check that only knew the named set
# would report every single entry for a heading the scaffolder itself writes. Both wordings, for the reason
# every reader here takes both: entries carrying the previous one are all over CHANGELOG.md.
$ehSectionNames += @(Get-EntryTierHigherHeading) + @(Get-EntryTierHigherRetiredHeadings)
$ehSectionNames = @($ehSectionNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
# At or above the entry's own level: '#' .. '##' while an entry is an H2.
$ehTooHighRx = '^#{1,' + $ehEntryLevel + '}\s'
# AND THE SAME TAIL TOLERANCE THE LIB'S READERS GOT (August 19, 2026) -- this gate is one of them, and it
# was the one left out. The 'Pull Request' heading carries the merge stamp now, so a folded entry reaches
# CHANGELOG.md as '### Pull Request <middot> 20260819-171500'. Anchored on a bare '\s*$' the name has to be
# the whole line, so that heading reads as a section nobody declares and the CHANGELOG.md half below raises
# [entry-heading] on it -- on the one write that happens directly on main, past every PR gate, inside the
# required CI check. Every PR after the first fold would have been blocked by the fold of the one before it.
# THE STAMP IS STRIPPED BEFORE THE COMPARISON, not tolerated inside it: the capture is still only the name,
# so 'Who is this For' differing by one letter is caught exactly as strictly as it was.
$ehSectionRx = '^#{' + $ehSectionLevel + '}\s+(.+?)' + (Get-EntrySectionHeadingTail)

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
# AND THE ENTRY IS A SECTION OF A DOCUMENT, NOT A DOCUMENT (August 23, 2026). Both branch files used to open
# with an H2, so the structural test -- the only thing that tells an entry from a root doc -- said yes to the
# step list too, and it had to be excluded by PATH. development.md opens with an H1, so that test now
# says no to the WHOLE file, which would have quietly dropped every branch entry out of this check rather
# than merely mis-reporting it. The exclusion is gone and the entry is read out of the document instead --
# Split-Development, the same boundary the fold and the two gates use.
#
# WITH ITS LINE OFFSET, because this check prints line numbers. A finding reported against the entry's own
# first line, in a file where the entry starts forty lines down, is a finding the reader cannot find.
#
# The fold needed no such repair: it reaches the document by path and only ever applies the structural test
# to loose *.md in the ROOT, where a step list has never lived.
$entryTextsForHeadings = @()
foreach ($ef in @(Get-ChildItem -Path $RepoRoot -Filter '*.md' -File |
        Where-Object { Test-IsChangelogEntryFile -Path $_.FullName })) {
    $entryTextsForHeadings += [pscustomobject]@{
        Rel    = $ef.FullName.Substring($RepoRoot.Length).TrimStart('\', '/')
        Text   = [System.IO.File]::ReadAllText($ef.FullName, [System.Text.Encoding]::UTF8)
        Offset = 0
    }
}
# THE BRANCH DOCUMENT, AND ONLY WHILE IT HOLDS AN ENTRY. In its reset state the DEPLOY section is the empty
# form, which has nothing to say about heading structure; check 13b is what holds that state to its shape.
# Every older name is read as well, because a branch created before the merge still has to be checked --
# Resolve-BranchFilePath picks the one that declares this branch.
$branchDocForHeadings = Resolve-BranchFilePath -Kind Deployment -RepoRoot $RepoRoot
$branchDocPathForHeadings = Join-Path $RepoRoot ($branchDocForHeadings -replace '/', '\')
if (Test-Path -LiteralPath $branchDocPathForHeadings) {
    $bdText = [System.IO.File]::ReadAllText($branchDocPathForHeadings, [System.Text.Encoding]::UTF8)
    if (Test-BranchChangelogIsFilled -Text $bdText) {
        $bdSplit = Split-Development -Text $bdText
        $entryTextsForHeadings += [pscustomobject]@{
            Rel    = $branchDocForHeadings -replace '/', '\'
            Text   = $(if ($bdSplit.Found) { $bdSplit.Entry } else { $bdText })
            Offset = $(if ($bdSplit.Found) { $bdSplit.Index } else { 0 })
        }
    }
}
foreach ($ef in $entryTextsForHeadings) {
    $ehChecked++
    $rel = $ef.Rel
    $masked = Get-FenceMaskedText -Text $ef.Text
    $ehLines = $masked -split "`r?`n"
    for ($i = 1; $i -lt $ehLines.Count; $i++) {
        $line = $ehLines[$i]
        if ($line -match $ehTooHighRx) {
            $lvl = ($line -replace '^(#+).*$', '$1')
            Add-Error "[entry-heading] ${rel}:$($ef.Offset + $i + 1): a '$lvl ' heading in an entry body, at or above the entry's own level. An entry heading is an H$ehEntryLevel, so an H$ehEntryLevel here becomes a SEPARATE entry the moment the fold pastes this section into CHANGELOG.md -- one that declares no impact and therefore reads as an undeclared tier 0 -- and an H1 climbs above every entry in the document. Use '$('#' * ($ehSectionLevel + 1)) ' or bold instead."
        } elseif (($line -match $ehSectionRx) -and -not (Test-IsDeclaredSectionHeading $line)) {
            Add-Error "[entry-heading] ${rel}:$($ef.Offset + $i + 1): '$($Matches[1])' is at the level of the entry's named sections but is not one of them ($($ehSectionNames -join ', ')). A section ends at the next heading of this level or above, so this truncates whichever section it sits in -- and if it is a misspelling of a real section heading, the entry silently loses that declaration and the tier/significance gates read nothing. Use '$('#' * ($ehSectionLevel + 1)) ' for a sub-heading, or correct the spelling."
        }
    }
}

$clForHeadings = $changelogFull
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
        # AND IT HAPPENED A THIRD TIME ON AUGUST 16, 2026, which is why the list of openers is no longer
        # built here. This read the CURRENT first key plus that key's retired NAMES -- correct until the
        # first KEY itself moves, which it did when 'Branch title' stopped being written: the retired-name
        # lookup then answered for 'What' while every pending entry in CHANGELOG.md still opened with
        # 'Branch title', and six correct entries were reported as split. Get-EntryOpeningSectionKeys is
        # the format owner's own answer to "which sections have ever opened an entry"; the gate adds each
        # one's retired names, which is the part that was already right.
        $ehHeadings = Get-EntrySectionHeadings
        $ehOpeners = @()
        foreach ($ehKey in (Get-EntryOpeningSectionKeys)) {
            $ehOpeners += @($ehHeadings[$ehKey]) + @(Get-EntrySectionRetiredNames -Key $ehKey)
        }
        # AND A FOURTH TIME, ON AUGUST 23, 2026 -- not a rename this time but a LEVEL MOVE, which is why the
        # three repairs above did not cover it. Tier 0 lost its heading when the entry became the development
        # cycle's DEPLOY section, and the audience tier's heading moved up to the section level to take its
        # place. So the first named section an entry has is now 'What makes this deploy extra special', and
        # this repo's own freshly folded entry was reported as split the moment it landed on main.
        #
        # ADDED BESIDE THE KEYED LIST RATHER THAN INTO IT, because it is not a section KEY: the tier writer
        # owns that heading, deliberately, and Get-EntrySectionHeadings does not answer for it. Both wordings,
        # like everywhere else that reads it -- every entry already in CHANGELOG.md carries the previous one.
        $ehOpeners += @(Get-EntryTierHigherHeading) + @(Get-EntryTierHigherRetiredHeadings)
        $ehOpeners = @($ehOpeners | Where-Object { $_ })
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
    -Note $(if ($entryTextsForHeadings.Count -eq 0) { 'no unfolded entry in the branch document or the root, so only CHANGELOG.md was judged -- normal between merges' } else { "$($entryTextsForHeadings.Count) unfolded entry(ies) plus CHANGELOG.md" })
# --- 13b. no branch document is left behind between branches -----------------------------------------------
# THE CHECK WAS INVERTED ON AUGUST 23, 2026 (Dave), AND THE THING IT PROTECTS DID NOT CHANGE. It used to hold
# the trunk's copy of development.md to the formatter byte-for-byte: a reference beside a scaffolder
# that writes the same shape is TWO SOURCES OF ONE FORMAT, which this repo has paid for repeatedly -- the
# scaffold wording, the fence readers, the tier sections. Before that it held two files under
# branch/templates/ for the same reason.
#
# THERE IS NO TRUNK COPY TO HOLD ANY MORE. The document exists for the lifetime of a branch: new-branch
# creates it, the fold removes it. So the drift this check existed to catch cannot happen -- a hand-edit to
# a reset copy needs a reset copy -- and what is worth asserting instead is the invariant that replaced it:
# NO DOCUMENT ANYWHERE DECLARES THE TRUNK. Absent is the trunk's normal state, a file naming this branch is
# work in progress, and a file naming the trunk is a leftover the fold should have taken.
#
# WHICH IS ALSO THE ONE STATE A CONSUMER CAN REACH BY DOING NOTHING WRONG, and the reason this reports the
# path rather than a shape. A repo updating from an older plugin has a trunk copy the previous fold wrote;
# their next fold removes it. Here, on the repo that owns the format, one should never survive a run.
#
# NO SHAPE IS ASSERTED, deliberately, and that is the cost of the inversion stated out loud. While a reset
# state existed there was one moment when the file was known-empty and could be compared to the formatter;
# a branch's file holds somebody's work and never can be. The scaffold gate and the step-list gate read the
# file's CONTENT on the way to the PR, so what is lost is the byte-comparison, not the coverage.
$btChecked = 0
$btStale = 0
if (Test-CheckEnabled 'branch-template') {
    # DOT-SOURCED INSIDE A SCRIPTBLOCK rather than at the top of the gate, deliberately. repo-config is not
    # loaded in this process anywhere else -- the one other check needing a repo-owned value spawns the script
    # that owns it -- and pulling two dozen repo functions into the whole lint to serve one check is how a gate
    # acquires a dependency nobody meant to give it. It is still dot-sourced now that no content is generated
    # here, because Get-BranchTrunkName reads a repo seam and answering it wrong would flip this check's verdict.
    $btState = & {
        $btCfg = Join-Path $RepoRoot 'scripts\repo-config.ps1'
        if (Test-Path -LiteralPath $btCfg) { . $btCfg }
        . (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
        $btRel  = (Get-BranchFilePaths).File
        $btFull = Join-Path $RepoRoot ($btRel -replace '/', '\')
        $btOnDisk = if (Test-Path -LiteralPath $btFull) {
            [System.IO.File]::ReadAllText($btFull, [System.Text.Encoding]::UTF8)
        } else { $null }
        [pscustomobject]@{
            Rel      = $btRel
            Present  = ($null -ne $btOnDisk)
            Declared = $(if ($null -ne $btOnDisk) { Get-BranchFileDeclaredBranch -Text $btOnDisk } else { '' })
            Trunk    = (Get-BranchTrunkName)
        }
    }
    $btChecked = 1
    if ($btState.Present) {
        if (-not $btState.Declared) {
            $btStale = 1
            Add-Error "[branch-template] $($btState.Rel) exists but declares no branch in its heading. Every reader of this document -- the fold, the two local gates and the CI gate -- identifies a branch's work by that name, so a document without one belongs to nobody. Let new-branch.ps1 write it rather than creating it by hand."
        } elseif ($btState.Declared -eq $btState.Trunk) {
            $btStale = 1
            Add-Error "[branch-template] $($btState.Rel) names the trunk ('$($btState.Trunk)'), which is the empty state this repo no longer keeps. The document lives only while a branch is open -- new-branch.ps1 creates it and fold-changelog-entry.ps1 removes it -- so a trunk-declaring copy is a leftover from a fold that ran under the old behaviour. Delete it."
        }
    }
    Write-Coverage -Category 'branch-template' -Checked $btChecked `
        -Note $(if ($btStale -gt 0) { 'a document declaring the trunk was found where none should exist' } elseif ($btState.Present) { "present and declaring '$($btState.Declared)', which is a branch in progress" } else { 'absent, which is the trunk between branches' })
} else {
    Write-Skip 'branch-template -- not run (-SkipCheck). Nothing is asserted about whether a branch document is left behind in this run.'
}

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
            # NAME WHAT THE CHILD SAID, not only its exit code (#851). A non-zero exit with no [mojibake]
            # line means the sub-script never got to READ anything, and the likeliest cause has nothing to
            # do with encoding: the source-repo guard refusing the copy that was invoked. Measured
            # 2026-08-24, when this line reported 'the mojibake gate could not complete' for two lanes
            # whose trees were both clean -- a finding about the wrong subject, whose real explanation was
            # reachable only by running the sub-script by hand. The exit code alone cannot tell them apart,
            # so the child's own first line is quoted and a refusal is named when it is one.
            $mjWhy = @($mjOut | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
            $mjSaid = if ($mjWhy) { " It said: '$(([string]$mjWhy[0]).Trim())'" } else { ' It printed nothing.' }
            $mjHint = if (@($mjOut | Where-Object { $_ -match 'REFUSED:' }).Count -gt 0) {
                ' The sub-script REFUSED to run, so this is not about encoding: the copy invoked is not the one the repo being checked maintains. Run the gate from that repo, or from a worktree of it.'
            } else { '' }
            Add-Error ("[mojibake] scripts/maintenance/fix-mojibake.ps1 -Check exited $mjCode without naming a file -- the mojibake gate could not complete, so nothing is asserted about encoding." + $mjHint + $mjSaid)
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
        'the set this repo names in Get-MojibakePaths (scripts/repo-config.ps1): every *.md in the root (the changelog and the root docs), every *.md under contributing-davekjohn/ (the entry whose text is pasted into CHANGELOG.md, the step list, and the templates), plus every *.md under plugins/ and every note under releases/. Peeled by the inverse round trip rather than matched against a table of known sequences'
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
# THE TWO ARE ONE FILE AGAIN -- INSTALL.md, the short page as its first half -- so the set is
# three entries, not four. Note what the merge did to the failure mode this comment describes: while
# they were separate, naming the wrong one silently halved the coverage. Now there is one page and no
# wrong one to name, which is worth more than the entry it saved.
#
# AND THEN THEY WERE THREE AGAIN, on the audience seam rather than the length one (inbound #664,
# August 14, 2026). The adoption half became plugins/ADOPTION.md and the two plumbing pages moved to
# the repo root, so the set is four entries at three new paths. ADOPTION.md is the entry that matters
# most here, and this comment predicted exactly why: the captured samples and measured figures these
# two checks exist for -- the bootstrap's closing line, the 4+15+2 counts, the verification snippet --
# travelled WITH the adoption half. Listing only the pages that kept their names would have left both
# checks reporting green over the document that now holds their subject, for the second time.
$consumerDocs = @(
    'INSTALL.md',
    'UNINSTALL.md',
    'plugins\ADOPTION.md',
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
        if (-not (Test-FenceDelimiterLine -Line $lines[$i])) { continue }
        if ($open -lt 0) { $open = $i; continue }
        $close = $i
        $lang = ($lines[$open] -replace '^\s*```', '').Trim().ToLowerInvariant()
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
        if (Test-FenceDelimiterLine -Line $lines[$i]) { $inFence = -not $inFence; continue }
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
# 'Type of change' are RETIRED entry sections and, AT THE TIME THIS WAS MEASURED, live headings of
# .github/pull_request_template.md. So a name-matcher accuses two correct documents of being stale for
# describing the PR body accurately -- and a check that is born red with an exemption list is the shape
# this repo was already bitten by (Get-RosterIgnoredIds).
#
# THAT COLLISION IS GONE, AND THE MEASUREMENT STANDS ANYWAY (#538, August 9, 2026). Both headings were
# removed from the PR template that day, so the six false findings are no longer reproducible from the
# tree. The tense above is deliberate rather than tidied away: it names WHEN the count was measured
# against the names, which is the only form in which a superseded measurement is still worth anything.
# Two reasons the conclusion does not move with the collision. First, name-matching lost on more than
# that: it also scored 3 findings with 2 false on the narrowed variant, against 4 claims with 3 correct
# for the count. Second, and structurally, a rule keyed on names is one rename away from silence in
# either direction -- which is precisely what just happened to the collision, and would just as easily
# happen to a match the check depends on. The count is a fact the scaffolder owns and no rename touches.
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
# copies, the release notes, RELEASE.md, and the branch's own document, which is history in the making.
# contributing-davekjohn/CONTRIBUTING.md is deliberately NOT excluded -- it is a document ABOUT the shape,
# which is precisely this check's subject. Two pages used to carry that role and both are gone into it:
# branch/README.md at the merge on August 23, 2026, and this folder's own CLAUDE.md on August 26 (#886).
# One page now, and the check reaches it the same way.
#
# AND NEITHER IS CHANGELOG.md'S INTRO (August 8, 2026). It went out with the rest of that file on the history
# grounds above, and this repo had already written down why that reasoning does not reach the intro:
# release-lib.ps1 was bitten by it on the per-plugin CHANGELOGs and recorded the lesson one screen above the
# code -- "the entries below the intro were history, the intro was a live statement about the present
# mechanism". A cut empties this document down to that intro and carries it through verbatim, so it is the
# one piece of prose in the repo that no release ever rewrites and no reviewer ever opens. Measured on the
# day this was written: it claimed THREE sections while the scaffolder wrote six, and had done so since
# August 6 -- two days, one release, and a consumer-facing release page in between.
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
# THE WRITTEN COUNT, NOT THE RECOGNISED ONE (August 16, 2026). Get-EntrySectionHeadings answers "which
# heading does key X have" for every key that ever existed, retired ones included, so counting its keys
# would hold a document to a shape the scaffolder stopped producing -- and accuse a correct page of being
# stale. Get-EntryWrittenSectionKeys is the shape a reader actually meets.
#
# AND IT IS DELIBERATELY NOT READ THROUGH repo-config, unlike check 16's own generation one screen up. That
# was tried on August 19, 2026, while the audience tier's heading was briefly a third '###' section, and
# reverted with it: the count is a property of the FORMAT rather than of the repo, so pulling two dozen repo
# functions in here to answer it would be a dependency bought for nothing.
$scExpected = @(Get-EntryWrittenSectionKeys).Count
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
    if ($rel -eq $changelogRelWin) { return $false }
    if ($rel -match '\\CHANGELOG\.md$') { return $false }
    if ($rel -match '(^|\\)RELEASE\.md$') { return $false }
    if ($rel -match '^releases\\') { return $false }
    # The moved release pages are the same history at their workflow-folder address (August 14, 2026).
    if ($rel -match '^contributing-davekjohn\\releases\\') { return $false }
    if (($rel -notmatch '\\') -and (Test-IsChangelogEntryFile -Path $_)) { return $false }
    # The branch's own document only -- NOT the whole folder. It is history in the making above and a scratch
    # pad below; the folder's own pages are the convention itself and are checked.
    #
    # SEPARATORS ARE NORMALISED, and leaving that out was caught by this check on its first run:
    # Get-BranchFilePaths returns forward slashes while $rel is built from a
    # Windows path, so the two never compared equal and the exclusion did nothing. The step list of the very
    # branch that added this check was then reported for QUOTING a stale count while explaining it.
    $scPaths = Get-BranchFilePaths
    $scBranchFiles = @($scPaths.File, $scPaths.LegacyCycle, $scPaths.LegacyDeployment,
        $scPaths.OlderCycle, $scPaths.OlderDeployment) |
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
$scChangelog = $changelogFull
if (Test-Path -LiteralPath $scChangelog) {
    $scClLines = (Get-FenceMaskedText -Text ([System.IO.File]::ReadAllText($scChangelog, [System.Text.Encoding]::UTF8))) -split "`r?`n"
    $scHeadEnd = $scClLines.Count
    for ($i = 0; $i -lt $scClLines.Count; $i++) {
        if ($scClLines[$i] -match ('^#{' + $ehEntryLevel + '}\s')) { $scHeadEnd = $i; break }
    }
    $scHeadText = if ($scHeadEnd -gt 0) { (@($scClLines[0..($scHeadEnd - 1)])) -join "`n" } else { '' }
    $scChecked += Test-EntryShapeClaims -Rel $changelogRel -Rx $scHeadClaimRx -Text $scHeadText
}

Write-Coverage -Category 'entry-shape' -Checked $scChecked `
    -Note "claim(s) about how many '$('#' * $scLevel)' sections a changelog entry has, held against the $scExpected the scaffolder writes. The rule is the COUNT and not the section NAMES, chosen by measuring four candidates against this tree: matching names accuses two correct documents, because 'What does this change do?' and 'Type of change' are retired entry sections AND live headings of the PR template. History is excluded as in checks 11 and 12; contributing-davekjohn/branch/README.md is not, being a document about the shape, and neither is CHANGELOG.md's INTRO -- the entries below it are history, the intro is a live statement about the present mechanism that every cut copies through verbatim, so it gets its own pass with the level marker optional"

# --- 21. The config blueprint matches what the source's own libs say right now -----------------------------
#
# The blueprint (the workflow plugin's blueprint/config-blueprint.json) is what a
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

# --- 22. a skill's own command must not point at the author's disk ----------------------------------------
# A shipped SKILL.md tells a consumer what to RUN. The path in that command therefore has to resolve on
# THEIR machine, and '${CLAUDE_PLUGIN_ROOT}' is what does it -- the plugin root, substituted when the skill
# runs, which is why the other pages already use it.
#
# THE MEASURED DEFECT: adopt-config's page shipped in v3.8.0 with both of its commands written as
# 'C:/Users/<the author>/.claude/plugins/cache/.../3.8.0/scripts/...'. Wrong for every consumer twice over
# -- a different username, often a different OS -- and pinned to a version that goes stale at the next
# release. It was the newest skill page and the only one of eleven that did not use the substitution, and
# it was the first command a consumer runs to use the release's headline feature.
#
# WHY THE RULE IS ABOUT COMMANDS AND NOT ABOUT PATHS, which is the obvious shape and was measured first: a
# tree-wide "no absolute paths in plugins/" rule is born with THREE findings and all three are correct
# prose -- comments in check-report-lib and check-roster-sync that quote 'C:\Users\x\.claude\...' precisely
# to explain a path-mangling bug. A check that needs an exemption list on its first run is the shape this
# repo already has scar tissue from, so the subject is the '-File' argument of a runnable command instead.
# Measured over the 26 invocations in the 11 shipped skill pages: 23 use the substitution and 3 use the
# '<plugin>' placeholder, which passes deliberately -- angle brackets tell a reader to substitute, while an
# absolute path reads as a command to paste. Zero exemptions, and it would have caught the defect on the
# day it was written.
$skillCmdChecked = 0
$skillPagesDir = Join-Path $RepoRoot 'plugins'
if (Test-Path -LiteralPath $skillPagesDir -PathType Container) {
    $skillPages = @(Get-ChildItem -Path $skillPagesDir -Recurse -Filter 'SKILL.md' -File)
    foreach ($page in $skillPages) {
        $lines = Get-Content -LiteralPath $page.FullName
        for ($i = 0; $i -lt $lines.Count; $i++) {
            # Only a '-File <path>' argument: that is the one token a reader is told to execute.
            $m = [regex]::Match($lines[$i], '-File\s+"(?<path>[^"]+)"')
            if (-not $m.Success) { continue }
            $skillCmdChecked++
            $p = $m.Groups['path'].Value
            # Absolute = a drive letter, a POSIX root, or a home shortcut. Everything else is either the
            # substitution or a signposted placeholder, and both are honest about needing resolution.
            if ($p -match '^([A-Za-z]:[\\/]|[\\/]|~)') {
                $rel = $page.FullName.Substring($RepoRoot.Length).TrimStart('\', '/')
                Add-Error ("[skill-command] {0}:{1}: the command points at an absolute path ('{2}'), which resolves only on the machine it was written on. Use `${{CLAUDE_PLUGIN_ROOT}}/... so it resolves in the consumer's own plugin install." -f $rel, ($i + 1), $p)
            }
        }
    }
}
Write-Coverage -Category 'skill-command' -Checked $skillCmdChecked `
    -Note "the '-File' argument of every runnable command in the shipped skill pages, held against being machine-specific. The subject is the COMMAND and not the path, chosen by measuring: a tree-wide absolute-path rule is born with three findings, all three correct comments that quote a user path in order to explain a path-mangling bug. A '<plugin>' placeholder passes on purpose -- angle brackets ask the reader to substitute, an absolute path reads as a line to paste"

# --- 23. a plugin's name says which kind it is, and it must sit where that says ---------------------------
# WHAT THIS CHECK IS FOR, RESTATED (August 26, 2026, issue #886) BECAUSE ITS ORIGINAL REASON EXPIRED.
# From August 9, 2026 the prefix was a MECHANISM: the core team's workflow-sessioncheck decided what
# counted as a workflow by asking whether the plugin's name started with 'workflow-', so a workflow
# named otherwise would never be counted and two could be enabled in silence. That hook and the
# exclusivity rule it enforced were RETIRED with workflow-default, so that argument is gone and is not
# quietly left standing here -- a check whose stated reason no longer holds is worse than one with no
# comment, because the next reader trusts it.
#
# THE TEETH THAT SURVIVE, and they are this check's own. The two halves are not independent: the
# DIRECTORY rule is DERIVED FROM THE NAME. A plugin called neither 'team-*' nor 'workflow-*' falls
# through both branches below, so its location is never held against anything -- an unprefixed name
# does not merely read untidily, it switches this check off for that plugin, silently and for as long
# as nobody counts the Checked total against the published set. That is why the else-branch is an
# error and not a style note, and the reason is now internal to the check rather than borrowed from a
# hook in another plugin.
#
# ANCHORED ON THE PUBLISHED SET, so a directory that is not a plugin is not held to a rule about
# plugins. That is what lets plugins/teams/agent-shared/ sit beside the teams it feeds without being
# read as a team whose name is missing its 'team-' prefix -- it is in no marketplace, so this loop
# never sees it. Worth knowing before anyone hardens the directory half into a filesystem sweep:
# 'every directory under plugins/teams/ is named team-*' is a DIFFERENT check from this one, and it
# would be false the moment it was written.

# TWO PREFIXES NAME THE SAME KIND SINCE AUGUST 26, 2026 (#886), AND THAT IS DELIBERATE. The directory
# plugins/workflows/ holds the KIND -- a way of working -- and the prefix names WHOSE it is. The plugin
# in it was renamed 'contributing-davekjohn' -> 'contributing-davekjohn' because that is what it does: it
# serves one owner's contributing rules, not a workflow among several. Dave kept the directory name
# (decision A on that issue), so a 'contributing-*' plugin living under plugins/workflows/ is the
# intended shape rather than a mismatch nobody noticed. 'workflow-*' is still accepted: it is what a
# plugin from anybody else would be called, and refusing it would make this family's rename somebody
# else's problem.
$kindChecked = 0
foreach ($p in $publishedPlugins) {
    $kindChecked++
    $rel = $p.RelativeRoot
    if ($p.Name -like 'team-*') {
        if ($rel -notmatch '^plugins\\teams\\') {
            Add-Error "[plugin-kind] '$($p.Name)' is a team by its name but its source is '$rel' -- a team belongs under plugins/teams/."
        }
    } elseif ($p.Name -like 'workflow-*' -or $p.Name -like 'contributing-*') {
        if ($rel -notmatch '^plugins\\workflows\\') {
            Add-Error "[plugin-kind] '$($p.Name)' is a way of working by its name but its source is '$rel' -- 'workflow-*' and 'contributing-*' both belong under plugins/workflows/."
        }
    } else {
        Add-Error "[plugin-kind] '$($p.Name)' is none of 'team-*', 'workflow-*' or 'contributing-*'. Every plugin here is a team or a way of working, and the name is what says which: the directory rule is DERIVED from the prefix, so a plugin whose name matches none of them has its location held against nothing at all -- this check switches itself off for it."
    }
}
Write-Coverage -Category 'plugin-kind' -Checked $kindChecked `
    -Note $(if ($kindChecked -eq 0) { 'no published plugin was read, so neither the naming rule nor the directory rule could be applied' } else { "every published plugin is a team or a way of working by name, and sits in the directory its name claims -- 'workflow-*' and 'contributing-*' both map to plugins/workflows/, the directory naming the KIND while the prefix names whose it is. The naming half is the one that cannot be seen by reading the tree: the directory rule is derived from the prefix, so an unprefixed plugin is silently held to nothing" })

# --- 24. the PR template keeps the two promises open-pr makes about it ------------------------------------
# WHAT THIS IS FOR, measured at a consumer rather than imagined (#573). open-pr fills the PR body's
# description by comparing each template line, WHOLE AND EXACT, against the recognised placeholders. A
# template one word away from one of them matches nothing, and until August 10, 2026 the run said nothing
# either: that consumer merged TWELVE of sixty PRs with no description at all, found months later by
# diffing their template against this repo's. The warning added that day tells the person running open-pr;
# this check tells the person editing the template, which is one step earlier and one person wider.
#
# TWO SUBJECTS, HELD TO DIFFERENT STRENGTHS ON PURPOSE.
#   * The SHIPPED REFERENCE is held byte for byte to Get-PrTemplateReference. It is not a document anybody
#     edits -- it is the answer this family hands a consumer, and a reference whose placeholder open-pr
#     would walk past is worse than no reference at all, because it arrives looking authoritative. Same
#     reasoning as check 13b for the branch document's reset state and check 21 for the config blueprint.
#   * THIS REPO'S OWN .github/pull_request_template.md is held only to the contract: a placeholder line
#     the matcher recognises. Deliberately weaker, because that file is genuinely repo-owned -- the day it
#     grows a section this repo needs, a byte-for-byte rule would refuse a correct change and the gate
#     would be edited to allow it, which is how a check gets switched off rather than heeded.
#
# THE CONTRACT LOST ITS SECOND HALF ON AUGUST 24, 2026 (issue #865), and the reason is that open-pr stopped
# needing it. It also required A FIRST HEADING, because -RefreshBody replaced the description under the
# template's first heading and a template with none would have degraded to a warning on every run. Since
# #865 that switch reads the PLACEHOLDER's position instead: headings above it are the description's,
# headings below it are the form's boundaries, and where the placeholder comes first the description is the
# body's leading section. So a heading-less template is a supported shape, and this check refusing one
# would now refuse the template this repo actually ships.
#
# A CONSUMER'S TEMPLATE IS NOT CHECKED BY ANYTHING, and that is stated rather than left as a gap: this gate
# runs in this repo. What travels to them is the warning in open-pr and the shipped reference to diff
# against. check-script-contract.ps1 cannot help either -- Get-PrDescriptionPlaceholder is OPTIONAL, so a
# repo that does not define it is correct, exactly the shape recorded for Get-BranchTypes.
$prtChecked = 0
$prtNote = ''
$prtRefRel = 'plugins\workflows\contributing-davekjohn\templates\pull_request_template.md'
$prtRefPath = Join-Path $RepoRoot $prtRefRel
$prtExpected = ((Get-PrTemplateReference) -join "`n").TrimEnd()
if (-not (Test-Path -LiteralPath $prtRefPath)) {
    Add-Error "[pr-template] $prtRefRel is missing. It is the reference body a consumer copies into their own .github/ -- generated from Get-PrTemplateReference in scripts/lib/pr-body-lib.ps1."
} else {
    $prtChecked++
    $prtOnDisk = (([System.IO.File]::ReadAllText($prtRefPath, [System.Text.Encoding]::UTF8)) -replace "`r`n", "`n").TrimEnd()
    if ($prtOnDisk -ne $prtExpected) {
        Add-Error "[pr-template] $prtRefRel no longer matches Get-PrTemplateReference (scripts/lib/pr-body-lib.ps1). It is a copy of that answer, not a second definition of it -- change the function and regenerate, rather than editing the file."
    }
}

$prtOwnRel = '.github\pull_request_template.md'
$prtOwnPath = Join-Path $RepoRoot $prtOwnRel
if (-not (Test-Path -LiteralPath $prtOwnPath)) {
    # Not an error: a repo without a PR template is a repo open-pr simply does not pre-fill a body for,
    # which the script already handles. Only a template that EXISTS makes a promise.
    $prtNote = 'this repo has no .github/pull_request_template.md, so only the shipped reference was judged'
} else {
    $prtChecked++
    $prtOwnLines = @(Get-Content -LiteralPath $prtOwnPath -Encoding UTF8)
    $prtKnown = @(Get-PrDescriptionPlaceholderDefaults)
    if (-not ($prtOwnLines | Where-Object { $prtKnown -contains $_ })) {
        Add-Error ("[pr-template] $prtOwnRel carries no placeholder line open-pr recognises, so every PR opened from it gets NO description. The comparison is whole-line and exact; one of these must appear verbatim:`n    " +
            ($prtKnown -join "`n    ") +
            "`n  Or define Get-PrDescriptionPlaceholder in scripts/repo-config.ps1 to name your own -- and then this check is the one that has to learn about it.")
    }
}
Write-Coverage -Category 'pr-template' -Checked $prtChecked `
    -Note $(if ($prtNote) { $prtNote } else { "the shipped reference held byte for byte to Get-PrTemplateReference, and this repo's own template held to the contract open-pr relies on -- a placeholder line the matcher recognises. Two strengths on purpose: the reference is an answer we hand out, the repo's own template is a file its owner edits" })

# --- 25. the consumer document does not send its reader into a tier written for somebody else -------------
# WHAT THIS IS FOR, and it is measured rather than imagined (August 10, 2026). The tier model gives each
# release document a named reader, and tier 0 -- the changelog notes -- is defined as "only this repo's own
# developers". A link from the consumer document into that tree hands a paying reader the per-PR record and
# calls it theirs. Measured on the day this landed: TWO of eleven consumer documents did exactly that, both
# of them labelling it invitingly -- v4.0.0's "The full recap is in the release notes" and v3.5.0's "Full
# per-change record". Both were removed in the same change, so this check is not born red.
#
# LINKS ONLY, DELIBERATELY. A path mentioned in prose or inline code is check 4's declined territory: this
# repo measured five variants of "a path in backticks must resolve" over 120 documents and the narrowest was
# born with 124 findings, none real, because most paths this product names describe somebody ELSE's repo. A
# markdown LINK escapes that entirely -- it is not a path being discussed, it is a destination being offered,
# and whose repo it is in is no longer ambiguous.
#
# TWO RULES WERE MEASURED ALONGSIDE THIS ONE AND BOTH DECLINED, recorded here because the next person to
# have the idea should not have to re-measure it:
#   * "no significance score in a consumer document" -- 4 findings, ALL FALSE. v3.7.0's release was ABOUT
#     the entry format, so its consumer document correctly quotes '#### Tier 2' and '**Score:** N/A' as
#     illustrations of the shape it is announcing. The generator already strips real scores
#     (-StripSignificance, asserted in release-lib.tests.ps1); what a human adds afterwards is prose.
#   * "no branch name or PR number in a consumer document" -- 3 findings, ALL FALSE, and the same reason:
#     '## `feat/your-branch` changelog' is v3.7.0 showing the reader the new heading.
# Both would have needed an exemption list on the day they landed, which is the shape this repo has already
# been bitten by. The rest of the writing norm therefore travels as PROSE in the cut-release skill, where a
# person applies it, rather than as gates that cannot tell an illustration from a leak.
#
# MORE THAN ONE TREE SINCE AUGUST 10, 2026, and the reason they are all read is that some of them are
# ARCHIVES. The two hand-written documents became one -- the tree Get-ReleaseNoteRoot names, since August 12
# releases/audience/, with a named section per reader -- and the
# rule follows the reader rather than the directory: a consumer reads the whole of that file, organisation
# section included, so a link into the per-PR record is exactly as wrong there as it was before.
#
# THIS REPO'S OWN ARCHIVE IS GONE AND 'releases\consumer' IS STILL READ, which is the point of the list
# rather than an oversight (August 12, 2026). Dave had the twelve releases/consumer/ + releases/internal/
# pairs merged into releases/audience/, so this repo has one hand-written tree and nothing else -- but a
# CONSUMER on the two-document flow still has that directory, and they receive this gate through a plugin
# update rather than by choosing to. Dropping the name would silently stop holding their outward-facing
# documents, with a coverage count that still looked healthy. Reading a root that is not there costs
# nothing: absent roots are filtered out below. Recognise both, write one.
#
# 'releases\internal' is deliberately NOT in the list, and that is not symmetry being broken by accident:
# this check asks whether a document written for a CONSUMER offers them a link into somewhere written for
# somebody else. An internal note's reader IS the organisation, so reading that tree here would accuse a
# correct document of the thing it cannot commit. The merged document is covered because its consumer
# section and its organisational sections share one file, which the reader-not-directory rule already
# handles -- not because both trees are scanned.
$ctrChecked = 0
# THE LIVE ROOT COMES FROM THE SEAM, and that is a repair rather than a flourish (August 12, 2026). This
# check named 'releases\notes' as a literal, so the day Get-ReleaseNoteRoot moved to 'releases/audience' the
# gate would have found no live tree, checked the archive alone, and reported a coverage count that still
# looked healthy -- a gate going quiet with nothing erroring, which is the failure class this repo keeps
# paying for. script-contract-lib.ps1 states the same lesson at this very seam's record, about its
# reader-versus-writer half; a GATE keyed on a hardcoded root is the third reader nobody thought of.
#
# ALL OF THEM ARE READ, NOT JUST THE CURRENT ONE. The seam's value, the pre-rename 'releases\notes' and the
# archive are walked together and deduplicated, so a repo mid-migration -- or one that never renamed -- has
# every document it owns held rather than whichever the seam happens to name today. Reading a root that is
# not there costs nothing: absent roots are filtered out below. Recognise both, write one.
#
# DOT-SOURCED IN A SCRIPTBLOCK, the pattern check 16 above established and for its reason: repo-config is
# not otherwise loaded in this process, and pulling two dozen repo functions into the whole lint to serve
# one check is how a gate acquires a dependency nobody meant to give it. A repo without the file falls
# through to the pre-rename literal, which is exactly what it had before.
$ctrSeamRoot = & {
    $ctrCfg = Join-Path $RepoRoot 'scripts\repo-config.ps1'
    if (Test-Path -LiteralPath $ctrCfg) { . $ctrCfg }
    if (Get-Command Get-ReleaseNoteRoot -ErrorAction SilentlyContinue) { [string](Get-ReleaseNoteRoot) } else { '' }
}
# @() around the pipeline, not decoration: with only one of the trees present -- which is every repo
# until its first cut under this model -- a bare pipeline yields a scalar, and under Set-StrictMode
# reading .Count on it throws. Caught by this gate's own run.
$ctrRoots = @(@($ctrSeamRoot, 'releases\notes', 'releases\consumer') |
    Where-Object { $_ } |
    ForEach-Object { $_ -replace '/', '\' } |
    Select-Object -Unique |
    ForEach-Object { Join-Path $RepoRoot $_ } |
    Where-Object { Test-Path -LiteralPath $_ })
if ($ctrRoots.Count -eq 0) {
    $ctrNote = 'this repo has neither a hand-written release-note tree (Get-ReleaseNoteRoot) nor a releases/consumer/ archive from the two-document flow, so the tier is off here and there is nothing to hold'
} else {
    foreach ($ctrFile in @($ctrRoots | ForEach-Object { Get-ChildItem -LiteralPath $_ -Recurse -Filter *.md -File })) {
        $ctrChecked++
        $ctrRel = $ctrFile.FullName.Substring($RepoRoot.Length).TrimStart('\')
        $ctrLines = @(Get-Content -LiteralPath $ctrFile.FullName -Encoding UTF8)
        for ($i = 0; $i -lt $ctrLines.Count; $i++) {
            # The link TARGET only -- '](...)'. A tier name in the link TEXT is someone writing about the
            # tiers, which is what v3.7.0 legitimately does.
            foreach ($m in [regex]::Matches($ctrLines[$i], '\]\(([^)]+)\)')) {
                $ctrTarget = $m.Groups[1].Value
                # 'changelog' IS LISTED BESIDE 'development', AND BOTH STAY (issue #914, August 26, 2026).
                # The tier-0 directory renamed, and this line is a LITERAL -- the same shape as the
                # hardcoded root the comment above this check describes going quiet. Dropping the old name
                # would un-cover every consumer who has not migrated; keeping only it would have covered
                # nothing here from the day of the rename onward, with the coverage count still reading
                # healthy. Recognise both, write one.
                if ($ctrTarget -match '(^|/)(development|changelog|internal)/') {
                    $ctrTier = if ($Matches[2] -eq 'internal') { 'tier 1, colleagues on this project' } else { 'tier 0, only this repo''s own developers' }
                    Add-Error ("[consumer-tier] $ctrRel line $($i + 1) links into '$($Matches[2])/' ($ctrTier): $ctrTarget`n" +
                        '  This document''s reader is a consumer of the product. Point them at another consumer document, at the docs, or at nothing -- ' +
                        'a link offered to them has to lead somewhere written for them.')
                }
            }
        }
    }
}
Write-Coverage -Category 'consumer-tier' -Checked $ctrChecked `
    -Note $(if ($ctrChecked -eq 0) { $ctrNote } else { "every document in the hand-written note tree Get-ReleaseNoteRoot names -- releases/audience/ here, one document with a named section per reader, and since August 12, 2026 the only such tree in this repo: the twelve releases/consumer/ + releases/internal/ pairs were merged into it -- plus the pre-rename releases/notes/ and a releases/consumer/ archive, both still read for a consumer who has one, held against offering its reader a link into the tier-0 tree (changelog/ since #914, development/ before it -- both recognised, so a consumer mid-migration stays covered) or the internal (tier 1) one. The rule follows the READER, not the directory: a consumer reads the organisation section too. LINK TARGETS only -- a tier named in link text or prose is someone writing ABOUT the model, which is check 4's declined-path territory. Two neighbouring rules (a score, a branch name) were measured on this same tree and declined at 4 and 3 findings, all false; the reasoning is above the check" })

# --- 26. no frontmatter-bearing shipped document carries a byte-order mark --------------------------------
# READ AS BYTES, AND THAT IS THE WHOLE POINT. Every other reader in this gate goes through
# [System.IO.File]::ReadAllText(..., UTF8), which DETECTS AND STRIPS a BOM before any regex sees it -- so a
# BOM is invisible to all twenty-five checks above, to the canonical-skillset reader that takes each skill's
# name from '(?m)^name:', and to every editor a reviewer would open the file in. It is the one defect
# findable by neither reading nor this gate, and the first three bytes are the only vantage point from which
# it exists at all.
#
# A REPAIR, NOT A PRECAUTION. plugins/workflows/contributing-davekjohn/skills/adopt-config/SKILL.md shipped with
# EF BB BF in 4.1.0 -- the only one of the eleven skills across the two shipped plugins to carry it, and the
# only model-invocable one absent from the agent's skill listing. A frontmatter parser that wants '---' at
# offset 0 sees a BOM in front of it and reads the file as having no frontmatter, so the skill has no name
# and never registers. Nothing errors; the page is simply not there. It bites the consumer who can least
# afford it -- a fresh one, whose seam adopt-config exists to fill, and who cannot tell a skill that failed
# to load from one deliberately hidden behind disable-model-invocation. Reported as #581 from
# BWJ-ecommerce/smartwatchbanden, who found it by diffing first bytes because reading cannot.
# (Described in words rather than quoted: a literal BOM in the sentence explaining the bug is invisible here
# too, which is how one got into this very comment on the first draft.)
#
# THE SET IS EVERY FRONTMATTER-BEARING SHIPPED DOCUMENT, not only SKILL.md -- an agent def, manual or
# persona whose frontmatter the harness parses for 'name:'/'id:'/'group:' breaks identically and just as
# quietly, and checks 3/3b/3c already enumerate three of the four sets. Measured before widening rather than
# assumed: 69 documents (26 agent defs, 26 manuals, 4 personas, 13 registered skill pages), all four sets
# non-empty, ZERO findings once the one BOM was stripped, zero exemptions. A check needing an exemption list
# on its first run is the shape this repo has scar tissue from; this one is born green, and reintroducing
# the byte was used to prove it fires rather than merely passes.
#
# THE SUBJECT IS THE BOM AND NOT "MUST HAVE FRONTMATTER", and that narrowing was forced by measurement. The
# first draft also reported a file not opening with '---' at all, which reads as the same defect and is not:
# this repo DELIBERATELY tolerates a skill page without the line -- the canonical reader above falls back to
# the folder name precisely "so a future skill without that line does not silently drop out". Demanding the
# block would be this gate inventing a policy the repo declined, and it showed up at once, because the lint
# suite's own minimal fixtures for checks 18 and 22 are frontmatter-less on purpose: the rule was born with
# two findings, both false, and quieting them meant shifting the line numbers check 22 asserts on.
#
# A BOM needs no such policy -- it is never intentional in any of these files and always breaks a positional
# parse where frontmatter is present. A stray blank line above the block is a real but UNMEASURED cousin:
# named here and deliberately not guarded, per the standing rule that a risk which has not bitten gets
# written down rather than built against.
$bomChecked = 0
$fmDocs = New-Object System.Collections.Generic.List[string]
foreach ($d in (@($agentDefs) + @($manuals) + @($personas))) { $fmDocs.Add($d.FullName) }
$fmSkillDir = Join-Path $RepoRoot 'plugins'
if (Test-Path -LiteralPath $fmSkillDir -PathType Container) {
    # EXACTLY ONE skill-name folder between 'skills' and the file, the same narrowing the canonical
    # skillset above applies. A top-level SKILL.md is what the harness REGISTERS, so a BOM in front of its
    # frontmatter costs the whole skill; a deeper skills/<name>/references/SKILL.md is a
    # progressive-disclosure page that nothing registers, so there is no positional parse for a BOM to
    # break. Check 22 globs broadly on purpose -- a runnable command is machine-specific wherever it sits
    # -- while this check's subject is registration, which only the top level has.
    foreach ($p in @(Get-ChildItem -Path $fmSkillDir -Recurse -Filter 'SKILL.md' -File |
                     Where-Object { $_.FullName -match '\\skills\\[^\\]+\\SKILL\.md$' })) { $fmDocs.Add($p.FullName) }
}
foreach ($fmPath in $fmDocs) {
    $bomChecked++
    $rel = $fmPath.Replace($RepoRoot, '.')
    $head = New-Object byte[] 3
    $readCount = 0
    $fs = [System.IO.File]::OpenRead($fmPath)
    try { $readCount = $fs.Read($head, 0, 3) } finally { $fs.Dispose() }
    if ($readCount -ge 3 -and $head[0] -eq 0xEF -and $head[1] -eq 0xBB -and $head[2] -eq 0xBF) {
        Add-Error ("[frontmatter-bom] $rel begins with a UTF-8 byte-order mark (EF BB BF) before its '---'." +
            " A frontmatter parser that requires '---' at offset 0 reads the file as having no frontmatter, so the" +
            " document registers under no name and fails with no error anywhere. The BOM is invisible in every editor" +
            " and to ReadAllText, so no reviewer and no other check here can see it. Strip the three bytes and save" +
            " the file as UTF-8 WITHOUT a BOM.")
    }
}
Write-Coverage -Category 'frontmatter-bom' -Checked $bomChecked `
    -Note "the first three bytes of every frontmatter-bearing shipped document (agent defs, manuals, personas, and the skill pages a plugin REGISTERS), held against a UTF-8 byte-order mark. Read as bytes because ReadAllText strips a BOM before any other check here can see it -- which is how adopt-config/SKILL.md shipped one in 4.1.0 and silently failed to register (#581). The subject is the BOM and not the presence of frontmatter: this repo deliberately tolerates a skill page without a 'name:' line. Measured at introduction: 69 documents across all four sets, 0 findings once that one BOM was stripped, 0 exemptions"

# --- 27. the script layer is pure ASCII ------------------------------------------------------------------
# THE RULE ALREADY EXISTED AND NOTHING ENFORCED IT. .claude/rules/language-layers.md has said "the script
# layer is ASCII, and a character the script must EMIT is written as a code point" since August 19, 2026,
# and every .ps1 in this tree closes its own docstring with "Pure ASCII (repo convention for .ps1)". A
# convention held up by whoever remembers it is the shape this repo keeps paying for; this is the check.
#
# THE MEASURED DAMAGE, and it is not a style complaint. Windows PowerShell 5.1 reads a BOM-less .ps1 as
# the SYSTEM ANSI CODE PAGE, so the two UTF-8 bytes of a middot (U+00B7) are decoded as two CP1252
# characters -- and nothing errors, because a mis-decoded string is still a string. On August 19, 2026 a
# middot typed literally into scripts/lib/entry-scaffold-lib.ps1 came out of EVERY generated changelog
# template as two wrong characters, and it reached the author's entry before anyone saw it. The repair is
# the code point ([char]0x00B7), not a BOM: the shared libs are held byte-identical to their plugin
# mirrors by check 8, so an encoding change would have to land in both, while an escape keeps the file
# out of the question entirely.
#
# WHY THIS AND NOT THE MOJIBAKE CHECK ABOVE. Check 14 hunts damage that has ALREADY happened, and its set
# (Get-MojibakePaths) is markdown -- so it sees the mangled character one layer downstream, in the
# generated document, after it has been copied into somebody's entry. This check sees the literal upstream,
# in the source that will emit it, which is the only place a repair is cheap.
#
# THE SUBJECT IS THE CHARACTER, NOT THE ENCODING. A BOM is deliberately NOT a finding here: on a .ps1 it
# is the one thing that makes 5.1 read the file correctly, so flagging it would push authors toward the
# defect. ReadAllText strips it before the scan for that reason, and check 26 owns the documents where a
# BOM does break something. Invalid UTF-8 is caught anyway -- it decodes to U+FFFD, which is non-ASCII.
#
# BORN GREEN, MEASURED BEFORE IT WAS WRITTEN: 158 tracked .ps1 files, all of them inside this set once
# the plugin hooks were added to it, and exactly two carrying a non-ASCII character --
# scripts/lib/pr-issues-lib.ps1 and its plugin mirror, two lines each, a deliberate en/em dash inside a
# regex character class. Both were repaired on this branch (composed from [char] code points) rather than
# exempted, and no exemption list exists. A check needing one on its first run is the shape this repo has
# scar tissue from; check 26 was born green on the same reasoning.
$asciiScripts = @(Get-PsScriptFiles)
$nonAscii = [regex]'[^\x00-\x7F]'
foreach ($sf in $asciiScripts) {
    $srcText = [System.IO.File]::ReadAllText($sf.FullName, [System.Text.Encoding]::UTF8)
    $first = $nonAscii.Match($srcText)
    if (-not $first.Success) { continue }
    $rel = $sf.FullName.Replace($RepoRoot, '.')
    # The line number is counted only for a file that already failed, so the scan itself stays a single
    # .NET regex pass over the text instead of a per-byte loop in PowerShell. That matters because this
    # runs over every .ps1 in the tree on every PR, and once more per scenario inside this gate's own
    # fixture suites -- which is where a hundred-odd extra passes over a few megabytes would show up.
    $lineNo = ($srcText.Substring(0, $first.Index) -split "`n").Count
    $total = $nonAscii.Matches($srcText).Count
    $cp = '0x{0:X4}' -f [int][char]$first.Value
    Add-Error ("[script-ascii] $rel`:$lineNo carries a non-ASCII character (U+$($cp.Substring(2)))" +
        "$(if ($total -gt 1) { ", $total in the file" }). Windows PowerShell 5.1 reads a BOM-less .ps1 as the" +
        " system ANSI code page, so this character decodes as two CP1252 characters -- silently, because a" +
        " mis-decoded string is still a string. Write it as a code point instead ([char]$cp), which is what" +
        " .claude/rules/language-layers.md requires of the script layer. Do NOT add a BOM: the shared libs" +
        " are held byte-identical to their plugin mirrors, so the encoding would have to change in both.")
}
Write-Coverage -Category 'script-ascii' -Checked $asciiScripts.Count `
    -Note $(if ($asciiScripts.Count -eq 0) {
        'no .ps1 found under scripts/ or in any plugin -- a literal non-ASCII character anywhere in the script layer could not have been seen'
    } else {
        "every .ps1 check 5 parses, held to the ASCII rule .claude/rules/language-layers.md states for the script layer. A literal non-ASCII character in a BOM-less .ps1 is decoded by Windows PowerShell 5.1 as two CP1252 characters, silently, and reaches whatever the script EMITS -- measured on a middot in entry-scaffold-lib.ps1 that came out wrong in every generated changelog template (August 19, 2026). A BOM is deliberately not a finding: on a .ps1 it is the fix, not the defect, and check 26 owns the files where one breaks something. Born green: 2 findings at introduction across all 158 tracked .ps1 files, both repaired rather than exempted, 0 exemptions"
    })

# --- 28. every '@'-import target resolves -----------------------------------------------------------------
# THE CLASS CHECK 4 CANNOT SEE. The [link] check above validates '[text](target)' and nothing else, so an
# '@'-import -- a different syntax entirely -- matches none of it. Reported as issue #874.
#
# WHY IT IS NOT JUST ANOTHER DEAD LINK. A dead markdown link costs a reader one click. A dead '@'-import
# costs the SESSION THE WHOLE DOCUMENT, silently: Claude Code drops an import it cannot resolve, nothing
# errors, and the instructions simply are not there. The failure is asymmetric in the worst direction,
# because the always-on path of this repo is assembled entirely out of imports and the layer that would
# vanish is the one carrying the safety rules or the roster. The only symptom is a session behaving as
# if it had never read them.
#
# THE THREE RESOLUTION RULES ARE NOT RESTATED HERE. measure-context-lib.ps1 already implements and
# documents them ('~/' -> user home, rooted -> as given, otherwise -> relative to the IMPORTING FILE's
# own directory, which is not the repo root), and its suite pins them. This check reuses that parser,
# so the gate and the measurement script cannot drift on what an import means. The issue proposed
# restating the rules; reusing them is the same repair with one definition instead of two.
#
# TWO DISCRIMINATORS, BOTH MEASURED BEFORE THIS WAS WRITTEN. A '^@' sweep of every markdown file in the
# tree returns 12 lines and only 3 are imports:
#   - 7 are PowerShell '@(...)' expressions inside fenced blocks. Fences are tracked, exactly as check 4
#     argues for links: illustrating a thing is not doing it.
#   - 1 is PROSE -- contributing-davekjohn/releases/changelog/1.x/1.16.0.md, a paragraph that happens to wrap onto
#     '@-imported here (this maintenance repo ...)'. Get-ImportLinePath takes the rest of the line as the
#     path, which is right for the always-on walk (it never meets prose) and wrong for a scan set that
#     includes archived release notes. A target containing WHITESPACE is therefore not an import here.
#     That is a discriminator rather than an exemption list, deliberately: a check born needing one is
#     the shape this repo has scar tissue from (see check 27).
#
# AN IMPORT OUTSIDE THE REPO IS COUNTED, NOT REFUSED. SPECIALISTS.md imports the orchestrator's persona
# from the plugin MARKETPLACE CLONE under '~/', which legitimately does not exist on a machine without
# that plugin installed. CI is such a machine, so erroring there would fail every PR for a correct file.
# The coverage line names how many were seen instead.
#
# WHAT IS DELIBERATELY NOT BUILT, because it has not bitten. The mirror image of the prose rule: a
# wrapped paragraph beginning '@' at column 0 INSIDE an always-on document would be read by Claude Code
# as an import, and the document after it lost. No instance exists -- the only prose line in the tree
# sits in an archived release note nothing loads -- and .claude/rules/language-layers.md's standing rule
# is that a risk which has not bitten is written down rather than built against. This comment is that
# writing-down.
#
# BORN GREEN: 3 imports on the always-on path, all three resolving, 0 findings at introduction.
$importScanFiles = @($linkFiles)
$importAnyLine = [regex]'(?m)^@'
$importResolved = 0
$importExternal = 0
$importNotAPath = 0
foreach ($lf in $importScanFiles) {
    $importText = [System.IO.File]::ReadAllText($lf, [System.Text.Encoding]::UTF8)
    # One regex pass per file decides whether the line walk is worth doing. Every other file in the scan
    # set -- the overwhelming majority -- costs exactly that pass, which matters because this set is a few
    # hundred documents and the gate runs on every PR and again inside its own fixture suites.
    if (-not $importAnyLine.IsMatch($importText)) { continue }
    $importRel = $lf.Replace($RepoRoot, '.')
    $importInFence = $false
    $importLineNo = 0
    foreach ($importLine in [regex]::Split($importText, '\r?\n')) {
        $importLineNo++
        if (Test-IsFenceLine $importLine) { $importInFence = -not $importInFence; continue }
        if ($importInFence) { continue }
        $importTarget = Get-ImportLinePath -Line $importLine
        if (-not $importTarget) { continue }
        if ($importTarget -match '\s') { $importNotAPath++; continue }
        # A target that cannot even be turned into a path is not one. Resolve-ImportPath goes through
        # System.IO.Path, which throws on characters no filesystem accepts -- and a line carrying those
        # is prose the whitespace rule happened not to catch, not an import somebody meant.
        $importPath = $null
        try { $importPath = Resolve-ImportPath -Target $importTarget -ImportingFile $lf } catch { $importPath = $null }
        if (-not $importPath) { $importNotAPath++; continue }
        if (-not $importPath.StartsWith($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $importExternal++
            continue
        }
        if (-not (Test-Path -LiteralPath $importPath -PathType Leaf)) {
            Add-Error ("[import] ${importRel}:${importLineNo} -> dead '@'-import '$importTarget'" +
                " (expected file does not exist). An import resolves relative to the IMPORTING FILE's own" +
                " directory unless it starts with '~/' or is rooted -- so from" +
                " '$((Split-Path -Parent $lf).Replace($RepoRoot, '.'))', not from the repo root. Claude Code" +
                " drops an import it cannot resolve WITHOUT ERRORING, so this costs the session the whole" +
                " document rather than one link.")
            continue
        }
        $importResolved++
    }
}
Write-Coverage -Category 'import' -Checked $importScanFiles.Count `
    -Note $(if ($importScanFiles.Count -eq 0) {
        'the scan set is empty -- no dead @-import anywhere could be found, which is not the same as there being none'
    } else {
        "every file check 4 reads for links, read again for column-0 '@'-imports and resolved through measure-context-lib's own parser. Found $importResolved resolving in-tree import(s) and $importExternal outside the repo (not a finding: a '~/'-relative import points into the plugin marketplace clone, which CI does not have). $importNotAPath line(s) began with '@' and were read as prose rather than as a path. Fenced blocks are excluded, as in check 4. A dead import is not a dead link: Claude Code drops it silently and the session loses the WHOLE document"
    })

# --- 29. a plugin's OWN skill enumeration, scoped to that plugin and read from its links ------------------
# THE HALF CHECK 10 CANNOT HOLD, split out of #873 and measured in #920. Check 10 exists for a document
# that claims to list EVERY skill in the marketplace, and both of its defining properties make it the
# wrong instrument for a document that claims to list every skill of ONE plugin:
#
#   * its canonical set is repo-wide -- built from Get-PluginSubdirs over every published plugin -- so a
#     span in plugins/workflows/contributing-davekjohn/README.md, which enumerates the 16 that plugin
#     ships, would report the team plugins' skills as 'missing';
#   * every backtick-quoted token inside its span is a claimed name, which is why its own author
#     condition is 'wrap tightly'. That table is two columns and three of its rows carry a backticked
#     path or flag in the SECOND one -- so the span could not close around only the names without
#     making the prose worse in order to satisfy a checker.
#
# So this is a second, separately opt-in sentinel rather than a relaxation of check 10. It differs in
# exactly those two respects and in nothing else: same fence masking, same unpaired-marker errors, same
# symmetric END sweep, same silent pass on zero spans.
#
#   1. SCOPE. The plugin is resolved from the FILE'S OWN PATH, through Get-PluginNameForPath -- the same
#      function the fold uses to decide which plugins a PR touched. A span in a file under no plugin root
#      is a hard error rather than a silent skip: the marker's whole meaning is 'this plugin', and a file
#      that belongs to none has made a claim nothing can adjudicate.
#   2. THE CLAIM IS THE LINK, NOT THE BACKTICKS. Every markdown link inside the span whose target
#      resolves to <this plugin>/skills/<one>/SKILL.md is one claimed skill; everything else inside the
#      span -- prose, backticked paths, flags, links elsewhere -- is ignored. That is what lets a
#      two-column table with running prose in the second column be marked without rewriting it, and it
#      needs no author condition at all. Resolution is relative to the document's own directory, exactly
#      as check 4 resolves a relative link.
#
# EXACTLY ONE segment between 'skills' and 'SKILL.md', mirroring check 10's canonical walk: a level-3
# progressive-disclosure page at skills/<name>/references/SKILL.md is not a top-level skill and is not
# read as a claim.
#
# THE COMPARISON IS ON FOLDER NAMES, where check 10 compares frontmatter 'name:' values. A link target
# can only ever name a DIRECTORY, so the directory is the only thing this span is able to claim. Should
# a skill's folder ever diverge from its frontmatter name, that divergence is check 3's domain, not
# this one's, and this check keeps answering the question it can actually answer: does the table link
# to every skill directory this plugin ships, and to nothing else.
#
# WHY IT MUST STAY OPT-IN, measured across all four plugins before it was proposed (#920): a generic
# rule -- 'a plugin README lists every skill it ships' -- would be born needing an exemption list.
# contributing-davekjohn ships 16 and lists 16; team-alpha ships 4 and lists 0; team-shopify ships 4
# and lists 0; team-ecomm ships 0. So a non-opt-in version produces 8 findings on two documents that
# never claimed to enumerate anything, which is the shape this repo has scar tissue from (check 10's
# own prose scan rejected at 147 hits, the stale-path check declined at 124, check 27's exemption
# argument). An explicit sentinel fires on exactly the one table that means it.
#
# THE RECURRENCE THIS CLOSES: that table's correctness was guarded only by 'count when you add one',
# which has failed three times -- nine/twelve, thirteen/fourteen, fourteen/sixteen.
#
# BORN GREEN: 1 span, 16 claimed, 16 canonical, 0 findings at introduction.
$pluginSkillBeginRegex = [regex]'<!--\s*skills:plugin\s*-->'
$pluginSkillEndRegex = [regex]'<!--\s*/skills:plugin\s*-->'
$pluginSkillLinkRegex = [regex]'\]\(([^)\s]+)\)'
$pluginSkillSpanCount = 0
$pluginSkillClaimTotal = 0
# Cached per plugin: the walk below is cheap, but a document could carry several spans and there is no
# reason to re-read a plugin's skills/ tree for each one.
$pluginSkillCanonicalCache = @{}
foreach ($lf in $linkFiles) {
    $content = [System.IO.File]::ReadAllText($lf, [System.Text.Encoding]::UTF8)
    # The cheap test first, on the RAW text, exactly as check 28 does for '@': masking is a split and a
    # regex-replace per line, and the overwhelming majority of this few-hundred-document set carries no
    # marker at all. A raw match is a superset of a masked one -- masking only ever removes markers, it
    # never creates one -- so skipping here can never skip a file the masked scan would have found.
    if (-not $pluginSkillBeginRegex.IsMatch($content) -and -not $pluginSkillEndRegex.IsMatch($content)) { continue }
    $maskedContent = Get-FenceMaskedText -Text $content
    $rel = $lf.Replace($RepoRoot, '.')
    $ownerName = Get-PluginNameForPath -PluginRoots $publishedPlugins -Path $lf.Substring($RepoRoot.Length)
    $ownerRoot = $null
    if ($ownerName) { $ownerRoot = Get-PluginRootByName -PluginRoots $publishedPlugins -Name $ownerName }
    $consumedEndIndices = New-Object System.Collections.Generic.HashSet[int]
    # Every BEGIN the walk actually VISITS -- whether it opened a span or was reported unpaired. The
    # sweep after the loop uses it to find the mirror image of the duplicate-END case: a SECOND BEGIN
    # pasted INSIDE an already-open span is never visited at all, because the walk jumps from a span's
    # opener straight past its END. Check 10 reports the duplicate END and is silent on this one; the
    # asymmetry was found on this branch, by writing the marker in prose above a real span -- the two
    # markers then paired across the whole table and the run came out GREEN, for the wrong reason.
    $visitedBeginIndices = New-Object System.Collections.Generic.HashSet[int]
    $searchStart = 0
    while ($searchStart -le $maskedContent.Length) {
        $beginMatch = $pluginSkillBeginRegex.Match($maskedContent, $searchStart)
        if (-not $beginMatch.Success) { break }
        [void]$visitedBeginIndices.Add($beginMatch.Index)
        $beginLineNo = 1 + [regex]::Matches($maskedContent.Substring(0, $beginMatch.Index), "`n").Count
        $spanStart = $beginMatch.Index + $beginMatch.Length
        $endMatch = $pluginSkillEndRegex.Match($maskedContent, $spanStart)
        if (-not $endMatch.Success) {
            Add-Error "[skill-list-plugin] ${rel}: '<!-- skills:plugin -->' at line $beginLineNo has no matching '<!-- /skills:plugin -->'."
            $searchStart = $spanStart
            continue
        }
        [void]$consumedEndIndices.Add($endMatch.Index)
        $searchStart = $endMatch.Index + $endMatch.Length
        if (-not $ownerRoot) {
            Add-Error ("[skill-list-plugin] ${rel}: <!-- skills:plugin --> span at line $beginLineNo sits in a file that" +
                " belongs to no published plugin, so there is no plugin whose skills it could be held against." +
                " This marker is plugin-scoped by definition -- for a marketplace-wide enumeration use" +
                " <!-- skills:all --> (check 10) instead.")
            continue
        }
        if (-not $pluginSkillCanonicalCache.ContainsKey($ownerName)) {
            $ownerSkillDirs = New-Object System.Collections.Generic.HashSet[string]
            $ownerSkillsRoot = Join-Path $ownerRoot.Root 'skills'
            if (Test-Path -LiteralPath $ownerSkillsRoot -PathType Container) {
                Get-ChildItem -Path $ownerSkillsRoot -Recurse -Filter 'SKILL.md' -File |
                    Where-Object { $_.FullName -match '\\skills\\[^\\]+\\SKILL\.md$' } | ForEach-Object {
                        [void]$ownerSkillDirs.Add((Split-Path (Split-Path $_.FullName -Parent) -Leaf))
                    }
            }
            $pluginSkillCanonicalCache[$ownerName] = $ownerSkillDirs
        }
        $ownerCanonical = $pluginSkillCanonicalCache[$ownerName]
        # The claim set. Read from the RAW text at the same offsets, not from the mask -- the mask only
        # ever blanks fenced blocks, and a span never legitimately contains one, so the two agree here;
        # reading the raw text keeps the target byte-exact regardless.
        $spanText = $content.Substring($spanStart, $endMatch.Index - $spanStart)
        $spanDir = Split-Path -Parent $lf
        $ownerSkillsPrefix = (Join-Path $ownerRoot.Root 'skills').TrimEnd('\') + '\'
        $claimed = New-Object System.Collections.Generic.HashSet[string]
        foreach ($m in $pluginSkillLinkRegex.Matches($spanText)) {
            $target = $m.Groups[1].Value
            if ($target -match '^(https?:|mailto:|#)') { continue }
            $target = ($target -split '#')[0]
            if (-not $target) { continue }
            $resolved = $null
            try { $resolved = [System.IO.Path]::GetFullPath((Join-Path $spanDir ($target -replace '/', '\'))) } catch { $resolved = $null }
            if (-not $resolved) { continue }
            if (-not $resolved.StartsWith($ownerSkillsPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
            if ($resolved -notmatch '\\skills\\[^\\]+\\SKILL\.md$') { continue }
            [void]$claimed.Add((Split-Path (Split-Path $resolved -Parent) -Leaf))
        }
        $missing = @($ownerCanonical | Where-Object { -not $claimed.Contains($_) } | Sort-Object)
        $extra = @($claimed | Where-Object { -not $ownerCanonical.Contains($_) } | Sort-Object)
        if ($missing.Count -gt 0) {
            Add-Error ("[skill-list-plugin] ${rel}: <!-- skills:plugin --> span at line $beginLineNo claims to enumerate" +
                " every skill of plugin '$ownerName' but links to none for: $($missing -join ', ').")
        }
        if ($extra.Count -gt 0) {
            Add-Error ("[skill-list-plugin] ${rel}: <!-- skills:plugin --> span at line $beginLineNo links into" +
                " '$ownerName'/skills/ for name(s) that ship no SKILL.md there: $($extra -join ', ').")
        }
        $pluginSkillSpanCount++
        $pluginSkillClaimTotal += $claimed.Count
    }
    foreach ($m in $pluginSkillEndRegex.Matches($maskedContent)) {
        if ($consumedEndIndices.Contains($m.Index)) { continue }
        $endLineNo = 1 + [regex]::Matches($maskedContent.Substring(0, $m.Index), "`n").Count
        Add-Error "[skill-list-plugin] ${rel}: '<!-- /skills:plugin -->' at line $endLineNo has no matching '<!-- skills:plugin -->'."
    }
    foreach ($m in $pluginSkillBeginRegex.Matches($maskedContent)) {
        if ($visitedBeginIndices.Contains($m.Index)) { continue }
        $beginLineNo = 1 + [regex]::Matches($maskedContent.Substring(0, $m.Index), "`n").Count
        Add-Error ("[skill-list-plugin] ${rel}: '<!-- skills:plugin -->' at line $beginLineNo sits INSIDE an" +
            " already-open span, so it is not the opener of anything -- the span that swallowed it closes at" +
            " the next '<!-- /skills:plugin -->' and its contents were checked as one. Usually this means the" +
            " marker was written in prose above a real span; show it in a fenced block instead.")
    }
}
Write-Coverage -Category 'skill-list-plugin' -Checked $pluginSkillSpanCount `
    -Note $(if ($pluginSkillSpanCount -eq 0) {
        "no <!-- skills:plugin --> span anywhere in the set check 4 reads. The marker is opt-in, so zero is a pass and not a gap -- but nothing about any plugin's own skill table is being asserted by this run"
    } else {
        "opt-in <!-- skills:plugin --> span(s), each held against the skills/ of the plugin the DOCUMENT ITSELF sits in (resolved via Get-PluginNameForPath, not named in the marker), with $pluginSkillClaimTotal claim(s) read from LINK TARGETS rather than from backticks -- so prose and backticked paths elsewhere in the row cost nothing. Check 10 is the marketplace-wide sibling and cannot serve this: its canonical set spans every plugin"
    })

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
