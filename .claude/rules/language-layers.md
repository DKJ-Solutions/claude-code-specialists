---
paths:
  - "scripts/**"
  - "plugins/**/scripts/**"
  - "plugins/**/hooks/**"
  - ".github/**"
  - "releases/**"
  - "contributing-davekjohn/releases/**"
  - "CHANGELOG.md"
  - ".gitignore"
---

# Language — which layers are English, and the exceptions

The norm itself lives in [`CLAUDE.md`](../../CLAUDE.md#language) because it governs every turn. **This
file is the per-layer detail**, path-scoped so it loads when you actually touch one of those layers
rather than in every session.

Two consequences of that scoping, both deliberate:

- It is **lost after a `/compact`** until a matching file is read again — documented behaviour for
  `paths:`-scoped rules. That is acceptable here precisely because the content only matters while you
  are editing one of these files, and editing one means reading one, which reloads this rule. Anything
  that must hold *regardless* of which files a turn touches does **not** belong here; the session-reply
  language rule is the example, and it stayed in `CLAUDE.md` for exactly this reason.
- Dropping the `paths:` field would make it load unconditionally with the same priority as
  `CLAUDE.md` — which would restore compaction-survival and **save nothing**. The saving is the
  scoping.

The list below is meant to be exhaustive. If it ever undercounts a layer, that is a gap to close on
discovery — as an earlier pass did for `.github/workflows/ci.yml` — not a quiet exception to the norm.

- **The script layer is fully in scope.** Every `.ps1` file under `scripts/**` (and the shared
  mirrors under `plugins/*/scripts/`), the hooks, the tests, and
  `.github/**` (the workflows, the issue templates, and the PR template) are English throughout —
  comments, docstrings, console output (`Write-Host`/`Write-Error`/`Write-Warning`/`throw` text), and
  workflow/template body text. `ci.yml` was translated on July 26, 2026, closing the gap a
  documentation audit found between this claim and the actual repo state — a CI workflow, matching none
  of the exceptions below, had simply been missed. New scripts and edits are written in English; no new
  non-English text is added anywhere in scope.
- **The root `.gitignore` is in scope, and it is the second gap this list has had to close.** Its four
  section comments were Dutch until August 15, 2026, found by a copy-editing sweep looking for exactly
  this — while the long explanatory blocks lower in the same file (the PowerShell cache, the
  release-notes page and its token) had been written in English all along, so the file read as
  half-translated rather than deliberately Dutch. It matches none of the exceptions below, and this
  repo being public makes it one of the first files a visitor opens. The same sweep found a layer this
  file **cannot** reach at all — the GitHub repo description and the `inbound` label description live in
  repo settings, not in the tree — which is worth knowing before treating this list as complete: it is
  exhaustive over the tree, and the tree is not the whole product.
- **Script-*generated* document content is in scope too.** The `CHANGELOG.md` sections, release notes,
  that `scripts/lib/release-lib.ps1` builds are English going forward (it built per-plugin CHANGELOGs
  too until August 8, 2026, when those files were retired): its
  document-generating template strings (the category labels, the reference line, the
  `## Releases`/plugin-CHANGELOG intro texts, the date label) were translated in that pass.
  `CHANGELOG.md` itself is now fully English (its intro paragraphs and every `## Releases` reference
  line were translated on July 22, 2026 — Dave's decision). The archived changelog notes
  (`contributing-davekjohn/releases/changelog/*.md`) stay in their original language, so older ones
  remain Dutch.
- **The script layer is ASCII, and a character the script must EMIT is written as a code point.** Measured
  August 19, 2026, on the branch that gave the changelog entry's heading a middle dot: typed literally into
  `scripts/lib/entry-scaffold-lib.ps1`, that one character came out of every generated template as `Â·`.
  Windows PowerShell 5.1 reads a `.ps1` with no BOM as the **system ANSI code page**, so the two UTF-8 bytes
  of U+00B7 are decoded as two CP1252 characters — and nothing errors, because a mis-decoded string is still
  a string. The repair is `[char]0x00B7`, not a BOM: the two shared libs are held byte-identical to their
  plugin mirrors, so an encoding change would have to land in both, and the escape keeps the file free of the
  question entirely. **The mojibake gate does not cover this** — `Get-MojibakePaths` walks `*.md`, so the
  damage is only caught one layer downstream, in the generated document, after it has been copied into
  somebody's entry.
  **Since August 23, 2026 the rule has its own gate**: check 27 (`[script-ascii]`) in
  [`check-plugin-integrity.ps1`](../../scripts/lint/check-plugin-integrity.ps1) holds every `.ps1` in the
  tree to it, upstream of the generated document, and names the code point and the `[char]0x..` form in the
  finding. A BOM is deliberately **not** a finding there: on a `.ps1` a BOM is the fix rather than the
  defect, and check 26 owns the documents where one breaks something.
  The two non-ASCII spots this section used to name as deliberately unrepaired — the en/em dashes inside the
  regexes in `scripts/lib/pr-issues-lib.ps1` — were repaired in the same movement, because a gate born
  needing an exemption list is the shape this repo has scar tissue from. That is **not** the no-pre-emptive-fixes rule
  being overruled: it says a risk that has not bitten is written down rather than built against, and this
  one had bitten, in the middot above. What it forbade was sweeping those two lines along with an
  *unrelated* change, and the change that enforces the rule they break is the related one. The class is
  closed at both ends: the dash class is now composed from `[char]` code points, and
  [`pr-issues.tests.ps1`](../../scripts/tests/pr-issues.tests.ps1) exercises both dashes, which nothing had
  done — until then only the ASCII hyphen was asserted, so a composition producing the wrong two characters
  would have passed every existing assert.
  **The gate holds the source to ASCII; it cannot vouch for the composition.** A repair tool that mangles
  an escape can still hand back pure ASCII, so check 27 passes the wrong answer along with the right one.
  Measured August 23, 2026: a GNU `sed` substitution meant to write those same two dash escapes hit `sed`'s
  own `\u` ("uppercase the next character") reading of the replacement and wrote the literal `[-20132014,]`
  instead — ASCII, and wrong. The mechanism is in
  [the system-administration manual's trap section](../../plugins/teams/team-alpha/manuals/05-15-manual.md#eight-powershell-traps-that-produce-well-formed-wrong-output);
  the consequence here is the same as above — compose the escape with
  `'-' + [char]0x2013 + [char]0x2014` rather than a non-PowerShell substitution, and where such a tool must
  write one anyway, read the written line back by code point before trusting it.
- **And the mirror-image rule for READING: a native command's output that is DATA is not decoded with the
  console code page.** Measured August 21, 2026 (inbound
  [#821](https://github.com/DaveKJohn/claude-code-specialists/issues/821)). The bullet above is about a
  character a script must *emit*; this one is about a byte a script must *understand*. Windows PowerShell
  5.1 decodes a native child's stdout with `[Console]::OutputEncoding`, i.e. with whatever console code
  page the run inherited — cp850 here, cp1252 elsewhere, cp65001 in a UTF-8 terminal. For a progress line
  that is a display problem. For a **path**, an id, or anything the script then compares, it is a wrong
  **answer**: `sync-main.ps1` asked git for paths with `core.quotePath=false` (raw UTF-8 bytes on the
  wire), so a theme file with an accent in its name decoded to two wrong characters, matched nothing on the
  other side, and reached the exact "foreign, taken, trunk overwritten" failure that flag had been added to
  prevent. The repair is to **hold the wire to ASCII and decode it yourself** — `core.quotePath=true` plus
  `Convert-GitQuotedPath` — because every candidate code page agrees below 0x80. Forcing the flag rather
  than relying on git's default is part of it: a repo may set `core.quotepath` in its own config.
  **Two things to know before touching this class again.** Never repair it by setting
  `[Console]::OutputEncoding`: that setter is `SetConsoleOutputCP`, console-**wide**, and the test gate
  runs every suite on one shared console — which is precisely how this bug stayed invisible, a sibling
  suite holding UTF-8 turning the failing assert green under the gate while it was red on its own. And a
  suite that is green under the gate and red standalone is reporting a **real** defect until proven
  otherwise; the gate is the run with the shared state in it.
- **Technical identifiers/flags** keep their original form — the scaffold marker `VUL-IN` (used across
  the plugin's scaffold scripts, e.g. `bootstrap.ps1`, `new-branch.ps1`) is one example; Dave's
  explicit decision. The job id **`lint-en-tests`** in [`ci.yml`](../../.github/workflows/ci.yml) is a
  second, higher-stakes one: it is the exact name GitHub's `main` ruleset requires as a passing status
  check before any PR can merge. This is not a forgotten translation — renaming it would silently break
  that binding, and every future PR would sit unmergeable (`BLOCKED`, waiting on a check that no longer
  exists) until someone traced it back to the rename, a failure that would surface only at the next PR
  rather than at the moment of the change. It stays Dutch-shaped on purpose.
- **Legacy back-compat markers** deliberately keep recognizing existing, not-yet-migrated consumer
  content and are not translation debt: the slot heading `## Specific to this repo` alongside its legacy
  predecessor in the drift-check (`scripts/lint/check-consumer-drift.ps1`) and the bootstrap templates,
  and the `[ERROR]` marker alongside its legacy predecessor in the connector session hook
  (`connector-sessioncheck.ps1`).
- **History** — the archived per-release notes under `contributing-davekjohn/releases/changelog/*.md` (at
  `releases/development/*.md` until August 26, 2026, #914) are this repo's narrow
  exception to the norm and may remain in their original language (older ones are Dutch).
  `CHANGELOG.md` and the release-history README (now `releases/README.md`) are themselves fully English (translated July 22, 2026,
  Dave's decision), so the exception no longer covers them.

Decision by Dave, July 20, 2026 (repo-wide English) — the decision that in turn prompted the
system-wide norm — sharpened July 21, 2026 to make explicit that it covers the script layer and
script-generated content, not only docs/manuals/agent-defs, and sharpened again July 26, 2026 to make
explicit that `.github/**` is covered too, after a documentation audit found `ci.yml` had been missed.

**A verification lesson from that same audit, worth keeping even though its concrete exception has since
closed:** a name that looks non-English is not automatically translation debt. Check first whether it is
the live name of an *external* object — one this repo does not define and cannot rename unilaterally
from a documentation pass. If it is, the doc may cite that name as-is (citing reality is not a language
violation), and the fix runs in one direction only: the object gets renamed first, by whoever owns that
object's security binding, and the doc follows — never the reverse. This section once cited the repo
ruleset enforcing the CI gate under that reasoning, as `main-ci-poort` (verified via the GitHub API
rather than assumed). Dave has since renamed it to `main-ci-gate` (July 26, 2026); a field-by-field API
re-check confirmed only the name changed — required check, enforcement, target branch, rules, and bypass
actors are all unchanged.
