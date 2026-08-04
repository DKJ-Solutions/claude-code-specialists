### In the source repo the source is the default destination, not the lens · Docs · 2026-08-04

**Dave's correction, August 4, 2026: this repo *is* the source, so a lesson learned here belongs in the
shared source unless it genuinely only applies here.** The lens is for what a *consumer* would have to
differ on — not the convenient place to write something down because it is the file already open. The
consequence of getting it wrong is one-directional and silent: a portable rule written into the lens
reaches nobody downstream, and looks identical while you are typing it.

**The measurement that shows how far this had drifted.** Rendall #06's portable persona is **1,700
bytes**; his repo lens had grown to **26,914** — sixteen times larger, and holding the release craft
itself rather than anything specific to this repo. Derek #05 sits at 5,835 against 23,995, Chris #01 at
7,943 against 14,469. The lens was winning everywhere.

**The layer test was measured rather than invented, and it changed the plan.** The first assumption was
that portable documents cannot carry repo-specific evidence at all. Held against the plugin's own files
that is true of **personas and manuals** — zero issue numbers, versions, repo names or person names across
all 18 — and false of **skills**, which carry 103 such references, including a character limit attributed
to the consumer repo it was hit in. So the convention the repo has actually been holding is three-layered:
the craft goes to a persona or manual stripped of every number, a *procedure whose reason rests on a
measurement* goes to the **skill** with the measurement included, and only what is true solely here stays
in the lens. Had the first assumption been acted on, today's lessons would have been abstracted into
toothless one-liners to fit a rule the repo does not have.

**Applied to the four lessons recorded in lenses earlier today.** Three were already in the right place:
the release-body rule, the attachment-name collision and the snapshot heading had all gone into the
`cut-release` skill with their measurements, and the snapshot rule into the script's own skeleton hint.
The fourth had not: **the parked-branch lesson now lives in the `park` skill**, which described parking
in full and picking a branch back up not at all. A consumer meets that gap exactly as this repo did.

**The two lens blocks that duplicated the source are reduced to their local half** — the rule and the
mechanism read from the skill, the lens keeps the citation naming where it was measured. Net: 90 lines
added, 33 removed, and the portable side gained everything the lens side lost.

**Recorded in the two places someone looks:** the practical test and the three-layer table in the
[Specialists handbook](.claude/specialists/README.md), where the source-vs-lens model is already
explained, and the rule itself in [`CLAUDE.md`](CLAUDE.md)'s repo slot beside "changes to shared agent
defs land here first" — which stated the same instinct about agent defs and had never been generalised.

**Deliberately not done, and it is a decision rather than an omission.** Rendall's remaining ~26 KB is not
migrated here. Most of it is portable — the entry-file mechanism and why a branch never edits
`CHANGELOG.md` directly, the entry format and the `##`-climbing-out-of-its-category trap, the
branch→merge→fold lifecycle with the multi-machine lesson, the two update-cache gates with their measured
`install`-versus-`update` distinction, and `-SummaryFile` — and each block needs its portable half
separated from its local half by hand before it can travel. That is several PRs of careful work in
documents that reach every consumer, so it is proposed rather than started. What stays local is already
clear: lockstep across four plugins, the per-plugin CHANGELOG and RELEASE.md cards, "only at Dave's
explicit request", which bumps get a Release, and the `3.x` grouping.
