# Changelog

Everything merged since the last release, furthest reach first: **one `##` per change**, and under it six
named `###` sections answering what a reader arrives with. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier under *Significance*, each closing with its score. That is what orders this list:
furthest reach first, and within a tier the most consequential change first. It also decides what may be
released, because **the bump follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or
higher earns a minor**, and a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a
patch waiting to be cut, not a release with nobody to announce it to.

---

## `docs/v4-8-0-release-note` changelog

### Branch title

The v4.8.0 release note

### Branch ID

20260813-204153

### Branch type

docs

### What does the change on this branch bring to main?

The one hand-written document for the minor tagged tonight: the consumer section rewritten from the
cut's draft against the seven writing tests, and the two organisational sections no script can
generate.

**The consumer section leads with the one item that asks the reader to re-check something** — an
audience-tier answer given from strings that stated the superseded ladder — and gives the check in one
look: who reads your release notes decides your tier, not who uses your product. The other items are
opt-ins: one seam answer to put a whole test suite behind the gates, one deletion to replace a
hand-copied process page with the plugin's maintained one, and a pointer back at `v4.7.0`'s notes.

**The *what it is worth* section is built on the release's own shape: four of the seven changes arrived
as consumer-filed inbound issues, each measured against a real adoption attempt.** The section names
what the organisation stops paying — not the 4,154 hand-copied words per mirror, but the standing risk
that a page a consumer's gates enforce against them describes a convention three claims out of date —
and records that both silent failures this release closed had produced plausible output the whole time
they stood.

**Step 0a's first pass is a subtotal of 5m 02s to the pushed tag**, three times less than `v4.7.0`'s
frozen 15m 31s, and the note says plainly that the gates cost the same three-and-a-bit minutes in both:
the difference is a pre-flight of two reads, on the second consecutive cut to start on the first
attempt. It names that five-minute figure as the fixed cost the release-cadence trade should be
computed against.

### Significance

#### Tier 0

The record of what a clean release now costs (about five minutes to the pushed tag) lives here or
nowhere, and it is the figure the next "make releases cheaper" discussion should start from.

**Score:** 3

#### Tier 2

It is the only document written *to* a consumer for `v4.8.0`, and it leads with the one item that asks
them to act: re-checking an audience-tier answer that, given wrong, silently degrades every release to
a patch — the failure one consumer already met.

**Score:** 4

### Pull Request

[PR #651](https://github.com/DaveKJohn/claude-code-specialists/pull/651) · merged 2026-08-13

---

## `docs/v4-8-0-timing-total` changelog

### Branch title

The v4.8.0 release note gains its end-to-end total

### Branch ID

20260813-210057

### Branch type

docs

### What does the change on this branch bring to main?

The second timing pass step 0a asks for, which exists because a release note cannot time its own
publication. `v4.8.0`'s note was frozen at a 5m 02s subtotal; the five remaining legs — writing the
document (3m 48s), its gates (3m 12s), its CI (7m 33s), the merge with the fold (3m 54s) and the
publish (20s) — are added, giving a **total of 23m 49s** from clock start to a published Release with
its attachments.

**The tail was 18m 47s, 79% of the total — and within forty seconds of `v4.7.0`'s 19m 26s.** Four timed
releases have now produced four different fractions, but the last two agree on something more useful
than a fraction: the tail is nearly constant in absolute terms, because it is made of fixed legs — this
CI run landed within two seconds of the previous release's, the document gates within three seconds.
The fraction grew only because the head shrank. That moves the optimisation question: the head is at
five minutes and nearly all gates, so the next saving lives in the tail's one duplicated leg — the
merge re-running the suites the PR already proved — measured here at about three of the merge leg's
3m 54s, consistent with `v4.7.0`'s 3m 18s.

**The copy attached to the GitHub Release is the frozen one**, and the note says so, following the rule
`v4.7.0` set: an attachment is what was published at the moment of publication, and silently replacing
it is the opposite of the record the document is for.

### Significance

#### Tier 0

The fourth timed release turns "the tail is unpredictable" into something sharper — the tail is
constant, the head is what varies — which redirects the next optimisation from the head (already at
five minutes) to the duplicated merge-leg gate run.

**Score:** 3

#### Tier 2

A consumer reads the release note, so a measured claim inside it is a claim made to them; this one
tells them where a release's time actually goes, on numbers from two consecutive releases that agree.

**Score:** 2

### Pull Request

[PR #652](https://github.com/DaveKJohn/claude-code-specialists/pull/652) · merged 2026-08-13

---

