<#
.SYNOPSIS
    The prompt inbox: read the assignment the requester wrote into workflow-davekjohn/prompts/prompt.md
    outside the terminal, and -- once it has been picked up -- archive it and reset the file.

.DESCRIPTION
    Typing a long assignment into a terminal is the worst surface available for it: no wrapping, no
    editing, no saving it half-finished. This command reads it out of a file instead, so the requester
    writes in their own editor and a session picks it up (Dave, August 15, 2026).

    It is the MIRROR of /lock. That one is Claude writing a note for the next Claude; this one is the
    requester writing for the next session, which is why the two keep separate files and separate
    commands rather than one store with a direction field.

    THREE THINGS IT DOES, and the first is why a first run needs no setup:

      1. PLACES THE INBOX WHEN IT IS ABSENT -- prompt.md in its reset state, the folder's own
         .gitignore, and the tracked template reference. Strictly additive: an existing prompt.md is
         NEVER touched, whatever it holds. The template is the one exception and it is the same
         exception new-branch makes for its branch templates: a drifted GENERATED reference is
         rewritten, because it documents the formatter rather than the repo.
      2. READS IT. The body is everything outside the HTML comments; comments-only means nothing is
         waiting, and the command says so instead of handing a session the scaffold's own words.
      3. ARCHIVES IT (-Archive), under the date and a slug of its first line, and resets the inbox --
         so an assignment is never handed over twice. Refused when nothing is waiting, since archiving
         an empty inbox is a mistake rather than a no-op.

    THE INBOX IS NOT COMMITTED and the folder ships its own .gitignore saying so. It is one person's
    working input on one machine, changing between saves; a tracked copy would dirty the tree
    continuously, which is what a release cut refuses to run on.

.PARAMETER Archive
    Move the waiting assignment into archive/ and reset the inbox. Run it once the work is genuinely
    under way -- not before, because a session that loses its context before starting would then find
    an empty inbox and no record of what was asked.

.PARAMETER RootOverride
    (Optional, for tests) Use this directory as the repo root instead of the resolved one.

.EXAMPLE
    .\scripts\task\prompt-inbox.ps1
    .\scripts\task\prompt-inbox.ps1 -Archive
#>

