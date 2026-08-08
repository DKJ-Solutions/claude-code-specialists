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
per plugin. The full story — the five plugins and how they differ, the split manual model, the
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
[`cut-release.ps1`](scripts/release/cut-release.ps1) needs no change. The five plugins are one system —
a shared core, domain groups, and one opt-in way-of-working pack — and a consumer running group 1
alongside group 3 needs matching versions. What was wrong was never the lockstep, but housing unrelated products in a single release
train, and that dissolved with the reorganisation rather than needing a fix. Decision by Dave,
August 3, 2026; the reader-facing statement is in
[`README.md`](README.md#one-product-one-repository).

**The repo consumes itself.** Via [`.claude/settings.json`](.claude/settings.json) this repo enables
its own `specialists` plugin (group 1), with the `github` marketplace source
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
[Tessa #16's portable manual](plugins/specialists/manuals/06-16-manual.md#what-tessa-covers)
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

The full repo layout (`.claude-plugin/`, `plugins/` incl. `agent-shared/`, `connectors/` at the root,
`scripts/`, `releases/`, `.claude/`, and the root docs + `.github/`) is described in
[README.md](README.md#repo-layout). Since August 3, 2026 the plugins sit **one** level down in
`plugins/<plugin>/` instead of two in `claude-code-plugins/claude-specialists/<plugin>/`: that second
level existed to hold several product families side by side, which the
[one-product rule](#specific-to-this-repo-claude-code-specialists) above retired. `connectors/` moved
**to the root** in the same movement, deliberately — it is the consumer register read by
`scripts/sync/`, not plugin payload, and must not travel along in the plugin cache. `agent-shared/`
stayed **inside** `plugins/` for the mirror-image reason: it *is* plugin source.

### claude-code-specialists's safety implementation

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

  **The entry format is described in about ten hand-maintained places, and the answer is a check rather
  than a clear-out** (Dave, August 7, 2026;
  [#508](https://github.com/DaveKJohn/claude-code-specialists/issues/508)). Two of those descriptions were
  measured stale during a sweep that was looking for exactly that, one of them consumer-facing. The
  alternative — deleting the shape from every document and pointing at
  [`branch/templates/`](branch/templates/) — was weighed and declined: the prose costs every reader on
  every read, while a check costs nothing per read. **What is checked is the section COUNT, not the
  section names**, and that was settled by measuring four candidate rules against the tree rather than by
  argument. A name-matching rule accuses **six** correct documents, because `What does this change do?`
  and `Type of change` are retired entry sections *and* live headings of the PR template — so it would
  have been born red behind an exemption list, the shape this repo was already bitten by. The count is a
  fact the scaffolder owns, both recorded drifts stated it, and holding it needs no exemptions at all.
- **A third gate, on the changelog entry itself: the scaffold gate** (August 3, 2026). `open-pr.ps1`
  refuses to push a branch whose entry still carries the wording `new-branch.ps1` scaffolded
  it with — the placeholder title, the "to do / where I left off" heading, or the fallback body.
  **Measured, after it had already shipped:** three of v3.2.0's twenty-one entries kept that heading
  with a status appended behind it, and it reached the release notes *and* the per-plugin
  `CHANGELOG.md` files that travel to consumers in the plugin cache. The window closes at the merge and
  closes **invisibly** — the fold moves the entry into `CHANGELOG.md`, the next release moves it on into
  `releases/`, so by then the place a reviewer would look is the one place it no longer is. Fenced code
  is excluded, so an entry documenting this mechanism is not accused of it; `-Force` is the escape
  valve, deliberately separate from `-SkipLint`/`-SkipTests` because it overrules a judgement about
  content rather than skipping a tool. The wording lives in **one** shared source
  ([`entry-scaffold-lib.ps1`](scripts/lib/entry-scaffold-lib.ps1)) read by both the script that writes
  it and the gate that refuses it — a copy in each would make the gate silently miss whatever the
  writer changed.

  **Two of those three strings are now recognised without being written** (August 6, 2026). The
  `branch/` split moved the step list into its own file, so the entry is no longer scaffolded with a
  to-do heading over a to-do placeholder — its placeholder asks what the change *does*. The gate keeps
  refusing the retired wording, and that is not politeness towards history: every branch in flight,
  here and in every consumer, carries an entry with those strings right now, and consumers receive the
  new scripts through a plugin update rather than by choosing to. A gate that forgot them would wave
  exactly those entries through. **Recognise both, write one** — the same rule the `Tier: N` line gets.
- **A fourth gate, on the branch's own plan: the step-list gate** (Dave, August 6, 2026). A branch
  reaches a PR when its own plan is finished, so `open-pr.ps1` refuses to push and `ship-pr.ps1` refuses
  to merge while `branch/branch-progress.md` has an unresolved step. **Both**, deliberately: the
  requirement Dave gave is about the *merge*, and `open-pr` has a `-Force` — a PR opened through that
  valve, or by hand on github.com, would otherwise land with an unfinished plan.
  **Three marks, not two.** `- [x]` is done, `- [~]` is dropped with the reason kept on the line, and a
  step still carrying the scaffold's placeholder is refused whether or not it is ticked. The third mark
  is what makes the gate safe to leave **un-`-Force`-able**: without it the only way past a step that
  turned out not to be needed is to tick it, which teaches people to report work they did not do — a
  gate that then says success is worse than no gate. **A branch with no step list at all is not
  refused**: that is the one-commit typo fix, and refusing it would make the mechanism ceremony. The
  full convention lives in [`branch/README.md`](branch/README.md).
- **Two deliberate exceptions to "never directly on `main`":**
  1. The **fold commit** after a merge: [`fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1)
     folds the entry into `CHANGELOG.md` and clears it, and with `-Commit`/`-Push` makes that
     commit itself — scope limited to `CHANGELOG.md` + the entry + `branch/branch-progress.md`, which
     the same run resets, and since August 2, 2026
     enforced rather than merely intended: the commit names its paths, so nothing else in the tree
     can ride along. **The scope grew by one path on August 6, 2026 and the exception did not widen
     with it**: the step list is reset by this run, so leaving it out would produce a commit that
     resets half the pair — the entry empty on `main` while the step list still shows the merged
     branch's ticked boxes. Committing stays opt-in, because it is this exception being used.
     See [Rendall #06](.claude/specialists/lenses/05-06-extension.md#changelog).
  2. The **release commit** (only on explicit request): [`cut-release.ps1`](scripts/release/cut-release.ps1)
     bumps all plugin versions in lockstep, generates the release notes in `releases/development/`,
     **empties `CHANGELOG.md` down to its intro**, commits that on `main`, and tags `vX.Y.Z`.
     Deliberately no branch/PR — just like the fold. See
     [Rendall #06](.claude/specialists/lenses/05-06-extension.md#versioning--releases).

     **It also used to write a per-plugin `CHANGELOG.md` and a consumer-facing `RELEASE.md` card into
     every plugin folder; both were retired on August 8, 2026 (Dave).** The repo has become the product,
     so there is one changelog. And measured before removing them: a consumer receives the marketplace
     source as a git clone of the **whole repository**, so `CHANGELOG.md` and `releases/` were always in
     their reach — those ten files were a second copy, 11,684 lines, free to disagree with the original.
     Lint checks 9 and 17 existed to police exactly that disagreement and went with them. A plugin's
     version now has one statement: `plugin.json`.

     **Why no PR, in Dave's own words (August 7, 2026): "aan het product zelf verandert verder niks."**
     A release republishes what is already merged — it bumps versions, generates documents and moves a
     tag. There is no change to review, so a PR would add a checkpoint over a diff nobody has to judge.
     Weighed against the alternative the same day rather than assumed: routing it through a PR would need
     a `release/` prefix that the table deliberately excludes, would conflict on `CHANGELOG.md` with every
     branch that folds while the release PR is open (the cut empties that file), and would meet two gates
     — the scaffold gate and the step-list gate — that a release branch cannot satisfy by construction,
     since its changelog is empty by design.

     **What the PR route WOULD have bought is real, and is being closed another way.** Measured on
     August 7, 2026: `open-pr` runs the lint *and* all 26 suites, and CI runs both again — while
     `cut-release` runs the lint alone and its push to `main` bypasses the required check. The release
     commit is therefore the least-gated commit in the workflow, and it is the one that empties the
     changelog and bumps every plugin. The repair is coverage, not route: the cut runs the
     suites too, and CI runs on `main` pushes so the artefacts the cut itself generates are checked after
     they land.
     Since August 3, 2026 it is a **shared** script, mirrored into the plugin like the rest of the
     workflow ([#417](https://github.com/DaveKJohn/claude-code-specialists/issues/417)): everything
     that legitimately differs per repo — which root docs are permanent, how the notes are foldered,
     whether there is a plugin tier at all, for which bumps a
     stakeholder-facing **highlights** document is generated, and how many minors a major must recap — is
     read from optional functions in [`scripts/repo-config.ps1`](scripts/repo-config.ps1), each falling
     back to what this repo already did.

     **A cut writes no release block, and that is deliberate** (Dave, August 5, 2026). It used to append a
     `## Latest Release` block naming the version, the date, the type and a pointer to the notes. Measured
     before removing it: that accumulating section had grown to **434 of the changelog's 1,062 lines**
     across 72 blocks that each said no more than "see the notes", while
     [`releases/README.md`](releases/README.md) already listed every one of those 72 versions with a date,
     a type and a descriptive title — the same coverage, verified in both directions, and richer per row.
     So the intro carries a one-line pointer to that page and the cut leaves the document at its intro.
     One consequence worth knowing: the internal note's only inbound link is now the **Version cell** of
     that page's history row, written by `new-internal-note.ps1` rather than by the cut — see
     `Set-ReleaseInternalNoteLink` for why it cannot be the cut's job. **The exception it runs under did not widen**: same scope, same
     "only on explicit request", and the release artefacts it produces here were verified
     byte-identical to the unshared script's, both when the script was shared and again when the
     highlights tier joined it.

     **The document is one change per `##` heading, with no section headings at all** (Dave, August 5,
     2026). `CHANGELOG.md` is an intro followed by a **flat ranked list**: a change *is* the `##`. The three
     `## Tier N - Pull Requests` sections it replaced said exactly one thing — how far each change reaches —
     and the entries now say that themselves, in a form that also carries what the change is worth.
     **What the sections communicated visually is kept as the ordering**: furthest reach first, and within a
     tier the highest significance first.

     **And since August 6, 2026 the entry is the branch's own dossier, folded in as it stands.** The heading
     names the **branch** — `` ## `feat/x` changelog `` — and six `###` sections answer, in order:
     `Branch title` (the human-readable name of the change, which the heading used to carry),
     `Branch ID` (a timestamp stamped at creation), `Branch type` (the prefix, lowercase),
     `What does the change on this branch bring to main?`, `Significance` (one `#### Tier N` sub-section per
     reach the change claims, each closing with `**Score:**`) and `Pull Request`, which the **fold** fills
     from the merge itself. `Plugins:` stays a plain line, because a heading around one fact is more
     structure than content.

     **That first section is called `Branch title`, and it IS the PR title** (Dave, August 7, 2026;
     [#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506) +
     [#505](https://github.com/DaveKJohn/claude-code-specialists/issues/505)). `open-pr.ps1` composes
     `<branch type>: <this section>` instead of taking a title on the command line, so the sentence is typed
     once — at `new-branch -Title` — and the PR, `CHANGELOG.md` and the release documents cannot disagree
     about what the change is called. It also closes a rule that had lived in a document and was never
     measured: Derek's manual has always said the PR title mirrors the branch type, and the five PRs before
     this change all merged without one. `-Title` is accepted and ignored rather than removed, because every
     branch in flight — here and in every consumer — passes one right now. The section was named
     `Branch description` for one day and is **still read** under that name, for the standing reason.

     **Dave chose that `CHANGELOG.md` receives this shape verbatim**, asked and answered before any of it was
     built. The alternative he was offered — a fold that reads the dossier and derives a slimmer entry from
     it — was declined, and the reason is one this repo has already paid for three times: a fold that rewrote
     the entry would put a **second definition of the entry format** inside the fold, free to drift from the
     one the scaffolder writes. One shape, written once, read everywhere.

     **The form writes no visible placeholder at all.** Every field is a heading with an HTML guidance
     comment above the space where the answer goes; the fold strips those comments, so leaving one standing
     is not a defect and there is nothing to tidy before the PR. What replaced the `TODO:` strings as the
     gate is a **measurement**: `open-pr` refuses an entry whose description, body or any tier's reason is
     still empty once the comments are stripped — strictly more than the strings caught, since it also
     catches a placeholder that was deleted rather than answered. The retired strings are still refused, for
     the standing reason: every branch in flight, here and in every consumer, carries one right now.

     **The tier model** (Dave, August 5, 2026). Every change declares **how far it reaches**, and that one
     number decides which release document it appears in:

     | tier | who notices | release document | when |
     |---|---|---|---|
     | **2** | consumers | `releases/highlights/<X>.x/<X.Y.Z>.md` | minor/major |
     | **1** | colleagues on this project | `releases/internal/<X>.x/<X.Y.Z>.md` | every release, patch included |
     | **0** | only this repo's developers | `releases/development/<X>.x/<X.Y.Z>.md` | every release |

     The grouping is per **major** (`3.x`) for all three, deliberately differing from the consumer this
     model came from, which folders per minor. `Get-ReleaseNotesGrouping` answers that once.

     **The release documents follow the same flat shape**, and that deletion is part of the decision rather
     than a tidy-up alongside it: the category grouping (`## Features`, `## Fixes`, …) is gone, together with
     `Format-CategorizedEntries`, the category labels and the `Get-ReleaseCategoryTitles` seam. It grouped on
     the **branch prefix**, which this repo has measured does not predict impact, so a document's most
     consequential change was filed third under whichever label its prefix produced — and the ranking could
     only reorder the categories, not escape them. Each change states its own type inside itself now, so
     nothing is lost by not grouping on it.

     **The ladder is cumulative**, so a tier-2 entry is in the highlights *and* in the internal note; the
     development note carries everything, tier 0 included, because it is the record rather than a summary.
     **The number comes from the author of the entry, on the branch** — and deliberately **not** from the
     branch prefix, which this repo has measured does not predict impact.

     **The second axis: significance, and the order follows it** (Dave, August 5, 2026;
     [#467](https://github.com/DaveKJohn/claude-code-specialists/issues/467)). The tier says how far a change
     **reaches**, and therefore which document it appears in. A significance score says how much it
     **weighs** for that document's reader, and therefore **where in it** the entry sits — so the most
     consequential change leads instead of sitting third under whichever heading its branch prefix produced.
     Both are declared under **`### Significance`**, one `#### Tier N` sub-section per reach the model has,
     each carrying why it matters there and then its score:

     ```text
     #### Tier 0

     The routine version bump stops needing a developer.

     **Score:** 4

     #### Tier 1

     Nobody but this repo's own developers can observe it.

     **Score:** N/A
     ```

     **The score label is bold** (Dave, August 6, 2026). `Score:` sat as bare prose in a section that is
     otherwise all prose, so it did not read as the field it is. The plain form is still **read**, because
     `CHANGELOG.md` and every consumer's tree are full of entries carrying it.

     **All three tiers are always present, and `N/A` is how one says it reaches nobody** (Dave, August 7,
     2026). Tier 1 and tier 2 used to be commented out, and uncommenting one *was* the claim — so an
     unreached tier and an unfinished one looked identical, and no gate could tell "this reaches no
     consumer" from "nobody got to tier 2 yet". Each tier is answered now: a score, or `N/A` with a line
     saying why. **The reach is the highest tier carrying a number**, so an `N/A` costs a sentence and
     nothing else — and the reasoning behind a *negative* claim survives into the record, which the
     absence model threw away. A `Yes/No` field was drafted alongside the score the same day and dropped:
     a score and a yes are one fact, free to contradict each other.

     **The scaffolded working files carry no comments at all** (Dave, August 7, 2026). Guidance is written
     only into `branch/templates/`, which is what those copies are for; the file a branch gets is the
     headings and the space under them. The routing questions went with the guidance — the trade being
     that the ladder is now learned from the template and this document rather than from the file in front
     of you. The fold keeps its comment stripper regardless: every branch in flight carries comments, and
     they reach the new scripts through a plugin update rather than by choosing to.

     **SUB-SECTIONS RATHER THAN A TABLE** (Dave, August 6, 2026), which replaced the impact table that had
     itself replaced the `Tier: N` line the day before. The table forced a rectangle onto something that is
     not always rectangular: **not every change has a tier 1 or a tier 2**, and a missing row reads as an
     omission while a missing section reads as a decision. The heading also stopped naming an audience —
     it was `Who is this for` — because each sub-section names its own by its number, and what the section
     carries is how much the change *weighs* for each of them.

     **Each section closes by asking whether there is a next one**, and that question is written even where
     the next tier is already there. An author who has answered does not need it; a reader at the fold, at
     the cut and in the record does — a question that disappears once answered leaves them unable to see
     that it was asked. Tier 2 has no successor and carries none.

     **The ladder stays cumulative and is still impossible to claim halfway.** A change consumers notice
     *is* a change colleagues get something out of, so a tier-2 entry owes a tier-1 section — the sections
     an entry has are the documents it appears in, and each is that document's reader answering their own
     question. The score is scaffolded **empty**, unlike the tier: 0 is a harmless final answer about
     reach, while any scaffolded *score* would be a guess at a ranking, and this repo has measured what a
     guessed ranking costs (the retired highlights marker, below).

     **Three shapes are read and one is written.** The sub-sections, the table, and the older `Tier: N`
     line — because `CHANGELOG.md` holds all three right now and every consumer's tree holds at least one.
     The retired section heading is recognised too (`Get-EntryRetiredSectionHeadings`): without that, the
     lint reported all 24 pending entries as *misspelled* headings the moment the name changed, which is
     how a check gets switched off rather than heeded.

     **1 to 5 against a written rubric** (`Get-EntrySignificanceRubric`, overridable per repo), because an
     unanchored ordinal scale invites false precision — 5 is *the reader must act*, 1 is *cosmetic, or names
     the failure it prevents*. That is what makes the number a measurement rather than a mood, and it is also
     why the score is comparable **across** releases. Dave reversed his own earlier "no anchors" answer the same day,
     and the reversal is the reasoning: without anchors there is nothing to drift, but also nothing to check.
     The **`Why` is required** and is the lasting half — the rubric says which band, the `Why` says why *this*
     change is in it.

     **Band 1 asks what is prevented, and that is the repair of a band that invited its own abuse** (Dave,
     August 7, 2026; [#509](https://github.com/DaveKJohn/claude-code-specialists/issues/509)). It used to read
     *"cosmetic or preventative — nothing changes for them today"*, and the second half is exactly the sentence
     the rubric exists to stop: [PR #503](https://github.com/DaveKJohn/claude-code-specialists/pull/503)'s entry
     scored its tier 0 with "Nothing changes here" — inside the band, and useless to a reader a year later.
     Four of the five bands describe something the reader can observe; this one describes an **absence**, and
     an absence has to be named or it cannot be told apart from having nothing to say.

     **The tiers are not nested audiences, so tier 0 may legitimately score below tier 1.** Dave asked whether
     that should be refused — if nothing changes for this repo's own developers, how can it change for anyone
     further out? PR #503 is the counterexample: the defect existed **only outside this repo** (consumers had
     no `branch/templates/`; this repo always did), so it was worth 4 to a consumer and almost nothing here. A
     consumer is not a colleague of this project. That gate would have refused a correct entry, and the
     instinct behind it is already encoded one level down and correctly: **tier 0 is the one tier that cannot
     be `N/A`**, because every change reaches this repo's own developers at least a little. The floor is a
     score of 1 — and band 1 now asks what that 1 buys.

     **Who reads it where.** The fold places the entry at its ranked position in `CHANGELOG.md`, and that is
     the *only* moment it can: the cut **empties the list**, so whatever order the fold leaves is
     what the release documents inherit — reproducible across two moments days apart with nothing
     re-estimated. Insert-only, never a re-sort: the fold commit lands directly on `main`, so a bug there
     must be able to misplace at most the one entry being folded rather than scramble a list it did not write. The **highlights** re-read the tier-2 row (its reader is the consumer); the **internal
     note** reads the tier-1 row. **Tier 0 is never ranked** — the development note is the record: complete
     and chronological. The table **survives into the record** because that is the last place each ranking's
     justification lives, and is **stripped from everything that travels outward** (the highlights),
     because a self-assigned number printed at a consumer is a marketing claim. It used to be stripped
     from the per-plugin `CHANGELOG.md` and `RELEASE.md` too; those were retired on August 8, 2026, so
     the highlights are the only outward document left to strip. `cut-release.ps1` refuses a release whose tier-1-or-higher entries have not scored themselves;
     `-SkipSignificanceGate` overrules it, separate from `-SkipTierGate` because one overrules whether the
     release should exist and the other how its contents are ordered.

     **`Tier: N` is still read, and always will be** — "recognise both, write one". Every entry already in
     `CHANGELOG.md` and in every consumer's tree predates the table, and a parser that only knew the new
     shape would read all of them as tier 0: silent, correct-looking, and wrong in the direction that empties
     a release.

     **The name was `Happiness` for one afternoon.** Dave rejected it as unprofessional, and he was right
     about more than the word: *happiness* names an emotion in the reader, which an entry's author is in no
     position to assert, while the weight of a change for an audience is something they can judge. Worth
     recording alongside it, because it is the first thing anyone reaches for: **RICE and WSJF do not apply
     here.** They price work *before* it is done, with effort in the denominator — they answer "what do we
     build next". Everything scored here is already merged, so effort is spent and irrelevant. Reach ×
     significance is the decomposition incident practice makes when it derives a priority from impact and
     urgency rather than asking for one number.

     **And a release now has to earn its bump.** `cut-release.ps1` refuses one that the pending entries do
     not justify, before it writes anything:

     - **the bump follows the highest tier pending** (Dave, August 7, 2026): **tier 0 only → patch**,
       **tier 1 or higher → minor**. A release made entirely of repo-internal work used to be refused
       outright, on the grounds that it "has nobody to announce it to" — the answer is that announcing
       nothing is exactly what a patch is for. And a minor used to demand a **tier-2** entry, so tier-1
       work earned only a patch;
     - **the audience of each note follows the TIER, not the bump**, and that is what keeps the looser
       rule honest. A tier-1-only minor writes the internal note and **no highlights**, so nobody outside
       is handed a document about work they cannot see. `cut-release.ps1` keys the highlights on a tier-2
       entry being present rather than on the bump type — a condition that was belt-and-braces while a
       minor required tier 2, and is now the whole mechanism;
     - a **major** needs **10 minors** in the current major line, on top of that minimum. A major is a
       *recap* — which is what both of this repo's majors already were — so what earns it is the
       accumulation, not any single pending change. `Get-ReleaseMajorMinMinors` owns the number.

     `-SkipTierGate` overrules it, deliberately separate from `-SkipLint`: that one skips a tool, this one
     overrules a judgement about content. **The gate switches itself off where no pending entry declared its
     impact at all**, so a consumer that has not adopted the model is untouched. That test used to be "does
     this repo declare more than one changelog section", which had a real basis while the sections existed
     and became a landmine the moment they went: a flat document gives an unadopted repo and an adopting one
     one group each, so the old line would have read every repo as not adopting and switched the gate off in
     silence, in the same change that made the tier the model's primary fact. Nothing would have errored.
     Counting **declarations** is a measurement rather than a flag, and it keeps "declared tier 0" distinct
     from "declared nothing" — which is the whole difference between a release that has nobody to announce
     itself to and a repo that never chose the model.

     **And that same ladder is why the internal document exists at every release.** Tier 2 and tier 1 are
     not the same question: highlights is *what a consumer notices*, internal is *what the organisation
     gets out of it*. They come apart most clearly on a patch — a release with nothing for a consumer can
     still be the one where a routine change stopped needing a developer.

     **Who writes what.** `cut-release.ps1` generates the development notes and the highlights **draft**,
     then names the two documents it deliberately did not write. The internal note has its own script
     ([`new-internal-note.ps1`](scripts/release/new-internal-note.ps1)), which needs the development
     notes as input and so can only run *after* the cut. Both the highlights edit and the internal note
     are hand-written and land **via a branch + PR** — the release commit is already tagged by then, and
     neither is one of the two named direct-on-`main` exceptions. **Confirmed by Dave, August 4, 2026**,
     over the alternative he was offered: widening the release exception to cover "the release *and*
     its written notes". He declined it, and the reasoning is the one that already applies elsewhere in
     this section — an exception is only safe while it stays the size it was granted at, which is what
     had to be repaired in `ship-pr.ps1` on August 2, 2026. The route also has a measured instance
     behind it now rather than only an argument:
     [PR #432](https://github.com/DaveKJohn/claude-code-specialists/pull/432) shipped `v3.2.0`'s internal
     note this way, gates green and entry folded, with nothing about being post-tag causing friction.
     Recorded because until that date this was an **assumption** stated as a rule: the question had been
     put twice without an answer, and the answer-shaped text went into the docs anyway.

     **The measurement the whole tier model rests on: the branch prefix does not predict impact in this
     repo.** Until August 5, 2026 the highlights document put `Feat`/`Fix` above a "remove before
     publishing" marker and everything else below it, explicitly as a *proposal* rather than a verdict.
     Measured against the 19 entries pending at v3.2.0, the single most consequential change for a consumer
     — renaming the marketplace, which breaks every existing install — arrived on a `chore/` branch and
     therefore landed below the marker. The tier asks the entry's author instead, so the marker and its two
     seam knobs are retired; a `docs/` branch carrying a tier-2 change now says so, and the prefix decides
     nothing but which category heading the entry is grouped under.
- **This repo is `public`.** A deliberate choice, so the remote `github` marketplace source can be
  read without gh auth. Consequence: **nothing confidential** belongs here — no personal
  information, credentials, or secrets. The group 1 agent defs are therefore deliberately
  repo-neutral; repo-specific context lives in the consuming (private) repo's
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
