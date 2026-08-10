## `feat/the-consumer-document-is-written-for-its-reader` changelog

### Branch title

The consumer document has a writing norm, and a gate against misrouting its reader

### Branch ID

20260810-153739

### Branch type

feat

### What does the change on this branch bring to main?

Renaming the tier-2 document after its reader was half the answer. This is the other half: **seven tests
for the document itself**, in the portable `cut-release` skill, and **one of them as a gate**.

**Where the tests come from.** `v4.0.0`'s own consumer document was reviewed against the question *"is
this written for someone who paid for the product?"*, and the answer was: partly. One of its four
substantive blocks was in the second person; it opened with "twenty-one releases and fifty-one pull
requests in ten days" — our effort, not their outcome; it carried a full block about a lint check we
measured and declined, which is tier-0 material in a tier-2 document; it used in-house vocabulary; it had
to tell the reader to skip to the bottom for the useful part; and it linked them into the development
notes. Five dev-tool changelogs were then read — Linear, Stripe, Vercel, Raycast, GitHub — and each of the
seven tests is carried by what one of them actually does, rather than by taste. Vercel runs 2–4 sentences
per entry; Stripe puts a `Breaking change? Yes/No` on every one; Raycast's changelog contains *zero*
internal metrics; React's upgrade guide orders its whole contents by urgency.

**The split between prose and gate is the measured part, and it is what travels.** Three candidate rules
were run over this repo's eleven consumer documents before anything was built:

| candidate rule | findings | true | verdict |
|---|---|---|---|
| links into `development/` or `internal/` | 2 | **2** | built — lint check 25 |
| a significance score in the document | 4 | 0 | declined |
| a branch name or PR number in the document | 3 | 0 | declined |

Both declined rules fail on the same document for the same reason: `v3.7.0`'s release **was about the
entry format**, so its consumer document correctly quotes `#### Tier 2`, `**Score:** N/A` and
`` ## `feat/your-branch` changelog `` as illustrations of the shape it was announcing. No regex separates
an illustration from a leak, and both rules would have needed an exemption list on the day they landed.

**Check 25 escapes that by reading the link TARGET only.** A path in prose is check 4's declined territory
— 124 findings, none real, because most paths this product names describe somebody else's repo — while a
link is not a path being discussed but a destination being offered. The two real findings were removed in
the same change, so the gate reports 11 documents and 0 findings rather than being born red behind an
exemption list. Eight asserts hold it, including all three deliberate narrowings and the case where a repo
has no consumer tier at all.

### Significance

#### Tier 0

The gate closes a defect class no other check sees, and the three-rule measurement means the next person
who proposes "flag X in the consumer document" has the answer already: two of the three obvious rules are
false-positive machines on this tree, and the reason is a document that legitimately quotes the format it
announces.

**Score:** 3

#### Tier 1

This is the transferable half. The finding was not sloppiness but **audience drift** — a maintainer editing
the draft keeps writing for the reader they have been writing for all week — and the seven tests are a
checklist against exactly that, with a named example behind each. Anyone here writing anything
outward-facing can hold it against the same list.

**Score:** 4

#### Tier 2

A consumer who enables this workflow gets the seven tests in the `cut-release` skill they already follow,
and the instruction to run the same three-rule measurement over their own documents before automating any
of it — because which rule a repo can afford as a gate is a fact about that repo's tree, not about the
list. Two of their release pages here also stop pointing them into a document written for developers.

**Score:** 3

### Pull Request

