## `docs/migrating-to-teams-and-workflows` changelog

### Branch title

How an existing consumer gets from specialists to teams and workflows

### Branch ID

20260809-112623

### Branch type

docs

### What does the change on this branch bring to main?

The last of six branches, and the only one written for somebody who already adopted this product. Five
plugins were renamed, a sixth was added, and every existing install now carries an id that no longer
exists. Until this page there was documentation for adopting from scratch and documentation for leaving,
and nothing for the state every current consumer is actually in.

**The part that would otherwise be missed is not the renaming.** Swapping ids is mechanical and a
consumer will get it right. What they will not notice is that they now have a choice they never had:
measured against `connectors/`, all three registered consumers enable **no workflow at all**, because
until this release there was one workflow and it was opt-in. A consumer who mechanically maps old id to
new id ends up with their teams back and, silently, no workflow — half the product, with nothing
reporting it, because zero workflows is a legitimate state the session check is deliberately quiet
about. So the page leads with the choice rather than closing on it.

**One caveat is stated as unrepaired, on purpose.** A consumer whose repo lenses still sit on the
pre-seam path `.claude/plugins/claude-specialists/<plugin>/` has the plugin name as that second segment,
so after reinstalling under the new name the readers look under `team-alpha/` and the existing lenses
are not found. That is not fixed in code: no consumer in the register is confirmed to be on that layout,
this machine has no such directory at all, and the repair if it ever bites is renaming one directory.
Writing a fallback for a consumer nobody has found would add a path nobody tests. The page says which
layout is affected, which is not, and what to do — and does not dress it up as handled.

The register keeps each consumer on their **old** ids until that consumer has actually migrated, and
`connectors/README.md` now says so where its doctrine already explains why: the register records what a
consumer *has*, so claiming a migration nobody performed turns it into a false alarm about itself.

### Significance

#### Tier 0

The last thing this restructure owed. Nothing here changes behaviour; it closes the gap between what
the product now is and what its own pages tell somebody who adopted the previous version.

**Score:** 2

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Barely, and only through the register: whoever runs the connector check now has a written answer to why
three consumers show old ids, instead of reading it as drift somebody forgot to fix.

**Score:** 2

#### Tier 2

Is this next one still relevant for a consumer of the product?

Yes — this branch is entirely theirs. Every existing install is on an id that no longer resolves, and
this is the page that gets them off it. Without it the reachable instructions describe either a fresh
adoption or a teardown, and neither is the situation they are in.

**Score:** 5

### Pull Request
