<#
.SYNOPSIS
    Read what this repo already says about how work moves through it, and write it down once.

.DESCRIPTION
    The specialists adapt to the repo they land in. That is a rule they carry in every agent def
    (agent-shared/repo-way-of-working.md), and it asks each of them to read the same handful of places
    at the start of every session: the contribution guide, the CI workflows, the PR template, the branch
    names, the commit subjects, the scripts the repo already has. This script does that reading once and
    records the answer, so a specialist arrives at an answer instead of re-deriving one.

    IT NAMES WHAT THE REPO DOES NOT SAY, and that half is the point. The shared rule is explicit about
    it -- "where the repo is genuinely silent, say that it is silent and pick the most conventional
    option for its stack; never import a convention from elsewhere and present it as the standard". A
    discovery that only reported findings would quietly turn every gap into an invitation to fill it
    with somebody else's habit, which is the exact failure the default workflow exists to prevent. So
    every question this script asks has three possible answers: an observation with its evidence, or
    SILENT, and never a guess.

    NEVER OVERWRITES (Dave, August 9, 2026). If the document already exists it is left exactly as it is
    and the run prints what it WOULD have changed. Same rule specialists-init follows: strictly
    additive, because a person may have corrected or extended it, and a script that refreshes its own
    output cannot tell an improvement from staleness. Delete the file and re-run to regenerate.

    WRITES INSIDE THE SEAM (.claude/specialists/), so the teardown needs to know nothing about it: that
    skill removes the seam directory as a whole and already spares what the owner filled in. One
    footprint, and adoption stays reversible without a second rule.

    Read-only against the repo itself: it runs git queries and reads files, and the single file it
    writes is its own output.

    Pure ASCII (repo convention for .ps1).

.PARAMETER ConsumerRoot
    The repo to read. Defaults to CLAUDE_PROJECT_DIR, then the git root. A test points it at a fixture.

.PARAMETER OutputPath
    Where to write, absolute or relative to the consumer root. Defaults to the seam.
#>

[CmdletBinding()]
param(
    [string]$ConsumerRoot = '',
    [string]$OutputPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-GitRootHere {
    <# The git root of wherever this is running, or '' when there is none.

       A FUNCTION WITH ITS OWN $ErrorActionPreference, not a one-liner, and the repo has a test that
       insists on it: in Windows PowerShell 5.1 a native command's stderr redirect wraps each line in a
       NativeCommandError and sets $? to false even when the exe returned 0, so under the script-wide
       'Stop' this would abort on any repo where `git rev-parse` has something to say. The guard is
       repo-wide (shared-scripts.tests.ps1) precisely because the bare form reads harmless. #>
    # THE try/catch COVERS A DIFFERENT FAILURE FROM THE 'Continue' ABOVE IT, and the pair is not
    # redundant (Victor, August 9, 2026). 'Continue' handles git RUNNING and writing to stderr; it does
    # nothing about git not being on the machine at all, which raises a genuine CommandNotFound that the
    # script-wide 'Stop' turns terminating. Invoke-Git already says "no commits, no remote, or no git at
    # all is a repo this still describes" -- this function is reached before that one and made that
    # sentence false for the last of the three.
    $ErrorActionPreference = 'Continue'
    try {
        $root = & git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $root) { return '' }
        return ([string]$root).Trim()
    } catch { return '' }
}

if (-not $ConsumerRoot) {
    $ConsumerRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-GitRootHere }
}
if (-not $ConsumerRoot -or -not (Test-Path -LiteralPath $ConsumerRoot -PathType Container)) {
    Write-Error "discover-workflow cannot run -- no repo root. Pass -ConsumerRoot, or run it from inside a git repository."
    exit 1
}
$ConsumerRoot = (Resolve-Path -LiteralPath $ConsumerRoot).Path

