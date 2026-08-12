<#
.SYNOPSIS
    Prints where this repo stands right now, plus the next topic if one was locked -- the input for
    /lock (before a context clear) and /continue (after one).

.DESCRIPTION
    A reporter, and deliberately nothing else. It reads; it never writes, commits, pushes or edits.
    Both skills that use it are safe to run at any moment for that reason, including on a dirty tree
    mid-branch.

    WHY THIS EXISTS. Clearing the context throws away the one thing the repo cannot reconstruct: which
    subject was agreed as next. Everything else -- the tree, the branch, the parked work, the open
    issues, the pending entries, the gates -- is a fact the repo still holds, and reading it is
    strictly better than reading a summary of it. This repo has the measured instance: a
    self-verifying start prompt arrived three times identically truncated, breaking off mid-word, and
    nothing in the visible list announced what was missing.

    SO THE TWO HALVES ARE SPLIT BY WHO OWNS THEM, and that split is the whole design:

      the LOCK   a decision. Not derivable from the tree, because a priority is a judgement about
                 what matters, not a fact about what is true. Written by /lock, read here verbatim.
      the REPO   the authority. Re-read on every run, so a lock that has been overtaken by work
                 done since is visible as a disagreement rather than followed off a cliff.

    THE LOCK IS RECORDED INTENT, NOT A REFUSAL. Nothing here enforces it and nothing should: this
    script prints both halves and leaves the comparison to the reader. A future change that made
    /continue obey the lock without re-reading the repo would reintroduce exactly the failure above --
    trusting a handover over the repo -- so the printout keeps them side by side and separately
    labelled.

    NO LIBRARY DEPENDENCIES, ON PURPOSE. It dot-sources nothing and requires no seam function, so it
    works in a repo that has adopted none of this workflow. Every optional source (gh, tags, the
    release notes, repo-config) is probed and degrades to a stated line rather than an error: a status
    command that fails because an optional tool is absent is worse than no status command.

    Dual-context repo root (issue #81): CLAUDE_PROJECT_DIR where a consumer runs the plugin mirror,
    otherwise the git root -- which is what lets the root copy and the mirror stay byte-identical.

    Pure ASCII (repo convention for .ps1).

.PARAMETER StoreOverride
    Absolute path to use as the lock file instead of the repo's own. Exists so the test suite can
    point at a fixture; a consumer never types it.

.EXAMPLE
    powershell -NoProfile -File scripts/task/session-status.ps1
#>
param(
    [string]$StoreOverride = ''
)

$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
# This is the one library this script loads, and it loads it OPTIONALLY -- the promise that a repo which
# has adopted none of this workflow still gets an answer is unchanged.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# The lock file's path is decided HERE and printed below, so the two skills cannot disagree about it.
# A path repeated in two markdown pages is two literals, and the drift shape this repo has paid for
# three times; a path the script prints is one.
$script:LockRelPath = '.claude/handover.md'

$repoRoot = if ($env:CLAUDE_PROJECT_DIR) {
    $env:CLAUDE_PROJECT_DIR
} else {
    try { (git rev-parse --show-toplevel 2>$null).Trim() } catch { '' }
}
if (-not $repoRoot -or -not (Test-Path -LiteralPath $repoRoot)) {
    Write-Error "session-status cannot run -- no repo root. Run it from inside a git repository, or set CLAUDE_PROJECT_DIR."
    exit 1
}
Set-Location $repoRoot

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)
    Write-Host ''
    Write-Host $Title -ForegroundColor Cyan
}

function Write-Absent {
    # An absent optional source is STATED rather than skipped. A blank where a section should be reads
    # as "nothing to report", which is a different claim from "this could not be read".
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "  (not read: $Message)" -ForegroundColor DarkGray
}

Write-Host ''
Write-Host "== session-status -- $repoRoot ==" -ForegroundColor Cyan

# --- 1. THE LOCK: the half the repo cannot reconstruct, so it is printed FIRST ------------------
#
# First deliberately. It is the reason somebody ran this command, and burying the agreed subject
# under six blocks of repo facts is how it gets skimmed past.
$lockPath = if ($StoreOverride) { $StoreOverride } else { Join-Path $repoRoot $script:LockRelPath }

