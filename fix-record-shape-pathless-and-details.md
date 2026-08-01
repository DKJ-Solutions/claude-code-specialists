### The demoted record is reported, and the details reach the session · Fix · 2026-08-01

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
