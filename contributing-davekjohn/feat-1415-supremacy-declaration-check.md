## feat/1415-supremacy-declaration-check

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Issue [#1415](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1415): the **second** of
the two narrow literal greps the prose-contract decline (#1380) recorded as proportionate. The first
shipped yesterday as `check-retired-doc-name.ps1` (#1389, PR #1414); the second had no tracker entry at
all until #1415, only a sentence in a lens.

#### What the issue asked for, and the precondition it set

The issue was explicit that the recorded shape was **inferred, never measured** -- *"it has never been
run as a check, and unlike the retired-name grep it has no measured precision"* -- and it set the
precondition: measure it over the same 8-document corpus first, and hold it to the bar this repo already
uses (the accepted dead-link check, 17 findings / 17 real, against the declined stale-path check, 124
findings / 0 real).

#### The measurement, run before a line of the check was written

Corpus: both BWJ consumer checkouts, the always-on closure of each (`CLAUDE.md` + its `@`-imports) plus
each one's `contributing-davekjohn/README.md` and `CONTRIBUTING.md`. The recorded test is
`wins`/`wint` + `CLAUDE.md` + the contributing page's own filename, all three in the same sentence:

| scope | raw | true | precision | recall of the standing instances |
|---|---|---|---|---|
| line | 0 | 0 | -- | 0 of 2 |
| **sentence** (the recorded shape) | **0** | **0** | -- | **0 of 2** |
| paragraph | 1 | 0 | **0%** | 0 of 2 |

**It scores zero on the one defect it was named to catch.** The reason is exact: the instance is
`smartwatchbanden`'s *"Bij tegenspraak wint `CLAUDE.md` en is de contributor-pagina de bug"*, which names
the contributing page by a Dutch **prose noun**, not by its filename -- the third term is precisely the
one absent, and the filename sits two lines up in a different sentence. Loosening the third term to catch
prose nouns is the step into fuzzy matching #1380 already declined.

#### What replaced it, and why it is still literal

**Adjacency**: `CLAUDE.md` and `wins`/`wint` must sit next to each other, either order, with nothing
between them but whitespace and markdown markup. Still a pure character test -- it never reads what a
sentence means -- but it answers the question co-occurrence cannot: *which* page is declared the winner.
Direction is the entire defect. *"this page wins"* over `CLAUDE.md` is `LAW-THIRD-RANK-ORDER` stated
**correctly**, and a term list scores it identically to the inversion.

Measured on the same corpus: **3 raw / 2 reported / 2 true / 100% precision**, both standing instances
found. The one suppressed hit is a `"…"` quotation -- `xoxowildhearts` quoting the closing line of a page
it **retired**, to explain why it removed it.

#### Two findings this produced that were not in the issue

1. **There are two standing inversions, not one.** #1380's census counted the `CLAUDE.md` preamble; the
   same inversion is stated a second time from the other side in that repo's own
   `contributing-davekjohn/CONTRIBUTING.md:306`, and no candidate measured there ever counted it. Both are
   in `BWJ-ecommerce/smartwatchbanden`. Not repaired from here -- the check is the delivery mechanism, the
   same call #1389 made about its own two measured instances.
2. **The publishing-repo skip the issue required is a guard here, not a repair.** Its stated reason --
   *"this repo's own pages discuss supremacy declarations at length, so without it the source reads as
   consumer drift"* -- does not hold for this detector: measured at **zero** hits in this repo without the
   skip, because every supremacy sentence here names the plugin's page as the winner and adjacency reads
   that correctly. Kept anyway, for sibling consistency and because this is where such sentences get
   written, but recorded as insurance rather than as the repair it is in `check-retired-doc-name.ps1`.

### CREATE

- [x] Measure the recorded three-term test over the 8-document corpus at three scopes, before building
      anything -- the precondition #1415 set. Result above: 0 findings, 0 recall.
- [x] Measure the adjacency alternative on the same corpus: 3 raw / 2 reported / 2 true / 100%.
- [x] Lift the corpus enumeration out of `Get-RetiredDocNameMention` into a shared
      `Get-ConsumerProseDocuments`, so both checks read one definition of which documents are in scope.
- [x] `Get-SupremacyDeclaration` in `entry-scaffold-lib.ps1` -- the detector, the quotation suppression,
      and the whole measurement written into the docstring rather than into a commit message.
- [x] `scripts/lint/check-supremacy-declaration.ps1` -- dual-context root, publishing-repo skip, optional
      `repo-config.ps1`, guarded `measure-context-lib.ps1` load, `[OK]`/`[ERROR]` + exit code.
- [x] `supremacy-declaration-sessioncheck.ps1` in the workflow plugin + its row in `hooks.json`.
- [x] Register the pair in `shared-scripts-lib.ps1` and regenerate the plugin mirrors.
- [x] Declare the deliberate `Assert-OwnCopy` omission in `source-repo-guard.tests.ps1`'s exemption list,
      with the difference from its sibling stated rather than inherited.

#### One doc deliberately not touched

The root `README.md` names three session hooks as examples and then says, in the same paragraph, that
**the set is not enumerated in prose anywhere** -- it was, as three, and went stale twice inside two days.
Adding a fourth example is the exact pressure that produced that sentence, so it is left alone; a consumer
meets this hook where it belongs to them, in `CONTRIBUTING-portable.md` and the plugin's own `README.md`,
and `hooks/hooks.json` stays the one authority that cannot go stale.

### TEST

- [x] `scripts/tests/supremacy-declaration-gate.tests.ps1` -- 27 asserts: the shared corpus on its own,
      both measured instances as fixtures, the suppressed quotation, and the **direction** case (the rank
      order stated correctly must not fire), which is the assert that fails first if anybody loosens the
      pattern back toward co-occurrence.
- [x] Run it: 27/27 pass.
- [x] Re-run the sibling suite after the corpus refactor: `retired-doc-name-gate` 25/25.
- [x] `source-repo-guard.tests.ps1` after the exemption: 46/46.
- [x] `check-plugin-integrity.ps1`: 0 errors.
- [x] Run the check against both live consumers and against this repo: 2 findings in `smartwatchbanden`,
      clean in `xoxowildhearts` (the quoted historical line correctly suppressed), skip here.
- [x] Measure the seventh session hook's cost, and re-measure the sibling in the same run rather than
      quoting its recorded figure -- 781 ms against 799 ms.

#### One defect the suite caught in itself, kept because it is a real trap

The first run failed one assert. The cause was in the **test**, not the lib: PowerShell unwraps a
single-element array on return, and under `Set-StrictMode -Version Latest` `.Count` on the resulting
scalar **throws** rather than answering 1. The zero-finding asserts survive unwrapped only because
`$null.Count` is still 0, which is exactly what makes it easy to write and hard to see. Wrapped in `@()`
with the reason on the line.

### DEPLOY: feat/1415-supremacy-declaration-check

A consumer is now told, at session start, when its own always-on prose declares its `CLAUDE.md` the
winner over the workflow's contributing page -- inverting the rank order the plugin legislates. This is
the one contradiction the declined prose-contract framework (#1380) proved was *structurally* invisible:
a pointer test only ever flags sections that cite nothing, so a page that names its source and then
overrides it four lines later can live nowhere but among the findings such a test suppresses.

The recorded design for it did not survive being measured, which is the more useful half of this change.
The three-term same-sentence grep the decline wrote down scored **0 findings and 0 recall** on the single
defect it was named to catch -- the real sentence names the contributing page by a prose noun rather than
by its filename. What ships instead is **adjacency**: `CLAUDE.md` and `wins`/`wint` beside each other,
which is just as literal but reads *direction*, and direction is the whole defect -- *"this page wins"*
is the same rank order stated correctly. On the same 8-document corpus: 3 raw / 2 reported / 2 true /
**100% precision**, against a bar this repo sets with an accepted check at 17/17 and a declined one at
124/0. It also found one standing inversion more than the original census knew about.

**Score:** 3

#### What makes this deploy extra special

N/A -- this repo's audience is its own maintainers and the repos consuming the plugin. The change reaches
a consuming repo at its next plugin update, as one more read-only session-start line that stays silent
unless that repo has the defect; it reaches no subscriber of a service, because there is none.

**Score:** N/A

#### Pull Request

A consumer-side check for an inverted supremacy declaration
