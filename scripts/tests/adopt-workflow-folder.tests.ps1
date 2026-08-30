<#
.SYNOPSIS
    Tests for scripts/task/adopt-workflow-folder.ps1 -- the scaffold that places the workflow's own
    root folder (contributing-davekjohn/) in a consuming repo.

.DESCRIPTION
    What is covered, and why these four:
      1. the DRY RUN default writes nothing -- the same contract adopt-config is trusted on;
      2. -Apply places every file the folder promises, with the branch files in the reset shape the
         shared formatters write -- and the releases page carrying NO history table, since the list
         belongs at the repo root (inbound #786);
      3. a re-run is additive: a file somebody edited is never overwritten, whatever it says;
      4. a repo that publishes plugins is refused -- the source keeps its docs at its root (Dave,
         August 14, 2026), so the scaffold must not build the layout its owner declined.

    The repo root is pinned per child run via CLAUDE_PROJECT_DIR, the same dual-context branch every
    mirrored script resolves first, so the fixtures need no git of their own.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\task\adopt-workflow-folder.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "adopt-workflow-folder-test-fixture-$PID"

# Dot-sourced for ONE constant: Get-EntryHeadingLevel, which the scaffolded CHANGELOG intro is asserted
# against rather than against a literal '###' (inbound #1098). The lib is pure and loads no state.
. (Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1')

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

function Assert-Match {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern not found: '$Pattern'" -ForegroundColor Red
    }
}

function New-FixtureConsumer {
    <#
        -AsWorkflowSource writes a marketplace that publishes THIS workflow; -AsOtherPluginSource writes
        one that publishes something else. The second shape used to be unreachable: the switch was
        -AsPluginSource and wrote an empty '{}', because the refusal was `Test-Path marketplace.json` and
        any manifest would do. Issue #998 (August 27, 2026) narrowed it, so the fixture has to say WHAT is
        published, and the two cases are now distinguishable -- which is the whole point.
    #>
    param(
        [string]$Label, [switch]$AsWorkflowSource, [switch]$AsOtherPluginSource,
        # -WithRepoConfig writes the lib the note-root seam is appended to; -NoteRootAnswer puts an answer
        # in it; -WithFallbackNotes puts a note at the shared 'releases/notes' fallback. Together they are
        # the three conditions the seam write is gated on (issue #1150), so every branch is reachable here.
        [switch]$WithRepoConfig, [string]$NoteRootAnswer, [switch]$WithFallbackNotes
    )
    $root = Join-Path $Fixture "consumer-$Label"
    if (Test-Path -LiteralPath $root) { Remove-Item -Recurse -Force -LiteralPath $root }
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    if ($WithRepoConfig -or $NoteRootAnswer) {
        $cfg = "# This repo's own seam answers.`n"
        if ($NoteRootAnswer) { $cfg += "function Get-ReleaseNoteRoot { '$NoteRootAnswer' }`n" }
        New-Item -ItemType Directory -Path (Join-Path $root 'scripts') -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $root 'scripts\repo-config.ps1'), $cfg)
    }
    if ($WithFallbackNotes) {
        New-Item -ItemType Directory -Path (Join-Path $root 'releases\notes\0.x') -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $root 'releases\notes\0.x\0.1.0.md'), "# 0.1.0`n")
    }
    if ($AsWorkflowSource -or $AsOtherPluginSource) {
        $plugin = if ($AsWorkflowSource) { 'contributing-davekjohn' } else { 'some-other-product' }
        $manifest = '{ "name": "fixture", "plugins": [ { "name": "' + $plugin + '", "source": "./x" } ] }'
        New-Item -ItemType Directory -Path (Join-Path $root '.claude-plugin') -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $root '.claude-plugin\marketplace.json'), $manifest)
    }
    return $root
}

