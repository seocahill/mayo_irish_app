# Extraction report — erris-verbs-ii-irregular-copula (2026-08-19)

## Summary

Created lesson 146 (number 145), "The Verb System in Erris II: the remaining
irregular verbs & the copula", from IE Chapter XXI "Verbs" concluded
(§§589–602), pp. 211–216. Source: `scans/erris_4/Irish_of_Erris__4.pdf`
spreads 11–14, verified exact against printed page numbers (no ±2 spread
adjustment needed — the queue's 2026-08-15 boundary estimate held precisely).
This continues directly from lesson 145 (pp.206–211, §§574–588, which ended
at fágbhaim/§588), and stops cleanly at §602/p.216 — confirmed by direct
inspection that the Index begins exactly at p.217, on the same rendered
spread as p.216. Chapter XXI ("Verbs") is now fully covered pp.206–216
across this unit and the previous one.

## Records created

| resource | ids |
|---|---|
| lessons | 146 (number 145) |
| lesson_blocks | 184–185 |
| grammar_rules | 228–230 |
| grammar_sections | 563–573 |
| vocabulary_items | 4420–4423 |
| phrases | 47–48 |

## Structure

Three grammar_rules, matching the queue's own suggested split, 11
grammar_sections total:

1. **The remaining irregular verbs** (§§589–594) — 6 sections, one per verb:
   *feicim* (suppletive pret. *chonnaic* for all persons); *ithim* (retained
   historic *s*-forms in fut./cond.); *táim* (by far the fullest paradigm in
   the chapter — pres., dependent, consuetudinal pres. *bíonn*, impf., fut.,
   cond., pret. *bhí* with dedicated pausa forms, imperative, and two
   functionally distinct pres. subj. forms: the optative and the
   final/temporal); *téighim*; *tigim* (incl. the *tig liom* 'I can' short
   form); *tugaim* (incl. its two alternate imperatives, *tug* and
   *tabhair*).
2. **The copula** (§595) — 2 sections: the pres.-fut. table and the
   pret.-cond. table, each crossing positive/negative with
   absolute/interrogative/dependent/relative (the copula does not inflect by
   person).
3. **Disyllabic verb stems and the formation of verbal nouns** (§§596–602) —
   3 sections: the *-(a)igh* class (íslighim model paradigm, plus the
   j-glide subtype *gnóaigheann*/*meadhaigheann*/*breó(dh)aigheann*); the
   *-í:* class (fuagairt-type stems ending in *l′ n′ ɴ′ r′ ʃ*, syncopated
   stem + *-í:*/*-ó:* suffixation, simple-stem retention in the 2sg impv.
   and 3sg pret.); formation of verbal nouns (the velar-medial vs.
   palatal-medial contrast pairs, e.g. *dúnadh*/*dúineadh*, and the *-an*/
   *-achan* verbal-noun ending).

Four vocabulary_items for notable standalone forms not otherwise captured in
the paradigm tables (*chonnaic*, *tabhair*, *gnóaigheann*, *dúineadh*). Two
phrases (*tig liom* 'I can'; *breacan an lae* 'dawn, daybreak' — a
*-an*-ending verbal-noun idiom drawn from §602's own example list). Two
lesson_blocks: source/notation (continuing the allegro/pausa convention and
notation legend established in the previous lesson) + a short aside on
chapter shape, táim's exceptional fullness, and the p.216/217 hard stop.

## Transcription errors caught and corrected

None. All glyphs in this stretch (pp.211–216) were double-checked at 400dpi
crops against the source images before creating records — no `[?]`
uncertainties arose, and no records needed create-only correction this run.

## Schema / state notes

- `get_record` on lesson 145 before creating confirmed the app's actual
  lesson id/number was 145/144, matching `next_lesson_number: 145` in the
  queue header exactly (id = number+1, same pattern as every prior run).
- `vocabulary_items.gender` again defaulted to "m" server-side for all four
  new records even though gender was not set in the create call (recurring
  schema quirk noted in every prior unit's report that created
  vocabulary_items; not corrected here since it is not in the
  writable-fields list).

## Environment notes

- Direct HTTP warm-up (`GET https://mayo-irish-app.fly.dev/`) was blocked by
  this session's own sandbox network policy — five retries over ~100s all
  returned HTTP 000/connection failure, consistent with all ten prior runs.
  The mayo-irish-app MCP connector worked normally throughout (verified with
  a `get_record` call on lesson 145 before writing), so extraction proceeded
  per EXTRACTION.md §4.1's "MCP tools still unavailable" carve-out not being
  triggered.
- `pymupdf` and `pillow` were pip-installed (not preinstalled in this
  environment) to rasterise spreads 11–14 at 200dpi, with 400dpi crops for
  dense/ambiguous passages (táim's paradigm, the copula tables, the
  disyllabic-stem classes, the verbal-noun contrast pairs), for visual
  page-number and glyph verification. No repo files changed;
  poppler-utils still not preinstalled.

## Suggested follow-ups for review

- Publish lesson 146 once reviewed.
- Chapter XXI ("Verbs") is now fully covered, pp.206–216. No further Erris
  queue units are scoped beyond p.216 — a human should decide whether any
  Erris material remains to scope (the Index at p.217+ is permanently out of
  scope per EXTRACTION.md §6) or whether the next unit should come from
  Foxford (partially covered, pp.171–184 per the 2026-08-10 report) or from
  scoping Tourmakeady (`tourmakeady-scoping`, still `needs_scoping` at the
  head of the remaining queue after this unit).
