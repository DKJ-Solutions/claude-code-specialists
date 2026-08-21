## `feat/team-shopify-push-preview` deployment

### What does the change on this branch deploy to main?

Pushing a branch to its own unpublished preview theme is the same call in every Shopify repo, and until now
every Shopify consumer wrote it themselves. `team-shopify` owns it from this release:

- **[`scripts/lib/preview-theme.ps1`](scripts/lib/preview-theme.ps1)** builds the two `shopify theme push`
  calls and holds every `--*` token against a whitelist measured off `shopify theme push --help`. Plus two
  readers of the CLI's own output that were inline expressions in the consumer's copy: the id of a theme
  that was created-and-pushed in one call, and the theme-list lookup.
- **[`scripts/task/push-preview.ps1`](scripts/task/push-preview.ps1)** resolves the target in four steps
  — an explicit id, the id remembered in the branch's git config, a name lookup, else it creates the
  theme — refuses the trunk, refuses live, and prints the preview URL(s).
- **[the `push-preview` skill](plugins/teams/team-shopify/skills/push-preview/SKILL.md)**, with the
  `Get-ShopifyPreviewUrls` seam written out.

**Lazy creation is the design, and it is measured.** A preview theme used to be created for every branch at
the moment the branch was made, including branches that could never touch a theme file. Measured on the day
the rule was made: 49 themes on one store, 47 unpublished, 16 named after a branch — and of the 12 real
branch previews, **6 belonged to branches that never needed one**. A Shopify store has a hard ceiling of 20
themes, so that estate eventually refuses the next push. A preview theme is a consequence of *"I want to
show this"*, not of *"I am starting work"*.

**Two things went further than [#805](https://github.com/DaveKJohn/claude-code-specialists/issues/805)
asked for**, and both are the same argument the report itself makes for the whitelist — the code that
cannot be run without a store is the code that has to be testable:

1. **Two more functions moved into the lib.** Parsing the new theme's id out of `--json` is the half that
   *cannot be re-run*, because the create call pushes at the same moment it creates. And the theme-list
   lookup carries a PowerShell 5.1 member-enumeration trap — `$parsed.themes` yields an array of `$null`
   that is truthy, so a bare `if` throws away the right list — which made a consumer's fallback report
   "no preview theme found" every single time. Both were untestable inline; both are pinned now, including
   the duplicate-name case, which **throws** rather than picking one, since pushing to the wrong of two
   identically named themes is invisible until somebody opens the preview.
2. **`start-task` was rewritten.** Not in #805's scope, but its page still said `team-shopify` ships no
   script because *"which markets get a preview URL … are facts about a store estate"* and told the reader
   to create a theme by hand at branch time. With lazy creation that is the opposite of the rule, so the
   two skills would have contradicted each other. It opens the branch now and states that the theme is
   `push-preview`'s job — and the reason that page's argument no longer holds is worth keeping: what made
   the step unshareable *was* the preview theme, and lazy creation is what separated the two.

**The market table is deliberately NOT shipped.** `Get-ShopifyPreviewUrls` is an optional seam because that
table genuinely is per-store: one consumer runs a single domain with locale-prefixed paths, another runs
five separate domains, so a shared table would have produced four domains that do not exist. What *is*
shared is that a preview link needs `_ab=0&_fd=0&_sc=1` to survive the first internal click — without them
you are looking at live while believing you are looking at the preview, which cost a consumer a whole
review. So a repo without the seam still gets one working URL rather than none.

**Score:** 4

#### What makes this change extra special

The reason to ship this rather than let each repo keep its copy is the failure that produced the report. A
consumer's create path spelled the flag `--theme-name`, which the Shopify CLI has never had. It failed the
**first** time anybody needed a preview theme created — written one day, reached the next, by the first
branch that actually wanted one. Nothing was wrong with the reasoning; the code had simply never run, and
a per-consumer copy means every consumer gets to discover that independently.

The whitelist earned its place immediately: on its first run it refused the lib's **own** call, because
`--unpublished` had been left out of the list. Same class of error, caught in three seconds instead of a
day.

Two design points from the consumer's review are kept deliberately. The whitelist answers *"is this a real
CLI flag"* and never *"may this repo use it"*, so it **admits** `--allow-live` — refusing a live push is
the guard hook's job, and a validator answering both questions would give two different answers to the
same one. And `Get-ShopifyLiveThemeId` is **recommended** here rather than required, unlike for `sync-main`:
that script reads *from* live and cannot work without it, while this one pushes to an unpublished theme and
wants the id for a belt-and-braces refusal the guard hook makes anyway. So it warns and continues instead
of blocking a preview.

**Score:** 4

### Pull Request

team-shopify owns push-preview, and validates the CLI flags it builds
