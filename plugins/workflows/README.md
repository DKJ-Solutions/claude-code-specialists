# The workflows — how work moves through the repo

**Every plugin in this directory is a workflow: a way of working, not a team.** Its sibling
[`../teams/`](../teams/) holds the other kind of plugin, which answers *who* the specialists are; a
workflow answers what happens to a piece of work between starting it and it reaching the trunk — how a
branch is named, what a change owes before it can open a PR, what a release is. A workflow therefore
carries **no specialists at all**: it changes how the existing ones work, not who they are. The two
kinds are put side by side one level up, in [`../README.md`](../README.md), and the full argument for
splitting them is in the root README under
[Teams and workflows — what's the difference?](../../README.md#teams-and-workflows--whats-the-difference).

## What is in here

| Folder | What it is |
|---|---|
| [`workflow-default/`](workflow-default/) | **The workflow a repo gets when it has not chosen one.** It imposes nothing; its one skill, `discover-workflow`, reads what the repo already states about how work moves through it and writes the answer down, including where the repo is silent. It has [its own README](workflow-default/README.md). |
| [`workflow-davekjohn/`](workflow-davekjohn/) | **DaveKJohn's own branch-and-entry model, packaged so a repo can choose it.** The branch, PR, changelog and release skills, the shared scripts behind them, the two session hooks that belong to running this across several repos, and a config blueprint holding the source's own answers to the repo-owned seam. It has [its own README](workflow-davekjohn/README.md). |

`workflow-default` is what a repo keeps unless it deliberately decides otherwise. The name of the other
one is a statement rather than vanity: it carries an owner's name because it is *his* branch discipline
and not a standard, which is exactly why a repo has to choose it rather than receive it.

## At most one, ever — and it is checked

**Two enabled workflows would hand the specialists two contradicting answers to the same question**,
with nothing in the session saying which one is this repo's; they would then pick, silently and
differently each time. That is not hypothetical — the two plugins here genuinely disagree, by design,
about whether a branch owes an entry file and a step list before it can open a PR.

Since August 9, 2026 the rule is enforced rather than merely written down. The
`workflow-sessioncheck` SessionStart hook counts the enabled plugin ids beginning with `workflow-`,
and prints an `[ERROR]` naming each one together with the settings layer that enabled it once there is
more than one. It never blocks, and stays silent at zero enabled workflows as well as at one — zero is
a legitimate state, not an oversight.

**That hook lives in the core team, not in these plugins**, and deliberately so: the core is the one
plugin every consuming repo enables, so it is the only place a check can see *all* the enabled
workflows at once. Putting a copy in each workflow would be symmetrical and would fail in exactly the
case it is needed — a conflict takes two plugins, and only one of them has to have left the check out.
It also keeps `workflow-default` free of hooks entirely, which is what lets it stay as thin as it is
meant to be.

## The name is load-bearing, and so is sitting here

A workflow is named `workflow-<name>` and lives under `plugins/workflows/`; a team is named
`team-<name>` and lives under `plugins/teams/`. Lint check 23 (`[plugin-kind]`) in
[`check-plugin-integrity.ps1`](../../scripts/lint/check-plugin-integrity.ps1) holds every published
plugin to both halves of that pairing.

The naming half is the one that cannot be seen by reading the tree, and it is the reason the check
exists: the count above keys on the `workflow-` prefix and nothing else, so a workflow published under
a different name would never be counted and could sit enabled alongside another in silence.

## What a workflow folder holds

- **`.claude-plugin/plugin.json`** — the manifest, carrying the `version` that is bumped in lockstep
  with every other plugin in this repo.
- **`skills/`** — the way of working, as skills a specialist invokes. This is where most of a workflow
  lives.
- **`scripts/`** — the scripts and libs those skills run, mirrored from this repo's own `scripts/` and
  held to it by the shared-script drift lint. Do not edit a mirror: a change lands in the source first
  and travels here. See the [scripts README](workflow-davekjohn/scripts/README.md). Even
  `workflow-default` has one, for a single function: it writes its document inside the seam, and where
  the seam is has one source rather than a literal per reader.
- **`hooks/`, `blueprint/`** — only where a workflow needs them. `workflow-davekjohn` carries both;
  `workflow-default` carries neither, which is the point of it.

**No `agents/`, no `manuals/`.** Those belong to a team, and a workflow that shipped one would be
answering the question the other directory owns.

## The seam: what `workflow-davekjohn` expects from your repo

Its shared scripts dot-source two **repo-owned** files — `scripts/repo-config.ps1` and
`scripts/lib/branch-info.ps1` — so the parts that legitimately differ per repo are answered by the
repo rather than baked into the plugin. The `specialists-init` bootstrap scaffolds both, and the
`adopt-config` skill reads the config blueprint this plugin ships: it **places** the answers that
state a shared way of working and **proposes** — never places — the answers that state what a repo
*is*. The reasoning behind that split, and why a `decide` answer is never written as a stub, is in the
root README under
[The plugin serves the consumer's repo](../../README.md#the-plugin-serves-the-consumers-repo); what
the seam consists of, file by file, is under
[The seam, specified](../../README.md#the-seam-specified).

`workflow-default` expects nothing: there is no seam to fill in, because there is no method to
configure.

## Switching from one to the other

Swapping workflows is an ordinary plugin change rather than a migration, but the two directions are
not quite symmetric — `workflow-default`'s own README describes both under
[Switching to another workflow](workflow-default/README.md#switching-to-another-workflow). Enabling
one in the first place is part of the adoption path in [`../INSTALL.md`](../INSTALL.md);
[`../UNINSTALL.md`](../UNINSTALL.md) is its mirror.
