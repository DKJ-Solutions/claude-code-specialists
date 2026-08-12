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
before the cut, so the document carries eight measured legs with the two that ran behind a person marked as
such, and a frozen subtotal of 46m 05s rather than an estimate. The largest single line is the one nobody had
counted: shipping one three-line fix ran the same 32 suites **four times** — twice locally, twice in CI — for
about 27 minutes of the release's wall clock.

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