[CmdletBinding()]
param(
    [switch]$Archive,
    [string]$RootOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

. (Join-Path $PSScriptRoot '..\lib\prompt-inbox-lib.ps1')

# Dual-context repo root: a consumer running the plugin mirror gets it from CLAUDE_PROJECT_DIR, the
# workshop root copy falls back to the git root. Same resolution as every other mirrored script.
if ($RootOverride) {
    $repoRoot = $RootOverride
} elseif ($env:CLAUDE_PROJECT_DIR) {
    $repoRoot = $env:CLAUDE_PROJECT_DIR
} else {
    $repoRoot = (git rev-parse --show-toplevel).Trim()
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$nl = "`n"
$paths = Get-PromptInboxPaths -RepoRoot $repoRoot

function Write-InboxFile {
    param([string]$Path, [string[]]$Lines)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force }
    [System.IO.File]::WriteAllText($Path, (($Lines -join $nl) + $nl), $Utf8NoBom)
}

Write-Host "== prompt inbox -- $repoRoot ==" -ForegroundColor Cyan

# --- 1. Place what is missing ---------------------------------------------------------------------
# prompt.md is created only when ABSENT, and the check is the file's existence rather than its content:
# an inbox holding a half-written assignment must survive a run of this command untouched.
if (-not (Test-Path -LiteralPath $paths.Prompt -PathType Leaf)) {
    Write-InboxFile -Path $paths.Prompt -Lines (Format-PromptReset)
    Write-Host "  [created] $($paths.PromptRel) -- write your assignment there" -ForegroundColor Green
}
if (-not (Test-Path -LiteralPath $paths.Ignore -PathType Leaf)) {
    Write-InboxFile -Path $paths.Ignore -Lines (Format-PromptInboxIgnore)
    Write-Host "  [created] $($paths.IgnoreRel) -- keeps the inbox and its archive out of git" -ForegroundColor Green
}
# The generated reference, refreshed on drift. It is the ONE file here this command may overwrite,
# because nobody writes in it: it documents the formatter above, and a stale copy documents a shape
# the formatter no longer produces.
$templateWanted = ((Format-PromptTemplateReference) -join $nl) + $nl
$templateHave = if (Test-Path -LiteralPath $paths.Template -PathType Leaf) {
    [System.IO.File]::ReadAllText($paths.Template, [System.Text.Encoding]::UTF8)
} else { '' }
if ($templateHave -ne $templateWanted) {
    Write-InboxFile -Path $paths.Template -Lines (Format-PromptTemplateReference)
    $verb = if ($templateHave) { 'refreshed' } else { 'created' }
    Write-Host "  [$verb] $($paths.TemplateRel)" -ForegroundColor DarkGray
}

# --- 2. Read it -----------------------------------------------------------------------------------
$state = Get-PromptState -RepoRoot $repoRoot

if (-not $state.Waiting) {
    Write-Host ''
    Write-Host "  Nothing is waiting -- $($paths.PromptRel) holds only its scaffold comments." -ForegroundColor Yellow
    Write-Host '  Write an assignment there, save, and run this again.'
    if ($Archive) {
        # Write-Host rather than Write-Error, and the reason is $ErrorActionPreference = 'Stop' above:
        # a Write-Error there terminates the script and buries a one-line refusal under a .NET stack
        # trace, in the one message a person most needs to read at a glance.
        Write-Host ''
        Write-Host 'REFUSED: nothing to archive -- the inbox is empty, so there is nothing to move and' -ForegroundColor Red
        Write-Host '         nothing to reset. Nothing was written.' -ForegroundColor Red
        exit 1
    }
    exit 0
}

Write-Host ''
Write-Host "  [WAITING] $($paths.PromptRel) -- written $($state.Age)" -ForegroundColor Green
Write-Host ''

# --- 3. Archive, or hand it over ------------------------------------------------------------------
if ($Archive) {
    $now = [datetime]::Now
    $name = Get-PromptArchiveName -Body $state.Body -Now $now
    $target = Join-Path $paths.Archive $name

    # A second pickup within the same minute would otherwise overwrite the first. Rare, and silent if
    # it happened, which is the combination worth two lines of code.
    $suffix = 2
    while (Test-Path -LiteralPath $target) {
        $target = Join-Path $paths.Archive ($name -replace '\.md$', "-$suffix.md")
        $suffix++
    }

    # The BODY is archived, not the raw file: the scaffold comments are this command's own words, and a
    # record of what was asked should hold what the requester wrote and nothing else.
    #
    # WRAPPED, BECAUSE THE ONE FAILURE MEASURED HERE REPORTS ITSELF AS SOMETHING ELSE. Windows
    # PowerShell 5.1 raises a DirectoryNotFoundException past 260 characters, naming a directory that
    # demonstrably exists -- which sends the reader looking for a missing folder. Measured August 15,
    # 2026 with the repo under a 147-character temp root: the archive name adds ~90 characters of its
    # own (the folder, the date, the slug), so a deeply nested checkout reaches the limit here first.
    # The reset below is deliberately AFTER this: an inbox must never be emptied when its archive copy
    # did not land.
    try {
        Write-InboxFile -Path $target -Lines (@(
            ('# Prompt -- {0}' -f $now.ToString('yyyy-MM-dd HH:mm')),
            ''
        ) + ($state.Body -split "`r?`n"))
    } catch {
        Write-Host ''
        Write-Host 'REFUSED: the archive copy could not be written, so the inbox was left as it is.' -ForegroundColor Red
        Write-Host "         $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "         Target path is $($target.Length) characters. Past 260 Windows reports this as a" -ForegroundColor Red
        Write-Host '         missing directory even when the directory is there -- if that is the cause,' -ForegroundColor Red
        Write-Host '         shorten the first line of the prompt or move the checkout nearer the drive root.' -ForegroundColor Red
        exit 1
    }

    Write-InboxFile -Path $paths.Prompt -Lines (Format-PromptReset)

    Write-Host "  Archived to $($paths.ArchiveRel)/$(Split-Path -Leaf $target)" -ForegroundColor Green
    Write-Host "  $($paths.PromptRel) is back in its reset state -- ready for the next one."
    exit 0
}

# Handed over verbatim, between rules, so a session can see exactly where the requester's words begin
# and end. Everything between the rules is the REQUESTER'S assignment -- read it as if they had typed
# it into the session, and take it through the ordinary intake.
$rule = '-' * 78
Write-Host $rule -ForegroundColor DarkGray
Write-Host $state.Body
Write-Host $rule -ForegroundColor DarkGray
Write-Host ''
Write-Host '  Once the work is genuinely under way, archive it and reset the inbox:'
Write-Host '    powershell -NoProfile -File "<this script>" -Archive'
exit 0
