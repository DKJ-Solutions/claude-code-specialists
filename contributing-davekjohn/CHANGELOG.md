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

### DEPLOY: docs/closeout-receipt-length-bound · 20260904-222307

Chris's close-out had three permitted shapes and a receipt-not-report rule, and still grew back into a
report. Two seams are tightened in his persona body. The instruction to "name what it filed, with
numbers" is now bounded by length — the number and at most a short clause, never a sentence of finding —
because that instruction was the one doing the expanding: a close-out that obeys the filing rule and then
writes a paragraph per issue asks the reader to read everything twice. And "the test is duplication, not
length" now has a cruder rule beside it, since a session can always find something non-duplicative to
add.

The second seam was a missing home rather than a missing bound. A finding that cannot be filed from the
current checkout — one belonging on another repo, where filing needs the owner's word — had no shape, so
it arrived as a fourth one, the *"this waits on you"* the page explicitly forbids. It is now filed
inward, into the nearest issue this session can already file, and cited like any other number.

Line-count neutral: the two clauses are paid for by cutting restatement, because this text loads on
every turn in every consuming repo.

**Score:** 3

#### What makes this deploy extra special

Every consumer's orchestrator gets the same bound, which matters because the failure it fixes is one a
consumer cannot see: a close-out that reads as thorough is exactly the one that costs its reader the
session. A repo adopting the specialists inherits the tightened rule rather than the wording that kept
giving way.

**Score:** 2

#### Pull Request

Chris's close-out receipt gets a length bound and a home for an unfileable finding

Plugins: team-alpha

