<#
.SYNOPSIS
    The prompt inbox: one file a requester writes an assignment into, outside the terminal, plus the
    reading, archiving and reset rules the script, the hook and the scaffold all share.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\prompt-inbox-lib.ps1')

    WHY IT EXISTS (Dave, August 15, 2026). Typing a long assignment into a terminal is the worst
    surface available for it: no wrapping, no editing, no saving it half-finished, and a paste that
    mangles anything with a newline in it. The inbox turns that around -- the requester writes in
    their own editor, saves, and a session picks the file up. It is the MIRROR of /lock: that one is
    Claude writing a note for the next Claude, this one is the requester writing for the next session.

    THE DIRECTION IS THE WHOLE DESIGN, and two rules follow from it:

      - THE FILE IS NEVER COMMITTED. It is one person's working input on one machine, it changes
        between saves, and a tracked copy would dirty the tree continuously -- the exact shape that
        blocked two release cuts in this repo when a PowerShell cache was tracked by accident. The
        folder therefore ships its own .gitignore covering prompt.md and archive/, so a consumer does
        not have to edit their root .gitignore to adopt the mechanism. What IS tracked is the folder's
        README and the template reference, so a fresh checkout knows the mechanism exists.
      - "IS SOMETHING WAITING" IS A STRUCTURAL TEST, NOT A STRING MATCH. The reset file is an HTML
        comment block and nothing else, so the body is "everything outside the comments" and an empty
        body means nothing waits. Deliberately unlike the changelog entry's scaffold gate, which has to
        recognise placeholder WORDING and therefore needs a shared source for those strings and a
        translation seam for a consumer who rewrote them. Here there is no placeholder to recognise:
        a consumer may translate every word of the comment block and the test is unaffected, because
        comments are comments in every language.

    Supplies Get-PromptInboxPaths, the three formatters the scaffold and the script share
    (Format-PromptReset, Format-PromptTemplateReference, Format-PromptInboxIgnore), and the readers
    Get-PromptBody / Get-PromptState / Get-PromptArchiveName.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

# The folder, relative to the repo root. Inside workflow-davekjohn/ because that is where everything
# portable about this workflow gathers (Dave, August 14, 2026) -- a prompt inbox scattered at the root
# would be the shape that decision retired.
$script:PromptInboxRel = 'workflow-davekjohn\prompts'

function Get-PromptInboxPaths {
    <# Every path the inbox uses, absolute plus repo-relative (forward slashes, for printing). One
       function so the script, the hook, the scaffold and the tests cannot disagree about where the
       file is -- the same reason session-status.ps1 decides the lock path in one place. #>
    param([Parameter(Mandatory)][string]$RepoRoot)

    $root = Join-Path $RepoRoot $script:PromptInboxRel
    return @{
        Root        = $root
        RootRel     = ($script:PromptInboxRel -replace '\\', '/')
        Prompt      = (Join-Path $root 'prompt.md')
        PromptRel   = (($script:PromptInboxRel -replace '\\', '/') + '/prompt.md')
        Archive     = (Join-Path $root 'archive')
        ArchiveRel  = (($script:PromptInboxRel -replace '\\', '/') + '/archive')
        Template    = (Join-Path $root 'templates\prompt_template.md')
        TemplateRel = (($script:PromptInboxRel -replace '\\', '/') + '/templates/prompt_template.md')
        Ignore      = (Join-Path $root '.gitignore')
        IgnoreRel   = (($script:PromptInboxRel -replace '\\', '/') + '/.gitignore')
    }
}

function Format-PromptReset {
    <# The empty inbox: a comment block and nothing else. Everything a writer needs to know sits inside
       the comments, so the whole file is scaffold and the body is empty by construction -- which is
       what makes "nothing is waiting" a fact about the file rather than a guess about its wording. #>
    return @(
        '<!--',
        '  Write your assignment below this block, in your own words, and save.',
        '',
        '  Everything inside HTML comments is scaffold and is stripped before a session reads the file,',
        '  so you can leave this block exactly where it is. An inbox holding only comments counts as',
        '  empty -- nothing is announced and nothing is picked up.',
        '',
        '  Pick it up with /prompt. The session reads what you wrote, moves it into archive/ under the',
        '  date, and resets this file -- so an assignment is never handed over twice.',
        '',
        '  This file is not committed (see .gitignore next to it): it is your working input, not repo',
        '  content.',
        '-->',
        ''
    )
}

function Format-PromptTemplateReference {
    <# The TRACKED reference beside the untracked inbox. It exists because prompt.md is gitignored: a
       fresh checkout would otherwise contain no evidence that the mechanism is there, and the first
       thing the script does on a repo without an inbox is write this content into prompt.md. Same
       relationship as branch/templates/ has to the two branch files. #>
    return @(
        '# The prompt inbox -- the reset state, for reference',
        '',
        'This file is the shape `prompt.md` is created in and returned to after each pickup. It is here',
        'because `prompt.md` itself is deliberately untracked, so without this reference a fresh clone',
        'would carry no trace of the mechanism.',
        '',
        '**Do not write your assignment here** -- write it in `prompt.md`, one directory up. Nothing',
        'reads this file; the script generates it and rewrites it when it has drifted.',
        '',
        '```markdown'
    ) + @(Format-PromptReset) + @(
        '```'
    )
}

