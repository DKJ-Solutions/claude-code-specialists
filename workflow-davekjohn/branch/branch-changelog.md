## `docs/a-findings-size-is-measured-too` changelog

### Branch title

A report's size is measured before its repair is scoped

### Branch ID

20260816-001143

### Branch type

docs

### What does the change on this branch bring to main?

**Chris's intake gains a fourth thing to check, and it is the one this repo just failed three times.**
His body already holds three: a report's symptom, its reason, and the repair it proposes each get held
against the tree, and each fails independently. The fourth is the finding's **size** — and unlike the
other three it is not about correctness at all. A report is usually right about *what* is wrong and
still wrong about *how much*, because the count it carries is whatever the reporter's search matched,
which is a proxy for the subject rather than the subject.

Scope to the proxy and one of two things follows: the repair leaves most of the problem standing while
looking finished, or it runs a mechanical fix across a subject far larger than anyone meant. So the
subject gets measured in its own terms before the work is scoped, the two numbers are compared, and a
large disagreement is filed as a finding rather than quietly absorbed — the decision to widen a job
belongs to whoever owns it. Where the recount changes the conclusion, the report is corrected out loud:
a corrected finding is worth more than a satisfied one.

**The evidence is this repo's own, which is why it is worth having.** A team-wide review on August 15,
2026 filed 22 issues; **three were mis-measured**, all three found only because the repair began with a
recount, and all three the reviewing team's own work rather than a consumer's:

- `#697` counted **32** uses of a retired name; the subject was **342** occurrences of the word. The
  remaining 310 went back as `#720` with the measurement, rather than being swept along unasked.
- `#700` claimed one identical sentence in **20** agent defs; exactly **3** are identical. The proposed
  shared block would have fed 17 role-specific tails to the next generator run for deletion.
- `#701` reported a claim falsified by **5** dated references; the claim names four categories and
  dates are not among them, so the real count is **2**. Repairing to the report would have stripped two
  correct measurements out of a manual.

**Three in twenty-two, with the reporter and the repairer an hour apart on the same team.** That is the
argument for recounting a report even when it is your own — and especially then, because a report you
wrote yourself carries no friction to slow you down.

The rule goes to Chris's portable body, stated timelessly; the three instances go to his repo lens,
where the issue numbers and the date belong.

### Significance

#### Tier 0

Intake is where the whole chain starts, so a check added there is paid back on every report. This one
would have caught three defects tonight before any work was scoped on them.

**Score:** 3

#### Tier 2

Chris's persona ships, so every repo running the specialists gets the fourth check. It is the most
portable kind of lesson there is — it is about reading a report, and every repo reads reports.

**Score:** 3

### Pull Request

