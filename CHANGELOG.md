# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #199 · A rule that stops a subagent hitting a wall belongs in the agent def too · Docs · 2026-07-27

Two lessons from the same session, both about documentation that was quietly wrong rather than
missing.

**1. The manual-is-leading rule has an exception (Specialists handbook).** The handbook says *"the
manual is leading; the agent def is the executable abbreviation — you change a craft rule in the
manual."* That division assumes the subagent consults its manual at the moment it matters, which
holds for a rule about *what the craft is*: it notices the gap and looks it up. It does not hold for
a rule about *what it will otherwise attempt and fail at* — there it does not know anything is
missing, so it never becomes "in doubt", never opens the manual, and hits the wall instead. Such a
rule now goes in the agent def in compact form **as well as** in the manual in full.

Sylvester #15 (PR #198) is the worked example, recorded with it: his working method opened with
"read before writing, always merge", silently assuming he can write to a permissions file at all.
He cannot — the auto-mode classifier blocks it by design — and he ran into that twice in two
consecutive pieces of work, improvising a recovery mid-task both times. **Fixing only the manual
would have produced a third collision**, which is exactly why #198 touched both files.

**2. Nobody was cleaning up merged branches, and both docs said otherwise.** Seven merged branches
had piled up on the remote unnoticed. Cause: `deleteBranchOnMerge` was **off**, while
`ship-pr.ps1` merges with a plain `gh pr merge --merge` (no `--delete-branch`). So no mechanism was
in force — and the two docs each named a *different* one, which is why the gap survived review:
Derek's persona credited the repo setting, his repo lens credited the `--delete-branch` flag.
Neither claim was true, and **nothing ever errored** — merged branches simply accumulate until
someone reads the branch list.

