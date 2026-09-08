<#
.SYNOPSIS
    A verdict a SessionStart hook may compute ONCE per session instead of on every firing: the
    session id the harness hands the hook on stdin, and a small cache under temp keyed on it.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\scripts\lib\session-cache-lib.ps1')

    WHY THIS EXISTS (issue #1605). The SessionStart hooks in this family are matched on
    "startup|resume|clear|compact", not on "startup" alone, because a SessionStart hook's injected
    stdout does not survive a compaction by itself -- a startup-only matcher made every report go
    silent after the first /compact and never return. That matcher is right and must not be narrowed.
    What it costs is that every firing re-runs the check, and connector-sessioncheck's #1591 fallback
    is the expensive one: two nested powershell bring-ups plus git in the marketplace clone, measured
    at 1.1-1.8s, of which ~750ms is the process spawn alone. A session with four compactions paid it
    five times for an answer that was identical each time.

    THE INVARIANT THIS CACHE STANDS ON, stated plainly because everything below is only as sound as
    it is: what the fallback reads -- the install record keyed on this checkout's path, and the
    marketplace clone -- is static for the life of a session. That is not an assumption made here; it
    is the same fact the hook's own closing line already tells the reader ("then restart the session
    -- a skill or hook that arrives with an update is not in a session that started before it").
    Where that is not true, the answer is a restart, which is a NEW session and therefore a new key.

    THE KEY IS THE HARNESS'S OWN session_id, NOT A PAIR OF FILE TIMESTAMPS. The issue proposed
    keying on the install record's mtime plus the clone's .git/FETCH_HEAD mtime, on the ground that
    the script already reads both -- but it is the ENGINE that reads them, in the child process this
    cache exists to avoid starting. Keying on FETCH_HEAD would mean the hook resolving the clone
    directories itself, which is engine logic copied into a caller, and it argues against the
    invariant above at the same time: if nothing can change within a session, an mtime key guards a
    case the premise says cannot occur. The session id expresses exactly the invariant, needs no
    knowledge of the engine, and falls out of the payload the harness already sends.

    AND IT SORTS THE FIRING KINDS FOR FREE, which is the second reason to prefer it. A compaction
    keeps the session id, so the answer is replayed -- which is the whole point. A startup and a
    /clear arrive with a NEW id, so both re-measure without this file having to read the payload's
    'source' field or hold a list of which kinds may trust a cache.

    A RESUME IS THE ONE CASE THE ID CANNOT BOUND, hence -MaxAgeHours. Resuming reuses the session id,
    so a session resumed days later would replay a verdict measured before whatever happened in
    between. The id says "the same session"; it says nothing about WHEN. So a replay is additionally
    bounded by age (default 4 hours, comfortably longer than a working session's compaction cycle and
    far shorter than a next-day resume), and entries older than the reap window are deleted on the
    next write rather than left to accumulate one file per session forever.

    THE CACHE IS ADVISORY IN BOTH DIRECTIONS, and every function here fails towards MEASURING. No
    session id, an unparseable payload, an unwritable temp directory, a corrupt entry, a shape this
    lib does not recognise: each returns "no cached answer" and the caller does what it did before
    this file existed. A cache that can break a session start would be a worse defect than the cost
    it saves.

    Read-only outside its own directory under temp. It never writes into a repo, into ~/.claude, or
    anywhere a check reads state from.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Get-HookPayloadRaw {
    <#
    .SYNOPSIS
        The hook's own stdin payload, as text -- bounded, and only where there is one to read.

    .DESCRIPTION
        A SessionStart hook receives a JSON payload on stdin carrying session_id, transcript_path,
        cwd and source. dkj-team-shopify's guard-live-theme.ps1 already reads its own payload this
        way ([Console]::In.ReadToEnd() + ConvertFrom-Json, with an explicit fallback on an
        unparseable one), and this is that pattern with two guards it does not need and this one does.

        TWO GUARDS, BOTH ABOUT NOT HANGING A SESSION START. First, stdin is read only when it is
        REDIRECTED: an unredirected [Console]::In is a live console, and reading it to the end blocks
        until somebody types EOF -- which is exactly what happens when this hook is run by hand or by
        a test suite from a terminal. Second, the read is bounded by a timeout even when redirected,
        because a redirected handle that nobody closes blocks just as completely as a console does.
        The normal case pays neither: the harness writes the payload and closes the handle, so the
        text is already buffered and the wait returns immediately.

        A hook that cannot read its payload gets '' and therefore no cache -- the failing-towards-
        measuring rule in this file's header.
    #>
    param([int]$TimeoutMs = 250)

    try {
        if (-not [Console]::IsInputRedirected) { return '' }
        $task = [Console]::In.ReadToEndAsync()
        if (-not $task.Wait($TimeoutMs)) { return '' }
        return [string]$task.Result
    } catch {
        return ''
    }
}

function Test-SessionIdShape {
    <#
    .SYNOPSIS
        Is this string safe to use as a session key AND as part of a file name?

    .DESCRIPTION
        The session id arrives from outside this process and is used to compose a path, so it is
        validated rather than escaped: letters, digits, dot, dash and underscore only, 8 to 128
        characters. Anything else -- a separator, a traversal segment, a colon, a control character,
        anything empty or absurdly long -- is refused and the caller falls back to measuring.

        WHITELIST RATHER THAN A SANITISER, deliberately. A sanitiser has to be right about every
        character it strips and about what the remainder then collides with; a shape check has to be
        right about the one shape the harness actually sends (a UUID), and every real session id
        passes it. The cost of being wrong is one re-measured verdict; the cost of being wrong the
        other way is a path this process composes out of somebody else's string.
    #>
    param([string]$SessionId)

    if ([string]::IsNullOrWhiteSpace($SessionId)) { return $false }
    return ($SessionId -cmatch '^[A-Za-z0-9._-]{8,128}$')
}

function Get-SessionIdFromPayload {
    <#
    .SYNOPSIS
        The session_id out of a hook payload, or '' when there is not a usable one.

    .DESCRIPTION
        Pure: it takes the text and returns a string, so the suite can walk every shape a payload
        arrives in -- empty, not JSON, JSON without the field, a field of the wrong type, a field
        whose value fails the shape check -- without a hook, a harness or a temp directory.

        NOT A FALLBACK TO THE RAW TEXT, unlike guard-live-theme.ps1's own read. That hook falls back
        because its subject is a command it must inspect, so an unrecognised payload has to fail
        towards CHECKING. Here the subject is a cache key, and an unrecognised payload has to fail
        towards MEASURING -- which is what no key means.
    #>
    param([string]$Payload)

    if ([string]::IsNullOrWhiteSpace($Payload)) { return '' }
    try {
        $j = $Payload | ConvertFrom-Json
    } catch {
        return ''
    }
    if (-not $j) { return '' }
    if ($j -isnot [pscustomobject]) { return '' }
    if (-not ($j.PSObject.Properties.Name -contains 'session_id')) { return '' }
    $id = $j.session_id
    # A non-scalar field (an array, a nested object) stringifies into something that is not an id at
    # all, so it is refused here rather than allowed to pass the shape check by accident.
    if ($id -is [array] -or $id -is [pscustomobject] -or $id -is [hashtable]) { return '' }
    $id = ([string]$id).Trim()
    if (-not (Test-SessionIdShape -SessionId $id)) { return '' }
    return $id
}

function Get-HookSessionId {
    <#
    .SYNOPSIS
        The two above in one call: read this hook's payload and return its session id, or ''.
    #>
    param([int]$TimeoutMs = 250)

    return (Get-SessionIdFromPayload -Payload (Get-HookPayloadRaw -TimeoutMs $TimeoutMs))
}

function Get-SessionCacheRoot {
    <#
    .SYNOPSIS
        The directory session-scoped verdicts live in.

    .DESCRIPTION
        Under temp, which is where every other scratch path in this repo goes (native-capture-lib,
        park-lib, open-pr, ship-pr, sync-main all compose one there) and which on Windows is
        per-user. NOT under ~/.claude: that tree is the plugin administration this family's checks
        READ, and claude-home-sessioncheck snapshots it -- writing a cache into a directory whose
        contents another check reports on is how a diagnostic starts describing itself.

        -Override exists for the suite, so a scenario writes into its own fixture and can assert on
        what is and is not there afterwards. Nothing in the shipped hooks passes it.
    #>
    param([string]$Override = '')

    if ($Override) { return $Override }
    return (Join-Path ([System.IO.Path]::GetTempPath()) 'dkj-session-cache')
}

function Get-SessionCacheFileName {
    <#
    .SYNOPSIS
        The file one (session, subject) pair is stored in.

    .DESCRIPTION
        '<session id>-<16 hex of SHA256(key)>.json'. The session id is in the name in the clear --
        it has passed the shape check, so it is already file-name-safe -- which is what lets the reap
        and a human reading the directory see whose entries these are. The SUBJECT is hashed rather
        than spelled out because it carries paths: a key naming an engine under a plugin cache and a
        checkout root would blow past the path limit and would put a machine's directory layout in a
        file name for no gain.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$SessionId,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Key)
        $hash  = $sha.ComputeHash($bytes)
    } finally {
        $sha.Dispose()
    }
    $hex = -join ($hash | ForEach-Object { $_.ToString('x2') })
    return ("$SessionId-" + $hex.Substring(0, 16) + '.json')
}

