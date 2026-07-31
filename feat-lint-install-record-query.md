### the gate that closes the under-determined record query · Feat · 2026-08-01

**Check 12 in the lint gate.** The three findings of adoption round v8 —
[#313](https://github.com/DaveKJohn/davekjohns-workshop/issues/313),
[#314](https://github.com/DaveKJohn/davekjohns-workshop/issues/314),
[#315](https://github.com/DaveKJohn/davekjohns-workshop/issues/315) — read as three unrelated problems and
are one class. Each is a way the family's own verification query, the thing every document points a reader
at to answer *"what am I actually running?"*, printed a green that **under-determined** the state it claimed
to prove:

| It could not distinguish | Because |
|---|---|
| the release from `main` after it | `version` reads `3.0.8` on both commits; only `gitCommitSha` differs, and that field was printed nowhere |
| one record from two | the prescribed repair install *adds* a record, and the line count was the only signal |
| `project` from `local` | which is what a session start silently leaves behind |

The three PRs before this one closed those three instances. **This closes the class**, which is the
difference between a fix and a gate: a fenced block that reads `installed_plugins.json` *in code* must
select `projectPath`, `scope`, `version` **and** `gitCommitSha`. Three adoption rounds in a row had already
produced this same species of defect — a doc place whose printed instruction no longer holds — and four doc
fixes only ever closed instances.

`projectPath` is a **required field, not part of the discriminator**: a query that reads the administration
without filtering on it reports records beyond this repo, which is precisely the `claude plugin list`
mistake both documents spend a paragraph warning against. A doc printing that would be reproducing the
defect it warns about.

The discriminator is *mention vs. use*, the third time this repo has had to answer that question and the
second time positionally: check 11 uses the `@`-target, check 12 uses "does the block actually parse the
file". So a fenced JSON snippet illustrating the record's shape is out of scope even though it names the
same fields — it teaches the file's layout, it is not a command anyone reads a verdict off. Matching is
case-insensitive on purpose (PowerShell property access is, so `$_.Version` is as correct as `$_.version`);
erring that way can miss a miscased field but never invent a finding.

Measured on the real repo: **2 subjects, both compliant, 0 findings** — the two prescribed queries, and no
false positives among the other live mentions of the file.

5 scenarios (28–32) in `check-plugin-integrity.tests.ps1`, including the discriminator and the
prose-exclusion case. Scenario 31 earned a change in the check itself: it asserted that a skip must be
*stated*, which exposed that the empty-scan coverage note dropped the skip count — making "saw nothing about
this file" and "saw one block and deliberately did not judge it" read identically. Both branches now carry
it, per the `[COVERAGE]` reasoning from issue #221.
