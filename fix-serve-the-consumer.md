### Hooks survive compaction, and consumer messages stop pointing at the workshop · Fix · 2026-07-28

Two findings from Dave's principle: **assume a consumer knows nothing about this workshop.** A
colleague who merely installs the plugin must be served by it, not put to work for it.

**1. The three session hooks went silent after the first `/compact`.** `hooks.json` matched only
`startup`, while a SessionStart hook's injected stdout does not survive a compaction on its own — the
[documented](https://code.claude.com/docs/en/hooks) way to keep it is to let the hook run again, which
it does only for the sources its matcher names (`startup`, `resume`, `clear`, `compact`, `fork`). So
every report — roster drift, script-contract drift, connector signals — disappeared from the context at
the first compaction and never came back. Now `startup|resume|clear|compact`.

`fork` is deliberately excluded: a forked session inherits the parent's context, so re-running would
only duplicate the report. The cost was **measured** before widening rather than assumed — all three
hooks together take ~4.6s (the connector check ~2.6s of it, since it runs the drift check per consumer),
less than the compaction they now run alongside. Because `hooks.json` is JSON and cannot carry a
comment, the reasoning lives in the hook docstrings.

This was filed in inbound #204 as one of two closing observations *"offered as data rather than as
asks"*, and left out of scope then. It turned out to be the load-bearing one.

**2. Two consumer-facing messages handed out homework in a repo the reader may not have.**

- **`[UNREGISTERED]`** said *"add connectors/<repo>.json in the workshop"*. Who benefits from
  registration is the plugin's maintainer; who was being instructed was the consumer. It now states that
  nothing there is broken (the plugin works normally; only the maintainer's view is missing) and
  addresses the fix conditionally — *"if you maintain the plugin source … if you just use the plugin, no
  action is needed on your side."* The hook's verdict line drops the word "workshop" too: internal
  nickname, meaningless to that reader.
- **A missing script-contract function** ended with *"update it from the workshop's own
  scripts\repo-config.ps1"* — useless advice for exactly the reader most likely to hit it. Each contract
  record now carries a `Returns` line stating in one sentence what the function must give back, so the
  finding is **self-contained**: the reader can write the function from the report alone. Example:

  > `[ERROR] 'Get-RosterPath' missing from scripts\repo-config.ps1 (required by: check-roster-sync) --
  > this lib predates the contract the shared script(s) call; add the function. It must return the
  > repo-root-relative path to the file holding the specialist roster -- 'CLAUDE.md' unless this repo
  > keeps it elsewhere.`

`Get-RecordReturns` degrades to the shorter message when a record has no `Returns`, so nothing breaks —
which is precisely why a record could be added without one and nobody would notice. A drift guard
asserts the `Returns` count equals the record count, so a ninth record without one turns the suite red.

Two test-quality notes worth keeping. The "no workshop jargon" assertion first failed on the *fixture*
rather than the hook: the stub still carried the old message text, making the hook look guilty of words
it never produced. Stubs that exist to prove a wording must carry the real wording. And the intended
demonstration against smartwatchbanden could not run — that repo's session had already repaired its
script contract while this branch was being built, so its eight functions now report `[OK]`. The
demonstration moved to a throwaway fixture instead.
