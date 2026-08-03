### Drop the print-ready HTML from the highlights tier · Chore · 2026-08-03

**Dave, August 3, 2026: the HTML is not wanted anywhere.** So this is a removal from the *shared* code,
not a knob switched off in this repo — the tier can no longer produce HTML in any consumer, including the
one it was ported from.

**What is gone.** `ConvertTo-ReleaseHtml` and `Format-InlineMarkdown` in `release-lib.ps1` (88 lines,
ported and removed the same day), the `.html` write in `cut-release.ps1` step 3d, and the `HtmlLang` key
from `Get-ReleaseHighlightsWording` — which now carries two keys instead of three. The highlights tier
keeps doing everything else: the stakeholder/developer split, the metadata stripping, the marker.

**Why the removal is an improvement and not just a subtraction.** That renderer was the weakest part of
the port and the part needing the most explanation: a partial markdown subset that passed links through
as literal `[text](url)`, documented as a known limitation and pinned by a test asserting the limitation
stayed. A page that silently renders a link as its own source text is worse than no page. Anyone wanting
a PDF renders the markdown with a tool built for it.

**The generated `v3.2.0.html` is removed from `main`, and the `v3.2.0` tag still contains it.** That is
deliberate: a tag records a moment and is not rewritten. So `git show v3.2.0` and `main` differ by that
one file, which is stated in `releases/README.md` rather than left for someone to discover.

**Tests assert the ABSENCE rather than dropping the old asserts** (`release-lib.tests.ps1` 199, down 20;
`cut-release-guardrail.tests.ps1` 11, up 2). A partial HTML renderer is exactly the kind of thing that
gets helpfully reintroduced, so re-adding one should turn a test red: the two function names must not
resolve, the generated document must carry no HTML tag other than the marker comment it is built from,
and `cut-release.ps1`'s text must contain no `.html` path at all.

**Docs corrected in five places** — `CLAUDE.md`'s tier table, [Rendall
#06](.claude/specialists/lenses/05-06-extension.md), `releases/README.md`, the `cut-release` skill, and
the seam comments in `repo-config.ps1`. Each one said the tier produces a print-ready page.

**One consequence for the consumer, worth naming.** smartwatchbanden has eleven `.html` files under
`releases/highlights/` from its own unshared script. Those stay — they are that repo's history — but once
it picks up this plugin version its next cut produces markdown only.
