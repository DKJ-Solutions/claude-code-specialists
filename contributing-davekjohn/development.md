## Development: `docs/v4-22-0-note-correction-v1` · 20260828-203916

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

Correct the two statements #1038 names in the published v4.22.0 audience note, under the published-record
rule that protects only what was true when typed.

#### The call this branch rests on, made before anything was edited

[#1038](https://github.com/DaveKJohn/claude-code-specialists/issues/1038) presents the repair as an open
policy question -- correct in place, annotate, or leave standing. It is not open.
[`RELEASES-portable.md`](plugins/workflows/contributing-davekjohn/RELEASES-portable.md)'s *"Once it has
landed it is a published record -- and that protects only what was true"* already gives the test, and it is
**not** whether the line is wrong now but whether it was wrong when it was typed. That test splits the
note's three claims rather than answering yes or no to all of them:

- the table row `54 suites at 443s` was **true when typed** -- the leg took that long, and recording elapsed
  time is the row's whole job. It is frozen and stays.
- *"The suites are now the release, at 443s ... the leg to watch, because it is the only one that grows with
  the product"* was **false when typed**: the gate cost about 200s on that tree, and the rest was load.
- *"The verdict had depended on who invoked the gate, not on the tree"* was **false when typed**, and
  checkably so on the day -- `cut-release.ps1:262,275` dot-source `repo-config.ps1` and
  `native-capture-lib.ps1` before the gate is called, so both runs had identical state.

The form comes from PR #694, which corrected the v4.11.0 note the same way: the false lines repaired in
place and marked, and a `## Correction to this page` section carrying the date, the original wording and the
status of the frozen attachment.

#### What the attachment actually carries, measured rather than assumed

`v4.22.0-notes-for-users.md` was uploaded 2026-08-28T15:19:17Z, 169 lines. It carries the 443s claim and
**not** the caller attribution -- that sentence was written into the repo copy afterwards, in the
release-notes commit, so the asset still ends at the pre-freeze *"the total is added in a second pass"*
paragraph. The Correction section says so, because a reader who downloads the asset needs to know which
half reached them.

### CREATE

- [x] Correct the two false claims in `releases/audience/4.x/4.22.0.md`, leaving the 443s table row frozen,
      and mark each corrected line
- [x] Add the `## Correction to this page` section: the date, what each line first said, what was
      re-measured, and which half the frozen attachment carries
- [x] Point the corrected prose at where the standing answer already lives, so the note is one click from
      the re-measurement rather than restating it

### TEST

- [x] Lint gate + all suites green via `open-pr.ps1`

### DEPLOY: `docs/v4-22-0-note-correction-v1`

The published `v4.22.0` note stops telling its readers that the test suites cost 443s, and stops
attributing a red gate run to who invoked it.

Both statements were falsified hours after publication, by the verification of the inbound report the
release's own gate trouble produced ([#1033](https://github.com/DaveKJohn/claude-code-specialists/issues/1033)),
and [#1038](https://github.com/DaveKJohn/claude-code-specialists/issues/1038) filed them rather than
repairing them -- correctly, since that was not #1033's assignment. It framed the repair as an open policy
question: correct in place, annotate, or leave standing.

**It is not an open question, and the answer splits the note's claims rather than covering them all.**
`RELEASES-portable.md` already gives the test -- *not whether the line is wrong now, but whether it was
wrong when it was typed*. The table row `54 suites at 443s` was true when typed: that leg took that
long, and recording elapsed time is the row's whole job, so it is **frozen and untouched**. The two
sentences built on top of it were false when typed --
the gate costs about 200s on that tree, and `cut-release.ps1:262,275` dot-source `repo-config.ps1` and
`native-capture-lib.ps1` before calling it, so no caller axis ever existed -- and those are **corrected**,
each marked *(Corrected -- see below.)*. The form is PR #694's, which corrected the `v4.11.0` note the same
way.

One thing was measured rather than assumed, and it is the part a reader cannot get anywhere else: the two
halves reached readers differently. The frozen attachment `v4.22.0-notes-for-users.md` carries the 443s
claim, and does **not** contain the caller attribution at all -- that sentence was written into the repo
copy afterwards, in the release-notes commit, so the asset still ends its timing section at *"the total is
added in a second pass"*. The new `## Correction to this page` section says exactly that, alongside what
each line first said and what the five re-runs measured.

**Score:** 2

#### What makes this deploy extra special

A published record was corrected without being rewritten, and the seam between those two things is now
demonstrated rather than merely stated. The published-record rule's own distinction -- protect what was
true, correct what was false -- had only ever been exercised on a line that was plainly false on the day.
Here it had to be applied *within a single paragraph*, separating a clock reading that stands from the
argument built on it that does not, which is the harder and far more common shape.

**Score:** 1

#### Pull Request

The v4.22.0 note's falsified gate cost and caller attribution, corrected
