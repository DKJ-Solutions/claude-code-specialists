## `feat/release-note-root-seam` progress

### Steps

- [x] Verify #616 against the tree: the literal in `cut-release.ps1`, the seams around it, and whether
      the proposed `Get-SeamValue` mechanism exists as described
- [x] Add `Get-ReleaseNoteRoot`, defaulting to today's value, and build the note path from it
- [x] Find the other readers of that location — `session-status.ps1` turned out to be one, with the
      same hardcoded root and a path filter that could not have honoured a seam at all
- [x] Repair the report's second finding: the missing-history warning used the literal where its two
      neighbours used the seam
- [x] Register the seam (script contract + this repo's own `repo-config.ps1`) and regenerate the
      config blueprint
- [x] Document it in the portable half — the `cut-release` skill, beside the knob it unblocks
- [x] Tests: a behavioural pair for the reader (note found under a repointed root, and the absent line
      naming it), and guardrail asserts pinning writer and reader to the same seam
- [~] A seam for `releases/development/` — dropped: nobody can show a repo that differs on it, and the
      reporter said so themselves. It comes back when somebody measures it
- [x] Review the diff, run the lint gate

### Where I left off
