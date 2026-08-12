## `docs/ticketwork-language-row` progress

### Steps

- [x] Replace the stale worked example on line 187 — the originating repo no longer answers "Dutch"
- [x] Split the language row into its two questions: the form (one answer per repo) and the outgoing message (a property of the requester)
- [x] Keep the measurement that made the split necessary, in the page's own style — no gate, no seam, no template
- [x] Copy edit the diff (Edith #17) — 7 findings, all applied or judged; see "Where I left off"
- [x] Write the changelog entry: what the change does + tier 0 (2) and tier 2 (3) scores
- [ ] PR + merge + fold

### Where I left off

Edith's findings, and what was done with each:

1. **Branch title lowercase** — fixed. Verified against `CHANGELOG.md`: 8 of 9 sampled titles are
   sentence-case, and the ninth starts lowercase only because its first word is the literal `new-branch`.
2. **"six headings" was an invented number** — fixed, now "every heading". The figure came from the issue,
   where it described the originating repo's own file; the page fixes no heading count and says a file
   answers four things, so stating six as a general fact broke the page's own "Measured:" discipline.
3. **"this page is English because the plugin is" was lost with the old cell** — restored verbatim, since
   it is a separate fact from the stale example and answers the question the new paragraph invites.
4. **Steps unticked** — fixed here.
5. **"outgoing message" vs "the reply"** — bridged once ("the reply of rules 6 and 8"), and the remaining
   uses in both the page and the entry now say "message" consistently.
6. **"Dutch" unquoted in the entry's tier 0** — fixed.
7. **The paragraph argues for English where other rows stay neutral** — kept deliberately. It is framed as
   *the argument for* picking English, with "a repo picks a language once and is done" ahead of it, so the
   answer stays the consumer's. The page's own ethos is that the reasoning is the half worth having, and
   #624 explicitly asks for the question's shape rather than for its answer.
