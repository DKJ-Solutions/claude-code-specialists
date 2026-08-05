<#
Creates the changelog entry file for the current branch in the repo root:
<branch-name-with-hyphens>.md, with branch name, date, and branch type already filled in.

Usage:
  .\scripts\release\new-changelog-entry.ps1 -Title "Short title of the change"

Branch type is derived from the branch prefix via the shared table in
scripts/lib/branch-info.ps1 (feat/fix/docs/chore).
Unknown prefix -> falls back to a repo-configurable type ("Chore" by default) with a warning,
adjust it yourself in the file.

THE ENTRY ALSO CARRIES A TIER, written at its default of 0: how far this change reaches, on the
scale 0 = only this repo's own developers notice / 1 = a colleague on the project gets something out
of it / 2 = a consumer notices. RAISE IT BY HAND when the change deserves it -- the release cut reads
these tiers and refuses a bump the pending work has not earned, so an entry left at 0 is work that
cannot be released on its own. The format lives in scripts/lib/entry-scaffold-lib.ps1, shared with
open-pr.ps1 (which refuses a malformed tier) and fold-changelog-entry.ps1 (which uses it to pick the
changelog section and then removes the line).

THE REACH IS DECLARED AS AN IMPACT TABLE, one row per tier (issue #467), written at tier 0:

  | Tier | Significance | Why |
  |---|---|---|
  | 0 | - | - |

ADD A ROW PER TIER THIS CHANGE REACHES, with a significance from 1 to 5 against the RUBRIC (printed
below the file when this script runs; owned by Get-EntrySignificanceRubric) and a Why saying why this
particular change sits in that band. The ladder is cumulative, so a tier-2 change owes a tier-1 row as
well -- the rows an entry has are the documents it appears in, and the score decides where in each one it
sits. The score cells are written EMPTY, unlike the tier, because any number here would be a guess at a
ranking; cut-release.ps1 refuses a release whose entries have not answered.

A repo that does not rank (Test-EntrySignificanceActive) gets the older single 'Tier: 0' line instead,
which is still read everywhere -- "recognise both, write one".

Optional -Intent: the direction of the branch -- what still needs to happen and where you left
off. Typically given when parking a branch for later (see new-branch.ps1 -Park). If it is given it
becomes the recorded entry body; if it is left empty the body falls back to a directional block
instead of a bare one-line TODO, so a forgotten -Intent still leaves a "what is next / where was
I" prompt rather than an empty placeholder (#162).

THE STUB WORDING IS REPO-OWNED (#410). The four strings this script writes -- the title
placeholder, the body heading, the fallback body and the unknown-prefix type -- come from four
OPTIONAL functions in the consumer's scripts/repo-config.ps1 (Get-EntryTitlePlaceholder,
Get-EntryBodyHeading, Get-EntryBodyPlaceholder, Get-EntryFallbackType), each guarded with
Get-Command and falling back to the English value it used to hardcode. Reason: the file this
script writes is repo-owned, so its language is too -- a non-English consumer previously had to
keep a whole private copy of this script at the same relative path just to change four strings,
and then got two entry formats for one branch depending on which entry point ran. repo-config
itself stays OPTIONAL here: if the file is absent (or fails to load) this script still runs on
branch-info.ps1 alone, which keeps it lighter than fold/open-pr.

Internal handoff from new-branch.ps1: that script invokes this file as a child process without
-Title/-Intent, and passes them instead via the environment variables CLAUDE_NEWBRANCH_TITLE and
CLAUDE_NEWBRANCH_INTENT. Reason: free text (e.g. copied from an external issue/PR title) as a
standalone CLI argument across a native process boundary is an injection primitive
(quotes/backslashes can break the child process's argv reconstruction); environment variable
values do not go through argv requoting. If -Title/-Intent is given explicitly (standalone use), it
always wins; only when the param is at its own default AND the env var is set is the env var used.
#>

param(
    # Empty by DEFAULT, not the placeholder text (#410). The placeholder is now repo-configurable, and
    # a param default is bound before repo-config can be read -- so the default here has to be a
    # sentinel meaning "the caller named no title", resolved to the configured placeholder further
    # down. It used to be the literal 'TODO: title', which doubled as that sentinel; keeping it would
    # have made the magic string exist in two files (here and new-branch.ps1) while the value it stood
    # for lived in a third.
    [string]$Title = "",
    [string]$Intent = ""
)

$ErrorActionPreference = "Stop"

# See the handoff explanation above: only adopt it if the param is still at its own default, so
# an explicit -Title (standalone use) always keeps precedence.
if ($Title -eq "" -and $env:CLAUDE_NEWBRANCH_TITLE) {
    $Title = $env:CLAUDE_NEWBRANCH_TITLE
}
# Same injection-safe env-var handoff for the optional intent; the env var is only the fallback
# while -Intent is still at its own (empty) default, so an explicit -Intent always wins.
if ($Intent -eq "" -and $env:CLAUDE_NEWBRANCH_INTENT) {
    $Intent = $env:CLAUDE_NEWBRANCH_INTENT
}

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# Pre-flight (#86): this script relies ONLY on scripts\lib\branch-info.ps1 in the consumer's repo
# root (no repo-config, no gh -- lighter than fold/open-pr). If that is missing -- typically on a
# clean consumer -- stop with a clear pointer instead of a raw dot-source error below.
$branchInfoPath = Join-Path $repoRoot 'scripts\lib\branch-info.ps1'
if (-not (Test-Path -LiteralPath $branchInfoPath)) {
    Write-Error "new-changelog-entry cannot run -- missing repo-owned file: $branchInfoPath (Get-BranchInfo / the branch prefix table). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward."
    exit 1
}

# The repo-owned stub wording (#410) -- OPTIONAL, unlike branch-info.ps1 above. repo-config.ps1 may be
# absent (a repo that never needed it) or may fail to load (a syntax error in someone's edit); neither
# is a reason for this script to stop, because every string it supplies has a working default. So:
# Test-Path, then a try/catch that degrades to a warning. Anything harsher would make the LIGHTEST
# script in the set the one with the strictest dependency.
#
# The local names are deliberately $stub*, NOT $EntryTitlePlaceholder and friends: repo-config backs
# each function with a $script: variable of that name, and at script top level the local and script
# scopes are the same -- so a same-named local would overwrite the dot-sourced value before the
# function is ever called, and the configured wording would silently read back as the default. That is
# the collision already documented on $RepoRoot/$repoRoot in fold-changelog-entry.ps1; it costs nothing
# to avoid and is invisible when you do not.
#
# THE THREE PROSE STRINGS NO LONGER LIVE HERE. They moved to entry-scaffold-lib.ps1 when open-pr.ps1
# gained the gate that REFUSES an entry still carrying them: the writer and the guard must not be able
# to disagree about the wording, or the guard silently misses whatever the writer changed. The fallback
# type stays here, because it is a changelog TYPE rather than scaffold prose -- 'Chore' is a legitimate
# final value and can never be evidence of an unedited entry.
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

$stubFallbackType = 'Chore'

$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $configPath) {
    try {
        . $configPath
        if (Get-Command Get-EntryFallbackType -ErrorAction SilentlyContinue) {
            $v = Get-EntryFallbackType; if ($v) { $stubFallbackType = $v }
        }
    } catch {
        Write-Warning "scripts\repo-config.ps1 could not be loaded ($($_.Exception.Message)) -- writing the entry with the built-in default wording."
    }
}

# Probed AFTER the dot-source above, so this repo's own answers win where it gives them.
$scaffold         = Get-EntryScaffoldWording
$stubTitle        = $scaffold.Title
$stubBodyHeading  = $scaffold.BodyHeading
$stubBody         = $scaffold.BodyPlaceholder

# The caller named no title (see the param comment): use this repo's placeholder.
if ($Title -eq "") { $Title = $stubTitle }

# BOM-less UTF8 -- Set-Content -Encoding UTF8 always adds a BOM in Windows PowerShell 5.1,
# and the rest of the repo has no BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq "main") {
    Write-Host "You are on main - create a branch first." -ForegroundColor Red
    exit 1
}

