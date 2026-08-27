## Development cycle: `fix/remove-lock-and-handover-v1` · 20260827-143634

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

#### What #957 asks, and what it drags along

Dave has no use for `/lock` and `/handover` since the development-cycle document took over the job of
recording where a branch stands. Removing the two skill pages is not free-standing work: they are two
front doors on **one** engine, `scripts/task/session-status.ps1`, and nothing else invokes it.

Scope confirmed with Dave before any file was touched: **everything goes** -- the two skills, the
engine and its plugin mirror, its suite, the shared-scripts registry entry, the two seam registrations
naming it as a reader, and every live claim about it in the docs. The alternative he declined was
re-homing the engine under `/park`.

Three things force the wider scope rather than being tidiness:

- **`[skill-param]` (lint check 18)** errors on a registry entry naming a SKILL.md that does not exist,
  and `shared-scripts-lib.ps1` registers `session-status` with `Skill = 'lock'`.
- **`[skill-list]` (lint check 10)** holds both marked skill-enumeration spans in the root `README.md` to
  the known-skill set, so a removed skill left in a span is a hard error.
- **The dead-link scan** catches the `skills/lock/SKILL.md` links in the plugin READMEs and the one in
  Chris's lens.

#### Two consequences, accepted deliberately

- **The park note loses its only printer.** `park-lib.ps1` writes it into the commit body and
  `session-status` was what read it back under each parked branch. It stays readable with `git log`;
  every doc that promised the automatic printout is repaired rather than left claiming it.
- **`source-repo-guard.tests.ps1` used the engine as its fixture script** and is re-pointed at another
  shared script, since the guard itself is unaffected by this removal.

#### What is history and stays

`CHANGELOG.md`, `contributing-davekjohn/releases/**`, and the measured-instance records that merely name
the script as the place a lesson was learned. A past-tense measurement does not become false when its
subject is deleted. What is repaired is every sentence stating what the script *does now*.

### CREATE

- [x] Delete the two skill directories, the engine (root copy + plugin mirror) and its suite
- [x] Drop the `session-status` entry from the shared-scripts registry (root + mirror)
- [x] Drop it as a reader from the two seam registrations in `script-contract-lib.ps1` (root + mirror)
- [x] Drop `.claude/handover.md` from `.gitignore` and both entries from the skill-cost baseline
- [x] Repair the plugin docs: both READMEs, the scripts README table, `DEVELOPMENT-portable.md`, `park/SKILL.md`
- [x] Repair the root `README.md` -- both `skills:all` spans and the `lock`/`handover` paragraph
- [x] Repair the repo layer: Chris's, Derek's, Rendall's, Sylvester's and Nolan's lenses
- [x] Repair the live claims in the script comments that name the engine as a current reader

### TEST

- [x] Re-point `source-repo-guard.tests.ps1` off the deleted engine onto another shared script
- [x] Update `script-contract.tests.ps1` and `cut-release-guardrail.tests.ps1` for the dropped reader
- [x] `check-plugin-integrity.ps1` green -- especially `[skill-param]`, `[skill-list]` and the dead links
- [x] `check-script-contract.ps1` + `check-roster-sync.ps1` green
- [x] All suites in `scripts/tests/` green -- 51 of 52. `seam-lib.tests.ps1` is red on this console
      BEFORE this branch (verified by stashing and re-running on a clean tree) and green in CI: its
      refusal wraps mid-word at the console width. Filed as #982, not repaired here.

### DEPLOY: `fix/remove-lock-and-handover-v1`

Removed the `/lock` and `/handover` skills, and with them the one reporter both wrapped
(`scripts/task/session-status.ps1`, its plugin mirror and its 636-line suite) --
[#957](https://github.com/DaveKJohn/claude-code-specialists/issues/957), Dave: the branch's own
development cycle has taken over the job of recording where the work stands, so a gitignored lock file
records nothing the tree does not already say. Full removal was his call when the alternative
(re-homing the reporter under `/park`) was put to him.

The removal is not free-standing, and three gates said so: `[skill-param]` refuses a shared-scripts
registry entry naming a `SKILL.md` that does not exist, `[skill-list]` holds both marked spans in
`README.md` to the real skill set, and the dead-link scan catches the pages that linked the two skills.
So the registry entry, the two seam registrations naming the reporter as a reader, `.gitignore`'s
`.claude/handover.md` line, both cost baselines and every live claim about the script went with it.

**Two consequences, both accepted rather than papered over.** The park note keeps its writer and loses
its automatic printer: `git log -1 --pretty=%B origin/<branch>` is now the only way to read it, and every
doc and comment that promised the printout says so instead. And two pins that needed *a* reader, not that
particular one, were re-pointed at `build-release-notes-page.ps1` -- which reads the same note-root seam,
verified in the code rather than assumed.

**What deliberately stayed** is the history: `CHANGELOG.md`, the release notes, and the dated measurements
that merely record where a lesson was learned. A past-tense measurement does not become false when its
subject is deleted. Two portable lessons the deleted script *did* carry -- the `2>$null`-makes-`catch`-
unreachable trap and no-`return`-at-script-scope -- were kept and reframed, because neither is about the
file they were measured in.

Net always-on cost: the two skills were 380 tokens per session; Chris's lens grew by ~100 taking in the
briefing mode whose portable home was the `/handover` page, so every session is roughly 280 tokens lighter.

**Score:** 4

#### What makes this deploy extra special

N/A -- nothing here reaches a service subscriber. `/lock` and `/handover` were a session-management
convenience for whoever authors work in this repo and its consumers, never anything an end user of a
published product could see.

**Score:** N/A

#### Pull Request

Remove the /lock and /handover skills and their session-status reporter
