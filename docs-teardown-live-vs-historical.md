### Separate live references from historical ones in the teardown goal · Docs · 2026-07-29

The last two findings of the hand measurement in `davekokbwj/smartwatchbanden` (July 29, 2026), and the
second one moves the goalpost rather than adding to the list.

**A consumer gate that goes blind rather than red.** A consumer that lints its own lens files keeps that
check after a teardown, and in the measured repo the lens category **silently skips** once the directory
is gone: nothing errors, nothing is reported, and the gate stays green while checking nothing. Right for
a deliberate teardown, wrong for an accidental loss — a silent skip cannot tell an operator's removal
from a bad merge or a mistyped path, so the one case it must warn about is the one case it stays quiet
in. The gate is the consumer's own, so this is documented rather than fixed here, together with the
target-shape requirement that a skip should *say* it skipped.

**The goal is no *live* reference, not zero references.** `CHANGELOG.md` (3) and
`releases/development/*` (43) mention specialists in the measured repo — 46 references that are each an
accurate record of something that happened. History is finished business: never rewritten, and a
teardown must not touch it. So the requirement as literally stated ("no lingering reference anywhere in
the repo") is both unreachable and undesirable for any repo that ever adopted the plugin, and it is now
read as: nothing a **session loads**, a **script resolves**, or a **gate depends on** may still point at
the plugin. That reading makes the goal testable and sorts the four known leftovers by what they cost —
a resolver that throws breaks a run, an orphaned roster row only misleads a reader.

Recorded in the [family README](claude-code-plugins/claude-specialists/README.md#removal-the-teardown-gap)
(the requirement itself, plus a fifth target-shape bullet) and in
[`specialists-teardown`](claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md),
whose leftover section now runs to four kinds and closes with what is correctly left standing.
