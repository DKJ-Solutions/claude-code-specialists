## `docs/branch-name-rule-why` progress

### Branch description
<!-- Short description of branch-->

The branch-name rule records why it exists

### Branch ID
<!--unique ID for branch like a timestamp of the moment this branch is created-->

20260807-100032

### Branch type
<!-- options for type are: feat, fix or docs-->

docs

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

- [x] Record the WHY of the 'final' rule in the docstring, in Dave's own words, and fix the attribution
- [x] Note the retired opposite rule (`-v2`) beside it, so nobody reinstates it in good faith
- [x] Make the refusal message name the remedy instead of only what was refused
- [x] Loosen the test off the literal Reason string onto its two load-bearing halves
- [x] Lint + the branch-info suite

### Where I left off

<!--
     For picking this branch up again -- tomorrow, or on another machine after a park.
     What is done, what you were in the middle of, and anything you decided but have
     not written down anywhere else yet.
-->

Done. `branch-info.ps1` is repo-owned and does not travel into the plugin mirror, so this reaches
colleagues on this project but no consumer -- hence tier 1 rather than tier 2.

