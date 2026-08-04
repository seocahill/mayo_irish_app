# Extraction report — erris-consonant-phonemes

**Date:** 2026-08-04
**Source:** IE (Mhac an Fhailigh, *The Irish of Erris, Co. Mayo*), Chapter IV
"Phonetic Description of Consonants", pp. 24–44, §§104–194.
**Scans:** `scans/erris_front/Irish_of_Erris_1_1.pdf`, spreads 20–30
(rasterised with PyMuPDF, pip-installed in-session since neither
poppler-utils nor any other PDF renderer was preinstalled; no repo files
were changed by this. Printed page numbers verified visually at every
spread checked — spread 20 = pp. 24–25 through spread 30 = pp. 44–45, no
drift, all 32 spreads of this file map as `page = 2*(N-20)+24`).

## Warm-up note

Step 2 of the routine (`GET https://mayo-irish-app.fly.dev/`) returned
HTTP 403 on every attempt via both `curl` and `WebFetch`. This was **not**
an app-sleep issue: `curl -sS "$HTTPS_PROXY/__agentproxy/status"` showed
the sandbox's own outbound-network policy rejecting the CONNECT to
`mayo-irish-app.fly.dev:443` ("gateway answered 403 to CONNECT (policy
denial or upstream failure)"). The mayo-irish-app MCP connector itself
worked normally throughout (confirmed via `list_records` before any writes
and every `create_record` call below succeeding), so this did not trigger
EXTRACTION.md §2's "MCP tools still unavailable → stop" clause. Flagging
for a human in case this sandbox's network policy is meant to allow that
host and doesn't.

## Created records

- **Lesson 137** (number 136), "The Sound System of Erris II: consonants",
  draft, `dias_material`. (Note: this app's lesson `id` consistently runs
  one ahead of the `number` field going back several units — id 137/number
  136 is consistent with that existing offset, not a new issue.)
- **lesson_blocks 164–165**: (1) source/notation recap; (2) short prose
  aside on the four-way lateral/nasal systems and the ḍ/ṭ subtlety.
- **grammar_rules 191–197**, one per manner class, matching Chapter IV's
  own organisation exactly:
  - 191 "Palatalisation, velarisation & the consonant phoneme system"
    (§§104–114) — 3 sections (426–428): contrastive examples, voicing/
    plosion mechanics, and the full §114 phoneme table.
  - 192 "Plosive consonants" (§§115–131) — 4 sections (429, 431, 432, 434):
    bilabial b′p′bp, dental dt, alveolar ḍṭ (+ affricate-replacing
    allophones d′/t′), velar g′k′gk.
  - 193 "Fricative consonants" (§§132–156) — 4 sections (435, 437–439):
    bilabial v′f′wf, sibilants ʃs, palatal/velar jçγx, glottal h.
  - 194 "Affricate consonants d′ t′" (§§157–160) — 1 section (440).
  - 195 "Nasal consonants" (§§161–174) — 3 sections (441–443): bilabial
    m′m, the four-way ɴ-n-n′-ɴ′ system, velar ŋ′ŋ.
  - 196 "Lateral consonants" (§§175–184) — 2 sections (446, 445): the
    four-way ʟ-l-l′-ʟ′ system.
  - 197 "Vibrant consonants r r′" (§§185–194) — 2 sections (447–448).
- **vocabulary_items 4388–4391**: b'éidir (perhaps), Méiricea (America,
  loanword), giosadán (corncrake — the only word the author documents with
  z), cárta (card, loanword spelled phonetically with d).
- **phrases 21, 23–24**: "is mithid liom" (§168), "ar mo shon" (§166),
  "i n-aon-turus" (§171) — all drawn from example words embedded in the
  nasal-consonant sections (this chapter is phonetic description, not
  running text, so idioms are scarce; only these three clean examples were
  found).

## Coverage

Confirmed by direct inspection: Chapter IV runs precisely pp. 24–44
(§§104–194), and Chapter V "Glides" begins exactly at p. 45/§195 — a clean
boundary. This unit starts exactly where `erris-vowel-phonemes` (lesson
136) left off and ends exactly where the next queue unit
`erris-glides-sandhi` should start; its current estimate ("roughly pp.
40-49") should be tightened to start at p. 45/§195.

The source is very dense (91 numbered paragraphs across 20 pages, almost
entirely per-phoneme example-word lists). Per "accuracy over coverage,"
each grammar_section curates 2–4 representative examples per phoneme/group
rather than transcribing every listed word.

## Transcription uncertainties [?]

- **grammar_section 446** ("Non-palatal laterals ʟ l"): the source's first
  example in the §179 (l) list is printed **lag ə ʟa: lag an lá** — using
  the dental ʟ even though it heads the post-alveolar l examples. Confirmed
  by zooming to 600dpi on the specific line; not an OCR artefact on my
  part. Left out of the curated table (replaced with two unambiguous l
  examples) and flagged in-record with `[?]` for human review against the
  physical/original scan — possible printer's inconsistency, or the word
  genuinely takes dental ʟ lexically in this dialect.
- **phrase 24** "i n-aon-turus": the source gives two side-by-side phonetic
  variants (əɴ' e:ɴtərəs / əɴ' e:ɴtrəs); both were kept rather than
  picking one.

No unreadable glyphs were encountered; scan quality was good throughout at
600dpi spot-checks.

## Records created in error (for human deletion)

Four grammar_sections and one phrase were created with transcription slips
(mostly schwa-for-e typos or transposed letters on my part while typing,
caught on review), then superseded by corrected records at the same
position. **Please delete:**

- grammar_sections **430** (dental plosive section — invented an incorrect
  gloss for *dáir*; superseded by 431)
- grammar_sections **433** (velar plosive section — "kolem" should read
  "koləm"; superseded by 434)
- grammar_sections **436** (sibilants section — "ʃagel" should read
  "ʃagəl"; superseded by 437)
- grammar_sections **444** (non-palatal laterals section — contained the
  ʟ/l ambiguity above plus a transposed-letters error, "bəla:x" for
  "baləx"; superseded by 446)
- phrases **22** ("d'aon-turus" — wrong phonetic transcription and a
  modernised-but-unsourced Irish spelling; superseded by 24, which uses
  the source's own spelling "i n-aon-turus" and verified phonetics)

## Schema notes

`vocabulary_items.gender` again defaulted server-side to `"m"` on all four
new records despite `gender` not being set in any create call (same
behaviour noted in the `erris-vowel-phonemes` report) — not corrected here
for the same reasons.

## Suggested follow-ups

- Delete the five superseded records listed above.
- When `erris-glides-sandhi` runs, start at p. 45/§195 exactly.
- A human with the physical/original scan could resolve the ʟ/l question
  on p. 42 (§179, "lag ə ʟa:") flagged above.
- Consider clearing the spurious `gender: "m"` on vocabulary_items
  4388–4391 (and the earlier flagged batch) in the admin UI.
