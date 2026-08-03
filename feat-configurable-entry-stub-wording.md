### Repo-configurable stub wording for a changelog entry · Feat · 2026-08-03

The shared `new-changelog-entry.ps1` wrote four hardcoded English strings into every entry file it
created: the title placeholder, the body heading, the fallback body, and the changelog type an
unknown branch prefix falls back to. They are now read from four **optional** functions in the
consumer's own `scripts/repo-config.ps1` — `Get-EntryTitlePlaceholder`, `Get-EntryBodyHeading`,
`Get-EntryBodyPlaceholder` and `Get-EntryFallbackType` — each `Get-Command`-guarded and falling back
to exactly the text it used to hardcode, so a consumer that defines none of them sees no change at
all. Same pattern as `Get-ChangelogHeading` (#178) and `Get-LiveStage` (#177).

**Why it matters more than four strings.** The file this script writes is repo-owned, so its
language is too. A Dutch-language consumer therefore kept a private copy of the whole script at the
*same relative path*, purely to change these four values — and then got two entry formats for one
branch, depending on which entry point ran: the repo's own flow called the local copy, the
`new-branch` skill called the shared one. That is precisely the duplication the skill exists to
prevent. Dropping the copy fixed the duplication and cost them English stubs in a Dutch changelog;
this gives the wording back without the copy.

Three details worth knowing:

- **`-Title` now defaults to an empty sentinel** in both `new-changelog-entry.ps1` and
  `new-branch.ps1`, not to the literal `TODO: title`. A param default is bound before `repo-config`
  can be read, so the default has to mean "the caller named no title" and be resolved afterwards.
  Keeping the literal would have put a copy of the placeholder in two scripts while the value it
  stands for lived in a third.
- **`repo-config.ps1` itself stays optional for this script**, unlike `open-pr`/`fold`, which
  pre-flight on it: `Test-Path` plus a `try`/`catch` that degrades to a warning. It is the lightest
  script in the set and every string it reads has a working fallback — a syntax error in someone's
  edit costs a warning, not a branch without an entry file. Measured, not assumed: the new fixture
  feeds it an unparseable `repo-config.ps1` and the entry is still written.
- All four are declared **OPTIONAL** in `check-script-contract.ps1`, so a consumer gets an `[INFO]`
  naming the default instead of discovering the wording one branch at a time. This is the clearest
  case yet for declaring an optional: nothing crashes without them, so that `[INFO]` is the only
  signal that will ever exist.

Tests: `new-branch.tests.ps1` gains a scenario proving a configured wording really reaches the entry
file (all four knobs at once, via an unknown prefix and no `-Title`/`-Intent`) and one proving a
broken `repo-config.ps1` degrades to a warning; `repo-config.tests.ps1` pins the four workshop values
against the shared defaults and asserts the fallback type is a type this repo's branch table actually
produces; `script-contract.tests.ps1` covers the four new records end to end.
