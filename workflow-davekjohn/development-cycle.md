# Development cycle: `docs/powershell-trap-six-and-sed-escape-v1` · 20260823-200256

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

Record two lessons measured during the PR #840 chain run into the portable system-administration manual, plus the local half of the sed lesson in the ASCII rule.

## PLAN

## CREATE

- [x] Add the sixth trap (a background test-gate run reporting exit 0 while the call inside it had
  thrown `CommandNotFoundException`) and the seventh (a GNU `sed \u` substitution mangling a dash
  escape into a wrong-but-ASCII literal) to the portable system-administration manual's trap section,
  and the local half of the sed lesson to `.claude/rules/language-layers.md`.

## TEST

## DEPLOY: `docs/powershell-trap-six-and-sed-escape-v1`

<!--
     Why the deploy matters AT THIS REACH specifically. A reason that would read the
     same under every tier is a sign the tier is wrong. Write it ABOVE the Score line --
     everything below that line is discarded. Then Score: 1-5 against the rubric
     new-branch printed when it wrote this file.

     Relative links resolve FROM THE REPO ROOT, not from this directory: this text is
     folded verbatim into CHANGELOG.md at the root. So write scripts/x.ps1, never
     ../../scripts/x.ps1 -- the second reads correctly here and is dead once it lands.
-->

Both traps were measured here, in this repo's own tooling, during the PR #840 chain run: a background
probe of `Invoke-TestSuiteGate` that reported `GATE OK = ` and exit 0 against every suite in the repo
while the call inside had failed to resolve, and a `sed` substitution meant to write two dash escapes
into a `scripts/lib/` regex that instead wrote a wrong-but-ASCII literal past the very check (`[script-ascii]`)
that same run built to catch this class in the source. Anyone here who probes a gate as a background
command, or reaches for a non-PowerShell tool to repair a `.ps1` file, is exactly who repeats this.

**Score:** 4

### What makes this deploy extra special
<!--
     Why the deploy matters AT THIS REACH specifically. For tier 2 audiences: the subscriber of a service.
     That reader and nobody else -- what matters only inside this repo is said in the section above.

     If it has no significance at this reach at all, then explain shortly why and insert N/A in Score.
     That reason goes above the Score line too, and one or two lines is the whole of it: N/A is a
     complete answer and the common one.
-->

This reaches every consumer's system-administration specialist: the portable manual travels through
the plugin cache, and the trap section is the one place that craft lives. Two of the seven traps are the
difference between believing a gate ran and knowing it did not, which is worth more than the ordinary
addition to a list. It stops short of a 4, though: a reader only meets either trap when they next write
their own probe or reach for a non-PowerShell substitution on a `.ps1` file — nothing about how they work
changes before that moment, and for most sessions that moment is not this week.

**Score:** 3

### Pull Request
<!-- the PR title on the first line -- no feat:/fix:/docs: prefix, open-pr puts the branch type in front.
     link to the PR in github when branch is merged to main and the date this happened-->

A sixth PowerShell trap, and a seventh one step out in the repair tooling: the sed escape that mangles the ASCII repair

