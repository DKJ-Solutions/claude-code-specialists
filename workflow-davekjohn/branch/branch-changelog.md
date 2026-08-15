## `docs/false-claims-sweep` changelog

### Branch title

Four documents corrected where they described something the tree does not do

### Branch ID

20260815-210707

### Branch type

docs

### What does the change on this branch bring to main?

Four documents each stated something a reader could check and find untrue. All four came out of the
team-wide review of August 15, 2026, and each was verified against the tree before it was touched.

**`SECURITY.md` told a researcher there is no hosted service.** Since `ddf5574` there is one: a
Cloudflare Worker serving the audience release notes at `/notes/<token>`, with no login and that
unguessable path as its only lock. The sentence sat under **Out of scope**, so the one document whose
whole job is to draw that line was excluding a real surface. The page is now named in scope with its
token as the stated boundary, and the out-of-scope half says what remains true and why — an outage
costs a reader nothing they cannot get from this repo, so availability reports stay out while
anything touching the token does not.

**Rendall's lens cited check 19 for a mechanism the lint implements as check 20** — and the comment
above that check exists precisely to prevent this: *"two checks answering to one number is how a
finding gets discussed as the wrong one."* Check 19 is a different check (a named consumer-facing
document that is not there). One word, and it was the document that most needed to be right about it.

**Ravi's lens listed a finished job as open.** Extending the shared-block mechanism to the persona
templates shipped on August 8, 2026 — the generator walks `personas/` alongside `agents/`. Worse, the
generator's own comment cites that list as the place the widening was foreseen, so a reader following
the citation landed on the plan rather than on the answer. The item is now recorded as closed rather
than deleted, so that citation still resolves to something.

**Bianca was described as invocable and is not.** She ships as a persona with no agent def, so
`@team-alpha:<name>` does not reach her, and Chris's routing table and every chain mention her zero
times. The handbook grouped her with five specialists that genuinely are subagents. The list is now
split by how each is actually reached, and the persona-lens note states plainly that she has a lens
and no caller. Deliberately not repaired by inventing a routing row: this repo does no intake
interviews, and a trigger invented to make a sentence true would be a way-of-working change nobody
asked for.

### Significance

#### Tier 0

Four corrections in documents this repo reads while working. The lens fixes matter most here: a
specialist who opens their own lens to find out what is on their plate is the reader being misled,
and both wrong lines were about their own craft.

**Score:** 3

#### Tier 2

`SECURITY.md` is the one that reaches outward. It is what an external researcher reads before
deciding whether to report something, and it was telling them a live surface was out of scope. Nobody
is known to have been turned away by it, which is exactly why it is a 3 rather than higher — the cost
is a report not filed, and an unfiled report is invisible by construction.

**Score:** 3

### Pull Request

