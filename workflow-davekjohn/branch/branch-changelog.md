## `feat/the-step-list-follows-the-sdlc-arc` changelog

### Branch title

the step list carries PLAN, CREATE and TEST, and the changelog entry is named as the deploy

### Branch ID

20260814-225947

### Branch type

feat

### What does the change on this branch bring to main?

[#655](https://github.com/DaveKJohn/claude-code-specialists/issues/655): a branch's own plan now follows
the SDLC arc instead of being an ad-hoc list. `### Steps` is scaffolded with **PLAN**, **CREATE** and
**TEST**, and the placeholder step sits under CREATE.

**The issue's hardest open question was what DEPLOY means in a repo whose deploy is the merge, and Dave
answered it in a way that dissolves the problem rather than working around it: DEPLOY is not a step, it
is the result — the part that travels to `CHANGELOG.md`.** So the arc does not fit inside one file; it
runs across the pair. `branch-progress.md` carries the three phases that stay behind and are reset after
the merge, and `branch-changelog.md` **is** the deploy phase.

That also retires an objection this branch started with. Measured first: a DEPLOY checkbox could only be
unresolvable — `open-pr` refuses to push while any step is open, and the merge happens after the push — or
ticked before it happened. The conclusion at the time was "three phases fit, the fourth does not". Dave's
answer is better, because it explains a rule that until now simply *was*: the step-list gate refuses a step
written for after the merge because post-merge belongs to the other document.

**The arc is drawn on top of the gate, never into it.** `Get-BranchProgressFindings` reads lines beginning
with a step mark, so a heading is invisible to it — which is why this could be added without touching the
mechanism at all. Asserted in that order: the headings are present, *and* they change no verdict. A test
also holds DEPLOY's absence, so somebody adding it later goes red rather than shipping an untickable box.

**An empty phase is a statement, not a finding.** A branch with nothing to test says so by leaving that
heading bare — the same tolerance that lets a one-commit typo fix carry no step list at all. Refusing it
would be exactly the ceremony that tolerance exists to prevent.

The phase names come from the wording seam, so a consumer can rename them; an empty list switches them off
and restores the pre-#655 shape, which the scaffolder still writes.

### Significance

#### Tier 0

Every branch from here on opens with the same three headings, and the reason DEPLOY is missing is written
where somebody reaching for it will read it. The gate is untouched, which is the part that had to be
proven rather than assumed.

**Score:** 3

#### Tier 2

Every consumer of `workflow-davekjohn` gets the arc on their next branch, through a plugin update rather
than by choosing to. Nothing they have written breaks: an existing step list keeps working, the gate reads
it exactly as before, and a repo that does not want the phases can empty the seam value.

**Score:** 3

### Pull Request

