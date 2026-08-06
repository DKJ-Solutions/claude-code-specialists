## A branch carries two files in branch/: the changelog entry and the step list

### What does this change do?

A branch's working files move out of the repo root and into a `branch/` directory, and there are **two**
of them because they answer two different questions for two different readers:

```text
branch/
  branch-changelog.md   what the change DOES     -- for whoever reads CHANGELOG.md later
  branch-progress.md    what still MUST HAPPEN   -- for whoever is working on the branch
```

**The split is the point.** One file used to do both jobs: `new-changelog-entry.ps1` scaffolded the entry
with a bold heading that asked, in so many words, what was still to do and where you left off -- and
`open-pr.ps1`'s scaffold gate refused to ship while that heading survived. So the entry was today's to-do list *and* tomorrow's changelog
prose, which is why "replace this whole block before the PR" had to be a written instruction rather than
something the format made obvious. Two files make it obvious: the entry now prompts for what the change
does, and nothing else.

**Fixed names rather than one per branch**, which looks like it should collide the moment two branches
exist and cannot: git already tracks these files per branch, so each branch carries its own version of the
same path and a checkout swaps them. The per-branch filename was solving a problem version control had
already solved, and it cost a repo root that filled up with other people's in-flight work.

**`branch-changelog.md` holds the entry block and nothing around it** -- no title, no branch line, no
warning. That is what makes it pasteable into `CHANGELOG.md` in one go; anything wrapped around it would be
a manual strip step for whoever pastes it. The branch name therefore lives in `branch-progress.md`, which
has room for it -- and the fold reads it back from there to find the PR, since the file name no longer
carries it.

**On the trunk both sit in an empty reset state**, with a warning under the branch line saying not to write
there until a branch exists. That state opens with an `#`, and that is load-bearing rather than cosmetic:
the entry test only accepts the entry heading levels, so the trunk's own empty file can never be folded as
if it were a change, and folding twice is impossible rather than merely unlikely.

**The fold resets instead of deleting**, which is the one real asymmetry the split introduces. A pre-split
root entry is named after its branch, so once folded it has no reason to exist and is still deleted.
`branch/branch-changelog.md` is a path the next branch will use, so it -- and `branch-progress.md`, whose
ticked-off steps would otherwise greet the next branch as somebody else's work -- is rewritten to its empty
state and named in the same fold commit.

**Everything reads both forms.** Every branch created before this change, here and in every consuming repo,
carries a root `<branch-name>.md`; consumers receive these scripts through a plugin update rather than by
choosing to. So the fold discovers both and disposes of each correctly, `open-pr` prefers the new path and
falls back to the old one, and `cut-release` refuses on either. The same rule covers the two scaffold
strings the entry no longer carries: the gate keeps refusing them, because a gate that forgot them would
wave exactly those in-flight entries through into `CHANGELOG.md` without erroring.

Two smaller corrections fell out of the move and are worth naming, because both fail silently:

- **`-Intent` now lands in the step list, not the entry.** It is a status, and the entry's text folds
  verbatim into `CHANGELOG.md` -- which is the shape v3.2.0 measured shipping three times over.
- **The PR template's changelog checkbox is ticked on the file *holding* an entry**, not on the file
  existing. Since the entry now exists on the trunk too, the old test would have ticked the box for a
  branch that wrote nothing -- the one direction a self-ticking checklist must never fail in.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 3 | every consumer's branch workflow changes shape: two files in `branch/` instead of one in the root, and their in-flight branches keep working only because both forms are still read |
| 1 | 4 | the entry stops being a to-do carrier, so the file that folds into the changelog can no longer ship somebody's progress note -- the defect this repo measured three times in one release |
| 0 | 3 | the lint gate, the mojibake scan and the release guard follow the entry to its new path instead of quietly finding nothing there |

### Type of change

Feat
