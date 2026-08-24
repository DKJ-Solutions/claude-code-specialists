# Development cycle: `feat/close-out-has-three-shapes-v1` · 20260824-110059

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own.** It is the result, and the one part of this file that
> travels verbatim into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

Replace step 6's 'what else might be possible' with the three permitted close-out shapes, so a reply says plainly whether the assignment succeeded and everything that would otherwise wait is filed instead.

Replace step 6's "what else might be possible" with the three permitted close-out shapes, so a reply says plainly whether the assignment succeeded and everything that would otherwise wait is filed instead.

## PLAN

- [x] Establish what was actually wrong, from the requester's own words: not that findings went
      unrecorded, but that the reply's SHAPE left it unclear whether the assignment was finished.
      "Wat nu nog op jou wacht", "waar ik bewust niks mee gedaan heb", "wat nog open staat".
- [x] Check whether #847 already covers it, since it landed the day before and looks adjacent: it does
      not. That rule is the INPUT half -- a finding becomes an issue rather than a question -- and a turn
      can obey it and still close with three paragraphs of open points. The two halves only work
      together, so this step points at that rule instead of restating it.
- [x] Verify the edit is not inside a generated shared block before hand-editing the persona: the
      sentinels sit at lines 191-235, step 6 at 53-82. Hand-editable, and the shared block is untouched.
- [x] Decide the reach, which the issue deliberately left open: **Chris only**, not the shared block that
      feeds all 30 carriers. A subagent's final text is a return value to its caller, not a reply to the
      requester -- so the close-out shape is the orchestrator's, and widening it would put a rule about
      talking to Dave into 30 files that do not.
- [x] Measure the always-on cost, because this persona loads in every session: 16,585 -> 18,276 bytes,
      **+1,691** (about +10%, roughly +420 tokens per session). Named rather than discovered later.

## CREATE

- [x] Step 6 of the fixed ritual in `plugins/teams/team-alpha/personas/01-01-persona.md`: the three
      shapes (done / one decision as a menu / a blocker already parked), the pointer to the filing rule
      that makes the first one normal, and the three phrasings that must stop appearing.

## TEST

- [x] The lint gate on this branch: `check-plugin-integrity.ps1`, 0 errors -- which is the check that
      matters for a persona edit, since it reads the frontmatter, the shared-block sentinels and the
      links. The generated block came out byte-identical, so no drift was introduced.
- [~] No suite: the change is a persona's prose. What could be asserted mechanically -- that the shared
      block is intact -- is what the gate above already reads, and duplicating it in a test would give
      two readers of one rule.

## DEPLOY: `feat/close-out-has-three-shapes-v1`

Step 6 told Chris to summarise *what else might be possible*, and that clause is what produced replies
ending in "what is still open" and "what I deliberately left alone" -- so the requester could not tell
whether the assignment was finished. A close-out is now **one of three shapes**: **done**, and the session
can be closed; **one decision put as a menu**, so the work continues in the same turn; or **a blocker
already parked**, reported as a state that is handled -- the issue filed with its number, the branch
parked. Everything that would otherwise wait becomes an issue at the moment it is found, and the close-out
names what it filed rather than asking about it. This is the output half of the rule #847 landed the day
before: that one says a finding becomes an issue instead of a question, and a turn could obey it and still
close with three paragraphs of open points, which is the pair that made the complaint. **Chris only, not
the shared block**: a subagent's final text is a return value to its caller, not a reply to the requester.

**Score:** 4

### What makes this deploy extra special

It changes how every consumer's sessions END -- the moment a person decides whether they can close the
window -- and it removes work from them rather than adding any: an unanswered list becomes a filed issue
with a number. Costs stated rather than left to be found: this persona loads in every session, and the
step grew by **1,691 bytes**, about +10% of the file and roughly +420 tokens per session. That is the
trade, and it is a small one against a reply whose ending had to be interpreted.

**Score:** 4

### Pull Request

A close-out is done, a decision, or a parked blocker -- never a list of what waits on you
