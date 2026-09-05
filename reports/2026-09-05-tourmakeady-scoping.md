# 2026-09-05 — Nightly extraction run: queue needs human attention

## Outcome

No extraction performed. No records created, no queue entries changed.

## Reason

Per EXTRACTION.md §6 and the routine's step 3: scanned `extraction_queue.yml`
top to bottom. Every unit through `erris-verbs-ii-irregular-copula` (completed
2026-08-19) has `status: done`. The next and final entry, `tourmakeady-scoping`,
still has `status: needs_scoping` — there is no `pending` entry anywhere in the
queue, and the first non-done entry is `needs_scoping`, an explicit stop
condition ("Routine must STOP here and report until this is scoped."). Queue
is unchanged since the 2026-08-20 through 2026-09-04 runs; nothing new to
report on that front. This is the **seventeenth consecutive nightly run**
blocked on this same entry (2026-08-20 through 2026-09-05) — seventeen days of
idle cycles since the last unit completed on 2026-08-19, and over three weeks
since `tourmakeady-scoping` was first left `needs_scoping` (2026-08-11).

App warm-up: attempted `GET https://mayo-irish-app.fly.dev/` 3 times over
~9 seconds per EXTRACTION.md §4.1; all attempts returned `curl: (56) CONNECT
tunnel failed, response 403` (HTTP 000), consistent with the same sandbox
network-egress policy denial (not an app-sleep issue) reported in every prior
run since 2026-08-04. The mayo-irish-app MCP connector was not available
(ToolSearch found no matching tools) by the time this report was written; no
MCP write was needed or attempted this run regardless, since the queue was
blocked on `tourmakeady-scoping` independent of app/connector availability.

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

Alternatively, a human could scope further Erris material beyond p.216 (if
any remains outside the Index, permanently out of scope per EXTRACTION.md §6)
or a next Foxford unit (pp.171-182, per `foxford-folklore-texts`'s open note
below) as `pending` units — either would unblock the routine without
requiring the Tourmakeady scoping work specifically.

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
above it. Seventeen nightly runs have now passed with zero throughput — the
queue has been idle for seventeen days of nightly cycles and needs human
scoping to resume progress.
