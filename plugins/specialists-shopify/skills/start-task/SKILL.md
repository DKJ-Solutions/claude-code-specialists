---
name: start-task
description: Start a new task — creates the git branch and the associated invisible preview theme via scripts/task/start-task.ps1. Invoke manually as "/specialists-shopify:start-task <prefix>/<short-name>", e.g. /specialists-shopify:start-task feat/size-chart-popup. Thin wrapper; the branch/theme creation itself stays deterministic in the script.
disable-model-invocation: true
---

# start-task — new branch + preview theme

Thin UX wrapper over `scripts/task/start-task.ps1` (in the repo root). The script does the real, **deterministic** work — from `main`, creating a branch `<prefix>/<short-name>` and a preview theme of the same name that is **unpublished**, remembering the theme id in the git config, and printing the preview URLs per market. This skill does not replace the script; it conveniently invokes it with the supplied argument.

## Argument

The branch name in kebab-case: `<prefix>/<short-name>`, e.g. `feat/size-chart-popup` or `fix/cart-totals`. Valid prefixes are in Derek's branch table (`.claude/manuals/05-05-manual.md`); classify by what changes (among others `feat/`, `fix/`, `style/`, `liquid/`, `gtm/`, `tooling/`, `config/`, `manual/`, `research/`, `extension/`).

## Steps

1. **No argument supplied?** → first ask which branch name is wanted. Do not guess.
2. **Gatekeepers:** verify that you are on `main` with a clean working tree, and that the pre-task sync has been done this session (the script branches off the current `main`).
3. **Run the script** via PowerShell — plain, without stderr redirect (the Shopify CLI writes progress to stderr):
   ```powershell
   scripts/task/start-task.ps1 -Name "$ARGUMENTS"
   ```
4. The script **validates the prefix itself** and refuses an invalid name, the `sync/` prefix and `final`. On an error: resolve it per the message, do not invent an alternative.
5. **On success** the script prints the preview URLs per market — pass them on to the user.

## Boundaries

- Preview action: the theme is `unpublished` and does not touch the live theme.
- Do not touch `main` or live beyond what the script does.
