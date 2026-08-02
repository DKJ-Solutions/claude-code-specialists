# CLAUDE.md — davekjohns-workshop

This file is the operating guide for this repo, which is run by the **Claude Specialists** — a team
of specialized Claudes under a single Chief of Staff. It is structured like every specialist manual:
**the portable way of working comes first** (the system and the constitution, valid in every repo
that works with the Claude Specialists), and **everything specific to this repo comes last**, under
[`## Specific to this repo (davekjohns-workshop)`](#specific-to-this-repo-davekjohns-workshop).

> **This repo is a special case.** See [`README.md`](README.md) for what davekjohns-workshop is and
> [`## Specific to this repo (davekjohns-workshop)`](#specific-to-this-repo-davekjohns-workshop)
> below for the team that maintains it.

---

## Safety rules

**Constitution — read this first.** These rules are broadly shared and take precedence over any
convenience; all other working practices live in the specialist manuals. The concrete implementation
for this repo (the main branch, the lint gate, the fold exception, being public) is in
[`## Specific to this repo (davekjohns-workshop)`](#specific-to-this-repo-davekjohns-workshop).

### Never without Dave's explicit permission

- **Merging work with a visible result** — if the change produces something Dave has to judge with
  his own eyes (a frontend, styling, rendered output, an artifact), the branch stops and reports
  instead of merging. No automated gate can prove that something *looks* right. Work whose
  correctness the gates do prove runs through on its own (see below).
- **A release/version bump** of a plugin (raising `version` in a `plugin.json`, creating a tag or
  GitHub Release) — only on explicit request.
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
  [#388](https://github.com/DaveKJohn/davekjohns-workshop/issues/388) is the measured instance
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

## Specific to this repo (davekjohns-workshop)

> *Everything above is the portable way of working of a repo run by the Claude Specialists. This
> part is the davekjohns-workshop lens: if you copy this system to another repo, this is the part
> you replace — it doesn't describe that there are specialists and safety rules, but what this repo
> is, which team works here, and how the constitution is concretely implemented here.*

`davekjohns-workshop` is the **workshop repo of Dave (DaveKJohn)**: the marketplace where all of his
plugins are built and maintained, and the **single source of truth** for all shareable subagent
definitions — every consuming repo (life-hub, smartwatchbanden) points here and enables or disables
per plugin. The full story (the plugin/family structure and consumption) is in the
[root `README.md`](README.md); the split manual model, the bootstrap path, and what the specialists
family does and how its plugins differ are in the
[family README](claude-code-plugins/claude-specialists/README.md); the drift lint is in the
[connectors README](claude-code-plugins/claude-specialists/connectors/README.md#maintenance-drift-lint).

**The repo consumes itself.** Via [`.claude/settings.json`](.claude/settings.json) this repo enables
its own `specialists` plugin (group 1), with the `github` marketplace source
`DaveKJohn/davekjohns-workshop` — so the repo points at itself. That way the maintenance team works
with exactly the product it maintains. One consequence to be aware of: through the `github` source
the team sees the **last pushed** version of the plugins, not your ongoing branch work — an agent
def you modify on a branch only takes effect after merge + push.

### Language

**Repo content is English** — every layer, the script layer included: comments, docstrings, console
output, and script-generated document content. **The session-reply language is separate and follows
the user.** That second half applies to every turn regardless of which files it touches, which is why
it lives here rather than in a path-scoped rule. The system-wide norm (and its three exceptions) is in
[Tessa #16's portable manual](claude-code-plugins/claude-specialists/specialists/manuals/06-16-manual.md#what-tessa-covers)
under **"Guarding the language convention,"** so it travels to every consuming repo.

**The per-layer detail — which layers are in scope, and the deliberate exceptions (`VUL-IN`,
`lint-en-tests`, the legacy markers, the archived release notes) — is in
[`.claude/rules/language-layers.md`](.claude/rules/language-layers.md).** It is path-scoped to
`scripts/**`, `.github/**`, `releases/**` and `CHANGELOG.md`, so it loads when you touch one of those
layers instead of in every session. Two things to know before moving anything else there: a
`paths:`-scoped rule is **lost after a `/compact`** until a matching file is read again, and a rule
*without* `paths:` loads unconditionally and therefore **saves nothing** — the scoping is the saving.
So only content that is inert until you open a matching file belongs there. Decision by Dave,
July 20, 2026; sharpened July 21 and July 26, 2026.

### Structure — where everything lives

The full repo layout (`.claude-plugin/`, `claude-code-plugins/` incl. `connectors/` and
`agent-shared/`, `scripts/`, `releases/`, `.claude/`, and the root docs + `.github/`) is described
in [README.md](README.md#repo-layout).

### davekjohns-workshop's safety implementation

The constitution above, concretely implemented here:

- **The main branch is `main`.** All changes via a `<prefix>/<short-name>` branch + PR to
  `main`. Valid prefixes ([`scripts/lib/branch-info.ps1`](scripts/lib/branch-info.ps1)):
  `feat/` → enhancement · `fix/` → bug · `docs/` → documentation · `chore/` → documentation. See
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
- **Two deliberate exceptions to "never directly on `main`":**
  1. The **fold commit** after a merge: [`fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1)
     folds the entry file into `CHANGELOG.md` and removes it, and with `-Commit`/`-Push` makes that
     commit itself — scope limited to `CHANGELOG.md` + the entry file, and since August 2, 2026
     enforced rather than merely intended: the commit names its paths, so nothing else in the tree
     can ride along. Committing stays opt-in, because it is this exception being used.
     See [Rendall #06](.claude/specialists/lenses/05-06-extension.md#changelog).
  2. The **release commit** (only on explicit request): [`cut-release.ps1`](scripts/release/cut-release.ps1)
     bumps all plugin versions in lockstep, generates the release notes in `releases/development/`,
     references them from `## Releases`, (re)generates each plugin's consumer-facing `RELEASE.md`
     card, commits that on `main`, and tags `vX.Y.Z`. Deliberately no branch/PR — just like the
     fold. See [Rendall #06](.claude/specialists/lenses/05-06-extension.md#versioning--releases).
- **This repo is `public`.** A deliberate choice, so the remote `github` marketplace source can be
  read without gh auth. Consequence: **nothing confidential** belongs here — no personal
  information, credentials, or secrets. The group 1 agent defs are therefore deliberately
  repo-neutral; repo-specific context lives in the consuming (private) repo's
  `.claude/specialists/lenses/` lens.
- **Changes to shared agent defs land here first**, are committed here, and only then picked up by
  the consuming repos — never the other way around.

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
