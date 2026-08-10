# 2026-08-10 — foxford-folklore-texts

## Summary
Created a new draft lesson (id 142, number 141) covering the closing
folklore/sayings section of "Notes on a Mayo Dialect" (Foxford), printed
pp. 183–184: six titled items across five text_passages, two phrases, one
vocabulary_item, and two lesson_blocks. This was a re-extraction of a lost
unit; the queue's own estimate of "~7 items" landed close (8 records).

## Source
- FX (Éamonn Mhac an Fhailigh, *Notes on a Mayo Dialect*), based on a
  tape-recorded conversation (21 May 1968) with James Deasy (JD) of Rinn an
  Eanaigh, near Foxford, Co. Mayo.
- `scans/foxford/FoxfordNOTES_ON_A_MAYO_DIALECT.pdf`, PDF page indices 12–13
  of 14, verified exact against the printed page numbers visible on the
  rasterised images (index 12 = p. 183, index 13 = p. 184).
- Printed pp. 183–184.

### Scan-scope discrepancy (flagged for a human)
`scans/foxford/FoxfordNOTES_ON_A_MAYO_DIALECT.pdf` is **not the full
monograph** as `EXTRACTION.md` §1 describes it. It is a single 14-page
journal article/offprint, printed pp. 171–184 only (PDF index 0 = an
unnumbered title page ≈ p. 171, through index 13 = p. 184 — a clean 1:1
`printed_page = index + 171` mapping, no two-page spreads unlike the Erris
scans). A human should correct `EXTRACTION.md` §1, and should check whether
any of pp. 171–182 already exist in the app before scoping a follow-up
Foxford unit — there is no larger "full book" left to extract from this
particular PDF.

## Schema probe: text_passages
Per the queue entry's instruction, probed `text_passages` before bulk
creating. The first create call (record 64, "Tobac Corp") included two
extra candidate fields, `phonetic` and `notes`, alongside the real
`lesson_id`/`position`/`title`/`body`. Both extra fields were silently
dropped from the response. **Confirmed writable fields: `lesson_id`,
`position`, `title`, `body` (HTML) — nothing else**, matching what
`list_records` already showed across the 51 pre-existing text_passages.
Usable as scoped by the queue: one text_passage per titled folklore text,
Irish/phonetic + translation + provenance folded into the `body` HTML since
there's no separate phonetic/translation/provenance field.

## Records created
| resource | id(s) | lesson_id |
|---|---|---|
| lessons | 142 (number 141, position 141) | — |
| lesson_blocks | 174–175 | 142 |
| text_passages | 64, 66, 67, 68, 69 (65 superseded by 67 — see below) | 142 |
| phrases | 37–38 | 142 |
| vocabulary_items | 4409 | 142 |

### text_passages (one per titled item)
1. **Tobac Corp** (id 64) — the wake-house tobacco prayer. (FX p.183)
2. **Na Deich nAitheanta** (id 67, corrected; see below) — the versified Ten
   Commandments, under the source's "Alia" section heading; spans p.183
   (phonetic verse) into p.184 (English translation). (FX pp.183–184)
3. **Feóil a' Mhadaigh** (id 66) — the dog-and-reflection fable (cf. Aesop),
   with its stated moral "Never be too greedy". (FX p.184)
4. **An Frog** (id 68) — a short piece on the frog's resemblance to humans.
   (FX p.184)
5. **Trí Ní** (id 69) — a four-line rhyme, signed in the source by Éamonn
   Mhac an Fhailigh himself (the article's author, and author of *The Irish
   of Erris*) — noted in the record body as his own contribution, distinct
   from JD's material. (FX p.184)

### phrases (from "Tobar Beannuighthe")
This item mixes short phonetic fragments into English narration about the
Tobar na bhFiann ("Well of the Fianna") cure-custom, rather than giving a
clean stretch of transcribed text — it fit `phrases` better than
`text_passages`, per the queue's fallback rule.
- **Tá leis ann** (id 37) — "there is a cure in it"; said when the *breac*
  (omen-fish) appears during a visit to the well. (FX p.183)
- **Tá do thurus leat abhaile** (id 38) — companion formula confirming the
  cure has taken effect for the sick person at home. (FX p.183)

### vocabulary_items
- **breac** (id 4409) — glossed here as "trout (omen-fish at a holy well)",
  the fish named in the Tobar Beannuighthe custom. (FX p.183)

### lesson_blocks
1. (id 174) Source & notation: JD/Rinn an Eanaigh background, the notation
   (= IE's, plus æ and h′), the scan-scope discrepancy note above, and a
   note on the untitled item omitted from p.183 (see below).
2. (id 175) A short aside on the source's "Alia" ("other things") section
   heading, which marks the shift from transcribed conversation to
   traditional/formulaic recitations.

## Self-caught transcription error (create-only, no delete tool)
Text_passage **65** ("Na Deich nAitheanta") was first created with a typo —
`sanɴti:` instead of the source's `saɴti:` (an extra inserted "n") in the
sixth line of the commandments verse. Caught by re-comparing against the
400dpi source crop before moving on to the next item. Text_passage **67**
was created as the corrected replacement (see table above). **Record 65 is
flagged for human deletion.**

## Not extracted (out of this unit's scope)
An untitled item opening p.183 — a story about a legendary milk-giving cow
and the place-names "Buaile-ar-a-chosa (for some place name?)", "Bun
Abhanna Buí", and "i bPollach" — is a continuation from p.182, outside this
unit's pp.183–184 scope, beginning mid-sentence with no title in view.
Omitted per the accuracy-over-coverage policy; noted in lesson_block 174.
Could be folded into a future Foxford unit covering p.182 (or nearby), which
would need to be scoped by a human against the article's actual pp.171–182
content first.

## No `[?]` transcription uncertainties
All phonetic glyphs across the six items were legible at 400dpi and
cross-checked directly against the source crops; no ambiguous glyphs
required a `[?]` flag this run (aside from the self-caught typo above, which
was my own transcription slip, not a source-legibility issue).

## Warm-up
Direct HTTP GET to the Fly URL was again blocked by this session's own
sandbox network policy (`CONNECT tunnel failed, response 403`, confirmed via
`/__agentproxy/status` as a policy denial, consistent with all seven prior
runs). The mayo-irish-app MCP connector worked normally throughout (verified
with `list_records` calls before writing), so extraction proceeded per
`EXTRACTION.md` §4.1's "MCP tools still unavailable" carve-out not being
triggered.

## Tooling
`pymupdf` and `pillow` were pip-installed to rasterise pp.183–184 at 200dpi
first (for page-number/scope verification) and then 400dpi with cropped
close-ups (for glyph-level transcription accuracy). No repository files were
changed besides the queue and this report.

## Schema/state check
The queue header's `next_lesson_number` (141) matched the app's actual next
available number exactly — the new lesson was created as id 142, number
141, position 141, confirming `id = number + 1`, the same pattern noted by
all seven prior runs.
