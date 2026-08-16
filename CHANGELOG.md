# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections answering what a reader arrives with. Entries written before August 16, 2026 carry
six, and are read exactly as they always were. Every release ever cut is listed in
[`workflow-davekjohn/releases/README.md`](workflow-davekjohn/releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier, each closing with its score. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## Branch `docs/v4-13-0-timing-total` changelog - 20260816-210952

### What does the change on this branch bring to main?

#### Tier 0

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.13.0`'s note was frozen at a **6m 15s** head; the remaining legs -- writing the document
(2m 40s), its own gates (2m 50s), CI and the merge (8m 07s), the fold and the publish (46s) -- are added,
giving a **total of 20m 38s** from clock start to a published Release with its attachments. The legs are
given as measured rather than reconciled to the total.

**The head and the total moved in opposite directions, and the note reports them together rather than
picking the flattering one.** The head is a minute above the five-release band because the ordinary,
pushing form of the cut was refused by the session's permission classifier and had to be re-run in its
`-NoPush` form with the push issued by hand. The total came in three seconds *below* `v4.12.0`'s 20m 41s
anyway, because the tail was 14m 23s against 15m 44s -- one CI run finishing faster, not a repair. Reporting
only the head would have said the release got slower; reporting only the total would have hidden a
harness-level cost worth watching if it recurs.

**Neither number is offered as a trend**, and the note says so in those words. What the pair does support is
the older claim they were taken against: the tail is a property of the procedure rather than a run of
coincidences, and the procedure did not change between these two releases.

**The bullet promising this edit is replaced rather than ticked**, following the rule `v4.7.0` set: an
attachment is what was published at the moment of publication, so the note now states that the attached copy
carries the head only and stays frozen. A promise written into a published record becomes false the moment it
is kept, which is why it becomes a condition instead.

**Score:** 2

#### Higher than tier 0?

A two-paragraph edit to a page a consumer may already have read, in the organisation's section rather than
theirs. Nothing they do changes.

**Score:** 1

### Pull Request

The v4.13.0 release note gains its end-to-end total

[PR #741](https://github.com/DaveKJohn/claude-code-specialists/pull/741) · merged 2026-08-16

---

## Branch `docs/v4-13-0-release-note` changelog - 20260816-205701

### What does the change on this branch bring to main?

#### Tier 0

The one hand-written document for the minor tagged this evening: the consumer section rewritten from the
cut's draft against the seven writing tests, and the two organisational sections no script can generate.

**The item that led *what was still open* for five releases is closed and leaves the list.** `v4.12.0`
carried "the gate record has not been measured on the case it was built for" because that release shipped
in one motion and so never produced the duplicate gate run the record absorbs. Two firings have since been
measured on real pull requests, and the note says what they do and do not support: they confirm the
mechanism, they are not a distribution, and nobody should read a ratio off n=2.

**The head is 6m 15s against a five-release band of 4m 57s to 5m 36s, and the extra minute is named rather
than absorbed.** The ordinary, pushing form of the cut was refused by this session's own permission
classifier, so it ran in its `-NoPush` form and the push was issued by hand -- two commands where there is
normally one. That is a property of the harness the release ran in, not of the procedure, and it is written
into *what was still open* in those terms. Nothing was skipped for it: both gates ran in full, 43 suites
green in 147s.

**The publication line was re-read at the target rather than carried forward**, which is the habit `#694`
established. `BWJ-ecommerce/claude-plugins-bwj` is unchanged at commit `d528567` -- the four team plugins
still on 4.11.0, published 2026-08-15T15:44:13Z -- so the only edit the line needed was that colleagues are
now **two** releases behind rather than one. Reading it is what establishes that, and carrying it forward is
what would have made it wrong for the second time in three notes.

**Eight entries became four consumer sections plus a two-item list.** The four gate-record and
release-note entries carry `Tier 2: N/A` or describe our own craft, so their consumer-facing halves are one
bullet each or nothing at all -- test 2's line, which asks whether a paragraph describes our effort or the
reader's outcome.

**Score:** 2

#### Higher than tier 0?

The one document a consumer reads to decide whether to update. This release's headline is an action they
have to take -- `/continue` no longer resolves to the workflow's skill after the update, and they have to
type `/handover` instead -- so the section leads with it and says plainly that everything else needs no
action and no migration.

**Score:** 4

### Pull Request

The v4.13.0 release note

[PR #740](https://github.com/DaveKJohn/claude-code-specialists/pull/740) · merged 2026-08-16

---

