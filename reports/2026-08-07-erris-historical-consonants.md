# Extraction report — erris-historical-consonants (2026-08-07)

## Summary

Created draft lesson **140** ("Historical development II: consonants",
`number: 139`) covering IE (Mhac an Fhailigh, *The Irish of Erris*) Part II
"Historical Development," Chapter XV "Consonants" (§§334–458). Source:
pp. 145–164, `scans/erris_3/Irish_of_Erris__3.pdf` spreads 7–17, verified
exact against the printed page numbers on the images.

**Scoping correction applied:** the queue entry's estimate
(`spreads 12-17 approx, pp. ~154-164`) had already been flagged wrong by
the previous run's report (erris-historical-vowels, 2026-08-06) — Chapter
XV actually begins at spread 7/p.145, not spread 12/p.154. This run used
the corrected range (spreads 7–17, pp.145–164) and confirmed it by direct
inspection: p.145 (spread 7, right page) opens with "CHAPTER XV /
CONSONANTS / PLOSIVE CONSONANTS / §334", and p.165 (spread 17, right page)
opens with "CHAPTER XVI / INTERCHANGE OF CONSONANTS / §459" — a clean,
exactly-confirmed chapter boundary at both ends, so the entire chapter
(§§334–458) is now covered by this one lesson.

## Records created

| resource | ids |
|---|---|
| lessons | 140 |
| lesson_blocks | 170–171 |
| grammar_rules | 206–211 |
| grammar_sections | 478–500 (493 superseded by 494 — see below) |
| vocabulary_items | 4400–4403 |
| phrases | 31–33 |

Structure:
- **grammar_rule 206** "Plosive consonants (§§334–355)" — sections 478–481:
  d assimilation/loss, g silence/loss/shift to c, t/c interchange,
  eclipsis & cross-references.
- **grammar_rule 207** "Fricative consonants (§§356–423)" — sections
  482–488, one per fricative class: dh/gh, bh/mh, th, f/ph, ch, s,
  sh+h+fh.
- **grammar_rule 208** "Nasal consonants (§§424–444)" — sections 489–492,
  494: m; n (the article's -n & elision); n (lenition, devoicing, the
  cn→kr/gn→gr/mn→mr cluster rule); n (final-position under-differentiation,
  Dú Chaocháin variants); ng.
- **grammar_rule 209** "Lateral consonants (§§445–450)" — sections
  495–497: unlenited l (ʟ vs l), lenited l & the preposition lé, vowels
  before laterals.
- **grammar_rule 210** "Vibrant consonants (§§451–457)" — sections
  498–500: lenited r & loss of the initial palatal/non-palatal contrast,
  medial/final r & the rh development, further sporadic shifts
  (r>l′, r>n′, thr>ʃ).
- **grammar_rule 211** "KEY RULE: vowel lengthening before rr/rd/rl/rn/rng
  (§458)" — created as its own rule (no sub-sections; the table is in the
  rule body), per the queue entry's explicit instruction that this rule
  be singled out.
- **lesson_blocks** 170 (source/notation) and 171 (short aside on chapter
  shape and the next boundary).
