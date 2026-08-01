### The kept count matches its markers, and the hook stub cannot be copied by accident · Fix · 2026-08-02

Two findings from test round v11, both in the reporting layer rather than in what the scripts do.

**`specialists-teardown` summarised itself as `0 kept` while printing two `[KEEP]` lines** (inbound
#356). The scaffold-prose loop added in #331 printed its own marker straight to the host and never
touched the `$kept` tally, so a run on the fresh-consumer row — a repo with no `CLAUDE.md` before
adoption — printed two `[KEEP]` markers, a `[note]` saying "2 line(s)", and a summary contradicting
both. The figure a reader skims to was the one that said nothing was left behind, which is precisely
the failure #331 was filed about, occurring inside the repair for it. Every `[KEEP]` marker now goes
through one `Add-Kept` door, so the markers and the number cannot drift apart — the same "one list,
one number" lesson #275 established for the remove side, applied to the half it did not reach. The
kept items carry which remedy applies to them and the summary groups by it: the `-EmptyLensPattern`
escape hatch is true of a file whose shape the script did not recognise and false of a prose line in
a governance file, so one blanket paragraph over both would have to be wrong for one of them.

**`settings.suggested.jsonc` invited copying a hook that points at nothing** (inbound #363). The
bootstrap proposes a `Stop` hook running `scripts/maintenance/lint-changed-hook.ps1`, a file it does
not create and nothing else ships. The proposal file did already say twice that its hooks are a stub
— so the gap was not the missing warning the issue reports, but where that warning is not: the
console's step 3 says "copy desired parts" with no exception named, and that console line is the
instruction a reader acts on. The path is now visibly a placeholder (`<your-check>.ps1`) rather than
a plausible-looking real one, and step 3 states which block is ready to use and which is not. Same
step also gave the file a trailing newline, which it never had — the `#337.2` warning names
`CLAUDE.md` for that and does not cover this file, so nothing pointed at it.

Regression covered on the v11 fixture itself, in both preview and apply mode, as the invariant
(every printed marker is counted) rather than against a literal count — a hardcoded expectation
could pass while both sides carried the same error, which is the failure the test exists to catch.
