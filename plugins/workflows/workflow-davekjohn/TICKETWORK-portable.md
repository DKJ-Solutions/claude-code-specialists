# Ticket work — the portable half

[`CONTRIBUTING-portable.md`](CONTRIBUTING-portable.md) begins at `new-branch`. **This page is about what
happens before that**, in the repos that do not choose their own work: a request arrives from somebody
else's tracker — Asana, Jira, Linear, a shared inbox — written as a desired outcome rather than an
instruction, and somebody has to decide whether it can be built at all before a branch is worth creating.

**These are rules, not a format.** Every one of them exists because it was got wrong first, and the
reasoning is the part worth having — a copied checklist would lose exactly the half that makes each rule
survive contact with a request that does not fit it. Nothing below prescribes a filename, a folder, a
language, or a set of section headings. Those are yours, and the closing section says which.

## Where this comes from, stated rather than discovered in review

**One repo, one day.** The workflow below was built in `BWJ-ecommerce/smartwatchbanden` on
2026-08-11, over five rounds against six real tickets, and donated upward on Dave's decision. There is no
second consumer with a ticket folder today, so this arrived **without the duplication that normally earns a
promotion** — the usual test for moving something into the shared core is that it exists in two places, and
this existed in one. That was weighed and overruled deliberately.

**What follows from that, for you.** Two things. First, the rules carrying explicit decisions — 2, 4 and 6
below — are the ones to keep even where they are inconvenient; they are what the five rounds were spent on.
Second, **the vocabulary has not met a second tracker**, so treat every name on this page as an example of a
role rather than a term to adopt. If a rule reads as obviously wrong for your tracker, the rule is the thing
to re-measure — file it back as an inbound issue rather than working around it silently.

---

## The one structural rule: where the provenance boundary is

A ticket file mixes two kinds of statement, and they age completely differently:

- **copied from the tracker** — the request, its priority, its deadline, who filed it. True on the day it
  was copied and slowly false afterwards, because the tracker keeps moving and the file does not.
- **our own** — what we worked out, what we measured, what we decided, what we are doing next. Written once
  and still true later.

**So the file states, once, the date the copied half was last checked against the tracker.** One date for
the whole block, not one per field — a per-field date invites nobody to update any of them. Everything above
that line is a snapshot; everything below it does not rot.

This is the rule that makes the rest safe, and it is the one most likely to be skipped as bookkeeping.
Measured in the originating repo before it existed: **30 undated copies of tracker state across six files**,
with no way to tell which were current and no gate on any of them.

Beyond that boundary, a ticket file needs to answer four things in some order — what we know, whether we
know enough, what happens next, and what has happened so far. The rules below are about how each of those is
answered. How you name them is your business.

---

## The rules

### 1. The decision is a section, not a mood

"Do we know enough to build this?" is answered **in one word, with the reason underneath** — and what hangs
below it follows from that answer. A reader who needs only the decision is done after one section, and does
not have to infer it from the length of the notes.

The reason is not optional. A one-word answer with no reason is the thing a later reader cannot check, in
exactly the way an unexplained score is.

### 2. The test is *can we build what they ask* — not *is it a good idea*

Two different questions, and only the first is ours to answer before starting. Conflating them is what turns
a buildable request into a blocked one: the request is perfectly clear, we are simply unconvinced, and
"unconvinced" gets written down in the place reserved for "unclear".

**Measured: three of six tickets flipped from blocked to buildable** on this rule alone, one of them after
seven weeks of sitting still.

An explicit decision, and the one to keep when it feels wrong.

### 3. Six kinds of question are not gaps

A gap is something whose absence stops us. These six get mistaken for gaps and are not — each learned the
hard way:

| not a gap | why |
|---|---|
| **verification** | needed to *prove* the fix afterwards, not to know what to do now |
| **an offer of ours** | widening a request that was already complete — ours to propose, not theirs to answer |
| **a caveat** | belongs with the notices (rule 4) and never needs an answer at all |
| **our own unfamiliarity** | a name or tool *we* do not recognise is something to ask internally |
| **work that is ours** | nobody supplies what we are paid to produce |
| **anything measurable on the product itself** | see rule 5 |

Two of those have sharp edges worth stating. **Unfamiliarity**: a "who is X" question was nearly sent out
about a colleague the requester works with daily — which reads as though we have not been paying attention,
and costs more than looking it up. **Work that is ours** has a real border rather than a bright line:
translating a *label* is ours, supplying *content* is theirs. A UI string in five languages is never a
question; a page of copy in five languages is.

### 4. A gap and a notice look identical and do the opposite

*I cannot continue* and *I can continue, and you should know this* are the same shape on the page and
opposite in effect. Mixed into one list, every caveat reads as a blocker and buildable work sits still.
Keep them apart, structurally.

**And the attitude inside a notice is mandated: we build what is asked.** Whether the request is wise is not
our call — we state the risk and stop. That means *"flagging X; say the word and I build it as described"*
and specifically **not** *"can you explain how that relates?"*, which hands the burden back and converts a
notice into a blocker while sounding more collaborative.

An explicit decision.

### 5. Measure the product before writing down a gap — and measure more than one instance

If the request is about something a user can see, **look at it first**. Most questions about observable
behaviour are answerable in less time than it takes to write the question, and a question sent out is at
minimum a day of latency and at worst a ticket that stops for weeks.

**Measured: two gaps that had blocked a ticket since 24 June** — which text block, and whether it contains
headings — were both answered with `curl` and `grep` in the time it took to ask.

