# Extraction report — erris-vowel-phonemes

**Date:** 2026-08-03
**Source:** IE (Mhac an Fhailigh, *The Irish of Erris, Co. Mayo*), Part I,
Chapter II "Phonetic Description of Vowels" + Chapter III "Phonetic
Description of Diphthongs", pp. 8–23, §§24–103.
**Scans:** `scans/erris_front/Irish_of_Erris_1_1.pdf`, spreads 12–20
(rasterised at 3x zoom with PyMuPDF; poppler-utils were unavailable in
this environment so `pdftoppm` was replaced with an equivalent PyMuPDF
render — printed page numbers verified visually against the images at
every spread, no drift found).

## Created records

- **Lesson 136** (number 135), "The Sound System of Erris I: vowels &
  diphthongs", draft, `dias_material`.
- **lesson_blocks 162–163**: (1) source/notation recap; (2) short prose
  aside on consonant-conditioned vowel quality and phoneme-boundary
  overlap.
- **grammar_rules 188–190**:
  - 188 "The vowel phonemes: quality and length" (§§24–74) — 6
    grammar_sections (414–419): /i//i:/, /e//e:/, /a//a:/, /o//o:/,
    /u//u:/, /ə/.
  - 189 "Nasalised vowels" (§§75–87) — 2 grammar_sections (420–421): the
    five nasalised phonemes (examples table), and the Faulmore/Doohoma
    open ã: diaphonic variant (§83, with district attribution).
  - 190 "The falling diphthongs" (§§88–103) — 4 grammar_sections
    (422–425): /iə/, /uə/, /əi/, /əu/.
- **vocabulary_items 4382–4387**: agus, bior, ceird, coirce, sgeallán,
  raibh — all chosen for a notable phoneme-boundary overlap/alternation
  (i/u, e/o, or unstressed a/o/u), per the schema's "individually notable
  words (irregulars)" guidance.
- **phrases 18–20**: "Cá bhfuil sé?" (əu diphthong example), "go deó" (/o:/
  after palatal), "ar ball" (/a:/ example; cross-references the
  non-lenition ar-phrase list in the Initial Mutation lesson).

## Coverage

Confirmed chapter boundaries by direct inspection of printed headings:
Chapter II runs pp. 8–20 (§§24–87), Chapter III runs pp. 21–23
(§§88–103), and Chapter IV ("Phonetic Description of Consonants") begins
exactly at p. 24/§104. This unit therefore starts precisely where
`erris-intro-notation` (lesson 135) left off, and ends precisely where the
next queue unit `erris-consonant-phonemes` should start — no gap, no
overlap. `erris-consonant-phonemes`'s current queue estimate of "~pp.
25-45" should be adjusted to start at p. 24 when it runs.

The source material for this span is very dense — 80 numbered paragraphs
across 16 pages, mostly consisting of long example-word lists for each
phonetic environment. Per "accuracy over coverage," each grammar_section's
example table was curated to 1–2 representative examples per described
environment rather than transcribing every example word in the source
(e.g. §35 alone lists ~35 example words for short /i/, of which 1 appears
here). The prose intro of each rule/section states the described
environments faithfully even where not every example made it into the
table.

## Transcription / gloss uncertainties [?]

Phonetic transcriptions were read directly from the printed IPA-ish
notation and are high-confidence. Two English glosses (supplied by me,
since the source gives Irish spelling but not English translation) are
lower-confidence and should be checked by a human:

- **foghmhar** (§85 example, phonetic fõ:wər) — glossed as "autumn,
  harvest," reading it as a dialectal/older spelling of standard *fómhar*.
  [?]
- **gadhar** (§98 example, phonetic gəir) — glossed as "dog" (dialectal
  for *madra*). Moderately confident but flagged. [?]

No unreadable glyphs were encountered; scan image quality was good
throughout at 3x zoom.

## Schema discovery

`vocabulary_items.gender` defaulted server-side to `"m"` on all six
created records even though `gender` was not included in any create call
attributes, and at least one of the words (*raibh*, a verb form) isn't a
gendered noun at all. Not corrected here since `gender` isn't a field this
pipeline writes to and update_record is unreliable per policy — flagged
for human review/cleanup in the admin.

## Nothing created in error

No records need human deletion for this unit.

## Suggested follow-ups

- When `erris-consonant-phonemes` runs, start at p. 24/§104 exactly (see
  Coverage above) rather than the queue's current "~pp. 25-45" estimate.
- Consider a human pass to verify the two [?]-flagged glosses above.
- Consider clearing/correcting the spurious `gender: "m"` on
  vocabulary_items 4382–4387 in the admin UI.
