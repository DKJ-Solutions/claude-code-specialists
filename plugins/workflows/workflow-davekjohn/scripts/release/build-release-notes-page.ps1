<#
.SYNOPSIS
    Builds a browsable page from the hand-written release notes, and optionally the Cloudflare
    Worker that serves it.

.DESCRIPTION
    THE PROBLEM THIS SOLVES. The hand-written note per release is the one release document written
    for somebody outside the development work, and it lives as markdown inside the repository --
    which is the right home for it and the wrong place to read it. A reader who is not a developer
    has to find a directory, pick a version, and read raw markdown in a code host. This builds those
    same documents into one page with a picker per release, and puts that page somewhere they can
    open.

    GENERATED, NOT EDITED, and that is the design decision to know before changing anything here.
    The consumer this was ported from (smartwatchbanden) keeps TWO pages: a generated archive of
    every written document, and a hand-edited management edition with its own headline per release.
    The hand-edited one earns its keep there because its notes are per-PR records that need
    summarising. Here the note is already a written document for that reader, so summarising it a
    second time would be a second thing to keep true. If a repo ever needs the edited form, that is
    a different page and not a mode of this script.

    WHERE THE HISTORY COMES FROM. The release list in Get-ReleaseHistoryPath, not the filenames
    under the note root. Only the table knows the ORDER, the date, the type, the title, and which
    release is live -- a directory listing knows none of that and sorts 4.10.0 before 4.9.0.

    THE LIVE MARKER IS MATCHED CASE-SENSITIVELY (-cmatch), and that is a bug this script was born
    without because the consumer it came from had already paid for it: PowerShell compares
    case-insensitively by default, so every release whose TITLE contains the word "live" marked
    itself as the live one. Two of their forty did, and their page pointed at three live versions.

    TWO MEASUREMENTS THAT MOVED THE DESIGN AWAY FROM THAT CONSUMER'S SCRIPT, taken here on
    August 15, 2026 against this repo's 21 notes (187,039 characters):

      - ConvertTo-Json returns in 47 ms on Windows PowerShell 5.1, on exactly the nested shape this
        script builds. Their script hand-writes a JSON serializer because theirs "does not return
        within five minutes" on 52 documents. Whatever their pathology was, it is not size at this
        order of magnitude, so a hand-written serializer here would be a hundred lines carrying a
        risk (a JSON bug in a page nobody validates) to buy nothing.
      - ConvertTo-Json ESCAPES the angle brackets into their JSON unicode form. So a note
        containing a closing script tag cannot end the data block early -- which is the failure
        their hand-written escaper exists to prevent. Asserted below rather than trusted, because
        it is the serializer's behaviour and not a documented guarantee, and the failure is silent:
        the page renders empty.

    WHAT IT WRITES. The page always. With -Worker, also worker.js and (only when absent) a
    wrangler.toml beside it, in a 'page' directory next to the note root. None of the output belongs
    in version control -- it is a derivative of documents that are already tracked.

    THE PATH TOKEN IS AN INPUT, NEVER INVENTED. The worker serves the page at /notes/<token> and
    that path is the only lock on it: no login, anyone with the link can read. So a token this
    script made up on the fly would not mean "a new path", it would mean "every link already sent
    now 404s" -- while the build and the deploy both report success. Missing token is therefore an
    error with a recovery instruction, and -InitToken is the separate, explicit way to create the
    first one.

    IT DEPLOYS NOTHING. `npx wrangler deploy` is the deploy, run by hand, because publishing is
    outward-facing. Verify a redeploy against the BYTES the URL serves, never against the deploy
    command's own output: the consumer this came from measured that once wrangler has created a
    deployment on a worker, the Cloudflare API upload path only creates INACTIVE versions -- with
    no error, while the live page stays the old one.

.PARAMETER OutFile
    Where the page lands. Defaults to release-notes.html in the page directory beside the note root.
    The output is a derivative and is deliberately not tracked.