Fixed at the root: `deleteBranchOnMerge` is now on (Dave's decision, July 27, 2026), which covers
every merge route including the GitHub UI and other machines — not just the script path. Both docs
now describe what actually happens, and both carry the trap that hid this: **`git fetch --prune`
only drops tracking refs for branches already gone from the remote**, so a clean local branch list
is no evidence whatsoever that the remote is clean. Verifying means `git ls-remote --heads origin`.

Plugins: specialists

[PR #199](https://github.com/DaveKJohn/davekjohns-workshop/pull/199)

---

### #198 · Two permission rules for Sylvester: not agent-editable, never version-pinned · Docs · 2026-07-27

Processes [#196](https://github.com/DaveKJohn/davekjohns-workshop/issues/196) (inbound from
life-hub). Two additions to Sylvester #15, both about permission rules for the plugin's own scripts,
and both holding for every consuming repo — which is why life-hub deliberately placed no bridging
note in its own lens.

**1. A permissions file is never agent-editable.** The existing rule *"Read before write, always
merge — never overwrite"* silently assumed Sylvester can write to `settings.json` /
`settings.local.json`. He cannot: the auto-mode classifier refuses every write, whatever the tool
(both an Edit and a scripted rewrite were blocked). That is correct behaviour — an agent that can
widen its own permissions has stopped being a gate — but because the manual never said so,
Sylvester walked into it, got blocked, and had to improvise a recovery mid-task. Twice in two
consecutive pieces of work. The rule now says: don't attempt the edit, hand over a paste-ready block
(exact lines out, exact lines in) plus the route, then verify by *reading*.

**2. Never pin a plugin-script permission to a version.** Plugin scripts live under
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/...`, so a rule containing the version
number dies at the next release — and it fails as a permission *prompt*, not an error, so it can sit
broken for releases unnoticed. In life-hub two rules had been pinned to `1.18.0` and `2.5.0` while
the plugin had moved to `2.7.3`, which made every `new-branch` and `park` run prompt. **That
friction was actively holding back adoption of the very workflow the plugin had just centralised**
— the skills worked, using them was merely annoying enough to avoid. The rule prescribes the prefix
form, for both the `Bash(...)` and `PowerShell(...)` routes.

**Written into the agent-def as well as the manual, and that is the point.** The subagent reads its
agent-def every run but the manual only "if unsure", so a rule that lives only in the manual does
not stop Sylvester from walking into the wall. Working method step 2 in `agents/05-15-agent.md` held
the exact misconception; it now has both rules beside it in compact form, with the full reasoning in
`manuals/05-15-manual.md`. The `fewer-permission-prompts` mention under "Sylvester is lazy" carries
a warning too, since the skill derives its proposals from concrete transcript paths and therefore
generates precisely the pinned form — the trap is built into the tooling, not a one-off slip.

**Checked in this repo:** no `plugins/cache` rules in its settings at all — the workshop runs its
scripts locally from `scripts/`, not from the plugin cache, so it never had the dead-rule problem.
Nothing to repair here; this is purely a core fix for the consumers.

Plugins: specialists

[PR #198](https://github.com/DaveKJohn/davekjohns-workshop/pull/198)

---

### #197 · Relax the PR rule: wait only for visible or irreversible work · Docs · 2026-07-27

The rule that a PR only opens on Dave's explicit word was written for a case that no longer occurs:
Dave wanted to look at a frontend change with his own eyes before it went in. In practice the work
here has been tooling, config, dossiers, and agent defs for a long time — none of which he can
meaningfully assess in a few seconds — so nine times out of ten he was rubber-stamping a merge
button that added nothing. **The checkpoint was costing a round trip and buying no safety.**

**The new test is one question: does Dave's own look add something the gates cannot?** Not
"frontend versus backend" — this very change is backend, and it is exactly the kind he *does* want
to see. What matters is whether an automated gate can prove the change is sound.

- **Default — no waiting.** Once a branch is finished, committed, and the gates are green, opening →
  merging → folding runs in one motion, without asking. Scripts, tests, config, manifests, docs,
  agent defs and manuals, the changelog, and research all fall here: the lint gate, the test gate,
  and CI prove them, and anything that slips through is one revert PR away.
- **Exception — stop and report.** Work with a **visible result** (a frontend, styling, rendered
  output, an artifact — no gate proves that something *looks* right) and work that is
  **irreversible or outward-facing** (a release, version bump, tag, repo settings/rulesets,
  publishing outside the PR flow).
- **Dave keeps the wheel in both directions.** He can pull a specific job under the exception when
  he assigns it ("this one I want to see first"), and an explicit PR command still counts as
  approval for the whole movement, so a waiting branch resumes in one move.

The reasoning worth keeping: **substantive approval is given in the conversation before the work is
built, not at the merge button afterwards.** That is why the button is only a checkpoint where it
genuinely buys something.

**Carried through both layers in one pass**, because a half-applied governance rule contradicts
itself. Portable (travels to the consuming repos via a release): the constitution in `CLAUDE.md`
(the permission list plus the "never directly on the main branch" block), Derek's persona
`05-05-persona.md` (his responsibilities and his hard rules), Chris's persona `01-01-persona.md`
(the PR step is no longer automatically a waiting point), the `open-pr` skill (frontmatter
description plus the governance note), the `ship-pr.ps1` docstring, and the inbound-route chain in
the connectors README. Repo lens: Chris's gatekeepers and all four chain descriptions in
`01-01-extension.md`, Derek's branch hygiene in `05-05-extension.md`, and step 4 of the workflow in
`CONTRIBUTING.md`.

**Deliberately left alone:** the `park` and `new-branch` skills say "opens no PR", but that is a
statement about those skills' scope, not an approval rule — unchanged. And the release/version bump
stays firmly on Dave's explicit request; this relaxation touches the merge, never the release.

Decision by Dave, July 27, 2026.

Plugins: specialists

[PR #197](https://github.com/DaveKJohn/davekjohns-workshop/pull/197)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.7.3] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.3.md](releases/development/2.x/2.7.3.md) for the full release notes.

---

### [v2.7.2] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.2.md](releases/development/2.x/2.7.2.md) for the full release notes.

---

### [v2.7.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.1.md](releases/development/2.x/2.7.1.md) for the full release notes.

---

### [v2.7.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.7.0.md](releases/development/2.x/2.7.0.md) for the full release notes.

---

### [v2.6.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.6.1.md](releases/development/2.x/2.6.1.md) for the full release notes.

---

### [v2.6.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.6.0.md](releases/development/2.x/2.6.0.md) for the full release notes.

---

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
