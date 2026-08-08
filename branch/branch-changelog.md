## `feat/config-blueprint` changelog

### Branch title

The source's release config becomes a blueprint a consumer can adopt

### Branch ID

20260808-192921

### Branch type

feat

### What does the change on this branch bring to main?

The workflow scripts are shared; the **answers** they read never were. `check-script-contract.ps1` has
always told a consumer which of the 22 repo-owned seam functions it is missing and what the shared script
falls back to -- and never what this repo chose, or why. So every consumer re-derived twenty values by
hand, or did not.

**The blueprint closes that.** `build-config-blueprint.ps1` derives an artefact from this repo's own libs
-- each seam function as its **source text**, comments and reasoning included -- and ships it in the
workflow plugin. `adopt-config.ps1` is the consumer's one command against it: it places what is safe to
place, proposes the rest, and never overwrites an answer somebody there already gave.

**Text rather than value, deliberately.** A value has to be serialized and rebuilt, which loses a
hashtable's shape and every comment above it -- and the comments are the half that is worth having, since
the blueprint's value to a consumer is the reasoning rather than the answer.

**The second axis (issue #456's only genuinely new design work).** Every record now declares whether the
source's value is safe to copy, and that is deliberately **not** the roster/workflow split of #522, which
classifies a function by which plugin reads it. `Get-ReleasePluginTier` is the proof they are different
questions: it sits squarely in the workflow half, so that split says it travels, and `$true` would tell a
storefront repo it publishes plugins. Twelve records are `copy`, ten are `decide`.

**A `decide` record is never written as a stub, and that is a mechanism rather than a courtesy.** A stub
returning a placeholder is *worse* than an absent function: absent means the shared script uses its
documented fallback, and `Get-ReleasePluginTier`'s fallback is computed from the tree and is usually
right. So the command cannot place them, rather than choosing not to.

**Six of the ten `decide` records were not on the issue's list**, which named four. That list answered the
neighbouring question -- which values a *script* cannot judge from outside -- so it never mentioned
`Get-RepoName`, whose copied value would point every `gh` call in the consumer at this repo.

**And two of them were classified `copy` first, until the repo overruled it.** Both `branch-info.ps1`
records looked like shared way-of-working. That file states the opposite about itself in its own comments
-- it "is repo-owned and does not travel", and its refusal of `chore/` is written down as this repo's rule,
phrased so it does not reach "a consumer who legitimately runs chore/ branches of their own". Copying
either would have imposed exactly what that sentence exists to prevent.

**Two extraction bugs, both found by reading the first generated artefact rather than by reasoning, both
now pinned by an assert:** a structural walk that stopped only at the previous `}` gave `Get-LiveStage` the
retirement note of a *different, deleted* function as its reasoning; and three of the four entry-wording
functions came out without the `$script:` value they read, which -- copied alone -- would have returned
`$null` in the consumer, a silent wrong answer where an absent function gets the documented fallback. The
reference scan that fixed the second runs through the PowerShell parser, after a text scan reported a
variable that a *comment* merely points at.

**Kept honest by a gate, because nothing in this repo reads the artefact.** Lint check 21 regenerates it
and compares; a stale one breaks nothing here and hands a consumer last week's answers under this week's
explanations. Regenerated rather than inspected -- the generator is the only thing that knows the answer,
so a second implementation could only disagree with it.

The contract registry moved to `scripts/lib/script-contract-lib.ps1` in the same movement: three things
read it now (the check, the generator, the suite), and a registry with two copies is how a new record
silently falls out of one of them.

**Two of the issue's six steps are deliberately not here.** Step 4 (create the missing `releases/` tiers)
was measured away rather than built -- `cut-release.ps1` and `new-internal-note.ps1` already create their
own note directories. Step 5 (migrating a sectioned `CHANGELOG.md` to flat) migrates a *document* rather
than the config, which is what this issue's title is about; it gets its own branch.

Plugins: specialists-workflow-davekjohn

### Significance

#### Tier 0

The registry gained a second axis and a third reader, and the repo gained a gate over an artefact nothing
else reads. A developer here has one new rule to know: a new contract record must declare its marker, and
the suite refuses one that does not.

**Score:** 3

#### Tier 1

The reasoning behind twenty seam values is now recorded as data next to each function rather than living
in whoever configured a consumer last. That is the half this project keeps losing -- issue #456 itself
expired three of its own load-bearing facts in four days.

**Score:** 3

#### Tier 2

A consumer adopting this workflow gets twelve values placed by one command and a written proposal for the
ten only they can answer, each with the reason it is theirs. Today that work is manual, undocumented, and
usually skipped. Not a 5: nothing breaks without it, and every proposed record has a working fallback.

**Score:** 4

### Pull Request