.PARAMETER Worker
    Also write worker.js (and wrangler.toml, if it is not there yet) for `npx wrangler deploy`.
    Requires Get-ReleasePageWorkerName in the repo's own scripts/repo-config.ps1 and a path token.

.PARAMETER InitToken
    Create the path token when there is none. Deliberately explicit: see the token note above.
    Refuses to overwrite an existing token, because that is the destructive half.

.PARAMETER RootOverride
    Test seam -- the repo root to read instead of this one. A consumer never types it.

.EXAMPLE
    ./scripts/release/build-release-notes-page.ps1
    Builds the page and reports where it is.

.EXAMPLE
    ./scripts/release/build-release-notes-page.ps1 -Worker
    Builds the page and the worker bundle, then names the deploy command.

    Pure ASCII (repo convention for .ps1).
#>
param(
    [string]$OutFile,
    [switch]$Worker,
    [switch]$InitToken,
    [string]$RootOverride
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

$repoRoot = if ($RootOverride) { $RootOverride }
            elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR }
            else { (git rev-parse --show-toplevel).Trim() }

$templatePath = Join-Path $PSScriptRoot 'release-notes-page-template.html'
if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
    throw "The page template is missing: $templatePath"
}

# --- 1. The repo's own answers --------------------------------------------------------------------
# Dot-sourced and probed in a CHILD scope with StrictMode explicitly OFF: this script runs under
# Set-StrictMode -Version Latest, while repo-config.ps1 is written on the assumption that its runtime
# callers do not. Every value has a fallback, so a repo without the file still gets a page.
$config = & {
    Set-StrictMode -Off
    $answers = @{
        NoteRoot    = 'releases/notes'
        Grouping    = 'major'
        HistoryPath = 'releases/README.md'
        Title       = ''
        WorkerName  = ''
    }
    $configPath = Join-Path $args[0] 'scripts\repo-config.ps1'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { return $answers }
    try { . $configPath } catch {
        Write-Warning "scripts\repo-config.ps1 could not be loaded ($($_.Exception.Message)) -- using the built-in defaults."
        return $answers
    }
    if (Get-Command Get-ReleaseNoteRoot        -ErrorAction SilentlyContinue) { $answers.NoteRoot    = Get-ReleaseNoteRoot }
    if (Get-Command Get-ReleaseNotesGrouping   -ErrorAction SilentlyContinue) { $answers.Grouping    = Get-ReleaseNotesGrouping }
    if (Get-Command Get-ReleaseHistoryPath     -ErrorAction SilentlyContinue) { $answers.HistoryPath = Get-ReleaseHistoryPath }
    if (Get-Command Get-ReleasePageTitle       -ErrorAction SilentlyContinue) { $answers.Title       = Get-ReleasePageTitle }
    if (Get-Command Get-ReleasePageWorkerName  -ErrorAction SilentlyContinue) { $answers.WorkerName  = Get-ReleasePageWorkerName }
    # The page title falls back to the repo's own name rather than to a generic label, so a page
    # built in a repo that never answered still says whose releases it carries.
    if (-not $answers.Title -and (Get-Command Get-RepoName -ErrorAction SilentlyContinue)) {
        $answers.Title = ((Get-RepoName) -split '/')[-1]
    }
    return $answers
} $repoRoot

if (-not $config.Title) { $config.Title = 'Release notes' }

