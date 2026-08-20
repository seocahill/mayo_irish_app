# 2026-08-20 — Nightly extraction run: queue needs human attention

## Outcome

No extraction performed. No records created, no queue entries changed.

## Reason

Per EXTRACTION.md §6 and the routine's step 3: scanned `extraction_queue.yml`
top to bottom. Every unit through `erris-verbs-ii-irregular-copula` (completed
2026-08-19) has `status: done`. The next and final entry, `tourmakeady-scoping`,
still has `status: needs_scoping` — there is no `pending` entry anywhere in the
queue, and the first non-done entry is `needs_scoping`, which is an explicit
stop condition ("Routine must STOP here and report until this is scoped.").

Note for context: the queue was briefly unblocked between 2026-08-16 and
2026-08-19, when a human/interactive session had scoped and appended four new
`pending` Erris units on 2026-08-15 (`erris-nouns-adjectives-numerals`,
`erris-pronouns-prepositions`, `erris-verbs-i-conjugation-classes`,
`erris-verbs-ii-irregular-copula`) above the `tourmakeady-scoping` entry; the
nightly routine consumed all four on consecutive nights. With that batch now
exhausted, `tourmakeady-scoping` is once again the first non-done entry, so
this run is blocked exactly as the five runs of 2026-08-11 through -15 were.

App warm-up: attempted `GET https://mayo-irish-app.fly.dev/` 5 times over
~2 minutes; all attempts failed with `curl: (56) CONNECT tunnel failed,
response 403`. This is the same sandbox network policy denial (not an
app-sleep issue) reported in every prior run since 2026-08-04. Since the
queue was blocked on `tourmakeady-scoping` regardless, no write via the
mayo-irish-app MCP connector was attempted this run.

## What's needed

A human/interactive session to scope `scans/tourmakeady/` per the entry's own
note (unchanged since 2026-08-11):
- Inventory `tourmaceady_1.pdf` (19pp), `tourmaceady_2.pdf` (21pp),
  `tourmaceady_3.pdf` (21pp), `tourmaceady_4.pdf` (29pp),
  `tourmaceady_part1.pdf` (8pp), and `tourmaceady_201.docx`.
- Determine each file's format (real PDF vs. ZIP-of-JPEGs, per EXTRACTION.md
  §1's historical caveat) and map printed page ranges / chapter structure.
- Decide unit boundaries and the #vs-erris comparison tagging strategy.
- Append scoped `T-*` units to `extraction_queue.yml` with `status: pending`
  so the nightly routine can pick them up.

Alternatively, per `erris-verbs-ii-irregular-copula`'s closing note (2026-08-19):
a human could scope further Erris material beyond p.216 (if any remains
outside the Index, which is permanently out of scope per EXTRACTION.md §6) or
a next Foxford unit (pp.171-182, per `foxford-folklore-texts`'s open note
below) as `pending` units, exactly as was done for the four Erris units
consumed this cycle — either would unblock the routine without requiring the
Tourmakeady scoping work specifically.

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
  vocabulary_item 4407), erris-nouns-adjectives-numerals (grammar_section 513),
  erris-pronouns-prepositions (lesson_block 178, grammar_section 539),
  erris-verbs-i-conjugation-classes (lesson_block 181),
  foxford-folklore-texts (text_passage 65).
- `erris-pronouns-prepositions` (2026-08-17): grammar_section 537 has a
  possible original typesetting slip (phonetic/gloss possessor mismatch,
  "mu dahir′" vs. "d'athair") transcribed as printed and flagged for human
  review, not silently corrected.

## Next scheduled run

Will re-check the queue head again next cycle; nothing to do until
`tourmakeady-scoping` is resolved by a human or a new `pending` unit is added
above it.
