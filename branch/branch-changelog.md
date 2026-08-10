## `fix/unrecognised-placeholder-is-silent` changelog

### Branch title

An unrecognised PR-template placeholder warns instead of losing the description

### Branch ID

20260810-120253

### Branch type

fix

### What does the change on this branch bring to main?

`open-pr.ps1` fills the PR body's description by comparing each template line, whole and exact, against
three known placeholder strings. A template one word away from one of them matched nothing, and there was
no check afterwards asking whether anything had matched at all: the description was never inserted, the
body came out structurally correct and empty exactly where it matters, and the run reported success. That
run now **warns** — naming the template, the strings it compared against, and
`Get-PrDescriptionPlaceholder` as the seam that overrides them.

Measured rather than supposed. `BWJ-ecommerce/smartwatchbanden` carried
`<!-- Beschrijf kort wat er verandert en waarom. -->` against the recognised
`<!-- Korte beschrijving van wat er verandert en waarom. -->`, and **12 of its last 60 merged PRs
(#217-#219, #233-#240) have no description at all**. Nothing reported it — not the script, not a gate, not
a review; it was found by diffing their template against this repo's, months later
([#573](https://github.com/DaveKJohn/claude-code-specialists/issues/573)).

**The asymmetry is what earns a warning.** A *missing* placeholder is caught by the first person who reads
the PR. A *near-miss* produces a body nobody looks at twice. That is the shape of the third seam this week
where a consumer answered a shared script wrongly and nothing failed — after `Get-BranchTypes` (a missing
function falling back to the canonical four) and `Get-ReleaseNotesGrouping`
([#560](https://github.com/DaveKJohn/claude-code-specialists/issues/560)).

**A warning, not a refusal.** The branch is sound, the entry is filled in and the PR is worth opening;
what is wrong is one line of a file this script does not own and a consumer may not be able to change
right now. And **no opt-out for a template that deliberately carries no placeholder**: an entry
description that reaches no PR body is the outcome this whole block exists to produce, so there is no
correct silent version of it — an exemption list is the shape this repo keeps getting bitten by.

`check-script-contract.ps1` cannot close this instead, and that is worth stating rather than leaving as an
open question: the seam function is **optional**, so a repo that does not define it is correct. The same
shape as `Get-BranchTypes`, where a missing function fell back to a wrong default and no gate said
anything.

**One lesson the branch paid for, kept in the test beside the assert that learned it:** the first CI run
was red while all 30 suites were green locally, on this change's own new assert. `Write-Warning` wraps its
text at the **host's buffer width** — wide in a developer console, narrow on the runner — so the identical
warning arrived as one line here and two there, and the phrase worth asserting landed exactly on the break.
Wrapping only ever replaces a space with a newline, so the asserts collapse whitespace before matching and
are now independent of a width nothing in this repo controls. Anything asserting on warning *text* has this
problem; asserting on a short token would have hidden it rather than solved it.

Alongside it, two statements about the same mechanism in the `open-pr` skill were repaired: both said the
description heading is read from the template's first `## ` line, which stopped being true on August 9,
2026 when the match was widened to any level — the promotion that would otherwise have silently switched
`-RefreshBody` off for a template starting at `#`.

Plugins: workflow-davekjohn

### Significance

#### Tier 0

The warning fires here too, but this repo's template and the built-in list are one file apart and have
never disagreed — so what it buys locally is the guarantee that they cannot start disagreeing unnoticed.

**Score:** 1

#### Tier 1

Names, for anyone working on the shared scripts, the failure mode all three of this week's seam defects
share: where a shared script reads a repo's answer and has a default, a wrong answer degrades quietly and
is found by accident months later. This is the cheapest possible instance of fixing that — the one path
that produces no output at all.

**Score:** 3

#### Tier 2

A consumer whose PR template has drifted learns it on the next PR instead of never. Twelve empty PR bodies
is the measured cost of not having it, and the fix on their side is one line — which the warning now names.

**Score:** 4

### Pull Request
