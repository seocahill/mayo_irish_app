# 2026-08-02 — erris-intro-notation

## Summary

Completed. Created draft lesson 135 ("Reading Mhac an Fhailigh: districts,
informants & notation") with 3 lesson_blocks, 2 grammar_rules, 5
grammar_sections, and 1 phrase. `next_lesson_number` incremented 134 → 135.

Note: an earlier run today aborted at the warm-up step because the
mayo-irish-app MCP connector was surfacing zero tools (see git history for
that report's prior content). This run re-checked and found the connector
fully functional — `list_records`/`get_record`/`create_record` all worked
normally — so it proceeded.

## Pages covered

- Preface, pp. iv–xvii (`scans/erris_front/Irish_of_Erris_1_1.pdf`, spreads
  1–7): title page, table of contents (partial — see gap note below),
  Preface (districts, dialect notes, survey history, informants).
- Chapter I "Introductory", §§1–23, pp. 1–7 (spread 8): general phonetic
  theory (not reproduced — see scoping note) through the "Symbols" section.

Printed page numbers were verified directly against the rendered spreads;
no drift found across spreads 1–8 (title → p. 7).

## Scoping change from the queue entry

The queue's `structure` field predicted a "notation" grammar_rule "with a
symbol table (ʟ ɴ, C′, :, ˜, ə, ʃ, ç, x, γ, ŋ)" sourced from pp. iii–xii.
That page range is entirely front-matter/Preface prose (districts,
informants) — there is no symbol-legend table there. The actual notation
legend the queue was anticipating is §§21–23 ("Symbols"), pp. 6–7, at the
very end of Chapter I, immediately before Chapter II ("Phonetic
Description of Vowels") begins on p. 8. I extended the unit's page range
to include Chapter I (pp. 1–7) specifically to reach this section, since
it's the natural chapter-boundary anchor point and matches the queue's
intent ("so every later IE lesson can reference it") much more closely
than fabricating a table from page headings I hadn't read.

I did **not** reproduce §§1–20 (organs of speech, cardinal vowels,
consonant classification by organ/manner, the phoneme concept) as separate
records — this is standard general-phonetics/IPA theory shared with any
introductory phonetics text, not Erris-dialect-specific content, so
including it would be padding relative to EXTRACTION.md's "accuracy and
faithfulness... beat coverage" guidance. It's summarized (not reproduced)
in lesson_block 159's scope note so a human reviewer knows it was seen and
deliberately skipped, not missed.

## Records created

- **lesson**: id 135, number/position 134, title "Reading Mhac an
  Fhailigh: districts, informants & notation", lesson_type dias_material,
  draft (unpublished).
- **lesson_blocks** (159–161): (1) source/scope note; (2) "The barony of
  Erris and its two Irish-speaking districts" (Faulmore, Dú Chaocháin,
  Inishkea resettlement, dialect-conservatism note, Preface pp. xi–xiii);
  (3) "Survey history" (1935–36 collection, 1961–62 revisit, Preface p.
  xv).
- **grammar_rules**:
  - 186 "Principal informants & abbreviated references (Preface, pp.
    xv–xvii)" → **grammar_sections** 409–411: Faulmore informants
    1935–36 (Sb, EOM, Lb); other districts 1935–36 (CM, POR, PB, AOS, SOG,
    PAG, POC); Faulmore informants 1961–62 (Wm, SBh, MMt, MCd). All 14
    sigla, names, districts and biographical notes transcribed from the
    Preface tables.
  - 187 "The notation: symbols used in this work (§§21–23, pp. 6–7)" →
    **grammar_sections** 412–413: master symbol table (ʟ/ɴ and their
    palatalized forms, the palatalization mark and its cluster-placement
    rule + the seven listed exceptions, stress marks, length/half-length,
    nasalization tilde, phonemic vs. "merely phonetic" bracket
    conventions, γ/ɣ variation note); and the boxed editorial note
    broadening "palatal"/"velar" terminology for later chapters (p. 7).
- **phrases** (17): "siúl a' chait ag a' bpisín" (cat-after-kind proverb,
  Doohoma form) with the Ballycroy variant noted, Preface p. xii.

## Correction made during the run

grammar_rule 187's first `create_record` call used the wrong Unicode
codepoints for ʟ and ɴ (U+028F/U+0273 — small-capital Y and retroflex n —
instead of the correct U+029F/U+0274). Caught immediately by verifying
codepoints in a shell before use; fixed with **one** `update_record` call
on 187's body (confirmed successful) before creating its grammar_sections,
which used the verified-correct characters from the start. No bad records
need human deletion.

## Transcription uncertainties (`[?]`)

None. All transcribed text was read directly off the rendered page images
at 3x zoom (5x for one crop) and cross-checked against EXTRACTION.md's
documented notation conventions; no illegible glyphs were encountered in
the pages used.

## Schema notes

No new schema discoveries — `lessons`, `lesson_blocks`, `grammar_rules`,
`grammar_sections`, and `phrases` all behaved as documented in
EXTRACTION.md §3. `update_record` succeeded on the one attempt made here
(contra the "unreliable" warning) — noting this in case it's useful
signal, but continuing to treat it as create-only/best-effort per policy.

## Suggested follow-ups

- TOC page 1 (roman pp. iv–v, listing Chapters I–III — the vowel/diphthong
  chapters) appears to be missing from the `erris_front` scan: spread 1 is
  title+blank and spread 2 jumps straight to pp. vi–vii (TOC continuing
  from Chapter IV). This didn't block anything (TOC isn't lesson content),
  but a human may want to confirm against the upstream source whether this
  page is genuinely absent from the scan or was mis-ordered.
- The `erris-vowel-phonemes` and `erris-consonant-phonemes` queue entries
  should link back to this lesson's notation grammar_rule (135/187) rather
  than repeating the symbol table.
