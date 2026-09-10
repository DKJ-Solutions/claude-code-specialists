## fix/1775-connector-unregistered-plugin

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

#### The defect, verified against the tree before the branch was cut

`check-connectors.ps1` walks `foreach ($p in @($m.plugins))` -- the plugins a `connectors/<repo>.json`
manifest **lists**. A plugin that is enabled in the consumer's settings chain but absent from that
manifest is therefore never handed to the loop, and the run prints nothing whatsoever about it: not
`[ERROR]`, not `[INFO]`, not `[SKIP]`. The neighbouring case one level in -- a lens present in the
consumer but not registered -- already prints an `[INFO]` plus a non-counting `[INVENTORY]` line. The
plugin level had no equivalent.

#### Why the reason for leaving it standing has expired

The asymmetry was written down deliberately in `connectors/xoxowildhearts.json`'s 2026-08-21 note, on the
stated ground that the population was zero. It stopped being zero on 2026-09-08, when this repo enabled
every plugin in the marketplace without updating its own `connectors/claude-code-specialists.json`.

#### Scope: the checker, not the register

The register data is being corrected on the separate parked branch `fix/connector-record-catch-up`, which
did not touch the checker -- which is why #1775 exists as its own issue. Nothing under `connectors/*.json`
is edited here.

### CREATE

- [x] `check-connectors.ps1`: read this repo's own marketplace name once, via the already-dot-sourced
      `Get-MarketplacePath`, degrading to `''` (which switches the new check off) rather than guessing.
- [x] `check-connectors.ps1`: add check 5 after the per-plugin loop closes and connector scope is
      restored -- a counting `[INFO]` per unlisted id, plus one aggregated non-counting `[UNLISTED]` line
      under `Test-IsSessionRepo`, following the `[INVENTORY]`/`[NOT-INSTALLED-HERE]` doctrine exactly.
- [x] Scope the predicate to ids whose marketplace segment is this repo's own, ordinally: a third-party
      marketplace is not this register's business, and a **retired** id still counts, because the existing
      `retired` branch already treats that state as something the register should record.
- [x] `connector-sessioncheck.ps1`: the hook filters the child's output on a fixed bracket-token list, so
      `[UNLISTED]` is added to `$notices`, to the composite output branches, and given its own verdict.
- [x] `connectors/README.md`: document the new marker as the fourth named exception to the `[INFO]`
      silence, beside the three already written up there.
- [x] Update both docstrings -- the script's enumeration of checks 1-4 and its exit-code sentence, and
      the hook's "three exceptions" count. A count going stale reads as authority.

### TEST

- [x] `scripts/tests/connectors.tests.ps1`: nine script-level cases (unlisted id reported; the
      `[UNLISTED]` line present only in the session repo and the run still exit 0; a different marketplace,
      an id with no `@`, and an id whose `@` is its first character all silently excluded; a fully-listed
      manifest silent; a retired id still reported; no settings file at all stays silent) plus three
      hook-level cases via the existing `New-StubWorkshop` machinery.
- [x] Suites green: `connectors.tests.ps1` 179 -> 218 assertions, `connector-sessioncheck.tests.ps1`
      47 unchanged.
- [~] No cases added to `connector-sessioncheck.tests.ps1` -- dropped deliberately, not skipped. Every
      fixture in that file points `-WorkshopPathOverride` at a path that does not exist, forcing the
      no-source-checkout fallback, so no fixture there can reach the branch that emits `[UNLISTED]` at
      all. Its siblings `[INVENTORY]` and `[NOT-INSTALLED-HERE]` are tested next door for the same
      reason, and the coverage went there.
- [x] `check-plugin-integrity.ps1`: 0 errors.
- [x] Ran the check against this repo's real register and confirmed the finding by measurement rather
      than from the report: before the change exactly one of six enabled ids produced any line at all.
- [x] Review chain on the diff -- Victor, Edith and Sebastian in parallel. Sebastian found nothing;
      the eight findings from the other two are repaired, and the run against the real register is
      byte-for-byte what it was before the repairs, as a comment-and-coupling pass should be.
- [~] One review finding was NOT repaired here: `release-lib.ps1`'s own docstring sizes
      `entry-scaffold-lib.ps1` at three thousand lines where it measures 8,289. It pre-dates this
      branch and is the source the corrected citation was copied from, so it is filed as
      [#1779](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1779) rather than swept
      in here.

### DEPLOY: fix/1775-connector-unregistered-plugin

`check-connectors.ps1` no longer goes silent about a plugin that a consumer has **enabled** but that
consumer's `connectors/<repo>.json` does not **list**. Such a plugin was never handed to the per-plugin
loop, so nothing about it was checked -- not the extension inventory, not the machine version -- and
nothing was printed either, which made the register unauditable against the settings file it exists to
describe. A new check 5 reports each one as an `[INFO]`, and adds a non-counting `[UNLISTED]` line for
the repo the session is actually in, on the same terms and with the same `Test-IsSessionRepo` scoping as
`[INVENTORY]`. Only ids naming this repo's own marketplace are in scope; a retired id still counts,
because the register records what a consumer has.

Measured here before the change: of the six plugins this repo enables, exactly one produced a line --
the other five, one of them merely coinciding with a differently-named retired entry, were checked by
nothing and reported by nothing. The asymmetry had been written down as acceptable on the ground that
its population was zero; that stopped being true on September 8, 2026, and this is the repair rather
than a second note saying so.

**Score:** 3

#### What makes this deploy extra special

A consumer running `dkj-policy` gets the new verdict at session start through
`connector-sessioncheck.ps1`: where their own register entry is behind their own enabled set, the
session now says so in one line instead of saying nothing. It changes nothing that was working and
adds no failure -- the marker is non-counting, so it never turns a clean run red.

**Score:** 2

#### Pull Request

check-connectors reports a plugin enabled in a consumer but absent from its register