**The sub-lesson is the expensive half.** The first measurement there was *wrong*, because it keyed on a
class that happened to exist on the one page checked (an artefact of content pasted out of Word). One
instance is an anecdote: **measure the structure, not what the first example happens to contain.** A
confident wrong measurement is worse than an open question, because nobody re-checks it.

### 6. At a *yes*, the questions leave the reply entirely

If we know enough, we need nothing, so we **ask nothing**. The reply carries notices and nothing else.

Where a choice is genuinely still open, **make it, state the default, and say it is reversible** — *"the
same section appears on product pages; I am including those unless you say otherwise"*. A question in a
message reads as a request to wait even when it is not meant that way, and the requester cannot tell the
difference between "blocked on you" and "just checking".

An explicit decision.

### 7. The heading never carries a status

A heading like *"the reply that was sent"* is written when the reply is **finished** — which is precisely
the moment nobody has sent it yet. So it is false on creation, and because it reads as done, nobody comes
back past it. **All six files in the originating repo were wrong this way on day one.**

State lives in a **field with a closed vocabulary**, not in prose and not in a heading. Closed is the
operative word: if a value needs a qualifying clause appended to cover the later stages, the vocabulary has
too few words in it, and the qualifier is where the lying starts.

Your stages are yours. The originating repo runs eight, from *draft* through *question sent* and *answer
received* to *buildable*, *building*, *delivered* and *closed*.

### 8. One list, with the answer under the gap it unblocks

Gaps and the questions in the outgoing message are the same things said twice, and two lists of the same
thing diverge. Measured: **31 items against 29**, together **66% of all words in the folder**, already out
of step in a way no gate could catch.

Keep **one** list. Each gap points at the question that carries it, or says why it has none. The message
keeps its own numbering, because it is a message to a person and has to read like one.

**And an incoming answer lands under the gap it answers**, with its date and author. This is the rule that
pays off longest: in a tracker, the answer arrives in the same feed as the question and both scroll away,
so the file is the only place the pair stays together.

### 9. The log is append-only, newest first, and holds references rather than descriptions

What was decided, what was rejected and why, when a question went out — and once built, a **reference**:
the PR it was built in, the version it shipped in. Never a fourth description of a change that the changelog
and the release documents already carry (see
[`CONTRIBUTING-portable.md`](CONTRIBUTING-portable.md#5-fold) for the three that exist already).

**A log cannot rot dishonestly**, which is the structural argument for having one: a log with no recent
entries correctly says nothing has happened. That is exactly where a status field lies.

### 10. The index carries only what you need to pick a file

Two things: what state each ticket is in, and whose move it is. Nothing else.

Anything else copied into an index is a third copy of something that already has a home, and it drifts from
the file below it. Measured: priority and "waiting on" were both copied up, and both drifted.

---

## What your repo answers

Nothing on this page is configurable through a seam, because none of it is read by a script. It is a set of
rules a person applies, so adopting it means writing your own answers next to it — the same split the rest
of this plugin uses:

| yours to decide | notes |
|---|---|
| **which tracker, and where the boundary is** | the whole page assumes the request originates somewhere you do not control |
| **the folder, and the file naming** | including where research material sits relative to the tickets |
| **the language of the form** | section names, field names, the state vocabulary — one answer per repo |
| **the language of the outgoing message** | not one answer per repo; see below |
| **every section and field name** | the roles above are the rule; the names are not |
| **the state vocabulary** | rule 7 requires it to be *closed*, not to be these eight values |
| **whether there is an index at all** | rule 10 applies if you have one |

**The language is two questions, and only the first has one answer per repo.** The **form** — the section
names, the field names, the state vocabulary — is workflow rather than subject matter, so a repo picks a
language once and is done; the argument for picking English is that a colleague who does not read your prose
can still open a file and recognise its structure without translating every heading first. This page is
English because the plugin is — the plugin's answer to its own version of the question, not yours. The
**outgoing message** — the reply of rules 6 and 8 — is the opposite: it is verbatim what a person receives,
so its language is a property of **whoever filed the ticket**, and it can differ from one file to the next.
The instruction is therefore *look up who filed it before you write*, not *write in language X*.

**Measured in the originating repo, 2026-08-12.** It had answered "Dutch" for the whole file, on a reason
that reads as sound: the outgoing message goes to colleagues, and those colleagues are Dutch-speaking.
**Some of them are not** — the rule had quietly generalised from the requesters seen so far to every
requester there will ever be. One answer per repo is the shape that fails here, and it fails silently:
nothing is wrong until the first request arrives from somebody who cannot read the message.

**And one thing to check before you adopt this**, in the same spirit as the note at the end of
[`CONTRIBUTING-portable.md`](CONTRIBUTING-portable.md#one-thing-to-do-before-you-adopt-a-root-contributingmd):
if your ticket files live in the repo root as `*.md`, they will look like unfolded changelog entries to the
release cut. Put them in a directory, or add them to your `Get-ReservedRootMd`. A directory is the better
answer — it costs nothing and needs no configuration.

## What deliberately is not here

**No template file, and no scaffolding script.** Both were offered and declined for now. A template fixes
the shape, and the shape is the half that has met exactly one tracker; a skill would wrap a script, and
there is no script here — every other skill in this plugin exists because a `.ps1` needed documenting.

Those are the pieces to build **once a second repo runs this**, at which point there is something real to
generalise from rather than one repo's five hours. Until then, the rules travel and the shape stays local.
