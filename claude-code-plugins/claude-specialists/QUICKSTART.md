# Quickstart — how to connect your repo

This page is for those who did **not** build the Claude Specialists system: a colleague with a repo
of their own who wants to work with the specialists team. Everything below is the common thread —
the deeper explanation sits behind the links and is deliberately not repeated here.

## What you get

Instead of one generic Claude, you work with a **team of specialized Claudes under one Chief of
Staff (Chris)**: every assignment is classified and delivered to the specialist with the right
playbook — a DevOps engineer for branches and PRs, a technical writer for docs, a copy editor
and code/security reviewers for the independent final pass before a PR or merge. Your repo stays in
charge: the governance (your `CLAUDE.md`, your safety rules) remains yours; the plugins only supply
the team and its playbooks.

The system consists of **four plugins**: the repo-neutral core `specialists` (group 1 — always
enable it) and three optional domain groups. Which specialists live in which plugin and who they are
meant for is covered in the [family README](README.md).

## Before you start

**Three things have to be true before Step 1's first command, and none of them used to be written down
anywhere in this family** (inbound
[#334](https://github.com/DaveKJohn/davekjohns-workshop/issues/334), measured August 1, 2026 on a
**virgin Windows user profile**, CLI `2.1.220`). On a machine that has been in use for a while all three
were satisfied long ago — which is exactly why they stayed invisible until someone adopted this system
on a new profile.

1. **Claude Code is installed and `claude` actually runs.** This page assumes a working `claude` and
   deliberately prints no install command of its own — it would go stale here. Start at Anthropic's
   [setup documentation](https://code.claude.com/docs/en/setup) instead. `claude --version` is the
   check; `claude doctor` prints read-only diagnostics when it fails.
2. **You are signed in.** Authentication hangs off your user profile, so on a fresh profile this is a
   real step even when the binary is already on the machine.
3. **On Windows, raise the execution policy — otherwise none of the PowerShell blocks on this page
   run.** A fresh Windows profile defaults to `Restricted`, which blocks **every** `.ps1`, and on an npm
   install `claude` itself resolves to one: measured, `ExternalScript …\npm\claude.ps1` comes ahead of
   `Application …\npm\claude.cmd`. So `claude plugin marketplace update …` — Step 1's first command —
   fails with a `PSSecurityException` on an untouched profile. One command settles it; no administrator
   rights, and it touches nothing under `~/.claude`:

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```

**If `claude` is still not found right after an install, close your editor completely rather than
opening another tab.** Every window spawned from a running editor inherits that editor's environment,
so a `PATH` that was just extended is invisible in a new tab or a terminal opened from it. Honest
scoping: this one is partly an artefact of the route that measurement took — npm was chosen there to pin
a specific CLI version, and Anthropic's own Windows installer handles `PATH` itself. It is here as a
symptom worth recognising, not as a step of this procedure.

**And if you are handing this page to an agent instead of reading it yourself, have it read the file
rather than a summary of it.** That is a plausible first move for a new consumer — paste the link into
Claude Code and say *"set this up for me"* — and it was measured (inbound
[#338](https://github.com/DaveKJohn/davekjohns-workshop/issues/338)): `WebFetch` on the raw URL refused
a verbatim request outright, and on an ordinary summarising question it returned content that did not
match the file. It described the document as *"8,000+ characters"*, a fraction of its real size, and it
**invented an enumeration for Step 2** that this page does not contain. Nothing here can fix a fetching
tool; two things do work. Save the raw file to disk and have the agent read it from there, or point it at
the marketplace clone once you have one — and check any count it quotes against the document itself,
because the counts on this page are load-bearing.

## Connecting in three steps

> **Three *steps* here, six *acts* inside Step 1 — a different unit, not a different path.** Step 1
> below is enable → **restart** → refresh → install → restart → verify, which the
> [family README](README.md#adoption-the-bootstrap-path) and
> [`specialists-init`](specialists/skills/specialists-init/SKILL.md#chicken-and-egg--step-0-is-done-by-the-user)
> both count as its six acts ("step 0" in their numbering). Saying so is the point: those two pages once
> counted the same procedure as *four* and *three*, and this page's *three steps* made a third number
> (inbound [#297](https://github.com/DaveKJohn/davekjohns-workshop/issues/297)). Nothing was missing from
> any of them — but if you are cross-reading and the counts differ, the count is exactly what you would
> use to check whether you skipped something.
>
> **It was five until August 1, 2026, and the sixth act is the first restart.** #329 measured that a
> session start is what registers the marketplace — so the act was always there, unwritten, and a reader
> who skipped it could not run act 3 at all. The number moved on all three pages in the same change rather
> than the restart being folded into "enable", because being folded into another act is precisely what
> kept it invisible.

**Step 1 — enable *and* install the plugins.** The first half is one file: **your repo's own**
`.claude/settings.json`. `.claude/` is a directory in the root of your repository, beside your
`README.md` — **create it if it is not there**, and on a repo that has never used Claude Code it will
not be.

> **`.claude` means two different places in this document, and from here on the difference matters**
> (inbound [#335](https://github.com/DaveKJohn/davekjohns-workshop/issues/335)). `.claude/` in **your
> repo** holds your settings, your seam and your lenses; it travels with the repo and it is yours.
> `~/.claude/` — on Windows `$env:USERPROFILE\.claude` — is the **machine** administration: the
> marketplace clone, the plugin cache, and the `installed_plugins.json` that the verification query
> below reads. Same name, two locations. Wherever this page prints a full path, it means the machine
> one. On the fresh profile this was measured on, neither existed yet, and one consumer reasonably read
> *"in your repo's `.claude/`"* as something still to be **installed** rather than **created**.

Set the marketplace source and the plugins you want in it (always the core; a domain group only if your
repo has that domain). What follows is a **complete, pasteable file** — if you already have a
`.claude/settings.json`, merge these two keys into the object that is there instead of pasting over it:

```json
{
  "extraKnownMarketplaces": {
    "davekjohns-workshop": {
      "source": { "source": "github", "repo": "DaveKJohn/davekjohns-workshop" }
    }
  },
  "enabledPlugins": {
    "specialists@davekjohns-workshop": true
  }
}
```

Claude Code parses that file as **strict JSON**: no comments, no trailing commas. An earlier version of
this page printed the two keys as a `jsonc` fragment — comment line on top, no outer braces — which does
not parse when pasted as printed, and `jsonc` as a label suggests the comment would be fine (#335).

This repo is public, so the source can be read without GitHub authentication; Claude Code clones
and caches it by itself. **But writing those keys is not the whole of Step 1, and the order is not
free.**

**First: restart your Claude Code session once, now.** The marketplace is registered by a **session
start**, not by writing the key — measured in three states on a virgin profile (inbound
[#329](https://github.com/DaveKJohn/davekjohns-workshop/issues/329)): without the settings file the
refresh command below fails; **with** the settings file, in the same session, it still fails; after one
session start in the repo it succeeds. The failure is easy to misread — on CLI `2.1.220` it reads:

```
✘ Failed to update marketplace(s): Marketplace 'davekjohns-workshop' not found.
  Available marketplaces: claude-plugins-official
```

The wording is version-bound and may differ on your CLI; what does not vary is that a "not found" here
means the marketplace has not been registered yet, never that you typed the name wrong. That reads as a
typo in the name, and it is not — it is a missing step. Until this was measured it was
the state of the very first executable command on this page for every consumer who had never had this
marketplace: a dead end, with nothing in the document to get past it.

**If you would rather not restart at that point**, `claude plugin marketplace add` registers it inside
the running session — measured, the refresh below then succeeded immediately, no restart. Two things to
get right, because this command does not follow the pattern of the others on this page:

```powershell
claude plugin marketplace add DaveKJohn/davekjohns-workshop --scope project
```

It takes a **source** (a URL, path, or GitHub repo) where everything else here uses the marketplace
*name*, and it defaults to `--scope user`, which would declare the marketplace machine-wide in
`~/.claude/settings.json` rather than in your repo's — the
[#279](https://github.com/DaveKJohn/davekjohns-workshop/issues/279) defect, rebuilt in a fourth command.
The `--scope project` above comes from the CLI's own `--help` (`user (default), project, or local`, CLI
`2.1.220`); #329's measurement was taken at the default scope, so treat the flag as documented rather
than measured and confirm with `claude plugin marketplace list` where it landed. Note also what `add`
does *not* do: measured, it left `installed_plugins.json` at `{}` and loaded no skills or subagents into
the running session. It makes the marketplace findable and installs nothing.

**Then the install** — an install is *per repo*, so run one command per plugin you listed, from the root
of your repo, preceded once by a refresh of that cached clone:

```powershell
claude plugin marketplace update davekjohns-workshop                     # 1. refresh the cache first
claude plugin install specialists@davekjohns-workshop --scope project    # 2. then install, per plugin
# and line 2 again for each domain group you enabled
```

**Line 1 matters most right here, because this is the command the failure was measured on.** Without
it, the install happily gives you the **previous** version and reports `✔ Successfully installed` —
measured on July 30, 2026 with a fresh `install`, not an `update` (the full account, and what `update`
does differently, is under [Staying up to date](#staying-up-to-date)). A stale cache produces a green line and a plausible
version number, so the only symptom is a session quietly missing whatever the release added. That is
easily mistaken for the restart problem described under
[Staying up to date](#staying-up-to-date) — a new skill needing a session restart — and is a
different cause with a different fix.

**Keep `--scope project` on that line.** `claude plugin install` defaults to `--scope user`, which
installs machine-wide and writes no `projectPath` at all — so you would get the one thing the
sentence above says this step is for, wrong, without any error. Same flag on the way back out:
`claude plugin update` has the same default and simply fails on a project-scoped install (see
[Staying up to date](#staying-up-to-date)).

**Expect that install to rewrite the `settings.json` you just wrote** (inbound
[#295](https://github.com/DaveKJohn/davekjohns-workshop/issues/295)). This is worth saying out loud
because `.claude/settings.json` is usually a **tracked** file, so the change shows up in `git status`
and looks like something went wrong. Measured on July 31, 2026 in throwaway repos with
`core.autocrlf false`: `claude plugin install … --scope project` re-serialises the whole file — key
order changes, nested objects get expanded onto separate lines — and in two of the fixtures it also
**removed a UTF-8 BOM** and **added a missing final newline**. It may also write LF into a CRLF file
(git says `LF will be replaced by CRLF the next time Git touches it`), which on a Windows repo is a
second, lasting source of diff.

**Whether that diff is only formatting depends on one thing: was `enabledPlugins` already there?**
Both halves are measured (inbound
[#303](https://github.com/DaveKJohn/davekjohns-workshop/issues/303), July 31, 2026):

- **Key already present** — the order above, where act 1 (enable) writes it before act 3 (install) runs.
  Then the content stays **equivalent**: no plugin is switched on that was not on before, and any diff is
  formatting. What you cannot count on is that there will be **no diff at all**. An earlier edition of this
  page said the file stays *byte-identical* and that *"the install writes only when there is something to
  write"*, on the strength of a single SHA256 comparison in `davekjohns-workshop`. Round v10 falsified the
  general form (inbound
  [#336](https://github.com/DaveKJohn/davekjohns-workshop/issues/336)): on a fresh Windows profile, with the
  key present and written in exactly this order, `claude plugin install … --scope project` **rewrote the
  file anyway** — `enabledPlugins` moved in front of `extraKnownMarketplaces` and the nested `source` object
  was expanded onto separate lines. The likeliest reading is that the workshop's file already happened to
  match the serialiser's own layout, which makes the old claim true of *that file* rather than of "key
  already present" as a category. So: **expect a formatting diff even when the key is there, and expect no
  behavioural change.** Round v12 closed the evidence gap v10 left: a hash pair captured at the moment of
  the install, key already present, written in exactly this order — SHA256
  `F694FB44…BF15EFA8` (224 bytes) before, `EB8834F7…AB275E4A` (246 bytes) after. Not byte-identical, and
  the 22 added bytes are precisely the two changes described above. **Behaviourally equivalent, textually
  different** is now measured rather than inferred.

  **On the path this page prescribes, that pair is reproducible — so it is a check you can actually use**
  (inbound [#385](https://github.com/DaveKJohn/davekjohns-workshop/issues/385)). Round v13 hit both hashes
  exactly, on a second profile: `F694FB44…BF15EFA8` at 224 bytes before, `EB8834F7…AB275E4A` at 246 after,
  and the +22 is the two changes described above, to the byte. That is not luck. Step 1 has you paste the
  printed block into a file that does not exist yet, so the "before" bytes are the block; and the CLI's
  serialiser is deterministic, so the "after" follows from it. Matching them tells you two things at once:
  you pasted the block intact, and the install did what it is supposed to do.

  **Only match them if that is the path you took.** An earlier edition of this line said the hashes were
  not something to match at all, which took a usable check away from the reader following the instructions.
  The warning still holds for everyone else: if you already had a `.claude/settings.json`, formatted it
  yourself, or merged the keys into an existing file, your two values will differ from these *and* from
  each other, and only the difference between them means anything.
- **Key absent** — then the install **adds `enabledPlugins`, with `true` per plugin**, and that is not
  formatting: it switches the plugins **on** in a tracked governance file. Measured in
  `DaveKJohn/life-hub`, which is deliberately plugin-clean between adoption rounds, so the key was
  nowhere. And this is not an exotic ordering: it is exactly what a **repair install** or a reinstall
  does — the prescribed move after a record has gone missing (see
  [Staying up to date](#staying-up-to-date)).

`claude plugin uninstall … --scope project` edits it too, on purpose: it removes your plugin's entry
and leaves `"enabledPlugins": {}` behind. All of it is the CLI's doing — the plugin's own scripts never
touch this file, which the `specialists-teardown` skill says of itself as well. So a **formatting** diff
here is expected rather than suspect; an **added `enabledPlugins` block** is the one change in this
paragraph you would want to see in code review. And if your repo has an opinion about JSON formatting,
this is the file that will lose the argument.

**What those two keys do on their own is an open question, and this page no longer claims they do
nothing.** It used to say so in bold. Measured on a virgin profile with the marketplace registered and the
cache present, a **single session start** — no command run, no file changed — wrote a full,
project-scoped install record with the correct `projectPath`, `version` and `gitCommitSha`,
indistinguishable from the one the install above produces (inbound
[#327](https://github.com/DaveKJohn/davekjohns-workshop/issues/327)). The session that writes it still
loads nothing itself: the record is written *after* the load phase, so only the next session gets the
plugin. Whether that makes the two commands above redundant has not been tested end to end — so run
them. They are the route this page can vouch for, and one of them is what puts a version in the record at
all.

**Then restart your Claude Code session** and check that it worked — but **not with `claude plugin
list`**. That command is not repo-scoped: it reports install records beyond your repo, so it can show
a plugin as `enabled` in a repo that has no install at all. Check the record for *your* repo, from
its root:

```powershell
$root = (Get-Location).Path
(Get-Content "$env:USERPROFILE\.claude\plugins\installed_plugins.json" -Raw | ConvertFrom-Json).plugins.PSObject.Properties |
  ForEach-Object { $n = $_.Name; $_.Value | Where-Object { $_.projectPath -eq $root } |
    ForEach-Object {
      $payload = if ($_.installPath -and (Test-Path -LiteralPath $_.installPath)) { 'payload present' } else { 'PAYLOAD MISSING' }
      "$n -> $($_.scope) $($_.version) $($_.gitCommitSha) [$payload]" } }
```

**One** `project` line per plugin you listed is what you want — the count is part of the check, not a
detail. **And it has to end in `payload present`.** The record names an `installPath`; nothing writes
that record and the files it points at in the same act, so the path can be absent while every other
field is correct. That last check is why this query has a fourth field at all — see the blockquote
below. The last field is the commit the payload came from, and it answers a different question than the
version does: see [Staying up to date](#staying-up-to-date) under *"the version is not the code"*. Empty output means nothing was installed here. *Two* lines for the same plugin is a stray second
record, which a repair install can create rather than prevent, and a line reading `local` was written by
a session start rather than by you; both are covered under
[Staying up to date](#staying-up-to-date). Do run it — if the install did not happen, the skill from
step 2 and the session hooks are simply absent, and that looks exactly like a session where everything
is fine.

> **The installed record with the inert session — the one state that reads as healthy from every angle**
> (inbound [#327](https://github.com/DaveKJohn/davekjohns-workshop/issues/327)). Measured on a virgin profile:
> a **single session start**, with no command run, wrote a full `project`-scoped record with the correct
> version and sha — and **that same session loaded nothing at all**: no `specialists-*` skills, no subagents,
> no session-hook output, no routing announcement. The record is written *after* the session's load phase.
>
> **And the second measurement was a notch worse than the first** (inbound
> [#355](https://github.com/DaveKJohn/davekjohns-workshop/issues/355), round v11). Above, the payload at least
> sat in the cache, so the *next* session got the plugin. Measured again on a fresh profile after **three**
> session starts and still zero `claude plugin` commands, the record read `project 3.1.0` with the right sha
> — and `installPath` pointed at a directory that **did not exist**. No cache directory, no payload, nothing
> to load in any session, ever. That is why the query above now checks the path instead of only the fields:
> a record is a claim, not evidence.
>
> Every angle you would normally trust says fine. The record says installed, project scope, correct sha. The
> checks that read that record agree. And the session is completely inert. So do not verify the adoption by
> the record alone — **verify it by the surface**: is `specialists-init` in your slash list, did the
> session-start hooks print anything, does Chris open the turn? `UNINSTALL.md` makes the same point from the
> other side (*"a session that loads no plugin has no hooks to complain"*), and it is the same discipline in
> both directions: absence of complaint is not evidence, because the thing that would complain is the thing
> that did not load.
>
> **What follows from this.** It is a second, independent reason why the `[NOT-INSTALLED-HERE]` marker never
> appears at a session start: not only has the state already been written away, there is **no hook running to
> report it** — the hooks ship in the plugin this session did not load.
>
> **And it settles the question this blockquote used to leave open** (inbound
> [#350](https://github.com/DaveKJohn/davekjohns-workshop/issues/350)): whether a session start makes the two
> `claude plugin` commands redundant. **It does not.** The experiment this page asked for has been run — the
> two keys, two restarts, six locations read without a single command — and the answer is that a session
> start does *half* the job: it registers the marketplace and writes a complete, correct-looking record, but
> never fetches the payload. `marketplace update` + `install` are the pair that does. So the commands stay,
> and now for a measured reason rather than caution.

**Step 2 — run the bootstrap skill.** In the new session, invoke `specialists-init`. It sets up —
purely additively, without overwriting anything — the **lens-only** persona lenses (including
Chris) + an empty repo-lens scaffold per specialist in **the seam**
(`.claude/specialists/lenses/`), one `@`-import at the bottom of your `CLAUDE.md` pointing at that
seam (which in turn imports Chris's portable body from the plugin install + his repo lens), and a
proposal for safety settings (`settings.suggested.jsonc`, for your own
review). The details of this path are in the
[family README › Adoption](README.md#adoption-the-bootstrap-path) — which counts the steps there
as "step 0" (enabling + installing, above) and "step 1" (the skill).

**What it should report, so you can check it rather than trust it** (inbound
[#337](https://github.com/DaveKJohn/davekjohns-workshop/issues/337)). With only the core `specialists`
plugin enabled, the closing line reads:

```
Done: 4 persona-lens(es) created, 0 already present; 15 lens-scaffold(s) created, 0 already present;
2 script-scaffold(s) created, 0 already present.
```

**4 personas + 15 subagent scaffolds = 19 lens files** in `.claude/specialists/lenses/`, plus 2 script
scaffolds and 1 `@`-import. Those figures used to appear only in the skill's own `SKILL.md`, which a reader
sees *after* invoking it — i.e. after the moment they would have needed them. This page is meticulous about
counting everywhere else (*"the count is part of the check, not a detail"*, two steps up), and this was the
one step where the script prints numbers with nothing to compare them against.

**Read each pair as `created + already present`, not as a fixed number.** The sum is what this page
promises; the split depends on what your repo already had. A **fresh** repo — this step's own audience —
gets everything under `created`, which is the sample above. A repo that already had, say,
`scripts/repo-config.ps1` sees that one move to `already present` instead. So a figure that is *higher*
than the sample is not an error, and neither is one that is lower: what matters is that each pair adds up
and that the skill names anything it skipped. If you enabled a domain group as well, expect its
specialists on top of these.

> The sample above was itself the finding: until August 2, 2026 it showed `0 script-scaffold(s) created,
> 2 already present` — captured in a repo that already had them, and therefore inverted for exactly the
> fresh-repo reader this section was written for (inbound
> [#358](https://github.com/DaveKJohn/davekjohns-workshop/issues/358)). The guidance covered only the
> "lower than this" direction, so the one number that could not match had no explanation.

**And one thing it does that no document mentioned:** every file it writes uses **LF** line endings and
`CLAUDE.md` gets **no trailing newline**, on Windows too. Harmless while nothing is committed, but on a repo
whose files are CRLF this is the same class of lasting diff that `claude plugin install` is warned about a
few paragraphs up — and the missing final newline turns any later hand-edit of `CLAUDE.md` into a two-line
diff. If your repo cares, normalise once after the bootstrap.

**Step 3 — restart and verify.** Start again and check that Chris takes the floor. What that looks
like: the turn **names the specialist the work belongs to, and why**, before doing it — Chris's ritual
step is *"This one is for \<name\> — \<reason\>."* So on an ordinary request you should see something
like:

```text
**This one is for Rebecca (Research Specialist)** — "what's in this repo" is internal repo
exploration, her domain.
```

**Check for the invariant, not for a fixed string** (inbound
[#361](https://github.com/DaveKJohn/davekjohns-workshop/issues/361)). A named owner with a stated reason
is what the persona guarantees and what proves the orchestrator loaded; the exact shape is not fixed.
Some repos add a house style on top — a fixed header line per turn, emoji and all — but that is a rule
those repos write into their own `CLAUDE.md`, not something this plugin ships. Until August 2, 2026 this
step told you to look for `🧭 Chris — intake & routing`, which no bootstrapped repo emits: a
verification a fresh consumer could not pass, on the step that exists to prove the install worked.

Then, at your own pace, fill in the repo lenses in the seam (`.claude/specialists/lenses/`): that is
where you tell each specialist what it serves in your repo. The worker specialists can be invoked
directly as `@specialists:<name>`.

## Staying up to date

Updates are *announced* via **releases** — the version bump, the notes, the `RELEASE.md` card — and
getting one takes **two** commands, from your repo's root. What actually lands in your cache is a
different question, answered under [the version is not the code](#staying-up-to-date) further down: the
clone these commands read tracks `main`, not the tag.

```powershell
claude plugin marketplace update davekjohns-workshop          # 1. refresh the marketplace cache
claude plugin update specialists@davekjohns-workshop --scope project   # 2. then update, per plugin
```

**Keep line 1 in the procedure — and here is exactly what each command was measured to do, because
the two differ and an earlier version of this page generalised them.**

- **`install` does not refresh the cache, and that is now measured twice.** First on July 30, 2026,
  minutes after `v3.0.2`: the cached clone still sat on the pre-release commit, so a fresh
  `claude plugin install … --scope project` produced **3.0.1**. Reproduced on July 31 right after
  `v3.0.5` was tagged, deliberately and as a **controlled pair on the same machine within the same
  minute**: without the refresh the install produced **3.0.4** and left the clone exactly where it was,
  and with the refresh a second fresh folder produced **3.0.5**. So the refresh is what makes the
  difference for this verb — nothing else.
  **And the output cannot warn you, even in principle:** `✔ Successfully installed plugin:
  specialists@davekjohns-workshop (scope: project)` names the scope and **no version at all**. The
  install record is the only place the version appears, which is exactly why the verification step in
  Step 1 queries `installed_plugins.json` instead of reading a success line.
- **`update` refreshed the cache by itself when measured.** On July 31, 2026 (CLI `2.1.220`), with the
  cached clone verifiably still on the pre-release commit — it did not even contain the release commit
  — a bare `claude plugin update … --scope project` from a consumer's root moved `3.0.3 -> 3.0.4`, and
  the clone itself advanced to the release commit during that run. So for `update`, the explicit
  refresh was **not** required here. (The command is elided as `…` on purpose: spelled out with its
  `plugin@marketplace` target it reads as an instruction to run, which is what check 11 in the lint
  gate enforces flags on — the repo's convention for quoting a command as the *subject* of a
  measurement is the ellipsis.)

**Why line 1 stays in front of both:** for `install` it is load-bearing — skip it and you get the
previous version, twice measured. For `update` it is idempotent insurance: the `update` behaviour is one
measurement on one CLI version, and a stale cache is invisible by construction, so the procedure
guarantees freshness instead of depending on the CLI continuing to do it for you. What is *not* claimed
is that skipping it makes an `update` serve the previous version; that was a generalisation from the
`install` measurement, and it did not survive being tested.

So a version number is one of **two** gates. `claude plugin update` compares version numbers only, and
it compares them against a **cached copy** of the marketplace rather than against the workshop
directly — a copy that `update` was measured to refresh for itself and `install` was measured not to.
On what schedule the cache refreshes when nothing asks was never established, which is why the explicit
command belongs in the procedure rather than a hope that it has caught up.

**The scope flag on the second command is not optional either.** Without it the command defaults to
user scope and does not act on a project-scoped install. **What it prints depends on your CLI version,
so treat the wording as version-bound and the flag as the invariant** (inbound
[#359](https://github.com/DaveKJohn/davekjohns-workshop/issues/359)). On `2.1.220` it names the scope
and the settings file, and then suggests `claude plugin disable … --scope local` — **which is not the
step to follow**: that writes a local disable key on top of your project setting and leaves the install
in place. Earlier releases said *"Plugin `specialists` is not installed at scope user"*, literally true
and easy to misread as "not installed at all". Whatever the phrasing, the failure means the command
looked in the wrong scope. Do not answer it by re-running the install either: a scopeless install adds
a **second, machine-wide record** beside the project one. Each plugin carries its own
`CHANGELOG.md` that travels with the plugin cache and describes per release what changed for that
plugin; the full history lives in the workshop itself
([`CHANGELOG.md`](../../CHANGELOG.md) and [`releases/`](../../releases/README.md)). Each plugin
folder also carries a `RELEASE.md` card next to its `CHANGELOG.md` — open it in your plugin cache
after an update to see, at a glance, which release the card describes and what changed in it. It
does not tell you where *you* are, and since August 2, 2026 it says so rather than claiming
otherwise (inbound [#384](https://github.com/DaveKJohn/davekjohns-workshop/issues/384)); the section
directly below is the check for that.

**The version is not the code, and on this marketplace the two routinely disagree.** The cached clone
this family installs from **checks out `main` and tracks `origin/main`** — not the newest tag. So any
refresh fast-forwards it to `main` and the install copies *that* tree, while `plugin.json` still carries
whatever version the last release bumped it to. Every commit merged after a release therefore ships to
consumers immediately, under the previous release's version number.

Measured twice, from both directions (inbound
[#313](https://github.com/DaveKJohn/davekjohns-workshop/issues/313), July 31 – August 1, 2026, CLI
`2.1.220`):

- **Without a command.** A consumer moved `3.0.6 → 3.0.8` on its own and landed on `main`, three commits
  past the `v3.0.8` tag. `version` read `3.0.8`; `gitCommitSha` was the fold commit of a PR merged after
  the release. The payload genuinely differed — the same `SKILL.md` hashed differently on the tag and in
  the installed cache — and `3.0.7` was never cached at all, so that release's fixes were skipped over
  entirely.
- **With the documented commands.** The two-command procedure at the top of this section, run
  deliberately in the workshop repo, produced exactly the same state: `version 3.0.8`, sha on `main`. So
  this is not an artefact of some unknown scheduler — **the documented update path cannot deliver a tagged
  release**, because the source it reads is a branch.

What that means for you, plainly: the version number tells you which release notes to read, and the sha
tells you which code you are running. Only the second is the truth about your session. Two practical
consequences — the family's own measuring discipline of *"pin source locations against the release tag"*
does not hold in a consumer, so pin against the sha your record names; and a bug you cannot reproduce
against the tag may still be real, because you were never on it. What remains genuinely unestablished is
what *triggers* the unasked refresh — that a refresh moves you to `main` is settled, when one happens by
itself is not.

**One part of what your session loads is not covered by that sha at all: the persona bodies** (inbound
[#330](https://github.com/DaveKJohn/davekjohns-workshop/issues/330)). Look at the imports
`specialists-init` writes into `.claude/specialists/SPECIALISTS.md` and you will see they point into
`~/.claude/plugins/marketplaces/<marketplace>/…`, **the clone** — while your install record's `installPath`,
`version` and `gitCommitSha` describe a different directory, the version-pinned copy under
`…/plugins/cache/<marketplace>/<plugin>/<version>/`. The two were hash-identical when this was measured, so
there was no divergence to see; they are simply not the same source, and nothing keeps them in step. A
`marketplace update` fast-forwards the clone — and therefore the body your next session loads — while
`version` and `gitCommitSha` do not move, because the refresh does not touch the cache.

**This is deliberate, and worth knowing before anyone "fixes" it.** The import points at the clone because
that path is *durable*: the version-pinned cache directory is cleaned up after an update, so an import into
it would leave the orchestrator's body failing to load at all after your first refresh. A stale-but-loading
body beats a pinned-and-gone one. The cost is this asymmetry, and the honest statement is that
`gitCommitSha` is the truth about the payload the record names, not about every file your session reads.
If a persona behaves differently from what the release notes describe, the clone is where to look:
`git -C "$env:USERPROFILE\.claude\plugins\marketplaces\<marketplace>" rev-parse HEAD`.

**Read your install record rather than assume it, because it can move — or be taken away — without you
asking** (inbound [#296](https://github.com/DaveKJohn/davekjohns-workshop/issues/296) and
[#301](https://github.com/DaveKJohn/davekjohns-workshop/issues/301)). Project scope gives your repo its
own record; it does not freeze it, and it does not guarantee it will still be there tomorrow.

- **It moves.** Measured July 31, 2026: both project-scoped records of a real consumer went
  `3.0.4 → 3.0.5` in a **single** write, timestamps 70 ms apart, while that repo's session ran no
  `claude plugin` command at all — checked afterwards against every session transcript on the machine for
  that day.
- **It can be taken.** Same day, reproduced **twice**: a *session start* in an unrelated directory
  rewrote this file and **adopted an existing record**, leaving the repo it belonged to with no install.
  Once the victim was a real consumer; once it was the workshop repo itself. The `installedAt` stamps are
  the proof — the CLI sets that to *now* on a real install, so a record carrying an older repo's stamp was
  not created where it ended up.

**The second one is the expensive one, because nothing tells you.** No command was run, no file in your
repo changed, `git status` is clean — and a session that loads no plugin has no hooks to complain,
because the hooks are *in* the plugin. So it looks exactly like a session where everything is fine.

Since `v3.0.7` the checks run the `projectPath` query for you and say
`[NOT-INSTALLED-HERE]` when an enabled plugin has no record for this path; the workshop's connector check
says it about each registered consumer, which is the vantage point that still works when a consumer has
gone quiet. **Do not expect that line at a session start, though, and this is measured rather than
assumed** (inbound [#314](https://github.com/DaveKJohn/davekjohns-workshop/issues/314)): a session start
*writes the missing record itself*, so by the time any hook can look the state has healed. Run against
exactly that fixture — three plugins enabled, one with no record anywhere on the machine — the hook
printed the line on no branch at all. It is reachable by a **deliberate** run in a repo where a record
went missing and no session has started since, and from the workshop about a consumer. What survives a
session start is a record of the wrong *shape*, which since `v3.0.9` the checks report as
`[RECORD-SHAPE]`: `local` where this family assumes `project`, or two records where it assumes one. None of this is a reason to avoid project scope — it is a reason not to treat "the version I
installed" as a lasting fact. The `projectPath` query from
[Step 1](#connecting-in-three-steps) is the answer to *"what am I actually running?"* — not the last
release notes you read, and not the install output, which names no version at all. If it comes back
empty, re-install from that root — and note that this is the case where the install **adds
`enabledPlugins`** rather than merely reformatting it (see [Step 1](#connecting-in-three-steps)).

**Check that query again *after* a repair install, because the repair can leave two records where you
wanted one.** Measured in `DaveKJohn/life-hub` on July 31, 2026, CLI `2.1.220` (inbound
[#315](https://github.com/DaveKJohn/davekjohns-workshop/issues/315)): re-installing at project scope
against a path that already carried a record **added a second one beside it** instead of correcting it,
reporting `✔ Successfully installed … (scope: project)` both times. Two lines for one plugin is not a
display quirk — it is the stray second record, and the count in that query is the only signal you get.

**And there is a third scope this family's documents had not accounted for: `local`.** The CLI does name
it — re-measured on August 1, 2026, CLI `2.1.220`, and worth stating precisely because an earlier version
of this sentence claimed the opposite: `install`, `uninstall` and `disable` each print
*"user, project, or local"* in their own `--help`, and `update` prints a fourth, `managed`. So the flag
list was never the gap; **these pages were**, which is why the state was met by a reader with nothing to
look it up in. It is what a *session start* writes — enabling a plugin is enough for one to create a missing record, and to flip an existing
`project` record to `local`, with no command run, no file in your repo changed, and nothing reporting it
(inbound [#314](https://github.com/DaveKJohn/davekjohns-workshop/issues/314)). Two consequences worth
holding on to: the "enabled but not installed" state **heals itself**, so a check that looks for it will
usually find nothing rather than confirm health; and the state you are actually left in is `local`, which
the rest of this family's documents do not assume anywhere. Remove such a record with `claude plugin
uninstall <plugin>@<marketplace> --scope local` — at `--scope project` it refuses with *"Plugin … is
installed in local scope, not project"*, literally true and easy to misread as "not installed at all" —
then re-install at project scope from the repo root, refresh first. That `uninstall` also writes
`"enabledPlugins": {}` into `.claude/settings.local.json`, the same way the project-scoped one does in
`.claude/settings.json`.

When an update adds a **new specialist**, your repo's roster (the specialists table in your
`CLAUDE.md`) and its lenses don't update themselves. The `roster-sessioncheck` SessionStart hook
flags at session start any enabled agent that is missing from your roster **or** has no repo-lens;
run the `sync-roster` skill to stage the catch-up — it creates the missing lens scaffold and
proposes a roster row for you to review. It never edits your `CLAUDE.md` or commits: you place the
change on a branch under your own governance. You can also run
`scripts/sync/check-roster-sync.ps1` yourself for the full report.

When an update adds a **new skill**, restart your Claude Code session before you go looking for it.
`/reload-plugins` and `/reload-skills` only reload the skill set that is already loaded, not a new
skill file from an updated plugin version. So a slash command that did not exist in the previous
release stays absent until you restart — `claude plugin update`'s own `Restart to apply changes.` is
literally true here. Don't trust the skill counter those two commands print as evidence either way:
it excludes any skill with `disable-model-invocation: true`. Several of `specialists`' own skills
(`cut-release`, `fold-changelog`, `open-pr`, `park`) are slash-only for exactly that reason, so an
unchanged count, or even `0 skills`, proves nothing about whether a new skill has actually landed.
The only reliable check is the slash list itself.

## Getting out again

Adoption is reversible by design, and the procedure has its own page: **[UNINSTALL.md](UNINSTALL.md)** —
the mirror of this one. Two things from it are worth knowing *before* you adopt rather than after. The
removal is **two** removals, out of your repo and off your machine, and they are done in that order
because the teardown skill ships inside the plugin you would be uninstalling. And if you build on the
shared workflow scripts, that dependency is not something a teardown can undo for you — the page says
what to do about it while you still can.

## Reporting back or improving something

- **An improvement to the shared core** (an agent def, playbook, persona, or skill): don't
  rework it locally, but report it as an issue on this repo with the label `inbound` — an
  [issue template](../../.github/ISSUE_TEMPLATE/inbound-improvement.md) is ready for that. The
  workshop processes it through its own chain, and the improvement comes back to all consumers via
  a release.
- **Repo-specific additions** belong in your own repo lenses in the seam
  (`.claude/specialists/lenses/`) — those are yours and do not travel with the plugin.
