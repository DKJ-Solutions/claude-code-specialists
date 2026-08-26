# contributing-davekjohn — one particular way of working, packaged so a repo can choose it

**This is DaveKJohn's own branch-and-entry model, and the name says whose it is on purpose.** It is not a
baseline every consumer inherits and not a standard: it is one answer to *how does work move through this
repo*, offered as something a repo can deliberately pick up. There is no sibling to inherit instead: what
a repo has until it chooses this one is its own way of working, which it never stopped having.

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
[`DEVELOPMENT-portable.md`](DEVELOPMENT-portable.md) for the branch's own document, beside
[`CONTRIBUTING-portable.md`](CONTRIBUTING-portable.md) for the cycle that connects them.

## What is in this folder

| what | what it holds |
|---|---|
| [`CONTRIBUTING-portable.md`](CONTRIBUTING-portable.md) | the contribution cycle in prose, seam-named — the human-facing half, meant to be read alongside your own repo's answers |
| [`RELEASES-portable.md`](RELEASES-portable.md) | the release workflow: the tier model, what a release must earn, the release documents, and how one is cut — your own `contributing-davekjohn/releases/README.md` holds your answers and your release list |
| [`DEVELOPMENT-portable.md`](DEVELOPMENT-portable.md) | the document a branch works in: its two halves, the dossier form, the three step marks, the version suffix, its branch-long lifetime, and what the fold does at the merge |
| [`TICKETWORK-portable.md`](TICKETWORK-portable.md) | the rules for the layer *before* a branch, in a repo whose work arrives from somebody else's tracker: whether a request can be built as written, and how the answer is recorded. Rules and reasoning only — no template and no script, deliberately |
| [`skills/`](skills/) | the skills a specialist invokes — this is where most of the workflow lives |
| [`scripts/`](scripts/) | the scripts and libs those skills run, mirrored from the source repo's own `scripts/`. **Never edit a file there** — see [its README](scripts/README.md) |
| [`hooks/`](hooks/) | two read-only SessionStart checks that never block, both belonging to running this across several repos: `connector-sessioncheck` and `script-contract-sessioncheck` |
| [`blueprint/`](blueprint/) | the source's own answers to the repo-owned seam, with the reasoning behind each — read by the `adopt-config` skill |
| [`templates/`](templates/) | the one file in this cycle that has to be **copied** rather than imported: `pull_request_template.md`. GitHub reads a PR template only from `.github/` in your own repo, so what ships here is the reference to copy and to diff against — see the [`open-pr` skill](skills/open-pr/SKILL.md) for the two promises it makes |

**No `agents/`, no `manuals/`.** Those belong to a team, and a workflow that shipped one would be
answering the question the other directory owns.

## The skills

**All of them, deliberately — and the heading no longer says how many.** A partial list of an enumerable
set is worse than none: a reader who finds one of their skills undocumented here cannot tell which of the
two documents is wrong. It has been wrong three times, and every time a number is what made the gap look
like a decision:

