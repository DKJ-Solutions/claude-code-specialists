## fix/1497-fold-all-reserved-names

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

Wires Get-BranchFilePaths().ReservedNames into fold-changelog-entry.ps1's fold-all discovery loop over dkj-policy/, which previously read CHANGELOG.md itself (and, separately, README.md) as an unfolded per-branch dossier and could delete/corrupt them. Found while testing #1493's CI fold workflow. Adds a regression test reproducing both false positives against a realistic fixture.

### CREATE

- [x] `scripts/release/fold-changelog-entry.ps1`: the fold-all discovery loop over
      `Get-BranchFilePaths().Directory` now skips any filename in `.ReservedNames`
      (`README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`) before reading its content, mirroring the
      legacy root-level scan's own `$reserved` exclusion a few lines below it.
- [x] `scripts/tests/fold-changelog.tests.ps1`: a new regression test builds a fixture with
      `dkj-policy/CHANGELOG.md` (re-pointing the seam `New-FoldFixture` patches to the root, since
      this fixture's whole premise is the co-located production shape), `README.md` (with a
      backtick-quoted, slash-carrying title -- the exact shape that fooled the parser) and
      `CONTRIBUTING.md` sitting alongside one genuine unfolded dossier, and asserts the real dossier
      still folds while all three reserved files survive untouched.

### TEST

Ran the full `fold-changelog.tests.ps1` suite: 200 pass, 0 fail (199 pre-existing + 1 new). The new
test failed twice before landing in its current form, both informative:

- First failure: the "already-folded" entry I seeded wasn't recognised at all -- traced to a missing
  `---`-free, `## [Unreleased]`-free intro shape; this suite's proven fixture shape
  (`$script:FixtureIntro`, already used by the "duplicate" test) has no such heading, and matching it
  exactly is what made the seeded entry parse.
- Second failure: the real dossier folded (file removed, tier/significance reported correctly) but its
  text never reached `CHANGELOG.md`. Root cause: `New-FoldFixture` unconditionally patches every
  fixture's `repo-config.ps1` to point `ChangelogPath` at the fixture ROOT -- deliberately, so the
  suite's other (pre-`dkj-policy/`) fixtures keep passing -- so my fixture's `dkj-policy/CHANGELOG.md`
  was never the file actually being read or written. Fixed by re-patching the seam back to
  `dkj-policy/CHANGELOG.md` for this one test, after `New-FoldFixture` runs.

Also re-verified directly against this repo's own live tree (not just the fixture) before writing the
fix: reproduced both false positives on `main`, restored the accidentally deleted `README.md` and
corrupted `CHANGELOG.md` via `git checkout` (nothing was committed), then re-ran fold-all mode after the
fix and confirmed a clean "No entry files found to fold." with `git status` showing no changes.

### DEPLOY: fix/1497-fold-all-reserved-names

`fold-changelog-entry.ps1`'s fold-all mode (no `-Branch`) no longer mistakes `CHANGELOG.md`,
`CONTRIBUTING.md` or `README.md` for an unfolded per-branch dossier. Since `dkj-policy/` started
holding all three alongside every branch's own dossier file (#1437), the fold-all discovery loop's
`*.md` glob over that directory had no exclusion for them -- unlike the legacy root-level scan a few
lines below it, which has always excluded these names correctly. `Get-BranchFilePaths` already exposed
exactly the exclusion needed, `.ReservedNames`, built for this and simply never wired into this loop
([`branch-document-path.tests.ps1`](../scripts/tests/branch-document-path.tests.ps1) already covers the
property itself).

**Two real, measured false positives, not a hypothetical one.** Found while testing #1493's CI fold
workflow (which runs fold-all mode on every push to `main`): `CHANGELOG.md`'s own newest
`### DEPLOY: <branch>` heading satisfied the widest branch-declaration pattern (built for a genuine
single-branch dossier, never asked whether a document holding *many* such headings might be handed to
it too), so the whole file read as one unfolded entry and every one of its already-folded `Score:`
pairs came back as "the same tier declared twice." Separately, `dkj-policy/README.md`'s own title
carries a backtick-quoted term with a slash in it -- exactly the shape that same pattern is built to
recognise -- and fold-all mode folded it and **deleted** the real file, splicing its title into
`CHANGELOG.md` as a folded entry. Reproduced directly against this repo's live tree; uncommitted and
caught before it reached `origin`, but the workflow in #1493 runs with `-Push`, so this would not have
failed loudly in CI -- it would have succeeded, silently.

**Score:** 5

#### What makes this deploy extra special

`fold-changelog-entry.ps1` is a shared script, mirrored to every consumer running the `dkj-policy`
plugin -- and every one of them has the identical `dkj-policy/` layout (CHANGELOG.md, CONTRIBUTING.md
and per-branch dossiers, all co-located) that makes fold-all mode reachable this way. Any consumer
whose fold ever runs without `-Branch` -- today that is only a hand-run "catch up the backlog" fold,
but #1493 is adding an automated one -- carries the identical risk until this update reaches them.

**Score:** 4

#### Pull Request

fold-all mode no longer mistakes CHANGELOG.md/README.md for a dossier

Resolves #1497

