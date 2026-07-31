# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #288 · the teardown skill's own checks report the wrong answer · Fix · 2026-07-31

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

Plugins: specialists

[PR #288](https://github.com/DaveKJohn/davekjohns-workshop/pull/288)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v3.0.3] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.3.md](releases/development/3.x/3.0.3.md) for the full release notes.

---

### [v3.0.2] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.2.md](releases/development/3.x/3.0.2.md) for the full release notes.

---

### [v3.0.1] - 2026-07-30 — Patch

See [releases/development/3.x/3.0.1.md](releases/development/3.x/3.0.1.md) for the full release notes.

---

### [v3.0.0] - 2026-07-30 — Major

See [releases/development/3.x/3.0.0.md](releases/development/3.x/3.0.0.md) for the full release notes.

---

### [v2.16.0] - 2026-07-30 — Minor

See [releases/development/2.x/2.16.0.md](releases/development/2.x/2.16.0.md) for the full release notes.

---

### [v2.15.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.15.1.md](releases/development/2.x/2.15.1.md) for the full release notes.

---

### [v2.15.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.15.0.md](releases/development/2.x/2.15.0.md) for the full release notes.

---

### [v2.14.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.14.1.md](releases/development/2.x/2.14.1.md) for the full release notes.

---

### [v2.14.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.14.0.md](releases/development/2.x/2.14.0.md) for the full release notes.

---

### [v2.13.3] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.3.md](releases/development/2.x/2.13.3.md) for the full release notes.

---

### [v2.13.2] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.2.md](releases/development/2.x/2.13.2.md) for the full release notes.

---

### [v2.13.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.1.md](releases/development/2.x/2.13.1.md) for the full release notes.

---

### [v2.13.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.13.0.md](releases/development/2.x/2.13.0.md) for the full release notes.

---

### [v2.12.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.12.0.md](releases/development/2.x/2.12.0.md) for the full release notes.

---

### [v2.11.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.11.0.md](releases/development/2.x/2.11.0.md) for the full release notes.

---

### [v2.10.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.10.0.md](releases/development/2.x/2.10.0.md) for the full release notes.

---

### [v2.9.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.9.0.md](releases/development/2.x/2.9.0.md) for the full release notes.

---

### [v2.8.0] - 2026-07-27 — Minor

See [releases/development/2.x/2.8.0.md](releases/development/2.x/2.8.0.md) for the full release notes.

---

### [v2.7.3] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.3.md](releases/development/2.x/2.7.3.md) for the full release notes.

---

### [v2.7.2] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.2.md](releases/development/2.x/2.7.2.md) for the full release notes.

---

### [v2.7.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.1.md](releases/development/2.x/2.7.1.md) for the full release notes.

---

### [v2.7.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.7.0.md](releases/development/2.x/2.7.0.md) for the full release notes.

---

### [v2.6.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.6.1.md](releases/development/2.x/2.6.1.md) for the full release notes.

---

### [v2.6.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.6.0.md](releases/development/2.x/2.6.0.md) for the full release notes.

---

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
