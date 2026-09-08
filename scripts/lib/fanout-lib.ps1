<#
.SYNOPSIS
    Did the working copy LOSE anything while dispatched subagents ran in it -- the snapshot, and the
    shrinkage comparison over two of them.

.DESCRIPTION
    Dot-source this file from a script in scripts/task/:

        . (Join-Path $PSScriptRoot '..\lib\fanout-lib.ps1')

    Supplies Get-WorkingCopySnapshot (the git reads), Compare-WorkingCopySnapshot (the whole
    judgement, pure) and Format-WorkingCopyShrinkage (the report). check-fanout.ps1 is the entry
    point; the split exists so the judgement can be tested against hand-built snapshots without a
    fixture repo per case.

    WHY THIS EXISTS AT ALL (issue #1670, September 8, 2026). Issue #1665 measured a dispatched review
    specialist running `git stash` and then `git checkout HEAD -- <file>` in the orchestrator's
    checkout, discarding three files of uncommitted work belonging to the session that dispatched it.
    That loss produced NO error, NO notice, NO refusal, and a clean `git status` afterwards -- the
    reviewer even cited that cleanliness as proof it had changed nothing. It was found by accident,
    days later, because a `grep` happened to show old text where new text had been verified minutes
    earlier.

    #1665 was repaired with an INSTRUCTION -- the shared block `working-copy-boundary`, carried by
    every agent def that holds `Bash`. That repair is purely preventive, and #1670's point is that the
    detection half did not exist anywhere: no pre/post-dispatch snapshot, no stash delta, nothing
    watching. So the next occurrence was exactly as invisible as the first, and LESS conspicuous
    whenever what gets discarded is a config value or a single flag rather than a paragraph of prose
    somebody later happens to read.

    SHRINKAGE IS THE SIGNAL, NOT CHANGE, and that asymmetry is what keeps this from being noise. A
    subagent legitimately writing files makes the porcelain list GROW, which is expected and is never
    reported. What is reported is the list getting SMALLER: a path that was modified and no longer is,
    a worktree change that has been reverted under a path that remains, or a stash entry that has
    gone.

    IT REPORTS AND CANNOT RESTORE, and that is a property of the damage rather than a choice. Content
    discarded by `git checkout HEAD -- <path>` was never committed and is in no reflog, so there is
    nothing to restore it FROM. Detection is the whole available remedy, which is exactly why its
    absence mattered.

    THE FIVE FALSE POSITIVES IT ANSWERS, because a detector that cries wolf is one somebody switches
    off:

      1. THE ORCHESTRATOR COMMITTED. It is told to keep working while the fan-out runs, so a path may
         leave the porcelain list because it was committed, not because it was discarded. The caller
         hands over the paths carried by the commits added since the baseline, and those are excluded.
      2. HISTORY WAS REWRITTEN. If the second HEAD is not a descendant of the first, that path list is
         not a bridge between them and cannot be trusted; the comparison says so instead of computing
         a number from it.
      3. THE BRANCH CHANGED. Porcelain is relative to HEAD, so two snapshots taken on different
         branches describe different questions. Reported as untrusted rather than differenced.
      4. THE INDEX HALF ALONE WENT CLEAN. `git reset` unstages a change and keeps its content, so a
         staged-to-unstaged transition is not a loss and is deliberately NOT reported. Only the
         WORKTREE half going clean is, because that is what `git checkout -- <path>` does.
      5. THE FILE WAS RENAMED. A `git mv` inside the window takes the baseline's key out of the list
         while the edit sits intact under the new name, so the rename pairing is kept and the
         comparison FOLLOWS the file -- in both directions, since a baseline taken with a rename
         already staged can equally be unstaged inside the window. Following it is not merely a way
         to stay quiet: the worktree-half rule then still reaches a real loss that happens on the far
         side of the rename, which a simple exemption would have hidden.

    THE RESIDUAL LIMIT, STATED RATHER THAN HIDDEN. `core.quotePath=true` is what makes the two
    readings comparable whatever console code page each ran under, and it is never undone -- so a path
    holding a non-ASCII character is reported in git's own C-quoted form rather than as the readable
    filename. That is correct for the comparison and poor for the reader, and the trade is deliberate:
    a mis-decoded path compares wrong (a silent miss, or a false alarm), while an escaped one is
    merely ugly to read. park-lib.ps1 makes the same trade and never feels it, because its figure is a
    count that is never displayed.

    A READ THAT FAILED REPORTS UNKNOWN, NEVER ZERO -- park-lib.ps1's Get-GitParkBacking states the
    same rule for the same reason: zero is an answer ("nothing was lost", the reassuring one), and
    handing it back for "this could not be established" would clear a working copy nobody measured.

    STASH ENTRIES ARE IDENTIFIED, NOT COUNTED. #1670 proposed a count and said a count is enough; it
    is not, and the gap is cheap to close. A subagent that pops one entry while the orchestrator
    pushes another leaves the count unchanged, and a count therefore reports nothing on exactly the
    #1665 command. `git stash list --format=%H` gives every entry its own commit id, so a vanished
    entry is a vanished id whatever else happened beside it.

    Dot-sources native-capture-lib.ps1 itself, guarded, the way git-identity-lib.ps1 does: a caller
    that already supplied it loses nothing, and a caller that did not still gets a working lib.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

# Guarded, for the reason the header gives: dot-sourcing twice is harmless, and a tree whose mirror
# predates this lib must not crash on load.
$captureLib = Join-Path $PSScriptRoot 'native-capture-lib.ps1'
if (Test-Path -LiteralPath $captureLib -PathType Leaf) { . $captureLib }

function Get-WorkingCopySnapshot {
    <#
        What this working copy holds right now, as an object a later run can be compared against:
        HEAD, the branch, one entry per changed or untracked path (with its index and worktree status
        halves kept separate), and the identity of every stash entry.

        THE STATUS HALVES ARE KEPT APART because they answer different questions and only one of them
        is a loss. Porcelain reports 'XY path': X is the index, Y is the worktree. `git reset` moves a
        change from X to Y and destroys nothing; `git checkout -- <path>` clears Y and destroys the
        edit. A snapshot that stored the two-character code as one string could still tell them apart,
        but every caller would then have to re-learn which column is which -- so the parse happens
        once, here.

        --untracked-files=all, AND THE DEFAULT IS MEASURABLY WRONG FOR THIS PURPOSE. git's default
        collapses an untracked DIRECTORY to a single entry naming the directory ('?? some/dir/'), so a
        subagent's `git clean` inside it would remove files this snapshot never listed. Per-file also
        respects .gitignore, so a build directory does not flood the list. Same lesson, same reason, as
        Get-GitParkBacking in park-lib.ps1.

        core.quotePath IS FORCED ON, and it is the language rule about reading a native command's
        output rather than a preference: these paths are COMPARED against a second snapshot's, and
        PowerShell 5.1 decodes a child process's stdout with whatever console code page the run
        inherited. Quoting holds the wire to ASCII, where every candidate code page agrees, so a
        filename with an accent cannot decode into something that accidentally matches -- or fails to
        match -- the same file read a minute later under a different code page. A repo may set
        core.quotepath in its own config, hence -c rather than trusting the default.

        EVERY FIGURE CARRIES ITS OWN Known FLAG. The three git reads fail independently -- a repo with
        no commit yet has no HEAD, and a `git stash list` can fail on its own -- and a caller must be
        able to say "not measured" about one of them while trusting the other two.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    $headRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $RepoRoot, 'rev-parse', 'HEAD') -DiscardStderr
    $head = ''
    $headKnown = $false
    if ($headRes.ExitCode -eq 0) {
        $head = (($headRes.Output | Out-String) -split '\r?\n' | Where-Object { $_.Trim() } | Select-Object -First 1)
        if ($head) { $head = $head.Trim(); $headKnown = $true }
    }

    # --abbrev-ref, WHICH ANSWERS 'HEAD' ON A DETACHED HEAD rather than the empty string --show-current
    # would give. Either is a constant, so the comparison's equality test behaves the same and the
    # branch-change refusal still fires between a detached reading and an on-branch one. It is named
    # here because the two commands are NOT interchangeable and nothing in the suite would notice the
    # swap: a future tidy-up towards --show-current would silently change what an empty answer means.
    # Two readings taken at DIFFERENT detached commits both read 'HEAD' and are not caught here at
    # all -- the ancestry check in the caller's bridge is what covers that case.
    $branchRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $RepoRoot, 'rev-parse', '--abbrev-ref', 'HEAD') -DiscardStderr
    $branch = ''
    $branchKnown = $false
    if ($branchRes.ExitCode -eq 0) {
        $branch = (($branchRes.Output | Out-String) -split '\r?\n' | Where-Object { $_.Trim() } | Select-Object -First 1)
        if ($null -ne $branch) { $branch = ([string]$branch).Trim(); $branchKnown = $true }
    }

    $entries = @{}
    $entriesKnown = $false
    $stRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-c', 'core.quotePath=true', '-C', $RepoRoot, 'status', '--porcelain', '--untracked-files=all')
    if ($stRes.ExitCode -eq 0) {
        $entriesKnown = $true
        foreach ($line in (($stRes.Output | Out-String) -split '\r?\n')) {
            if ($line.Length -lt 4) { continue }
            $index = $line.Substring(0, 1)
            $worktree = $line.Substring(1, 1)
            $raw = $line.Substring(3)
            # A rename reads 'old -> new'. The new path is the one that exists on disk and is the key;
            # THE OLD ONE IS KEPT RATHER THAN DISCARDED, and that is a repair rather than a nicety.
            # Discarding it made an ordinary `git mv` during the window look exactly like a loss: the
            # baseline's key disappeared, no commit carried it, and the comparison reported the edit
            # gone while it sat intact under the new name. Measured on this lib before it shipped --
            # a file at ' M', renamed, reported as Vanished. Keeping the pair lets the comparison
            # follow the file instead, which ALSO means the worktree-half rule still reaches a real
            # loss that happens on the far side of a rename.
            $from = ''
            $arrow = $raw.IndexOf(' -> ')
            if ($arrow -ge 0) {
                $from = $raw.Substring(0, $arrow).Trim().Trim('"')
                $raw = $raw.Substring($arrow + 4)
            }
            $path = $raw.Trim().Trim('"')
            if (-not $path) { continue }
            $entries[($path -replace '\\', '/')] = [pscustomobject]@{
                Index    = $index
                Worktree = $worktree
                From     = if ($from) { ($from -replace '\\', '/') } else { '' }
            }
        }
    }

    $stash = @()
    $stashKnown = $false
    # %H is the stash commit's own id. See the header: an id survives the case a count cannot, where one
    # entry is popped and another pushed in the same window.
    $stashRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $RepoRoot, 'stash', 'list', '--format=%H') -DiscardStderr
    if ($stashRes.ExitCode -eq 0) {
        $stashKnown = $true
        $stash = @(($stashRes.Output | Out-String) -split '\r?\n' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }

    return [pscustomobject]@{
        Head         = $head
        HeadKnown    = $headKnown
        Branch       = $branch
        BranchKnown  = $branchKnown
        Entries      = $entries
        EntriesKnown = $entriesKnown
        Stash        = $stash
        StashKnown   = $stashKnown
        TakenUtc     = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }
}