Write-Section "The locked topic (a decision -- the repo cannot reconstruct this)"
Write-Host "  path: $lockPath"
if (Test-Path -LiteralPath $lockPath -PathType Leaf) {
    # -Encoding UTF8 on every markdown read here, and it is not belt-and-braces. PowerShell 5.1 reads a
    # BOM-LESS file in the system ANSI codepage, so a note containing an em dash comes back as 'a EUR"'
    # -- measured on this script's own first run against releases/notes/4.x/4.5.0.md. This repo writes
    # its markdown BOM-less by convention (lint check 26 refuses a BOM in shipped frontmatter), so the
    # default is wrong for every file this block reads, and the corruption lands in exactly the text a
    # reader is meant to act on.
    $lockText = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8
    $lockAge  = (Get-Date) - (Get-Item -LiteralPath $lockPath).LastWriteTime
    Write-Host ("  set:  {0:0} h {1:00} min ago" -f [math]::Floor($lockAge.TotalHours), $lockAge.Minutes)
    Write-Host ''
    foreach ($line in ($lockText -split '\r?\n')) { Write-Host "  | $line" }
    Write-Host ''
    Write-Host "  VERIFY THIS AGAINST THE BLOCKS BELOW before acting on it. Where they disagree the repo" -ForegroundColor Yellow
    Write-Host "  wins, and say so out loud -- a locked topic can have been done or overtaken since." -ForegroundColor Yellow
} else {
    Write-Host "  no topic is locked. Run /lock to set one, or read the blocks below and propose."
}

# --- 2. BRANCH AND TREE ------------------------------------------------------------------------
#
# The check most likely to be skipped exactly when it matters: a successful chain ends by switching to
# the trunk with a clean tree, which reads as "ready" rather than as "one command from working in the
# wrong place". Measured August 10, 2026, after seven files were edited on main.
Write-Section 'Branch and tree'
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
$dirty  = @(git status --porcelain)
Write-Host ("  branch: {0}" -f $branch)
Write-Host ("  tree:   {0}" -f $(if ($dirty.Count -eq 0) { 'clean' } else { "$($dirty.Count) change(s) uncommitted" }))
if ($dirty.Count -gt 0) { $dirty | ForEach-Object { Write-Host "    $_" } }

Write-Section 'Recent commits'
git log --oneline -5 | ForEach-Object { Write-Host "  $_" }

# --- 3. PARKED BRANCHES -------------------------------------------------------------------------
#
# A parked branch has no pull request by design, so it is invisible to every other block here and to
# a local git status. The measured instance: a briefing, a memory note and every local command agreed
# the tree was clean while a fully-planned parked branch sat on the remote, overtaken hours earlier.
Write-Section 'Parked branches on origin (no PR by design -- invisible everywhere else)'
$trunk = 'main'
try {
    $originHead = (git symbolic-ref --quiet refs/remotes/origin/HEAD 2>$null)
    if ($originHead) { $trunk = ($originHead -split '/')[-1].Trim() }
} catch { }
try {
    $heads = @(git ls-remote --heads origin 2>$null |
        ForEach-Object { ($_ -split "`t")[-1] -replace '^refs/heads/', '' } |
        Where-Object { $_ -and $_ -ne $trunk })
    if ($heads.Count -eq 0) { Write-Host "  none (trunk '$trunk' only)" }
    else { $heads | ForEach-Object { Write-Host "  $_" } }
} catch {
    Write-Absent 'origin is unreachable'
}

# --- 4. OPEN ISSUES ----------------------------------------------------------------------------
#
# Printed as a list rather than a count because the next act on an inbound item is to VERIFY it still
# stands -- filing and repairing can cross inside one morning, and routing an already-repaired item
# produces a second repair competing with the first.
Write-Section 'Open issues (verify each still stands BEFORE routing it)'
$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    Write-Absent 'the gh CLI is not installed'
} else {
    try {
        $issues = @(gh issue list --state open --limit 30 --json number,title 2>$null | ConvertFrom-Json)
        if ($issues.Count -eq 0) { Write-Host '  none' }
        else { $issues | ForEach-Object { Write-Host ("  #{0}  {1}" -f $_.number, $_.title) } }
    } catch {
        Write-Absent 'gh could not reach the remote (not authenticated, or no network)'
    }
}

