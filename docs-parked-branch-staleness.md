### A parked branch can be silently overtaken, and only one command shows it · Docs · 2026-08-04

**A branch with a complete plan and no content sat on the remote, obsolete, and nothing anywhere said
so.** `docs/split-quickstart-and-adoption` was parked on August 3, 2026 at 16:49 carrying an 81-line
hand-off and not one line of the work it described. The same work was then built on a different branch
and merged at 18:32 that same day (`d151b6e`), closing all three of the inbound issues the plan named. The
parked branch stayed behind — perfectly intact, entirely superseded. It was found the next morning while
listing remote heads after an unrelated merge, not by anything designed to find it.

**The reason it was invisible is the design, not a defect.** Parking deliberately opens **no PR**, so the
branch appears in no PR listing, no issue, and nothing `git status` or `git log` prints on `main`. On a
machine that never checked it out, `git branch --list` does not show it either. `git ls-remote --heads
origin` is the only place it surfaces — so that command joins Chris's stand-verification list, alongside
`git status`/`git log`, the `## Pull Requests` section, and the unfolded-entry-file check.

**What is new about this instance is which sources were wrong.** The existing rule was written after a
briefing arrived truncated: the channel had dropped text. Here nothing was dropped. A briefing, a memory
note written the evening before, and every local git command all agreed the tree was clean — and all
three were simply blind to the remote. That is why the rule is *read the repo*, not *read a better
summary*; a more careful note would have failed in exactly the same way.

**So the working rule for picking one up: measure the plan against `main` before executing a line of it.**
A park note is written at the moment work stops and knows nothing about what came after, so a plan that
reads as current is no evidence that it is. The cheap checks first — `git log --oneline` on the files the
plan renames or creates, and the state of the issues it claims to close. Here that was two commands, and
it turned a day of planned work into a paste-ready branch deletion. Recorded in
[Derek #05](.claude/specialists/lenses/05-05-extension.md) (the mechanism and the pick-up check, beside
the existing note on why deleting a remote branch stays manual) and in
[Chris #01](.claude/specialists/lenses/01-01-extension.md) (the verification list itself).

**One stale count repaired along the way.** That same list called the SessionStart checks "the two gates"
while there are three — `check-script-contract.ps1` had joined `check-roster-sync.ps1` and
`check-plugin-integrity.ps1` without the sentence following. Corrected in place rather than filed, since
it is one word in the sentence being edited anyway.