function Get-WorkingCopyEntryFrom {
    <#
        One entry's rename origin, or '' -- read DEFENSIVELY rather than as a property access.

        Three kinds of object reach the comparison and only two of them are this lib's own: a snapshot
        taken here, a baseline rehydrated from JSON, and an entry a caller (or a suite) built by hand.
        A hand-built one predating the rename pairing has no From at all, and under StrictMode a bare
        $e.From on it is a terminating error rather than a blank -- which would take the whole
        comparison down over a field whose absence has a perfectly good meaning: not a rename.
    #>
    param([AllowNull()][object]$Entry)
    if ($null -eq $Entry) { return '' }
    if (-not ($Entry.PSObject.Properties.Name -contains 'From')) { return '' }
    if ($null -eq $Entry.From) { return '' }
    return [string]$Entry.From
}

function Get-WorkingCopySnapshotFormat {
    <# The baseline file's own shape version. Bumped when the serialised shape changes, so a baseline
       written by an older copy is REFUSED rather than half-read -- a snapshot whose Entries arrive
       empty because the shape moved would report every changed path as vanished, which is the
       false-alarm end of this detector and the one that gets it switched off. #>
    return 1
}

function ConvertTo-WorkingCopySnapshotJson {
    <#
        A snapshot as JSON, for the baseline file that lives between the two runs.

        ENTRIES BECOME AN ARRAY, and that is the whole reason this function exists rather than a bare
        ConvertTo-Json at the call site. A hashtable serialises to a JSON object, and ConvertFrom-Json
        hands a JSON object back as a PSCustomObject -- which has no ContainsKey, so the comparison
        would fail on a baseline read from disk while passing every test that built its snapshots in
        memory. An array of records round-trips into exactly what it left as.
    #>
    param([Parameter(Mandatory = $true)][object]$Snapshot)

    $entries = @()
    foreach ($path in @($Snapshot.Entries.Keys | Sort-Object)) {
        $e = $Snapshot.Entries[$path]
        $entries += [pscustomobject]@{
            Path     = $path
            Index    = $e.Index
            Worktree = $e.Worktree
            # Carried through the file for the same reason it is captured at all: without it a rename
            # that straddles the baseline reads as a loss on the far side of the round trip, which is
            # the exact defect the parse was repaired for -- and a baseline read from disk is the
            # commonest way the comparison actually runs.
            From     = if ($e.PSObject.Properties.Name -contains 'From') { [string]$e.From } else { '' }
        }
    }

    return ([pscustomobject]@{
        Format       = Get-WorkingCopySnapshotFormat
        Head         = $Snapshot.Head
        HeadKnown    = [bool]$Snapshot.HeadKnown
        Branch       = $Snapshot.Branch
        BranchKnown  = [bool]$Snapshot.BranchKnown
        Entries      = $entries
        EntriesKnown = [bool]$Snapshot.EntriesKnown
        Stash        = @($Snapshot.Stash)
        StashKnown   = [bool]$Snapshot.StashKnown
        TakenUtc     = $Snapshot.TakenUtc
    } | ConvertTo-Json -Depth 6)
}

