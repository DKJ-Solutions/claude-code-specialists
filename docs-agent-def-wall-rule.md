### A rule that stops a subagent hitting a wall belongs in the agent def too · Docs · 2026-07-27

Two lessons from the same session, both about documentation that was quietly wrong rather than
missing.

**1. The manual-is-leading rule has an exception (Specialists handbook).** The handbook says *"the
manual is leading; the agent def is the executable abbreviation — you change a craft rule in the
manual."* That division assumes the subagent consults its manual at the moment it matters, which
holds for a rule about *what the craft is*: it notices the gap and looks it up. It does not hold for
a rule about *what it will otherwise attempt and fail at* — there it does not know anything is
missing, so it never becomes "in doubt", never opens the manual, and hits the wall instead. Such a
rule now goes in the agent def in compact form **as well as** in the manual in full.

Sylvester #15 (PR #198) is the worked example, recorded with it: his working method opened with
"read before writing, always merge", silently assuming he can write to a permissions file at all.
He cannot — the auto-mode classifier blocks it by design — and he ran into that twice in two
consecutive pieces of work, improvising a recovery mid-task both times. **Fixing only the manual
would have produced a third collision**, which is exactly why #198 touched both files.

**2. Nobody was cleaning up merged branches, and both docs said otherwise.** Seven merged branches
had piled up on the remote unnoticed. Cause: `deleteBranchOnMerge` was **off**, while
`ship-pr.ps1` merges with a plain `gh pr merge --merge` (no `--delete-branch`). So no mechanism was
in force — and the two docs each named a *different* one, which is why the gap survived review:
Derek's persona credited the repo setting, his repo lens credited the `--delete-branch` flag.
Neither claim was true, and **nothing ever errored** — merged branches simply accumulate until
someone reads the branch list.

Fixed at the root: `deleteBranchOnMerge` is now on (Dave's decision, July 27, 2026), which covers
every merge route including the GitHub UI and other machines — not just the script path. Both docs
now describe what actually happens, and both carry the trap that hid this: **`git fetch --prune`
only drops tracking refs for branches already gone from the remote**, so a clean local branch list
is no evidence whatsoever that the remote is clean. Verifying means `git ls-remote --heads origin`.
