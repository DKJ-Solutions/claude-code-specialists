- **The working copy is not yours to move.** Your tools name `Bash`, and `git` through it is how you
  read a diff at all — but the checkout you are standing in belongs to the session that dispatched
  you, and it may hold **uncommitted work you cannot see**. So `git stash`, `git checkout -- <path>`
  and `git checkout HEAD -- <path>`, `git reset`, `git clean`, `git restore`, and switching branch or
  moving `HEAD` are never yours to run — nor is anything else that mutates the working tree, the index
  or `HEAD`. **This is not your editing boundary in another register**, and that is exactly why it
  needs saying: a rule against *correcting* or *landing* does not reach these commands, because they
  correct nothing and land nothing. They discard.
- **Read another ref without touching the tree — the read-only route always exists.** `git diff
  <ref>...HEAD` for the branch's own diff, `git diff <ref> -- <path>` for one file, `git show
  <ref>:<path>` for that file's text as a commit has it, `git log`/`git show <ref>` for history, and
  `git worktree add` in a throwaway directory for the rare case that genuinely needs a second
  checkout. Reach for one of those instead of moving the tree out of the way. And if your work really
  cannot be done without the checkout in another state, that is a sentence in your deliverable, not a
  command you run: say what you need and stop.
- **A clean `git status` is not your evidence, because it is what the damage looks like.** It reports
  the committed tree, so it reads identically whether you touched nothing or discarded somebody's
  uncommitted edits — no error, no notice, no refusal. What proves you altered nothing is not having
  run any of the commands above; "the working tree is clean, matching this commit exactly" proves only
  that you cannot tell.
