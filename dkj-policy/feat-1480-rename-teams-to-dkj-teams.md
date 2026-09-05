## feat/1480-rename-teams-to-dkj-teams

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

Issue #1480: the teams folder becomes plugins/dkj-teams/ and the four team plugin ids become dkj-team-alpha, dkj-team-ecomm, dkj-team-lifehub, dkj-team-shopify, so every plugin in the marketplace carries the dkj- owner prefix that dkj-policy already does.

#### The line between what gets rewritten and what does not

Taken from [#1467](https://github.com/DaveKJohn/claude-code-specialists/issues/1467), which ran the
same shape one commit earlier and settled the question: a **link target** is repointed everywhere,
including in archived release notes, because a dead link is a defect at any age; **prose** naming a
name is left alone in the history layer, because `plugins/teams/...` in a 4.14.0 note is a correct
statement about the layout that shipped in 4.14.0. The register in `connectors/` is the same
argument in a second form -- it records what a consumer **HAS**, and each record catches up when
that consumer migrates (#952).

### CREATE

- [x] `git mv` the folder and the four plugin directories: `plugins/teams/` -> `plugins/dkj-teams/`,
      and `team-<x>/` -> `dkj-team-<x>/` inside it.
- [x] Rewrite paths and ids across the live tree -- 171 files. Both separators: the forward-slash form
      that documents use and the **backslash** form that every `Join-Path` literal in `scripts/`
      uses. The second one is the half that hides.
- [x] Rewrite **link targets only** in the history layer (`dkj-policy/releases/**`,
      `dkj-policy/CHANGELOG.md`); leave their prose and `connectors/*.json` untouched.
- [x] Repair the `[plugin-kind]` gate, which the rename would otherwise have switched off for all
      four teams.
- [x] Sharpen `plugins/README.md`, whose organising paragraph claimed the team directory names a
      kind where it now names a kind and an owner.

### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors across all 30 checks. The `[shared]` check is the one
      that earned its keep -- it failed on the first pass with 178 findings, and the cause was the
      backslash literal in `Get-AgentSharedDir` that a forward-slash sweep cannot see.
- [x] All suites under `scripts/tests/`.
- [x] Grep the tree for any surviving un-prefixed team name outside the history layer: none.
- [x] Grep for the mirror-image defect -- a **dated** sentence the sweep retconned. Two found and
      reverted: the account in Sylvester's lens of what check 18 *used to* hardcode, and this
      document's own PR title, which the sweep read as live text and turned into "rename
      plugins/dkj-teams to plugins/dkj-teams".

### DEPLOY: feat/1480-rename-teams-to-dkj-teams

`plugins/teams/` is `plugins/dkj-teams/`, and the four teams are `dkj-team-alpha`,
`dkj-team-ecomm`, `dkj-team-lifehub` and `dkj-team-shopify`. That finishes what
[#1467](https://github.com/DaveKJohn/claude-code-specialists/issues/1467) started on the workflow
side a commit earlier: every plugin this marketplace publishes now carries the owner in its name,
and both top-level directories say whose kind they hold rather than only which kind.

**The `[plugin-kind]` gate moved its directory rule rather than gaining a second one, and that is
the part worth reading twice.** `dkj-team-*` now claims `plugins/dkj-teams/`; bare `team-*` keeps
the naming half and loses the directory half, joining `workflow-*`, `contributing-*` and `*-codex`
where #1467 put them. The reasoning is that decision applied to the half it had not reached: once
this family's own teams carry the prefix, a prefixless `team-*` is exactly what **somebody else's**
team is called, and ordering it into this family's directory is the failure the workflow side
already refuses to commit. The tempting third option -- leave `team-*` pointed at
`plugins/dkj-teams/` and add `dkj-team-*` beside it -- reads as harmless and is, right up until
somebody publishes a plugin actually named `team-something`, which is the one case the rule exists
for. The else-branch is untouched: a name matching none of the shapes is still an error.

Archived release notes were split the way #1467 split them -- **targets** repointed so navigation
still works, **prose** untouched. `connectors/*.json` is untouched entirely, ids included: the
register records what a consumer HAS, so a record naming `team-alpha@` is correct until that
consumer migrates, and `check-connectors.ps1` reporting the retired id as an `[INFO]` is the
designed behaviour of a rename rather than a regression.

**Score:** 3

#### What makes this deploy extra special

**This one renames plugin IDs, so it breaks every consumer at the moment it lands, and unlike
[#1467](https://github.com/DaveKJohn/claude-code-specialists/issues/1467) there is no one-line
version of the migration.** #1467 moved a directory and left the ids alone, which is why it could
promise that `claude plugin install`, `${CLAUDE_PLUGIN_ROOT}` and every skill invocation resolved
exactly as before. None of that holds here. `team-alpha@claude-code-specialists` stops existing;
so do the other three.

What each consuming repo has to do, in order:

```text
claude plugin marketplace update claude-code-specialists
claude plugin uninstall team-alpha@claude-code-specialists
claude plugin install   dkj-team-alpha@claude-code-specialists --scope project
```

...repeated for whichever of `team-ecomm`, `team-lifehub` and `team-shopify` that repo enables. Then
three edits in its own tree, none of which any plugin can make for it:

- **`.claude/settings.json`** -- the keys under `enabledPlugins` are the old ids.
- **The orchestrator `@`-import**, normally in `.claude/specialists/SPECIALISTS.md`. It is a fixed,
  versionless path into the marketplace clone, and `@`-imports take no variables, so it names
  `plugins/teams/team-alpha/personas/01-01-persona.md` literally. Re-running `specialists-init`
  rewrites it, because the bootstrap derives that path from where it is actually running rather than
  from any literal; editing the one line by hand is equally good.
- **Every `@team-alpha:<name>` subagent invocation** in that repo's own lenses, skills and docs
  becomes `@dkj-team-alpha:<name>`.

**A dead `@`-import is the one to get right, because it fails silently and expensively:** Claude Code
drops the line without an error and the session loses the whole document, so an orchestrator that
simply never loads reads as a model problem rather than a path problem.

Nothing else moves. The marketplace name is unchanged, so the `extraKnownMarketplaces` block stays as
it is, and no lens, manual or specialist id changes -- the specialists are the same people in a
differently-named box.

**Score:** 5

#### Pull Request

Rename plugins/teams to plugins/dkj-teams and prefix the four team plugins with dkj-
