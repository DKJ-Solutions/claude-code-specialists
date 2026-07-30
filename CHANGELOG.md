# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #277 · three reporting inaccuracies in teardown/init (inbound #275) · Fix · 2026-07-30

Three defects measured in the v3.0.0 adoption round (two full `init` → `teardown` cycles in an
*occupied* consumer, July 30, 2026). None broke a run; all three made a report claim something other
than what happened, which is the class the previous round was about.

**1. The preview and the apply run now report the same total.** They differed by two on identical work
— `29 item(s) to remove` against `31 item(s) removed`, reproduced in both cycles — because the
directory prune (`lenses/`, then `specialists/`) sat entirely inside `if ($Apply)`: pruned, listed and
tallied on the apply run, never mentioned in the preview. A dry run is explicitly *the inventory a
reader needs in order to say yes*, so a preview that undercounts its own execution weakens exactly the
property it exists to provide. Both modes now list those directories under `[remove]` off **one code
path**: on a dry run the emptiness is *predicted* (a directory counts as empty when every file still in
it is already on the remove list), which is the same question `-Apply` answers by looking. One label
serves the printed line and the tally, so the list and the number cannot describe an item differently.

**2. The free-standing audit now excludes at line granularity, not only per file.** The 3.0.0 fix
excluded *files* the run is about to delete; the bootstrap's orchestrator note and its `@`-import(s) are
*lines* it deletes inside a `CLAUDE.md` that stays. So a dry run reported `CLAUDE.md:<n> -- name 'Chris'`
as a surviving live reference on the very run that lists that line under `[remove]`, and the audit fell
from 5 live references to 4 after `-Apply` on a consumer that changed nothing in between — over-reporting
by exactly what the run removes, in the mode where a reader is least able to tell. The predicate is
**hoisted and shared** with the section that does the removing (a predicate mirrored by hand in two
places is what produced both instances of the orphaned-note defect), and it matches on **content, not
line numbers**: after `-Apply` every number has shifted, so a number-based exclusion would skip the wrong
lines. The exclusion is stated in the scan line like the file-level one, and it counts **references
excluded rather than lines skipped** — most removed lines carry no reference at all, and counting those
would inflate a notice into a claim.

**3. `specialists-init` no longer documents fewer personas than it places.** `SKILL.md` named three
(Chris `01-01`, Derek `05-05`, Rendall `05-06`) while the bootstrap enumerates `personas/` and places
**four** — `03-02` (Bianca) was missing from the prose. Nothing miscounted: the closing line reported
`4 persona-lens(es) created` honestly and the total was right; the description was simply narrower than
the behaviour, which costs a reader a detour. The doc now says the set is read from the payload, lists
all four, and names the run's own counter as the authority — so it grows on its own when a release adds
a persona.

**Tests (all three, and each verified to fail against the old code — 7 asserts did):**
`teardown.tests.ps1` gains *"the dry run and the apply run count the same items"* (both counts read out
of the real output rather than pinned to today's lens inventory, so the next added specialist does not
break the guard) and *"the audit excludes removed CLAUDE.md LINES"* (a fixture carrying one genuinely
authored `Derek` reference, so "no hits at all" cannot pass it for the wrong reason, plus the
before/after-`-Apply` count that used to drop by one). `bootstrap-drift.tests.ps1` gains a check that
`SKILL.md` names **every** persona id the payload ships and that the run's counter matches that number.

Reported from a consumer via [issue #275](https://github.com/DaveKJohn/davekjohns-workshop/issues/275).

Plugins: specialists

[PR #277](https://github.com/DaveKJohn/davekjohns-workshop/pull/277)

---

### #276 · adoption path: the missing plugin install step (inbound #274) · Fix · 2026-07-30

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
- `QUICKSTART.md` — step 1 is now "enable *and* install", and carries the self-check itself.
- the family `README.md` — step 0 of *Adoption: the bootstrap path*, with the finding and why the
  failure mode is self-camouflaging.
- the root `README.md` — the *Consumption* pointer, which summarised the walkthrough without it.

**Found while fixing this, and fixed along:** the QUICKSTART still described "the two Chris
`@`-imports" in a consumer's `CLAUDE.md`. Since the seam landed that is **one** import pointing at
`.claude/specialists/SPECIALISTS.md`, which in turn imports the body and the lens — the same
doc-claims-other-than-behaviour class as the finding itself, in a file this change was already
correcting.

Reported from a consumer via [issue #274](https://github.com/DaveKJohn/davekjohns-workshop/issues/274).

Plugins: specialists

[PR #276](https://github.com/DaveKJohn/davekjohns-workshop/pull/276)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v3.0.0] - 2026-07-30 — Major

See [releases/development/3.x/3.0.0.md](releases/development/3.x/3.0.0.md) for the full release notes.

---

### [v2.16.0] - 2026-07-30 — Minor

See [releases/development/2.x/2.16.0.md](releases/development/2.x/2.16.0.md) for the full release notes.

---

### [v2.15.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.15.1.md](releases/development/2.x/2.15.1.md) for the full release notes.

---

### [v2.15.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.15.0.md](releases/development/2.x/2.15.0.md) for the full release notes.

---

### [v2.14.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.14.1.md](releases/development/2.x/2.14.1.md) for the full release notes.

---

### [v2.14.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.14.0.md](releases/development/2.x/2.14.0.md) for the full release notes.

---

### [v2.13.3] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.3.md](releases/development/2.x/2.13.3.md) for the full release notes.

---

### [v2.13.2] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.2.md](releases/development/2.x/2.13.2.md) for the full release notes.

---

### [v2.13.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.1.md](releases/development/2.x/2.13.1.md) for the full release notes.

---

### [v2.13.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.13.0.md](releases/development/2.x/2.13.0.md) for the full release notes.

---

### [v2.12.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.12.0.md](releases/development/2.x/2.12.0.md) for the full release notes.

---

### [v2.11.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.11.0.md](releases/development/2.x/2.11.0.md) for the full release notes.

---

### [v2.10.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.10.0.md](releases/development/2.x/2.10.0.md) for the full release notes.

---

### [v2.9.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.9.0.md](releases/development/2.x/2.9.0.md) for the full release notes.

---

### [v2.8.0] - 2026-07-27 — Minor

See [releases/development/2.x/2.8.0.md](releases/development/2.x/2.8.0.md) for the full release notes.

---

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
