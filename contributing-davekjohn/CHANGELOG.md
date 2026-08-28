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

### DEPLOY: `feat/chris-on-demand-manual-v1` · 20260828-105519

The orchestrator gets the on-demand half every other specialist already had. His persona is loaded on
every turn in every consuming repo, and until now the lint gate's check 6b required an agent def
behind every manual -- which he has none of, by design, being the only specialist who can ask the
owner anything. So every rule he carried sat on the always-on path whether or not the session ever
needed it. 6b now accepts a persona as a backer, and three sections moved into
`manuals/01-01-manual.md`: the workflow phase model, delegating parallel work, and the six inbound
checks in full. Each is unknowable at the start of a turn, which is what made them the right three.

**5,139 B off the always-on path, ~1,647 tokens, 20.0% of the persona** -- on top of the 1,861 B the
compression branch before it recovered, and paid for by no rule being dropped. The gate enforces the
half that can break: a persona backing a manual must name it, since it is the only half that loads.

**Score:** 4

#### What makes this deploy extra special

Every consuming repo pays this path before its first assignment, so the saving lands on each of them
at the next plugin update without anyone doing anything. Nothing a consumer has to act on: no rule
changed, no file they own moved, and a persona with no manual -- Bianca, Derek, Rendall -- is
untouched in both directions.

**Score:** 3

#### Pull Request

Chris gets an on-demand manual, like every other specialist

Plugins: team-alpha

[PR #1019](https://github.com/DaveKJohn/claude-code-specialists/pull/1019)

---

### DEPLOY: `docs/trim-chris-persona-v1` · 20260828-101704

Chris's persona is the one document on the always-on path that every consuming repo pays too, and it
was 27,535 B. It is now 25,674 -- **1,861 B / ~596 tokens, 6.8%** -- with no rule removed and no
generated block touched.

Two sections carried it. The fixed ritual's step 6 said the same thing about the close-out in four
paragraphs where two do. The inbound route described **six** ways a report fails on pickup across five
running prose paragraphs, while every document that refers to them -- the repo lens, the
`triage-inbound` skill -- already calls them "the six". They are a numbered list now, so the count in
the prose and the count on the page finally agree, and a reader checking a report against them can
find the fifth one.

**What this branch could not do is the more useful half, and it is filed rather than left implicit.**
The other fifteen specialists split into an always-listed agent def and a `manuals/` playbook read on
demand; Chris has no manual, because check 6b of the integrity gate refuses one to a specialist with no
agent def and he is deliberately a persona. So every rule he carries has to sit in the always-loaded
body, which is why he is ~35% of the path. Measurement, the inconsistency in the handbook that states
both halves of it, and the three candidate answers are in
[#1017](https://github.com/DaveKJohn/claude-code-specialists/issues/1017) -- choosing between them is a
structural decision and not a branch's.

**Score:** 2

#### What makes this deploy extra special

A consumer gets the same rules in a shorter persona, and the six inbound checks as a list they can work
through instead of five paragraphs they have to parse. No behaviour changes.

**Score:** 2

#### Pull Request

Compress the orchestrator's always-loaded persona without dropping a rule

Plugins: team-alpha

[PR #1018](https://github.com/DaveKJohn/claude-code-specialists/pull/1018)

---

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

