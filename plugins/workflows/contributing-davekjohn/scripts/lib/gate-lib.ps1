<#
.SYNOPSIS
    Gate evidence: record what the gates proved, and against which exact working state.

.DESCRIPTION
    The gates (lint + test suites) are expensive and are frequently asked to prove the same thing
    twice. ship-pr.ps1 calls open-pr.ps1, which runs both; on a branch whose PR is already open
    open-pr skips only the `gh pr create` and runs the gates anyway. So a branch that was opened in
    one step and shipped in a later one pays for the identical commit twice.

    MEASURED BEFORE IT WAS BUILT (August 16, 2026), because the figure in circulation was wrong.
    Over 293 merged PRs, the gap between the gating CI run going green and the merge landing is
    sharply bimodal: 205 merges land within 60s (median 14s) and 83 land at a median of 263s, with a
    void between 60s and 180s and an interior peak at 240-300s. A void followed by an interior peak
    is a fixed-cost operation; human delay produces a monotonic tail with no interior peak. The one
    confound that could fake it -- ship-pr waiting on a second CI run -- was ruled out: zero of the
    83 have a push-event run on the same sha. So the excess is 249s on 28.3% of merges, not the
    "3m 27s, 3m 18s, ~3 min, 4m 02s, 4m 18s across five releases" the release notes carried. That
    series conflates the whole merge-with-fold leg with the gate re-run inside it; only v4.9.0
    separates the two.

    WHAT THE WORKAROUND WAS, AND WHY IT IS THE ACTUAL DEFECT. The practitioner's answer has been
    `ship-pr.ps1 -SkipLint -SkipTests`, used deliberately because the identical commit passed both
    gates minutes earlier. It is correct exactly while the commit is unchanged, and dangerous the
    moment it is not -- and NOTHING CHECKS THAT. The flag is doing the design's job without the
    design's safety. So the repair is not a better flag or a default-off gate: it is to make the
    unchanged case provably not need one.

    THE EVIDENCE IS THE CONTENT, NOT THE CLOCK AND NOT A PROMISE. A gate run is recorded against a
    fingerprint of precisely what it judged -- HEAD, plus the content of every dirty and untracked
    file. If the fingerprint still matches, re-running the gate cannot reach a different verdict,
    and the skip is a deduction rather than a favour. If anything moved, the fingerprint moves with
    it and the gate runs, with nobody having to remember why.

    WHY HEAD ALONE IS NOT ENOUGH, stated because it is the obvious shortcut. `git status --porcelain`
    reports that a file is modified, never what it was modified TO -- so a file edited, gated, and
    edited again presents an identical status line over different content. The fingerprint therefore
    hashes the dirty files themselves. On the common case (a clean tree, which is what open-pr and
    ship-pr both see) that costs one `git rev-parse` and nothing else.

    WHAT THE FINGERPRINT DOES NOT COVER, so nobody reads it as stronger than it is:
      - GITIGNORED FILES. They are outside `git status` by definition, so a gate input that lives in
        one is invisible here. Nothing in this repo's gates reads one; a consumer whose does should
        not rely on this skip.
      - THE ENVIRONMENT. A git, PowerShell or dependency upgrade between two runs changes what the
        suites do without changing a byte in the tree. That is what the age bound below is for --
        not a safety property of the content, but an honest limit on how long "nothing moved" is
        allowed to stand in for "nothing changed".

    THE STATE LIVES IN THE GIT DIRECTORY, deliberately. It is guaranteed present, guaranteed local,
    guaranteed never committed, and per-worktree -- so a linked worktree cannot inherit the trunk's
    evidence. That is four properties a tracked file plus a .gitignore entry would each have to be
    given, in every consumer, correctly.

    CI IS UNAFFECTED AND MUST STAY SO. A fresh checkout has no state file, so ci.yml always runs the
    gate for real. The skip is a local-only optimisation over a local-only redundancy; the required
    merge check never consults it.

    NOT MOVED HERE: Invoke-TestSuiteGate. native-capture-lib.ps1's own note asks that if a second
    gate helper ever appears, both move out together rather than that file being widened again --
    and this file is that second helper. It is deliberately NOT taken in this change: the move would
    put ci.yml, the one check that blocks every merge, into the same diff that changes gate
    behaviour, and coupling those two risks buys nothing. The constraint the note actually states is
    honoured -- native-capture-lib is not widened. The move is a clean follow-up on its own.
#>

# How long a recorded pass is allowed to stand in for a fresh run. Not a content property -- the
# fingerprint already covers content exactly -- but a bound on the environment drifting underneath
# it. Four hours comfortably covers the measured case (open-pr and ship-pr minutes apart) while
# refusing to let yesterday's green decide today's push. A constant rather than a parameter, so it
# cannot become another knob somebody sets to skip a gate.
$script:GateEvidenceMaxAgeMinutes = 240

