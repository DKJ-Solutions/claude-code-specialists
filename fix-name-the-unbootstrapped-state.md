### A repo that was never set up is told so, instead of shouted at 44 times · Fix · 2026-07-29

Resolves [#225](https://github.com/DaveKJohn/davekjohns-workshop/issues/225). Dave's bar: a consumer
may still have work to do after installing, **as long as they are told**. Measured before the change
(PR #224), a fresh consumer got **44 `[ERROR]` lines** at session start and **zero** mentions of the
skill that resolves them — which reads as "this plugin is broken", not "you are not done yet". One
channel actively said *"no action is needed on your side."*

The root cause was a distinction the checks could not make: **drift reporting is right for a
bootstrapped repo and wrong for one that was never set up.** A repo with no lenses and no roster rows
has every enabled specialist "missing" twice over, which is not 38 findings — it is one.

Both checks now detect that state and emit a single non-counting **`[BOOTSTRAP]`** marker naming
`specialists-init`, and both hooks give it **its own verdict** rather than folding it under an existing
one. It arrives on an exit-0 run, so without a dedicated branch it would have fallen through to
"roster in sync with the enabled plugins" — a flat untruth for a repo that has no roster.

| a fresh consumer sees | before | after |
|---|---|---|
| `[ERROR]` lines at session start | **44** | **0** |
| lines naming `specialists-init` | **0** | **2** |

**The predicate is deliberately strict, and that is most of the work.** Only *neither lenses nor roster
rows* counts as never-bootstrapped; a repo with one half is a maintained repo that has drifted and must
keep erroring. Same for the contract check: one lib present means real drift, all absent means not set
up. Both directions are asserted, because a fix like this earns its keep by *not* swallowing genuine
findings.

**Also fixed: remediation pointers that named paths the reader does not have.** The hooks told
consumers to run `scripts/sync/check-roster-sync.ps1` and `scripts/sync/check-script-contract.ps1` —
repo-relative paths for scripts that ship in the plugin. Same class as the v2.11.0 fix ("consumer
messages stop pointing at the workshop"); these were remaining instances. The roster hook now names the
`sync-roster` skill, and the contract hook drops the pointer entirely since its findings already name
every function and its file.

**Honest about what is not fixed.** After a *correct* bootstrap the count is still **21**: three are
[#226](https://github.com/DaveKJohn/davekjohns-workshop/issues/226) (the bootstrap's own scaffolds
failing the plugin's own contract check) and eighteen are the roster rows the owner genuinely has to
add. Those eighteen now carry an actionable pointer instead of a path that does not exist, so the state
meets Dave's bar — but 18 lines is a lot of red for someone who just followed the instructions, and
that is worth revisiting once #226 lands.

Two engineering notes recorded in
[Sylvester #15's lens](.claude/plugins/claude-specialists/specialists/05-15-extension.md). The
non-counting marker is now a **standing pattern** rather than a fourth exception — `[ORPHANS]`,
`[UNREGISTERED]`, `[INVENTORY]`, `[BOOTSTRAP]` all answer the same problem, and the recipe is written
down so a fifth case reaches for it instead of inventing a shape. And: a repo-wide verdict must be
computed where the evidence is complete, not where it is cheapest. The first implementation
short-circuited before plugin resolution and immediately mistook *plugin not installed on this machine*
for *repo not set up* — two states that need opposite advice. The suite caught it in one run, which is
the argument for landing the guard case in the same commit as the feature.
