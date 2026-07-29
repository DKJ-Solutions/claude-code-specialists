<#
.SYNOPSIS
    Removes what specialists-init put into a consuming repo, so the repo can stand free of the plugin.

.DESCRIPTION
    The counterpart to bootstrap.ps1, and deliberately its mirror image: where the bootstrap is
    strictly ADDITIVE and never overwrites, the teardown is strictly SUBTRACTIVE and never deletes
    anything the repo owner wrote. Adoption is reversible by design (Dave's requirement, July 29, 2026):
    a consumer must be able to install and uninstall at any moment and afterwards carry no lingering
    reference to a specialist, manual, persona or roster.

    THE CENTRAL RULE. Consumer-side content is three things and only one is disposable, so this script
    classifies before it removes:
      1. Generated and untouched  -> REMOVED. A lens still carrying its VUL-IN marker, a script scaffold
         still carrying its placeholders, the @-imports the bootstrap wrote, settings.suggested.jsonc.
      2. Authored by the owner    -> REPORTED, never touched. A filled-in lens holds repo knowledge
         somebody wrote; deleting it to leave a tidy tree is a worse outcome than leaving clutter.
      3. Owned by the repo anyway -> REPORTED as "yours to keep or drop". A repo-config with real values
         and a filled branch table describe THIS repo's conventions and stay useful with the plugin gone.

    WHAT IT DELIBERATELY DOES NOT DO:
      - It never edits .claude/settings.json. Disabling/uninstalling the plugin is the owner's act, and
        the bootstrap never wrote that file either -- symmetry cuts both ways. It is reported instead.
      - It never removes roster rows or repo-specific prose from CLAUDE.md. Those are authored text in a
        file full of other authored text; the only lines it touches there are the two @-imports, which
        are knowably bootstrap-written and can never be anything else.
      - It never touches the plugin install or cache.

    DRY RUN BY DEFAULT. Nothing is removed unless -Apply is passed. A destructive script that runs on a
    consumer's repo should have to be asked twice, and the preview doubles as the inventory a reader
    needs in order to say yes.

.PARAMETER ConsumerRoot
    Repo root to tear down. Defaults to the current directory.

.PARAMETER Apply
    Actually remove. Without it the script only reports what it would do.

.EXAMPLE
    ./teardown.ps1
    # Preview: what would be removed, what is authored, what is yours to decide.

.EXAMPLE
    ./teardown.ps1 -Apply
#>
param(
    [string]$ConsumerRoot = (Get-Location).Path,
    [switch]$Apply,
    # Regex identifying THIS repo's own "nothing recorded here yet" convention for an empty lens.
    # Left empty on purpose: the plugin recognises the scaffold shapes IT writes and must not guess at
    # a convention it did not create. Measured in a real consumer (davekokbwj/smartwatchbanden,
    # 2026-07-29): 20 of its 22 lenses are empty under that repo's own "schone lei" convention -- a
    # closing sentence in Dutch, no '(VUL-IN)' heading anywhere -- so the teardown kept all 22 and
    # reported them as authored. The prediction "all 22 kept" came out for the WRONG reason, and
    # adoption was therefore less reversible than this skill claimed.
    # Pass e.g. -EmptyLensPattern 'Nog niets vastgelegd' to have those recognised as removable.
    [string]$EmptyLensPattern = ''
)
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $ConsumerRoot).Path
$midDot = [char]0x00B7

Write-Host "== specialists-teardown $midDot $root ==" -ForegroundColor Cyan
if (-not $Apply) {
    Write-Host "   DRY RUN -- nothing will be removed. Re-run with -Apply to act." -ForegroundColor Yellow
}

# Tallies. $kept is the interesting one: it is what makes this safe to run, and it is reported rather
# than silently skipped, because a reader has to know what the script chose NOT to do.
$removed = @()
$kept    = @()
$notes   = @()

