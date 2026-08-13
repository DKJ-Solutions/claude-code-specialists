# Contributing — changelog & PR workflow

Changes to this repo go through a branch + Pull Request to `main`, with a folded changelog entry. **That
cycle is not this repo's own** — it is what the `workflow-davekjohn` plugin does, in every repo that
enables it, and it is described once, with the plugin:

📄 **[The contribution cycle — the portable half](plugins/workflows/workflow-davekjohn/CONTRIBUTING-portable.md)**

Read that first. It covers the five steps, the two files a branch works in, the gates on the PR, and the
Significance model — naming the *seam* wherever a repo owns the answer instead of asserting one repo's
answer as the rule. **This page is this repo's set of answers to it**, and nothing more.

The split is the same one the manuals and the repo lenses already use: the portable half travels with the
plugin, the local half stays in the repo. It exists because a document that hardcodes one repo's answers
cannot be adopted by the next repo — it has to be rewritten, and a rewrite is a second source. That was
[inbound #566](https://github.com/DaveKJohn/claude-code-specialists/issues/566), from a consumer who tried
to adopt this page and measured why it could not be done.

---

## Specific to this repo (claude-code-specialists)

> *Everything in the portable half is the cycle, and it travels to every repo that enables the plugin. This
> part is the claude-code-specialists lens: if you copy that page into your own repo, this is the section
> you replace.*

### The seam, answered — the whole table in one place

| the portable half says | this repo's answer | declared in |
|---|---|---|
| your lint gate | [`scripts/lint/check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1) | `Get-LintScript` |
| your branch prefixes | `feat/` · `fix/` · `docs/` — and **no `chore/`** | [`scripts/lib/branch-info.ps1`](scripts/lib/branch-info.ps1) |
| the type an unknown prefix falls back to | `Chore` | `Get-EntryFallbackType` |
| your entry's section headings | the English defaults — nothing is overridden | *(no override defined)* |
| your significance rubric | the shared default, 1–5 | *(no override defined)* |
| your permanent root docs | `CHANGELOG` · `CLAUDE` · `README` · `LICENSE` · `CONTRIBUTING` · `SECURITY` | `Get-ReservedRootMd` |
| your merge method | `merge` — a merge commit, not a squash | `Get-PrMergeMethod` |
| whether you have a plugin tier | yes — the `Plugins:` line is derived | `Get-ReleasePluginTier` |
| whether you have a separate live stage | no | `Get-LiveStage` |
| how release notes are foldered | per **major** (`3.x`) | `Get-ReleaseNotesGrouping` |

All of them live in [`scripts/repo-config.ps1`](scripts/repo-config.ps1) except the prefix table, which is
its own repo-owned lib. Where the table above says *no override defined*, this repo deliberately runs on
the shared default — that is an answer, not an omission.

### The prefixes, and why there are three

| Type of work | Branch name | GitHub label | Changelog type |
|---|---|---|---|
| New or extended capability | `feat/<description>` | `enhancement` | Feat |
| Correction of an error in something existing | `fix/<description>` | `bug` | Fix |
| Documentation, workflow explanation, manual content | `docs/<description>` | `documentation` | Docs |

**There is no `chore/`, and `Test-BranchName` refuses it outright.** Chore is the name for work that lands
*directly on the trunk* under one of the named exceptions, so a chore branch is a contradiction. `Chore`
stays a recognised changelog **type** — every entry already written under it must still validate, and it is
what an unknown prefix falls back to. Recognise both, write one.

Classify by **what actually changes**, not by which files move along: `docs/` is purely text, `feat/` is a
capability that is new or larger than it was, even when documentation comes with it.

### The gates, and the CI check the merge waits on

`open-pr.ps1` runs the lint gate above and then every `scripts/tests/*.tests.ps1`, and refuses to push on
any error or failing suite. The same pair runs as CI in
[`.github/workflows/ci.yml`](.github/workflows/ci.yml) — on every PR and every push to `main` — under the
job id **`lint-en-tests`**, which is the exact name the `main` ruleset requires as a passing status check.
A merge attempted before it goes green returns `BLOCKED`.

That job id is deliberately not English, and renaming it would silently break the ruleset binding — every
future PR would sit unmergeable, waiting on a check that no longer exists. See
[`.claude/rules/language-layers.md`](.claude/rules/language-layers.md).

### Merging — it does not wait, with two exceptions

The portable half leaves this to each repo, because it is a governance decision rather than a configuration
value. Here, a finished branch **opens, merges and folds in one motion without waiting for Dave**. The lint
gate, the test gate and CI prove this class of change is sound, and anything that does turn out wrong is one
revert PR away.

Two kinds of change stop and wait for his word: work with a **visible result** that has to be judged by eye,
and work that is **irreversible or outward-facing** (a release, a version bump, a tag, repo settings, or
publishing beyond the normal PR flow). The full statement is in
[the safety rules](CLAUDE.md#never-directly-on-the-main-branch--via-branch--pr).

### The two direct-on-`main` exceptions

Both are named, narrow, and nothing else may use them: the **fold commit** after a merge, and the
**release commit** on explicit request. Their exact scope is in
[the safety rules](CLAUDE.md#never-directly-on-the-main-branch--via-branch--pr).

### The bump — this repo runs the shared floor, unchanged

The portable half asks each repo to say so out loud where its own rule is stricter than the gate's, because
a contributor otherwise picks their bump type from the wrong rule. **Here there is no stricter rule:** the
gate's floor *is* this repo's policy — tier 0 only is a patch, tier 1 or higher earns a minor, and a major
additionally needs ten minors in the current major line.

The audience of each release document follows the **tier**, not the bump, which is what keeps that looser
rule honest: a tier-1-only minor writes the internal note and no consumer document, so nobody outside is handed a
document about work they cannot see. Full model:
[the tier model](plugins/workflows/workflow-davekjohn/RELEASES-portable.md#the-tier-model) and
[what a release must earn](plugins/workflows/workflow-davekjohn/RELEASES-portable.md#what-a-release-must-earn).

### Releases

A release here is **repo-wide and in lockstep**, which works because this repository holds *one* product
whose plugins are one system — see [One product, one repository](README.md#one-product-one-repository). A
second, unrelated product would get its own repository and marketplace rather than joining this release
train.

The cycle itself — what a release is, the `cut-release.ps1` steps, the three release documents and the
guardrails — is in
[Cutting a release](plugins/workflows/workflow-davekjohn/RELEASES-portable.md#cutting-a-release); the list
of releases actually cut is on [this repo's own release page](releases/README.md#the-release-list).

### Where the rest lives

- The two files a branch works in, and the three step marks: [`branch/README.md`](branch/README.md).
- The pending changelog entries, ranked: [`CHANGELOG.md`](CHANGELOG.md).
- Which specialist owns which kind of change: [`CLAUDE.md`](CLAUDE.md) and the roster it imports.
