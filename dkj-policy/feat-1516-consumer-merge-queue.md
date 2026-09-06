## feat/1516-consumer-merge-queue

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

Make the merge queue GitHub setting consumer-broad: scaffold the fold runner, report queue readiness, and state the policy in the portable page.

#### What the queue actually took away, and why "flip the setting everywhere" is not the feature

The queue went live on `main-ci-gate` (#1492) and took THREE things away from the shipping session,
each of which got its own runner in the source repo and NONE of which a consumer has:

1. **the merge** -- the queue does it, minutes later, on a `gh-readonly-queue/**` branch (#1506);
2. **the fold** -- `fold-on-merge.yml` (#1493, #1507), pushing as `FOLD_PUSH_TOKEN`;
3. **the resolves verification** -- `verify-resolved.yml` (#1511), holding `issues: write`.

And one prerequisite has to be true BEFORE the switch is flipped: every workflow carrying a
**required** check context must trigger on `merge_group`, or the check never reports for a queue
entry and the merge fails outright -- a total merge outage, not a degradation (#1325).

So a consumer who switches the setting on today, with the plugin installed and nothing else, gets:
an outage if their required check has no `merge_group` trigger, silently unfolded entries on their
trunk from then on, and unverified issue closures. **The setting is not the portable half. The floor
under it is.**

#### The three parts

- **A floor a consumer can adopt** -- `adopt-merge-queue.ps1`: reports where this repo stands
  against all four points above, places the two runners on `-Apply`, and prints the paste-ready
  ruleset command WITHOUT running it (repo settings are the owner's act, never a script's).
- **An enforcement point that costs nothing** -- `ship-pr`'s enqueue arm already knows a queue is
  active, off the payload step 0b fetched. Today it promises `fold-on-merge.yml` unconditionally,
  which in a consumer without one is a lie told at the exact moment the entry is stranded.
- **The policy, stated where it travels** -- `CONTRIBUTING-portable.md` step 5 has no queue arm at
  all: it says "merge and fold in one motion", which is what ship-pr no longer does under a queue.

#### Deliberately NOT in this branch

- **Flipping the setting in any consumer.** It is a repo-settings change in five other repos, and
  every one of them is Dave's -- see the constitution. The script prints the command and stops.
- **A sixth SessionStart hook.** The answer changes about once per repo lifetime and reading it
  costs a network round trip at every session start in every consumer. The adoption command and the
  free ship-pr check are the two places the answer is actually needed.
- **A new always-on skill description.** The adoption becomes Part 3 of `adopt-dkj-policy`, which
  already carries two, rather than a fourth skill every session pays the description of.

### CREATE

- [x] `scripts/task/adopt-merge-queue.ps1` -- the queue floor: report the four points, place the two runners on `-Apply`, print the ruleset command
- [x] Register the pair in `scripts/lib/shared-scripts-lib.ps1` and build the mirror
- [x] `ship-pr.ps1`: the enqueue arm promises `fold-on-merge.yml` only where this repo actually has one
- [x] `CONTRIBUTING-portable.md`: step 5 gains the queue arm and states the policy
- [x] `adopt-dkj-policy/SKILL.md`: Part 3

#### One thing the plan did not know: `verify-pushed-merges.ps1` was not shared

It landed hours before this branch opened (#1511) and was never registered in
`Get-SharedScriptPairs`, so it existed only in this tree. A consumer's scaffolded
`verify-resolved.yml` calls it out of the plugin tree, so without that registration the runner this
command places points at a path no consumer has -- and fails on a push to the trunk, after a merge has
already landed, which is the quietest place in the whole cycle to fail. Registered here, and pinned by
an assert in `merge-queue-prereq.tests.ps1` rather than left to be noticed.

#### And a drift risk this branch creates, named rather than gated

`adopt-merge-queue.ps1` carries **derived copies** of both runners, and nothing holds them against the
originals in `.github/workflows/`. A byte comparison would be wrong -- the two genuinely differ, in the
script paths and in `CLAUDE_PROJECT_DIR` -- and a property gate would be a third statement of the same
rules. So the suite pins the properties that break a consumer *silently* (the plugin paths, the
`CLAUDE_PROJECT_DIR`, the credential split in both directions), and
[Sylvester's lens](../.claude/specialists/lenses/05-15-extension.md) now says out loud, on the bullet
for each runner, that changing one means reading the scaffold in the same movement.

### TEST

- [x] `scripts/tests/adopt-merge-queue.tests.ps1` -- new suite, 41 asserts: the dry-run contract, both
      runners placed and reaching the **plugin** tree rather than an in-repo path, `CLAUDE_PROJECT_DIR`
      in both, the credential split asserted in both directions, additive re-run, the two vocabularies
      and the exit code (a gap on a queueless trunk exits 0; the same gap under a live queue exits 1),
      an unreadable payload treated as neither, `merge_group` read as a **key** against a fixture whose
      comment names the trigger in prose, the trunk seam followed into the placed files, no gh call in
      the script carrying a write method or addressing the rulesets endpoint, and the source repo
      refused with nothing written.
- [x] `scripts/tests/merge-queue-prereq.tests.ps1` -- a fifth section for the half that travels: the
      enqueue arm tests for the fold runner before promising it, and both scripts a consumer's own
      runners call are registered mirrors.
- [x] Full gate green: `check-plugin-integrity.ps1` 0 errors, all **72** suites passed in 135s.
- [x] `check-script-contract.ps1` -- 0 errors (the one `Get-ReleasePageMasthead` INFO is pre-existing
      and unrelated).
- [x] Verified by hand against a scratch consumer fixture before the suite existed: the queue-active
      arm, the queue-off arm, and `-Apply` writing both runners.

### DEPLOY: feat/1516-consumer-merge-queue

The merge queue became this workflow's policy for every repo that runs it, and the only thing that
travelled was the half `ship-pr` already carried. `adopt-merge-queue.ps1` is the rest: Part 3 of
`adopt-dkj-policy`, it reads a repo's trunk rules and its workflow files, reports whether that repo
would survive a queue, places the two CI runners a queue takes away from the shipping session -- the
fold (#1493) and the resolves verification (#1511) -- and prints the ruleset command **without running
it**. `verify-pushed-merges.ps1`, which the second of those runners calls, was registered as a shared
mirror in the same movement; it had none, so the runner would have pointed at a path no consumer has.
And `ship-pr`'s enqueue arm now checks for a fold runner before promising one.

**Score:** 3

#### What makes this deploy extra special

**The order is the feature, and getting it wrong is an outage rather than a gap.** A merge queue is
not a setting you switch on and then tidy up after: without a `merge_group` trigger on the workflow
carrying your required check, that check never runs for a queue entry, never reports, and **every merge
fails**. So the command reports the prerequisite first, the runners second, and the switch last -- and
it refuses to pull the switch at all. A ruleset changes what every contributor's merge does,
immediately, for everybody; that is the repo owner's act, and reading a ruleset needs a token that can
read while writing one needs a token that can administer the repo.

**Everything it guards against fails silently, which is why the report has two vocabularies.** A `[gap]`
on a trunk with no queue is a to-do and exits 0 -- your merges are fine today. The identical gap with a
queue **active** exits 1, because entries are already being stranded on your trunk or your merges are
about to stop. Collapsing those two is how an honest report earns being ignored.

**And a plugin install writes nothing into a repo**, which is the fact the whole feature turns on.
Neither runner is plugin payload, so before this a consumer who flipped the setting got: an outage, or a
trunk quietly collecting unfolded changelog entries, with `ship-pr` printing *"fold-on-merge.yml folds
the entry off that push"* at the exact moment nothing was going to.

**Score:** 4

#### Pull Request

The merge-queue policy travels with dkj-policy

