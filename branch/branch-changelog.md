## `docs/portable-ticketwork-rules` changelog

### Branch title

A portable half for ticket work: the rules between an external tracker and a branch

### Branch ID

20260811-162719

### Branch type

docs

### What does the change on this branch bring to main?

`workflow-davekjohn` now ships
[`TICKETWORK-portable.md`](plugins/workflows/workflow-davekjohn/TICKETWORK-portable.md), beside
`CONTRIBUTING-portable.md` and picking up where it starts: that page begins at `new-branch`, and this one
covers the layer before it, in a repo whose work arrives from somebody else's tracker as a desired outcome
rather than an instruction. Donated from a consumer
([#603](https://github.com/DaveKJohn/claude-code-specialists/issues/603)) where it was built over five
rounds against six real Asana tickets.

**Ten rules, each with the reasoning and the measured instance behind it**, plus one structural rule about
where a ticket file's provenance boundary sits -- the single date that separates what was copied from the
tracker (true when copied, quietly false afterwards) from what is ours (written once, still true later).
Before that boundary existed there were 30 undated copies of tracker state across six files.

The rules that carry weight rather than tidiness, and what they were measured to be worth:

- **The test is "can we build what they ask", not "is it a good idea"** -- two questions, and only the first
  is ours before starting. Conflating them writes "unconvinced" in the space reserved for "unclear". Three
  of six tickets flipped from blocked to buildable on this alone, one after seven weeks.
- **Six kinds of question are not gaps** -- verification, an offer of ours, a caveat, our own unfamiliarity,
  work that is ours, and anything measurable on the product. Two questions were nearly sent that the
  recipient could not have answered, one of them about a colleague they work with daily.
- **A gap and a notice are the same shape and opposite in effect**, so a notice states the risk and closes
  with "say the word and I build it as described" rather than a question, which hands the burden back while
  sounding collaborative.
- **Measure the product before writing down a gap, and measure more than one instance** -- two gaps that had
  blocked a ticket since 24 June were answered with `curl` and `grep`. The sub-lesson is the expensive half:
  the first measurement there was wrong because it keyed on a class that happened to exist on one page.
- **The heading never carries a status**, because a heading like "the reply that was sent" is written when
  the reply is finished, which is exactly when nobody has sent it -- false in all six files on day one, and
  read as done, so nobody came back past it. State goes in a field with a *closed* vocabulary.

**Rules only -- deliberately no template and no skill**, which was Dave's call when the three options in the
report were put to him. The reasoning is in the document rather than only here: a template fixes the shape,
and the shape is the half that has met exactly one tracker; a skill would wrap a script, and every other
skill in this plugin exists because a `.ps1` needed documenting. Both are named in a closing *what is
deliberately not here* section, so a consumer reads the absence as a decision rather than an oversight.

**The provenance is stated in the document, not just in this entry**, because it changes how a reader should
treat it. This arrived from one repo after one day, with **no duplication to justify the promotion** -- the
usual test for moving something into the shared core is that it exists in two places, and this existed in
one. That was weighed and overruled deliberately, so the page says which three rules carry explicit
decisions and should survive inconvenience, and asks a consumer who finds a rule wrong for their tracker to
file it back as an inbound issue rather than work around it silently.

One adoption trap is called out where a reader will meet it: ticket files sitting in the repo root as `*.md`
look like unfolded changelog entries to the release cut, so they belong in a directory -- which costs nothing
and needs no configuration -- or in `Get-ReservedRootMd`. Same class of note as the one closing
`CONTRIBUTING-portable.md`, and linked to it.

### Significance

#### Tier 2

The repo this came from can shrink its own working document to a pointer plus its own answers, the way its
`CONTRIBUTING.md` already did, and stops being the only place the reasoning exists. For every other
consumer it is inert until tracker work arrives -- at which point the rules are there to be read instead of
re-derived over five rounds against live tickets.

**Score:** 3

#### Tier 1

The reasoning behind each rule is now written down where this project can read it rather than living in one
repo's head, which is the whole difference between a rule that survives and a checklist somebody copied.
Nobody here does ticket work today, so that is what it is worth: preservation, not use.

**Score:** 2

#### Tier 0

One more shipped document to keep current, and two rows in the plugin README. What it prevents is narrow and
worth naming: the rules existed in exactly one consumer's `README.md`, so a rewrite of that file would have
taken all ten with it and left nothing to recover them from.

**Score:** 1

### Pull Request
