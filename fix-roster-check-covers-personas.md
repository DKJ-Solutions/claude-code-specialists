### Roster check covers persona-only specialists · Fix · 2026-07-28

Inbound #204 from life-hub. `check-roster-sync.ps1` never checked whether a **persona-only**
specialist had a roster row and a lens, so the roster could lose Chris's or Derek's row and the check
would stay green. Measured in life-hub: the shared check validated **20** specialists where that
repo's own `lint-plugin-sync.ps1` compared **24** — the gap being exactly the four persona-only
main-loop specialists.

**The old exclusion bundled two decisions into one, and only the first followed from the reasoning.**
*"A persona is not an orphan"* is right — counting personas as backing is what stops them being
flagged as orphans in every real repo, and `Get-BackingIds` keeps doing exactly that, untouched.
*"A persona can therefore never be missing"* does not follow: a persona is a real specialist with a
roster row and a lens, just like an agent, and when the row or the lens is gone that is actionable
drift of precisely the kind this check exists for. The missing-row/missing-lens loop now walks agents
**and** personas, each finding naming which kind it is about.

**One persona exception remains, deliberately: the lens-header drift check.** That comparison needs
the specialist's current name, which comes from an agent file's `name:` frontmatter. A persona file
carries only `id`/`group`. Run it anyway and every persona lens whose header holds a name — i.e. all
the older ones — would be reported as drifting from its own id: a false signal in exactly the
register the session hook is being taught to trust. Documented as a gap in the script, with a test
pinning the absence of the false signal rather than the presence of a feature.

**Two consequences of extending the coverage, both handled rather than discovered later:**

- **A deliberately unrostered persona is now real drift.** This workshop has one: Bianca (03-02), a
  main-loop *intake* persona `CLAUDE.md` explicitly does not roster, because there is no
  intake-interview work here. That choice was prose only; it is now also recorded in
  `Get-RosterIgnoredIds`, where the check can read it. The ignore-list doing its job — the
  alternative was a permanent `[ERROR]` at every session start for a decision made on purpose.
- **The `sync-roster` skill would have staged nothing for the new findings.** Its `[ERROR]`-parsing
  regex matched the literal word `agent`, while both the check's own report and the session hook point
  the reader at that skill to stage the catch-up. Left alone, the pointer would have looked helpful
  and quietly done nothing for exactly the findings this change introduced. The pattern now accepts
  `persona` too. Both downstream steps already cope: the lens scaffold has been nameless since #145,
  so it needs no persona variant, and a proposed roster row falls back to the id plus an explicit
  *"(add a short description)"* placeholder — degraded on purpose rather than inventing a name a
  persona file does not contain.

**Change 2 — the orphan trail is no longer silent.** An orphan (a roster token or lens file with no
backing agent *or* persona — the "specialist removed from the plugin, consumer lens left behind"
case) is `[INFO]`, and the hook suppresses `[INFO]`, so the finding existed only for whoever
deliberately ran the script: in practice nobody. The per-orphan lines stay `[INFO]` and stay
suppressed — an orphan can be a legitimately just-removed specialist, and a red line through every
transition is how a gate gets ignored. What the check now adds is one non-counting `[ORPHANS]`
roll-up naming the count, which the hook *does* surface, in both the drift and the in-sync branch.

Deliberately **not** the alternative the issue also offered (promote the orphan to `[ERROR]`), and
deliberately not a generic *"N info signals"* line either: a repo permanently carries ignore-list
`[INFO]`s — this one has six — so a generic counter would fire at every single session start, which
is the noise PR #99 removed. No orphans means no line at all, and there is a test for that too.

**What this unblocks.** With persona coverage in place the shared check subsumes the repo-local
duplicate, so a consumer can retire its own `lint-plugin-sync.ps1` — the reason #204 was
investigated. Until this reaches a consumer via a release, that duplicate is load-bearing, not
redundant.

The issue's two closing observations (`Resolve-PluginDir`'s cache-based resolution as the reference
behavior, and the `startup`-only hook matcher) were offered as data rather than asks and are left as
they are.
