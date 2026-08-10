## `feat/the-trunk-warning-lead-is-seamable` progress

### Steps

- [x] Verify inbound #562 still stands: `Format-BranchFileHeader` builds the lead inline, and it is the only
      fragment of the two branch files not reachable through `Get-BranchFileWordingOverrides`
- [x] Add `TrunkWarningLead` to `$script:BranchFileDefaults`, with `{0}` for the trunk name
- [x] Read it in `Format-BranchFileHeader` via a plain string replace, not `-f`
- [x] Correct the stale key count in `Get-BranchFileWording`'s docstring ("these nine" was thirteen)
- [x] Tests: the override replaces the sentence, a literal brace does not throw, an empty override keeps the
      default, and the seam function is torn down afterwards
- [x] `new-branch`'s SKILL.md: name the key, since its "exactly the English text above" promise was what the
      defect contradicted
- [x] Mirror the shared scripts, lint gate + all suites green

### Where I left off

Done. Two things the tests corrected rather than confirmed, both recorded in place: an empty override cannot
drop the sentence (the seam ignores empty values by design, so the first draft's claim was wrong), and an
assert scoped to the whole document went red on unrelated English prose — it reads only the warning block now.
