## `docs/unverified-proper-nouns` changelog

### Branch title

A report's subject is verified too, not just its symptom and its reason

### Branch ID

20260815-112535

### Branch type

docs

### What does the change on this branch bring to main?

Chris's inbound route already checks three things before it builds: whether the reported **symptom**
still stands, whether the **reason** given for it holds, and whether the **repair** it proposes names
mechanisms that exist. This adds the one that sits underneath all three — the **subject**. Each of the
existing checks quietly assumes that the thing the report is *about* exists at all, and where it does
not, every one of them still passes on its own terms while the item as a whole is air.

**Measured on [#660](https://github.com/DaveKJohn/claude-code-specialists/issues/660)**, closed the day
this was written. It asked for a GitHub Projects board for *"pair-cli issues, tickets and project
work"*, and everything downstream of that name was sound: two pickups answered its four design points,
measured two genuine blockers, and designed an owner-level board carrying draft items because the repo
did not exist yet. Coherent throughout, and about nothing — asked directly, Dave did not recognise the
name, and the search that followed found `pair-cli` in exactly one place in the visible world: the issue
itself. No file in the tree, no other issue or PR under either owner, no repository of his anywhere on
GitHub.

**The portable half is a check plus the condition that makes it likely.** The check is one search — *a
name that occurs nowhere but inside the report that names it, names nothing*. The condition is that the
report was written **for** the requester rather than **by** them: an idea mentioned in passing and filed
by a session so it is not forgotten carries a proper noun nobody has ever verified, under the
requester's own name, in the house style. #660 was one of three dictated within 45 minutes that morning,
and the other two were real and closed the same day — so the name arrived flanked by siblings that
checked out.

**The specific mis-read is recorded in the lens, because it will look identical next time.** The first
pickup *did* search for the repo, found nothing, and wrote it down as **"not visible from here"** rather
than as *"not there"*. That single reading is the whole defect: it turned an answer into a blocker, and
cost a second pickup plus an auth-scope refresh requested from Dave for a board that was never going to
be built. The lens also keeps the measurement that settled the wish underneath the name, so nobody
re-opens it on instinct — 179 issues filed here, 178 closed, 170 of them within 24 hours, median
lifetime 3.4 hours, none older than seven days, and exactly one open, which was the issue asking for the
board.

### Significance

#### Tier 0

The lens now carries the pattern and the mis-read that produced it, so the next pickup here starts by
asking rather than by searching. It also closes the Projects question with a number instead of an
instinct, which is what stops it coming back.

**Score:** 3

#### Tier 2

Every consumer's Chris gains the fourth check at the front of the inbound route — the one place it pays
for itself, since a consumer files ideas on their own requester's spoken word exactly as this repo does.
It arrives with the next release and is noticed the moment they pick up a report.

**Score:** 3

### Pull Request
