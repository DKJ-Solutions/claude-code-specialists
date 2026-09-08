<#
.SYNOPSIS
    Decides whether a git ref name may be interpolated into a PRINTED, PASTE-READY command -- and when
    it may not, supplies the placeholder to print instead plus the line that names the real branch away
    from any command.

.DESCRIPTION
    ISSUE #1594, September 8, 2026. Seven printed remedies across ship-pr.ps1 and sync-main.ps1 put a
    branch name into a command line meant to be copied and run verbatim, unquoted. git's own ref rules
    do not forbid the characters that matter: `git check-ref-format --branch` accepts every one of
    `fix/evil;touch`, `fix/evil&touch`, `fix/evil|touch`, `fix/evil$(touch)`, `` fix/evil`touch` `` and
    `fix/it's-fine` (exit 0, measured). What it DOES reject is ASCII control characters and the space
    (exit 128), which is why the ANSI/OSC-repaint class remote-ahead-lib.ps1's sanitiser exists for
    (#1439, #1446) is already closed for a ref name, and why this is a different hole in the same wall:
    not display deception, but a command a reader is invited to run.

    WHY QUOTING IS NOT THE FIX, WHICH IS THE PART WORTH RECORDING. The obvious repair -- wrap the value
    in quotes -- fails in both spellings, and it fails in both shells this workflow's readers actually
    use:
      - DOUBLE QUOTES do not close it. Command substitution runs inside them in bash AND in PowerShell,
        so `git checkout "x$(id -un)"` executes the substitution in either. Measured on a branch named
        `x$(id -un)`: it resolved to the current user's name.
      - SINGLE QUOTES do not close it either, because `fix/it's-fine` is a legal branch name (above), so
        the value can terminate its own quoting.
    A shell-correct escape exists per shell ('' doubling in PowerShell, '\'' in bash) and that is
    precisely the problem: a printed line does not know which shell will receive it, and this repo's
    remedies are pasted into PowerShell, Git Bash and cmd alike. So the answer is not to escape the
    value but to REFUSE TO PUT IT IN A COMMAND AT ALL, which is what this lib does.

    THE ALLOWLIST RATHER THAN A DENYLIST, and its first character is pinned. A denylist of shell
    metacharacters has to be right about four shells at once; an allowlist has to be right about the
    characters it admits. Admitted: ASCII letters, digits, `.`, `_`, `-` and `/`, with the FIRST
    character held to a letter or a digit so a name cannot read as a flag. Everything else -- `;`, `&`,
    `|`, `` ` ``, `$`, `(`, `)`, `'`, `"`, `<`, `>`, `!`, `#`, `%`, `^`, `*`, `?`, `[`, `]`, `{`, `}`,
    `~`, `=`, `+`, `,`, `:`, `@`, `\`, whitespace and every control character -- is refused. `!`, `%`
    and `^` are in that list for cmd's sake (history/delayed expansion, variable expansion, escape)
    even though bash and PowerShell would pass two of them.

    MEASURED AGAINST THIS REPO'S OWN HISTORY BEFORE IT WAS ADOPTED: all 994 pull-request head refs this
    repo has ever had match the pattern, so the rule refuses nothing anybody here has wanted. That is
    the whole argument for an allowlist this narrow -- it costs nothing real.

    WHAT THIS LIB DOES NOT DO. It does not sanitise for DISPLAY: `'$branch'` quoted inside a prose
    sentence ("this checkout is still on 'x;y'") is not a command and is left alone, because git already
    rejects the control characters that would make prose deceptive. And it is not the creation-side
    guard -- Test-BranchName in the repo-owned scripts\lib\branch-info.ps1 holds the same allowlist so a
    branch this workflow CREATES is safe by construction. Neither half closes the hole alone: that file
    is repo-owned and per-consumer, and a branch cloned, fetched or created by hand reaches these print
    sites having never met it. This lib is the half that travels.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script. No
    dependencies -- deliberately, so a caller can load it before anything else.
#>

# The one definition of "safe to paste". Anchored at both ends, first character pinned to alphanumeric.
$script:RefPasteSafePattern = '^[A-Za-z0-9][A-Za-z0-9._/-]*$'

function Test-RefPasteSafe {
    <#
        Ref -- the ref name to judge.

        Returns $true when the name may be interpolated into a printed command line as-is. An empty or
        null name is NOT safe: a caller that lost its branch would otherwise print a command with a hole
        in it, which is the one outcome worse than a placeholder.
    #>
    param([AllowEmptyString()][AllowNull()][string]$Ref)

    if ([string]::IsNullOrEmpty($Ref)) { return $false }
    return [bool]($Ref -match $script:RefPasteSafePattern)
}

function Get-PasteableRef {
    <#
        Ref         -- the ref name a printed command wants to carry.
        Placeholder -- what to print in the command's place when the name is refused. Defaults to
                       '<branch>', the angle-bracket convention every other printed remedy in this
                       workflow already uses for "fill this in yourself" (see ship-pr's own
                       '<that worktree>' and '<push, wait for CI...>').

        Returns one object with three fields, and it is ONE call on purpose: a caller cannot obtain the
        placeholder and forget the sentence that explains it.
          .Token  -- what to put in the command. The name itself when safe, else the placeholder.
          .IsSafe -- the verdict, for a caller that wants to branch on it.
          .Note   -- '' when safe. Otherwise the line to print BENEATH the command, naming the real
                     branch outside any command context so its characters are inert.

        THE NOTE NAMES THE BRANCH RATHER THAN HIDING IT. A remedy that says only "your branch name is
        unsafe" leaves the reader unable to act at all, which is a worse failure than the one this
        guards: they are standing on that branch and need it in the command. So the name is printed --
        as prose, where git's own rejection of control and whitespace characters means it cannot repaint
        a terminal -- together with what the reader has to do about it, which is quote it for whichever
        shell they are actually in.
    #>
    param(
        [AllowEmptyString()][AllowNull()][string]$Ref,
        [string]$Placeholder = '<branch>'
    )

    if (Test-RefPasteSafe -Ref $Ref) {
        return [pscustomobject]@{ Token = $Ref; IsSafe = $true; Note = '' }
    }

    # THE NAME IS SHOWN IN THE NOTE, and the empty case is spelled out rather than printing '' into a
    # sentence: a caller with no branch at all is a different problem from a caller with a hostile one,
    # and a note reading "the branch name is: ." tells the reader nothing.
    #
    # AND IT IS STRIPPED OF CONTROL AND FORMAT CHARACTERS FIRST, which is remote-ahead-lib.ps1's
    # sanitiser applied to this lib's own output. For a name that came from `git rev-parse` this is
    # belt-and-braces -- git rejects those characters in a ref -- but Get-PasteableRef takes a STRING,
    # and sync-main.ps1 hands it one built from a seam answer a consumer wrote, which git has never
    # seen. Without this, the one place this lib prints is a place an ANSI/OSC escape could repaint a
    # terminal or wear this workflow's own warning prefix, and a guard whose refusal path is itself an
    # injection surface is worse than no guard. The same reasoning as #1439 and #1446, at a new site.
    $shown = if ([string]::IsNullOrEmpty($Ref)) {
        '(this run could not read it)'
    } else {
        ($Ref -replace '[\p{Cc}\p{Cf}]', ' ')
    }

    $note = @"
  NOTE: the branch name is not safe to paste into the line above, so it reads '$Placeholder' instead.
  The branch is: $shown
  It carries characters your shell would interpret (issue #1594), and neither single nor double quotes
  close that -- put it in the command yourself, escaped for the shell you are actually in.
"@

    return [pscustomobject]@{ Token = $Placeholder; IsSafe = $false; Note = $note.TrimEnd() }
}
