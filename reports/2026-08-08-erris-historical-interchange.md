# Extraction report — erris-historical-interchange (2026-08-08)

## Summary

Created lesson 141 (number 140), "Historical development III: interchange,
dissimilation & metathesis", from IE Part II Chapter XVI "Interchange of
Consonants" (§§459–467) and Chapter XVII "Metathesis" (§§468–481), pp.
165–169. Source: `scans/erris_3/Irish_of_Erris__3.pdf` spreads 17–19,
verified exact against printed page numbers (130+2N formula, no drift).

## Records created

| resource | ids |
|---|---|
| lessons | 141 (number 140) |
| lesson_blocks | 172–173 |
| grammar_rules | 212–215 |
| grammar_sections | 501–512 (508 superseded by 509; 511 superseded by 512) |
| vocabulary_items | 4404–4408 (4407 superseded by 4408) |
| phrases | 34–36 |

## Structure

Four grammar_rules, following the source's own section headings rather
than the queue's original guess (which split §§459-460 from §§461-466; the
book actually groups §§459-464 under "Palatals and Non-Palatals" and only
§§465-466 under "Other Consonant Changes"):

1. **Interchange of consonant quality: palatals and non-palatals**
   (§§459–464) — non-palatal>palatal; palatal>non-palatal; consonant
   quality assimilating to a following vowel-initial word.
2. **Other consonant changes: initial/final shifts and prosthesis**
   (§§465–466) — initial substitutions + prosthetic f/g/t; final -t/-d
   addition.
3. **Dissimilation** (§467) — all five patterns, with district/informant
   attribution (Sb, SOG, Faulmore/Dú Chaocháin).
4. **Metathesis** (Chapter XVII, §§468–481) — palatal cluster metathesis;
   liquids/nasals in stressed & unstressed syllables; thr/fr/rth clusters;
   formulaic & sporadic cases.

Chapter boundary confirmed clean both ends: Chapter XVI opens exactly at
p.165/§459 (matching the prior unit's note), and p.170/§482 opens Chapter
XVIII "Grammatical Supplement — Initial Mutation", which was already
covered by lesson 134 (erris-initial-mutation) — no gap, no overlap.

## Transcription errors caught and corrected (create-only, no delete tool)

1. **grammar_section 508** (caisearbhán metathesis, §471): I wrote
   "caisearbhán > kasʟ'əwa:n" — wrong sibilant (`s` instead of `ʃ`) and
   missing the attested intermediate form. Corrected in **grammar_section
   509**: "caisearbhán > caisreabhán > kaʃʟ'əwa:n". **508 flagged for
   human deletion.**
2. **grammar_section 511** (§477/§478): misread §477 as "luirpín seems to
   represent luirpín" (should be "**luiprín** seems to represent luirpín")
   and §478's headword as "dearagnait" (should be "**deargnait**").
   Corrected in **grammar_section 512**. **511 flagged for human
   deletion.**
3. **vocabulary_item 4407** (paraffin note): said the p>b shift
   "devoices" — factually backwards, since p is voiceless and b is voiced,
   so this is *voicing*, not devoicing. Corrected in **vocabulary_item
   4408**. **4407 flagged for human deletion.**

## [?] Transcription uncertainties for human review

- **vocabulary_item 4406** (luiprin, §477, IE p.169): recorded without its
  length mark. Correct form per the zoomed source image is **luiprín**. A
  third create-only replacement for a single diacritic seemed like
  unwarranted churn given two corrections already made in this unit, so
  this is flagged here instead of re-created.
- **grammar_section 502** (§460(iii), IE p.165): the source is printed
  "Palatal m > m in uaim wum" — apparently identical before and after,
  which looks like a possible lost prime mark in the original typesetting
  (expected "m′ > m", matching the rule's own heading "palatal >
  non-palatal"). Transcribed exactly as printed since the glyph is not
  visibly damaged in the scan. Flagged for human review, not corrected.

## Schema / state notes

- `get_record` on lesson 140 before creating confirmed id=140, number=139
  (id = number+1), matching `next_lesson_number: 140` in the queue header
  exactly — same pattern noted by every prior run.
- `vocabulary_items.gender` again defaulted to "m" server-side for all four
  records in this unit even though gender was not set in the create call
  (recurring schema quirk noted in every prior unit's report; not
  corrected here since it is not in the writable-fields list).

## Environment notes

- Direct HTTP warm-up (`GET https://mayo-irish-app.fly.dev/`) was again
  blocked by this session's own sandbox network policy ("CONNECT tunnel
  failed, response 403", confirmed via `/__agentproxy/status` as a policy
  denial) — consistent with all five prior runs. The mayo-irish-app MCP
  connector worked normally throughout (verified with a `get_record` call
  before writing), so extraction proceeded per EXTRACTION.md §4.1's "MCP
  tools still unavailable" carve-out not being triggered.
- `pymupdf` + `pillow` were pip-installed to rasterise pages for visual
  page-number verification (no repo files changed; poppler-utils still not
  preinstalled in this environment).

## Suggested follow-ups for review

- Delete grammar_sections 508, 511 and vocabulary_item 4407 (superseded,
  see above).
- Fix the missing diacritic on vocabulary_item 4406 (luiprin → luiprín).
- Confirm/investigate the "m > m" reading in grammar_section 502 against
  the physical book or a higher-resolution scan if available.
- Publish lesson 141 once reviewed.
