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
  [`workflow-davekjohn/branch/templates/`](workflow-davekjohn/branch/templates/) — was weighed and declined: the prose costs every reader on
  every read, while a check costs nothing per read. **What is checked is the section COUNT, not the
  section names**, and that was settled by measuring four candidate rules against the tree rather than by
  argument. A name-matching rule produced **six** findings on the tree, **all six false**: `What does this
  change do?` and `Type of change` are retired entry sections *and*, at the time of that measurement, were
  live headings of the PR template, so it accused **two** correct documents of being stale for describing
  that template accurately — and would have been born red behind an exemption list, the shape this repo was
  already bitten by. The count is a fact the scaffolder owns, both recorded drifts stated it, and holding it
  needs no exemptions at all.

  **That collision is gone since August 9, 2026, and the conclusion does not move with it**
  ([#538](https://github.com/DaveKJohn/claude-code-specialists/issues/538)). Both headings were removed from
  the PR template, so the six false findings can no longer be reproduced from the tree. The measurement is
  kept in the past tense rather than deleted, because a superseded measurement is worth something only while
  it says *when* it was taken. Two reasons the count still wins: name-matching also lost on its narrowed
  variant (3 findings, 2 false, against 4 claims with 3 correct), and a rule keyed on names is one rename
  away from going silent — which is exactly what just happened to this collision, and would as easily happen
  to a match the check depended on.

  **A check on stale PATH references in prose was measured and declined** (August 9, 2026), and the reason
  generalises past this one rule, which is why it is recorded rather than forgotten. The proposal came out of
  a README sweep that found a title naming `specialists/scripts/`, a directory the plugin reorganisation had
  removed — a defect no gate sees, since check 4 reads markdown **links** and this was a path in inline code.
  The obvious rule is "a path in backticks must resolve against the tree". Five candidates were measured over
  120 documents (history excluded as in checks 11 and 12), each with the most generous resolver a checker
  could honestly use — repo root, the document's own directory, and every ancestor between:
  requiring a separator **and** an extension gave **124** findings, a separator alone **349**, an extension
  alone **621**, either **736**. **Not one of the 124 was a true finding**, and the narrowest rule does not
  even reach the measured defect — `specialists/scripts/` carries no extension — so catching the one real
  instance means adopting a rule born with 349.

  **The reason is structural, and it is about what this repo is.** Being a plugin source, most paths it
  names correctly describe *somebody else's* repo: `.claude/extensions/…` is the legacy lens location this
  family deliberately still documents for unmigrated consumers, `config/settings_data.json` is a Shopify
  store's file named in `team-shopify`'s manual, `PRETTY/[Emotie]/README.md` is a life-hub folder. All three
  answer "no such file here", exactly as the stale title does — and **the difference is whose repo the line
  is about, which the line never says**. An existence check reads "describes a consumer" as "stale", and no
  regex recovers that distinction. Do not revive it behind an exemption list: that is the shape this repo has
  already been bitten by, and the list would need to hold the entire consumer-facing vocabulary.

  **What survived, unbuilt and deliberately so:** a title claiming a path must name its own location. It
  sidesteps the anchor question entirely, because a document knows where it sits — 4 subjects tree-wide,
  0 findings today, and verified against `33a41a2` to fire on the real defect. Not built, because four
  subjects is close to nothing to guard; worth revisiting when per-directory READMEs multiply.

  **The PR template that caused the collision is itself the change** (Dave, August 9, 2026). It now carries
  one section — the changelog entry — because `open-pr.ps1` composes the body from
  `workflow-davekjohn/branch/branch-changelog.md`, so everything else it asked was already answered four lines lower. Measured
  over 60 PRs before removing anything: `Type of change` had exactly **one of four** boxes ticked every
  single time, a fact the entry states under `### Branch type` and which the GitHub label takes from
  `Get-BranchInfo` rather than from the tick; of the checklist, `Requested by Dave` and
  `Changelog entry written` were ticked **60/60** — both by the script itself — while the two items the
  docstring called "human judgement checks" were ticked **0/60**, by anyone, ever, though both were already
  enforced by gates that block the PR. A box that is always ticked and a box that is never ticked carry the
  same information. The template also still offered a `chore/` row, four days after
  `Test-BranchName` began refusing that prefix outright — the one line in the form that could actively
  mislead. **`open-pr.ps1` keeps filling all of it in**: a consumer's PR template is their file, every one of
  them still has those sections, and they receive the script through a plugin update rather than by choosing
  to. Recognise both, write one.

  **What travels from that decision is the MEASUREMENT, not the two-line answer** (August 10, 2026;
  [#573](https://github.com/DaveKJohn/claude-code-specialists/issues/573)). The rule is *"keep what is
  neither restated by the entry nor proven by a gate"*, and in this repo nothing survived it — which is a
  fact about this repo, not about the form. The consumer who reported that issue re-ran the same
  measurement over their own 60 PRs and found **one box of eight that genuinely varied**: a preview-URL
  approval, on a repo whose result has to be judged by eye and which no gate can prove. They kept it and
  dropped the other seven, and that is #538 applied rather than #538 ignored. So the portable half — the
  `open-pr` skill and the reference template the plugin now ships — states *why* the default is two lines
  and asks the next repo to run the measurement, instead of shipping "the portable template has no
  checkboxes" as a conclusion. Their same pass confirmed the failure this repo predicted when it removed
  the prefix checklist: **5 of their 60 PRs ticked two rows and 2 ticked none**, while the label came from
  `Get-BranchInfo` in all 60.

  **The template's shape is shipped, and the placeholder list moved so a gate could reach it** (same
  issue). `.github/pull_request_template.md` cannot live in the plugin — GitHub reads it only from that
  path in the consumer's own repo — so what ships is a reference to copy and diff against, at
  `plugins/workflows/workflow-davekjohn/templates/pull_request_template.md`, held byte for byte to
  `Get-PrTemplateReference`. The three recognised placeholder strings were three literals inside
  `open-pr.ps1`, which meant **nothing outside that script could read them**: the reference could not be
  held against the list that has to recognise it, and that gap is the defect the issue reported. They now
  live in `pr-body-lib.ps1`, and lint check 24 holds both files — the shipped reference byte for byte,
  this repo's own template only to the contract (a first heading, a recognised placeholder), because that
  one is genuinely repo-owned and a byte rule would refuse a correct change the day it grows a section.

  **The gate reaches `CHANGELOG.md`'s intro, and getting it there took two independent repairs** (August 8,
  2026; [#525](https://github.com/DaveKJohn/claude-code-specialists/pull/525)). The check was born
  excluding that file whole, on the history grounds it shares with checks 11 and 12 — but only the entries
  below the intro are history. The intro is a live statement about the present mechanism that every cut
  copies through **verbatim**, so it is the one piece of prose here that no release rewrites and no reviewer
  opens; measured on the day it was repaired, it had promised *three* named sections for two days, with one
  release and a consumer-facing release page in between. **Repairing either half alone changes nothing**:
  the file was unread, *and* the pattern would have walked past the sentence anyway, because it carried no
  `###` marker and ran across a line break. So the intro gets its **own pass with the level marker
  optional**, and matching runs over the whole text instead of per line. Both relaxations were chosen by
  measuring: whole-text matching finds the same **4** claims in the scanned tree as per-line, while dropping
  the marker tree-wide would find **50** — which is why it is dropped only across the dozen lines of the
  intro, where it was the whole difference between catching the drift and not.
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
  to merge while `workflow-davekjohn/branch/branch-progress.md` has an unresolved step. **Both**, deliberately: the
  requirement Dave gave is about the *merge*, and `open-pr` has a `-Force` — a PR opened through that
  valve, or by hand on github.com, would otherwise land with an unfinished plan.
  **Three marks, not two.** `- [x]` is done, `- [~]` is dropped with the reason kept on the line, and a
  step still carrying the scaffold's placeholder is refused whether or not it is ticked. The third mark
  is what makes the gate safe to leave **un-`-Force`-able**: without it the only way past a step that
  turned out not to be needed is to tick it, which teaches people to report work they did not do — a
  gate that then says success is worse than no gate. **A branch with no step list at all is not
  refused**: that is the one-commit typo fix, and refusing it would make the mechanism ceremony. The
  full convention ships with the plugin as
  [`BRANCH-portable.md`](plugins/workflows/workflow-davekjohn/BRANCH-portable.md); this repo's own
  answers to it stay in [`workflow-davekjohn/branch/README.md`](workflow-davekjohn/branch/README.md). Since
  August 14, 2026 (Dave) the directory itself sits inside `workflow-davekjohn/`, the workflow's own root
  folder — the start of gathering everything portable in one place at a consumer instead of scattering it
  through their root.
- **Two deliberate exceptions to "never directly on `main`":**
  1. The **fold commit** after a merge: [`fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1)
     folds the entry into `CHANGELOG.md` and clears it, and with `-Commit`/`-Push` makes that
     commit itself — scope limited to `CHANGELOG.md` + the entry + `workflow-davekjohn/branch/branch-progress.md`, which
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

     **A MAJOR NEEDS TWO COMMITS AHEAD OF IT, AND THEY RUN UNDER THIS SAME EXCEPTION** (Dave,
     August 9, 2026). `cut-release.ps1` refuses to file a `v4.0.0` row under `#### 3.x` and does not
     open the new section itself, and the live assert in
     [`release-lib.tests.ps1`](scripts/tests/release-lib.tests.ps1) pins which major
     [`releases/README.md`](releases/README.md) targets — so cutting `v4.0.0` took `b2cea9c` (the
     `#### 4.x` heading plus its empty table header) and `1d2d3ff` (that pin, `'3'` → `'4'`, with the
     reason written above it) before the cut would run at all. Both were made by hand, on `main`,
     while the exception on paper covered only the release commit itself.

     **The bound is what makes it safe, and it is deliberately narrow**: a **major** only, those
     **two paths** only, and only once the cut has been **explicitly asked for**. An exception is only
     safe while it stays the size it was granted at — the lesson `ship-pr.ps1` cost on August 2, 2026 —
     and this one is granted for the preparation of a requested cut, not for editing the overview or
     the test whenever it is convenient. Outside a cut, both files take the ordinary branch + PR route.

     **Neither half is automated, and that is the decision rather than a gap.** Opening the section by
     hand is the milestone moment the script deliberately leaves to a person; the assert is the same
     fact written a second time on purpose, so a script that repointed it would remove the tripwire
     that caught the half-done edit here. What *was* repaired is the advice: the refusal now names both
     edits, because naming only the section is what made the second commit a surprise. **A major is not
     rare here** — `v1.0.0` through `v4.0.0` fell on July 14, July 23, July 30 and August 9, 2026, one
     every nine days or so — so this comes round again soon enough to be worth writing down.

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
     August 7, 2026: `open-pr` runs the lint *and* every test suite, and CI runs both again — while
     `cut-release` runs the lint alone and its push to `main` bypasses the required check. The release
     commit is therefore the least-gated commit in the workflow, and it is the one that empties the
     changelog and bumps every plugin. The repair is coverage, not route: the cut runs the
     suites too, and CI runs on `main` pushes so the artefacts the cut itself generates are checked after
     they land.
     Since August 3, 2026 it is a **shared** script, mirrored into the plugin like the rest of the
     workflow ([#417](https://github.com/DaveKJohn/claude-code-specialists/issues/417)): everything
     that legitimately differs per repo — which root docs are permanent, how the notes are foldered,
     whether there is a plugin tier at all, for which bumps a
     stakeholder-facing **consumer** document is generated, and how many minors a major must recap — is
     read from optional functions in [`scripts/repo-config.ps1`](scripts/repo-config.ps1), each falling
     back to what this repo already did.

     **A cut writes no release block, and that is deliberate** (Dave, August 5, 2026). It used to append a
     `## Latest Release` block naming the version, the date, the type and a pointer to the notes. Measured
     before removing it: that accumulating section had grown to **434 of the changelog's 1,062 lines**
     across 72 blocks that each said no more than "see the notes", while
     [`releases/README.md`](releases/README.md) already listed every one of those 72 versions with a date,
     a type and a descriptive title — the same coverage, verified in both directions, and richer per row.
     So the intro carries a one-line pointer to that page and the cut leaves the document at its intro.
     One consequence worth knowing: the hand-written note's only inbound link is the **Version cell** of
     that page's history row — and **the cut writes it itself, on the first write** (August 10, 2026). This
     paragraph said the opposite until August 11, naming `new-internal-note.ps1` as the writer and
     `Set-ReleaseInternalNoteLink` as the reason it *could not* be the cut's job. That reason was real and it
     expired: it could not be the cut's job while the note did not exist during the cut, and since the two
     hand-written documents merged the cut **drafts** the note, so there is a real file to point at by the
     time the row is written. `Set-ReleaseInternalNoteLink` still exists and is still called by
     `new-internal-note.ps1`, for a repo running the two-document flow — recognise both, write one.
     **Measured rather than assumed**: `v4.4.0`'s row pointed at `notes/4.x/4.4.0.md` on the first write,
     with nothing repointing it afterwards. **The exception it runs under did not widen**: same scope, same
     "only on explicit request", and the release artefacts it produces here were verified
     byte-identical to the unshared script's, both when the script was shared and again when the
     consumer tier joined it.

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

     | tier | who notices | where it is written | when |
     |---|---|---|---|
     | **2** | subscribers of the service | the *For consumers* section of `releases/audience/<X>.x/<X.Y.Z>.md` | minor/major |
     | **1** | management and the employer/commissioner | the organisation's two sections of that same file | minor/major |
     | **0** | only this repo's developers | `releases/development/<X>.x/<X.Y.Z>.md` | every release |

     **TIERS 1 AND 2 ARE TWO KINDS OF AUDIENCE, NOT TWO RUNGS, AND A REPO HAS EXACTLY ONE** (Dave, August 12,
     2026; inbound [#620](https://github.com/DaveKJohn/claude-code-specialists/issues/620)). Tier 1 is
     management and whoever commissions or pays for the work — the audience of a repo that *delivers*
     something, or that sells a **product** whose buyers never read a release note. Tier 2 is the subscriber
     of a **service**, who decides whether to upgrade. The answer is fixed per repo, before any entry is
     written, in `Get-ReleaseAudienceTier`; **this repo answers 2**, the webshop that filed #620 answers 1.
     Same model, opposite answer — which is exactly why it is a knob and not a constant. `new-branch`
     scaffolds tier 0 plus that tier alone, the routing question under tier 0 points at it, and `open-pr` and
     `cut-release` require that tier rather than every rung from 1 up.

     **THE MEASUREMENT, AND IT REVERSED AN ARGUMENT MADE AGAINST THIS CHANGE THREE HOURS EARLIER.** Counting
     tier sections **in aggregate** says tier 1 is a working axis here — 89 of 95 scored — and produces a case
     for keeping the ladder. Counting the highest scored tier **per entry** over the same 97 says the
     opposite: **81 top out at tier 2, 8 at tier 1, 8 at tier 0**, so 81 of those 89 tier-1 sections existed
     only because the ladder demanded one under a scored tier 2 — the same reach argued twice, in a second
     register, for a reader who here is the same person. The consumer measured the mirror image: 37 open
     entries, 15 at tier 1, zero ever at tier 2. **Count per entry, never in aggregate**; the aggregate is an
     artefact of the rule being questioned.

     **TWO SEPARATIONS CARRY THE WHOLE SAFETY OF IT.** `Get-EntryTierMax` stays **2** and every validator
     keeps reading it: the MAX says which tier numbers are valid to *read* — a tier-1 repo must still parse
     the tier-2 entries in its own history — while the audience says which tiers a repo is *asked* about. And
     **an unstated seam means ask about all of them**, exactly as before the knob existed: reading absence as
     "no audience enabled" would switch the tier off in every consumer the moment they took the plugin update,
     with nothing erroring and a release document going out empty. The loud channel is the contract, where
     this is a `decide` record that `adopt-config` scaffolds rather than copies.

     **THE GATE NARROWED WHAT IT ASKS WITHOUT NARROWING WHAT IT ACCEPTS**, which is the half that would
     otherwise have cost real work: the entries pending when this landed each carried all three tiers, and a
     gate that began refusing an *extra* answered tier would have turned finished dossiers into PRs that
     cannot be opened. An asserted test holds exactly that case — do not "tighten" it.

     **`releases/notes/` BECAME `releases/audience/` IN THE SAME MOVEMENT** (August 12, 2026), completing the
     rule that every root under `releases/` names its **reader**: `development/` the developers, `github/` the
     Release page, `audience/` whoever this repo publishes to. `notes/` named the *form* — the same mistake
     `highlights/` made, fixed in that sibling two days earlier and missed in this one. **The shared default
     stays `releases/notes`** in `cut-release.ps1`, `session-status.ps1` and the contract record: an unstated
     seam has to keep meaning what it meant yesterday, and a consumer receives these scripts through a plugin
     update rather than by choosing to.

     **AND `consumer/` + `internal/` WERE MERGED INTO `audience/` TWO HOURS LATER, WHICH IS WHY THAT MOVEMENT
     WAS NOT FINISHED** (Dave, August 12, 2026). This paragraph said they *stay as frozen archives* — and that
     freeze was the assistant's call written as settled, in three places, **none of which named Dave**, while
     the rename standing beside it in the same entry was attributed to him. Asked why `releases/` still had
     five folders, he was offered the freeze as one of three options and chose the merge instead: the twelve
     `consumer/`+`internal/` pairs are now twelve documents in `audience/`, and `releases/` holds three
     reader-named roots and nothing else. **The identical filenames are why it was a merge and not a rename** —
     `3.x/3.2.0.md` existed in both trees, so 24 documents became 12 and no `git mv` could do it.

     **The published-record rule is what made it safe, and it is the half to copy.** Each pair kept both
     registers verbatim — the consumer body under *For consumers*, the organisational prose under *What it is
     worth* and *What was still open at this release* — and dropped exactly one section, `## What is different
     now`, which the 62/38 measurement below identifies as the duplicated half. Prose was otherwise left as
     written, so a merged document may still name `releases/highlights/` or describe itself as one of three
     tiers; **links** were repointed, because a dead link in a record is worse than a relocated one and
     repointing one changes no claim the record makes. That is the same rule the `highlights/` → `consumer/`
     move ran under on August 10, and the same one that left the seven wrong merge dates standing. The one
     thing genuinely rewritten was a clause that had become **false**: an internal note whose lead said the
     commands *"are not on this page"* now sits one section below the page that carries them.

     **ONE HAND-WRITTEN DOCUMENT SINCE AUGUST 10, 2026, WITH A NAMED SECTION PER READER** (Dave). Tier 1 and
     tier 2 had a document each — `releases/internal/` and `releases/consumer/` — and at **all twelve**
     releases since the internal tier existed, both were written, about the same changes. The merge was
     measured rather than argued: `v4.2.0`'s internal note (962 words) held against the writing norm's test 2
     gave **~365 words (38%) that could appear in a consumer-facing section** — and did, rewritten in a second
     register in the other document — against **~597 (62%) that could not**, including the 316-word *what it
     is worth*, which is not an outlier but the whole reason the organisational tier exists. So a **blended**
     document was refused and a **sectioned** one built: each register intact, the shared 38% written once.
     The heading *"what is different now"* is gone rather than moved — it *was* the duplicated half.
     `new-internal-note.ps1` is still shipped for a repo running the two-document flow; nothing here calls
     it, and **its `releases/internal/` path must not be repointed at `audience/`** — that is a consumer's
     archive, not this repo's, and switching it would be the one failure here that produces no error message.
     The same holds for `Get-ReleaseNoteRoot`'s shared `releases/notes` default.

     **A patch writes no hand-written document at all**, and is announced by the generated GitHub Release
     body alone — which is what made this possible in the first place: while the body *was* the internal
     note, that note had to exist at every release or the page had none. The **sections** follow the tier;
     whether there is a document follows the bump.

     The grouping is per **major** (`3.x`) for all three, deliberately differing from the consumer this
     model came from, which folders per minor. `Get-ReleaseNotesGrouping` answers that once.

     **EACH DOCUMENT IS NAMED FOR ITS READER, AND TIER 2 WAS THE ONE THAT WAS NOT** (Dave, August 10,
     2026). It was `releases/highlights/` — the directory, the seam, the renderer and some ten documents of
     prose — while its neighbours name their audience and this very table has always said tier 2 is
     *consumers*. So the name disagreed with the model it belongs to, and it named the **form** (a selection
     of the nice bits) rather than the reader. **Measured before renaming rather than argued:** five
     dev-tool changelogs in the field — Linear, Stripe, Vercel, Raycast, GitHub — and **not one publishes
     anything called "highlights"**; the live names are *Changelog*, *Release notes* and *What's new*, all
     of which name the document or its reader. That same pass found the split this repo already runs:
     GitHub keeps a terse engineering changelog beside readable announcements, which is
     `development`/`internal` beside this tier. The form-name was also earning its keep in the wrong
     direction — it invites the register a self-selected best-of invites, which is what a review of
     `v4.0.0`'s own document had just found it guilty of.

     **THE SEAM IS THE HALF THAT COULD HAVE BROKEN A CONSUMER IN SILENCE**, so it is read under both names:
     `Get-ReleaseConsumerBumps` first, `Get-ReleaseHighlightsBumps` second. The fallback for an undefined
     seam is `@()` — *the tier switched off* — so a repo still carrying the old name would cut a minor,
     write no document for the very consumer it was cut for, and report success. That is the same
     failure-with-no-error-message class the previous release was about, and it is why "recognise both,
     write one" is not politeness here: consumers receive a rename through a plugin update rather than by
     choosing to. `Get-SeamValue` takes a **list** of names now, the current one first, and three asserts in
     `cut-release-guardrail.tests.ps1` hold exactly that.

     **What was deliberately NOT renamed, and the rule behind it.** No GitHub Release body links to a
     `releases/highlights/…` path — checked rather than assumed, which is what made moving all eleven
     documents safe. The **prose** in the archived `releases/development/` notes and in the already-folded
     `CHANGELOG.md` entries keeps the old word, because those describe what the document was called on the
     day they were written; that is the same published-record rule that left the seven wrong merge dates
     standing that [Chris's lens](.claude/specialists/lenses/01-01-extension.md#the-dave-rules) records.
     Their **links** were repointed, since a dead link
     in a record is worse than a relocated one and repointing one changes no claim the record makes.
     `Get-ReleaseHighlightsStakeholderTypes` and `Get-ReleaseHighlightsWording` keep their names too — they
     name functions that no longer exist under any name.

     **AND THE DOCUMENT NOW HAS A WRITING NORM, WITH EXACTLY ONE OF ITS SEVEN TESTS AS A GATE** (Dave,
     August 10, 2026). The rename came out of reviewing `v4.0.0`'s own consumer document against the
     question *"is this written for someone who paid for the product?"*, and the answer was: partly. Of its
     four substantive blocks one was in the second person; it opened with **"twenty-one releases and
     fifty-one pull requests in ten days"** (our effort, not their outcome), carried a full block about a
     lint check we measured and declined (tier-0 material in a tier-2 document), used in-house vocabulary
     (*"against the tree they describe"*), had to tell the reader to skip to the bottom for the useful part,
     and linked them into the development notes. The seven tests are in the
     [`cut-release` skill](plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md) — the portable
     half, so a consumer receives them — each one carried by what a named dev-tool changelog actually does.

     **The split between prose and gate was measured, not assumed, and that is the transferable part.**
     Three candidate rules were run over this repo's eleven consumer documents:

     | candidate rule | findings | true | verdict |
     |---|---|---|---|
     | links into `development/` or `internal/` | 2 | **2** | **built** — lint check 25 |
     | a significance score in the document | 4 | 0 | declined |
     | a branch name or PR number in the document | 3 | 0 | declined |

     Both declined rules fail on the same document and for the same reason: `v3.7.0`'s release **was about
     the entry format**, so its consumer document correctly quotes `#### Tier 2`, `**Score:** N/A` and
     `` ## `feat/your-branch` changelog `` as illustrations of the shape it was announcing. **No regex
     separates an illustration from a leak**, and both would have needed an exemption list on the day they
     landed — the shape this repo has already been bitten by. Check 25 escapes it by reading the link
     **target** only: a path in prose is
     [check 4's declined territory](#claude-code-specialistss-safety-implementation) (124 findings, none
     real), while a link is not a path being discussed but a destination being offered, and whose repo it
     lives in stops being ambiguous. The other six tests stay prose that a person applies.

     **The release documents follow the same flat shape**, and that deletion is part of the decision rather
     than a tidy-up alongside it: the category grouping (`## Features`, `## Fixes`, …) is gone, together with
     `Format-CategorizedEntries`, the category labels and the `Get-ReleaseCategoryTitles` seam. It grouped on
     the **branch prefix**, which this repo has measured does not predict impact, so a document's most
     consequential change was filed third under whichever label its prefix produced — and the ranking could
     only reorder the categories, not escape them. Each change states its own type inside itself now, so
     nothing is lost by not grouping on it.

     **The audience tier decides which sections of the hand-written note the entry reaches**; the
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

     **Every tier the repo asks about is present, and `N/A` is how one says it reaches nobody** (Dave,
     August 7, 2026; narrowed from "all three" to tier 0 plus the audience tier on August 12). Tier 1 and
     tier 2 used to be commented out, and uncommenting one *was* the claim — so an
     unreached tier and an unfinished one looked identical, and no gate could tell "this reaches no
     consumer" from "nobody got to tier 2 yet". Each tier is answered now: a score, or `N/A` with a line
     saying why. **The reach is the highest tier carrying a number**, so an `N/A` costs a sentence and
     nothing else — and the reasoning behind a *negative* claim survives into the record, which the
     absence model threw away. A `Yes/No` field was drafted alongside the score the same day and dropped:
     a score and a yes are one fact, free to contradict each other.

     **The scaffolded working files carry no comments at all** (Dave, August 7, 2026). Guidance is written
     only into `workflow-davekjohn/branch/templates/`, which is what those copies are for; the file a branch gets is the
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
     that it was asked. **The LAST written tier has no successor and carries none** — which used to be a
     statement about tier 2 specifically and is now about whichever audience tier the repo asked for. The
     question is keyed on what is actually written rather than on a fixed pair, so a tier-2 repo no longer
     prints *"continue to Tier 1"* above a file whose next section is Tier 2.

     **The cumulative ladder is gone** (August 12, 2026), and with it the rule that a tier-2 entry owed a
     tier-1 section. What remains is that every tier the file *does* carry is answered, `N/A` ones included.
     The score is scaffolded **empty**, unlike the tier: 0 is a harmless final answer about
     reach, while any scaffolded *score* would be a guess at a ranking, and this repo has measured what a
     guessed ranking costs (the retired remove-before-publishing marker, below).

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

     **The tiers are not nested audiences, so tier 0 may legitimately score below the audience tier.** Dave asked whether
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
     must be able to misplace at most the one entry being folded rather than scramble a list it did not write. The **consumer** re-read the tier-2 row (its reader is the consumer); the **internal
     note** reads the tier-1 row. **Tier 0 is never ranked** — the development note is the record: complete
     and chronological. The table **survives into the record** because that is the last place each ranking's
     justification lives, and is **stripped from everything that travels outward** (the consumer document),
     because a self-assigned number printed at a consumer is a marketing claim. It used to be stripped
     from the per-plugin `CHANGELOG.md` and `RELEASE.md` too; those were retired on August 8, 2026, so
     the consumer document is the only outward document left to strip. `cut-release.ps1` refuses a release whose tier-1-or-higher entries have not scored themselves;
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
       work earned only a patch. It is written as **tier 1 or higher** rather than as "the audience tier"
       deliberately: `Test-ReleaseBumpEarned` then reads correctly in a tier-1 repo and a tier-2 repo alike,
       with neither having to translate it, and **#620's "silently wrong bump" cannot happen** — that was the
       one claim in the report which measurement did not support;
     - **the sections of the note follow the TIER, not the bump**, and that is what keeps the looser
       rule honest. A minor whose highest pending entry is tier 1 writes the note **without its *For
       consumers* section**, so nobody outside is handed a section about work they cannot see —
       which is every minor in a repo whose audience is tier 1. `cut-release.ps1` keys that section on a tier-2
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
     not the same question: the consumer document is *what a consumer notices*, internal is *what the organisation
     gets out of it*. They come apart most clearly on a patch — a release with nothing for a consumer can
     still be the one where a routine change stopped needing a developer.

     **Who writes what.** `cut-release.ps1` generates the development notes and the consumer **draft**,
     then names the two documents it deliberately did not write. The internal note has its own script
     ([`new-internal-note.ps1`](scripts/release/new-internal-note.ps1)), which needs the development
     notes as input and so can only run *after* the cut. Both the consumer-document edit and the internal note
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
     repo.** Until August 5, 2026 the consumer document put `Feat`/`Fix` above a "remove before
     publishing" marker and everything else below it, explicitly as a *proposal* rather than a verdict.
     Measured against the 19 entries pending at v3.2.0, the single most consequential change for a consumer
     — renaming the marketplace, which breaks every existing install — arrived on a `chore/` branch and
     therefore landed below the marker. The tier asks the entry's author instead, so the marker and its two
     seam knobs are retired; a `docs/` branch carrying a tier-2 change now says so, and the prefix decides
     nothing but which category heading the entry is grouped under.
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
