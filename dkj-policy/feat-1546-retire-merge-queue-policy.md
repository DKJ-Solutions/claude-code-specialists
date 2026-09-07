## feat/1546-retire-merge-queue-policy

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

Dave chose detect-and-rebase (option A) on 2026-09-07. Verified: DKJ-Solutions is plan 'free' and this repo is public, so it is eligible only via the public-repos clause; BWJ-Development is plan 'team', so a private repo there cannot run a queue at all. The queue stays SUPPORTED where a repo has one -- ship-pr's enqueue path and the two runners stay -- it just stops being prescribed. The ruleset flip on this repo's main is Dave's own act and is NOT in this branch.

#### Why this closes all three of the merge-queue issues, not only #1546

They were one question. #1546 sets the direction (the plugin must work everywhere, so find another
path); #1540 is the measurement that a private consumer cannot reach the setting at all and that
`adopt-merge-queue` reported it as a closable `[gap]`; #1538 is the trap one level down -- the command
tells you to make a CI check required, and the only workflow the plugin ships cannot be one. Repairing
#1538 or #1540 while the queue was still policy would have polished an instruction the direction was
about to retire, which is why they were held until the direction was settled.

#### The eligibility facts, re-measured here rather than inherited from the report

| | source repo | the private consumer |
|---|---|---|
| visibility | `public` | `private` |
| org plan | `DKJ-Solutions` = `free` | `BWJ-Development` = `team` |
| eligible | yes -- through the **public repos owned by orgs** clause | no -- private needs Enterprise Cloud |

`BWJ-ecommerce`'s plan is **not readable from this checkout** (the token carries no scope for it), so
it is unmeasured rather than clear.

**What that says about the old policy is the part worth keeping**: it was set in the one repo whose own
answer could not reveal the constraint. A capability that is *present* announces nothing about why, so
"it is available to this repo" generalised into "every repo running this workflow adopts one", and the
consumer met the gap as a missing checkbox after building the whole floor beneath it.

### CREATE

- [x] `CONTRIBUTING-portable.md`: the staleness race gets its own section naming **detect-and-rebase**
      as the answer; the queue keeps a subsection saying it is supported, not prescribed, with the
      entitlement quoted. The three-things list is re-cut so items 1 and 2 are **every repo's** and only
      item 3 (the `merge_group` trigger) belongs to a queue.
- [x] `adopt-merge-queue.ps1` (+ its plugin mirror, via `build-shared-scripts.ps1`): the missing queue
      is a `[note]` reading "the ordinary state, not a gap" instead of a `[gap]`; the required-check gap
      keeps its place with the **new reason** (the staleness guard is off without a certificate to date)
      and now names why `branch-entry` cannot carry the role. Section headings re-cut along the same
      seam.
- [x] `adopt-dkj-policy/SKILL.md`: Part 3 is "the CI floor" rather than "the merge-queue floor" --
      frontmatter description, part summary and page heading included, since a consumer reads the
      description before anything else.
- [x] `CLAUDE.md`: this repo's own statement, written so it is true **today** -- the queue is still live
      on `main-ci-gate` and taking it off is Dave's ruleset act, so the text says the policy has changed
      and that the queue is live until he makes that change.
- [x] Sylvester's lens: the "the earlier Enterprise-only reading was wrong" correction is kept and
      **bounded** -- it was right about this repo and wrong as a rule, which is the distinction that
      cost the policy.

### TEST

- [x] `adopt-merge-queue.tests.ps1`: **41 asserts before, 52 after** -- 11 added, 0 removed, counted
      off the diff rather than estimated. In two groups -- a trunk with no queue is a `[note]` and never a `[gap]`, says
      "ordinary state", names Enterprise Cloud and detect-and-rebase, and still exits 0; and a trunk with
      **nothing required** is still a gap, for the staleness-guard reason, naming `branch-entry` and
      `github.head_ref`.
- [x] A new rules fixture, `$RulesQueueOffNoChecks` -- no queue and no required check, the shape that
      leaves the guard with no certificate to date. That combination had no fixture before.
- [x] One real regression caught by the suite rather than by review: rewording split "Require merge
      queue" across two console lines, so the phrase naming the setting no longer appeared whole. Put
      back on one line -- a reader who cannot search for the rule name cannot find it either.
- [x] Lint gate green: 0 errors.
- [x] The shared-script mirror re-synced, so `scripts/` and `plugins/dkj-policy/scripts/` stay
      byte-identical.

#### What is deliberately NOT in this branch

**Taking the `merge_queue` rule off `main-ci-gate`.** A ruleset changes what every contributor's merge
does, immediately, for everybody -- the constitution puts that class in Dave's hands, and no script here
may make it. Nothing in this branch depends on which way it goes: the two runners stay either way, and
`ship-pr` already handles both a queued and an unqueued trunk.

### DEPLOY: feat/1546-retire-merge-queue-policy

A GitHub merge queue is no longer this workflow's policy. **Detect-and-rebase is** -- `ship-pr` dates the
run behind your required check, counts what the trunk gained after it, and refuses the merge when that is
not zero, naming the commits and the way forward. It converges by repetition rather than by construction,
and unlike a queue it runs anywhere.

**The queue was prescribed to readers who are not allowed to have one.** GitHub offers merge queue on a
private repo only under Enterprise Cloud, and otherwise only on a public repo owned by an organization;
on Free, Pro or Team it hides the *Require merge queue* checkbox rather than disabling it. The policy was
set in this workflow's source repo, which is public and therefore qualifies through the public clause --
the one repo where the constraint cannot be felt. A private consumer built the entire floor beneath the
setting before the missing checkbox surfaced.

**So `adopt-merge-queue` no longer reports a missing queue as a gap.** It is a note saying this is the
ordinary state. The gap that survives is the one every repo can close and should: **a required status
check**, because that is the certificate the staleness guard dates itself from, and without one `ship-pr`
says so and skips the step. The command now also names the trap under that instruction -- the
`branch-entry` gate this plugin ships **cannot** be that check, since it reads `github.head_ref`, which is
empty outside a pull request.

**And the two CI runners are every repo's, queue or no queue.** What breaks the fold is a merge the
shipping session does not observe, and the GitHub UI merge button produces one in every repository on
earth; a queue only made it the normal case. Only the `merge_group` trigger is queue-only, and in a repo
without one it is inert.

Where a repo does run a queue nothing is taken away: `ship-pr` still enqueues, and both runners still
catch what that merge skips.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo's audience is its own developers and the consuming repos, and neither is a subscriber of
a service. The consumers do get the substance at the next release: an instruction they could not follow
becomes one they can, and the `[gap]` they could never close stops being reported as one.

**Score:** N/A

#### Pull Request

Retire the merge queue as policy -- detect-and-rebase is the mechanism every repo can run

