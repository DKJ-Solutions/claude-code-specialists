## `docs/release-readme-tier-model` changelog

### Branch title

The release page states the tier gate the code actually runs

### Branch ID

20260809-174214

### Branch type

docs

### What does the change on this branch bring to main?

`releases/README.md`'s portable half — everything above the mirroring rule, so everything that travels to a
repo adopting this workflow — described the changelog model as it stood before August 6, 2026. Measured
against `release-lib.ps1` and `cut-release.ps1` rather than read, it was wrong on five load-bearing points at
once:

- **The bump table refused what the code permits.** It required a tier-1 entry for *any* release and a
  tier-2 entry for a **minor**. `Test-ReleaseBumpEarned` requires nothing for a patch (a tier-0-only release
  is what a patch is for, Dave, August 7) and tier **1** for a minor. A reader following the page would have
  believed a legitimate release could not be cut.
- **It named a retired script as the writer.** `new-changelog-entry.ps1` was retired on August 7 and folded
  into `new-branch.ps1`; the page still had it writing `Tier: 0` into the entry.
- **It described the fold as rewriting the entry** — filing it under a section and stripping the tier line.
  The fold does neither: it folds **verbatim**, and `fold-changelog-entry.ps1:50` keeps the legacy
  `Tier: N` line deliberately.
- **It described the entry's retired shape**: an "impact table" and `#### What does this change do?`, both
  replaced by `### Significance` with one `#### Tier N` sub-section per reach.
- **It stated the gate's off-switch as a section count**, the exact test that became a landmine when the
  changelog went flat and which was replaced by counting declarations.

Two further claims were corrected against what was measured rather than against `CLAUDE.md`, which
summarises this one step too loosely. The highlights document is written when the bump is one the seam names
**and** a tier-2 entry is pending — both conditions, not either — and that second one only became
load-bearing when a minor stopped requiring tier 2. And the development note's structure is now stated as
what it is: the one document that still groups by tier, carrying each entry whole with its six `####`
sections, rather than "structured the way `CHANGELOG.md` itself is".

Alongside it, the root `README.md` claimed `cut-release.ps1` "stays repo-only and is deliberately not
mirrored" and cited `check-script-contract.ps1` for it — a file which opens that very record with
*"cut-release.ps1 USED TO BE OUT OF SCOPE HERE"*. The script has been shared and mirrored since #417; the
paragraph now separates the shared **script** from the portable **skill** instead of resting on a
distinction that dissolved.

### Significance

#### Tier 0

The page is what a maintainer here reads before cutting, and it disagreed with the gate they were about to
meet. The `new-changelog-entry.ps1` reference in particular sends a reader looking for a file that is not
there.

**Score:** 3

#### Tier 1

Anyone reasoning about this project's release policy from its own documentation was reading the pre-August-7
rules, including the one that says a tier-1-only release cannot be cut at all.

**Score:** 3

#### Tier 2

This is the half of the page that travels: a repo mirroring this workflow copies everything above the rule
verbatim, so it would have adopted a bump gate that refuses releases its own scripts permit — and would have
had no way to notice, since the page is the only statement of the rules it gets.

**Score:** 4

### Pull Request

