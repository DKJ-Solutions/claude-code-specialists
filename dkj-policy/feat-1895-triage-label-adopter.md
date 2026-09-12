## feat/1895-triage-label-adopter

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

Give dkj-policy a shared, print-only adopter for the canonical prio-1..prio-4 triage labels: a new Get-TriageLabels seam (Adopt=copy) in scripts/repo-config.ps1, a new contract record, and scripts/task/adopt-triage-labels.ps1 (mirrored into the plugin), which composes paste-ready gh label create commands for whatever this repo's tracker is missing and never runs them. Split from #1843, issue #1895.

### CREATE

- [x] `Get-TriageLabels` in `scripts/repo-config.ps1` -- the canonical `prio-1`..`prio-4` set (this
      repo's own live label colours/descriptions, read back via `gh label list`), with the WHY
      (copy vs. decide, and why this axis differs from `Get-BranchInfo`'s decide) in its docstring.
- [x] New contract record for `Get-TriageLabels` in `scripts/lib/script-contract-lib.ps1`,
      `Adopt = 'copy'`, `Optional = $true`, right beside the neighbouring `Get-ReachLabel` record.
- [x] New script `scripts/task/adopt-triage-labels.ps1`: read-only, no `-Apply` ever, composes a
      paste-ready `gh label create` per missing canonical label and reports `[ok]` for one that
      already exists (case-insensitive, no colour/description drift check -- out of scope per the
      issue). Registered in `scripts/lib/shared-scripts-lib.ps1` (`Skill = ''`, deliberately -- see
      that registration's own comment for why no skill page was added).
- [x] Mirrored to `plugins/dkj-policy/scripts/task/adopt-triage-labels.ps1` via
      `scripts/sync/build-shared-scripts.ps1`.
- [x] Regenerated `plugins/dkj-policy/blueprint/config-blueprint.json` via
      `scripts/sync/build-config-blueprint.ps1`.
- [x] Docs: one row in `plugins/dkj-policy/scripts/README.md`'s shared-scripts table, and one
      sentence in `plugins/dkj-policy/CONTRIBUTING-portable.md`'s labels section (no new skill, no
      new "Part" of `adopt-dkj-policy` -- out of scope per the issue).
- [x] Fixed two real bugs the new test suite caught while writing it (both PowerShell-array traps,
      not logic mistakes): an `-eq $triageLabels`/`-not $triageLabels` boolean-coercion trap on a
      single-element array under `Set-StrictMode`, and an `if/else`-as-expression assignment that
      silently unwraps a one-element array back to a bare object. Both fixed and explained inline.
- [x] Wired in the source-repo guard (`Assert-OwnCopy`) the script was missing -- caught by running
      the FULL `scripts/tests/*.tests.ps1` sweep, not by any suite scoped to this branch alone. Every
      person-invoked shared script carries it, exemptions are hook-only, and this script is neither --
      the header now distinguishes it clearly from the separate, content-specific
      `Test-IsWorkflowSourceRepo` refusal it correctly still does not need.
- [x] Review round (Victor, Edith, Sebastian, parallel on the diff). Sebastian's finding was real and
      blocking: the composed `gh label create` line quoted Name/Color/Description in bare `'...'`
      with no escaping, and `Get-TriageLabels` is `Adopt = 'copy'` and Optional -- free to be answered
      with a consumer's own free text, which test 6 already proved fully replaces the built-in four.
      An unescaped apostrophe ("won't wait", "team's convention") would close the quoting early the
      moment a person pasted the printed line, spilling the rest as separate shell tokens. Fixed with
      `Format-SingleQuotedArg` (doubles an embedded `'`, PowerShell's own escape for it) applied at the
      one composition site, plus test 6b exercising exactly that. Edith's finding was a missing
      possessive in the PLAN text above ("this repo tracker" -> "this repo's tracker"), fixed.

### TEST

- [x] `scripts/tests/repo-config.tests.ps1` -- `Get-TriageLabels`: four rungs, exact colours and
      descriptions held against this repo's own live labels.
- [x] `scripts/tests/script-contract.tests.ps1` -- the new record wired into the `$expectedContract`
      loop (it is a real registered shared script, unlike `Get-ReachLabel`'s skill-name attribution),
      the total record count bumped 38 -> 39, and a dedicated absent/present INFO-fallback scenario
      (6g), mirroring 6c/6d for the neighbouring seams.
- [x] New `scripts/tests/adopt-triage-labels.tests.ps1` (51 asserts): never applies (no `-Apply`
      param, no native `label create` call anywhere in the source), all-missing / all-present /
      partial / unreadable-payload arms, case-insensitive matching, the seam actually overriding the
      built-in fallback (not merely defined), mirror byte-identity, the two canonical copies
      (this script's fallback and `Get-TriageLabels`) held byte-for-byte identical, and the contract
      record's own shape.
- [x] Full repo-wide `scripts/tests/*.tests.ps1` sweep (all 100 suites), run twice: the first pass
      caught the missing source-repo guard above -- the ONLY failure across all 100 suites, everything
      else was already green -- and the second, after that fix, is green end to end: 0 of 100 suites
      failing.
- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors.

### DEPLOY: feat/1895-triage-label-adopter

`dkj-policy` shipped no machinery for the triage-priority label set this repo's own orchestrator
already prescribes on every issue (`prio-1`..`prio-4`) -- the scale existed only as prose in
`.claude/specialists/lenses/01-01-extension.md`, so any other dkj-policy consumer adopting the
convention had to retype four names and four colours by hand, with no gate to catch a typo before
`gh label create` refused it. `Get-MissingLabelNote` already established the precedent for this class
of problem on a PR label (compose the exact `gh label create` and stop, never substitute, never drop),
and `Get-ReachLabel` already established the precedent for sharing a label's SPELLING as a `copy`
seam across dkj-policy consumers. This closes the gap between the two for the priority axis: a new
`Get-TriageLabels` seam states the canonical four (`Adopt = 'copy'`, since the rungs are a shared
convention rather than a fact about the adopting repo -- unlike `Get-BranchInfo`, which is `decide`),
and a new print-only script, `adopt-triage-labels.ps1`, reads a repo's `gh label list` and prints a
paste-ready create command for whatever it is missing -- never creating one itself. Split from #1843
per its own red-team review; the three open questions it left (apply-or-print, is there a shared set,
where does it live) are answered by this branch: print, yes one set, and in its own seam rather than in
`branch-info.ps1`. This does not touch `#1686`'s BWJ-versus-source disjointness, or `#1841`/`#1870`'s
reach-label machinery -- it is the neighbouring axis, for ordinary dkj-policy consumers only.

**Score:** 2

#### What makes this deploy extra special

A dkj-policy consumer that has adopted the shared triage convention (or wants to) now has a single
command that tells them exactly which of the four canonical labels their tracker is missing and hands
them the paste-ready fix -- one command instead of four hand-typed ones, and no risk of a typo'd hex
colour or a `gh label create` failing after the fact. It never writes anything on its own.

**Score:** 2

#### Pull Request

Print-only adopter for the shared triage-priority labels

Resolves #1895.

`dkj-policy` prescribes the four `prio-1`..`prio-4` labels on every issue this repo files, but shipped
no machinery for a consumer to adopt them -- the scale was prose in one family's page, and creating a
label is a GitHub-side write nothing here should do silently. This gives the axis its own `copy` seam
(`Get-TriageLabels`, next to `Get-ReachLabel`) and a print-only adopter script,
`adopt-triage-labels.ps1`, that composes a paste-ready `gh label create` for whatever a repo's tracker
is missing and never runs it -- the same compose-and-stop shape `Get-MissingLabelNote` already
established for a PR label. Mirrored into the plugin, wired into the script contract and the
shared-scripts registry, with a new dedicated test suite plus additions to `repo-config.tests.ps1` and
`script-contract.tests.ps1`. Lint and the full test suite are green.

Not in scope, per the issue: `Get-BranchInfo`, the BWJ reach labels/buckets (#1686, #1841, #1870), any
colour/description drift detection on an existing label, and a new skill page or a fifth "Part" of
`adopt-dkj-policy` (documented instead via `plugins/dkj-policy/scripts/README.md` and one sentence in
`CONTRIBUTING-portable.md`).

