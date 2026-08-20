## `docs/handover-spent-not-broken` deployment

### What does the change on this branch deploy to main?

One boundary added to the `/handover` skill, on the step that was being read one clause too far.

Step 3 tells a pickup to say a lock-vs-repo disagreement out loud, because that is how a requester learns
their lock was stale. It does not say what to do next, and the gap was filled with the obvious-looking
answer: *so it needs repairing*. Measured here on August 20, 2026 — a session asked whether anything
important was still open, swept the tree correctly, and then put "the lock is stale, three of its items
are done" at the **top** of the answer as the item that most needed action. Nothing was wrong. A `/lock`
is written once, read once, and waits to be overwritten; being out of date is its resting state.

So step 3 gains its own second half — **a spent lock is spent, not broken** — with the instruction that
naming the change *is* the whole of it: do not offer to clear it, do not propose re-locking it, and do
not carry it into a list of what is still open. The requester's own correction is kept as the sentence
that settles it. The *deliberately does not do* list gains the matching clause on the bullet that already
explains why the command never deletes the lock: it does not hand that job back to the requester either.

Nothing about the mechanism changes, and no script is touched. It is the reading of one step, in the one
place a reader of it actually looks.

**Score:** 2

#### What makes this change extra special

It is the fourth measured failure mode of the same document, and the first that runs the *other* way. The
three already written up are all under-trust of the repo: a briefing arriving truncated, one whose
reasoning had expired, one that transcribed a cause that did not exist. This one is over-trust of the
*lock's tidiness* — a session treating a working mechanism as a defect because nobody had written down
that its end state looks like neglect.

That direction matters more than it sounds for a command whose whole purpose is to hand a session its
bearings. A pickup that reports phantom work spends the requester's attention on the one thing that never
needed it, and does so in the first paragraph, where it displaces whatever was genuinely open.

**Score:** 3

### Pull Request

A spent lock is the resting state
