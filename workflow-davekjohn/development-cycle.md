# Development cycle: `feat/measure-the-always-on-document-path-v1` · 20260824-162809

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
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
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

## PLAN

**Where this came from.** Issue #861 asked for a `prune-claude` skill that judges an instruction
document block by block. A counter-report on that issue (August 24, 2026) argued it down and Dave
accepted the verdict: the skill would automate the **judgement**, which is one already-written
sentence, while carrying always-on cost into three consumer repos that do not have this repo's
condition. What is genuinely mechanical, repeated and unbuilt is the **measurement** — and it was
hand-run with `wc -c` and `awk` for the fourth time while writing that report.

**So this branch builds the measurement and nothing else.** No verdicts, no relocation, no judgement
about what should go. It answers one question: *what does the always-on document path cost right now,
and where does the mass sit?*

**The two rules it has to obey, both already written down elsewhere:**

- **It resolves the load path before reporting.** `SPECIALISTS.md` imports Chris's persona from the
  **marketplace clone**, not from the tree. Today that clone is 16,585 B against 21,860 B in the tree:
  5,275 B of queued always-on cost arriving at the next plugin update. The performance lens is explicit
  that this difference is not error to smooth away.
- **It states its own provenance.** `measure-skill` owns the authoritative figure by driving
  `claude plugin details`, and its rule is *do not estimate from file sizes*. That rule is about a
  subject the API prices; **it does not price documents**, so here a calibrated estimate is the only
  answer available. The script must therefore say, in its own output, that the token column is an
  estimate at a named factor and the byte column is the measurement. A number that looks authoritative
  and is not is the failure this repo has the most scar tissue from.

**The factor lives in code for the first time.** 3.12 chars/token was calibrated on August 15, 2026 over
10 skill pages (min 2.95, median 3.12, max 3.23) and exists only in prose in the performance lens — where
three separate notes record that it was inherited unexamined at 3.70 for three re-measurements, ~19% too
generous. Putting it in the lib with its provenance is the point: *a measurement in a document that
nothing regenerates goes stale silently.*

## CREATE

- [x] `scripts/lib/measure-context-lib.ps1`: resolve the always-on document set by following `CLAUDE.md`'s
      `@`-imports recursively (capped at the documented four hops); split a document into sections; hold the
      calibrated factor with its provenance in one place. **`Get-SeamPaths` turned out not to be reusable
      here** and was dropped from the plan: it returns the seam's fixed paths, while the walk has to follow
      whatever a document actually imports — reusing it would have hard-coded the very thing being measured.
- [x] `scripts/maintenance/measure-always-on.ps1`: the report — per document and per section, ranked by
      bytes, with each document's share; names the copy it measured and the tree/loaded divergence per
      plugin-sourced import; labels the token column an estimate at the named factor.
- [x] `scripts/README.md`: add the new script to the entry-points table.
- [x] `scripts/README.md`: add the **missing** `maintenance/measure-skill.ps1` row — found on this branch's
      own route. That table's preamble says everything not listed is "a lib, a generator or a test", and
      `measure-skill` is none of the three.
- [x] `scripts/README.md`: widen the `maintenance/` directory description, which reads "one-off repairs run
      by hand" and covers neither measurement script.
- [x] The performance lens (`06-25-extension.md`): record that the always-on figure is now regenerable, and
      the boundary the counter-report established — portable-first applies to **rules**, not to tooling that
      carries a per-session cost in every consumer.
- [~] Register the script in the shared-scripts mirror — **dropped, deliberately.** The counter-report's whole
      argument was that consumers do not have this repo's condition, and an unregistered script also carries
      no skill page, so a mirrored copy would be an undocumented file nobody can reach. Repo-local is the
      decision, not an omission.

## TEST

- [x] `scripts/tests/measure-always-on.tests.ps1`, fixture path carrying `$PID` per the suite convention:
      **47 asserts, 0 failures.** The walk follows a nested import, terminates on a cycle, counts a diamond's
      shared document once, caps at the hop budget and returns a dead import rather than skipping it; the
      section split sums exactly to the file length at two depths; a fence hides both a `#` and an `@`.
