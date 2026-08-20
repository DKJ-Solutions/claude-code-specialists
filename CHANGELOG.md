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