function Get-SessionCacheEntry {
    <#
    .SYNOPSIS
        The cached verdict for this session and subject, or $null when there is not a usable one.

    .DESCRIPTION
        Returns a pscustomobject with Output (string[]) and ExitCode (int) -- the shape
        Set-SessionCacheEntry was given -- and $null in every other case: no file, an unreadable
        file, JSON this lib does not recognise, an entry whose stored session/key disagree with the
        ones asked for, or one older than -MaxAgeHours.

        THE STORED KEY IS COMPARED, not just the file name it hashed into. The file name is a
        16-hex-character digest, so two subjects can in principle land on one name; comparing the
        key the writer recorded makes a collision a miss rather than a wrong answer.

        THE AGE BOUND IS WHY A RESUME IS SAFE -- see this file's header. It is checked against the
        WrittenAt the writer recorded rather than the file's mtime, because an mtime is changed by
        anything that touches the file and the question here is when the measurement was taken.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$SessionId,
        [Parameter(Mandatory = $true)][string]$Key,
        [string]$Root = '',
        [double]$MaxAgeHours = 4
    )

    if (-not (Test-SessionIdShape -SessionId $SessionId)) { return $null }

    try {
        $path = Join-Path (Get-SessionCacheRoot -Override $Root) (Get-SessionCacheFileName -SessionId $SessionId -Key $Key)
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
        $j = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $j) { return $null }
        foreach ($field in @('sessionId', 'key', 'writtenAt', 'exitCode', 'output')) {
            if (-not ($j.PSObject.Properties.Name -contains $field)) { return $null }
        }
        if ([string]$j.sessionId -cne $SessionId) { return $null }
        if ([string]$j.key -cne $Key) { return $null }

        $written = [datetime]::MinValue
        if (-not [datetime]::TryParse([string]$j.writtenAt, [ref]$written)) { return $null }
        $ageHours = ([datetime]::UtcNow - $written.ToUniversalTime()).TotalHours
        # A NEGATIVE AGE IS A MISS, not a fresh entry. A clock moved backwards (or an entry written by
        # a machine whose clock is ahead) would otherwise read as valid for as long as the skew lasts.
        if ($ageHours -lt 0 -or $ageHours -gt $MaxAgeHours) { return $null }

        return [pscustomobject]@{
            Output   = @($j.output | ForEach-Object { [string]$_ })
            ExitCode = [int]$j.exitCode
        }
    } catch {
        return $null
    }
}

