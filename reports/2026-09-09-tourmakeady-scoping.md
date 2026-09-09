# 2026-09-09 — Nightly extraction run: queue needs human attention

## Outcome

No extraction performed. No records created, no queue entries changed.

## Reason

Per the routine's step 2 (warm the app / verify MCP availability) and step 3
(queue scan):

1. **App warm-up failed at the network level, not just Fly auto-sleep.**
   `GET https://mayo-irish-app.fly.dev/` was retried 5+ times over the
   session's outbound proxy; every attempt was rejected by the proxy gateway
   itself with `403` on the CONNECT (`connect_rejected`, "policy denial or
   upstream failure"), not a timeout or a Fly cold-start response. This looks
   like this session's network policy does not permit direct HTTPS egress to
   `mayo-irish-app.fly.dev`, distinct from the app being asleep.
2. **The mayo-irish-app MCP connector never exposed its tools this session.**
   `ListConnectors` reports the connector as `connected: true` and
   `enabledInChat: true`, but repeated `ToolSearch` queries (direct tool
   names, and keyword searches for "lesson", "record", "grammar",
   "vocabulary", "phrase") returned zero `mcp__mayo-irish-app__*` tools
   throughout the run. Per EXTRACTION.md §4.1 / routine step 2, this is an
   explicit stop condition: no write path was attempted other than the
   sanctioned MCP tools.
3. **Independently, the queue is still blocked anyway.** `extraction_queue.yml`
   was scanned top to bottom: every unit through `erris-verbs-ii-irregular-copula`
   (completed 2026-08-19) has `status: done`. The next and final entry,
   `tourmakeady-scoping`, still has `status: needs_scoping` — there is no
   `pending` entry anywhere in the queue. This is the **twenty-first
   consecutive nightly run** blocked on this same entry (2026-08-20 through
   2026-09-09) — twenty-one days of idle cycles since the last unit completed
   on 2026-08-19, and just over four weeks since `tourmakeady-scoping` was
   first left `needs_scoping` (2026-08-11).

Because both the connector and the queue are independently blocking, no
extraction was attempted and nothing was written to the app.

## What's needed

Two separate things need human attention:

1. **Infra check**: confirm whether the mayo-irish-app MCP connector is
   expected to be reachable from scheduled/automated runs — tonight it
   reported "connected" in metadata but exposed no callable tools, and direct
   HTTPS to the Fly app was rejected by the outbound network policy before
   even reaching the app. If this recurs, the nightly routine cannot make
   progress even once the queue is unblocked.
2. **Queue scoping** (unchanged from prior reports): a human/interactive
   session to scope `scans/tourmakeady/` per the entry's own note (unchanged
   since 2026-08-11):
   - Inventory `tourmaceady_1.pdf` (19pp), `tourmaceady_2.pdf` (21pp),
     `tourmaceady_3.pdf` (21pp), `tourmaceady_4.pdf` (29pp),
     `tourmaceady_part1.pdf` (8pp), and `tourmaceady_201.docx`.
   - Determine each file's format (real PDF vs. ZIP-of-JPEGs, per
     EXTRACTION.md §1's historical caveat) and map printed page ranges /
     chapter structure.
   - Decide unit boundaries and the #vs-erris comparison tagging strategy.
   - Append scoped `T-*` units to `extraction_queue.yml` with
     `status: pending` so the nightly routine can pick them up.

Alternatively, a human could scope further Erris material beyond p.216 (if
any remains outside the Index, permanently out of scope per EXTRACTION.md §6)
or a next Foxford unit (pp.171-182, per `foxford-folklore-texts`'s open note
below) as `pending` units — either would unblock the queue side without
requiring the Tourmakeady scoping work specifically. This would not by itself
fix the connector issue in point 1 above if that recurs.

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

Will re-check the queue head and connector availability again next cycle;
nothing to do until `tourmakeady-scoping` is resolved by a human or a new
`pending` unit is added above it, and until the mayo-irish-app MCP tools are
confirmed reachable from this environment. Twenty-one nightly runs have now
passed with zero throughput on the queue side.
