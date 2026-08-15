## `feat/release-notes-page` progress

### Steps

#### PLAN

- [x] Read what smartwatchbanden actually built: TWO pages, and only one is on Cloudflare -- a
      generated archive published as a private artifact, and a hand-edited management edition served
      by the worker `swb-release-notes`.
- [x] Put the three course-defining questions to Dave rather than guessing: the lock (unguessable
      path + noindex), where the machinery lands (portable, in the plugin), and the content (the
      audience notes, generated).
- [x] Measure the two claims the consumer's script is built on, before copying either.
      `ConvertTo-Json` returns in **47 ms** on the nested shape at this size, not "not within five
      minutes"; and PowerShell 5.1 **does** escape the angle brackets. Both of their workarounds are
      therefore left out, and the escaping is asserted instead of trusted.

#### CREATE

- [x] `scripts/release/release-notes-page-template.html` -- the page: release picker, prev/next,
      keyboard arrows, deep link per version, light/dark, self-contained (no CDN: the worker serves
      one string, and a third-party request would leak who is reading).
- [x] `scripts/release/build-release-notes-page.ps1` -- reads the history table for order/date/type/
      title, the notes for content; writes the page, and with `-Worker` the worker bundle.
- [x] Two optional seams with working fallbacks: `Get-ReleasePageTitle` and
      `Get-ReleasePageWorkerName`, answered for this repo in `scripts/repo-config.ps1`.
- [x] Register both files in `scripts/lib/shared-scripts-lib.ps1` so they travel to consumers, and
      declare the two seams in `scripts/lib/script-contract-lib.ps1` (both `decide`).
- [x] `.gitignore` the page directory -- output is derivative, and the token is a lock whose key must
      not be committed in a public repo.
- [x] The skill page: `plugins/workflows/workflow-davekjohn/skills/release-notes-page/SKILL.md`.
- [x] Regenerate the mirrors and the config blueprint.
- [~] A `-Deploy` switch: dropped deliberately. Publishing is outward-facing under the safety rules,
      so the script names the command and stops; automating it would move the decision into a flag.

#### TEST

- [x] `scripts/tests/release-notes-page.tests.ps1` -- 48 asserts, testing the GENERATED PAGE rather
      than the script's internals, which is how the consumer found their live-marker bug.
- [x] Exercise the renderer for real: all 21 notes rendered under node with a DOM stub, 0 problems,
      plus 14 targeted cases (inline code with asterisks, a bare number in prose, list boundaries,
      tables, blockquotes, fenced code). Two bugs found and fixed that way -- a code-span sentinel
      that matched ordinary numbers, and a link regex looking for an entity `esc()` never writes.
- [x] Exercise the worker without deploying: loaded `worker.js` in node and asserted 200 on the token
      route (and with a trailing slash), 404 elsewhere, the noindex header, and the full page served.
- [x] Documentation: the portable half in `RELEASES-portable.md`, this repo's answers in
      `workflow-davekjohn/releases/README.md`, both `scripts/README.md` pages, the plugin README and
      the two root-README skill spans.
- [x] Lint gate green, all suites green.

### Where I left off

The build half is finished and nothing has been published. **Deploying is Dave's call** -- it is
outward-facing under the safety rules, so this branch stops at the bundle.

What is waiting on that word, in order:

1. `cd workflow-davekjohn/releases/page && npx wrangler deploy` (needs a Cloudflare login on this
   machine; the account resolves from `CLOUDFLARE_ACCOUNT_ID` or from a single-account token).
2. Check the bytes the URL serves -- not the deploy output, for the reason the script prints.
3. Record the finished URL **outside this repo**: the token is gitignored here because the repo is
   public, so nothing in git remembers it. The token created on this machine is already in
   `workflow-davekjohn/releases/page/worker-path-token.txt`.

Also worth knowing: the page is a snapshot, so it goes stale at the next cut until it is rebuilt and
redeployed. No gate watches that, deliberately -- the page carries its build date instead.
