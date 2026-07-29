### Verify the stand against the repo, not a handover text · Docs · 2026-07-30

[Chris's lens](.claude/specialists/lenses/01-01-extension.md) now carries a rule next to *Consult the
docs*: a session-start briefing is a pointer, not an inventory, and the repo is what settles the stand.

**The incident.** On July 29, 2026 Dave's self-verifying start prompt — the one whose whole design is
*"hij vertelt je wat er geladen moet zijn, zodat afwezigheid opvalt"* — arrived **three times, identically
truncated** at the same character. It broke off mid-word inside open point 2 and resumed at the tail of a
bullet whose subject was gone, taking one pitfall with it entirely, the opening of another, and —
unknowably — any open points numbered after 2. Re-sending did not help; the channel would not carry it.

**Why it is worth a rule.** A prompt built to make absence conspicuous became the thing that hid absence:
the visible points looked complete, and nothing in a truncated list announces what is missing. The two
fixes that day survived it only because they were built on the code rather than on the description — the
second bug in #257 (`$anyLensFile` not scanning the seam) was not in the briefing at all. And the
briefing's *expectations* went stale in the same session: it kept predicting the one `[INFO]` that #257
had already removed, which is the friendlier half of the same failure.

The rule therefore names this repo's concrete verification surfaces — `git status`/`git log`, the
`## Pull Requests` section, the root checked for **unfolded entry files**, and the two gates — and states
that where briefing and repo disagree, the repo wins and Chris says so out loud.

**On why this is not just a memory note.** It was written to memory first, which
[`CLAUDE.md`](CLAUDE.md#general-working-practices) rules out on its own: *"a memory note alone is too
noncommittal."* Dave asked at close of day that everything be on origin, and a note under
`~/.claude/projects/` is not. The memory pointer stays for fast recall next session; this lens block is
the record.