- [x] The formatting is pinned under **nl-NL**, following `measure-skill`'s own suite. Three asserts exist
      because the first draft got them wrong, and they are the reason this step was worth doing rather than
      assuming: `$home` is read-only (assigning threw while the built-in value returned the *right* answer),
      `if` is not an expression in a hashtable literal in PS 5.1, and `-eq` against an array filters instead
      of comparing — which reported two identical-looking values as different.
- [x] Run the script on this repo and check the total against the hand-count in the #861 counter-report:
      **71,690 B across four documents, matched exactly**, and the sections tile each file to the byte.
- [x] `check-plugin-integrity.ps1`: **0 errors**, with both new `.ps1` files inside `[script-ascii]`'s 161.
- [x] All 53 suites: **failed once, on `shared-scripts.tests.ps1`, and the catch was correct.** Its repo-wide
      guard found `git rev-parse --show-toplevel 2>$null` in the new script — under `EAP=Stop` that redirect
      wraps every stderr line in a terminating `NativeCommandError` even when git exits 0, so a redirect
      written to *silence* a failure would have killed the run on a warning. Replaced with a try/catch (the
      form that guard exonerates); `Invoke-NativeCapture` is deliberately not used there, because it lives in
      a lib under the repo root that this very line exists to locate. Suite green again at 437 asserts.
      **No new assert was added for it** — the repo-wide guard already owns that verdict, and two verdicts on
      one subject is worse than one.
- [x] The full suite re-run via `open-pr` before the push.

## DEPLOY: `feat/measure-the-always-on-document-path-v1`

**The always-on document path can now be measured by running something instead of by typing `wc -c`.**
`scripts/maintenance/measure-always-on.ps1` walks `CLAUDE.md` and everything it `@`-imports, and reports
each document and each section by bytes, share and estimated tokens.

That figure had been hand-produced four times (July 28, August 14, August 15 and August 24, 2026), and the
performance lens records the cost of that three separate times in its own words: *a measurement in a
document that nothing regenerates goes stale silently*. It did, in the most expensive way available — the
conversion factor was inherited unexamined at 3.70 through three re-measurements and was ~19% too
generous, so every token figure derived from it was under-stated while looking precise. The factor now
lives in `scripts/lib/measure-context-lib.ps1` with its calibration attached, where it cannot be inherited
by copying a table.

Four properties are enforced rather than remembered, each one a rule this repo already had:

- **Bytes are labelled a measurement and tokens an estimate, in the output itself.** `do not estimate from
  file sizes` governs the subject the `count_tokens` API prices; it does not price documents, so here an
  estimate is the only answer available and the honest move is to say so every time. The plugin listings
  stay `measure-skill`'s and the report says so instead of absorbing them.
- **The copy that LOADS is the copy reported.** The orchestrator persona is imported from the marketplace
  clone, so the report names it and prints the tree counterpart beside it — today 16,585 B loaded against
  21,860 B in the tree, i.e. 5,275 B of queued cost arriving at the next plugin update.
- **The sections must sum to the file or no table is printed**, because a plausible wrong share is worse
  than a refusal.
- **A dead `@`-import is reported rather than skipped.** It costs a session the whole document and nothing
  errors; no gate covers that class yet, which is now filed as #874.

It reaches **no verdict** about what should move, deliberately. That is the outcome of #861, where a skill
that would have judged an instruction document block by block was argued down and the verdict accepted: the
judgement is one already-written sentence, while a portable skill would have put always-on cost into three
consumer repos that do not share this repo's condition. The boundary that came out of it — `portable-first`
applies to rules, not to tooling that carries a per-session cost — is recorded in the performance lens.

Also on this branch, both found on its own route: `scripts/README.md` was missing a row for
`maintenance/measure-skill.ps1` in the table whose own preamble says everything unlisted is "a lib, a
generator or a test", and its `maintenance/` description ("one-off repairs run by hand") covered neither
measurement script.

**Score:** 3

### What makes this PR extra special

N/A — this reaches no consumer. The script is deliberately repo-local: it is not registered in the
shared-scripts mirror and carries no skill page, so nothing about it ships. That is the point rather than an
omission — the argument for building this instead of the skill #861 asked for was precisely that consumers do
not have this repo's condition, and putting the tool in the plugin anyway would have contradicted it.

**Score:** N/A

### Pull Request

The always-on document path is measured by a script instead of by hand

