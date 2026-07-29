### Repo-wide guard that every native call site uses Invoke-NativeCapture · Feat · 2026-07-29

`shared-scripts.tests.ps1` already proved the #107 pitfall from two angles: the mechanism (a bare
native call with stderr is terminating under `EAP=Stop`, the capture pattern is not) and the helper
(`Invoke-NativeCapture` does not throw, reads the real exit code, restores the caller's EAP). What it
could not prove is **coverage**. Section (c) names call sites by hand — open-pr's `push`, its
`gh pr create` — so it guards the two that already regressed once and says nothing about the next
one. A new script, or one new line in an existing one, can reach for a bare `git ... 2>$null` and
every assert stays green, because nothing is looking there.

Added: a repo-wide static scan over every `.ps1` in the repo — the workshop's own `scripts/` **and**
the plugin payload (`hooks/`, `skills/`, each plugin's `scripts/` mirror). Two forms count as
protected, and only these two: the call sits in a function that sets `EAP=Continue` first (what the
helper does), or it sits in a `try`/`catch` so the terminating record is caught and the script picks
its own fallback deliberately. A file that never sets `EAP=Stop` is not at risk and is skipped.

The scan runs over a fixture as well, holding all four shapes side by side. A guard that can no
longer find anything is not a guard: without that case, an over-eager try/catch exemption would
exonerate the whole repo and still report green.

**Result here: clean — 36 scripts, zero unprotected call sites.** The centralization from #107/#114
holds. This adds the guarantee that it keeps holding.

**Why it was worth writing.** The same class of bug was found four times in the smartwatchbanden
consumer on 2026-07-29. One was known — a successful `git fetch` killed a `ship-pr` run right before
the fold step. The other three nobody had noticed: `lint-brain` fell over the moment `-Path` pointed
outside a git repo, `switch-account` died on `gh auth status` before it could switch anything, and
`archive-and-remove-theme` plus `rename-specialist` made their own clear error messages unreachable.
Every one of them was a call site no per-site assertion covered. That consumer maintains a local
`ship-pr.ps1` fork instead of the shared one, which is how it re-derived a pitfall this repo had
already solved — a separate finding, recorded there.

7 new asserts; `shared-scripts.tests.ps1` goes from 110 to 117, and all 18 suites stay green.

**Written 2026-07-29, landed 2026-07-31, and re-measured rather than taken on trust.** The branch sat
unmerged across five releases (v2.13 → v3.0.7), during which the repo gained scripts and suites — so the
claims above were re-run against the rebased tree instead of carried over: the scan now covers **36**
scripts (was 35) and the suite count is **18** (was fifteen). The assert numbers held exactly. Worth
recording because a stale entry file is the one artifact that folds into `CHANGELOG.md` as history: had it
been folded unchecked, the changelog would carry two numbers that were true in July and false on arrival.
