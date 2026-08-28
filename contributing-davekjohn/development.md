## Development: `feat/chris-on-demand-manual-v1` · 20260828-102349

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

Relax lint check 6b so a manual may be backed by a persona; move Chris's evidence-carrying prose off the always-on path into manuals/01-01-manual.md. Closes #1017.

#### The decision this branch implements

#1017 named three candidates and reserved the choice. Dave picked the first on August 28, 2026:
relax the gate and give Chris a manual. Candidate 2 (a new portable skill) was declined on its own
measurement -- a skill's description is paid by every session in every consumer whether it fires or
not, so it buys back less than it costs to reach.

### CREATE

- [x] `check-plugin-integrity.ps1`: 6b accepts a persona as a backer, and requires a persona that
      backs a manual to name it. Header docs for 3c and 6b corrected in the same edit -- 3c asserted
      that check 6 leaves personas alone, which stopped being true.
- [x] `manuals/01-01-manual.md`: the phase model, parallel delegation, and the six inbound checks in
      full, plus what "leading" means for a persona-backed pair.
- [x] `personas/01-01-persona.md`: those three replaced by the rule and a pointer. 25,674 -> 20,535 B.
- [x] `.claude/specialists/README.md` and root `README.md`: the contradiction #1017 measured
      ("the leading half is the manual" + "Chris remains a persona"), resolved rather than reworded.
- [~] The index table in the handbook -- not touched: its column is **Agent def**, and Chris still
      has none. The row was already correct.

### TEST

- [x] Check 6 had **no** coverage in any of the four integrity suites. Seven asserts added to
      `check-plugin-integrity-docs.tests.ps1` covering all four states, not just the new one: no
      backer, a silent persona, a naming persona, and a persona with no manual at all.
- [x] Full gate green -- `check-plugin-integrity.ps1` 0 errors, `check-roster-sync.ps1` 0 errors.

### DEPLOY: `feat/chris-on-demand-manual-v1`

The orchestrator gets the on-demand half every other specialist already had. His persona is loaded on
every turn in every consuming repo, and until now the lint gate's check 6b required an agent def
behind every manual -- which he has none of, by design, being the only specialist who can ask the
owner anything. So every rule he carried sat on the always-on path whether or not the session ever
needed it. 6b now accepts a persona as a backer, and three sections moved into
`manuals/01-01-manual.md`: the workflow phase model, delegating parallel work, and the six inbound
checks in full. Each is unknowable at the start of a turn, which is what made them the right three.

**5,139 B off the always-on path, ~1,647 tokens, 20.0% of the persona** -- on top of the 1,861 B the
compression branch before it recovered, and paid for by no rule being dropped. The gate enforces the
half that can break: a persona backing a manual must name it, since it is the only half that loads.

**Score:** 4

#### What makes this deploy extra special

Every consuming repo pays this path before its first assignment, so the saving lands on each of them
at the next plugin update without anyone doing anything. Nothing a consumer has to act on: no rule
changed, no file they own moved, and a persona with no manual -- Bianca, Derek, Rendall -- is
untouched in both directions.

**Score:** 3

#### Pull Request

Chris gets an on-demand manual, like every other specialist

