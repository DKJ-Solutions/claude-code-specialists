## `docs/major-prep-exception` changelog

### Branch title

The release exception names the preparation a major needs

### Branch ID

20260809-215721

### Branch type

docs

### What does the change on this branch bring to main?

Cutting a new major takes two commits that land directly on `main` **before** `cut-release.ps1` will run
at all: the `#### <X>.x` section in the release overview, and the live assert that pins which major the
overview targets. `v4.0.0` needed both by hand on August 9, 2026 (`b2cea9c` and `1d2d3ff`) — under a
release exception that on paper covered only the release commit itself.

The exception now says so. The safety rules gain the mirror image of the rule they already carry for the
closing steps: preparation a requested cut cannot run without is covered by that same request, and
**bounded by it** — a major only, those two paths only, and only once the cut has been asked for. Outside
a cut both files take the ordinary branch + PR route. The same statement lands in Rendall #06's lens as a
numbered step 0, and in the portable `cut-release` skill, so a consumer cutting their own major does not
meet the refusal without knowing there is a documented way through it.

Neither half is automated, deliberately: opening the section is the milestone moment the script leaves to
a person, and the assert is one fact written twice on purpose — a script that repointed it would remove
the tripwire that caught the half-done edit here. What *was* repaired is the advice. The refusal named
only the section, so following it exactly still produced a red test and a second, unannounced commit; it
now names both edits and where they belong, pinned by four asserts in `cut-release-guardrail.tests.ps1`
against the block itself rather than the file, so the explanation in the comments cannot satisfy them.

### Significance

#### Tier 0

A major is not rare here — `v1.0.0` through `v4.0.0` fell on July 14, July 23, July 30 and August 9,
2026, roughly one every nine days — so the next person to cut one meets this within a fortnight, and
meets it as a documented step instead of an exception they have to decide about mid-cut.

**Score:** 3

#### Tier 1

The rule that was actually followed is on paper now, at its granted size. The value for a colleague is
less the procedure than the bound around it: this repo has already paid once for an exception that grew
past what it was granted at, and this one records its own limits in the same breath as its permission.

**Score:** 2

#### Tier 2

Both the refusal text and the `cut-release` skill travel to consumers. A consumer cutting `X.0.0` hits a
guardrail whose advice used to be complete-looking and short by one edit; they now get both, plus the
statement that these commits belong to the cut they already authorised.

**Score:** 3

### Pull Request

