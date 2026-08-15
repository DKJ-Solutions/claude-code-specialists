## `feat/release-notes-page` changelog

### Branch title

Host the audience release notes as a generated page on a Cloudflare Worker

### Branch ID

20260815-190736

### Branch type

feat

### What does the change on this branch bring to main?

**The hand-written release note is the one document written for somebody outside the development work,
and it lives as markdown in a repository.** That is the right home for it and the wrong place to read
it: the reader has to find a directory, pick a version out of a filename, and read raw markdown in a
code host. `build-release-notes-page.ps1` builds those documents into one page -- a picker per release,
prev/next, keyboard arrows, a deep link per version, light and dark -- and with `-Worker` into a
Cloudflare Worker that serves it at `/notes/<32 hex>`.

**Ported from smartwatchbanden, where two pages exist and only one is on Cloudflare.** That repo keeps
a generated archive of every document *and* a hand-edited management edition; the edited one earns its
keep there because its notes are per-PR records that need summarising. Here the note is already written
for that reader, so this page is **generated and never edited** -- summarising it a second time would
be a second thing to keep true.

**Two of that consumer's design decisions were re-measured before being copied, and both were dropped.**
Their script hand-writes a JSON serializer because `ConvertTo-Json` "does not return within five
minutes"; on this repo's 21 notes (187,039 characters) it returns in **47 ms** on exactly the nested
shape this builds. And it hand-escapes the angle brackets, which PowerShell 5.1 already does. So a
hundred lines of serializer are left out -- and the escaping is **asserted** rather than trusted,
because that failure is silent: an unescaped closing script tag ends the page's data block early and
the page renders empty with nothing erroring.

**One of their decisions was copied verbatim, with the reason.** The live marker is matched with
`-cmatch`. PowerShell compares case-insensitively by default, so every release whose *title* contains
the word "live" marks itself; two of their forty did, and their page pointed at three live versions.
There is a test for it here.

**The path token is an input and is never invented.** A token generated on the fly does not mean "a new
path" -- it means every link already sent now 404s, while the build and the deploy both report success.
Missing is an error with a recovery instruction; `-InitToken` is the separate, explicit way to make the
first one, and it refuses to replace one.

**It publishes nothing.** `npx wrangler deploy` is a deliberate, separate step, because publishing is
outward-facing under the safety rules. The script names the command and adds the warning that cost that
consumer a silent failure: verify a redeploy against the **bytes the URL serves**, never against the
deploy command's own output -- once wrangler has deployed a worker, an API-side upload only creates
inactive versions, with no error, while the live page stays the old one.

**Portable, not local.** Both files travel to consumers via the shared-scripts registry, with the
[`release-notes-page`](plugins/workflows/workflow-davekjohn/skills/release-notes-page/SKILL.md) skill as
their page and two optional seams -- `Get-ReleasePageTitle` and `Get-ReleasePageWorkerName` -- both
`decide`, both with working fallbacks, so a repo that answers neither still gets a page and simply hosts
it nowhere. The template is the first registry entry whose source is not a script; it is registered
`LibOnly` because what that flag really declares is "this file never resolves a repo root of its own",
which a template satisfies more completely than a lib does.

**Whether the token belongs in git is the consumer's answer, not the plugin's, and it splits on one
fact.** Private repo: commit it, because a tracked token survives a lost machine. Public repo -- this
one: keep it out, and accept that nothing in git then remembers the URL.

**Three stale counts were repaired on the way**, all of the same class the repo already guards for
elsewhere: the plugin README listed nine skills under the heading "The nine skills" while the directory
held twelve, and `scripts/README.md` named twenty-three mirrored scripts and thirteen guarded entry
points against twenty-eight and sixteen. The skill table is now complete rather than partial -- a
partial list of an enumerable set is worse than none, because a reader who finds four of their skills
missing cannot tell which document is wrong.

**Verified by running it, not by reading it.** All 21 notes rendered under node with a DOM stub (0
problems) plus 14 targeted cases, which found two real bugs before they shipped: a code-span sentinel
that also matched ordinary numbers in prose, and a link regex looking for an HTML entity the escaper
never writes. The worker was exercised the same way -- loaded in node, asserting 200 on the token route
and with a trailing slash, 404 everywhere else, the noindex header, and the full page served. 48 asserts
in `release-notes-page.tests.ps1`, all against the generated page rather than the script's internals,
which is how that consumer found their live-marker bug in the first place.

### Significance

#### Tier 0

This repo gets a reading copy of its own release notes, and three stale counts in the always-read docs
are corrected. Nothing about how work moves through the repo changes.

**Score:** 3

#### Tier 2

A consumer gains a way to put the note they already write in front of the reader it is written for,
without building it themselves -- one command, two optional seams, and no configuration at all for the
page half. It asks nothing of anybody: a repo that ignores it is unaffected, and hosting is a separate,
explicit decision with its trade-off written down rather than defaulted.

**Score:** 3

### Pull Request

