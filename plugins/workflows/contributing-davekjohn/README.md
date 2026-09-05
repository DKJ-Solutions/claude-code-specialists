# contributing-davekjohn — one particular way of working, packaged so a repo can choose it

**This is DaveKJohn's own branch-and-entry model, and the name says whose it is on purpose.** It is not a
baseline every consumer inherits and not a standard: it is one answer to *how does work move through this
repo*, offered as something a repo can deliberately pick up. There is no sibling to inherit instead: what
a repo has until it chooses this one is its own way of working, which it never stopped having.

**It carries no specialists.** A workflow changes how the existing ones work, not who they are; the
specialists come from [the teams](https://github.com/DaveKJohn/claude-code-specialists/tree/main/). Enabling this without `team-alpha` gives you skills with
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
`## Specific to this repo` section on whichever page carries your floor -- normally your root
`CONTRIBUTING.md`, and see that page's closing section for when it is not -- holding your values; the source
repo's
[own answers](https://github.com/DaveKJohn/claude-code-specialists/blob/main/contributing-davekjohn/CONTRIBUTING.md)
are a worked example of that half.

**That link moved on August 27, 2026, and the old one is why this sentence is worth reading twice.** It
pointed at the source's ROOT `CONTRIBUTING.md`, which #980 deleted -- so the worked example this page
offered a consumer was a 404, while the sentence around it still told them to put their values in a root
page unconditionally. The source keeps its floor in `contributing-davekjohn/CONTRIBUTING.md` now, and which
file carries yours is your answer to make.

**And if your work arrives from somebody else's tracker, that layer is step 1 of the cycle rather than a
page of its own.** [The ticket-work section](CONTRIBUTING-portable.md#ticket-work--the-layer-before-the-branch)
carries it: how to tell a request that cannot be built from one we are merely unconvinced by, which six
kinds of question are not blockers, and why a status in a heading is always false. Rules only, no template —
they come from one repo and one day, which the section says out loud.

**It was a fourth portable page, `TICKETWORK-portable.md`, until August 30, 2026.** What retired it was not
its size but its reach: the cycle document began at the branch and never mentioned it, so a reader following
that cycle end to end met neither the section nor the step it described
([#1123](https://github.com/DaveKJohn/claude-code-specialists/issues/1123)).

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
| [`skills/`](skills/) | the skills a specialist invokes — this is where most of the workflow lives |
| [`scripts/`](scripts/) | the scripts and libs those skills run, mirrored from the source repo's own `scripts/`. **Never edit a file there** — see [its README](scripts/README.md) |
| [`hooks/`](hooks/) | read-only SessionStart checks that never block, all belonging to running this across several repos — among them `connector-sessioncheck`, `script-contract-sessioncheck`, `consumer-prose-sessioncheck` (your own always-on prose contradicting this workflow — two detectors over one corpus read once, since #1421: a convention this workflow has renamed, still stated as current, #1389, and your own `CLAUDE.md` declared the winner over this workflow's contributing layer, inverting the rank order, #1415) — plus one **Stop** hook that acts rather than reports: `cycle-autopark` pushes the branch's `<branch>.md` to `origin` after every turn, until a PR publishes it (#900). **The set is deliberately not counted here**: this cell said "two" and went stale twice inside two days, and [`hooks/hooks.json`](hooks/hooks.json) is the one place that cannot |
| [`blueprint/`](blueprint/) | the source's own answers to the repo-owned seam, with the reasoning behind each — read by the `adopt-config` skill |
| [`templates/`](templates/) | the one file in this cycle that has to be **copied** rather than imported: `pull_request_template.md`. GitHub reads a PR template only from `.github/` in your own repo, so what ships here is the reference to copy and to diff against — see the [`open-pr` skill](skills/open-pr/SKILL.md) for the one promise it makes: the placeholder line |

**No `agents/`, no `manuals/`.** Those belong to a team, and a workflow that shipped one would be
answering the question the other directory owns.

## The skills

**All of them, deliberately — and the heading no longer says how many.** A partial list of an enumerable
set is worse than none: a reader who finds one of their skills undocumented here cannot tell which of the
two documents is wrong. It has been wrong three times, and every time a number is what made the gap look
like a decision:

- nine rows under the heading "The nine skills" while the directory held twelve — `lock`, `handover` and
  `prompt` had each arrived without one (all three are gone now:
  [#882](https://github.com/DaveKJohn/claude-code-specialists/issues/882) retired `prompt` and
  [#957](https://github.com/DaveKJohn/claude-code-specialists/issues/957) the other two, both Dave's);
- thirteen rows against fourteen directories — `check-branch-entry` had shipped without a row and stayed
  missing until August 21, 2026, when `prune-merged` was added and the set was recounted;
- fourteen rows against sixteen directories, under a heading still reading twelve — `measure-skill` and
  `worktree-lane` both absent, repaired here
  ([#873](https://github.com/DaveKJohn/claude-code-specialists/issues/873), August 26, 2026).

**Dropping the count is the cheaper half of the repair, and it has been tried on its own before — it did
not stop the drift, it only made it quieter.** So it is gone from the heading and from the layout table
above — and since August 26, 2026 the table below is **machine-checked**, which is the half that actually
closes the recurrence. The source repo's lint gate holds marked enumeration spans to the real skill set,
and this table now carries one.

**It took a second marker to get there, and the reason is worth keeping**, because it is a property of the
older check rather than of this document. The marketplace-wide `skills:all` span (`[skill-list]`, check 10
of `scripts/lint/check-plugin-integrity.ps1`) could not serve here on two counts:

- **Its canonical set is repo-wide.** It is built from every published plugin's `skills/`, so it holds a
  span to *all* the skills the marketplace ships. This table enumerates one plugin's, so a span there would
  report every team plugin's skills as missing.
- **Every backtick-quoted token inside its span counts as a claimed name**, so that span has to close around
  nothing but the names. A two-column table cannot honour it: three rows below carry a backticked path or
  flag in their second column.

The `skills:plugin` span (`[skill-list-plugin]`, check 29) is the plugin-scoped sibling that answers both
([#920](https://github.com/DaveKJohn/claude-code-specialists/issues/920)). It resolves the plugin from the
**document's own path** rather than from anything written in the marker, and it reads each row's **link
target** — `skills/<name>/SKILL.md` — instead of its backticks, so prose and backticked paths anywhere else
in a row cost nothing. Adding a skill to this plugin without adding a row now turns the source repo's
gate red rather than relying on somebody remembering. *Count when you add one* has been retired; the
check counts. That gate runs where this plugin is **maintained**, not where it is installed — nothing
below changes for you, and nothing here asks you to run anything.

<!-- skills:plugin -->

| skill | when |
|---|---|
| [`adopt-workflow-folder`](skills/adopt-workflow-folder/SKILL.md) | right after installing — scaffolds `contributing-davekjohn/`, the one folder in your root where everything portable gathers (an install alone writes nothing into your repo) |
| [`adopt-config`](skills/adopt-config/SKILL.md) | first-time setup — reads the blueprint, places what states the shared way of working, proposes the rest |
| [`new-branch`](skills/new-branch/SKILL.md) | starting any piece of work — creates the branch and its `contributing-davekjohn/<branch>.md` in one move |
| [`park`](skills/park/SKILL.md) | handing an unfinished branch to another machine: push, no PR |
| [`worktree-lane`](skills/worktree-lane/SKILL.md) | one branch has to be built while another one ships — opens a branch in its own worktree, and hands it back when it is ready to ship |
| [`open-pr`](skills/open-pr/SKILL.md) | the work is committed — runs the four gates, pushes, opens the PR with the title and body composed from the entry |
| [`ship-pr`](skills/ship-pr/SKILL.md) | open → wait for CI → merge → fold, in one motion |
| [`fold-changelog`](skills/fold-changelog/SKILL.md) | the fold on its own, after a merge done by hand |
| [`check-branch-entry`](skills/check-branch-entry/SKILL.md) | the CI gate on the branch dossier — the same two checks `open-pr` runs, where a hand-pushed branch cannot escape them |
| [`prune-merged`](skills/prune-merged/SKILL.md) | merged branches have piled up in the clone — reaps the local ones it can prove are merged, and leaves every other one alone |
| [`cut-release`](skills/cut-release/SKILL.md) | the release: the bump, the notes, the tag, and the closing steps the script does not automate |
| [`release-notes-page`](skills/release-notes-page/SKILL.md) | after a release — builds the hand-written notes into one browsable page for the reader they are written for, and optionally the Cloudflare Worker that hosts it |
| [`fix-mojibake`](skills/fix-mojibake/SKILL.md) | repairing encoding damage in markdown |
| [`measure-skill`](skills/measure-skill/SKILL.md) | pricing what a skill costs the sessions that carry it — always-on against on-invoke tokens, the delta against a stored baseline, and the wall-clock of the script behind it |

<!-- /skills:plugin -->

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

**`bwj-codex` is a second workflow, added August 31, 2026 with that question answered.** It shares
none of the contradictions above: it extends only the *ticket-work* step — how a discovered issue is
filed and mirrored to Asana in BWJ's two Shopify store repos — and says nothing about branch naming,
the pre-PR bar, or releases. It **requires** this plugin rather than competing with it. A repo that
enables both gets one branch-and-release discipline and one ticket rule layered on its front, not two
answers to one question. The retired guard's reasoning still applies to any *third* workflow that
overlaps either of these.

**And the collision this plugin could have with your own contributing rules is answered by isolation
instead.** Its changelog and its releases live inside **its own folder**, so what it writes never lands
in your repo's root and never competes with the conventions you already had. Keeping both side by side is
a supported answer, which is the reason there is no default to switch away from.

Disabling this plugin removes nothing it already wrote to your repo — your entry files and your config
stay; the skills and scripts that read them stop.

## Enabling it

Part of the adoption path in [`../../INSTALL.md`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/);
[`../../UNINSTALL.md`](https://github.com/DaveKJohn/claude-code-specialists/blob/main/) is the mirror. It requires the core team `team-alpha`, which
every consuming repo enables anyway.
