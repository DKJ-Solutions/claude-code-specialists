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

### Pull Request

The v4.18.0 release note
