## branch/templates/ holds a blank copy of each branch file, held to the scaffolder by the lint gate

### What does this change do?

`branch/templates/` carries a blank `branch_template_changelog.md` and `branch_template_progress.md` --
something to look at, or paste from when a file has been cut about.

**They are generated, not maintained, and that is the whole design.** A template sitting beside a
scaffolder that writes the same shape is two sources of one format, which is the drift this repo has paid
for repeatedly -- the scaffold wording, the fence readers, the tier sections. It is not a theoretical
risk here: **the entry format changed three times on the day these templates were added**, so a
hand-written copy would have been stale before it was committed.

So their content comes from the same formatters `new-changelog-entry.ps1` calls, through one function
(`Get-BranchTemplates`), and a new lint check holds the files on disk to it. Editing a template by hand
is an error the gate names; changing the format makes the templates follow. That is what lets them exist
as a convenience without becoming a second definition of anything.

**The check is asserted in both directions**, because a check that only ever passes cannot be told from
one that reads nothing: correct content is silent, a hand-edit is reported with the direction of the
drift, and a deleted template is reported rather than quietly skipped.

Two scans that walked `branch/` non-recursively now recurse into it -- the dead-link scan and the
mojibake scan. Both matter more for a template than for an ordinary file: whatever is wrong in one is
copied forward into every branch that pastes it, instead of staying in the one place it was written.

### Significance

#### Tier 0

Two more files in the repo, and one more lint check -- which is the only reason the two files are
allowed to exist.

Score: 2

Is this change also relevant to colleagues and employers? Then continue to Tier 1.
If not, stop here and move on to the next section.

#### Tier 1

The entry format now has somewhere to be *looked at* rather than only inferred from a scaffolded file or
read out of a formatter, without anyone having to keep that copy true by hand.

Score: 2

### Type of change

Feat
