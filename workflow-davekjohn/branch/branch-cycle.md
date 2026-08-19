# `feat/release-page-theme-seam` cycle · 20260820-011103

## PLAN

- [x] Split inbound #759: the palette seam is mechanism, the design pass is a visible result
- [x] Decide the shape -- the issue left it to the source, and the sibling `Get-ReleasePage*` family is
      the obvious home

## CREATE

- [x] `Get-ReleasePageTheme` probed in `build-release-notes-page.ps1`, beside the other two
- [x] `Format-ReleasePageStyle`: an allowlist for names and values, a warning per drop, never a failure
- [x] The template gains its placeholder AFTER the dark-mode block, so an override wins
- [x] The contract record (`Optional`, `Adopt = 'decide'`), this repo's own empty answer, blueprint rebuilt
- [x] The skill page's seam table goes from two to three, with the three things to know before writing one
- [~] The design pass -- not taken: it is a visible result, and no gate can prove a page looks right
- [~] A gradient/web-font vocabulary -- refused by the allowlist on purpose; that is the design pass asking

## TEST

- [x] `release-notes-page.tests.ps1`: 65 asserts green, 12 of them new
- [x] The hostile-palette case: a closing style tag, a brace escape and a non-custom-property name are all
      dropped, the sound key in the same map still lands, and every drop is warned about by key
- [x] Position and count asserted, not only presence -- which is what caught the template defect below
- [x] `check-script-contract`: `Get-ReleasePageTheme` present, 0 errors, the 5 pre-existing `[INFO]`s
      unchanged
- [x] `check-plugin-integrity.ps1` green, including `[config-blueprint]` and `[shared-script]`

## DEPLOY

## Where I left off

Done, and the lesson is not about palettes.

The template's doc comment spelled its own placeholders in full, and `String.Replace` hits every
occurrence -- so it had been filling itself in on every build since the page existed. With four short
strings that was invisible. With a CSS block it wrote a `:root` rule inside an HTML comment, above the
dark-mode block, while the page still rendered correctly. Only an assert on POSITION could see it, and that
assert existed only because the cascade made position matter.

Then the same shape once more, one level in: the count assert counted the comment that quotes `:root { }`
while explaining the defect. Anchored on the line start now.

**The design pass of #759 is Dave's** and the issue stays open for it.
