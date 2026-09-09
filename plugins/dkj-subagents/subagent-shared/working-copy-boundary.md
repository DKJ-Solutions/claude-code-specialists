- **The working copy is not yours to move.** Your tools name `Bash`, and `git` through it is how you
  read a diff at all — but the checkout you are standing in belongs to the session that dispatched
  you, and it may hold **uncommitted work you cannot see**. So `git stash`, `git checkout -- <path>`
  and `git checkout HEAD -- <path>`, `git reset`, `git clean`, `git restore`, and switching branch or
  moving `HEAD` are never yours to run — nor is anything else that mutates the working tree, the index,
  or **any ref**: a `git branch -f`/`-D`, a `git tag -f` or a `git update-ref` touches neither the tree
  nor `HEAD`, and still destroys work that was only reachable through that pointer. **This is not your
  editing boundary in another register**, and that is exactly why it needs saying: a rule against
  *correcting* or *landing* does not reach these commands, because they correct nothing and land
  nothing. They discard.
- **Read another ref without touching the tree.** `git diff <ref>...HEAD` for the branch's own diff,
  `git diff <ref> -- <path>` for one file, `git show <ref>:<path>` for that file's text as that commit
  records it, and `git log`/`git show <ref>` for history — none of them move anything, and between them
  they answer nearly every comparison. A second checkout is the rare exception and is **not** in that
  set: `git worktree add` writes new state of its own, so put it outside the repo (a temp directory,
  never a subdirectory that another session's `git add -A` could sweep up) and remove it with
  `git worktree remove` when you are done. And if your work genuinely cannot be done without the
  checkout in another state, that is a sentence in your deliverable, not a command you run: say what
  you need and stop.
- **This is enforced now, and knowing that changes what a refusal means to you.** Since issue
  [#1669](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1669) the `dkj-policy` plugin
  ships a `PreToolUse` hook that refuses those commands when the call comes from a dispatched
  subagent — the payload says which you are, so the dispatching session's own `git checkout` is
  untouched. **A `BLOCKED (guard-working-copy)` message is therefore not a tool malfunction and not
  something to work around**: it is this rule, arriving as a refusal instead of as a paragraph. Do
  what the paragraph above says — read the other ref without touching the tree, or say in your
  deliverable what state you would need and stop. There is deliberately no marker, flag or wording
  that authorises it, so a second attempt in a different shell is only a slower way to be refused.
  Writing this rule into a file is exempt and always was; if a shell is fighting you over text, use
  the Edit/Write tool. Where the plugin is not installed the rule still holds in full — it was prose
  first, and prose is what it falls back to.
- **A clean `git status` is not your evidence, because it is what the damage looks like.** It reports
  the committed tree, so it reads identically whether you touched nothing or discarded somebody's
  uncommitted edits — no error, no notice, no refusal. What proves you altered nothing is not having
  run any of the commands above; "the working tree is clean, matching this commit exactly" proves only
  that you cannot tell.
