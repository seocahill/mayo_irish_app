# Run report — 2026-08-02

**Queue unit:** `erris-initial-mutation` ("Initial Mutation in Erris")
**Status:** STOPPED before extraction — no records created, no writes attempted.

## What happened

1. Read `EXTRACTION.md` — conventions, schema, safety rules understood.
2. Warmed the app. Direct `GET https://mayo-irish-app.fly.dev/` was blocked
   by this session's network egress policy (proxy returned 403 on every
   retry, 5 attempts over ~2 minutes — a policy denial, not an app-asleep
   symptom: `gateway answered 403 to CONNECT`). Confirmed the app itself is
   up and reachable via the `mayo-irish-app` MCP connector instead
   (`list_records` on `lessons` returned the full existing lesson set, ~90KB
   of data, no errors). Per EXTRACTION.md rule 1 ("only use the MCP tools
   after warming"), treated the successful MCP call as confirmation and did
   not attempt any other write path.
3. Opened `extraction_queue.yml`. First `pending` entry: `erris-initial-mutation`
   (pp. 170-177, §§482-495, `scans/erris_3/` spreads 20-23). Not
   `needs_scoping`, so proceeded.
4. **Blocked here.** Looked for the unit's source pages and found that the
   `scans/` directory does not exist anywhere in this checkout:
   - Not present in the working tree (`scans/`, `scans/erris_3/` — no such
     path).
   - Not present in `git log` history on this branch or `main`.
   - Not Git-LFS tracked (no `git-lfs` installed / no LFS pointers).
   - Not present anywhere else on disk in this container.

   Per EXTRACTION.md and the routine's own hard rule: *"If you cannot find
   the pages, report and stop — do not substitute other material."* Stopping
   here rather than guessing at content for §§482-495.

## Root cause (for the human)

This is not specific to `erris-initial-mutation` — **no queue unit can be
processed** until the `scans/` directory (the monograph page images listed
in EXTRACTION.md §1: `erris_front`, `erris_3`, `erris_4`, `foxford`,
`tourmakeady`) is available inside the repo that the nightly session clones.
It is currently not committed to git and not provisioned any other way
visible to this container. Every future nightly run will hit the same wall
at step 4 until this is fixed. Options: commit the scans (as a real PDF/ZIP
or via Git LFS), or provision them into the session's working directory by
some other mechanism (e.g. a setup/session-start hook that fetches them from
external storage).

## Queue / records

- No queue entry status changed (`erris-initial-mutation` remains `pending`).
- No lesson, grammar_rule, grammar_section, vocabulary_item, phrase, or
  lesson_block records created.
- `next_lesson_number` (133) not consumed.

## Transcription uncertainties

None — no source material was read.

## Records for human deletion

None.

## Suggested follow-ups

1. Add the `scans/` source images to the repository (or a fetchable store)
   so the nightly runner can actually locate pages.
2. Consider adding a step-2.5 check to EXTRACTION.md/the routine prompt that
   verifies `scans/` exists and is non-empty *before* picking a queue unit,
   so this fails fast with a clearer signal.
3. Once scans are restored, re-run this routine; `erris-initial-mutation` is
   still the correct next unit to process.
