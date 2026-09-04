## feat/1421-merge-consumer-prose-checks

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

Merge check-retired-doc-name and check-supremacy-declaration into one hook plus one check script. Baseline measured against a consumer fixture with both defects present: 492 ms + 498 ms = 990 ms for the pair, over three passes.

#### The deferral reason was checked first, and it had expired

#1421 held the merge back on the ground that it renames a consumer-facing hook one release after
introducing it. Neither hook had ever been released: both landed after the `v4.29.0` tag and both sit in
`CHANGELOG.md`'s `[Unreleased]` section, so no consumer has ever received either name. Doing it before
the cut is strictly cheaper than doing it after, and the branch proceeds on that measurement rather than
on the issue's own framing.

### CREATE

- [x] `scripts/lint/check-consumer-prose.ps1` -- one preamble, one corpus walk, both detector functions,
      one report block each. Both always run: the first finding does not short-circuit the second.
- [x] `plugins/workflows/contributing-davekjohn/hooks/consumer-prose-sessioncheck.ps1` -- one hook, one
      row in `hooks.json` where there were two.
- [x] `shared-scripts-lib.ps1`: two registry entries folded into one, carrying both measurements.
- [x] `source-repo-guard.tests.ps1`: two guard exemptions folded into one, with the repair-versus-guard
      difference stated once instead of inherited by a copy.
- [x] The four superseded files and the two hooks removed; the mirror regenerated from the registry.
- [x] Docs: root `README.md`, the plugin `README.md`, `CONTRIBUTING-portable.md` (both slices are one
      hook and one pass now), and Sylvester's lens (the two bullets merged, the pre-merge per-hook
      figures kept as the baseline the saving is measured against).

### TEST

- [x] `scripts/tests/consumer-prose-gate.tests.ps1` -- the two suites folded into one. Every assert from
      both is preserved; the shared corpus is asserted ONCE, on its own, because it is the half both
      detectors read. **77 asserts, all passing.**
- [x] Eight new asserts the merge exists for: a tree with only the rename produces one block, a tree with
      only the inversion produces the other, a tree with BOTH produces exactly two `[ERROR]` markers from
      one invocation, the skip silences both at once, and the sanitizer is exercised in each block
      separately -- the retired-name one mixes consumer text with the plugin's own raw strings, the
      supremacy one is the consumer's end to end.
- [x] Lint gate green (`check-plugin-integrity.ps1`, 0 errors), script contract green, all 66 suites
      green in 102 s.
- [x] After-measurement, same fixture, same three-pass shape as the baseline: **541 / 527 / 530 ms**
      against **990 / 986 / 995 ms**, both blocks still reported.

### DEPLOY: feat/1421-merge-consumer-prose-checks

The two consumer-prose session checks are one check, one hook and one suite. They already shared their
corpus (`Get-ConsumerProseDocuments`) and nothing else, so the pair still paid two process launches, two
nested `powershell -File` spawns, two dot-sources of `entry-scaffold-lib.ps1` and `measure-context-lib.ps1`,
and two walks of the same ~8-document always-on closure -- at every session start, in every consumer.
`check-consumer-prose.ps1` walks it once and hands the same rows to both detectors, which stay two
functions with their own measurements and their own report blocks.

Measured on a consumer fixture carrying both defects, three passes each: **990 ms for the pair against
533 ms merged, a saving of ~457 ms of every session start** -- slightly above the ~350-450 ms the issue
inferred, which is worth recording because it was honest that no merged version had been built. For
scale, all 7 SessionStart hooks come to ~6.8 s on this machine, of which `connector-sessioncheck` alone
is ~4.9 s.

The rename the issue deferred over cost nothing: neither hook had ever been released, so
`consumer-prose-sessioncheck` is the first name a consumer ever sees.

**It overtakes two entries pending in this same block, and they are left exactly as they are.**
`feat/1389-retired-doc-name-check` announces *"`check-retired-doc-name.ps1` closes it, driven by a new
`retired-doc-name-sessioncheck` SessionStart hook"*, and `feat/1415-supremacy-declaration-check`
announces its own sibling beside it. Both were true on the day each branch merged, and both name files
this branch removed a day later. **The current statement is this one**: one script,
`check-consumer-prose.ps1`, and one hook, `consumer-prose-sessioncheck`, carrying both detectors. Nothing
either of those entries says about *what* is detected has changed -- only the count of scripts, hooks and
suites doing it.

**Score:** 3

#### What makes this deploy extra special

A consumer gets ~457 ms of every session start back and one hook where there were two, with nothing to
migrate -- the names being merged never shipped. The report is unchanged in substance: one block per
defect actually present, both when both are, and a run never stops at the first thing it finds.

**Score:** 3

#### Pull Request

One consumer-prose session check instead of two, walking the corpus once

