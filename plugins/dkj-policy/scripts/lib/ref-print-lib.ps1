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
    `fix/it's-fine` (exit 0, measured). What it DOES reject is ASCII control characters (\p{Cc}) and the
    space (exit 128) -- NOT the whole of the ANSI/OSC-repaint class remote-ahead-lib.ps1's sanitiser
    exists for (#1439, #1446), because that class is `[\p{Cc}\p{Cf}]` and git enforces only the first
    half. A `\p{Cf}` run is accepted in a ref name and is a live display hazard; see the scope note at
    the foot of this block. What THIS lib is about is a different hole in the same wall: not display
    deception, but a command a reader is invited to run.

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

    THE DISPLAY AXIS, AND WHY IT IS A SECOND FUNCTION RATHER THAN A WIDER ALLOWLIST. `'$branch'` quoted
    inside a prose sentence ("this checkout is still on 'x;y'") is not a command, and the shell
    metacharacters this lib refuses are inert there. THAT IS NOT THE SAME AS SAFE (#1617). The deceptive
    class is `[\p{Cc}\p{Cf}]` and `git check-ref-format` enforces only the `\p{Cc}` half, so a ref
    carrying a `\p{Cf}` character is accepted, creatable and checkout-able, and `git rev-parse
    --abbrev-ref HEAD` hands it back verbatim. Measured, September 8, 2026, `--branch` exit codes:
    U+202E RIGHT-TO-LEFT OVERRIDE 0, U+200D ZERO WIDTH JOINER 0, U+200B ZERO WIDTH SPACE 0, U+2066
    LEFT-TO-RIGHT ISOLATE 0 -- against 128 for BEL and ESC. Those first two are the exact code points
    #1446 was filed for, where they bypassed the #1439 tip sanitiser, which is why
    remote-ahead-lib.ps1 strips `\p{Cf}` deliberately and this lib's own refusal note (below) does the
    same.

    THAT GAP WAS LEFT OPEN KNOWINGLY FOR A DAY, AND #1623 CLOSED IT. Get-DisplayRef below is the one
    definition of the strip, and the thirty-two prose sites across ship-pr.ps1, sync-main.ps1,
    remote-ahead-lib.ps1 and worktree-lib.ps1 go through it. The two axes stay distinct because the
    right answer differs: a name refused for PASTE is replaced by a placeholder, because a command
    carrying it would RUN, while a name printed as PROSE is stripped and still reads, because the reader
    is standing on that branch and has to recognise it -- a sentence that will not name the branch has
    nothing left to say. The narrow path the measurement above names (Test-BranchName refuses these at
    creation, so it takes a branch created by hand, cloned or fetched) is now the argument for why the
    strip COSTS nothing rather than for why the gap could be weighed and left.

    WHAT THIS LIB DOES NOT DO. It is not the creation-side
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

function Get-DisplayRef {
    <#
        Ref -- the ref name, or any other single-line label, about to be printed as PROSE.

        Returns that name with every control and format character replaced by a space, runs of spaces
        collapsed, and the result trimmed. Nothing is refused and nothing is quoted: the words stay,
        because a reader has to recognise the branch they are standing on, and only the characters that
        make the printed line say something other than what it is are removed.

        WHY A SPACE RATHER THAN NOTHING. Deleting a zero-width joiner silently welds the two halves of a
        name into one word that reads as a different, legitimate branch -- which is the deception rather
        than the repair. A space cannot do that, and git forbids one in a ref, so a space in the output
        is itself the signal that something was taken out.

        WHY IT TRIMS, AND WHAT AN EMPTY RETURN MEANS. A name made ENTIRELY of format characters strips to
        blanks and comes back as ''. That is the honest answer -- the name has no display at all -- and it
        hands callers that already word an empty name ("on its branch", "this run could not read it") the
        wording they have rather than a pair of quotes around nothing.

        THE SAME CALL THIS REPO ALREADY MADE FOR A COMMIT SUBJECT, at #1439 and #1446, now stated once:
        remote-ahead-lib.ps1 carried the second copy of this pattern until #1623 and reads it from here.
    #>
    param([AllowEmptyString()][AllowNull()][string]$Ref)

    if ([string]::IsNullOrEmpty($Ref)) { return '' }
    return ((($Ref -replace '[\p{Cc}\p{Cf}]', ' ') -replace ' {2,}', ' ').Trim())
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
        as prose, where the shell metacharacters are inert, and STRIPPED OF `[\p{Cc}\p{Cf}]` on the way
        (see the implementation note below) so that it cannot repaint a terminal. The strip is what
        makes that safe, NOT git's own rules: git rejects only the `\p{Cc}` half and accepts a
        `\p{Cf}` run in a ref name (#1617). Printed with it is what the reader has to do about the
        name, which is quote it for whichever shell they are actually in.
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
    # sanitiser applied to this lib's own output. IT IS LOAD-BEARING ON BOTH INPUTS, not belt-and-braces
    # on either (#1617). git rejects only `\p{Cc}` in a ref, so a name straight from `git rev-parse` can
    # still carry a `\p{Cf}` character -- U+202E and U+200D among them, the two #1446 was filed for --
    # and Get-PasteableRef additionally takes a STRING, which sync-main.ps1 builds from a seam answer a
    # consumer wrote and git has never seen. Without this, the one place this lib prints is a place an
    # ANSI/OSC escape or an RTL override could repaint a terminal or wear this workflow's own warning
    # prefix, and a guard whose refusal path is itself an injection surface is worse than no guard. The
    # same reasoning as #1439 and #1446, at a new site.
    #
    # THE STRIP ITSELF MOVED TO Get-DisplayRef (issue #1623) -- it was written out here, which made this
    # the tree's third copy of one pattern. Two things followed. The wording above is now the WHY and the
    # function is the WHAT, so a future correction to either lands in one place; and a case this line got
    # wrong is repaired, because Get-DisplayRef trims: a name made ENTIRELY of format characters used to
    # strip to blanks and produce a note reading "The branch is:" with nothing after it, which is the
    # "tells the reader nothing" failure the paragraph above exists to prevent, arriving through the
    # strip instead of through the empty case. It now falls through to the empty wording, which is what
    # it is once the invisible characters are gone.
    $shown = Get-DisplayRef -Ref $Ref
    if (-not $shown) { $shown = '(this run could not read it)' }

    $note = @"
  NOTE: the branch name is not safe to paste into the line above, so it reads '$Placeholder' instead.
  The branch is: $shown
  It carries characters your shell would interpret (issue #1594), and neither single nor double quotes
  close that -- put it in the command yourself, escaped for the shell you are actually in.
"@

    return [pscustomobject]@{ Token = $Placeholder; IsSafe = $false; Note = $note.TrimEnd() }
}
