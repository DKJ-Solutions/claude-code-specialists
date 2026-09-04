## fix/duplicate-entry-section-heading

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

Issue #1367. The reported cause -- "open-pr's PR-link writer appended a second `#### Pull Request`
section" -- did not survive verification. Git history for `docs/language-layers-bypass-restored-v1`
shows the second heading was hand-authored in commit `1af31be4`, an ordinary `docs:` work commit that
touched only `.claude/rules/language-layers.md` and the branch document; `open-pr.ps1` writes no
`[PR #NN]` link into the branch document at all -- the fold does, afterward. So the root cause is a
hand-editing slip while writing the DEPLOY section, and the gap is that `check-plugin-integrity.ps1`
check 13 (`[entry-heading]`) validates that each `####` heading IS a declared section but never that a
declared section appears only ONCE. Downstream, the fold stamps/links the LAST `Pull Request` heading
while `Get-PrDescription` and the release renderer read the FIRST, so the v4.29.0 Release body took the
copy with no PR link -- silent in both directions, the same shape as #1268 and #952.

Fix: extend check 13 to flag a declared section heading repeated within one entry, in both passes it
already walks (the branch document / root entry files, and `CHANGELOG.md` below its intro).

### CREATE

- [x] `check-plugin-integrity.ps1` check 13, branch-document/entry-file pass: track declared section
  headings per entry (stamp-stripped name), raise `[entry-heading]` on the second occurrence.
- [x] Same check, `CHANGELOG.md` pass: per-entry (`$from..$to`) duplicate detection, so a copy that
  arrives through the fold is caught on the one write that lands directly on `main`.
- [~] Touch `open-pr.ps1` / the fold -- dropped: the reported cause is disproven, no script doubles the
  section. The gate is the repair.

### TEST

- [x] `scripts/tests/check-plugin-integrity-entries.tests.ps1` scenario 34, three new cases: a doubled
  declared section in an entry file (reported on the second occurrence, names the section and #1367), a
  doubled section folded into `CHANGELOG.md`, and two negatives -- a duplicate quoted inside a fence,
  and the same section name in two different entries.
- [x] Full `check-plugin-integrity.ps1` green on the real tree (0 errors); the three sibling entry
  suites green; entries suite 78 -> 85 asserts.
- [x] Lint + tests green, then PR + merge + fold.

### DEPLOY: fix/duplicate-entry-section-heading

`check-plugin-integrity.ps1`'s entry-heading check (check 13) now refuses a changelog entry whose
declared section heading appears more than once -- `#### Pull Request` written twice, say. Both copies
are valid names, so nothing errored before: the entry validated, every gate passed, and the split only
showed in a published GitHub Release body, because the fold stamps and links the last `Pull Request`
heading while the PR body and the release notes read the first. `v4.29.0`'s Release body shipped a
bullet with no PR link that way (issue #1367). The check catches it in both places it already
walks -- the branch's development document (on the PR, and in CI) and `CHANGELOG.md` below its intro
(after a fold, the one write that lands directly on `main`) -- and a heading quoted inside a code fence
is a mention, not a finding.

**Score:** 2

#### What makes this deploy extra special

N/A -- an internal lint gate. No subscriber of any service reaches it; the entry files and `CHANGELOG.md`
it guards are developer-facing.

**Score:** N/A

#### Pull Request

refuse an entry whose section heading appears more than once

