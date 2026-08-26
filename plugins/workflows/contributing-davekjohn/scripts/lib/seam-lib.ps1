<#
.SYNOPSIS
    Get-SeamValue: read an optional repo-config seam function, falling back to a default when the repo
    does not define it. Get-Default*: the computed defaults for the changelog and release-note-root seams
    (issue #885) -- source keeps its root files, consumer is isolated inside workflow-davekjohn/ by
    default.

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
        file), workflow-davekjohn/CHANGELOG.md otherwise -- so every consumer is isolated by default and
        the Get-ChangelogPath seam exists only for the repo that wants to differ from that.
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
        still keeps its root file, same as Get-DefaultChangelogPath), 'workflow-davekjohn/releases/history.md'
        for a consumer.

        history.md, NOT README.md: 'workflow-davekjohn/releases/README.md' already names this folder's
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

function Get-DefaultReleaseDevelopmentNotesRoot {
    <#
        The generated development notes' (tier 0, always written) computed default (issue #885, group E).
        UNLIKE Get-ReleaseNoteRoot (the HAND-WRITTEN audience note's root, which keeps its 'releases/notes'
        default deliberately -- see that seam's own contract record), this root carried NO seam at all
        before this branch: 'releases/development/' was hard-coded everywhere, by deliberate refusal
        (cut-release.ps1's own comment: "a seam nobody can be shown to need... it comes back when somebody
        measures it" -- #885 is that measurement). So there is no prior meaning a computed default could
        silently redefine: every existing consumer's development notes already sit at the ROOT path this
        default still returns for the source, and only a consumer newly adopting the isolated folder gets
        the isolated answer.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    if (Test-IsWorkflowSourceRepo -RepoRoot $RepoRoot) { return 'releases/development' }
    return "$(Get-WorkflowFolderName -RepoRoot $RepoRoot)/releases/development"
}

function Get-DefaultReleaseGithubNotesRoot {
    <# The generated GitHub Release body's computed default (issue #885, group E). Same reasoning and same
       "no prior seam to redefine" argument as Get-DefaultReleaseDevelopmentNotesRoot -- read that one first. #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    if (Test-IsWorkflowSourceRepo -RepoRoot $RepoRoot) { return 'releases/github' }
    return "$(Get-WorkflowFolderName -RepoRoot $RepoRoot)/releases/github"
}

function Get-DefaultReleaseInternalNotesRoot {
    <# The generated internal note's (tier 1) computed default (issue #885, group E). Same reasoning and
       same "no prior seam to redefine" argument as Get-DefaultReleaseDevelopmentNotesRoot -- read that one
       first. Read by new-internal-note.ps1, which is why it exists as its own function rather than being
       folded into the development-notes one: the two roots are read by different scripts on different days
       (the cut writes the development note at every release; the internal note is a separate, later run). #>
    param([Parameter(Mandatory)][string]$RepoRoot)
    if (Test-IsWorkflowSourceRepo -RepoRoot $RepoRoot) { return 'releases/internal' }
    return "$(Get-WorkflowFolderName -RepoRoot $RepoRoot)/releases/internal"
}

function Assert-WorkflowIsolatedSeamPath {
    <#
        THE PROVENANCE PREFLIGHT (issue #885, group D): the backstop under the four seams groups A and E
        made isolate-by-default (Get-ChangelogPath, Get-ReleaseHistoryPath,
        Get-ReleaseDevelopmentNotesRoot, Get-ReleaseGithubNotesRoot) plus the internal-note root read the
        same way -- not a replacement for them. Their COMPUTED defaults are already proven isolated; what
        this catches is a repo's own EXPLICIT override resolving somewhere it should not, e.g. a typo'd
        Get-ChangelogPath pointing at 'README.md' and the cut truncating a file it does not own. Call this
        right after a seam of that kind resolves, before anything is read from or written to the path.

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
    Write-Error "$SeamName resolved to '$RelativePath', outside contributing-davekjohn/ -- this repo is a workflow consumer (issue #885), and this seam is one of the ones that isolates into that folder by default. Nothing was read or written. If '$RelativePath' is genuinely where this belongs, move it under contributing-davekjohn/ instead of pointing the seam outside it."
    exit 1
}
