### A documented test gap is a question, not a conclusion · Docs · 2026-08-04

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
