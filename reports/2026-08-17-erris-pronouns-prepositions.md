# Extraction report — erris-pronouns-prepositions (2026-08-17)

## Summary

Created lesson 144 (number 143), "Pronouns, Prepositions & Demonstratives in
Erris", from IE Chapter XX "Pronouns, Prepositions, etc." in full (§§562–573),
pp. 200–205. Source: `scans/erris_4/Irish_of_Erris__4.pdf` spreads 6–8,
verified exact against printed page numbers (no ±2 spread adjustment needed —
the queue's own 2026-08-15 boundary check held precisely). This continues
directly from lesson 143 (pp.192–199, §§530–561) and ends exactly at the
p.205/p.206 boundary where Chapter XXI "Verbs" begins (§574) — confirmed by
direct inspection, so no gap or overlap with the next queued unit
(erris-verbs-i-conjugation-classes).

## Records created

| resource | ids |
|---|---|
| lessons | 144 (number 143) |
| lesson_blocks | 178–180 (178 superseded by 179) |
| grammar_rules | 222–225 |
| grammar_sections | 534–551 (539 superseded by 540) |
| vocabulary_items | 4414–4415 |
| phrases | 42–44 |

## Structure

Four grammar_rules, matching the source's own four printed section headings
exactly (Personal Pronouns / Demonstratives / Possessives / Prepositions),
18 grammar_sections total:

1. **Personal Pronouns** (§§562–563) — 2 sections: simple + emphatic
   subject-of-active-verb paradigm; the special object/copula-predicate/
   passive-subject/absolute forms (2nd & 3rd persons only — 1st person is
   unchanged from §562), plus the note that *tú* not *thú* follows the
   copula and *agus/is*.
2. **Demonstratives** (§§564–567) — 4 sections: basic demonstratives +
   combination with the 3rd person pronouns; forms after the copula/*nach*/
   *gurb*; forms following a defined noun (adjectival use); the
   *voici/voilà* adverbial use.
3. **Possessives** (§§568–569) — 2 sections: the full preceding-consonant/
   preceding-vowel paradigm table; the emphatic-suffix construction
   (attaching the emphatic particle to the following noun, including the
   1st/2nd p. pl. *s'againne*/*s'agaibh-se* forms of §569). Re-scoped: §569
   is the tail of the Possessives topic, not the head of Prepositions — no
   new printed heading appears until "PREPOSITIONS" immediately before §570.
4. **Prepositions** (§§570–573) — 9 sections: the full list of simple
   prepositions; then full singular/plural pronominal-form paradigms for
   all thirteen prepositions that take one — *ag* (+ its "more commonly
   used" 1st/2nd person variant forms *ugam/ogam* etc.), *ar* + *as*, *de* +
   *do* (+ their lenited variants), *faoi* + *i/ann* + *idir*, *lé* + *ó*,
   *roimh* + *thar* + *tré* — grouped into 6 sections by page/theme rather
   than one-per-preposition, since several share a single compact table on
   the same page; the *chun*/*ag* merger note (including the irregular
   h-prefixed warning form *chugad*, and the *chun a(n)* vs. *ag a(n)*
   places-vs-persons distinction); the emphatic-suffix rule for
   prepositional pronouns.

Two vocabulary_items (*muid*/*sinn* — the 1st p. pl. pronoun doublet;
*chugad* — the irregular h-prefixed form). Three phrases (*nach eo é do
mhac?*; *seo chugainn* 'next' in time; *chugad an púca!* warning cry). Two
lesson_blocks: source/notation (incl. clarifying that bold small-caps in the
source render the velarised nasal ɴ) + a short aside on chapter shape
(almost entirely paradigm tables) and the p.206/§574 boundary into the next
unit.

## Transcription errors caught and corrected (create-only, no delete tool)

- **lesson_block 178** (source/notation block): used the wrong Unicode
  codepoint for ɴ (U+0274, velarised nasal) in the notation-legend prose —
  typed U+025B (ɛ) by mistake, which rendered as "render the velarised nasal
  ɛ ... here transcribed ɛax" — nonsensical. Caught immediately after
  creation by reading the record back. **lesson_block 179** was created as
  the corrected replacement. **Block 178 is flagged for human deletion.**
- **grammar_section 539** (§567, demonstrative-adverb examples): mis-glossed
  the second example, giving only "thíos é" as the gloss for the phonetic
  "hin′ e: hi:s e:" when the source actually glosses the *full* phonetic
  string as "sin é thíos é" (i.e. two words, not one). Caught by re-zooming
  into the source image at 600dpi before moving on to §568. **grammar_section
  540** was created as the corrected replacement. **Section 539 is flagged
  for human deletion.**

## [?] Transcription uncertainty

- **grammar_section 537** (§565, demonstrative-after-copula examples): the
  source's own phonetic transcription of its second example reads "mu
  dahir′" (which would correspond to *m'athair*, "my father") while the
  Irish/English gloss printed alongside it is *d'athair*/"your father" — the
  phonetic and the gloss disagree on possessor. Transcribed exactly as
  printed (not silently corrected); flagged for human review as a probable
  original typesetting slip (**mu** for **də**).

## Schema / state notes

- `get_record` on lesson 143 before creating confirmed id=143, number=142
  (id = number+1), matching `next_lesson_number: 143` in the queue header
  exactly — same pattern noted by every prior run.
- `vocabulary_items.gender` again defaulted to "m" server-side for both new
  records in this unit even though gender was not set in the create call
  (recurring schema quirk noted in every prior unit's report that created
  vocabulary_items; not corrected here since it is not in the
  writable-fields list).

## Environment notes

- Direct HTTP warm-up (`GET https://mayo-irish-app.fly.dev/`) was again
  blocked by this session's own sandbox network policy — five retries over
  ~100s all returned HTTP 000 (connection failure), consistent with all
  nine prior runs. The mayo-irish-app MCP connector worked normally
  throughout (verified with a `get_record` call on lesson 143 before
  writing), so extraction proceeded per EXTRACTION.md §4.1's "MCP tools
  still unavailable" carve-out not being triggered.
- `pymupdf` + `pillow` were pip-installed to rasterise pages at 200dpi
  (with 500–600dpi crops for dense/ambiguous passages) for visual
  page-number and glyph verification (no repo files changed; poppler-utils
  still not preinstalled in this environment).

## Suggested follow-ups for review

- Delete lesson_block 178 and grammar_section 539 (both superseded, see
  above).
- Review grammar_section 537's [?] flagged phonetic/gloss mismatch (mu vs.
  də dahir′) against the physical source if available.
- Publish lesson 144 once reviewed.
- Next queue unit (erris-verbs-i-conjugation-classes) is scoped and ready;
  its page boundaries were already verified 2026-08-15.
