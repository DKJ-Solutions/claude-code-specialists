<#
Folds one or more changelog entry files (<branch-name>.md in the repo root) into a section of
CHANGELOG.md, and then removes the entry files.

WHICH section is decided by the entry's TIER, and the sections themselves are repo-owned:
repo-config.ps1's Get-ChangelogTierHeadings maps tier -> the literal heading line ('## Tier 2 - Pull
Requests' and its two siblings in this workshop). An entry declares its tier with a 'Tier: N' line;
this script reads it, files the entry under the matching section, and REMOVES the line -- from then on
the section states the tier, so the fact lives in exactly one place.

An entry with no 'Tier:' line is tier 0, the harmless end of the scale: forgetting to classify can
never promote work into a consumer-facing document, it can only leave that work unreleasable on its
own -- which the cut says out loud.

WHERE IN that section is decided by the entry's SIGNIFICANCE SCORE (issue #467), and this is the only
moment it can be: the cut EMPTIES the tier sections, and the release documents read what is left in
document order without sorting it. So the order this script leaves behind is the order the notes and the
highlights inherit -- which is what makes it reproducible across two moments days apart with nothing
re-estimated in between. Highest score at the top; an equal score keeps the newer entry above its
equals, which is exactly what the fold did before ranking existed. INSERT-ONLY, NEVER A RE-SORT,
deliberately: this commit lands directly on main, so a bug must be able to misplace at most the one
entry being folded rather than scramble a section it did not write.

Both facts come from the entry's IMPACT TABLE -- one row per tier, the row's second column its
significance. The highest row is the reach; that row's score is the position. An entry with no table falls
back to the older 'Tier: N' line and folds unranked, which is correct rather than tolerated: every entry
written before this format has no score to rank by.

