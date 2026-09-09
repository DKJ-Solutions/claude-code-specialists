<#
.SYNOPSIS
    One reading of `git status --porcelain`: the command with its two flags, and the line parse.

.DESCRIPTION
    Dot-source this file from another lib in scripts/lib/, or from a script in scripts/task/:

        . (Join-Path $PSScriptRoot 'git-porcelain-lib.ps1')

    Supplies ConvertFrom-GitPorcelainLine (one line -> {Path, Index, Worktree, From}, or $null for a
    line carrying no path), Get-GitPorcelainStatus (the whole read: the command, its two flags, every
    line parsed, plus a Known flag saying whether it could be taken at all), and
    ConvertTo-GitPorcelainPath, which the first uses for each path half and which is exposed because
    lesson 4 below is entirely its business.

    WHY THIS EXISTS (issue #1682, September 9, 2026). Two libs parsed a porcelain line into a path plus
    its status halves, near-verbatim and comment for comment: park-lib.ps1's Get-GitParkBacking, which
    needs a COUNT of uncommitted files excluding a pathspec, and fanout-lib.ps1's
    Get-WorkingCopySnapshot, which needs a per-path MAP of {Index, Worktree, From}. The return shapes
    genuinely differ, so neither could reuse the other wholesale -- what was duplicated is the
    git-quirks knowledge underneath, and every piece of it was learned the hard way. fanout-lib's own
    header said "Same lesson, same reason, as Get-GitParkBacking in park-lib.ps1", which is the
    citation that stood in for this extraction.

    THE DIVERGENCE WAS ALREADY VISIBLE rather than hypothetical, which is why this is a defect and not
    tidiness. The #1670 branch had to repair the rename half of ITS copy -- a `git mv` inside the
    window read as a lost edit -- while park-lib's copy still discarded the old path. That is correct
    for a count and wrong for anything that follows a file, so the two were not in conflict yet; they
    were one requirement change away from it. This repo has extracted merged-pr-lib.ps1 and
    git-identity-lib.ps1 for exactly this shape, the first of them after the same fix landed twice in
    one day in two branches that did not know about each other.

    THE FOUR LESSONS, DOCUMENTED ONCE. The first three arrived with the two copies and every one of them
    was separately measured; the fourth is a defect the extraction itself exposed, which is the shortest
    argument for having done it. Two of the four are properties of the COMMAND rather than of the parse
    -- which is why this file owns the read as well as the line, instead of only the ConvertFrom half.
    Extracting the parse alone would have left the two flags, and the reasons for them, in both callers.

      1. --untracked-files=all, BECAUSE THE DEFAULT IS MEASURABLY WRONG FOR BOTH CALLERS. git's default
         collapses an untracked DIRECTORY to a single entry naming the directory ('?? some/dir/'). For a
         count that reports 2 uncommitted files where there is 1 (park-lib measured exactly that on the
         ordinary happy path); for a snapshot it means a subagent's `git clean` inside that directory
         removes files the snapshot never listed. Per-file still respects .gitignore, so a build
         directory does not flood the list.

      2. core.quotePath IS FORCED ON, and it is the language rule about reading a native command's
         output rather than a preference. Both callers COMPARE these paths -- park-lib against an
         excluded pathspec, fanout-lib against a second snapshot -- and PowerShell 5.1 decodes a child
         process's stdout with whatever console code page the run inherited. Quoting holds the wire to
         ASCII, where every candidate code page agrees, so a filename with an accent cannot decode into
         something that accidentally matches, or fails to match, the path it is held against. A repo may
         set core.quotepath in its own config, hence -c rather than trusting the default.

      3. THE RENAME'S OLD PATH IS RETURNED, NOT DISCARDED. A rename reads 'old -> new'. The new path is
         the one that exists on disk and is what a map keys on, but discarding the old one made an
         ordinary `git mv` during a snapshot window look exactly like a loss: the baseline's key
         disappeared, no commit carried it, and the comparison reported the edit gone while it sat
         intact under the new name. Returning both lets a caller follow the file; a caller that only
         counts simply ignores From, which is what park-lib does.

      4. A QUOTED PATH IS NOT SEPARATOR-NORMALISED, and this one was found BY the extraction rather
         than carried into it. Both copies normalised backslashes to forward slashes unconditionally,
         which rewrote lesson 2's own escapes into path segments: '"caf\303\251.txt"' read back as
         'caf/303/251.txt'. Latent in both callers -- a count still counts it and a comparison still
         matches because both readings mangle it the same way -- and the first thing that goes looking
         for the actual FILE would have found nothing. See ConvertTo-GitPorcelainPath.

    WHAT THIS FILE DELIBERATELY DOES NOT DO: DECODE THE ESCAPE. Lesson 4 stops at not destroying it. The
    correct .NET string for '"caf\303\251.txt"' is 'cafe.txt' with an accent, and the function that
    produces it ALREADY EXISTS -- Convert-GitQuotedPath in sync-rules.ps1, written for inbound #821,
    which unpacks the octal form and git's C escapes and reads the bytes as UTF-8. It is not called from
    here because the dependency would run the wrong way: a porcelain parse would then dot-source the
    Shopify sync rules. Unifying the two -- moving that decoder in here, where the quoting concern
    belongs, and having sync-rules dot-source it -- is issue #1689, and it is a different subject from
    this extraction: it touches sync-main's three call sites and three suites, and it changes what a live
    Shopify theme sync compares paths against. Neither caller here needs the decoded form: park-lib
    counts, and fanout-lib compares two readings that escape identically. The escape is preserved rather
    than mangled precisely so that unification stays possible; mangling destroyed the information.

    THE STATUS HALVES ARE KEPT APART, for fanout-lib's reason: porcelain reports 'XY path', X is the
    index and Y is the worktree, and only one of them is a loss. `git reset` moves a change from X to Y
    and destroys nothing; `git checkout -- <path>` clears Y and destroys the edit. Handing back the
    two-character code as one string would make every caller re-learn which column is which.

    IT ANSWERS $null FOR A LINE WITH NO PATH rather than an object with an empty Path, so a caller's
    loop can `continue` on the falsy result and never has to know which of the two guards fired -- a
    line too short to carry a path at all, or one whose path is empty once trimmed.

    NO CONTRACT ROW FOLLOWS. Nothing here is repo-owned: it takes lines and a repo root and returns
    paths and status characters, the same reason worktree-lib.ps1's registry entry gives.

    ITS OWN FILE RATHER THAN native-capture-lib.ps1, following park-lib's and worktree-lib's precedent:
    that file's own header says it took an imperfect fit deliberately and asks the next person not to
    widen it again. Reading `git status --porcelain` is not a capture helper.

    Pure ASCII (repo convention for .ps1).
#>

# Guarded, on fanout-lib's precedent: dot-sourcing twice is harmless, and a tree whose mirror predates
# this lib must not crash on load.
$gpCaptureLib = Join-Path $PSScriptRoot 'native-capture-lib.ps1'
if (Test-Path -LiteralPath $gpCaptureLib -PathType Leaf) { . $gpCaptureLib }

function ConvertTo-GitPorcelainPath {
    <#
        One path half of a porcelain line -- the whole path, or one side of a rename's arrow -- with its
        quotes off and its separators settled. Empty string where there is no path.

        A QUOTED PATH IS RETURNED BYTE FOR BYTE, MINUS THE QUOTES, AND THAT IS LESSON 4 (found by this
        extraction, September 9, 2026). Both original copies ran `-replace '\\', '/'` over every path
        unconditionally, and that is wrong for exactly the paths core.quotePath exists to produce: git
        quotes a path precisely WHEN it has to escape something in it, and inside those quotes a byte
        outside ASCII is printed as a backslash-octal escape. So the normalisation rewrote git's own
        escapes into path segments -- '"caf\303\251.txt"' came back as 'caf/303/251.txt', a path with
        two directories in it that exists nowhere.

        It was latent rather than live in both callers, which is why it survived two implementations: a
        count still counts the mangled entry, and a comparison still matches because both snapshots
        mangle it identically. What it would break is anything that takes one of these paths and goes
        looking for the FILE -- and the near miss is real, because park-lib compares its paths against
        an exclusion the caller supplies.

        AN UNQUOTED PATH IS STILL SEPARATOR-NORMALISED, which is what the normalisation was always for.
        git reports forward slashes and never uses a backslash as a separator, so this cannot be
        repairing git's side; it exists so a CALLER holding a Windows-shaped path can compare against
        what comes back without remembering to normalise first. park-lib's exclusion map depends on it.

        THE ESCAPE IS PRESERVED, NOT DECODED, and the file header says why: Convert-GitQuotedPath in
        sync-rules.ps1 already decodes it, calling it from here would point the dependency the wrong
        way, and unifying the two is issue #1689. Preserving it is what keeps that possible.
    #>
    param([string]$Raw)

    if ($null -eq $Raw) { return '' }
    $t = $Raw.Trim()
    if (-not $t) { return '' }
    # Both ends, because git quotes a path by wrapping the whole of it. A lone quote at one end is not
    # git's quoting and is left where it is rather than guessed at.
    if ($t.Length -ge 2 -and $t.StartsWith('"') -and $t.EndsWith('"')) {
        return $t.Substring(1, $t.Length - 2)
    }
    return ($t -replace '\\', '/')
}

function ConvertFrom-GitPorcelainLine {
    <#
        One `git status --porcelain` line as an object -- {Path, Index, Worktree, From} -- or $null
        where the line carries no path. See the file header for all three lessons; this function owns
        the third (the rename's old path) and the status-halves split.

        PATHS COME BACK FORWARD-SLASHED, on both halves. git reports forward slashes already, but a
        caller comparing against a path IT holds may have either separator, and normalising in one
        place means neither caller has to remember to.
    #>
    param([string]$Line)

    # 'XY path' -- under four characters there is no path to read, which also skips the empty line the
    # output's trailing newline produces.
    if ($null -eq $Line -or $Line.Length -lt 4) { return $null }

    $index = $Line.Substring(0, 1)
    $worktree = $Line.Substring(1, 1)
    $raw = $Line.Substring(3)

    $from = ''
    $arrow = $raw.IndexOf(' -> ')
    if ($arrow -ge 0) {
        $from = ConvertTo-GitPorcelainPath -Raw $raw.Substring(0, $arrow)
        $raw = $raw.Substring($arrow + 4)
    }
    $path = ConvertTo-GitPorcelainPath -Raw $raw
    if (-not $path) { return $null }

    return [pscustomobject]@{
        Path     = $path
        Index    = $index
        Worktree = $worktree
        From     = $from
    }
}

function Get-GitPorcelainStatus {
    <#
        What this working copy holds right now, as an object: Entries (one parsed record per changed or
        untracked path, in the order git reported them) and Known (whether the read succeeded at all).

        KNOWN IS SEPARATE FROM AN EMPTY LIST, and both callers depend on the distinction. Zero entries
        is an answer -- 'nothing outstanding' -- and handing it back for a git call that failed would
        report a clean working copy on a repo that could not be read.
    #>
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $entries = @()
    $res = Invoke-NativeCapture -FilePath 'git' -Arguments @('-c', 'core.quotePath=true', '-C', $RepoRoot, 'status', '--porcelain', '--untracked-files=all')
    if ($res.ExitCode -ne 0) {
        return [pscustomobject]@{ Entries = @(); Known = $false }
    }
    foreach ($line in (($res.Output | Out-String) -split '\r?\n')) {
        $e = ConvertFrom-GitPorcelainLine -Line $line
        if ($e) { $entries += $e }
    }
    return [pscustomobject]@{ Entries = @($entries); Known = $true }
}