# The recognised gate names. A typo in a caller would otherwise record evidence nothing ever reads,
# which fails in the worst direction: silently, as a gate that keeps running.
$script:GateEvidenceKnownGates = @('lint', 'tests')

function Invoke-GitRead {
    <#
        A git QUERY, captured with its exit code. Query commands write their result to stdout and
        only real errors to stderr, so this does not need the EAP dance Invoke-NativeCapture does for
        `git push`. What it does need is the repo's standing rule: capture in full, record
        $LASTEXITCODE immediately, and only then filter -- never pipe the native call itself into a
        cmdlet, which can tear the process down before it exits cleanly.

        Returns $null on any non-zero exit, so every caller degrades to "cannot answer" rather than
        to a plausible wrong answer.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string[]]$GitArgs
    )

    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & git -C $RepoRoot @GitArgs 2>$null
        $code = $LASTEXITCODE
    } catch {
        return $null
    } finally {
        $ErrorActionPreference = $prevEap
    }

    if ($code -ne 0) { return $null }
    # Assigned first and wrapped at the call site, not returned as @(...): PowerShell unrolls a
    # single-element array on return, and a caller indexing the result would get a character.
    $lines = @($output | ForEach-Object { "$_" })
    return ,$lines
}

function Get-GateFingerprint {
    <#
        A stable hash of exactly what a gate would judge: HEAD, plus the path AND content hash of
        every dirty or untracked file. Returns $null when git cannot answer, which every caller
        treats as "no evidence" -- so a non-git checkout simply runs its gates as it always did.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)

    $headLines = Invoke-GitRead -RepoRoot $RepoRoot -GitArgs @('rev-parse', 'HEAD')
    if (-not $headLines -or $headLines.Count -eq 0) { return $null }
    $head = "$($headLines[0])".Trim()
    if (-not $head) { return $null }

    # --untracked-files=all so a new file inside an untracked DIRECTORY is listed individually
    # rather than as the directory alone -- the directory form would hash nothing and let a new
    # suite slip past the fingerprint.
    $statusLines = Invoke-GitRead -RepoRoot $RepoRoot -GitArgs @('status', '--porcelain', '--untracked-files=all')
    if ($null -eq $statusLines) { return $null }

    $parts = New-Object System.Collections.ArrayList
    $parts.Add("head:$head") | Out-Null

    foreach ($line in ($statusLines | Sort-Object)) {
        if (-not "$line".Trim()) { continue }
        # Porcelain v1: two status columns, a space, then the path. A rename carries 'old -> new';
        # the new path is the one on disk, so that is the half worth hashing.
        $rest = if ("$line".Length -gt 3) { "$line".Substring(3) } else { '' }
        $path = $rest
        $arrow = $rest.IndexOf(' -> ')
        if ($arrow -ge 0) { $path = $rest.Substring($arrow + 4) }
        $path = $path.Trim('"').Trim()
        if (-not $path) { continue }

        $full = Join-Path $RepoRoot $path
        $contentHash = 'absent'
        if (Test-Path -LiteralPath $full -PathType Leaf) {
            try {
                $contentHash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
            } catch {
                # Unreadable (locked, or vanished between the listing and the read) -- recorded as a
                # distinct value rather than skipped, so it cannot silently match a later run in
                # which the file reads fine.
                $contentHash = 'unreadable'
            }
        }
        $parts.Add("file:$path=$contentHash") | Out-Null
    }

    $joined = ($parts -join "`n")
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($joined)
        $hash = $sha.ComputeHash($bytes)
    } finally {
        $sha.Dispose()
    }
    return (($hash | ForEach-Object { $_.ToString('x2') }) -join '')
}

function Get-GateEvidencePath {
    <#
        Where the record lives: inside the git directory, which is per-worktree and never committed.
        Returns $null when git cannot answer.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)

    $dirLines = Invoke-GitRead -RepoRoot $RepoRoot -GitArgs @('rev-parse', '--git-dir')
    if (-not $dirLines -or $dirLines.Count -eq 0) { return $null }
    $gitDir = "$($dirLines[0])".Trim()
    if (-not $gitDir) { return $null }
    # `--git-dir` answers relatively when the query is made from inside the work tree.
    if (-not [System.IO.Path]::IsPathRooted($gitDir)) { $gitDir = Join-Path $RepoRoot $gitDir }
    return (Join-Path $gitDir 'workflow-gate-evidence.json')
}

