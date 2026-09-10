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
[`dkj-policy/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

**The line directly under `## [Unreleased]` is a tally, and nobody types it.** It reads
`**4 / 9 minor entries**`: how many of the pending entries reach the audience this repo publishes to, out of
how many are waiting for the next release, and which bump that work has earned. The two numbers answer
different questions and may differ — the fraction counts tier 2 and above, the bump follows tier 1 and
above — so `**0 / 8 minor entries**` says nothing reaches a subscriber while the version still owes a minor
for what reaches management. It is
**derived from the entries below it every time it is written**, by the fold that adds one and the cut that
removes them all, so it holds no state of its own and a hand-edited count is simply corrected on the next
fold. It ends with an HTML comment that marks it as machine-written; that marker is what the next run
replaces, so anything else written in this space is left alone.

---

## [Unreleased]

**2 / 2 minor entries** <!-- pending-tally -->

### DEPLOY: docs/1820-marketplace-remove-machine-wide · 20260910-231520

`INSTALL.md`'s three migration sequences now say that step 3's `claude plugin marketplace remove` is
machine-wide over install records, and a new section states what that means for a machine with more than
one checkout. It also splits step 3, which is two commands with two different reaches: `remove` drops the
registration for the whole machine and is run once, while `marketplace add … --scope project` writes the
source key into the repo it is run in and is owed to every checkout. So the first checkout runs the whole
sequence and each one after it skips step 2 and the `remove`, then runs the `add` and step 4. The section
carries the measured record counts, both of the CLI's failure messages verbatim — the second reads as a
`--scope` mistake by the operator and is not one — and the bounds of what was measured. The same
mechanism is now a hard rule in the system administrator's portable manual, so it travels to every
consumer rather than living only on this page.

Before this, a reader with three checkouts was told by the page's own per-checkout framing to run the
sequence three times, and the first run silently made steps 2 and 3 impossible in the other two — with
two error messages that name a missing plugin or the wrong scope rather than the cause.

**Score:** 3

#### What makes this deploy extra special

A consumer migrating more than one checkout hits this on the second one, and the page gave them a red
error at a step its own step 3 had already made impossible. Nothing was broken on their machine and the
CLI's wording says otherwise. It is a procedure repair on the page consumers are told to follow, so it
reaches anyone still to migrate.

**Score:** 3

#### Pull Request

State that marketplace remove ends the other checkouts' migration

Plugins: dkj-subagents-alpha

[PR #1825](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1825)

---

### DEPLOY: fix/1769-flag-day-register-and-install-page · 20260910-224248

The connector register now records the five consumer repositories as they actually are after the
`v5.0.0` flag day: `<plugin>@dkj-claude-plugins`, with the current plugin names. Every record was
written from the consumer's own `.claude/settings.json` on `main` rather than from the migration plan,
which matters because three of them were two renames behind and the plan's one-axis swap would have
written ids that never existed.

This is decision A coming due rather than a change of mind about it. The doctrine in
`connectors/README.md` -- write a renamed id only after the consumer itself has migrated, so the
register never raises a false alarm about a migration nobody performed -- held the whole way: all five
consumers merged first, and their records followed within the hour.

**And `INSTALL.md` stops handing a reader the retired slug in a command they are meant to paste.**
Four sites resolved the repository name rather than merely printing it, and two contradicted
themselves inside three lines by naming the marketplace `dkj-claude-plugins` while pointing its
`repo` at `DKJ-Solutions/claude-code-specialists`. They worked, because GitHub answers the transfer
redirect -- which is exactly the dependency `CLAUDE.md` says must never be load-bearing, since it
holds only while nothing is created at the old path. The three old-slug hits still on the page are
issue URLs and are correct as they stand.

**Score:** 3

#### What makes this deploy extra special

**A page that tells a new consumer to register the wrong source is the one doc defect that cannot be
noticed by the person it hurts.** The registration succeeds, the plugins install, and nothing is
visibly wrong -- until the day the redirect stops answering, at which point the failure lands on
somebody who followed the instructions exactly. Three adoption rounds' worth of lint rules in this
repo exist for that class, and this is the same class arriving through the rename that was supposed
to close it.

The register half has a quieter payoff: `check-connectors.ps1` is the thing that answers *"is this
consumer behind?"*, and it SKIPS a plugin whose id it cannot resolve. With five records naming a
marketplace that no longer exists, every one of those consumers would have been unreportable in
exactly the way #1465, #1525 and #1698 each recorded before -- the fourth time by the same route.

**Score:** 3

#### Pull Request

The connector register and the install page catch up with the flag day

[PR #1822](https://github.com/DKJ-Solutions/dkj-claude-plugins/pull/1822)

---

