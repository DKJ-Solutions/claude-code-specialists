## `fix/refreshbody-keeps-template-sections` changelog

### Branch title

-RefreshBody keeps the template sections below the description, and says so when one is lost

### Branch ID

20260811-160426

### Branch type

fix

### What does the change on this branch bring to main?

`open-pr.ps1 -RefreshBody` deleted every template section below the description and reported success naming
only the description. Reported from a consumer
([#598](https://github.com/DaveKJohn/claude-code-specialists/issues/598)), where that was the entire
repo-specific half of the PR form -- heading, guidance comment and both checkboxes, including the one box
[#538](https://github.com/DaveKJohn/claude-code-specialists/issues/538)'s own measurement found to be the
only one that ever varies there, on a repo whose `CLAUDE.md` requires it answered before a theme-touching PR
may merge.

Two correct halves that are wrong together, which is why neither looked like a bug on its own:

- `open-pr.ps1` took the description heading to be the **first** heading of the template. Since #538 that
  template opens on an **H1**.
- `Update-PrBodySection` ends a section at the next heading **at the same level or shallower**. Nothing is
  shallower than an H1, so no boundary is ever found and the section runs to the end of the body.

The function's own reasoning is right and is left standing: a description can contain its own deeper
headings, so the level rule cannot simply be loosened to "the next heading of any kind" -- that would strand
half the old description below the new one. What the caller knows and the function cannot is which headings
belong to the *form* rather than to the description. So it passes them in: `-StopAtHeading` takes the
template's headings after the first, and the section ends at the earliest of that list and the level rule.

**The parameter is narrowing only**, which is what makes it safe to add to a function three paths call.
Passing nothing, passing an empty list, or passing a heading the body does not contain are each
byte-identical to the behaviour before it existed, and all three are asserted. The stops travel to the
legacy-heading fallback path too, for the same reason and with the same guarantee.

**And a lost section is now said out loud.** `Get-LostBodyHeadings` names any heading that was in the body
and is not in the version about to be sent, and `open-pr` warns before the edit rather than after. The
subject is deliberately a heading that disappeared and not a body that got shorter: a refresh legitimately
shrinks a body whenever the new description is shorter than the old one, so a size rule would fire on the
common case and be switched off within a week. A warning rather than a refusal, because the body may have
been hand-edited on github.com and refusing would leave the branch pushed with no way through but the
website. After this fix it should be unreachable, which is the point of keeping it -- it is a tripwire for
the next shape nobody predicted.

Two things found while verifying, both part of the change:

- **This repo cannot reproduce the loss.** Its own template is a single H1 section, so there is nothing below
  the description to lose -- which is why this shipped, and why the fixture in `pr-body.tests.ps1` is the only
  place the two-section shape exists in this tree. The blast radius grows as consumers adopt the shape #538
  recommends.
- **The codebase already knew this failure mode from the other side.** `Add-ResolvesBlock` matches the body's
  own top level precisely because, in its words, "a block deeper than the description is inside it, and the
  next -RefreshBody deletes it along with the description it replaces." That is the same sentence as this
  defect, written about the closing block and never carried across to the form.

One existing test was re-pointed rather than deleted: it asserted the whole
`Where-Object { $_ -match '^#{1,6}\s+\S' }` expression, so a correct change to how the template's lines are
enumerated failed a test that was watching the wrapper instead of the rule. It now asserts the level-agnostic
pattern, and gained a sibling asserting that the later headings are actually handed on -- the half whose
absence was the bug.

### Significance

#### Tier 2

`-RefreshBody` was silently destructive on the template shape this repo recommends, and the only workaround
available to the reporting repo was to stop using the flag and reassemble bodies by hand -- more steps than
the flag exists to save. Any consumer that has adopted the H1 template is losing sections on every run right
now without a signal, so this is one to know about rather than merely receive: the workaround can go, and
open PRs are worth a look.

**Score:** 5

#### Tier 1

A colleague on this project is not bitten today, because this repo's template has one section -- but the day
one is added, the same loss would start here with no warning. The tripwire is what changes that, and it is
the half that keeps working when the next unpredicted shape arrives.

**Score:** 2

#### Tier 0

The fix is in a shared lib with a new pure function and eleven new asserts, so the cost here is a slightly
larger suite against a defect this repo's own tree could not produce.

**Score:** 2

### Pull Request
