# Extraction report — erris-historical-vowels (2026-08-06)

## Summary

Created draft lesson **139** ("Historical development I: vowels",
`number: 138`) covering IE (Mhac an Fhailigh, *The Irish of Erris*) Part II
"Historical Development," Chapter XIV "Vowels and Diphthongs" (§§285–333),
preceded by the Part II "Introductory" framing (§§281–284). Source:
pp. 134–144, `scans/erris_3/Irish_of_Erris__3.pdf` spreads 1–7, verified
exact against the printed page numbers on the images — the documented
formula (spread N ≈ pp. 130+2N/131+2N) held with **no drift** at either end
checked (spread 2 = pp.134–135, spread 12 = pp.154–155).

## Records created

| resource | ids |
|---|---|
| lessons | 139 |
| lesson_blocks | 168–169 |
| grammar_rules | 201–205 |
| grammar_sections | 461–477 |
| vocabulary_items | 4396–4399 |
| phrases | 28–30 |

Structure:
- **grammar_rule 201** "Long vowels (§§285–294)" — sections 461–465: á/ái;
  ae/aé/ao/aoi; é/éa/éi; ó/ói/eó; í/ío/iú/ú.
- **grammar_rule 202** "Diphthongs (§§295–296)" — sections 466–467: ia/iai;
  ua/uai.
- **grammar_rule 203** "Short stressed vowels (§§297–311)" — sections
  468–472: a/ai/ea; e/ei/eo; i/io/iu; o/oi; u/ui.
- **grammar_rule 204** "Short unstressed vowels: pretonic & post-tonic
  (§§312–326)" — sections 473–475: (a) pretonic; (b) post-tonic incl. the
  i: plural/dative-singular/emphatic marker; prepositional-pronoun endings
  & final -e (§326's "rules … not easy to formulate").
- **grammar_rule 205** "Epenthetic vowels (§§327–333)" — sections 476–477:
  the l/r/n svarabhakti table; further epenthesis incl. devoiced p/f/k and
  the fossilised historical stages behind modern *tarú*/*drú*.
- **lesson_blocks** 168 (source/notation — Part I synchronic vs. Part II
  diachronic framing, §§281–284) and 169 (short aside on chapter shape and
  the next chapter boundary).
- **vocabulary_items** 4396 *ae* 'liver' (irregular disyllabification),
  4397 *aon* 'one' (three variant pronunciations), 4398 *taisbeán* (loses
  its first syllable), 4399 *amadán*.
- **phrases** 28 *Dé hAoine*, 29 *acht uiread*, 30 *riaghail Dhubhagáin*
  (phonetic only — see uncertainties below).

## Chapter boundary confirmed precisely

Chapter XIV "Vowels and Diphthongs" runs exactly pp.135–144/§§285–333
(preceded by the Part II opening, pp.134/§§281–284), and Chapter XV
"Consonants" begins exactly at p.145/§334 — confirmed by direct inspection
of spread 7. This is a clean boundary, the same pattern seen at every prior
Erris chapter transition.

**Important scoping correction for the next unit:** the queue entry for
`erris-historical-consonants` currently estimates `scans/erris_3/ spreads
12-17 approx (pp. ~154-164)`. That is **wrong by ~10 pages / 5 spreads** —
Chapter XV actually begins at spread 7/p.145, not spread 12/p.154 (p.154 is
already mid-chapter, at §381, deep in the *mh/bh* consonant material). This
exceeds the ±2-spread tolerance EXTRACTION.md anticipates for verification
drift, so it is flagged here rather than silently corrected in the queue —
the next run should re-scope `erris-historical-consonants` starting from
p.145/§334, and should expect the consonants chapter (§§334–458, ~125
paragraphs) to be substantially larger than the current entry's structure
notes suggest, likely warranting more than one queue unit.

## [?] transcription uncertainties

None requiring a `[?]` marker in the final records. One glyph was ambiguous
on first read — *cnoc* in §306 (IE p.138) looked like it could be a length
mark (`krūk`) or a nasalisation tilde (`krũk`) — and was resolved by
zooming into the source scan at high resolution: it is unambiguously a
nasalisation tilde, `krũk`. Recorded as such in grammar_section 471.

## Schema / pipeline notes

- `vocabulary_items.gender` again defaulted server-side to `"m"` for all
  four records created here, though gender was not supplied in any create
  call. Same recurring behaviour flagged in every report since 2026-08-03;
  still not correctable from the MCP writable-fields list.
- Direct HTTP warm-up (`GET https://mayo-irish-app.fly.dev/`) was blocked
  again by this session's own sandbox network proxy (`403` to `CONNECT`,
  confirmed via `/__agentproxy/status` as a policy denial, not an
  app-sleep issue) — identical to every prior run. The `mayo-irish-app`
  MCP connector worked normally throughout and was explicitly verified
  with a `list_records` call before any writes, so EXTRACTION.md §4.1's
  stop condition ("MCP tools still unavailable") was not triggered.
- The queue header's `next_lesson_number` (138) looked stale on a first
  read — the last completed unit (erris-glides-sandhi) had
  `created_lesson_id: 138` — but this is expected, not a bug:
  `lessons.id = lessons.number + 1` consistently across every lesson in
  the app (verified directly), so `next_lesson_number: 138` correctly
  yielded `lessons.number: 138` / `lessons.id: 139` here, with no
  collision. Verified with `get_record` calls before writing (lesson 139
  didn't yet exist; lesson 138 and the prior max ids for every other
  resource matched the queue exactly).
- No `poppler-utils` preinstalled; `pymupdf` was pip-installed in-session
  to rasterise pages at high DPI for visual page-number verification and
  precise phonetic transcription (no repo files changed).

## Suggested follow-ups for review

1. Re-scope `erris-historical-consonants` before its run: it should start
   at IE p.145/§334 (spread 7 of `erris_3`), not p.~154/spread 12 as
   currently written, and likely needs splitting into more than one queue
   unit given the size of Chapter XV (§§334–458).
2. Human lookup needed for **phrase 30**, *riaghail Dhubhagáin* — the
   source (§295) gives only the phonetic form `re:l γuga:n'` as an example
   of the ia > e: sound change, without translating the phrase itself. The
   English field records this honestly as unevidenced rather than
   inventing a gloss; a human with access to a fuller dictionary/corpus may
   be able to supply the traditional meaning.
3. Same recurring `gender`-defaulting issue as prior lessons — a candidate
   for a small schema/UI fix upstream (default to null, not `"m"`, when
   gender isn't supplied) rather than a per-record fix.
