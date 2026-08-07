## `feat/scaffold-without-comments` progress

### Steps

- [x] One `-Template` switch decides guidance + the `(template)` marker together; only `Get-BranchTemplates` passes it
- [x] The routing questions go with the guidance -- Dave chose that over keeping them, shown both shapes
- [x] Both templates verify byte-identical, so the reference is untouched by this
- [x] Moved the two routing-question asserts onto the template rendering, and added the mirror assert
- [x] Took in Dave's own edit: all three tiers always present, and `N/A` for a tier the change misses
- [x] Resolved the contradiction it carried -- route said "leave empty", tier guidance said "N/A + reason"
- [x] Dropped the `Yes/No` field he had drafted beside the score; one fact, one field
- [x] The reach became "the highest tier with a NUMBER" -- reading it off section presence would have made every entry tier 2
- [x] `N/A` under a scored tier is refused by name: the ladder is cumulative
- [x] Retired `Add-TemplateTierPrompt`; there is no commented-out block left to splice
- [x] Twelve new asserts pinning the N/A semantics, including blank-is-not-N/A
- [x] Docs: branch/README.md (incl. finishing Dave's half-edit), CONTRIBUTING.md, CLAUDE.md, the new-branch skill
- [x] Took in his second edit: the three branch fields leave the step list, so nothing is stated twice
- [x] Dropped the now-unused `-Description`/`-Id` parameters rather than leaving them wired to nothing
- [x] Removed the worked example from `branch/README.md` too -- the template already carries it
- [x] Pinned the separation with a test, since the three are still entry sections and could drift back
- [x] Full suite green (26 suites, 0 failures) and lint clean, twice over after each of his edits
- [x] PR -- opened on Dave's word, August 7, 2026

### Where I left off

Green: entry-scaffold 273 asserts, new-branch 98, release-lib 374, lint 0 errors, mirrors in sync.
Full suite running. Committed locally, nothing pushed.

**Dave's edit changed the model, not just the layout**, and that is the thing to carry forward: the
sections an entry has no longer say what it reaches -- the answers inside do. Four readers had to move
with it (`Resolve-EntryImpact`, the two gates, the fold's ranking).

His `branch/README.md` was left mid-edit -- two fenced examples removed and a `## branch-progress`
heading inserted, with the prose after it still pointing at the deleted example. Finished rather than
reverted, since the new headings are clearly what he wants.
