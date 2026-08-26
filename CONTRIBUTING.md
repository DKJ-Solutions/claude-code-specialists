# Contributing

This page is the **standard workflow** — what holds in this repo before any workflow plugin is
consulted, and what a contributor can rely on even if they know nothing else about how this repo works:

1. **Never commit directly to `main`.** Every change travels on a branch and reaches `main` through a
   Pull Request.
2. **CI must pass before the merge.** The `main` ruleset requires the `lint-en-tests` status check; a
   merge attempted before it goes green returns `BLOCKED`.
3. **One change per branch**, described in the PR, and the branch is deleted after the merge.

## The layer on top: the workflow folder

This repo runs the `contributing-davekjohn` plugin, and that plugin carries its own contributing page:

📄 **[`contributing-davekjohn/CONTRIBUTING.md`](contributing-davekjohn/CONTRIBUTING.md)**

**When the plugin is installed, that page applies on top of this one — and where the two disagree, the
plugin's page wins.** It does not replace the standard workflow above; it extends it with the plugin's
own mechanics (the branch dossier, the changelog entry that folds at the merge, the significance model,
the release cycle) and with this repo's answers to the workflow's seams. A reader in a repo *without*
the plugin stops at this page; a reader in a repo *with* it reads both and lets the plugin's page settle
any conflict.

The layering is deliberate (Dave, August 14, 2026): this page stays meaningful the day the plugin is
absent — a fresh checkout, a repo that tears the workflow down, or a contributor who has not installed
anything — while everything the plugin owns lives in the folder that travels with it.
