## `docs/v4-11-0-release-note` changelog

### Branch title

The v4.11.0 release note

### Branch ID

20260815-153845

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this afternoon: the consumer section rewritten from
the cut's draft against the seven writing tests, and the two organisational sections no script can
generate.

**The migration item leads for a second release running, and the wording changed rather than being
copied.** A consumer updating from 4.8.0 or earlier straight to *4.11.0* is no more carried past
v4.9.0's two actions than one updating to 4.10.0 was, so the item stands -- but it now says so in those
terms and points at both intervening notes, because the reader arriving here has a longer gap to cross
than the reader of the previous note did. Test 3 orders by urgency rather than by which release a change
belongs to.

**The prompt inbox is written as what the reader can do, and the adoption command was verified against
the tree before it was printed.** `adopt-workflow-folder` is what places `workflow-davekjohn/prompts/`
(`scripts/task/adopt-workflow-folder.ps1`) and `/prompt` is a real skill in the plugin's `skills/`
directory -- both checked rather than inferred, which is the #566 rule applied to a document written to
be acted on. The untracked inbox is given as *what you are part-way through writing is yours*, not as a
`.gitignore` decision.

**The token calibration reaches a consumer as a specialist that behaves differently**, not as a
corrected figure. The 19% and the ~41,800 are this repo's numbers and stay in the lens; what a consumer
gets is Nolan naming which copy he read and how his conversion factor was arrived at. The miss is quoted
once, as the reason the rules exist, because a rule with its failure attached is the half a reader can
use.

**The release-craft move is offered as a method, because the saving demonstrably does not travel.** A
consumer's `CLAUDE.md` is their own file and nothing here edits it -- so the section says that first,
then gives the three transferable parts (separate decision from evidence, measure the block before
cutting it, move the prose verbatim). The 87% figure sits in *what it is worth* rather than in the
consumer section: it is a fact about how the split was decided here, which is test 2's line exactly.

**One entry got no heading of its own, for the second release running and for the same reason.** The
v4.10.0 timing total scored tier 2 at 2 with its author's reason ending *"nothing they do changes"*, and
its content is an internal cost measurement. It survives as one clause -- that the v4.10.0 notes ask
nothing of the reader -- under the migration item.

**`What was still open` names five items, and the first is again this document.** The end-to-end total
cannot exist while the words are being written; the merge that re-runs the tests the PR already proved
is named for the **fifth** release running; the two degraded specialists and the unpublished
organisation set are unchanged from v4.10.0; and the priced options from the token measurement are
recorded as not exhausted, with the next cut owing its own measurement rather than inheriting this one's
momentum.

**Step 0a's first pass is a subtotal of 5m 25s to the pushed tag**, against `v4.10.0`'s 5m 12s,
`v4.9.0`'s 5m 36s and `v4.8.0`'s 5m 02s -- the fourth consecutive head inside a thirty-five second band,
which is the 218s test gate being the floor. About 40 seconds of it blocked a person: reading the
assembled notes before the push, and naming the release.

### Significance

#### Tier 0

The release procedure's own record of what this cut cost, written while the head still exists -- that
half is unrecoverable afterwards, which is why step 0a splits into two passes at all. It also hands the
next person the legs to add and says where they go.

**Score:** 3

#### Tier 2

This is the only document in the release that tells a consumer whether they must act, and for anyone
updating from 4.8.0 or earlier the answer is still yes -- a required migration they would otherwise meet
as a session-start `[ERROR]` with nothing in this release explaining it. For everyone else it is the
plain statement that nothing is asked of them, plus the one thing they can newly do: write an assignment
in an editor rather than into a terminal.

**Score:** 4

### Pull Request
