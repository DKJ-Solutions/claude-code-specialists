# Development cycle: `fix/the-deploy-section-is-locked-at-the-pr-v1` · 20260825-223411

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

## PLAN

**The ask ([#884](https://github.com/DaveKJohn/claude-code-specialists/issues/884), Dave).** The DEPLOY
section travels four times -- `development-cycle.md` -> the PR body -> `CHANGELOG.md` -> the developer
release notes -- and it must be the same thing in all four. Three parts:

1. **It always says `What makes this deploy extra special`**, never `... this PR ...`. The section also
   lands in `CHANGELOG.md` and the release documents, where nobody is looking at a PR.
2. **The PR body starts with the same `## DEPLOY` heading the document carries.**
3. **The whole section is locked once the PR opens.** After that it cannot change: what is in the PR is
   what lands everywhere.

**Sequencing, and why this branch exists at all.** `feat/rename-workflow-to-contributing-davekjohn-v1`
(#886) is parked and states the order Dave resolved on August 25, 2026: **#882 -> #885 -> #884 -> #886**,
each its own branch, so the rename only ever touches settled ground. #882 landed as
[#889](https://github.com/DaveKJohn/claude-code-specialists/pull/889) and #885 as
[#890](https://github.com/DaveKJohn/claude-code-specialists/pull/890); this is the third, and #886 stays
parked until it is in.

**Part 1 needs no find-and-replace, and the grep count says otherwise -- which is the measurement worth
recording.** `What makes this PR extra special` occurs in 15 tracked files, 43 times. The *subject* is
**one constant**: `entry-scaffold-lib.ps1` already separates the heading it WRITES
(`$script:EntryTierHigherHeading`) from every heading it still READS
(`$script:EntryTierHigherRetiredHeadings`), under a standing rule -- *recognise all, write one*. So the
work is to move `PR` into the retired list and promote `deploy` out of it. Of the remaining 14 files:
`CHANGELOG.md`'s pending entries, `releases/development/4.x/*.md` and
`workflow-davekjohn/releases/audience/4.x/*.md` are **published records and stay exactly as written**
(20 of the 43 occurrences); what does need an edit is the prose that states which wording is *written
today* -- the two portable manuals, `RELEASES-portable.md`, `workflow-davekjohn/CONTRIBUTING.md`, four
skill pages, Rendall's lens, and `CHANGELOG.md`'s own intro paragraph, which dates each wording and is
live prose rather than a record.

**This is the third reversal of the same one-word heading, and the second in two days.** `deploy` was
written August 23, `PR` replaced it August 24 ([#865](https://github.com/DaveKJohn/claude-code-specialists/issues/865)),
and #884 puts `deploy` back. Dave confirmed on August 25, 2026 that #884 wins, having reread #865's
reasoning rather than treating its recency as an argument. What #865 got right is recorded and kept: it
removed the PR template's heading so the section stands on its own. What it got wrong is the reader it
optimised for -- the section is not only a PR, and #865's own code comment says so.

**Part 2 reverses the heading promotion of August 9, 2026, and only on today's shape.**
`Get-PrDescription` currently returns everything *after* the DEPLOY heading and then promotes every
heading one level (H3 -> H2), on the argument that a PR body is a document of its own rather than a block
inside `CHANGELOG.md`. That argument was sound when the entry had no H2 of its own to carry. It is now the
one transformation that makes the PR copy differ from the document copy -- which is exactly what part 3
must be able to compare. Carrying the `## DEPLOY:` heading verbatim answers both at once: the body has its
own title again, so the hierarchy is right without promoting anything, and the lock becomes exact string
equality instead of a comparison across a transform. **The legacy path keeps its promotion**: an entry
found by its old `What does the change...` heading has no H2 to carry, so promoting is still correct
there, and consumers have such branches in flight right now.

**Part 3, the mechanism Dave chose (August 25, 2026): refuse, and the PR is the recorded copy.** No new
state, nothing to strip at the fold, and nothing to clean up. `open-pr` already writes the section into
the PR body; `ship-pr` reads that body back before the merge and refuses when the document has since
diverged. Two candidates were declined: a fingerprint stamped into the document (adds an artefact to the
file the fold consumes) and a silent re-sync at merge time (never refuses anything, so it is not a lock).

**The comparison lives in `pr-body-lib.ps1` as one pure function, and the CI gate does not grow a PR
reader.** `check-branch-entry.ps1` states in its own header that it reads no PR body and knows nothing
about review state -- a deliberate boundary that keeps it pure and needs no token. Widening it would
contradict that. So the lock is its own gate script calling the same pure function `ship-pr` calls, added
as a second step to `.github/workflows/branch-entry.yml`, which needs `pull-requests: read` on top of the
`contents: read` it has today.

**Non-goals, so nothing sweeps them in:**
- **`CHANGELOG.md`'s pending entries and every release note stay as written.** Published records of what
  was true when written -- the same doctrine `workflow-davekjohn/CLAUDE.md` states for
  `releases/audience/`. Only the intro paragraph, which is live prose, is edited.
- **No wording ever leaves the reader.** `Higher than tier 0?`, `... this change ...`, `... this PR ...`
  all stay recognised. A parser that forgot one would read those entries as tier 0 alone, which is the
  silent direction that empties a release.
- **The fold, `CHANGELOG.md` and the release documents keep their own heading levels.** Part 2 changes
  the copy that goes into the PR, at the one point that copy is made.
- **This branch does not touch the plugin id.** That is #886, and it is parked on purpose.

## CREATE

- [x] Part 1: swap `$script:EntryTierHigherHeading` to `What makes this deploy extra special` and move `What makes this PR extra special` into `$script:EntryTierHigherRetiredHeadings`, with the reversal recorded in the comment block -- `scripts/lib/entry-scaffold-lib.ps1` and its plugin mirror
- [x] Part 1 (correction found while building it): `What makes this deploy extra special` had to LEAVE the retired list rather than sit on both. The list means "never written", and `entry-scaffold.tests.ps1` loops it against the scaffold -- so a heading on both would have made the scaffolder emit a string its own suite asserts is absent. Nothing stops being read by leaving: every reader unions the written constant with the list. First time a wording has come back, and the array's comment is where that case is worked out
- [x] Part 2: `Get-PrDescription` carries the `## DEPLOY:` heading verbatim and stops promoting on that path; the legacy `What ...` path keeps its promotion -- `scripts/lib/pr-body-lib.ps1` and its plugin mirror
- [x] Part 3a: `Test-DeployLock` in `pr-body-lib.ps1` -- pure, containment not equality (a consumer's template may wrap the section), normalising only CRLF and trailing whitespace, with `Applicable = $false` as a third answer for the legacy shape and an empty body
- [x] Part 3b: the lock gate fires in `ship-pr.ps1` before the merge, beside the step-list gate, with no `-Force`; an unreadable body is reported and not refused
- [x] Part 3c: the same function behind the CI gate, wired into `.github/workflows/branch-entry.yml` with `pull-requests: read`
- [~] Part 3c as PLANNED -- *a separate gate script* -- dropped, and the reason is worth the line: a new shared entry point needs a registry entry AND its own skill page (`shared-scripts.tests.ps1` asserts every shared script names a documenting page), and a skill page is an always-on token cost paid by every session. `check-branch-entry.ps1` grew an optional `-Pr` instead. Its header claimed *"It reads no PR body"*, so that paragraph was rewritten rather than quietly falsified -- the half that was load-bearing is kept: every check but the lock still needs no token, no network and no PR
- [x] Part 1 (docs): the two portable manuals, `RELEASES-portable.md`, `workflow-davekjohn/CONTRIBUTING.md`, four skill pages, Rendall's lens, and `CHANGELOG.md`'s intro. **20** live claims changed -- 19 in the docs plus `CHANGELOG.md`'s intro, counted with `grep -o` because `grep -c` counts LINES and this repo has a written lesson about that. The 20 occurrences in `CHANGELOG.md`'s pending entries and the two 4.19.0 release notes are left exactly as written
- [x] Both `CLAUDE.md` layers: they promised **three** gates and there are now four. Root page and `workflow-davekjohn/CLAUDE.md`, including the anchor between them
- [x] `.github/pull_request_template.md`: the heading travels now, so "paste that section's body" was wrong. **And the placeholder is compared VERBATIM** -- `Get-PrDescriptionPlaceholderDefaults` had to gain the new line, and the shipped reference at `plugins/workflows/workflow-davekjohn/templates/pull_request_template.md` is held to it byte for byte by the `[pr-template]` lint check. Changing the template alone would have made every PR body lose its description, silently, which is the exact defect that list exists to prevent
- [x] `check-branch-entry` skill page: `-Pr` documented (the `[skill-param]` lint check holds every shared script's parameters to its page), plus the lock's own section and three rows in the refusal table
- [x] Tests: `pr-body.tests.ps1` -- the two promotion asserts INVERTED rather than deleted, a new assert that the legacy path still promotes, and eleven for `Test-DeployLock`. 160 asserts, up from 142
- [x] `open-pr.ps1` checked and deliberately unchanged: this repo's template has no headings, so `-RefreshBody` takes the leading-section path with no boundary and replaces the whole body -- which is right, since the body IS the section. A consumer whose template has headings below the placeholder gets them as stops, as before
- [x] **`.gitignore`: `.env` ignored -- carried in deliberately, not swept in.** The line was already in the
  working tree, uncommitted, when this branch started, so it belonged to nobody's branch and would have sat
  there indefinitely. This repo is **public**. Verified before including it: `.env` exists on disk (108 B),
  has never been tracked, and appears nowhere in history -- so nothing leaked, and what was missing was only
  the guard against it. Named here and in the commit rather than riding along silently, because sweeping an
  unrelated change into a branch is the thing this repo has a written lesson about; the reason it is an
  exception is that leaving a public repo's secrets file untracked-but-unignored overnight is a live risk
  and this is one line.

## TEST

- [x] `check-plugin-integrity.ps1`: **0 errors**. The three checks this branch could plausibly have broken all
  passed on their own terms rather than by luck -- `[pr-template]` (the shipped reference held byte for byte
  to `Get-PrTemplateReference`, which is what caught the placeholder half of this change), `[skill-param]`
  (86 parameters of 22 shared entry points held against their pages, which is what required `-Pr` to be
  documented), and `[script-ascii]` (160 `.ps1` files).
- [x] **All 53 suites green, 0 failing.** `pr-body.tests.ps1` at 160 asserts, up from 142 -- and 4 of those
  142 FAILED first, which is the part worth recording: two were the promotion asserts this change
  deliberately inverts, and two were the placeholder asserts that caught a defect the plan had not
  predicted. `entry-scaffold.tests.ps1` at 486.
- [x] The failure that mattered was found by a test rather than by review. Changing
  `.github/pull_request_template.md` alone would have made **every PR body silently lose its description** --
  `open-pr` matches the placeholder as a VERBATIM whole line against `Get-PrDescriptionPlaceholderDefaults`,
  so an unrecognised comment is not an error, it is a body with nothing in it. Exactly the defect that list
  was created for (#573, twelve merged PRs found months later by diffing templates). Repaired by adding the
  new line to the list and regenerating the shipped reference from the function.
- [x] The second one was found by reading the invariant rather than by running anything, and it would have
  been caught either way: putting `What makes this deploy extra special` on BOTH the written constant and
  the retired list makes the scaffolder emit a string `entry-scaffold.tests.ps1` asserts is absent. Corrected
  before the suite ran; the array's comment now carries the case.
- [x] `Test-DeployLock` exercised on all six behaviours before it was wired into anything: identical body,
  body wrapped by a template, a CRLF round trip, one line edited in the document, the heading missing from
  the body, and the legacy shape answering *not applicable*.
- [x] `check-branch-entry.ps1` run on this branch with no `-Pr`: it reported the unwritten DEPLOY section
  correctly and asked for it under the NEW heading, which is part 1 proved end to end through the scaffolder,
  the parser and the gate in one run.
- [~] The CI half is **not proved here**, and that is a limit rather than a pass. `pull-requests: read` plus
  `${{ github.event.pull_request.number }}` can only be exercised by a real `pull_request` event, so this
  branch's own PR is the first run of it. The failure mode if it is wrong is benign by construction -- an
  unreadable body is reported and not refused -- so a wrong token scope shows up as an `[INFO]` line saying
  the lock did not fire, not as a blocked merge.

## DEPLOY: `fix/the-deploy-section-is-locked-at-the-pr-v1`

The DEPLOY section is now **one text in all four places it lands** -- the branch's own
`development-cycle.md`, the PR body, `CHANGELOG.md`, and the developer release notes -- and it is **fixed
at the moment the PR opens**. `ship-pr` refuses to merge when the document has since diverged from what
the PR published, and the branch-entry check in CI refuses the same thing for a PR merged from the GitHub
UI. Neither has a `-Force`, like the step-list gate beside them. What that closes is a window that used to
shut invisibly: an edit made after the review landed in the changelog and from there in the release notes
having been seen by nobody, and because the fold *removes* the document at the merge, the place a reviewer
would compare the two was the one place it no longer existed.

Two changes had to happen for that to be checkable at all, and both are reversals recorded rather than
quietly made. The heading says **`What makes this deploy extra special`** again -- `deploy` was written
August 23, `PR` replaced it August 24 ([#865](https://github.com/DaveKJohn/claude-code-specialists/issues/865)),
and #884 puts it back, because two of the section's four readers are not looking at a PR and the two that
come last are the ones a release is read from. And `Get-PrDescription` now carries the `## DEPLOY:` heading
**verbatim**, promoting nothing, which reverses the August 9, 2026 heading promotion **on today's shape
only**: while body and document were two renderings of one section, a comparison would have had to
reproduce the transform to make sense of them. The legacy `What does the change...` path keeps promoting,
because there the H2 genuinely stays behind, and consumers have such branches in flight.

**Score:** 3

### What makes this deploy extra special

A consumer meets three things at their next plugin update. Their PR bodies start carrying the
`## DEPLOY:` heading and the section's own levels, instead of a level-shifted copy with the heading
dropped -- so a PR body and the changelog entry it becomes now read as the same document. Their scaffolder
writes `deploy` rather than `PR`, and every wording it has ever written is still **read**, so branches in
flight fold unharmed. And a merge is refused where it used to go through: edit the DEPLOY section after
opening the PR and `ship-pr` stops, naming the first line the PR body does not have, with two ways out --
put it back, or republish deliberately with `open-pr.ps1 -RefreshBody` so the change is reviewable where
the review happens.

The one action a consumer may have to take is a permission line: reading a PR body needs
`pull-requests: read` on the branch-entry workflow, on top of the `contents: read` it has today. Without
it the lock reports that it could not read the body and merges anyway -- deliberately, because `gh`
failing says something about the token rather than about the section -- so nothing breaks, it simply does
not fire.

**Score:** 4

### Pull Request

The DEPLOY section is locked once the PR opens, and says deploy everywhere
