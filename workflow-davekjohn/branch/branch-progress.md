## `fix/permission-rule-form` progress

### Steps

#### PLAN

- [x] Establish that the existing rule is dead as written: it exists, and the cut was refused anyway
- [x] Check whether `/permissions` had persisted anything -- it had not, those grants were session-only

#### CREATE

- [x] Add the four rules in the form actually invoked, keeping the existing one
- [~] The eight same-shaped rules in `settings.local.json` -- dropped: gitignored and machine-local,
      so Dave's to edit, not this branch's. Recorded in the entry as an observation instead

#### TEST

- [x] JSON valid, no duplicate rules, `enabledPlugins` and the marketplace source untouched
- [~] Prove the rules fire -- dropped: the same actions were granted by hand for this session, so
      any run now is confounded. The first fresh session is the measurement, and the entry says so

### Where I left off

Settings edit made by Dave (the assistant is refused on permission files, by design); entry written,
shipping it.
