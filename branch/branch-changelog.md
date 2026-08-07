## `fix/consumer-templates` changelog

### Branch description

A consumer repo gets the branch templates too

### Branch ID

20260807-132519

### Branch type

fix

### What does the change on this branch bring to main?

`new-changelog-entry.ps1` writes `branch/templates/` into the repo it runs in, and rewrites a copy that has
drifted from the current format.

**This repairs a regression that shipped in v3.7.0**, found by red-teaming a documentation proposal rather
than by anyone reporting it. Until now **nothing created those templates anywhere**: they exist in this repo
because they were written by hand, and the check that holds them to `Get-BranchTemplates` is repo-owned --
`plugins/specialists/scripts/lint/` does not exist, so no consumer has ever had it. When the working files
became bare in v3.7.0, this repo's guidance moved to `branch/templates/` and a consumer's simply went away:
their scaffolder stopped writing it and they had nowhere to read it. Their only remaining description of the
form was the skill page.

The measurement was one question asked of the code instead of assumed -- *does "see the templates" resolve
in a consumer repo?* -- and the answer was no.

**Refreshed rather than only created**, which is the half that keeps working. A copy written once is correct
on the day the branch directory appears and stale from the next release on; rewriting a drifted one carries
a format change into a consumer's reference through the same plugin update that carries it into their
scripts. That follows the rule the templates already carry: generated, not maintained.

Pinned by tests in a fixture that **is** a consumer -- shared scripts only, no lint, no hand-written
templates -- so the case that broke is the case under test.

### Significance

#### Tier 0

Nothing changes here: this repo already had the templates, and the writer now rewrites them to the same
bytes the lint already demanded.

**Score:** 1

#### Tier 1

A shipped regression is closed within hours of shipping, and it was caught by an adversarial review of a
proposal rather than by a consumer hitting it. Worth knowing as evidence that the review step earns its
place.

**Score:** 3

#### Tier 2

A consuming repo gets the guidance back, on its next branch and without doing anything. Since v3.7.0 their
branch files have been bare with no reference to read; this restores it and keeps it current from now on.

**Score:** 4

### Pull Request