The table is CARRIED INTO the changelog whenever any row is scored, unlike the 'Tier:' line, which is
always consumed. The cut EMPTIES these sections, so a score consumed here would not exist when the release
documents are built days later. An UNSCORED table (a tier-0 entry's scaffold row) is stripped, because a
question nobody was asked does not belong in the record. A missing score is reported and folded anyway:
refusing the fold of an already-merged branch is the silent half-state this repo has measured, and
cut-release.ps1 is the refusal point instead. A malformed table DOES stop the run -- it decides which
section the entry lands in, and getting that wrong is a section-move on main.

Both seams are read, newest first (Get-ChangelogTierSections in entry-scaffold-lib.ps1): the legacy
single-section Get-ChangelogHeading (issue #178) still answers where a repo has not declared tiers, and
neither function is required -- without both, this falls back to one '## Pull Requests' section, which
is what it always did. A repo with one section is simply a repo with one tier, so there is no separate
code path for it.

In fold-all mode (no -Branch) only files that are actually changelog entries are folded: an entry
opens with the '### <title> <midDot> <type>' H3 heading, so repo-root meta docs
(CONTRIBUTING.md, SECURITY.md, ...) that open with an H1 are left untouched. -Branch mode targets
exactly the named entry and is unaffected.

The entry file is already compact (heading `### title - type` with middot separation, followed by the
description) -- matching the CHANGELOG format. What the fold adds is exactly what does not exist until
the merge: '#NN - ' at the front of the title, and as the last line
`[PR #NN](url) - merged <date>`. The PR number, url and merge timestamp are fetched via one
`gh pr list` (on -Branch, or in fold-all mode derived from the file name) -- which can only happen
after opening the PR. If no PR is found (e.g. a manual merge without a PR), none of the three is
added: the heading stays without #NN and there is no closing line.

THE DATE MOVED HERE FROM THE SCAFFOLD ON AUGUST 5, 2026 (Dave), and both halves of that were
deliberate. It is the FOLD's to write, because new-changelog-entry.ps1 runs when the branch is created
and could only ever record the branch's birth date -- wrong by however many days the branch lived, in
the one document whose subject is when things landed. And it goes at the BOTTOM, because the heading
carries what the author knows (title, type) while this line carries what only the merge knows.

Nothing here parses that date back out, and neither does anything downstream: release-lib reads the
TYPE off the heading by matching the known branch types rather than by counting fields from the end,
so a heading with or without a trailing date is read the same way. That was a required part of this
change -- the old parse took the second-to-last field, which would have silently made every entry's
type 'Other' the moment the date left.

Usage:
  .\scripts\release\fold-changelog-entry.ps1 -Branch feat/new-plugin
  .\scripts\release\fold-changelog-entry.ps1              # folds all present entry files
  .\scripts\release\fold-changelog-entry.ps1 -RepoRoot C:\path\to\worktree   # explicit root (#101)
  .\scripts\release\fold-changelog-entry.ps1 -Branch feat/x -Push            # fold, commit and push

Run this on main, right after merging a branch.

COMMITTING IS OPT-IN (-Commit, or -Push which implies it). Without either, the fold is left on disk for
you to commit -- the behaviour this script always had. With them it makes the commit itself, naming
CHANGELOG.md and the entry files as the commit's pathspec so nothing else can be swept in: this commit
lands directly on the main branch under one of the two named exceptions to "never commit directly", and
an exception only stays safe while it stays the size it was granted at.
#>

param(
    [string]$Branch,
    # #101: explicit override of the repo root, for a consumer that runs the fold from a
    # temporary/detached worktree (e.g. a ship-pr.ps1 that checks out main elsewhere) and wants to
    # write to that tree instead of whatever CLAUDE_PROJECT_DIR/git-root would resolve to. Default
    # (omitted): unchanged behavior below.
    [string]$RepoRoot,
    # Commit the fold. OFF BY DEFAULT, deliberately: this commit lands directly on the main branch,
    # which is one of the two named exceptions to "never commit directly" -- so it has to be asked for,
    # exactly like teardown.ps1 requires -Apply before it removes anything.
    #
    # The scope limit the exception grants is enforced by git rather than by care: the commit names its
    # paths, so CHANGELOG.md and the entry files this run folded are the only things that can end up in
    # it, whatever else is lying around in the tree or already staged.
    [switch]$Commit,
    # Push the fold commit. Implies -Commit. Separate because a fold commit sitting unpushed on main is
    # its own silent half-state -- the repo looks folded locally and unfolded to everyone else -- and
    # that is precisely the class of half-finished state this repo keeps finding the expensive way.
    [switch]$Push
)

$ErrorActionPreference = "Stop"

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
# -RepoRoot (#101), when supplied, wins over both -- see the param comment above. Note: PowerShell
# variable names are case-insensitive, so $RepoRoot (the param) and $repoRoot (used below) are the
# same variable; the guard below only computes the dual-context fallback when it is still empty.
if (-not $repoRoot) {
    $repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }
}
Set-Location $repoRoot

# Pre-flight (#86): fold relies on scripts\repo-config.ps1 in the consumer's repo root. If that is
# missing -- typically on a clean consumer -- stop with a clear pointer instead of a raw
# dot-source error on the . (dot-source) line below.
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "fold-changelog cannot run -- missing repo-owned file: $configPath (Get-RepoName / Get-RepoBlobUrl / Get-LintScript). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward."
    exit 1
}

# Repo name from the repo root's local repo-config (single source), no longer hardcoded.
# Deliberately from $repoRoot and not $PSScriptRoot: from the plugin mirror, $PSScriptRoot points
# to the plugin cache, while repo-config always lives in the consumer's repo root.
. (Join-Path $repoRoot 'scripts\repo-config.ps1')
$repo = Get-RepoName

