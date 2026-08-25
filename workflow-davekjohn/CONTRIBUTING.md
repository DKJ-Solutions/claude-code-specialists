# Contributing — the workflow's layer

This page sits **on top of** the repo's own [`CONTRIBUTING.md`](../CONTRIBUTING.md), which describes the
standard workflow that holds before any plugin is consulted. **Where the two disagree, this page wins**
(Dave, August 14, 2026): the standard page stays meaningful in a repo without the plugin, and everything
the `workflow-davekjohn` plugin owns — the development cycle, the folded changelog entry, the significance
model, the release cycle — is stated here, in the folder that travels with it.

Changes to this repo go through a branch + Pull Request to `main`, with a folded changelog entry. **That
cycle is not this repo's own** — it is what the `workflow-davekjohn` plugin does, in every repo that
enables it, and it is described once, with the plugin:

📄 **[The contribution cycle — the portable half](../plugins/workflows/workflow-davekjohn/CONTRIBUTING-portable.md)**

Read that first. It covers the five steps, the document a branch works in, the gates on the PR, and the
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
| your lint gate | [`scripts/lint/check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1) | `Get-LintScript` |
| your branch prefixes | `feat/` · `fix/` · `docs/` — and **no `chore/`** | [`scripts/lib/branch-info.ps1`](../scripts/lib/branch-info.ps1) |
| the type an unknown prefix falls back to | `Chore` | `Get-EntryFallbackType` |
| your audience tier | **2** — a service, not a product | `Get-ReleaseAudienceTier` |
| your entry's section headings | the English defaults — nothing is overridden | *(no override defined)* |
| the wording inside the development cycle | the English defaults | `Get-BranchFileWordingOverrides` *(none)* |
| your significance rubric | the shared default, 1–5 | *(no override defined)* |
| your permanent root docs | `CHANGELOG` · `CLAUDE` · `README` · `LICENSE` · `CONTRIBUTING` · `SECURITY` | `Get-ReservedRootMd` |
| your merge method | `merge` — a merge commit, not a squash | `Get-PrMergeMethod` |
| whether you have a plugin tier | yes — the `Plugins:` line is derived | `Get-ReleasePluginTier` |
| whether you have a separate live stage | no | `Get-LiveStage` |
| how release notes are foldered | per **major** (`3.x`) | `Get-ReleaseNotesGrouping` |

All of them live in [`scripts/repo-config.ps1`](../scripts/repo-config.ps1) except the prefix table, which is
its own repo-owned lib. Where the table above says *no override defined*, this repo deliberately runs on
the shared default — that is an answer, not an omission.

### The development cycle — what this repo's answers make of it

The document itself, its two halves and every rule about them are in
[`DEVELOPMENT-portable.md`](../plugins/workflows/workflow-davekjohn/DEVELOPMENT-portable.md).
Three of this repo's answers change what a contributor here actually sees in it, so they are stated here
rather than left to be worked out from the seam table above.

**The audience tier is `2`, so the entry asks two questions rather than four.** Tier 0 needs no heading —
the `` ## DEPLOY: `<branch>` `` line is its section, and its answer goes directly underneath — and the one
audience tier gets `### What makes this PR extra special`. Both sit at the entry's own section level,
beside `### Pull Request`. A repo that has stated *no* audience tier gets the older shape instead, a
`#### Tier N` sub-section per tier the model has, nested one level deeper; that is the shape the portable
half describes as the fallback, and it is not what you will see here.

**Every branch name carries a version, and `new-branch` completes it.** `docs/thing` becomes
`docs/thing-v1`; a second cycle on the same subject is `docs/thing-v2`, typed deliberately rather than
guessed — a rerun of `new-branch` resumes the branch it named rather than opening the next one. The
refusal on `final` in [`branch-info.ps1`](../scripts/lib/branch-info.ps1) is the same rule from the other
end: a name claiming to be the last word is a prediction, and the number is the honest form.

**The lint gate holds the document's shape here, which a consumer's repo typically cannot.** Three checks
in [`check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1) do it: **no document declaring
the trunk survives a fold** anywhere in the tree, which is what replaced holding an empty copy byte-for-byte
to the formatter once that copy stopped existing; the **entry-shape** claims in prose are held against the
section count the scaffolder writes; and the **heading-level** rules are enforced against the DEPLOY section,
read out of the document with its line offset so a finding names the line you can find. In a consumer none
of that runs — the plugin ships no `scripts/lint/` — so there, the document is the only statement of its own
shape. That is also why the guidance lives inside it.

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
[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) — on every PR and every push to `main` — under the
job id **`lint-en-tests`**, which is the exact name the `main` ruleset requires as a passing status check.
A merge attempted before it goes green returns `BLOCKED`.

That job id is deliberately not English, and renaming it would silently break the ruleset binding — every
future PR would sit unmergeable, waiting on a check that no longer exists. See
[`.claude/rules/language-layers.md`](../.claude/rules/language-layers.md).

**A second check appears on every PR, and it does not block.**
[`.github/workflows/claude-code-review.yml`](../.github/workflows/claude-code-review.yml) runs an
automated review over the diff and posts inline comments, under the job id `claude-review`. It is
advisory: the ruleset names `lint-en-tests` and nothing else, so a red `claude-review` is a finding to
read rather than a merge blocker. On a pull request from a fork it fails by construction — GitHub
withholds secrets from fork-triggered workflows, which is the safe outcome and not a defect to work
around by switching that workflow to `pull_request_target`.

### Merging — it does not wait, with two exceptions

The portable half leaves this to each repo, because it is a governance decision rather than a configuration
value. Here, a finished branch **opens, merges and folds in one motion without waiting for Dave**. The lint
gate, the test gate and CI prove this class of change is sound, and anything that does turn out wrong is one
revert PR away.

Two kinds of change stop and wait for his word: work with a **visible result** that has to be judged by eye,
and work that is **irreversible or outward-facing** (a release, a version bump, a tag, repo settings, or
publishing beyond the normal PR flow). The full statement is in
[the safety rules](../CLAUDE.md#never-directly-on-the-main-branch--via-branch--pr).

### The three direct-on-`main` exceptions

All three are named, narrow, and nothing else may use them: the **fold commit** after a merge, the
**release commit** on explicit request, and the **release-notes commit** that follows it. Their exact
scope is in
[the safety rules](../CLAUDE.md#never-directly-on-the-main-branch--via-branch--pr).

### The bump — this repo runs the shared floor, unchanged

The portable half asks each repo to say so out loud where its own rule is stricter than the gate's, because
a contributor otherwise picks their bump type from the wrong rule. **Here there is no stricter rule:** the
gate's floor *is* this repo's policy — tier 0 only is a patch, tier 1 or higher earns a minor, and a major
additionally needs ten minors in the current major line.

The audience of each release document follows the **tier**, not the bump, which is what keeps that looser
rule honest: a tier-1-only minor writes the internal note and no consumer document, so nobody outside is handed a
document about work they cannot see. Full model:
[the tier model](../plugins/workflows/workflow-davekjohn/RELEASES-portable.md#the-tier-model) and
[what a release must earn](../plugins/workflows/workflow-davekjohn/RELEASES-portable.md#what-a-release-must-earn).

### Releases

A release here is **repo-wide and in lockstep**, which works because this repository holds *one* product
whose plugins are one system — see [One product, one repository](../README.md#one-product-one-repository). A
second, unrelated product would get its own repository and marketplace rather than joining this release
train.

The cycle itself — what a release is, the `cut-release.ps1` steps, the three release documents and the
guardrails — is in
[Cutting a release](../plugins/workflows/workflow-davekjohn/RELEASES-portable.md#cutting-a-release); the list
of releases actually cut is on [this repo's own release page](../releases/README.md#the-release-list).

### Where the rest lives

- The document a branch works in, and the three step marks:
  [`DEVELOPMENT-portable.md`](../plugins/workflows/workflow-davekjohn/DEVELOPMENT-portable.md).
  **This repo keeps no local half of it**, which is the one place the split above is not followed, and
  deliberately: that page was `branch/README.md`, and once the two branch files merged its prose would have
  had to be reproduced byte-for-byte by a *portable* formatter inside every branch's own document —
  repo-specific prose generated by a portable formatter cannot be right. Its answers are split between
  [the section above](#the-development-cycle--what-this-repos-answers-make-of-it) and the file rules in
  [`CLAUDE.md`](CLAUDE.md) here.
- The pending changelog entries, ranked: [`CHANGELOG.md`](../CHANGELOG.md).
- Which specialist owns which kind of change: [`CLAUDE.md`](../CLAUDE.md) and the roster it imports.
