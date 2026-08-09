## `docs/v4-0-0-release-body-lead-in` changelog

### Branch title

The v4.0.0 release body says where the instructions are

### Branch ID

20260809-203951

### Branch type

docs

### What does the change on this branch bring to main?

A lead-in block at the top of the `v4.0.0` internal summary, matching the one `v3.10.0` received for the
same reason: that document is the **body** of the published GitHub Release, and the internal tier
deliberately carries no file names, no commands and no code — so where a reader has to act, the
instruction is on an attachment rather than on the page they are looking at.

**`v4.0.0` is the case that reads as not needing one, which is why it does.** The release itself asks
nothing of anyone: eleven documentation and pull-request-body changes, nothing breaking, nothing to run.
But a **major** is the version number most likely to make somebody open the page after skipping several
releases — and the chapter it closes contains **two** changes that break every existing installation
without producing an error message, the marketplace rename in `v3.2.0` and the plugin-id rename in
`v3.10.0`. A reader arriving from before either one has a session that starts normally with no specialists
in it, and a body that opens "this release asks nothing of you" is, for them, true and useless.

**So the block states both halves and hands off.** It says the release requires nothing, that the version
they are coming *from* may, and that the routing lives in the attached notes for users — which is where
the three from-which-version sections were written, one per breaking release, keyed on the state the
reader is in rather than on a version they have to work out for themselves.

**Written before the Release was published rather than after.** The body is a file, so a pointer added
later would mean editing a published page — and the ordering the closing checklist already enforces, that
the hand-written documents merge before the Release is created, is exactly what makes this the cheap
moment to notice it.

### Significance

#### Tier 0

The lead-in is now the second instance of a pattern rather than a one-off, which is what makes it
findable next time: the previous release's note carries the same block for the same structural reason.

**Score:** 2

#### Tier 1

This is the tier that reads the internal note, and it is the page's own opening. Before this block the
document told a reader on an old install that nothing was required of them, which is the one thing that
page should never say to that reader.

**Score:** 3

#### Tier 2

The published Release page is where a consumer lands from a version notification, and a major is the bump
most likely to be reached after skipping releases. This is the sentence that stops a silent broken install
from being read as a working one.

**Score:** 4

### Pull Request

