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

