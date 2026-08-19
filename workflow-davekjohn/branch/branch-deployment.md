## `feat/branch-files-cycle-and-deployment` deployment

### What does the change on this branch deploy to main?

The branch dossier is renamed after what each file **is**: `branch-cycle.md` carries the branch through
PLAN / CREATE / TEST / DEPLOY, and `branch-deployment.md` is the part that travels to `main`. The old
names said where a file ended up rather than what it held, which is why the entry kept being read as a
fragment of `CHANGELOG.md` instead of as the claim a branch makes.

Four things move with the names. The step list loses its `### Steps` wrapper — the phases are the
sections now, at `###` — and gains **DEPLOY** as a fourth heading that deliberately holds no steps, only a
pointer to the other file. The **creation stamp** leaves the entry's heading for the cycle file's, which
is the document created with the branch and reset with the merge; the **landing stamp** appears on the
entry's `Pull Request` heading, written by the fold from the PR's own merge timestamp. So each end of a
branch's life is stamped in the document that owns it.

Both old filenames stay readable. `Resolve-BranchFilePath` is the one place that dual-read lives, so a
branch already in flight — here or in any consumer, who meet this through a plugin update rather than by
choosing to — folds and resets in the files it has. Entries whose heading still says `changelog` keep
declaring their type and their shape, which is every entry in `CHANGELOG.md` today.

Two judgement calls are worth Dave's eye rather than being buried: the cycle template's guidance no longer
says *"DEPLOY is missing on purpose"* — it would have contradicted the heading three lines below it — and
the fold's closing line keeps `[PR #N](url)` while the merge moment moved up to the heading, rather than
stating the same fact twice in one section.

**Score:** 4

#### What makes this change extra special

The workflow plugin's two branch files are what a subscriber of this system works in every day, and both
their names and the shape of the step list change. Nothing breaks on the way — the old names and the old
heading word are still read — but the file you open tomorrow has a different name than the one you closed
today, and the arc you fill in has four phases instead of three.

**Score:** 4

### Pull Request

the branch dossier becomes cycle and deployment