- nine rows under the heading "The nine skills" while the directory held twelve — `lock`, `handover` and
  `prompt` had each arrived without one (`prompt` itself is gone since
  [#882](https://github.com/DaveKJohn/claude-code-specialists/issues/882), Dave);
- thirteen rows against fourteen directories — `check-branch-entry` had shipped without a row and stayed
  missing until August 21, 2026, when `prune-merged` was added and the set was recounted;
- fourteen rows against sixteen directories, under a heading still reading twelve — `measure-skill` and
  `worktree-lane` both absent, repaired here
  ([#873](https://github.com/DaveKJohn/claude-code-specialists/issues/873), August 26, 2026).

**Dropping the count is the cheaper half of the repair, and it has been tried on its own before — it did
not stop the drift, it only made it quieter.** So it is gone from the heading and from the layout table
above, and the reason this table is still not machine-checked is written down here rather than left as a
risk. The source repo's lint gate does hold marked enumeration spans to the real skill set (`[skill-list]`,
check 10 of `scripts/lint/check-plugin-integrity.ps1`) — and this table cannot carry one, for two reasons
that are properties of that check rather than of this document:

- **Its canonical set is repo-wide.** It is built from every published plugin's `skills/`, so it holds a
  span to *all* the skills the marketplace ships. This table enumerates one plugin's, so a span here would
  report every team plugin's skills as missing.
- **Every backtick-quoted token inside a span counts as a claimed name**, so the span has to close around
  nothing but the names. A two-column table cannot honour that: three rows below carry a backticked path or
  flag in their second column.

A variant scoped to one plugin, reading each row's **link target** instead of its backticks, would fit both
constraints; it is filed as
[#920](https://github.com/DaveKJohn/claude-code-specialists/issues/920) rather than built here. Until it
exists, the only thing keeping this table true is that whoever adds a skill adds a row. **Count when you
add one.**

| skill | when |
|---|---|
| [`adopt-workflow-folder`](skills/adopt-workflow-folder/SKILL.md) | right after installing — scaffolds `contributing-davekjohn/`, the one folder in your root where everything portable gathers (an install alone writes nothing into your repo) |
| [`adopt-config`](skills/adopt-config/SKILL.md) | first-time setup — reads the blueprint, places what states the shared way of working, proposes the rest |
| [`new-branch`](skills/new-branch/SKILL.md) | starting any piece of work — creates the branch and its `contributing-davekjohn/development-cycle.md` in one move |
| [`park`](skills/park/SKILL.md) | handing an unfinished branch to another machine: push, no PR |
| [`worktree-lane`](skills/worktree-lane/SKILL.md) | one branch has to be built while another one ships — opens a branch in its own worktree, and hands it back when it is ready to ship |
| [`open-pr`](skills/open-pr/SKILL.md) | the work is committed — runs the four gates, pushes, opens the PR with the title and body composed from the entry |
| [`ship-pr`](skills/ship-pr/SKILL.md) | open → wait for CI → merge → fold, in one motion |
| [`fold-changelog`](skills/fold-changelog/SKILL.md) | the fold on its own, after a merge done by hand |
| [`check-branch-entry`](skills/check-branch-entry/SKILL.md) | the CI gate on the branch dossier — the same two checks `open-pr` runs, where a hand-pushed branch cannot escape them |
| [`prune-merged`](skills/prune-merged/SKILL.md) | merged branches have piled up in the clone — reaps the local ones it can prove are merged, and leaves every other one alone |
| [`cut-release`](skills/cut-release/SKILL.md) | the release: the bump, the notes, the tag, and the closing steps the script does not automate |
| [`release-notes-page`](skills/release-notes-page/SKILL.md) | after a release — builds the hand-written notes into one browsable page for the reader they are written for, and optionally the Cloudflare Worker that hosts it |
| [`lock`](skills/lock/SKILL.md) | closing a session — records where the work stands before a context clear |
| [`handover`](skills/handover/SKILL.md) | opening the next one — reads that record back (named for the file it reads, and to stay out of the built-in `/continue`'s way) |
| [`fix-mojibake`](skills/fix-mojibake/SKILL.md) | repairing encoding damage in markdown |
| [`measure-skill`](skills/measure-skill/SKILL.md) | pricing what a skill costs the sessions that carry it — always-on against on-invoke tokens, the delta against a stored baseline, and the wall-clock of the script behind it |

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

## One workflow, and no guard on it any more

**Two enabled workflow plugins would hand the specialists two contradicting answers to the same
question** — how a branch is named, what a change owes before it can open a PR, what a release is — with
nothing in the session saying which one is this repo's. That was not hypothetical while a second one
existed: this plugin and `workflow-default` genuinely disagreed, by design, about whether a branch owes
an entry at all.

**Both the sibling and the guard were retired on August 26, 2026**
([#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886)). The `workflow-sessioncheck`
hook that counted enabled ids beginning with `workflow-` is gone, along with the plugin whose existence
made two of them reachable. Nothing counts them now, so adding a second workflow to this family means
answering the question above again rather than trusting a check that is no longer there.

**And the collision this plugin could have with your own contributing rules is answered by isolation
instead.** Its changelog and its releases live inside **its own folder**, so what it writes never lands
in your repo's root and never competes with the conventions you already had. Keeping both side by side is
a supported answer, which is the reason there is no default to switch away from.

Disabling this plugin removes nothing it already wrote to your repo — your entry files and your config
stay; the skills and scripts that read them stop.

## Enabling it

Part of the adoption path in [`../../INSTALL.md`](../../../INSTALL.md);
[`../../UNINSTALL.md`](../../../UNINSTALL.md) is the mirror. It requires the core team `team-alpha`, which
every consuming repo enables anyway.
