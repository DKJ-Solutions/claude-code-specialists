## `docs/release-notes-on-main` deployment

### What does the change on this branch deploy to main?

A release cut now runs in one place from end to end. The hand-written release documents — the
audience note the cut drafts, and the internal note where a repo still runs the two-document flow —
are committed straight onto `main` in the commit after the tag, instead of travelling a branch + PR.
That makes a **third** named direct-on-`main` exception beside the fold commit and the release
commit, and the three read as one procedure: fold the changelog, bump the version, write the release
notes.

It is bounded the way the other two are, because that is the only thing that keeps an exception safe:
the hand-written documents of a cut that was actually asked for, named in the commit, and nothing
else in the tree. Outside a cut there is nothing for it to be part of.

This reverses the August 4, 2026 answer, which sent those documents through the reviewed route. The
argument that answer rested on — an exception is only safe while it stays the size it was granted at
— is not overturned; it is why the new bound is spelled out rather than assumed. What changed is the
judgement about which size is right: running one procedure across two routes left the trunk carrying
a tagged release whose own notes were still in review.

**Score:** 4

#### What makes this change extra special

Anyone running this workflow gets a shorter, single-track release. What used to be a cut, a branch, a
PR, a CI wait and a merge is now a cut and a second commit — and the step-zero timing instruction
loses two of the legs it could not measure. Nothing already published changes, and the tag still
holds the draft exactly as before, so there is no action to take: the next cut simply commits where
it used to open a PR.

**Score:** 3

### Pull Request

The written release notes land directly on main

