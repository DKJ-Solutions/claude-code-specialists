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
| [`dkj-policy/`](dkj-policy/) | **DaveKJohn's own branch-and-entry model, packaged so a repo can choose it.** The branch, PR, changelog and release skills, the shared scripts behind them, the session hooks that belong to running this across several repos, and a config blueprint holding the source's own answers to the repo-owned seam. It has [its own README](dkj-policy/README.md). |
| [`dkj-policy-bwj/`](dkj-policy-bwj/) | **BWJ's codex — the binding rules its two Shopify store repos (smartwatchbanden, xoxowildhearts) operate under.** Two chapters: **ticket handling** — file on GitHub first, mirror to Asana as a colleague-friendly variant; closing the GitHub issue only makes a CI template post that the work is ready to test and move the card to `ReadyToTest` — it never resolves the task itself; and **the sync log** — a `sync/` branch is exempt from the changelog by design and owes `dkj-policy-bwj/SYNC-LOG.md` instead. Two skills, no specialists, no hooks. **Additive to `dkj-policy`** — it extends only the ticket-work step and what a sync branch owes, and contradicts nothing that workflow decides. It has [its own README](dkj-policy-bwj/README.md). |

**`dkj-policy` carries an owner's name because it is *his* branch discipline and not a
standard**, which is exactly why a repo has to choose it rather than receive it. `dkj-policy-bwj` sits
here because it too is a way of working rather than a team — a deliberately narrow one, scoped to one
step and one pair of repos.

## There is no default workflow, and that is the answer rather than a gap

This directory held a second plugin, `workflow-default`, until August 26, 2026
([#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886)). It was described as *"the
workflow a repo gets when it has not chosen one"*, and removing it was Dave's call on a simple reading:
**a consuming repo already has its own way of working before any plugin is installed.** Its contributing
rules, its branch conventions and its release steps are its own, written by whoever runs it. A plugin
asserting itself as the *default* method claims a slot that was never empty.

So the honest shape is one opt-in and no baseline. A repo that enables nothing here keeps exactly what
it had, which is what it wanted; a repo that enables `dkj-policy` has deliberately adopted
somebody else's discipline on top of its own.

**Nothing checks how many workflows are enabled, and that rule was retired rather than lost.** Until
this change a `workflow-sessioncheck` SessionStart hook in the core team counted enabled plugin ids
beginning with `workflow-` and raised an `[ERROR]` above one, on the argument that two enabled workflows
would hand the specialists two contradicting answers to the same question. That argument rested on the
two plugins here genuinely disagreeing about whether a branch owes an entry before it can open a PR —
and with one of them gone there is nothing left to disagree with. #886 also settled the wider question
in the other direction: this workflow keeps its changelog and its releases inside **its own folder**, so
a repo's own contributing rules and this one can stand side by side without colliding. Coexistence is
now a supported answer, not a misconfiguration.

**What that costs, stated because it is a real risk and not a hypothetical.** If a second workflow
plugin is ever added here, nothing will notice two of them being enabled at once, and the specialists
will again get two answers with nothing saying which is this repo's. The guard is retired on the state
of the tree, not on a proof that the failure is impossible — so adding a second workflow means
answering this question again, deliberately, rather than discovering that the check quietly went away.

**`dkj-policy-bwj` is that second workflow, added August 31, 2026 as `bwj-codex` and renamed on
September 5 (#1437), and the question was answered on the
merits.** It does **not** disagree with `dkj-policy` about anything: it extends only the
*ticket-work* step (how a discovered issue is filed and mirrored to Asana in BWJ's two store repos)
and, since [#1382](https://github.com/DaveKJohn/claude-code-specialists/issues/1382), what a `sync/`
branch owes instead of a changelog entry. It decides nothing about branch naming, the pre-PR bar, or
releases. Two workflows collide when they
answer one question two ways; these answer different questions, so both stay enabled. The retired
guard's reasoning is still the test for any *further* workflow — and it would fail for one that
overlapped either of these.

## The name is load-bearing, and so is sitting here

A way of working is named `workflow-<name>`, `contributing-<name>` or `<name>-codex` and lives under
`plugins/workflows/`; a team is named `team-<name>` and lives under `plugins/teams/`. Lint check 23
(`[plugin-kind]`) in [`check-plugin-integrity.ps1`](../../scripts/lint/check-plugin-integrity.ps1)
holds every published plugin to both halves of that pairing. The directory names the KIND — a way of
working — and the rest of the name says whose it is: `dkj-policy` is DaveKJohn's, `dkj-policy-bwj`
is BWJ's.

**The naming half's reason changed with the guard, and the check says so too.** It used to be that the
count above keyed on the `workflow-` prefix, so a workflow published under another name would never be
counted. With no count left, what keeps the naming rule is internal to the check: **the directory rule
is derived from the name.** A plugin matching none of those shapes falls through every branch, so its
location is held against nothing at all — an unclassifiable name does not read untidily, it switches the
check off for itself.

## What a workflow folder holds

- **`.claude-plugin/plugin.json`** — the manifest, carrying the `version` that is bumped in lockstep
  with every other plugin in this repo.
- **`skills/`** — the way of working, as skills a specialist invokes. This is where most of a workflow
  lives.
- **`scripts/`** — the scripts and libs those skills run, mirrored from this repo's own `scripts/` and
  held to it by the shared-script drift lint. Do not edit a mirror: a change lands in the source first
  and travels here. See the [scripts README](dkj-policy/scripts/README.md).
- **`hooks/`, `blueprint/`** — only where a workflow needs them; `dkj-policy` carries both.

**No `agents/`, no `manuals/`.** Those belong to a team, and a workflow that shipped one would be
answering the question the other directory owns.

## The seam: what `dkj-policy` expects from your repo

Its shared scripts dot-source two **repo-owned** files — `scripts/repo-config.ps1` and
`scripts/lib/branch-info.ps1` — so the parts that legitimately differ per repo are answered by the
repo rather than baked into the plugin. The `specialists-init` bootstrap scaffolds both, and the
`adopt-dkj-policy` skill's Part 2 reads the config blueprint this plugin ships: it **places** the answers that
state a shared way of working and **proposes** — never places — the answers that state what a repo
*is*. The reasoning behind that split, and why a `decide` answer is never written as a stub, is in the
root README under
[The plugin serves the consumer's repo](../../README.md#the-plugin-serves-the-consumers-repo); what
the seam consists of, file by file, is under
[The seam, specified](../../README.md#the-seam-specified).

## Enabling it, and going back

Enabling a workflow is an ordinary plugin change rather than a migration, and there is no longer a
second one to switch between: the two directions are **on** and **off**. Turning it off leaves the repo
with its own way of working, which it never stopped having — that is the whole reason there is no
default here. Enabling it in the first place is part of the adoption path in
[`../INSTALL.md`](../../INSTALL.md); [`../UNINSTALL.md`](../../UNINSTALL.md) is its mirror.
