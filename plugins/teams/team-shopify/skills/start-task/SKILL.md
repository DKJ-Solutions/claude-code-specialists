---
name: start-task
description: Start a new task in a Shopify store repo — the git branch plus the matching invisible preview theme. Invoke manually as "/team-shopify:start-task <prefix>/<short-name>", e.g. /team-shopify:start-task feat/size-chart-popup. It drives THIS repo's own start-task script; the team deliberately ships none.
disable-model-invocation: true
---

# start-task — new branch + preview theme

Two things happen at the start of a Shopify task: a branch, and an **unpublished** preview theme of the
same name to push it to. This page drives both. It does not carry the code for either.

## What this needs from your repo, and why it is not shipped

**`team-shopify` ships no `start-task` script**, and that is a decision rather than an omission. Creating a
preview theme means the Shopify CLI against one specific store: which markets get a preview URL, where the
theme id is remembered, and what counts as a safe target are facts about a *store estate*, not about the
team. So the executing half stays in the repo, conventionally at `scripts/task/start-task.ps1`.

**If your repo has no such script, this skill has nothing to run — say so rather than improvising one.**
The two steps are then done by hand and your repo's own `CLAUDE.md` is what says how: the branch first, per
that repo's branch convention, then a `shopify theme push --unpublished` to create the preview. Never
against a theme whose role is `live`.

## Argument

The branch name, in the form **your repo** uses. This page carries no list of prefixes on purpose: a
taxonomy hardcoded here would contradict whichever one the repo actually has, and it is the repo that
refuses a bad name. Read it from `CLAUDE.md`, and — in a repo that also runs `workflow-davekjohn` — from
the seam at `scripts/lib/branch-info.ps1` (`Get-BranchTypes`, `Test-BranchName`), which is where that repo
states it once for every script that asks. Classify by *what actually changes*.

## Steps

1. **No argument supplied?** → first ask which branch name is wanted. Do not guess.
2. **Gatekeepers:** verify you are on the trunk with a clean working tree, and that this session has done
   its sync. Take the branch convention from the repo, not from memory.
3. **Run the repo's script**, if it has one — plain, without a stderr redirect (the Shopify CLI writes its
   progress to stderr):
   ```powershell
   scripts/task/start-task.ps1 -Name "$ARGUMENTS"
   ```
   No such file? Stop, say that this repo has no start-task script, and offer the by-hand route above.
4. **A refusal is an answer.** Where the script validates the name, resolve the error it names; do not try
   another spelling to get past it.
5. **On success** pass on whatever preview URLs it prints.

## Boundaries

- Preview only: the theme is `unpublished` and does not touch the live theme.
- Do not touch the trunk or live beyond what the script does.