- **vocabulary_items** 4400 *adubhairt* (irregular past of *abair*,
  historically misanalysed as *d'ubhairt*), 4401 *féin* (irregular f>h),
  4402 *oidhche* (ch disappears without trace — see uncertainty below),
  4403 *deirbhshiúr* (bh+sh>f′ compound).
- **phrases** 31 *ó tharla* ('since'), 32 *Dé Dardaoin > Dé ardaoin*
  ('Thursday', d-haplology), 33 *níor mhaith liom* ('I would not like').

This chapter is unusually dense — 125 numbered paragraphs across 20 pages,
almost all recording individual exceptions rather than systematic rules —
so every section curates representative examples rather than reproducing
every cited word, consistent with the accuracy-over-coverage policy used
throughout this project.

## Record created in error — flagged for human deletion

**grammar_section 493** ("ng", §444) contained two transcription slips
introduced while typing up the phonetics, caught only after re-zooming
into the source scan for verification:
- `tarraing` was entered as `tarɩɴ′` (spurious inserted vowel letter);
  the source shows `tarɴ′` (bold small-caps N, no extra vowel).
- `tarrngaireacht` was entered as `tarəg′ir′əxd` (spurious prime after
  g); the source shows `tarəgir′əxd` (single prime, after r).

**grammar_section 494** was created immediately after as the corrected
replacement (same label/position, correct phonetics, with a note in the
body identifying it as the replacement for 493). **493 should be deleted
by a human reviewer.**

## [?] transcription / sourcing uncertainties

1. **vocabulary_item 4402** (*oidhche*, "night"): the phonetic field
   `i:ʒə` is **not directly attested** in the source. §412 only
   transcribes *oidhche* inside the fixed phrase "Oidhche fhéil Muire" →
   `i:l' mir'ə` (which folds in loss of *fh* and elision into the
   following word) and never gives the bare word alone. I should not have
   supplied a standalone reconstruction — it also uses `ʒ`, a symbol this
   source's notation never actually employs. **Flagged for human
   correction**: either clear the phonetic field or replace it with a
   note pointing only to the phrase-level example.
2. **grammar_section 500** / **grammar_rule 211**: the gloss "friends"
   given for *cairde* (in the §458 lengthening-rule example table) is
   **not from the source** — §458 cites *cairde* purely as a phonological
   example of the *ai+rd* cluster, with no translation given. "Friends"
   (plural of *cara*) is a plausible but unverified guess on my part —
   flagged for human review rather than treated as sourced.

No other transcription uncertainties: all other phonetics were checked
directly against the rasterised page images, including a re-verification
pass on §444 (ng) after the errors above were found.

## Schema / pipeline notes

- `vocabulary_items.gender` again defaulted server-side to `"m"` for all
  four records created here, though gender was not supplied in any create
  call — same recurring behaviour flagged in every report since
  2026-08-03; still not correctable from the MCP writable-fields list.
- Direct HTTP warm-up (`GET https://mayo-irish-app.fly.dev/`) was blocked
  again by this session's own sandbox network proxy (`curl: (56) CONNECT
  tunnel failed, response 403`, all 5 retries), identical to every prior
  run. The `mayo-irish-app` MCP connector worked normally throughout and
  was explicitly verified with a `list_records` call before any writes,
  so EXTRACTION.md §4.1's stop condition ("MCP tools still unavailable")
  was not triggered.
- Schema/state check: queue header's `next_lesson_number` (139) matched
  the app's actual next available number exactly — verified via
  `get_record` on lesson 139 before creating (id=139, number=138,
  position=138), confirming `id = number+1` and `position = number`, the
  same pattern documented by the prior run. New lesson 140 was created
  with `number: 139, position: 139` accordingly.
- `pymupdf` + `pillow` were pip-installed in-session to rasterise pages at
  high DPI for visual page-number verification and precise phonetic
  transcription, including a targeted re-zoom used to catch and fix the
  §444 transcription errors above (no repo files changed; poppler-utils
  still not preinstalled).

## Suggested follow-ups for review

1. Delete **grammar_section 493** (superseded by 494 — see above).
2. Correct or clear the phonetic field on **vocabulary_item 4402**
   (*oidhche*) — it is an unattested reconstruction, not sourced.
3. Verify the "friends" gloss I supplied for *cairde* in
   **grammar_section 500** / rule 211's example table, or remove it if a
   reviewer can't confirm it — the source doesn't translate the word.
4. Same recurring `gender`-defaulting issue as prior lessons — a
   candidate for a small schema/UI fix upstream (default to null, not
   `"m"`, when gender isn't supplied) rather than a per-record fix.
5. Next queue unit, `erris-historical-interchange`, is unaffected by
   today's re-scoping — its own estimate (spreads 17-19, pp.165-169,
   §§459-481) was already correct and is now directly confirmed: p.165
   opens Chapter XVI exactly at spread 17's right page.
