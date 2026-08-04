### Move the git and gh craft from Derek's lens into the shared source · Docs · 2026-08-04

**The same migration #441 did for the release craft, applied to the git/gh craft.** Derek's lens went
from **23,112 to 20,861 bytes**; his persona from 5,835 to 7,383, and the `ship-pr` skill gained a
section it had been missing since it was written earlier today. The layer test from #440 decided each
block: a **craft rule** goes to the persona stripped of its numbers, a **measured procedure** goes to
the skill *with* its measurement, and only what is true solely here stays in the lens.

**To the persona: never pass a body inline to `git` or `gh`.** Two failure modes that look like
different bugs — quotes get **mangled** (the argument boundaries break, so a commit message's tail is
read as a pathspec), newlines get **split** (each line arrives as a separate argument and the tool
complains about the count) — plus the half-success that makes it a hard rule rather than a preference:
a command that does its primary job and silently drops the text, closing an issue while discarding the
comment explaining why. Stated without dates or PR numbers, because the trap belongs to the shell and
not to this repo. The corollary travels with it: after any call that was supposed to leave text behind,
**verify the text is there** instead of trusting the success line.

**To the `ship-pr` skill: what to do when the required check never appears.** Step 3 already gave up
after 180 seconds without merging; it did not say what that state usually is or how to get out of it.
It now does — recognise it by a blocked merge with **no rollup at all**, confirm via the head-SHA run
count that no run exists rather than one being merely late, then close and reopen the PR. Including the
trap on the other side: retrigger a late run and you get two concurrent ones, the merge state drops
back to `BLOCKED` while the original finishes, and the forge's own error text suggests `--admin`, which
is precisely the bypass to refuse.

**What stayed, and why that is the interesting half.** Three of these rules had already reached the
source this morning by a different route — `--ff-only` over a bare pull, and never chaining
`gh pr checks --watch` onto a merge, both landed in the `ship-pr` skill when it was written. So the
lens blocks became **citations** rather than being deleted: the skill carries the reasoning and the
commands, the lens carries the local evidence and the names that are only true here — the check
`lint-en-tests`, the `main-ci-gate` ruleset, `netlify` as the check suite that can fool a head-SHA
count, and the fact that `main` is guarded by a ruleset rather than classic branch protection, which is
why `gh` phrases its refusal as a base-branch policy.

**One rule was kept deliberately un-migrated in its explanatory half, and that is worth stating.** The
bare `git pull --ff-only` failure of July 29 was never explained — the repo's git config is ordinary
and a later inspection found a single `for-merge` line in `FETCH_HEAD`. The rule became portable
anyway **because it stands on reasoning rather than on that unknown**: the explicit form names exactly
one ref, so it cannot reach the failure mode at all. A rule that only worked because of an
unreproduced local quirk would have had no business travelling.

**Also local, and a shell rather than a repo fact:** PowerShell 5.1 has no `&&`, so a chain here is `;`
or `if ($?) { ... }` — both of which run the merge regardless of what the watch concluded. Kept in the
lens because the portable statement of that rule is "do not chain them", which needs no shell.
