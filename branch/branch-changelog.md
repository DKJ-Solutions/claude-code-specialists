## `docs/migration-before-layouts` changelog

### Branch title

The migration section tests by shape, and names both before-layouts

### Branch ID

20260812-103540

### Branch type

docs

### What does the change on this branch bring to main?

The *"Migrating from the old plugin names"* section in `plugins/INSTALL.md` gave exactly one **before**
path for the `@`-import repair, and one before-path per row in the folder table beside it. There were
two in the field, and the one documented was the further of the two from the migration's own starting
line.

Measured across every tag this repo has cut, rather than reasoned about:

| layout | shipped by | a team's folder |
|---|---|---|
| two-level product folder | `v1.1.0` – `v3.1.2` | `claude-code-plugins/claude-specialists/specialists/` |
| flat plugin folder | `v3.2.0` – `v3.9.0` | `plugins/specialists/` |
| teams and workflows split | `v3.10.0` onward | `plugins/teams/team-alpha/` |

**The reporter's own framing is corrected by that measurement**, which is why it was run rather than
taken: their issue states that `3.2.0` is the *last* version under the old plugin id. It is the
**first** version of the second layout, and the old ids survived through `v3.9.0` — eight releases, not
one. So the gap was never a single stale line; it was a whole era of the product that the section did
not describe.

**A second defect the report did not name, found by the same measurement:** the folder table's third
row gave `claude-code-plugins/claude-specialists/specialists-workflow-davekjohn/` as the workflow
plugin's before-path, and **that path never existed**. The workflow plugin first shipped in `v3.8.0`,
by which time the flat layout was two months old — so a reader following that row was looking for
something no release ever contained.

The repair takes the alternative the reporter offered as the more durable of the two, and keeps the
literals as well. The test is now the **shape** — *any import whose path does not contain
`plugins/teams/<team>/` or `plugins/workflows/<workflow>/` is stale, whatever it contains instead* —
with both real before-forms quoted underneath it and the version range each belongs to. The section
also says out loud what to do when neither literal matches, because that is the failure it exists to
prevent: this repair is the silent one, so a consumer who searches for the quoted line, finds nothing,
and reasonably reads that as *"not mine to make"* is left with an orchestrator running bodyless.

Reported from a consumer as inbound
[#612](https://github.com/DaveKJohn/claude-code-specialists/issues/612), while migrating a repo off
`specialists@3.2.0`.

### Significance

#### Tier 0

Nothing here reads this section — this repo has never been a consumer of the old ids. What it prevents
is a maintainer re-deriving the layout history from install records the next time somebody asks, which
is what this branch had to do to answer it.

**Score:** 1

Is there a tier above this one?

#### Tier 1

The measurement is now written down where it belongs: three layouts, their version ranges, and the one
row that was describing a path no release shipped. Both were previously recoverable only by walking the
tags.

**Score:** 2

Is there a tier above this one?

#### Tier 2

This is the page a consumer follows to migrate, and its silent repair is the one it warns about first.
Anyone still on `v3.2.0` – `v3.9.0` — the whole second era — was reading a before-path they do not have,
with no feedback loop to tell them so. One consumer already hit exactly that and had to reason it out
from their own install record.

**Score:** 4

### Pull Request
