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

## `docs/v4-16-0-release-note` deployment

### What does the change on this branch deploy to main?

The hand-written release document for v4.16.0. The cut drafts it from the tier-2 entries in the words their
authors wrote for a diff reviewer and commits it inside the tagged release commit; this is the rewrite for
somebody deciding whether to update, held against the seven tests in the `cut-release` skill.

All four of this release's entries reach tier 2, and only one of them carries an action — so the page opens
with it and the other three say **no action needed** rather than leaving it to be inferred. The action item
is `team-shopify`'s new `adopt-shopify-floor` command, written with the dry-run call and the `-Apply` call
both shown, because the skill's own default is a dry run and a reader who copies one line should copy the
safe one. The `-LiveThemeId` paragraph states what happens in **both** directions — given, the guard's third
rule fires; omitted, the block lands commented out and the session check keeps reporting — since the whole
finding underneath that entry is that the omitted case must stay noisy.

Both organisation sections are written. *What it is worth* leads on the install path closing a gap that was
the default on install, on the two consumers who independently derived the same theme-check config, and on
the report that was right about the symptom and the cause and wrong about the lever. *What was still open* is
a snapshot rather than a claim about the present, and every figure in it was read at its source rather than
carried forward: the organisation's publication target at `9ea8dcf` with all four team plugins at 4.13.0,
read from their own `plugin.json` files, and the two Dutch settings layers confirmed English by reading the
repository settings and the label.

**Two things are recorded against this release rather than smoothed over.** The GitHub Release was published
in the same motion as the cut, one step ahead of the checklist, so its `notes-for-users` attachment is the
generated draft — the exact outcome step 5's ordering exists to prevent, and which the checklist names as the
first wrong idea that suggests itself. And step 0a's baseline was never noted, so the timing legs are
reconstructed from file and commit timestamps and are stated as the weaker evidence they are.

**Score:** 2

#### What makes this change extra special

It is the one document a consumer reads to decide whether to update, and it reaches every one of them as an
attachment on this release's GitHub Release.

The item that earns the top of the page is the one where doing nothing has a cost that does not announce
itself twice. A consumer who refreshed to v4.15.0 met a standing `[ERROR]` and a guard whose live-push rule
could not fire; this page gives them the command that closes it, says which rules were protecting them the
whole time so it cannot read as "you were unprotected", and tells the two consumers who wrote their own guard
that they are now running two of them.

The page is also the first in this series to carry a process failure of its own release in the section meant
for it, rather than in a chat message. Publishing early and skipping the baseline are both small, and both
are exactly the kind of thing a release record is for: the checklist already argued against publishing early
in advance, which makes this a measured instance of its own warning rather than a new lesson.

**Score:** 3

### Pull Request · 20260820-135458

The v4.16.0 release note

[PR #783](https://github.com/DaveKJohn/claude-code-specialists/pull/783)

---

