# 2026-08-12 — Nightly extraction run: queue needs human attention

## Outcome

No extraction performed. No records created, no queue entries changed.

## Reason

Per EXTRACTION.md §6 and the routine's step 3: scanned `extraction_queue.yml`
top to bottom. Every unit through `foxford-folklore-texts` (completed
2026-08-10) has `status: done`. The next and final entry, `tourmakeady-scoping`,
still has `status: needs_scoping` — there is no `pending` entry anywhere in the
queue, and the first non-done entry is `needs_scoping`, which is an explicit
stop condition ("Routine must STOP here and report until this is scoped.").

This is unchanged from the 2026-08-11 run: no new units were appended, and no
change was made to the `tourmakeady-scoping` entry itself. The routine did not
warm the app or touch the mayo-irish-app MCP tools, since no write was going
to happen regardless of connector state.

## What's needed

A human/interactive session to scope `scans/tourmakeady/` per the entry's own
note:
- Inventory `tourmaceady_1.pdf` (19pp), `tourmaceady_2.pdf` (21pp),
  `tourmaceady_3.pdf` (21pp), `tourmaceady_4.pdf` (29pp),
  `tourmaceady_part1.pdf` (8pp), and `tourmaceady_201.docx`.
- Determine each file's format (real PDF vs. ZIP-of-JPEGs, per EXTRACTION.md
  §1's historical caveat) and map printed page ranges / chapter structure.
- Decide unit boundaries and the #vs-erris comparison tagging strategy.
- Append scoped `T-*` units to `extraction_queue.yml` with `status: pending`
  so the nightly routine can pick them up.

## Follow-ups noted by prior runs, still open (informational only)

These were flagged by earlier completed units and remain unactioned — listed
here for visibility, not acted on by this run (out of scope, no queue entry
covers them):

- `erris-singular-flexions-summary` (2026-08-09): duplicate grammar_rules
  1-6 on lesson 133 (ids 168-173 and a second set 174-179) — pre-existing
  duplication, needs human dedup review.
- `foxford-folklore-texts` (2026-08-10): `scans/foxford/...pdf` covers only
  printed pp.171-184, not the "full book" EXTRACTION.md §1 describes;
  EXTRACTION.md needs correction, and a human should check whether pp.171-182
  material already exists in the app before scoping a next Foxford unit. Also
  an untitled milk-cow folklore item opening p.183 (continuing from p.182)
  was left unextracted, noted in lesson_block 174.
- Several prior units flagged individual records `for human deletion`
  (create-only pipeline, no delete tool) — see each unit's own report for
  ids: erris-initial-mutation (grammar_section 399), erris-consonant-phonemes
  (sections 430/433/436/444, phrase 22), erris-historical-consonants
  (grammar_section 493), erris-historical-interchange (sections 508/511,
  vocabulary_item 4407), foxford-folklore-texts (text_passage 65).

## Next scheduled run

Will re-check the queue head again next cycle; nothing to do until
`tourmakeady-scoping` is resolved by a human or a new `pending` unit is added
above it.
