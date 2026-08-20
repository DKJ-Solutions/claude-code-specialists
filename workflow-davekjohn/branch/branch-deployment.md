## `feat/shopify-floor-adoption` deployment

### What does the change on this branch deploy to main?

The install path the `team-shopify` floor shipped without. v4.15.0 gave the plugin a `PreToolUse` guard on
the live theme, and it started working on its own — for two of its three rules. The third needs the
consumer to name the live theme, no install step owned that answer, and an install writes nothing into a
repo, so every refreshed consumer met a standing `[ERROR]` at session start and a guard with a documented
hole in it. Three inbound reports came back within nine hours of the cut, and this branch answers all
three.

**The new `adopt-shopify-floor` skill** places the floor: the Shopify seam block appended to
`scripts/repo-config.ps1`, a starter `.theme-check.yml`, and `.github/workflows/theme-check.yml`. Additive
and dry-run by default like its two `adopt-` siblings, refused in a repo that publishes plugins, and it
takes `-LiveThemeId` so the guard is armed in the same move. It travels in `team-shopify` rather than in
`specialists-init`, because the core team must not learn the seams of an add-on it does not depend on.

**The starter config is measured, not designed.** Both existing Shopify consumers wrote one independently
before the floor shipped, and both arrived at the same two checks over `extends: nothing` — Liquid that
does not parse, JSON that does not parse — with the same false-positive exemption for `.liquid` files
carrying no HTML. Neither turned the recommended set on: it reports 1504 offenses across 171 files on one
of those themes and roughly 58k on the other, and a gate that is red on arrival gets bypassed on day one.
So the floor ships green on arrival (Dave, August 20, 2026, choosing that over assuming a clean theme),
and the CI workflow runs at `--fail-level error`, which is not a loosening but exactly the two checks the
config declares.

**Inbound #776's proposed repair would have made things worse, and that is the finding underneath this
branch.** It asked for the seam block to be written with a `VUL-IN` marker. The session check reads a
non-empty answer as *answered*, so a stub returning `VUL-IN` would have silenced the report while leaving
the id half exactly as inert as before — a hole with a comment on it, the failure this plugin's own README
is built around. So the block lands **commented out** unless an id is supplied, and both the guard and the
session check now read a **non-numeric** answer as unanswered. The observation was right, the remedy was
not.

**Inbound #777** gets the two halves it was missing: a *Converging off a hand-written guard* section in the
README, and a second finding in the floor session check — a `PreToolUse` command in the consumer's own
settings naming this guard is, by construction, a second one, and two guards then block every command
twice. Its third item is closed as already answered rather than built: the README has stated which marker
spellings the guard accepts since `056a097`, the same commit that shipped the guard.

Twelve new asserts in `guard-live-theme.tests.ps1` (69, from 51) and a new 36-assert
`adopt-shopify-floor.tests.ps1`.

**Score:** 4

#### What makes this change extra special

A guard that reads as protection while one of its rules cannot fire is the worst state of the three
available, and it was the **default on install** for every Shopify consumer. This closes it in the only
place it could be closed — the install path — rather than asking each consumer to notice it alone.

The part worth keeping is the shape of the mistake it avoided. All three reports were correct about the
symptom; one was correct about the cause and wrong about the cure, in a way that reads as obviously right:
*scaffold the function with a placeholder, like every other seam*. Every other seam has a documented
fallback, and this one has none — a placeholder there does not prompt an answer, it cancels the question.
The counter-case is now asserted from both sides, on the guard and on the check, because an exemption
without one is a hole with a comment on it.

And the second-guard finding is what a system owes a consumer who did the right thing: `xoxowildhearts`
built the guard, reported it, offered it upstream, and was rewarded with two hooks doing one job — with no
version bump to prompt anyone to look, because the refresh happened inside `4.14.0`. The check now says so
once per session, and the README says what to delete and what to keep.

**Score:** 4

### Pull Request

The Shopify floor gains its install path