# The seam directory, from the one source that owns it, so this writer cannot drift from the teardown
# that removes it. $PSScriptRoot-relative: the lib travels in this same plugin payload.
# Guarded rather than assumed -- if the lib is ever absent the script must say so, not invent a path
# that nothing else agrees on.
$reportLib = Join-Path $PSScriptRoot '..\..\scripts\lib\check-report-lib.ps1'
if (-not (Test-Path -LiteralPath $reportLib)) {
    Write-Error "discover-workflow cannot run -- the shared seam helper is missing next to it ($reportLib). Update the plugin."
    exit 1
}
. $reportLib

$SILENT = 'SILENT'

function Invoke-Git {
    <# A git query against the consumer, returning its lines, or @() when git says nothing or fails.
       Never throws: a repo with no commits, no remote, or no git at all is a repo this still describes. #>
    param([string[]]$GitArgs)
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & git -C $ConsumerRoot @GitArgs 2>$null
        if ($LASTEXITCODE -ne 0) { return @() }
        return @($out | Where-Object { $_ })
    } catch { return @() } finally { $ErrorActionPreference = $prev }
}

function Get-RelIfExists {
    <# A repo-relative path when the file is there, otherwise $null. #>
    param([string]$Rel)
    if (Test-Path -LiteralPath (Join-Path $ConsumerRoot $Rel)) { return $Rel }
    return $null
}

# --- The questions -----------------------------------------------------------------------------------
# Each returns @{ Answer; Evidence }. Answer is $SILENT when the repo does not say.

