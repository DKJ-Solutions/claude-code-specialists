# Development cycle: `docs/exit-code-read-through-a-pipeline-v1`

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

Generalise trap 6 in the portable system-administration manual: the same mis-read is available to whoever is CHECKING, measured twice in the session that wrote the trap.

## PLAN

- [x] Decide whether the second mis-read is an eighth trap or a clause inside the sixth. Settled as a
  clause: trap 6 and this are one rule in two languages, the section had already gone from five to seven
  in a single day, and a bullet per language would grow the list without adding a lesson.

## CREATE

- [x] Generalise trap 6 in the portable system-administration manual with the checker's half of the same
  mis-read, unbolded so the bullet keeps one claim and one remedy.

## TEST

- [x] Re-measured the claim rather than writing it from recollection: a script exiting 3 reports `$?` as 0
  through a pipeline, while `${PIPESTATUS[0]}` still reports 3.
- [~] No suite added. The subject is a shell idiom used by whoever reads a gate's result, not a surface
  any script in this repo exposes, so there is nothing here for an assert to hold; the manual is the
  only place it can be caught.

## DEPLOY: `docs/exit-code-read-through-a-pipeline-v1`

<!--
     Why the deploy matters AT THIS REACH specifically. A reason that would read the
     same under every tier is a sign the tier is wrong. Write it ABOVE the Score line --
     everything below that line is discarded. Then Score: 1-5 against the rubric
     new-branch printed when it wrote this file.

     Relative links resolve FROM THE REPO ROOT, not from this directory: this text is
     folded verbatim into CHANGELOG.md at the root. So write scripts/x.ps1, never
     ../../scripts/x.ps1 -- the second reads correctly here and is dead once it lands.
-->

Trap 6 landed here yesterday and was mis-read twice inside the same session that wrote it -- both times
by reading `$?` after piping a PowerShell run through `tail`, which reports the pipe's last command and
not the run. The second time it argued that a correct remedy was broken, which is the expensive shape:
the mis-read does not merely hide a failure, it manufactures one. Anyone here who judges a gate, a suite
or a probe from a shell is who repeats it, which in this repo is every chain run.

**Score:** 3

### What makes this deploy extra special
<!--
     Why the deploy matters AT THIS REACH specifically. For tier 2 audiences: the subscriber of a service.
     That reader and nobody else -- what matters only inside this repo is said in the section above.

     If it has no significance at this reach at all, then explain shortly why and insert N/A in Score.
     That reason goes above the Score line too, and one or two lines is the whole of it: N/A is a
     complete answer and the common one.
-->

A consumer's system-administration specialist gets trap 6 through the plugin, so without this they
inherit the half about an exit code that lies and not the half about reading it through a pipe. It is a
clause rather than a new trap, though, landing in a bullet they may already have read -- a smaller thing
than either trap that shipped yesterday.

**Score:** 2

### Pull Request
<!-- the PR title on the first line -- no feat:/fix:/docs: prefix, open-pr puts the branch type in front.
     link to the PR in github when branch is merged to main and the date this happened-->

The exit code you read is not the exit code you meant: trap 6 generalised to whoever is checking
