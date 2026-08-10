## `docs/the-rename-has-a-migration-path` progress

### Steps

- [x] Verify all three inbound issues still stand, and establish what the existing migration section already
      covers -- the id table landed with the rename, the two in-repo repairs did not
- [x] Verify the replacement path claim by reading the code rather than assuming it: `new-branch.ps1` is
      idempotent on an existing branch (`git checkout` when the ref exists), so it does serve the
      Dependabot case
- [x] Verify the current clone layout against `.claude-plugin/marketplace.json` rather than from memory
- [x] `INSTALL.md`: the two things the id swap does not fix -- the `@`-import (with before/after) and the
      roster prefixes, plus why neither skill repairs them
- [x] `INSTALL.md`: a section for a consumer calling the shared scripts -- the removed script and its
      replacement, the moved entry files and the CI gate to check, the dead `Get-ChangelogHeading`
- [x] `cut-release` SKILL.md: the convention for a cut that retires a script, a contract function or a
      convention -- and why no gate was built
- [x] Lint gate + all suites green

### Where I left off

Done. Two self-inflicted corrections worth naming, both caught before the PR: the lint's `expected-output`
check refused two unbound fenced samples, which is what turned the before/after import into one labelled
block with its binding stated; and I first wrote "4 personas + 21 subagents = 25 for `team-alpha` alone",
which is the measured consumer's total with three teams enabled -- `team-alpha` on its own is the figure Step
2 already prints. The sentence now says the rename moves no count at all, which is the fact a reader can
actually use while editing prefixes.
