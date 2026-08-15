---
name: release-notes-page
description: >-
  Build the hand-written release notes into one browsable page -- a picker per release, the document
  rendered -- and, optionally, into a Cloudflare Worker that serves it at an unguessable path. Use
  this when the people a release is written for are not developers: the note is markdown in a
  repository, which is the right home for it and the wrong place to read it. The page is a SNAPSHOT,
  so it is rebuilt and redeployed after a release rather than following one. The script builds and
  never publishes -- `npx wrangler deploy` is a separate, deliberate step, because publishing is
  outward-facing. Needs no configuration to build the page; hosting needs two optional seam values.
disable-model-invocation: true
---

# release-notes-page — the reading copy of your release notes

This is the **plugin mirror** of `build-release-notes-page.ps1`: the same tested source as in the
source repo, shared here so consumers do not each write their own.

**Why it exists.** The hand-written note per release is the one release document written for somebody
*outside* the development work — management, a commissioner, a subscriber. It lives as markdown under
your note root, which is the right home for it and the wrong place to read it: that reader has to find
a directory, pick a version out of a filename, and read raw markdown in a code host. This turns the
same documents into one page they can open.

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/build-release-notes-page.ps1"
```

**In the source repo, run its own copy instead — `scripts/release/build-release-notes-page.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. The script refuses outright when it is a
released copy running in the repo that maintains it.

It reads:

- **the release list at `Get-ReleaseHistoryPath`** — for the order, the date, the type, the title and
  the live marker. Not the filenames under your note root: a directory listing knows none of those, and
  sorts `4.10.0` before `4.9.0`.
- **the note per release**, at `<Get-ReleaseNoteRoot>/<folder>/<X.Y.Z>.md`, where the folder shape is
  `Get-ReleaseNotesGrouping`'s answer (`4.x` or `4.11`).

A release with no note is skipped, and the report tells the two kinds of absence apart: one *inside*
the covered range is named (either a bump you write no note for, or a note nobody wrote — both are
answers you can check), while releases older than your first note are counted. Naming all of them
printed **seventy** versions when this was measured, which reads as a defect list and is history.

## Where the output goes, and why none of it is committed

A `page/` directory beside your note root — derived rather than configured, because the note root
already says where this repo keeps its release documents:

```text
<note root>/../page/
  release-notes.html      the page                        (generated)
  worker.js               the worker bundle, with -Worker  (generated)
  wrangler.toml           written ONCE, then yours
  worker-path-token.txt   the path token -- see below
```

**Add that directory to your `.gitignore`.** The page and the worker are derivatives of documents that
are already tracked, rebuildable in a second, and large enough that a tracked copy dirties the working
tree on every release — which is a problem, because `cut-release.ps1` refuses to run on a dirty tree.

**The token is the exception, and which way it goes depends on your repository.** In a **public** repo
it must stay out: the token *is* the lock (see below), so committing it publishes the key beside the
door — and the consequence is that nothing in git remembers your URL, so whoever creates it records it
elsewhere. In a **private** repo, commit it: a tracked token is what survives a lost machine, and it is
already inside a repository only your people can read.

## Hosting it: two seam values, and one of them has a consequence outside your repo

Both live in your own `scripts/repo-config.ps1`, both optional:

| function | what it answers | absent |
|---|---|---|
| `Get-ReleasePageTitle` | the heading and window title — what the reader should understand the page to be, usually the **product's** name rather than the repository's | falls back to the name half of `Get-RepoName` |
| `Get-ReleasePageWorkerName` | the Cloudflare Worker that serves it | `''` — the page is built and hosted nowhere, and `-Worker` refuses while naming this function |

**Read this before answering the second one.** The worker serves the page at `/notes/<32 hex>`, and
**that path is the only lock on it**: there is no login, so anyone with the link can read. The page
carries `noindex` in both the response header and the meta tag, because a link nobody can guess is
worth nothing once a crawler has published it. Answer this only where the notes are safe in the hands
of whoever receives the link — in the source repo they already are, since that repository is public and
the notes are in it.

## The path token is an input, never invented

The script **does not make one up** when the file is missing, and that refusal is the whole design:

> A token invented on the fly does not mean *"a new path"*. It means **every link you have already sent
> now 404s** — while the build and the deploy both report success.

So a missing token is an error with a recovery instruction: restore the 32 hex characters from the URL
you have. `-InitToken` is the separate, explicit way to create the **first** one, and it refuses to
replace an existing token.

## Publishing, and how to tell whether it worked

The script **deploys nothing**. It writes the bundle and names the command:

```powershell
cd <note root>/../page
npx wrangler deploy
```

**Verify a redeploy against the bytes the URL serves, never against the deploy command's output.**
Measured in the consumer this was ported from: once wrangler has created a deployment on a worker, an
API-side upload only creates **inactive versions** — with no error, while the live page stays the old
one.

## It is a snapshot, not a mirror

The page is built from the files as they are at that moment and does not move with them. After a
release: **rebuild and redeploy**, in that order. Nothing reminds you — the page carries its build date
in the footer so a reader can see how current it is, which is the honest version of a guarantee nobody
can make.

## Parameters

| parameter | what it does |
|---|---|
| `-OutFile <path>` | where the page lands, instead of `release-notes.html` in the page directory |
| `-Worker` | also write `worker.js`, and `wrangler.toml` if it is not there yet |
| `-InitToken` | create the path token when there is none; refuses to replace one |

## Requirements in the consumer

- `scripts/repo-config.ps1` — **optional for the page**, like `new-branch`'s: every value it reads has
  a working fallback, and a repo without the file still gets a page. Required for `-Worker`, which
  needs `Get-ReleasePageWorkerName`.
- A release list at `Get-ReleaseHistoryPath` with at least one release whose note exists. Both are
  named in the error when they are not there.
- `node`/`npx` only for the deploy, which is not this script's step.

## Important

- **The page is generated, not edited.** If your notes are per-PR records that need summarising for
  their reader, that is a different, hand-written page — not a mode of this script. Here the note is
  already written for that reader, so summarising it again would be a second thing to keep true.
- **This script is maintained in the source repo**; do not modify it locally in the consumer.
  A change lands first in the source and then travels via a release to the plugin mirror, guarded by
  the shared-scripts drift lint. The page template beside it travels the same way.
