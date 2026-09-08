# `dkj-policy/` — the workflow's own folder in this repo

Everything portable about the `dkj-policy` workflow gathers here, so the workflow occupies one
folder in the repo root instead of scattering through it (Dave, August 14, 2026). The conventions
themselves travel with the plugin as three portable pages; each page in this folder is **this repo's own
set of answers** to them. **There were four until August 30, 2026**, when `TICKETWORK-portable.md` folded
into the cycle page as its first step — the layer this repo has no work in, and describes anyway.

| here | what it holds | portable half |
|---|---|---|
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | **the centre of this folder** — the standard branch + PR workflow, the workflow's contributing layer AND the working rules a session needs here, on one page. Two of those three merged on August 26, 2026 (#886) and the standard workflow arrived from the root on August 27. It wins over the [root CLAUDE.md](../CLAUDE.md) on conflict | [`CONTRIBUTING-portable.md`](../plugins/dkj-policy/CONTRIBUTING-portable.md) |
| [`CHANGELOG.md`](CHANGELOG.md) | what is pending for the next release: one `##` entry per merged branch, folded in at the merge and emptied by a cut. Here since August 27, 2026, stated in `Get-ChangelogPath` | *(the format travels in [`DEVELOPMENT-portable.md`](../plugins/dkj-policy/DEVELOPMENT-portable.md))* |
| `<branch>.md` | the branch's own document, one per branch and present only while that branch is open: its plan, and the DEPLOY section that folds into the changelog | [`DEVELOPMENT-portable.md`](../plugins/dkj-policy/DEVELOPMENT-portable.md) |
| [`releases/`](releases/) | the dated list of every release ever cut ([`history.md`](releases/history.md), here since August 27, 2026), the published audience notes, the generated changelog and GitHub-Release trees, and this repo's seam answers in its own [`README.md`](releases/README.md) | [`RELEASES-portable.md`](../plugins/dkj-policy/RELEASES-portable.md) |

