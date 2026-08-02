### the untouched-install note is gated on the install record · Fix · 2026-08-02

`teardown.ps1` closed every run with *"The plugin install itself is untouched: run
`claude plugin uninstall …`"* — unconditionally, while the note directly above it was already gated
on the content of `settings.json`. Round v13 reached it by the route `UNINSTALL.md` Step 4 has
offered since `v3.1.2` (re-run the audit from the cache, which survives Step 2) and read that the
install was untouched **one step after** `Successfully uninstalled`, with the advice to run the
command again (inbound [#381](https://github.com/DaveKJohn/davekjohns-workshop/issues/381)). New
behaviour reached by the #373 repair, and unmeasured until someone walked it.

The condition was lying around: it is the same `projectPath` query `UNINSTALL.md` prints twice, in
Step 2 and again in Step 4. `Get-InstallRecordState` now asks it, and the note has three readings,
because *"no record"* and *"could not look"* are different claims:

- **a record points here** — the note names the plugin **and the scope the record is actually in**,
  rather than assuming `project`. A session start can write a `local` record by itself, and an
  uninstall aimed at the wrong scope is the failure the document spends a paragraph on;
- **readable, nothing points here** — it says so, and stops advising a command the reader has
  already run. This is what the Step 4 re-run now reads like;
- **missing or unparseable records file** — reported as a gap in the reading, never as a clean
  machine, and the teardown still exits 0.

`UNINSTALL.md` Step 4 says what to expect from that re-run, so the confirmation is documented rather
than discovered. Ten assertions cover the three states plus the unparseable route into the third.
