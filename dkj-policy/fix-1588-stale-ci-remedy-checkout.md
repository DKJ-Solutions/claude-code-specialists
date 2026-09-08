## fix/1588-stale-ci-remedy-checkout

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

Issue [#1588](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1588): `ship-pr.ps1`'s
stale-CI refusal prints a remedy written as though the branch were still checked out, and the run that
prints it moved the tree to the trunk a whole CI wait earlier (step 2b, #1073). So both printed commands
act on `main`, and neither errors: the merge fast-forwards the trunk with a full diffstat that reads like
the branch moving forward, the push is `Everything up-to-date`, and the first thing to say anything is the
re-run of `ship-pr`, one CI cycle later, reporting `You are on main` -- the wrong problem.

#### Verified before repairing, not after

Six things could have expired; the ones that mattered here:

- **Symptom stands.** Step 2b's `git checkout main` is at `scripts/release/ship-pr.ps1:654`; the stale-CI
  refusal is at `:1360`. Step 3b starts at `:1157`, at script level, so it is genuinely downstream.
- **The proposed repair names a mechanism that exists.** `$branch` is assigned exactly once, at `:357`,
  before step 2b runs, and step 3b is not inside a function -- so the here-string interpolates the branch
  name even though `HEAD` no longer holds it. Confirmed by grep (`\$branch\s*=` -> one hit) and by the
  function/section map.
- **Nothing else in the tree prescribes the remedy.** One grep over every `.md` outside the archived
  release history found no second copy of the command block.

#### And it made a neighbouring claim wrong, which is the reason two docs move too

The portable page and the `adopt-dkj-policy` skill both said the refusal names *"the **two** commands that
bring the branch forward."* It names three now. Repairing the script and leaving that count standing would
publish a contradiction to every consumer, so both lose the count and gain the reason the checkout leads --
a count is what went stale here, and naming the first command cannot go stale on a fourth line.

### CREATE

- [x] `scripts/release/ship-pr.ps1`: `git checkout $branch` as the first line of the stale-CI remedy,
      with the printed sentence saying why it is there, plus the comment block carrying both measured
      instances (PR #1583 / issue #1579, and PR #1316 via #1325) and why the line is unconditional.
- [x] `plugins/dkj-policy/scripts/release/ship-pr.ps1`: mirror regenerated via
      `scripts/sync/build-shared-scripts.ps1` -- not hand-edited.
- [x] `plugins/dkj-policy/CONTRIBUTING-portable.md`: the stale-CI paragraph drops the count and gains a
      paragraph on why the checkout is first, since that page is where a consumer meets this mechanism.
- [x] `plugins/dkj-policy/skills/adopt-dkj-policy/SKILL.md`: the same count, the same repair, one clause.
- [~] Nothing added to `.claude/specialists/lenses/05-15-extension.md`. The reasoning's reader is whoever
      next opens that refusal, and it is in the script beside the string -- this repo's own convention for
      where a measurement lives. The lens is 172 KB and loaded on demand; a second copy there would cost
      every invocation and say nothing the comment does not.
- [~] Nothing changed about the gate's behaviour. The issue scopes it out by name, and having the gate
      perform the update itself is option 3 in #1325 -- a larger decision that is not this branch's.

### TEST

- [x] `scripts/tests/pr-issues.tests.ps1`: three asserts in the stale-certificate block. The order is
      pinned with offset-scoped `IndexOf` reads rather than three presence checks, because the defect was
      the **order** -- `git fetch` and `git merge` were both already present and both wrong on their own,
      so an assert on `git checkout` anywhere in the file would pass on a remedy that printed it last.
- [x] Proved the asserts bite: `git show HEAD:scripts/release/ship-pr.ps1` gives `IndexOf` = -1 for the
      checkout line and `False` for the explanatory sentence, so all three fail on the pre-repair text.
- [x] `scripts/tests/pr-issues.tests.ps1` green -- 682 asserts.
- [x] `scripts/lint/check-plugin-integrity.ps1` green -- 0 errors, shared-script mirror in sync.
- [x] The script parses (`[Parser]::ParseFile` -> no errors), which is what a here-string edit can break
      without any test noticing.

### DEPLOY: fix/1588-stale-ci-remedy-checkout

`ship-pr`'s stale-CI refusal now tells you to check the branch out before bringing it forward. It printed
`git fetch` and `git merge` alone, and by the time it fires the same run has already returned your tree to
the trunk -- so both commands acted on `main`, silently: the merge fast-forwarded the trunk with a diffstat
that reads exactly like the branch moving forward, the push was a no-op, and the branch was untouched. The
cost was a full CI cycle and a re-run complaining about the wrong problem, twice in five days.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing a subscriber of a service notices. This is a refusal message inside the shipping tooling;
its reader is whoever is merging a pull request.

**Score:** N/A

#### Pull Request

ship-pr's stale-CI remedy names the branch to check out first

