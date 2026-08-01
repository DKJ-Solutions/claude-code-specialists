### The PR closes the issues it resolves · Feat · 2026-08-01

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
