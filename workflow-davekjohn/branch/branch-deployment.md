## `docs/lens-inbound-to-skill` deployment

### What does the change on this branch deploy to main?

Chris's repo lens stops carrying the evidence for its own rule in every session. The five inbound
failure-pattern case studies — #469 repaired inside the morning it was filed, #456's expired
reasoning, #566's `Resolve-PluginScript` that never existed, #660's `pair-cli` that named nothing,
and the four of 22 own reports whose counts were wrong — move verbatim into a new
`.claude/skills/triage-inbound/` skill. The rule stays always-loaded; the measurements are now one
invocation away, read when an inbound item is actually being triaged.

Measured rather than projected, because the projection was wrong: the lens drops 25,689 B -> 18,056 B
(-7,633 B, ~1,908 est. tokens) and the skill costs 126 est. tokens back as a resident description, so
the net is **~1,782 est. tokens per session** -- 10% of the 18.6k always-loaded chain. The first estimate
said ~2,255, counting the 94 removed lines but not the 15-line bullet that replaced them. Corrected here
rather than repaired to, which is what this repo asks of a recount that changes the number.

This follows the convention `CLAUDE.md` already records — skills carry the evidence behind a
procedure, personas and manuals carry no repo-specific detail — so it is that rule being applied to
the one always-loaded file that had not yet been, rather than a new idea about where things go.

**Score:** 3

#### What makes this change extra special

N/A — the change is entirely repo-local under `.claude/`. No plugin payload moves, so no consuming
repo and no subscriber of the specialists system receives anything from it.

**Score:** N/A

### Pull Request

Move the inbound-triage evidence out of the always-loaded lens into a skill
