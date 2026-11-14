# Decisions

The owner's yes/no decisions on proposals, newest first. The architect reads
this every run so it learns what the owner wants and doesn't re-propose
rejected ideas. The architect appends entries from issue activity (approved =
`approved` label; rejected = closed with `rejected` label and the owner's
one-line reason as the last comment). The owner can also edit this file
directly to state standing preferences.

## Standing preferences

- Pace (owner, 2026-11-14): continuous. Keep building small steps toward
  `VISION.md` without waiting; this replaces "steady, not hectic".
- Dialect content is the owner's domain; the app's job is to present it
  brilliantly.
- Merge on green CI; destructive data changes always need the owner. No
  feature flags while the app is a private beta (owner, 2026-11-12): changes
  go live on merge. Revisit when it opens to the public.
- Dependencies (owner, 2026-11-12): patch bumps merge on green, and minor
  bumps are checked against the changelog and merged. Major bumps are prepared
  by the builder with every change the upgrade needs and tests added where
  missing; dev and test-only dependencies and GitHub Actions then merge if the
  suite is green, and everything else waits for the owner's review.
- Learner progress (owner, 2026-11-12): first-party tracking of each
  learner's vocabulary, listening, speaking and grammar from what they do, for
  the purposes in `VISION.md`, is approved in principle and counts as tier 2.
  Analytics or tracking for any other purpose, anything shared with third
  parties, and collecting anything beyond what helps learning still needs my
  yes. (Since 2026-11-14 this is no longer a stop: see Autopilot below. The
  `VISION.md` limits still apply: collect only what helps learning, share
  nothing with third parties.)
- Autopilot (owner, 2026-11-14, supersedes the 2026-11-12 list): the
  architect proposes, the builder builds and merges and picks its own next
  steps, and the owner only intervenes at two stops, both in `CADENCE.md`:
  (1) a change that could mutate existing data (destroying or changing user
  or course data; adding keys, relations, tables or columns does not count),
  which is asked about first; (2) the agents are out of ideas or development
  has reached its logical end for now, so they ask for new direction. New
  third-party services, cost, auth/MCP permissions and similar no longer wait
  for a yes. The limits in `VISION.md` (no invented Irish, no manipulation,
  collect only what helps learning) still apply.

## Log

<!-- - YYYY-MM-DD #<issue> <title> — approved | rejected: <reason> -->
