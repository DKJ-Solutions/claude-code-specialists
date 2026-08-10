## `feat/the-github-release-body-is-generated` changelog

### Branch title

The GitHub Release body is generated, so the page stops depending on which note exists

### Branch ID

20260810-231904

### Branch type

feat

### What does the change on this branch bring to main?

`cut-release.ps1` writes `releases/development/<dir>/<X.Y.Z>-github-body.md`: the release title, a
pointer at the attached notes where one is expected, and **one linked line per change that landed**. The
hand-written tier documents become attachments. Generated from the three entries pending today it comes to
**10 lines and 57 words** — a page a reader can take in at a glance, with every change clickable.

**The body was the internal note from August 4 to August 10, and that was a coupling dressed as a choice.**
The reason recorded for it was that the internal note is the only tier written at *every* release, so the
only one that could be the body under a no-exceptions rule. Read the other way round, that says the Release
page depended on which hand-written document happened to exist — and it is precisely why a patch nobody
wanted a note for still needed one. Cutting the dependency is what lets the **document** model be
simplified separately from the **page**, which is the next change rather than this one.

**Every tier is in the list, and that is not the ladder being ignored.** The tiers decide which *document*
a change appears in; this is not one of those documents. "What landed" is the question someone arriving
from a tag or a diff has, and a repo-internal change still landed.

**Three failure modes closed by construction rather than by care.**

- **It has to be built by the cut**, because that run empties `CHANGELOG.md` — the entries the list is made
  of are gone a moment later, and nothing could regenerate the body afterwards except the archived notes.
- **An entry with no PR link is listed without one, never dropped**, and a title-less entry falls back to
  its own heading. A hand-filed entry, or one whose fold could not reach the PR, would otherwise vanish
  from the only complete list — silently, which is this repo's recurring failure shape.
- **The link is read from the `Pull Request` section rather than from the first match in the entry**,
  because an entry body may quote a PR of its own. The entry for this very change would have been at risk
  from the naive version.

**The pointer line is gated on a document actually being expected.** Naming an attachment that will not
exist is the confidently-wrong published line this repo keeps finding in its own records, so a release with
no hand-written document emits no pointer instead of a promise.

**And the length problem is gone by construction.** `gh release create`'s body caps at 125,000 characters;
life-hub's v2.1.0 development notes were 134,419 and returned an HTTP 422. A title and a list cannot reach
that.

The `cut-release` skill's three-row body table is retired, its step 5 keeps its position for a **new**
reason — the attachments are what step 4 produces — and the note about why the Release moved to last is
kept in the past tense rather than rewritten, because a step whose reason has been replaced is a step
somebody will try to move back.

One process lesson recorded alongside it, in Chris's gatekeepers: `ship-pr.ps1` switches to `main` to fold,
so the end of every successful chain leaves you on the trunk with a clean tree. This branch's own work was
started on `main` for exactly that reason and caught by Dave before anything was committed. The check
belongs at the start of every *assignment*, not every session — a bare "go ahead" is an assignment.

### Significance

#### Tier 0

Nobody has to decide which document is the body any more, and what was published is now recorded in the
tree instead of existing only on the Release page.

**Score:** 3

#### Tier 1

The Release page is the same shape at a patch as at a major, and it no longer requires a hand-written
document to exist at all.

**Score:** 3

#### Tier 2

A consumer arriving at the Release page gets every change with a link to its PR, instead of a document
written in the register of a different audience. The body also cannot hit the size limit that fails a
publish.

**Score:** 3

### Pull Request

