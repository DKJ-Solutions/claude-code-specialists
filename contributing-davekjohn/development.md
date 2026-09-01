## Development: `fix/shopify-cli-calls-not-bare-v1` · 20260901-121537

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

Route every Shopify CLI call in `team-shopify` through one wrapper that lowers
`$ErrorActionPreference` for the duration of the call, so the `$LASTEXITCODE` check below it is
actually reached — and add a lint check that refuses a bare call, because the dangerous form is the
*absence* of a wrapper rather than something a regex can spot. Closes
[#1183](https://github.com/DaveKJohn/claude-code-specialists/issues/1183).

#### What the report got right, and the two places the tree said something else

Verified against the tree before anything was written, per the inbound pickup rule:

1. **The symptom stands.** `scripts/task/sync-main.ps1` sets `$ErrorActionPreference = 'Stop'` and
   called the CLI bare, with the mirror-cleanup and the `The Shopify pull failed. Nothing was touched.`
   message sitting in the `if ($LASTEXITCODE -ne 0)` block below it. Exactly as reported.
2. **The size is four, not one.** The report scopes `sync-main.ps1`'s pull. `push-preview.ps1` has
   **three** more — the `theme list --json` lookup, the create-and-push, and the update push — and one
   of those three, the captured `theme list --json`, is the form the consumer actually confirmed
   breaking. So the report's own confirmed instance lives in a file it did not name.
3. **Capture-versus-uncapture is not the discriminator, which changes what "same class" means.** The
   report treats the uncaptured pull as weaker evidence and says it could not be reproduced. Reading
   the stack it quotes settles it: the `ErrorRecord` is raised at `shopify.ps1:24`, which is inside
   npm's generated PowerShell shim — on Windows `shopify` is not an `.exe` at all — and `& shopify`
   runs that script **in-process**, so it inherits the caller's preference variables. Measured here: a
   shim invoked from a script at `Stop` reports `$ErrorActionPreference = 'Stop'` inside itself. The
   frame that wraps stderr is one level in, so every call site is equally exposed and lowering the
   preference around the call is the only place the repair can go.

**What was NOT reproduced, stated rather than glossed.** No synthetic reproduction of the death
succeeded on this machine: the CLI here is 4.7.0 and emits no hint line, and a stub faithful to the npm
template does not wrap its child's stderr when driven from this harness. The evidence that it happens is
the consumer's stack trace; the evidence for *why* is the inherited preference above, which is
measurable and is what the suite pins.

#### Why not `Invoke-NativeCapture`, which was the first thing tried

It is already mirrored into `team-shopify` (inbound #1181, yesterday), and reusing it would have kept
the EAP dance in one place. Two things rule it out, and both are about shape rather than the dance:

* **It captures, and these calls have to stream.** `theme pull` and `theme push` run for minutes on a
  real theme and the CLI can stop to ask for authentication. Captured, that prompt is invisible and the
  run reads as still in progress — the same silent hang #1179 and #1181 exist to end.
* **Its bounded arm starts the child with `Start-Process`, which cannot run a `.ps1`.** So
  `-TimeoutSeconds` and `-Utf8` are unavailable to a Shopify call whatever else is decided.

`Invoke-SyncGitQuiet` in `sync-rules.ps1` is the precedent for a small purpose-built wrapper that
repeats the four-line dance because what it needs around the call differs.

### CREATE

- [x] `scripts/lib/shopify-cli-lib.ps1` — `Invoke-ShopifyCli`: EAP lowered for the call, restored in a
      `finally`, returns `Output` + `ExitCode`. Streams by default and tees into `Output`; `-Quiet`
      opts out of the echo, `-DiscardStderr` keeps the CLI's hint line out of a `--json` capture.
- [x] Registered `LibOnly` for `team-shopify` in `scripts/lib/shared-scripts-lib.ps1`, so it travels
      beside the two scripts that dot-source it, and regenerated the mirrors.
- [x] All four call sites routed through it, each keeping its own stream semantics: the pull and the
      update push stream, the `--json` list and the create capture.
- [x] Lint check 31 in `scripts/lint/check-plugin-integrity.ps1` — every `.ps1` in the tree parsed for
      a `CommandAst` named `shopify`. Through the parser, not by line matching, so a comment or a
      printed hint naming the CLI is not a subject.

### TEST

- [x] `scripts/tests/shopify-cli.tests.ps1` — 19 asserts against a `.ps1` stub on PATH shaped like
      npm's shim. The headline pair reads the preference back out of the stub: `Continue` through the
      wrapper, `Stop` when invoked bare. Plus the exit code surviving a call that also wrote to stderr,
      the preference restored on both paths, `-DiscardStderr` making a `--json` capture parse, the tee,
      and the wiring (no bare call left, both scripts dot-source it unguarded, the registry mirrors it).
- [x] Scenarios 51 and 52 in `scripts/tests/check-plugin-integrity-commands.tests.ps1` — a bare call is
      a finding that names its line, a comment and a printed hint are not, and the wrapper is exempt.
- [x] The guard was proven to FIRE, not only to pass: a bare call reintroduced into `push-preview.ps1`
      was reported at its line, and the tree restored.
- [x] Lint gate green (0 errors, `[shopify-cli] checked 167`); full test gate green, 57/57 suites.

#### What the review found, against the real CLI rather than the stub

Running the wrapper against the installed CLI 4.7.0 — `shopify theme pull` with no `--theme`, which it
refuses — surfaced the exit code correctly and showed a second defect the stub could not: one line of
the CLI's error box printed as the literal text `System.Management.Automation.RemoteException`. With
`2>&1` a stderr line arrives as an `ErrorRecord`, and for an **empty** line — which that box is full
of — `ToString()` has no message to defer to and returns the type name. It reached the console and
`Output` alike, so anything parsing the capture got it too. `Get-ShopifyLineText` now reads
`TargetObject` first, `Output` is `string[]` throughout, and the stub grew an empty stderr line so the
case is pinned. Fourteen lines in that box, thirteen correct, one type name.

#### The exemption list is two files, and the second one the gate found itself

The check reported `shopify-cli.tests.ps1:89` on its first full run — the assert that invokes the stub
bare on purpose, to prove the shim inherits `Stop`. Exempting it by name was the right answer rather
than dodging the parser: without that probe the neighbouring `Continue` assert proves nothing. Both
exemptions are matched on the file NAME, so a plugin mirror of either is exempt too.

### DEPLOY: `fix/shopify-cli-calls-not-bare-v1`

Every Shopify CLI call in `team-shopify` — the live-theme pull in `sync-main.ps1` and the three in
`push-preview.ps1` — was invoked bare under `$ErrorActionPreference = 'Stop'`. In Windows PowerShell 5.1
a single stderr line from the CLI is a **terminating** `ErrorRecord`, at exit code 0 as much as any
other, so the run died on the line *after* the call and the `$LASTEXITCODE` block below it never ran.
For the pull that block is the one that deletes the temp mirror and says `The Shopify pull failed.
Nothing was touched.` — so the failure mode was not a slower failure but a different one: a mirror left
behind and a message nobody saw. All four now go through `Invoke-ShopifyCli`
(`scripts/lib/shopify-cli-lib.ps1`), which lowers the preference for the duration of the call, restores
it in a `finally`, and hands back the exit code.

The half that makes it stick is lint check 31: every `.ps1` in the tree is parsed for a command named
`shopify`, and the two files allowed to hold one are named. **The dangerous form is the ABSENCE of a
wrapper** — there is no redirect to grep for and no suspicious flag, the wrong spelling is simply the
shorter one, which is how four bare sites accumulated without anyone noticing.

The part worth reading twice is where the `ErrorRecord` actually comes from. On Windows `shopify` is
npm's generated PowerShell shim, and `& shopify` runs it **in-process**, so it inherits the caller's
preference — measured, and pinned by the suite. That is why a `try/catch` at the call site would not
have fixed this, and why the report's distinction between its confirmed captured call and the
"not separately reproduced" uncaptured one does not hold: the frame that wraps stderr is one level in,
below both.

**Score:** 3

#### What makes this deploy extra special

A Shopify consumer running `team-shopify` gets this on their next update with nothing to configure, and
they are the only ones who can meet the failure — both scripts refuse to run in a repo that publishes
plugins. What changes for them is that a Shopify call that goes wrong now **reports itself**. The pull
that fails cleans up its mirror and says so; the preview push that fails says `Push failed.` instead of
ending on a `NativeCommandError` naming a file inside `AppData\Roaming\npm`.

It matters now rather than in the abstract because **the environment changed, not the code**: the CLI
writes a `claude-code-hint` line to stderr *while succeeding* when it runs under Claude Code. Nothing in
these scripts was wrong yesterday and nothing in them was edited to break — a bare native call is only
safe while the exe never writes to stderr, and that is not a property any calling script controls.

**Nothing to adopt and no flag to set**, and no behaviour changes on a successful run: the pull and the
preview push still stream their progress as they always did. The one visible difference is on failure,
which is the point.

**Score:** 3

#### Pull Request

the Shopify CLI is never invoked bare

