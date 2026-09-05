## docs/1473-readme-hook-count

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

Issue #1473: the `dkj-policy/` row of the README plugin table says the plugin ships
*"the two session hooks"*. `plugins/workflows/dkj-policy/hooks/hooks.json` lists **five**
SessionStart hooks and one Stop hook, so the first half of that clause is stale and the second
half is correct.

#### The second occurrence, judged rather than swept

`README.md:115` carries the same three words and is **left standing deliberately**. It sits inside
a paragraph opened by *"Measured on August 8, 2026"* and closed by *"Decision by Dave, August 8,
2026; packaged the same day"*, and it enumerates what moved out on that day -- when two is what
there were. Sweeping it is the defect #952 named: historical-by-design text rewritten to match the
present, where the repair was to keep those strings at the wording they were WRITTEN with.
Restating two as five here would make a correct account of that day wrong. Only line 196 is
present-tense current-state prose, and only line 196 is touched.

### CREATE

- [x] Verify the symptom against `plugins/workflows/dkj-policy/hooks/hooks.json` on a current trunk -- five SessionStart hooks, one Stop hook
- [x] Drop the count from `README.md:196`, matching the wording `plugins/workflows/README.md:16` already uses for the same set
- [x] Judge `README.md:115` deliberately and record the verdict in PLAN -- left standing, dated account
- [~] Repair `connectors/claude-code-specialists.json` -- dropped: the open branch `fix/1465-register-dkj-policy-id` already owns that line
- [~] Repair `plugins/teams/team-alpha/skills/specialists-init/SKILL.md:50` -- dropped: different subject (which documents name the bootstrap command, where one hook does, not five), filed as its own issue

### TEST

- [x] `check-plugin-integrity.ps1` + the full suite green (run by `open-pr.ps1`)
- [x] `git diff --stat` shows one file, one line -- line 115 provably untouched
- [x] `grep -c "the two session hooks that belong to running this" README.md` reads 0

### DEPLOY: docs/1473-readme-hook-count

The README's plugin table no longer tells a reader how many session hooks `dkj-policy` ships. It
says the plugin ships *the session hooks that belong to running this across several repos* -- the
mechanism, not a count -- which is the wording `plugins/workflows/README.md` already carries for
the same set. The number that was there said **two** while `hooks.json` lists **five**.

That is the same answer `.claude/specialists/SPECIALISTS.md` reached after its own hook count went
stale twice inside two days: each plugin's `hooks/hooks.json` is the one place that cannot drift,
so the prose points at it instead of racing it. The **Stop** hook keeps its number, exactly as
SPECIALISTS.md keeps it -- *one* is not a running total there but the distinction the sentence is
making, between hooks that report and the one that acts.

`README.md:115` says *the two session hooks* as well and is deliberately untouched. It is the
account of what moved out of `team-alpha` on August 8, 2026, bracketed by that date at both ends,
and two is what there were that day; a dated measurement keeps the wording it was written with.

**Score:** 2

#### What makes this deploy extra special

The plugin table is what a prospective consumer reads to decide whether to enable `dkj-policy` at
all, so the one stale number in it was the one sizing figure they had. Nothing broke on the old
wording -- the failure it prevents is a consumer budgeting for two session hooks and adopting
five.

**Score:** 1

#### Pull Request

README's workflow-plugin row no longer states a session-hook count that goes stale
