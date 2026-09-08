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

**10 / 18 minor entries** <!-- pending-tally -->

### DEPLOY: feat/plugin-version-overview · 20260908-102335

A new `dkj-policy` skill, `plugin-versions`, answers a question nothing else in the system does: for
each enabled plugin, is the version installed IN THIS CHECKOUT the same as the one the local
marketplace clone holds, and if not, which command closes the gap? It reads only what every consumer
machine already has -- the install record keyed on this checkout's `projectPath`
(`version`, short `gitCommitSha`, `scope`), and the marketplace clone's per-plugin `plugin.json`
`version` plus its git `HEAD`. Because the clone advances only on
`claude plugin marketplace update`, the version string is cut-granular and the HEAD sha is the finer
truth, so the verdict prefers the sha (ancestor of HEAD -> `claude plugin update`; equal -> up to
date; unknown to the clone -> refresh the clone) and falls back to the version comparison when a sha
is absent. Read-only, no arguments, runs on any device; a missing clone, a missing install record, a
declarative-only enable, a moved checkout and a non-git marketplace fetch each degrade to a clear
line rather than an error. `Get-InstallRecord` in `check-report-lib.ps1` gains a `GitCommitSha` field
on its projection to feed it.

**Score:** 3

#### What makes this deploy extra special