function Format-PromptInboxIgnore {
    <# The folder's own .gitignore. Shipped INSIDE the folder rather than as lines a consumer must add
       to their root file: adopting the inbox then costs one scaffold run and no edit to a file the
       consumer already owns, and a repo that later deletes the folder takes the rule with it. #>
    return @(
        '# The inbox you are writing in, and the ones already handled. Never committed: this is one',
        '# person''s working input on one machine, it changes between saves, and a tracked copy would',
        '# dirty the tree continuously -- which is what a release cut refuses to run on.',
        'prompt.md',
        'archive/',
        ''
    )
}

function Get-PromptBody {
    <# What the requester actually wrote: the text with every HTML comment removed and the result
       trimmed. Returns '' when nothing but scaffold is left, which is how every caller tests whether
       an assignment is waiting.

       Unclosed comments are treated as running to the end of the file. That is the state a half-typed
       comment leaves, and reading the rest of the file as an assignment would hand a session the
       scaffold's own instructions as if the requester had written them. #>
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }

    $stripped = [regex]::Replace($Text, '(?s)<!--.*?-->', '')
    $stripped = [regex]::Replace($stripped, '(?s)<!--.*$', '')
    return $stripped.Trim()
}

function Get-PromptFirstLine {
    <# The first non-empty line of a body, shortened for a one-line announcement. The hook prints this
       and NOT the whole body, deliberately: announcing is not the same as handing over, and a session
       that had already read the assignment would start on it before the requester said go. #>
    param([string]$Body, [int]$MaxLength = 100)

    $line = @($Body -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
    if ($line.Count -eq 0) { return '' }

    $text = $line[0].Trim()
    if ($text.Length -le $MaxLength) { return $text }
    return $text.Substring(0, $MaxLength - 3).TrimEnd() + '...'
}

function ConvertTo-PromptSlug {
    <# A short, ASCII, filename-safe slug from the first words of a body, for the archive name. Falls
       back to 'prompt' rather than to an empty component: a file named '2026-08-15-1042-.md' reads
       like a bug in the archiver. #>
    param([string]$Text, [int]$MaxLength = 40)

    $first = Get-PromptFirstLine -Body $Text -MaxLength 200
    $slug = ($first -replace '[^A-Za-z0-9]+', '-').Trim('-').ToLowerInvariant()
    if ($slug.Length -gt $MaxLength) {
        $slug = $slug.Substring(0, $MaxLength).Trim('-')
        # Cut back to the last whole word, so the name does not end mid-word -- unless that would leave
        # almost nothing, in which case the hard cut is the better of the two.
        $lastDash = $slug.LastIndexOf('-')
        if ($lastDash -gt ($MaxLength / 2)) { $slug = $slug.Substring(0, $lastDash) }
    }
    if (-not $slug) { return 'prompt' }
    return $slug
}

function Get-PromptArchiveName {
    <# The archive filename for a body: '<yyyy-MM-dd-HHmm>-<slug>.md'. -Now is a parameter rather than
       a Get-Date call inside, so the suite can assert an exact name instead of whatever minute it runs
       in. Sorts chronologically as text, which is the whole reason the date leads. #>
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][datetime]$Now
    )

    return ('{0}-{1}.md' -f $Now.ToString('yyyy-MM-dd-HHmm'), (ConvertTo-PromptSlug -Text $Body))
}

function Format-PromptAge {
    <# How long ago the inbox was written, in words. Its job is to let a reader spot a STALE prompt --
       one written days ago, from a session that never picked it up -- which a bare timestamp makes
       them compute for themselves. #>
    param(
        [Parameter(Mandatory)][datetime]$Written,
        [Parameter(Mandatory)][datetime]$Now
    )

    $span = $Now - $Written
    if ($span.TotalSeconds -lt 0) { return 'just now' }
    if ($span.TotalMinutes -lt 1) { return 'less than a minute ago' }
    if ($span.TotalMinutes -lt 60) {
        $m = [int]$span.TotalMinutes
        return ('{0} minute{1} ago' -f $m, $(if ($m -eq 1) { '' } else { 's' }))
    }
    if ($span.TotalHours -lt 24) {
        $h = [int]$span.TotalHours
        return ('{0} hour{1} ago' -f $h, $(if ($h -eq 1) { '' } else { 's' }))
    }
    $d = [int]$span.TotalDays
    return ('{0} day{1} ago' -f $d, $(if ($d -eq 1) { '' } else { 's' }))
}

function Get-PromptState {
    <# Everything a caller needs about the inbox in one read: does the file exist, is an assignment
       waiting, what does it say, and how old is it. One function because THREE readers ask the same
       question -- the script, the session hook, and the suite -- and a hook that answered it its own
       way would announce prompts the script then declines to see. #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [datetime]$Now = [datetime]::Now
    )

    $paths = Get-PromptInboxPaths -RepoRoot $RepoRoot
    $state = @{
        Paths     = $paths
        Exists    = $false
        Waiting   = $false
        Body      = ''
        FirstLine = ''
        Written   = $null
        Age       = ''
    }

    if (-not (Test-Path -LiteralPath $paths.Prompt -PathType Leaf)) { return $state }
    $state.Exists = $true

    # Explicit UTF-8, matching every other reader in this tree: the default encoding mangles exactly
    # the accented text a Dutch-language assignment is most likely to contain.
    $text = [System.IO.File]::ReadAllText($paths.Prompt, [System.Text.Encoding]::UTF8)
    $state.Body = Get-PromptBody -Text $text
    $state.Waiting = [bool]$state.Body
    if ($state.Waiting) {
        $state.FirstLine = Get-PromptFirstLine -Body $state.Body
        $written = (Get-Item -LiteralPath $paths.Prompt).LastWriteTime
        $state.Written = $written
        $state.Age = Format-PromptAge -Written $written -Now $Now
    }
    return $state
}
