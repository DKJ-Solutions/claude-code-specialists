# CLAUDE.md — claude-code-specialists

This file is the operating guide for this repo, which is run by the **Claude Specialists** — a team
of specialized Claudes under a single Chief of Staff. It is structured like every specialist manual:
**the portable way of working comes first** (the system and the constitution, valid in every repo
that works with the Claude Specialists), and **everything specific to this repo comes last**, under
[`## Specific to this repo (claude-code-specialists)`](#specific-to-this-repo-claude-code-specialists).

> **This repo is a special case.** See [`README.md`](README.md) for what claude-code-specialists is and
> [`## Specific to this repo (claude-code-specialists)`](#specific-to-this-repo-claude-code-specialists)
> below for the team that maintains it.

---

## Safety rules

**Constitution — read this first.** These rules are broadly shared and take precedence over any
convenience; all other working practices live in the specialist manuals. The concrete implementation
for this repo (the main branch, the lint gate, the fold exception, being public) is in
[`## Specific to this repo (claude-code-specialists)`](#specific-to-this-repo-claude-code-specialists).

### Never without Dave's explicit permission

- **Merging work with a visible result** — if the change produces something Dave has to judge with
  his own eyes (a frontend, styling, rendered output, an artifact), the branch stops and reports
  instead of merging. No automated gate can prove that something *looks* right. Work whose
  correctness the gates do prove runs through on its own (see below).
- **A release/version bump** of a plugin (raising `version` in a `plugin.json`, creating a tag) —
  only on explicit request. **The closing steps of a cut that was asked for are covered by that
  request**, including **publishing the GitHub Release**: the version bump and the tag are the
  irreversible act, and once they are authorised, stopping again at the last step of the same
  checklist is a rubber stamp. So "cut a release" runs through: generate, ship the hand-written
  documents via their PR, publish. Where a repo has a separate **live stage**, that block is not part
  of this — a Release document describes a version, a live push changes what customers see. Decision
  by Dave, August 5, 2026; the release manager's own statement of it is in his portable body.

  **And the same holds at the other end of the checklist, for the preparation a cut cannot run
  without.** Opening a new **major** stops before anything is written: the release overview needs that
  major's own section, and the test pinning which major the overview targets has to be repointed at it.
  Neither edit is made for you — opening a major is a deliberate milestone moment — so both land
  directly on the trunk, ahead of the release commit they exist to enable. They are covered by the
  same request, and **bounded by it**: only for a major, only those two files, and only once a cut has
  actually been asked for. Without a cut on the table there is nothing for them to be part of, and
  they are then ordinary changes needing an ordinary route. Decision by Dave, August 9, 2026, after the
  `v4.0.0` cut needed both by hand under an exception nobody had granted.
- **`git push --force`** (on any branch whatsoever), **`git reset --hard`**, **`git rebase`** on a
  shared branch.
- **Publishing anything externally** beyond the normal PR flow (issues on other repos, a gist, an
  external post).

### Never directly on the main branch — via branch + PR

All changes go through a branch + Pull Request. **Whether that PR waits for Dave depends on what is
in it**, and the test is one question: *does Dave's own look add something the gates cannot?*

- **The default — no waiting.** Once the work on a branch is finished, committed, and the gates are
  green, the whole movement runs in one go: opening → merging → folding the changelog entry, with no
  intermediate question. This covers the bulk of the work — scripts, tests, config, manifests, docs,
  agent defs and manuals, the changelog, research. The lint gate, the test gate, and CI prove this
  kind of change is sound; a stamp from Dave adds nothing to that, and anything that does turn out
  wrong is one revert PR away.
- **The exception — stop and wait for Dave's word.** Two kinds of change do not merge on their own:
  1. **A visible result** — the change produces something that has to be judged by eye: a frontend,
     styling, rendered output, an artifact. No gate can prove that something looks right.
  2. **Irreversible or outward-facing** — a release, a version bump, a tag, repo settings or
     rulesets, or publishing anything beyond the normal PR flow.
- **Dave keeps the wheel in both directions.** He can pull any single piece of work under the
  exception when he assigns it ("this one I want to see first"), and then the chain waits. And when
  he *does* give an explicit PR command ("open the PR", "set up the PR", "take it live"), that counts
  as approval for the whole movement exactly as it always did.

The reasoning behind the default: Dave's substantive approval is given in the conversation *before*
the work is built, not at the merge button afterwards. Where the button used to be a second
checkpoint, in practice it was a rubber stamp — so it is only a checkpoint now where it genuinely
buys something. Decision by Dave, July 27, 2026.

On the main branch a few narrowly defined, deliberate exceptions to "never commit directly" exist —
the **fold commit** after a merge and the **release commit** (on explicit request) — and a
**lint gate** serves as the safety guard before every PR. Exactly which exceptions apply here and
how they are implemented (scripts, scope) is described in the repo slot. A release and the
destructive actions above happen only on Dave's explicit request.

---

## General working practices

- **Lessons learned are secured in the docs, not just in memory.** If a specialist learns an
  important lesson or discovers something that must be remembered for next time, it is recorded
  immediately in the relevant doc(s) — `README.md`, this `CLAUDE.md`, or a manual/agent def
  — a memory note alone is too noncommittal. (In this repo that is the technical-writer specialist,
  [Tessa #16](.claude/specialists/lenses/06-16-extension.md).)
- **A reported finding's *reason* is verified before it is repaired, not just its symptom.** A report
  says both what went wrong and why, and the second half is an inference by someone who was measuring
  the outside. Read the code, the doc, or the output that would have to be true for that explanation
  to hold — and if it does not, the repair changes with it. Building the proposed fix on an unverified
  reason produces a change that satisfies the report and is wrong, which is worse than the original
  defect: it now carries a citation. Inbound
  [#388](https://github.com/DaveKJohn/claude-code-specialists/issues/388) is the measured instance
  (August 2, 2026). It reported that the teardown does not count a fixture's `README.md` "even as
  prose", and proposed deleting the sentence that promised the count. The symptom was real — nothing
  about that file appears in the output — but the reason was not: the prose pass *does* scan the root
  markdown, and the file scores **0** because it deliberately names no specialist, with the note
  printed only above zero. Following the proposal would have deleted a correct sentence and left the
  next reader with the same confusion, minus the explanation.
- Within a branch, be proactive about creating new folders/files as soon as a new topic comes up.
  Don't ask permission first for the file structure itself; do ask for the content if something is
  sensitive or uncertain.
- When in doubt about priority: ask about deadlines/urgency instead of guessing.
- **Approval questions are rare, not the norm.** Interrupt Dave only for truly exceptional actions:
  irreversible, outward-facing, or carrying real risk (cutting a release, publishing externally,
  something destructive). All routine work — git, bash, config, branches, commits, tooling/scripts,
  and passing a specialist's delivery on to the next link in an already agreed chain — is simply
  executed and reported, not asked about first. When in doubt, a specialist picks a sensible
  default, executes it, and reports it. This is separate from the PR rule above: a PR always waits
  for Dave's explicit word — that is the deliberate, explicitly named exception to this rarity
  rule, not a contradiction of it.

---

## Specific to this repo (claude-code-specialists)

> *Everything above is the portable way of working of a repo run by the Claude Specialists. This
> part is the claude-code-specialists lens: if you copy this system to another repo, this is the part
> you replace — it doesn't describe that there are specialists and safety rules, but what this repo
> is, which team works here, and how the constitution is concretely implemented here.*

`claude-code-specialists` is the **home repo of one product**: the Claude Specialists system, built and
maintained here by Dave (DaveKJohn), and the **single source of truth** for all shareable subagent
definitions — every consuming repo (life-hub, smartwatchbanden) points here and enables or disables
per plugin. The full story — the plugins (teams and workflow) and how they differ, the split manual model, the
bootstrap path, and consumption — is in the [root `README.md`](README.md); the drift lint is in the
[connectors README](connectors/README.md#maintenance-drift-lint).

**One product, one repository — and therefore one marketplace.** This repo used to be framed as a
*workshop*: `davekjohns-workshop`, the marketplace where **all** of Dave's plugins would be built, with
the specialists as the first family among more to come. That framing was retired on August 3, 2026,
together with the directory layer that was holding a place for the second family. The reason is the
release train: it is repo-wide, so one `CHANGELOG.md`, one `vX.Y.Z` tag and a lockstep version bump
cover everything in the repo. A second, unrelated product would be bumped for work it never had, one
tag would span two products, and one changelog would mix two histories. So the next product gets its
own repository and its own marketplace instead.

**The nuance, so nobody repairs the wrong thing: lockstep *within* this product is correct** and
[`cut-release.ps1`](scripts/release/cut-release.ps1) needs no change. The plugins are one system —
a stack of teams plus one opt-in workflow — and a consumer running `team-alpha` alongside `team-shopify`
needs matching versions. What was wrong was never the lockstep, but housing unrelated products in a single release
train, and that dissolved with the reorganisation rather than needing a fix. Decision by Dave,
August 3, 2026; the reader-facing statement is in
[`README.md`](README.md#one-product-one-repository).

**The repo consumes itself.** Via [`.claude/settings.json`](.claude/settings.json) this repo enables
its own `team-alpha` plugin (the core team), with the `github` marketplace source
`DaveKJohn/claude-code-specialists` — so the repo points at itself. That way the maintenance team works
with exactly the product it maintains. One consequence to be aware of: through the `github` source
the team sees the **last pushed** version of the plugins, not your ongoing branch work — an agent
def you modify on a branch only takes effect after merge + push. A second: being a consumer, this repo
carries an install record keyed on its **folder path**, so renaming or moving this checkout unlinks the
plugin without any error — the measured instance and the repair are in
[Sylvester #15](.claude/specialists/lenses/05-15-extension.md#repo-specific-rules).

### Language

**Repo content is English** — every layer, the script layer included: comments, docstrings, console
output, and script-generated document content. **The session-reply language is separate and follows
the user.** That second half applies to every turn regardless of which files it touches, which is why
it lives here rather than in a path-scoped rule. The system-wide norm (and its three exceptions) is in
[Tessa #16's portable manual](plugins/teams/team-alpha/manuals/06-16-manual.md#what-tessa-covers)
under **"Guarding the language convention,"** so it travels to every consuming repo.

**The per-layer detail — which layers are in scope, and the deliberate exceptions (`VUL-IN`,
`lint-en-tests`, the legacy markers, the archived release notes) — is in
[`.claude/rules/language-layers.md`](.claude/rules/language-layers.md).** It is path-scoped to
`scripts/**`, the plugin-carried `plugins/**/scripts/**` and `plugins/**/hooks/**`, `.github/**`,
`releases/**` and `CHANGELOG.md`, so it loads when you touch one of those layers instead of in every
session. Two things to know before moving anything else there: a
`paths:`-scoped rule is **lost after a `/compact`** until a matching file is read again, and a rule
*without* `paths:` loads unconditionally and therefore **saves nothing** — the scoping is the saving.
So only content that is inert until you open a matching file belongs there. Decision by Dave,
July 20, 2026; sharpened July 21 and July 26, 2026.

### Structure — where everything lives

The full repo layout (`.claude-plugin/`, `plugins/` incl. `teams/agent-shared/`, `connectors/` at the root,
`scripts/`, `releases/`, `.claude/`, and the root docs + `.github/`) is described in
[README.md](README.md#repo-layout). Since August 3, 2026 the plugins sit **one** level down in
`plugins/<plugin>/` instead of two in `claude-code-plugins/claude-specialists/<plugin>/`: that second
level existed to hold several product families side by side, which the
[one-product rule](#specific-to-this-repo-claude-code-specialists) above retired. `connectors/` moved
**to the root** in the same movement, deliberately — it is the consumer register read by
`scripts/sync/`, not plugin payload, and must not travel along in the plugin cache. `agent-shared/`
stayed **inside** `plugins/` for the mirror-image reason: it *is* plugin source.

**And on August 17, 2026 it moved one level further in, to `plugins/teams/agent-shared/`** (Dave). Same
reasoning, applied one level down: every file carrying a shared block is a team's — 30 agent defs and
personas across all four teams, none in either workflow — so sitting beside `teams/` and `workflows/`
claimed a reach the folder does not have. **Nothing in the tooling had to learn the new address**, which
is the part worth keeping: every script that asks which plugins exist reads `marketplace.json` through
[`plugin-tree-lib.ps1`](scripts/lib/plugin-tree-lib.ps1), so a directory in no marketplace is not a
plugin wherever it sits — and the `[plugin-kind]` rule that requires `team-*` under `plugins/teams/` is
anchored on the published set rather than on a sweep of that directory. Under the previous
shape this exact folder had to be excluded **by name**, and that exclusion had already gone stale once.
The one thing that did change is a publish: `agent-shared/` now sits inside the `teams` kind-directory,
which `publish-to-business.ps1` prunes when it holds no plugin — so it travels with the teams it feeds
instead of unconditionally. Reader-facing statement in
[`plugins/teams/README.md`](plugins/teams/README.md).

### claude-code-specialists's safety implementation

**This section stands on its own, and that is deliberate.** Everything below holds in this repo
whether or not a plugin is installed — the branch, the PR, the required CI check, the lint and test
gates, and the two exceptions with their bounds. **The layer on top** is the `workflow-davekjohn`
plugin, which carries its own page:

📄 **[`workflow-davekjohn/CLAUDE.md`](workflow-davekjohn/CLAUDE.md)**

**When the plugin is installed, that page applies on top of this one — and where the two disagree, the
plugin's page wins.** It does not replace anything below; it adds the workflow's own mechanics (the two
gates on the branch dossier, how the exceptions actually run, the measurements behind them). The
layering mirrors the one [`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md)
already makes over the root [`CONTRIBUTING.md`](CONTRIBUTING.md) (Dave, August 14, 2026), and
was extended to this operating guide on August 19, 2026. The second reason is the one the two moves
before it give: this file loads on **every** session, the folder page only when a session touches that
folder.

The constitution above, concretely implemented here:

- **The main branch is `main`.** All changes via a `<prefix>/<short-name>` branch + PR to
  `main`. Valid prefixes ([`scripts/lib/branch-info.ps1`](scripts/lib/branch-info.ps1)):
  `feat/` → enhancement · `fix/` → bug · `docs/` → documentation. **Three, and `chore/` is refused**
  (Dave, August 7, 2026): chore is the name for work that lands *directly on the trunk* under one of the
  named exceptions, so a chore branch is a contradiction. `Chore` remains a recognised changelog **type**
  — every entry already written under it still has to validate — it just has no prefix any more. The rule
  had always held and was never enforced; measured on the day it was written down, `chore/` had been used
  12 times. See
  [Derek #05](.claude/specialists/lenses/05-05-extension.md#classifying-naming-and-creating-a-branch).
- **The lint and test gates are the safety guard before every PR.**
  [`scripts/lint/check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1) validates the
  manifests (`marketplace.json` + every `plugin.json`) and the agent-def and manual frontmatter,
  scans for dead links, and holds every **printed** `claude plugin install`/`update`/`uninstall` to
  its flags (`--scope project`, plus the marketplace refresh for install/update) — the class of doc
  defect three adoption rounds in a row kept producing; after that all test suites run
  (`scripts/tests/*.tests.ps1`), exactly as CI
  does. `open-pr.ps1` runs both gates first; on an error or a failing suite nothing is pushed and
  no PR is opened (`-SkipLint`/`-SkipTests` are the escape valves). See [Sylvester #15](.claude/specialists/lenses/05-15-extension.md).

  **Why these checks have the shape they do — and every rule that was measured and DECLINED — is in
  [Sylvester #15](.claude/specialists/lenses/05-15-extension.md#how-the-gate-checks-got-their-shape-and-the-measurements-behind-them-august-15-2026)**:
  the entry-format count and the four candidate rules behind it, the stale-path check declined at 124
  findings all false, the PR template measured over 60 PRs, and the two repairs it took to reach
  `CHANGELOG.md`'s intro. **Read it before changing any check above** — most of what looks arbitrary
  here was measured there. Moved off this always-on path on August 15, 2026, where it was 9,440 B over
  102 lines: 26% of this document, and the same shape as the release craft moved out the day before.

- **Two more gates arrive with the workflow plugin**, and both read the branch's own two files: the
  **scaffold gate** refuses to push an entry still carrying the wording `new-branch.ps1` wrote it
  with, and the **step-list gate** refuses to push *and* to merge while
  `workflow-davekjohn/branch/branch-progress.md` has an unresolved step. Their mechanics, escape
  valves and the measurements behind them are in
  [`workflow-davekjohn/CLAUDE.md`](workflow-davekjohn/CLAUDE.md#the-two-gates-this-workflow-adds-on-top).
- **Two deliberate exceptions to "never directly on `main`", each one bounded:**
  1. The **fold commit** after a merge: [`fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1)
     folds the entry into `CHANGELOG.md` and clears it, and with `-Commit`/`-Push` makes that commit
     itself. **Bounded to three paths** — `CHANGELOG.md`, the entry, and
     `workflow-davekjohn/branch/branch-progress.md`, which the same run resets — and the commit names
     them, so nothing else in the tree can ride along. Committing stays opt-in, because it is this
     exception being used.
  2. The **release commit** (only on explicit request): [`cut-release.ps1`](scripts/release/cut-release.ps1)
     bumps all plugin versions in lockstep, generates the release notes in `releases/development/`,
     **empties `CHANGELOG.md` down to its intro**, commits that on `main`, and tags `vX.Y.Z`.
     Deliberately no branch/PR — just like the fold. **A major additionally needs two preparation
     commits ahead of it** (Dave, August 9, 2026), under this same exception and bounded just as
     narrowly: a **major** only, **two paths** only (the new `#### N.x` section in
     [`releases/README.md`](workflow-davekjohn/releases/README.md) and the assert in
     [`release-lib.tests.ps1`](scripts/tests/release-lib.tests.ps1) that pins which major it targets),
     and only once a cut has been **explicitly asked for**. Outside a cut, both files take the
     ordinary branch + PR route. **What the exception does *not* cover**: the hand-written release
     documents — the consumer-document edit and the internal note — land **via a branch + PR**, not
     under it (Dave, August 4, 2026, declining the wider version he was offered).

  **An exception is only safe while it stays the size it was granted at** — the lesson `ship-pr.ps1`
  cost on August 2, 2026, and the reason both bounds are stated here rather than left to the layer
  below. How the two actually run, which release documents are deliberately *not* covered by the
  second one, and the measurements behind each are in
  [`workflow-davekjohn/CLAUDE.md`](workflow-davekjohn/CLAUDE.md#how-the-two-direct-on-main-exceptions-actually-run)
  and in [Rendall #06](.claude/specialists/lenses/05-06-extension.md#versioning--releases).
- **This repo is `public`.** A deliberate choice, so the remote `github` marketplace source can be
  read without gh auth. Consequence: **nothing confidential** belongs here — no personal
  information, credentials, or secrets. The core team's (`team-alpha`) agent defs are therefore
  deliberately repo-neutral; repo-specific context lives in the consuming (private) repo's
  `.claude/specialists/lenses/` lens.
- **Changes to shared agent defs land here first**, are committed here, and only then picked up by
  the consuming repos — never the other way around.
- **And because this repo *is* the source, the shared source is the default destination for a lesson
  learned here — not the lens** (Dave, August 4, 2026). The lens is for what a *consumer* would
  genuinely have to differ on; it is not the convenient place to write something down because it is the
  file already open. Writing a portable rule into the lens leaves the source thinner than the repo that
  maintains it, and nobody downstream ever receives it. Measured that day: Rendall #06's portable persona
  was **1,700 bytes** while his repo lens had grown to **26,914** — sixteen times larger, holding the
  release craft itself rather than anything specific to this repo. **Which layer a rule belongs in, and
  the split when a rule has both a portable and a local half, is in the
  [Specialists handbook](.claude/specialists/README.md#where-a-new-rule-goes--the-source-is-the-default-the-lens-is-the-exception)**
  — including the measured convention that personas and manuals carry no repo-specific detail at all
  while skills carry the evidence behind a procedure.

### The how (portable) vs. the what (repo-specific)

In short: the **how** (there is a team of specialists under a Chief of Staff, everything via
branch + PR, lessons learned in the docs, the constitution above any convenience) is portable and
sits at the top. The **what** (this small maintenance team, the marketplace/plugin structure, the
language, the concrete `main` branch and fold exception, the scripts, and the plugin lint gate)
belongs to this repo and sits in this slot.

The orchestrator (Chris) is always loaded along; he refers on demand to the specialists in
[`.claude/specialists/lenses/`](.claude/specialists/lenses/).

The orchestrator (Chris) is always loaded -- portable body from plugin install and repo lens
from `.claude/specialists/`; that file carries the body import, the lens import and this repo's roster.

@.claude/specialists/SPECIALISTS.md
