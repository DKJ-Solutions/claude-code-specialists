## docs/1499-fold-on-merge-ruleset-diagnosis

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

#### What #1499 actually turned out to be

Filed as a live defect in `fold-changelog-entry.ps1`'s fold-all mode surviving #1498's fix. Verified
before repairing, and it does not stand: two of its three cited runs are pre-#1498 commits (the #1497
bug, already repaired), and the third — the merge of #1498 itself, the run the report leans on to prove
the fix did not take — folded cleanly and then failed on the `main-ci-gate` ruleset, which the report
explicitly sets aside as "not this". No code change is needed and none is made.

What IS wrong is the diagnosis a reader reaches for when this job goes red, in three places: the
workflow's own header names one blocking rule where the ruleset now has two, the system-administration
lens's ruleset record is one rule short, and the `triage-inbound` skill has no instance of the shape
that made #1499 convincing.

### CREATE

- [x] `.github/workflows/fold-on-merge.yml`: the INERT UNTIL paragraph names both blocking rules
      (`required_status_checks` **and** `merge_queue`), and a second paragraph carries the verbatim
      rejection from run 34020828593 so a red fold step is no longer read as a fold refusal.
- [x] `.claude/specialists/lenses/05-15-extension.md`: a September 6, 2026 row on `main-ci-gate` — the
      rule list gained `merge_queue`, measured on the same ruleset id, with both `remote:` lines and the
      note that a bypass actor still answers both in one move.
- [x] `.claude/skills/triage-inbound/SKILL.md`: #1499 recorded under the first pattern as the shape that
      survives a check — a report that anticipates "already repaired" and cites a CI run against it,
      where the cited run is a different failure under the same job name. Includes the stale-checkout
      repro that looked like confirmation and was not.
- [~] No change to `fold-changelog-entry.ps1` or its mirror. The reported defect does not exist on
      `main`; repairing to the report would have re-fixed a bug #1498 already closed.

### TEST

Reproduced in both directions in a scratch clone, which is what settled it:

- At `ac0e0246` (the exact commit run 34020828593 checked out) fold-all mode prints
  `Folded and removed: dkj-policy/fix-1497-fold-all-reserved-names.md (tier 2, significance 4 ...)`,
  `CHANGELOG.md updated.`, exit 0 — the same fold the CI log shows above its rejected push.
- At today's tip with a fresh, never-folded dossier seeded into `dkj-policy/`: folded cleanly, exit 0,
  `dkj-policy/CHANGELOG.md` never entered `$entryFiles`.
- The reported error reproduces **only** on a pre-#1498 checkout. The first repro here did reproduce it
  and was measuring a stale local `main`, two commits behind the fix — recorded in the skill, because it
  is the part of this pickup that nearly produced a wrong repair.
- `scripts/tests/fold-changelog.tests.ps1` at the tip: 203 pass, 0 fail, exit 0.

The three cited runs were read from `gh run view --log` rather than from their conclusions, which is the
step that separated the two causes.

### DEPLOY: docs/1499-fold-on-merge-ruleset-diagnosis

A red `fold-on-merge` job now says which of its two unrelated causes fired. The workflow's header named
`required_status_checks` as the one rule blocking its push to `main`; `main-ci-gate` has carried
`merge_queue` alongside it since September 6, 2026, so a rejected push comes back naming two rules and a
reader holding the old note starts hunting for a second cause. Both are named now, with the verbatim
rejection from the run that measured them, plus the fact that matters most for reading a red run: the
fold step failing is not evidence that the *fold* refused — in run 34020828593 the fold succeeded and the
push was rejected underneath it. `.claude/specialists/lenses/05-15-extension.md` gains the same
measurement as a dated row rather than a silent edit, because every other record in that lens names one
rule and was correct when written.

No change to the fold itself. [#1499](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1499)
reported fold-all mode still misreading `CHANGELOG.md` after #1498, on three failed runs read as one
symptom; two of them are pre-#1498 commits and the third folded cleanly before the ruleset refused its
push. Reproduced both ways against the exact commits before concluding it.

**Score:** 3

#### What makes this deploy extra special

N/A — the three files changed are this repo's own workflow, its system-administration lens and a local
skill. None of them ships to a consumer, and the fold scripts that do ship are untouched.

**Score:** N/A

#### Pull Request

the fold-on-merge diagnosis names both blocking rules, and #1499 is measured

Resolves #1499
