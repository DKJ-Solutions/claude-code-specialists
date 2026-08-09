## `docs/v4-0-0-release-documents` progress

### Steps

- [x] Author the milestone recap for the chapter-3 arc and cut `v4.0.0` with it via `-SummaryFile`
- [x] Generate the internal-note skeleton with `new-internal-note.ps1 -Version 4.0.0`
- [x] Write the internal summary: what is different, what it is worth, what was open at the cut
- [x] Rewrite the highlights draft for a consumer, with the from-which-version routing sections
- [x] Verify the relative links in both documents resolve from their own directory

### Where I left off

Both hand-written documents are finished, so this branch's own plan is done. What follows is the
surrounding procedure rather than a step of this branch: ship these two through the normal route, and only
then publish the GitHub Release — in that order, because the body is the internal note and publishing
earlier would publish a document that does not exist yet.
