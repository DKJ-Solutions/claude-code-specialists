## Development: `docs/record-strict-ci-gate` · 20260903-171346

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

#### Status

Docs-only branch. It records a repo-settings change -- `main-ci-gate` `strict` turned on; repo
`allow_auto_merge` and `allow_update_branch` turned on -- that was made and verified out-of-band on
2026-09-03 under issue #1325 (now closed). Nothing in this branch touches GitHub settings.

### CREATE

- [x] Record the change in `.claude/specialists/lenses/05-15-extension.md`, in the `main-ci-gate` /
  `ci.yml` bullet, immediately after the #1239 "check the field you actually rely on" paragraph.
- [x] Date the closing "verification lesson" paragraph in `.claude/rules/language-layers.md` for the
  same change: note that `strict_required_status_checks_policy` on `main-ci-gate` went `false` to
  `true` on 2026-09-03, a third change to that ruleset beyond the transfer and the bypass refill, so
  a reader treating that paragraph as a full field-by-field inventory is one field short.
- [~] The GitHub settings change itself is not a step of this branch: the three `gh api` PUTs
  (`strict_required_status_checks_policy` on ruleset `main-ci-gate`; `allow_auto_merge` and
  `allow_update_branch` on `DKJ-Solutions/claude-code-specialists`) were applied and verified
  out-of-band on 2026-09-03, before this branch existed. This branch is docs-only.

### TEST

- [x] Verified the three fields at their new values by `gh api` readback (2026-09-03):
  `gh api repos/DKJ-Solutions/claude-code-specialists/rulesets/19008062` shows the
  `required_status_checks` rule carrying `"strict_required_status_checks_policy": true` -- ruleset
  still `active`, target `~DEFAULT_BRANCH`, rules `deletion` + `non_fast_forward` +
  `required_status_checks` on `lint-en-tests` only, `bypass_actors` still
  `[{OrganizationAdmin, always}, {RepositoryRole 5, always}]`;
  `gh api repos/DKJ-Solutions/claude-code-specialists --jq '{allow_auto_merge, allow_update_branch}'`
  returns both `true`.
- [~] No automated suite: a lens edit has none, and `scripts/tests/*.tests.ps1` exercise the
  scripts, libs and manifests this branch does not touch. CI (`lint-en-tests`) still runs the full
  lint gate and every suite on the PR.

### DEPLOY: `docs/record-strict-ci-gate`

`main-ci-gate` now enforces `strict_required_status_checks_policy`, and
`DKJ-Solutions/claude-code-specialists` now allows auto-merge and branch auto-update. The three
fields were changed by `gh api` out-of-band on 2026-09-03 (Dave's call on
[#1325](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1325)); this branch is the
docs record of that change.

- ruleset `main-ci-gate`, `required_status_checks` rule: `strict_required_status_checks_policy`
  `false` to `true`
- repo `DKJ-Solutions/claude-code-specialists`: `allow_auto_merge` and `allow_update_branch` both
  `false` to `true`

With `strict` on, a PR must be up to date with `main` before it can merge; `allow_auto_merge` and
`allow_update_branch` let GitHub run the convergence loop unattended -- update the behind branch,
re-run `lint-en-tests` against the fresh tree, merge when green -- so the operator arms auto-merge
once instead of standing between CI rounds. The cost is a full extra `lint-en-tests` run for every
branch that falls behind `main` while its own CI runs. `ship-pr.ps1`'s step-3b stale-CI certificate
gate (PR #1316) is unchanged: its detection is correct and it remains the portable safety net for
consumers, whom a repo-settings change does not reach; `-SkipStaleCheck` stays the valve for a
known-harmless window. This enacts option 1 of
[#1292](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1292) ("require branches to
be up to date") for this repo; #1292 stays open as the broader merge-queue question. Recorded in
`.claude/specialists/lenses/05-15-extension.md` (the `main-ci-gate` / `ci.yml` bullet) and in
`.claude/rules/language-layers.md` (the closing verification-lesson paragraph, which now notes this
as the third change to that ruleset in two days).

This branch ships only documentation; the settings change was applied and verified out-of-band and
is already in force, so a maintainer feels the new merge behaviour regardless of this entry. What
the entry buys is that the next session reading the `main-ci-gate` / `ci.yml` bullet finds the
convergence-race resolution -- and the reason step 3b was deliberately left alone -- recorded with
its #1325 / #1292 / #1316 chain intact, rather than re-deriving it or re-proposing the script-side
fix the #1325 verdict rejected.

**Score:** 2

#### What makes this deploy extra special

A change to this repo's own GitHub ruleset and merge settings reaches no consumer: it ships no
plugin change, no script change, and no page a consumer adopts. The portable consumer-side
mechanism -- `ship-pr.ps1` step 3b -- is explicitly unchanged, and no earlier release note told
consumers to adopt anything this retires.

**Score:** N/A

#### Pull Request

Record strict CI checks + auto-merge on main-ci-gate

