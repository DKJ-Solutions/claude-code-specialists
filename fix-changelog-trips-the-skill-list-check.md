### A changelog entry no longer trips the check it describes · Fix · 2026-07-29

Cutting v2.13.0 aborted: the lint gate failed **on `main`**, on content no PR gate could have caught.

PR #233's changelog entry described the skill-enumeration check and wrote its marker out literally
inside backticks. Check 10 scans `CHANGELOG.md` for those delimiters and does not skip code spans, so it
saw an opening marker with no matching close and reported the changelog as a broken enumeration. The
entry is reworded to name the marker without its delimiters, which unblocks the release.

**The reword is the symptom. The defect is the window, and it is structural** — filed as
[#234](https://github.com/DaveKJohn/davekjohns-workshop/issues/234). The text lived in the root entry
file while the PR was open, and root entry files are not in check 4's scan set. It only enters a scanned
file at **fold** time, which happens directly on `main` after the merge, past every PR gate. So:

- CI on the PR is green, because the text sits in an unscanned file.
- The fold introduces the error, and the fold is one of the two sanctioned direct-on-`main` actions, so
  nothing reviews it.
- The next thing to run the full gate is `cut-release.ps1`, which refuses to release.

A release blocked by one changelog sentence is a cheap outcome. The general shape — *the fold can
introduce a lint error that no PR gate can see* — is not, because the same window covers anything checks
4 and 10 look for: a dead link written into an entry body, a broken anchor, a stray marker. The likely
fix is to add root entry files to the scanned set, so the PR gate sees exactly what the fold will paste
into `CHANGELOG.md`; that closes the window rather than the symptom, and needs no change to a guard's
semantics. Deliberately not rushed into this PR, because a release was waiting on it and a guard is the
wrong thing to change in a hurry.
