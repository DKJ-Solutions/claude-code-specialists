### local as a third scope, and the duplicate record the documented repair leaves · Docs · 2026-08-01

Closes inbound [#315](https://github.com/DaveKJohn/davekjohns-workshop/issues/315), the first of the
three findings from adoption round v8 (overview:
[#316](https://github.com/DaveKJohn/davekjohns-workshop/issues/316)).

**Two things the family's docs got wrong about the install record, both measured in
`DaveKJohn/life-hub` on July 31, 2026 (CLI `2.1.220`):**

- **The prescribed repair install leaves a *duplicate* record.** Re-installing at project scope against
  a path that already carried a record adds a second record beside it instead of correcting the first,
  and reports `✔ Successfully installed` both times. That is exactly the "stray second record" step 0c
  already warns about — so the document warned against a state its own remedy produces, and the only
  signal is the *line count* in its own verification query. Both `specialists-init/SKILL.md` step 0c and
  the QUICKSTART's step 1 now say **one** line per plugin, and say why two can happen.
- **`local` is a third scope, and it is not written by the reader.** A session start creates a missing
  record itself and flips an existing `project` record to `local` — no command run, no file in the repo
  changed, nothing reporting it. It was documented nowhere in the payload (`git grep`: no hits), so a
  reader who met it had nothing to look it up in. Both docs now name all three scopes, say which one a
  session start produces, and give the removal that actually works.

**And the same class turned out to be sitting in the lint gate.** Check 11 required `--scope project` on
every printed lifecycle command — which would have rejected `claude plugin uninstall … --scope local`,
the only command that removes such a record (`--scope project` refuses it with *"installed in local
scope, not project"*). The gate encoded the very assumption round v8 disproved: that `project` is the
only scope a consumer can be in. The scope rule is therefore **verb-specific** now — `uninstall` accepts
`project` or `local`, `install`/`update` keep the stricter rule, since nothing measured says a
local-scoped install is ever wanted. Two new scenarios in `check-plugin-integrity.tests.ps1`: 26 proves
the allowance, 27 proves it did not leak to the other verbs. Scenario 25 also got the docstring entry it
was missing.
