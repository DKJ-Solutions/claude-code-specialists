## fix/sync-main-3b-offline-dryrun

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

Inbound #1373. `sync-main.ps1`'s `[3b/6]` standing-predecessor guard runs
`git ls-remote --heads origin` through `Invoke-NativeCapture` (inbound #1181) and
`exit 1`s whenever `origin` cannot be listed -- with no `-DryRun` carve-out. That
defeats the offline `-MirrorPath` rehearsal path the `.PARAMETER MirrorPath`
docstring promises: `-DryRun -MirrorPath <dir> -RootOverride <dir>` against a
checkout with no reachable `origin` stops at `[3b]` before printing any verdict.

The guard's own design already waives its *refusal* for `-DryRun` (a dry run
writes and pushes nothing, so an unnoticed standing predecessor causes no harm).
The `ls-remote` hard-exit added by #1181 is the one spot at `[3b]` that is
stricter than that. #1181's intent -- never read an unprovable `origin` as "no
predecessor" on a run that pushes -- is fully served by keeping the hard refusal
on non-`-DryRun` runs.

Fix: on `-DryRun`, an unreadable `ls-remote` prints an explicit "could not check,
skipped for this dry run" note (never "none on origin", which is the false
negative #1181 closed) and continues to the verdict. Non-`-DryRun` is unchanged.
Scoped out, deliberately: the `fetch` and `gh pr list` failure branches lower in
`[3b]` -- both are only reachable once `ls-remote` has *succeeded*, i.e. `origin`
was reachable, so #1181's loud refusal is right there.

### CREATE

- [x] `[Sylvester]` `plugins/teams/team-shopify/scripts/task/sync-main.ps1`: at
  `[3b/6]`, the `ls-remote`-failure block gains a `$DryRun` branch that sets
  `$lsRemoteUnknown = $true`, prints the softer note and falls through (skipping
  the candidates/fetch/merged-PR block); the `# BOUNDED ...` comment and the
  "A DRY RUN IS EXEMPT" header paragraph record the carve-out.
- [x] `[Sylvester]` `scripts/task/sync-main.ps1`: the byte-identical same edit.
- [x] `[Sylvester]` two copies byte-identical (`diff`), ASCII-clean, parse OK,
  `build-shared-scripts.ps1 -Check` in sync.

### TEST

- [x] `[Tycho]` `scripts/tests/sync-main.tests.ps1`, the `net/ls-remote` block:
  a `-DryRun` against an unreachable `origin` now exits 0, still `-notmatch
  'none on origin'`, names the skipped check, reaches `[5/6]` and the DRY RUN
  summary; a real run against the same origin still refuses; static asserts pin
  the non-`-DryRun` refusal message + `exit 1` and the distinct dry-run flag.
- [x] `[Tycho]` `scripts/tests/sync-main.tests.ps1` -> OK 118/118;
  `sync-rules.tests.ps1` OK 111; full `scripts/tests/*.tests.ps1` sweep exit 0,
  no failures; `check-plugin-integrity.ps1` 0 errors.
- [x] `[Victor + Edith + Sebastian + Marlowe]` reviewed the diff: no blocking
  findings. Victor -- one nit (the comment-only `if ($lsRemoteUnknown)` arm),
  kept with its explanatory comment. Edith -- "shut" -> "closed" for house-style
  consistency, applied. Sebastian -- none; the softening is `-DryRun`-only and a
  dry run mutates nothing, so #1181's pushing-run threat model is untouched.
  Marlowe -- conclusion survives; fix restores a documented capability rather
  than documenting its loss, and the degraded dry run says so plainly.

### DEPLOY: fix/sync-main-3b-offline-dryrun

The documented offline `-MirrorPath` rehearsal of the pre-task sync works again:
`[3b]` no longer hard-exits a dry run when `origin` cannot be reached. A real
(pushing) run still refuses there, exactly as inbound #1181 built it.

**Score:** 2 -- restores a rehearsal path the plugin's own docstring promises but
`[3b]` had closed; noticed by a maintainer who runs the sync offline against a
mirror, and prevents a consumer working around it in their own test fixture.

#### What makes this deploy extra special

N/A -- team-shopify tooling internals. No subscriber of any consuming service
notices whether the offline dry run stops at `[3b]` or prints its verdict.

**Score:** N/A

#### Pull Request

the sync's [3b] step lets a dry run continue when origin cannot be reached

