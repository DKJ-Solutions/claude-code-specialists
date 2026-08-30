## Development: `fix/named-gate-entry-point-v1` · 20260830-180522

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

Issue #1156. `cut-release`'s step 4 — the release-notes commit, made standing on `main` under the third
direct-on-`main` exception — closes with *"run the repo's lint and test gates before this commit, exactly as
`open-pr` would have run them for you"*. `open-pr.ps1` refuses on `main` at line 314, six hundred lines above
the gates it runs at 978. The rule is right; the route is closed at the point it is given.

#### Why candidate repair 1 was declined

The issue offered two: name the two commands in prose, or give the test gate a named entry point. Repair 1
looks cheapest and ships a **wrong** invocation on both halves, which is what settled it. The working
invocation recorded in the issue dot-sources `native-capture-lib.ps1` and nothing else, so
`Get-TestCommands` is never in scope — a consumer whose suites are not all PowerShell has the rest of them
skipped **silently**, which is the exact failure inbound #644 was filed about and the one that lib's own
docblock warns `ci.yml` about by name. And the lint half in prose hardcodes `check-plugin-integrity.ps1`
instead of reading the consumer's `Get-LintScript`. A gate reachable only by rebuilding it is a gate whose
weakest invocation is the one that gets used.

#### And why the entry point is a flag rather than a new script

The issue costed repair 2 at "a shared-script registry entry and a mirror". `-GatesOnly` on `open-pr.ps1`
pays neither: the script is already registered, already mirrored, already documented by a skill. It also
keeps step 4's original sentence true instead of replacing a good rule with prose — the gates a trunk commit
runs are now literally the gates the PR would have run, because they are the same function.

### CREATE

- [x] `Invoke-WorkflowGates` in `scripts/lib/gate-lib.ps1`: the lint gate, the test gate, the dirty-tree
      warning, the evidence consult/record and the four movement notes, moved out of `open-pr.ps1` whole.
      Returns `True`/`False` rather than calling `exit` — what a red costs belongs to the caller, and
      the two callers differ, so the consequence phrase is a parameter.
- [x] `-GatesOnly` on `open-pr.ps1`, placed after both pre-flights and **before** the branch check. That
      placement is the fix; a block after that check is unreachable from the trunk, which is the defect.
- [x] The PR path's inline block replaced by one call, so the two routes cannot describe the same tree
      differently.
- [x] `cut-release` step 4 and the `open-pr` skill page name the command; `CONTRIBUTING.md` Â§4.6 carried
      the same gap (*"the gates still run"*, no route named) and was repaired with it.
- [x] Plugin mirrors regenerated (`build-shared-scripts.ps1`).

### TEST

- [x] Both edited scripts parse clean.
- [x] `-GatesOnly` routing smoke-tested on a branch (`-SkipLint -SkipTests` — exit 0, nothing pushed).
- [x] **And on a branch literally named `main`**, which is the case the issue is about: a throwaway clone
      carrying this work as `main`, run with `-GatesOnly -SkipLint -SkipTests`, reached the gates and exited 0 —
      while the SAME tree without the flag still refused with *"You are on main; a PR is created from a
      branch."* and exited 1. The route opens without the refusal weakening, which is the property worth
      proving: a flag that reaches the gates by disarming the trunk guard would be a different change.
- [x] `gate-lib.tests.ps1` extended: the structural cases that introspected `open-pr.ps1` retargeted at the
      extracted function, the ordering property (`-GatesOnly` before the `main` refusal) asserted, and
      behavioural coverage of `Invoke-WorkflowGates` against a real git fixture.
- [x] Lint gate and all suites green.

### DEPLOY: `fix/named-gate-entry-point-v1`

`open-pr.ps1` gains **`-GatesOnly`**: run this repo's lint gate and every test suite against the working
tree, and stop there — no branch check, no push, no PR. It exists for the commits that are made on the
trunk. Three changes land directly on `main` under named exceptions, and the release-notes commit is the one
typed by hand: `cut-release`'s step 4 told its reader to run the gates *"exactly as `open-pr` would have run
them for you"*, and `open-pr` refuses on `main` six hundred lines before it reaches a gate. The rule was
right and the route was closed.

**What that cost is not the missing flag but the invocation that replaces it.** With no named entry point the
reader assembles one, it goes green, and it is quietly missing two things: `Get-TestCommands` is out of
scope, so a repo whose suites are not all PowerShell has the rest of them skipped **without a word**, and the
lint half gets a hardcoded script rather than the repo's own `Get-LintScript`. Both bite a consumer harder
than they bite here.

Mechanically, the gate block moved out of `open-pr.ps1` into `Invoke-WorkflowGates` in
[`scripts/lib/gate-lib.ps1`](../scripts/lib/gate-lib.ps1), and both routes now call it — the flag's whole
value is that the two **cannot** reach a different verdict about the same tree. It is not an escape valve: it
adds a place the gates can run and removes none, `-SkipLint`/`-SkipTests` still mean what they always
meant, and a green run records gate evidence like any other. `cut-release`'s step 4, the `open-pr` skill
page and [`CONTRIBUTING.md`](CONTRIBUTING.md) Â§4.6 — which carried the same gap in different words — all
name the command now.

**Score:** 3

#### What makes this deploy extra special

A consumer meets this harder than the source repo does: their `scripts/tests` may hold a different set,
`Get-TestCommands` may add commands an ad-hoc call never runs, and they have no #1033 in their history to
warn them off the in-process shape. They receive both the flag and the pages that name it through the plugin
update, so the documented route arrives with the capability rather than after it.

**Score:** 3

#### Pull Request

A named entry point for the gates, so a direct-on-main commit can run them

