## Development: `fix/blueprint-record-carries-only-its-own-value-v1` · 20260830-104253

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

The config blueprint generator over-collected: the first function under a shared assignment block shipped all four of that block's values, so a consumer's placed repo-config.ps1 assigned three variables twice -- silently overriding a translation. Inbound #1126.

#### What the report got right, and the one thing it did not

Verified against the tree before anything was built. The symptom stands exactly as filed, and the
blueprint-wide measurement reproduces: three variables assigned by two records each, and
`Get-EntryTitlePlaceholder` the only record declaring a sibling's value.

**Its proposed repair names the wrong file.** The issue asks for the `text` of that record in
`blueprint/config-blueprint.json` to be trimmed. That artefact is DERIVED -- its own `note` field says
so, and `check-plugin-integrity.ps1` regenerates it and reports any difference -- so a hand-trim would
be reverted by the next `build-config-blueprint.ps1` run and would fail the lint gate before that. The
repair therefore lands in the generator, and the artefact follows from it.

The issue's open question needed no answer: it had already picked the smaller of its two options
(keep the shared comment block in the title record, move the three stray assignments out), and that is
what the generator now produces.

### CREATE

- [x] `Get-FunctionBlock` trims its walk back to the values the function itself reads. The contiguous
      walk that gives a function its comment block and its value is correct for a function with its own
      assignment directly above it, and over-inclusive for the FIRST of several sharing one block. The
      trim asks the function's OWN AST rather than the assembled block: to the parser an assignment
      target is a `VariableExpressionAst` exactly like a read, so a scan of the whole block cannot tell
      "this function uses this value" from "this line happens to sit above it".
- [x] Takes the `FunctionDefinitionAst` instead of two line numbers -- `Get-LibFunctions` had already
      parsed the node the trim needs, so nothing re-parses and there is no fragment-does-not-parse
      branch in which every value would be dropped.
- [x] `Get-StatementEndIndex` extracted: the bracket-balance walk was already in
      `Get-ScriptVarAssignment` and the new `Remove-ForeignAssignments` needs the same one.
- [x] Artefact regenerated. One record changed, three lines removed, nothing else moved -- the whole
      diff is those three assignments.

### TEST

- [x] `scripts/tests/config-blueprint.tests.ps1`: extraction bug 3 added as the mirror of bug 2 --
      per-record (a record carries no value its function never reads), cross-record (no variable is
      assigned by more than one record), and end-to-end on the file `adopt-config` actually writes
      (each of the four assigned exactly once).
- [x] The reads are taken from the function alone, not from the existing `Get-ReadVars` over the whole
      record. Written the obvious way first, the per-record assert was TAUTOLOGICAL -- every assignment
      counted as its own justification -- and passed against the unrepaired artefact. Caught by running
      the new asserts against the old generator rather than by reading them.
- [x] Both directions measured: 7 asserts fail on the pre-fix generator and artefact, 178 pass 0 fail
      on the repaired ones.
- [x] Lint gate and the full suite run.

### DEPLOY: `fix/blueprint-record-carries-only-its-own-value-v1`

The config blueprint's generator handed the first function under a shared assignment block every value
in that block, while each of the block's other functions already shipped its own. Three variables
therefore arrived in a consumer's `scripts/repo-config.ps1` assigned twice, the second assignment
silently winning. `Get-FunctionBlock` now trims its walk back to the values the function itself reads,
asked of that function's own AST rather than of the assembled text -- where an assignment target is
indistinguishable from a read.

Nothing errored and a fresh adoption behaved correctly, because the duplicate values agreed. The cost
lands on the next reader: these four strings are the entry-scaffold wording, and they exist to be
translated (#410). A consumer editing them under the comment that explains them would have had an
assignment three lines further down -- one they had no reason to read past -- put the English back,
after which `new-branch` writes English stubs and `open-pr`'s body-heading gate goes on recognising
only the English marker, with nothing anywhere saying why.

**Score:** 3

#### What makes this deploy extra special

It is only visible in a file `adopt-config` has written. The source repo's own `repo-config.ps1`
assigns each of these variables exactly once, so no amount of reading this tree shows the defect --
which is why the regression test asserts on the placed consumer lib and not only on the artefact.

The measurement that mattered was not the fix but the test: the natural way to write the per-record
assert passes against the broken artefact, because the parser cannot distinguish an assignment target
from a read. Running the new asserts against the old generator is what caught it.

**Score:** N/A

#### Pull Request

a blueprint record carries only the values its own function reads
