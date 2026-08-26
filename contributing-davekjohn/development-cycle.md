## Development cycle: `feat/the-workflow-shifts-one-level-down-v1` · 20260826-113323

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Implement the delta between the `CONTRIBUTING.md` that PR #905 shipped and the spec in
[#894](https://github.com/DaveKJohn/claude-code-specialists/issues/894) **as edited on August 26, 2026** at
08:02-08:03 UTC. That branch was parked the previous evening and its plan was written from the original body,
so the edits existed 21 minutes before its commit and never reached it; `Closes #894` was true for the spec of
August 25 and not for the one on the issue now. Reopened today with the delta written out.

#### The two decisions this rests on (Dave, August 26, 2026)

**1. Everything shifts one heading level down.** The ambiguity was real and had three readings -- the edited
body says "4 `###` headers" where the original said "4 `##`", and the third edit added a `#` before each
`---- [ N ... ] ----` divider. Dave chose the whole-document reading: the cycle file's title becomes an H2 and
its four phases H3, and `CONTRIBUTING.md`'s four numbered sections become H1 with their substeps at H2.

**2. `## [Unreleased]` becomes real.** The spec names it three times and `CHANGELOG.md` does not have it: the
document is an intro followed by one H2 per change, and a cut empties it down to that intro. That flat shape is
Dave's own decision of August 5, 2026, stated in `scripts/lib/release-lib.ps1` as *"THE FLAT CHANGELOG ... ONE
H2 PER CHANGE"* and *"A CUT WRITES NO RELEASE BLOCK"*. He is reversing it deliberately, and the argument is
mechanical rather than a preference: see the invariant below.

#### The invariant that decides every number

The DEPLOY section travels **verbatim** from this file into `CHANGELOG.md` at the fold. That is why
`BranchCycleSectionLevel` and `EntryHeadingLevel` were equal before this branch, both `2` -- a property built on August 23,
2026, replacing a fold that pasted H3 entries unchanged and renderers that re-levelled per document. Decision 1
alone would break it, and decision 2 is what keeps it: with `## [Unreleased]` occupying H2, entries nest at H3,
which is exactly where the cycle file's DEPLOY lands.

| knob | today | after |
|---|---|---|
| `BranchCycleHeadingLevel` (this file's title) | 1 | 2 |
| `BranchCycleSectionLevel` (PLAN/CREATE/TEST/DEPLOY) | 2 | 3 |
| `EntryHeadingLevel` (an entry in `CHANGELOG.md`) | 2 | 3 |
| `EntrySectionLevel` (an entry's inner sections) | 3 | 4 |

`BranchCycleSectionLevel == EntryHeadingLevel` holds before and after. Any change that breaks that equality is
wrong regardless of what else it satisfies.

#### Reading the old levels is mandatory, not a courtesy

This is the repo's standing precedent -- #905 stated it as *"Nothing is renamed without the old name still being
read"* -- but here it is load-bearing for **this branch's own merge**: the file you are reading was scaffolded
at the old levels, and the fold that runs after the merge must still parse it. Beyond that: every consumer with
an in-flight branch, the pending entries in `CHANGELOG.md`, and every archived note under
`releases/development/`. Both level pairs are read; only one is written.

#### What is deliberately NOT in this branch

The three release-note roots of the edited `3B` -- `releases/changelog/`, `releases/github/`,
`releases/audience/` under the workflow folder, where today `releases/development/` and `releases/github/` sit
at the repo root and only `audience` sits under the folder. That is a relocation plus a rename
(`development` -> `changelog`), it overlaps the open questions on the release-note layout, and it is a separate
subject from the heading levels. It stays on #894 for its own branch.

### CREATE

- [x] Shift the four level knobs in `scripts/lib/entry-scaffold-lib.ps1` and widen every reader to accept both
      pairs -- `Get-BranchFileDeclaredBranch`'s heading regex (now 1..3), `Get-DevelopmentCycleEntryPattern`
      (now a range, safe because it also requires the branch name and the title word),
      `Test-IsChangelogEntryFile`'s legacy range (which changed DIRECTION: the level still to cover is the one
      ABOVE, not below), a new `Get-EntrySectionLevelRange` for the six readers that pinned the section
      level exactly, `Get-EntryTierSubLevel` (both shapes now derived from the section level rather than
      stated), and `Get-EntryInsertOffset`'s `$EntryPattern` default -- a literal, because a parameter default
      cannot call a function, and therefore the one pin that failed silently rather than loudly
- [x] Update the scaffolder's own preamble so a new branch document states its own shape correctly -- and
      compose the levels from the knobs rather than typing them, since the prose and the parser disagreeing
      is what this step exists to fix
- [x] Replace the two hardcoded levels in `scripts/lint/check-branch-entry.ps1`. Not with a range: the new
      TITLE level and the old PHASE level are the same number, so a range would read a correct document's
      title as a fifth phase. It reads the first heading as the title and the phases as exactly one under it
- [x] Replace the hardcoded levels in `scripts/lib/pr-body-lib.ps1` -- the DEPLOY-lock's expected-first-line
      test now reads the level off the format and accepts both
- [~] Teach `scripts/lib/release-lib.ps1` the `## [Unreleased]` model -- **no change needed, and that is the
      design rather than luck.** The pending heading sits one level shallower than an entry, so
      `Split-Changelog`'s existing boundary ("the first entry heading") lands below it and it falls into the
      document's HEAD. Asserted rather than assumed: `release-lib.tests.ps1` now pins it as the last line of
      `.Head`
- [~] `scripts/release/fold-changelog-entry.ps1` inserts under `## [Unreleased]` -- **no change needed**, for
      the same reason. `Get-EntryInsertOffset` takes the ENTRIES region, which begins below the head, so every
      insert already lands under the pending heading. Asserted alongside the head test
- [~] `scripts/release/cut-release.ps1` -- **split, and half of it moved.** The half that matters here is free:
      `Convert-ChangelogForRelease` keeps the head verbatim, so a cut leaves a fresh empty `## [Unreleased]`
      rather than a bare intro, and there is now an assert on that function saying so. The other half --
      stamping the block as `## [X.Y.Z] - <date>` into the release note -- belongs with the three release-note
      roots on #894: the note already carries its version and date as `# Release notes vX.Y.Z` plus a
      `**Date:**` line, and Dave's `3C`/`3D` name `releases/changelog/` as the destination, which this branch
      deliberately does not touch
- [x] Add `## [Unreleased]` to `CHANGELOG.md` and re-level its pending entries -- 27 headings shifted one
      deeper, fence-aware through the lib's own flagger so the intro's quoted examples were left alone
- [x] Update the `CHANGELOG.md` intro, which stated the shape in prose ("one `##` per change", "two named
      `###` sections", "`#### Tier N`"), and the two `entry-shape` fixtures in
      `check-plugin-integrity-docs.tests.ps1` that stated it too
- [x] Restructure `contributing-davekjohn/CONTRIBUTING.md`: sections to H1 and substeps to H2; section 1 to
      `[ 1 NEW DEVELOPMENT TASK ]` split into 1A-1H; section 2 to `[ 2 PULL REQUEST ]` with "open PR" as its
      own 2A and the rest at 2B-2E; section 3 gaining the optional 3H wait for a SHIP MAIN / PUSH LIVE
      command; section 4 to `[ 4 SHIP MAIN / PUSH LIVE ]` with only 4A left
- [~] Fix the two places in that file that name the Unreleased heading -- **they were already right.** The
      step assumed they would move level; they name `## [Unreleased]`, which is exactly the level the heading
      now occupies. The two lines that described the format wrongly were elsewhere in the same file, and those
      were fixed
- [x] Update the four-headings rule in
      `plugins/workflows/contributing-davekjohn/DEVELOPMENT-portable.md`, keeping its measurement
      (`check-branch-entry.ps1` gives byte-identical output at four headings and at five) -- and record why
      the reset-versus-written test is now the NAME rather than the level, since the level test would call an
      empty trunk document a foldable change
- [x] Mirror every changed script into `plugins/workflows/contributing-davekjohn/scripts/`, byte-identical
      (three mirrors, via `build-shared-scripts.ps1`)
- [x] File the `new-branch.ps1 -Intent` defect as
      [#908](https://github.com/DaveKJohn/claude-code-specialists/issues/908): it writes branch-specific text
      above `### PLAN`, which the preamble it prints in the same breath forbids

### TEST

- [x] Extend `scripts/tests/entry-scaffold.tests.ps1` to assert BOTH level pairs parse -- including a document
      built at the PRE-SHIFT pair whose DEPLOY section is still found, which is the case this branch's own fold
      will meet after the merge
- [x] Extend `branch-entry-gate.tests.ps1`, `pr-body.tests.ps1`, `new-branch.tests.ps1`, `fold-changelog.tests.ps1`, `cut-release-drive.tests.ps1`, `session-status.tests.ps1`,
      `check-plugin-integrity-entries.tests.ps1` and `check-plugin-integrity-docs.tests.ps1` -- every one of
      them by COMPOSING the level from the lib rather than restating it, so the next re-level does not
      reproduce this work
- [x] Add the `release-lib` asserts: the pending heading is the last line of the head, the first entry is
      still the first real entry, and a cut leaves a fresh pending heading behind
- [x] Assert the invariant directly, in both libs -- the cycle document's section level equals the entry
      heading level -- so a future re-level cannot silently break the verbatim paste
- [x] Run `scripts/lint/check-plugin-integrity.ps1` (0 errors) and every suite, and count PASS as well as
      FAIL: a parse error yields zero of both, which is how a broken suite read as green once during this
      branch

### DEPLOY: `feat/the-workflow-shifts-one-level-down-v1`

The development cycle document and `CHANGELOG.md` each move one heading level deeper, and
`contributing-davekjohn/CONTRIBUTING.md` moves one shallower -- the shape Dave asked for in the edited
[#894](https://github.com/DaveKJohn/claude-code-specialists/issues/894), which PR #905 could not have built
because the edits landed 21 minutes before its commit and after its plan was written. A branch document is now
`## Development cycle` with `### PLAN`, `### CREATE`, `### TEST`, `### DEPLOY`; `CHANGELOG.md` gained a real
`## [Unreleased]` section with `###` entries under it; and CONTRIBUTING's four steps became its top level, with
section 1 split into 1A-1H, section 2 gaining "open the PR" as its own 2A, section 3 gaining an optional 3H
wait for a `SHIP MAIN` / `PUSH LIVE` command, and section 4 reduced to the single act that command releases.

**`## [Unreleased]` is what makes the rest cost nothing, and it reverses a decision on purpose.** The flat
changelog -- an intro followed directly by one entry per change -- was Dave's own answer of August 5, 2026. He
reversed it here, and the mechanical argument is that the pending heading takes H2, which is what lets an entry
nest at H3 and therefore land at exactly the level the cycle document's DEPLOY phase carries. That equality is
what makes the fold a verbatim paste instead of a re-level, and it now has an assert in both libs -- it had
none before, having held only by the two pairs happening to agree.

**Nothing was pinned that could be composed.** Sixty assertions across six suites failed on the shift, and
almost none of them were about the level they named: they were structural claims written with a literal `##`
that had drifted into being a second definition of the format. Every one now reads its level from the lib, so
the next re-level does not reproduce this afternoon.

**And two of those pins were in the SCRIPTS, where the same drift is silent instead of red.** Both were found
by a suite rather than by reading, and neither would have raised anything at runtime:

- **`Get-EntryInsertOffset`'s `$EntryPattern` default was the literal `'(?m)^## '`.** A parameter default
  cannot call a function, so the level had been typed -- and once it was stale, every caller relying on the
  default saw a changelog with no entries in it. The fold then ranked each new entry against an empty list
  and appended it, which silently reverses the order the list is supposed to hold. It is resolved in the
  function body now. The fixture that caught it carries a comment describing this exact failure from the
  *previous* level move, three weeks earlier -- it had been repaired by typing the new number rather than by
  composing it, which is why it broke a second time.
- **`session-status.ps1` walked the changelog on `'^##\s'`.** Two things went wrong at once and only one was
  loud: entries at H3 stopped being counted, so the status block would have reported "none pending" on a
  changelog holding nine -- and `## [Unreleased]`, which sits at exactly the level that pattern wanted, would
  have been printed *as* a pending change. It reads the level from the lib now and skips the pending heading;
  the no-library fallback accepts both levels, because that branch cannot ask.

**This section is pure ASCII on purpose, and it is not a house style.** The DEPLOY lock compares the section
against the PR body, and `ship-pr` reads that body through a non-UTF-8 decode -- so any non-ASCII character
makes a clean document mismatch a mojibake copy of itself
([#907](https://github.com/DaveKJohn/claude-code-specialists/issues/907), still open). Three em-dashes were
flattened to `--` to get this merged, exactly as
[#906](https://github.com/DaveKJohn/claude-code-specialists/pull/906) did the day before. Do not copy the
convention; fix the decode.

**Score:** 4

#### What makes this deploy extra special

**A consumer's `CHANGELOG.md` needs migrating, and the fold and the cut now say so instead of doing something
quiet.** Their document's entries sit at the level the pending heading occupies, so without a migration
`Split-Changelog` finds no entries and a cut would describe nothing. That path was already guarded; the guard
had to be widened, because with an entry one level deeper a leftover heading falls into the HEAD where neither
loop was looking. Widening it turned up a second gap the same guard already had: a leftover heading BELOW the
first entry -- exactly the shape of the consumer document this guard was built from, which has two of them with
a real entry between -- was never reported at all, and the assert demanding both had been passing on the
example list inside the refusal's own message rather than on a finding.

**What does not need migrating is anything in flight.** Every reader accepts both level pairs, so a branch open
when the plugin updates keeps folding, and this branch is the proof: its own document was scaffolded before the
shift and is read by the merged code.

**Score:** 5

#### Pull Request

The cycle document and CONTRIBUTING shift one heading level down
