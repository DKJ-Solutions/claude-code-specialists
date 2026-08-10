## `docs/the-v4-0-0-page-holds-itself-to-the-seven-tests` changelog

### Branch title

The v4.0.0 consumer page is rewritten for its own reader

### Branch ID

20260810-161502

### Branch type

docs

### What does the change on this branch bring to main?

The seven tests in the `cut-release` skill were written after reviewing `v4.0.0`'s own consumer page and
finding it half-written for a maintainer. This applies them to that page. **Every factual claim it made
is still there** — what changed is who it is addressed to, and in what order.

**What the tests actually caught:**

- **Test 3, the order.** The three migration sections — the only actionable content on the page — sat at
  the *bottom*, and the lead had to tell the reader to skip down to them. They are now the first section,
  and they run chronologically (`3.2.0` → `3.8.0` → `3.10.0`) instead of the previous
  `3.10.0` → `3.2.0` → `3.8.0`, so a reader on an old version walks forward from wherever they are
  instead of jumping backwards.
- **Test 5, the symptom.** The page said both breaking changes "fail in silence" and stopped there.
  Silence is a category; what a reader can check is a fact. Each one now names what they will actually
  see — a session that starts normally with no specialists in it, and a name that no longer resolves.
- **Test 2, our effort versus their outcome.** Gone: "twenty-one releases and fifty-one pull requests in
  ten days", and the whole block about a lint check we measured over 120 documents and declined. Both are
  true and neither is theirs; the second is tier-0 material that had reached a tier-2 page.
- **Test 4, the lead.** It now answers both branches of the only question the reader arrives with: on
  `v3.10.0` there is nothing to do, before it there are two things that break with no error message.
- **Test 1, the second person.** Three of the three "what you get" items are now addressed to the reader,
  including the release-rules correction, which is genuinely useful to them and had been written as a
  description of our documentation.

**Measured, because "it reads better" is not a measurement:** 654 words from 679 and `you`/`your` from 27
to 33. The word count barely moved, and that is the honest result — this was not a trim. One block left,
structure arrived (the symptoms, the numbered walk), and the essayistic paragraphs became two-to-four
sentence items. What moved was what the words are about and where they sit.

### Significance

#### Tier 0

The page is one of eleven consumer documents and nothing reads it programmatically. Its value here is as
the worked example: the next person editing a consumer draft has a before-and-after of the seven tests
applied to a real page rather than a list of rules.

**Score:** 2

#### Tier 1

The norm proved itself on the document that provoked it, and the measurement is the part worth carrying:
the word count barely moved. Anyone expecting "write for the reader" to mean "cut it down" now has the
counterexample — the repair was ordering, addressee and one deletion, not length.

**Score:** 3

#### Tier 2

Anyone updating from `v3.x` opens this page to answer one question, and the answer used to be at the
bottom behind a chapter retrospective. It is now the first thing on the page, in the order they would
actually walk it, and each breaking change tells them what they will see when it bites.

**Score:** 3

### Pull Request

