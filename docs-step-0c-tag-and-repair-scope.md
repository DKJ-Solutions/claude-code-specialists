### Step 0c: an executable version check and a repair warning that fits · Docs · 2026-08-01

The two remaining findings of test round v9 (#326), both in `specialists-init/SKILL.md` step 0c, on
non-overlapping lines — the grouping the dossier proposed.

**#322 — the prescribed tag comparison cannot be answered in a consumer's clone.** The step told a reader
to resolve the release tag in the cached marketplace clone and offered a binary reading: equal means the
release, different means `main`. Three measured facts about that clone break it, and this branch
**re-measured all three locally** rather than adopting them:

- it is **shallow** (`.git/shallow` present) and its fetch refspec is `+refs/heads/main:refs/remotes/origin/main`
  — `main` only, **no tags**;
- so its tag set is frozen at whatever came along with the clone. The consumer that filed the issue had
  newest tag **`v2.7.3`**; the clone on this machine has **66 tags, newest `v3.0.8`** — both serving a
  `3.0.9` payload;
- **and therefore the step's own example command succeeds on one machine and fails on the other.** Verified
  here: `rev-list -n1 v3.0.8` returned a sha, `rev-list -n1 v3.0.9` returned
  `fatal: ambiguous argument`. On the filing consumer the same `v3.0.8` line failed.

That third point sharpens the issue rather than confirming it. The finding was reported as "the command
cannot run on a consumer"; measured across two machines it is worse than that — **it is machine-dependent**.
A command that always failed would announce itself. This one answers on some machines, which means a reader
who runs it once and gets a sha has no way to know the answer was unreliable. And the failure mode inverts:
with no branch for `fatal:`, the natural reading of an error is *"not equal, so I am on `main`"*, while the
filing consumer's sha **was** the release tag's commit. The one situation the round could have confirmed as
clean was the one the procedure called unclean.

So the comparison is no longer prescribed. In its place: the clone's shape stated once, `fatal: ambiguous
argument` named as an expected third outcome that is **evidence of nothing**, `rev-parse HEAD` offered as
the narrower question that *is* answerable locally — with the honest caveat that the clone and the
version-pinned install cache in `installPath` are two different directories, so it speaks about the clone
and not the payload — and `gh api …/tags` given for identifying the release, because that is where tags
actually live.

**#325 — the repair warning fired against the safe repair.** The step warned that a project-scoped install
*"against a path that already had a record"* adds a second record instead of correcting the first. Measured
against `3.0.9`, that condition is too broad: a **same-scope** install replaces cleanly (one record, fresh
`installedAt`, and the query afterwards prints exactly the one-line green the step defines). What
accumulates is a **scope mismatch** — v8's duplicate had a pre-existing `local` record and the install added
a `project` one beside it.

The consequence of leaving it broad is the reason this counts as more than an accuracy fix: read broadly, the
warning fires against re-installing at project scope over a project record — the ordinary way to restore a
repo, and **exactly what step 0b prescribes two paragraphs earlier**. A reader who believed it had no safe
repair left at all. Both halves are now stated with their measurement, and the rule a reader can act on is
one line: read the scope of what is already there before a repair install; remove at *that* scope first, or
the install adds beside it. That also makes the fourth state consistent — a repair install against a demoted,
pathless record is itself a scope mismatch, so the duplicate would return.

The mirrored broad phrasing in `check-report-lib.ps1`'s design note was corrected in
[PR #345](https://github.com/DaveKJohn/davekjohns-workshop/pull/345), where the same lines were being
rewritten anyway; leaving a measured-false clause standing in a block that PR touched was not defensible.

**Scope checked, not assumed.** The issue states the QUICKSTART does not carry this defect because it stops
at *"pin against the sha your record names"*. Verified: it contains no `rev-list` command, so nothing there
needed changing. Lint green (including the record-query check over all three prescribed queries), all suites
green.

Plugins: specialists
