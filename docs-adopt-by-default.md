### Adopting a new specialist is the default, not a question · Docs · 2026-07-28

Dave, during the smartwatchbanden catch-up: the session asked him, one by one, which of five new
specialists to adopt. His answer — *it should always just be adopted after a plugin update.*

**The asking came from a hand-written handover prompt, not from the system.** Nothing in the plugin or
the repo docs said to ask; the prompt for that session did, explicitly. That is the interesting part:
the rule had no home, so whoever writes the next prompt is free to invent the approval step again. It
now lives in the two places a session actually reads at that moment — the `sync-roster` skill (where
the catch-up is staged) and `check-roster-sync.ps1`'s docstring (where the `[ERROR]` comes from) —
rather than in a prompt that is written once and forgotten.

**The reasoning, because "always adopt" sounds careless and is not.** The lens scaffold is empty on
purpose: a `VUL-IN` lens may sit untouched until that specialist actually has work in the repo — that
is what the scaffold is *for*, not an unfinished task. So adopting costs a file nobody has to fill in
yet, while asking costs an interruption over a decision with no downside either way. That is exactly
the shape of approval question the governance rule already rules out: reserve them for the
irreversible, the outward-facing, and the genuinely risky.

What stays a judgment call is the *content* — what the lens says once the specialist has work, and
where the roster row belongs — and those are writes to the governance doc, which `sync-roster`
deliberately never makes. Adoption and lens content were being treated as one decision; they are two,
and only the second needs a human.

**The ignore-list keeps its role, with its character corrected.** `Get-RosterIgnoredIds` is for a
specialist that genuinely has no place in a repo, recorded on your own initiative with a comment
naming who and why. It is a statement, not an answer to a per-update question.

Also corrected in the same pass: the ordering advice given for the smartwatchbanden catch-up. Fixing
the script contract still has to come first, but for a different reason than was written down. It is
not "so that skipping becomes possible" — it is that `check-roster-sync` needs `Get-RosterPath` and
`Get-RosterIgnoredIds` to run without a hard error at all.
