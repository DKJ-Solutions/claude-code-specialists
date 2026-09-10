<#
.SYNOPSIS
    Which scripts of THIS tree a consumer's CI runners reach into, and whether those paths still
    exist here. Issue #1805.

.DESCRIPTION
    WHAT BROKE, AND WHY NOTHING SAID SO. Three runners this workflow scaffolds into a consumer --
    branch-entry.yml from adopt-workflow-folder.ps1, fold-on-merge.yml and verify-resolved.yml from
    adopt-merge-queue.ps1 -- do not vendor the script they run. They check THIS repository out beside
    the consumer's own tree and run a path into it:

        - uses: actions/checkout@v5
          with:
            repository: DKJ-Solutions/claude-code-specialists
            ref: main
            path: .workflow-scripts
        - run: powershell ... -File .workflow-scripts/plugins/dkj-policy/scripts/lint/check-branch-entry.ps1

    That is deliberate and stays: there is ONE definition of the entry gate, of the fold and of the
    resolves check in this system, and a vendored copy would be a second one, free to drift. The cost
    is a dependency pointing the wrong way -- a path INTO this tree, written into a file this tree
    cannot reach, by a scaffolder that runs once at adoption and never again.

    So when `plugins/workflows/contributing-davekjohn/` became `plugins/dkj-policy/`, every consumer
    scaffolded before the move kept naming the old path. Measured September 10, 2026 (#1805):
    `DaveKJohn/thumbnail-generator` and `DaveKJohn/life-hub` had been red on every pull request since
    August 3 -- five weeks -- and neither had been noticed, because neither repo had opened a pull
    request since the break.

    THE `ref: main` PIN IS NOT THE DEFECT, AND WAS NOT WHAT WENT UNARGUED. adopt-dkj-policy/SKILL.md
    argues the pin by name: a pinned tag keeps enforcing the shape it was pinned at, and the ENTRY's
    own path has moved twice, so a stale pin does not fail loudly -- it refuses branches that do carry
    an entry at the current path. That is right, and this lib does not reopen it. What the argument
    never weighed is the other half of the same trade: tracking the tip protects a consumer from a
    stale convention and exposes it to a moved SCRIPT. This lib is what covers that exposure, which
    is why the pin can stay.

    AND THE TESTS DID NOT CATCH IT BECAUSE THEY PINNED THE LITERAL. adopt-merge-queue.tests.ps1
    asserted `$fold -like '*.workflow-scripts/plugins/dkj-policy/scripts/...*'` -- that the scaffolder
    EMITS that string. Moving the script in this tree leaves that assertion green: it compares the
    emitted text against itself. The two callers of this lib close both ends of that:

      * the scaffolder suites read the emitted runners back through Get-SharedScriptReference and
        assert every referenced path EXISTS in this tree, so a move here goes red on the day it lands
        rather than in somebody else's repository five weeks later;
      * check-connectors.ps1 reads the runners a REGISTERED CONSUMER has already got, so a path
        written before a move is reported from the register instead of discovered by a red gate.

    Only the second reaches a repo that adopted in August. That distinction is the whole reason this
    is a lib and not a test helper: a repair that must reach an already-adopted consumer cannot live
    in the thing that is written once.

    THE CHECKOUT IS MATCHED ON THE REPOSITORY *NAME*, NEVER THE OWNER, and that is a decision rather
    than laziness. This repo was transferred from `DaveKJohn` to `DKJ-Solutions` on September 2, 2026,
    and a consumer scaffolded before that names the old owner -- which still works, through a transfer
    redirect. Matching `owner/name` would skip those files entirely and report nothing about them:
    the same silence this lib exists to end, arriving through the guard itself. What the match has to
    answer is "does this checkout step bring in the tree I am judging", and the name answers it for a
    redirect, a fork and an org move alike. An old-owner citation is a real finding, but a different
    one (#1526's subject), and it is not made here.

    THE PREFIX IS READ FROM THE FILE, NOT ASSUMED TO BE `.workflow-scripts`. The scaffolders write
    that value and nothing stops a consumer changing it; a hard-coded prefix would go quietly blind on
    exactly the repo that had edited its own runner. It costs one more line of parsing to read the
    `path:` the checkout step actually declares.

    NO YAML PARSER, AND THE BOUND THAT MAKES THAT HONEST. This walks lines and matches two keys inside
    one `with:` block by indentation. That is not YAML and cannot be: a quoted multi-line scalar or a
    flow mapping would defeat it. What it is asked to read are files THIS workflow wrote, in a shape
    these scaffolders control and their own suites assert -- and where it fails to recognise a
    checkout step it yields nothing, so an unreadable runner is invisible rather than misreported.
    A finding here is therefore always about a path that IS named; the absence of one is never
    evidence that a consumer is clean. Adding a parser dependency to a lint that must run on a bare
    Windows PowerShell 5.1 in a consumer with no modules installed is the cost this declines to pay.
#>

Set-StrictMode -Version Latest

function Get-SharedScriptReference {
    <#
        Every script path a workflow file reaches into a checkout of $RepositoryName for.

        Returns one record per DISTINCT path: @{ Path; Prefix; Repository; Line }, where Path is
        repo-relative to the checked-out tree with forward slashes ('plugins/dkj-policy/scripts/...'),
        Prefix is the local directory the step checks it out into, Repository is the `repository:`
        value as written (so a caller can name the owner the consumer cited), and Line is the
        1-based line of the first reference.

        Distinct by Path: fold-on-merge.yml names two scripts and would name one of them twice if a
        step retried it, and a reader wants one finding per broken path rather than one per mention.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyString()][AllowNull()][string]$WorkflowText,
        [Parameter(Mandatory)][string]$RepositoryName
    )

    if ([string]::IsNullOrWhiteSpace($WorkflowText)) { return @() }

    $lines = $WorkflowText -split "`r?`n"

    # --- 1. Which local prefixes hold a checkout of this repository -----------------------------
    # A `repository:` whose name half matches, then the `path:` of the SAME `with:` block -- same
    # indentation, before the block ends (a line indented less than the key, ignoring blanks). A
    # checkout step with no `path:` lands in the workspace root itself, which this deliberately does
    # NOT treat as a prefix: every reference in the file would then look like one of ours, including
    # the consumer's own scripts. The scaffolders always write a path, so that shape is somebody
    # else's checkout step and not this lib's business.
    $prefixes = @{}
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $m = [regex]::Match($lines[$i], '^(?<ind>[ \t]*)repository:[ \t]*["'']?(?<repo>[^"''\r\n#]+?)["'']?[ \t]*$')
        if (-not $m.Success) { continue }

        $repo = $m.Groups['repo'].Value.Trim()
        $name = $repo.Substring($repo.LastIndexOf('/') + 1)
        if (-not [string]::Equals($name, $RepositoryName, [System.StringComparison]::OrdinalIgnoreCase)) { continue }

        $indent = $m.Groups['ind'].Value
        for ($j = $i + 1; $j -lt $lines.Count; $j++) {
            $line = $lines[$j]
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            $lead = [regex]::Match($line, '^[ \t]*').Value
            if ($lead.Length -lt $indent.Length) { break }
            if ($lead.Length -gt $indent.Length) { continue }

            $p = [regex]::Match($line, '^[ \t]*path:[ \t]*["'']?(?<path>[^"''\r\n#]+?)["'']?[ \t]*$')
            if ($p.Success) {
                $prefix = $p.Groups['path'].Value.Trim().TrimEnd('/', '\')
                if ($prefix) { $prefixes[$prefix] = $repo }
                break
            }
        }
    }
    if ($prefixes.Count -eq 0) { return @() }

    # --- 2. Every '<prefix>/<...>.ps1' token in the file ----------------------------------------
    # Both separators are admitted and normalised to '/': the scaffolders emit forward slashes, but a
    # hand-edited runner on Windows may not, and a reference this lib fails to recognise is a finding
    # it fails to make.
    $seen = @{}
    $found = @()
    foreach ($prefix in $prefixes.Keys) {
        $pattern = '(?<![\w./\\-])' + [regex]::Escape($prefix) + '[/\\](?<rel>[\w./\\-]+?\.ps1)\b'
        for ($i = 0; $i -lt $lines.Count; $i++) {
            foreach ($hit in [regex]::Matches($lines[$i], $pattern)) {
                $rel = ($hit.Groups['rel'].Value -replace '\\', '/')
                if ($seen.ContainsKey($rel)) { continue }
                $seen[$rel] = $true
                $found += [pscustomobject]@{
                    Path       = $rel
                    Prefix     = $prefix
                    Repository = $prefixes[$prefix]
                    Line       = $i + 1
                }
            }
        }
    }

    return @($found)
}

