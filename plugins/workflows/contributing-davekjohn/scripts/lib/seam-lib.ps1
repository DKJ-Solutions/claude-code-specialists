<#
.SYNOPSIS
    Get-SeamValue: read an optional repo-config seam function, falling back to a default when the repo
    does not define it. Get-Default*: the computed defaults for the changelog and release-note-root seams
    (issue #885) -- source keeps its root files, consumer is isolated inside the workflow's own root
    folder by default. That folder is NAMED by Get-WorkflowFolderName below and never written out here:
    it renamed once already (#886), and a docstring that states the answer instead of the function goes
    stale the next time it does.

.DESCRIPTION
    ONE DEFINITION, WHERE THERE WERE TWO PLUS THREE INLINE PROBES (issue #885, group A). cut-release.ps1
    and new-internal-note.ps1 each carried a private copy of Get-SeamValue -- byte-different, since only
    the first supported more than one name for a renamed seam -- and fold-changelog-entry.ps1, open-pr.ps1
    and session-status.ps1 each probed inline with `Get-Command Get-X -ErrorAction SilentlyContinue`
    instead of calling either copy. The changelog seam this branch adds is read at three of those sites
    (cut-release.ps1, fold-changelog-entry.ps1, session-status.ps1), so it is the one they read through
    rather than adding a third idiom for one seam.

    ARRAY-CAPABLE ON PURPOSE, kept from cut-release.ps1's copy rather than new-internal-note.ps1's
    single-name one: $Name takes MORE THAN ONE NAME where a seam has been renamed, tried in order, so the
    current name is preferred and a retired one still answers -- a repo that defined the old name receives
    the rename through a plugin update rather than by choosing to, and without the fallback it would drop
    to $Default in silence.

    Dot-source this file:

        . (Join-Path $PSScriptRoot 'seam-lib.ps1')

    Pure ASCII (repo convention for .ps1).
#>

function Get-SeamValue {
    <#
        Calls an optional repo-config function, or returns $Default when the repo does not define it.
        See the file synopsis for why $Name is an array.
    #>
    param([Parameter(Mandatory)][string[]]$Name, $Default)
    foreach ($n in $Name) {
        if (Get-Command $n -ErrorAction SilentlyContinue) { return (& $n) }
    }
    return $Default
}

function Get-DefaultChangelogPath {
    <#
        The changelog seam's computed default, so a repo that configures nothing still gets the right
        answer instead of needing to remember a setting: this repo's own root CHANGELOG.md if it
        publishes plugins (the same one-file test Get-ReleasePluginTier's fallback and
        adopt-workflow-folder.ps1's source refusal already use -- a repo with a
        .claude-plugin/marketplace.json is the workflow's SOURCE, not a consumer, and keeps its root
        file), '<workflow folder>/CHANGELOG.md' otherwise, the folder name coming from
        Get-WorkflowFolderName -- so every consumer is isolated by default and the Get-ChangelogPath seam
        exists only for the repo that wants to differ from that.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    if (Test-Path -LiteralPath (Join-Path $RepoRoot '.claude-plugin\marketplace.json') -PathType Leaf) {
        return 'CHANGELOG.md'
    }
    return "$(Get-WorkflowFolderName -RepoRoot $RepoRoot)/CHANGELOG.md"
}

function Test-IsWorkflowSourceRepo {
    <#
        The one-file test repeated at four sites before this function existed (Get-ReleasePluginTier's
        fallback in repo-config.ps1, adopt-workflow-folder.ps1's source refusal, source-repo-guard-lib.ps1's
        Assert-OwnCopy, and now every computed default in this file): a repo with
        .claude-plugin/marketplace.json is the workflow's SOURCE and keeps its root files; every other repo
        is a consumer and gets the isolated answer. Extracted here for the computed defaults below rather
        than repeated a fifth time -- the other three sites are untouched (issue #885 is about the release
        machinery's own defaults, not a repo-wide dedup of this test).
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    return (Test-Path -LiteralPath (Join-Path $RepoRoot '.claude-plugin\marketplace.json') -PathType Leaf)
}

function Get-WorkflowFolderName {
    <#
        The name of the workflow's own root folder in $RepoRoot: 'contributing-davekjohn' normally, and
        'workflow-davekjohn' where only that one is present.

        WHY THIS EXISTS (#886, August 26, 2026). The folder renamed, and the five seam DEFAULTS below all
        compose a path out of it. Hardcoding the new name would point a consumer's changelog and release
        roots at a directory they do not have, and the fold would then create a second changelog beside the
        one holding their history rather than failing loudly. Hardcoding the old name would send every NEW
        consumer to a folder the scaffolder no longer writes. Neither is a default worth shipping.

        SO: PREFER WHAT EXISTS, which is the same answer Resolve-BranchFilePath gives one level down for the
        documents inside this folder. A repo with neither folder gets the new name, so a writer creates the
        current one; a repo with both gets the new name, because that is what a writer would have made.

        Deliberately NOT a seam. A repo that wants to differ already has Get-ChangelogPath and the four
        release-root seams to say so; a sixth answer for "what is the folder called" would let those five
        disagree with each other.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    $current = 'contributing-davekjohn'
    if (Test-Path -LiteralPath (Join-Path $RepoRoot $current) -PathType Container) { return $current }
    $prior = 'workflow-davekjohn'
    if (Test-Path -LiteralPath (Join-Path $RepoRoot $prior) -PathType Container) { return $prior }
    return $current
}

function Get-DefaultReleaseHistoryPath {
    <#
        The release-history seam's computed default (issue #885, group E), REVERSING the August 19, 2026
        answer rather than silently replacing it -- see script-contract-lib.ps1's Get-ReleaseHistoryPath
        record for why that premise no longer holds. 'releases/README.md' for the source (unchanged: it
        still keeps its root file, same as Get-DefaultChangelogPath), '<workflow folder>/releases/history.md'
        for a consumer -- the folder name from Get-WorkflowFolderName, exactly as above.

        history.md, NOT README.md: that same folder's 'releases/README.md' already names its
        seam-ANSWERS page (adopt-workflow-folder.ps1's own scaffold target). The list and the answers are
        two different documents that happen to share a filename in the source repo only because they sit at
        different directory levels there; folded into one directory they need different names.

        ACCEPTED COST, same as the changelog: an existing consumer's history splits at the point this
        default starts applying to them -- old rows stay at their root file, new rows land here -- rather
        than the seam moving under them silently forever. Repointing the seam back to the old path keeps a
        single list for a consumer who would rather have that.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    if (Test-IsWorkflowSourceRepo -RepoRoot $RepoRoot) { return 'releases/README.md' }
    return "$(Get-WorkflowFolderName -RepoRoot $RepoRoot)/releases/history.md"
}

function Get-DefaultReleaseChangelogNotesRoot {
    <#
        The generated tier-0 notes' (always written) computed default (issue #885, group E; renamed and
        relocated by issue #914, August 26, 2026).

        'changelog', NOT 'development'. The name says what the document IS -- the changelog for that
        version, the entries as the fold left them, which is literally what CHANGELOG.md held before the
        cut emptied it -- rather than which stage of the work produced it. 'development/' named the stage,
        the same mistake 'notes/' and 'highlights/' made in the sibling root that became 'audience/' (see
        Get-ReleaseNoteRoot's own record), and it is the only root under releases/ that still named
        something other than its reader or its content.

        AND IT IS ONE ANSWER FOR BOTH KINDS OF REPO, where every other computed default in this file
        branches on Test-IsWorkflowSourceRepo. Those branch because the source keeps its ROOT files: a
        repo's changelog and its release history exist whichever tooling cut them, so a plugin folder is
        the wrong home for them. This tree is the opposite -- nothing writes it but a cut, so it exists
        only BECAUSE the workflow does, exactly like the hand-written note that already lived in the
        folder. #914 is the decision that the source stops being special here, which REVERSES the
        August 14, 2026 answer recorded at Get-ReleaseNoteRoot ("the generated development/ and github/
        trees stay at the repo root deliberately"). What changed is not that argument's force but its
        subject: it was made while those roots had no seam at all and their location was a fact about
        this repo, and #885 turned them into a seam every consumer answers.

        SO THE BRANCH IS GONE RATHER THAN LEFT RETURNING THE SAME STRING TWICE. A vestigial branch reads
        as a distinction somebody still relies on, and the next reader repairs one half of it.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    return "$(Get-WorkflowFolderName -RepoRoot $RepoRoot)/releases/changelog"
}


function Get-DefaultReleaseGithubNotesRoot {
    <# The generated GitHub Release body's computed default (issue #885, group E), relocated into the
       workflow folder by #914 on the same reasoning as Get-DefaultReleaseChangelogNotesRoot above -- read
       that one first, including why it no longer branches on the source. Its NAME was already right: the
       root says who reads it. #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    return "$(Get-WorkflowFolderName -RepoRoot $RepoRoot)/releases/github"
}

function Get-DefaultReleaseInternalNotesRoot {
    <# The generated internal note's (tier 1) computed default (issue #885, group E). Same reasoning and
       same "no prior seam to redefine" argument as Get-DefaultReleaseChangelogNotesRoot -- read that one
       first. Read by new-internal-note.ps1, which is why it exists as its own function rather than being
       folded into the changelog-notes one: the two roots are read by different scripts on different days
       (the cut writes the changelog note at every release; the internal note is a separate, later run). #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    if (Test-IsWorkflowSourceRepo -RepoRoot $RepoRoot) { return 'releases/internal' }
    return "$(Get-WorkflowFolderName -RepoRoot $RepoRoot)/releases/internal"
}

function Get-PreIsolationSeamPath {
    <#
        THE ANSWER EACH ISOLATED SEAM GAVE BEFORE IT ISOLATED (issue #956, August 27, 2026), and the only
        value Assert-WorkflowIsolatedSeamPath below accepts outside the workflow folder. One entry per
        seam in that assert's set, and nothing else: this is a lookup of history, not a list of
        preferences.

        WHY IT EXISTS. #885 and #914 moved these seams' defaults into the workflow folder, and a consumer
        meets that through a plugin update rather than by choosing to -- exactly the situation the assert
        already tolerates for the FOLDER's own rename. A consumer that keeps its CHANGELOG.md at the repo
        root is not an un-migrated state to be corrected but a layout, and both Shopify consumers answered
        the seam that way independently (#956: smartwatchbanden and xoxowildhearts, 14 and 24 pending
        entries). The assert refused it with exit 1, so the fold failed AFTER the merge had landed and the
        entry had to be folded by hand.

        THE ARGUMENT IS NOT NEW, ONLY APPLIED IN A SECOND PLACE. Get-ReleaseNoteRoot is exempt from the
        assert outright, and its stated reason is that it is "the one seam whose whole point is to keep
        meaning what it meant yesterday." That is true of every seam here for the repo that was already
        folding into the root before the folder existed. So the tolerance is written per seam INSIDE the
        guard rather than as a second blanket exemption: a typo'd 'README.md' is still refused for every
        one of them, which an exemption would not do.

        TWO NAMES FOR THE CHANGELOG NOTES ROOT. #914 relocated that tree and renamed it in one move
        (releases/development -> <folder>/releases/changelog), so a consumer sitting at the root may carry
        either the pre-rename directory or the renamed one beside its siblings. Both are the same layout
        answered at the same place, so both are recognised.

        NOT KEYED ON THE SEAM'S CURRENT DEFAULT, deliberately: that default is computed and will move
        again. These strings are what the tooling wrote before the move, which is a fact about the past
        and therefore does not go stale.
    #>
    param([Parameter(Mandatory)][string]$SeamName)
    switch ($SeamName) {
        'Get-ChangelogPath'             { return @('CHANGELOG.md') }
        'Get-ReleaseHistoryPath'        { return @('releases/README.md') }
        'Get-ReleaseChangelogNotesRoot' { return @('releases/development', 'releases/changelog') }
        'Get-ReleaseGithubNotesRoot'    { return @('releases/github') }
        'Get-ReleaseInternalNotesRoot'  { return @('releases/internal') }
    }
    return @()
}

function Assert-WorkflowIsolatedSeamPath {
    <#
        THE PROVENANCE PREFLIGHT (issue #885, group D): the backstop under the four seams groups A and E
        made isolate-by-default (Get-ChangelogPath, Get-ReleaseHistoryPath,
        Get-ReleaseChangelogNotesRoot, Get-ReleaseGithubNotesRoot) plus the internal-note root read the
        same way -- not a replacement for them. Their COMPUTED defaults are already proven isolated; what
        this catches is a repo's own EXPLICIT override resolving somewhere it should not, e.g. a typo'd
        Get-ChangelogPath pointing at 'README.md' and the cut truncating a file it does not own. Call this
        right after a seam of that kind resolves, before anything is read from or written to the path.

        TWO ANSWERS PASS, NOT ONE (issue #956, August 27, 2026): the workflow folder, and the seam's own
        PRE-ISOLATION answer from Get-PreIsolationSeamPath above -- read that function for why a root
        CHANGELOG.md is a layout rather than a mistake, and for the measurement that forced it. Before
        this, the guard could not tell a typo from a layout and treated both as a typo: it refused with
        exit 1 and had no opt-out, so the fold and the cut were hard-blocked in a consumer that had been
        folding into a root CHANGELOG.md since before the folder existed.

        THE SHAPE #956 PROPOSED FIRST WAS DECLINED, and the reason is worth keeping. It offered warning
        instead of refusing "where the resolved path exists and is non-empty", on the grounds that a
        typo'd README.md and a real 24-entry CHANGELOG.md are distinguishable by looking at the target.
        By that test they are not: README.md exists and is non-empty in every repo, so the one case this
        guard's own docstring names as its reason would have passed with a warning while the cut went on
        to truncate it. What separates the two is not whether the target has content but whether the seam
        is pointing where it used to point, which is what the lookup above answers.

        SILENT ON THE LEGACY MATCH, deliberately. A recognised layout is not a finding, and this runs at
        every fold and every cut -- a line printed there would be noise in a repo that has answered the
        seam the same way for months. Telling an existing consumer that a default moved under them
        belongs to the adoption run, which is where re-adoption warnings already live (issue #955).

        DELIBERATELY NOT UNIVERSAL. Get-ReleaseNoteRoot is read the same way but is NOT checked here and
        must never be: its own contract record argues, on purpose, that its default stays at the root
        ('releases/notes') rather than moving into the folder, because real consumers already configure it
        or rely on that literal fallback -- forcing it through this assert would refuse the one seam whose
        whole point is to keep meaning what it meant yesterday.

        A SOURCE REPO (marketplace.json present) is exempt outright: it deliberately keeps these roots at
        its own root by its own decision (Dave, August 14, 2026), and Get-Default*'s own computed answer
        for a source IS that root -- so a source is not a repo that could resolve "outside the folder" in
        the sense this check is guarding against.

        Refuses (Write-Error + exit 1) rather than returning a bool, matching every other guardrail in
        cut-release.ps1: a caller that reaches this call is about to read or write the path, so a silent
        return leaves the mistake to be discovered in the write itself, at which point it may already have
        clobbered something.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$SeamName
    )
    if (Test-IsWorkflowSourceRepo -RepoRoot $RepoRoot) { return }
    $normalized = $RelativePath -replace '\\', '/'
    # BOTH FOLDER NAMES ARE ALLOWED WHILE CONSUMERS MIGRATE (#886, August 26, 2026). The folder renamed
    # 'workflow-davekjohn/' -> 'contributing-davekjohn/', and a consumer meets that through a plugin update
    # rather than by choosing to -- so their existing folder is still where their seams resolve. Allowing
    # only the new name would turn this guard from an isolation check into a hard stop on every seam call in
    # every unmigrated consumer, and it REFUSES with exit 1 rather than warning. Same answer as
    # Get-BranchFilePaths gives for the documents inside it: recognise the old name, write the new one.
    $allowedRoots = @('contributing-davekjohn', 'workflow-davekjohn')
    foreach ($root in $allowedRoots) {
        if ($normalized -eq $root -or $normalized -like "$root/*") { return }
    }
    # AND THE SEAM'S OWN PRE-ISOLATION ANSWER, EXACT MATCH ONLY (#956). Exact, not prefix: every call site
    # passes the resolved seam value itself, so the legacy layout is that value or it is not that layout --
    # a prefix match would additionally wave through paths BELOW a legacy file, which no caller produces
    # and which a typo could.
    $legacyRoots = @(Get-PreIsolationSeamPath -SeamName $SeamName)
    foreach ($legacy in $legacyRoots) {
        if ($normalized -eq $legacy) { return }
    }
    if ($legacyRoots.Count -gt 0) {
        $legacyList = ($legacyRoots | ForEach-Object { "'$_'" }) -join ' or '
        $allowedClause = "the only answer accepted outside that folder is $legacyList, which is where this seam pointed before it isolated"
    } else {
        $allowedClause = 'no answer outside that folder is accepted for it'
    }
    Write-Error "$SeamName resolved to '$RelativePath'. This repo is a workflow consumer (issue #885) and this seam isolates into contributing-davekjohn/ by default; $allowedClause. Nothing was read or written. If '$RelativePath' is genuinely where this belongs, move it under contributing-davekjohn/ instead of pointing the seam outside it."
    exit 1
}
