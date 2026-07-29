---
name: specialists-init
description: >-
  Bootstrap the Claude Specialists system in a new consuming repo: hook up the orchestrator
  (Chris) via two @-imports in CLAUDE.md (the portable body from the plugin install + his
  lens-only repo lens on the plugin path), put the other main-loop personas (Derek, Rendall) and the
  subagents in place as lens-only scaffolds on the plugin path plus the script-config scaffolds, and
  deliver a governance/safety-hooks proposal.
  Use this when the shared `specialists` plugin is enabled but the conductor and the
  governance layer are still missing ("the workers are there, Chris is not").
---

# specialists-init — the adoption path for a new consumer

The shared `specialists` plugin delivers the **worker subagents** (Sylvester, Tessa, Edith, Victor,
Tycho, …). What a plugin **cannot** do is inject always-on main-loop context or edit a consumer's
`CLAUDE.md`. That is exactly where the gap sits: **Chris** (the orchestrator) is loaded via an
`@`-import at the bottom of the repo `CLAUDE.md`; **Derek** and **Rendall** stand ready as lens-only
personas on the plugin path and are read on demand. This skill sets that up, plus the governance and
safety layer that differs per repo.

## Chicken-and-egg — step 0 is done by the user

This skill lives inside the `specialists` plugin. A plugin skill only becomes available after the
repo has enabled the plugin **and the session has been restarted**. So the skill cannot hook itself
up. Step 0 is therefore manual — verify that the consumer already has this in `.claude/settings.json`:

```jsonc
"extraKnownMarketplaces": {
  "davekjohns-workshop": { "source": { "source": "github", "repo": "DaveKJohn/davekjohns-workshop" } }
},
"enabledPlugins": {
  "specialists@davekjohns-workshop": true
  // plus a domain plugin of choice, e.g. "specialists-shopify@davekjohns-workshop": true
}
```

If that is not there, put it in first, **restart the session**, and then invoke this skill again.
If it is there, continue.

## What the skill does

Run the bundled bootstrap script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/skills/specialists-init/bootstrap.ps1"
```

The script performs only **safe, additive** actions — it never overwrites existing content:

**Where the lenses land — the seam (issue #221).** A **fresh** consumer gets one directory and one
line: lenses flat in `.claude/specialists/lenses/`, everything else behind
`.claude/specialists/SPECIALISTS.md`, and a single `@`-import in `CLAUDE.md`. A consumer that
**already has a lens tree** on the pre-seam plugin path (`.claude/plugins/<family>/<plugin>/`) keeps
writing there — this script never relocates a file the repo owner owns, and splitting the surface
across both paths would be worse than either. Migrating is your act, four steps, described in the
[family README](../../../README.md#the-seam-specified). Every reader accepts both layouts.

1. **Persona lenses (lens-only)** — for each main-loop persona (Chris `01-01`, Derek `05-05`,
   Rendall `05-06`), puts a `*-extension.md` in place in the lens directory chosen above, only if it
   is not already there. The lens carries **no body copy** — only the repo-lens slot; the portable
   body comes via an `@`-import directly from the plugin install.
2. **Empty lens scaffolds** — for each subagent of the **enabled** plugin(s), puts an empty
   `VUL-IN` scaffold in place in that same directory (never overwriting). This makes it
   visible from the first install where the repo-specific tasks per specialist are to be filled in;
   the agent-def automatically reads the lens along once it is filled. In the seam the directory is
   **flat**: `<group>-<id>` is unique family-wide, so several enabled plugins share one `lenses/`.
3. **Script-config scaffolds (#86)** — puts `scripts/repo-config.ps1` and `scripts/lib/branch-info.ps1`
   in place as `VUL-IN` scaffolds (never overwriting, with an **empty** branch table — the taxonomy
   differs per repo). Without these two files, the shared workflow skills `open-pr`/`fold` break on
   a clean consumer over a missing file.
4. **The import(s)** — ensures `CLAUDE.md` carries the orchestrator at the bottom. In the seam that is
   **one** line, `` `@.claude/specialists/SPECIALISTS.md` ``, and that file carries the body import, the
   lens import and this repo's roster slot; on the pre-seam path it stays the two imports it always was
   (portable body + repo lens). Creates a minimal `CLAUDE.md` scaffold if it is missing.
5. **Settings proposal** — writes `.claude/settings.suggested.jsonc` with the recommended
   `permissions.deny` + a hooks **stub**. It does **not** touch `settings.json`: a JSON merge is
   repo-specific and risky, so that judgment stays with you.
6. **Register proposal** — prints a paste-ready **connector manifest** for the *workshop* repo: the
   repo name derived from the git remote, plus the lens inventory per plugin (personas included).
   `visibility` and `localCheckout` stay `VUL-IN`, because this script cannot know them — it has no
   idea where the workshop checkout sits relative to this repo, and a guessed path is exactly what
   the register's marker check exists to prevent. Printed, never written: the register lives in the
   workshop and deliberately never receives cross-repo writes.

## Finishing up (manual — the judgment-call steps)

After the script:

1. **Fill in the repo lens.** Every `*-extension.md` put in place on the plugin path has an
   `## Specific to this repo (VUL-IN)` slot. Replace it with the repo-specific context: the roster/
   routing (Chris), the branch/PR conventions (Derek), the release mechanics (Rendall). The portable
   body lives in the plugin install (not in the lens) and is loaded along via the `@`-import — the
   marketplace's drift lint guards the lenses against the canonical source.
2. **Adopt the settings.** Copy what fits from `.claude/settings.suggested.jsonc` into
   `settings.json` (or `settings.local.json`), adapt the hooks stub to real repo scripts (or leave
   them out), and then remove the proposal file.
3. **Write the governance.** The `CLAUDE.md` scaffold is bare — fill in the safety rules and the
   working method of this repo (see an existing consumer as a model).
4. **Enable auto-delete of merged branches (#163).** Turn on the GitHub repo setting
   *"Automatically delete head branches"* (`deleteBranchOnMerge: true`) — via the repo settings UI
   or `gh api -X PATCH repos/<owner>/<repo> -F delete_branch_on_merge=true`. That makes remote
   branch cleanup automatic on merge; the local-clone cleanup (`git fetch --prune` +
   `git branch -d <branch>`) stays the fixed closing step of the fold (see the `fold-changelog`
   skill).
5. **Restart the session.** The new `@`-import and config only become active on a **restart** of
   Claude Code.
6. **Register the repo in the workshop.** Take the printed manifest block, fill in the two `VUL-IN`
   fields, and land it as `connectors/<repo>.json` in the marketplace repo via that repo's normal
   branch + PR flow. Skip this and the workshop stays blind to this repo: no plugin-version check, no
   lens-inventory check, no agent-def drift check. Until it is registered, this repo's own session
   start says so — `connector-sessioncheck` surfaces an `[UNREGISTERED]` line next to its verdict.

## Important

- **Do not overwrite.** If a `*-extension.md`, a scaffold, or the `@`-imports already exist, the
  script leaves them alone. The skill is safe to invoke repeatedly.
- **The personas are templates, not subagents.** They deliberately have no agent-def; they run in the
  main loop. Do not modify the portable body locally — a body change lands first in the marketplace
  (`personas/`), not in a consumer (just like a shared agent-def).
