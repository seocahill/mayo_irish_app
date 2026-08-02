# 2026-08-02 — erris-initial-mutation

## Summary

Extracted IE §§482–495 (pp. 170–178), "Initial Mutation in Erris" (Grammatical
Supplement, Chapter XVIII), into a new draft lesson. Pages verified against
printed page numbers on the scan; no drift from the estimate (spread N = pp.
`130+2N`/`131+2N` held exactly at N=20–24).

## Records created

- **Lesson** id **134**, number/position **133**, title "Initial Mutation in
  Erris", `lesson_type: dias_material`, draft (unpublished).
- **grammar_rules** ids **180–185** (6 rules, numbers 1–6):
  1. The mutation system + master consonant table (§§483–485)
  2. Lenition of nouns (§486)
  3. Lenition of adjectives (§487)
  4. Lenition of verbs, adverbs & prepositions (§§488–489)
  5. Eclipsis of nouns and verbs (§§490–491)
  6. Provection: h, t, N/n, j (§§492–495)
- **grammar_sections** ids **376–408** (33 created, 32 valid — see "Created in
  error" below):
  - 376: master consonant table (§485), under rule 180
  - 377–390: all 14 numbered environments of §486 (lenition of nouns), under
    rule 181
  - 391–398, 400: all 9 numbered environments of §487 (lenition of
    adjectives), under rule 182 (400 supersedes 399)
  - 401–402: §488 (verbs) and §489 (adverbs/prepositions/pronominal forms),
    under rule 183
  - 403–404: §490 (eclipsis of nouns, six environments) and §491 (eclipsis of
    verbs, three environments), under rule 184
  - 405–408: §492 (h-provection, a–d), §493 (t t′), §494 (N N′/n n′), §495
    (j-provection, Dú Chaocháin vs Faulmore), under rule 185
- **lesson_blocks** ids **157–158**: block 1 = source/abbreviations/notation
  legend; block 2 = a "things worth noticing" aside cross-referencing lé's
  irregular behaviour across the lenition and provection systems.
- **phrases** ids **12–16**: lé chéile 'together', lé dhol '(about) to go',
  lé thoidheacht '(about) to come', thar dhuine ar bith oile 'more than
  anyone else', lé haghaidh 'for, regarding'.
- No vocabulary_items created — this unit is a mutation-rules chapter, not a
  vocabulary-presenting one; no items stood out as distinct from the grammar
  examples already carried in the sections.

## Pages & paragraphs covered

pp. 170–177 in full (§§482–495), plus the first few lines of p. 178 only to
complete the sentence that §495(ii)'s example list runs into (the vowel-elision
examples from informant Sb). The rest of p. 178 — §496 "w v′" (bh from níorbh/
nárbh carried forward before a vowel) and the start of Chapter XIX (Declension
of Nouns) — was seen but deliberately **not** extracted: it falls outside this
unit's scoped paragraphs (§§482–495) and pages (170–177). §496 is a natural
continuation of the provection material and may be worth folding into a future
unit (it's currently uncovered by any queue entry).

## Transcription uncertainties ([?])

None — all example forms and phonetic transcriptions were read directly and
legibly off the scan; no glyphs required a best-guess marker.

## Created in error (for human deletion)

- **grammar_section id 399** (§487(ix) "After budh"): the created body
  mistranscribed the example `badə b'fhada` as `badə b'fadə budh b'fhada`
  (dropped the h in fhada and inserted a spurious extra "budh"). Corrected in
  **id 400** (same grammar_rule_id 182, position 9). Please delete id 399.

## Other notes for review

- While probing the app before this run, `list_records(grammar_rules)` for
  lesson 133 ("Noun Declension in Erris") showed rule numbers 1–6 **each
  duplicated** (ids 168–173 and again 174–179), and `list_records(lesson_blocks)`
  similarly shows lesson 133's blocks in what look like two overlapping sets.
  This predates this run and is unrelated to the unit processed here, but the
  queue's next entry (`erris-singular-flexions-summary`, appending rule 7 to
  lesson 133) assumes a single clean set of rules 1–6 — worth a human check
  before that unit runs.
- Direct HTTP GET to `https://mayo-irish-app.fly.dev/` was blocked by this
  session's sandbox network policy (403 from the outbound proxy gateway) —
  this is a sandbox restriction, not the app being asleep. The MCP connector
  itself connected normally and `list_records`/`create_record` calls worked
  throughout, so this did not block the run.
- No `pdftoppm`/`pdfinfo` binaries were present in this environment (only
  `libpoppler`); rasterised `scans/erris_3/Irish_of_Erris__3.pdf` with
  `pymupdf` (`pip install pymupdf`) instead. Future runs may hit the same gap.

## Suggested follow-ups

- Scope a future unit for IE §496 (p. 178) — the last piece of the provection
  chapter, currently uncovered.
- Human review of the lesson-133 duplicate-rules issue noted above before the
  `erris-singular-flexions-summary` unit is run.
