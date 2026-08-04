### Two release attachments cannot share a filename, and the checklist did not say so · Fix · 2026-08-04

**Found by walking the checklist rather than by reading it, on the first Release published under the new
body rule.** Step 5 said `gh release upload vX.Y.Z <development-notes> [<highlights>]` — and all three
release tiers name their file `<X.Y.Z>.md`. An asset's name is its **basename**, so the first upload
succeeded and the second returned `HTTP 404` on `…assets?label=…&name=3.3.0.md`. Every consumer following
that line with two attachments would have hit it.

**`gh`'s `file#label` syntax looks like the fix and is not.** It sets the asset's *label* and leaves `name`
as the basename — visible in the failing request above, which carried the label and the colliding name
together. The repair is to copy each attachment to a distinct filename and upload the copies
(`vX.Y.Z-development-notes.md`, `vX.Y.Z-notes-for-users.md`). Worth doing on its own merits: a reader who
downloads `3.3.0.md` cannot tell which of the three tiers they received.

Recorded in all three places someone meets this — the `cut-release` skill's step 5, the release manager's
lens, and `releases/README.md` — with the measurement rather than as advice, since the failing URL is what
makes the cause unambiguous.

**And a second defect the same publication exposed, of the class predicted a day earlier.** `v3.3.0`'s
internal note said the migration steps for the marketplace rename are "in the user-facing notes **attached
to** that release" — but `v3.2.0` has no GitHub Release, so there is no attachment to point at. The
highlights carried the same claim. Both now point at something that is true whether or not that release is
ever published: the note names the previous release's notes and the project's adoption guide, and the
highlights link the file directly.

That is exactly why the internal tier stopped being an archive document when it became the Release body
(PR #436): a claim about *where a reader can find something* is now a claim made in public, and it can be
false for a reason that has nothing to do with the release it appears in. The published body is corrected
in place once this merges.
