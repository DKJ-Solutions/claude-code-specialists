# CLAUDE.md — claude-code-specialists

This file is the operating guide for this repo. **The rules come first** — the constitution and the
general practices, which are Dave's and hold across the repos he runs — and **everything
specific to this repo comes last**, under
[`## Specific to this repo (claude-code-specialists)`](#specific-to-this-repo-claude-code-specialists).

**Everything in this file holds on its own**, and that is deliberate. Two plugins layer on top of it
where they are installed, and nothing below assumes either one is:

- **`dkj-policy`** — the branch, entry and release mechanics, on its own page
  [`dkj-policy/CONTRIBUTING.md`](dkj-policy/CONTRIBUTING.md).
- **`team-alpha`** — the specialists, reached through the single `@`-import at the foot of this file.

Uninstall both and this guide still describes how the repo is run: the rules below are the repo's own,
and where a plugin adds to one, the addition lives in that plugin's layer rather than here. Read a
statement here as true whether or not anything is installed — if one ever is not, that is a defect in
this file.

> **This repo is a special case.** See [`README.md`](README.md) for what claude-code-specialists is and
> [`## Specific to this repo (claude-code-specialists)`](#specific-to-this-repo-claude-code-specialists)
> below for how it is maintained.

---

## Safety rules

**Constitution — read this first.** These rules are broadly shared and take precedence over any
convenience; the craft detail behind them lives in the layers named above. The concrete implementation
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
  checklist is a rubber stamp. So "cut a release" runs through: generate, commit the hand-written
  documents on `main`, publish. Where a repo has a separate **live stage**, that block is not part
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
- **Publishing anything externally** beyond the normal PR flow (a gist, an external post, an issue
  opened on somebody else's repository).

  **The inbound route is NOT this**, and it is carved out by name because an unstated exception is
  indistinguishable from a prohibition (inbound
  [#1094](https://github.com/DaveKJohn/claude-code-specialists/issues/1094), August 29, 2026). Filing
  an `inbound` issue on the **source repo of a plugin this repo consumes** needs no permission from
  anyone: it is the one outward-facing act this family asks a session to perform unprompted, and the
  only way a defect found in a consumer reaches the tree that can repair it. What applies to it is the
  ordinary filing bar in the orchestrator's body — verify it still stands, search that tracker first,
  one subject per issue — never a permission gate.

  **It matters most where this file is copied.** A consumer's scaffolded `CLAUDE.md` tells them to
  *"expand with governance and safety rules for this repo"*, and this document is the nearest model —
  so without the carve-out, adopting it hands them a rule forbidding the route the plugin they just
  installed requires of them. Measured in a fresh consumer: two real defects found during its
  adoption, both verified, neither filed.

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
the **fold commit** after a merge, the **release commit** and the **release-notes commit** (both on
explicit request) — and a **lint gate** serves as the safety guard before every PR. Exactly which
exceptions apply here and how they are implemented (scripts, scope) is described in the repo slot. A
release and the destructive actions above happen only on Dave's explicit request.

---

## General working practices

- **Lessons learned are secured in the docs, not just in memory.** If a session learns an
  important lesson or discovers something that must be remembered for next time, it is recorded
  immediately in the relevant doc(s) — `README.md`, this `CLAUDE.md`, or the layer that owns the rule
  — a memory note alone is too noncommittal. Which layer that is, and the split when a rule has both
  a portable and a local half, is settled further down under
  [the source-is-the-default rule](#claude-code-specialistss-safety-implementation).
- **A reported finding's *reason* is verified before it is repaired, not just its symptom.** A report
  says both what went wrong and why, and the second half is an inference by someone who was measuring
  the outside. Read the code, the doc, or the output that would have to be true for that explanation
  to hold — and if it does not, the repair changes with it. Building the proposed fix on an unverified
  reason produces a change that satisfies the report and is wrong, which is worse than the original
  defect: it now carries a citation. The measured instance, inbound #388, is in the
  [`triage-inbound` skill](.claude/skills/triage-inbound/SKILL.md), beside the five other ways a
  report fails on pickup.
- Within a branch, be proactive about creating new folders/files as soon as a new topic comes up.
  Don't ask permission first for the file structure itself; do ask for the content if something is
  sensitive or uncertain.
- When in doubt about priority: ask about deadlines/urgency instead of guessing.
- **Approval questions are rare, not the norm.** Interrupt Dave only for truly exceptional actions:
  irreversible, outward-facing, or carrying real risk (cutting a release, publishing externally,
  something destructive). All routine work — git, bash, config, branches, commits, tooling/scripts,
  and passing a finished deliverable on to the next link in an already agreed chain — is simply
  executed and reported, not asked about first. When in doubt, pick a sensible default, execute it,
  and report it. This is separate from the PR rule above: a PR always waits
  for Dave's explicit word — that is the deliberate, explicitly named exception to this rarity
  rule, not a contradiction of it.

---

## Specific to this repo (claude-code-specialists)

> *Everything above is how work is run here — the constitution and the general practices. They are
> **Dave's**, shared across the repos he runs rather than universal: they name him as the
> decision-maker throughout and carry this repo's own measured instances. This part is the
> claude-code-specialists lens: not *that* there are safety rules, but what this repo is and how the
> constitution is concretely implemented here. Copying this file to another repo of Dave's means
> replacing this part; copying it to somebody else's means replacing the decision-maker above it too.*

`claude-code-specialists` is the **home repo of one product**: the Claude Specialists system, built and
maintained here by Dave (DaveKJohn), and the **single source of truth** for all shareable subagent
definitions — every consuming repo (life-hub, smartwatchbanden) points here and enables or disables
per plugin. The full story — the plugins (teams and workflow) and how they differ, the split manual model, the
bootstrap path, and consumption — is in the [root `README.md`](README.md); the drift lint is in the
[connectors README](connectors/README.md#maintenance-drift-lint).

**One product, one repository — and therefore one marketplace.** This repo used to be framed as a
*workshop* meant to house every future plugin family; that framing was retired on August 3, 2026,
because the release train is repo-wide and a second product would be bumped for work it never had.
The reasoning, and which sense of the word deliberately survived, is in
[`README.md`](README.md#one-product-one-repository).

**The nuance, so nobody repairs the wrong thing: lockstep *within* this product is correct** and
[`cut-release.ps1`](scripts/release/cut-release.ps1) needs no change. The plugins are one system — a
stack of teams plus one opt-in workflow — and a consumer running `team-alpha` alongside `team-shopify`
needs matching versions. What was wrong was never the lockstep but housing unrelated products in a
single release train, and that dissolved with the reorganisation rather than needing a fix.

**The repo consumes itself.** Via [`.claude/settings.json`](.claude/settings.json) this repo enables
its own `team-alpha` plugin (the core team), with the `github` marketplace source
`DKJ-Solutions/claude-code-specialists` — so the repo points at itself. That way work here runs against
exactly the product it maintains. One consequence to be aware of: a session reads the plugins from the
**local marketplace clone**, and that clone advances on a `claude plugin marketplace update` — **not on
a push**. So an agent def you modify on a branch takes effect after merge, push *and* that refresh, and
between two releases **no version check can tell you the clone is behind**. A second: being a consumer,
whichever machine has actually run `claude plugin install ... --scope project` for this checkout
carries an install record keyed on its **folder path** there, and renaming or moving the checkout on
that machine unlinks the plugin without any error. A machine that has never run that install carries no
such record and has nothing to unlink — the record is per-machine state, not a fixed property of the
repo (inbound [#1449](https://github.com/DaveKJohn/claude-code-specialists/issues/1449)). Both measured
instances, and why detection is deliberately left alone, are in
[the system-administration lens](.claude/specialists/lenses/05-15-extension.md#repo-specific-rules).

### Language

**Repo content is English** — every layer, the script layer included: comments, docstrings, console
output, and script-generated document content. **The session-reply language is separate and follows
the user.** That second half applies to every turn regardless of which files it touches, which is why
it lives here rather than in a path-scoped rule. The system-wide norm (and its three exceptions) is in
[the technical writer's portable manual](plugins/teams/team-alpha/manuals/06-16-manual.md#what-tessa-covers)
under **"Guarding the language convention,"** so it travels to every consuming repo.

**The per-layer detail — which layers are in scope, and the deliberate exceptions (`VUL-IN`,
`lint-en-tests`, the legacy markers, the archived release notes) — is in
[`.claude/rules/language-layers.md`](.claude/rules/language-layers.md).** It is path-scoped to
`scripts/**`, the plugin-carried `plugins/**/scripts/**` and `plugins/**/hooks/**`, `.github/**`,
`releases/**`, `dkj-policy/releases/**` and `dkj-policy/CHANGELOG.md`, so it
loads when you touch one of those layers instead of in every session. Two things to know before moving anything else there: a
`paths:`-scoped rule is **lost after a `/compact`** until a matching file is read again, and a rule
*without* `paths:` loads unconditionally and therefore **saves nothing** — the scoping is the saving.
So only content that is inert until you open a matching file belongs there. Decision by Dave,
July 20, 2026; sharpened July 21 and July 26, 2026.

### Structure — where everything lives

The full repo layout (`.claude-plugin/`, `plugins/` incl. `teams/agent-shared/`, `connectors/` at the root,
`scripts/`, `dkj-policy/` (the changelog, the contributing page and the release history since
August 27, 2026; the folder was `contributing-davekjohn/` until September 5, 2026, #1437),
`.claude/`, and the root docs + `.github/`) is described in
[README.md](README.md#repo-layout). Since August 3, 2026 the plugins sit **one** level down in
`plugins/<plugin>/` instead of two in `claude-code-plugins/claude-specialists/<plugin>/`: that second
level existed to hold several product families side by side, which the
[one-product rule](#specific-to-this-repo-claude-code-specialists) above retired. `connectors/` moved
**to the root** in the same movement, deliberately — it is the consumer register read by
`scripts/sync/`, not plugin payload, and must not travel along in the plugin cache. `agent-shared/`
stayed **inside** `plugins/` for the mirror-image reason: it *is* plugin source.

**And on August 17, 2026 it moved one level further in, to `plugins/teams/agent-shared/`** (Dave):
every file carrying a shared block is a team's, so sitting beside `teams/` and `workflows/` claimed a
reach the folder does not have. **Nothing in the tooling had to learn the new address** — every script
that asks which plugins exist reads `marketplace.json` through
[`plugin-tree-lib.ps1`](scripts/lib/plugin-tree-lib.ps1), so a directory in no marketplace is not a
plugin wherever it sits. Reader-facing statement, and what the move changed for the publish, in
[`plugins/teams/README.md`](plugins/teams/README.md).

### claude-code-specialists's safety implementation

**This section stands on its own, and that is deliberate.** Everything below holds in this repo
whether or not a plugin is installed — the branch, the PR, the required CI check, the lint and test
gates, and the three direct-on-`main` exceptions with their bounds. **The layer on top** is the
`dkj-policy` plugin, which carries its own page:

📄 **[`dkj-policy/CONTRIBUTING.md`](dkj-policy/CONTRIBUTING.md)**

**When the plugin is installed, that page applies on top of this one — and where the two disagree, the
plugin's page wins.** It does not replace anything below; it adds the workflow's own mechanics (the four
gates on the branch dossier, how those three exceptions actually run, the measurements behind them).

**That folder carries one page, and no root `CONTRIBUTING.md` layers under it any more** (Dave,
August 26 and 27, 2026, in the same instruction that moved `CHANGELOG.md` and the release history
there). Both moves, and what the second one cost — GitHub shows its *Contributing guidelines* link
only for a page in the root, `docs/` or `.github/` — are written out on the page itself, and the
reasoning per file sits at its own seam in
[`scripts/repo-config.ps1`](scripts/repo-config.ps1). The reason the layer exists at all is
unchanged: this file loads on **every** session, that page only when a session touches that folder.

The constitution above, concretely implemented here:

- **The main branch is `main`.** All changes via a `<prefix>/<short-name>` branch + PR to
  `main`. Valid prefixes ([`scripts/lib/branch-info.ps1`](scripts/lib/branch-info.ps1)):
  `feat/` → enhancement · `fix/` → bug · `docs/` → documentation. **Three, and `chore/` is refused**
  (Dave, August 7, 2026): chore is the name for work that lands *directly on the trunk* under one of the
  named exceptions, so a chore branch is a contradiction. `Chore` remains a recognised changelog **type**
  — every entry already written under it still has to validate — it just has no prefix any more. The rule
  had always held and was never enforced; measured on the day it was written down, `chore/` had been used
  12 times. See
  [the branch-taxonomy lens](.claude/specialists/lenses/05-05-extension.md#classifying-naming-and-creating-a-branch).
- **The lint and test gates are the safety guard before every PR.**
  [`scripts/lint/check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1) validates the
  manifests (`marketplace.json` + every `plugin.json`) and the agent-def and manual frontmatter,
  scans for dead links, and holds every **printed** `claude plugin install`/`update`/`uninstall` to
  its flags (`--scope project`, plus the marketplace refresh for install/update) — the class of doc
  defect three adoption rounds in a row kept producing; after that all test suites run
  (`scripts/tests/*.tests.ps1`), exactly as CI
  does. `open-pr.ps1` runs both gates first; on an error or a failing suite nothing is pushed and
  no PR is opened (`-SkipLint`/`-SkipTests` are the escape valves). See [the system-administration lens](.claude/specialists/lenses/05-15-extension.md).

  **Why these checks have the shape they do — and every rule that was measured and DECLINED — is in
  [the system-administration lens](.claude/specialists/lenses/05-15-extension.md#how-the-gate-checks-got-their-shape-and-the-measurements-behind-them-august-15-2026)**:
  the entry-format count and the four candidate rules behind it, the stale-path check declined at 124
  findings all false, the PR template measured over 60 PRs, and the two repairs it took to reach
  `CHANGELOG.md`'s intro. **Read it before changing any check above** — most of what looks arbitrary
  here was measured there. Moved off this always-on path on August 15, 2026, where it was 9,440 B over
  102 lines: 26% of this document, and the same shape as the release craft moved out the day before.

- **Five more gates arrive with the workflow plugin**, and all of them read the branch's own document.
  Four run locally: the **scaffold gate** refuses to push an entry still carrying the wording
  `new-branch.ps1` wrote it with, the **step-list gate** refuses to push *and* to merge while
  `dkj-policy/<branch>.md` has an unresolved step above its DEPLOY heading, the
  **backing gate** refuses to push when that plan reads as finished while nothing is committed on the
  branch behind it and the work sits uncommitted in the working copy, and the
  **DEPLOY lock** refuses to merge once that section no longer matches what the PR published — it is fixed
  at the moment the PR opens, because that is what the review approved and what the fold folds. The fifth
  runs in **CI** (`.github/workflows/branch-entry.yml` → `check-branch-entry.ps1`) and exists because the
  local four are escapable by not using the scripts; it re-uses three of their functions rather than
  restating the convention, and it reports the significance instead of refusing on it. **The backing gate is
  deliberately not among the three**: its subject is what sits uncommitted in a working copy, and a CI
  runner checks out a commit, so there the measurement always reads zero. Their mechanics, escape valves and
  the measurements behind them are in
  [`dkj-policy/CONTRIBUTING.md`](dkj-policy/CONTRIBUTING.md), under its PULL REQUEST step -- each gate
  sits at the point where it fires rather than in a list of its own.
- **And one guard fires *after* the merge, on the trunk.** The fold runs from `ship-pr.ps1` only, so a
  PR merged from the GitHub UI never folds it and the entry stays trapped in the development document on
  `main`, with nothing saying so ([#1270](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1270),
  the residual [#1244](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1244) left). Since
  September 3, 2026 `check-unfolded-entry.ps1` reports a per-branch `dkj-policy/<branch>.md` sitting
  on the trunk whose branch is not the one checked out — from a CI workflow on every `push` to `main`
  (merger-independent, **advisory**, not in `main-ci-gate`) and from a SessionStart hook in every
  consumer. It is Sylvester's; the reasoning is in
  [his lens](.claude/specialists/lenses/05-15-extension.md#what-sylvester-owns-here).
- **Three deliberate exceptions to "never directly on `main`", each one bounded.** Together they are
  one procedure read end to end — **fold the changelog, bump the version, write the release notes** —
  and that is why they are the three (Dave, August 23, 2026):
  1. The **fold commit** after a merge: [`fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1)
     folds the entry into `dkj-policy/CHANGELOG.md` and clears it, and with `-Commit`/`-Push`
     makes that commit itself. **Bounded to two paths** — that changelog and the branch's development
     document, which the same run **removes** — and the commit names them, so nothing else in the tree
     can ride along. Committing stays opt-in, because it is this exception being used.
     **The second path is named by its resolver, `Resolve-BranchFilePath`, rather than spelled out here.**
     That document has been renamed four times, and on the day of each rename every branch already open
     carried a name the bound did not list — which put its own fold outside the exception it runs under.
     So the bound is still exactly two paths and still checkable after the fact, because the commit prints
     the path it actually touched; it is simply no longer a spelling that goes stale under the tooling it
     governs. Today's writer is `dkj-policy/<branch>.md` — **one document per
     branch since September 3, 2026** (#1255), where it was the single `development.md`, and **named after
     the branch alone since later that same day** (#1335), where it was `development-<branch>.md`. That
     fixed path did not collide on checkout, which is what the old reasoning said, but it collided on
     *merge*: every merge to `main` left every other open PR conflicting on it, and a conflicting PR gets
     no check suite at all, so it could never go green and could never merge. The bound is unchanged and so
     is the reason it is named by its resolver rather than spelled out — two more renames landed in one day,
     and the resolver is what keeps a branch opened before either of them from folding outside the exception.
  2. The **release commit** (only on explicit request): [`cut-release.ps1`](scripts/release/cut-release.ps1)
     bumps all plugin versions in lockstep, generates the release notes in `dkj-policy/releases/`,
     **empties the changelog down to its intro**, commits that on `main`, and tags `vX.Y.Z`.
     Deliberately no branch/PR — just like the fold. **A major additionally needs two preparation
     commits ahead of it** (Dave, August 9, 2026), under this same exception and bounded just as
     narrowly: a **major** only, **two paths** only (the new `#### N.x` section in
     [`dkj-policy/releases/history.md`](dkj-policy/releases/history.md) and the assert in
     [`release-lib.tests.ps1`](scripts/tests/release-lib.tests.ps1) that pins which major it targets),
     and only once a cut has been **explicitly asked for**. Outside a cut, both files take the
     ordinary branch + PR route.
  3. The **release-notes commit** (Dave, August 23, 2026): the hand-written release documents — the
     audience note the cut drafted, and the internal note where a repo still runs the two-document
     flow — are committed straight onto `main` in the commit after the tag. **Bounded to the
     hand-written documents of a cut that was actually asked for**: the note under
     `Get-ReleaseNoteRoot` and `releases/internal/<dir>/<X.Y.Z>.md`, named in the commit, and nothing
     else. Outside a cut there is nothing for it to be part of, and a later edit to an
     already-published note is an ordinary change on the ordinary route. It reverses the
     August 4, 2026 answer, which sent those documents through a branch + PR.

  **An exception is only safe while it stays the size it was granted at**, which is why every bound
  above is stated here rather than left to the layer below. How the three actually run, the
  measurements behind each, and both halves of that August 4 reversal are in
  [`dkj-policy/CONTRIBUTING.md`](dkj-policy/CONTRIBUTING.md) -- the fold under its PULL
  REQUEST step, the release commit and the notes commit under CUT RELEASE --
  and in [the release lens](.claude/specialists/lenses/05-06-extension.md#versioning--releases).
- **This repo is `public`.** A deliberate choice, so the remote `github` marketplace source can be
  read without gh auth. Consequence: **nothing confidential** belongs here — no personal
  information, credentials, or secrets. The core team's (`team-alpha`) agent defs are therefore
  deliberately repo-neutral; repo-specific context lives in the consuming (private) repo's
  `.claude/specialists/lenses/` lens.

  **And a measurement taken in a *private* consumer quotes only what the finding needs — the matched
  fragment, never the surrounding sentence** (Dave, September 5, 2026, on
  [#1420](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1420)). The convention that a
  measurement cites its instance verbatim is not weakened by this and must not be: a citation is
  auditable and a paraphrase is not, and this tree has scar tissue from measurements rewritten until
  nothing in them was checkable. What is bounded is the *excerpt*. The **repo name, the file and the
  line** are published as before — they are already in `connectors/` and in the `dkj-policy-bwj` skill — and
  they are what carries the provenance, so the quote itself shrinks to the characters the check, the
  count or the argument actually turns on. Everything the finding does not read is the consumer's own
  wording and stays in the consumer's own tree.

  **The test is mechanical: could the finding be re-verified without this character?** In the
  supremacy-declaration case the check reads an adjacency — `` `CLAUDE.md` `` beside `wins`/`wint` —
  which is the check's own pattern rather than anybody's prose, so that clause is cited and the
  governance sentence around it is not. **A test fixture is held to the same bound and is not an
  exception**, because a matcher reads structure: a fixture needs the shape the finding turns on, and
  the consumer's remaining words are decoration that a public repository then keeps forever. The reason
  the bound is worth having at all is asymmetry — a public quote cannot be withdrawn, and the next
  measurement reaches for as long an excerpt as the last one was allowed.
- **Changes to shared agent defs land here first**, are committed here, and only then picked up by
  the consuming repos — never the other way around.
- **And because this repo *is* the source, the shared source is the default destination for a lesson
  learned here — not the lens** (Dave, August 4, 2026). The lens is for what a *consumer* would
  genuinely have to differ on; it is not the convenient place to write something down because it is the
  file already open. Writing a portable rule into the lens leaves the source thinner than the repo that
  maintains it, and nobody downstream ever receives it. **Which layer a rule belongs in, the split when
  a rule has both a portable and a local half, and the measurement behind that convention are in the
  [specialists handbook](.claude/specialists/README.md#where-a-new-rule-goes--the-source-is-the-default-the-lens-is-the-exception)**
  — including that personas and manuals carry no repo-specific detail at all while skills carry the
  evidence behind a procedure.

### The how (Dave's, across his repos) vs. the what (this repo only)

In short: the **how** (everything via branch + PR, lessons learned in the docs, the constitution
above any convenience) is Dave's and carries across the repos he runs, so it sits at the top. The
**what** (the marketplace/plugin structure, the language, the concrete `main` branch and fold
exception, the scripts, and the plugin lint gate) belongs to this repo alone and sits in this slot.

**Neither half is a universal baseline, and the top half least of all.** It names Dave as the
decision-maker throughout and reaches for mechanisms only this repo has — a `plugin.json` version
bump, the release overview's `#### N.x` section, the test pinning which major that overview targets.
What travels is the shape (a constitution, then a repo slot), not the content, so a repo adopting this
system writes its own owner into the top half rather than inheriting Dave.

**The word *portable* appears elsewhere in this file in the plugin sense — a persona body, a manual,
the portable half of a rule — and is correct there; do not sweep it.** Those files genuinely travel to
a consumer through a release, while this repo's constitution travels nowhere on its own. Why the word
had to be corrected in the three places above, and the miscount the repair itself introduced, are in
[Tessa's lens](.claude/specialists/lenses/06-16-extension.md#the-portable-word-and-the-count-that-came-with-it).

The one line below is the whole specialist surface of this file. Everything about the team — who they
are, what each covers, how they are routed to — sits behind it, so removing the plugin is removing one
import and one directory rather than untangling this document. It is deliberately the last thing here.

@.claude/specialists/SPECIALISTS.md
