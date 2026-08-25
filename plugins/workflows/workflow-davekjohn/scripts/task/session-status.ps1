<#
.SYNOPSIS
    Prints where this repo stands right now, plus the next topic if one was locked -- the input for
    /lock (before a context clear) and /handover (after one).

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
    /handover obey the lock without re-reading the repo would reintroduce exactly the failure above --
    trusting a handover over the repo -- so the printout keeps them side by side and separately
    labelled.

    NO REQUIRED DEPENDENCIES, ON PURPOSE. It requires no seam function and no library, so it works in
    a repo that has adopted none of this workflow. Every optional source -- gh, tags, the release
    notes, repo-config, the source-repo guard and the entry format's own library -- is probed and
    degrades to a stated line rather than an error: a status command that fails because an optional
    tool is absent is worse than no status command.

    THIS SAID 'IT DOT-SOURCES NOTHING' UNTIL AUGUST 19, 2026, and that sentence did damage. It had been
    untrue since the source-repo guard arrived on August 12, and while it stood it was the argument for
    giving the tier block below a heading pattern of its own instead of the shared reader -- which then
    missed every heading the entry format grew after it was written. What is load-bearing is that
    nothing is REQUIRED, not that nothing is loaded.

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
    # Declared OUTSIDE the try, because both the exit-code branch and the catch print it and the catch can
    # fire before the try's first line completes. There is no Set-StrictMode here, so an unset variable
    # would reach Write-Absent's mandatory parameter as $null and throw from inside the handler.
    $unreachable = 'gh could not reach the remote (not authenticated, or no network)'
    try {
        # ASSIGN FIRST, WRAP SECOND. PowerShell 5.1 emits a parsed JSON array to the pipeline as ONE
        # object, so `@(gh ... | ConvertFrom-Json)` collects a single element that IS the whole array:
        # $_.number then does member enumeration and prints every number on one line. Measured on this
        # very block -- three open issues rendered as '#System.Object[]  System.Object[]'.
        #
        # AND THE COUNT IS 1 WHETHER THE LIST HOLDS ZERO ITEMS OR THIRTY, which is the half a test misses:
        # the 'none' branch below could never fire, so an issue-free repo printed a bare '#' with two empty
        # fields. Exactly ONE open issue is the blind spot that let this survive -- there the broken form is
        # correct, so the block only misbehaves at 0 or 2+.
        #
        # Same trap, same remedy as pr-issues-lib.ps1's Get-OpenPrRecord; the Where-Object is that lib's
        # 'require a number before believing a record'.
        #
        # THE EXIT CODE IS CHECKED BECAUSE THE CATCH BELOW NEVER FIRES. `2>$null` means an unauthenticated
        # or offline gh throws nothing and yields no stdout, so ConvertFrom-Json never runs, the pipeline
        # yields nothing, and the branch below reports 'none'. Measured against the pre-fix script: an
        # unanswerable gh already printed 'none' -- so the degrade line this script's docstring promises
        # for every optional source was unreachable here, and 'we could not ask' was being printed as
        # 'there are none'. A wrong answer that looks like a right one. The catch stays for a payload that
        # arrives but does not parse.
        #
        # NO `return` IN HERE: this is script scope, so a return would exit session-status entirely and
        # silently drop every block below -- the pending entries, the tag, the release note. Hence the
        # else, and hence the one message declared above rather than the same sentence typed in both
        # places: two literals of one string is the drift shape this repo has paid for repeatedly.
        $raw = gh issue list --state open --limit 30 --json number,title 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Absent $unreachable
        } else {
            $parsed = $raw | ConvertFrom-Json
            $issues = @($parsed | Where-Object { $_ -and $_.number })
            if ($issues.Count -eq 0) { Write-Host '  none' }
            else { $issues | ForEach-Object { Write-Host ("  #{0}  {1}" -f $_.number, $_.title) } }
        }
    } catch {
        Write-Absent $unreachable
    }
}

