# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #341 · QUICKSTART entry path: prerequisites, the settings fragment, and the first command · Docs · 2026-08-01

The first four findings of test round v10 (#340), all of them on the stretch a consumer walks *before*
the adoption path begins. v10 was the first round run on a **virgin Windows user profile**, which is why
none of this was findable earlier: on an occupied machine every prerequisite below was satisfied years
ago.

- **A `Before you start` section, which the QUICKSTART did not have** (#334). Claude Code installed and
  `claude` actually running (pointing at Anthropic's own [setup
  documentation](https://code.claude.com/docs/en/setup) rather than an install command that would go
  stale here), signed in, and on Windows raising the execution policy — a fresh profile defaults to
  `Restricted`, which blocks every `.ps1` **including `claude.ps1` itself** on an npm install, so this
  page's own first command failed with a `PSSecurityException`. The `PATH`/full-restart symptom is
  recorded as context rather than as a defect, because it is partly an artefact of the install route that
  measurement took.
- **The first executable command was a dead end, and now it is not** (#329). The marketplace is
  registered by a **session start**, not by writing `extraKnownMarketplaces` — measured in three states,
  and the CLI's own error (`Marketplace 'davekjohns-workshop' not found. Available marketplaces:
  claude-plugins-official`) reads as a typo rather than as a missing step. Step 1 now restarts first, with
  `claude plugin marketplace add <source> --scope project` as the no-restart alternative. That command
  gets its own caveats because it breaks the page's pattern twice: it takes a **source** where everything
  else uses the marketplace *name*, and it defaults to `--scope user` — which would rebuild #279 in a
  fourth command. Its `--scope project` is flagged as **documented rather than measured** (from the CLI
  `--help`; #329's measurement was taken at the default scope).
- **Step 1's fragment now parses when pasted, and `.claude` no longer means two things silently**
  (#335). The `jsonc` block with a comment and no outer braces is a complete `json` file, with the
  merge case named for readers who already have a `settings.json`. The repo-level `.claude/` is
  identified as a directory to **create**, and a blockquote separates it from the machine-level
  `~/.claude/` the verification query reads — one consumer read the former as something still to be
  *installed*.
- **Reaching the documents at all** (#338). A pointer to the Quickstart and UNINSTALL.md at the **top**
  of the root README, where a reader handed only the repository stands, instead of two-thirds down under
  `## Consumption`. The `specialists-teardown` skill now names its own missing half: the machine side of
  leaving lives in `UNINSTALL.md`, which ships in the marketplace clone and not in the payload, and was
  reached in the measurement **only by grepping blindly**. And a warning that an agent pointed at this
  page may not read it: `WebFetch` refused a verbatim request and then returned a summary that
  understated the document's size and **invented an enumeration for Step 2** that the page does not
  contain.

**The act count moved from five to six, in all three places at once.** Adding the registering restart made
the `enable → refresh → install → restart → verify` line wrong — the exact cross-document count that #297
and #305 exist to keep aligned, asserted in the QUICKSTART, the family README and `specialists-init`'s
step 0. It is now `enable → restart → refresh → install → restart → verify` in all three, with
`specialists-init`'s letters absorbing it (`0a` is two acts). Folding the restart into act 1 would have
kept the number at five and was rejected deliberately: being folded into another act is what kept this
step unwritten while it was already required. Verified with the emphasis-tolerant sweep #305 prescribes —
the remaining `five steps` hits all belong to the **migration** path (steps 0–4), a different procedure.

**One correction pulled in from outside this branch's four issues.** The bold claim *"Those keys do not
install anything, though"* sits in the exact paragraph #329 rewrites, and #327 falsifies it: on a virgin
profile with the marketplace registered, a single session start wrote a full project-scoped install
record, indistinguishable from the one the documented command produces. Leaving a measured-false sentence
standing inside a paragraph being rewritten was not defensible, so it is corrected here — stating what was
measured, that the session doing the writing still loads nothing itself, and that whether this makes Step
1's two commands redundant is **untested end to end**. That last question needs one round on a fresh
profile and stays open.

Plugins: specialists

[PR #341](https://github.com/DaveKJohn/davekjohns-workshop/pull/341)

---

### #321 · An UNINSTALL document beside the QUICKSTART · Docs · 2026-08-01

**The Quickstart has had no counterpart since the day the reversibility requirement was set.** Adoption
had to be reversible *"at any moment"* (Dave, July 29, 2026), and the machinery for it exists — the
`specialists-teardown` skill, measured across five adoption rounds. What did not exist is the page a
consumer reads. The removal was documented only inside a 452-line skill written for the people who
maintain it, and split across two more places: the machine-side half lived in the Quickstart's *Staying
up to date* section, under a heading nobody looking to leave would open.

[`UNINSTALL.md`](claude-code-plugins/claude-specialists/UNINSTALL.md) is that page — the mirror of the
Quickstart, four steps, same reader. **Its organising claim is that there are two removals, not one:**
out of your repo (the seam, the import, the scaffolds — the skill) and off your machine (the record, the
keys, the registration, the cache). Confusing them is the ordinary failure: a repo teardown leaves the
plugin loading, a plugin uninstall leaves a repo full of lenses and a broken import.

**And the order between them is the one irreversible mistake in the whole procedure.** The teardown skill
*ships inside the plugin*. Uninstall first and the skill goes with it, leaving a repo full of generated
files and no tool that can still tell which of them it wrote — the classification lives in the skill, not
in the files. Same class of trap, one step later: `-VendorScripts` has to be used while the plugin is
still installed, or a consumer that built on the shared scripts loses its daily git workflow.

## Two things measured while writing it, both of which the docs had wrong or missing

**1. The Quickstart said the CLI does not name `local`. It does.** The sentence read *"a third scope the
CLI's own flag list does not mention"*. Re-measured August 1, 2026 on CLI `2.1.220` — the same version
[#315](https://github.com/DaveKJohn/davekjohns-workshop/issues/315) was measured on: `install`,
`uninstall` and `disable` each print *"user, project, or local"* in their own `--help`, and `update`
prints a **fourth**, `managed`. The finding underneath was always right — a reader who met a `local`
record had nothing in this family to look it up in — but the sentence blamed the wrong party. Corrected
to say what is true: the flag list was never the gap, **these pages were**.

**2. Three machine-level locations this family had never named.** Taken from a machine that has run it,
not estimated: `~/.claude/plugins/data/<plugin>-<marketplace>/` (a persistent data directory that
`uninstall` deletes unless `--keep-data`), `~/.claude/plugins/cache/<marketplace>/` (the unpacked
payload, beside the git clone under `marketplaces/`), and `~/.claude/plugins/known_marketplaces.json`
(the registration, removed by `claude plugin marketplace remove`). `git grep` over the whole payload:
**no hits for any of them.** So "get this machine back to a clean state" was not answerable from the
family's own documents. It is now, including the honest gap — whether `marketplace remove` also deletes
the two cache paths from disk is *not* established, and the page says to check rather than assume.

**One trap that follows from #314 and is worth its own line:** an enable key alone is enough for a
session start to write a missing install record by itself. So a machine where `enabledPlugins` still
names the plugin **heals its own uninstall**, silently, on the next session. Remove the keys before
re-checking the record, or the verification keeps finding a record with a fresh timestamp and nothing to
explain it.

## The gate could not see the new page, and that is the part that got closed properly

`UNINSTALL.md` landed in the family directory and **no check looked at it**: not the dead-link scan, not
check 11 (printed lifecycle commands), not check 12 (the install-record query) — all three take their
scan set from `$linkFiles`, and the family's entry there was a hardcoded list of two names,
`'README.md', 'QUICKSTART.md'`. A brand-new consumer-facing page, printing exactly the class of command
those two checks exist to police, was invisible on the run that introduced it.

**Adding a third name would have repeated the fix rather than closed the class**, and the evidence is
that the list itself came from [#103](https://github.com/DaveKJohn/davekjohns-workshop/issues/103),
which closed this same gap the same way. A named list is only correct until the next document is
written, and nothing announces the omission. The directory holds the family's consumer-facing pages and
nothing else, so it is enumerated now — non-recursive, since the per-plugin subdirectories are gathered
by their own rules and would otherwise be counted twice. Effect on the real repo: `[link-scan]`
144 → 145, `[lifecycle]` 14 → 16, `[record-query]` 2 → 3, still **0 errors**.

Scenario 33 in `check-plugin-integrity.tests.ps1` pins it, deliberately using a file name this suite has
never heard of — if that scenario ever needs updating because a real document took the name, the
enumeration has stopped being one. **Proven load-bearing:** run against the pre-fix scan set, three of
its assertions fail. The fourth is the interesting one — `Assert-Equal 1 $r33.Code` passed in **both**
worlds, so it was removed rather than kept as decoration, with the measurement recorded in place. A green
that proves nothing is the exact failure this suite exists to catch, and it had just produced one.

All 18 suites green (`check-plugin-integrity` 83 → 88 asserts), lint gate `0 error(s)`.

Plugins: specialists

[PR #321](https://github.com/DaveKJohn/davekjohns-workshop/pull/321)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v3.0.9] - 2026-08-01 — Patch

See [releases/development/3.x/3.0.9.md](releases/development/3.x/3.0.9.md) for the full release notes.

---

### [v3.0.8] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.8.md](releases/development/3.x/3.0.8.md) for the full release notes.

---

### [v3.0.7] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.7.md](releases/development/3.x/3.0.7.md) for the full release notes.

---

### [v3.0.6] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.6.md](releases/development/3.x/3.0.6.md) for the full release notes.

---

### [v3.0.5] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.5.md](releases/development/3.x/3.0.5.md) for the full release notes.

---

### [v3.0.4] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.4.md](releases/development/3.x/3.0.4.md) for the full release notes.

---

### [v3.0.3] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.3.md](releases/development/3.x/3.0.3.md) for the full release notes.

---

### [v3.0.2] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.2.md](releases/development/3.x/3.0.2.md) for the full release notes.

---

### [v3.0.1] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.1.md](releases/development/3.x/3.0.1.md) for the full release notes.

---

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
