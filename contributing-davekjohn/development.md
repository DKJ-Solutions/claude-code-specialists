## Development: `docs/sync-main-trigger-v1` · 20260901-175339

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

#### What this branch is

Inbound [#1196](https://github.com/DaveKJohn/claude-code-specialists/issues/1196): `sync-main` documents
what it does and why it is safe, and never states **when it fires**. Two Shopify consumers of the same
owner filled that gap in opposite directions.

**Verification changed the size of the report.** It claims the frontmatter description is the only
statement of the trigger in the plugin. It is not -- there are **three**, and they disagree with each
other:

| where | what it says |
|---|---|
| `sync-main` frontmatter | *"at the START of any **theme** task"* |
| `start-task` SKILL.md, step 2 | *"verify ... that this session has done its sync"* -- unconditional |
| `manuals/05-21-manual.md` | *"It has to happen **before every task** whether or not anybody remembers it, which is the definition of a **hook**"* |

So the consumers did not drift from one source; each picked up a different one of the plugin's own
wordings faithfully. The strict consumer's *"before starting any task"* matches Sandra's manual, which
makes it the plugin's own text rather than the consumer excess the report concedes it to be. Adding a
section to `sync-main` alone would leave four statements instead of one.

#### The trigger this branch writes, and where it comes from

Not invented here. The owner's instruction is quoted verbatim in the issue (*"the live sync is actually
only relevant at the moment I push main to live"*), and the plugin already carries his precedent: inbound
[#805](https://github.com/DaveKJohn/claude-code-specialists/issues/805) narrowed `start-task`'s preview
theme on exactly this argument -- a theme is a consequence of *"I want to show this"*, not of *"I am
starting work"* -- measured at 6 of 12 previews belonging to branches that never needed one.

The two reconcile rather than compete, because the step has two jobs that fire at different moments:
capturing drift (safety-critical at the **live push**, because the `--only` push carries the trunk's copy
of those paths to live) and not branching off a stale base (only ever bites a branch that **edits a theme
file**, and costs rework rather than data).

### CREATE

- [x] `skills/sync-main/SKILL.md`: a `## When to run it` section stating the trigger, with the #1196
      measurement and the #805 precedent; narrow the frontmatter description to match
- [x] `manuals/05-21-manual.md`: repair both trigger statements -- the section opening and the
      hook-versus-script paragraph -- so they point at the skill instead of restating it
- [x] `skills/start-task/SKILL.md`: make step 2's sync gatekeeper conditional and point it at the skill

### TEST

- [~] Dropped as a step: `open-pr` runs both gates itself, so this box could only be ticked by
      pre-running the tooling's own gate. The lint gate was run standalone while writing and reported 0
      findings across 319 links and the 94 plugin-root resolutions that cover the three new
      cross-references; the suites are left to the push, which is what records them.

### DEPLOY: `docs/sync-main-trigger-v1`

`sync-main` now states **when it fires**, in one place, and the two pages that used to restate it link
there instead. The trigger: before a live push, and before work that will edit theme files -- not before a
branch that cannot touch one.

The gap was never that the trigger was unwritten. It was written **three times**, differently, and each
copy looked authoritative from where it sat: the skill's frontmatter said *"any theme task"*, `start-task`
step 2 made a sync an unconditional gatekeeper, and Sandra's manual said *"before every task ... which is
the definition of a hook"*. Two Shopify consumers of one owner then read the same step as
mandatory-always, mandatory-for-theme-work and optional -- and neither of them had drifted; each had
picked up a different one of the plugin's own wordings faithfully.

What that cost, measured on September 1, 2026 in the strict consumer: a session picked up an issue whose
entire content was a paste of `.claude/settings.json`, ran the sync first because its `CLAUDE.md` said to
before *any* task, pulled the live theme, classified 25 paths held back and 4 to take, and reported that a
real run would have refused on a standing predecessor branch. **That refusal is the structural half.**
Inbound #1021 made a standing sync branch stop the run, on the reasoning that refusing costs nothing
because the drift already sits on the predecessor -- and that holds only while the sync is a step in theme
work. Mandate it before every task and one unmerged sync PR becomes a gate on the start of *all* work in
the repo, documentation and permission changes included.

The narrowing is the owner's, twice over: his instruction is quoted in the issue, and the plugin already
carried the precedent -- inbound #805 moved the preview theme out of `start-task` on the same argument, at
6 of 12 previews belonging to branches that never needed one. A preview theme is a consequence of *"I want
to show this"*; this sync is a consequence of *"I am about to touch the theme"*.

The skill's section also says out loud that the trigger lives there and nowhere else, and that the name
*pre-task sync* is a label rather than the trigger -- because the name is what every paraphrase reached
for.

**Score:** 4

#### What makes this deploy extra special

A Shopify consumer stops running a live theme pull, a full-theme comparison and a possible hard refusal at
the start of documentation, tooling, CI and config work that cannot touch a theme file -- and stops having
one unmerged sync PR block the start of that work. It also gives their `CLAUDE.md` a section to point at
instead of a fourth paraphrase to write.

**Score:** 3

#### Pull Request

state when the pre-task sync fires, once, in the skill both other pages point at

