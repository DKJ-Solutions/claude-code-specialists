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

## `fix/audience-tier-strings` changelog

### Branch title

The visible tier strings state the post-#620 audience definition

### Branch ID

20260813-124219

### Branch type

fix

### What does the change on this branch bring to main?

Every string a human reads when answering the tier question now states the post-#620 audience
definition — tier 1 is management and the employer/commissioner, tier 2 is the subscriber of a
service — where all of them still carried the pre-#620 ladder ("a colleague working on this project" /
"a consumer of the product notices it"). Inbound
[#640](https://github.com/DaveKJohn/claude-code-specialists/issues/640) measured that the two
definitions produce opposite answers for the same repo: a webshop's customers are literally "consumers
of the product", so the old wording sent the one worked example the new model is built on to tier 2
instead of tier 1 — and one consumer (life-hub) had already answered its `Get-ReleaseAudienceTier`
knob wrong from these strings, declaring tier 2 structurally N/A and cutting every release as a patch.

Repaired, verified against the tree before building: the routing questions and UNCOMMENT openers in
`entry-scaffold-lib.ps1` (`Route0`/`Route1`/`Uncomment1`/`Uncomment2`), the refused-entry tier table in
`open-pr.ps1`, the tier tables in `new-branch/SKILL.md` and `CONTRIBUTING-portable.md`, and four
sites the issue did not name: the tier tables in `branch/README.md` and `open-pr/SKILL.md`, and the
two gate-refusal messages in `cut-release.ps1` (the tier gate and the significance gate) — found by
the verification sweep and the pre-PR reviews. Two source comments that still stated the cumulative
model as current (`release-lib.ps1`, `new-internal-note.ps1`) now mark it as the pre-#620 reading. Both doc tables now also carry the
webshop worked example, since that is the case that separates the two kinds of audience. The
contradiction inside `entry-scaffold-lib.ps1` — the cumulative ladder at one comment block and the
one-audience model thirty lines below it — is resolved: the ladder block now marks itself as the
superseded half and points at the block that wins. The retired route questions joined
`EntrySignificanceRetiredRoutes` so in-flight entries scaffolded with the old wording keep being
filtered from the `Why` sections everywhere — recognise both, write one. `branch/templates/` is
regenerated from the new wording, and both scripts' plugin mirrors travel byte-for-byte.

Deliberately left standing: `Get-ReleaseTierHeading`'s `Tier 1 - colleagues` heading in the
development notes. It does not feed the audience decision, it is machine-parsed by the internal-note
generator, and every existing development note carries it — renaming it is a separate decision, not
part of this defect.

### Significance

#### Tier 0

Source readers of `entry-scaffold-lib.ps1` no longer meet two contradicting tier definitions thirty
lines apart, with only the wrong half getting printed.

**Score:** 2

#### Tier 2

The strings a consumer reads when answering the `Get-ReleaseAudienceTier` knob — the new-branch table,
the scaffolded template comments, the refused-entry printout — gave the inverted answer, and the knob
is `Adopt = 'decide'`, so every repo taking the update is asked to answer it from exactly these
strings. One consumer already answered wrong and had its release cadence silently degraded to
patches; after this, the visible definition and the model agree.

**Score:** 4

### Pull Request

Plugins: workflow-davekjohn

[PR #645](https://github.com/DaveKJohn/claude-code-specialists/pull/645) · merged 2026-08-13

---

## `docs/v4-7-0-release-note` changelog

### Branch title

The v4.7.0 release note

### Branch ID

20260813-115746

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this morning: the consumer section rewritten from the
cut's draft against the seven writing tests, and the two organisational sections no script can generate.

**The release has a theme and the *what it is worth* section is built on it.** Three of the six changes are
the same shape — a hardcoded path sitting behind a working seam, a skill page showing an entry block the
scaffolder has never written, and a step-list convention satisfiable only by ticking a box for work not
done. None failed loudly; each produced a plausible page, a passing gate or a populated directory. It is the
shape `v4.6.0` named, found three more times by looking for it rather than by being bitten again.

**The consumer section leads with the one item that asks anything of the reader**, and hands them a one-line
test for whether it reaches them at all: if `Get-ReleaseNoteRoot` answers anything other than
`releases/notes`, the hardcoded directory would have hard-failed their first cut into a new major. The other
two items are corrections to pages they may have copied from, and the fourth points back at `v4.6.0`'s notes
rather than repeating them.

**Step 0a's first pass is a subtotal of 15m 31s, and the comparison it invites is the honest half.** That is
three times less than `v4.6.0`'s frozen 46m 05s, and the document says plainly that the process did not get
faster: that release carried a mid-release repair and needed two manual interventions before the cut would
start. Both causes were removed by work shipped in this release, so this is the first cut in three to start
on the first attempt.

**Four things go into *what was still open* rather than being smoothed over**, including the one this release
paid again without building: `ship-pr` re-runs locally the same 32 suites `open-pr` proved minutes earlier on
the same commit, about seven minutes per pull request, measured at `v4.6.0` and still unbuilt.

### Significance

#### Tier 0

The record of what this release cost, and of the first cut in three that started on the first attempt, lives
here or nowhere. It is also where the next person reads that the `-NoPush` inspection and the two-pass timing
are load-bearing rather than ceremony.

**Score:** 3

#### Tier 2

It is the only document written *to* a consumer for `v4.7.0`, so it is the only place they learn whether this
version asks anything of them. It carries the one item that does — with a one-line check for whether the
hardcoded release-note directory ever reached their repo — and tells them what changed in the two skill pages
they may have copied an entry block from.

**Score:** 4

### Pull Request

[PR #641](https://github.com/DaveKJohn/claude-code-specialists/pull/641) · merged 2026-08-13

---

## `docs/v4-7-0-timing-total` changelog

### Branch title

The v4.7.0 release note gains its end-to-end total

### Branch ID

20260813-121522

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.7.0`'s note was frozen at a 15m 31s subtotal; the five remaining legs — writing the
document (4m 23s), its gates (3m 15s), its CI (7m 35s), the merge with the fold (3m 18s) and the publish
(27s) — are added, giving a **total of 34m 57s** from clock start to a published Release with its
attachments.

**The tail was 19m 26s, 56% of the total**, against 29% at `v4.6.0` and two thirds at `v4.4.0`. Three
releases have now been timed and produced three very different fractions, which is the argument for two
passes stated more strongly than one measurement could: the tail is not merely large, it is unpredictable,
so an estimate written at the freeze would have been wrong in a different direction each time.

**A figure carried forward from `v4.6.0` did not survive being measured, and it is the one somebody was
about to act on.** That note put the duplicate gate run — `ship-pr` re-running locally what `open-pr` proved
minutes earlier on the same commit — at *about seven minutes off every pull request*. Timed end to end
here, `open-pr`'s whole leg was 3m 15s and `ship-pr`'s 3m 18s, so removing the second run recovers **a
little over three minutes**, not seven. The saving is still real and still the largest single one on the
table; it is half the size the plan assumed. Both the note's *what it is worth* section and its *still open*
bullet are corrected, and the bullet now carries the measured figure rather than the inherited one.

**The copy attached to the GitHub Release is the frozen one**, and the note says so rather than leaving a
reader to discover that the file in the repository and the file they downloaded disagree. Re-uploading the
asset was considered and not done: an attachment is what was published at the moment of publication, and
silently replacing it is the opposite of the record this document is for.

### Significance

#### Tier 0

The seven-minute estimate is the number the next optimisation would have been budgeted against, and it was
wrong by half. Correcting it before anyone builds against it is worth more than the saving itself, and the
third timed release is what turns "the tail is large" into "the tail is unpredictable" — which is the actual
case for the two-pass method.

**Score:** 3

#### Tier 2

A consumer reads the release note, so a measured claim inside it is a claim made to them — and this one
would have shaped what they chose to optimise in their own workflow. This is also the third release running
whose note reports its own corrected figure rather than only its successes, which is the habit that makes
the rest of the document worth trusting.

**Score:** 2

### Pull Request

[PR #642](https://github.com/DaveKJohn/claude-code-specialists/pull/642) · merged 2026-08-13

---

