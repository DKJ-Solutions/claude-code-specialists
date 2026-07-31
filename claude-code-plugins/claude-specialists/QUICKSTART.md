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

**Step 1 — enable *and* install the plugins.** In your repo's `.claude/settings.json`, set the
marketplace source and the plugins you want (always the core; a domain group only if your repo has
that domain):

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
and caches it by itself. **Those keys do not install anything, though** — an install is *per repo*,
so run one command per plugin you listed, from the root of your repo, preceded once by a refresh of
that cached clone:

```powershell
claude plugin marketplace update davekjohns-workshop                     # 1. refresh the cache first
claude plugin install specialists@davekjohns-workshop --scope project    # 2. then install, per plugin
# and line 2 again for each domain group you enabled
```

**Line 1 is not only an update-time step, and this is where the evidence for it came from.** Without
it, the install happily gives you the **previous** version and reports `✔ Successfully installed` —
measured on July 30, 2026 with a fresh `install`, not an `update` (the full account is under
[Staying up to date](#staying-up-to-date)). A stale cache produces a green line and a plausible
version number, so the only symptom is a session quietly missing whatever the release added. That is
easily mistaken for the restart problem described under
[Staying up to date](#staying-up-to-date) — a new skill needing a session restart — and is a
different cause with a different fix.

**Keep `--scope project` on that line.** `claude plugin install` defaults to `--scope user`, which
installs machine-wide and writes no `projectPath` at all — so you would get the one thing the
sentence above says this step is for, wrong, without any error. Same flag on the way back out:
`claude plugin update` has the same default and simply fails on a project-scoped install (see
[Staying up to date](#staying-up-to-date)).

**Then restart your Claude Code session** and check that it worked — but **not with `claude plugin
list`**. That command is not repo-scoped: it reports install records beyond your repo, so it can show
a plugin as `enabled` in a repo that has no install at all. Check the record for *your* repo, from
its root:

```powershell
$root = (Get-Location).Path
(Get-Content "$env:USERPROFILE\.claude\plugins\installed_plugins.json" -Raw | ConvertFrom-Json).plugins.PSObject.Properties |
  ForEach-Object { $n = $_.Name; $_.Value | Where-Object { $_.projectPath -eq $root } |
    ForEach-Object { "$n -> $($_.scope) $($_.version)" } }
```

One `project` line per plugin you listed is what you want; empty output means nothing was installed
here. Do run it — if the install did not happen, the skill from step 2 and the session hooks are
simply absent, and that looks exactly like a session where everything is fine.

**Step 2 — run the bootstrap skill.** In the new session, invoke `specialists-init`. It sets up —
purely additively, without overwriting anything — the **lens-only** persona lenses (including
Chris) + an empty repo-lens scaffold per specialist in **the seam**
(`.claude/specialists/lenses/`), one `@`-import at the bottom of your `CLAUDE.md` pointing at that
seam (which in turn imports Chris's portable body from the plugin install + his repo lens), and a
proposal for safety settings (`settings.suggested.jsonc`, for your own
review). The details of this path are in the
[family README › Adoption](README.md#adoption-the-bootstrap-path) — which counts the steps there
as "step 0" (enabling + installing, above) and "step 1" (the skill).

**Step 3 — restart and verify.** Start again and check that Chris takes the floor (every turn opens
with a sender header such as `🧭 Chris — intake & routing`). Then, at your own pace, fill in the
repo lenses in the seam (`.claude/specialists/lenses/`): that is where you tell each specialist what it serves in your repo.
The worker specialists can be invoked directly as `@specialists:<name>`.

## Staying up to date

Updates reach you via **releases**, and getting one takes **two** commands, from your repo's root:

```powershell
claude plugin marketplace update davekjohns-workshop          # 1. refresh the marketplace cache
claude plugin update specialists@davekjohns-workshop --scope project   # 2. then update, per plugin
```

**Do not skip the first one — without it the second happily installs the previous version and reports
success.** Measured on July 30, 2026, minutes after `v3.0.2` was tagged and pushed: the cached
marketplace clone still sat on the commit from *before* the release, so a fresh
`claude plugin install … --scope project` in a repo produced **3.0.1** and said `✔ Successfully
installed`. Nothing about that output hints the version is stale. After
`claude plugin marketplace update`, the same plugin moved `3.0.1 -> 3.0.2` in one step. There is a
refresh mechanism (the command reports `Refreshing marketplace cache (timeout: 120s)`), so a cache
does not stay stale forever; on what schedule it refreshes by itself was not established, which is
exactly why the explicit command belongs in the procedure rather than a hope that it has caught up.

So a version number is one of **two** gates. `claude plugin update` compares version numbers only —
but it compares them against *its cached copy of the marketplace*, not against the workshop. You get
a change once the workshop has cut a new version **and** your cache has seen it.

**The scope flag on the second command is not optional either.** Without it the command defaults to
user scope and fails on a project-scoped install with *"Plugin `specialists` is not installed at
scope user"* — literally true, and easy to misread as "not installed at all" on a machine where it
is. Do not answer that by re-running the install: a scopeless install adds a **second, machine-wide
record** beside the project one. Each plugin carries its own
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
  [issue template](../../.github/ISSUE_TEMPLATE/inbound-improvement.md) is ready for that. The
  workshop processes it through its own chain, and the improvement comes back to all consumers via
  a release.
- **Repo-specific additions** belong in your own repo lenses in the seam
  (`.claude/specialists/lenses/`) — those are yours and do not travel with the plugin.
