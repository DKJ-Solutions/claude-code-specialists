## `feat/branch-files-cycle-and-deployment` deployment

### What does the change on this branch deploy to main?

The branch dossier is renamed after what each file **is**: `branch-cycle.md` carries the branch through
PLAN / CREATE / TEST / DEPLOY, and `branch-deployment.md` is the part that travels to `main`. The old
names said where a file ended up rather than what it held, which is why the entry kept being read as a
fragment of `CHANGELOG.md` instead of as the claim a branch makes.

Four things move with the names. The step list loses its `### Steps` wrapper — the phases are the
sections now — and gains **DEPLOY** as a fourth heading that deliberately holds no steps, only a pointer to
the other file. The **creation stamp** leaves the entry's heading for the cycle file's, which is the
document created with the branch and reset with the merge; the **landing stamp** appears on the entry's
`Pull Request` heading, written by the fold from the PR's own merge timestamp. So each end of a branch's
life is stamped in the document that owns it.

**And the cycle file becomes a document in its own right** (Dave, by hand in the template, which is this
format's spec): an `#` title over `##` phases, one level shallower than the entry beside it. The entry is
pasted *into* `CHANGELOG.md` and has to arrive at that document's entry level; the cycle file is opened on
its own and travels nowhere, so its title is its own. It loses nothing by no longer switching level between
its reset and written states — nothing folds it, and what tells those states apart is the branch **name** in
the heading, which its reader accepts at either level. `Get-BranchCycleHeadingLevel` and
`Get-BranchCycleSectionLevel` state the pair, so a repo that re-levels its changelog does not silently
re-level the file beside it.

Both old filenames stay readable. `Resolve-BranchFilePath` is the one place that dual-read lives, so a
branch already in flight — here or in any consumer, who meet this through a plugin update rather than by
choosing to — folds and resets in the files it has. Entries whose heading still says `changelog` keep
declaring their type and their shape, which is every entry in `CHANGELOG.md` today.

**Two defects the review on this PR found, both introduced by the move above.** The first would have
blocked the trunk: six section readers were given a shared tolerant tail for the stamped heading, and the
lint's own was the seventh, left on a bare `\s*$`. A folded entry reaches `CHANGELOG.md` as
`### Pull Request · 20260819-171500`, which that gate would have read as a section nobody declares — an
`[entry-heading]` error on the one write that happens directly on `main`, inside the required CI check, so
every PR after the first fold would have been blocked by the fold of the one before it. The stamp is now
stripped before the comparison rather than tolerated inside it, so a misspelled heading is caught exactly as
strictly as before. The second is quieter and reaches consumers: a **pre-dossier** entry has no
`Pull Request` heading to stamp, so moving the date off the closing line took it away from that shape
altogether — silently, in the one document whose subject is when things landed. The fold now asks whether
the section exists and puts the date on the line when it does not. One fact, one place, wherever that place
happens to be.

Two smaller judgement calls, stated rather than buried: the cycle template's guidance no longer says
*"DEPLOY is missing on purpose"* — it would have contradicted the heading three lines below it — and the
fold's closing line carries `[PR #N](url)` alone wherever the heading can hold the moment, rather than
stating the same fact twice in one section.

**Score:** 4

#### What makes this change extra special

The workflow plugin's two branch files are what a subscriber of this system works in every day, and both
their names and the whole shape of the step list change. Nothing breaks on the way — the old names and the
old heading word are still read — but the file you open tomorrow has a different name than the one you
closed today, and the arc you fill in has four phases instead of three, under headings a level up.

And one of the two repairs above is theirs rather than ours: a consumer with a branch in flight from before
the dossier split carries a pre-dossier entry, meets this change through a plugin update rather than by
choosing to, and would have had the landing date quietly dropped from the entry that lands in their
changelog.

**Score:** 4

### Pull Request

the branch dossier becomes cycle and deployment
