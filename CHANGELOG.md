# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #345 · The demoted record is reported, and the details reach the session · Fix · 2026-08-01

Two findings from test round v9 (#326), taken together because the second decides what the first's new
lines are allowed to say — the dossier's own reason for ordering them, satisfied better by one PR than by
two touching the same block twice.

**#323 — a `project` record demoted to a pathless one, reported by nothing.** Measured in `life-hub`: a
single session start rewrote a correct `project` record into a `user`-scope record with the `projectPath`
**removed**, one write, original `installedAt` preserved. The repo then had no record for its own path for
the plugin that was demonstrably loading — 4 skills and 15 subagents present — and it **disappeared from the
verification query the documents prescribe**. Both predicates stayed silent, each correct by its own rule:
`Test-PluginInstalledHere` returns `$true` on a pathless record (a user-scope install really does load
here, and a false `[NOT-INSTALLED-HERE]` is the cry-wolf failure #294 spent a release removing), while
`Get-RecordShape` read only records scoped to this path and so had nothing to judge.

`Get-RecordShape` now judges it as a third shape, `pathless-only`. That is the right owner rather than a
convenient one: the question this predicate asks is *"is the administration for this repo the shape the
documents assume?"*, and a repo whose record has lost its path is the sharpest possible no. `Count` is `0`
for this shape — there being no records for this path **is** the finding — and `Scopes` carries the pathless
record's own scope so the report can name what it found instead. The permissive predicate is deliberately
left permissive; the boundary between the two markers moved from *path* to *evidence*: no evidence at all is
`[NOT-INSTALLED-HERE]`'s subject, any evidence of the wrong shape is this one's, and they still cannot
describe the same plugin.

**The design note that said this state heals itself was wrong, and that is worth more than the fix.** The
block argued `[NOT-INSTALLED-HERE]` was practically unreachable because the missing-record state *"HEALS
ITSELF"*. Round v9 settled it with the only test that can: after the first session start rewrote the
administration, a **second** fresh session wrote nothing at all — `installed_plugins.json` kept its mtime to
the tick and the verdict was identical. So the truth is the opposite of self-healing: the *first* session
start rewrites the administration and later ones do not, which makes the post-write state stable,
persistent and observable. A state that really healed itself would need no marker; this one waits for you.
Corrected in `check-report-lib.ps1`, in `check-roster-sync.ps1`'s and the hook's copies of the same claim,
and turned into a sentence a reader can act on in `specialists-init/SKILL.md`.

**#324 — the roll-up promised details that the hook filtered away.** `[RECORD-SHAPE]`'s roll-up ends with
*"Details below."* It is true when the check is run by hand and false in a session, because
`roster-sessioncheck.ps1` forwards only lines matching `[RECORD-SHAPE]` and the details were `[SKIP]` lines.
That is the context that needs them most: **the remedy lives only in the detail lines**, and the three
shapes have three different ones. A reader was told an administration problem exists, told the details
follow, and given neither the detail nor a way to reach it — a fix that stopped one sentence short of being
actionable.

The detail lines now carry the marker themselves, so the promise holds in both contexts and the hook's
filter needs no change. Still plain `Write-Host`, never `Write-Info`: carrying the marker must not smuggle
the severity back in through the counting summary, and the fixture asserts that `Summary: 0 error(s),
0 info signal(s)` survives. Why this marker and not `[ORPHANS]`/`[NOT-INSTALLED-HERE]`, whose per-plugin
lines still stay out: those restate their headline, these carry the remedy. The difference is content, and
the hook's docstring now says so rather than leaving it to look like inconsistency.

**One correction pulled in from the neighbouring issue.** The `duplicate` detail line said a repair install
produces the stray second record; #325 measured that a **same-scope** install replaces cleanly and it is a
**scope mismatch** that accumulates. The line now says so. The full narrowing, in `SKILL.md` and in the
design note, belongs to #325's own PR — leaving a measured-false clause standing in a line this PR rewrites
was not defensible.

### Tested

- `check-report-lib.tests.ps1` (154 asserts) — the `pathless-only` shape, asserted with its pairing: the
  permissive predicate must *not* move with it, and a plugin with no record of any kind must stay out of
  this predicate so exactly one marker ever speaks.
- `roster-sync.tests.ps1` (275 asserts) — 11j **reversed**, plus a new 11j-2 that counts the
  `[RECORD-SHAPE]` lines rather than pattern-matching them: the property under test is *how many lines the
  hook's filter picks up*, and a bare `-match` would pass on the roll-up alone, which is the exact state the
  fixture exists to distinguish.

**Two asserts changed direction, and both say why in place.** They used to pin the silence — *"pathless
record: not this marker — it judges only records scoped to THIS path"* — on the reasoning that a pathless
record is step 0b's scopeless-install warning. That reasoning was not wrong about what it had seen; it was
wrong about the population. A pathless record is also something a session start **manufactures** out of a
correct one, and an install warning cannot own a state nobody ran a command to produce. A test that reverses
without recording that is indistinguishable from a test someone weakened to get green.

Plugins: specialists

Plugins: specialists

[PR #345](https://github.com/DaveKJohn/davekjohns-workshop/pull/345)

---

### #344 · The PR closes the issues it resolves · Feat · 2026-08-01

Dave, reading the changelog: *"a lot of new things in the changelog but all 20 issues are still open.
How does that work?"* Two separate answers, and only the second is a defect.

**Eight of them were done and simply never closed.** PRs #341, #342 and #343 repaired real findings —
#334, #329, #335, #338 · #328, #339 · #332, #331 — and every one of them referenced its issue as a
**plain mention**. GitHub auto-closes only on a *closing keyword*, so nothing closed on merge, and the
manual `gh issue close` afterwards was skipped **three times running**. The changelog said done; the
tracker said open. The eight were closed by hand, each with a comment naming the PR that fixed it.
The other twelve are genuinely open work (#322-#325, #327, #330, #333, #336, #337, the round dossiers
#326 and #340, and the older #215) — nothing was wrong with those.

**This entry is the gate, because a third generation of the same slip is a class, not an instance.**
`open-pr.ps1` now forces the decision instead of trusting anyone to remember it:

- `-Resolves "331,332"` writes a `## Resolved issues` block with **one closing keyword per line**. Not
  a style choice: GitHub does not distribute a keyword over a comma list, so the list form closes the
  first and leaves the rest silently open — the very failure being gated. The suite asserts the
  *shape*, and asserts that the comma form reads back as closing only the first number, so the
  recogniser cannot report a false green.
- `-NoResolves` declares "this PR closes nothing" and is the honest way past.
- **Neither**, while the changelog entry mentions an issue that is currently **open** → it stops
  before the lint, the tests, and the push, and names what it saw. It runs first precisely so a
  forgotten keyword does not cost forty test suites.
- **PR references are excluded** (`PR #341`, `PRs #341-#343`, `/pull/341`). A gate that fires on every
  branch gets bypassed, and then it guards nothing.
- **An undeterminable state warns, never wedges.** If `gh` is unavailable or errors, the PR proceeds
  with the check stated as skipped; blocking the whole flow on a network hiccup would be worse than
  the bookkeeping slip.

**The post-merge half is its own script.** `verify-resolved-issues.ps1` reads the closing keywords back
out of the **merged body** and checks that each issue really reached `CLOSED`, closing any that did not
(comment first, then close — `gh issue close --comment` with a multiline body drops the comment).
Reading them back rather than reusing the parameter is deliberate: a second tally is how the #275
preview/apply drift started. It is a separate script rather than a step inside `ship-pr.ps1` because it
is the one part of that chain that **mutates state outside this repo** — it posts comments and closes
issues — so inline would have meant untestable write access. It doubles as the tool for the manual
catch-up above, and `-ReportOnly` inspects without touching anything.

### What the reviews changed, and the one that mattered

**Victor found a way this branch could have closed an unrelated issue.** A document explaining the gate
necessarily writes the pattern it explains — this entry did, in prose about GitHub's comma behaviour —
and `open-pr.ps1` copies the entry body verbatim into the PR body. The recogniser read that example as
a real declaration, so the PR would have reported a close and the post-merge step would have
force-closed that issue with a comment crediting a PR that had nothing to do with it. Reproduced on
this file before the fix.

The fix is not an escape: **GitHub does not link a reference inside a code span, so it closes nothing
there either.** Stripping fenced blocks and inline spans makes the recogniser *agree with GitHub*
rather than merely dodge the case. One detail worth keeping — the filler is a run of `|`, not spaces:
blanking with spaces would leave `` Closes `x` #332 `` looking adjacent and reading as live, while
GitHub needs the keyword directly before the reference. That correction came out of a failing assert.

Three more from the same review, each a silent false negative — the direction that matters, because a
missed mention means the gate never fires:

- **A slash-separated list lost all but the first number.** `#334/#329/#335/#338` yielded only `334`:
  the lookbehind excluded `#N` after `/`. Removed; the URL forms were already handled separately.
- **A real issue after a singular PR reference was swallowed.** In `PR #341 and #332` nothing marks
  #332 as a PR. The list scrub now requires a **plural** head (`PRs`, `pull requests`); an unambiguous
  dash range is still scrubbed after either.
- **A partial `-Resolves` went silent.** Naming one of two open mentions left the second unclosed *and
  unreported*. It still does not block (closing one of two is legitimate) but it is now said out loud.

Two accepted limits, measured rather than assumed: the repo's `Name #NN` specialist notation is
indistinguishable from an issue reference, harmless only while specialist ids stay below the open issue
numbers; and the open-issue query is capped, now at 1000 rather than 200, because an issue past the
page boundary would read as "not open" and let the gate pass in silence.

**Edith found a test that passes or fails depending on console width.** The blocked-gate assert matched
a literal phrase in `Write-Error` output, and the child renders that at its own buffer width — with
this repo's path length the wrap can land mid-phrase, so it failed consistently at width 120 while
passing at another. The same wrap hazard was already documented in this suite for the #86 pre-flight
pointers; this was its second instance.

**And then it cost a red CI run, because the first fix was per-assert.** Both gate-output asserts in
`shared-scripts.tests.ps1` were normalized — and the *sibling* suite, written the same afternoon, kept
matching `gh issue list` in a `Write-Warning`. Locally green, red on CI at its width, one assert out of
31, nothing merged. Fixing the two visible asserts instead of the shape that produced them is exactly
the instance-instead-of-class mistake this repo has a standing rule against, and the rule caught its own
author. The fixture now normalizes whitespace **once, centrally**, so no assert in that file *can* be
width-fragile. Verified against the failing phrase directly: with the wrap in place the raw match is
`False` and the normalized match is `True`.

### Tested

- `scripts/tests/pr-issues.tests.ps1` — new, 104 asserts on the decision table, fully offline.
- `scripts/tests/verify-resolved-issues.tests.ps1` — new, 31 asserts driving the post-merge script end
  to end against a fake `gh` that records every call: the comment lands **before** the close and via
  `--body-file`, an already-closed issue is not re-closed, a plain mention closes nothing, a backticked
  or fenced example closes nothing, `-ReportOnly` mutates nothing, and an unreadable body warns without
  failing a ship that already merged.
- `shared-scripts.tests.ps1` — five wiring scenarios against the offline fake `gh`, because a pure
  decision table proves the decision, never that it is *reached*: blocked with nothing reaching `gh`,
  `-NoResolves` through without a keyword, `-Resolves` writing both lines, a PR-only entry not
  blocking, and a failing `gh` warning instead of wedging. One of them asserts the gate **really
  checked** rather than taking the degraded path — without it, the blocked scenario passes while the
  gate does nothing, which is precisely what one bug below did.

**Two PowerShell 5.1 traps, both now pinned by asserts** and recorded in
[Sylvester #15](.claude/specialists/lenses/05-15-extension.md)'s lens because the next script will hit
them too:

1. **`powershell -File` cannot bind an `[int[]]`.** `-Resolves 332,340` arrives as one string and casts
   to the single number **332340** — the comma read as a *thousands separator*. Silent, not an error.
   Every `-File` form fails, so the parameter is a `[string]` with its own parser, and the fixture
   passes it over that same hop.
2. **`@(… | ConvertFrom-Json)` does not flatten.** The parsed array arrives as *one* pipeline object,
   so `@()` wraps a single element that IS the array; `$_.number` then does member enumeration and
   hands `[int]` an `Object[]` that throws. The throw landed in a `catch` that degrades the gate to
   "cannot check" — so **the gate silently never blocked while every pure unit assert stayed green.**
   Assign first, then wrap.

**One duplication closed along the way.** The shared-scripts suite kept its own hand-written list of
which registered scripts are dot-sourced libs (exempt from the dual-context invariant), so a new lib
arrived as a failing assert about an invariant that does not apply to it, fixable only by editing a
second literal nothing tied to the registration. `LibOnly` now lives in the registry itself
(`shared-scripts-lib.ps1`); registering a lib declares its own exception.

Plugins: specialists

Plugins: specialists

[PR #344](https://github.com/DaveKJohn/davekjohns-workshop/pull/344)

---

### #343 · The teardown reports what it keeps, and the pre-flight measures commits · Fix · 2026-08-01

Two findings from test round v10 (#340), both on the teardown's own correctness — and the second is the
third generation of one defect, so it arrives with a fixture rather than a third correction.

**#332 — the pre-flight measured the index, not the commits.** `git ls-files .claude` reports the
**index**: measured in v10, a `git add -A` went through, the following `git commit` failed, and the command
flipped from empty to 20 lines with **zero commits in the repository**. Its comment — `# empty = not
committed yet` — was therefore false in the direction that matters, and this is the one section whose whole
purpose is answering *"do I have an undo?"*. Both printed copies (`UNINSTALL.md` and the skill's own
pre-flight) now run `git ls-tree -r --name-only HEAD`, with the `fatal: ... HEAD` outcome named as the
"no commits at all" case. The skill's *explanation* was wrong in the same way — it said `ls-files` "lists
committed files only" — and is corrected too.

**The gate, because the lineage is #280 → #283 → this.** `teardown-protocol.tests.ps1` gains a seventh
fixture: a tree that is **staged and not committed**. It asserts both directions, because a fixture that
only checks the new command proves nothing — the old command must *also* be shown reporting this state as
committed, which is the false green a reader was handed. The command assertions are scoped to the **fenced
block** rather than the section, so the prose stays free to name `git ls-files` while explaining what it
used to be; a test that banned the string outright would force the document to drop its own history to stay
green.

Two companion observations from the same pre-flight, both now written down: **command 1's success case exits
`1`** (invisible in a shell, reads as a failed command in an agent harness — it is the answer you want), and
**the safety-net commit was scoped too narrowly** — it named only the lens tree, while the teardown also
edits `CLAUDE.md` and, with `-VendorScripts`, writes under `scripts/`.

**#331 — `[FREE]` while bootstrap-written prose survived, reported as neither `[remove]` nor `[KEEP]`.** On
a consumer that had no `CLAUDE.md` before adoption, every byte of that file is `specialists-init`'s, and
after `-Apply` two prose lines stayed — unreported, while the audit printed `[FREE]`. The audit's claim was
narrowly *true* (those lines name no specialist, persona, roster or lens, so nothing loads because of them),
and that is exactly what made the silence the finding: this script's contract with a reader is that
`[remove]` versus `[KEEP]` tells them which case they were in.

They are now reported per line as `[KEEP]`, with a note, and **not removed** — deliberately. The boundary
the teardown keeps is that it takes out lines whose authorship is knowable *and* whose removal costs the
owner nothing: an `@`-import loads something, prose does not, and cutting sentences out of a governance file
to satisfy a counter is the wrong side of that line. `UNINSTALL.md` gains the fifth row in *"What is left
behind, honestly"* — the only entry in that list the plugin itself wrote — and the section's intro count
moved from three to four to match.

**The literal lives in one place.** `Get-ClaudeMdScaffold` + `Test-IsClaudeMdScaffoldProseLine` join
`Get-SeamPaths` and `Get-OrchestratorNote` in `check-report-lib.ps1`, and `bootstrap.ps1` now builds its
scaffold from that source. Third literal to cross the writer/recogniser boundary, and a hand-mirrored
literal is what produced *both* instances of the accumulation bug those functions exist for.

**Second half of #331: `scripts\lib\` was left behind as an empty directory.** The single pruning pass ran
before section 3 put the only file in it on the removal list. It is now one callable invoked twice — deepest
first, returning its labels so the caller keeps one tally, because a second tally is how the #275
preview/apply drift started.

**Verified.** Lint 0 errors, all suites green. `teardown.tests.ps1` gains the **fresh-consumer** fixture
this suite never had — every existing fixture hands the bootstrap a `CLAUDE.md` it already has, so the
branch that *creates* one was never exercised, which is the same blind-spot shape `bootstrap.ps1` documents
about itself. And the refactor was checked against the series' own anchor: a freshly generated `CLAUDE.md`
is still **463 bytes, 0 CRLF, 8 lone LFs** — byte-identical to v10's virgin-profile measurement and to
v5/v6 on a different machine and release.

Plugins: specialists

[PR #343](https://github.com/DaveKJohn/davekjohns-workshop/pull/343)

---

### #342 · UNINSTALL step order: the document and the audit survive until the end · Docs · 2026-08-01

Test round v10 (#340) was the **first time anyone followed `UNINSTALL.md` end to end** — it had travelled
since PR #321 and had never been walked. It broke on itself twice, in the same pattern it warns about one
step earlier for something else.

- **Step 3 deleted the document you were reading** (#328). `UNINSTALL.md` is not part of the plugin
  payload: it ships only in the cached marketplace clone, and `claude plugin marketplace remove` deletes
  that clone (measured: 2.9 MB, gone). After that step the manual existed **nowhere on the machine**, with
  no error and nothing to search for. `marketplace remove` is therefore now **Step 5**, after the
  verification — the last thing removed is the last thing needed — and *Before you start* says to keep a
  copy, pointing at the durable one on GitHub. The page already made exactly this argument for
  `specialists-teardown` shipping inside the plugin; it simply never turned it on itself.
- **Step 4's audit tool went with Step 2** (#328, second half). Step 4 said the teardown's audit *"says
  `[FREE]`"* and offered a re-run *"if you still have the plugin installed"* — which its own Step 2
  guarantees you do not. Reordering cannot fix this half, because the audit lives in the payload the
  uninstall removes. So Step 1 now says to **keep that output** (it is the last point at which it can be
  produced) and Step 4 reads it back instead of asking for a fresh run, naming the honest alternative for a
  reader who did not keep it.
- **#339's open question is answered, and the answer became a rule.** The page used to admit it did not
  know whether `marketplace remove` also deletes the clone and the unpacked cache, and told the reader to
  go look. The looking has been done on a virgin profile — the one environment where an earlier install
  could not obscure it: **the clone goes, the unpacked cache stays** (2,930,310 → gone; 939,860 → still
  there). Stated as the rule rather than the two measurements: **the unpacked cache belongs to the
  marketplace, not to the install** — `marketplace add` creates it (absent → 939,768 bytes, install record
  still `{}`), `marketplace remove` does not remove it, and no `plugin install`/`uninstall` is involved
  either way. Step 5 carries the manual delete.
- **What a torn-down profile actually looks like**, replacing "clean" with something checkable: three files
  exist that were absent before adoption — `installed_plugins.json` (35 bytes), `known_marketplaces.json`
  (288 bytes, no longer naming this marketplace) and `~/.claude/settings.json` (22 bytes) — none holding
  anything of this family's. Plus a per-location table saying which step closes which, including the one
  entry **no step closes for you**.

**Sweep, as PR #341 established for this class:** no count claim in the page was invalidated by adding a
fifth step (the "two removals" framing is repo-vs-machine and unaffected), and the three pages that link
here — the QUICKSTART, the family README twice — describe the order without numbering it, so none needed a
matching edit. Both new anchors follow the existing `#step-N--<slug>` pattern.

[PR #342](https://github.com/DaveKJohn/davekjohns-workshop/pull/342)

---

### #341 · QUICKSTART entry path: prerequisites, the settings fragment, and the first command · Docs · 2026-08-01

The first four findings of test round v10 (#340), all of them on the stretch a consumer walks *before*
the adoption path begins. v10 was the first round run on a **virgin Windows user profile**, which is why
none of this was findable earlier: on an occupied machine every prerequisite below was satisfied years
ago.

- **A `Before you start` section, which the QUICKSTART did not have** (#334). Claude Code installed and
  `claude` actually running (pointing at Anthropic's own [setup
  documentation](https://code.claude.com/docs/en/setup) rather than an install command that would go
  stale here), signed in, and on Windows raising the execution policy — a fresh profile defaults to
  `Restricted`, which blocks every `.ps1` **including `claude.ps1` itself** on an npm install, so this
  page's own first command failed with a `PSSecurityException`. The `PATH`/full-restart symptom is
  recorded as context rather than as a defect, because it is partly an artefact of the install route that
  measurement took.
- **The first executable command was a dead end, and now it is not** (#329). The marketplace is
  registered by a **session start**, not by writing `extraKnownMarketplaces` — measured in three states,
  and the CLI's own error (`Marketplace 'davekjohns-workshop' not found. Available marketplaces:
  claude-plugins-official`) reads as a typo rather than as a missing step. Step 1 now restarts first, with
  `claude plugin marketplace add <source> --scope project` as the no-restart alternative. That command
  gets its own caveats because it breaks the page's pattern twice: it takes a **source** where everything
  else uses the marketplace *name*, and it defaults to `--scope user` — which would rebuild #279 in a
  fourth command. Its `--scope project` is flagged as **documented rather than measured** (from the CLI
  `--help`; #329's measurement was taken at the default scope).
- **Step 1's fragment now parses when pasted, and `.claude` no longer means two things silently**
  (#335). The `jsonc` block with a comment and no outer braces is a complete `json` file, with the
  merge case named for readers who already have a `settings.json`. The repo-level `.claude/` is
  identified as a directory to **create**, and a blockquote separates it from the machine-level
  `~/.claude/` the verification query reads — one consumer read the former as something still to be
  *installed*.
- **Reaching the documents at all** (#338). A pointer to the Quickstart and UNINSTALL.md at the **top**
  of the root README, where a reader handed only the repository stands, instead of two-thirds down under
  `## Consumption`. The `specialists-teardown` skill now names its own missing half: the machine side of
  leaving lives in `UNINSTALL.md`, which ships in the marketplace clone and not in the payload, and was
  reached in the measurement **only by grepping blindly**. And a warning that an agent pointed at this
  page may not read it: `WebFetch` refused a verbatim request and then returned a summary that
  understated the document's size and **invented an enumeration for Step 2** that the page does not
  contain.

**The act count moved from five to six, in all three places at once.** Adding the registering restart made
the `enable → refresh → install → restart → verify` line wrong — the exact cross-document count that #297
and #305 exist to keep aligned, asserted in the QUICKSTART, the family README and `specialists-init`'s
step 0. It is now `enable → restart → refresh → install → restart → verify` in all three, with
`specialists-init`'s letters absorbing it (`0a` is two acts). Folding the restart into act 1 would have
kept the number at five and was rejected deliberately: being folded into another act is what kept this
step unwritten while it was already required. Verified with the emphasis-tolerant sweep #305 prescribes —
the remaining `five steps` hits all belong to the **migration** path (steps 0–4), a different procedure.

**One correction pulled in from outside this branch's four issues.** The bold claim *"Those keys do not
install anything, though"* sits in the exact paragraph #329 rewrites, and #327 falsifies it: on a virgin
profile with the marketplace registered, a single session start wrote a full project-scoped install
record, indistinguishable from the one the documented command produces. Leaving a measured-false sentence
standing inside a paragraph being rewritten was not defensible, so it is corrected here — stating what was
measured, that the session doing the writing still loads nothing itself, and that whether this makes Step
1's two commands redundant is **untested end to end**. That last question needs one round on a fresh
profile and stays open.

Plugins: specialists

[PR #341](https://github.com/DaveKJohn/davekjohns-workshop/pull/341)

---

### #321 · An UNINSTALL document beside the QUICKSTART · Docs · 2026-08-01

**The Quickstart has had no counterpart since the day the reversibility requirement was set.** Adoption
had to be reversible *"at any moment"* (Dave, July 29, 2026), and the machinery for it exists — the
`specialists-teardown` skill, measured across five adoption rounds. What did not exist is the page a
consumer reads. The removal was documented only inside a 452-line skill written for the people who
maintain it, and split across two more places: the machine-side half lived in the Quickstart's *Staying
up to date* section, under a heading nobody looking to leave would open.

[`UNINSTALL.md`](claude-code-plugins/claude-specialists/UNINSTALL.md) is that page — the mirror of the
Quickstart, four steps, same reader. **Its organising claim is that there are two removals, not one:**
out of your repo (the seam, the import, the scaffolds — the skill) and off your machine (the record, the
keys, the registration, the cache). Confusing them is the ordinary failure: a repo teardown leaves the
plugin loading, a plugin uninstall leaves a repo full of lenses and a broken import.

**And the order between them is the one irreversible mistake in the whole procedure.** The teardown skill
*ships inside the plugin*. Uninstall first and the skill goes with it, leaving a repo full of generated
files and no tool that can still tell which of them it wrote — the classification lives in the skill, not
in the files. Same class of trap, one step later: `-VendorScripts` has to be used while the plugin is
still installed, or a consumer that built on the shared scripts loses its daily git workflow.

## Two things measured while writing it, both of which the docs had wrong or missing

**1. The Quickstart said the CLI does not name `local`. It does.** The sentence read *"a third scope the
CLI's own flag list does not mention"*. Re-measured August 1, 2026 on CLI `2.1.220` — the same version
[#315](https://github.com/DaveKJohn/davekjohns-workshop/issues/315) was measured on: `install`,
`uninstall` and `disable` each print *"user, project, or local"* in their own `--help`, and `update`
prints a **fourth**, `managed`. The finding underneath was always right — a reader who met a `local`
record had nothing in this family to look it up in — but the sentence blamed the wrong party. Corrected
to say what is true: the flag list was never the gap, **these pages were**.

**2. Three machine-level locations this family had never named.** Taken from a machine that has run it,
not estimated: `~/.claude/plugins/data/<plugin>-<marketplace>/` (a persistent data directory that
`uninstall` deletes unless `--keep-data`), `~/.claude/plugins/cache/<marketplace>/` (the unpacked
payload, beside the git clone under `marketplaces/`), and `~/.claude/plugins/known_marketplaces.json`
(the registration, removed by `claude plugin marketplace remove`). `git grep` over the whole payload:
**no hits for any of them.** So "get this machine back to a clean state" was not answerable from the
family's own documents. It is now, including the honest gap — whether `marketplace remove` also deletes
the two cache paths from disk is *not* established, and the page says to check rather than assume.

**One trap that follows from #314 and is worth its own line:** an enable key alone is enough for a
session start to write a missing install record by itself. So a machine where `enabledPlugins` still
names the plugin **heals its own uninstall**, silently, on the next session. Remove the keys before
re-checking the record, or the verification keeps finding a record with a fresh timestamp and nothing to
explain it.

## The gate could not see the new page, and that is the part that got closed properly

`UNINSTALL.md` landed in the family directory and **no check looked at it**: not the dead-link scan, not
check 11 (printed lifecycle commands), not check 12 (the install-record query) — all three take their
scan set from `$linkFiles`, and the family's entry there was a hardcoded list of two names,
`'README.md', 'QUICKSTART.md'`. A brand-new consumer-facing page, printing exactly the class of command
those two checks exist to police, was invisible on the run that introduced it.

**Adding a third name would have repeated the fix rather than closed the class**, and the evidence is
that the list itself came from [#103](https://github.com/DaveKJohn/davekjohns-workshop/issues/103),
which closed this same gap the same way. A named list is only correct until the next document is
written, and nothing announces the omission. The directory holds the family's consumer-facing pages and
nothing else, so it is enumerated now — non-recursive, since the per-plugin subdirectories are gathered
by their own rules and would otherwise be counted twice. Effect on the real repo: `[link-scan]`
144 → 145, `[lifecycle]` 14 → 16, `[record-query]` 2 → 3, still **0 errors**.

Scenario 33 in `check-plugin-integrity.tests.ps1` pins it, deliberately using a file name this suite has
never heard of — if that scenario ever needs updating because a real document took the name, the
enumeration has stopped being one. **Proven load-bearing:** run against the pre-fix scan set, three of
its assertions fail. The fourth is the interesting one — `Assert-Equal 1 $r33.Code` passed in **both**
worlds, so it was removed rather than kept as decoration, with the measurement recorded in place. A green
that proves nothing is the exact failure this suite exists to catch, and it had just produced one.

All 18 suites green (`check-plugin-integrity` 83 → 88 asserts), lint gate `0 error(s)`.

Plugins: specialists

[PR #321](https://github.com/DaveKJohn/davekjohns-workshop/pull/321)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v3.0.9] - 2026-08-01 — Patch

See [releases/development/3.x/3.0.9.md](releases/development/3.x/3.0.9.md) for the full release notes.

---

### [v3.0.8] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.8.md](releases/development/3.x/3.0.8.md) for the full release notes.

---

### [v3.0.7] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.7.md](releases/development/3.x/3.0.7.md) for the full release notes.

---

### [v3.0.6] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.6.md](releases/development/3.x/3.0.6.md) for the full release notes.

---

### [v3.0.5] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.5.md](releases/development/3.x/3.0.5.md) for the full release notes.

---

### [v3.0.4] - 2026-07-31 — Patch

See [releases/development/3.x/3.0.4.md](releases/development/3.x/3.0.4.md) for the full release notes.

---

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