function ConvertFrom-WorkingCopySnapshotJson {
    <#
        The inverse, with Entries rehydrated into a hashtable so the comparison sees the same shape it
        sees in memory. THROWS on a shape it does not know, for the reason
        Get-WorkingCopySnapshotFormat gives.
    #>
    param([Parameter(Mandatory = $true)][string]$Json)

    $o = $Json | ConvertFrom-Json
    $format = if ($o.PSObject.Properties.Name -contains 'Format') { [int]$o.Format } else { 0 }
    if ($format -ne (Get-WorkingCopySnapshotFormat)) {
        throw "This baseline was written in snapshot format '$format' and this copy reads format '$(Get-WorkingCopySnapshotFormat)'. Take a fresh baseline; a half-read one would report every changed path as lost."
    }

    $entries = @{}
    foreach ($e in @($o.Entries)) {
        if (-not $e -or -not $e.Path) { continue }
        $entries[[string]$e.Path] = [pscustomobject]@{
            Index    = [string]$e.Index
            Worktree = [string]$e.Worktree
            # A baseline written before the rename pairing existed carries no From at all. It reads as
            # '' -- which is what a non-rename says too, so an old file degrades to the pre-repair
            # behaviour for renames only, rather than throwing on load.
            From     = if ($e.PSObject.Properties.Name -contains 'From') { [string]$e.From } else { '' }
        }
    }

    return [pscustomobject]@{
        Head         = [string]$o.Head
        HeadKnown    = [bool]$o.HeadKnown
        Branch       = [string]$o.Branch
        BranchKnown  = [bool]$o.BranchKnown
        Entries      = $entries
        EntriesKnown = [bool]$o.EntriesKnown
        Stash        = @($o.Stash | ForEach-Object { [string]$_ } | Where-Object { $_ })
        StashKnown   = [bool]$o.StashKnown
        TakenUtc     = [string]$o.TakenUtc
    }
}

