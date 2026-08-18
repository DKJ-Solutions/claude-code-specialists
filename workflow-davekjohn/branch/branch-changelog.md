## Branch `docs/marker-literal-trap` changelog - 20260818-222226

### What does the change on this branch bring to main?

#### Tier 0

Tessa's lens gains the written convention for describing a lint marker without tripping it. Check 10
(`[skill-list]`) masks **fenced** code only before it scans for an enumeration marker -- deliberately,
because a real span's own claimed names are single-backtick quoted, so masking inline code would erase
the very names the check exists to read. So a document that writes *about* the mechanism in running
prose, quoting the opening marker inline, reads to the gate as a span opened and never closed, and the
branch does not push.

**The trap is not the finding; the repeat is.** It has fired twice in three days, both times on a
branch's own two files: `03bf135` (August 16, 2026) on `fix/rename-continue-skill-to-handover`, and
[#745](https://github.com/DaveKJohn/claude-code-specialists/pull/745) again on August 18, in a step list
that named the mechanism as the model for a gate somebody should build later. Both times the lesson was
written down -- into the step list, which the fold resets. **The record was destroyed by the same commit
that shipped the repair**, which is the merge-shaped expiry date every branch file carries and precisely
what the repo's rule about securing lessons in the docs exists to prevent. This bullet is the durable
copy the two earlier ones never became.

**One claim is made true rather than struck out.** Check 10's own comment already states that the fence
form is documented as the convention -- *"Tessa documents the fence form as the convention, not inline
code"* -- and it was not. The lens now documents both routes: the fence for showing the bare marker text,
and naming the mechanism instead of the syntax (*"the lint-checked enumeration spans"*) for running
prose, which is what both repairs actually settled on.

**Score:** 2

#### Higher than tier 0?

N/A -- `.claude/specialists/lenses/` is this repo's own lens layer and is not plugin payload, so nothing
here reaches a consumer. The convention it records is about a check that only runs in this repo's gate.

**Score:** N/A

### Pull Request

the marker-literal trap gets a written convention
