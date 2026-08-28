## Development: `fix/fenced-links-rewritten-by-the-cut-v1` · 20260828-234344

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
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

Issue #1052: the gate that judges an entry's links and the cut that moves them disagreed about what
counts as a link. `Get-EntryLinkTargets` excludes fenced blocks, inline code spans and html comments;
`Convert-EntryRelativeLinks` applied its regex to the whole entry. Give both halves one answer.

#### Why a stripper could not simply be reused

The exclusion was written as three successive deletions, which is everything a reader needs -- it looks
at what is left and never has to hand the text back. The rewriter cannot use that shape at all: it must
return the entry with the illustrations still in it. So the shared form is offsets, not stripped text.

### CREATE

- [x] `Get-EntryCodeSpans` in `../scripts/lib/entry-scaffold-lib.ps1` -- the three exclusions as spans over
      the text as given, masked (not stripped) between the passes so the offsets stay true and a stray
      backtick inside a fence cannot pair with one in the prose after it.
- [x] `Remove-EntryCodeSpans` -- the reader's half; `Get-EntryLinkTargets` now calls it instead of carrying
      its own three strippers.
- [x] `Test-EntryOffsetInCodeSpans` -- the rewriter's half.
- [x] `Convert-EntryRelativeLinks` in `../scripts/lib/release-lib.ps1` walks the entry's link matches and
      skips any that begins inside a span.
- [x] Docstrings on both functions updated to name the shared owner, so neither reads as the one that
      decides what an illustration is.
- [x] Mirrored to `../plugins/workflows/contributing-davekjohn/scripts/lib/` via `build-shared-scripts.ps1`.

### TEST

- [x] `../scripts/tests/release-lib.tests.ps1`: all three illustration classes plus a `~~~` fence left
      alone while three real links beside them are rewritten, an assert that the rewriter moves exactly
      the set `Get-EntryLinkTargets` reads, and a CRLF fixture proving the offsets land on the right
      characters.
- [x] `../scripts/tests/entry-scaffold.tests.ps1`: the primitives themselves -- span bounds, ordering and
      non-overlap, the empty cases, the stray-backtick case that proves masking rather than stripping, the
      boundary behaviour of the offset test, and the measured `[PR #N](url)` fixture still reading zero
      through the shared function.
- [x] All 55 suites green; `check-plugin-integrity.ps1` and `check-script-contract.ps1` clean.

### DEPLOY: `fix/fenced-links-rewritten-by-the-cut-v1`

A markdown link written inside a code fence, an inline code span or an html comment is an illustration
of a link -- a sample entry, a quoted path, a line a gate prints -- and the release cut now leaves it
exactly as written. It used to rewrite it, because the two halves of one rule had two implementations:
`Get-EntryLinkTargets`, which open-pr's link gate reads, excluded code and comments; `Convert-EntryRelativeLinks`,
which the cut reads, applied its regex to the whole entry. So the cut rebased links the gate had never
looked at. Both halves now read one function, `Get-EntryCodeSpans`, which answers where the code is
rather than handing back the text without it -- the form a rewriter can use and a stripper cannot.

**Score:** 2

#### What makes this deploy extra special

Prevents a silently mangled illustration inside a tagged, immutable release document: quote a relative
markdown link inside a fence in a changelog entry, cut a release, and the generated note ships that
example with an extra `../../../` on the front, discoverable only by a reader. [#1047](https://github.com/DaveKJohn/claude-code-specialists/issues/1047)
widened the exposure by one class a day earlier when it stopped exempting `../`, which is the ordinary
shape a quoted example has. Nothing has broken yet in this repo -- no entry here has quoted one -- so this
is the failure named rather than the failure repaired.

**Score:** 1

#### Pull Request

the cut leaves a markdown link inside a code fence alone
