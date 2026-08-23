# Development cycle: `main` · <timestamp of the moment this branch was created>


> **You are on `main`.** Do not work in this file yet -- create a branch first.
> Anything written here on the trunk belongs to no branch, will not be folded, and is in the way
> of the next person who does create one.

<!--
     The plan for this branch. Every step must be resolved before the PR: open-pr and
     ship-pr both refuse while anything is still "- [ ]", and there is no -Force.

       - [ ] not done yet
       - [x] done
       - [~] dropped -- why it turned out not to be needed

     The dropped mark exists so nobody is pushed into ticking a box for work they did
     not do. It keeps its line and its reason, which is the half worth reading later.

     PLAN / CREATE / TEST / DEPLOY are the arc, not a quota: a phase with nothing
     under it is a statement that this branch had nothing there. The headings are
     invisible to the gate, which reads step marks only.

     DEPLOY takes no steps of its own. It is not a step but the result -- the
     section at the foot of this file, which is the part that travels verbatim into
     CHANGELOG.md at the merge. So a step written for after the merge is refused
     here: what happens after the merge is what DEPLOY describes, not a box to tick.
-->

## PLAN

## CREATE

## TEST

## DEPLOY: `main` · <timestamp of the moment this branch was merged>

<!--
     Why the deploy matters AT THIS REACH specifically. A reason that would read the
     same under every tier is a sign the tier is wrong. Write it ABOVE the Score line --
     everything below that line is discarded. Then Score: 1-5 against the rubric
     new-branch printed when it wrote this file.

     Relative links resolve FROM THE REPO ROOT, not from this directory: this text is
     folded verbatim into CHANGELOG.md at the root. So write scripts/x.ps1, never
     ../../scripts/x.ps1 -- the second reads correctly here and is dead once it lands.
-->

**Score:**

### What makes this deploy extra special
<!--
     Why the deploy matters AT THIS REACH specifically. For tier 2 audiences: the subscriber of a service.
     That reader and nobody else -- what matters only inside this repo is said in the section above.

     If it has no significance at this reach at all, then explain shortly why and insert N/A in Score.
     That reason goes above the Score line too, and one or two lines is the whole of it: N/A is a
     complete answer and the common one.
-->

**Score:**

### Pull Request
<!-- the PR title on the first line -- no feat:/fix:/docs: prefix, open-pr puts the branch type in front.
     link to the PR in github when branch is merged to main and the date this happened-->

