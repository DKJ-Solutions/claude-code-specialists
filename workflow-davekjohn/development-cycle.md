# Development cycle: `docs/the-26-manuals-name-the-hook-too-v1` · 20260824-214016

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

Issue #878, round two of #875. The shared `laziness-automation` block has distinguished three forms of
automation since #877 -- a **hook** runs unasked, everything somebody invokes is a **script**, and every
script lives in a **skill** -- but each specialist's hand-written "is lazy" section still names a script
as the only answer.

Verified against the tree before starting: 26 manuals, 26 hand-written sections, and the word `hook`
occurs in **3** of the 26 files -- in none of them inside the lazy section itself. #878's recount (26,
not #875's 29) holds: 29 was 26 manuals plus the 4 personas #877 already did.

Not a sweep. Each section is about that specialist's own craft, so replacing 26 paragraphs with one
sentence would delete what makes a manual worth loading. Derek's lens (`.claude/specialists/lenses/05-05-extension.md`)
is deliberately out of scope -- it lists which scripts exist here, states no rule about form, and needs
nothing.

## CREATE

- [x] team-alpha, 15 manuals: state the three-way distinction in each specialist's own craft terms
- [x] team-ecomm (3), team-lifehub (5), team-shopify (3): the same, 11 manuals
- [x] Name a hook only where that craft would genuinely have one; said plainly for Marlowe and Auden, whose judging no harness can fire on
- [x] Keep every existing craft-specific detail -- 159 insertions against 14 deletions, and the 14 are rewrapped opening lines

## TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` green -- 0 errors across all 27 checks
- [x] All suites in `scripts/tests/` green -- 0 failing
- [x] Recount: the lazy section of all 26 manuals names the hook; it named it in 0 before

## DEPLOY: `docs/the-26-manuals-name-the-hook-too-v1`

**A specialist who never reads the word *hook* will never propose one.** The shared block has
distinguished three forms of automation since #877 -- a hook runs unasked, a script is invoked, and
every script lives in a skill -- but each of the 26 manuals still carried its own hand-written "is
lazy" section naming a script as the only answer. Measured before the work: `hook` appeared in the
lazy section of **0 of 26**. It now appears in all 26.

**Not a sweep, and the count says why.** 159 insertions against 14 deletions, and the 14 are rewrapped
opening lines rather than removed craft. Each section states the distinction in that specialist's own
terms: Tycho's suite is green because nobody looked, Ravi's duplication does not announce itself,
Onyx's orphan node is by definition the one nobody is watching, Sean's rejected product costs money
for every day it goes unnoticed. Sylvester got the hook named as **his own craft** -- every other
specialist who concludes "this must happen whether or not anyone remembers" is describing a file that
is his.

**Two manuals say plainly that a hook is the wrong form for them.** Marlowe judges whether a
conclusion survives contact with reality and Auden writes the argument; there is no event a harness
can fire on that means "somebody is about to believe this". #878 asked for the distinction in each
craft's terms *or* for it to be left alone where the existing text was already right -- saying which
of the three forms does not apply is the same answer, written down instead of left to the reader.

Derek's lens is deliberately untouched: it lists which scripts exist in this repo and states no rule
about form, so a sweep on its heading would have rewritten a correct paragraph. #878 flagged that, and
reading the section confirmed it.

**Score:** 2

### What makes this PR extra special

The manuals travel with the plugin, so this lands in every consuming repo at the next release. What
changes there is which automation gets proposed at all: the class of work that pays most -- a check
nobody invokes, because the failure it catches is silent by nature -- was the class no manual had
vocabulary for. A specialist that reaches for a script where a hook was needed builds something that
works exactly as long as somebody remembers to run it.

**Score:** 3

### Pull Request

Every specialist's manual names the hook, not just the script
