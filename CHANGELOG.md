# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `fix/tier-reason-below-score` changelog

### Branch title

The scaffold gate names a tier reason written below its score instead of calling it missing

### Branch ID

20260811-152836

### Branch type

fix

### What does the change on this branch bring to main?

A tier whose reason was written *below* its `**Score:**` line was refused as `a tier with no reason`. The
refusal was correct -- the fold would have published that tier empty -- but unactionable: "no reason" is the
one thing an author looking at their own three written paragraphs can verify is untrue, so the natural next
move is to distrust the gate rather than to move the text. Reported from a consumer
([#596](https://github.com/DaveKJohn/claude-code-specialists/issues/596)) where all three tiers were
answered and all three were reported as unanswered, and finding out why took reading
`entry-scaffold-lib.ps1` line by line.

The cause was one branch of one loop. `Read-EntryTierSections` collects a section's lines until the next
heading, and `$whyLines.Add($line)` sat behind `elseif ($null -eq $scoreCell)` -- so everything after the
score was read and then thrown away. The text needed to tell the two cases apart was already in hand at the
moment the gate said there was none.

Both halves of the section are now kept, and both gates that read the row say which case they are looking
at. The lines below the score become `WhyBelowScore`, which is diagnosis and never content: nothing
publishes it, nothing counts it as an answer, and the reason still has to move above the score line before
the entry passes. `open-pr.ps1`'s explanatory paragraph gains the third reading it was missing, and states
the rule once -- above the score is the reason, below it is discarded.

Three details that are part of the change rather than alongside it:

- **The filtering is one shared helper**, `Get-EntryTierReasonText`, called for both sides. This format's
  guidance comments live in the section, and one sitting under the score would otherwise read back as a
  misplaced reason -- accusing an entry nobody has written in yet, on every consumer, from the first branch.
  Asserted in both directions.
- **The release gate carried the same misdiagnosis**, which #596 did not report. `Get-EntryImpactFindings`
  reads the same row, so a below-score reason reached `cut-release` with the same unactionable wording --
  days later, when whoever wrote it is no longer the one reading the refusal.
- **The paragraph also still promised per-plugin `CHANGELOG.md` files that travel to consumers.** Those were
  retired on August 8, 2026. It was rewritten anyway, so the false clause went with it rather than being
  left in text this change was already touching.

The report's other suggestion -- moving the blank space *above* `**Score:**` so the mistake is harder to make
-- was deliberately not built. It changes what every consumer's scaffolder writes, and the report files it as
a consideration rather than a proposal. Measured while verifying: the scaffold leaves exactly one blank line
on *each* side of the score, which is why the mistake is easy rather than merely possible, and that
measurement is now written into the code as the reason the distinction exists.

One correction to the report, since the repair was built on reading rather than on it: the loop it describes
is in `Read-EntryTierSections`, not `Resolve-EntryImpact` -- the line numbers it gave were right, the
function name was one off.

### Significance

#### Tier 0

The same refusal runs here, at this repo's own `open-pr` and at its own cut. An author here loses the same
half hour, and the release gate half means it can be met days after the entry was written.

**Score:** 3

#### Tier 1

A colleague on this project meets this at the cut rather than on the branch, which is the expensive end: the
entry is already merged and folded, and the person reading the refusal is not the person who wrote it.

**Score:** 3

#### Tier 2

Consumers receive both gates through a plugin update rather than by choosing to, and the reporting repo lost
the better part of a round trip to a message that had the answer available and did not say it. The local
documentation net written there to stand in for this fix can now be deleted.

**Score:** 4

### Pull Request

Plugins: workflow-davekjohn

[PR #604](https://github.com/DaveKJohn/claude-code-specialists/pull/604) · merged 2026-08-11

---

## `docs/a-per-run-cost-is-counted-over-its-population` changelog

### Branch title

A cost that varies per run is counted over its population, not cited from one run

### Branch ID

20260811-143647

### Branch type

docs

### What does the change on this branch bring to main?

The performance engineer carries a new hard rule: **a cost that varies per run is counted over its
population, not cited from one run.** It sits directly beside *report in the unit the question was asked
in*, because the two are siblings — there the easy number is the wrong **unit**, here it is the wrong
**sample**.

The measured instance behind it, which is what makes it a rule rather than an opinion: a CI gate was
written into a cost model as the fixed cost of a release, taken from one carefully measured run and cited
correctly. The next run came in **25% below it**. Counting every successful run of that workflow — 63
blocking ones — put the recorded figure **exactly on the p90**: the slow tail recorded as the typical,
from a citation that was entirely accurate. Accurate and unrepresentative are not the same property, and
only one of them is visible when you hold a single sample.

Four practices come with it. Ask whether the history is **queryable** before writing a per-run cost as a
fixed number — CI providers, job runners and build systems keep it, so the population is usually one
command away, and collecting a *second* run is the wrong instinct because two anecdotes are not a
distribution. Report an **n, a median and a range**, since a bare point value invites being quoted as
though it had no spread. **Compare sub-populations** where they exist, which separates environmental
variance from a real difference and kills a plausible explanation before somebody builds on it. And then
say **whether the conclusion moved** — in that instance the correction shifted every derived figure by
~7% and changed nothing concluded from them, which is worth stating outright: a model whose shape
survives a large error in its largest input is one worth deciding on, and that is a different claim from
the model being precise.

This repo's lens keeps the measured instance and now points at the rule, matching how the unit rule is
already split between the two layers: the manual carries the craft, the lens carries the evidence.

### Significance

#### Tier 0

The lens had recorded this as a one-off correction to one number. Promoting it to the manual means the
next per-run cost measured here — a suite, a build, a script — meets the rule before the figure is
written down, rather than after it has already been quoted. It also closes the split honestly: the
instance and the rule now point at each other, instead of this repo holding both halves in its own layer
where nobody downstream would ever receive the rule.

**Score:** 2

Is this change also relevant to colleagues and employers? Yes — continue to Tier 1.

#### Tier 1

Cost figures are what delivery and capacity arguments get built on, and a single-run figure is the most
citable and least reliable form they come in. The rule prevents the specific failure that was caught
here: a tail value entering a decision document as the typical cost, with a correct citation attached
that makes it look verified. The reassurance travels with it — the conclusions survived the correction,
so the lesson is about how to report a cost, not a warning that the cost model was unsound.

**Score:** 2

Is this change also relevant to customers and users? Yes — continue to Tier 2.

#### Tier 2

The rule ships in the performance engineer's manual, so every consumer receives it on their next plugin
update and it applies to every cost question they put to him — not only to CI, and not only to releases.
A consumer measuring their own test suite, build or gate gets the discipline that turns one stopwatch
reading into a defensible figure, including the instruction to report an n and a range so their own
readers can judge it. Nothing they run changes and no command moves; this is craft their specialist did
not have before.

**Score:** 3

### Pull Request

Plugins: team-alpha

[PR #601](https://github.com/DaveKJohn/claude-code-specialists/pull/601) · merged 2026-08-11

---

## `docs/a-release-note-cannot-time-its-own-publication` changelog

### Branch title

The release note carries its own total, and step 0a says where each half goes

### Branch ID

20260811-105337

### Branch type

docs

### What does the change on this branch bring to main?

**Step 0a asked for a number the release note structurally cannot contain, and running it once was what
exposed that.** The instruction said: note the clock before the cut, note it again when the Release is
published, write the end-to-end duration into the release document's organisational section. All three
halves are right and the combination is impossible — the note is frozen for its own pull request at step 4,
and the Release is published at step 5, so while the timing section is being written its CI gate, its merge
and the publish are all still running on that very file.

**The size of the gap is the argument.** At `v4.4.0` the subtotal available at freeze was **9m 42s** of a
release that came to **28m 03s**: the unmeasurable tail was **two thirds**. A document carrying only the
first pass is not slightly incomplete, and the predictable failure is that whoever writes it fills the gap
with an estimate — in the one section whose entire point is that the figure was measured rather than felt.

**So the step is two passes now, and the second one is expected rather than exceptional.** At step 4 the
document gets the clock start, the legs already readable off timestamps, the subtotal to freeze, and which
of them blocked a person — the half that cannot be recovered later. After step 5 the total is added in its
own small pull request, together with the three legs the first pass could not see. This branch *is* that
second pass for `v4.4.0`, which is why the number it adds is a measurement and not a worked example.

**Two wrong repairs are refused by name, because both suggest themselves before the right one.** Publishing
the Release earlier would make the total writable in one pass and would put the page up before its
attachments exist, which is exactly what step 5's ordering is for — the tail of a release is cheap to
measure twice and expensive to publish twice. And letting the total live only in the closing report to the
requester is refused too: a chat message is not where the next person looks for what a release costs, which
is the whole reason the number was asked for in a document.

**The measurement itself lands in three places, each for a different reader.** The v4.4.0 note gets the full
leg table and the 56% gate share; [Nolan #25](.claude/specialists/lenses/06-25-extension.md)'s first
outstanding number is answered with both cautions attached — that release carried two entries against
`v4.2.0`'s seven, so it measures the clock well and the writing gain not at all, and 28m 03s **confirms** the
~30 min everyone had been reasoning about rather than improving on it; and
[Rendall #06](.claude/specialists/lenses/05-06-extension.md)'s clock paragraph learns that noting the time is
a two-pass job for him specifically.

### Significance

#### Tier 0

The repo's most-repeated expensive procedure has a complete measured duration for the first time — 28m 03s,
56% of it gates, all of it blocking — and the instruction that produces it no longer asks for something
impossible.

**Score:** 4

#### Tier 1

An improvement cycle that could not state its result in the asked-for unit now has a figure that can be
compared against the next one, with the two conclusions it does *not* license written down beside it.

**Score:** 3

#### Tier 2

The corrected step travels: a consuming repo following step 0a would have hit the same impossibility, filled
it with an estimate, and had no way to tell that two thirds of the number was guessed.

**Score:** 3

### Pull Request

Plugins: workflow-davekjohn

[PR #594](https://github.com/DaveKJohn/claude-code-specialists/pull/594) · merged 2026-08-11

---

## `docs/v4-4-0-release-note` changelog

### Branch title

The v4.4.0 release note, and the first release this repo timed

### Branch ID

20260811-103026

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this morning — and the first release note in this repo
that answers *"how long does a release take"* in minutes, which is the whole reason the previous branch
existed.

**The number that had no owner now has one.** `v4.3.0` ran a full cycle against the thirty-minute release,
demonstrably improved it, and reported **43% fewer words** because words were what somebody had counted.
Step 0a was written to close that, and this is its first run: the clock was noted at **10:24:11** before
anything was cut, and the legs are taken from git timestamps rather than recalled — **5m 07s** from clock
start to the release commit, covering the repo-state check, the checklist walk, the lint gate, the 30 test
suites at **231s**, the writes, the commit and the tag.

**The document names the boundary it cannot cross, and that is the part worth keeping.** A release note is
frozen before the Release is published, so the last two legs — the pull request's CI gate and the publish
— are running *on the document itself* while it is written. Rather than estimate them into the total, the
section states the subtotal to freeze, marks the release commit's own CI as the non-blocking leg it is, and
reports what `lint-en-tests` has actually cost across the four most recent runs (**8m 41s to 9m 20s**),
which is the largest single thing a person waits on. The closing report carries the end-to-end figure. A
document that estimates its own tail is the failure step 0a was written against, one recursion deeper.

**And it writes down the conclusion nobody should draw from it.** This release carried two entries against
`v4.2.0`'s seven, so it is a good test of the clock and a weak one of the writing gain — less to read is
less to write, and the merged-document model is not shown to be faster by a smaller release. The caveat is
in the organisational section instead of being left for a later reader to reconstruct, together with the
admission that cutting this soon after `v4.3.0` works *against* the cadence lever the performance engineer
had just named: it was paid deliberately, because a baseline cannot be taken retroactively.

**One defect found by walking the checklist, and routed rather than repaired here.**
[`releases/README.md`](releases/README.md)'s tier table still named `consumer/<dir>` and `internal/<dir>`
as the tier-2 and tier-1 documents, four days after both were merged into `notes/`. No gate sees it: a
directory named in a table cell is prose, not a link, and lint check 4 reads links. It is the technical
writer's change and belongs in its own branch, so this one records it in the release note's *still open*
section and leaves it there.

### Significance

#### Tier 0

The repo's most-repeated expensive procedure has a measured duration for the first time, with the split
that decides whether any proposal about it is worth anything — two of the three gate runs block a person,
the third does not.

**Score:** 4

#### Tier 1

An improvement cycle that could not state its result in the unit it was commissioned in now has one that
can, and the document says out loud which comparison this release does *not* license.

**Score:** 4

#### Tier 2

This is the document a consumer receives. It carries the one new thing to do — time your own release — and
states plainly that nothing breaks and no command changes.

**Score:** 3

### Pull Request

[PR #593](https://github.com/DaveKJohn/claude-code-specialists/pull/593) · merged 2026-08-11

---

## `docs/the-release-overview-describes-one-document` changelog

### Branch title

The release overview describes the one document it actually writes

### Branch ID

20260811-115645

### Branch type

docs

### What does the change on this branch bring to main?

`releases/README.md` still described the retired three-document model four days and two releases after
the August 10, 2026 merge into one hand-written note with a named section per reader — a stale claim no
gate could see, because the drift sat in table cells and prose rather than in a link (lint check 4 is
deliberately scoped away from a path in prose) and never touched a live-figure sample either (checks 15/16
guard those, not a document-count claim). This branch corrects it: the tier table, `## The three documents`
(renamed `## The release documents`) and its three `### Tier N` sub-sections are rewritten around the
merged `notes/<dir>/<X.Y.Z>.md` with its *For consumers* / *What it is worth* / *What was still open*
sections, cross-checked against `cut-release.ps1`, `release-lib.ps1`'s `Build-ReleaseNoteDraft`, the
`cut-release` skill and Rendall's lens rather than invented from summary. Two further staleness sites
turned up while reading the "Cutting a release" section for correctness rather than rewrite: the GitHub
Release closing step still said the body came from the internal note (it is generated), and the seam-value
note still described `new-internal-note.ps1` writing the overview's Version cell (the cut writes it itself
now). Both are corrected. The published release list at the bottom of the page — rows, `#### 4.x` heading,
the `release-lib.tests.ps1` major pin — is untouched, as required: those are published records and a live
test asserts against that exact heading.

**And the same defect was carrying a false claim in `CLAUDE.md`, which is why it is in this branch rather
than a later one.** The constitution said the note's inbound Version cell is *"written by
`new-internal-note.ps1` rather than by the cut"*, and pointed at `Set-ReleaseInternalNoteLink` for why it
*could not* be the cut's job. That reasoning was correct on August 5 and expired on August 10: it could not
be the cut's job while the note did not exist during the cut, and the merge made the cut **draft** the note,
so there is a real file to point at by the time the row is written. Verified against the tree rather than
inherited — `cut-release.ps1:794` says so in its own comment, `Set-ReleaseInternalNoteLink` is still called
by `new-internal-note.ps1` alone for the two-document flow, and `v4.4.0`'s row pointed at
`notes/4.x/4.4.0.md` on the first write with nothing repointing it. Same August 10 movement, same class of
drift, one document further in — so it belongs in the same entry rather than being filed as an unrelated
find. What generalises is the shape: **when a mechanism moves, the sentence explaining why it could not move
is the one that survives longest**, because it reads as reasoning rather than as a fact anyone re-checks.

### Significance

#### Tier 0

The class of defect this closes — a written convention that moved while the scripts moved with it, leaving
only the prose behind — is exactly the shape this repo's own docs sweeps keep finding (inbound #508, #556,
#557, #561 are all instances of the same pattern: a mechanism changes and no gate reads the sentence
describing it). `releases/README.md` is the page a release manager actually opens mid-checklist, so a
developer following it during the next cut would have hit "the consumer document" and "the internal note"
and had to reconcile that against what `cut-release.ps1` actually printed.

**Score:** 2

#### Tier 1

Colleagues on this project read this page to understand how a release is put together and what it costs;
a page that describes a retired model teaches the wrong mental model of the one document that now carries
both the *For consumers* section and the organisation's two sections. This is the release process's own
reference page, not a peripheral doc.

**Score:** 3

#### Tier 2

**This page's portable half exists to be copied**, and that is the half that was stale. Its own mirroring
instruction tells an agent that everything above the horizontal rule *"is portable and can be copied
as-is"* — and `releases/` sits in every consumer's plugin cache, because a marketplace source is a git
clone of the whole repository. So for four days, anyone mirroring this workflow into their own repo copied
a retired three-document model and would have built their release process around two documents their
scripts no longer write.

Small rather than urgent: it needs a mirroring to have happened inside that window to bite anyone, and
nothing a consumer already has stops working. But it is not nothing, and it was first assessed as `N/A` on
the premise that a consumer cannot reach this page — which its own mirroring section disproves.

**Score:** 2

### Pull Request

[PR #597](https://github.com/DaveKJohn/claude-code-specialists/pull/597) · merged 2026-08-11

---

## `docs/the-cadence-is-counted` changelog

### Branch title

The cadence is counted against the fixed gate cost

### Branch ID

20260811-135241

### Branch type

docs

### What does the change on this branch bring to main?

Nolan's third open number — the release cadence against the fixed gate cost — is counted, and his lens
carries the measurement instead of the question. The decision it feeds is deliberately left open: it is
Dave's, and counting it does not make it.

What is now written down rather than estimated: the cadence recount (**16 releases in the 10 days to
August 11, 2026** — the same number as the previous window over a different mix, 13 minor, 1 major, 2
patch, with **no patch at all** in the last seven days), the fixed gate cost **split by bump type**
(**15m 47s** blocking for a minor or major, **3m 51s** for a patch, which writes no document and so opens
no pull request and meets no blocking CI), and what the window cost at that price: **3h 48m 40s of
blocking gate time in 10 days, 22.9 minutes per day**.

Both sides of the trade are priced in the same table, because `plugin.json`'s version is one of the two
update gates and releasing less often is delivering later. The saving is simulated against the **real 73
merge timestamps** in the window; the delivery cost is **measured** as merge → next tag (mean 7.45h today).
Two findings come out of it and neither is the choice: the **ceiling is low** — the entire lever is worth
under four hours per ten days — and the **first step is the efficient one**, 16 → 8 releases capturing 48%
of that ceiling at 29.5 minutes saved per added hour of delivery delay, against 2.4 minutes at weekly.

Measured rather than assumed at four points, each of which could have gone the other way. The patch cost
rests on `releases/consumer/3.x/` and `releases/internal/3.x/` holding documents for every minor in the
window and **none** for `3.1.1` or `3.1.2`. The merge list and the release list cross-check: exactly **4**
of the window's 77 merges are unreleased, matching the four entries pending in `CHANGELOG.md`. The
window's releases are re-priced at **today's** gate cost, with the note that nine of the sixteen predate
`fix/release-runs-the-suites` (#514) and so historically paid less — a re-pricing of past volume, which is
the only pricing a forward cadence decision can use. And a **3-second discrepancy is left standing**: the
`v4.4.0` note states 15m 44s of gates while its own components sum to 15m 47s, so the separately measured
components are what the lens uses.

The paragraph that estimated "~17 minutes of fixed gate time" is repointed at the measurement that
replaced it.

### Significance

#### Tier 0

An open question in a lens has become a citable cost model: a developer opening Nolan's lens now finds
what a release costs, split by bump type, instead of the question of what it costs. It also removes an
estimate that was quietly wrong in a way that mattered — "~17 minutes" averaged two bump types whose real
costs differ by a factor of four, so any reasoning that used it under-priced a minor and over-priced a
patch.

**Score:** 3

Is this change also relevant to colleagues and employers? Yes — continue to Tier 1.

#### Tier 1

The organisation now knows what its delivery rhythm costs and what changing it would buy, in minutes and
in hours of delivery delay, on the same table. The useful half for a colleague is the shape rather than
any single figure: the whole lever is worth under four hours per ten days, and its steps are sharply
diminishing, so a cadence decision is not a slider where further is better. That is the kind of finding
that stops a plausible efficiency drive before it costs engineering time.

**Score:** 2

Is this change also relevant to customers and users? No — see Tier 2.

#### Tier 2

Nothing here reaches a consumer. The measurement lives in `.claude/specialists/lenses/`, which is this
repo's own layer and never travels in the plugin; no shipped script, skill, manual or manifest changes,
and the cadence decision that could eventually affect delivery timing is deliberately not made on this
branch.

**Score:** N/A

### Pull Request

[PR #599](https://github.com/DaveKJohn/claude-code-specialists/pull/599) · merged 2026-08-11

---

## `docs/markdown-only-does-not-mean-script-free` changelog

### Branch title

Nine of thirty suites read this repo's own markdown

### Branch ID

20260811-113314

### Branch type

docs

### What does the change on this branch bring to main?

Answers item 2 of Nolan #25's own "three numbers owed" list in
[`06-25-extension.md`](.claude/specialists/lenses/06-25-extension.md#wall-clock-here--the-gates-and-the-baseline-measured-at-v420-august-10-2026):
which of the 30 suites in `scripts/tests/*.tests.ps1` can change behaviour on a markdown-only diff. Measured
rather than guessed, over all 30 files: **9** read this repo's own real markdown for content and can flip on
a docs-only diff, **21** build and read only their own fixtures and cannot, **0** were undecided. So the
assumption "markdown-only, therefore skip the second local run" does not hold in this repo — 9 of 30 read
real content a docs change can move.

The transferable half is not the count but the method that produced it, and the reason that matters is the
result it caught: the obvious guess — that the lint-gate suite (`check-plugin-integrity.tests.ps1`), which
exercises checks over agent defs, manuals and the changelog, must be one of the nine — is wrong. It builds
every document into its own fixture and is in the 21. A guess sorted by "sounds document-heavy" would have
put the wrong nine in the risk bucket; only reading each suite's source and citing the line that reads (or
doesn't read) the real repo root got the right nine. That is the repeatable part for any future "can a
diff of shape X change behaviour in suite Y" question: cite the line, don't infer from the suite's name or
subject matter.

No recommendation is made about whether to change how the second local run works — that is a change to
this repo's safety rules and is not this branch's decision to take.

### Significance

#### Tier 0

A repo-internal cost question — is a tempting optimisation (skip the second local suite run on a
markdown-only diff) actually safe here — is closed with evidence instead of instinct, and the answer is "no,
don't", with the nine named suites and their exact triggers as the record. That refusal-on-measurement is
the substantive part: without this branch, the next person tempted by that shortcut would either skip it on
a hunch (and might silently lose coverage on the 9) or re-derive the same 30-file audit from scratch to be
sure.

**Score:** 4

#### Tier 1

Colleagues on this project gain a citable answer to a question that was open in the shared lens, plus the
method (read the source, cite the line) for the next such audit — useful, but it is the same fact as tier 0
seen by a different reader, not a new one.

**Score:** 2

#### Tier 2

This measurement is about *this* repo's own thirty suites and their real-file reads — a consumer has a
different suite set, if any, and would have to re-run the same audit against their own tree rather than
inherit this count. Only the method travels, and the method is already carried by tier 0/1's record of how
it was done; there is nothing here written for a consumer to read.

**Score:** N/A

### Pull Request

[PR #595](https://github.com/DaveKJohn/claude-code-specialists/pull/595) · merged 2026-08-11

---

## `docs/the-cadence-stays-unconstrained` changelog

### Branch title

The release cadence stays unconstrained, by decision

### Branch ID

20260811-145444

### Branch type

docs

### What does the change on this branch bring to main?

The release cadence is **decided, not merely counted**: there is no cap and no rule, and cutting stays
available whenever Dave wants it. His words: *"ik wil gewoon kunnen snijden wanneer ik wil, dat moet niet
begrensd worden."* Nolan's third open number is now answered *and* acted on.

**The reason this is written down at all is that the decision changes nothing.** A decision to leave
things as they are is the one most likely to be mistaken for an unanswered question — and the lens had
just acquired a table showing that batching would save real time, with the choice recorded as open. Any
later reader arriving at that table without the answer beside it would reasonably re-propose the lever,
which is exactly the wasted round the record exists to prevent. So the decline is stated where the
proposal lives, and it names what would have to change for it to be revisited: new evidence that the
ceiling has moved — a materially slower gate, or a much higher release rate — not a re-reading of the
same table.

Three things make it a decision rather than a deferral, and all three are recorded. **The size of the
prize settles it**: the entire lever is worth at most ~20 minutes per day of blocking gate time, which is
the releaser's own waiting, and that does not buy a standing rule removing the freedom to ship on demand
— had the ceiling been four hours a day the same table would have argued the other way, which is why
counting it first was worth doing. **There was never a mechanism to change, only a habit**: a release
happens on explicit request, so the 16 releases in the measured window were 16 requests, and a cadence
policy could only ever have been a self-imposed constraint plus a brief telling the release manager to
propose fewer. And **the counterweight ran in the same direction**, which is unusual enough to note:
batching would have traded the releaser's minutes for consumers' hours, so the cheap side and the
fast-delivery side agreed and declining costs nothing on either.

### Significance

#### Tier 0

A measured proposal now carries its verdict in the same place, so nobody re-derives a lever that has been
priced and declined. The specific waste it prevents is a plausible and recurring one: the table showing
1h 35m to 3h 03m of savings is genuinely persuasive read on its own, and a session finding it without the
answer would open the question again — this time without the context that the freedom to release on
demand was the thing being traded away.

**Score:** 2

Is this change also relevant to colleagues and employers? Yes — continue to Tier 1.

#### Tier 1

The delivery rhythm is settled and stays as it is: work reaches a release as soon as somebody asks for
one, with no batching window in between. Anyone reasoning about how quickly merged work becomes available
can take the current mean of 7.45 hours as the standing state rather than a figure about to change.

**Score:** 1

Is this change also relevant to customers and users? No — see Tier 2.

#### Tier 2

Nothing reaches a consumer, and the outcome is that nothing about their delivery changes. The record lives
in `.claude/specialists/lenses/`, this repo's own layer, which never travels in the plugin; no shipped
script, skill, manual or manifest is touched. The one consumer-relevant effect is an absence — releases
are not slowed down — and an absence needs no announcement.

**Score:** N/A

### Pull Request

[PR #602](https://github.com/DaveKJohn/claude-code-specialists/pull/602) · merged 2026-08-11

---

## `fix/the-ci-leg-is-a-distribution` changelog

### Branch title

The CI leg of the gate cost is a distribution, not a single run

### Branch ID

20260811-141746

### Branch type

fix

### What does the change on this branch bring to main?

The largest component of the release gate cost — `lint-en-tests` on a pull request — was recorded in
Nolan's lens as **8m 36s**, correctly cited from the `v4.4.0` release but taken from one run. It is now
recorded as what it is: **median 7m 23s, range 5m 17s–9m 27s over 63 blocking runs**.

**The figure was the p90 presented as the fixed cost.** The pull request that recorded it came in at
6m 25s, 25% below the number it had just written down, which prompted counting every successful run of
`ci.yml` instead of collecting a second anecdote. `v4.4.0`'s run sits **exactly on the p90** of that
population. The 6m 25s was never an outlier — it falls between the minimum and the median.

Two things the population settles that a second sample could not. The `pull_request` and `push`
distributions are near-identical (median 7m 23s against 7m 16s, over 63 and 134 runs), so this is **runner
variance and not a property of the event type** — which rules out the tempting explanation that a
docs-only diff runs faster. And a cost with a 4m 10s spread is now written with its range beside it, so it
cannot be quoted as a point again.

**Every derived figure moved by about 7% and no conclusion moved at all**, which is recorded as a finding
rather than quietly patched: a minor now costs 14m 34s instead of 15m 47s, the 10-day window 3h 31m 38s
instead of 3h 48m 40s, and the ceiling of the whole batching lever 3h 17m instead of 3h 32m. The scenarios
scale by a common factor, so the ceiling stays under four hours, the 48% capture at one-release-per-day is
unchanged, and the first step remains worth roughly twelve times the last. A model whose shape survives a
25% error in its largest input is one worth deciding on — a different claim from the model being precise.

**What was deliberately not done.** The two local suite legs (231s in the cut, 200s and 226s at `open-pr`)
are left exactly as measured. They are an n=1 and an n=2 standing next to an n=63, and manufacturing a
distribution from two points would repeat at smaller scale the error this change corrects. The 3-second
discrepancy in `v4.4.0`'s own stated gate total is kept as a live note about that document, now that the
total it concerns is no longer what the model uses.

### Significance

#### Tier 0

The number a developer opens Nolan's lens to find is the one they would build a cost argument on, and it
was the slow tail of its own distribution. It now carries an n, a median and a range, so the next reader
can see how much confidence it deserves without re-deriving it. The correction also demonstrates the check
that produced it: where a cost varies per run and the history is queryable, the population is one command
away and beats a second anecdote.

**Score:** 3

Is this change also relevant to colleagues and employers? Yes — continue to Tier 1.

#### Tier 1

It prevents a specific and likely failure rather than improving anything observable: quoting 8m 36s as
"what CI costs" in an organisational discussion about delivery, when that is the p90 and the typical run
is a minute and a quarter shorter. Nobody had made that argument yet, which is exactly why the repair is
cheap now. What a colleague gains beyond the corrected number is the reassurance that the cadence
conclusions never depended on it.

**Score:** 1

Is this change also relevant to customers and users? No — see Tier 2.

#### Tier 2

Nothing reaches a consumer. The change is confined to `.claude/specialists/lenses/`, this repo's own
layer, which never travels in the plugin; no shipped script, skill, manual or manifest is touched. The
portable half of the lesson — that a per-run cost is counted over its population rather than cited from
one run — is deliberately left for a separate decision about Nolan's shipped manual.

**Score:** N/A

### Pull Request

[PR #600](https://github.com/DaveKJohn/claude-code-specialists/pull/600) · merged 2026-08-11

---

