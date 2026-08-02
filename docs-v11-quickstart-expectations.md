### QUICKSTART's checks are ones a fresh consumer can actually pass · Docs · 2026-08-02

Four findings from test round v11, all in `QUICKSTART.md`. Three are the same class — a captured sample
presented as a fixed expectation without naming what it was bound to — and the fourth is a verification
that reported green on a state that was not.

**The `projectPath` query passed while nothing was installed** (inbound #355). Measured on a fresh
profile after three session starts and zero `claude plugin` commands: the record read `project 3.1.0`
with the correct sha, the page's own query returned a clean line, and `installPath` pointed at a
directory that did not exist. No cache, no payload, three consecutive sessions that loaded nothing. The
query now resolves `installPath` and prints `payload present` or `PAYLOAD MISSING` as a fourth field, so
a record cannot pass as evidence of a payload — verified in both directions before shipping. The `#327`
blockquote said the payload "sat in the cache", i.e. one notch better than what v11 actually found; it
now carries both measurements.

**That same round settles the question the blockquote left open** (inbound #350). The experiment this
page prescribed has been run, and the two `claude plugin` commands are **not** redundant: a session start
registers the marketplace and writes a complete, correct-looking record, but never fetches the payload.
`marketplace update` + `install` are what do. The commands stay, now for a measured reason rather than
caution.

**The expected bootstrap `Done:` line was captured in the wrong kind of repo** (inbound #358). It
promised `0 script-scaffold(s) created, 2 already present`, which is what a repo that *already had* those
scaffolds prints. A fresh repo — this step's own audience — gets the inverse. The sample is now the
fresh-repo one, and the guidance covers both directions instead of only "lower than this": each pair
reads as `created + already present`, and the sum is what the page promises.

**Step 3 told you to look for a header no bootstrapped repo emits** (inbound #361). It asked the reader
to confirm `🧭 Chris — intake & routing`. Neither the portable persona nor `specialists-init` writes any
such rule — the persona guarantees *"This one is for \<name\> — \<reason\>."*, which is exactly what the
round measured. So the behaviour was correct and the acceptance check was unpassable, on the step that
exists to prove the install worked. The check is now the invariant (a named owner with a stated reason),
with a sample marked as illustrative and a note that a fixed per-turn header is a house style a repo
writes into its own `CLAUDE.md`, not something this plugin ships.

**The predicted scopeless-uninstall error was stale** (inbound #359, the "Staying up to date" half; the
`UNINSTALL.md` half shipped in #366). On CLI `2.1.220` the message names the scope and the settings file
and suggests `plugin disable --scope local`, which is not the step to follow. Quoted as version-bound,
with the flag named as the invariant.
