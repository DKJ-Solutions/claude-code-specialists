## `feat/register-xoxowildhearts-workflow-slot` deployment

### What does the change on this branch deploy to main?

The workflow slot in `connectors/xoxowildhearts.json`, which that manifest deliberately left blank on
2026-08-20 -- inbound [#800](https://github.com/DaveKJohn/claude-code-specialists/issues/800), and the
follow-up the manifest's own note asked for rather than a defect report. The deferral was right and the
answer it predicted was the losing one: `feat-harness-hardening` merged as PR #7, `ad315a1` did switch the
slot to `workflow-default`, and the same day the consumer reversed it -- `463e091` adopts
`workflow-davekjohn`, `01a2723` disables `workflow-default` so exactly one workflow holds the slot. All
four commits were read in the consumer's own history rather than taken from the report, and
`extensions: []` is the measured answer: the plugin ships no `agents/` directory.

**The condition the deferral set is now measured wider than the report could.** It said to write the block
once the branch had merged, because a state about to move records an `[ERROR]` half the time. Rather than
check `main` alone, all **16** of the consumer's remote branches were read: every one carries
`workflow-davekjohn: true`, so nothing in flight moves the slot back. `check-connectors.ps1` now reports
four plugins `[OK]` for this consumer where it reported three.

**Why registering it is the repair and not a formality.** `check-connectors.ps1` loops over the plugins a
manifest *lists*, so an enabled plugin absent from that array is invisible to the version check -- and the
report walked into it: a session-start `[ERROR]` named three drifted plugins where four had drifted, and
the one it could not name was `workflow-davekjohn`, the plugin that ships `connector-sessioncheck` itself.
**Measured across all five connectors, this was the only enabled-but-unregistered plugin anywhere**, so
registering it empties the class. The asymmetry is named and not repaired: the analogous case one level
down -- a lens present but unregistered -- already prints an `[INVENTORY]` line, and the plugin level has
none. A risk whose population is now zero gets written down, not built.

**And the recount found more than the issue asked about, which is the half worth reading.** #800 asked for
one block. Verifying the manifest around it showed that **all three** "differences" it records for this
consumer had become false, each overtaken by the very branch the slot note named as in-flight:

| the manifest said | measured 2026-08-21 |
|---|---|
| no `CHANGELOG.md` at all, a flat `update_log.txt` | `CHANGELOG.md`, 15 `##` sections, the workflow's own intro (`8541994`) |
| has not adopted `workflow-davekjohn/` | present and fully scaffolded -- `branch/`, `prompts/`, `releases/`, three docs |
| lint gate at `--fail-level crash`, 1504 pre-existing offences | `--fail-level error` since `ad315a1`, green on five consecutive runs |

They are corrected in the same change, because a register whose whole purpose is to record what a consumer
**has** cannot carry three claims it no longer has while a fourth accurate one is added beside them. One of
the three also carried a wrong reading of inbound #763 -- it recorded that the missing-folder `[ERROR]` had
been answered by disabling the hook's own plugin, and the consumer did the opposite and adopted the folder.

**Score:** 3

#### What makes this change extra special

Nothing here travels to a consumer -- the register lives in the source and only this repo can write to it,
which is why the issue placed no bridging note anywhere. What travels is the shape of the mistake, and it
is the one the workflow's own folder page already warns about in a different document: **a stale line
copied forward becomes a false line.** Every one of those three claims was true when written. Each was
measured against `main` on a day when a named, in-flight branch was about to change the answer -- the same
branch the slot note was deliberately waiting on -- and none was re-read when it merged. So the note that
correctly deferred the one field it knew would move sat directly above three fields that moved for exactly
the same reason.

The transferable rule is narrower than "re-verify everything": **when you defer one field because a branch
is in flight, the other fields that branch touches are deferred too, whether or not you wrote them down.**
Waiting on a branch and then reading only the field you were waiting on is how a record ends up
three-quarters wrong while its one careful sentence looks like diligence.

**Score:** 2

### Pull Request

the register records xoxowildhearts' workflow slot
