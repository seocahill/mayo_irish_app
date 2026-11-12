# Decisions

The owner's yes/no decisions on proposals, newest first. The architect reads
this every run so it learns what the owner wants and doesn't re-propose
rejected ideas. The architect appends entries from issue activity (approved =
`approved` label; rejected = closed with `rejected` label and the owner's
one-line reason as the last comment). The owner can also edit this file
directly to state standing preferences.

## Standing preferences

- Pace: steady, not hectic. A few good changes a week beats many.
- Dialect content is the owner's domain; the app's job is to present it
  brilliantly.
- Merge on green CI; destructive data changes always need the owner. No
  feature flags while the app is a private beta (owner, 2026-11-12): changes
  go live on merge. Revisit when it opens to the public.
- Dependencies (owner, 2026-11-12): patch bumps merge on green, minor bumps
  are checked against the changelog and merged, major bumps get a PR from the
  builder with every change the upgrade needs, and wait for the owner's
  review.
- Autopilot (owner, 2026-11-12): the architect proposes, the builder builds
  and merges, and the owner only intervenes occasionally. Visible changes are
  built without approval. Only these wait for the owner's yes: new
  third-party services, anything costing money, new data collection about
  learners, auth and permissions, destructive data changes, changes to
  content records, and anything needing the owner's answer.

## Log

<!-- - YYYY-MM-DD #<issue> <title> — approved | rejected: <reason> -->