function Compare-WorkingCopySnapshot {
    <#
        The whole judgement, and deliberately PURE: two snapshots plus what the caller could establish
        about the history between them, in; a list of findings, out. No git, no filesystem, no clock --
        which is what lets the suite put a case in front of it in three lines instead of building a
        fixture repo.

        $Bridge carries what only a git read can answer about the gap between the two snapshots:

          CommittedPaths       paths carried by the commits added since $Before (already normalised
                               to forward slashes). Excluded from the vanished set, because a path
                               that left the list by being COMMITTED was not discarded -- and the
                               orchestrator is explicitly told to keep working while the fan-out runs,
                               so this is the ordinary case rather than an edge one.
          CommittedPathsKnown  whether that list could be established at all.
          HistoryLinear        whether $After's HEAD is a descendant of $Before's. False means the
                               path list above is not a bridge between them and nothing may be
                               differenced across it.
          HistoryKnown         whether THAT could be established.

        A finding is @{ Kind; Path; Detail }. Kinds, and each one is a different fault:

          Vanished          a path was listed and is not any more. THE #1665 CASE.
          WorktreeCleared   the path is still listed, but its worktree change is gone -- what
                            `git checkout -- <path>` does to a file that also had a staged change.
          StashGone         a stash entry present in $Before is absent from $After, by its own id.
          BranchChanged     the two snapshots are not about the same ref. Untrusted, not differenced.
          HistoryRewritten  $After's HEAD is not a descendant of $Before's. Same.
          NotMeasured       one of the reads behind one of the figures failed. Reported so a caller
                            can say "unknown" where it would otherwise print a reassuring zero.

        THE ORDER OF THE TWO REFUSALS MATTERS. BranchChanged and HistoryRewritten are returned INSTEAD
        of a path comparison, not beside one: a list of "losses" computed across a branch switch is
        worse than no list, because it is wrong in the direction that gets the detector switched off.
    #>
    param(
        [Parameter(Mandatory = $true)][object]$Before,
        [Parameter(Mandatory = $true)][object]$After,
        [Parameter(Mandatory = $true)][object]$Bridge
    )

    $findings = @()

    # --- What could not be established at all -----------------------------------------------------
    # Reported first and unconditionally: these are the sentences that stop a clean report from being
    # read as proof, and they are true regardless of what the comparison below manages to say.
    if (-not $Before.EntriesKnown -or -not $After.EntriesKnown) {
        $which = if (-not $Before.EntriesKnown) { 'the baseline' } else { 'the second reading' }
        $findings += [pscustomobject]@{
            Kind   = 'NotMeasured'
            Path   = ''
            Detail = "the changed-path list could not be read for $which, so no path comparison was made"
        }
    }
    if (-not $Before.StashKnown -or -not $After.StashKnown) {
        $findings += [pscustomobject]@{
            Kind   = 'NotMeasured'
            Path   = ''
            Detail = 'the stash list could not be read, so a vanished stash entry would not be seen'
        }
    }

    # --- The two refusals -------------------------------------------------------------------------
    if ($Before.BranchKnown -and $After.BranchKnown -and $Before.Branch -ne $After.Branch) {
        $findings += [pscustomobject]@{
            Kind   = 'BranchChanged'
            Path   = ''
            Detail = "the baseline was taken on '$($Before.Branch)' and this reading on '$($After.Branch)'; a changed-path list is relative to HEAD, so the two are not comparable"
        }
        return $findings
    }
    if ($Bridge.HistoryKnown -and -not $Bridge.HistoryLinear) {
        $findings += [pscustomobject]@{
            Kind   = 'HistoryRewritten'
            Path   = ''
            Detail = "this reading's HEAD is not a descendant of the baseline's, so the commits between them are not a bridge and nothing was differenced across it"
        }
        return $findings
    }

    # --- The path comparison ----------------------------------------------------------------------
    if ($Before.EntriesKnown -and $After.EntriesKnown) {
        $committed = @{}
        foreach ($p in @($Bridge.CommittedPaths)) {
            if ($p) { $committed[([string]$p -replace '\\', '/')] = $true }
        }

        # WHERE A RENAME MOVED A BASELINE PATH TO, built once from the second reading. An entry whose
        # From is set says "this file used to be called that", and that is what lets the comparison
        # FOLLOW a file rather than report the name it no longer has.
        $renamedTo = @{}
        foreach ($p in @($After.Entries.Keys)) {
            $from = Get-WorkingCopyEntryFrom -Entry $After.Entries[$p]
            if ($from) { $renamedTo[[string]$from] = $p }
        }

        foreach ($path in @($Before.Entries.Keys | Sort-Object)) {
            $was = $Before.Entries[$path]
            $nowPath = $path
            $now = $null

            if ($After.Entries.ContainsKey($path)) {
                $now = $After.Entries[$path]
            } elseif ($renamedTo.ContainsKey($path)) {
                # Renamed inside the window. Follow it, and report any real loss under the name the
                # file carries NOW -- that is the name a reader has to act on.
                $nowPath = $renamedTo[$path]
                $now = $After.Entries[$nowPath]
            } elseif ((Get-WorkingCopyEntryFrom -Entry $was) -and $After.Entries.ContainsKey((Get-WorkingCopyEntryFrom -Entry $was))) {
                # THE MIRROR IMAGE, and it needs its own arm: the baseline was taken with a rename
                # already staged and the window UNSTAGED it, so the file is back under its old name
                # with its content intact. That is an index-half move, which false positive 4 covers --
                # but the KEY changed, so the same-key arm above cannot see it.
                continue
            }

            if ($null -eq $now) {
                if ($committed.ContainsKey($path)) { continue }
                # THE ONE HONEST HEDGE IN HERE. Where the committed-path list could not be read, a
                # vanished path is still reported -- but the report says the innocent explanation could
                # not be ruled out, rather than accusing or staying silent.
                $detail = if ($Bridge.CommittedPathsKnown) {
                    'was changed at the baseline and is now unchanged, and no commit since the baseline carries it'
                } else {
                    'was changed at the baseline and is now unchanged; whether a commit since the baseline carries it could NOT be established'
                }
                $findings += [pscustomobject]@{ Kind = 'Vanished'; Path = $path; Detail = $detail }
                continue
            }

            # The worktree half only. See the header's false positive 4: the index half going clean is
            # `git reset`, which keeps the content.
            if ($was.Worktree -ne ' ' -and $was.Worktree -ne '?' -and $now.Worktree -eq ' ') {
                $findings += [pscustomobject]@{
                    Kind   = 'WorktreeCleared'
                    # The name the file has NOW, which is the one a reader has to act on. Where a
                    # rename was followed to get here, the detail says so and names the old one.
                    Path   = $nowPath
                    # NO BACKTICKS IN A DOUBLE-QUOTED STRING: PowerShell reads one as an escape, so a
                    # markdown-style quote around the command name would be swallowed silently and the
                    # reader would never know the sentence had been edited by the parser.
                    Detail = ("its worktree change ('$($was.Worktree)') is gone while the path is still listed -- what a 'git checkout -- <path>' leaves behind" +
                              $(if ($nowPath -ne $path) { " (renamed from '$path' inside the window, and the loss is on this side of the rename)" } else { '' }))
                }
            }
        }
    }

    # --- The stash ---------------------------------------------------------------------------------
    if ($Before.StashKnown -and $After.StashKnown) {
        $present = @{}
        foreach ($id in @($After.Stash)) { if ($id) { $present[[string]$id] = $true } }
        foreach ($id in @($Before.Stash)) {
            if ($id -and -not $present.ContainsKey([string]$id)) {
                $findings += [pscustomobject]@{
                    Kind   = 'StashGone'
                    Path   = ''
                    Detail = "stash entry $id was present at the baseline and is gone"
                }
            }
        }
    }

    return $findings
}

