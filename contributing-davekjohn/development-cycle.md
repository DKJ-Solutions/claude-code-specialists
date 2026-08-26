## Development cycle: `feat/one-wording-merge-loop-v1` · 20260826-192130

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

Promote the duplicated defaults/override merge loop in `scripts/lib/entry-scaffold-lib.ps1` to one
helper, so the seam's fail-safe is stated once instead of twice
([#941](https://github.com/DaveKJohn/claude-code-specialists/issues/941)).

#### What the issue asked to be established first

Whether `scripts/sync/check-script-contract.ps1` enumerates these getters by name, and whether the
shipped config blueprint (`[config-blueprint]`, check 24) describes the loop rather than the contract.
**Neither does.** The contract registry carries the consumer-facing seams -- `Get-ReleaseNoteWording`,
`Get-InternalNoteWording` and the rest -- and names neither `Get-BranchFileWordingOverrides` nor
`Get-EntrySignificanceWordingOverrides`; the blueprint is generated from that registry, so it carries
them no more. The promotion therefore has **no doc half**: it is internal to one lib, and every seam
name a consumer has ever written stays exactly as it was.

#### And the recount, which changed the shape of the fix

The issue named **two** loops. The container walk inside them is shared by **three** -- `Get-EntryGuidance`
reads its override map the same way, thirty lines further up, including the PS 5.1 string-indexing note.
What it does **not** share is the verdict on the line below: there an empty value means *"this repo wants
no guidance"*, which `Get-EntryGuidance` documents as a legitimate answer, while the two wording getters
ignore it and keep their default. Folding all three behind one fail-safe would have made that documented
answer unreachable.

So the helper is split at exactly that seam -- `Get-OverrideMapValue` answers *what does the map say*
(shared by three), `Merge-WordingOverrides` answers *what counts as an answer* (shared by two). The
subject the issue measured is unchanged; only its size was one caller larger than the report knew.

### CREATE

- [x] `Get-OverrideMapValue` -- the container walk: hashtable / ordered dictionary / pscustomobject, with the PS 5.1 string-index pitfall stated once
- [x] `Merge-WordingOverrides` -- defaults + override command, with both fail-safes (the empty scalar, and #927's blank-only list) stated once
- [x] `Get-EntrySignificanceWording` and `Get-BranchFileWording` reduced to one call each
- [x] `Get-EntryGuidance` reads through the shared walk and keeps its own, opposite verdict
- [x] mirrored into the plugin copy via `scripts/sync/build-shared-scripts.ps1`

### TEST

- [x] `scripts/tests/entry-scaffold.tests.ps1` extended: the walk on its own, then the three rules run down **both** wording seams, then the guidance seam's opposite verdict
- [x] the whole suite green -- 522 asserts, up from 506
- [x] `check-plugin-integrity.ps1` green, 0 errors
- [x] every suite under `scripts/tests/` green

#### A regression the new tests caught in this very change

The first draft of `Get-OverrideMapValue` returned the value plainly. That is correct inline and wrong in
a function: PowerShell emits **nothing** for `return @()`, so the caller gets `$null` rather than an empty
array -- and a one-element array is **unrolled** to the bare element, so a consumer's single-item override
would have come back a string. The two loops this was promoted out of read the value inline and could
never meet either failure; the promotion is what created the risk. The guidance assert went red on the
first run and named it. Every return is comma-wrapped now, and a second assert pins the list shape.

Worth recording because it is the argument for writing the test **as part of** the promotion rather than
after it: a refactor whose whole claim is *"nothing changes"* is exactly the one where the suite has to be
able to disagree.

### DEPLOY: `feat/one-wording-merge-loop-v1`

Two getters in `entry-scaffold-lib.ps1` each merged a consumer's wording overrides over a defaults map,
and the loop was the same code line for line -- thirty-three hundred lines apart. Both are now three
lines over one shared helper, and the rule they enforce is written down once.

The cost of the duplicate was measured rather than predicted, which is why this is worth doing at all:
[#927](https://github.com/DaveKJohn/claude-code-specialists/issues/927) was a hole in one of those
fail-safes, and repairing it meant writing the identical guard into **both** loops. Noticing the second
one was luck -- the report named `StepPhases`, while `Route0` and `Route1` in the other map are
list-valued for exactly the same reason. A repair aimed at the reported key alone would have shipped with
the same bug one key over, in the same file.

`Get-EntryScaffoldWording`'s three separate getters are deliberately **not** touched: each of those is
read by a gate that must match the writer string-for-string, so each is its own contract. These two were
one mechanism copied, and that is the difference that makes them promotable.

**Score:** 3

#### What makes this deploy extra special

Nothing reaches the subscriber of this plugin. The seam names, the accepted container shapes and the
verdict for every possible override value are byte-identical to what shipped before; the 522 asserts are
what says so. A consumer's `repo-config.ps1` needs no edit and would not notice this release.

**Score:** N/A

#### Pull Request

One wording-merge loop, not two: the seam's fail-safe is stated once
