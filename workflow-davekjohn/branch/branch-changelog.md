## `docs/always-on-token-calibration` changelog

### Branch title

the always-on layer's token figures are calibrated against a measured count

### Branch ID

20260815-130908

### Branch type

docs

### What does the change on this branch bring to main?

Every always-on token figure this repo has recorded since July 28, 2026 was under-stated by about 19%,
and the cause was one number nobody had ever checked: a conversion of **3.70 characters per token**,
written down once and inherited unexamined through three re-measurements. Calibrated against ten skill
pages of this repo's own prose whose token cost `claude plugin details` reports authoritatively, the real
factor is **median 3.12** (n=10, range 2.95-3.23, spanning 5,002 B to 47,434 B).

Re-measured at 3.12, and with the two plugin listings included -- both earlier tables omitted them
entirely, which is the second half of the under-count -- the always-on layer is **~41,800 tokens**, not
the ~30,205 last recorded. The character counts in the July 28 and August 14 tables were always right;
only the tokens derived from them were wrong, so both tables are left as they were written and marked at
the factor they used, rather than restated.

Two findings travel with the number. **The persona that loads is the marketplace copy, not the one in the
tree** -- `SPECIALISTS.md` imports from `~/.claude/plugins/marketplaces/`, which sat ten commits behind
`main` and differed by 1,243 B, so the figure a session pays and the figure the repo suggests are two
different objects; the gap is queued cost that arrives at the next plugin update. And **the cost is not
diffuse**: `CLAUDE.md` is 875 lines, of which one section is 80%, one bullet inside it is 42,191 B, and
one sub-item inside that -- the release commit -- is **41,168 B over 474 lines**, which is 56% of
`CLAUDE.md` and 32% of the whole always-on layer.

The lens records the priced options and does not act on them: `.claude/rules/` scoping is assessed and
**fails** for this content, for reasons the August 14 note already gave; what applies is the lever this
repo invented on July 28 and used once -- the decision belongs on the always-on path, the evidence for it
does not. That is a proposal with standing evidence now, which is what this branch exists to provide.

The portable half is in Nolan's manual as two craft rules: a conversion factor is calibrated and not
inherited, and the copy measured is the one actually loaded rather than the one in the repository.

### Significance

#### Tier 0

The number every future cost decision here starts from was 19% wrong, and nothing errored -- the
arithmetic was right, so the error was invisible and self-propagating. It also relocates the argument: the
always-on layer is not a diffuse 875-line document to trim but one 474-line sub-item, which is a different
kind of problem with a different answer. Continue to Tier 2.

**Score:** 4

#### Tier 2

A consumer takes Nolan's two new craft rules through a plugin update and gets them the next time they
measure anything -- an inherited conversion factor fails identically in any repo, and any consumer of this
marketplace loads personas from a cache that lags their own tree by exactly the same mechanism measured
here. The corrected figures themselves are this repo's and stay in the lens.

**Score:** 3

### Pull Request
