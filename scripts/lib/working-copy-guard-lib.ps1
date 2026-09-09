<#
.SYNOPSIS
    The judgement behind the working-copy guard: does this command string mutate the working tree, the
    index or a ref -- and which part of it does.

.DESCRIPTION
    Dot-source this file from a hook or a script:

        . (Join-Path $PSScriptRoot '..\lib\working-copy-guard-lib.ps1')

    Supplies Get-WorkingCopyViolation (the whole judgement, pure) and the pieces under it --
    Get-GitInvocation, Test-HasFlag, Remove-TokenQuotes. It dot-sources command-guard-lib.ps1 from its
    own directory for the false-positive machinery.

    WHY THE JUDGEMENT IS SPLIT OFF FROM THE HOOK (issue #1669). Same reason fanout-lib.ps1 states for
    its own split: the judgement can then be tested, and MEASURED, without a payload and a process per
    case. #1669 does not merely ask for a guard, it asks for the guard to arrive with a measured
    false-positive rate -- the standard guard-live-theme.ps1 set for this repo. That measurement runs a
    real corpus of thousands of commands through the decision, and it has to be the SAME decision the
    hook makes rather than a second copy of it in a measuring script.

    IT KNOWS ABOUT GIT, AND command-guard-lib DELIBERATELY DOES NOT. The machinery there is generic --
    heredocs, here-strings, segments, wrappers -- and is meant to serve any command guard, including
    dkj-subagents-shopify's, which is about a completely different CLI. Git belongs on this side of that
    line.

    THE CLASS IS ONE CLASS, which is #1669's own correction to #1665. #1665 measured `git stash`
    followed by `git checkout HEAD -- <path>`, so a guard written against that pair reads as
    sufficient. #1669's comment records a later occurrence that a pair-shaped guard would have passed:
    a bare `git checkout <branch>` discards nothing by itself and is the same violation, because it
    carries uncommitted work onto another branch or refuses in the middle of somebody else's work. So
    checkout, switch, restore, reset, stash, clean and the ref mutations are judged together.

    THE READ-ONLY SIBLINGS ARE NAMED, not left to a whole-verb rule: `git stash list`, `git stash
    show`, `git branch` as a listing, `git tag` as a listing, `git clean -n` and reading the reflog all
    share a verb with a destructive form and destroy nothing.

    WHAT IT JUDGES A VIOLATION:

      always                 checkout, switch, restore, reset, rebase, merge, pull, cherry-pick,
                             revert, am, update-ref
      unless read-only       stash (list/show open), clean (-n/--dry-run open),
                             branch (only -d/-D/-f/--force/-m/-M/-c/-C), tag (only -d/-f/--force),
                             reflog (only expire/delete)

    AND WHAT IT DELIBERATELY DOES NOT: `git worktree add` and `git worktree remove`, because the
    working-copy-boundary block explicitly permits a second checkout outside the repo; every
    diff/show/log/status/ls-files/rev-parse read, which is how a reviewer does its job; and
    commit/add/push, which belong to a different block (no-commit-push-pr) and do not discard.

    RESIDUAL LIMITS, STATED RATHER THAN HIDDEN:
      - a script FILE ('bash ./do.sh') is not read, so a git command inside it is not seen;
      - '-EncodedCommand' is not decoded;
      - a text tool asked to execute ('perl -e' with a system() call) is not caught;
      - `git gc --prune=now` and `git prune` can destroy objects a bad reset left unreachable, and are
        NOT judged: the boundary block does not name them, and this enforces that block rather than
        inventing rules beside it;
      - `git fetch` mutates remote-tracking refs and is not judged either, for the same reason and
        because it is how a reviewer reads the remote at all.
    Each is a deliberate trade in the same direction as guard-live-theme's own residual: the vector
    needs somebody to go out of their way, while the false positives the alternative causes happen in
    ordinary work every time a repo documents its own safety rules.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
    Tested by scripts/tests/working-copy-guard-lib.tests.ps1 -- change one, run the other.
#>

# Unconditional and unguarded, like fanout-lib's own sibling loads: this file is never reached except
# through a dot-source from a caller that already resolved a root, and the sibling travels with it in
# the same mirror.
. (Join-Path $PSScriptRoot 'command-guard-lib.ps1')

# Text and file-write commands that cannot themselves invoke git. NOTE WHAT IS ABSENT: `git` is in
# guard-live-theme's equivalent list, because there a segment led by git is handling text -- here git
# is the subject, and exempting it would exempt everything this guard exists for. `perl` is absent
# too: it is an interpreter, and `perl -e` with a system() call is a stated residual limit rather than
# an exemption.
$script:WcTextTools = @(
    'grep', 'egrep', 'fgrep', 'rg', 'sed', 'awk', 'cat', 'echo', 'printf', 'head', 'tail',
    'less', 'more', 'jq', 'findstr', 'tee', 'diff', 'wc', 'sort', 'uniq', 'tr', 'cut',
    'out-file', 'set-content', 'add-content', 'get-content', 'select-string', 'tee-object',
    'write-output', 'write-host', 'out-string'
)

# Subcommands that mutate the tree, the index or HEAD in every form they have.
$script:WcAlways = @{
    'checkout'    = 'moves this working copy or its HEAD'
    'switch'      = 'moves this working copy to another branch'
    'restore'     = 'overwrites files in this working copy from another state'
    'reset'       = 'moves HEAD or the index, discarding what was staged'
    'rebase'      = 'rewrites this branch and moves the tree with it'
    'merge'       = 'moves HEAD and writes into this working copy'
    'pull'        = 'is a fetch plus a merge, so it moves HEAD and the tree'
    'cherry-pick' = 'writes somebody else''s commit into this working copy'
    'revert'      = 'writes an inverse commit into this working copy'
    'am'          = 'applies a patch series into this working copy'
    'update-ref'  = 'moves a ref directly, destroying whatever was only reachable through it'
}

# git's own global options, which sit BEFORE the subcommand. These take a separate value, so the token
# after them is not the subcommand either.
$script:WcGlobalWithValue = @('-c', '-C', '--git-dir', '--work-tree', '--namespace', '--exec-path', '--super-prefix', '--config-env')

function Remove-TokenQuotes {
    <# A token keeps its quotes through tokenisation, because a quoted run has to stay one token. They
       come off before a token is COMPARED, so a quoted '-d' is still a delete flag. #>
    param([string]$Token)
    $t = [string]$Token
    if ($t.Length -ge 2) {
        $q = $t[0]
        if (($q -eq '"' -or $q -eq "'") -and $t[$t.Length - 1] -eq $q) { return $t.Substring(1, $t.Length - 2) }
    }
    return $t
}

function Get-GitInvocation {
    <# Split a segment led by git into its subcommand and the arguments after it, skipping git's own
       global options. Returns $null when the segment is not a git invocation at all. #>
    param([string]$Segment)

    $s = ([string]$Segment).Trim()
    while ($s -match '^\(?\{?\s*[A-Za-z_][A-Za-z0-9_]*=[^\s]*\s+(.*)$') { $s = $Matches[1].Trim() }
    $s = $s -replace '^[\(\{\s]+', ''

    # Tokenise on whitespace, keeping quoted runs together so a quoted pathspec cannot look like a flag.
    $tokens = @([regex]::Matches($s, '"[^"]*"|''[^'']*''|\S+') | ForEach-Object { $_.Value })
    if ($tokens.Count -eq 0) { return $null }

    $lead = ($tokens[0] -replace '.*[\\/]', '').ToLower()
    if ($lead -ne 'git' -and $lead -ne 'git.exe') { return $null }

    $i = 1
    while ($i -lt $tokens.Count) {
        $t = $tokens[$i]
        if ($t -notmatch '^-') { break }
        $bare = ($t -split '=')[0].ToLower()
        if ($script:WcGlobalWithValue -contains $bare -and $t -notmatch '=') { $i += 2 } else { $i += 1 }
    }
    if ($i -ge $tokens.Count) { return $null }

    # THE RANGE IS GUARDED rather than written as $tokens[($i+1)..($tokens.Count-1)]. With no arguments
    # after the subcommand that range counts DOWN -- 2..1 -- and hands the tokens back reversed with a
    # $null in front. `git stash` and `git clean` both take that path, and both happened to reach the
    # right verdict through it, which is the kind of luck a later edit spends.
    $rest = @()
    if ($i + 1 -le $tokens.Count - 1) { $rest = @($tokens[($i + 1)..($tokens.Count - 1)]) }

    return @{
        Sub  = (Remove-TokenQuotes $tokens[$i]).ToLower()
        Args = @($rest | ForEach-Object { Remove-TokenQuotes $_ })
    }
}

function Test-HasFlag {
    <# Case-SENSITIVE on purpose: -d and -D are different flags, and so are -m/-M and -c/-C. #>
    param([string[]]$Arguments, [string[]]$Flags)

    foreach ($a in $Arguments) {
        $bare = ($a -split '=')[0]
        foreach ($f in $Flags) { if ($bare -ceq $f) { return $true } }
        # Bundled short flags: `git clean -nd` carries -n, and `git branch -Dr` carries -D.
        if ($bare -cmatch '^-[A-Za-z]{2,}$') {
            foreach ($f in $Flags) {
                if ($f -cmatch '^-[A-Za-z]$' -and $bare.Substring(1).Contains($f.Substring(1))) { return $true }
            }
        }
    }
    return $false
}

function Resolve-GuardPath {
    <# Full path without touching the filesystem: the path may not exist, and a guard must not stat
       anything a caller handed it. Returns '' when it cannot be resolved at all. #>
    param([string]$Path, [string]$Base)

    $p = (Remove-TokenQuotes ([string]$Path)).Trim()
    if (-not $p) { return '' }
    try {
        if (-not [System.IO.Path]::IsPathRooted($p) -and $Base) { $p = Join-Path $Base $p }
        return ([System.IO.Path]::GetFullPath($p)).TrimEnd('\', '/')
    } catch { return '' }
}

function Test-PathUnder {
    <# Is $Path the same as, or under, $Root? Case-insensitive and separator-insensitive, because a
       Windows command line spells the same directory four ways. #>
    param([string]$Path, [string]$Root)

    if (-not $Path -or -not $Root) { return $false }
    $a = $Path.Replace('/', '\').TrimEnd('\')
    $b = $Root.Replace('/', '\').TrimEnd('\')
    if ($a -ieq $b) { return $true }
    return $a.StartsWith($b + '\', [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-PathInside {
    <#
    .SYNOPSIS
        Is this path part of the DISPATCHING SESSION'S checkout -- the thing this guard protects?

    .DESCRIPTION
        Under the project root, with one carve-out.

        A DISPATCHED AGENT'S OWN WORKTREE IS NOT THE DISPATCHING SESSION'S CHECKOUT, even though the
        harness puts it inside the repo. `.claude/worktrees/agent-<id>` is where an agent granted
        worktree isolation works, and this repo's own .gitignore records that the location is the
        harness's choice rather than anything the repo picked -- there is no seam that would move it
        outside the tree the way worktree-lane.ps1 places a lane in a sibling '<repo>-lanes/'
        directory.

        So a plain "under the root" test would refuse an isolated agent every command inside its own
        tree, which is the one place it is entitled to run all of them. That is not a rate to accept:
        it would break the harness feature whose entire purpose is to make this hazard impossible.

        THE LANE DIRECTORY NEEDS NO CARVE-OUT for the mirror-image reason: a lane worktree is a
        SIBLING of the repo, so it is already outside the root and the ordinary rule covers it.
    #>
    param([string]$Path, [string]$Root)

    if (-not (Test-PathUnder -Path $Path -Root $Root)) { return $false }
    if (Test-PathUnder -Path $Path -Root (Join-Path $Root '.claude\worktrees')) { return $false }
    return $true
}

function Test-CommandLeavesProject {
    <#
    .SYNOPSIS
        Does this whole command work in a repo that is NOT the dispatching session's checkout?

    .DESCRIPTION
        THE MEASURED FALSE POSITIVE THIS ANSWERS (issue #1669, September 9, 2026). Run over the 995
        Bash/PowerShell calls this repo's dispatched subagents have actually made, the judgement
        refused 12. Eleven were real crossings of the boundary -- including both commands #1665
        measured and the `git checkout` #1669's own comment records. The twelfth was

            cd /tmp/grtest2 && git log --oneline
            git checkout $(git rev-parse HEAD)

        a test engineer working in its own throwaway FIXTURE repo, which cannot discard anybody's
        work. That is not a concession to a rate, it is the guard's actual scope: the subject is the
        dispatching session's checkout, and a git command aimed at another repo is out of scope by
        construction. This repo makes the class recurrent rather than incidental -- it ships
        scripts/lib/fixture-git-lib.ps1, so building a fixture repo is routine work here.

        IT CANNOT BE USED AS A BYPASS, and that is what the second half of the rule is for. A command
        that steps out and then steps BACK IN is not exempt: every `cd` target is resolved, and one
        landing inside the project (or a path that cannot be resolved at all) settles it as inside. So
        `cd /tmp && cd <project> && git reset --hard` is judged, and so is anything whose directory
        this file cannot work out -- failing towards checking, the same direction as everything else
        in this pair of libs.

        A git invocation's OWN `-C` / `--work-tree` / `--git-dir` is stronger than any of this and is
        read per invocation by the caller, so `cd /tmp && git -C <project> checkout main` is judged
        too.
    #>
    param([string]$Command, [string]$ProjectRoot, [string]$Cwd = '')

    if (-not $ProjectRoot) { return $false }

    $root = Resolve-GuardPath -Path $ProjectRoot -Base ''
    if (-not $root) { return $false }

    # WHERE THE COMMAND STARTS, which is the tool's own working directory rather than the project
    # root. The two differ in exactly the case that matters: an agent granted worktree isolation runs
    # with its cwd already inside .claude/worktrees/agent-<id>, and a command there carries no `cd` to
    # give the game away. Starting from the root instead would refuse that agent every command in the
    # one tree it owns outright.
    $start = if ($Cwd) { Resolve-GuardPath -Path $Cwd -Base '' } else { $root }
    if (-not $start) { $start = $root }

    $targets = New-Object System.Collections.Generic.List[string]
    foreach ($segment in (Split-CommandSegments $Command)) {
        $s = $segment.Trim()
        if (-not $s) { continue }
        $m = [regex]::Match($s, '^\s*(?:cd|chdir|set-location|sl|pushd)\s+(?:-LiteralPath\s+|-Path\s+)?("[^"]*"|''[^'']*''|[^\s;|&]+)')
        if ($m.Success) { $targets.Add($m.Groups[1].Value) }
    }

    # No `cd` at all: the answer is wherever the tool was already standing.
    if ($targets.Count -eq 0) { return (-not (Test-PathInside -Path $start -Root $root)) }

    foreach ($t in $targets) {
        $full = Resolve-GuardPath -Path $t -Base $start
        # An unresolvable target is treated as inside: a guard must not exempt what it cannot read.
        if (-not $full) { return $false }
        if (Test-PathInside -Path $full -Root $root) { return $false }
    }
    return $true
}

function Get-InvocationTargetDirection {
    <# Where does THIS git invocation point, if it says so itself? Returns 'inside', 'outside' or ''
       (it did not say). Read from -C / --work-tree / --git-dir, which override any `cd`. #>
    param([hashtable]$Invocation, [string]$Segment, [string]$ProjectRoot, [string]$Cwd = '')

    if (-not $ProjectRoot) { return '' }
    $root = Resolve-GuardPath -Path $ProjectRoot -Base ''
    if (-not $root) { return '' }

    $m = [regex]::Match($Segment, '(?:^|\s)(?:-C\s+|--work-tree(?:=|\s+)|--git-dir(?:=|\s+))("[^"]*"|''[^'']*''|[^\s;|&]+)')
    if (-not $m.Success) { return '' }

    $full = Resolve-GuardPath -Path $m.Groups[1].Value -Base $root
    if (-not $full) { return 'inside' }
    # A --git-dir of '<project>\.git' is the project; Test-PathInside answers that without a special case.
    if (Test-PathInside -Path $full -Root $root) { return 'inside' }
    return 'outside'
}

function Get-WorkingCopyViolation {
    <#
    .SYNOPSIS
        The judgement. Returns $null when nothing in this command mutates the working copy, or
        @{ Sub; Reason; Segment } for the first thing that does.

    .DESCRIPTION
        Pure: it reads a string and returns a verdict. It does NOT decide whether the caller is
        allowed to run it -- that gate is agent_id, and it belongs to the hook.

        IT MATCHES THE SUBCOMMAND POSITION, WHICH IS THE STRONGER ANSWER to the false-positive lesson
        guard-live-theme.ps1 records. Where that guard matches its patterns anywhere in a segment, this
        reads the segment's leading command and then git's own subcommand. That is what lets

            git commit -m "the reviewer must never run git checkout HEAD -- <path>"

        through, and no heredoc or text-tool exemption would have saved it: the segment IS led by git.
        A guard that cannot describe its own rule in a commit message is one somebody switches off.

        -ProjectRoot IS OPTIONAL AND OMITTING IT JUDGES EVERYTHING. It is what makes "this command
        works in a fixture repo somewhere else" answerable, and with no root there is no question to
        answer -- so the whole directory rule is skipped and every git invocation is judged, which is
        the failing-towards-checking direction. See Test-CommandLeavesProject.
    #>
    param([string]$Command, [string]$ProjectRoot = '', [string]$Cwd = '')

    if (-not $Command) { return $null }

    $leavesProject = Test-CommandLeavesProject -Command $Command -ProjectRoot $ProjectRoot -Cwd $Cwd

    # THE ONE PLACE THIS MATCHES ANYWHERE RATHER THAN IN SUBCOMMAND POSITION, and the narrow condition
    # is what makes it affordable. `echo "git stash" | bash` really does run git stash, and no segment
    # of it is LED by git -- so the subcommand rule, which is what keeps this guard quiet, cannot see
    # it. Test-CommandExecutesText is already computed by the machinery for its own reasons (it is what
    # switches the heredoc and text-tool exemptions off), so when it is true the guard has been told,
    # by the command itself, that text somewhere in here is about to be executed. Only then does the
    # whole string become fair game.
    #
    # MEASURED BEFORE IT WAS KEPT, and the number is zero: across all 9084 Bash/PowerShell calls in
    # this repo's transcripts -- 8089 from the main thread and 995 from dispatched subagents -- there
    # is not ONE command this rule refuses that the subcommand rule did not already refuse. So it
    # closes a real hole at no measured cost. It stays narrow anyway, gated on that flag rather than
    # applied generally, because a match-anywhere rule is exactly what guard-live-theme's first
    # version was and its header records what that cost.
    if ((Test-CommandExecutesText $Command) -and (-not $leavesProject)) {
        $verbs = (@($script:WcAlways.Keys) + @('stash', 'clean')) -join '|'
        $m = [regex]::Match($Command, "(?i)\bgit\s+($verbs)\b")
        if ($m.Success) {
            $sub = $m.Groups[1].Value.ToLower()
            return @{
                Sub = $sub; Segment = $m.Value
                Reason = "``git $sub`` sits inside text this command pipes into an interpreter, so it runs -- and this checkout is not a dispatched subagent's to move."
            }
        }
    }

    foreach ($segment in (Get-GuardSegments -Command $Command -TextTools $script:WcTextTools)) {
        $git = Get-GitInvocation $segment
        if ($null -eq $git) { continue }

        # The invocation's own -C / --work-tree / --git-dir outranks any `cd`, in both directions.
        $direction = Get-InvocationTargetDirection -Invocation $git -Segment $segment -ProjectRoot $ProjectRoot -Cwd $Cwd
        if ($direction -eq 'outside') { continue }
        if ($direction -ne 'inside' -and $leavesProject) { continue }

        if ($script:WcAlways.ContainsKey($git.Sub)) {
            return @{ Sub = $git.Sub; Segment = $segment; Reason = "``git $($git.Sub)`` $($script:WcAlways[$git.Sub]), and is never a dispatched subagent's to run." }
        }

        $first = if ($git.Args.Count -gt 0) { ([string]$git.Args[0]).ToLower() } else { '' }

        switch ($git.Sub) {
            'stash' {
                # A bare `git stash` IS `git stash push`, which is why the empty case is a violation and
                # not an exemption: that is the exact command #1665 measured.
                if ($first -ne 'list' -and $first -ne 'show') {
                    return @{ Sub = 'stash'; Segment = $segment; Reason = "``git stash`` puts the dispatching session's uncommitted work away, where a clean ``git status`` then hides it. ``git stash list`` and ``git stash show`` are not blocked." }
                }
            }
            'clean' {
                if (-not (Test-HasFlag -Arguments $git.Args -Flags @('-n', '--dry-run'))) {
                    return @{ Sub = 'clean'; Segment = $segment; Reason = "``git clean`` deletes untracked files outright, and there is no reflog for those. ``git clean -n`` is not blocked." }
                }
            }
            'branch' {
                if (Test-HasFlag -Arguments $git.Args -Flags @('-d', '-D', '--delete', '-f', '--force', '-m', '-M', '--move', '-c', '-C', '--copy')) {
                    return @{ Sub = 'branch'; Segment = $segment; Reason = "``git branch`` with a delete, force or move flag destroys work that may be reachable only through that pointer. Listing branches is not blocked." }
                }
            }
            'tag' {
                if (Test-HasFlag -Arguments $git.Args -Flags @('-d', '--delete', '-f', '--force')) {
                    return @{ Sub = 'tag'; Segment = $segment; Reason = "``git tag`` with a delete or force flag moves or removes a ref somebody's work hangs from. Listing tags is not blocked." }
                }
            }
            'reflog' {
                # The reflog is the ONLY recovery path left after a bad checkout or reset, which is why
                # expiring it counts here even though it leaves the tree alone.
                if ($first -eq 'expire' -or $first -eq 'delete') {
                    return @{ Sub = 'reflog'; Segment = $segment; Reason = "``git reflog $first`` destroys the only record by which a discarded commit could still be found. Reading the reflog is not blocked." }
                }
            }
        }
    }

    return $null
}
