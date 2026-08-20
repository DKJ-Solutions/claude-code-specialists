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

## `docs/v4-16-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.16.0 release
document froze at a subtotal of **7m 36s** because four of its legs were still running on the file it was
written into — writing the page itself, its local gates, its CI and merge, and the fold. Those legs now have
timestamps, so the total goes in: **25m 29s** of working time, with writing the page **5m 45s**, the local
gates and push **2m 57s**, CI and the merge **9m 07s**, and the fold **4s**.

**The reading that needed a decision rather than a subtraction is the 58m 53s between the published Release
and the start of the page.** That is the requester deciding to ask for the document, not the procedure
running. Folded into the total it would report **1h 24m 22s** for work that took twenty-five minutes, and
every comparison with another release would break. So it is stated beside the total rather than inside it,
and the wall-clock span is given once so the number is not lost.

Two readings the first pass could not produce. The head came to **26%** of the working total, a fifth reading
for the claim that most of a release happens after the version number exists (`v4.15.0` 21%, `v4.12.0` 24%,
`v4.13.0` 30%, `v4.14.0` 32%). And the two heaviest legs are **58%** between them, of which only the writing
is a person's time.

**Score:** 2

#### What makes this change extra special

It puts a second consecutive end-to-end measurement beside the first, and the pair is what makes the
fixed-cost claim concrete: **24m 34s** for v4.15.0's thirteen entries against **25m 29s** for v4.16.0's four.
A release costs what it costs per *event*, not per change — which is an argument for cutting when there is
something to ship rather than for batching until there is a lot.

The separated requester gap is the part a consumer running this workflow will meet first. A release
interrupted halfway is the normal case, not the exception, and a timing section that cannot tell waiting
apart from working produces a number nobody can use twice. The rule this instance sets is to exclude the
wait, name it, and give the wall clock once.

**Score:** 2

### Pull Request · 20260820-140950

The v4.16.0 release note gains its end-to-end total

[PR #790](https://github.com/DaveKJohn/claude-code-specialists/pull/790)

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

