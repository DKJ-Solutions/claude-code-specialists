## `fix/an-unmigrated-consumer-is-not-a-defect` changelog

### Branch title

A consumer registered under a retired plugin id is reported as unmigrated, not invalid

### Branch ID

20260809-132431

### Branch type

fix

### What does the change on this branch bring to main?

The connector check reported four `[ERROR]` lines against `life-hub` and `smartwatchbanden` for holding
`specialists@…` and `specialists-shopify@…` — ids that are correct for those repos, recorded on
purpose, and which `connectors/README.md` had been updated one branch earlier to say are kept
deliberately until each consumer migrates. **The check and the doctrine contradicted each other, and
the doctrine was right:** this register records what a consumer *has*.

**Three ways to miss had collapsed into one verdict.** `Get-PluginDir` returned a bare `$null` and the
caller called every case *"invalid or unknown plugin field"*. That was survivable while the lookup was
a directory probe, because the only way to miss was a name nobody publishes. Resolving through the
marketplace added a second way, and it is not a fault at all — a plugin renamed upstream leaves every
consumer holding the old id until they reinstall. The reasons are separated now:

| status | what it means | verdict |
|---|---|---|
| `malformed` | the id is not a slug at all | `[ERROR]` — a register file defect |
| `retired` | a well-formed name the marketplace no longer declares | `[INFO]` — they have not migrated |
| `no-source` | declared, but the folder is missing here | `[ERROR]` — a defect in this checkout |

An `[INFO]` is the right level rather than a softer error: the session hook surfaces only `[ERROR]`, so
this shows on a deliberate run and does not interrupt anyone's session start over the state of somebody
else's repo — the same rule the register's other administrative markers already follow.

**How it got here is the part worth keeping, because no single step was wrong.** One branch made the
check ask the marketplace instead of joining a path. A later one removed the old names from that
marketplace. A third wrote down the doctrine the check had by then been contradicting for two branches.
Each was reviewed on its own; what no review caught was the interaction between them.

The lesson is sharper than "review interactions", which nobody can act on. It is that **a document
describing a mechanism is not evidence about that mechanism.** The doctrine paragraph was written from
the design, published, and passed every gate — while the thing it described was reporting the opposite.
Nothing measured the two against each other until the check was run for an unrelated reason. That
paragraph now carries the episode, so the next person to write a rule about a check has a reason to run
it first.

### Significance

#### Tier 0

The connector check is red at every deliberate run until this lands, on four lines that are correct.
A gate that cries wolf about a correct state is one people learn to skip.

**Score:** 3

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Yes, and it is the reason the check exists at all: it is the only thing that reports on the connected
repos, and it had started reporting a normal, expected phase of a migration as a defect — precisely
during the migration it was meant to help track.

**Score:** 3

#### Tier 2

Is this next one still relevant for a consumer of the product?

No. The register and its check live in this repo and read consumers from the outside; nothing about a
consumer's own sessions changes, and no consumer runs this script. What changes is what *we* see when
we look at them.

**Score:** N/A

### Pull Request