function Set-SessionCacheEntry {
    <#
    .SYNOPSIS
        Store a verdict for this session and subject. Returns $true when it landed, $false otherwise.

    .DESCRIPTION
        Best-effort by contract: a failure to write is not a failure of the check that called it, so
        every path here is inside a try and the return value is the only report. The caller has the
        answer in hand either way -- it has just measured it.

        IT REAPS BEFORE IT WRITES, and the window is deliberately much wider than -MaxAgeHours: an
        entry older than the replay bound is dead weight rather than a hazard, and deleting it on the
        first write of the next session is enough to keep the directory from growing one file per
        session forever. -ReapOlderThanHours 0 turns the sweep off, which only the suite does.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$SessionId,
        [Parameter(Mandatory = $true)][string]$Key,
        [AllowEmptyCollection()][string[]]$Output = @(),
        [int]$ExitCode = 0,
        [string]$Root = '',
        [double]$ReapOlderThanHours = 24
    )

    if (-not (Test-SessionIdShape -SessionId $SessionId)) { return $false }

    try {
        $dir = Get-SessionCacheRoot -Override $Root
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        if ($ReapOlderThanHours -gt 0) { Remove-StaleSessionCacheEntry -Root $dir -OlderThanHours $ReapOlderThanHours | Out-Null }

        $payload = [ordered]@{
            sessionId = $SessionId
            key       = $Key
            writtenAt = ([datetime]::UtcNow.ToString('o'))
            exitCode  = $ExitCode
            output    = @($Output)
        }
        $path = Join-Path $dir (Get-SessionCacheFileName -SessionId $SessionId -Key $Key)
        $json = ($payload | ConvertTo-Json -Depth 6)
        [System.IO.File]::WriteAllText($path, $json, (New-Object System.Text.UTF8Encoding $false))
        return $true
    } catch {
        return $false
    }
}

function Remove-StaleSessionCacheEntry {
    <#
    .SYNOPSIS
        Delete cache files last written more than -OlderThanHours ago. Returns how many went.

    .DESCRIPTION
        Reaping on the FILE's mtime rather than on the WrittenAt inside it, which is the opposite of
        what Get-SessionCacheEntry compares and is right for the opposite reason: this pass has to be
        able to remove a file it cannot parse, and a corrupt or truncated entry is exactly the one
        with no readable timestamp. It only ever deletes inside the cache directory and only files
        matching the shape this lib writes.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [double]$OlderThanHours = 24
    )

    $gone = 0
    try {
        if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return 0 }
        $cutoff = [datetime]::UtcNow.AddHours(-1 * $OlderThanHours)
        foreach ($f in @(Get-ChildItem -LiteralPath $Root -Filter '*.json' -File -ErrorAction SilentlyContinue)) {
            if ($f.LastWriteTimeUtc -lt $cutoff) {
                Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path -LiteralPath $f.FullName)) { $gone++ }
            }
        }
    } catch {
        return $gone
    }
    return $gone
}
