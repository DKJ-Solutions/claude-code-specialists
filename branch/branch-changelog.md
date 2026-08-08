## `feat/the-workflow-is-its-own-plugin` changelog

### Branch title

The way of working becomes its own plugin

### Branch ID

20260808-101244

### Branch type

feat

### What does the change on this branch bring to main?

The branch/changelog/release workflow leaves the core and ships as a fifth, opt-in plugin:
**`specialists-workflow-davekjohn`**. This is the packaging half of the doctrine PR #520 wrote down —
*does this describe a craft, or a way of working?* — applied to what the core was actually sending.
Measured that day: **9%** of the `specialists` payload described a craft and **47%** was workflow
machinery, so most of what a consumer received was a method they had never chosen.

**What moved:** the seven workflow skills (`new-branch`, `open-pr`, `ship-pr`, `fold-changelog`,
`cut-release`, `park`, `fix-mojibake`), their scripts, the libs only they read, and **two of the three
session hooks** — `connector-sessioncheck`, which reads a register of Dave's own repos, and
`script-contract-sessioncheck`, which demands config for scripts a core-only consumer does not have.
`roster-sessioncheck` stays: a roster is the core's own concern. **The enforcement moving is the half
that matters most** — a repo that works differently is no longer told at every session start that it is
misconfigured, because the checker that had the opinion is not there.

**`specialists-init` stops scaffolding what it cannot justify.** It could not simply stop, and the
measurement said why: `Get-RosterPath` and `Get-RosterIgnoredIds` are read by `check-roster-sync`,
which stays in the core. So `repo-config.ps1` splits — the roster half always, the workflow half only
with the pack — and `branch-info.ps1`, whose every function serves a branch script, is not written at
all without it. Assembled from parts rather than as two complete variants, so the roster functions
exist once instead of in two here-strings free to drift.

**The name says whose method it is on purpose.** Groups 2–4 answer *what kind of repo is this*; group 5
answers *whose way of working is this*, and a subject-shaped name would have hidden that difference.

**The design question this branch was parked on for days was a misreading, and that is the part worth
keeping.** The parked note said `check-report-lib` and `native-capture-lib` each had readers in both
halves, and neither did: `open-pr.ps1` and `fold-changelog-entry.ps1` name the first only in a comment
("Like check-report-lib.ps1 this lib is not repo-owned…"), and `check-report-lib.ps1` names the second
on line 294 to say it **needs none of** its EAP dance. Both rows were *mention* read as *use* — the
fifth recorded instance of that defect class in this repo, and the first where it cost days of not
building rather than a wrong build. One lib does end up shared, for a reason the note never identified:
moving `check-script-contract` to the pack leaves `check-roster-sync` in the core, and both dot-source
`check-report-lib`. That got a second registry entry after all three readers were **read** rather than
assumed — the generator and lint check 8 loop per pair, check 18 skips `LibOnly` entirely, and the
suite tolerates it **only with a distinct `Name`**, because eleven lookups use
`Where-Object { $_.Name -eq … }` and would otherwise get an array back. `shared-scripts.tests.ps1` now
refuses any mirror that dot-sources a lib living in the other plugin: the assert that would have caught
the original misreading, not merely the fix for it.

**Two defects the step list never predicted, both found by running the gates rather than by reading.**
The lint's check 18 and `shared-scripts.tests.ps1` looked for a script's documenting page at a
hardcoded `plugins\specialists\skills\…`, so the moment nine entry points moved, every one of their
existing skills was reported as a typo; the registry now **derives** the page path from the mirror, so a
script that moves takes its lookup with it. And `specialists-teardown` classifies a scaffold by
placeholder *value* — but a core-only `repo-config.ps1` has nothing to fill in and therefore carries no
placeholder, so it read as authored and would have been kept forever, making adoption exactly as
irreversible as that skill promises it is not. It recognises a second shape now, keyed on "still
exactly what the bootstrap wrote", which is conservative in the right direction: every way an owner can
touch that file adds something.

**Coverage follows the split rather than being retargeted to it.** `bootstrap-drift.tests.ps1` asserts
**both** shapes — the plain consumer (no `branch-info.ps1`, roster half only, and the run *names* the
pack the other half belongs to) and one that enabled the pack — because asserting only the full shape
would have left the case the doctrine is about untested while looking thorough. `-VendorScripts` now
states which pack it does **not** cover instead of listing four files silently.

All 27 suites green in 139s; lint gate 0 errors.

Plugins: specialists, specialists-workflow-davekjohn

### Significance

#### Tier 0

The shared-scripts registry now spans two plugins and derives the skill page from the mirror, so the
next person who moves a script does not meet the nine-typo report this change met. The `check-report-lib`
double registration and the cross-plugin dot-source assert are both new machinery a maintainer has to
know about. Against that, nothing about how this repo itself is developed changes: the same scripts sit
at the same root paths.

**Score:** 3

#### Tier 1

The parked design question turned out to be a mention-vs-use misreading, which is this project's
best-documented defect class and the first time it cost *days of not building*. The lesson generalises
past this branch: a note that stops work is an inference, and reading the four files it names took
minutes. Also here: a generator that gains a mode emitting no placeholder silently breaks every
consumer that classifies its output by one.

**Score:** 4

#### Tier 2

A consumer that enables only the core stops receiving a way of working it never chose — no branch
scripts, no `branch-info.ps1` to fill in, and no session hook auditing it against somebody else's
method. A consumer that *wants* the workflow has to enable a second plugin, and until it does, its next
plugin update takes `ship-pr` away. That is a required action with a deadline, which is what puts this
at the top of the band rather than in the middle.

**Score:** 5

### Pull Request
