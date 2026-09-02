## Development: `docs/tracker-native-ticket-fields-v1` · 20260902-101126

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

#### The finding, verified before it was routed

Inbound [#1216](https://github.com/DaveKJohn/claude-code-specialists/issues/1216). Every measurement in
it holds against the tree at `a663616d`: the section is 290 lines, and over them **16 uses of
`file`/`files`, 3 of `index`, and 0 of `title`**. The section exists in exactly one place -- the
portable page -- so there is no second site to repair.

**What is ours and what is not.** The duplicate `# H1` the reporter measured is migration residue in
their own tree, and they say so; no rule on this page prescribes a heading. What is ours is the reason
it survived twelve tickets: the section is written for a ticket that is a **file**, so nothing in it
prompts the reader to ask *which of these does my tracker already carry?*

#### The nuance that decides the wording

Two trackers are in play, and the passage is worthless if it does not separate them. The section
already assumes a **source** tracker -- somebody else's, the one the request came out of -- and the
provenance boundary exists to date what is copied out of it. The gap is about the **host**: where your
own ticket sits, when it is not a file. A rule that does not name which of the two it means reads as
licence to delete the snapshot the structural rule exists to protect.

### CREATE

- [x] Add a short subsection between the structural rule and the rules: the rules say *file*, read it
      as *the ticket*, and what a host tracker owns natively is not written a second time in the body.
- [x] Name which rules that touches -- including rule 7, which looks like a duplicate and is not.
- [x] Update the rows in **What your repo answers** that assume a folder of files.

### TEST

- [x] Lint gate and all suites green (`check-plugin-integrity.ps1`), the dead-link scan over the new
      anchor included.

### DEPLOY: `docs/tracker-native-ticket-fields-v1`

The ticket-work layer gains the one rule it was missing for a consumer whose tickets live in a tracker
rather than in a folder: **what the tracker you host already owns natively is not written a second time
in the body.** The section was written for a ticket that is a file and reads that way -- measured over
its 290 lines, **16 uses of `file`/`files`, 3 of `index`, and 0 of `title`** -- so nothing in it ever
prompted the reader to ask *which of these does my tracker already carry?*

A new subsection sits between the structural rule and the rules, where it is read before any rule is
applied. It does the whole job in one sentence -- *read `file` as `the ticket`, wherever yours lives* --
rather than sweeping sixteen occurrences out of 290 lines that were each measured in their current
wording. Then it names what a host tracker typically owns and what that does to the rules: the **title**
(the body does not open by repeating it), the **list** (that *is* rule 10's index, so you have one
whether or not you asked for one), and the **author and creation date** (which record who transcribed
the ticket, never who filed the request -- so the snapshot half stays written down). **Rule 7's state
field is named as the one that reads as a duplicate and is not**: open/closed is two values, and a
vocabulary that is closed *and* covers every stage cannot be two values.

**The distinction the passage is built on is which of two trackers is meant.** The section already
assumes a **source** tracker -- somebody else's, the one the request came out of -- and the provenance
boundary exists to date what is copied from it. The new rule is about the **host**, where your own ticket
sits. Stated without that separation it reads as licence to delete the snapshot the structural rule
exists to protect, which is the opposite of what that rule says.

**What your repo answers** picks up the same seam: the folder row now covers a tracker row too, the index
row says a host tracker hands you one whether or not you wanted it, and a new row asks which fields yours
already owns.

**Deliberately not here:** a template or a scaffolder, both of which [What deliberately is not
here](../plugins/workflows/contributing-davekjohn/CONTRIBUTING-portable.md#what-deliberately-is-not-here)
declines and inbound [#1216](https://github.com/DaveKJohn/claude-code-specialists/issues/1216) explicitly
did not reopen. The ask was one rule, not a shape.

**Score:** 1

The rule is inert here -- this repo consumes the workflow but runs no ticket layer, so nothing a
maintainer does today changes. What it prevents is the repair that was available instead: answering the
next report of this class by sweeping `file` out of 290 lines whose wording is the record of five rounds
against six real tickets.

#### What makes this deploy extra special

A consumer adopting the ticket layer against a tracker rather than a folder is now told, before they
reach the first rule, which fields they are about to write down twice -- and which one only looks like a
duplicate. Measured in the originating repo on 2026-09-02, after its eleven ticket files were moved
verbatim into its tracker: **12 of 12 carried their title twice.** The twelfth of those was not migration
residue -- it was written from this page, from the rules, and the page did not prompt the question. That
is the rediscovery the next repo no longer has to pay for, which is the whole argument for the section
being portable at all.

**Score:** 3

#### Pull Request

the ticket-work section names what a host tracker already owns
