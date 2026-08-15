## `docs/unverified-proper-nouns` progress

### Steps

#### PLAN

- [x] Verify the subject of #660 against the tree: `pair-cli` occurs in no file, no other issue or PR
      under either owner, and no repository on GitHub — one occurrence in the visible world, the issue
      itself
- [x] Ask Dave directly whether he recognises the name (he does not), and close #660 with the evidence
- [x] Measure the wish underneath the name before recommending anything: 179 issues, 178 closed, 170
      within 24h, median 3.4h, none over 7 days, 1 open

#### CREATE

- [x] Portable half in `plugins/teams/team-alpha/personas/01-01-persona.md`: the subject check as a
      fourth paragraph in the inbound route, plus the for-them-not-by-them condition that makes it likely
- [x] Repo half in `.claude/specialists/lenses/01-01-extension.md`: #660 as the fourth failure pattern,
      including the "not visible from here" mis-read and the issue-lifetime measurement
- [~] No change to the three existing failure-pattern paragraphs — dropped: they are correct as written
      and the new one sits before them rather than amending them

#### TEST

- [x] `check-plugin-integrity.ps1` green
- [x] All suites in `scripts/tests/` green

### Where I left off

Ready for the PR. After the merge: the persona change reaches consumers only at the next release, so
nothing further is needed on this branch — the fold resets these two files as usual.
