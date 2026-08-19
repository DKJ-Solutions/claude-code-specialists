## Branch `docs/portability-claim` changelog - 20260819-101246

### What does the change on this branch bring to main?

#### Tier 0

The root `CLAUDE.md` claimed in three places that its top half is *portable* and travels to any repo
that adopts it. It does not. **Measured above the repo slot: Dave is named as the decision-maker
fifteen times** (`Never without Dave's explicit permission`, `Dave keeps the wheel in both
directions`, `Decision by Dave, July 27, 2026`), one link points at this repo's own issue #388, and
four lines reach for mechanisms only this repo has — a `plugin.json` version bump, the release
overview's `#### N.x` section, and the test pinning which major that overview targets, with the
`v4.0.0` cut as the reason. What travels is the **shape** (a constitution, then a repo slot); the
content is Dave's, shared across the repos he runs rather than universal.

The three now say so, and the slot blockquote states the consequence a reader actually needs:
copying this file to another repo of Dave's means replacing the slot; copying it to somebody else's
means replacing the decision-maker above it as well. The `### The how ... vs. the what` heading
follows — *(portable)* / *(repo-specific)* became *(Dave's, across his repos)* / *(this repo only)*.
Nothing links to that anchor, checked before renaming it.

**Caught by Dave reading the paragraph, and two of the three were written the same morning.** The
sentence before this branch read *"the portable way of working of a repo run by the Claude
Specialists"* — overclaiming already, but qualified. The de-personification pass dropped the
qualifier and widened it to *"travels to any repo that adopts it"*, which is the wrong direction: it
also contradicts the standing decision that Dave's way of working is an opt-in package rather than
the baseline a consuming repo inherits.

**The word is deliberately left standing everywhere else in the file, with a note saying not to
sweep it.** Those are the *plugin* sense — a persona body, a manual, the portable half of a rule —
and those files genuinely travel to a consumer through a release. A later reader running a
find-and-replace on the word would break six correct statements to fix three wrong ones. The note
carries no count on purpose: a tally of a word, written inside a sentence that uses that word, goes
stale on its own next edit — the staleness class check 16 exists for.

**Score:** 2

#### Higher than tier 0?

N/A — the root `CLAUDE.md` is this repo's own document and is not plugin payload. Nothing here
reaches a consumer.

**Score:** N/A

### Pull Request

The root stops calling Dave's constitution portable
