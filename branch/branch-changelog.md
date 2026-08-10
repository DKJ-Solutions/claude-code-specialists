## `docs/the-rename-has-a-migration-path` changelog

### Branch title

The rename gets a migration path: the dead import, the roster prefixes, and the two conventions that moved

### Branch ID

20260810-101425

### Branch type

docs

### What does the change on this branch bring to main?

`plugins/INSTALL.md`'s migration section gains the half it was missing, and `cut-release`'s skill page gains
the convention that would have prevented needing it. Three inbound issues filed on 2026-08-09 —
[#555](https://github.com/DaveKJohn/claude-code-specialists/issues/555),
[#556](https://github.com/DaveKJohn/claude-code-specialists/issues/556) and
[#557](https://github.com/DaveKJohn/claude-code-specialists/issues/557) — reduce to one sentence: `v4.0.0`
renamed the plugins, moved them in the tree, removed a shared script and changed a file convention, and the
page told a consumer only about the first.

**What was already there, and what was not.** The id table (`specialists` → `team-alpha`, and so on) landed
with the rename. What no document stated is that the swap leaves two things broken *inside* the consumer's
repo:

- **The `@`-import of the orchestrator's body**, which names the plugin's path inside the marketplace clone
  — and that path changed twice over, by id *and* by directory (`claude-code-plugins/claude-specialists/…` →
  `plugins/teams/…`, with a workflow under `plugins/workflows/`). It **fails silently**: Claude Code drops an
  unresolvable `@`-import without a word, so the roster renders, the session looks normal, and the
  orchestrator runs without its ritual. Only `roster-sessioncheck` catches it, as a blocking `[ERROR]` — it
  did, in the measured case.
- **Every `<plugin>:<name>` id in the roster**, where the names are unchanged and only the prefix is wrong,
  which is precisely the mechanical rename a reader's eye slides over.

Both now have a before/after in the page, plus the reason neither tool repairs them: `specialists-init` never
overwrites (its own `[keep]` lines say so), and `sync-roster` adds scaffolds and prints rows without
rewriting an existing id — a gap beside those skills rather than a bug in either.

**And a second new section for a consumer who calls the shared scripts directly.** `new-changelog-entry.ps1`
no longer exists; the replacement is `new-branch.ps1`, and the objection that it "also creates a branch" is
answered by measurement rather than waved away — it is **idempotent on an existing branch**, checking it out
and writing the two files beside it, which is exactly the Dependabot case the old script was used for. The
entry files also moved out of the repo root into `branch/`, so a CI gate keyed on `<branch>.md` fails *after*
the work is done; the page says to look for one before using the skill, and says that entries already in
flight are safe because the fold still recognises both shapes. The dead `Get-ChangelogHeading` sitting in a
consumer's seam is named too, together with the consequence that outlived it: the scripts now assume a flat
changelog, and since the repair for
[#561](https://github.com/DaveKJohn/claude-code-specialists/issues/561) the fold refuses rather than writing
outside their sections.

**The convention half is in `cut-release`'s skill page, so this does not recur.** When a cut removes or
renames a shared script, drops a script-contract function, or changes a written convention the scripts read,
the release document names it, says what to use instead, and states the difference. **No gate was built for
it, deliberately**: recognising "names a migration" in prose is the matcher-satisfied-by-a-mention shape this
project keeps paying for. What the model already provides is the place — significance band 5 is *the reader
must act — a breaking change or a required migration* — so a tier-2 entry scoring 5 is the entry that owes
the text, and the cut then carries it outward on its own.

### Significance

#### Tier 0

Nothing here needs it: this repo is the source, so it never migrated and its own layout is what the new
tables are read off. The convention in the skill page is the part that binds locally — the next cut that
retires a script has somewhere to look, which the last one did not.

**Score:** 2

#### Tier 1

Three inbound issues in one day all reduced to the same missing document, and one of them cost a consumer a
session running without its orchestrator while every check around it stayed green. Naming the class — a
shared script, a contract function, a written convention — is what turns three repairs into one rule.

**Score:** 3

#### Tier 2

This is the whole point of the change. A consumer migrating off the old plugin ids now has the two in-repo
repairs written down with before/after, the silent failure named as silent, and the tools' refusal to do it
for them explained rather than left as a surprise. The measured repo derived the correct path by reading this
repo's own seam — a good trick, and not a procedure.

**Score:** 4

### Pull Request