function Invoke-Adopt {
    param([string]$Dir, [string[]]$ScriptArgs = @())
    $prevPd = $env:CLAUDE_PROJECT_DIR
    try {
        $env:CLAUDE_PROJECT_DIR = $Dir
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script @ScriptArgs
        # Flat is FOR PHRASE ASSERTS ONLY: the child wraps its Write-Host lines at its own host width,
        # a point that moves with the console and with the fixture's temp path length, so a phrase
        # sitting mid-line arrives split MID-WORD across two records. Joined with '' rather than a
        # space because the break is a hard one at a column, so the halves reconstruct exactly --
        # prune-merged.tests.ps1's Get-FlatOutput carries the full reasoning, and #982/#959 are the two
        # suites this class had already turned red. Out keeps the line structure for the [create]/
        # [exists] asserts, which are per-line and must stay that way.
        return [pscustomobject]@{
            Code = $LASTEXITCODE
            Out  = ($out -join "`n")
            Flat = (($out | ForEach-Object { [string]$_ }) -join '')
        }
    } finally {
        if ($null -eq $prevPd) { Remove-Item Env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    }
}

# Every file -Apply must place. Read from the same claim the script makes rather than restated per
# assert, so a target added there fails ONE list here instead of passing unexamined.
$ExpectedFiles = @(
    'contributing-davekjohn\README.md',
    'contributing-davekjohn\CONTRIBUTING.md',
    'contributing-davekjohn\releases\README.md'
)

try {
    Write-Host "== adopt-workflow-folder.tests: scripts/task/adopt-workflow-folder.ps1 ==" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null

    # --- 1. Dry run (the default): the plan is printed, nothing is written -------------------------
    Write-Host "adopt-workflow-folder -- dry run writes nothing" -ForegroundColor Cyan
    $c1 = New-FixtureConsumer -Label 'dryrun'
    $r1 = Invoke-Adopt -Dir $c1
    Assert-Equal 0 $r1.Code 'dry run: exit 0'
    Assert-Match 'DRY RUN' $r1.Out 'dry run: says so out loud'
    Assert-Match '\[create\]\s+contributing-davekjohn/README\.md' $r1.Out 'dry run: lists the folder README as to-create'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $c1 'contributing-davekjohn'))) 'dry run: the folder was not created'

    # --- 2. -Apply places the whole folder ----------------------------------------------------------
    Write-Host "adopt-workflow-folder -- -Apply places every file" -ForegroundColor Cyan
    $c2 = New-FixtureConsumer -Label 'apply'
    $r2 = Invoke-Adopt -Dir $c2 -ScriptArgs @('-Apply')
    Assert-Equal 0 $r2.Code '-Apply: exit 0'
    foreach ($rel in $ExpectedFiles) {
        Assert-True (Test-Path -LiteralPath (Join-Path $c2 $rel) -PathType Leaf) "-Apply: $rel exists"
    }
    # THE BRANCH DOCUMENT IS NOT PLACED, and that is this adopter's half of the lifetime rule (Dave,
    # August 23, 2026). It used to be written here in its reset state, so a consumer's first look at the
    # folder was also their reference. The document exists only while a branch is open now, so placing one
    # would hand them a file their own first fold deletes -- the only entry in this list that is not
    # permanently theirs.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $c2 'contributing-davekjohn\development.md'))) '-Apply: the branch document is NOT placed -- it lives only while a branch is open'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $c2 'contributing-davekjohn\branch'))) '-Apply: and no branch/ directory is placed any more'
    # NEITHER IS THE AUDIENCE ROOT (issue #1150). It was placed as a .gitkeep on the stated ground that
    # "the audience root must exist before the first cut writes into it" -- a premise cut-release itself
    # contradicts: it creates the note's own parent before writing. So the file bought nothing, while what
    # it did buy was an empty committed directory asserting a destination the unanswered seam did not use.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $c2 'contributing-davekjohn\releases\audience'))) '-Apply: the audience root is NOT placed -- the first cut creates it'
    # THE FOLDER PAGE MUST NOT CARRY A HISTORY TABLE, and this assert is the regression guard on inbound
    # #786. It did until August 20, 2026: the page was scaffolded with a '## Release history' heading, a
    # table, and a VUL-IN promising that the cut would insert its rows there -- while this same command's
    # closing advice told the reader to leave Get-ReleaseHistoryPath at the repo root. Two statements in
    # one run that cannot both be true, and the consumer who followed the advice got a table that stays
    # empty forever. The page now points at the seam's answer instead.
    $relText = [System.IO.File]::ReadAllText((Join-Path $c2 'contributing-davekjohn\releases\README.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($relText -notmatch '\| Version \| Date \| Type \| Title \|') '-Apply: the folder page carries NO history table (the list is not here)'
    # MATCHED ON THE LIST'S OWN PATH, not on 'releases/README.md'. That was the pattern until
# August 27, 2026, and it was passing on the wrong sentence: the scaffolded page names the seam's answer
# in one place and mentioned 'releases/README.md' in another, as a comparison with the source repo's
# layout, so removing the comparison turned this assert red while the thing it checks was untouched. The
# list's filename is what the assert is about.
Assert-Match 'releases/history\.md' $relText '-Apply: it names where the list actually lives instead'
    # THE CHANGELOG INTRO STATES THE LEVEL THE FOLD ACTUALLY WRITES (inbound #1098). It said '##' while the
    # fold has written '###' since the levels shifted, so the one piece of prose a consumer ever reads ABOUT
    # their own changelog contradicted the first entry three lines below it. Nothing breaks, which is why it
    # survived a release: no gate compares the two, and the first person to notice is somebody debugging why
    # their hand-written '##' entry did not fold.
    #
    # ASSERTED AGAINST Get-EntryHeadingLevel RATHER THAN AGAINST '###'. Pinning the literal would pass while
    # the sentence went stale again at the next shift, which is exactly the failure being repaired -- and it
    # would also turn red for a repo that legitimately overrode the level. The constant is the claim.
    $clText = [System.IO.File]::ReadAllText((Join-Path $c2 'contributing-davekjohn\CHANGELOG.md'), [System.Text.Encoding]::UTF8)
    $entryHashes = '#' * (Get-EntryHeadingLevel)
    Assert-Match ('one `' + $entryHashes + '` per change') $clText '-Apply: the changelog intro states the heading level the fold writes'
    Assert-True ($clText -notmatch 'one `#{1,2}` per change') '-Apply: and no longer states a shallower one'

    # And the closing block names the two seams only this repo can answer.
    Assert-Match 'Get-ReleaseNoteRoot' $r2.Out '-Apply: the next-steps block names Get-ReleaseNoteRoot'
    Assert-Match 'Get-ReleaseHistoryPath' $r2.Out '-Apply: and Get-ReleaseHistoryPath'

    # --- 3. Additive: a re-run never overwrites what somebody wrote --------------------------------
    Write-Host "adopt-workflow-folder -- re-run keeps every existing file" -ForegroundColor Cyan
    $marker = '# HAND-EDITED -- the scaffold must never win over this line'
    [System.IO.File]::WriteAllText((Join-Path $c2 'contributing-davekjohn\CONTRIBUTING.md'), $marker)
    $r3 = Invoke-Adopt -Dir $c2 -ScriptArgs @('-Apply')
    Assert-Equal 0 $r3.Code 're-run: exit 0'
    Assert-Match '\[exists\]\s+contributing-davekjohn/CONTRIBUTING\.md' $r3.Out 're-run: the edited file is reported as left alone'
    $kept = [System.IO.File]::ReadAllText((Join-Path $c2 'contributing-davekjohn\CONTRIBUTING.md'), [System.Text.Encoding]::UTF8)
    Assert-Equal $marker $kept 're-run: the hand-edited content survives byte for byte'

    # --- 4. THE SOURCE OF THIS WORKFLOW is refused ---------------------------------------------------
    Write-Host "adopt-workflow-folder -- refused in the source of this workflow" -ForegroundColor Cyan
    $c4 = New-FixtureConsumer -Label 'source' -AsWorkflowSource
    $r4 = Invoke-Adopt -Dir $c4 -ScriptArgs @('-Apply')
    Assert-Equal 1 $r4.Code 'workflow source: exit 1'
    Assert-Match 'REFUSED' $r4.Out 'workflow source: says it is refusing, and why'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $c4 'contributing-davekjohn'))) 'workflow source: nothing was written'

    # --- 4b. A repo that publishes OTHER plugins is NOT refused (issue #998) -------------------------
    # THE CASE THIS SCRIPT USED TO GET WRONG, and the harm was concrete: the refusal was `Test-Path
    # marketplace.json`, so a repo publishing an unrelated product was told it "arranges
    # contributing-davekjohn/ by hand" and turned away from the one command that scaffolds the folder it
    # needs. Under Dave's own one-product-one-repository rule that repo is the next product, and it
    # consumes this workflow like any other consumer.
    Write-Host "adopt-workflow-folder -- a repo publishing OTHER plugins is a consumer" -ForegroundColor Cyan
    $cOther = New-FixtureConsumer -Label 'other-source' -AsOtherPluginSource
    $rOther = Invoke-Adopt -Dir $cOther -ScriptArgs @('-Apply')
    Assert-Equal 0 $rOther.Code 'other plugins: exit 0 -- not refused'
    Assert-True ($rOther.Out -notmatch 'REFUSED') 'other plugins: no refusal in the output'
    Assert-True (Test-Path -LiteralPath (Join-Path $cOther 'contributing-davekjohn\README.md')) 'other plugins: the folder really was scaffolded'

    # --- 5. The two generated note roots #914 moved (issue #955) -------------------------------------
    # BOTH DIRECTIONS ARE ASSERTED, and the silent one is the half that matters. A warning that fires
    # unconditionally is one every consumer learns to scroll past, and this block exists precisely
    # BECAUSE the two sibling seams' warnings were noticed. So: it names the resolved roots always, and
    # it warns only where a pre-#914 tree is genuinely still sitting at the repo root.
    #
    # Asserted on Flat, not Out: these phrases sit mid-line in a Write-Host the child wraps at its own
    # width, which is the exact shape that turned seam-lib and internal-note red (#982, #959).
    Write-Host "adopt-workflow-folder -- the two note roots #914 moved" -ForegroundColor Cyan
    $c5 = New-FixtureConsumer -Label 'strandednotes'
    New-Item -ItemType Directory -Path (Join-Path $c5 'releases\development\2.x') -Force | Out-Null
    1..3 | ForEach-Object {
        [System.IO.File]::WriteAllText((Join-Path $c5 "releases\development\2.x\2.$_.0.md"), "note $_")
    }
    New-Item -ItemType Directory -Path (Join-Path $c5 'releases\github\2.x') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $c5 'releases\github\2.x\2.1.0.md'), 'body')
    $r5 = Invoke-Adopt -Dir $c5
    Assert-Equal 0 $r5.Code 'stranded notes: exit 0 -- this is a warning, never a refusal'
    Assert-Match 'Get-ReleaseChangelogNotesRoot ->' $r5.Flat 'stranded notes: the changelog-notes root is named with its resolved answer'
    Assert-Match 'Get-ReleaseGithubNotesRoot' $r5.Flat 'stranded notes: and so is the github-notes root'
    Assert-Match 'a generated-notes tree is still sitting at' $r5.Flat 'stranded notes: the re-adoption warning fires'
    Assert-Match 'releases/development/  -- 3 \.md file' $r5.Flat 'stranded notes: it names the tree AND counts what is in it, so the reader can see the scale'
    Assert-Match 'releases/github/  -- 1 \.md file' $r5.Flat 'stranded notes: for both roots, not just the first'
    Assert-Match 'git mv the tree' $r5.Flat 'stranded notes: and it offers the migrate answer'
    Assert-Match 'define the seam in' $r5.Flat 'stranded notes: and the repoint answer, because both are honest'

    # THE SILENT CASE. A fresh consumer has no such tree and must not be warned about one.
    Write-Host "adopt-workflow-folder -- no stranded tree, no warning" -ForegroundColor Cyan
    $c6 = New-FixtureConsumer -Label 'nonotes'
    $r6 = Invoke-Adopt -Dir $c6
    Assert-Equal 0 $r6.Code 'no stranded tree: exit 0'
    Assert-Match 'Get-ReleaseChangelogNotesRoot ->' $r6.Flat 'no stranded tree: the resolved roots are still named'
    Assert-True ($r6.Flat -notmatch 'a generated-notes tree is still sitting at') 'no stranded tree: and the warning stays silent'

    # --- 6. The note-root seam: answered for a fresh adoption, never for anybody else (issue #1150) ---
    # THE CONTRADICTION THIS BLOCK GUARDS. This command scaffolded contributing-davekjohn/releases/audience/
    # and its own pages said the cut drafts the note there, while Get-ReleaseNoteRoot's shared fallback
    # writes to releases/notes/ at the repo root. Both statements are produced by the same run, so one
    # clean adoption plus one clean release left a fresh consumer with an empty committed directory and
    # their note outside the folder the adoption had just built.
    #
    # ALL FOUR BRANCHES ARE ASSERTED, and the three that DECLINE are the half that matters -- the write is
    # only safe because it is narrow, so a test that covered the write alone would pass while the guard
    # rotted. Each case also asserts what the SCAFFOLDED PAGE says, because that page naming a destination
    # the seam does not resolve to is the defect itself rather than a side effect of it.
    $NoteSentence = 'the cut drafts the hand-written note'

    Write-Host "adopt-workflow-folder -- fresh adoption: the note-root seam is answered" -ForegroundColor Cyan
    $c7 = New-FixtureConsumer -Label 'seam-fresh' -WithRepoConfig
    $r7 = Invoke-Adopt -Dir $c7 -ScriptArgs @('-Apply')
    Assert-Equal 0 $r7.Code 'seam fresh: exit 0'
    $cfg7 = [System.IO.File]::ReadAllText((Join-Path $c7 'scripts\repo-config.ps1'), [System.Text.Encoding]::UTF8)
    Assert-Match 'function Get-ReleaseNoteRoot' $cfg7 'seam fresh: the answer was written into scripts/repo-config.ps1'
    Assert-Match "'contributing-davekjohn/releases/audience'" $cfg7 'seam fresh: and it points into the folder this run just scaffolded'
    # THE GENERATED SOURCE IS PARSED, not merely matched. This block writes PowerShell into somebody
    # else's lib, and the failure mode it already produced once in development is a file that greps
    # correctly and does not parse -- an array literal splits an unparenthesised 'a' + $x + 'b' into three
    # elements, so -join wrote the seam's own path across three lines as an unterminated string. A regex
    # assert passes on that; every later run of every shared script does not.
    $perr = $null
    [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $c7 'scripts\repo-config.ps1'), [ref]$null, [ref]$perr) | Out-Null
    Assert-Equal 0 @($perr).Count 'seam fresh: the lib it wrote into still parses as PowerShell'
    $con7 = [System.IO.File]::ReadAllText((Join-Path $c7 'contributing-davekjohn\CONTRIBUTING.md'), [System.Text.Encoding]::UTF8)
    Assert-Match ('`releases/audience/` is where\s+' + $NoteSentence) $con7 'seam fresh: and the scaffolded page names that same destination'

    Write-Host "adopt-workflow-folder -- notes already at the fallback: the seam is left alone" -ForegroundColor Cyan
    $c8 = New-FixtureConsumer -Label 'seam-hasnotes' -WithRepoConfig -WithFallbackNotes
    $r8 = Invoke-Adopt -Dir $c8 -ScriptArgs @('-Apply')
    Assert-Equal 0 $r8.Code 'seam has-notes: exit 0 -- declining is never a refusal'
    $cfg8 = [System.IO.File]::ReadAllText((Join-Path $c8 'scripts\repo-config.ps1'), [System.Text.Encoding]::UTF8)
    Assert-True ($cfg8 -notmatch 'Get-ReleaseNoteRoot') 'seam has-notes: NOTHING was written into their lib'
    Assert-True (Test-Path -LiteralPath (Join-Path $c8 'releases\notes\0.x\0.1.0.md')) 'seam has-notes: and their existing note was not touched'
    Assert-Match 'left UNANSWERED' $r8.Flat 'seam has-notes: the run says out loud that it declined'
    $con8 = [System.IO.File]::ReadAllText((Join-Path $c8 'contributing-davekjohn\CONTRIBUTING.md'), [System.Text.Encoding]::UTF8)
    Assert-Match ('`releases/notes/` at your repo root is where\s+' + $NoteSentence) $con8 'seam has-notes: and the page names where their notes ACTUALLY go'

    Write-Host "adopt-workflow-folder -- an answer already given always wins" -ForegroundColor Cyan
    $c9 = New-FixtureConsumer -Label 'seam-answered' -NoteRootAnswer 'my/own/notes'
    $r9 = Invoke-Adopt -Dir $c9 -ScriptArgs @('-Apply')
    Assert-Equal 0 $r9.Code 'seam answered: exit 0'
    $cfg9 = [System.IO.File]::ReadAllText((Join-Path $c9 'scripts\repo-config.ps1'), [System.Text.Encoding]::UTF8)
    Assert-Equal 1 ([regex]::Matches($cfg9, 'function Get-ReleaseNoteRoot').Count) 'seam answered: their function was not duplicated or overwritten'
    Assert-Match 'already answered here' $r9.Flat 'seam answered: the run reports it as left alone'
    $con9 = [System.IO.File]::ReadAllText((Join-Path $c9 'contributing-davekjohn\CONTRIBUTING.md'), [System.Text.Encoding]::UTF8)
    Assert-Match ('`my/own/notes/` at your repo root is where\s+' + $NoteSentence) $con9 'seam answered: and the page names THEIR answer, not the source''s'

    # NO LIB TO WRITE INTO. specialists-init owns that file's existence, exactly as adopt-config says when
    # it stops -- so this run scaffolds the folder and reports the seam instead of half-creating a lib.
    Write-Host "adopt-workflow-folder -- no repo-config.ps1: the folder still lands, the seam is reported" -ForegroundColor Cyan
    $c10 = New-FixtureConsumer -Label 'seam-noconfig'
    $r10 = Invoke-Adopt -Dir $c10 -ScriptArgs @('-Apply')
    Assert-Equal 0 $r10.Code 'seam no-config: exit 0'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $c10 'scripts\repo-config.ps1'))) 'seam no-config: no lib was conjured up'
    Assert-True (Test-Path -LiteralPath (Join-Path $c10 'contributing-davekjohn\README.md')) 'seam no-config: the folder was scaffolded anyway'
    Assert-Match 'has no scripts/repo-config\.ps1' $r10.Flat 'seam no-config: and the run says why the seam is unanswered'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
