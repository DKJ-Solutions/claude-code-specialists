<#
.SYNOPSIS
    The one implementation of parking a branch: stage, commit, push -- no PR, no live action.

.DESCRIPTION
    Dot-source this file from a script in scripts/task/:

        . (Join-Path $PSScriptRoot '..\lib\park-lib.ps1')

    Supplies Invoke-GitPark, which both parking entry points call: park-branch.ps1 (an existing branch,
    mid-work) and new-branch.ps1 -Park (a branch at creation).

    WHY ONE OWNER (issue #507, August 7, 2026). The two entry points had a copy each of the same four
    steps, and they had already drifted in the way that matters least to a script and most to a person:
    THEY WROTE THE IDENTICAL COMMIT MESSAGE. Both said `park: <branch> (work parked for later)` while
    committing different things -- new-branch -Park commits ONLY the two branch files, park-branch commits
    everything outstanding. So afterwards the git log could not tell you which half of your work was
    safely on origin, which is the single question a park exists to answer.

    THE MEASUREMENT THAT SHAPED THIS, because it refuted the obvious proposal. Across the whole history
    there are THREE park commits: two from `new-branch -Park` (eb5e0f7, a72cc91) and one from
    `park-branch` (fd2083b). The proposal on the table was "drop -Park, it parks a branch with nothing in
    it yet" -- and two of the three real parks are exactly that case. -Park is the more used of the two.
    Neither was deleted; what was wrong was never that there are two moments to park at, but that the
    record could not tell them apart.

    THE SCOPE AND THE MESSAGE COME FROM ONE DECISION, deliberately. -Scope picks both the pathspec that is
    committed and the words that describe it, so a future caller cannot commit one scope while announcing
    another -- which is the defect this function was written to end, reappearing one level down.

    WHY A NEW LIB RATHER THAN native-capture-lib.ps1, where Invoke-TestSuiteGate went the same week: that
    file's own note says it took an imperfect fit deliberately and asks the next person NOT to widen it
    again ("if a second gate helper ever appears, move both out together"). A park is not a gate, and its
    cost here is one registry entry and one mirror -- no contract row, since nothing in it is repo-owned.

    Self-contained apart from the shared native-capture helper: git only, no repo-owned config, so a
    consumer needs no scaffold for it.

    Every git call goes through Invoke-NativeCapture (EAP=Continue -> run -> record $LASTEXITCODE),
    because git writes progress to stderr, which under EAP=Stop would become a terminating
    NativeCommandError before the exit code could be judged (the #96/#97/#107 pitfall). The commit message
    goes via `git commit -F <file>`, never `-m "...$branch..."`: a branch name may legally carry a `"`,
    which embedded in an -m argument would break native argv reconstruction (the quoting lesson).

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

# THE TWO SCOPES, AND WHAT EACH IS CALLED IN THE COMMIT. One map, so the words and the pathspec are the
# same decision -- see the note above. 'Everything' carries no pathspec: git add -A and a bare commit.
$script:GitParkScopes = @{
    Everything = 'all outstanding work'
    BranchFiles = 'the branch files only'
}

function Get-GitParkScopes {
    <# The scope names this function accepts, and the phrase each one puts in the commit subject. Exposed
       so a test can assert the pair rather than re-typing either half. #>
    return $script:GitParkScopes
}

function Invoke-GitPark {
    <#
        Parks $Branch: stages what $Scope says, commits it when there is something staged, and pushes with
        `git push -u`. Returns $true on success, $false with a message written by the caller's own
        Write-Error -- the caller owns the exit code, because the two entry points differ in what a
        failure means (park-branch stops; new-branch has already created the branch and the files).

        NOTHING TO COMMIT IS NOT A FAILURE. A branch whose files were already committed locally but never
        pushed is the real-world case park exists for (issue #175): the commit is skipped and the existing
        commits are pushed as-is.

        THE PATHSPEC IS NAMED, NOT SWEPT, in the BranchFiles scope -- so anything the caller had already
        staged for their own next commit stays staged and uncommitted rather than riding along.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$Branch,
        [ValidateSet('Everything', 'BranchFiles')][string]$Scope = 'Everything',
        [string[]]$Paths = @(),
        [string]$Intent = ''
    )

    $pathArgs = @()
    if ($Scope -eq 'BranchFiles') {
        # Only paths that exist: a branch parked before one of its files was written would otherwise fail
        # on a pathspec git cannot resolve.
        $pathArgs = @($Paths | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $RepoRoot $_)) })
        if ($pathArgs.Count -eq 0) {
            Write-Host "park: nothing to stage in this scope -- pushing the existing commits as-is." -ForegroundColor Yellow
        }
    }

    if ($Scope -eq 'Everything') {
        $addRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $RepoRoot, 'add', '-A')
    } elseif ($pathArgs.Count -gt 0) {
        $addRes = Invoke-NativeCapture -FilePath 'git' -Arguments (@('-C', $RepoRoot, 'add', '--') + $pathArgs)
    } else {
        $addRes = $null
    }
    if ($addRes) {
        $addRes.Output | ForEach-Object { Write-Host $_ }
        if ($addRes.ExitCode -ne 0) { Write-Error "park: staging failed."; return $false }
    }

    # `git diff --cached --quiet` exits 0 when nothing is staged and 1 when there is -- so this asks
    # whether there is anything to commit, scoped exactly as the staging above was.
    $diffArgs = @('-C', $RepoRoot, 'diff', '--cached', '--quiet')
    if ($pathArgs.Count -gt 0) { $diffArgs += @('--') + $pathArgs }
    $diffRes = Invoke-NativeCapture -FilePath 'git' -Arguments $diffArgs

    if ($diffRes.ExitCode -ne 0) {
        $msg = "park: $Branch ($($script:GitParkScopes[$Scope]))"
        if ($Intent.Trim()) { $msg = "$msg`n`n$($Intent.Trim())" }
        $msgFile = Join-Path ([System.IO.Path]::GetTempPath()) "git-park-msg-$PID.txt"
        [System.IO.File]::WriteAllText($msgFile, $msg, (New-Object System.Text.UTF8Encoding $false))
        try {
            $commitArgs = @('-C', $RepoRoot, 'commit', '-F', $msgFile)
            if ($pathArgs.Count -gt 0) { $commitArgs += @('--') + $pathArgs }
            $commitRes = Invoke-NativeCapture -FilePath 'git' -Arguments $commitArgs
            $commitRes.Output | ForEach-Object { Write-Host $_ }
            if ($commitRes.ExitCode -ne 0) { Write-Error "park: committing failed."; return $false }
        } finally {
            Remove-Item -Path $msgFile -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "park: nothing new to commit -- pushing the existing commits as-is." -ForegroundColor Yellow
    }

    # Push + set upstream tracking, so the branch is reachable (and continuable) from another device.
    # No PR: push != PR (the PR rule stays intact and separate).
    $pushRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $RepoRoot, 'push', '-u', 'origin', $Branch)
    $pushRes.Output | ForEach-Object { Write-Host $_ }
    if ($pushRes.ExitCode -ne 0) { Write-Error "park: git push failed (is 'origin' configured and reachable?)."; return $false }

    Write-Host "Branch '$Branch' parked on origin -- $($script:GitParkScopes[$Scope]) (pushed, no PR)." -ForegroundColor Green
    return $true
}
