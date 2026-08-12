## `docs/ticketwork-language-row` changelog

### Branch title

The ticket-work page asks the language question in the shape that does not fail

### Branch ID

20260812-153014

### Branch type

docs

### What does the change on this branch bring to main?

`TICKETWORK-portable.md`'s *What your repo answers* table asked **one** question about language where there
are **two**, and illustrated it with a worked example that had moved on. Inbound
[#624](https://github.com/DaveKJohn/claude-code-specialists/issues/624), filed at Dave's request from
`BWJ-ecommerce/smartwatchbanden`, reported both.

**The row is now two rows, and the reasoning under the table says why.** The **form** — section names, field
names, the state vocabulary — is workflow rather than subject matter, so it takes one answer per repo. The
**outgoing message** is verbatim what a person receives, so its language is a property of **whoever filed the
ticket** and can differ from one file to the next: the instruction is *look up who filed it before you write*,
not *write in language X*.

**The measurement that made the split necessary replaces the stale example rather than sitting beside it.**
The originating repo had answered "Dutch" for the whole file on a reason that reads as sound — the outgoing
message goes to colleagues, and those colleagues are Dutch-speaking. Some of them are not (Dave, August 12,
2026): the rule had generalised from the requesters seen so far to every requester there will ever be. That
is the failure mode one-answer-per-repo has, and it is silent — nothing is wrong until the first request
arrives from somebody who cannot read the message.

**The answer stays the consumer's**, which is what the table is for. Nothing here writes this repo's answer,
or the originating repo's, into the portable page.

**No gate, no seam and no template**, deliberately. #624 says of itself that *"nothing is broken for anybody
today"* and has not measured whether a second consumer even has a ticket folder — so this is prose a person
applies, in a page that already states why it deliberately ships no template and no scaffolding script.

### Significance

#### Tier 0

The page is one this repo owns and nobody here applies — there is no ticket folder on this side. What it buys
a maintainer is that a false statement is gone from a document they write into: the example said the
originating repo answers "Dutch", and it had stopped doing so. Small, and the kind of thing noticed only
when somebody points it out, which is how it arrived.

**Score:** 2

#### Tier 2

A consumer adopting the ticket-work rules gets the language question in the shape that survives contact with a
requester they have not met yet, instead of the shape that invites one answer per repo. It is a rule they
apply by hand, so it lands the moment they read that table — at adoption, or on the next re-read — rather than
within a day.

**Score:** 3

### Pull Request

