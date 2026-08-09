## `docs/the-release-body-names-the-action` progress

### Steps

- [x] A lead-in block at the top of `releases/internal/3.x/3.10.0.md` saying that this release requires
      the reader to act and that the instructions are in the attachment, not on the page
- [x] Gates green: lint 0 errors, all 30 suites
- [x] Changelog entry: body + a score per tier

### Where I left off

One line, and it exists because the cut-release procedure asks for it: *"for a release that requires
the reader to act, the instruction lives in the attached highlights rather than on the page. Say so in
the body when that applies."*

**No previous internal note carries such a pointer, and that is not an oversight in them** -- the
clause is conditional and the condition had never held before. `v3.10.0` is the first release in this
repo where every existing installation stops resolving until the reader does something. Checked
`v3.8.0` and `v3.9.0` before writing this, rather than assuming a house pattern existed to copy.

The GitHub Release for `v3.10.0` is published straight after this merges: body = the internal note
(the highest tier this repo has, which outranks the highlights precisely because it is the one written
for whoever is deciding rather than for whoever is affected), with the notes for users and the
development notes as attachments under distinct filenames -- all three tiers name their file
`3.10.0.md`, and two attachments cannot share a name.
