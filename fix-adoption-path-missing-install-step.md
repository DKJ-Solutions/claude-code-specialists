### adoption path: the missing plugin install step (inbound #274) · Fix · 2026-07-30

**The documented adoption path did not install the plugin, and the failure was silent.** Step 0 told
a new consumer to put `extraKnownMarketplaces` + `enabledPlugins` in `.claude/settings.json`, restart,
and invoke `specialists-init`. Measured in a consumer during the v3.0.0 adoption round (July 30, 2026):
those two keys plus a restart produce **no install**. A plugin install is **project-scoped** —
`~/.claude/plugins/installed_plugins.json` keys every record by `projectPath` — so an explicit
`claude plugin install <plugin>@<marketplace>`, run per plugin from the consumer's root, is required
before `claude plugin list` reports either plugin as `enabled`.

Worse than a typo, because of *how* it fails: a consumer that follows the old path lands in a session
where the skill is absent **and** the session-start hooks are absent, and "no hooks because the plugin
is not loaded" prints exactly the same nothing as "no hooks because everything is in order". No signal
distinguishes them, and the documentation is the only thing the reader has — until the plugin loads,
the skill that would say otherwise does not exist.

Corrected in all four places a new consumer can land, each stating the **order** (enable → install
per plugin from the repo root → restart → verify) plus the one-command self-check that turns the
silent failure into a visible one (`claude plugin list` must show every plugin from `enabledPlugins`
as `enabled`), including the caveat that the list can hold several records per repo:

- `specialists/skills/specialists-init/SKILL.md` — step 0 rewritten as three named acts (0a/0b/0c);
  the frontmatter now says "installed and enabled".
- `QUICKSTART.md` — step 1 is now "enable *and* install"; step 3's check made explicit.
- the family `README.md` — step 0 of *Adoption: the bootstrap path*, with the finding and why the
  failure mode is self-camouflaging.
- the root `README.md` — the *Consumption* pointer, which summarised the walkthrough without it.

**Found while fixing this, and fixed along:** the QUICKSTART still described "the two Chris
`@`-imports" in a consumer's `CLAUDE.md`. Since the seam landed that is **one** import pointing at
`.claude/specialists/SPECIALISTS.md`, which in turn imports the body and the lens — the same
doc-claims-other-than-behaviour class as the finding itself, in a file this change was already
correcting.

Reported from a consumer via [issue #274](https://github.com/DaveKJohn/davekjohns-workshop/issues/274).
