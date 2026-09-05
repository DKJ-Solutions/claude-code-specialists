## feat/plugin-policy-precedence

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

#### Why this branch exists

Dave: a consuming repo's root `CLAUDE.md` must never contradict the policy shipped by an installed
plugin. Fixed precedence when both are installed: `contributing-davekjohn` outranks `bwj-codex`, which
outranks the consumer's own root `CLAUDE.md`. A consumer's only choice is to install and follow, or not
install and run its own policy -- never a blend. A new on-demand, report-only skill (pattern:
`adopt-config`/`check-branch-entry`, not a SessionStart gate) scans a consumer repo for contradictions
against the installed plugins' portable policy and states which side wins; it never edits the
consumer's file itself.

### CREATE

- [ ] Tessa: state the precedence rule itself in `contributing-davekjohn/CONTRIBUTING-portable.md`
      (a new section, positioned so it reads before the cycle steps) -- `contributing-davekjohn`'s
      policy outranks a consumer's root `CLAUDE.md`; the consumer's real choice is full adoption or no
      install, never a blend.
- [ ] Tessa: a one-line cross-reference in `bwj-codex/WORKFLOW-portable.md` naming its own second
      place in that order (behind `contributing-davekjohn`, ahead of the consumer's root `CLAUDE.md`)
      -- pointing at the canonical statement above rather than restating it (single source, Ravi's
      convention).
- [ ] Sylvester: a new on-demand, report-only skill in `contributing-davekjohn/skills/check-policy-drift/`
      (`SKILL.md` + script under `scripts/task/`) that reads a consumer's root `CLAUDE.md` against the
      installed plugins' portable policy (`CONTRIBUTING-portable.md` always; `WORKFLOW-portable.md` too
      when `bwj-codex` is installed) and reports every contradiction found, naming which side wins per
      the rule above. No auto-fix; the actual edit to the consumer's `CLAUDE.md` is a separate,
      ordinary branch+PR in that consumer's own repo. Semantic comparison is a judgement call (like
      `report-issue`), so the script's job is locating and handing over the right documents, not parsing
      prose.
- [ ] Roster/lint sanity: run `check-plugin-integrity.ps1` and the full suite locally before requesting
      review.

### TEST

### DEPLOY: feat/plugin-policy-precedence

**Score:**

#### What makes this deploy extra special

**Score:**

#### Pull Request

Plugin policy outranks a consumer's root CLAUDE.md

