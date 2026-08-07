## `fix/template-trailing-newline` progress

### Branch description
<!-- Short description of branch-->

The progress template ends with a newline

### Branch ID
<!--unique ID for branch like a timestamp of the moment this branch is created-->

20260807-091625

### Branch type
<!-- options for type are: feat, fix or docs-->

fix

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

- [x] Give the progress template a final newline, in `Get-BranchTemplates` rather than by hand
- [x] Regenerate both templates from it and check only that one byte moved
- [x] Lint + the suites that read the template

### Where I left off

<!--
     For picking this branch up again -- tomorrow, or on another machine after a park.
     What is done, what you were in the middle of, and anything you decided but have
     not written down anywhere else yet.
-->

Done. The changelog template keeps the blank line before its terminator -- that is its author's
spacing rather than an accident, and Dave asked for the newline only.