# Pre-flight (#86): an unfilled scaffold (repo-config still at VUL-IN) would otherwise only fail
# further down with an unclear gh error. Stop here with a clear pointer.
if ($repo -match 'VUL-IN') {
    Write-Error "fold-changelog cannot run -- scripts\repo-config.ps1 still contains VUL-IN placeholders. Fill in Get-RepoName with this repo's value and run again."
    exit 1
}

# The 'Plugins:' detection relies on Get-TouchedPlugins from scripts\lib\release-lib.ps1 (#103,
# Victor #3) -- but release-lib.ps1 is deliberately NOT mirrored to the plugin (workshop-specific
# tooling, see scripts\lib\shared-scripts-lib.ps1), unlike this fold script itself. In the
# workshop root it simply exists; in a consumer repo running the plugin mirror it is missing, and
# the Plugins line is omitted -- functionally the same as before, since
# plugins/<plugin>/ paths do not exist there anyway.
$releaseLibPath = Join-Path $repoRoot 'scripts\lib\release-lib.ps1'
$canDetectPlugins = Test-Path -LiteralPath $releaseLibPath
if ($canDetectPlugins) { . $releaseLibPath }

# Shared native-capture helper (#114 item 1). $PSScriptRoot-relative, not $repoRoot: like
# check-report-lib.ps1 this lib is not repo-owned -- it travels with the SAME plugin/mirror payload
# as this script (registered in scripts\lib\shared-scripts-lib.ps1), so it resolves from the
# workshop root, a consumer's plugin cache, or the plugin mirror tree alike.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# The entry format: the 'Tier: N' line this script READS to pick a section and then REMOVES, plus the
# section map itself (Get-ChangelogTierSections). $PSScriptRoot-relative for the same reason as the lib
# above -- it travels with this script, so the writer (new-changelog-entry.ps1), the validator
# (open-pr.ps1) and this reader always hold the same version of the format.
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

# BOM-less UTF8 -- Set-Content -Encoding UTF8 always adds a BOM in Windows PowerShell 5.1,
# and the rest of the repo (CHANGELOG.md etc.) has no BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Test-IsChangelogEntryFile {
    # A changelog entry file (created by new-changelog-entry.ps1) always opens with the compact
    # entry heading '### <title> <midDot> <type> <midDot> <date>' -- an H3. Repo-root meta docs
    # (CONTRIBUTING.md, SECURITY.md, a future CODE_OF_CONDUCT.md, ...) open with an H1 ('# ...').
    # Fold-all mode keys off this structural signature so it only ever folds a genuine entry, never
    # whatever other *.md happens to sit in the repo root. Deliberately independent of the branch-
    # prefix table: consumer-extended prefixes (Shopify's style/, liquid/, ...) still fold, since an
    # entry from any prefix is written in this same format. The denylist below stays as a cheap
    # first filter; this is the actual gate.
    param([Parameter(Mandatory = $true)][string]$Path)
    foreach ($line in [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        return ($line -match '^###\s')
    }
    return $false
}

if ($Branch) {
    # Explicit target: the caller named the branch, so trust it and fold exactly that entry file.
    $entryFiles = @(($Branch -replace '/', '-') + ".md")
}
else {
    # Fold-all: never fold a file that is not an actual changelog entry (structural gate above).
    $reserved = @("CHANGELOG.md", "CLAUDE.md", "README.md")
    $entryFiles = Get-ChildItem -Path $repoRoot -Filter "*.md" -File |
        Where-Object { $reserved -notcontains $_.Name } |
        Where-Object { Test-IsChangelogEntryFile -Path $_.FullName } |
        Select-Object -ExpandProperty Name
}

if ($entryFiles.Count -eq 0) {
    Write-Host "No entry files found to fold." -ForegroundColor Yellow
    exit 0
}

$changelogPath = Join-Path $repoRoot "CHANGELOG.md"

