## fix/1570-shopify-floor-no-store-seam

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

The floor session check (`shopify-floor-sessioncheck.ps1`) asks which theme is live and has exactly
two states: a numeric answer, or "not answered" -- which fires an `[ERROR]` every session, forever.
A repo that enables this team **without a Shopify store** has no truthful answer, so it is stuck with
that `[ERROR]`. This branch adds the missing third state: an opt-in seam `Get-ShopifyRepoHasNoStore`
that a no-store repo sets to `$true` to declare itself, after which the check stays silent on the
half-armed finding -- the same silence an answered id already earns, and for the same reason (a
self-authored declaration, never an inference from the tree).

#### Scope

- **Plugin only.** The change lives entirely under `plugins/dkj-teams/dkj-team-shopify/` plus its
  test suite. It has **no file overlap** with open PR #1573 (`feat: Enable every plugin in the source
  repo`), which touches `CLAUDE.md` / `settings.json` / lenses and explicitly *"changes nothing under
  `plugins/`"*. #1570 was filed by #1573's own author as the tracked follow-up for the check itself.
- **Not in this branch:** wiring the seam into *this* repo's `scripts/repo-config.ps1`, and softening
  the `CLAUDE.md` floor-check note from "gap in the check" to "declared no-store". Those only matter
  once `dkj-team-shopify` is enabled here (#1573) and belong to that chain -- filed separately as a
  follow-up.

#### Deliberately left alone

- **`guard-live-theme.ps1` is untouched.** With no store there is nothing to push to, so the id half
  of its rule 3 staying inert costs nothing; widening a guard a no-store repo never invokes would be
  change for its own sake.
- **The duplicate-guard finding stays independent.** A no-store repo would not carry a hand-written
  guard; if one somehow does, its `else` branch ("ANSWER Get-ShopifyLiveThemeId BEFORE YOU CONVERGE")
  reads slightly oddly, but the finding correctly still fires and wording polish for that contradiction
  is out of scope.

### CREATE

- [x] `shopify-floor-sessioncheck.ps1`: probe `Get-ShopifyRepoHasNoStore` in the same StrictMode-off
      child scope that reads the id (returned together as a hashtable, the `$answers` idiom
      `guard-live-theme.ps1` already uses); gate the `[ERROR]` on `-not $noStore`; `.DESCRIPTION` gains
      the third-state paragraph.
- [x] `dkj-team-shopify/README.md`: new subsection after the placeholder paragraph documenting the seam.

### TEST

- [x] `scripts/tests/shopify-floor-sessioncheck.tests.ps1`: `New-FixtureRepo` gains `-NoStore` /
      `-ConfigExtra`; five new asserts -- silent on a truthy declaration, declaration beats a `VUL-IN`
      placeholder, a falsy answer is **not** a declaration, and the duplicate-guard finding stays
      independent. **25 passed, 0 failed** (was 20).
- [x] `scripts/tests/guard-live-theme.tests.ps1`: unchanged hook, **102 passed, 0 failed** -- no regression.
- [x] `scripts/lint/check-plugin-integrity.ps1`: **0 errors** -- `[script-ascii]`, `[plugin-link]` and
      the dead-link pass all clean over the edited hook and README.

### DEPLOY: fix/1570-shopify-floor-no-store-seam

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

