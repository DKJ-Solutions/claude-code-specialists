## docs/1656-gate-count-readme

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

#### What the issue reported, and what verification changed about it

Inbound #1656 reported `plugins/dkj-policy/README.md:30` as contradicting the page it points the reader
at one paragraph later, on the ground that #1650 had already bumped that page from four gates to five.

The symptom stands; the reason had not arrived yet. `fix/1650-shape-gate-local` is **open, parked and
has no PR**, so on the trunk `CONTRIBUTING-portable.md:282` still reads "Four further gates" too. The
contradiction is pending rather than live, and that settles the repair the issue left open: it offered
"drop the number or bump it to five", and bumping to five would be **wrong on the trunk today**.
Dropping the count is correct on both sides of that merge, which is the whole argument for it.

- [x] Read the issue and claim it -- `claim-issue.ps1`, claimed for `maikel-bwj`
- [x] Verify the symptom against the trunk, not against the report
- [x] Verify the reason -- establish whether #1650 has landed (it has not)
- [x] Establish the precedent the repair should follow

### CREATE

The precedent is the #1650 branch's own answer everywhere else it touched a count: it drops rather than
bumps, and `CLAUDE.md` states why in so many words -- *"Neither count is stated here any more,
deliberately: both went stale as gates were added, and a wrong number reads as authority."* The root
`README.md` and `scripts/README.md` both go to "the gates on the branch dossier", naming what the gates
gate instead of counting them.

- [x] Drop the count in `../plugins/dkj-policy/README.md`, naming the gates rather than numbering them
- [x] Keep "and none of them is advisory" -- the load-bearing half, which survives any count
- [~] Sweep the other "four gates" occurrences -- deliberately not done. Two are a different subject
      (`../.claude/specialists/lenses/01-01-extension.md`, the session-start checks), and the rest sit
      in files `fix/1650-shape-gate-local` already edits, so touching them here would collide with a
      branch in flight for no gain.

### TEST

- [x] Re-read the paragraph in full: the sentence introduces the gates rather than assuming them,
      so dropping the count leaves no dangling first-mention reference behind it
- [x] Confirm the trunk still reads "Four further gates" in `CONTRIBUTING-portable.md`, i.e. that the
      new wording is true now and not only after #1650
- [~] Run the lint gate and the suites -- dropped as a step rather than ticked: `open-pr.ps1` runs
      both before it pushes, so a copy set going here proves nothing that gate would not catch, and
      neither mark is honest for work that has not happened yet at the moment the gate reads this list.

### DEPLOY: docs/1656-gate-count-readme

The `dkj-policy` README's one-paragraph summary no longer counts the gates. It read *"Four gates hold the
whole thing together, and none of them is advisory"* and now reads *"Gates on the branch's own paperwork
hold the whole thing together"* -- the same claim, with the half that goes stale removed and the half that
does the work kept verbatim.

The count was correct when it was written and is correct today. What it was not is durable: the paragraph
sits one sentence above the pointer to
[`CONTRIBUTING-portable.md`](../plugins/dkj-policy/CONTRIBUTING-portable.md), whose matching sentence
becomes "Five further gates" the moment
[#1650](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1650) lands -- so the summary would
have started contradicting its own next paragraph without anybody editing it. That is the second time this
count has gone stale by standing still, which is the argument for naming the gates instead: *"Gates on the
branch's own paperwork"* is what `CONTRIBUTING-portable.md` already calls them, and it stays true at four,
five or six.

Deliberately scoped to this one sentence. The other counts in the tree are either a different subject or
sit in files #1650's own branch is already editing; the one it leaves behind,
`CONTRIBUTING.md:380`, is filed on
[that thread](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1650#issuecomment-5589481061)
rather than swept from here.

**Score:** 1

A wrong number in a summary paragraph misleads nobody today -- it prevents a contradiction that has not
happened yet, and names the failure it prevents. Cosmetic in isolation; worth doing because the alternative
is finding it a third time.

#### What makes this deploy extra special

This page ships with the plugin, and it is the one the README itself calls *"the page to read"* before
handing a consumer to `CONTRIBUTING-portable.md`. A consumer adopting the workflow reads the summary and
the page it points at in that order, so the pending contradiction would have landed on them first and with
nothing in their own tree to explain it.

**Score:** 1

They read a paragraph that stays true instead of one that quietly stops being true. Cosmetic on arrival,
and invisible if it works.

#### Pull Request

Drop the gate count from the dkj-policy README's opening paragraph