Every consumer of the `dkj-policy` workflow receives the `plugin-versions` skill in the next release,
and with it the first per-device answer to *"is this checkout on the current plugin release, and do I
run `claude plugin update` or `claude plugin marketplace update`?"* -- a blind spot the repo slot in
`CLAUDE.md` calls out explicitly ("between two releases no version check can tell you the clone is
behind"). It is noticed the moment a consumer wonders whether a session loaded a stale plugin.

**Score:** 3

#### Pull Request

A per-device plugin-version overview: installed vs. marketplace clone, with a verdict

Plugins: dkj-policy, dkj-team-alpha

[PR #1599](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1599)

---

### DEPLOY: fix/1588-stale-ci-remedy-checkout · 20260908-100702

`ship-pr`'s stale-CI refusal now tells you to check the branch out before bringing it forward. It printed
`git fetch` and `git merge` alone, and by the time it fires the same run has already returned your tree to
the trunk -- so both commands acted on `main`, silently: the merge fast-forwarded the trunk with a diffstat
that reads exactly like the branch moving forward, the push was a no-op, and the branch was untouched. The
cost was a full CI cycle and a re-run complaining about the wrong problem, twice in five days.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing a subscriber of a service notices. This is a refusal message inside the shipping tooling;
its reader is whoever is merging a pull request.

**Score:** N/A

#### Pull Request

ship-pr's stale-CI remedy names the branch to check out first

Plugins: dkj-policy

[PR #1596](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1596)

---

### DEPLOY: fix/1584-ship-pr-conflicting-early-exit · 20260908-095109

`ship-pr` now refuses a CONFLICTING pull request the instant it starts waiting for CI, instead of
after the full 180s check-registration timeout. A conflicting PR has no `refs/pull/<n>/merge` for a
`pull_request` workflow to run against, so no check suite can ever register for it -- a state GitHub
reports the moment the PR exists, which made the wait pure cost. The refusal reuses the existing
#1247 diagnosis (resolve the conflict; a close/reopen was measured doing nothing), and where the
conflict is a branch whose changelog entry has already folded on `main`, it says the branch is spent
and the follow-up belongs on a fresh branch off the trunk -- rather than a rebase that just re-adds a
folded entry.

**Score:** 3

#### What makes this deploy extra special

N/A -- internal shipping-workflow tooling; no subscriber of a service is affected.

**Score:** N/A

#### Pull Request

Refuse a CONFLICTING PR up front instead of after the 180s check-registration wait

Plugins: dkj-policy

[PR #1595](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1595)

---

### DEPLOY: fix/1586-fold-on-merge-stale-trunk-deferral · 20260908-094224

The `Fold on merge` CI job no longer goes red when two merges land within seconds of each other. Its
checkout reads the trunk once, and the fold's trunk-freshness guard measures the same trunk again about
eleven seconds later -- so a second merge in that gap left the job refusing on an entry another actor
had already folded. The guard was right and the trunk ended correct; only the red was wrong, and it
described a state that was gone by the time anybody opened it.

That refusal now carries its own exit code -- `2`, the only thing in `fold-changelog-entry.ps1` that
returns it -- and the job stands down green on that code alone, naming the reason in the log. Every
other non-zero code still fails it, so the three real ways the job goes red are untouched. Nothing is
lost by standing down: the guard fires in a pre-pass before a single entry is folded, and the push that
moved the trunk queues its own run of the same job behind this one. The consumer template in
`adopt-merge-queue.ps1` places the same behaviour, and both workflow headers stop claiming -- as
#1543's repair did -- that `ref: <trunk>` puts that guard out of reach.

**Score:** 3

#### What makes this deploy extra special

A consumer who has adopted the CI floor gets a fold runner that stops crying wolf, and the guidance
that goes with it: a `Stood down:` line in the log is the job working rather than a fold that went
missing. `git fetch` + `--ff-only` before the fold was the obvious alternative and is declined in
writing -- it narrows the window without closing it, which leaves the guardrail red *rarely*, and a
guardrail that is wrong rarely is the one nobody reads.

**Score:** 2

#### Pull Request

fold-on-merge stands down on a trunk that moved under it, instead of going red

Plugins: dkj-policy

[PR #1593](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1593)

---

### DEPLOY: docs/1587-staleness-source-of-truth · 20260908-093101

`dkj-policy/README.md`'s staleness paragraph claimed a connector manifest "carries the version its
record was last seen on." No manifest field has ever stored a version — that bookkeeping was removed
by decision on July 20, 2026 (see [`connectors/README.md`](../connectors/README.md#the-manifest-format))
— and the actual mechanism reads the version installed on that machine from its own
`installed_plugins.json` record and compares it to the source checkout's `plugin.json`; the register's
only part in that is `localCheckout`, i.e. which machine record to read. The rewritten paragraph keeps
what was true (`connector-sessioncheck` still reports every lagging consumer at session start, and
`check-connectors.ps1` is still the deliberate full run, because the lagging checkout itself reports a
plausible version and works) and adds the case the old wording missed: with no verified source checkout
on the machine, the check is skipped outright, so silence there is not "up to date" — it is no verdict
at all. No other passage in the file rested on the same false premise.

**Score:** 2

#### What makes this deploy extra special

N/A -- this corrects one paragraph's wording about an internal maintenance mechanism (the connector
register and the staleness check). No subscriber of a service reaches this page or is affected by
whether the mechanism is described accurately.

**Score:** N/A

#### Pull Request

Describe the plugin-staleness mechanism as it actually works

[PR #1590](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1590)

---

### DEPLOY: fix/1566-truncated-plugin-links · 20260908-092431

Sixteen links in the plugin payload named a file and pointed at the repository front page. A consumer
reading `specialists-init` -- the first page a new adopter opens -- was told to read `INSTALL.md` and
landed on the repo's home page to find it themselves. All sixteen now carry the path they name, and the
six that named a section carry its anchor.

Nothing could have caught them. GitHub answers `.../blob/main/` with the repo root, so all sixteen
returned 200 and were never dead links; the dead-link scan skips absolute targets, and `[plugin-link]`
skipped them too, because its subject is a *relative* target escaping the plugin root. The defect sat
in the gap between "not dead" and "not relative".

So the check that produced the shape now holds it. `[plugin-link]`'s suggestion hands the author the
absolute form of an escaping link, anchor included; sixteen base-only links against the seventeen
repairs that suggestion was written for is close enough to name the mechanism -- the advice was right,
and nothing held the *result* of taking it. The new half reports an absolute link that is this repo's
blob/tree base with nothing after it: the one absolute shape that is provably not what the author
meant, since the link text always names something more specific. Absolute links stay otherwise out of
scope. It keys on `Get-RepoBlobUrl`, so it cannot disagree with the suggestion about which URL counts
as this repo's -- and in a repo without that seam it does not run and the coverage line says so.

That keying has one named cost: a base-only link written on the *previous* owner name is out of reach,
which is where all sixteen of these were. Widening to reach it was declined -- recognising a retired
owner path would bless a spelling the repo-citation rule is retiring -- and there is no instance left to
justify it: zero base-only links on either owner remain anywhere in the tree, and every future one comes
from the suggestion, which writes the current base. A test pins the pass, so reaching for it later has to
be a deliberate edit.

**Score:** 3

#### What makes this deploy extra special

A gate whose own advice creates a defect class it cannot see is the shape this repo keeps paying for,
and the reach is a consumer's first read rather than an internal document. Not a required migration and
nothing breaks, so it stops short of 4: a reader who never clicked those links loses nothing, and one
who did now lands where the text said.

**Score:** 3

#### Pull Request

Give the 16 truncated absolute plugin links their real paths, and gate the shape

Plugins: dkj-policy, dkj-team-alpha

[PR #1571](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1571)

---

### DEPLOY: fix/machine-local-note-review-findings · 20260908-091324

Five review findings on the machine-local note reached `main` after the change they were about. The
gate's reworded note (#1574) merged from a parked commit while the reviews on it were still running, so
the text that shipped still said to keep a swept-in edit in "that file's gitignored sibling" -- singular,
against a note whose first line lists however many paths the repo watches. A consumer with two entries
in `Get-MachineLocalPaths` read advice with no antecedent. That is corrected here, along with a seam
comment that called PR #1573 a branch whose "entire subject" was one hunk of a fifteen-file diff, and
three defects in the folded changelog entry: it credited #1557 with founding the gate where #1559 did,
used "misfires" transitively where the two neighbouring restatements do not, and switched the referent
of "it" mid-paragraph. Nothing about when the gate fires changed, and it still only warns.

**Score:** 2

#### What makes this deploy extra special

The note is printed by a shared script that travels in the plugin mirror, so its wording is what every
consumer reads at `open-pr`. The correction matters most in the repo this text was NOT written in: one
watched path is this repo's answer, and the sentence only breaks where somebody has configured two.

**Score:** 1


#### Pull Request

Land the review findings the queue merged past on the machine-local note

Plugins: dkj-policy

[PR #1589](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1589)

---

### DEPLOY: fix/1579-shopify-no-store-seam · 20260908-090100

This repo now declares that it has no Shopify store, so `dkj-team-shopify`'s floor check stops asking it
for a live theme id it cannot truthfully give. `scripts/repo-config.ps1` answers
`Get-ShopifyRepoHasNoStore` with `$true` -- the seam inbound #1570 added to the check -- and the
`CLAUDE.md` repo slot no longer describes that permanent `[ERROR]` as a gap in the check, because it is
not one any more. The "do not silence it by seeding a theme id" warning stays: a declaration says there
is no store, an id says there is one and names it, and only the first of those is true here. The
session start on a given machine goes quiet once the plugin change reaches its marketplace clone
through a release, which the slot now states rather than leaving a reader to wonder why the message
persists.

**Score:** 3

#### What makes this deploy extra special

N/A -- nothing here reaches a consumer of the plugins. Both files are this repo's own layer:
`scripts/repo-config.ps1` is repo-local configuration and never ships, and `CLAUDE.md`'s repo slot is
explicitly the part a copying repo replaces. The seam it answers was shipped by #1570; this branch only
answers it.

**Score:** N/A

#### Pull Request

This repo declares it has no Shopify store, so the floor check goes quiet

[PR #1583](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1583)

---

### DEPLOY: fix/1572-lane-ship-queue-trunk-holder · 20260908-085026

`ship-pr.ps1` refused a lane ship whenever another worktree (the primary checkout) held `main`, on the
ground that "step 5 could not fold after the merge" -- but under a merge queue step 5 folds nothing:
the queue's own push to `main` runs `fold-on-merge.yml`. The refusal therefore blocked the exact
lane workflow `ship-pr` itself recommends, since step 2b (#1073) leaves the primary on the trunk on
purpose. The refusal now runs *after* the queue verdict and is gated on `-not $queueActive`, the same
shape #1506 established for the fold-push verdict; under a queue the held trunk is noted, not refused.
Where no queue is read the guard is unchanged.

**Score:** 4

The lane ship path -- the one `ship-pr` prints while waiting on CI -- was simply broken on a queued
trunk. Each occurrence was worked around by hand (moving the primary off the trunk, against the
orchestrator's "end on the trunk" rule for the duration of the ship).

#### What makes this deploy extra special

A consumer running `dkj-policy` *with a merge queue on their trunk* hits the same refusal if they
follow `ship-pr`'s own advice to ship from a lane. Bounded audience -- GitHub only offers merge queue
on private repos under Enterprise/Team -- but for those repos the lane ship was unusable.

**Score:** 3

#### Pull Request

ship-pr no longer refuses a lane ship on a queued trunk where it folds nothing

Plugins: dkj-policy

[PR #1576](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1576)

---

### DEPLOY: fix/1575-prune-merged-dirty-guard · 20260908-084930

`prune-merged.ps1` no longer refuses a dirty working tree on runs that could never move it. The
refusal's own ground is step 4c -- stepping off the branch you are standing on in order to reap it --
and that step is unreachable when HEAD is the trunk (never a reap candidate), when HEAD is detached,
and under `-DryRun` (which deletes nothing). The guard now asks exactly that reachability question, so
those runs proceed; a dirty tree they pass through is reported with the reason it was harmless, rather
than passed over in silence.

This is the command the orchestrator's lens tells a session to run mid-assignment in place of
classifying `git ls-remote` output by hand -- and mid-assignment is exactly when a checkout has
uncommitted work in it, so the guard was blocking the report in the state the advice was written for.
The two ways out it offered are the wrong price for a read: parking commits to a branch, and stashing
touches a file the session was told to leave alone.

Nothing the guard protected is given up. A dirty checkout standing on a non-trunk branch refuses
exactly as before, because that branch can be squash-merged while the work is uncommitted, and that is
the case where the step-off drags it onto the trunk. The refusal now names the branch that makes it
reachable, and offers `-DryRun` beside commit, park and stash.

That last case is why the doc half moved too. The orchestrator's lens and the consumer-facing skill page
for this script now name `-DryRun` as the route for a session standing on a branch with uncommitted
work, which is the ordinary mid-assignment shape: it deletes nothing, so it never has to step off, and
the classification it prints -- the paste-ready delete command for a merged leftover,
`Kept ... -- live work` for everything else -- is identical to the full run's. The skill page had gone
further than stale; it still described the refusal as unconditional, which is what a consumer would have
read.

The suite's own dirty case ran from the trunk, so it had been pinning the defect; it is re-pointed at a
branch, and two cases are added for the arms that now proceed.

**Score:** 3

#### What makes this deploy extra special

N/A -- this is a maintenance script in the development workflow. No subscriber of a service reaches it,
and nothing about a published artifact changes.

**Score:** N/A

#### Pull Request

prune-merged only refuses a dirty tree where the run could actually step off it

Plugins: dkj-policy

[PR #1581](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1581)

---

### DEPLOY: fix/1570-shopify-floor-no-store-seam · 20260908-084027

The Shopify floor session check gains a third state. A repo that enables `dkj-team-shopify` without a
store -- the plugin's own source repo, or any repo that turns the team on only to validate its
manifests and hooks -- can now answer `Get-ShopifyRepoHasNoStore` with `$true` in its
`scripts/repo-config.ps1`, and the check then stays silent on the half-armed live-theme finding
instead of raising a permanent `[ERROR]` it has no truthful way to clear. The silence follows a
deliberate, self-authored declaration only -- never an inference from the tree -- so no real store is
ever quieted by it, and the guard hook, every other seam and the independent duplicate-guard finding
are unchanged.

**Score:** 3

#### What makes this deploy extra special

A consumer that enables `dkj-team-shopify` purely to check that its manifests and hooks still resolve,
without owning a store, gets a clean session start instead of a standing `[ERROR]` or a faked theme
id. Store consumers -- the common case -- see nothing change.

**Score:** 2

#### Pull Request

let a repo declare it has no Shopify store, so the floor check stops the permanent [ERROR]

Plugins: dkj-team-shopify

[PR #1578](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1578)

---

### DEPLOY: fix/1574-machine-local-remedy-wording · 20260908-083227

The machine-local path gate stops giving wrong advice on the path it fires on. It warns whenever a
branch's commits touch a tracked file that usually belongs to a clone -- `.claude/settings.json` here
-- and its remedy sentence said, flatly, to drop the change from the branch because "machine-local
plugin enablement belongs in `.claude/settings.local.json`". That is right for a machine's own extra
enable, the sweep the gate was built for (#1559, measured on PR #1557), and wrong for the other case
the same file carries: a branch whose subject IS the declared, tracked set every clone inherits. Measured on PR
#1573, where the gate fired on a branch that existed to change exactly that. The note now names both
cases and prescribes the move only for the clone's own edit; the seam comment in `repo-config.ps1`
records which half of the advice belongs where, and the suite asserts it. Nothing about when the gate
fires changed, and it still only warns -- what changed is that the sentence a reader acts on is true on
both paths. The cost of leaving it was not a broken branch but a decaying reader: a warning that gives
the wrong advice on the path it fires on is one that gets scrolled past, and it is then scrolled past on
the day it is right.

**Score:** 2

#### What makes this deploy extra special

The note is emitted by a shared script that travels in the plugin mirror, so every consumer running
`open-pr` reads this text. A consumer branch that legitimately changes its own shared harness settings
now gets advice it can follow instead of being told to move the change somewhere gitignored. Small --
three sentences on a rare path -- but until now following that advice was the wrong move, and only a
reader who already distrusted it came out right.

**Score:** 2

#### Pull Request

Sharpen the machine-local gate's remedy so it names both cases

Plugins: dkj-policy

[PR #1577](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1577)

---

### DEPLOY: feat/source-enables-every-plugin · 20260908-081857

The source repo now enables **every** plugin in its own marketplace, not just the core team and the
workflow, and says why: a plugin whose agent defs, manifests and hooks are never resolved anywhere is one
whose install is only ever proven in somebody else's session. Enabling all six means a frontmatter that
stops parsing, a manifest that goes stale or a hook that stops resolving surfaces at this repo's own
session start instead of downstream. The three add-on teams and `dkj-policy-bwj` have no work here and are
not expected to, so the eleven specialists they bring get roster entries and empty `VUL-IN` lenses -- and
`CLAUDE.md` and `SPECIALISTS.md` both now say, in as many words, that those eleven lenses are the intended
end state and not a backlog. The one cost that cannot be documented away is `dkj-team-shopify`'s floor
check, which reports an `[ERROR]` every session here because it asks which theme is live and has no third
state for a repo with no store; that is named in the repo slot and filed as #1570, with an explicit
instruction not to silence it by inventing a theme id.

**Score:** 4

#### What makes this deploy extra special

N/A -- nothing under `plugins/` changed, so no released payload moves and no consumer sees anything from
this branch. It is a change to how the source repo is configured and what its own governance documents
claim.

**Score:** N/A

#### Pull Request

Enable every plugin in the source repo, with the roster catch-up it owes

[PR #1573](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1573)

---

### DEPLOY: feat/consumer-readme-update-topup · 20260908-080839

A consumer's `dkj-policy/README.md` now **gets** the UPDATE section, and gets it even if their folder was
scaffolded before the section existed. `adopt-dkj-policy` Part 1 places it on a fresh adoption and
**appends** it to a page that has none, recognised by a marker comment
(`<!-- dkj-policy:update-section -->`) — the one write this command makes into a file it did not create,
bounded to a single append at the end of a single file, in whichever folder `Get-WorkflowFolderName` says
that repo actually has. A page that already carries it is left untouched and reported as such, so a
re-run still finds nothing to do.

The section itself names that repo's **own** plugin ids, read from its settings chain, one
`claude plugin update <id> --scope project` line per enabled plugin under the marketplace refresh — with
the command's shape as the fallback, because a placeholder is honest and a wrong id is not. It carries
why both halves of the pair matter, that the marketplace clone and the install record are per-checkout
state no session reports, and the seam answer a newer version of the shared scripts can start asking for.

This closes the reach half of #1567: without it, the section landed in the source repo and in no consumer.

**Score:** 4

#### What makes this deploy extra special

Three consumers are registered against this source today, and every one of them adopted its folder
before this section existed — so this is the difference between the section existing and the section
arriving. It is also the first time this scaffold can deliver a *later* improvement to a page it already
placed, which is a shape the folder's other documents will want as well.

**Score:** 3

#### Pull Request

Let the adoption scaffold place -- and top up -- the UPDATE section in a consumer's folder README

Plugins: dkj-policy

[PR #1569](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1569)

---

### DEPLOY: fix/1564-fold-stale-offset-after-tally · 20260908-075318

`fold-changelog-entry.ps1` crashed on the first fold after every release cut -- folding into an empty
`## [Unreleased]` -- because it read byte offsets against the changelog *before* the pending-tally
rewrite replaced that string with a shorter one, then used them in the "placed above N" console line.
The crash landed between the changelog write and the commit, so `-Commit -Push` silently did neither
and left the fold uncommitted on the trunk with the entry file already deleted. The offset-dependent
counts now run before the tally rewrite, while the offsets are still valid; a regression test folds
into a freshly-cut `## [Unreleased]` and checks the fold is committed.

**Score:** 4

Every first fold after a release cut hit this; recovering it meant a hand-typed commit of the two
bounded paths, twice in one day per the issue. Not a 5 only because that recovery was known and
in-bounds.

#### What makes this deploy extra special

A consumer running the `dkj-policy` workflow hits the same crash on their first fold after their own
release cut -- a shipped script broken on a guaranteed code path, leaving their trunk in a silent
half-state (`-Commit -Push` doing neither, entry file gone so `check-unfolded-entry.ps1` sees nothing).

**Score:** 4

#### Pull Request

fold-changelog-entry.ps1 no longer crashes on the first fold after a release cut

Plugins: dkj-policy

[PR #1568](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1568)

---

### DEPLOY: docs/dkj-policy-folder-update-section · 20260908-074642

`dkj-policy/README.md` now says how to **update** the plugins, not only how the folder is arranged — a
section between the seam table and the pointer list, written for the case this repo is peculiarly
exposed to: it consumes its own marketplace, so a session here runs the installed copy and **a push does
not advance the local clone**. It carries the two commands per plugin, the session restart, and then the
three things that make an update invisible until somebody looks: between two releases no version check
can tell you the clone is behind, the install record is per-checkout and keyed on its folder path
(#1449), and the only place a lagging machine is actually visible is the connector register. It closes
on the two catch-ups an update can require — the seam function `script-contract-sessioncheck` reports,
and the roster row and lens a newly arrived specialist needs.

The same edit narrows this page's intro, which called the index **two** sections below the divider and
is now three.

**Score:** 3

#### What makes this deploy extra special

N/A — this is the source repo's own folder index, and nothing here travels to a subscriber. The
consumer-facing half of the same subject shipped in #1565, on the plugin's own page.

**Score:** N/A

#### Pull Request

Say how to update the plugins in another checkout of this repo

[PR #1567](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1567)

---

### DEPLOY: docs/dkj-policy-update-section · 20260908-072707

The `dkj-policy` plugin page now says how to **update** the plugin, not only how to enable it — a
`## Updating it` section beside `## Enabling it`. It carries the two commands, the session restart, and
the ministry's own pair; then the reason the section has to exist at all: the cached marketplace clone
and the install record are both **per-machine** state keyed on the checkout's folder path, so a version
picked up on one machine changes nothing on the next one and no session says so. It closes on what a
consumer needs afterwards: the script-contract catch-up an update can require — the shared scripts may
call a repo-owned function that checkout has never had (#147), which `script-contract-sessioncheck`
reports and `adopt-dkj-policy` Part 2 fills in — and the assurance that an update never touches the
consumer's own `dkj-policy/` folder, so work in flight cannot be lost.
No measurement is restated: the page links the family's `INSTALL.md` for those.

The same edit corrects that file's 13 `DaveKJohn/claude-code-specialists` citations to the canonical
`DKJ-Solutions/…`, under the rule that corrects them in a file being edited anyway.

**Score:** 3

#### What makes this deploy extra special

For a consumer running this workflow in more than one checkout — which is every consumer with a laptop
and a desktop — the page they read now answers the question that sends them to the wrong tree: *why is
this machine behind, and what do I run here?* The answer was only ever in the family's adoption page,
one repo away from the plugin they had just installed.

**Score:** 2

#### Pull Request

Say how to update dkj-policy on every other machine

Plugins: dkj-policy

[PR #1565](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1565)

---

### DEPLOY: fix/1562-origin-remote-redirect · 20260907-211130

The repo-citation section of `CLAUDE.md` now covers the layer it could not reach: a checkout's own
`origin` remote. A checkout cloned before the September 2, 2026 transfer still pushes to
`DaveKJohn/claude-code-specialists.git` and succeeds only because GitHub answers `remote: This
repository moved` — every push of the `v4.32.0` cut did exactly that. The note names the
one-command repoint (`git remote set-url origin
https://github.com/DKJ-Solutions/claude-code-specialists.git`) and ties the fragility to the same
condition the prose rule already carries: the redirect holds only while nothing is created at the
old path.

**Score:** 1

The failure this prevents has not happened: pushes from un-repointed checkouts still work today. It
bites the day anything is created at `DaveKJohn/claude-code-specialists` — every such checkout's
pushes then fail with no redirect to catch them, and nothing in the tree points at the cause.

#### What makes this deploy extra special

N/A — an internal documentation note. A subscriber of the service never sees a repo remote URL.

**Score:** N/A

#### Pull Request

Note the origin remote fix for checkouts still on DaveKJohn/

[PR #1563](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1563)

---