# --- THE OPTIONAL SEAMS, LOADED ONCE ------------------------------------------------------------
#
# Two files this script uses where they exist and does without where they do not: the consumer's
# repo-config.ps1 (the release-note wording and root, and the audience tier a named tier heading
# resolves against) and the entry format's own library. Loaded HERE, above the first block that reads
# either, because two blocks below need repo-config and the reader needs it before it is asked
# anything -- a named tier heading resolves through Get-ReleaseAudienceTier, so a library loaded
# without it would report this repo's own entries as unreadable.
#
# NEITHER IS REQUIRED, WHICH IS THE PROMISE IN THE HEADER ABOVE. A repo that has adopted none of this
# workflow still gets a full report; each block that reads one of these degrades to a stated line.
$script:HaveEntryReader = $false
try {
    $cfgPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
    if (Test-Path -LiteralPath $cfgPath -PathType Leaf) { . $cfgPath }
} catch { }
# Get-SeamValue + Get-DefaultChangelogPath (issue #885, group A): the pending-entries block below used
# to hard-code 'CHANGELOG.md' where cut-release.ps1 and fold-changelog-entry.ps1 now read the same seam
# through the same shared definition. GUARDED, same as entry-scaffold-lib.ps1 below: a repo (or test
# fixture) that has not adopted this far still gets a full report, and the pending-entries block falls
# back to the flat 'CHANGELOG.md' literal when Get-SeamValue is unavailable.
$script:HaveSeamReader = $false
try {
    $seamLib = Join-Path $PSScriptRoot '..\lib\seam-lib.ps1'
    if (Test-Path -LiteralPath $seamLib -PathType Leaf) {
        . $seamLib
        $script:HaveSeamReader = [bool](Get-Command Get-SeamValue -ErrorAction SilentlyContinue)
    }
} catch { $script:HaveSeamReader = $false }
try {
    # THE SAME RELATIVE STEP new-branch.ps1 TAKES, and that is what makes it right in both contexts:
    # 'scripts\task' -> 'scripts\lib' in the repo that maintains this file, and the identical step
    # inside the plugin mirror a consumer runs. Resolving the library through the REPO ROOT instead
    # would have found it only here, and reported every consumer's tiers as unread.
    $entryLib = Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1'
    if (Test-Path -LiteralPath $entryLib -PathType Leaf) {
        . $entryLib
        $script:HaveEntryReader = [bool](Get-Command Resolve-EntryImpact -ErrorAction SilentlyContinue)
    }
} catch {
    $script:HaveEntryReader = $false
}

function Write-EntryTiers {
    <#
        Prints one entry's tier declarations, through the shared reader or not at all.

        WHAT IT REFUSES TO DO IS THE POINT: it never prints a tier it did not read. Where the library is
        absent, the entry declares nothing, or the parse throws, it says so -- because the block this
        replaced printed 'tier 0' in all three cases, and tier 0 is not a missing answer. It is an
        answer, and it earns a patch. A reader deciding whether to cut a minor cannot tell the two apart.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$EntryText,
        [Parameter(Mandatory)][string]$NotApplicable
    )
    if (-not $script:HaveEntryReader) {
        Write-Host '      tier not read -- entry-scaffold-lib.ps1 is not beside this script' -ForegroundColor DarkGray
        return
    }
    $impact = $null
    try { $impact = Resolve-EntryImpact -EntryText $EntryText } catch { }
    if (-not $impact) {
        Write-Host '      tier not read -- the entry could not be parsed' -ForegroundColor DarkGray
        return
    }
    $parts = @()
    foreach ($row in @($impact.Rows)) {
        if ($row.Error) { continue }
        # N/A AND UNANSWERED ARE NAMED, not folded into 'score 0' the way a table's empty cell made them
        # look. 'N/A' is a tier stating it reaches nobody; a blank score is an author who has not
        # answered yet, and the release gates treat those two very differently. Only the section shape
        # carries the property, so it is probed rather than assumed.
        $score = if ($row.PSObject.Properties['NotApplicable'] -and $row.NotApplicable) {
            $NotApplicable
        } elseif ([int]$row.Score -gt 0) {
            [string][int]$row.Score
        } else {
            'unanswered'
        }
        $parts += ("tier {0} -> {1}" -f [int]$row.Tier, $score)
    }
    if ($parts.Count -gt 0) {
        Write-Host ("      {0}" -f ($parts -join ', ')) -ForegroundColor DarkGray
    } elseif ($impact.Declared) {
        # The pre-table 'Tier: N' line states a reach and carries no per-tier score to list beside it.
        Write-Host ("      tier {0}" -f [int]$impact.Tier) -ForegroundColor DarkGray
    } else {
        Write-Host '      no tier declared' -ForegroundColor DarkGray
    }
    # A MALFORMED SECTION IS PRINTED, NOT DROPPED. The reader reports row-level faults instead of
    # absorbing them precisely so a caller can surface them; swallowing them here would rebuild the
    # silence this block is a repair for, one layer in.
    foreach ($err in @($impact.Errors)) {
        Write-Host ("      unreadable: {0}" -f $err) -ForegroundColor DarkGray
    }
}

