### An UNINSTALL document beside the QUICKSTART · Docs · 2026-08-01

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
