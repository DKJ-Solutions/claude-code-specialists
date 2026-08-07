<#
.SYNOPSIS
    Shared branch conventions for the workflow scripts (single source of truth).

.DESCRIPTION
    Dot-source this file from a script in scripts/release/:

        . (Join-Path $PSScriptRoot '..\lib\branch-info.ps1')

    Supplies Get-BranchPrefix, Get-BranchInfo and Get-BranchTypes. The prefix table determines both
    the GitHub label of the PR and the changelog entry type, and follows the standard GitHub labels:
    Enhancement -> label 'enhancement', Bug -> 'bug', Documentation -> 'documentation'.
    Changing the table? Do it here too -- and nowhere else: every script reads this one table.

    The branch types (Feat/Fix/Docs/Chore) have their single source here. release-lib.ps1 reads
    them via Get-BranchTypes for the release-notes grouping, so the list does not drift across two
    places (previously release-lib.ps1 duplicated the same types as $catOrder).

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script
    and could break loose code there.
#>

# The canonical branch types, in the order they appear in the release notes. Single source: every
# Type value in the table below is a member of this list, and release-lib.ps1 reads it via
# Get-BranchTypes. Adding a type? Do it here -- and nowhere else.
$script:BranchTypeOrder = @('Feat', 'Fix', 'Docs', 'Chore')

# prefix -> GitHub label (PR) + branch type (changelog entry).
# Note: a release does NOT run via a branch/PR (cut-release.ps1 commits directly to main),
# so there is deliberately no 'release' prefix here.
$script:BranchPrefixTable = @{
    feat  = @{ Label = 'enhancement';   Type = 'Feat' }
    fix   = @{ Label = 'bug';           Type = 'Fix' }
    docs  = @{ Label = 'documentation'; Type = 'Docs' }
    chore = @{ Label = 'documentation'; Type = 'Chore' }
}

function Get-BranchTypes {
    # The canonical branch types in release-notes order (SSOT for release-lib.ps1).
    return $script:BranchTypeOrder
}

function Get-BranchPrefix {
    param([Parameter(Mandatory = $true)][string]$Branch)
    # 'feat/name' -> 'feat'; without a slash, the part before the first hyphen applies
    if ($Branch -match '/') { return ($Branch -split '/')[0] }
    return ($Branch -split '-')[0]
}

function Get-BranchInfo {
    param([Parameter(Mandatory = $true)][string]$Branch)
    $prefix = Get-BranchPrefix -Branch $Branch
    $known  = $script:BranchPrefixTable.ContainsKey($prefix)
    [pscustomobject]@{
        Branch   = $Branch
        Prefix   = $prefix
        IsKnown  = $known
        Label    = $(if ($known) { $script:BranchPrefixTable[$prefix].Label } else { $null })
        Type     = $(if ($known) { $script:BranchPrefixTable[$prefix].Type } else { $null })
        # The same name is used for the changelog entry file <SafeName>.md in the repo root.
        SafeName = $Branch -replace '/', '-'
    }
}

function Test-BranchName {
    <#
        Additive SSOT helper (alongside Get-BranchInfo) for scripts that need to VALIDATE a branch
        name before using it (e.g. new-branch.ps1), instead of repeating the hard-reject rules
        inline. Does not touch Get-BranchInfo/Get-BranchTypes/the prefix table.

        Hard rejects (IsValid = $false, Reason filled in):
          - empty/whitespace-only name
          - name equal to 'main'
          - name contains the substring 'final' (case-insensitive, so also 'finalize'/'refinalization' --
            deliberately broad; see below)

        WHY 'final' IS REFUSED, IN DAVE'S OWN WORDS (August 7, 2026): "je weet nooit zeker of iets echt
        final is" -- you can never be certain something really is final. A branch named for being the last
        word on something is a prediction, and the prediction is wrong often enough that the name outlives
        its own truth: the next round has to be called 'final-2' or 'really-final', which is the shape the
        rule exists to prevent. **Use a version suffix instead** -- 'fix/template-newline-v2' -- because a
        number makes no claim about being the last one.

        The rule is Dave's, recorded here rather than only in a memory note because this repo's convention
        is that a lesson lives in the doc closest to what it governs. It was attributed to Derek in this
        docstring until the day the reasoning was actually asked for, which is how a rule ends up looking
        like a habit somebody picked up.

        AND THE OPPOSITE RULE ONCE EXISTED, WHICH IS WORTH KNOWING BEFORE ANYONE "RESTORES" IT. A written
        rule used to forbid exactly that '-v2' suffix, because the fold looked an entry file up by the exact
        branch name ('feat-x.md') and a suffix broke both the match and the cleanup that followed it. The
        branch/ split (August 6, 2026) retired it: the fold reads the branch out of the document rather than
        guessing it from a filename, so a suffix costs nothing. Nothing here rejects '-v2', deliberately.

        An unknown prefix is NOT a hard reject (IsValid stays $true); the caller reads IsKnown and
        decides for itself whether/how a soft warning is needed, consistent with
        new-changelog-entry/open-pr which also fall back (Chore/'question') on an unknown prefix
        instead of blocking.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Branch)

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        return [pscustomobject]@{ IsValid = $false; Reason = "Branch name must not be empty."; IsKnown = $false }
    }
    if ($Branch -eq 'main') {
        return [pscustomobject]@{ IsValid = $false; Reason = "Branch name must not be 'main'."; IsKnown = $false }
    }
    if ($Branch -match 'final') {
        # THE REFUSAL NAMES THE REMEDY, which this one did not. A gate that says only "not that" leaves the
        # next person guessing, and the guess for a rejected 'final' is 'finished' or 'done' -- the same
        # claim in a different word. '-v2' is the answer Dave gave when asked, and it is one word longer.
        return [pscustomobject]@{
            IsValid = $false
            Reason  = "Branch name must not contain the token 'final' -- you can never be sure something really is final, and the next round then has to be called 'final-2'. Use a version suffix instead, e.g. 'fix/template-newline-v2'."
            IsKnown = $false
        }
    }

    $info = Get-BranchInfo -Branch $Branch
    [pscustomobject]@{ IsValid = $true; Reason = $null; IsKnown = $info.IsKnown }
}
