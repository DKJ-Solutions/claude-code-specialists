<#
.SYNOPSIS
    Read `git worktree list --porcelain` -- who holds which branch, and which tree is the primary one.

.DESCRIPTION
    Dot-source this file from a script in scripts/release/ or scripts/task/:

        . (Join-Path $PSScriptRoot '..\lib\worktree-lib.ps1')

    Supplies the four pure functions below. None of them runs git -- the caller passes the lines
    `git worktree list --porcelain` produced, so every one of them is testable, which is the whole
    reason this file exists rather than a fourth inline parse.

    WHY IT EXISTS AT ALL (issue #1069, August 29, 2026). git allows exactly ONE worktree per branch, so
    a tree standing on `main` takes a lock that is global to the clone: from that moment no other
    worktree can check `main` out. ship-pr.ps1's step 5 checks `main` out in whatever tree it runs in --
    correct, that is where it folds -- and then leaves it there. In the primary checkout that is
    harmless and deliberate, because the trunk is where a finished chain belongs. In a LANE it means the
    lane holds the trunk hostage for every later chain on the machine, and the cost is paid by an
    unrelated branch, later, AFTER its merge has already landed: the PR is merged, CHANGELOG.md is
    unfolded and the development document is still on the trunk. That is the one silent half-state
    fold-changelog-entry.ps1's own -Push comment exists to prevent.

    THE PARSE WAS ALREADY WRITTEN TWICE BEFORE THIS FILE, which is the second reason. worktree-lane.ps1
    reads the porcelain to find the primary checkout, ship-pr.ps1's Remove-ShipFoldWorktree reads it to
    ask whether a worktree it just tried to remove is still registered -- and both had to solve the same
    path-comparison problem separately (see Get-WorktreePathKey). A third copy was owed by this repair;
    a lib is what it got instead.

    AND ship-pr.ps1's OWN HEADER ASKED FOR THIS: "anything in here that is a pure function of text
    belongs in a lib, precisely because this file cannot be tested". ship-pr drives live git and gh
    against a real remote and carries no suite; the decision this repair turns on -- does another tree
    hold the trunk? -- is a pure function of the porcelain, so it is tested in
    scripts/tests/worktree-lib.tests.ps1 rather than only exercised by a full live ship.

    Pure ASCII (repo convention for .ps1).
#>

# THE COMPARISON KEY, and it is not decoration. Three things make two spellings of the same directory
# compare unequal on Windows, and all three have been measured in this repo:
#   - the separator: git reports forward slashes on Windows, PowerShell composes back slashes;
#   - case: NTFS is case-insensitive, so 'C:\Users' and 'c:\users' are the same directory;
#   - a trailing separator, which Join-Path and a hand-typed path disagree about.
# The 8.3-short-name problem is NOT solved here and cannot be: only the filesystem knows that
# C:\Users\DAVEKO~1 and C:\Users\davekokbwj are one directory, and this function takes a string. A
# caller that composes a path itself resolves it while the directory certainly exists (ship-pr does
# exactly that for its throwaway worktree) and passes the resolved spelling in.
function Get-WorktreePathKey {
    param([string]$Path)
    if (-not $Path) { return '' }
    return $Path.Trim().Replace('/', '\').TrimEnd('\').ToLowerInvariant()
}

# THE PORCELAIN, AS RECORDS. Its shape is a stanza per worktree, blank-line separated:
#
#     worktree C:/repo
#     HEAD 926bd0ca...
#     branch refs/heads/main
#
#     worktree C:/repo-lanes/feat--x
#     HEAD 979f2daa...
#     detached
#
# A stanza carries EITHER `branch` or `detached`, never both, and a bare repository carries `bare`
# instead of a HEAD at all. The `worktree` line is what opens a stanza, so it is what closes the
# previous one -- the blank line is not relied on, because a caller that trims its captured output (and
# Invoke-NativeCapture's callers do) can lose it.
#
# ORDER IS PRESERVED AND IT CARRIES MEANING: git lists the MAIN worktree first, which is the only thing
# in the output that identifies it. Get-PrimaryWorktreePath below is that fact, named.
function Get-WorktreeRecords {
    param([string[]]$PorcelainLines)
    $records = @()
    $current = $null
    foreach ($line in @($PorcelainLines)) {
        $text = "$line".Trim()
        if ($text -match '^worktree\s+(.+)$') {
            if ($current) { $records += $current }
            $current = [pscustomobject]@{
                Path     = $Matches[1].Trim()
                Branch   = ''
                Detached = $false
                Bare     = $false
            }
            continue
        }
        if (-not $current) { continue }
        if ($text -match '^branch\s+(.+)$') {
            # Stored SHORT ('main'), not as refs/heads/main: every caller here asks about a branch by the
            # name a person types. The full ref is what git prints and the only place the distinction
            # matters, so it is stripped once, here.
            $current.Branch = ($Matches[1].Trim() -replace '^refs/heads/', '')
            continue
        }
        if ($text -eq 'detached') { $current.Detached = $true; continue }
        if ($text -eq 'bare')     { $current.Bare = $true; continue }
    }
    if ($current) { $records += $current }
    return @($records)
}

# git lists the main worktree first. That is the whole definition -- there is no flag on the stanza
# saying so, and no other way to tell from the porcelain alone.
function Get-PrimaryWorktreePath {
    param([string[]]$PorcelainLines)
    $records = Get-WorktreeRecords -PorcelainLines $PorcelainLines
    if ($records.Count -eq 0) { return '' }
    return $records[0].Path
}

# THE QUESTION THAT MATTERS: is $Branch checked out somewhere OTHER than the tree I am standing in?
# Returns that worktree's path as git spells it (so a message can name a directory the reader can
# paste), or '' when the answer is no.
#
# -SelfPath IS NOT OPTIONAL IN PRACTICE and the reason is worth stating: the tree asking the question is
# itself in the list, so without excluding it a checkout ALREADY standing on main would report itself as
# the blocker and refuse a run that was never in danger. It is compared through Get-WorktreePathKey
# above rather than with -eq, for the three reasons stated there.
function Get-WorktreeHoldingBranch {
    param(
        [string[]]$PorcelainLines,
        [Parameter(Mandatory = $true)][string]$Branch,
        [string]$SelfPath
    )
    $selfKey = Get-WorktreePathKey $SelfPath
    foreach ($record in (Get-WorktreeRecords -PorcelainLines $PorcelainLines)) {
        if ($record.Branch -ne $Branch) { continue }
        if ($selfKey -and (Get-WorktreePathKey $record.Path) -eq $selfKey) { continue }
        return $record.Path
    }
    return ''
}