# WHICH SECTION AN ENTRY IS FOLDED INTO -- one per tier, in document order. Both seams are read by
# Get-ChangelogTierSections (entry-scaffold-lib.ps1): Get-ChangelogTierHeadings where the repo declares
# tiers, otherwise the legacy single-section Get-ChangelogHeading (issue #178), otherwise the built-in
# '## Pull Requests'. A repo with one section is simply a repo with one tier, so there is no second code
# path here -- the loop below looks up a heading by tier either way.
#
# The local name is $foldSections, NOT $changelogTierHeadings: repo-config.ps1 backs each seam with a
# $script: variable of that name, and PowerShell variable names are case-insensitive -- at script
# top-level the local and script scopes are the same, so a same-named local would overwrite the
# dot-sourced value before the function is ever called, and the configured answer would silently read
# back as the default. Sibling of the $RepoRoot/$repoRoot collision documented at the top of this file.
$foldSections = @(Get-ChangelogTierSections)

# Does this repo rank its entries at all (issue #467)? Off where there is no tier split, and switchable
# off via Get-EntrySignificanceEnabled -- see Test-EntrySignificanceActive. Resolved once, from the sections
# already read above, so the seam is not probed per entry.
$significanceActive = Test-EntrySignificanceActive -TierSections $foldSections

# --- Pre-pass: every entry's tier is resolved and checked BEFORE anything is folded ---------------
# A fold-all run writes one entry at a time, so a problem found on the third file would leave the first
# two already folded and their source files deleted -- a half-state that has to be unpicked by hand on
# main. Both failures this catches are cheap to see up front and impossible to undo afterwards, so they
# are checked here rather than in the loop: a malformed 'Tier:' value, and a tier this repo declares no
# section for.
#
# Nothing else moves to a pre-pass. The gh lookup and the heading match stay in the loop where they
# always were: those depend on state this pass cannot know (the PR, and a changelog that the previous
# iteration has already rewritten).
$tierByFile = @{}
$tierProblems = @()
foreach ($file in $entryFiles) {
    $filePath = Join-Path $repoRoot $file
    if (-not (Test-Path $filePath)) { continue }
    $raw = Get-Content -Path $filePath -Raw -Encoding UTF8
    # One read answers both questions: which section (the highest tier a row claims) and where in it (that
    # row's significance). Resolve-EntryImpact falls back to the older 'Tier: N' line when the entry carries
    # no table, so an entry written before this format still files correctly.
    $impact = Resolve-EntryImpact -EntryText $raw
    $tier = [pscustomobject]@{ Tier = $impact.Tier; Declared = $impact.Declared }
    $impactErrors = @(@($impact.Errors) | Where-Object { $_ })
    if ($impactErrors.Count -gt 0) {
        # A tier that cannot be honoured stops the whole run, exactly as a malformed 'Tier:' line did: it
        # decides which SECTION the entry goes in, and guessing that wrong is a section-move on main.
        foreach ($problem in $impactErrors) { $tierProblems += "  $file -- $problem" }
        continue
    }
    $section = @($foldSections | Where-Object { $_.Tier -eq $tier.Tier })
    if ($section.Count -eq 0) {
        $declared = ($foldSections | ForEach-Object { $_.Tier }) -join ', '
        $tierProblems += "  $file -- declares tier $($tier.Tier), but this repo has no changelog section for it (it declares tiers: $declared). Add the section to Get-ChangelogTierHeadings in scripts\repo-config.ps1, or change the entry's tier."
        continue
    }
    # The significance score that decides WHERE IN the section this entry lands (issue #467). Read here
    # with the tier, because the position depends on both: only a tier-1-or-higher section is ranked.
    #
    # DELIBERATELY NOT A $tierProblems ENTRY, unlike a malformed tier. This pass refuses before anything
    # is folded, and that is right for the two failures it already catches: both are decidable before the
    # merge, and open-pr.ps1 refuses over them while the branch is still the only thing affected. A
    # significance score is different in the one way that matters here -- refusing the FOLD of an
    # already-merged branch produces the silent half-state this repo has measured (an unfolded entry file
    # sitting in the repo root the morning after its merge, with main looking finished). So a bad or
    # missing score is said out loud and the fold proceeds; cut-release.ps1 is the refusal point Dave
    # chose for it, and by then the branch is long gone and the fix is one edit in CHANGELOG.md.
    $rankScore = 0
    $anyScored = $false
    if ($significanceActive -and $tier.Tier -ge 1) {
        # The entry is filed under its OWN tier's section, so that tier's row is the one that orders it.
        $rankScore = Get-EntryImpactScore -Impact $impact -Tier $tier.Tier
        if ($rankScore -le 0) {
            Write-Host "  ($file declares no significance for tier $($tier.Tier) -- folded unranked, at the top of its section. The release cut will refuse until it has one.)" -ForegroundColor DarkYellow
        }
    }
    foreach ($row in @($impact.Rows)) { if ([int]$row.Score -gt 0) { $anyScored = $true } }
    $tierByFile[$file] = [pscustomobject]@{
        Tier      = $tier.Tier
        Declared  = $tier.Declared
        Heading   = $section[0].Heading
        RankScore = $rankScore
        AnyScored = $anyScored
    }
}
if ($tierProblems.Count -gt 0) {
    Write-Host "Nothing was folded -- these entries could not be filed:" -ForegroundColor Red
    $tierProblems | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    exit 1
}

