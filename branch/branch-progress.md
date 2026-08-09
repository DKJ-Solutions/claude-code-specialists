## `docs/major-prep-exception` progress

### Steps

- [x] Name the preparation step in the release exception in `CLAUDE.md`, bounded to a major, to the two paths, and to a cut that was asked for
- [x] Mirror that boundary in Rendall #06's repo lens, where the direct-on-`main` exceptions are listed
- [x] Carry the step into the portable `cut-release` skill as step 0 — a consumer meets the same refusal and had no documented way through it
- [x] Extend `cut-release.ps1`'s new-major refusal so its advice names the pinned assert as well as the section, and re-mirror it to the plugin
- [x] Check whether the extended advice needs a test: yes — four asserts in `cut-release-guardrail.tests.ps1`, verified to go red against the previous version of the script
- [ ] Review pass on the diff (copy edit + code review)

### Where I left off

