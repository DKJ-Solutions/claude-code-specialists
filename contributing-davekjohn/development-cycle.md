## Development cycle: `fix/changelog-seam-record-names-four-readers-v1` · 20260827-181900

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

Issue #983: new-branch.ps1 and open-pr.ps1 read Get-ChangelogPath since #967 but are absent from the record's Scripts list, so Write-ReachabilityGaps never walks them. Add both, amend Returns, update the matching asserts, mirror into the plugin. Also settle the Get-ReleaseNoteRoot side-note: check-plugin-integrity.ps1 reads it but is not a shared script, so it needs a sentence rather than a list entry.

### CREATE

- [x] Read #967 first, as issue #983 asks. It closed by giving the changelog seam two more readers and
      registering them against seam-lib in `shared-scripts-lib.ps1` -- with that comment ending *"which
      is why the list is kept current"*. Nothing anywhere records the contract record being left short
      on purpose, so this was an oversight rather than a decision, and the repair is to add them.
- [x] Add `new-branch` and `open-pr` to the `Get-ChangelogPath` record's `Scripts` in
      `scripts/lib/script-contract-lib.ps1`, and amend `Returns` to name four readers, why the two new
      ones read a seam whose file they never touch, and what the short list cost.
- [x] Settle the `Get-ReleaseNoteRoot` side-note the issue raises in the same pass. It goes in prose,
      not in `Scripts`: `check-plugin-integrity.ps1` is a repo-local gate, so `Resolve-SharedScriptPath`
      finds it in the source and finds nothing in a consumer -- listing it would report a reachability
      gap that exists in one repo only.
- [x] Mirror into the plugin (`build-shared-scripts.ps1`) and regenerate the shipped config blueprint
      (`build-config-blueprint.ps1`), which is what a consumer is actually handed.
- [x] Pin the record in the contract drift guard, which is the part the issue could not see from the
      outside -- see TEST.

### TEST

- [x] The assert issue #983 points at does not exist. It says to update *"the matching assert in
      `scripts/tests/script-contract.tests.ps1:~560`"*, and there is none: `Get-ChangelogPath` was
      declared in the lib and absent from `$expectedContract` entirely. That absence is the mechanism --
      the loop asserts each pinned record is *"required by exactly {...}"*, so an unpinned record's
      reader list can go stale in silence, which is precisely what happened. The observation was right
      and the proposed lever was not there; the row is added rather than an assert edited.
- [x] `script-contract.tests.ps1`: 293 pass, 0 fail, including four new asserts proving each of the four
      named scripts really references the seam in its own source rather than being a stale entry.
- [x] The suite was run BEFORE the pin as well (282 pass, 0 fail) to check the issue's other prediction
      -- that adding two readers would move the reachability counts. It does not:
      `Resolve-SharedScriptPath` resolves against the scripts tree its own lib sits in, so in this repo
      both scripts are the source's own and both reach `seam-lib`. No `[INFO]` count moved.
- [x] The full gate (`check-plugin-integrity.ps1` + all 52 suites) via `open-pr`.

### DEPLOY: `fix/changelog-seam-record-names-four-readers-v1`

The `Get-ChangelogPath` contract record named two readers and four scripts read it. `cut-release` and
`fold-changelog-entry` were named; `new-branch` and `open-pr` were not, having become readers with
inbound #967 -- neither touches the file, and both need the DIRECTORY it names, because that is the base
an entry's relative links resolve from once the entry folds into it. What the gap cost is not
bookkeeping: `Write-ReachabilityGaps` walks only the scripts a record names, so a consumer defining this
seam somewhere `new-branch` or `open-pr` could not see it ran on the computed fallback instead of their
answer, silently, with the check reporting nothing because it never looked there. Both are named now, in
the record and in the shipped config blueprint a consumer is handed.

**Score:** 3

#### What makes this deploy extra special

**The record is now PINNED by the drift guard, and that is the half the report could not see.** It asked
for an existing assert to be updated; there was none. `Get-ChangelogPath` was declared in the lib and
absent from `$expectedContract` altogether -- so the loop that asserts every pinned record is *required
by exactly* its named scripts had nothing to say about this one, and its reader list could go stale
without a single test turning red. That is the mechanism behind the defect rather than a side-effect of
it, so the row is what actually stops the next recurrence. Four new asserts come with it, each proving
one named script really references the seam in its own source.

**One reader is deliberately NOT in a list, and says so in prose instead.**
`scripts/lint/check-plugin-integrity.ps1` reads `Get-ReleaseNoteRoot` to decide which hand-written tree
its release-document tier check walks, and it is a repo-local gate rather than a shared script.
`Resolve-SharedScriptPath` searches the scripts tree its own lib sits in, so naming it would resolve in
the source and resolve to nothing in a consumer -- a reachability gap reported in one repo and invisible
in every other. The record carries a sentence for it, so repointing that seam is still known to move
that gate's scope here.

**Score:** 3

#### Pull Request

the Get-ChangelogPath contract record names all four of its readers

Plugins: contributing-davekjohn