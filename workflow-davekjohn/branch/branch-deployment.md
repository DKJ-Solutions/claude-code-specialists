## `feat/release-page-theme-seam` deployment

### What does the change on this branch deploy to main?

The release-notes page takes its colours from the repo. `Get-ReleasePageTheme` joins
`Get-ReleasePageTitle` and `Get-ReleasePageWorkerName` as the third optional answer in that family: a map
of custom-property overrides, written into the page as one `:root` block. Absent, nothing changes — the
page keeps its shipped palette in light and dark.

**`color-scheme` is accepted as a name beside the `--custom-properties`, and that is the half the request
turned on.** A brand with no dark variant pins `light` and keeps its colours on any background; without it
the seam could say *these colours* but not *no dark mode*, which is exactly the case inbound #759 named.
The block is written **after** the dark-mode media query, so a repo's answer beats both defaults rather
than being overridden by whichever matched last — and that is asserted by position, not just by presence.

**The values are validated rather than escaped, and that distinction is the security half.** They land in
a `<style>` element, where escaping a `#` would stop it being a colour while a closing style tag would end
the element and turn everything after it into markup. So `Format-ReleasePageStyle` allows names that are
`--something` or `color-scheme`, and values built from letters, digits, `#`, parentheses, commas, dots,
percent, spaces and hyphens — nothing else. A rejected key is **dropped with a warning naming it**, and the
page is still generated: a report about releases must not be stopped by one bad colour, and a silently
ignored setting is the failure this repo keeps paying for.

**What this deliberately does not do is the design pass**, which is the other half of #759 and is not a
branch's to take: no gate can prove that a page *looks* right. The seam is the prerequisite that request
named, and its shape survives a redesign — whatever the properties end up being called, the mechanism is
the same override block in the same place.

**Score:** 3

#### What makes this change extra special

The interesting part was not the seam but what building it exposed. The template's own doc comment listed
its placeholders **by spelling them in full**, and `String.Replace` hits every occurrence — so the comment
was being filled in on every build. Harmless while all four were short strings, and not harmless the moment
a palette joined them: the page came out with a whole `:root { ... }` rule, comment and all, written inside
an HTML comment above the dark-mode block.

**Nothing rendered wrong.** The real block was also in its proper place, so the page looked correct, no
check spoke, and only an assert measuring *where* the palette landed could see it. That assert existed
because the cascade made position load-bearing — which is the argument for writing the assert that way even
when presence would have been easier. The doc comment now names the placeholders without their sigils, and
carries the reason.

A second, smaller instance of the same shape followed immediately: the assert counting `:root` blocks
counted the new comment, which quotes `:root { ... }` while explaining the defect. It is anchored on the
line start now — the mention-versus-use question this repo's lint has answered four times, arriving in a
test.

**Score:** 3

### Pull Request

the release-notes page takes a palette from the repo
