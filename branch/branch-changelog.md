## `docs/a-report-proposes-a-mechanism-too` changelog

### Branch title

An inbound report's proposed repair is verified like its reason

### Branch ID

20260810-112130

### Branch type

docs

### What does the change on this branch bring to main?

Chris's inbound intake checked two things before routing an item: is the defect still there, and does the
reason it gives hold. It now checks a third — **does the repair it proposes name anything real** — because
that fails independently of the other two. A reporter measures from outside the repo, so the functions,
flags and files their proposal names are inferred rather than read.

The rule goes into Chris's portable body, so it reaches every consuming repo's orchestrator; the measured
instance goes into his repo lens beside the other two failure patterns.
[#566](https://github.com/DaveKJohn/claude-code-specialists/issues/566) is that instance, caught on pickup
the same morning: it was right that `CONTRIBUTING.md` hardcoded answers the seam already owns, right about
which functions those were — five of the six it named exist under exactly those names — and its proposal
named `Resolve-PluginScript`, a function that exists nowhere in the tree. The real form is
`${CLAUDE_PLUGIN_ROOT}`.

What makes this the costliest of the three to get wrong is what the deliverable was: a document written to
be **copied**. Building the proposal verbatim would have handed every consumer an instruction to call a
function that has never existed — a defect that reads as authoritative and arrives by plugin update rather
than by anyone choosing it.

### Significance

#### Tier 0

Intake here reads every consumer's inbound reports, so the check runs often. It closes the one gap the two
existing checks leave: a report whose symptom and reason both survive verification can still carry a
proposal built on nothing, and nothing in the old sequence would have asked.

**Score:** 3

#### Tier 1

The reasoning behind a *rejected* proposal now survives in the record rather than in whoever happened to
notice it. The next person handling a similar inbound reads why that lever was not pulled instead of
re-deriving it — or worse, pulling it.

**Score:** 2

#### Tier 2

The rule sits in the portable persona body, so every consuming repo's orchestrator applies it — and those
repos are also the ones filing the reports, so it tells both ends what a proposal is held to. They meet it
at their next inbound item, from either side.

**Score:** 3

### Pull Request
