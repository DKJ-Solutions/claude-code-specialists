### three reporting inaccuracies in teardown/init (inbound #275) · Fix · 2026-07-30

Three defects measured in the v3.0.0 adoption round (two full `init` → `teardown` cycles in an
*occupied* consumer, July 30, 2026). None broke a run; all three made a report claim something other
than what happened, which is the class the previous round was about.

**1. The preview and the apply run now report the same total.** They differed by two on identical work
— `29 item(s) to remove` against `31 item(s) removed`, reproduced in both cycles — because the
directory prune (`lenses/`, then `specialists/`) sat entirely inside `if ($Apply)`: pruned, listed and
tallied on the apply run, never mentioned in the preview. A dry run is explicitly *the inventory a
reader needs in order to say yes*, so a preview that undercounts its own execution weakens exactly the
property it exists to provide. Both modes now list those directories under `[remove]` off **one code
path**: on a dry run the emptiness is *predicted* (a directory counts as empty when every file still in
it is already on the remove list), which is the same question `-Apply` answers by looking. One label
serves the printed line and the tally, so the list and the number cannot describe an item differently.

**2. The free-standing audit now excludes at line granularity, not only per file.** The 3.0.0 fix
excluded *files* the run is about to delete; the bootstrap's orchestrator note and its `@`-import(s) are
*lines* it deletes inside a `CLAUDE.md` that stays. So a dry run reported `CLAUDE.md:<n> -- name 'Chris'`
as a surviving live reference on the very run that lists that line under `[remove]`, and the audit fell
from 5 live references to 4 after `-Apply` on a consumer that changed nothing in between — over-reporting
by exactly what the run removes, in the mode where a reader is least able to tell. The predicate is
**hoisted and shared** with the section that does the removing (a predicate mirrored by hand in two
places is what produced both instances of the orphaned-note defect), and it matches on **content, not
line numbers**: after `-Apply` every number has shifted, so a number-based exclusion would skip the wrong
lines. The exclusion is stated in the scan line like the file-level one, and it counts **references
excluded rather than lines skipped** — most removed lines carry no reference at all, and counting those
would inflate a notice into a claim.

**3. `specialists-init` no longer documents fewer personas than it places.** `SKILL.md` named three
(Chris `01-01`, Derek `05-05`, Rendall `05-06`) while the bootstrap enumerates `personas/` and places
**four** — `03-02` (Bianca) was missing from the prose. Nothing miscounted: the closing line reported
`4 persona-lens(es) created` honestly and the total was right; the description was simply narrower than
the behaviour, which costs a reader a detour. The doc now says the set is read from the payload, lists
all four, and names the run's own counter as the authority — so it grows on its own when a release adds
a persona.

**Tests (all three, and each verified to fail against the old code — 7 asserts did):**
`teardown.tests.ps1` gains *"the dry run and the apply run count the same items"* (both counts read out
of the real output rather than pinned to today's lens inventory, so the next added specialist does not
break the guard) and *"the audit excludes removed CLAUDE.md LINES"* (a fixture carrying one genuinely
authored `Derek` reference, so "no hits at all" cannot pass it for the wrong reason, plus the
before/after-`-Apply` count that used to drop by one). `bootstrap-drift.tests.ps1` gains a check that
`SKILL.md` names **every** persona id the payload ships and that the run's counter matches that number.

Reported from a consumer via [issue #275](https://github.com/DaveKJohn/davekjohns-workshop/issues/275).