function Test-LooksGenerated {
    <# Is this file still an unfilled scaffold?

       A content test rather than a timestamp or hash, deliberately: a consumer may have reformatted
       line endings or been through a merge, and neither makes the content authored.

       CRITICAL: the test keys on an UNFILLED PLACEHOLDER, not on the string 'VUL-IN' appearing
       anywhere. The first version did the latter and would have deleted a fully configured
       repo-config.ps1 in a real consumer -- found by a dry run against davekokbwj/smartwatchbanden on
       2026-07-29, where all eight contract functions carry real values and the only 'VUL-IN' left is
       in the scaffold's own DOCSTRING, which a consumer has no reason to strip. That is not an edge
       case, it is the normal state of a filled-in scaffold, so the naive rule would have removed the
       file that open-pr, fold-changelog, new-branch and check-roster-sync all depend on.

       Third instance of one pattern in a single day -- a content test that matches a MENTION rather
       than a USE. The roster check counted an '@'-import path as a roster row (#227); the lint gate
       read a marker quoted in changelog prose as a real enumeration (#235); this one read a docstring
       explaining placeholders as a placeholder. When a check's evidence is "this string appears in the
       file", ask what else in that file legitimately contains it -- and for a script that DELETES,
       resolve every doubt toward keeping. #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        # 'lens'        -> the scaffold's unfilled slot heading, e.g. '## Specific to this repo (VUL-IN)'
        #                  or the nameless '# 06-16 <dot> repo lens (VUL-IN)' header.
        # 'repo-config' -> an assignment whose VALUE is still a placeholder ($script:LintScript = 'VUL-IN').
        # 'branch-info' -> the empty prefix table the bootstrap writes; a repo that filled its taxonomy
        #                  has entries there, and that is the only signal that cannot be faked by prose.
        [Parameter(Mandatory = $true)][ValidateSet('lens', 'repo-config', 'branch-info')][string]$Kind
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    switch ($Kind) {
        'lens' {
            # The scaffold shape this plugin writes.
            if ($text -match '(?m)^#{1,6}\s.*\(VUL-IN\)\s*$') { return $true }
            # The consumer's own empty-lens convention, only if they told us what it looks like.
            if ($EmptyLensPattern -and ($text -match $EmptyLensPattern)) { return $true }
            return $false
        }
        'repo-config' { return ($text -match "=\s*'[^']*VUL-IN") }
        'branch-info' { return ($text -match '(?m)\$script:BranchPrefixTable\s*=\s*@\{\s*\}') }
    }
    return $false
}

function Remove-IfApplying {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][string]$Label)
    if ($Apply) { Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction Stop }
    $script:removed += $Label
    Write-Host ("  [remove] " + $Label) -ForegroundColor Green
}

