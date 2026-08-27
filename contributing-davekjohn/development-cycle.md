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

Recounted on this branch, 27 August 2026, and the recount changed the arithmetic without changing the
conclusion. `grep -rl` over `*.md` returns **0** files for `simplify` and **11** for `code-review` —
but **four of those eleven never mention the skill at all**: they match on the filename
`.github/workflows/claude-code-review.yml`, which contains the string. Of the seven that do, three are
archived release notes. That leaves the two agent defs and the two manuals as the whole of its
wiring, which is what this plan assumed — reached by a different route than the first count
suggested, and worth writing down because a naive count over-reports the subject here by more than
half.

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

So `simplify` goes to whoever wrote the code — and **which specialist that is depends on the layer**,
which this plan got wrong on the first pass and corrected while building.

**Portable: Cody #13, the App Developer.** He is the one specialist in the plugin whose craft *is*
writing code, he already carries `Write`, `Edit`, `Bash` and `Skill`, and `artifact-design` is
already wired into his working method the same way. Sylvester #15 was the first answer here and it
does not survive reading his portable playbook: his shipped scope is the **harness** — `.claude/`,
settings, hooks, MCP, skills, marketplaces — and `scripts/**` is an *extension this repo's lens gives
him*, not something he owns in every consumer. Writing `simplify` into his portable agent def would
have claimed script authorship for him in repos that never granted it.

**Local: Sylvester #15, in the lens.** Here the code *is* `scripts/**` and those are his, so the repo
lens names him as the author who runs the tidy pass. That split is the source-is-default rule working
exactly as intended: *"the reviewer must not apply his own findings"* is craft and travels; *"the
author of code here is Sylvester"* is local and stays.

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

The **rule** is craft, not repo trivia: a reviewer must not apply his own findings in **any** repo,
and an author tidying before the handoff is how the chain is meant to run everywhere. So the rule
lands in the **portable layer** — the agent defs under `plugins/teams/team-alpha/agents/` and the
manuals beside them — and reaches every consumer through the next release.

The **lens gets what is genuinely local**, and here that is two things rather than one: Chris's
routing line, and Sylvester's own lens entry. The second is not optional — Sylvester never reads
Chris's lens, so a routing line alone would name an owner who is never told.

#### Tactically: three moves, smallest first

1. **Bound what already exists** (`code-review`, Victor + Edith). Prose only: no new wiring, no
   generator run, no shared block. Lowest risk, and it stands on its own if the rest is dropped.
2. **Give `simplify` a home** — portable with Cody #13, local with Sylvester #15.
3. **State the pairing once** where each side can see it: the author simplifies, the reviewer
   reviews.

Deliberately **out of scope**: the four *Worth a trial* skills (`skill-doctor`, `security-review`,
`artifact-diagramming`, `schedule`), and any change to the shared blocks under
`plugins/teams/agent-shared/`. If the pairing rule turns out to belong to more than one specialist,
that is Ravi's alarm and a separate branch — not a copy-paste here.

### CREATE

- [x] Re-verify both counts above on this branch before writing anything — the assessment is five days old. 0 and 11 both confirmed; the split behind the 11 was wrong and is corrected above (four hits are the filename `claude-code-review.yml`, not the skill)
- [x] Victor #19: name `--fix` and `--comment` as out of bounds, in the agent def and the manual
- [x] Edith #17: bound `--fix` the same way — she also delivers findings and does not correct the text. **Widened to `--comment` as well, deliberately**: "the same way" is Victor's way, and his covers both. She carries the same shared `no-commit-push-pr` block he does, so the PR reasoning applies to her word for word — bounding one flag and not the other would have left exactly the inconsistency her craft exists to catch. Worded from her side, not pasted from his
- [~] Sylvester #15 in the **portable** layer: dropped, and the reason is the finding above — his shipped scope is the harness, not `scripts/**`, so this would have claimed script authorship for him in every consumer. Replaced by the next two lines
- [x] Cody #13: add `simplify` at the author's moment, in the agent def (working method 4) and the manual (hard rules)
- [x] Sylvester #15 in the **lens**: name him the local author who runs the tidy pass, because he never reads Chris's lens
- [x] Write the `simplify` ↔ `code-review` pairing once per manual, in one sentence, without repeating the reasoning
- [x] Chris's lens: add the routing line so an assignment about simplification reaches Sylvester rather than Victor

### TEST

- [x] Confirm the pairing sentence is NOT verbatim in ≥2 agent defs — if it is, it is a shared block and Ravi's call, not a paste
- [x] Confirm no shared block was touched: the `<!-- BEGIN shared: -->` regions must still equal `agent-shared/` (lint check 7)
- [x] `check-plugin-integrity.ps1` green (manifests, frontmatter, dead links, install-line flags)
- [x] All suites green (`scripts/tests/*.tests.ps1`) — **53 suites, 5,352 asserts, 0 failures, 58s**, measured with `Invoke-TestSuiteGate`, the runner CI itself calls. Worth recording how it was NOT measured: a hand-rolled `ForEach-Object { & $_.FullName; $LASTEXITCODE }` loop reported `sync-rules.tests.ps1` as `-1` while that suite printed `OK: all 61 asserts passed` — `&`-invoking a .ps1 that never calls `exit` leaves `$LASTEXITCODE` at whatever the previous native command left, so the loop invented a failure the gate does not have. Ask the gate, not a loop
- [x] Read the diff back against the three moves above: nothing touched outside the three agent defs, three manuals and two lenses

### DEPLOY: `feat/adopt-act-on-this-skills-v1`

Two built-in skills that look like a pair are split along the line that actually separates them:
`code-review` **reports**, `simplify` **applies**. The reporting skill was wired into two reviewers with
its flags unmentioned, and the applying skill was mentioned nowhere in the repo at all — so this closes
both halves at once. Victor #19 and Edith #17 are now told that `--fix` and `--comment` sit outside their
boundary rather than inside their tooling; Cody #13 gains `simplify` as the author's tidy pass before the
handover; and Chris's routing plus Sylvester's lens name Sylvester the author who runs it here, because
in this repo the code is `scripts/**`.

For somebody maintaining this repo that is two concrete answers where there were none: a review never
reaches for either flag, and "tidy this up" routes to the author rather than to the reviewer. Nothing
already written stops working, which is what keeps this at 3 — it is noticed the moment somebody runs a
review or finishes a script, not before.

**Score:** 3

#### What makes this deploy extra special

A consuming repo receives the portable half through the next release, and only one third of it is
observable there: **Cody hands over tidied code where he previously handed over untidied code.** The other
two thirds prevent a failure rather than deliver a feature, and the rubric asks for that failure to be
named — a reviewer who reaches for `code-review --fix` has silently applied his own findings, which is the
exact act his boundary forbids, and one who reaches for `--comment` has written on a PR that belongs to
the git role. Neither had anything telling them so.

Sylvester's half deliberately does not travel. His shipped scope is the harness; `scripts/**` is this
repo's own extension to it, so naming him the script author in the portable layer would have claimed that
authorship in consumers that never granted it.

**Score:** 2

#### Pull Request

Adopt the two 'Act on this' built-in skills into the specialists chain

