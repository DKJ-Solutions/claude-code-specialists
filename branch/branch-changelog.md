## `docs/the-release-body-names-the-action` changelog

### Branch title

The release body points at the instructions a consumer must follow

### Branch ID

20260809-125038

### Branch type

docs

### What does the change on this branch bring to main?

A lead-in block at the top of the `v3.10.0` internal summary, because that document is the **body** of
the published GitHub Release and this is the first release where the body has to send its reader
somewhere else to act.

**Why the internal note is the body at all**, since it reads like the wrong choice for a public page:
it is the only tier written for whoever is *deciding* rather than for whoever is *affected*, and a
release page is read by both. The procedure settles it and also names the consequence — where the
release requires the reader to act, the instructions live in the attached notes for users rather than
on the page, *"so say so in the body when that applies"*.

**It has never applied before.** Neither `v3.8.0` nor `v3.9.0`'s internal note carries such a pointer,
and that is correct rather than an omission: the clause is conditional, and no earlier release in this
repo stopped an existing installation from resolving. `v3.10.0` renames every plugin, so every consumer
must act before anything works again — which makes a body that leads with what the organisation gained,
and never mentions that the reader has something to do, precisely the wrong first screen.

Checked both previous notes before writing this rather than assuming a house pattern existed to copy.

### Significance

#### Tier 0

One block in one document. What it protects is the moment the release goes public, which is the one
moment none of the gates in this repo can reach.

**Score:** 2

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Barely, and honestly: it is a precedent more than a change. The conditional clause in the release
procedure now has its first worked instance, so the next person to cut a breaking release has something
to copy instead of a rule to interpret.

**Score:** 2

#### Tier 2

Is this next one still relevant for a consumer of the product?

Yes. The release page is where most people meet a release, and without this the first screen of
`v3.10.0` describes what the project gained while their installation has silently stopped resolving.
The block puts the action on that first screen and says where the steps are.

**Score:** 4

### Pull Request