. $branchInfoPath

$info = Get-BranchInfo -Branch $branch
$branchType = $info.Type
if (-not $branchType) {
    $branchType = $stubFallbackType
    Write-Host "Unknown branch prefix '$($info.Prefix)' - 'Branch type' set to '$stubFallbackType', adjust this by hand if needed." -ForegroundColor Yellow
}

$fileName = $info.SafeName + ".md"
$filePath = Join-Path $repoRoot $fileName

if (Test-Path $filePath) {
    Write-Host "Entry file '$fileName' already exists - nothing done." -ForegroundColor Yellow
    exit 0
}

$midDot = [char]0x00B7

# Body: an explicit -Intent (typically when parking the branch for later / another device) becomes
# the recorded body; otherwise it falls back to a directional block instead of a bare one-line
# TODO, so a forgotten -Intent still prompts for "what is next / where was I" (#162). Either way
# this is a scaffold: whoever finishes the branch replaces the body with the final description
# before the PR (open-pr and fold-changelog-entry read exactly this text).
if ($Intent -ne "") {
    $body = $Intent
} else {
    $body = $stubBody
}

# THE IMPACT TABLE, at its harmless default: one tier-0 row with no score (issue #467). It declares both
# facts about reach at once -- how far this change goes, and how much it weighs at each reach it claims --
# and the fold reads the tier off it to pick which of the changelog's three sections the entry lands in.
#
# RAISING THE REACH IS ADDING A ROW, which is the shape's real gain over the 'Tier: N' line it replaced.
# The ladder is cumulative, so a change consumers notice is also a change colleagues get something out of;
# as rows that is impossible to claim halfway. You cannot say "reaches consumers" without also saying what
# it is worth to them AND to the project, because each is a row and each row has a score.
#
# WRITTEN AT TIER 0 RATHER THAN GUESSED FROM THE BRANCH PREFIX, which is the whole point of the table
# existing. This repo has MEASURED that the prefix does not predict impact: held against the 19 entries
# pending at v3.2.0, the single most consequential change for a consumer -- renaming the marketplace, which
# breaks every existing install -- arrived on a chore/ branch. A derived tier would encode that same wrong
# guess as a verdict; a declared one makes it the author's call.
#
# AND THE SCORE CELLS ARE WRITTEN EMPTY, deliberately unlike the tier. Tier 0 is a legitimate final answer,
# so defaulting to it under-promotes at worst and the cut says so out loud. A significance score has no
# harmless value: any number written here would be a GUESS at a RANKING, which is exactly the failure the
# retired highlights marker was measured on. So the cells are questions, and cut-release.ps1 refuses a
# release whose entries have not answered them.
#
# DELIBERATELY NO -Tier PARAMETER. Whoever finishes the branch already has to rewrite this file's title and
# body before the PR (open-pr's scaffold gate refuses the stubs), so filling in the table is editing a file
# that is being edited anyway -- not a manual sequence worth a flag, and one fewer parameter that every
# consumer's skill page would have to document.
#
# THE SECTION SHAPE IS THE SHAPE, ALWAYS -- the ranking's on/off switch does not change it. An earlier
# draft wrote the table only where Test-EntrySignificanceActive said the repo ranks, and the old 'Tier: 0'
# line otherwise. That produced TWO entry shapes in one system, so every reader downstream would have needed
# both paths forever. The table at tier 0 is harmless in a repo that never scores it -- nothing asks, nothing
# refuses -- so the switch now governs only the GATES, which is the thing a repo was ever opting out of.
$impactActive = Test-EntrySignificanceActive

