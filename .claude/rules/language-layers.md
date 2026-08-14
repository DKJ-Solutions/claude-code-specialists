---
paths:
  - "scripts/**"
  - "plugins/**/scripts/**"
  - "plugins/**/hooks/**"
  - ".github/**"
  - "releases/**"
  - "CHANGELOG.md"
---

# Language — which layers are English, and the exceptions

The norm itself lives in [`CLAUDE.md`](../../CLAUDE.md#language) because it governs every turn. **This
file is the per-layer detail**, path-scoped so it loads when you actually touch one of those layers
rather than in every session.

Two consequences of that scoping, both deliberate:

- It is **lost after a `/compact`** until a matching file is read again — documented behaviour for
  `paths:`-scoped rules. That is acceptable here precisely because the content only matters while you
  are editing one of these files, and editing one means reading one, which reloads this rule. Anything
  that must hold *regardless* of which files a turn touches does **not** belong here; the session-reply
  language rule is the example, and it stayed in `CLAUDE.md` for exactly this reason.
- Dropping the `paths:` field would make it load unconditionally with the same priority as
  `CLAUDE.md` — which would restore compaction-survival and **save nothing**. The saving is the
  scoping.

The list below is meant to be exhaustive. If it ever undercounts a layer, that is a gap to close on
discovery — as an earlier pass did for `.github/workflows/ci.yml` — not a quiet exception to the norm.

- **The script layer is fully in scope.** Every `.ps1` file under `scripts/**` (and the shared
  mirrors under `plugins/*/scripts/`), the hooks, the tests, and
  `.github/**` (the workflows, the issue templates, and the PR template) are English throughout —
  comments, docstrings, console output (`Write-Host`/`Write-Error`/`Write-Warning`/`throw` text), and
  workflow/template body text. `ci.yml` was translated on July 26, 2026, closing the gap a
  documentation audit found between this claim and the actual repo state — a CI workflow, matching none
  of the exceptions below, had simply been missed. New scripts and edits are written in English; no new
  non-English text is added anywhere in scope.
- **Script-*generated* document content is in scope too.** The `CHANGELOG.md` sections, release notes,
  that `scripts/lib/release-lib.ps1` builds are English going forward (it built per-plugin CHANGELOGs
  too until August 8, 2026, when those files were retired): its
  document-generating template strings (the category labels, the reference line, the
  `## Releases`/plugin-CHANGELOG intro texts, the date label) were translated in that pass.
  `CHANGELOG.md` itself is now fully English (its intro paragraphs and every `## Releases` reference
  line were translated on July 22, 2026 — Dave's decision). The archived `releases/development/*.md`
  notes stay in their original language, so older ones remain Dutch.
- **Technical identifiers/flags** keep their original form — the scaffold marker `VUL-IN` (used across
  the plugin's scaffold scripts, e.g. `bootstrap.ps1`, `new-branch.ps1`) is one example; Dave's
  explicit decision. The job id **`lint-en-tests`** in [`ci.yml`](../../.github/workflows/ci.yml) is a
  second, higher-stakes one: it is the exact name GitHub's `main` ruleset requires as a passing status
  check before any PR can merge. This is not a forgotten translation — renaming it would silently break
  that binding, and every future PR would sit unmergeable (`BLOCKED`, waiting on a check that no longer
  exists) until someone traced it back to the rename, a failure that would surface only at the next PR
  rather than at the moment of the change. It stays Dutch-shaped on purpose.
- **Legacy back-compat markers** deliberately keep recognizing existing, not-yet-migrated consumer
  content and are not translation debt: the slot heading `## Specific to this repo` alongside its legacy
  predecessor in the drift-check (`scripts/lint/check-consumer-drift.ps1`) and the bootstrap templates,
  and the `[ERROR]` marker alongside its legacy predecessor in the connector session hook
  (`connector-sessioncheck.ps1`).
- **History** — the archived per-release notes under `releases/development/*.md` are this repo's narrow
  exception to the norm and may remain in their original language (older ones are Dutch).
  `CHANGELOG.md` and the release-history README (now `workflow-davekjohn/releases/README.md`) are themselves fully English (translated July 22, 2026,
  Dave's decision), so the exception no longer covers them.

Decision by Dave, July 20, 2026 (repo-wide English) — the decision that in turn prompted the
system-wide norm — sharpened July 21, 2026 to make explicit that it covers the script layer and
script-generated content, not only docs/manuals/agent-defs, and sharpened again July 26, 2026 to make
explicit that `.github/**` is covered too, after a documentation audit found `ci.yml` had been missed.

**A verification lesson from that same audit, worth keeping even though its concrete exception has since
closed:** a name that looks non-English is not automatically translation debt. Check first whether it is
the live name of an *external* object — one this repo does not define and cannot rename unilaterally
from a documentation pass. If it is, the doc may cite that name as-is (citing reality is not a language
violation), and the fix runs in one direction only: the object gets renamed first, by whoever owns that
object's security binding, and the doc follows — never the reverse. This section once cited the repo
ruleset enforcing the CI gate under that reasoning, as `main-ci-poort` (verified via the GitHub API
rather than assumed). Dave has since renamed it to `main-ci-gate` (July 26, 2026); a field-by-field API
re-check confirmed only the name changed — required check, enforcement, target branch, rules, and bypass
actors are all unchanged.