# What this run actually folded -- the source for both the commit message and the committed pathspec.
$folded = @()

foreach ($file in $entryFiles) {
    $filePath = Join-Path $repoRoot $file
    if (-not (Test-Path $filePath)) {
        Write-Host "Entry file '$file' not found - skipped." -ForegroundColor Yellow
        continue
    }

    $entryContent = (Get-Content -Path $filePath -Raw -Encoding UTF8).TrimEnd()
    $changelogContent = Get-Content -Path $changelogPath -Raw -Encoding UTF8

    $usesCRLF = $changelogContent.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }
    $entryContent = ($entryContent -replace "`r`n", "`n") -replace "`n", $nl

    # The tier decides the section, and the pre-pass has already proved both are usable -- so this is a
    # lookup, not a decision. The line is then REMOVED: from here on the section states the tier, and
    # the same fact in two places is the drift this repo has paid for three times.
    $filed = $tierByFile[$file]
    # WHAT THE FOLD CONSUMES AND WHAT IT CARRIES (issue #467). The old 'Tier: N' line is always consumed:
    # once the entry sits under '## Tier 2 - Pull Requests', a line restating that is the same fact twice.
    # The impact TABLE is carried whenever any row is scored, and that is not an inconsistency -- the cut
    # EMPTIES these sections, so a score consumed here would not exist when the release documents are built
    # days later, and the ordering could not be reproduced without re-estimating it. Its Tier column is not
    # the duplication either: the section says how far the change reached, the column says which audience
    # each SCORE belongs to.
    #
    # AN UNSCORED TABLE IS SCAFFOLDING AND GOES. A tier-0 entry is never asked for a score, so its
    # '| 0 | - | - |' row is a question nobody put -- carrying it would leave a placeholder in the record.
    $entryContent = (Remove-EntryTierLine -EntryText $entryContent).TrimEnd()
    if (-not $filed.AnyScored) {
        $entryContent = (Remove-EntryImpactTable -EntryText $entryContent).TrimEnd()
    }
    $foldHeading = $filed.Heading
    $headingPattern = '(?m)^' + [regex]::Escape($foldHeading) + '\s*?$'
    if (-not $filed.Declared) {
        # Worth saying out loud rather than absorbing. Tier 0 is the documented default and the safe
        # one, but an author who simply forgot the line has produced work that cannot carry a release on
        # its own -- and the moment to learn that is now, not when the cut refuses.
        Write-Host "  ($file has no $(Get-EntryTierLabel): line -- filed as tier 0, which no release can be cut from on its own.)" -ForegroundColor DarkYellow
    }

    # The entry file is already compact ("### <title> <midDot> <type> <midDot> <date>" +
    # description), matching the CHANGELOG format. Fold only adds '#NN <midDot> ' at the front of
    # the title and the PR link at the end. The PR number only exists after the merge; we fetch it
    # via the branch -- from -Branch, or in fold-all mode derived from the file name
    # (<prefix>-<rest>.md -> <prefix>/<rest>).
    $midDot = [char]0x00B7
    $branchForPr = $Branch
    if (-not $branchForPr) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $branchForPr = $base -replace '^([^-]+)-', '$1/'
    }
    # gh can write messages to stderr; Invoke-NativeCapture runs it under EAP=Continue so that
    # cannot become a terminating error before the graceful exit-code handling below (#107).
    # -DiscardStderr (2>$null) keeps stderr out of the captured JSON. 'files' is simply included in
    # --json (Victor #4, #103) -- gh pr list supplies that field just as well as gh pr view, so the
    # second gh call (previously gh pr view --json files) has been dropped: one PR lookup suffices
    # for both the number/url and the touched files.
    # 'mergedAt' joined the field list on August 5, 2026 for the merge date below -- at no cost, since
    # this call already happens and gh returns whatever fields are asked for in one roundtrip.
    $prList = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--head', $branchForPr, '--state', 'all', '--json', 'number,url,files,mergedAt', '--limit', '1', '--repo', $repo) -DiscardStderr
    $ghCode = $prList.ExitCode
    $prJson = $prList.Output
    if ($ghCode -ne 0) { Write-Host "  (gh pr list returned exit code $ghCode -- PR-number enrichment skipped; run gh manually for the reason.)" -ForegroundColor DarkYellow }
    $prs = if ($ghCode -eq 0 -and $prJson) { @($prJson | ConvertFrom-Json) } else { @() }
    if ($prs.Count -ge 1) {
        $num = $prs[0].number
        $entryContent = ([regex]'(?m)^### ').Replace($entryContent, "### #$num $midDot ", 1)

        # Deriving touched plugins from the PR files (automation-first): paths under
        # plugins/<plugin>/ become a 'Plugins:' line, which
        # cut-release.ps1 later uses to update the per-plugin CHANGELOGs. The detection itself
        # lives in the pure Get-TouchedPlugins (release-lib.ps1, #103) -- only the guard is here;
        # 'files' already came along with the gh pr list call above, so no separate gh roundtrip
        # is needed anymore.
        if ($canDetectPlugins) {
            $paths = @($prs[0].files | ForEach-Object { $_.path })
            $touched = @(Get-TouchedPlugins -Files $paths)
            if ($touched.Count -gt 0) {
                $entryContent = $entryContent.TrimEnd() + "$nl$nl" + ('Plugins: ' + ($touched -join ', '))
            }
        }

        # THE CLOSING LINE CARRIES BOTH FACTS THE MERGE OWNS: which PR this was, and when it landed
        # (Dave, August 5, 2026). Built by Format-EntryFoldFooter in entry-scaffold-lib.ps1 -- the lib
        # that owns the entry FORMAT, so the one place that writes this line is the one place a test can
        # read it. Its header carries the reasoning for reading mergedAt rather than the clock; the clock
        # is passed in as the fallback because a pure function may not have one of its own.
        $entryContent = $entryContent.TrimEnd() + "$nl$nl" + (Format-EntryFoldFooter `
            -Number $num -Url $prs[0].url -MergedAt ([string]$prs[0].mergedAt) `
            -FallbackDate (Get-Date -Format 'yyyy-MM-dd'))
    }
    else {
        # No PR: no number, no url -- and no merge date either, deliberately. There is nothing to read a
        # landing date off, and inventing one from the clock would put a fact in the changelog that
        # nothing backs. An entry folded this way simply carries neither, exactly as it carried no #NN.
        Write-Host "  No PR found for '$branchForPr' - entry without PR number/url or merge date." -ForegroundColor Yellow
    }

    $headingMatch = [regex]::Match($changelogContent, $headingPattern)
    if (-not $headingMatch.Success) {
        Write-Host "Could not find the '$foldHeading' heading in CHANGELOG.md - stopping. (Section for tier $($filed.Tier); the heading comes from Get-ChangelogTierHeadings -- or the legacy Get-ChangelogHeading -- in scripts\repo-config.ps1. Either add that heading to CHANGELOG.md or correct the seam so the two match.)" -ForegroundColor Red
        exit 1
    }
    $afterHeader = $headingMatch.Index + $headingMatch.Length

    # Insert after any intro paragraph: at the top of the section, but below its intro text. The
    # section ends at whichever comes first after the heading -- the first ###-entry already in it, or
    # the next ##-section. Deriving the boundary structurally (issue #178) rather than looking for a
    # literal '## Releases' keeps this correct on a Keep-a-Changelog consumer too, where the sections
    # below '## [Unreleased]' are the released versions ('## [vX.Y.Z] - ...'), not a Releases block.
    $nextSection = ([regex]'(?m)^## ').Match($changelogContent, $afterHeader)
    $sectionEnd = if ($nextSection.Success) { $nextSection.Index } else { $changelogContent.Length }

    # WHERE IN the section, decided by the significance score (issue #467). The fold is the only moment at
    # which CHANGELOG.md's pending list can be ordered, because the cut empties these sections: whatever
    # order is left here IS the order the release documents inherit, since they read the section in
    # document order and sort nothing. That is what makes the ordering reproducible across the fold and
    # the cut without either re-estimating a score.
    #
    # A SCORE OF 0 -- a tier-0 section, an unscored entry, a repo with the ranking off -- returns the top
    # of the section, byte-identical to what this did before ranking existed.
    #
    # THE SLICE, AND WHY THE OFFSET IS RELATIVE TO IT: Get-ImpactInsertOffset only ever returns an
    # entry boundary or the slice's end, so adding $afterHeader back cannot land mid-entry. The insert
    # itself is unchanged -- '<entry>\n\n---\n\n' is correct before any '### ' and at the section end
    # alike, because every folded entry is followed by its own separator.
    $sectionText = $changelogContent.Substring($afterHeader, $sectionEnd - $afterHeader)
    $insertPos = $afterHeader + (Get-ImpactInsertOffset -SectionText $sectionText -Score $filed.RankScore -Tier $filed.Tier)

    $entryBlock = "$entryContent$nl$nl---$nl$nl"
    $changelogContent = $changelogContent.Substring(0, $insertPos) + $entryBlock + $changelogContent.Substring($insertPos)

    Write-Utf8NoBom -Path $changelogPath -Content $changelogContent
    Remove-Item -Path $filePath -Force
    $rankNote = if ($filed.RankScore -gt 0) { ", significance $($filed.RankScore)" } else { '' }
    Write-Host "Folded and removed: $file (tier $($filed.Tier)$rankNote -> $foldHeading)" -ForegroundColor Green
    # Captured per iteration rather than read back afterwards. $num in particular survives from one loop
    # pass to the next, so an entry whose PR lookup found nothing would otherwise inherit the previous
    # entry's number -- into a commit message, where a wrong PR reference is worse than none.
    $folded += [pscustomobject]@{
        File   = $file
        Branch = $branchForPr
        Pr     = $(if ($prs.Count -ge 1) { $prs[0].number } else { $null })
    }
}

