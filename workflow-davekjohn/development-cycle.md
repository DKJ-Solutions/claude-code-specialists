# Development cycle: `docs/cache-follows-refresh-not-push-v1` · 20260824-093423

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own.** It is the result, and the one part of this file that
> travels verbatim into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

Repoint CLAUDE.md's last-pushed promise at the mechanism that actually holds, and record the measured stale-cache instance plus the declined commit-comparison in the system-administration lens.

Repoint CLAUDE.md's last-pushed promise at the mechanism that actually holds, and record the measured stale-cache instance plus the declined commit-comparison in the system-administration lens.

## PLAN

- [x] Verify the report still stands: the cache is current right now (`97ac646b` = `main`), so the
      symptom is not reproducible -- but the detection gap is, and that is what was reported.
      `check-connectors.ps1:497-500` still compares version strings only.
- [x] Read what the script could compare instead before judging the proposal: it already reads the
      source sha (line 212, printed as `source read at <sha>`), so option 1 was cheap to build.
- [x] Judge it anyway, and decline it: the version verdicts are per CONSUMER checkout, and a
      consumer's clone is meant to follow the releases -- so between two cuts a commit comparison
      reports a gap on every consumer where nothing is wrong. Same shape as the stale-path check this
      repo declined at 124 findings all false.
- [x] Establish what the measured harm actually was: not a missing check but a false promise in
      `CLAUDE.md` -- the sentence that led to expecting otherwise on the day this was found.

## CREATE

- [x] Repoint the sentence in `CLAUDE.md` at the refresh, and say plainly that between releases no
      version check can tell you the clone is behind.
- [x] Record the instance, the declined option and the untested boundary in check 11's own measurement
      in `.claude/specialists/lenses/05-15-extension.md`.

## TEST

- [~] No suite: nothing executable changed. The claim the change makes about `check-connectors.ps1` is
      about behaviour that script's existing suites already pin, and a test asserting the wording of a
      doc sentence would break on every legitimate rewrite of it.

## DEPLOY: `docs/cache-follows-refresh-not-push-v1`

`CLAUDE.md` promised that a session here sees the **last pushed** version of the plugins. It does not: a
session reads the local marketplace clone, and that clone advances on `claude plugin marketplace update`
rather than on a push. Measured on August 23, 2026, after four PRs had merged and pushed, the clone still
stood on the previous day's commit while `/plugin` reported nothing to do and `check-connectors.ps1`
reported `[OK] machine record is on the source version` -- both compare version strings, and between two
releases the version is unchanged by definition, so a clone any number of commits behind `main` is
indistinguishable from a current one. The sentence now names the refresh and says that no version check
can tell you otherwise between releases. **Detection is deliberately left alone**, with the reasoning in
the lens: comparing commits would report a gap on every consumer between cuts, where following the
releases is the intended contract.

**Score:** 3

### What makes this deploy extra special

N/A -- both halves are about how this repo consumes its own plugin. A consumer's clone following the
releases is the intended contract for them, and nothing in their workflow changes.

**Score:** N/A

### Pull Request

The plugin cache follows a marketplace refresh, not a push
