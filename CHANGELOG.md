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

## `docs/v4-15-0-release-note` deployment

### What does the change on this branch deploy to main?

The hand-written release document for v4.15.0. The cut drafts it from the tier-2 entries in the words their
authors wrote for a diff reviewer, and commits it inside the tagged release commit; this is the rewrite for
somebody deciding whether to update, held against the seven tests in the `cut-release` skill.

Twelve of the release's thirteen entries reach tier 2, so the page is long by subject rather than by
indulgence. It is ordered by urgency rather than by branch: the three items carrying an action open the page
— seeding `Get-ShopifyLiveThemeId` for the live-theme guard, the three `team-shopify` subagents that named
one consumer's store, and deleting the retired `Get-ChangelogHeading` from an already-scaffolded
`repo-config.ps1` — and every remaining item says **no action needed** rather than leaving it to be inferred.

Both organisation sections are written: *what it is worth* leads on the guard, on why a permission deny list
structurally cannot do that job, and on the four separate changes that were all one defect — a shipped
document naming something that does not exist. *What was still open* is a snapshot rather than a claim about
the present, and it records the two guard reports that arrived before the cut and are not answered by it.

The timing is the first of the two passes step 0a asks for: **5m 12s** from clock start to the tag being
pushed, with the legs measured from timestamps. The total lands in its own small edit once the publish has
happened, because this document cannot time its own publication.

**Score:** 2

#### What makes this change extra special

It is the one document a consumer reads to decide whether to update, and it reaches every one of them as an
attachment on this release's GitHub Release.

Three items on the page carry an action and each says exactly what it is; the rest say plainly that there is
none. The first of the three is the one that earns the ordering: a consumer running `team-shopify` receives a
guard that reads as protection while its live-push rule is inert until they answer one seam — so the page
opens with the visible symptom (a standing `[ERROR]` at session start), states which rules do still hold so
it cannot read as "unprotected", and tells the two consumers who wrote their own guard that they are now
running two.

The page also carries the correction to a figure v4.14.0's own note left unexplained: the test gate read
**151s** here and **888s** earlier the same morning on the same commits, and the cause is that the earlier
reading was taken while the machine ran a full branch review. A count taken under load measures the load.

**Score:** 4

### Pull Request · 20260820-092020

The v4.15.0 release note

[PR #779](https://github.com/DaveKJohn/claude-code-specialists/pull/779)

---