Write-Host "CHANGELOG.md updated." -ForegroundColor Green

# --- The fold commit ------------------------------------------------------------------------------
# WHY THIS IS IN THE SCRIPT AT ALL. The fold has always ended with a hand-typed commit, and on
# August 2, 2026 that happened four times in one session -- the exact "noticed once, automated the
# second time" trigger this house works by. It is also the step where a mistake is least visible: the
# fold itself is verified by the lint gate, while the commit around it is typed from memory each time.
#
# THE SCOPE IS ENFORCED BY GIT, NOT BY CARE. 'git commit -- <paths>' commits exactly those paths and
# ignores the index, so whatever else is modified or already staged cannot ride along. That matters
# more here than anywhere else in this repo: this commit goes straight to the main branch under a named
# exception to "never commit directly", and an exception is only safe while it stays the size it was
# granted at.
if ($Push) { $Commit = $true }
if ($Commit) {
    if ($folded.Count -eq 0) {
        Write-Host "Nothing was folded, so there is nothing to commit." -ForegroundColor Yellow
        exit 0
    }
    $subjects = @($folded | ForEach-Object {
        if ($_.Pr) { "$($_.Branch) (#$($_.Pr))" } else { $_.Branch }
    })
    $message = if ($folded.Count -eq 1) {
        "chore: fold changelog entry $($subjects[0])"
    } else {
        "chore: fold $($folded.Count) changelog entries: " + ($subjects -join ', ')
    }
    # CHANGELOG.md plus the entry files -- named, and nothing else. The entry files are gone from disk
    # by now; naming a deleted path is how git is told to record the deletion.
    #
    # ONLY THE ONES GIT ALREADY KNOWS. In the normal flow the entry file was committed on the branch and
    # came to main with the merge, so it is tracked and its deletion belongs in this commit. But an entry
    # written and folded without ever being committed is untracked, and naming an untracked path makes
    # 'git commit' fail on the pathspec -- after the fold has already deleted the file, which is the
    # worst possible moment for an avoidable error. Read from the index rather than from disk, because by
    # now the file is gone from disk and still in the index, which is exactly the state that needs
    # recording.
    $entryPaths = @($folded | ForEach-Object { $_.File })
    $lsFiles = Invoke-NativeCapture -FilePath 'git' -Arguments (@('ls-files', '--') + $entryPaths)
    # git reports its own paths with forward slashes; the entry names are plain file names in the repo
    # root, so normalising both sides costs nothing and removes the one way this could silently drop a
    # deletion from the commit.
    $tracked = @($lsFiles.Output | Where-Object { $_ } | ForEach-Object { ($_ -replace '/', '\').Trim() })
    $paths = @('CHANGELOG.md') + @($entryPaths | Where-Object { $tracked -contains ($_ -replace '/', '\') })
    $untracked = @($entryPaths | Where-Object { $tracked -notcontains ($_ -replace '/', '\') })
    if ($untracked.Count -gt 0) {
        Write-Host "  (not in the commit, because git never tracked them: $($untracked -join ', ') -- they were folded and deleted all the same.)" -ForegroundColor DarkYellow
    }
    $commitRun = Invoke-NativeCapture -FilePath 'git' -Arguments (@('commit', '-m', $message, '--') + $paths)
    if ($commitRun.ExitCode -ne 0) {
        Write-Host ($commitRun.Output -join "`n") -ForegroundColor Red
        Write-Host "The fold is on disk but NOT committed (git commit exited $($commitRun.ExitCode)). Commit it by hand; do not re-run the fold, it has already removed the entry files." -ForegroundColor Red
        exit 1
    }
    Write-Host "Committed: $message" -ForegroundColor Green

    if ($Push) {
        $pushRun = Invoke-NativeCapture -FilePath 'git' -Arguments @('push')
        if ($pushRun.ExitCode -ne 0) {
            Write-Host ($pushRun.Output -join "`n") -ForegroundColor Red
            Write-Host "Committed locally but NOT pushed (git push exited $($pushRun.ExitCode)) -- the state this flag exists to avoid. Push by hand." -ForegroundColor Red
            exit 1
        }
        Write-Host "Pushed." -ForegroundColor Green
    }
}
