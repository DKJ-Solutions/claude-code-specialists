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

## `docs/v4-6-0-release-note` changelog

### Branch title

The v4.6.0 release note

### Branch ID

20260812-235800

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged this evening: the consumer section rewritten from the
cut's draft against the seven writing tests, and the two organisational sections no script can generate.

**The release has a theme, and the *what it is worth* section is built on it.** Three of its defects are one
shape — a hardcoded path where a seam existed, a test that checked the fully-qualified form of that path
while the escape was the short form, and a file selection sorted by a property git does not preserve. None
failed loudly; each produced a populated section, a plausible link or a passing test. The rule written
against it is *when a check and the thing it checks disagree about wording, the check is the one that is
wrong* — which is this release's own repair, generalised.

**The `-NoPush` inspection is recorded as having paid for itself**, because it is the step most likely to be
dropped as ceremony: it had found nothing for several releases and costs a full re-run of the gates when it
does fire. This time it caught the dead overview row before anything was public, which is the whole argument
for keeping it.

**Step 0a was followed this time, and the previous release's note said it was not.** The clock ran from
before the cut, so the document carries its measured legs with the ones that ran behind a person marked as
such, and a frozen subtotal of 46m 05s rather than an estimate. The largest single line is the one nobody had
counted: the same 32 suites ran **ten times** over the release, five locally and five in CI, with the four
timed local runs coming to 26m 58s between them.

**That figure was first written as "four times, twice locally and twice in CI, about 27 minutes" and was
wrong** — it attributed the whole release's local runs to the one mid-release fix, which accounted for two of
them. Corrected by the follow-up branch that added the end-to-end total, while the entry was still pending
rather than published. Worth keeping visible: the release whose theme is *a check and the thing it checks
disagreeing about wording* produced a measured claim in its own note that did not survive being recounted.

**Three things are written into *what was still open* rather than smoothed over**, including one that cost
real time in this very release: the tracked `Microsoft/Windows/PowerShell/ModuleAnalysisCache`, a
machine-local binary committed by accident in `65902dd`, which dirties the tree and had to be restored by hand
twice to get the cut to start. It is deliberately left for its own branch rather than folded into a release
fix.

### Significance

#### Tier 0

The record of what this release cost and why it was re-cut lives here or nowhere; the next person to cut one
reads this document to find out that the inspection step is load-bearing.

**Score:** 3

#### Tier 2

It is the only document written *to* a consumer for `v4.6.0`, and it is where they learn that the two new
seams need no action, what visible symptom the stacked-branch bug left in their own `branch/` files, and that
what `/continue` told them about the last release before this version was unverified.

**Score:** 4

### Pull Request

[PR #634](https://github.com/DaveKJohn/claude-code-specialists/pull/634) · merged 2026-08-13

---

## `docs/v4-6-0-timing-total` changelog

### Branch title

The v4.6.0 release note gains its end-to-end total

### Branch ID

20260813-001510

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists precisely because the release note cannot time its own
publication. `v4.6.0`'s note is frozen at a 46m 05s subtotal; the five remaining legs — writing the document,
its gates, its CI, the merge and the publish — are added, giving a **total of 64m 52s** from clock start to a
published Release with its attachments.

**The tail was 18m 47s, 29% of the total, against two thirds at `v4.4.0` — and the note says that is not an
improvement.** The head was inflated here by a mid-release repair `v4.4.0` did not have. What both
measurements agree on is that the tail is never small enough to estimate, which is the whole argument for two
passes.

**A wrong measured figure in the first pass is corrected rather than left, and named where it was wrong.**
The note claimed shipping one three-line fix ran the 32 suites *"four times — twice locally, twice in CI — for
about 27 minutes"*. The 27 minutes was the whole release's four timed local runs; the fix accounted for two of
them. The real count is **ten runs over the release**, five local and five in CI, with the four timed local
ones at 26m 58s. The pending `CHANGELOG.md` entry for
[#634](https://github.com/DaveKJohn/claude-code-specialists/pull/634) carried the same claim and is corrected
with it — it was still pending rather than published, so this is a repair and not a rewrite of a record.

**The recount also found the two savings the wrong figure was hiding**, which is the reason it was worth
recounting rather than just softening: `ship-pr` re-runs locally what `open-pr` proved minutes earlier on the
same commit, and three of the five CI runs land on commits nobody waits for. The second is worth nothing to
shorten; the first is about seven minutes off every pull request in this workflow. Neither is built here —
this branch is the measurement, not the repair.

### Significance

#### Tier 0

The seven-minute duplicate gate run is now a measured figure somebody can act on rather than a suspicion, and
the total is in the document instead of only in a chat message nobody will find again.

**Score:** 3

#### Tier 2

A consumer reads the release note, so a false measured claim inside it is a claim made to them. This is also
the second release in a row whose note reports its own process failure rather than only its successes, which
is the habit that makes the rest of the document trustworthy.

**Score:** 2

### Pull Request

[PR #635](https://github.com/DaveKJohn/claude-code-specialists/pull/635) · merged 2026-08-13

---

