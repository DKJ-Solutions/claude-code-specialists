## Development: `fix/ship-pr-fold-push-bypass-preflight-v1` · 20260903-104449

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

Read the trunk ruleset at step 0: if a rule that a direct push cannot satisfy applies to main and this account has no bypass, refuse before anything is merged rather than merging and leaving the trunk half-done (issue #1278).

#### What the report claimed, and what it actually is

Two of #1278's claims were checked against the API before anything was built, and one does not stand:

- **Does not stand.** *"`main-ci-gate` carries no `bypass_actors` at all."* Read from an admin token at
  the same `updated_at` the issue cites (2026-09-03T09:35:39+02:00, unchanged since), it carries two:
  `OrganizationAdmin` and repo role 5, both `always`. The report was written from a non-admin token,
  which is not shown that field -- so the absence was a visibility artefact of the reader, not the
  config. Nothing in the repair depended on it.
- **Stands, and is the whole defect.** `maikel-bwj` is neither of those two actors, so its
  `current_user_can_bypass` really is `never`, and the GH013 rejection on the fold of PR #1271 is a
  measurement rather than an inference. That is what the guard is built on.

The issue's second correction stands too: #1266 and #1270 attributed the unfolded merges of
September 2 to a GitHub-UI merge path, explicitly marked as inferred. For #1261 the verified
explanation is this one instead -- `ship-pr` reached the fold and the *push* was refused.

#### And the leftover state, cleared first

PR #1271's entry was still unfolded on the trunk. Folded from this account (which has bypass) before
the branch was cut, so the trunk was clean under the work: `b508cfd5`.

### CREATE

- [x] `Get-DirectPushBlockingRules` in `scripts/lib/pr-issues-lib.ps1` -- which rulesets on the trunk
      carry a rule a direct push cannot satisfy, read from `rules/branches/<trunk>`
- [x] `Get-FoldPushVerdict` beside it -- the verdict from those rules plus this account's bypass per
      ruleset; `Blocked` / `Unknown` / `Reason` / `BlockedBy`
- [x] Step 0b in `scripts/release/ship-pr.ps1`, after the worktree check and before step 1: two `gh`
      reads, the refusal naming the ruleset, the check and the account, and both remedies it declines
      to take
- [x] Header docstring: 0b listed beside 0 in the step list
- [x] Skill page section on the refusal, beside the #1069 one it is the sibling of
- [x] Mirrored into the plugin via `build-shared-scripts.ps1` -- both copies byte-identical

### TEST

- [x] `pr-issues.tests.ps1`: 22 asserts on the two functions plus the ship-pr call site, over a fixture
      transcribed from the live payload rather than invented
- [x] Both directions pinned: an account with `never` is refused, an account with `always` ships
      unchanged -- the second matters more, since this repo's owner ships through that ruleset daily
- [x] Proved the guards fire: treating every bypass value as `always` -> 6 failed / 503 passed;
      removing the ship-pr call site -> 2 failed / 507 passed
- [x] `pr-issues` 509, `shared-scripts` 476, `script-contract` 293, `check-plugin-integrity-docs` 95,
      `bootstrap-drift` 205 -- all green; lint gate 0 errors

### DEPLOY: `fix/ship-pr-fold-push-bypass-preflight-v1`

`ship-pr` now asks, before it opens anything, whether the account running it will be allowed to push
the fold -- and refuses when it will not, instead of merging and leaving the trunk merged-but-unfolded.

The fold is a direct push by design, one of the three named exceptions to "never commit directly on the
trunk", and a required status check cannot be satisfied by a direct push: the pushed commit carries no
checks, so the ref update is refused before any workflow could run. An account can therefore be fully
entitled to *merge* -- the PR's own check ran and passed -- and not entitled to *fold*. Measured on
PR #1271: merged, checked out the trunk, folded, committed, `GH013 ... Required status check
"lint-en-tests" is expected`. Not once, but on every run from that account, because the cause sits in
the ruleset rather than in the run.

Step 0b answers it for two `gh` reads. `rules/branches/<trunk>` gives the rules and deliberately does
**not** filter by bypass -- measured: it returns `required_status_checks` to an account whose
`current_user_can_bypass` is `always` -- so the ruleset detail is read for the second half, from the org
endpoint when the ruleset is the org's. Three rule types block a fold, each by its own definition:
`required_status_checks`, `pull_request` (so `pull_requests_only` bypass is not bypass here) and
`update`. `deletion`, `non_fast_forward`, `required_linear_history` and `required_signatures` do not.

It sits where the worktree check sits, and for that check's reason: nothing is gated, pushed, opened or
merged yet, so refusing is free. The local check still runs first, so a network read never costs the one
that needs no network. An unreadable ruleset warns rather than refusing -- the opposite posture to the
merge verdict at step 3, because there an unread required-check list could put red code on the trunk,
while here the thing at risk is a fold that can be redone from an account with bypass. And it takes
neither remedy: it names them (grant the account bypass, or ship from an account that has it) and stops.

**Score:** 4

#### What makes this deploy extra special

It closes the second route into the one state this workflow has no detector for. `ship-pr` already
refused, at exactly this point, when step 5 would not be able to *check out* the trunk (#1069); it now
refuses when step 5 would not be able to *push* to it. Same step, same reasoning, same sentence -- and
the failure it prevents is not a risk that might occur but one that fired on every run from one of the
two accounts that ship this repo.

**Score:** 3

#### Pull Request

ship-pr refuses before the merge when it cannot push the fold
