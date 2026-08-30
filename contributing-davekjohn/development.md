## Development: `fix/record-shape-rollup-observational-v1` · 20260830-113644

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

#### What inbound #1130 measured, and the one thing it did not

The `[RECORD-SHAPE]` roll-up (`check-roster-sync.ps1:621`) asserts a defect -- *"not the assumed
shape"*, *"what is wrong is the administration"* -- one line above the `pathless-only` detail arm that
#1095 repaired into saying the same state may be entirely deliberate and *"needs no action"*. Both
lines describe the same plugin in the same hook output and say opposite things.

Verified at `c06726e6`: the roll-up wording is live in both script copies, #1095's point 3 carries no
decline comment, and the arm's conditional remedy is shipped exactly as the report describes.

**What the report did not measure: the reader's FIRST line is not the roll-up.** In a session
`roster-sessioncheck.ps1:287` prints *"the plugin is installed here, but its record is not the shape
the docs assume:"* above it, making the identical unconditional claim. Repairing only 621 leaves the
contradiction verbatim in the output the report was looking at, so both lines are in scope.

**Not a predicate change**, per the report and per #1095's own correction: `$recordShapes` still
counts every enabled id. #323 measured that the demotion writes a record byte-for-byte identical to an
ordinary machine-wide install, so no field separates the two states and any gate reopens a silence
#314/#315/#323 were built to end. The arms keep firing; the headline stops claiming.

### CREATE

- [x] `check-roster-sync.ps1`: the roll-up states the observation and defers the verdict to the arms
- [x] `roster-sessioncheck.ps1`: its `[RECORD-SHAPE]` verdict line does the same
- [x] mirror the root copy into the plugin via `build-shared-scripts.ps1`

### TEST

- [x] `roster-sync.tests.ps1`: repoint the asserts that pin the old wording, in the fixtures and in the hook stubs
- [x] add the asserts that pin the repair -- the roll-up may not claim a defect while a `pathless-only` arm is forwarded
- [x] `roster-sync.tests.ps1` green (339 pass) and `check-plugin-integrity.ps1` green -- the full suite set is open-pr's own gate, not a step to pre-run

### DEPLOY: `fix/record-shape-rollup-observational-v1`

The `[RECORD-SHAPE]` session-start report stops calling a deliberate machine-wide install a defect.
Its two headlines — the check's roll-up and the hook verdict above it — asserted one unconditionally:
*"not the assumed shape"*, *"what is wrong is the administration"*, *"its record is not the shape the
docs assume"*. Directly beneath them sat the `pathless-only` detail line, which since
[#1095](https://github.com/DaveKJohn/claude-code-specialists/issues/1095) says in so many words that
the same state may be entirely deliberate and *"needs no action"*. Two lines about one plugin, in one
hook output, saying opposite things — at every session start, for as long as that plugin stays
installed machine-wide.

Both headlines now report what they observed and leave the verdict to the arms, which are the only
lines that can answer it. The count says the record **differs from** the assumed shape, and the
sentence after it points at the detail lines instead of pronouncing on them. Every arm still fires,
and the roll-up still says that nothing else on the machine reports this shape — that half was never
the defect, and dropping it would have traded one silence for another.

**The predicate is unchanged, deliberately.** #1095's third proposal — stop counting a plugin this
repo's own `.claude/settings.json` never enabled — reads a field the demotion does not touch, so it is
not the scope gate [#323](https://github.com/DaveKJohn/claude-code-specialists/issues/323) disproved.
It is *unmeasured*: whether `claude plugin install --scope project` always writes that enable is the
fact it would rest on, and if it does not, the gate restores exactly the silence
[#314](https://github.com/DaveKJohn/claude-code-specialists/issues/314)/[#315](https://github.com/DaveKJohn/claude-code-specialists/issues/315)/#323
were built to end. The wording needed no measurement, so the wording is what changed.

Reported as inbound [#1130](https://github.com/DaveKJohn/claude-code-specialists/issues/1130) from
`DaveKJohn/ccs-testrun-3` against `4.24.0`, and repaired one line wider than reported. The report named
the check's roll-up; the line a session reader meets *first* is the hook's own verdict, which made the
identical claim above it. Fixing only the roll-up would have left the contradiction verbatim in the
output the report was looking at.

**Score:** 2

#### What makes this deploy extra special

A consumer whose plugins are installed machine-wide — the ordinary, correct arrangement — met a yellow
"what is wrong is the administration" at every single session start, and had to read down two lines to
learn it applied to nothing. That false alarm is gone without any arm going quiet: the same states are
still reported, with the same remedies, and now the headline agrees with them.

**Score:** 3

#### Pull Request

the [RECORD-SHAPE] headline states what it observed instead of a defect it cannot establish
