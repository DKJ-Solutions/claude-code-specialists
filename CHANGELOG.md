# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections answering what a reader arrives with — what the change deploys to `main`, and the PR.
The first holds the change's two audiences, the second of them under `#### What makes this change extra
special`; the tier numbers live in the parser rather than in any heading. Entries written before
August 16, 2026 carry the longer set of headings that shape replaced, and every earlier shape is read
exactly as it always was. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier, each closing with its score. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## `docs/v4-17-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.17.0 release
document froze at a subtotal of **11m 12s** because three of its legs were still running on the file it was
written into -- its local gates, its CI and merge, and the publish. Those legs now have clock readings, so the
total goes in: **32m 19s** end to end, with the local gates and push **4m 03s**, CI and the merge **15m 22s**,
and the fold plus publish **40s**. There was no requester gap to separate out this time; the run was
continuous, so wall clock and working time are the same number.

**The reading worth the branch is which check governed the wait.** `lint-en-tests` is the only required check
on `main` and it passed in **9m 29s**. `claude-review` is not required and took **15m 09s**, and `ship-pr`
waits for every check rather than for the required one -- so the merge landed 15m 22s after the pull request
opened, and that single leg is **48%** of the release. Both figures were read from `gh pr checks` and the
ruleset rather than inferred from the wall clock.

**It is named and not repaired**, under the rule that a risk which has not bitten gets written down rather
than fixed. One measurement is not evidence for changing what the merge path waits on, and the same wait is
what a reviewer would want if the review were the point. It is recorded in the release document's open
section so the next release has something to compare against.

Two readings the first pass could not produce. The head came to **18%** of the total, the lowest of the six
releases timed so far (`v4.15.0` 21%, `v4.12.0` 24%, `v4.16.0` 26%, `v4.13.0` 30%, `v4.14.0` 32%) -- and the
reason is stated rather than left to read as an improvement: the head did not get faster, the tail got longer.
And the frozen subtotal was 65% short of the total, in line with 66% at `v4.4.0` and 70% at `v4.16.0`.

**Score:** 2

#### What makes this change extra special

It puts a third consecutive end-to-end measurement beside the first two, and this one complicates the
fixed-cost claim in a useful direction rather than confirming it: **24m 34s** for v4.15.0's thirteen entries,
**25m 29s** for v4.16.0's four, **32m 19s** for v4.17.0's nine. The spread still does not track the entry
count, which is the claim -- but the longest of the three is longest for a reason that has nothing to do with
its contents, and a reader who saw only the three totals would draw the wrong conclusion about batching.

For a consumer running this workflow, the transferable part is the diagnostic rather than the number: when a
release feels slow, check which check is governing the merge wait before assuming the work grew. The required
gate and the slowest gate are not necessarily the same one, and only the first is the one anybody chose.

**Score:** 2

### Pull Request · 20260820-200637

The v4.17.0 release note gains its end-to-end total

[PR #799](https://github.com/DaveKJohn/claude-code-specialists/pull/799)

---

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

### Pull Request · 20260820-194607

The v4.17.0 release note

[PR #798](https://github.com/DaveKJohn/claude-code-specialists/pull/798)

---

