### A gate states its coverage, not just its verdict · Feat · 2026-07-30

The last open item of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221)'s target
shape: *"consumer gates that announce when they stop applying."*

**The defect was sharper than the issue described, and the difference matters.** The family README said
the gate *silently skips* the lens category once the directory is gone. It does not skip quietly and
print nothing — it prints a **verdict with no coverage**. `check-consumer-drift`'s persona section closed
with:

```
-- Personas (portable body vs. the <g>-<id>-extension.md copy in the consumer) --
  Persona drift is INFORMATIONAL (does not affect the exit code): 0 drifted.
```

Measured today against a directory holding a `CLAUDE.md` and nothing else: that was the section's
*entire* output. Four personas exist in the source; zero were compared; the reader was told "0 drifted".
**"0 drifted of 0 compared" and "0 drifted of 4 compared" were the same sentence.** That is not a false
pass — it is a true statement that reads as a different, false one, which is harder to catch than
silence, because there is nothing missing to notice.

Worse, the asymmetry was visible in the same output the whole time: the agent-def section right above it
*does* state its coverage (*"26 missing, 0 identical, 0 drifted"*). One half of the report had the
denominator and the other half did not.

**The fix.** One shared, non-counting `Write-Coverage` in
[`scripts/lib/check-report-lib.ps1`](scripts/lib/check-report-lib.ps1) — plugin-owned, so it travels to
every consumer with the payload — emitting `[<category>] checked N of M -- <why, when empty>`:

- **`check-consumer-drift`** — the persona section is now printed **unconditionally** (it used to be
  wrapped in `if ($personaResults.Count -gt 0)`, so it could vanish entirely), and its verdict carries
  its denominator: *"0 drifted of 0 compared"*, plus a line naming why nothing was compared. A reader
  can now tell a deliberate teardown from a bad merge or a wrong `-ConsumerPath`.
- **`check-plugin-integrity`** — a `[COVERAGE]` line closes **all ten** categories, with
  `link-scan/lenses` counted separately from the scan total precisely because it is the category a
  teardown removes.

**Applied to all ten on purpose.** A partial rollout recreates the exact asymmetry that caused this: the
agent-def section was honest and the persona section was not, and that is why nobody noticed for months.
Uniformity is the fix, not thoroughness for its own sake.

**Coverage is context, never a finding.** `[COVERAGE]` is non-counting like `[OK]`/`[SKIP]`/`[SCOPE]`: it
moves no exit code and no signal count, and a unit test asserts exactly that — a legitimately empty
category must not break its own gate, or the honesty would cost more than the silence did.

**Two things the work produced beyond the feature:**

- **The gate caught its own change.** Editing `check-report-lib.ps1` made the plugin mirror drift, and
  check 8 reported it on the first run. The shared-script model working as designed, worth stating
  because it is the kind of thing that only ever gets noticed when it fails.
- **The integrity fixture was already the perfect witness, and its own docstring said so.** That fixture
  carries no agent def, no manual, no persona and no plugin manifest — it recorded those categories as
  *"expected noise, asserted on nowhere below"*. They are asserted on now: six categories that report
  `checked 0`, two that report a real count (so the line cannot be hardcoded), and the empty lens
  category's stated reason. As a side effect three redundant recursive directory walks collapsed into
  the sets already collected.

**What this deliberately does not fix, said out loud instead of quietly scoped away.** A consumer's own
lint — whatever `Get-LintScript` points at — is the repo owner's code. The measured silent skip lives
there, and no plugin can make someone else's gate honest. The helper is available to it; adopting it is
the owner's act. Recorded in the family README as the owner's item rather than counted as closed here.