function Read-GateEvidence {
    <#
        The record as an object, or $null when there is none, it cannot be read, or it is malformed.
        Every one of those is "no evidence", which fails toward running the gate.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)

    $path = Get-GateEvidencePath -RepoRoot $RepoRoot
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }

    try {
        $raw = [System.IO.File]::ReadAllText($path)
        # Assigned before use: @(... | ConvertFrom-Json) collects a parsed array as ONE element in
        # PowerShell 5.1, the trap this repo has now hit in two unrelated scripts.
        $parsed = $raw | ConvertFrom-Json
    } catch {
        return $null
    }
    if (-not $parsed) { return $null }
    return $parsed
}

function Test-GateEvidence {
    <#
        Does a recorded pass of $Gate still cover the tree as it stands right now?

        $true only when all four hold: a record exists, it names this gate as passed, its fingerprint
        equals the tree's fingerprint today, and it is younger than the age bound. Anything else is
        $false -- including every error path, because the cost of a false $false is one gate run and
        the cost of a false $true is an ungated merge.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][ValidateSet('lint', 'tests')][string]$Gate,
        # The tree's current fingerprint, when the caller has already computed it. Passing it keeps
        # one push from hashing the same tree once per gate.
        [string]$Fingerprint
    )

    $record = Read-GateEvidence -RepoRoot $RepoRoot
    if (-not $record) { return $false }

    $recorded = $null
    if ($record.PSObject.Properties['gates']) {
        $gatesNode = $record.gates
        if ($gatesNode -and $gatesNode.PSObject.Properties[$Gate]) { $recorded = $gatesNode.$Gate }
    }
    if (-not $recorded) { return $false }

    if (-not $record.PSObject.Properties['fingerprint']) { return $false }
    $current = if ($PSBoundParameters.ContainsKey('Fingerprint') -and $Fingerprint) {
        $Fingerprint
    } else {
        Get-GateFingerprint -RepoRoot $RepoRoot
    }
    if (-not $current) { return $false }
    if ("$($record.fingerprint)" -ne "$current") { return $false }

    if (-not $record.PSObject.Properties['recordedAt']) { return $false }
    try {
        $stamp = [datetime]::Parse("$($record.recordedAt)", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    } catch {
        return $false
    }
    $ageMinutes = ([datetime]::UtcNow - $stamp).TotalMinutes
    # A negative age is a clock that moved backwards, not a fresh record -- refused rather than
    # trusted, since "recorded in the future" is exactly what a tampered or restored file looks like.
    if ($ageMinutes -lt 0) { return $false }
    if ($ageMinutes -gt $script:GateEvidenceMaxAgeMinutes) { return $false }

    return $true
}

function Save-GateEvidence {
    <#
        Record that $Gate passed against the tree as it stands. A fingerprint that differs from the
        stored one RESETS the other gates rather than joining them: the two gates prove different
        things about the same tree, so a lint pass on today's tree must not inherit yesterday's test
        pass on a different one.

        Best-effort by design -- an unwritable git directory costs a future skip, never this run.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][ValidateSet('lint', 'tests')][string]$Gate,
        [string]$Fingerprint
    )

    $current = if ($PSBoundParameters.ContainsKey('Fingerprint') -and $Fingerprint) {
        $Fingerprint
    } else {
        Get-GateFingerprint -RepoRoot $RepoRoot
    }
    if (-not $current) { return $false }

    $path = Get-GateEvidencePath -RepoRoot $RepoRoot
    if (-not $path) { return $false }

    $gates = @{}
    $existing = Read-GateEvidence -RepoRoot $RepoRoot
    if ($existing -and $existing.PSObject.Properties['fingerprint'] -and "$($existing.fingerprint)" -eq "$current") {
        if ($existing.PSObject.Properties['gates'] -and $existing.gates) {
            foreach ($name in $script:GateEvidenceKnownGates) {
                if ($existing.gates.PSObject.Properties[$name] -and $existing.gates.$name) { $gates[$name] = $true }
            }
        }
    }
    $gates[$Gate] = $true

    $record = [ordered]@{
        fingerprint = $current
        recordedAt  = [datetime]::UtcNow.ToString('o')
        gates       = $gates
    }

    try {
        $json = $record | ConvertTo-Json -Depth 4
        # WriteAllText with an explicit BOM-less UTF8: Set-Content -Encoding utf8 means WITH BOM in
        # Windows PowerShell 5.1, and this file is read back by ConvertFrom-Json on every run.
        [System.IO.File]::WriteAllText($path, $json, (New-Object System.Text.UTF8Encoding($false)))
    } catch {
        return $false
    }
    return $true
}

function Clear-GateEvidence {
    <#
        Drop the record entirely. Used by the suites, and available to anyone who wants the next run
        to prove everything again from scratch.
    #>
    param([Parameter(Mandatory)][string]$RepoRoot)

    $path = Get-GateEvidencePath -RepoRoot $RepoRoot
    if (-not $path) { return $false }
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        try { Remove-Item -LiteralPath $path -Force } catch { return $false }
    }
    return $true
}
