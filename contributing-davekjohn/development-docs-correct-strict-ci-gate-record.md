## Development: `docs/correct-strict-ci-gate-record` · 20260903-193037

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

Corrective, doc-only branch. PR #1333 (2026-09-03, also Sylvester's) shipped a record saying
option 1 of [#1325](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1325) --
`strict_required_status_checks_policy` on `main-ci-gate` plus repo `allow_auto_merge` and
`allow_update_branch` -- was "the resolution". About 45 minutes later, on Dave's explicit
instruction and after research on #1325 disproved option 1, all three fields were reverted to
`false`. This branch corrects the two now-wrong paragraphs #1333 added. No GitHub settings are
touched here -- they are already back to `false` (verified in TEST).

### CREATE

- [x] `.claude/specialists/lenses/05-15-extension.md` -- replace the `strict`-turned-on paragraph on
  the `ci.yml` / `main-ci-gate` bullet with one recording: the three fields on (~15:10 UTC) and
  reverted the same day (~15:55), the load-bearing reason it does not converge (GitHub does no
  server-side base-sync of a PR branch outside a merge queue; `allow_update_branch` is only a UI
  button; auto-merge never syncs the base), the live confirmation (PR #1316 needed
  `gh pr merge --admin` while `strict` was briefly on), why `allow_auto_merge` was reverted too
  (strict-off + auto-merge would merge on a stale-but-green certificate -- #1292's defect), and the
  real fix (a merge queue -- available here, gated on a `merge_group` trigger landing in `ci.yml`
  first, open on #1325). Keeps the generalisable lesson: a repo-settings "fix" for the staleness
  race that is not a merge queue does not converge.
- [x] `.claude/rules/language-layers.md` -- in the closing verification-lesson paragraph, correct
  the two clauses that read `strict` as left on: it was switched on and back off the same day
  (~45 min round trip). The paragraph's language point (`lint-en-tests` is the un-renameable live
  name of an external object) is untouched.

### TEST

No suite applies -- both edits are prose. Verification is a GitHub settings readback proving the
three fields PR #1333 recorded are back to `false`:

    $ gh api repos/DKJ-Solutions/claude-code-specialists/rulesets/19008062 --jq '.rules[] | select(.type=="required_status_checks") | .parameters.strict_required_status_checks_policy'
    false

    $ gh api repos/DKJ-Solutions/claude-code-specialists --jq '{allow_auto_merge, allow_update_branch}'
    {"allow_auto_merge":false,"allow_update_branch":false}

Both corrected paragraphs now match that state. Ruleset id `19008062` is `main-ci-gate`.

### DEPLOY: `docs/correct-strict-ci-gate-record`

Two paragraphs added by PR #1333 are corrected to record that option 1 of
[#1325](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1325) --
`strict_required_status_checks_policy` on `main-ci-gate` plus repo `allow_auto_merge` and
`allow_update_branch` -- was applied on 2026-09-03 and reverted the same day, after about 45
minutes, once research on #1325 disproved it. All three fields are back to `false`.

`.claude/specialists/lenses/05-15-extension.md` (the `main-ci-gate` / `ci.yml` bullet) now records
why the combination does not converge: GitHub performs no server-side base-sync of a PR branch
outside a merge queue, `allow_update_branch` only renders a UI button for a human with write
access, and auto-merge flips the merge switch only once "up to date" is already satisfied -- so
`strict` turns the ~44% behind-at-merge rate into a hard, repeating, server-side block with no
automatic resolution and no valve (`-SkipStaleCheck` cannot touch a refusal that is now GitHub's).
Confirmed live: PR #1316 had to be landed with `gh pr merge --admin` while `strict` was briefly on.
`allow_auto_merge` was reverted too because strict-off with auto-merge on is not a fallback -- it
would merge on a stale-but-green certificate, reintroducing exactly
[#1292](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1292)'s defect. The real
fix recorded there is a GitHub merge queue -- available to this repo, gated on a `merge_group`
trigger landing in `.github/workflows/ci.yml` first (a required workflow without it never reports
in the queue, and the merge then fails outright). #1292 (the red-trunk mechanism issue) stays open
and assigned in its own right; the keep-`strict`-or-adopt-a-merge-queue decision now sits on #1325
and is Dave's call. `ship-pr.ps1` step 3b is unchanged: its detection is correct and it stays the
mechanism and the portable net for consumers.

`.claude/rules/language-layers.md`'s closing verification-lesson paragraph is corrected in the same
direction: `strict` was switched on and back off the same day, a round trip, not left on. The
paragraph's language point -- the job id `lint-en-tests` is the live name of an external object this
repo may cite but not unilaterally rename -- is untouched.

The generalisable lesson kept in both files: a repo-settings "fix" for the staleness race that is
not a merge queue does not converge -- the base never moves under the PR on its own, so `strict` +
`allow_auto_merge` + `allow_update_branch` add only the block.

This branch changes documentation only; the settings were reverted out-of-band and are already
`false`, so nothing a maintainer runs changes. What the correction buys is that the next session
reading the `main-ci-gate` bullet finds the true #1325 outcome -- option 1 tried and rejected, with
the #1292 mechanism issue and PR #1316's gate both intact and the merge-queue prerequisite
recorded -- instead of a record that would have it believe option 1 is in force and converging, and
possibly re-derive or re-propose it.

**Score:** 2

#### What makes this deploy extra special

Reaches no consumer. The reverted settings were this repo's own GitHub ruleset and merge
configuration; no plugin, script, or adopted page changes. The portable consumer-side mechanism --
`ship-pr.ps1` step 3b -- is explicitly unchanged, and no release note ever told consumers to adopt
the settings this corrects.

**Score:** N/A

#### Pull Request

Correct the strict-CI record: option 1 was tried and reverted