# --- 5. PENDING CHANGELOG ENTRIES ---------------------------------------------------------------
#
# The tiers are printed with the entries because they decide which release documents a cut would
# produce and which bump the pending work has earned -- the two facts a release decision turns on.
Write-Section 'Pending changelog entries'
$changelog = Join-Path $repoRoot 'CHANGELOG.md'
if (-not (Test-Path -LiteralPath $changelog -PathType Leaf)) {
    Write-Absent 'this repo has no CHANGELOG.md'
} else {
    $entries = 0
    $tier    = $null
    foreach ($line in (Get-Content -LiteralPath $changelog -Encoding UTF8)) {
        if ($line -match '^##\s+(?<h>.+)$') {
            $entries++
            Write-Host ("  {0}" -f $Matches['h'])
        } elseif ($line -match '^####\s+Tier\s+(?<t>\d+)') {
            $tier = $Matches['t']
        } elseif ($line -match '^\s*(?:\*\*)?Score:(?:\*\*)?\s*(?<s>\S+)' -and $null -ne $tier) {
            Write-Host ("      tier {0} -> {1}" -f $tier, $Matches['s']) -ForegroundColor DarkGray
            $tier = $null
        }
    }
    if ($entries -eq 0) { Write-Host '  none pending -- the list is at its intro' }
    else { Write-Host ("  ({0} entry/entries pending)" -f $entries) }
}

# --- 6. THE LAST RELEASE, AND WHAT IT LEFT OPEN -------------------------------------------------
Write-Section 'Last release'
try {
    $tag = (git describe --tags --abbrev=0 2>$null)
    if ($tag) { Write-Host "  $($tag.Trim())" } else { Write-Absent 'this repo has no tags yet' }
} catch {
    Write-Absent 'this repo has no tags yet'
}

# THE SECTION HEADING IS MATCHED, NOT ASSUMED, and the match is loose on purpose. The literal comes
# from Get-ReleaseNoteWording where a repo defines it; otherwise any heading saying "still open" is
# taken, so a repo that reworded the section is not silently reported as having nothing open. A
# lib dot-source would have given the exact string and would also have made this reporter fail in a
# repo that has adopted none of the workflow -- which is the wrong trade for a status command.
$openHeading = 'still open'
# WHERE THE NOTES LIVE COMES FROM THE SAME SEAM THE CUT WRITES THEM WITH (inbound #616). This is the
# reader; cut-release.ps1 is the writer. A seam that reaches only the writer is worse than no seam --
# the consumer who repoints it would have their notes written to the new root and looked for in the
# old, and the miss reports as "no release note was found", which reads like a repo that has not cut
# one yet. Read here the way the wording beside it already is: repo-config directly, in the try that
# degrades to the default, because this script dot-sources no library in order to produce its ANSWER.
# (Since August 12, 2026 it does load one, optionally: the source-repo guard, above, which either stops
# the run outright or contributes nothing to it. The property that matters is unchanged -- a repo
# carrying neither this seam nor that lib still gets a full report.)
$noteRootRel = 'releases/notes'
try {
    $cfg = Join-Path $repoRoot 'scripts\repo-config.ps1'
    if (Test-Path -LiteralPath $cfg -PathType Leaf) {
        . $cfg
        if (Get-Command Get-ReleaseNoteWording -ErrorAction SilentlyContinue) {
            $w = Get-ReleaseNoteWording
            if ($w -and $w.ContainsKey('SectionOpen') -and $w['SectionOpen']) { $openHeading = [string]$w['SectionOpen'] }
        }
        if (Get-Command Get-ReleaseNoteRoot -ErrorAction SilentlyContinue) {
            $r = Get-ReleaseNoteRoot
            if ($r) { $noteRootRel = [string]$r }
        }
    }
} catch { }

