## `feat/shopify-pre-task-sync` deployment

### What does the change on this branch deploy to main?

`team-shopify` gains the pre-task sync: `sync-main`, a shipped script that mirrors the live theme into
the trunk without letting live overwrite what the trunk has done since, with the exclusion rule beside
it as its own tested lib. Two suites, 32 asserts: `sync-rules.tests.ps1` drives the two queries directly
against fixture repositories -- including the case a deletion is also a touch, which is the one the first
hand-written implementation got wrong -- and `sync-main.tests.ps1` drives the script's refusals, which
are the safety surface. Both mirrors are registered pairs, so the drift lint holds them to the source.

Four seam answers arrive with it, all read through `Get-Command` so the plugin depends on **neither**
workflow plugin: the store, the reference pattern, the branch prefix, and whether it merges.
`adopt-shopify-floor` writes them into the block it already appends and takes `-StoreDomain` so the sync
is runnable in the same move as the guard being armed.

Two things the branch found rather than built. The report named three seam-worthy divergences between the
two consumers' implementations; **the branch name is not one of them** -- both write `sync/live-<date>`.
It is a seam for a different reason, which the docs now give: it has to line up with whatever the
consumer's CI and PR guardrails exempt. And `-SkipPull` contradicted itself in both implementations --
it promises to run the rule over what is already in the working tree, while the clean-tree check refuses
a dirty tree, so with the switch there could never be anything there. It now warns and proceeds on that
path, loudly, naming what it is about to read as third-party drift.

**Score:** 3

#### What makes this change extra special

This is the script a Shopify consumer cannot afford to get wrong, and until now every consumer wrote it
themselves. Both of the two that exist did, and the first version destroyed work in both -- one of them
recording the same wholesale procedure reverting merged work three times in one week. A live theme has no
locking and no merge, so the obvious implementation of "mirror live" is the one that eats unpushed work,
and nothing warned about it. The exposed party was the next consumer, who has no sibling repo to copy
from.

It also states the interaction nobody had written down: the moment a repo adopts this marketplace's
changelog model, "merged into the trunk but not live yet" becomes a **designed** state, so every entry in
`CHANGELOG.md` names work the naive sync would have reverted. Adopting one half of the marketplace makes
the other half more dangerous, and that sentence now exists in Sandra's manual and in the skill page.

**Score:** 5

### Pull Request

The Shopify floor gains the pre-task sync, with the exclusion rule as a tested lib
