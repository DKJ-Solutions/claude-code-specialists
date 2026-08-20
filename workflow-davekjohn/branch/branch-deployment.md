## `docs/v4-17-0-release-note` deployment

### What does the change on this branch deploy to main?

The hand-written release document for v4.17.0. The cut drafts it from the tier-2 entries in the words their
authors wrote for a diff reviewer and commits it inside the tagged release commit; this is the rewrite for
somebody deciding whether to update, held against the seven tests in the `cut-release` skill.

All nine of this release's entries reach tier 2, which is the largest set this document has had to order.
Five of them carry an action, so those five open the page -- the `team-shopify` pre-task sync first, since it
is the only item where the thing being replaced has already destroyed work in both repos that hand-wrote it.
The four that carry none say **no action needed** in as many words rather than leaving it to be inferred, and
the theme-delete marker gets the same treatment despite being a new capability, because doing nothing is a
complete answer to it.

Every mechanism the page instructs a reader to invoke was read in the tree before it was written down, not
carried over from the entry bodies: `adopt-shopify-floor`'s `-StoreDomain` and `-LiveThemeId`, `sync-main`'s
six seams and which two of them refuse to guess, `adopt-workflow-folder` as the placer of
`.github/workflows/branch-entry.yml`, and `Get-EntryGateExemptPrefixes` defaulting to `sync`. That check is
the reason the sync section names two required seams rather than the one the entry emphasises.

Both organisation sections are written. *What it is worth* leads on the distinction between the guard this
family shipped in v4.15.0 and the sync it ships now -- one prevents a bad act, the other prevents a good act
from silently reverting finished work -- and on the two-consumers-derived-the-same-artefact pattern appearing
for the second release running, this time with both consumers making the same mistake. *What was still open*
is a snapshot, with every figure read at its source: the organisation's publication target at `84e6316` with
all four team plugins at 4.16.0, and the registered consumer three releases behind, read from the session
check rather than from a document.

**Step 0a's baseline was taken before starting this time**, which the v4.16.0 record notes was missed, so this
page's timing legs are clock readings rather than reconstructions from file timestamps.

**Score:** 2

#### What makes this change extra special

It is the one document a consumer reads to decide whether to update, and it reaches every one of them as an
attachment on this release's GitHub Release.

The item that earns the top of the page is the one where the cost of doing nothing is invisible until it has
already happened. A `team-shopify` consumer who keeps their own sync keeps an implementation whose first
version destroyed work in both repos that wrote one, over a failure -- a deletion is also a touch -- that
produces no error and no warning, only quietly reverted files. The page gives them the command, names the two
seams the script refuses to guess, and states what it never does, so converging onto it does not read as
handing a script the authority to push.

The page also carries the correction the previous release could not: v4.16.0's Release was published one step
early and its attachment was the generated draft. This one follows the checklist's order, so what a reader
downloads is this document rather than the entry bodies.

**Score:** 3

### Pull Request

The v4.17.0 release note