# The scan starts AT the notes root rather than at releases/ with a path filter behind it. The filter it
# replaces asked whether the full path contained a 'notes' segment, which is also true of every file in
# the tree when the checkout itself sits under a folder of that name -- and it could not have honoured
# the seam at all, since the segment it looked for was the thing being configured.
$notesRoot = Join-Path $repoRoot ($noteRootRel -replace '/', '\')
$newestNote = $null
#
# THE NEWEST NOTE IS THE HIGHEST VERSION, NOT THE MOST RECENTLY WRITTEN FILE. This sorted on
# LastWriteTime until August 12, 2026, and the measurement that retired it is that mtime says when a
# file was last TOUCHED, which any reorganisation of the tree rewrites for every document at once.
# Measured the day the twelve releases/consumer/ + releases/internal/ pairs were merged into
# releases/audience/: all twelve came out with the identical stamp (17:07:29), so
# 'Sort-Object LastWriteTime -Descending | Select-Object -First 1' returned whatever the enumeration
# order happened to yield -- 4.2.0 while 4.5.0 existed, and unstable between runs. The block was
# populated and therefore looked correct, which is why two readers walked straight past it.
#
# A STRING SORT WOULD NOT HAVE FIXED IT EITHER: this tree holds 3.10.0.md beside 3.9.0.md, which sorts
# the wrong way as text. Hence the [version] cast.
#
# The mtime path is KEPT as the fallback rather than removed, for a consumer whose note documents are
# not named X.Y.Z: switching the block off for them would be the silent failure this repair is about,
# one layer along. Nothing here dot-sources a library, so the parse stays inline.
if (Test-Path -LiteralPath $notesRoot -PathType Container) {
    $allNotes = @(Get-ChildItem -Path $notesRoot -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue)
    $versioned = @($allNotes | Where-Object { $_.BaseName -match '^\d+\.\d+\.\d+$' })
    if ($versioned.Count -gt 0) {
        $newestNote = $versioned | Sort-Object { [version]$_.BaseName } -Descending | Select-Object -First 1
    } elseif ($allNotes.Count -gt 0) {
        $newestNote = $allNotes | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    }
}

Write-Section "What the last release left open (from its own note)"
if (-not $newestNote) {
    Write-Absent "no release note was found under $noteRootRel/"
} else {
    Write-Host ("  source: {0}" -f ($newestNote.FullName.Substring($repoRoot.Length).TrimStart('\', '/') -replace '\\', '/'))
    $lines    = @(Get-Content -LiteralPath $newestNote.FullName -Encoding UTF8)
    $inside   = $false
    $printed  = 0
    foreach ($line in $lines) {
        if ($line -match '^(#{1,6})\s+(?<h>.+)$') {
            if ($inside) { break }
            if ($Matches['h'] -like "*$openHeading*") { $inside = $true; continue }
            continue
        }
        if ($inside -and $line.Trim()) { Write-Host "  $line"; $printed++ }
    }
    if ($printed -eq 0) {
        Write-Host "  (that note has no section matching '$openHeading', or the section is empty)"
    }
}

# --- 7. THE GATES -------------------------------------------------------------------------------
#
# NAMED, NOT RUN. Together they take minutes, and a status command that costs minutes gets avoided --
# at which point it reports nothing at all. The commands are printed so the reader can run whichever
# the work in front of them actually needs.
Write-Section 'The gates (not run here -- minutes each; run what the work needs)'
foreach ($g in @(
    'scripts/lint/check-plugin-integrity.ps1',
    'scripts/sync/check-script-contract.ps1',
    'scripts/sync/check-roster-sync.ps1'
)) {
    if (Test-Path -LiteralPath (Join-Path $repoRoot ($g -replace '/', '\')) -PathType Leaf) {
        Write-Host "  powershell -NoProfile -File $g"
    }
}

Write-Host ''
Write-Host 'Read the blocks above before proposing or resuming anything. Where the locked topic and the' -ForegroundColor DarkGray
Write-Host 'repo disagree, the repo wins -- and the disagreement is itself worth reporting.' -ForegroundColor DarkGray
Write-Host ''
exit 0