function Find-BranchConvention {
    # BRANCH NAMES ONLY, and that restriction is the finding rather than a limitation. The first version
    # of this also mined commit subjects, on the reasoning that a repo which deletes branches after
    # merging keeps the names nowhere else. Measured against this repo, it reported `plugins/`,
    # `releases/`, `branch/` and `templates/` as branch prefixes -- every one of them a directory path
    # quoted in a commit message. A '<word>/' token in prose is not evidence of a branch, and no
    # sharpening of the pattern can tell the two apart reliably, because they are the same shape.
    #
    # So: refs are evidence, prose is not. A repo whose branches are all deleted answers SILENT here,
    # which is correct -- it means a specialist has to ask rather than infer, and that is the whole
    # posture this workflow exists to hold.
    $names = @(Invoke-Git @('branch', '--all', '--format=%(refname:short)'))
    $prefixes = @{}
    foreach ($n in $names) {
        $leaf = ([string]$n) -replace '^origin/', ''
        if ($leaf -match '^([a-z][a-z0-9-]{1,14})/\S') {
            $p = $Matches[1]
            if (-not $prefixes.ContainsKey($p)) { $prefixes[$p] = 0 }
            $prefixes[$p]++
        }
    }
    if ($prefixes.Count -eq 0) {
        if ($names.Count -le 1) {
            return @{ Answer = $SILENT; Evidence = 'only the trunk exists right now -- no branch to read a convention from' }
        }
        return @{ Answer = 'no prefix convention -- branches are named freely'; Evidence = "$($names.Count) branch name(s), none in a `"<prefix>/<name>`" shape" }
    }
    $ranked = @($prefixes.GetEnumerator() | Sort-Object -Property @{ Expression = { $_.Value }; Descending = $true }, @{ Expression = { $_.Key } })
    $top = @($ranked | Select-Object -First 8 | ForEach-Object { "$($_.Key)/ ($($_.Value))" })
    return @{ Answer = ($top -join ', '); Evidence = "read from $($names.Count) branch name(s); commit subjects are deliberately NOT mined -- a `"word/`" in prose is a path as often as a branch" }
}

# THE EVIDENCE FLOOR, shared by the two readers that call something a repo-wide "style" (Victor,
# August 9, 2026). Find-BranchConvention already refused to speak on a single branch, and the other two
# had no equivalent -- so a repo with two commits got a confident verdict on how it writes commit
# subjects and how it shapes its history. Both readings might even be right; the problem is that they
# are asserted with the same confidence as one drawn from a hundred commits, in a document whose whole
# value is that a reader can trust what it states. Below the floor the honest answer is SILENT, which
# here means "not enough history to call this a convention" rather than "this repo has none".
$MIN_COMMITS_FOR_A_STYLE = 5

function Find-CommitSubjectStyle {
    $subjects = @(Invoke-Git @('log', '--format=%s', '-n', '100'))
    if ($subjects.Count -eq 0) { return @{ Answer = $SILENT; Evidence = 'no commits to read' } }
    if ($subjects.Count -lt $MIN_COMMITS_FOR_A_STYLE) {
        return @{ Answer = $SILENT; Evidence = "only $($subjects.Count) commit(s) -- too little history to call any of it a convention" }
    }
    $conventional = @($subjects | Where-Object { $_ -match '^[a-z]+(\([^)]+\))?!?:\s' }).Count
    $pct = [math]::Round(100.0 * $conventional / $subjects.Count)
    if ($pct -ge 60) {
        return @{ Answer = "conventional-commit style (`"type: subject`")"; Evidence = "$conventional of the last $($subjects.Count) subjects match, $pct%" }
    }
    if ($pct -le 10) {
        return @{ Answer = 'free-form subjects, no type prefix'; Evidence = "only $conventional of the last $($subjects.Count) subjects carry a `"type:`" prefix" }
    }
    return @{ Answer = $SILENT; Evidence = "mixed -- $conventional of the last $($subjects.Count) subjects ($pct%) carry a type prefix, too few to call a convention and too many to call its absence one" }
}

function Find-MergeStyle {
    $merges = @(Invoke-Git @('log', '--merges', '--format=%h', '-n', '60')).Count
    $all = @(Invoke-Git @('log', '--format=%h', '-n', '60')).Count
    if ($all -eq 0) { return @{ Answer = $SILENT; Evidence = 'no commits to read' } }
    # The same floor as the subject reader above, and for the sharper reason: "no merge commit yet" is
    # the normal state of a young repo that fully intends to merge, so a handful of commits is evidence
    # of nothing at all here.
    if ($all -lt $MIN_COMMITS_FOR_A_STYLE) {
        return @{ Answer = $SILENT; Evidence = "only $all commit(s) -- an absence of merges this early says nothing about how this repo lands work" }
    }
    if ($merges -eq 0) { return @{ Answer = 'linear history -- squash or rebase'; Evidence = "no merge commit in the last $all" } }
    return @{ Answer = 'merge commits'; Evidence = "$merges of the last $all commits are merges" }
}

function Find-PullRequestFlow {
    $tpl = @('.github/pull_request_template.md', '.github/PULL_REQUEST_TEMPLATE.md', 'docs/pull_request_template.md') |
        ForEach-Object { Get-RelIfExists $_ } | Where-Object { $_ } | Select-Object -First 1
    if ($tpl) { return @{ Answer = 'pull requests, with a template'; Evidence = $tpl } }
    $merges = @(Invoke-Git @('log', '--merges', '--format=%s', '-n', '60'))
    $prMerges = @($merges | Where-Object { $_ -match '#\d+' }).Count
    if ($prMerges -gt 0) { return @{ Answer = 'pull requests'; Evidence = "$prMerges recent merge subject(s) reference a numbered PR" } }
    return @{ Answer = $SILENT; Evidence = 'no PR template, and no recent merge subject references a PR number' }
}

function Find-CiGate {
    $dir = Join-Path $ConsumerRoot '.github\workflows'
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        return @{ Answer = $SILENT; Evidence = 'no .github/workflows directory' }
    }
    $files = @(Get-ChildItem -LiteralPath $dir -File | Where-Object { $_.Extension -in @('.yml', '.yaml') })
    if ($files.Count -eq 0) { return @{ Answer = $SILENT; Evidence = '.github/workflows exists but holds no workflow file' } }
    $jobs = @()
    foreach ($f in $files) {
        # The job ids, i.e. the names a required-status-check rule would refer to. Two-space indent
        # under a 'jobs:' key -- deliberately shallow parsing, because reading YAML properly is not
        # worth a dependency here and a wrong job name is more misleading than none.
        $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        $inJobs = $false
        foreach ($line in ($text -split "`r?`n")) {
            # A BLANK LINE OR A FULL-LINE COMMENT ENDS NOTHING, and skipping them is a repair rather
            # than a nicety (Victor, August 9, 2026). Both start at column 0, so the "back at top level"
            # rule below read them as the end of the jobs mapping -- and a comment between two jobs is
            # an ordinary way to divide a workflow file. Measured against a fixture with jobs 'build'
            # and 'lint': a comment between them reported only 'build', presented as the complete set,
            # and a comment directly under 'jobs:' reported none at all. A confidently incomplete answer
            # is precisely what this script must not produce.
            if ($line -match '^\s*(#|$)') { continue }
            if ($line -match '^jobs:\s*$') { $inJobs = $true; continue }
            if ($inJobs -and $line -match '^\S') { $inJobs = $false }
            if ($inJobs -and $line -match '^  ([A-Za-z0-9_.-]+):\s*$') { $jobs += $Matches[1] }
        }
    }
    # The job ids come out of a charset-restricted capture above and cannot carry anything. The
    # FILENAMES do not -- they are whatever is on the consumer's disk -- so they go through the shared
    # path sanitizer, which strips control characters and square brackets for the reason its own
    # docstring gives: these lines are forwarded into session context, and a bracket is what the hooks
    # count markers by. Defence in depth rather than a measured incident; a filename is a far narrower
    # channel than the guide headings that were removed above, but it is the same kind of channel.
    $names = @($files | ForEach-Object { Format-SafePathToken -Value ".github/workflows/$($_.Name)" })
    $jobText = if ($jobs.Count -gt 0) { "job(s): $((@($jobs | Sort-Object -Unique)) -join ', ')" } else { 'no job id read' }
    return @{ Answer = "CI runs here -- $jobText"; Evidence = ($names -join ', ') }
}

function Find-ContributionGuide {
    # NO CONTENT FROM THE GUIDE IS COPIED OUT OF IT, and that restriction is a security decision rather
    # than a style one (Sebastian, August 9, 2026). An earlier version listed the guide's first eight
    # headings here. Those are prose from a file this script does not control, and they were being
    # written verbatim into a document whose own opening line says it is "read by the Claude Specialists
    # before they propose anything about process" -- which makes it a persistence channel: anyone who
    # can land one line in a repo's CONTRIBUTING.md (an accepted pull request, a vendored template, a
    # dependency that ships one) plants an instruction-shaped heading that every future session then
    # reads as established context.
    #
    # SANITIZING WAS THE OBVIOUS REPAIR AND IS THE WEAKER ONE. Format-SafeToken exists for exactly this
    # class and is available here -- but its charset is built for ids, so a real heading comes out
    # mangled, and a mangled preview is worth less than no preview. The stronger move is to stop
    # carrying the content at all: the answer a specialist needs is "this repo has a guide, read it",
    # and the guide itself is one file away. A copy of its headings here would also be a second
    # statement of the guide's structure, free to go stale against the original -- the shape this repo
    # keeps repairing elsewhere.
    #
    # What is left is a filename from a FIXED candidate list and a count. Neither can carry a payload.
    $guide = @(@('CONTRIBUTING.md', 'CONTRIBUTING.rst', 'docs/CONTRIBUTING.md', '.github/CONTRIBUTING.md') |
        ForEach-Object { Get-RelIfExists $_ } | Where-Object { $_ }) | Select-Object -First 1
    if (-not $guide) { return @{ Answer = $SILENT; Evidence = 'no contribution guide found' } }
    $sections = @([System.IO.File]::ReadAllLines((Join-Path $ConsumerRoot $guide)) |
        Where-Object { $_ -match '^#{1,3}\s+\S' }).Count
    return @{ Answer = "read it first: $guide"; Evidence = "$guide, $sections section heading(s) -- deliberately not quoted here, see the note in this script" }
}

# THE @() AROUND EACH PIPELINE IS LOAD-BEARING, not decoration. Assigning a pipeline's output unrolls
# it, so a single match arrives as a scalar and '.Count' then throws under StrictMode -- which is
# exactly how this script failed on its first run, on a repo where precisely one of the candidates
# existed. It is the third time the same unrolling has bitten during this restructure (the other two
# are noted in plugin-tree-lib.ps1 and shared-scripts-lib.ps1), so it is written down here too rather
# than fixed silently for a third time.
function Find-GovernanceDoc {
    $found = @(@('CLAUDE.md', '.claude/CLAUDE.md', 'AGENTS.md') |
        ForEach-Object { Get-RelIfExists $_ } | Where-Object { $_ })
    if ($found.Count -eq 0) { return @{ Answer = $SILENT; Evidence = 'no CLAUDE.md or AGENTS.md' } }
    return @{ Answer = "the repo states its own rules: $($found -join ', ')"; Evidence = ($found -join ', ') }
}

function Find-Automation {
    $dirs = @(@('scripts', 'bin', 'tools', 'Makefile', 'justfile', 'Taskfile.yml') |
        ForEach-Object { Get-RelIfExists $_ } | Where-Object { $_ })
    if ($dirs.Count -eq 0) { return @{ Answer = $SILENT; Evidence = 'no scripts/, bin/, tools/, Makefile, justfile or Taskfile' } }
    return @{ Answer = "the repo already automates things: $($dirs -join ', ')"; Evidence = 'use what is there before proposing anything new' }
}

$questions = @(
    @{ Key = 'Branch names';        Ask = 'What does a branch here look like?';                Run = { Find-BranchConvention } },
    @{ Key = 'Commit subjects';     Ask = 'How is a commit subject written?';                  Run = { Find-CommitSubjectStyle } },
    @{ Key = 'Landing a change';    Ask = 'How does work reach the trunk?';                    Run = { Find-PullRequestFlow } },
    @{ Key = 'History shape';       Ask = 'Merge commits, or a linear history?';               Run = { Find-MergeStyle } },
    @{ Key = 'Gates';               Ask = 'What has to pass before a change lands?';           Run = { Find-CiGate } },
    @{ Key = 'Written procedure';   Ask = 'Has the repo written its process down?';            Run = { Find-ContributionGuide } },
    @{ Key = 'Rules for agents';    Ask = 'Does the repo address its agents directly?';        Run = { Find-GovernanceDoc } },
    @{ Key = 'Existing automation'; Ask = 'What does the repo already script for itself?';     Run = { Find-Automation } }
)

Write-Host '== discover-workflow ==' -ForegroundColor Cyan
Write-Host "  repo: $ConsumerRoot" -ForegroundColor DarkGray

$results = @()
foreach ($q in $questions) {
    $r = & $q.Run
    $results += [pscustomobject]@{ Key = $q.Key; Ask = $q.Ask; Answer = $r.Answer; Evidence = $r.Evidence }
    $colour = if ($r.Answer -eq $SILENT) { 'Yellow' } else { 'Green' }
    Write-Host ("  {0,-20} {1}" -f $q.Key, $r.Answer) -ForegroundColor $colour
}
$silentCount = @($results | Where-Object { $_.Answer -eq $SILENT }).Count

# --- The document ------------------------------------------------------------------------------------
$nl = "`n"
$lines = @(
    '# How work moves through this repo',
    '',
    'Read by the Claude Specialists before they propose anything about process. Written by',
    '`discover-workflow` from what this repo already states -- its own documents, its CI, its branch',
    'names and its commit history -- and never from how another repo does it.',
    '',
    '**A `SILENT` answer is an answer.** It means the repo does not state this, so a specialist says so',
    'rather than filling the gap: pick the most conventional option for the stack, name that you are',
    'picking it, and do not present it as this repo''s standard.',
    '',
    '**This file is not maintained by anything.** It is a snapshot, and `discover-workflow` will never',
    'overwrite it -- re-running prints what changed and leaves the file alone. Correct it, extend it,',
    'or delete it and re-run.',
    ''
)
foreach ($r in $results) {
    $lines += "## $($r.Key)"
    $lines += ''
    $lines += "*$($r.Ask)*"
    $lines += ''
    if ($r.Answer -eq $SILENT) {
        $lines += '**SILENT** -- the repo does not state this.'
    } else {
        $lines += $r.Answer
    }
    $lines += ''
    $lines += "Read from: $($r.Evidence)"
    $lines += ''
}
$doc = ($lines -join $nl).TrimEnd() + $nl

if (-not $OutputPath) {
    $OutputPath = Join-Path (Get-SeamPaths -RepoRoot $ConsumerRoot).Dir 'repo-workflow.md'
} elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $ConsumerRoot $OutputPath
}

# CONTAINMENT: the one file this writes must land inside the repo it was pointed at. Sean's advice,
# applied here for a reason specific to this script rather than as a habit -- it is meant to be invoked
# by an agent that has just READ the consumer's repo, so a path influenced by something in that repo
# must not be able to send the write anywhere else on the disk. The shipped invocation passes no
# -OutputPath at all, which is what keeps this a guard rather than a fix.
$fullOut = [System.IO.Path]::GetFullPath($OutputPath)
$rootPrefix = $ConsumerRoot.TrimEnd('\') + '\'
if (-not $fullOut.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Error "discover-workflow refuses to write outside the repo it read: '$OutputPath' resolves to '$fullOut', which is not under '$ConsumerRoot'."
    exit 1
}
$OutputPath = $fullOut
$rel = $OutputPath.Replace($ConsumerRoot, '.')

Write-Host ''
if (Test-Path -LiteralPath $OutputPath -PathType Leaf) {
    # NEVER OVERWRITE. Report the differences and stop -- see the header for why.
    #
    # THE COMPARISON IS WHOLE-DOCUMENT, AND THAT IS A KNOWN LIMITATION rather than an oversight (found
    # by Tycho while writing this script's suite). An answer is looked for anywhere in the file instead
    # of inside its own '## <Key>' section, so if two sections ever carried the same sentence, a change
    # to one of them would read as unchanged. Left as it is deliberately: no fixture could produce it
    # without contrivance, this output is advisory rather than a gate -- the worst case is one changed
    # answer going unmentioned in a report that already tells you to look at the file -- and this repo
    # does not build repairs for defects nobody has met. Named here so the next reader knows it was
    # weighed rather than missed.
    $existing = [System.IO.File]::ReadAllText($OutputPath, [System.Text.Encoding]::UTF8)
    Write-Host "  [keep]  $rel already exists -- nothing written." -ForegroundColor Yellow
    $changed = 0
    foreach ($r in $results) {
        $shown = if ($r.Answer -eq $SILENT) { '**SILENT**' } else { $r.Answer }
        if ($existing -notmatch [regex]::Escape($shown)) {
            Write-Host ("  [diff]  {0,-20} now reads: {1}" -f $r.Key, $r.Answer) -ForegroundColor Yellow
            $changed++
        }
    }
    if ($changed -eq 0) {
        Write-Host '  [same]  every answer still matches what the file says.' -ForegroundColor DarkGray
    } else {
        Write-Host "  $changed answer(s) differ. Update the file yourself, or delete it and run again." -ForegroundColor DarkGray
    }
    exit 0
}

$dir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($OutputPath, $doc, (New-Object System.Text.UTF8Encoding $false))
Write-Host "  [write] $rel" -ForegroundColor Green
Write-Host "  $($results.Count) question(s) asked, $silentCount answered SILENT -- those are the ones where this repo has not decided, not the ones where it decided nothing matters." -ForegroundColor DarkGray
exit 0
