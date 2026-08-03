# Quickstart — the commands, and nothing else

**This page is the short one.** Two settings keys, four commands, one verification query, two
restarts. Every caveat, every measurement and every failure mode behind them lives in
**[ADOPTION.md](ADOPTION.md)** — the full adoption manual, and the page this one used to be.

> **Take the long page instead if any of this is true**: this is a machine that has adopted the
> family before (a leftover user-scope marketplace makes half of Step 1 silently unnecessary —
> [which of the three machine states are you in?](ADOPTION.md#which-of-the-three-machine-states-are-you-in));
> it is a fresh Windows profile ([before you start](ADOPTION.md#before-you-start) — the execution
> policy alone will stop you); or **you are an agent executing this for someone**
> ([where it has to stop](ADOPTION.md#if-an-agent-is-doing-this-for-you--where-it-has-to-stop) —
> two of these acts are ones you structurally cannot perform).

## Step 1 — enable and install

**1. Write your repo's own `.claude/settings.json`** (create `.claude/` beside your `README.md` if it
is not there). A complete, pasteable file; if you already have one, merge these two keys into it.
Strict JSON — no comments, no trailing commas. Add a line per domain group you want.

```json
{
  "extraKnownMarketplaces": {
    "claude-code-specialists": {
      "source": { "source": "github", "repo": "DaveKJohn/claude-code-specialists" }
    }
  },
  "enabledPlugins": {
    "specialists@claude-code-specialists": true
  }
}
```

**2. Restart your Claude Code session.** A session start is what registers the marketplace; without
it, the next command fails with `Marketplace … not found`.

**3–4. Refresh, then install — from your repo's root, one install per plugin you enabled.**

```powershell
claude plugin marketplace update claude-code-specialists                     # never skip: install does not refresh
claude plugin marketplace list                                               # came the entry from YOUR repo's settings?
claude plugin install specialists@claude-code-specialists --scope project    # once per plugin
```

`--scope project` is not optional — without it the install goes machine-wide and writes no
`projectPath`, with no error.

**5. Restart your Claude Code session again.**

**6. Verify — from your repo's root.** The install output names no version at all, so this query is
the only place your version is written down.

```powershell
$root = (Get-Location).Path
(Get-Content "$env:USERPROFILE\.claude\plugins\installed_plugins.json" -Raw | ConvertFrom-Json).plugins.PSObject.Properties |
  ForEach-Object { $n = $_.Name; $_.Value | Where-Object { $_.projectPath -eq $root } |
    ForEach-Object {
      $payload = if ($_.installPath -and (Test-Path -LiteralPath $_.installPath)) { 'payload present' } else { 'PAYLOAD MISSING' }
      "$n -> $($_.scope) $($_.version) $($_.gitCommitSha) [$payload]" } }
```

**One** `project` line per plugin, ending in `payload present`. The count is part of the check.
Anything else — empty output, two lines for one plugin, `local`, `PAYLOAD MISSING` — is covered in
[ADOPTION.md](ADOPTION.md#connecting-in-four-steps).

## Step 2 — run the bootstrap skill

In the new session, invoke `specialists-init`. It places the persona lenses, an empty lens scaffold
per specialist, two script scaffolds, one `@`-import in your `CLAUDE.md` and a settings proposal —
purely additively, in seconds. Check its closing `Done:` line against
[what it should report](ADOPTION.md#connecting-in-four-steps).

## Step 3 — restart and verify

Restart once more and check that Chris takes the floor: the turn **names the specialist the work
belongs to, and why**, before doing it. Look for that invariant, not for a fixed string.

## Step 4 — write the roster and fill the lenses

**This is the big one, and it is not optional.** Steps 1–3 give you a team that knows its craft and
nothing about your repo; the lenses in `.claude/specialists/lenses/` are where you say what each
specialist serves *here*, and an unfilled lens does nothing. Budget writing time, not typing time —
[Step 4 in ADOPTION.md](ADOPTION.md#connecting-in-four-steps) states the cost and the two things that
reliably surface while you do it.

## Staying up to date

Two commands, from your repo's root, one pair per plugin:

```powershell
claude plugin marketplace update claude-code-specialists
claude plugin update specialists@claude-code-specialists --scope project
```

Same scope flag, same reason. **The version number is not the code** — the clone these commands read
tracks `main`, not the tag, so your `gitCommitSha` is the truth about your session and your `version`
only tells you which release notes to read. A new *skill* needs a session restart before it appears;
a new *specialist* needs a roster and lens catch-up (`sync-roster`). Your install record can also
move, be adopted by another directory, or be orphaned by renaming your checkout, all without you
asking. All of that, measured:
[Staying up to date in ADOPTION.md](ADOPTION.md#staying-up-to-date).

## Getting out again

Adoption is reversible by design: **[UNINSTALL.md](UNINSTALL.md)**. Two removals, out of your repo
and off your machine, in that order — the teardown skill ships inside the plugin you would be
uninstalling.

## Reporting back

An improvement to the shared core (an agent def, playbook, persona, or skill) is not reworked
locally: file it as an issue on this repo with the label `inbound` — there is an
[issue template](.github/ISSUE_TEMPLATE/inbound-improvement.md). Repo-specific additions belong in
your own lenses, which do not travel with the plugin.
