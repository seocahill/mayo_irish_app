# Development cadence: how agents work on this app

Applies to every Claude session on this repo: the nightly builder, the weekly
architect, the watchdog, and interactive sessions. Product direction is in
`docs/product/VISION.md` (the owner's, never edited by agents).

## Development cadence (owner, 2026-11-14)

Keep improving the app toward `VISION.md` without waiting for approval. Choose
the next small step yourself, build it, test it, merge it on green CI, then
choose the next one. Small steps that each ship on their own beat big builds.

There are exactly **two** reasons to stop and ask the owner. Nothing else
needs a yes: new gems or services, UI and copy changes, new tables, columns,
keys, indexes and relations, new endpoints, auth and MCP changes the vision
calls for are all yours to decide and ship (keep them small and reversible).

### Stop 1: a change that could mutate existing data

Ask first, every time, when a change could destroy or alter data that already
exists in production: user accounts, learner progress, lessons, vocabulary,
phrases, recordings, anything a person or an extraction run put there.

Counts as mutating existing data:

- a migration that drops, renames or retypes a column or table, or that
  updates, deletes or backfills existing rows (`update_all`, `execute "UPDATE
  ..."`, data migrations, `change_column`, `remove_*`, `rename_*`)
- a rake task, console script, seed or MCP write that updates or deletes
  existing records
- code that rewrites or deletes existing records in bulk, or changes how stored
  values are interpreted so that old rows read differently
- anything you are not sure about: if in doubt, it counts

Does **not** count (just do it): adding a table, a column (nullable or with a
default), an index, a primary key, a foreign key or another relation; creating
new rows through the app's normal use; read-only reports and queries; adding
MCP tools that only read or create.

Fly runs `db:migrate` on every deploy, so a merged migration is a production
change the moment it lands. That is why this stop exists.

How to ask: open an issue titled `Data change needs your yes: <what>`,
labelled `needs-human` and `data-change`, saying in plain words which tables
and roughly how many rows change, what the change does, how to undo it
(backup or Litestream restore point), and the one-line answer needed. Open the
PR for it labelled `needs-human` and do **not** merge it. Park that item and
carry on with other work; build it only after the owner adds `approved` or says
yes in a comment. A push notification reaches the owner when a routine run
finishes; interactive sessions just ask in the chat.

### Stop 2: out of ideas, or development has reached its logical end

Before concluding this, do a real pass: the vision's Where it's going and
Current priorities, `ROADMAP.md` (Next and Later), each of the eight
architect lenses in `ARCHITECT.md` once (with fresh research), follow-ups on
shipped work, open issues and Sentry. If something worthwhile and safe remains,
build it instead.

If nothing does, open one issue titled `Direction needed: <short reason>`,
labelled `needs-human` and `direction-needed`, with: what has shipped since
the last direction, what you considered and why you dropped it, two or three
options for what could come next, and the one question to answer. While that
issue is open, do not open another and do not invent busywork: do only the
merge sweep and fixes, then finish with "Waiting for direction." When the
owner replies, treat the reply as the new steer and go on.

## Always, whatever the cadence

These come from the vision, not from a gate:

- Never invent, correct or normalise Irish dialect forms; Irish comes from the
  course material, Abairt, speakers or transcripts. The lesson conversation
  (comhrá) is the only AI-written Irish, labelled as such.
- Never merge with a failing, pending or missing check.
- No feature flags while the app is a private beta.
- Run `bin/rails test` and `bundle exec brakeman --no-pager` before opening a PR.
- Add tests with each change; take phone and desktop screenshots for UI changes.
