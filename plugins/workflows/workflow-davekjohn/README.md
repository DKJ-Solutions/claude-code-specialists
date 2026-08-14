# workflow-davekjohn — one particular way of working, packaged so a repo can choose it

**This is DaveKJohn's own branch-and-entry model, and the name says whose it is on purpose.** It is not a
baseline every consumer inherits and not a standard: it is one answer to *how does work move through this
repo*, offered as something a repo can deliberately pick up. Its sibling
[`workflow-default`](../workflow-default/) is the other answer — the deliberate absence of a method — and
that is what a repo has until it chooses this one.

**It carries no specialists.** A workflow changes how the existing ones work, not who they are; the
specialists come from [the teams](../../teams/). Enabling this without `team-alpha` gives you skills with
nobody to invoke them.

## What it is, in one paragraph

A branch is never entry-less: creating one writes the two files it works in — a changelog entry and a step
list — and the branch cannot reach a PR until both are answered. The entry declares **how far the change
reaches** (a tier) and **what it weighs** for each audience (a score), and that pair decides where it lands
in `CHANGELOG.md` and which release documents it appears in. The merge folds the entry into the changelog;
a release empties the changelog into dated notes and moves a tag. Four gates hold the whole thing together,
and none of them is advisory.

**The cycle itself is written out in [`CONTRIBUTING-portable.md`](CONTRIBUTING-portable.md), beside this
file.** That is the page to read — and the page to point your own contributors at — because it names the
seam wherever your repo owns the answer instead of asserting one repo's answer as the rule. Pair it with a
`## Specific to this repo` section in your own root `CONTRIBUTING.md` holding your values; the source repo's
[own answers](https://github.com/DaveKJohn/claude-code-specialists/blob/main/CONTRIBUTING.md) are a worked
example of that half.

**And if your work arrives from somebody else's tracker, the cycle starts earlier than `new-branch`.**
[`TICKETWORK-portable.md`](TICKETWORK-portable.md) covers that layer: how to tell a request that cannot be
built from one we are merely unconvinced by, which six kinds of question are not blockers, and why a status
in a heading is always false. Rules only, no template — it comes from one repo and one day, which the page
says out loud.

The full reasoning — the tier model, why the fold rewrites nothing, what a release must earn — ships with
this plugin: [`RELEASES-portable.md`](RELEASES-portable.md) for the release workflow and
[`BRANCH-portable.md`](BRANCH-portable.md) for the two branch files, beside
[`CONTRIBUTING-portable.md`](CONTRIBUTING-portable.md) for the cycle that connects them.

## What is in this folder

| what | what it holds |
|---|---|
| [`CONTRIBUTING-portable.md`](CONTRIBUTING-portable.md) | the contribution cycle in prose, seam-named — the human-facing half, meant to be read alongside your own repo's answers |
| [`RELEASES-portable.md`](RELEASES-portable.md) | the release workflow: the tier model, what a release must earn, the release documents, and how one is cut — your own `workflow-davekjohn/releases/README.md` holds your answers and your release list |
| [`BRANCH-portable.md`](BRANCH-portable.md) | the two files a branch works in: the dossier form, the three step marks, the reset state, and what the fold does at the merge |
| [`TICKETWORK-portable.md`](TICKETWORK-portable.md) | the rules for the layer *before* a branch, in a repo whose work arrives from somebody else's tracker: whether a request can be built as written, and how the answer is recorded. Rules and reasoning only — no template and no script, deliberately |
| [`skills/`](skills/) | the eight skills a specialist invokes — this is where most of the workflow lives |
| [`scripts/`](scripts/) | the scripts and libs those skills run, mirrored from the source repo's own `scripts/`. **Never edit a file there** — see [its README](scripts/README.md) |
| [`hooks/`](hooks/) | two SessionStart checks that belong to running this across several repos: `connector-sessioncheck` and `script-contract-sessioncheck`. Both are read-only and never block |
| [`blueprint/`](blueprint/) | the source's own answers to the repo-owned seam, with the reasoning behind each — read by the `adopt-config` skill |
| [`templates/`](templates/) | the one file in this cycle that has to be **copied** rather than imported: `pull_request_template.md`. GitHub reads a PR template only from `.github/` in your own repo, so what ships here is the reference to copy and to diff against — see the [`open-pr` skill](skills/open-pr/SKILL.md) for the two promises it makes |

**No `agents/`, no `manuals/`.** Those belong to a team, and a workflow that shipped one would be
answering the question the other directory owns.

## The nine skills

| skill | when |
|---|---|
| [`adopt-workflow-folder`](skills/adopt-workflow-folder/SKILL.md) | right after installing — scaffolds `workflow-davekjohn/`, the one folder in your root where everything portable gathers (an install alone writes nothing into your repo) |
| [`new-branch`](skills/new-branch/SKILL.md) | starting any piece of work — creates the branch and both `workflow-davekjohn/branch/` files in one move |
| [`park`](skills/park/SKILL.md) | handing an unfinished branch to another machine: push, no PR |
| [`open-pr`](skills/open-pr/SKILL.md) | the work is committed — runs the four gates, pushes, opens the PR with the title and body composed from the entry |
| [`ship-pr`](skills/ship-pr/SKILL.md) | open → wait for CI → merge → fold, in one motion |
| [`fold-changelog`](skills/fold-changelog/SKILL.md) | the fold on its own, after a merge done by hand |
| [`cut-release`](skills/cut-release/SKILL.md) | the release: the bump, the notes, the tag, and the closing steps the script does not automate |
| [`adopt-config`](skills/adopt-config/SKILL.md) | first-time setup — reads the blueprint, places what states the shared way of working, proposes the rest |
| [`fix-mojibake`](skills/fix-mojibake/SKILL.md) | repairing encoding damage in markdown |

## What it expects from your repo — the seam

The shared scripts dot-source two **repo-owned** files, so the parts that legitimately differ per repo are
answered by the repo rather than baked into the plugin:

- **`scripts/repo-config.ps1`** — the seam: the trunk name, the lint script, the merge method, the release
  grouping, and the rest.
- **`scripts/lib/branch-info.ps1`** — your branch taxonomy: which prefixes exist and what each one means.

`specialists-init` (from `team-alpha`) scaffolds both, and **`adopt-config` fills them in**: it *places*
the answers that state a shared way of working and *proposes* — never places — the answers that state what
your repo **is**. A `decide` answer is deliberately never written as a stub, because a stub returning a
placeholder overrides a documented fallback that is usually right; absent beats wrong.

## Exactly one workflow, ever

**At most one workflow plugin may be enabled.** Two would hand the specialists two contradicting answers to
the same question — how a branch is named, what a change owes before it can open a PR, what a release is —
with nothing in the session saying which one is this repo's. That is not hypothetical: this plugin and
`workflow-default` genuinely disagree, by design, about whether a branch owes an entry file at all.

The `workflow-sessioncheck` hook enforces it, and it lives in **`team-alpha`** rather than here — the core
is the one plugin every consuming repo enables, so it is the only place a check can see all the enabled
workflows at once. Putting a copy in each workflow would fail in exactly the case it is needed: a conflict
takes two plugins, and only one of them has to have left the check out.

Switching between the two is an ordinary plugin swap rather than a migration; both directions are described
in [`workflow-default`'s README](../workflow-default/README.md#switching-to-another-workflow). Disabling
this plugin removes nothing it already wrote to your repo — your entry files and your config stay; the
skills and scripts that read them stop.

## Enabling it

Part of the adoption path in [`../../INSTALL.md`](../../INSTALL.md);
[`../../UNINSTALL.md`](../../UNINSTALL.md) is the mirror. It requires the core team `team-alpha`, which
every consuming repo enables anyway.
