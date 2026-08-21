## `feat/prune-merged-ships-centrally` deployment

### What does the change on this branch deploy to main?

Branch cleanup gets its two halves answered where each one lives: `scripts/task/prune-merged.ps1` ships
**centrally** for the local clone, and `ship-pr.ps1` **reads the repo setting after the merge** and names
it when it is off. Reported as inbound
[#815](https://github.com/DaveKJohn/claude-code-specialists/issues/815) after Dave asked, mid-session and
unprompted, *"waarom worden branches niet automatisch verwijderd na een merge? Dit zou de plugin moeten
vertellen"* -- looking at 20 remote heads of which 18 belonged to already-merged PRs, five days into using
this workflow.

**The report's symptom was right and its reason was not, and the reason is what changed the repair.** It
said the plugin leans on *"a per-repo setting nobody's docs mention"*. Measured on pickup, the setting is
named in **three** places in the plugins -- the `specialists-init` checklist, with a paste-ready
`gh api -X PATCH ... -F delete_branch_on_merge=true`; the `fold-changelog` skill; and Derek's persona --
and the reporting repo has both plugins installed. So it was documented three times and still off. All
three are **setup checklists, read once at init, with nothing ever asking again**: the gap is reach, not
documentation, and a fourth document would have been the wrong fix. `ship-pr` now says it at the one
moment it is both true and cheap to fix -- straight after a merge that left a branch standing -- with the
one-line command. It reads, it never writes, and it stays silent when the answer is yes.

**No `--delete-branch` on the merge. Dave's decision, on three measured grounds:**

1. The flag covers only the path it is passed on; the setting covers every route -- this script, the web
   UI, another machine, another tool. Two mechanisms for one job is exactly the shape that let seven
   merged branches pile up in July 2026: two documents each named a different one and neither was in
   force.
2. The flag also deletes the **local** branch, and on **July 16, 2026** it was measured leaving the
   checkout *on* the merged branch -- with the fold then running there and having to be undone by hand.
   `ship-pr`'s very next act is that fold. The plugin's own skill already says *"Do not trust the flag;
   trust the check."*
3. It would make merging destructive as a side effect, which is the opposite of the shape the reaper was
   deliberately given.

**The local half is the real gap, and it ships as a separate command.** Nothing in the plugin deleted a
branch anywhere; meanwhile the script existed as a hand-written copy in *two* consumers. That is issue
[#81](https://github.com/DaveKJohn/claude-code-specialists/issues/81)'s argument for `new-branch.ps1`
word for word -- a mechanism several repos need, living as a copy in each, will drift. So
`prune-merged.ps1` is registered in `Get-SharedScriptPairs`, mirrored to the plugin, and documented by a
`prune-merged` skill (which the registry requires, and which is the only thing a consumer actually has).

What it does, and what each step is guarding:

- **Refuses on a dirty working tree**, before anything is touched -- not discovered by a failing checkout
  halfway, at which point the fetch has already run and the reader has to reconstruct what happened.
- **Fast-forward only** on the trunk. It may advance the trunk and must never merge into it. A
  non-fast-forward is a warning and not a stop: the ancestry is then judged against the older trunk,
  which errs towards *keeping* branches.
- **`fetch --prune`**, which matters even where the remote reaps its own heads -- and the run prints the
  command that actually answers the remote question, because pruning only drops refs for branches
  *already* gone, so a clean local list proves nothing.
- **Deletes only on proof:** `-d` where the branch is an ancestor of the trunk (and `-d` re-checks that
  itself, so the proof is checked twice), `-D` only where a merged PR proves a squash whose tip is
  deliberately outside the trunk's history. Anything with neither proof -- unfinished work, a parked
  branch, a branch pushed from another machine -- is **kept, with the reason printed**. That is the whole
  safety property, and it is the mirror image of the remote-delete permission Dave declined on
  July 27, 2026: every branch this can reach is one whose loss is recoverable by construction.

The merged-PR set is read **once** per run rather than once per branch. Where `gh` is missing or
unauthenticated that is not an error: proof (b) is simply unavailable, the run says so, and every
squash-merged branch is kept.

28 asserts cover it, including the two directions that matter -- the merged branch goes, the unmerged one
survives -- and one structural assert that no git call in the source carries a `--delete` argument, so
"touches no remote branch" is a tested property rather than a promise in a header.

**One test gap is declared rather than papered over:** `ship-pr`'s new step 7 has no suite. It runs only
after a real merge, and the precedent here for testing gh-mutating logic is to split it into its own
script -- which is not worth it for one read and one printed line.

**And one extra finding, repaired on the way past.** The workflow README's skill table says it lists all
of them and listed **13 of 14**; `check-branch-entry` had shipped without a row. It was found by counting
when adding the new row. The paragraph above that table already explained this exact failure from the
last time -- it dropped the *"The nine skills"* heading so the count could not go stale, which stopped the
drift being visible without stopping the drift.

**Score:** 3

#### What makes this change extra special

A consumer five days into this workflow could not tidy their own clone without writing the script
themselves, and two of them had. They now get it through a plugin update, with the judgement about which
branches are safe to delete made once inside it rather than every time by whoever is looking. The
`ship-pr` half reaches the case that actually bit: a repo where the setting is off learns it from the
merge that just left a branch behind, instead of from a checklist read at init and never again.

**Score:** 4

### Pull Request

Branch reaping ships centrally, and ship-pr says when the remote setting is off