# --- 1. Lens files on the plugin path ------------------------------------------------------------
# Both layouts the bootstrap has ever used, so a repo adopted before #179 is torn down too.
$lensDirs = @(
    (Join-Path $root '.claude\plugins'),
    (Join-Path $root '.claude\extensions')
)
foreach ($dir in $lensDirs) {
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    $lenses = @(Get-ChildItem -LiteralPath $dir -Recurse -Filter '*-extension.md' -File -ErrorAction SilentlyContinue)
    foreach ($lens in $lenses) {
        $rel = $lens.FullName.Substring($root.Length).TrimStart('\', '/')
        if (Test-LooksGenerated -Path $lens.FullName -Kind 'lens') {
            Remove-IfApplying -Path $lens.FullName -Label $rel
        } else {
            # Deliberately does NOT say "filled in" or "somebody wrote this". The script cannot
            # establish authorship -- it can only say the file does not match a scaffold shape it
            # recognises. Claiming otherwise was measurably false in a real consumer, where 20 empty
            # lenses were reported as repo knowledge because they used that repo's own convention.
            $kept += $rel
            Write-Host ("  [KEEP]   $rel -- not recognised as an unfilled scaffold; this script does not judge it") -ForegroundColor Yellow
        }
    }
}

# Prune the plugin lens tree only when it is genuinely empty -- an authored lens must not lose its
# directory out from under it.
if ($Apply) {
    foreach ($dir in $lensDirs) {
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        $leftovers = @(Get-ChildItem -LiteralPath $dir -Recurse -File -ErrorAction SilentlyContinue)
        if ($leftovers.Count -eq 0) {
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
            $removed += ($dir.Substring($root.Length).TrimStart('\', '/') + '\ (empty)')
        }
    }
}

# --- 2. The @-imports in CLAUDE.md ---------------------------------------------------------------
# The only lines in that file this script will touch. Safe precisely because an @-import naming a
# persona body or an extension lens is bootstrap-written and cannot be anything else -- the same
# property that let check-roster-sync stop counting them as roster rows (issue #227).
$claudeMd = Join-Path $root 'CLAUDE.md'
if (Test-Path -LiteralPath $claudeMd -PathType Leaf) {
    $text0 = [System.IO.File]::ReadAllText($claudeMd, [System.Text.Encoding]::UTF8)
    $lines = [System.IO.File]::ReadAllLines($claudeMd)
    $isSpecialistImport = {
        param($line)
        ($line -match '^\s*@') -and ($line -match '(-persona\.md|-extension\.md)\s*$')
    }
    # The explanatory line the bootstrap writes above the imports. Removed too, and matched on its
    # LITERAL generated wording only -- a consumer who reworded or translated it has authored that
    # text. Leaving it behind is what made the round-trip accumulate a copy per cycle: the bootstrap's
    # guard saw the paragraph gone-but-not-gone and re-appended the whole block (measured 1 -> 2 -> 3
    # in davekokbwj/smartwatchbanden, 2026-07-29, with every gate reporting "in sync").
    $bootstrapNote = 'The orchestrator (Chris) is always loaded -- portable body from plugin install and repo lens'
    $noteHits = @($lines | Where-Object { $_.Trim() -eq $bootstrapNote })
    foreach ($n in $noteHits) {
        Write-Host "  [remove] CLAUDE.md: the bootstrap's orchestrator note line" -ForegroundColor Green
        $removed += "CLAUDE.md: bootstrap orchestrator note line"
    }

    $hits = @($lines | Where-Object { & $isSpecialistImport $_ })
    if ($hits.Count -gt 0 -or $noteHits.Count -gt 0) {
        foreach ($hit in $hits) {
            Write-Host ("  [remove] CLAUDE.md import: " + $hit.Trim()) -ForegroundColor Green
            $removed += ('CLAUDE.md import: ' + $hit.Trim())
        }
        if ($Apply) {
            $keptLines = @($lines | Where-Object {
                (-not (& $isSpecialistImport $_)) -and ($_.Trim() -ne $bootstrapNote)
            })
            # Trailing blank lines the imports left behind, so the file does not end in a growing gap.
            while ($keptLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($keptLines[-1])) {
                $keptLines = $keptLines[0..($keptLines.Count - 2)]
            }
            # Preserve the file's own line endings. WriteAllLines uses Environment.NewLine, which is
            # right on Windows/CRLF and wrong for an LF-normalised repo; the sibling defect on the
            # bootstrap side pasted LF into a CRLF file and no gate saw it.
            $nl = if ($text0 -match "`r`n") { "`r`n" } else { "`n" }
            [System.IO.File]::WriteAllText($claudeMd, (($keptLines -join $nl) + $nl))
        }
    }
    # Everything else in CLAUDE.md is authored text, and a roster row is not distinguishable from
    # ordinary prose by any rule this script could apply safely. Reported as the owner's call.
    $rosterish = @($lines | Where-Object { $_ -match '(?<![\d-])\d{2}-\d{2}(?![\d])' -and $_ -notmatch '^\s*@' })
    if ($rosterish.Count -gt 0) {
        $notes += "CLAUDE.md still holds $($rosterish.Count) line(s) mentioning a specialist id (the roster table, the routing, the chains). Authored text -- remove the sections you no longer want by hand. This script will not guess where a roster row ends and your own prose begins."
    }
}

# --- 3. Script-config scaffolds ------------------------------------------------------------------
# Category 3: these describe THIS repo's conventions (its branch taxonomy, its lint gate) and stay
# useful with the plugin gone. Removed only while still untouched placeholders.
foreach ($pair in @(
    @{ Rel = 'scripts\repo-config.ps1';     What = 'repo config';      Kind = 'repo-config' },
    @{ Rel = 'scripts\lib\branch-info.ps1'; What = 'branch taxonomy';  Kind = 'branch-info' }
)) {
    $path = Join-Path $root $pair.Rel
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    if (Test-LooksGenerated -Path $path -Kind $pair.Kind) {
        Remove-IfApplying -Path $path -Label $pair.Rel
    } else {
        $kept += $pair.Rel
        Write-Host ("  [KEEP]   $($pair.Rel) -- filled in; it describes this repo's $($pair.What), which outlives the plugin") -ForegroundColor Yellow
    }
}

# --- 4. The settings proposal --------------------------------------------------------------------
# A proposal the bootstrap prints for the owner to merge. If it is still lying around it was never
# merged, so it is pure leftover.
$suggested = Join-Path $root '.claude\settings.suggested.jsonc'
if (Test-Path -LiteralPath $suggested -PathType Leaf) {
    Remove-IfApplying -Path $suggested -Label '.claude\settings.suggested.jsonc'
}

# --- 5. What only the owner can do ---------------------------------------------------------------
# Reported, never done. Disabling the plugin is the actual uninstall, and the bootstrap never wrote
# settings.json either -- the symmetry that keeps this script safe to run cuts both ways.
$settings = Join-Path $root '.claude\settings.json'
if (Test-Path -LiteralPath $settings -PathType Leaf) {
    $text = [System.IO.File]::ReadAllText($settings, [System.Text.Encoding]::UTF8)
    if ($text -match 'specialists') {
        $notes += ".claude/settings.json still enables the plugin. That file is yours -- this script never edits it. Remove the entry from 'enabledPlugins' (and the marketplace source, if nothing else uses it), then restart the session. Until then the subagents and the session hooks stay active."
    }
}
$notes += "The plugin install itself is untouched: run 'claude plugin uninstall' if you want it gone from this machine as well."

# --- Summary --------------------------------------------------------------------------------------
Write-Host ''
# "kept", not "kept (authored)". The script cannot establish authorship, and saying so was measurably
# wrong: 20 empty lenses in a real consumer were reported as authored because they used that repo's own
# convention rather than this plugin's scaffold shape.
Write-Host ("Summary: " + $removed.Count + " item(s) " + $(if ($Apply) { 'removed' } else { 'to remove' }) + ", " + $kept.Count + " kept.") -ForegroundColor Cyan
if ($kept.Count -gt 0) {
    Write-Host "  Kept -- not recognised as an unfilled scaffold. Review them: some may be empty under a" -ForegroundColor Yellow
    Write-Host "  convention this plugin does not know, in which case they are yours to delete (or re-run" -ForegroundColor Yellow
    Write-Host "  with -EmptyLensPattern '<your marker>' to have them recognised):" -ForegroundColor Yellow
    foreach ($k in $kept) { Write-Host "    $k" }
}
foreach ($n in $notes) { Write-Host "  [note] $n" }
if (-not $Apply -and $removed.Count -gt 0) {
    Write-Host "  Re-run with -Apply to remove the $($removed.Count) item(s) above." -ForegroundColor Yellow
}
exit 0
