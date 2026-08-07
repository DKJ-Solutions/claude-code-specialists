## `fix/template-trailing-newline` changelog

### Branch description
<!-- Short description of branch-->

The progress template ends with a newline

### Branch ID
<!--unique ID for branch like a timestamp of the moment this branch is created-->

20260807-091625

### Branch type
<!-- options for type are: feat, fix or docs-->

fix

### What does the change on this branch bring to main?
<!--
     What the change DOES, for someone reading CHANGELOG.md months from now --
     not a report of what you did on the branch. Name what is different afterwards,
     and where a decision was measured rather than assumed, say what was measured.
-->

`branch/templates/branch_template_progress.md` ends with a newline. It had none: an accident of the editor
the form was designed in, reproduced faithfully by `Get-BranchTemplates` while the hand-written templates
were being treated as the spec for the shape. A file without a terminator is the one whose next diff shows
a line nobody edited, and git says so on every one of them.

### Significance

#### Tier 0

<!--
     Why the change matters AT THIS REACH specifically. A reason that would read the
     same under every tier is a sign the tier is wrong. Then Score: 1-5 against the
     rubric new-branch printed when it wrote this file.
-->

One byte, and it stops every future diff of that file carrying a phantom line.

**Score:** 1

<!--
     Is this change also relevant to colleagues and employers? Then continue to Tier 1.
     If not, stop here and move on to the next section.
-->

### Pull Request
<!-- link to the PR in github when branch is merged to main and the date this happened-->

