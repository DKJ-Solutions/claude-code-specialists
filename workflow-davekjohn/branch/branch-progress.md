## `fix/readme-stale-pointers` progress

### Steps

#### PLAN

- [x] Establish which law applies. `README.md` is product documentation, not an operating guide, so
      "does this break on uninstall?" is largely the wrong question — the product *is* the subject.
      It already states a sharper test of its own: *craft, or way of working?*
- [x] Audit compliance with that test rather than adding it: 0 `lint-en-tests`, 0 branch prefixes,
      18/18 uses of *portable* in the sense the page defines, figures covered by checks 15 and 16.
- [x] Check whether the README still describes `CLAUDE.md` and `CONTRIBUTING.md` in their pre-August
      shape. It did, in two places.

#### CREATE

- [~] Add the law to the README — dropped: it is already there, in
      *"Does this describe a craft, or a way of working?"*, and stated more sharply than the version
      applied to `CLAUDE.md`.
- [x] `## Contributing`: the standard page and the workflow layer named separately, each for what it
      actually holds, with the plugin's page winning on conflict.
- [x] Same section: the roster and routing pointed at `SPECIALISTS.md` instead of `CLAUDE.md`,
      matching what the README's own repo-layout list and seam section already say.
- [x] Start-here table: *"the branch / PR / fold workflow"* corrected — the fold is not on that page.
- [x] Sweep the other consumer-facing docs for the same stale pointer. `INSTALL.md`, `UNINSTALL.md`
      and `plugins/ADOPTION.md` never point at `CONTRIBUTING.md`; `CHANGELOG.md`'s intro already
      names the workflow layer correctly.

#### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors, 273 links resolve including the new `#the-seam-specified`
      anchor.
- [x] Full test suites.

### Where I left off

Nothing open.

Method note worth keeping: the grep that was meant to prove `CONTRIBUTING.md` no longer holds the fold
mechanics returned **3**, which reads as the opposite of the finding. Two hits were `fold` inside
`folder` and the third was the delegating sentence. That is the second substring trap in two branches
(`Dave` inside `DaveKJohn` was the first) — a raw count is what the pattern matched, never what the
question asked, and both times reading the matched lines settled it in seconds.
