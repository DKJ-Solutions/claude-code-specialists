## Development: `docs/claim-rule-covers-resume-and-strong-claim-v1` · 20260831-194524

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

Inbound #1169: the "Picking up an issue" section of Chris's persona body fires only at the start of
fresh work and illustrates only the weak claim, so a resumed session passes both halves without
either firing. All six inbound checks run against the tree and pass — symptom (lines 294-308 match
verbatim), reason (the "start" framing genuinely excludes resume), repair (text-only, names nothing
that does not exist), subject, size (body loads every turn; growth kept to one paragraph), repo (the
portable body is sourced here). #1139 is the closed script-mechanics half; this is the governance
half and no duplicate.

- [x] Verify the inbound report against the tree — six checks
- [x] Confirm no open duplicate and that #1139 does not cover this

### CREATE

- [x] `plugins/teams/team-alpha/personas/01-01-persona.md` — three edits to the claim section:
      broaden the opening to "or resume one" and fold in the read command
      (`gh issue view <n> --json assignees`); add a **Resuming is picking up** paragraph; replace the
      **claim says *taken*, not *by whom*** paragraph with strong-claim-first framing that keeps the
      one-account case as the named exception

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` — persona frontmatter + dead-link scan
- [x] `scripts/tests/*.tests.ps1` — full suite, as CI runs it

### DEPLOY: `docs/claim-rule-covers-resume-and-strong-claim-v1`

Chris's "Picking up an issue" rule now covers a resumed session and names the strong claim. The
opening line reads "before you start on an issue — or resume one —" and carries the read command
(`gh issue view <n> --json assignees`) beside the write one; a new **Resuming is picking up**
paragraph says a crash, a `--continue` or a clone that finds a pushed branch with no PR is a pickup
even though nothing announces it; and the weak-claim paragraph is replaced by
**An assignee that is not this session's own account stops the work — that is not a judgement call**,
which keeps the one-account/no-branch/no-activity case as the named exception and states its inverse.
Prose only, in the always-loaded persona body; +6 lines.

**Score:** 2 — read by any session picking up or resuming an issue; closes a silent failure that
otherwise lands at the merge (a resumed branch merging another session's work under this session's
name).

#### What makes this deploy extra special

**Score:** N/A — governance text for the specialists system; does not reach a subscriber of any
consuming service.

#### Pull Request

the claim rule covers a resumed session and names the strong claim, not only the weak one

