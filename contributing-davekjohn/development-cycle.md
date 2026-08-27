## Development cycle: `feat/adopt-act-on-this-skills-v1` · 20260827-090447

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Plan written from the 22 August skills assessment; simplify has no home yet and code-review's --fix/--comment flags are unbounded.

#### Where this comes from

The skills assessment of 22 August 2026 scored the eighteen built-in skills on **weight** (how much
the skill matters in this repo) and **gain** (what is still on the table), and ranked them by
`√(weight · gain)`. Exactly two reached the **Act on this** band, and those two are the whole scope
of this branch:

| action | skill | w·g | state in this repo |
|---|---|---|---|
| 5.00 | `simplify` | 5·5 | **no mention anywhere** |
| 4.47 | `code-review` | 5·4 | wired into Victor #19 and Edith #17 |

Counted on this branch, 27 August 2026: `grep -rl` over `*.md` returns **0** files for `simplify`
and **11** for `code-review` — of which four are archived release notes and one is `README.md`,
leaving the two agent defs and the two manuals as the whole of its wiring.

#### The finding the assessment did not carry: these are not two of a kind

`code-review` **reports** and `simplify` **repairs**. That is not a difference in depth but a
difference in *moment*, and the moment decides the owner:

- **`code-review` delivers findings.** That is the reviewer's moment, and it is already there.
- **`simplify` applies the fixes** — its own description says so, and adds "quality only — it does
  not hunt for bugs; use `/code-review` for that". That is the **author's** moment, before the
  handoff.

Read that way the obvious home for `simplify` is the wrong one, and provably so:

- **Not Victor #19.** His own boundary refuses it: *"You deliver findings, you do **not apply them
  yourself unprompted**: pushing a fix without consulting the author undermines exactly the
  independent look you provide."* A reviewer who runs `simplify` has stopped being a reviewer.
- **Not Ravi #24.** He has the right *shape* — he is the one review-adjacent specialist who delivers
  a changed working copy — but the wrong *subject*: his standing scope is duplication of
  **behavioural rules across agent-defs and personas**, not the reuse and efficiency of script code.

So `simplify` goes to whoever wrote the code. In this repo that is **Sylvester #15** for `scripts/**`
and the manifests, who already carries `Edit`, `Write`, `Bash` and `Skill`.

#### The second half: `code-review` is wired, but unbounded

Both wirings name the skill and stop there — Victor's agent def step 2 and manual lines 40/48,
Edith's agent def step 3 and manual lines 38/41. The skill takes two flags neither manual mentions:

- **`--fix`** applies the findings to the working tree. For Victor that is the exact act his boundary
  forbids, and nothing currently says so.
- **`--comment`** posts the findings as inline PR comments. Victor neither opens nor touches PRs —
  that is Derek #05 — and again nothing says so.

Neither is hypothetical: they are documented flags on a skill two agent defs already instruct a
specialist to reach for. Naming them as out of bounds is the *sharpening* half of this branch.

#### Where the change lands, and why not the lens

Both halves are craft, not repo trivia: a reviewer must not apply his own findings in **any** repo,
and an author tidying before the handoff is how the chain is meant to run everywhere. So both land in
the **portable layer** — the agent defs under `plugins/teams/team-alpha/agents/` and the manuals
beside them — and reach every consumer through the next release. The repo lens gets only what is
genuinely local: Chris's routing line.

#### Tactically: three moves, smallest first

1. **Bound what already exists** (`code-review`, Victor + Edith). Prose only: no new wiring, no
   generator run, no shared block. Lowest risk, and it stands on its own if the rest is dropped.
2. **Give `simplify` a home** (Sylvester #15) — one agent def, one manual, one routing line.
3. **State the pairing once** where both sides can see it: the author simplifies, the reviewer
   reviews.

Deliberately **out of scope**: the four *Worth a trial* skills (`skill-doctor`, `security-review`,
`artifact-diagramming`, `schedule`), and any change to the shared blocks under
`plugins/teams/agent-shared/`. If the pairing rule turns out to belong to more than one specialist,
that is Ravi's alarm and a separate branch — not a copy-paste here.

### CREATE

- [ ] Re-verify both counts above on this branch before writing anything — the assessment is five days old
- [ ] Victor #19: name `--fix` and `--comment` as out of bounds, in the agent def and the manual
- [ ] Edith #17: bound `--fix` the same way — she also delivers findings and does not correct the text
- [ ] Sylvester #15: add `simplify` to his working method at the author's moment, in the agent def and the manual
- [ ] Write the `simplify` ↔ `code-review` pairing once per manual, in one sentence, without repeating the reasoning
- [ ] Chris's lens: add the routing line so an assignment about simplification reaches Sylvester rather than Victor

### TEST

- [ ] Confirm the pairing sentence is NOT verbatim in ≥2 agent defs — if it is, it is a shared block and Ravi's call, not a paste
- [ ] `check-plugin-integrity.ps1` green (manifests, frontmatter, dead links, install-line flags)
- [ ] All suites green (`scripts/tests/*.tests.ps1`)
- [ ] Read the diff back against the three moves above: nothing touched outside the four agent defs/manuals and the one lens

### DEPLOY: `feat/adopt-act-on-this-skills-v1`

**Score:**

#### What makes this deploy extra special

**Score:**

#### Pull Request

Adopt the two 'Act on this' built-in skills into the specialists chain

