## `feat/branch-file-form` progress

### Branch description
<!-- Short description of branch-->

The branch files take the form Dave designed

### Branch ID
<!--unique ID for branch like a timestamp of the moment this branch is created-->

20260807-000213

### Branch type
<!-- options for type are: feat, fix or docs-->

feat

### Steps

<!--
     The plan for this branch. Every step must be resolved before the PR: open-pr and
     ship-pr both refuse while anything is still "- [ ]", and there is no -Force.

       - [ ] not done yet
       - [x] done
       - [~] dropped -- why it turned out not to be needed

     The dropped mark exists so nobody is pushed into ticking a box for work they did
     not do. It keeps its line and its reason, which is the half worth reading later.
-->

- [x] Reproduce both templates byte-for-byte from the formatters, so Dave's files stay untouched
- [x] The entry becomes the branch dossier: six sections, branch heading, `**Score:**`, filled ID and type
- [x] The step list follows the same shape, keeping one open step in the real file (not in the template)
- [x] Readers keep recognising every older shape: retired headings, plain `Score:`, one-line questions
- [x] The scaffold gate measures empty fields instead of matching placeholder prose
- [x] Wire the comment stripper into the fold -- it was written for that caller and nothing called it
- [x] Stop the step gate reading the three example marks out of its own guidance comment
- [x] Exclude `branch-progress.md` from the lint's entry check, now that it opens with an `##` too
- [x] Rebuild the plugin mirrors and update `branch/README.md` + `CLAUDE.md`
- [x] Also brought the four consumer-facing skill pages along -- they still showed the impact table
- [x] Lint green (0 errors) and all 26 suites green

### Where I left off

<!--
     For picking this branch up again -- tomorrow, or on another machine after a park.
     What is done, what you were in the middle of, and anything you decided but have
     not written down anywhere else yet.
-->

Built, and both templates verify byte-identical against the generator -- their file timestamps are
still Dave's own, so they were never written to. Lint 0 errors, all 26 suites green.

Two byte-level questions were left for Dave rather than decided here, because both live in HIS files
and the instruction was not to touch them:

  * the Pull Request hint ended in Dutch ("en de datum waarop dit gebeurde"), which conflicts with the
    repo's rule that script-generated document content is English -- and this one ships to consumers.
    **Translated on his word, August 7, 2026**, in the SOURCE, with the template regenerated from it:
    one line changed, and it changed in the direction the format is meant to travel;
  * `branch_template_progress.md` has no final newline, so the generator reproduces that too. Left as
    it is -- he did not ask for it, and it is harmless.

