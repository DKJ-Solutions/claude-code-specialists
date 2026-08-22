---
name: measure-skill
description: >-
  Measure what a skill COSTS and how fast the script behind it runs -- always-on tokens (paid by
  every session whether the skill fires or not), on-invoke tokens (paid per firing), the delta
  against a stored baseline, and the wall-clock of the script it drives. Use it before adding a
  skill, when a plugin's session cost has grown, or to find which skills are carrying that cost. It
  drives `claude plugin details` rather than estimating from file sizes, so the figure is the
  authoritative one; it is read-only by default and is not a gate.
---

# measure-skill — what a skill costs, before somebody asks

A skill's **description** is paid by every session in every consumer, whether it ever fires or not.
Its **body** is paid per firing. Both were unmeasured in the repo that maintains these plugins until
this script existed, and the growth was real: 7 skill descriptions cost **~1,245** tokens at
`v2.10.0`, while 18 across two enabled plugins cost **~3,650** at `v4.17.0` — nearly 3×, never
re-measured in between.

**This page is itself one of the figures it reports.** Its own description costs always-on tokens in
every session that has this plugin enabled, which is the argument for keeping it short rather than a
joke at its own expense.

## What it measures, and what it deliberately does not

| dimension | who owns it |
|---|---|
| always-on + on-invoke tokens, per skill, with a baseline delta | **this skill**, pass 1 |
| wall-clock of the script behind a skill | **this skill**, pass 2 — read-only invocations only |
| frontmatter, dead links, parameter coverage, printed install commands | `check-plugin-integrity.ps1` — 26 checks. Not duplicated here: two verdicts on one subject is worse than one. |
| whether the skill actually WORKS — does it fire, does it beat no-skill | `claude plugin eval`. Designed for, not built. See [Pass 3](#pass-3--effectiveness-designed-not-built) below. |

**It computes no token count of its own, deliberately.** Pass 1 parses `claude plugin details`, whose
figures come from the `count_tokens` API for the active model. A second, file-size-based estimate would
produce a number that disagrees with the authoritative one — the failure the performance lens names
directly: *do not estimate from file sizes*.

**It is not a gate and must not become one.** `open-pr` already spends ~10s of lint plus ~170s of
suites, and CI's `lint-en-tests` has a median of **7m 23s** and blocks every merge. A skill's cost
changes on the scale of releases, not commits.

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/measure-skill.ps1"
```

**In the source repo, run its own copy instead** — `scripts/maintenance/measure-skill.ps1`. The plugin
cache holds the last *released* mirror and so lags its own source by however many merges have landed
since.

With no arguments it measures **what a session here actually pays**: every plugin enabled for this
repo, read from the settings chain. Pass 1 only, nothing is written.

## Pass 1 — cost

Per skill: always-on, the delta against the baseline, on-invoke, and its share of the plugin's
always-on total. Ranked by always-on, because that is the figure paid unconditionally.

Two rules are enforced by the script rather than left to whoever reads the output:

- **It names the copy it measured.** `claude plugin details` prices the **marketplace clone**, not the
  tree. Where those differ the report says so, because the difference is *queued cost arriving at the
  next plugin update* — not error to smooth away.
- **The "fires how often" column is left empty.** An on-invoke figure without a firing frequency is not
  a cost, and a guessed frequency is worse than a blank one. Fill it in yourself; the script will not
  invent it.

**The parse is the weak point, and it fails loudly.** The per-component table is human-formatted output
whose shape the CLI owns. Two cross-checks run before any figure is printed: the rows must sum to the
printed `Always-on` total within tolerance, and every skill the component inventory names must have
produced a row. Either failing is an `[ERROR]` and **no table is printed for that plugin** — a
plausible wrong number is worse than a refusal.

Two notations share one table and both are handled: `~3.031` is **3031** (the dot is a thousands
separator) while `~1.3k` is **1300**. A parser that read the first as 3.031 would under-report by a
factor of a thousand and still look entirely plausible, which is why the sum check exists.

## Pass 2 — speed

Opt-in. It times the script behind a skill and reports min/median/max with the machine state and `n`.

**It will not run a script that has no declared read-only mode, and that is the whole safety model.**
Timing the script behind `cut-release` by invoking it would cut a release. So a script is timed only
where its registration in the shared-scripts registry carries a `MeasureArgs` key naming a harmless
invocation; everything else is reported as **not measured**, by name, with the reason. The declaration
lives beside the registration rather than in a list inside the measuring script, because a second
hand-written list is one a newly shared script falls out of silently.

Pass 2 needs that registry and therefore runs only in the repo that maintains these scripts. In a
consumer it reports `[SKIP]` with the reason; **pass 1 works everywhere**, since it needs nothing but
the `claude` CLI.

## Pass 3 — effectiveness (designed, not built)

The question pass 1 cannot answer: *does this skill earn its always-on tokens?* A skill that scores no
better than no skill at all is a pure loss however elegant it is, and the metric that says so is the
**score delta per always-on token**.

`claude plugin eval` already provides the engine — cases, graders, `--runs`, and an `--ablation
with-without` arm that scores the same cases with the plugin removed. It is not wired up here, and
building it is separate work: this repo has **zero** eval suites, so pass 3 starts with authoring
cases via `claude plugin eval init`.

Four flags are non-negotiable whenever that work does happen, and they are recorded here so the first
person to run it does not have to rediscover them:

- **`--no-publish`** — the HTML report otherwise goes to claude.ai. Publishing outside the normal PR
  flow is the repo owner's decision, not a side effect of a measurement.
- **`--max-cost-usd <ceiling>`** — `--runs` defaults to 3 per case, and each run is a real agent.
- **no `--scaffold`** — that runs author-supplied bash as you.
- **`--ablation with-without`** — the delta is the entire point; a bare score does not say whether the
  skill was needed.

## Parameters

| parameter | what it does |
|---|---|
| `-Plugin <name...>` | Which plugin(s) to measure, as `<name>@<marketplace>` or just `<name>`. Default: every plugin enabled for this repo — i.e. what a session here actually pays. |
| `-Skill <name...>` | Limit the report to these skill names. Default: every skill the plugin's inventory names. |
| `-IncludeSpeed` | Also run pass 2. Off by default because it executes scripts — and it executes only those whose registration declares a read-only invocation. |
| `-Runs <n>` | Timed runs per script in pass 2. Default `3`, the smallest n that yields a median. |
| `-BaselinePath <path>` | The cost baseline to compare against. Default: `scripts/maintenance/baselines/skill-cost.json`. |
| `-UpdateBaseline` | Record the measured cost figures instead of only comparing against them. **Merges**: a run narrower than the file updates its own rows and leaves the rest standing. |
| `-OutFile <path>` | Also write the markdown report to this path, for pasting into a lens or a dossier. |

**A comma-separated value works**, and that is not free: `powershell -File <script> -Skill a,b,c` does
not parse PowerShell syntax for the arguments after the script path, so `a,b,c` arrives as one string.
The script splits it, because that invocation form is the documented one.

## Examples

```powershell
# What does a session here pay, and which skills carry it?
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/measure-skill.ps1"

# One skill, with the wall-clock of the script behind it
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/measure-skill.ps1" `
  -Plugin workflow-davekjohn -Skill cut-release -IncludeSpeed -Runs 5

# Record the baseline, so the NEXT run reports the growth
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/measure-skill.ps1" -UpdateBaseline

# A markdown report to paste into a lens
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/maintenance/measure-skill.ps1" -OutFile skill-cost.md
```

## What it writes

Nothing, unless asked. `-UpdateBaseline` rewrites the baseline file and `-OutFile` writes the report;
without either, the script reads and prints. The baseline is **committable**: token counts come from an
API rather than from the machine that ran the script, so the file means the same thing everywhere.
Pass-2 timings are machine-dependent and are deliberately **not** stored — a median that travelled to
another machine would be a figure nobody could reproduce.
