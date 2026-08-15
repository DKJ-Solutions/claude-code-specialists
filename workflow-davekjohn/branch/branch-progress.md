## `docs/false-claims-sweep` progress

### Steps

#### PLAN

- [x] Verify all four findings against the tree before touching anything (done during the review; each
      is quoted with its file:line in the issue it was filed under)

#### CREATE

- [x] `#696` — `SECURITY.md`: name the release-notes Worker in scope with its path token as the
      boundary, and narrow the out-of-scope sentence to what is still true
- [x] `#702` — `05-06-extension.md`: check 19 → check 20
- [x] `#716` — `06-24-extension.md`: record the persona-template widening as shipped (August 8, 2026)
      rather than open, kept as a closed item so the generator's citation still resolves
- [x] `#703` — `.claude/specialists/README.md`: split the six by how they are actually reached, and
      state in the persona-lens note that Bianca has a lens and no caller
- [~] Give Bianca a routing row instead — dropped: that would be a way-of-working change (this repo
      does no intake interviews), not a documentation repair, and it is not what was asked

#### TEST

- [x] `check-plugin-integrity.ps1` green
- [x] full test suite green

### Where I left off

