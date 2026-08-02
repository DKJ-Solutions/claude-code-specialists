### two promises the consumer path cannot keep are made conditional · Docs · 2026-08-02

Both v13 findings are the same shape: a sentence that is true of the writer's situation and not of
the reader's.

**The `#336` hash pair is reproducible, and the warning said it was not** (inbound
[#385](https://github.com/DaveKJohn/davekjohns-workshop/issues/385)). `QUICKSTART.md` printed a
before/after SHA256 pair for `install --scope project` and then told the reader the values *"are not
something to match"*. Round v13 hit both of them exactly on a second profile — 224 bytes before, 246
after, and the +22 accounted for to the byte by the two documented changes.

That is not a coincidence, it is the prescribed path: Step 1 has the reader paste the printed block
into a file that does not exist yet, so the "before" bytes *are* the block, and the CLI's serialiser
is deterministic from there. Matching the pair therefore tells a reader two useful things — the block
went in intact, and the install did what it should. The warning was taking that away. It is now
conditional: match them if you followed this path, and if you had a `settings.json` already or
formatted it yourself, only the *difference* between your two values means anything.

**The `[UNREGISTERED]` safety net does not reach the reader it was written for** (inbound
[#383](https://github.com/DaveKJohn/davekjohns-workshop/issues/383)). `specialists-init`'s closing
step promised that until the repo is registered in the workshop, its own session start says so. The
line exists — but it comes from `check-connectors.ps1`, which `connector-sessioncheck` only runs when
it finds a **verified workshop checkout on this machine**, and a plain consumer has none. The
unregistered v13 repo got `no verified workshop checkout found on this machine -- check skipped.` in
every session of the round, and nothing else.

Defensible behaviour — there is nothing to check against — but it means the net catches the reader
who needs it least. The step now says so, with the line a consumer will actually see, and names why
this is the step most easily left lying: it asks for a PR in another repo, afterwards, once the
adoption already works.
