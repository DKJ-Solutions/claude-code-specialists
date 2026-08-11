## `docs/the-cadence-stays-unconstrained` changelog

### Branch title

The release cadence stays unconstrained, by decision

### Branch ID

20260811-145444

### Branch type

docs

### What does the change on this branch bring to main?

The release cadence is **decided, not merely counted**: there is no cap and no rule, and cutting stays
available whenever Dave wants it. His words: *"ik wil gewoon kunnen snijden wanneer ik wil, dat moet niet
begrensd worden."* Nolan's third open number is now answered *and* acted on.

**The reason this is written down at all is that the decision changes nothing.** A decision to leave
things as they are is the one most likely to be mistaken for an unanswered question — and the lens had
just acquired a table showing that batching would save real time, with the choice recorded as open. Any
later reader arriving at that table without the answer beside it would reasonably re-propose the lever,
which is exactly the wasted round the record exists to prevent. So the decline is stated where the
proposal lives, and it names what would have to change for it to be revisited: new evidence that the
ceiling has moved — a materially slower gate, or a much higher release rate — not a re-reading of the
same table.

Three things make it a decision rather than a deferral, and all three are recorded. **The size of the
prize settles it**: the entire lever is worth at most ~20 minutes per day of blocking gate time, which is
the releaser's own waiting, and that does not buy a standing rule removing the freedom to ship on demand
— had the ceiling been four hours a day the same table would have argued the other way, which is why
counting it first was worth doing. **There was never a mechanism to change, only a habit**: a release
happens on explicit request, so the 16 releases in the measured window were 16 requests, and a cadence
policy could only ever have been a self-imposed constraint plus a brief telling the release manager to
propose fewer. And **the counterweight ran in the same direction**, which is unusual enough to note:
batching would have traded the releaser's minutes for consumers' hours, so the cheap side and the
fast-delivery side agreed and declining costs nothing on either.

### Significance

#### Tier 0

A measured proposal now carries its verdict in the same place, so nobody re-derives a lever that has been
priced and declined. The specific waste it prevents is a plausible and recurring one: the table showing
1h 35m to 3h 03m of savings is genuinely persuasive read on its own, and a session finding it without the
answer would open the question again — this time without the context that the freedom to release on
demand was the thing being traded away.

**Score:** 2

Is this change also relevant to colleagues and employers? Yes — continue to Tier 1.

#### Tier 1

The delivery rhythm is settled and stays as it is: work reaches a release as soon as somebody asks for
one, with no batching window in between. Anyone reasoning about how quickly merged work becomes available
can take the current mean of 7.45 hours as the standing state rather than a figure about to change.

**Score:** 1

Is this change also relevant to customers and users? No — see Tier 2.

#### Tier 2

Nothing reaches a consumer, and the outcome is that nothing about their delivery changes. The record lives
in `.claude/specialists/lenses/`, this repo's own layer, which never travels in the plugin; no shipped
script, skill, manual or manifest is touched. The one consumer-relevant effect is an absence — releases
are not slowed down — and an absence needs no announcement.

**Score:** N/A

### Pull Request
