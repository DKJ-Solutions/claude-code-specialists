## `docs/v3-7-0-release-documents` progress

### Steps

- [x] Generate the internal note skeleton with `new-internal-note.ps1 -Version 3.7.0`
- [x] Write the internal summary: what the organisation got out of v3.7.0, one page
- [x] Rewrite the highlights draft for a consumer -- no branch names, no IDs, no scores
- [x] State the two open items honestly in the internal note rather than leaving them out
- [x] Lint green (0 errors), PR, merge, fold
- [x] Publish the GitHub Release (body = the internal note) -- step 5 of the cut's checklist

### Where I left off

`v3.7.0` is cut, pushed and tagged. These are the two documents the cut deliberately does not write.

Both generated drafts carried branch administration -- the internal note's bullets were literally
"`feat/branch-file-form` changelog", and the highlights draft still had `### Branch ID` sections in a
customer-facing document. Edited out by hand; noted in the entry as avoidable work rather than a fault,
since both are drafts by design and nothing incorrect could ship.

After the merge and fold, the last step of the cut's checklist is the GitHub Release, with the internal
note as its body and the development notes attached. That is not a second approval point -- it is the
close of the procedure Dave asked for.
