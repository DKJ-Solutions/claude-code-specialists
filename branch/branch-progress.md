# Branch progress

**Branch:** `feat/branch-templates`

## Steps

- [x] `branch/templates/` with a blank copy of each branch file, generated from the formatters
- [x] One owner for what they must contain (`Get-BranchTemplates`), read by the generator and the gate
- [x] Lint check 13b holding the files on disk to it -- the only reason a second copy may exist
- [x] Recurse the dead-link and mojibake scans into `branch/`, since a fault in a template is copied
      forward into every branch that pastes it
- [x] Tests in both directions: correct is silent, a hand-edit is caught, a deletion is reported
- [~] Add a regenerate script -- dropped: two files written by one function, and the gate's message
      already names it. A script would be a third thing to keep in step with the second.
- [x] Docs: `branch/README.md`
- [x] Mirror, lint, all suites
- [x] Take `main` in and re-run the gates on the merged tree
- [x] PR

## Where I left off

Done. The folder is `templates/`, not `template/` -- corrected mid-build on Dave's word.
