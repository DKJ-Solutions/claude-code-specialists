## fix/1768-path-paste-one-answer

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Two branches answered #1762 eleven minutes apart and both landed on `main`, leaving the tree with two
mechanisms for one question -- how a filesystem path is rendered into a command a reader is invited to
paste. #1765 gave the shared paste guard its own `$PathPasteSafePattern`; #1767 shipped
`Format-PasteablePathToken` in `tidy-lib.ps1`, which quotes the path as a PowerShell literal instead of
judging it. Inbound #1768 asks which one survives.

#### The verdict, and what decided it

The allowlist survives; the literal-quote formatter is retired. Two measurements decided it, and neither
is in the report.

**Its premise had already expired when it landed.** The formatter argues that `Get-PasteableRef -Kind
Path` judges against the ref allowlist and so "NO absolute Windows path can pass it, ever". That was true
of the pattern it was written against and false eleven minutes later -- #1765 is exactly the change that
fixed it. An ordinary lane path passes today, so the noise the second mechanism was built to remove was
already gone when it was read.

**Its guarantee belongs to one shell, and the commands it serves do not.** The single-quoted literal is
exact in PowerShell and in neither of the other two this lib commits to. Measured September 10, 2026:
the token for `C:\it's\here` is `'C:\it''s\here'`, and bash reads a doubled quote as close-then-open, so
Git Bash resolves it to `C:\its\here` -- a different, entirely plausible path, silently and with no
error to notice. In cmd, where single quotes do not quote, any spaced path splits into two arguments.
That is decisive *here* because `tidy-machine.ps1` prints two commands per lane from the same call: a
PowerShell-only `worktree-lane.ps1 -HandBack`, and a bare `git worktree remove` directly beneath it --
which is precisely the kind a reader pastes into Git Bash.

#### What the report proposed that is NOT done, and why

#1768 offers "if the allowlist wins, it needs at least a space". It must not have one. The `.Token` is
printed **unquoted**, on purpose -- ref-print-lib's header rejects quoting as the guard -- so
`git worktree remove C:/Program Files/x` splits into two arguments in every shell rather than one. A
space is the one character an allowlist over an unquoted token can never admit, whatever the destination
turns out to be. `ref-print-lib.tests.ps1` has asserted that refusal for `C:\Program Files\a b\x` since
#1762: it is the answer, not a gap in it, and the note carries the reader the rest of the way.

#### And one claim in the report does not stand

It states that `tidy-lib.ps1`'s header "cites #1762 as open" and quotes *"if that reasoning holds it
belongs in this lib and not in a caller"*. Neither is in the tree: that file's only #1762 mention reads
"(issue #1762, measured September 10, 2026)", and the quoted sentence matches nothing anywhere in the
repo. The symptom the report is actually about -- two mechanisms, one question -- stands on its own, so
the repair is unaffected; the wording is corrected here rather than inherited.

### CREATE

- [x] `scripts/lib/tidy-lib.ps1` -- `Format-PasteablePathToken` removed. It was that lib's only caller
      into `ref-print-lib.ps1`, so the dependency goes with it.
- [x] `scripts/maintenance/tidy-machine.ps1` -- `Write-PathHandover` now calls
      `Get-PasteableRef -Ref $Path -Kind Path`, and its doc comment carries the reasoning above. The old
      comment claimed the path "is quoted here because a lane directory legally contains spaces", which
      stopped being true of what the function does.
- [x] `scripts/lib/ref-print-lib.ps1` -- the surviving mechanism records why it survived, why a space
      stays out of the pattern, and the cross-shell measurement, beside the #1762 block it continues.
- [x] `scripts/sync/build-shared-scripts.ps1` run -- four plugin mirrors updated.

### TEST

- [x] `scripts/tests/tidy-lib.tests.ps1` -- section 7 (the retired formatter) removed and the remaining
      sections renumbered; three structural assertions added so the second mechanism cannot come back by
      halves: the formatter is not called, the handover goes through `-Kind Path`, and the function is
      not defined at all.
- [x] **A defect in that suite's own scan, found by the new assertion and repaired rather than worked
      around.** Its structural section stripped line-comment tails but not `<# ... #>` blocks, so every
      inner line of a function comment stood as apparent code. A doc paragraph *naming* the retired
      formatter therefore failed the assertion that it is not *called*. Block comments are removed first
      now. This was silent only while the forbidden words happened not to appear in one -- every other
      assertion in that section inherited the same hole.
- [x] `scripts/tests/ref-print-lib.tests.ps1` -- the space refusal is pinned with its reason, because it
      reads as the pattern's weakest point and #1768 proposed removing it.
- [x] **The first draft of that third assertion was refused by another gate, and the refusal was
      right.** It probed with `Get-Command -Name ... -ErrorAction SilentlyContinue`, the idiom #1729
      retired tree-wide, and `command-probe-lib.tests.ps1` caught it in the full run. This probe is a
      MISS by design, which is that idiom's expensive case: a bare `Get-Command` answers a miss by
      scanning all 19 PATH directories for an executable of that name, uncached. Now
      `Test-FunctionDefined`.
- [x] `tidy-lib.tests.ps1` 46 passed / 0 failed; `ref-print-lib.tests.ps1` 444 pass / 0 fail;
      `command-probe-lib.tests.ps1` 16/16.

### DEPLOY: fix/1768-path-paste-one-answer

A filesystem path printed into a paste-ready command now has **one** answer again, the shared allowlist
`Get-PasteableRef -Kind Path`. Two branches answered #1762 eleven minutes apart and both landed;
`tidy-lib.ps1`'s `Format-PasteablePathToken` -- which quoted the path as a PowerShell literal rather than
judging it -- is retired, and `tidy-machine.ps1` joins `sync-main.ps1` and `check-plugin-integrity.ps1`
on the allowlist. Fixes inbound #1768.

The literal lost on the destination, which is the one thing a printed remedy does not know. It is exact
in PowerShell and silently wrong in Git Bash, which reads its doubled quote as close-then-open and turns
`C:\it's\here` into `C:\its\here` -- a different, plausible path, with no error to notice -- while cmd
splits any spaced path in two. `tidy-machine.ps1` prints a PowerShell-only `worktree-lane.ps1 -HandBack`
and a bare `git worktree remove` from the same call, one line apart, and the second is exactly what a
reader pastes into Git Bash. Its own justification had also expired before it was read: it argued no
absolute path could pass the allowlist, which #1765 had fixed eleven minutes earlier.

**Score:** 2

#### What makes this deploy extra special

The report's own proposed alternative is declined with a measurement rather than adopted: *"if the
allowlist wins, it needs at least a space"* would break the guard rather than widen it, because the token
is printed **unquoted** by design and a spaced path splits in all three shells, not one. A space is the
one character an allowlist over an unquoted token can never admit -- so the refusal plus the note is the
answer, and the suite has asserted it since #1762.

That is the second of #1768's two halves to fail on contact with the tree. The first is its claim that
`tidy-lib.ps1` cites #1762 as open and carries a sentence about where the reasoning belongs; neither is
in the repo. The symptom it reports -- two mechanisms for one question -- was real and is what got fixed.

**Score:** 3

#### Pull Request

One answer for a path in a printed command: the allowlist, not the PowerShell literal

