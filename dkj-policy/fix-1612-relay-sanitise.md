## fix/1612-relay-sanitise

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

Issue [#1612](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1612), filed by Dave. Two
halves, and the second is the one worth repairing whatever is decided about the first.

`Get-AuthoredFailureNote` (`scripts/lib/pr-issues-lib.ps1`) relays a sentence a **workflow author**
wrote into the operator's console, under `ship-pr`'s own warning prefix and indent. It trims, cuts to the
first line and caps at 500 -- so the newline tricks are gone and nothing else is: an in-line `ESC[`, an
OSC string or an RTL override survives all three. The sibling relay `Get-RemoteAheadNote`
(`scripts/lib/remote-ahead-lib.ps1`) faces the same class -- a commit subject somebody else wrote -- and
strips it, with the reasoning stated at the line. Every word of that reasoning applies here.

The second half: `plugins/dkj-policy/skills/new-branch/SKILL.md` said of that sanitiser that this "is the
only place this workflow prints externally-authored text to one", which has been false since #1103 added
the relay. That sentence is what stops a reader looking for a second site.

#### Verified before it was repaired, all three claims plus one the report did not name

- The relay really does not strip: read at the line, and reproduced -- an ESC, a BEL and an RTL override
  all reached the composed note.
- `Get-RemoteAheadNote` really does strip, and its comment really does state that reasoning.
- The skill page's claim really is false and really is the only prose copy -- but **not** the only copy:
  `scripts/tests/new-branch.tests.ps1` says the same thing in its own words ("which nothing else in this
  repo does with externally-authored text"), and a repair that left it standing would leave the tree
  contradicting itself in the file that asserts the behaviour.
- One the report did not name: `Get-MissingCheckSuiteNote`'s comment ten lines below already contrasted
  itself with "Get-AuthoredFailureNote ABOVE" as **bounded and escaped**. It was describing a property
  that did not exist; the fix makes it true, and it now says so.

#### What was NOT done, and why

**No shared home for the class.** The obvious DRY move -- lift it into a helper both libs load -- was
priced and declined. `native-capture-lib.ps1` is the only lib both dependency chains already load, and it
carries a written request not to be widened again (`park-lib.ps1` and `gate-lib.ps1` both cite it); a new
lib would cost a registry entry in `shared-scripts-lib.ps1`, a mirror, a dot-source line in every caller
and a `Copy-Item` in every fixture suite. The functions share nothing but the class: different bounds,
different source processes.

**And the tree settled that question one day before this branch, in the other direction.** #1594 landed
`scripts/lib/ref-print-lib.ps1` on September 8, 2026, and `Get-PasteableRef` **re-typed this same
character class** with `remote-ahead-lib` already in place, recording at the line why ("a guard whose
refusal path is itself an injection surface is worse than no guard"). So hand-typing the class and citing
its source is the live convention here, not a shortcut this branch invented. What the copies may not do is
disagree -- which is what the assert buys, at none of the machinery's cost.

#### And that lib arrived mid-branch, which changed a claim this branch was writing

`ref-print-lib.ps1` reached `main` while this PR was in CI (#1618), and the merge that brought the branch
forward is where it turned up. The first draft of this repair said the class lived in **two** libs, in the
docstring, on the skill page and in `new-branch.tests.ps1` -- a count a reader falsifies with one `grep`,
which is precisely the defect #1612's second half is about. Corrected to **three** in all four places
before the merge, and the count is now asserted rather than asserted-in-prose: `pr-issues.tests.ps1`
enumerates `scripts/lib/*.ps1` and pins the set to exactly those three, naming the two documents a fourth
site has to update.

**The 500 is untouched**, as the report asks. Only the character class was in question.

### CREATE

- [x] `Format-AuthoredText` in `scripts/lib/pr-issues-lib.ps1`: control and format characters to spaces,
      runs of spaces collapsed, ends trimmed -- one definition, used for both the title and the message.
      Bounding stays at the call site, because the two relays' caps are separately measured numbers.
- [x] The title goes through it **before** the emptiness test, so a "title" of nothing but format
      characters falls through to the next annotation like any untitled one -- and so the `CheckName`
      prefix match cannot be defeated by a leading escape.
- [x] The message goes through it **after** the first-line cut and **before** the cap. Both ends of that
      order are load-bearing: a newline is itself a control character, so stripping first would leave no
      first line to take; capping first would count characters the reader never sees.
- [x] `Get-MissingCheckSuiteNote`'s neighbouring comment now describes what the function does.
- [x] The skill page's retired claim replaced by the **three** sites, their three bounds, and the assert
      that keeps them from disagreeing -- and the same claim in `new-branch.tests.ps1` corrected with it.
- [x] Plugin mirror rebuilt (`scripts/sync/build-shared-scripts.ps1`).

### TEST

- [x] Six new asserts in `scripts/tests/pr-issues.tests.ps1`: no ESC, no BEL and no RTL override reaches
      the note; the words on either side of the override survive in the order they were written; no
      double space is left where an escape was; and a format-character-only title falls through rather
      than winning. Fixtures carry `\u` escapes, so the suite stays pure ASCII.
- [x] Plus the drift pin: all three libs carry the same class, this lib carries exactly **one** copy of
      it, and `scripts/lib/` holds no fourth site -- the count itself is an assert now.
- [x] Merged `origin/main` after the staleness guard refused the first ship (a non-fold commit had landed
      behind the certifying run, exactly what #1292 exists for), then re-ran the gate on the merged tree.
- [x] `scripts/tests/pr-issues.tests.ps1` -- 759 asserts, all passing.
- [x] Full lint + suite gate via `open-pr.ps1`.

### DEPLOY: fix/1612-relay-sanitise

`ship-pr` prints the sentence a failing workflow wrote about itself, and it now strips the control and
format characters out of that sentence before it reaches your terminal -- the same guard the
"N commits behind" line has always had on a commit subject. An ANSI or OSC escape in a workflow's own
`::error title=...::` can no longer repaint the console it is relayed into, and an RTL override can no
longer make the relayed line read as something other than what it says. The words are kept; only the
characters that act rather than read are removed. The 500-character cap is unchanged.

Small, because it prevents a failure that has not happened: the author of an annotation is whoever writes
the repo's own workflows, which is a high-trust surface. It is worth more than a 1 in one specific shape
that is ordinary practice -- a workflow echoing untrusted input into `::error title=...::`, such as a PR
title, a branch name or a third-party action's output -- where the relayed text stops being the author's
own.

**Score:** 2

#### What makes this deploy extra special

It closes a claim as well as a gap. A page in the tree told readers this workflow printed
externally-authored text to a console in exactly one place, so nobody had reason to look for the second
one -- and the comment beside the second one already described itself as guarded. The repair makes three
statements agree with the code instead of one, and pins the two sanitisers to each other so the next
reader inherits a checkable arrangement rather than a claim.

**Score:** N/A

#### Pull Request

Strip control and format characters from the relayed annotation, and correct the only-place claim

