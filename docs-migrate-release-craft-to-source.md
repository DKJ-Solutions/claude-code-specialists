### The release craft moves from the lens into the shared source · Docs · 2026-08-04

**Rendall's lens went from 26,219 to 21,584 bytes (−18%), and the two skills that should have been
carrying that knowledge gained it.** Green light from Dave to finish what the previous change only
established as a rule. Net 156 lines added against 97 removed — the source gained more than the lens lost,
because a rule that was implicit in a local paragraph has to be stated plainly for a reader who has none of
the surrounding context.

**The strongest justification for the whole exercise was found while doing it: the portable skill carried a
stale instruction.** `fold-changelog` told every consumer *"Then commit the result directly on main"* — by
hand. The script has been able to do that itself since August 2, 2026 via `-Commit`/`-Push`, and those
flags appeared **nowhere** in the skill; they existed only in this repo's lens. So consumers were being
told to do by hand what the shared script already did, for two days, because the improvement was written
where only this repo could read it. That is precisely the failure mode the source-first rule exists to
prevent, caught in the act.

**What moved into [`fold-changelog`](plugins/specialists/skills/fold-changelog/SKILL.md).** The entry-file
mechanism it never explained: *why* a branch never edits `CHANGELOG.md` directly (every branch would touch
the same section, and a conflict there is pure noise since the entries never disagree), the filename rule
and why a `-v2` suffix silently breaks the auto-delete, the entry format and which parts only the fold can
add, and **the `##`-in-a-body trap** — a body's `##` climbs out of its category, and it bites only once the
release cut lifts the body into the notes, past every gate that could have judged it. Plus the two things
that go wrong in practice: `gh pr merge --delete-branch` can leave the local checkout **on the merged
branch**, so check rather than trust the flag; and always fold with `-Branch` when two machines are in
play, or you fold an entry the other machine is still folding.

**What moved into [`cut-release`](plugins/specialists/skills/cut-release/SKILL.md).** The marketplace-cache
gate, as a per-command table rather than one rule — because the tidy generalisation was tested and broke:
`install` does **not** refresh the cached clone (two independent releases) while `update` **does** and
advances the clone during its own run. With the reason it must be said out loud at all: a stale cache is
invisible by construction, reporting success with a plausible version number, and an install's success line
names no version whatsoever. Also `-SummaryFile` and the milestone rule that a `major` bump must state
plainly when it breaks nothing.

**What stayed, and why it is not laziness.** The lens keeps lockstep across four plugins, the per-plugin
`CHANGELOG.md` and `RELEASE.md` cards, "only at Dave's explicit request", which bumps get a Release, the
`3.x` grouping, and the direct-on-`main` exception the fold commit runs under — that last one being exactly
what the path-scoped commit exists to keep honest, which is a governance fact about *this* repo rather than
a property of the script. Every migrated block leaves a citation naming where it was measured here:
`v2.13.2` for the `##` trap, July 16 and PRs #46/#47 for the two git lessons, `v3.0.2`/`v3.0.4`/`v3.0.5`
for the cache measurements, and the 2.x seam for the "a major that breaks nothing" case.

**One measurement worth keeping about the shape of the result.** The migrated text is longer in the source
than it was in the lens, and that is not padding: a lens paragraph can lean on the reader already knowing
the repo, while a portable one must state the mechanism from scratch. Expect the same ratio on the next
migration rather than reading the growth as duplication.
