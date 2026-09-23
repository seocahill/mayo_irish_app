# 2026-09-23 — Nightly extraction run: queue needs human attention

## Outcome

No extraction performed. No records created, no queue entries changed.

## Reason

Per the routine's step 2 (warm the app / verify MCP availability) and step 3
(queue scan):

1. **App warm-up failed at the network policy level, not Fly auto-sleep.**
   `GET https://mayo-irish-app.fly.dev/` returned `HTTP 000` (no connection)
   on all 5 attempts over ~100s. `curl` reported `CONNECT tunnel failed,
   response 403` on every attempt — a hard proxy/policy denial, not a slow
   cold-start. This is the same egress-policy denial reported every night
   since at least 2026-09-19 (and, per the connector split below, effectively
   since 2026-08-20).
2. **The mayo-irish-app MCP connector still exposes no tools this session.**
   `ListConnectors` reports the connector as `connected: true`,
   `enabledInChat: true` at the org/auth level. `ToolSearch` for
   `mayo-irish-app` / `create_record` and for generic record-shaped queries
   (lesson/grammar/vocabulary/phrase/record) returned zero matching tools —
   same split (authenticated at the account level, zero tools in-session) as
   every report since 2026-08-20. Per EXTRACTION.md §4.1 / routine step 2,
   this is an explicit stop condition: no write path was attempted other
   than the sanctioned MCP tools.
3. **Independently, the queue is still blocked anyway.** `extraction_queue.yml`
   was scanned top to bottom: every unit through
   `erris-verbs-ii-irregular-copula` (completed 2026-08-19) has
   `status: done`. The final entry, `tourmakeady-scoping`, still has
   `status: needs_scoping` — there is no `pending` entry anywhere in the
   queue. This is the **thirty-fifth consecutive nightly run** blocked on
   this same entry (2026-08-20 through 2026-09-23) — thirty-five days of
   idle cycles since the last unit completed on 2026-08-19, and forty-three
   days since `tourmakeady-scoping` was first left `needs_scoping`
   (2026-08-11).

Because both the connector and the queue are independently blocking, no
extraction was attempted and nothing was written to the app.

## What's needed

Two separate things need human attention (unchanged from every report since
2026-08-20):

1. **Infra check**: the mayo-irish-app MCP connector and direct HTTPS to the
   Fly app have now failed for thirty-five consecutive nights and should be
   treated as a standing infra defect, not a transient blip. Someone who
   administers the connector/session network policy needs to either
   allowlist `mayo-irish-app.fly.dev` for scheduled/automated sessions or
   fix the connector so it actually exposes tools (it currently reports
   "connected" at the account level while exposing zero tools to the
   session — these look like two distinct failures compounding each
   other). The nightly routine cannot make progress even once the queue is
   unblocked, and every night spent otherwise investigating this is wasted
   run budget until the network/connector policy itself changes.
2. **Queue scoping**: a human/interactive session to scope
   `scans/tourmakeady/` per the entry's own note (unchanged since 2026-08-11):
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
fix the connector/network issue in point 1 above if that recurs.

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
confirmed reachable from this environment. Thirty-five nightly runs have now
passed with zero throughput on the queue side.
