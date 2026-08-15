## `fix/bypassed-helpers-and-stale-register` changelog

### Branch title

Two shared helpers stop being bypassed, and the consumer register catches up

### Branch ID

20260815-220937

### Branch type

fix

### What does the change on this branch bring to main?

**Checks 15 and 16 were reading fences with their own pattern instead of the one function written to
own that.** `Test-FenceDelimiterLine` exists so fence syntax lives in one place — its own docstring
says so, and describes the syntax as *"three-plus backticks, optionally indented"*, which its pattern
honours by allowing leading whitespace before the backticks. Checks 4 and 10 call it. Checks 15 and 16
matched the backticks anchored at column 0 instead, with no allowance for indentation, so an indented
fence was invisible to both.

**Not hypothetical, and not yet firing.** The documents those two checks scan already contain indented
fences: `INSTALL.md:554`, `UNINSTALL.md:267` and `:468`. None of those blocks happens to hold a
measured figure today, so nothing misfires — but the day one does, check 16's in-fence flag never
toggles for it and a figure inside a code sample gets judged as prose, which check 16's own comment
says is check 15's territory and would be a double report. Both now call the shared function, and
check 15's language-tag extraction strips leading whitespace too, since it was reading the same line.

**`connectors/djcylow-react.json` made three statements about that consumer and all three were
false.** It named plugin id `specialists@claude-code-specialists`, retired in the August 3 reorg; it
said only that one plugin was enabled; and it said the consumer's `.claude/settings.json` carried no
`extraKnownMarketplaces` block. Read live from the GitHub API on the day of this change, that file
enables **team-alpha and workflow-davekjohn** and does carry the block.

**Why it had rotted unseen is the part worth keeping.** That checkout is not on this machine, so
`check-connectors.ps1` reports `[SKIP]` for it and nothing in routine tooling ever compares the record
against reality. `connectors/README.md` already names this as structural, and the register's own
doctrine — it records what a consumer *has*, so it changes when they do — is only true if somebody
looks. The note now says that out loud, so the next reader knows the record is unverified rather than
verified-and-quiet.

**Deliberately not done here: `#707`**, the second `Get-JsonField`. Victor found no live misbehaviour;
the risk is a future caller relying on a `-Default` the second copy does not have. That is a risk that
has not bitten, which this repo's standing rule says to name and leave — and every available repair
either dot-sources 1,274 lines of report machinery into a publishing script or changes the default
across eighteen call sites. The reasoning is on the issue rather than in a commit.

### Significance

#### Tier 0

The fence repair removes a bug that is real and dormant: today it produces nothing, tomorrow it
produces a false finding in a gate people trust. The register repair restores a record that three
separate statements had drifted away from.

**Score:** 3

#### Tier 2

Neither reaches a consumer directly — the lint gate is this repo's, and the register is this repo's
view of others. Scored 1 rather than N/A because the register being wrong is exactly what makes a
consumer's problem invisible from here, which is the one way this does eventually cost them.

**Score:** 1

### Pull Request

