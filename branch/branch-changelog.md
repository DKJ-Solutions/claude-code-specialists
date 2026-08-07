## `feat/scaffold-without-comments` changelog

### Branch description

The scaffolded branch files carry no guidance comments

### Branch ID

20260807-103608

### Branch type

feat

### What does the change on this branch bring to main?

`new-branch` writes both branch files **bare**: headings, the three fields it fills in itself, and nothing
else. Every HTML comment -- the per-field guidance and the two routing questions under Tier 0 and Tier 1 --
is now written only into the copies under `branch/templates/`, which is what those copies are for. The file
you write in stopped being mostly form text.

One switch carries it. `Format-EntryBlock -Template` and `Format-BranchProgressScaffold -Template` are the
only renderings that emit guidance, and they are also the only ones that mark their heading `(template)` --
one flag rather than two, because those are the same fact: this is the reference, not somebody's working
file. `Get-BranchTemplates` is the only caller that passes it.

Nothing downstream changed, and that is the part that was checked rather than assumed. The scaffold gate
already **measured** empty fields instead of matching placeholder prose, so it is unaffected. The fold keeps
its comment stripper: every branch in flight, here and in every consumer, carries comments right now, and
they meet these scripts through a plugin update rather than by choosing to.

### Significance

#### Tier 0

The file you actually type in is now the questions and your answers, with the reference one directory away.

**Score:** 3

#### Tier 1

It reverses a decision from the day before -- the routing questions were added so an author who stops at
tier 0 has decided there is nothing above it rather than never having been asked. Weighed against both
shapes side by side and chosen deliberately: the ladder is learned from the template and `CONTRIBUTING.md`
now, rather than from the file in front of you.

**Score:** 3

#### Tier 2

The scaffolder is plugin-carried, so a consumer's next `new-branch` writes the bare form. Their templates
still carry the full reference, and everything they already have keeps working.

**Score:** 3

### Pull Request
