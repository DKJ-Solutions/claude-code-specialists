## feat/consumer-readme-update-topup

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

The source repo's own `dkj-policy/README.md` gained an UPDATE section in #1567. A consumer's copy of
that page is **scaffolded** by `adopt-workflow-folder.ps1`, which is strictly create-when-absent — so
that section would reach a repo that already adopted the folder **not at all**. That is the "right owner,
wrong reach" shape the script's own header already records for `CLAUDE.md` (PR #734), and this branch is
the first time it was worth closing rather than noting: the section is the one page in the folder whose
*content goes stale on the consumer's side* — it names commands and a failure mode, not this repo's
answers.

#### The shape, and why it is not a policy change

`adopt-dkj-policy` Part 1 promises a re-run finds nothing to do, and that promise is kept. The section
carries a marker comment, the run recognises it, and the append happens only when it is absent. Nothing
is read back beyond the marker test, nothing is merged, and the file the loop reports as `[exists]` is
still left as it is — both halves hold at once, which is what keeps this an append rather than a rewrite
in disguise. Same rule the note-root seam answer has appended under since #1150.

#### What the section says, and where its ids come from

The consumer's version is not a copy of the source repo's. It reads the enabled plugin ids out of that
repo's own settings chain (`Get-EnabledPlugins`, `RepoEnabledIds` — an enable arriving from the machine
layer is not theirs to document) and prints one `claude plugin update <id> --scope project` line per
plugin, under the refresh. Where the lib or the ids are unavailable it prints the shape instead: a page
with a placeholder is honest, a page with a wrong id is worse than no page.

### CREATE

- [x] `scripts/task/adopt-workflow-folder.ps1`: build the UPDATE section (with its marker), append it to
      the scaffolded `$folderReadme`, and add the section-level top-up for a README that already exists.
      Guarded dot-source of `check-report-lib.ps1` for the ids, the idiom this script already uses.
- [x] Narrow the header's "STRICTLY ADDITIVE, NEVER OVERWRITES" claim with the one bounded exception,
      and say in the folder listing that the README now carries the update procedure.
- [x] Count the top-up separately from `$created` in the closing summary — it is a different act.
- [x] `plugins/dkj-policy/skills/adopt-dkj-policy/SKILL.md`: the same bound, under Part 1's rules, plus
      the one-line correction to "never overwrite a file that already exists". The **frontmatter
      description is deliberately untouched**: it says "strictly additive" and "none overwrites
      anything", both of which an append satisfies, and that line is always-on in every session.
- [x] `scripts/tests/adopt-workflow-folder.tests.ps1`: the four branches — placed fresh, left alone on a
      re-run, appended to an already-adopted page whose own writing survives byte for byte, and the dry
      run that reports it and writes nothing. Plus the order assert: the refresh is printed before the
      update, the doc defect the lint gate refuses.
- [x] Mirror via `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] `adopt-workflow-folder.tests.ps1` in the lane: 79 asserts pass, 18 of them new.
- [x] `check-plugin-integrity.ps1` + every suite, via `open-pr.ps1`.

### DEPLOY: feat/consumer-readme-update-topup

A consumer's `dkj-policy/README.md` now **gets** the UPDATE section, and gets it even if their folder was
scaffolded before the section existed. `adopt-dkj-policy` Part 1 places it on a fresh adoption and
**appends** it to a page that has none, recognised by a marker comment
(`<!-- dkj-policy:update-section -->`) — the one write this command makes into a file it did not create,
bounded to a single append at the end of a single file, in whichever folder `Get-WorkflowFolderName` says
that repo actually has. A page that already carries it is left untouched and reported as such, so a
re-run still finds nothing to do.

The section itself names that repo's **own** plugin ids, read from its settings chain, one
`claude plugin update <id> --scope project` line per enabled plugin under the marketplace refresh — with
the command's shape as the fallback, because a placeholder is honest and a wrong id is not. It carries
why both halves of the pair matter, that the marketplace clone and the install record are per-checkout
state no session reports, and the seam answer a newer version of the shared scripts can start asking for.

This closes the reach half of #1567: without it, the section landed in the source repo and in no consumer.

**Score:** 4

#### What makes this deploy extra special

Three consumers are registered against this source today, and every one of them adopted its folder
before this section existed — so this is the difference between the section existing and the section
arriving. It is also the first time this scaffold can deliver a *later* improvement to a page it already
placed, which is a shape the folder's other documents will want as well.

**Score:** 3

#### Pull Request

Let the adoption scaffold place -- and top up -- the UPDATE section in a consumer's folder README
