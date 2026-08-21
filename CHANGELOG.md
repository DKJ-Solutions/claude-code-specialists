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

## `docs/v4-18-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.18.0 release
document froze at **43m 55s** because three of its legs were still running on the file it was written into --
its own local gates, its CI and merge, and the publish. Those legs now have clock readings, so the total goes
in: **63m 33s** end to end, 19:09:35 to the Release published at 20:13:08, with the note's local gates and
push **4m 37s**, its CI and merge **14m 19s**, and the fold plus publish **42s**.

**Two of this release's readings invert what the previous six supported, and both are stated as mechanisms
rather than as numbers.**

- **The head is 58% of the release** -- 36m 37s of 63m 33s to the tag being pushed -- against 18% at v4.17.0
  and 21% to 32% across v4.12.0 through v4.16.0. Every earlier reading said most of a release happens after
  the version number exists. The reason this one says the opposite is that **a blocked cut moves work into the
  head**: the cut refused on a red test gate, and the 31m 50s of diagnosing and shipping that unrelated repair
  all fell before the tag, because nothing downstream could start until it merged. So the head/tail split
  measures where the obstacles were rather than where the effort inherently is.
- **The unmeasurable share is 31%**, against 65% at v4.17.0, 66% at v4.4.0 and 70% at v4.16.0. Same cause
  read from the other end: the tail a document cannot time about itself is roughly constant per release, so it
  looks small here only because the head was abnormally large.

**And the total is nearly double the previous longest for a reason that is not its size.** 24m 34s for
v4.15.0's thirteen entries, 25m 29s for v4.16.0's four, 32m 19s for v4.17.0's nine, 63m 33s for this one's
fifteen. The spread has never tracked the entry count and still does not. What made this release expensive is
that it needed **two** pull requests where a release normally needs one -- a repair before the cut, then the
note -- and therefore two full CI cycles. CI is the largest single cost in here at **23m 12s**, or **37%** of
the release.

**The first pass's reading about which check governs the merge is CORRECTED here rather than confirmed**, which
is the part of this branch worth more than the total. That pass had one data point -- the repair's pull request,
where the required `lint-en-tests` took 8m 37s against `claude-review`'s 3m 02s -- and concluded the ordering
had reversed from v4.17.0. This note's own pull request says the opposite: `claude-review` **14m 05s** against
`lint-en-tests`'s **9m 58s**. Across three readings the tally is **two to one** for the non-required check
governing the wait, so the direction of the evidence is the same as v4.17.0's after all, and the even split the
first pass implied was an artefact of measuring once. The unstable quantity turns out to be `claude-review`'s
own duration -- 3m 02s and 14m 05s on two pull requests forty minutes apart -- rather than the ordering, which
is a different question from the one that was being asked. Still named and not repaired: a check whose runtime
varies fourfold is the thing to understand before changing what a merge waits on.

The note's open section also gains the standing line that the attachment carries the frozen subtotal only and
is deliberately not swapped -- extended this time to say that the same second pass corrected a reading, so a
reader holding the attachment knows there are two reasons to prefer the page.

**Score:** 2

#### What makes this change extra special

It puts a fourth consecutive end-to-end measurement beside the first three, and this one is the first that
**breaks** the pattern the other three built rather than adding to it. A reader who saw only the four totals
would conclude that releases are getting slower as they get bigger; the measurement says the opposite, and
names the mechanism -- one blocked cut, two CI cycles instead of one.

For a consumer running this workflow the transferable part is a diagnostic they can apply without any of these
numbers: **when a release runs long, check whether it shipped one pull request or two before assuming the work
grew.** A release that had to repair something before it could cut pays for a whole extra CI cycle, and that
cost lands in the head, where the earlier readings had taught everyone not to look.

The correction is worth its own line for the same reason the first pass was: a timing is a count, and this one
was taken once. Publishing an even split off a single pull request and then finding the opposite on the next
one is precisely the recount discipline the house rules ask for, applied to a figure written an hour earlier by
the same hand.

**Score:** 2

### Pull Request · 20260821-223214

The v4.18.0 release note gains its end-to-end total

[PR #829](https://github.com/DaveKJohn/claude-code-specialists/pull/829)

---

## `docs/v4-18-0-release-note` deployment

### What does the change on this branch deploy to main?

The hand-written release document for v4.18.0. The cut drafts it from the tier-2 entries in the words their
authors wrote for a diff reviewer and commits it inside the tagged release commit; this is the rewrite for
somebody deciding whether to update, held against the seven tests in the `cut-release` skill. **1,100 draft
lines became 304**, which is the largest reduction this document has had to make -- v3.2.0's was 1,098 to 153,
but that draft still carried every category, and this one is fifteen tier-2 entries with nothing to discard.

**The ordering decision is the whole of the editorial work here, and it is a merge rather than a sort.** Four
of the fifteen entries are repairs to the same script -- the `team-shopify` pre-task sync -- filed and fixed
separately, scored 5, 5, 4 and 4. For a reader they are not four items: they are one script, one update, and
one dry run. So they open the page as a single section with the four repairs listed inside it, ordered by which
bites first, and the section says plainly that it is the one item in the release with a deadline. Presenting
them as four sections would have been faithful to the entry set and wrong for the reader, who would have had
to work out that all four resolve to the same command.

The remaining eleven are ordered by whether they carry an action, and the two that change what a consumer's own
tooling **refuses** are placed above the ones that only add a capability -- a cut that stops working and a push
that stops working are the two things somebody meets without asking for them. Three carry no action at all and
say so under their own heading rather than leaving it to be inferred (test 4).

Every mechanism the page tells a reader to invoke was read in the tree rather than carried over from an entry
body: `sync-main.ps1`'s `-DryRun` and the retired `-SkipPull`, `push-preview.ps1`'s four-step resolution,
`cut-release.ps1`'s `-Type`, `prune-merged.ps1`'s two proofs, and `Get-ShopifyPreviewUrls` being optional while
`Get-ShopifyLiveThemeId` is recommended here and required for the sync. That check is why the preview section
states the asymmetry between the two seams instead of repeating the sync's requirement.

Both organisational sections are written. *What it is worth* leads on the signature the four sync repairs share
-- no error, no warning, a green run -- and on the zero-false-positive/ten-of-eleven measurement that chose a
redesign over a fifth flag. *What was still open* is a snapshot with every figure read at its source: the
publication target at `84e6316` with all four team plugins at 4.16.0, now two releases behind, and all four
registered consumers one release behind as of this cut, read from `check-connectors.ps1` rather than from a
document.

**Score:** 2

#### What makes this change extra special

It is the one document a consumer reads to decide whether to update, and it reaches every one of them as an
attachment on this release's GitHub Release.

The item that earns the top of the page is the one where doing nothing is invisible until it has already
happened. Both Shopify consumers are running a sync measured to revert merged work, and one of them carries a
temporary hook routing its own sessions away from the shipped skill -- a workaround whose stated removal
condition is this release. The page gives them the three commands in the order that makes the dry run useful,
names what the sync now refuses to do at all, and says which flag is gone, so converging onto it does not read
as handing a script more authority than it has.

This page also carries the first timing pass, and this release's reading is unusual enough to be worth the
line: **73%** of the run went on a red test gate that had nothing to do with the release. That is the number a
later reader would otherwise have to reconstruct, and it is the kind that only exists if somebody starts the
clock before the first command.

**Score:** 3

### Pull Request · 20260821-221226

The v4.18.0 release note

[PR #828](https://github.com/DaveKJohn/claude-code-specialists/pull/828)

---

