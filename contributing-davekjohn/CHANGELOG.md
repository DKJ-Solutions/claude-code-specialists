# Changelog

Everything merged since the last release sits under **`## [Unreleased]`**, **newest first**: **one `###` per
change**, and under it two named `####` sections. The `###` heading is the change's own —
`` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `#### What makes this deploy extra special` for the second audience, and `#### Pull Request`.
Every level here moved one deeper on August 26, 2026, when the pending section above them was introduced and
the development cycle beside them shifted to match; entries written before that day carry the whole set one
level shallower and are read exactly as they always were.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/history.md`](releases/history.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`contributing-davekjohn/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## [Unreleased]

### DEPLOY: `docs/trim-always-on-path-v1` · 20260828-093822

Every session paid 27,762 tokens of instruction documents before its first assignment. It now pays
25,195 -- **2,567 fewer, 9.2%**, across `CLAUDE.md`, `SPECIALISTS.md` and Chris's lens.

Nothing was decided differently. Eight passages of *evidence* moved to destinations those documents
already named, under the rule the repo states itself: the decision belongs on the always-on path, the
measurement behind it does not. Two of the eight turned out to be neither evidence nor decision but
**duplication** -- the `contributing-davekjohn/CONTRIBUTING.md` layering history and the
1,700-vs-26,914 lens measurement were already written out in full at the pages `CLAUDE.md` was pointing
at -- so those were deleted rather than moved. Every bound on the three direct-on-`main` exceptions is
still stated here, verbatim and checkable; what left them is their history.

The evidence has three new homes, each of which is read on demand and costs a session nothing until it
is opened: a `## Measured instances kept off the always-on path` section in the specialists handbook
(the three ways a briefing fails, why `Get-RosterIgnoredIds` is empty, why the branch check fires on
the follow-up assignment), a section in Tessa's lens for the *portable*-word repair and the `grep -c`
miscount that came with it, and inbound #388 in the `triage-inbound` skill, beside the five other ways
a report fails on pickup.

Chris's persona carries another 35% of the path and was deliberately left alone: it is plugin payload
that ships to every consumer, and trimming it is a release-bound change rather than a repo-local one.

**Score:** 3

#### What makes this deploy extra special

N/A -- every file touched is repo-owned. Nothing here ships in a plugin, so no consumer sees a
difference.

**Score:** N/A

#### Pull Request

Move the measured evidence off the always-on document path

[PR #1016](https://github.com/DaveKJohn/claude-code-specialists/pull/1016)

---

### DEPLOY: `feat/shopify-sync-pr-body-seam-v1` · 20260827-215731

`team-shopify`'s pre-task sync now writes the PR body itself, on **both** paths, and a consumer can replace
it. The body names what was TAKEN from live as well as what was held back, and gives every path its kind in
words -- `changed on live`, `new on live`, `gone from live` -- so a deletion on live reads as a deletion
instead of as a filename in a list. `Get-ShopifySyncPrBody` receives the classified rows and the composed
body and returns whatever the repo's own review policy needs around them.

**Score:** 4

#### What makes this deploy extra special

**The PR body is the record, and in some repos it is the only one.** Where a consumer has ruled that the
sync PR does not wait for a review -- provided it states plainly what a third party did -- nobody reads the
diff by design. *"The diff shows what came in, never what was held back"* was the script's own instinct and
it was the right half of a two-half problem: the diff of a sync branch cannot show what live no longer has
either. That is not hypothetical. Inbound #1000 arrived with the failure already measured in the reporting
repo's sync PR #350, where a flat file list could not say that a template had disappeared.

**And the path that had no body at all was the default one.** The merging variant composed a partial body;
the non-merging variant composed none and printed a `gh pr create` line without `--body`, plus a list for
the operator to paste in. Merging is opt-in, so the common case was the empty one -- the sort of gap that
survives because every consumer who hits it works around it locally, which is exactly what the reporting
repo had been doing since the time-window era.

**Score:** N/A

#### Pull Request

team-shopify sync-main: a seam for the sync PR body

Plugins: team-shopify

[PR #1014](https://github.com/DaveKJohn/claude-code-specialists/pull/1014)

---

