### the teardown skill's own checks report the wrong answer · Fix · 2026-07-31

Three findings from test round v5 (life-hub against 3.0.3, inbound
[#283](https://github.com/DaveKJohn/davekjohns-workshop/issues/283),
[#285](https://github.com/DaveKJohn/davekjohns-workshop/issues/285),
[#286](https://github.com/DaveKJohn/davekjohns-workshop/issues/286)), and one class: a **documented
check that silently reported the wrong answer**. Nothing was wrong with what the teardown *does* — the
round showed no accumulation, matching preview/apply totals, and a byte-identical `CLAUDE.md` after two
full cycles. What was wrong is what the skill told an operator to run, and what the run told them back.

**The pre-flight said "stop here" to a repo that ignores nothing (#283).** `git check-ignore -v
.claude/specialists/lenses/` returned a hit in life-hub — `.gitignore:19:` + TAB + the path, exit `0` —
while nothing about that path was ignored: no `claude` line anywhere in `.gitignore`, 16 files under
`.claude` tracked, no `core.excludesFile`, a default `info/exclude`, and line 19 of that file blank.
Isolated in fresh fixtures: with **CRLF line endings and at least one blank line**, git reads the blank
line as a pattern of a single `CR`, which matches every path with a trailing slash. That is the normal
state of a repo on Windows, and both real consumers are Windows repos. It is also the harder mistake to
distrust — the output looks like a real gitignore hit, filename and line number included, and the only
tell is that the **pattern field is empty**. Worse in kind than the fault it inherited: this check was
*added* in 3.0.3 to fix #280, where the old one merely alarmed a safe repo. This one hands it the
section's single stop-work verdict.

The command now reads its own output and keeps only hits whose pattern field is filled. Two
measurements decided that shape over the tempting alternative:

- **Dropping the trailing slash would trade the false positive for a false negative.** In a CRLF repo
  that genuinely ignores `node_modules/`, `git check-ignore -v node_modules` (no slash, directory absent
  from disk) exits `1` — a real ignore rule, missed.
- **The artefact never outranks a real pattern.** With a genuine rule placed *before* and *after* the
  blank line, git reported the genuine one, pattern field filled, in both orders. So filtering can only
  ever remove a false hit, never suppress a true one. Deliberately **not** claimed: *why* git prefers
  the real pattern. It was measured in both orders, not explained, and the fix does not depend on the
  mechanism.

**Two of the four prescribed round-trip measurements were measuring nothing (#285).** The import counter
used `[System.IO.File]::ReadAllLines('CLAUDE.md')` — a .NET static call with a relative path, which
resolves against `[Environment]::CurrentDirectory` and *not* against `Set-Location`. Measured from a
fresh disposable consumer: `19` lenses counted in that folder, `0` imports read out of **life-hub's**
`CLAUDE.md`, in the same block. The lone-LF counter used a `$text` the document never assigned anywhere,
and `[regex]::Matches($null, …)` does not throw — it returns zero matches. Both wrong answers are the
**green** one: a `0` reads as "the import was removed cleanly" and as "no line-ending pollution", which
are precisely the two defects the protocol exists to catch. The block now reads `CLAUDE.md` once, into
`$text`, from a path anchored to the repo root, and the lone-LF counter reuses it.

**The report counted per line while the doc counted per note (#286).** The bootstrap's note is a
two-line block, so `teardown.ps1` printed *the bootstrap's orchestrator note line* twice, byte-identical
— and `SKILL.md` frames that counter as the defective series 1 → 2 → 3. A healthy repo therefore showed
`2` to anyone counting from the report, which is the most natural source because the word is right there:
the clean run's loudest reading was the accumulation defect itself. Two identical lines also carried no
information about *which* of the two was meant. The lines now name it —
`CLAUDE.md:<n> -- the bootstrap's orchestrator note (head|tail)`, the same `file:line` format the audit
below it already uses for the same reason — and the bullet in `SKILL.md` names the head line as the unit
and says out loud that the report shows two. `Test-IsOrchestratorNoteLine` was correct and is untouched,
so the two `check-report-lib.ps1` copies stay byte-identical.

**And a gate, because none of this was visible to one.** `scripts/tests/teardown-protocol.tests.ps1`
tests the commands the *skill* prints rather than the script: it extracts the pre-flight's
`Where-Object` from `SKILL.md` and executes **that** against six real git fixtures (LF, CRLF with and
without a blank line, a genuine rule, and a genuine rule on either side of the blank line), so a
document that drifts back to the unfiltered command goes red. Whether this git version still produces
the artefact is reported rather than asserted — a future git that fixes it should not fail the suite,
but it should be visible. `teardown.tests.ps1` gained the report case for #286, asserting the two lines
are distinct and that each line number really resolves to a note line of the half it claims.

Plugins: specialists