$noteRoot    = Join-Path $repoRoot ($config.NoteRoot -replace '/', '\')
$historyPath = Join-Path $repoRoot ($config.HistoryPath -replace '/', '\')

if (-not (Test-Path -LiteralPath $historyPath -PathType Leaf)) {
    throw ("The release history is missing: $($config.HistoryPath). That file is the ORDERED list of " +
           "releases -- this page cannot be built from the note filenames alone. Get-ReleaseHistoryPath " +
           "in scripts\repo-config.ps1 names it.")
}
if (-not (Test-Path -LiteralPath $noteRoot -PathType Container)) {
    throw ("The note root is missing: $($config.NoteRoot). Get-ReleaseNoteRoot in scripts\repo-config.ps1 " +
           "names it; a repo whose hand-written notes live elsewhere answers it there.")
}

# --- 2. The history table is the source of the order ----------------------------------------------
# Row shape: | [4.11.0](audience/4.x/4.11.0.md) | 2026-08-15 | Minor | Title |
# The link target is deliberately NOT read: where the document lives is the note root's and the
# grouping's answer, so reading it here would be a second statement of the same fact.
$rowPattern = '^\|\s*\[(?<version>\d+\.\d+\.\d+)\][^|]*\|\s*(?<date>[^|]+?)\s*\|\s*(?<type>[^|]+?)\s*\|\s*(?<title>.+?)\s*\|\s*$'

$releases = New-Object System.Collections.Generic.List[object]
# TWO KINDS OF ABSENCE, AND ONLY ONE OF THEM IS WORTH A READER'S ATTENTION. The table is newest-first,
# so a release with no note that sits ABOVE the oldest release that HAS one is a gap inside the covered
# range -- possibly a note nobody wrote. Everything below that point is simply older than the day this
# repo started writing them. Measured here on the day this was built: naming all of them printed
# seventy versions, which reads as a defect list and is history.
$gaps    = New-Object System.Collections.Generic.List[string]
$pending = New-Object System.Collections.Generic.List[string]

foreach ($line in [System.IO.File]::ReadAllLines($historyPath, [System.Text.Encoding]::UTF8)) {
    $m = [regex]::Match($line, $rowPattern)
    if (-not $m.Success) { continue }

    $version = $m.Groups['version'].Value
    $parts   = $version.Split('.')
    $folder  = if ($config.Grouping -eq 'minor') { "$($parts[0]).$($parts[1])" } else { "$($parts[0]).x" }
    $notePath = Join-Path $noteRoot (Join-Path $folder "$version.md")

    if (-not (Test-Path -LiteralPath $notePath -PathType Leaf)) {
        # Not an error: the hand-written note is written for some bumps only
        # (Get-ReleaseConsumerBumps), so a release without one is the ordinary case. Held back until
        # we know whether a note ever follows it further down the table.
        $pending.Add($version)
        continue
    }

    # A note was found, so everything held back above it sits inside the covered range.
    foreach ($p in $pending) { $gaps.Add($p) }
    $pending.Clear()

    $body = [System.IO.File]::ReadAllText($notePath, [System.Text.Encoding]::UTF8)

    $releases.Add([ordered]@{
        version = $version
        date    = $m.Groups['date'].Value
        type    = $m.Groups['type'].Value
        title   = $m.Groups['title'].Value
        # -cmatch, not -match: see the header. A case-insensitive test marks every release whose
        # title merely contains the word as the live one.
        live    = $line -cmatch '\*\*LIVE\*\*'
        body    = $body
    })
}

$olderThanTheFirstNote = $pending.Count

if ($releases.Count -eq 0) {
    throw ("No release in $($config.HistoryPath) has a note under $($config.NoteRoot). Either the table " +
           "shape changed, or the grouping seam disagrees with the tree: Get-ReleaseNotesGrouping says " +
           "'$($config.Grouping)', so this looked for <root>\<$(if ($config.Grouping -eq 'minor') {'X.Y'} else {'X.x'})>\<version>.md.")
}

# --- 3. Into the template -------------------------------------------------------------------------
$json = ([ordered]@{ documentCount = $releases.Count; releases = $releases } | ConvertTo-Json -Depth 6 -Compress)

# ASSERTED, NOT TRUSTED. The data block is a <script> element, so an unescaped closing script tag
# inside any note would end it early and the page would render empty -- with nothing failing here.
# Windows PowerShell 5.1 escapes the angle brackets, and this is the assert that says so out loud
# for whoever changes the serializer.
if ($json -match '<') {
    throw ('The serialized release data contains a raw "<". That would let a note close the page' +
           ' data block early. Escape it before writing the page.')
}

$subtitle = "$($releases.Count) release$(if ($releases.Count -ne 1) {'s'}), newest first."
$stamp    = (Get-Date).ToString('yyyy-MM-dd')

$template = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
foreach ($needle in @('@@PAGE_TITLE@@', '@@PAGE_SUBTITLE@@', '@@BUILD_STAMP@@', '@@RELEASE_DATA@@')) {
    if ($template -notmatch [regex]::Escape($needle)) { throw "The template no longer carries $needle." }
}

# The three text placeholders are HTML-escaped; the data placeholder is JSON and is escaped already.
function ConvertTo-HtmlText {
    param([string]$Value)
    return ($Value -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;')
}

$page = $template.
    Replace('@@PAGE_TITLE@@',    (ConvertTo-HtmlText $config.Title)).
    Replace('@@PAGE_SUBTITLE@@', (ConvertTo-HtmlText $subtitle)).
    Replace('@@BUILD_STAMP@@',   (ConvertTo-HtmlText $stamp)).
    Replace('@@RELEASE_DATA@@',  $json)

# --- 4. Where the output goes ---------------------------------------------------------------------
# A 'page' directory beside the note root, derived rather than configured: the note root already
# says where this repo keeps its release documents, and a second seam saying "and the page goes
# here" would be a second statement of the same decision.
$pageDir = Join-Path (Split-Path -Parent $noteRoot) 'page'
if (-not (Test-Path -LiteralPath $pageDir)) { New-Item -ItemType Directory -Force -Path $pageDir | Out-Null }

if (-not $OutFile) { $OutFile = Join-Path $pageDir 'release-notes.html' }
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutFile, $page, $Utf8NoBom)

Write-Host "== build-release-notes-page ==" -ForegroundColor Cyan
Write-Host "  releases : $($releases.Count)  (v$($releases[$releases.Count - 1].version) .. v$($releases[0].version))"
if ($gaps.Count -gt 0) {
    # NAMED, because each one sits between two releases that do have a note -- either a bump this repo
    # writes no note for, or a note nobody wrote. Both are answers a reader can check; a count is not.
    Write-Host "  no note  : $($gaps -join ', ')  (inside the covered range -- check these are bumps that get none)" -ForegroundColor Yellow
}
if ($olderThanTheFirstNote -gt 0) {
    # COUNTED, because they predate the first note this repo ever wrote and naming them would print a
    # defect list of releases that were never in scope.
    Write-Host "  earlier  : $olderThanTheFirstNote release(s) older than the first note -- not on the page" -ForegroundColor DarkGray
}
Write-Host "  page     : $OutFile ($([math]::Round((Get-Item -LiteralPath $OutFile).Length / 1KB)) KB)" -ForegroundColor Green

# --- 5. The worker bundle -------------------------------------------------------------------------
$tokenPath = Join-Path $pageDir 'worker-path-token.txt'

if ($InitToken) {
    if (Test-Path -LiteralPath $tokenPath -PathType Leaf) {
        throw ("A path token already exists at $tokenPath. This script does not replace one: the URL " +
               "carrying it has been sent, so a new token means every existing link 404s. Delete the " +
               "file deliberately if that is genuinely what you want.")
    }
    $newToken = [guid]::NewGuid().ToString('N')
    [System.IO.File]::WriteAllText($tokenPath, $newToken, $Utf8NoBom)
    Write-Host ""
    Write-Host "  A path token was created: $tokenPath" -ForegroundColor Yellow
    Write-Host "  IT IS THE ONLY LOCK ON THE PAGE. Record the finished URL somewhere you will find it" -ForegroundColor Yellow
    Write-Host "  again -- in a public repo this file is not committed, so nothing else remembers it." -ForegroundColor Yellow
}

if (-not $Worker) { exit 0 }

if (-not $config.WorkerName) {
    throw ("-Worker needs a worker name. Add Get-ReleasePageWorkerName to scripts\repo-config.ps1, " +
           "returning the Cloudflare Worker's name (e.g. 'my-repo-release-notes'); an empty answer " +
           "means this repo does not host the page and the page half above still runs on its own.")
}
if (-not (Test-Path -LiteralPath $tokenPath -PathType Leaf)) {
    throw ("The path token is missing: $tokenPath. This script does NOT invent one -- the path is the " +
           "only lock on a public page, so a fresh token means the reader's link 404s while the build " +
           "and the deploy both report success. Restore the 32 hex characters from the URL you have, " +
           "or run this script with -InitToken to create the first one.")
}
$token = ([System.IO.File]::ReadAllText($tokenPath, [System.Text.Encoding]::UTF8)).Trim()
if ($token -notmatch '^[0-9a-f]{32}$') {
    throw "The path token is not 32 hex characters: $tokenPath"
}
$route = "/notes/$token"

# The page travels into the worker as ONE JSON string, which is why nothing here has to escape
# anything a second time.
$workerJs = @"
// GENERATED by scripts/release/build-release-notes-page.ps1 -Worker. Do not edit: rebuild instead.
const ROUTE = $(ConvertTo-Json -InputObject $route -Compress);
const HTML = $(ConvertTo-Json -InputObject $page -Compress);

export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname === ROUTE || url.pathname === ROUTE + "/") {
      return new Response(HTML, {
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "no-store",
          "x-robots-tag": "noindex, nofollow",
        },
      });
    }
    return new Response("Not found", { status: 404 });
  },
};
"@