function Test-SharedScriptReference {
    <#
        Does each referenced path still exist in $SourceRoot -- and where a path is gone, where did
        that script go?

        Returns the input records with Exists added, plus MovedTo: the repo-relative paths in
        $SourceRoot carrying the same file name. THE SUGGESTION IS THE POINT OF THE CHECK, not a
        courtesy. "This path no longer exists here" leaves the reader to find out what replaced it in
        a tree they may not have; "it is at plugins/dkj-policy/scripts/lint/check-branch-entry.ps1
        now" is a repair they can paste. Where the name matches nothing, MovedTo is empty and the
        script was removed rather than moved -- which is a different conversation and reads as one.

        A PUBLISHED COPY IS OFFERED BEFORE THE TREE'S OWN. Most scripts here exist twice: the source
        under scripts/, and the mirror under plugins/<plugin>/scripts/ that a release carries. Both
        answer the file-name search and only the second is the one an outside caller may run -- the
        source copy is this repo's own path, correct here and absent from every consumer, which is the
        mistake adopt-merge-queue.tests.ps1 already asserts against in the other direction. So a
        candidate under a plugin folder sorts first, and a reader who takes the first suggestion takes
        the right one. Both are still listed: which plugin publishes it is a question this lib has no
        business answering, and hiding the alternative would make a genuinely ambiguous case look
        settled.

        The recursive search runs ONLY on the failure path, so a clean consumer costs one Test-Path
        per reference. .git is excluded because a packed object tree holds no scripts and walking it
        is the whole cost of the walk.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Reference,
        [Parameter(Mandatory)][string]$SourceRoot
    )

    $results = @()
    foreach ($ref in @($Reference)) {
        $full = Join-Path $SourceRoot ($ref.Path -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        $exists = Test-Path -LiteralPath $full -PathType Leaf

        $movedTo = @()
        if (-not $exists) {
            $leaf = Split-Path -Leaf $ref.Path
            $rootLen = (Resolve-Path -LiteralPath $SourceRoot).Path.TrimEnd('\', '/').Length + 1
            $movedTo = @(
                Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -Filter $leaf -ErrorAction SilentlyContinue |
                    Where-Object { $_.FullName -notmatch '(^|\\|/)\.git(\\|/)' } |
                    ForEach-Object { $_.FullName.Substring($rootLen) -replace '\\', '/' } |
                    Sort-Object -Property @{ Expression = { -not $_.StartsWith('plugins/') } }, @{ Expression = { $_ } }
            )
        }

        $results += [pscustomobject]@{
            Path       = $ref.Path
            Prefix     = $ref.Prefix
            Repository = $ref.Repository
            Line       = $ref.Line
            Exists     = $exists
            MovedTo    = $movedTo
        }
    }

    return @($results)
}