[PR #1406](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1406)

---

### DEPLOY: fix/1395-empty-label-on-create · 20260904-221518

`open-pr.ps1` sends no `--label` at all when the branch-prefix seam answers no label for a prefix it
knows. It used to append `--label` unconditionally, so a repo that has abolished PR labels -- the issue
**type** carries the classification there now -- had every gate pass, its branch pushed, and then the
whole `gh pr create` refused over a label named `''`. The empty answer is now recognised before the
`gh label list` call, so there is no lookup whose answer cannot matter and no success line announcing
that `''` exists in the repository; the resolved label is normalised first, because `$null` in a native
argument list is an empty argument rather than an absent one. Inbound #1395, measured in
`BWJ-ecommerce/smartwatchbanden` on September 4, 2026, which had been opening its PRs by hand in the
meantime.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo's own prefix table names a label for all three of its prefixes, so nothing here
changes. The consumer that reported it gets its scripted PR route back.

**Score:** N/A

#### Pull Request

open-pr sends no --label at all when the seam answers none

Plugins: contributing-davekjohn

[PR #1404](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1404)

---

### DEPLOY: feat/bwj-codex-sync-log · 20260904-220935

`bwj-codex` is now the shared **extra layer** for BWJ's two Shopify store repos rather than only their
ticket workflow, and it has a second chapter: **the sync log**,
[`SYNC-LOG-portable.md`](../plugins/workflows/bwj-codex/SYNC-LOG-portable.md).

A `sync/` branch mirrors what a **third party** changed on the live Shopify theme. It is exempt from
the changelog by design -- that is somebody else's change, not the repo's -- which left it the only
branch in the workflow owing **nothing durable at all**: the sole account of what was taken and what
was held back was the PR body on GitHub, in two repos whose standing rule is that a sync PR does *not*
wait for review. A sync now owes a sync-log entry where an ordinary branch owes a changelog entry:
`bwj-codex/SYNC-LOG.md`, newest at the top, one entry per sync branch, never folded and never released.

**The mechanism is `team-shopify`'s and the policy is `bwj-codex`'s**, which is the seam split the
consumer repos already run. `sync-rules.ps1` gains `New-SyncLogEntry` and `Add-SyncLogEntry`;
`sync-main.ps1` reads one new seam, `Get-ShopifySyncLogPath`. **Unanswered means no log** -- every
Shopify consumer gets the machinery through the update, and none of them finds a new file in its tree
because of it.

Two things are deliberately *not* built, both named on the page rather than left as gaps. There is
**no PR field** in an entry: it is committed on the sync branch before any PR exists, and the default
seam never opens one, so the field would be blank on the common path -- the branch name is the head
ref instead. And there is **no gate**: `sync-main.ps1` writes the entry in the same commit that
creates the branch, the shape `new-branch.ps1` already uses, so a sync branch cannot land record-less
and `contributing-davekjohn`'s generic entry gate never has to learn a `bwj-codex` concept.

The entry is a **second rendering of the same rows**, not a second measurement: it shares
`Get-SyncPrBodySection` and `Get-SyncFileKind` with the PR body, and a suite asserts the two produce
identical bullets from identical rows -- the one assert that fails if they ever fork.

Closes [#1382](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1382).

**Score:** 3

#### What makes this deploy extra special

The two BWJ store repos get a record of third-party live-theme drift that survives the merge, in the
tree, greppable -- where before it lived only in a PR body nobody re-reads. It costs them one line in
`scripts/repo-config.ps1`. Every other consumer notices nothing, which is the design.

**Score:** 3

#### Pull Request

the sync log: bwj-codex chapter two, and a sync branch that leaves a record in the tree

Plugins: bwj-codex, team-shopify

[PR #1392](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1392)

---

### DEPLOY: docs/prose-contract-check-declined · 20260904-220309

A manifest-driven prose contract check — the analogue of `check-script-contract.ps1` for the laws this
plugin legislates rather than the functions it calls — was measured against 11 laws over 8 consumer
documents in the two consuming repos, and declined in every deployment mode: as a gate, as a session-start
line, and as the deliberately-run advisory audit #1380 asked about. A verbatim cue fired once. Term
co-occurrence reached 12.5% precision, adding a normative marker 13%, and a declaration-based check
reported 88 of 88 laws undeclared because no consumer has the convention it looks for.

Two measurements carry the decline. **The law the check was written to catch has no standing violation
left:** `LAW-RELEASE-ORDER` was the acceptance test because #1378 had just made it the one known-real
defect, and #1378's repair then made the consumer's order a sanctioned answer rather than a divergence —
so the check's reason for existing was repaired out from under it mid-measurement. **And the detector
found one of the three defects that actually stand in the corpus:** one instance was flagged, one was
missed because the term list wanted a word that section does not use, and one was suppressed by the very
pointer test meant to prevent false alarms. That last case is the structural reason, measured: a section
that restates a law may also cite it, and a pointer test cannot tell correct deference from
restatement-with-citation-and-override — 1 of the 4 suppressed sections in the corpus was hiding a real
contradiction.

The 11-law manifest is kept in the lens entry rather than discarded with the check, so a later revisit
does not re-derive it. So is the proportionate alternative: two narrow literal greps, each aimed at one
law, rather than one framework carrying eleven at 12% precision.

**Score:** 3

#### What makes this deploy extra special

`CONTRIBUTING-portable.md` stops promising an enforcement mechanism that has come back negative. A
consumer reading the layering section now learns that the prose half of the corollary is unenforced by
design, and why in one sentence — so they can stop waiting for a gate that is not coming and lean on the
ranking itself, which is what #1379 said makes a divergence nameable. Small: it changes one paragraph of
a page they already have, and nothing they run.

**Score:** 2

#### Pull Request

The prose contract check is measured and declined rather than left open

Plugins: contributing-davekjohn

[PR #1398](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1398)

---

### DEPLOY: docs/fix-1396-bwj-codex-resolve-wording · 20260904-215537

Fixes the second of two defects issue #1396 reported on the same two table cells: both
`README.md` and `plugins/workflows/README.md` claimed that closing the GitHub issue **resolves**
the mirrored Asana task. `bwj-codex`'s own README says the opposite in so many words ("It never
ticks the task off, and it has no code path that could" -- Dave, September 1, 2026), and the
`report-issue` skill agrees: closing the issue only makes the CI template post that the work is
ready to test and move the card to `ReadyToTest`. Both cells now say that instead.

The issue's other half -- "one rule" becoming false once the plugin gains a second chapter -- does
**not** yet apply: that chapter ships in PR #1392, which is still open (blocked on CI) and does not
touch either of these two files. Fixing that half now would have described a chapter `main` does
not carry yet. Left for a follow-up once #1392 merges; noted on issue #1396 rather than closing it.

**Score:** 1 -- cosmetic wording correction, no behavior change.

#### What makes this deploy extra special

N/A -- an internal documentation correction; nothing here reaches an external reader.

**Score:** N/A

#### Pull Request

Fix the wrong 'resolves the Asana task' claim in two READMEs (issue #1396)

[PR #1397](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1397)

---

### DEPLOY: docs/fix-1388-corollary-delegated-law-exception · 20260904-214401

`CONTRIBUTING-portable.md`'s restatement corollary named three permitted moves for a consumer document
(point, state a seam's answer, say nothing) and forbade a fourth (restate the law). `cut-release/SKILL.md`
Block 2 instructs exactly that fourth move for the release-order law, which it deliberately answers with
no seam. The corollary now names a fourth permitted move -- prose for a law the plugin explicitly declines
to answer at all -- scoped to a plugin page that says so in as many words, and `cut-release` Block 2 now
cross-references it. Neither page's underlying reasoning changed; only the corollary's coverage did.
Fixes #1388.

**Score:** 2

#### What makes this deploy extra special

A consumer repo that reads both pages while deciding whether to keep a non-default release order note in
its own `CLAUDE.md` no longer meets a contradiction between the two.

**Score:** 2

#### Pull Request

Add the fourth move (deliberately delegated law, no seam) to CONTRIBUTING-portable.md's restatement corollary

Plugins: contributing-davekjohn

[PR #1393](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1393)

---

### DEPLOY: docs/bwj-github-type-field-convention · 20260904-213855

`bwj-codex` now carries the board's `Github Type` field the same way it carries `Github Issue`: an
optional `Get-AsanaTypeFieldGid` seam in `adopt-bwj-asana`, and a `report-issue` step 2 that sets the
field **from the issue type step 1 already chose** rather than deciding it a second time. Because the
value is carried forward rather than re-derived, a ticket this workflow files cannot end up with a
board type its own GitHub issue contradicts.

The field's **option** GIDs are deliberately not part of the seam -- they are resolvable at run time
from the project `report-issue` is already reading for the section, so pinning three more GIDs per
repo would only add three more values that go stale in silence. What that buys is stated where a
maintainer will meet it: rebuild an option and nothing breaks; rename one away from `Bug`, `Feature`
or `Task` and the write is skipped with a note rather than guessing.

Two things measured on the way in are written down with it. Asana's `opt_fields` takes **no
wildcard**, so the enum options are not free on the call already being made and the exact string is
spelled out; and of the 23 cards on the BWJ board, whose `Github Type` had only ever been filled by
hand, **5 disagreed with the GitHub issue** in both directions -- which is what a hand-fill costs
rather than a drift rate for a step that had never run.

**Score:** 3

#### What makes this deploy extra special

A consuming repo whose board carries the field gets it filled at creation instead of by hand, and
`adopt-bwj-asana` now proposes the seam that turns it on. A consumer whose board carries no such
field sets nothing and sees no change -- `$null` stays the default and the write is skipped silently.
The `bwj-codex` seam register in the plugin README lists both GitHub field seams for the first time,
so the set of values a consumer is expected to answer is readable in one place again.

**Score:** 3

#### Pull Request

set the board's Github Type field from the issue type report-issue already chose

Plugins: bwj-codex

[PR #1390](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1390)

---

### DEPLOY: docs/fix-1386-step5-per-project-not-workspace · 20260904-213204

`WORKFLOW-portable.md` step 5 blamed a self-filed ticket's missing `Prio-Score` on a workspace
boundary; measured against the real BWJ boards the two boards sit in the SAME workspace and still
differ, because a custom field also has to be added to the project (`custom_field_settings`), not
merely defined in a reachable workspace. Step 5 and its echo in step 7 now name that per-project test
instead, with the `GitHub - WH` / `GitHub - SWB` measurement as evidence -- a refinement of #1213 rather
than a duplicate.

**Score:** 3 -- corrects a step that reads as safe when it silently is not: a maintainer following the
old text would conclude a same-workspace project is fine, exactly where `GitHub - WH` shows it is not.

#### What makes this deploy extra special

A BWJ store repo troubleshooting why its self-filed tickets never gain a prio label now gets the test
that actually explains it (is the field added to this project?) instead of one that predicts nothing
useful once workspaces already agree.

**Score:** 2

#### Pull Request

Fix step 5 workspace framing: per-project custom_field_settings gates Prio-Score, not the workspace boundary

Plugins: bwj-codex

[PR #1387](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1387)

---

### DEPLOY: docs/bwj-github-issue-field-convention · 20260904-211725

Documents and closes the write-side of #1377: `bwj-codex` now states the `Github Issue` Asana
custom-field convention -- the full issue URL, never a bare number, because Asana only renders a
text field as a clickable link when its value is a complete URL. `adopt-bwj-asana`'s step 2
proposes an optional `Get-AsanaIssueFieldGid` seam (defaults to `$null`; addressed by GID rather
than by name, unlike `Prio-Score`, because writing a field at creation needs its GID where reading
one back can go by name), and `report-issue`'s step 2 sets that field on task creation when a repo
has configured it. The read-side fallback discussed in the issue is deliberately left out.

**Score:** 3

#### What makes this deploy extra special

A BWJ store repo running `adopt-bwj-asana` (or re-reading `report-issue`) now finds a documented,
optional convention for the board's `Github Issue` field instead of a silent gap filled in by
hand. Nothing changes automatically -- the seam defaults to `$null` and stays silent until a
maintainer sets it -- so no existing repo is affected unless it opts in.

**Score:** 2

#### Pull Request

Document and write the bwj-codex Github Issue Asana field convention

Plugins: bwj-codex

[PR #1384](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1384)

---

### DEPLOY: fix/cut-release-live-stage-order · 20260904-210554

The `cut-release` skill stated **cut-then-push** as a rule for a repo with a live stage — *"Block 1 always
runs first; Block 2 only follows it"* — and this repo's `CONTRIBUTING.md` restated it at 4.7. It is a
default now, and the repo picks the order from one property of its live target.

**The condition, stated where the block is walked:** a push that cannot meaningfully fail — it either runs
or errors loudly, nobody else writes to the target — cuts first, which is what most repos with a deploy
step want, because the audience document then exists before anything reaches a customer. A push that can
**fail or be partial** — no locking on the target, third parties editing it through a web UI while you
work, a drift check that legitimately refuses, a per-file rather than wholesale push — pushes first and
makes the cut the documented closing act of the push.

**What the default gives up, now named rather than left to be discovered.** Cutting first in front of a
fallible push produces a **stranded release**: the tag, the GitHub Release and the audience document all
exist, permanently, describing a state no customer ever saw. Nothing detects it — every artefact is
well-formed — and the only witness is whoever watched the push refuse. The `← LIVE` marker makes it
visible: its own reasoning is that *only the person who did the push knows it succeeded*, which under
cut-then-push makes the marker wrong by construction from the moment the cut lands until a human moves it.
In the repo that reported this, that marker sat two releases behind.

**No seam, deliberately.** `Get-LiveStageCutOrder` was the obvious shape and would have cost a script
contract record, a blueprint entry and asserts to carry a value no script reads — the order is a sentence
a person walks past in a checklist, where `Get-LiveStage` gates whether the block prints at all. It stays
available if a second live-stage consumer ever wants the checklist rendered in its order rather than told
which orders exist.

**This was already the tree contradicting itself, which is what settled it against declaring the old rule
universal.** `team-shopify`'s webshop-manager manual has documented push-then-cut for exactly this case
all along — *"only when the user decides to push; the release is then cut by the release manager"* — so
two pages shipped from one repo disagreed, and inbound
[#1378](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1378) found it from the outside.

**Score:** 3

#### What makes this deploy extra special

A checklist that imposes itself is only as good as its right to impose. This page had one rule it could
not justify, and the tell was that the repo shipping it already ran the other way somewhere else — the
kind of contradiction that is invisible from inside, because each page reads as correct on its own. It
took a consumer walking the checklist against a target that can refuse to surface it.

**Score:** 2

#### Pull Request

Block 2's cut-then-push is a default a live stage can answer differently

Plugins: contributing-davekjohn

[PR #1383](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1383)

---

### DEPLOY: docs/contributing-layering-third-rank · 20260904-205254

`CONTRIBUTING-portable.md`'s layering section ranked only the two consumer documents (the floor and
`contributing-davekjohn/CONTRIBUTING.md`), leaving nothing to say where the plugin's own portable pages
and skills sit relative to either — a vacuum a consumer had filled by declaring its own `CLAUDE.md`
supreme over the shared law itself. A new subsection states the complete three-rank order (the plugin's
law above both consumer layers, scoped to what the plugin actually legislates) and the operational
corollary that keeps it: a consumer document may point at, or answer the seam of, a shared law, but never
restate it — a restatement is a copy, and a copy diverges silently.

Closes [#1379](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1379). Item 3 of that
issue (a prose equivalent of `check-script-contract.ps1` enforcing the corollary automatically) is a
standalone mechanism and is filed separately as
[#1380](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1380).

**Score:** 3

#### What makes this deploy extra special

N/A — this repo already runs the ranking it describes (its `contributing-davekjohn/CONTRIBUTING.md`
already says it wins over its own `CLAUDE.md`); the change closes a documentation gap a consumer had
filled the wrong way, not a rule this repo itself was running incorrectly.

**Score:** N/A

#### Pull Request

State the plugin-law rank above both consumer contributing layers

Plugins: contributing-davekjohn

[PR #1381](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1381)

---

### DEPLOY: fix/sync-main-3b-offline-dryrun · 20260904-113834

The documented offline `-MirrorPath` rehearsal of the pre-task sync works again:
`[3b]` no longer hard-exits a dry run when `origin` cannot be reached. A real
(pushing) run still refuses there, exactly as inbound #1181 built it.

**Score:** 2 -- restores a rehearsal path the plugin's own docstring promises but
`[3b]` had closed; noticed by a maintainer who runs the sync offline against a
mirror, and prevents a consumer working around it in their own test fixture.

#### What makes this deploy extra special

N/A -- team-shopify tooling internals. No subscriber of any consuming service
notices whether the offline dry run stops at `[3b]` or prints its verdict.

**Score:** N/A

#### Pull Request

the sync's [3b] step lets a dry run continue when origin cannot be reached

Plugins: team-shopify

[PR #1376](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1376)

---

### DEPLOY: fix/readme-keys-install-claim · 20260904-105119

`README.md` no longer claims the two settings keys produce no install at all. That absolute was retired
in `INSTALL.md` after inbound #327 and survived here in two places, so the repo's own front page
contradicted its install manual -- and the contradiction was load-bearing enough to generate a false
report (#1371) whose author read the README, measured the register, and concluded the documents were
wrong rather than one of them stale. Both statements now say the keys leave you without a *working*
install, name what they do produce -- a full project-scoped record written after the load phase, by a
session that loads nothing, sometimes pointing at a payload that does not exist -- and send the reader to
`INSTALL.md`'s install step for the mechanics.

**Score:** 3

#### What makes this deploy extra special

The state this repairs is the one a consumer cannot diagnose: a record that says *installed, project
scope, correct sha* while the session is completely inert, with every check that reads the record
agreeing. `README.md` is the first page an adopter opens, and it was the one page that said that state
could not arise -- so an adopter who hit it had been told to look for an absent record instead of an
inert session. The corrected block names the surface to verify instead (is the bootstrap skill in the
slash list, did the session hooks print, does Chris open the turn), which is the check that works when
the administration lies.

**Score:** 3

#### Pull Request

README stops claiming the settings keys produce no install at all

[PR #1375](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1375)

---

### DEPLOY: fix/retire-build-consumernotes · 20260904-104312

`Build-ConsumerNotes` is gone from `scripts/lib/release-lib.ps1`, and with it the second answer to a
question the library should only answer once. It rendered `releases/consumer/<dir>/<X.Y.Z>.md` for the
two-document release flow that became one document on August 11, 2026; that commit dropped the call and
left the function, and nothing has called it since. It was still passing a hard-coded `-EntryLevel 2` --
the literal [#1369](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1369) had just
repaired out of both live renderers -- and its own test pinned that stale answer, which is why the repair
could not reach it.

It is **retired rather than levelled** because levelling needed a container heading invented for a
document nothing generates. In its place is a record in the file's own convention, saying what it built,
why it went, why deletion was the honest repair, and why a pinned consumer cannot be reached by it: the
lib and `cut-release.ps1` ship together from one plugin version.

**The tests were triaged, not deleted with it.** Around forty asserts only ever ran through this
renderer, and every property still true of a document that travels outward moved onto
`Build-ReleaseNoteDraft`, which passes the identical switch set. Two of them now assert something they
could not before: the legacy impact table and the older `Tier: N` line run against a fixture that
actually carries them. And the no-HTML scan came out stronger than it went in -- it covers both generated
documents now, excluding html comments by name, because the draft carries its guidance as comments
deliberately and the scan had been written against a document that had none.

**Score:** 2

#### What makes this deploy extra special

N/A. Nothing a consumer runs changes: the function had no caller, the document it built is not generated
anywhere, and every archived `releases/consumer/` document a consumer may still hold is read by
`check-plugin-integrity.ps1` from disk rather than through this code.

**Score:** N/A

#### Pull Request

Build-ConsumerNotes is retired rather than levelled

Plugins: contributing-davekjohn

[PR #1374](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1374)

---

### DEPLOY: fix/release-note-entry-heading-level-v1 · 20260904-101415

A generated release note keeps a `DEPLOY:` heading at the H3 it was written at, under a
`## Version <X.Y.Z> (<Mon DD, YYYY>)` heading naming the release the entries landed in. It came out
an H2, so the record contradicted the changelog the entry had been copied out of -- and an entry
pasted back out of it landed a level shallower than it was written.

**The defect is a repaired one that came back through its own repair.** `#881` set these entries to
`##` because that was `CHANGELOG.md`'s entry level on August 25, 2026; on August 26 that document
gained `## [Unreleased]`, every entry moved to H3, and this renderer went on promoting them. Nothing
errored and no gate fired: the docstring above the literal and the assert below it both still stated
the repaired claim, so the suite passed against a document that had started disagreeing with its
source again. Every release from v4.11.0 on carries the demoted shape. The level is now asked for --
`Get-EntryHeadingLevel`, the one function that owns it -- so the next move of that pair carries this
document with it instead of leaving it behind.

**The H2 is what the level change needed, and the H1 pays for it.** Entries at their written level
would hang under an H1 with H2 empty, so the release occupies H2 and states its own version and date;
the H1 becomes the constant `# Changelog Releases`, mirroring `CHANGELOG.md`'s own `# Changelog`, so
the version is stated once by the heading that owns the entries rather than twice in four lines. The
date is formatted through the invariant culture: a published record must not read differently
depending on the machine that cut it, and `nl-NL` abbreviates September as `sep.` -- the assert runs
under that culture rather than trusting the flag.

**The `**Date:**` and `**Type:**` pair stays, and that is a reader rather than a preference.**
`new-internal-note.ps1` parses both labels out of this document to build the internal note, so
dropping them would silently degrade a consumer's two-document flow to `(fill in)` and a warning.

**Existing notes are untouched.** They are published records and are not rewritten, so the 60-odd
already cut keep the shape they were cut with; this changes what the next cut writes.

**Score:** 2

#### What makes this deploy extra special

N/A -- a subscriber of a service reads none of this. The document is the raw record written for this
repo's own developers, and the change is to the heading levels inside it.

**Score:** N/A

#### Pull Request

Release notes keep DEPLOY at the H3 it was written at, under a version heading

Plugins: contributing-davekjohn

[PR #1372](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1372)

---

### DEPLOY: fix/duplicate-entry-section-heading · 20260904-094044

`check-plugin-integrity.ps1`'s entry-heading check (check 13) now refuses a changelog entry whose
declared section heading appears more than once -- `#### Pull Request` written twice, say. Both copies
are valid names, so nothing errored before: the entry validated, every gate passed, and the split only
showed in a published GitHub Release body, because the fold stamps and links the last `Pull Request`
heading while the PR body and the release notes read the first. `v4.29.0`'s Release body shipped a
bullet with no PR link that way (issue #1367). The check catches it in both places it already
walks -- the branch's development document (on the PR, and in CI) and `CHANGELOG.md` below its intro
(after a fold, the one write that lands directly on `main`) -- and a heading quoted inside a code fence
is a mention, not a finding.

**Score:** 2

#### What makes this deploy extra special

N/A -- an internal lint gate. No subscriber of any service reaches it; the entry files and `CHANGELOG.md`
it guards are developer-facing.

**Score:** N/A

#### Pull Request

refuse an entry whose section heading appears more than once

[PR #1368](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1368)

---

