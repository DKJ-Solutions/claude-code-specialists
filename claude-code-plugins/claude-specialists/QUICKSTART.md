# Quickstart — how to connect your repo

This page is for those who did **not** build the Claude Specialists system: a colleague with a repo
of their own who wants to work with the specialists team. Everything below is the common thread —
the deeper explanation sits behind the links and is deliberately not repeated here.

## What you get

Instead of one generic Claude, you work with a **team of specialized Claudes under one Chief of
Staff (Chris)**: every assignment is classified and delivered to the specialist with the right
playbook — a DevOps engineer for branches and PRs, a technical writer for docs, a copy editor
and code/security reviewers for the independent final pass before a PR or merge. Your repo stays in
charge: the governance (your `CLAUDE.md`, your safety rules) remains yours; the plugins only supply
the team and its playbooks.

The system consists of **four plugins**: the repo-neutral core `specialists` (group 1 — always
enable it) and three optional domain groups. Which specialists live in which plugin and who they are
meant for is covered in the [family README](README.md).

## Connecting in three steps

**Step 1 — enable the plugins.** In your repo's `.claude/settings.json`, set the marketplace source
and the plugins you want (always the core; a domain group only if your repo has that domain):

```jsonc
// .claude/settings.json (your repo)
"extraKnownMarketplaces": {
  "davekjohns-workshop": {
    "source": { "source": "github", "repo": "DaveKJohn/davekjohns-workshop" }
  }
},
"enabledPlugins": {
  "specialists@davekjohns-workshop": true
}
```

This repo is public, so the source can be read without GitHub authentication; Claude Code clones
and caches it by itself. **Then restart your Claude Code session** — only then are the plugins (and
the skill from step 2) available.

**Step 2 — run the bootstrap skill.** In the new session, invoke `specialists-init`. It sets up —
purely additively, without overwriting anything — the **lens-only** persona lenses (including
Chris) + an empty repo-lens scaffold per specialist on the **plugin path**
(`.claude/plugins/claude-specialists/<plugin>/`), the two Chris `@`-imports in your `CLAUDE.md`
(his portable body from the plugin install + his repo lens), and a proposal for safety settings
(`settings.suggested.jsonc`, for your own
review). The details of this path are in the
[family README › Adoption](README.md#adoption-the-bootstrap-path) — which counts the steps there
as "step 0" (the enabling above) and "step 1" (the skill).

**Step 3 — restart and verify.** Start again and check that Chris takes the floor (every turn opens
with a sender header such as `🧭 Chris — intake & routing`). Then, at your own pace, fill in the
repo lenses on the plugin path (`.claude/plugins/claude-specialists/<plugin>/`): that is where you tell each specialist what it serves in your repo.
The worker specialists can be invoked directly as `@specialists:<name>`.

## Staying up to date

Updates reach you via **releases**: `claude plugin update` compares version numbers only, so you
get changes as soon as the workshop has cut a new version — not before. Each plugin carries its own
`CHANGELOG.md` that travels with the plugin cache and describes per release what changed for that
plugin; the full history lives in the workshop itself
([`CHANGELOG.md`](../../CHANGELOG.md) and [`releases/`](../../releases/README.md)). Each plugin
folder also carries a `RELEASE.md` card next to its `CHANGELOG.md` — open it in your plugin cache
after an update to see, at a glance, exactly which release you're now on.

When an update adds a **new specialist**, your repo's roster (the specialists table in your
`CLAUDE.md`) and its lenses don't update themselves. The `roster-sessioncheck` SessionStart hook
flags at session start any enabled agent that is missing from your roster **or** has no repo-lens;
run the `sync-roster` skill to stage the catch-up — it creates the missing lens scaffold and
proposes a roster row for you to review. It never edits your `CLAUDE.md` or commits: you place the
change on a branch under your own governance. You can also run
`scripts/sync/check-roster-sync.ps1` yourself for the full report.

When an update adds a **new skill**, restart your Claude Code session before you go looking for it.
`/reload-plugins` and `/reload-skills` only reload the skill set that is already loaded, not a new
skill file from an updated plugin version. So a slash command that did not exist in the previous
release stays absent until you restart — `claude plugin update`'s own `Restart to apply changes.` is
literally true here. Don't trust the skill counter those two commands print as evidence either way:
it excludes any skill with `disable-model-invocation: true`. Several of `specialists`' own skills
(`cut-release`, `fold-changelog`, `open-pr`, `park`) are slash-only for exactly that reason, so an
unchanged count, or even `0 skills`, proves nothing about whether a new skill has actually landed.
The only reliable check is the slash list itself.

## Reporting back or improving something

- **An improvement to the shared core** (an agent def, playbook, persona, or skill): don't
  rework it locally, but report it as an issue on this repo with the label `inbound` — an
  [issue template](../../.github/ISSUE_TEMPLATE/inbound-verbeterpunt.md) is ready for that. The
  workshop processes it through its own chain, and the improvement comes back to all consumers via
  a release.
- **Repo-specific additions** belong in your own repo lenses on the plugin path
  (`.claude/plugins/claude-specialists/<plugin>/`) — those are yours and do not travel with the plugin.
