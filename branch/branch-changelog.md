## An entry's links are checked against where the text lands, not where the file sits

### What does this change do?

The dead-link scan judges `branch/branch-changelog.md` from the **repo root**, because that is where
its text ends up: the fold pastes the entry verbatim into `CHANGELOG.md`. Until the `branch/` split
this held by construction -- the entry file sat in the root, so a root-relative link resolved the same
way in both places. Moving it one level down broke that silently, and in the worst direction: every
root-relative link in an entry became a dead link, so the gate refused entries that were correct and
would have forced authors to write `../` links that break the moment they land.

**Measured on the first entry written after the move**, which cited a specialist lens and was refused
for it. Five of the entries already pending in `CHANGELOG.md` carry a link of exactly that shape, so
this was not a corner case waiting to happen -- it was the next entry, every time.

**This is the second instance of a rule the scan already had**, not a new exception: persona templates
are validated as if they were already in a consumer's `.claude/extensions/`, for the same reason and
with the same one-line mechanism. A document whose destination differs from its location is judged at
its destination.

**The step list is deliberately excluded.** `branch/branch-progress.md` never travels -- it is read
where it lies and reset in place -- so its location *is* its destination, and the ordinary `../`
convention every other nested document here follows is the correct one for it. Excluding it is what
keeps the rule about destinations rather than about the directory.

The regression test asserts both halves. A fix that simply stopped scanning `branch/` would satisfy
the first assertion and quietly lose the check, which is how the gap arrived in the first place.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 1 | 4 | without it the next entry that cites any file is refused by a gate that is wrong, and the obvious workaround produces links that break after the fold |
| 0 | 3 | the link scan keeps its coverage of the entry instead of being narrowed to get past the refusal |

### Type of change

Fix
