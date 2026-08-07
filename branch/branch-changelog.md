## `feat/branch-file-form` changelog

### Branch description
<!-- Short description of branch-->

The branch files take the form Dave designed

### Branch ID
<!--unique ID for branch like a timestamp of the moment this branch is created-->

20260807-000213

### Branch type
<!-- options for type are: feat, fix or docs-->

feat

### What does the change on this branch bring to main?
<!--
     What the change DOES, for someone reading CHANGELOG.md months from now --
     not a report of what you did on the branch. Name what is different afterwards,
     and where a decision was measured rather than assumed, say what was measured.
-->

The two files a branch works in now carry the form Dave designed, and `branch/templates/` holds it as the
spec rather than as a copy: the generator reproduces both files **byte for byte**, so they were never
edited to match the code. The entry became the branch's own dossier -- the heading names the branch, and
six sections carry the description, a creation timestamp, the type, what the change brings to `main`, the
Significance sub-sections and a `Pull Request` section the fold fills from the merge.

Every field is now a heading with a guidance comment above an empty space, which retired the last visible
`TODO:`. So the scaffold gate stopped matching prose and started **measuring**: it refuses an entry whose
description, body or any tier's reason is empty once the comments are stripped -- strictly more than the
strings caught, because it also catches a placeholder deleted rather than answered. Every older shape is
still read: the retired section headings, the plain `Score:`, the one-line routing questions and the
`Tier: N` line.

Three defects surfaced while wiring it, each found by a check rather than by a report. The fold never
called the comment stripper written for it, so every guidance block would have folded into `CHANGELOG.md`
verbatim. The step gate read the three example marks out of its own guidance comment, reporting four open
steps on a fresh branch -- three of which no one could resolve, since they return with the next scaffold.
And `Resolve-EntryType` took the first line of its section, which is now the hint, so every new entry
declared its type to be `<!-- options for type are: feat, fix or docs-->`.

### Significance

#### Tier 0

<!--
     Why the change matters AT THIS REACH specifically. A reason that would read the
     same under every tier is a sign the tier is wrong. Then Score: 1-5 against the
     rubric new-branch printed when it wrote this file.
-->

Filling either branch file is now a form with the guidance beside each box, and the three defects above
would each have reached `main` silently.

**Score:** 4

<!--
     Is this change also relevant to colleagues and employers? Then continue to Tier 1.
     If not, stop here and move on to the next section.
-->

#### Tier 1

Every branch in this project starts from these two files, so the shape is the first thing anyone working
here meets -- and the gates that read it decide what a release can be cut from.

**Score:** 3

<!--
     Is this change also relevant to the people who consume this product? Then
     continue to Tier 2. If not, stop here and move on to the next section.
-->

#### Tier 2

The scaffolder and the gates are plugin-carried, so a consumer's next `new-branch` writes this form
whether or not they went looking for it. Nothing they already have breaks -- every older shape is still
read, deliberately -- but the file they open on their next branch looks different.

**Score:** 4

### Pull Request
<!-- link to the PR in github when branch is merged to main and the date this happened-->