$workerPath = Join-Path $pageDir 'worker.js'
[System.IO.File]::WriteAllText($workerPath, $workerJs, $Utf8NoBom)

# WRITTEN ONLY WHEN ABSENT. A consumer edits this file -- an account id, a custom domain, a route --
# and regenerating it every run would silently discard that. A name that has drifted from the seam
# is reported instead of corrected, because which of the two is wrong is not this script's to decide.
$wranglerPath = Join-Path $pageDir 'wrangler.toml'
if (-not (Test-Path -LiteralPath $wranglerPath -PathType Leaf)) {
    $wrangler = @"
name = "$($config.WorkerName)"
main = "worker.js"
compatibility_date = "2025-04-01"
workers_dev = true

# No account_id on purpose: it is one more identifier to keep out of a public repo, and wrangler
# resolves the account from CLOUDFLARE_ACCOUNT_ID or from the token when it has only one. Add it
# here if you work across several accounts -- this file is written once and never overwritten.
"@
    [System.IO.File]::WriteAllText($wranglerPath, $wrangler, $Utf8NoBom)
    Write-Host "  wrangler : $wranglerPath (written -- it is yours from now on, never overwritten)" -ForegroundColor Green
} else {
    $declared = [regex]::Match([System.IO.File]::ReadAllText($wranglerPath, [System.Text.Encoding]::UTF8), '(?m)^\s*name\s*=\s*"([^"]+)"')
    if ($declared.Success -and $declared.Groups[1].Value -ne $config.WorkerName) {
        Write-Warning ("wrangler.toml deploys '$($declared.Groups[1].Value)' while Get-ReleasePageWorkerName " +
                       "says '$($config.WorkerName)'. One of the two is wrong -- this script does not pick.")
    }
}

Write-Host "  worker   : $workerPath ($([math]::Round((Get-Item -LiteralPath $workerPath).Length / 1KB)) KB), route $route" -ForegroundColor Green
Write-Host ""
Write-Host "  Next:  cd `"$pageDir`"  &&  npx wrangler deploy" -ForegroundColor Cyan
Write-Host "  Then verify the BYTES the URL serves, not the deploy command's output -- once wrangler has" -ForegroundColor DarkGray
Write-Host "  deployed a worker, an API upload only creates inactive versions, silently." -ForegroundColor DarkGray
exit 0
