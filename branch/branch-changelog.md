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

**And the step list carries the plan and nothing else.** Description, ID and type briefly sat at the top of
both files so the pair would say whose it is; they are the entry's alone now. The same information in two
places is free to disagree, and here it would have been visible on every branch -- two files side by side,
each with its own copy of the same three boxes. The step list identifies itself by its heading, which is
the one thing any script reads out of it besides the step marks.

**And the tier model changed with it.** All three tiers are now written into every entry instead of tier 1
and 2 arriving commented out, and a tier the change does not reach is **answered** -- `**Score:** N/A` with
a line saying why -- rather than left out. The reason is the same one behind the bare files: an absent
section and an unfinished one look identical, so no gate could tell *"this reaches no consumer"* from
*"nobody has got to tier 2 yet"*, and those need opposite responses. **The reach is now the highest tier
carrying a number**, where it used to be the highest tier with a section -- without that, every entry would
have read as tier 2 and repo-internal work would have been published to consumers. A `Yes/No` field was
drafted alongside the score and dropped: a score and a yes are one fact, free to contradict each other.

### Significance

#### Tier 0

The file you actually type in is now the questions and your answers, with the reference one directory away
-- and an unreached tier states its reason instead of vanishing, so a negative claim survives into the
record rather than being thrown away.

**Score:** 3

#### Tier 1

Two decisions from the day before are reversed here, both deliberately and both after being shown side by
side: the routing questions leave the working file, and an unreached tier is answered rather than absent.
The first has a cost worth naming -- the ladder is learned from the template and `CONTRIBUTING.md` now,
not from the file in front of you. The second removes one: a blank no longer has to mean two things.

**Score:** 3

#### Tier 2

The scaffolder is plugin-carried, so a consumer's next `new-branch` writes the bare form. Their templates
still carry the full reference, and everything they already have keeps working.

**Score:** 3

### Pull Request
