# Extraction report — erris-verbs-i-conjugation-classes (2026-08-18)

## Summary

Created lesson 145 (number 144), "The Verb System in Erris I: conjugation
classes & the first irregular verbs", from IE Chapter XXI "Verbs", opening
material (§§574–588), pp. 206–211. Source: `scans/erris_4/Irish_of_Erris__4.pdf`
spreads 9–11, verified exact against printed page numbers (no ±2 spread
adjustment needed — the queue's own 2026-08-15 boundary estimate held
precisely). This continues directly from lesson 144 (pp.200–205, §§562–573,
Chapter XX) and stops cleanly at §588 (fágbhaim) on p.211, immediately before
§589 (feicim) opens the right-hand column of the same page — confirmed by
direct inspection, so no gap or overlap with the next queued unit
(erris-verbs-ii-irregular-copula).

## Records created

| resource | ids |
|---|---|
| lessons | 145 (number 144) |
| lesson_blocks | 182–183 (181 superseded by 182) |
| grammar_rules | 226–227 |
| grammar_sections | 552–562 |
| vocabulary_items | 4416–4419 |
| phrases | 45–46 |

## Structure

Two grammar_rules, matching the queue's own suggested split, 11
grammar_sections total:

1. **Allegro/pausa forms and monosyllabic-stem verbs** (§§574–582) — 5
   sections: the allegro/pausa convention itself (§574, with the source's
   three worked examples); *caillim* as the chapter's centerpiece model
   verb, reproduced in full across all tenses/moods incl. rel., pass. and
   pret. (§§575–576), including the muid/sinn 1st p. pl. pronoun rule and
   the Dú Chaocháin *-(e)amaist* variant; group (i) ç-stems — *caithim*'s
   full paradigm plus the 7 other group members given compactly wherever
   the source illustrates a divergent form (§§577–579); group (ii) j-stems
   — *léighim*'s full paradigm plus 6 other members compactly (§§577,
   580–581); group (iii) diphthong stems in *-w* — the paired *snámhaim*/
   *treabhaim* paradigm, plus the source's own note that *sgríobhaim*
   conjugates like *snámhaim* and *lobhaim*/*gabhaim* like *treabhaim*,
   with *gabhaim*'s own irregular fut./cond. by-forms (§§577, 582).
2. **The first irregular verbs** (§§583–588) — 6 sections, one per verb:
   *beirim* (irregular fut. stem, pret. *rug*); *cluinim* (irregular only
   in the 2nd sg. interrogative and the vn.); *deánaim* (Faulmore pret.
   *rinne*, special dependent form, Dú Chaocháin *níodh sé* variant);
   *deirim* (the densest of the six — distinct dabair-/abair-/deir-/deár-
   stems across the paradigm, frequentative and dependent forms); *faghaim*
   (dependent fut./cond. forms built on a separate *bhfuigh-/fhuigh-*
   stem, Faulmore *d'gheobhfadh* variant); *fágbhaim* (irregular only in
   the pret., otherwise fully regular).

Four vocabulary_items for non-paradigm group members mentioned only in
passing rather than given full tables (*brúighim*, *dóighim*, *sgríobhaim*,
*gabhaim*). Two phrases (*an gcluin tú?*, *an ndearna sé?* — the two
irregular interrogative forms encountered in this unit). Two lesson_blocks:
source/notation (including the allegro/pausa convention as the chapter's
distinctive notational device) + a short aside on chapter shape and the
p.211/§589 boundary into the next unit.

## Transcription errors caught and corrected (create-only, no delete tool)

- **lesson_block 181** (source/notation block): used the wrong numeric HTML
  character entities for the velarised lateral/nasal — `&#658;`/`&#626;`
  (decimal codepoints for ʒ/ɲ) instead of the correct U+029F/U+0274 (ʟ/ɴ).
  The block rendered with "ʒ ɲ" in place of "ʟ ɴ" throughout the notation
  legend. Caught immediately after creation by reading the record back.
  **lesson_block 182** was created as the corrected replacement, using
  literal Unicode characters instead of numeric entities to avoid the same
  mistake. **Block 181 is flagged for human deletion.**

No other transcription errors were caught, and no `[?]` uncertainties arose
— all glyphs in this stretch (pp.206–211) were legible at 200dpi.

## Schema / state notes

- `get_record` on lesson 144 before creating, and a full `list_records` scan
  of the `lessons` resource, confirmed the app's actual max lesson id/number
  was 144/143, matching `next_lesson_number: 144` in the queue header
  exactly — same id=number+1 pattern noted by every prior run.
- `vocabulary_items.gender` again defaulted to "m" server-side for all four
  new records even though gender was not set in the create call (recurring
  schema quirk noted in every prior unit's report that created
  vocabulary_items; not corrected here since it is not in the
  writable-fields list).

## Environment notes

- Direct HTTP warm-up (`GET https://mayo-irish-app.fly.dev/`) was blocked by
  this session's own sandbox network policy — five retries over ~2 minutes
  all returned "CONNECT tunnel failed, response 403", consistent with all
  ten prior runs. The mayo-irish-app MCP connector worked normally
  throughout (verified with a `get_record` call on lesson 144, then a full
  `list_records` on `lessons`, before writing), so extraction proceeded per
  EXTRACTION.md §4.1's "MCP tools still unavailable" carve-out not being
  triggered.
- `pymupdf` (imported as `fitz`) was already available in this environment
  and was used to rasterise spreads 9–11 at 200dpi for visual page-number
  and glyph verification (no repo files changed; poppler-utils still not
  preinstalled).

## Suggested follow-ups for review

- Delete lesson_block 181 (superseded, see above).
- Publish lesson 145 once reviewed.
- Next queue unit (erris-verbs-ii-irregular-copula) is scoped and ready;
  its page boundaries were already verified 2026-08-15. It continues
  directly at §589/p.211 and has a hard stop at p.216 (the Index begins at
  p.217, out of scope permanently per EXTRACTION.md §6).