function Format-WorkingCopyShrinkage {
    <#
        The findings as report lines, in the [OK]/[ALARM]/[INFO] shape the rest of this repo's checks
        print. Returns an array of strings; the caller decides where they go and what the exit code is.

        WHY THE PATHS ARE NAMED HERE AND ARE COUNTS-ONLY IN park-lib.ps1. That function's figure ends up
        in a park COMMIT on a public branch, where listing paths would leak the shape of unrelated work.
        This one is read by the session that owns the working copy, in its own terminal, and the whole
        value of the finding is WHICH file lost its edit -- a count would tell that session it lost
        something and leave it to guess what.
    #>
    param(
        [AllowNull()][AllowEmptyCollection()][object[]]$Findings
    )

    $f = @($Findings | Where-Object { $_ })
    if ($f.Count -eq 0) {
        return @('[OK] nothing shrank: every path and stash entry the baseline held is still accounted for.')
    }

    $lines = @()
    foreach ($kind in @('Vanished', 'WorktreeCleared', 'StashGone')) {
        foreach ($item in @($f | Where-Object { $_.Kind -eq $kind })) {
            $subject = if ($item.Path) { $item.Path } else { '(working copy)' }
            $lines += "[ALARM] $subject -- $($item.Detail)"
        }
    }
    foreach ($item in @($f | Where-Object { $_.Kind -eq 'BranchChanged' -or $_.Kind -eq 'HistoryRewritten' })) {
        $lines += "[INFO] not comparable: $($item.Detail)"
    }
    foreach ($item in @($f | Where-Object { $_.Kind -eq 'NotMeasured' })) {
        $lines += "[INFO] not measured: $($item.Detail)"
    }
    return $lines
}