# --- 5. PENDING CHANGELOG ENTRIES ---------------------------------------------------------------
#
# The tiers are printed with the entries because they decide which release documents a cut would
# produce and which bump the pending work has earned -- the two facts a release decision turns on.
#
# THEY ARE READ THROUGH THE SHARED READER, NOT THROUGH A PATTERN OF THIS SCRIPT'S OWN, and the history
# of the pattern it replaced is the argument. That pattern matched '#### Tier N' and nothing else, so it
# never knew the audience tier's named heading and from August 16, 2026 reported tier 0 alone --
# dropping the reach silently. When tier 0 in turn stopped carrying a heading of its own on August 19,
# the partial blind spot became a total one: no tier at all for an entry written in the shape the
# scaffolder had just been taught to write. Both failures point the same way, towards a patch.
#
# Resolve-EntryImpact reads every shape an entry has ever been written in, and is the same reader the
# fold ranks on and the release cut groups on. Teaching this block the one heading it was missing would
# have left the identical defect waiting for the next rename: the reader was what was wrong, not the
# pattern.
Write-Section 'Pending changelog entries'
$changelogRel = if ($script:HaveSeamReader) {
    Get-SeamValue -Name 'Get-ChangelogPath' -Default (Get-DefaultChangelogPath -RepoRoot $repoRoot)
} else {
    'CHANGELOG.md'
}
$changelog = Join-Path $repoRoot $changelogRel
if (-not (Test-Path -LiteralPath $changelog -PathType Leaf)) {
    Write-Absent "no $changelogRel"
} else {
    # THE 'N/A' LITERAL COMES FROM THE LIBRARY TOO where the library is there. It is one of the strings
    # the format states once on purpose, and a second copy here is the drift shape this repair is about.
    $naLabel = 'N/A'
    if ($script:HaveEntryReader -and (Get-Command Get-EntryScoreNotApplicable -ErrorAction SilentlyContinue)) {
        $naLabel = [string](Get-EntryScoreNotApplicable)
    }

    # ONE '##' BLOCK PER ENTRY, HANDED TO THE READER WHOLE. The line-at-a-time walk this replaced could
    # not have used the reader at all: tier 0's section is now the entry's opening '###' question, and
    # the discriminator for it is the score label underneath -- neither is visible one line at a time,
    # and neither is fence-aware. An entry that QUOTES a tier heading inside a code fence -- the entries
    # documenting this format do -- is now read as what it is rather than as what it describes.
    $entries = 0
    $heading = $null
    $body    = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in (Get-Content -LiteralPath $changelog -Encoding UTF8)) {
        if ($line -match '^##\s+(?<h>.+)$') {
            if ($null -ne $heading) { Write-EntryTiers -EntryText ($body -join "`n") -NotApplicable $naLabel }
            $entries++
            $heading = $Matches['h']
            Write-Host ("  {0}" -f $heading)
            $body.Clear()
            $body.Add($line)
        } elseif ($null -ne $heading) {
            $body.Add($line)
        }
    }
    if ($null -ne $heading) { Write-EntryTiers -EntryText ($body -join "`n") -NotApplicable $naLabel }
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
# REQUIRED lib dot-source would have given the exact string and would also have made this reporter
# fail in a repo that has adopted none of the workflow -- which is the wrong trade for a status
# command. The tier block above loads one OPTIONALLY, which is a different bargain: present, it answers
# exactly; absent, it says the tiers are unread rather than inventing a number.
$openHeading = 'still open'
# WHERE THE NOTES LIVE COMES FROM THE SAME SEAM THE CUT WRITES THEM WITH (inbound #616). This is the
# reader; cut-release.ps1 is the writer. A seam that reaches only the writer is worse than no seam --
# the consumer who repoints it would have their notes written to the new root and looked for in the
# old, and the miss reports as "no release note was found", which reads like a repo that has not cut
# one yet. Read here the way the wording beside it already is: from repo-config, which the seam probe
# above has already loaded where the repo has one, in a try that degrades to the default. The property
# that matters is unchanged -- a repo carrying neither this seam nor that library still gets a full
# report.
$noteRootRel = 'releases/notes'
try {
    if (Get-Command Get-ReleaseNoteWording -ErrorAction SilentlyContinue) {
        $w = Get-ReleaseNoteWording
        if ($w -and $w.ContainsKey('SectionOpen') -and $w['SectionOpen']) { $openHeading = [string]$w['SectionOpen'] }
    }
    if (Get-Command Get-ReleaseNoteRoot -ErrorAction SilentlyContinue) {
        $r = Get-ReleaseNoteRoot
        if ($r) { $noteRootRel = [string]$r }
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
# one layer along. No library states this naming, so the parse stays inline.
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
