### install scope and the two verification checks (inbound #279, #280) · Fix · 2026-07-30

Adoption round v4 (life-hub, against 3.0.1) filed two doc-versus-behaviour defects. Verifying them
against this machine turned up two more of the same family, so all four are fixed together.

**1. The scope flag — `install`, `update`, and `uninstall` (inbound
[#279](https://github.com/DaveKJohn/davekjohns-workshop/issues/279)).** `specialists-init` step 0b
explained that an install is project-scoped and then gave the command **without** `--scope project`.
All three `claude plugin` verbs default to `--scope user` (verified via their own `--help`), so the
documented step produced a machine-wide record with no `projectPath` — precisely what the paragraph
above it said the step exists to create. The same default makes `claude plugin update` fail outright
on a project-scoped install with *"Plugin `specialists` is not installed at scope user"*: literally
true, easily read as "not installed at all", and the obvious response — re-running the install —
silently adds a second, machine-wide record beside the project one.

**Dave decided the open question explicitly on July 30, 2026: project scope is the intended model.**
It is what both real consumers carry, it keeps a repo pinned to the version it was tested against,
and the rest of the family's documentation is written against it. So the flag was added rather than
the justification rewritten: step 0b (install + a new update paragraph), the family README's step 0,
the root README's Consumption and update-gate paragraphs, the Quickstart's install and *Staying up to
date* sections, and the connectors README's version-gate line. `uninstall` was found to share the
default while fixing the rest, so the teardown skill and `teardown.ps1`'s closing note carry the flag
too. Prose mentions of "after a plugin update" were left alone — they name the event, not a command.

**2. `claude plugin list` is not a verification (found while checking #279).** Step 0c prescribed it
as the self-check against the silent no-install failure of #276. Measured in this repo on July 30,
2026: `davekjohns-workshop` has `enabledPlugins` set, **no install record of its own**, and no loaded
plugin — no `specialists:*` subagents, no skills, no session hooks — and the list still reported
`Status: ✔ enabled` at `Scope: project`. It enumerates records beyond the current repo, so a green
line proves nothing about *this* one. Worse, 0c's own "just check each plugin appears as `enabled` at
all" caveat steered the reader past the one signal that would expose a stray record. Step 0c and the
Quickstart now query `installed_plugins.json` for a record whose `projectPath` is this repo — a check
verified in both directions here (empty in the workshop, two `project` rows for life-hub) — and add
the in-session confirmation that the skill and hooks actually arrived. Why the list reports as it
does was not established and is deliberately not recorded as a mechanism.

**3. The teardown pre-flight reported the alarming answer for the safe repo (inbound
[#280](https://github.com/DaveKJohn/davekjohns-workshop/issues/280)).** `git ls-files .claude` lists
**committed** files only, so immediately after a bootstrap — which is exactly when the section says
to run it — it comes back empty in a repo whose `.claude/` is fully tracked, contradicting the table
two lines below it. The single command could not separate *"this repo can never protect its lenses"*
(ignored) from *"you have not committed them yet"*, and only the first is a reason to stop. The
pre-flight is now two commands: `git check-ignore -v` answers the ignore question directly and
regardless of commit state, `git ls-files` answers whether the undo has been claimed. Both were
verified in this repo. Added with it: the undo the table promises begins at the **commit**, not at
the bootstrap.