# ONE H2 PER CHANGE, WITH THREE NAMED SECTIONS (Dave, August 5, 2026). The heading carries only what a reader
# scans -- the title, and after the merge the PR number. Everything else is stated under its own '### ':
# what the change does, who it is for (the impact table), and its type.
#
# THE TYPE IS NO LONGER A MIDDOT FIELD IN THE HEADING. It used to be parsed back out of there -- first by
# position, then by matching against the known types -- because the heading was doing three jobs at once. As
# its own section it is stated rather than inferred.
#
# NO DATE HERE, DELIBERATELY (Dave, August 5, 2026). This script runs when the BRANCH is created, so any
# date it writes is the branch's birth date -- and the changelog records what LANDED when. A branch opened on
# Monday and merged on Thursday used to be filed as Monday's work, silently, in the one document whose whole
# job is to say when things happened. The date is the fold's to add, from the PR's own merge timestamp, and
# it goes at the BOTTOM with the PR number: the two facts that do not exist until the merge.
#
# THE STUB BODY STILL GOES INSIDE the 'what does this change do?' section rather than replacing it, so
# open-pr's scaffold gate keeps working unchanged: it refuses an entry still carrying this wording, and it
# looks for the wording, not for where it sits.
$entryLines = Format-EntryBlock -Title $Title -Type $branchType -Body ($stubBodyHeading + "`n`n" + $body)
$template = ($entryLines -join "`n") + "`n"

[System.IO.File]::WriteAllText($filePath, $template, $Utf8NoBom)
Write-Host "Created: $fileName" -ForegroundColor Green

# The rubric, printed at the moment the entry comes into existence. The scores themselves are filled in
# later -- when the tier is raised, by whoever finishes the branch -- so this is not a prompt to act on
# now; it is the scale being stated where the author is looking, instead of only inside a refusal further
# down the line. A gate that first mentions the definitions when it blocks you has already let the guess
# happen.
if ($impactActive) {
    $range = Get-EntrySignificanceRange
    Write-Host "  Impact table written at tier 0. Add a row per tier this change reaches, with a significance ($($range.Min)-$($range.Max)):" -ForegroundColor Cyan
    Format-EntrySignificanceRubricLines | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
}