In this repo the portable pages resolve as relative links because this is the plugin's **source**; in a
consumer they live in the plugin install instead, which is why the consumer version of this page (the
`adopt-dkj-policy` skill's Part 1 scaffolds it) names them in code rather than linking them.

One thing a consumer's folder has that this one deliberately does not: this page itself is hand-written
rather than scaffolded — the scaffold refuses a repo that publishes plugins. The generated
`releases/changelog/` and `releases/github/` trees sat at this repo's root until August 26, 2026 and
now sit here too, so on that point the two folders match (#914).

**On August 27, 2026 the last three followed them** (Dave): `CHANGELOG.md`, the contributing page's own
standard-workflow half, and the release list — which is now `releases/history.md` rather than a second
`README.md`. So this folder is no longer *the workflow's belongings beside the repo's own*; it is every
document the contribution cycle produces or governs, and the seam answers below say so rather than the
computed defaults doing it silently. Nothing about a consumer changed: those defaults have pointed here
since #885, and this repo was the one holdout.

**This page also carries the folder's index sections**, below the divider: the seam table — this repo's
answer to every question the portable half leaves open — then how to update the plugins in another
checkout of this repo, and the pointer list saying where the rest lives. The first and the last sat on
`CONTRIBUTING.md` until August 26, 2026, where they were two `##` sections that were not steps.

---

## The seam, answered — the whole table in one place

It sits here rather than on [`CONTRIBUTING.md`](CONTRIBUTING.md) because it is not a step: the five numbered
steps on that page all run on these answers, and a folder index is where you look one up. Moved here on
August 26, 2026 (Dave), when that page was reduced to its `##` steps and nothing else — four of them then,
five since `1. NEW ISSUE / TASK` was written ahead of them on August 29, 2026.

| the portable half says | this repo's answer | declared in |
|---|---|---|
| your lint gate | [`scripts/lint/check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1) | `Get-LintScript` |
| your branch prefixes | `feat/` · `fix/` · `docs/` — and **no `chore/`** | [`scripts/lib/branch-info.ps1`](../scripts/lib/branch-info.ps1) |
| the type an unknown prefix falls back to | `Chore` | `Get-EntryFallbackType` |
| your audience tier | **2** — a service, not a product | `Get-ReleaseAudienceTier` |
| your entry's section headings | the English defaults — nothing is overridden | *(no override defined)* |
| the wording inside the development document | the English defaults | `Get-BranchFileWordingOverrides` *(none)* |
| your significance rubric | the shared default, 1–5 | *(no override defined)* |
| your permanent root docs | `CLAUDE` · `README` · `LICENSE` · `SECURITY` · `INSTALL` · `UNINSTALL` — `CHANGELOG` and `CONTRIBUTING` came off on August 27, 2026, having left the root | `Get-ReservedRootMd` |
| where your changelog lives | `dkj-policy/CHANGELOG.md` — the consumer default, which this repo adopted on August 27, 2026 (the folder renamed on September 5, #1437) | `Get-ChangelogPath` |
| where the release list lives | `dkj-policy/releases/history.md` | `Get-ReleaseHistoryPath` |
| where the generated internal note goes | `dkj-policy/releases/internal` | `Get-ReleaseInternalNotesRoot` |
| your merge method | `merge` — a merge commit, not a squash | `Get-PrMergeMethod` |
| whether you have a plugin tier | yes — the `Plugins:` line is derived | `Get-ReleasePluginTier` |
| whether you have a separate live stage | **no** — which is what makes step 5 of [`CONTRIBUTING.md`](CONTRIBUTING.md) a no-op here | `Get-LiveStage` |
| how release notes are foldered | per **major** (`3.x`) | `Get-ReleaseNotesGrouping` |
| where the hand-written notes live | `dkj-policy/releases/audience` | `Get-ReleaseNoteRoot` |

All of them live in [`scripts/repo-config.ps1`](../scripts/repo-config.ps1) except the prefix table, which is
its own repo-owned lib. Where the table says *no override defined*, this repo deliberately runs on the shared
default — that is an answer, not an omission.

## Updating the plugins — in every other checkout of this repo

**This repo consumes itself**, so the workflow a session here runs is the *installed* copy, not the tree
you are standing in. Via [`.claude/settings.json`](../.claude/settings.json) it enables `dkj-team-alpha`
and `dkj-policy` from the `github` marketplace source `DKJ-Solutions/claude-code-specialists` — itself.
That is what makes the update a step of its own rather than something a merge does for you, and the whole
reason this section sits in the folder index instead of only in the plugin's own
[README](../plugins/dkj-policy/README.md).

Two commands, from the root of the checkout you want to move, once per plugin:

```powershell
claude plugin marketplace update claude-code-specialists                        # 1. refresh the clone
claude plugin update dkj-policy@claude-code-specialists --scope project         # 2. then update, per plugin
claude plugin update dkj-team-alpha@claude-code-specialists --scope project
```

Then **restart the session** — a skill or a hook that arrived with the update is not in a session that
started before it.

**A push does not do it, and neither does a merge.** A session reads the plugins from the **local
marketplace clone**, which advances on that first command and on nothing else. So an agent def, a skill
or a script you merged here takes effect after merge, push *and* that refresh — and **between two
releases no version check can tell you the clone is behind**, because `version` only moves at a cut. The
[root `CLAUDE.md`](../CLAUDE.md#specific-to-this-repo-claude-code-specialists) states both halves; this
is the procedure they imply.

**Everything the second command touches is per-checkout state, which is why every machine runs it
itself.** The install record is keyed on the checkout's **folder path**, so renaming or moving a checkout
unlinks the plugin there with no error, and a machine that never ran `claude plugin install … --scope
project` carries no record at all — nothing to unlink and nothing to update
([#1449](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1449)).

**What tells you a machine is behind is its own install record, not the connector register.** No
manifest in [`connectors/`](../connectors/README.md) stores a version — that bookkeeping was removed
deliberately (July 20, 2026, see [`connectors/README.md`](../connectors/README.md#the-manifest-format)):
the check reads the version actually installed from that machine's own `installed_plugins.json` and
compares it to the source checkout's `plugin.json`, and the register's only part in that is
`localCheckout`, i.e. which machine record to read. `connector-sessioncheck` still reports every
consumer that lags the source at session start, and `scripts/sync/check-connectors.ps1` is still the
deliberate full run — that comparison is the only place the answer exists, because the lagging checkout
itself reports a plausible version and works. And it exists only where a verified source checkout sits
beside the consumer on that machine: with none found the check is skipped outright
([#1587](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1587)), so silence there is not
"up to date" — it is no verdict at all.

**And two things can need catching up after the update.** `script-contract-sessioncheck` reports a
repo-owned seam function the newer shared scripts call and this checkout has never had; a specialist that
arrived with the update needs a roster row and a lens, which `sync-roster` stages — and which the repo
owner types, because that skill is reserved for explicit invocation. The measurements behind the two
commands, and why the version number is not the code you are running, are in
[`INSTALL.md`](../INSTALL.md#staying-up-to-date) rather than repeated here.

## Where the rest lives

- The document a branch works in, its four phases and the three step marks:
  [`DEVELOPMENT-portable.md`](../plugins/dkj-policy/DEVELOPMENT-portable.md).
  **This repo keeps no local half of it** (Dave, August 23, 2026), which is the one place the portable/local
  split is not followed, and deliberately: that page was `branch/README.md`, and once the two branch files
  merged its prose would have had to be reproduced byte-for-byte by a *portable* formatter inside every
  branch's own document — repo-specific prose generated by a portable formatter cannot be right. Its answers
  moved to the pages that already own them: the file rules to step 2.1 of [`CONTRIBUTING.md`](CONTRIBUTING.md),
  the seam answers to the table above.
- **The lint gate holds the document's shape here, which a consumer's repo typically cannot.** Three checks in
  [`check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1) do it: **no document declaring the
  trunk survives a fold** anywhere in the tree, which is what replaced holding an empty copy byte-for-byte to
  the formatter once that copy stopped existing; the **entry-shape** claims in prose are held against the
  section count the scaffolder writes; and the **heading-level** rules are enforced against the DEPLOY section,
  read out of the document with its line offset so a finding names the line you can find. In a consumer none of
  that runs — the plugin ships no `scripts/lint/` — so there, the document is the only statement of its own
  shape. That is also why the guidance lives inside it.
- The cycle as a portable page, with the seams named:
  [`CONTRIBUTING-portable.md`](../plugins/dkj-policy/CONTRIBUTING-portable.md) — and the
  reason the split exists at all is
  [inbound #566](https://github.com/DaveKJohn/claude-code-specialists/issues/566), from a consumer who tried to
  adopt this page and measured why it could not be done.
- Which specialist owns which kind of change: [`CLAUDE.md`](../CLAUDE.md) and the roster it imports.
