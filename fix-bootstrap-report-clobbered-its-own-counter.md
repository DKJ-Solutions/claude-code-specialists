### The bootstrap report printed CLAUDE.md instead of a count · Fix · 2026-07-30

Found by **measuring** rather than reasoning, while checking a blocking report from the first real
adoption attempt (`life-hub`, July 30, 2026). The report itself turned out to be about something else
entirely — see below — but running the measurement it demanded surfaced this:

```
Done: 4 persona-lens(es) created, # life-hub-achtig  Eigen governance.  already present; ...
```

`$kept` is the persona-lens *"already present"* **counter**, declared at the top of `bootstrap.ps1`. The
note-tidy block near the end assigned an **array of `CLAUDE.md` lines** to that same name, so by the time
the summary line ran, PowerShell interpolated the consumer's whole `CLAUDE.md` where a number belonged.
Renamed to `$keptLines`; the counter is left alone.

**Why every suite stayed green, which is the part worth keeping.** That block runs *only* when the
consumer already has a `CLAUDE.md` that does not yet carry the guard import — **exactly the path a real
adoption takes**, and never the path a fixture takes: a fixture with no `CLAUDE.md` gets one written by
the bootstrap and goes down the other branch. So the bug was reachable only where no test looked, and it
corrupted the one number the round-trip protocol tells an operator to write down first.

Third instance of one lesson in this repo — after the `$pid` note in `check-roster-sync` and the
shared-counter collision behind it: **a name reused for a second purpose in the same scope breaks
somewhere else entirely, and a report line is the last place anyone looks.**

**The blocking report itself was a defect in the test, not in the plugin — and the plugin's behaviour
already was what the reporter proposed.** They found both scaffold addresses occupied in `life-hub`:
`scripts/repo-config.ps1` (55 lines) and `scripts/lib/branch-info.ps1` (88 lines, named by that repo's own
`CLAUDE.md` as its single source of truth for the branch taxonomy). Their proposal was to treat scaffolds
like lenses — neither placed nor removed once inhabited. Measured on a fixture built to match:

- **Bootstrap:** `[keep] scripts/repo-config.ps1 already exists -- not overwritten`, both files
  byte-identical afterwards.
- **Teardown `-Apply`:** `[KEEP] ... filled in; it describes this repo's branch taxonomy, which outlives
  the plugin` — both kept, both byte-identical, while the 25 items the plugin *did* write are removed and
  the audit reports `[FREE]`.

So the round trip on an occupied consumer was already correct in both directions. What was wrong were the
**expectations in the test prompt**, which read "both scaffolds present" as a success criterion after the
bootstrap and "both scaffolds gone" after the teardown — true only for a repo that never had them. Stopping
before installing was the right call, and the second half of their note ("a fixture cannot measure this by
definition") is exactly right.

**Both halves are now pinned by tests** — an *occupied consumer* scenario in `teardown.tests.ps1`: the
bootstrap keeps and reports, the teardown keeps and reports, both files byte-identical across the full
round trip, and the report line asserted to carry digits. Verified against the unfixed script: **the two
report assertions fail and the thirteen behavioural ones pass either way**, which is the proof that the
behaviour was always right and only the report was broken.

**And the protocol that misled the prompt is corrected at the source.** The round-trip section of
[`specialists-teardown`](claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md#verifying-a-round-trip--and-why-git-status-is-not-enough)
now states that the two `Test-Path` lines are an **inventory, not an expectation**, with a table for the
occupied case and the instruction to read `[create]`/`[keep]` and `[remove]`/`[KEEP]` rather than the
booleans. The general form: **the plugin scaffolds precisely the files that were extracted from repos like
these** — free real estate on a fixture, inhabited in any real consumer.

**One correction to the report, for the record.** It concluded that the prompt's ~20 mid-word truncations
were *"in the source file, not in the transfer."* The source file is intact: line 64 reads
`Where-Object { $_ -match '^\s*@' }`, not the reported `Where-Obount`, and no scratchpad file contains a
single broken token. So the damage is in the channel — the same failure
[#260](https://github.com/DaveKJohn/davekjohns-workshop/pull/260) recorded on July 29, now on a different
route. Worth stating plainly because the two diagnoses lead somewhere different: a corrupt source is fixed
by rewriting it, a corrupt channel is not. The prompt's own truncation guard did its job — the session saw
the damage, stopped at step 2, and said so instead of guessing.
