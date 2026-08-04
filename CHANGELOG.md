# Changelog

Where this repo stands: under **Latest Release** the version currently cut, and under **Pull Requests**
everything merged since it — so the top of this file is the published state and the rest is what is
queued behind it. Every release ever cut is listed in
[`releases/README.md`](releases/README.md); how the mechanism works (entry files, folding) is described
in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Latest Release

The most recent release — every earlier one is listed in
[releases/README.md](releases/README.md), with its date, type and title.

**v3.4.0** — 2026-08-04 — Minor

See [releases/internal/3.x/3.4.0.md](releases/internal/3.x/3.4.0.md) for what this release is worth. The full per-PR record is in [releases/development/3.x/3.4.0.md](releases/development/3.x/3.4.0.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.
### #459 · A documented test gap is a question, not a conclusion · Docs · 2026-08-04

**Tycho #18's manual gained the follow-up question that belongs behind "flagging test gaps".** Naming a
gap honestly is where his manual stopped, and in practice that is where the work starts: a file that
drives a live remote, a real filesystem or a real clock cannot be covered as a whole, but it is almost
never *uniformly* untestable. The parts that are **pure functions of their input** can move to a library
and be asserted there, shrinking the gap from "this file" to "the orchestration order in this file". A gap
that has been documented and left at that reads as a boundary of what is possible, when usually it is a
boundary of what was attempted.

**Why it earned a place rather than being a nice thought: a documented gap had been hiding a shipped
bug.** `ship-pr.ps1` carries an explicit test-gap note — it drives live git/gh — and its step 2 held an
inline parse whose "no open PR found" guard could never fire and whose missing-PR case produced the empty
string, so the script would have run `gh pr merge ''`. **The defect was not in the orchestration the note
excused; it was in a pure function of text that had no business being in there.** Moving it to
`pr-issues-lib.ps1` is why the same mistake is now a failing assert instead of a comment. The repair
shipped in [#458](https://github.com/DaveKJohn/claude-code-specialists/pull/458).

**The wording is deliberately free of anything from this repo**, per the convention that personas and
manuals carry no repo-specific detail while skills carry the evidence behind a procedure. The scripts, the
PR and the measurement live in the `ship-pr` skill and in that script's own docstring, where a consumer
meets them; the manual states only the reasoning that travels.

Plugins: specialists

[PR #459](https://github.com/DaveKJohn/claude-code-specialists/pull/459)

---

### #458 · ship-pr resumes a branch whose PR is already open · Feat · 2026-08-04

**`ship-pr` was unusable on exactly the branch you most want it for: one whose PR is already open.**
Step 1 calls `open-pr.ps1`, whose `gh pr create` was unconditional. A duplicate makes `gh` exit non-zero,
step 1 dies, and **steps 2 through 6 never run** — the CI watch, the merge, the fold, and the issue
verification. So a branch whose PR was opened in an earlier session had to be merged and folded by hand,
which is the five-step sequence `ship-pr` exists to remove. Measured on
[PR #457](https://github.com/DaveKJohn/claude-code-specialists/pull/457): merge, sync, and fold were all
done by hand that evening, one command at a time, because the one script that does it refused the branch.

**The repair is in `open-pr.ps1`, not in the orchestrator, and that placement is the whole design.** One
`gh pr list --head <branch>` up front, and if there is a PR the *only* thing skipped is the create — the
resolves gate, the scaffold gate, the lint gate, the test suites and the push all still run against the
new commits, and the script exits **0** with the PR number. Putting the check in `ship-pr` instead would
have skipped the gates and the push along with the create, and left `open-pr` on its own still failing on
the same branch.

**Title and body are left alone, with one exception that is not a matter of taste.** A body edited on
github.com must not be overwritten by a freshly generated template — a stale title is at least visible on
the PR, an overwritten body is gone. But a `-Resolves` the existing body does not yet carry **is
appended**, because dropping it is the #341–#343 failure arrived at from the other side: GitHub closes
what the body says *at merge time*, so the issue would stay open, and `ship-pr`'s step 6 reads that same
body back and would confirm the same silence. `Add-ResolvesBlock` is idempotent per issue, so nothing is
duplicated and a run with nothing to add writes nothing at all. A failed append is a hard `exit 1`: the
branch is pushed by then, and merging it would publish the loss.

**Symmetrically, an existing body that already says `Closes #332` now satisfies the resolves gate.**
Without that, resuming such a branch would be blocked for not repeating a decision that is already
published on the PR — and that the gate could not change anyway, since GitHub honours the body it has,
not what the run declares.

**The parse became a library function so it could be tested at all.** `Get-ExistingPrRecord` in
`pr-issues-lib.ps1` is a pure function of the JSON text, which is the part worth a test: Windows
PowerShell 5.1 hands a parsed JSON array to the pipeline as a **single** object, and indexing the result
with `[0]` returns `$null` on an empty list — a wrong answer that looks like a right one. Both shapes have
already cost this repo a silent bug. Sixteen new asserts cover the empty list, the single record, several
records, unparseable JSON, a record without a number, and the append being idempotent. `open-pr.ps1`
itself remains the known test gap it always was: it drives a live remote.

**The review of that lookup found a second, worse defect in `ship-pr` itself — and this one was already
shipped.** Step 2, which finds the PR number to merge, parsed gh's answer as
`$prs = @($prList.Output | ConvertFrom-Json)` and then read `$prs[0].number`. Both halves fail on Windows
PowerShell 5.1, and it was **measured, not reasoned**: the count is `1` even for `[]`, so the
`if ($prs.Count -lt 1)` guard — "No open PR found, stopping" — was **dead code that could never fire**;
and `$prs[0]` is the whole `Object[]`, whose `.number` works only by member enumeration, yielding the
**empty string** when there is nothing. With no open PR, `$pr` became `''` and the script went on to run
`gh pr checks ''` and `gh pr merge ''` — in the one script that writes to `main`, with nothing in the
output naming which PR it thought it was merging. It now uses the same tested `Get-ExistingPrRecord`, so
`$null` means no PR and the guard is real. Two asserts pin the old shape as wrong, so a future
simplification back to it fails in the suite rather than on `main`.

**Both lookups now pin `--base main`, which is load-bearing rather than symmetry.** Without it the query
answers "does this branch have an open PR *anywhere*", and a consumer running stacked PRs
(`branch -> branch -> main`) would get the wrong one: `open-pr` would skip creating the PR to `main`, and
`ship-pr` would find and **merge the stacked PR into its intermediate base**. GitHub allows one open PR
per `(head, base)` pair, so with the base pinned there is at most one answer — which is also why
`--limit 1` cannot hide a second candidate.

**Every unreadable answer collapses to "no existing PR", deliberately.** A failed query or a bad payload
falls back to precisely the behaviour this script had all along — a duplicate `gh pr create` that `gh`
refuses with its own message — rather than wedging the PR flow on a network hiccup. Same reasoning as the
resolves gate's undeterminable-state branch.

Plugins: specialists

[PR #458](https://github.com/DaveKJohn/claude-code-specialists/pull/458)

---

### #457 · The v3.4.0 internal note: what this release is worth · Docs · 2026-08-04

**The note itself, and the first live proof that the link-repointing chain works.** `new-internal-note.ps1`
now updates `CHANGELOG.md` as well as writing the skeleton, and this is the first release where that ran
for real. Before: `See [releases/development/3.x/3.4.0.md] ... for the full release notes.` After:
`See [releases/internal/3.x/3.4.0.md] ... for what this release is worth. The full per-PR record is in
[releases/development/3.x/3.4.0.md].`

**It found the block by the shape it was warned about.** `## Latest Release` no longer carries a
`### [vX.Y.Z]` heading — that went in #454, because a section holding exactly one release does not need a
per-version heading. `Set-ReleaseInternalNoteLink` matches the bold `**vX.Y.Z**` line as well, which is
the only reason this worked. Had it known only the old heading, **the failure would have been silent**:
the cut succeeds, the note is written, and the link simply never moves. That was the argument for teaching
it both shapes, and it is now an observed outcome rather than an argument.

**What the note says, written for the reader it names.** Not a list of sixteen changes but four claims:
undocumented tools were costing measurable work (the two-day fold-by-hand instance, plus the gate that
makes it non-repeatable), shipping a release now takes a fraction of the attention (five manual steps to
one command — and this very cut caught two defects before publication *because* the process has an
inspection point), three projects had each written the same repair tool and now share one, and verifying
an inbound report's premise avoided a day of work on a problem that had ceased to exist.

**The open section is deliberately a snapshot**, per the rule that earned itself in #439: this file is the
Release body, so anything phrased as a live claim goes stale in place within hours. It names the
unpublished Release page, the blueprint proposal filed as
[#456](https://github.com/DaveKJohn/claude-code-specialists/issues/456), and the two items consciously not
backfilled — each as "open at this release", not as a statement about now.

[PR #457](https://github.com/DaveKJohn/claude-code-specialists/pull/457)

---

### #455 · The v3.4.0 highlights, written for the consumer instead of assembled from entries · Docs · 2026-08-04

**831 lines to 91**, and the reduction is a side effect rather than the goal. The generated draft is the
changelog entries stacked up — text written for whoever reviews the diff. This is the first highlights
document written from the other end: what a reader of this plugin can now do, get quieter, or switch on.

**The model came from the storefront repo this tier was borrowed from** (`davekokbwj/smartwatchbanden`),
where the good examples open with what a visitor can *do* and put the reason with its evidence right
behind it. Its `v2.11.0`: *"Bezoekers kunnen nu met pijltjes door álle productafbeeldingen bladeren"*,
then **Waarom** with a measured conversion figure. Compare our `v3.3.0`, which opened with *"A PR is now
refused while its changelog entry still carries the scaffolder's own wording"* — accurate, and written
from the system's side.

**Turning the perspective around surfaced the strongest item, which the draft had buried.** #442 appeared
there as a rule about our own gate — a shared script's parameters must be in its skill. From the reader's
side it is this: *you spent two days committing the fold by hand while `-Push` already existed, because
our page did not mention it.* That is somebody's wasted work, and it was sitting underneath a process
statement. It now leads the section, with the command to stop doing it.

**What the reordering cost the draft's own top item.** The draft opened with `#453`, our
README/HISTORY split — a sentence about this repo's internal file layout, as the first thing a consumer
reads. It does not appear in the finished document at all.

**Three headings that answer questions instead of listing changes**: *What you can do now* · *What gets
quieter* · *What you can turn on*, plus *Worth knowing* for the two facts you need once but need not act
on.

**One thing from the model was deliberately not copied: dropping the technical names.** `-Push`,
`Get-ReleaseHistoryMode`, `-Check` are not jargon to this reader — they are the buttons. In a storefront
repo `product-card.liquid` is noise because that reader never touches it; here, removing the script names
would make the document unusable. **The audience differs, so the rule "strip the technical detail"
transfers as "strip what the reader does not touch" instead.**

**Also worth recording: the source is not itself consistent.** That repo's `v2.13.0` is as
implementation-heavy as anything we produce, with liquid snippets and CSS classes in the consumer tier. The
model is its `v2.11.0`, not the folder.

[PR #455](https://github.com/DaveKJohn/claude-code-specialists/pull/455)

---
