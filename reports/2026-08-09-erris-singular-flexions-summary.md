# 2026-08-09 — erris-singular-flexions-summary

## Summary
Appended one grammar_rule to the existing lesson 133 ("Noun Declension in
Erris: Classes I–V"): a summary table of singular flexion patterns for
Classes I–V, reproducing §525 (IE p. 190). No new lesson was created; the
queue's `next_lesson_number` was not consumed, per the unit's own scope.

## Source
- IE (Mhac an Fhailigh, *The Irish of Erris*)
- `scans/erris_4/Irish_of_Erris__4.pdf`, spread 1
- Printed pp. 190–191, verified exact against the printed page numbers on
  the rasterised image (queue's estimate of "first spread ≈ pp. 190-191"
  was correct, no adjustment needed)
- §525 (the table itself sits entirely on p. 190; p. 191 continues into
  §§526–529, prose about plural formation, which is out of scope for this
  unit's "table of singular flexions" target and was not extracted)

## Records created
| resource | id(s) |
|---|---|
| grammar_rules | 216 (lesson_id 133, number 7, position 7) |

No grammar_sections, vocabulary_items, phrases, or lesson_blocks were
created — the queue's structure note specified a single grammar_rule with
the table as its body.

## Pre-flight check
Confirmed grammar_rules numbers 1–6 already exist on lesson 133 (ids
168–173) before creating number 7, as the queue entry required.

## Content notes
- The table reproduces all five declension classes exactly as printed:
  Class I (5 sub-columns A/B/C/D(i)/D(ii), rows nd./gv.), Class II (4
  sub-columns A/B/C/D, rows nv./d./g.), Class III (8 sub-columns
  A(i)/A(ii)/B(i)/B(ii)/B(iii)/C(i)/C(ii)/D, rows nd./g.), Class IV (nil —
  no singular flexion), Class V (4 unlabelled sub-columns, rows nd./g.).
- Phonetic glyphs carried faithfully, including the book's four-way
  lateral/nasal system (ʟ/l/l′/ʟ′, ɴ/n/n′/ɴ′) established in the earlier
  consonant-phonemes lesson (grammar_rules 191–197 on lesson 137). Two
  glyph pairs that look similar at low resolution were verified at 400dpi
  with 2x crops before transcription:
  - Class II column B: `b′iɴ′` (velarised-palatalised ɴ′) throughout,
    contrasting with column D's `gan′...` (plain palatal n′) — confirmed
    the bold small-caps N vs. plain lowercase n distinction is real in the
    source font, not a scan artefact.
  - Class V column 2: `f′aɴu:` / `f′aɴti:/ə` (velarised ɴ) vs. column 3
    `ki:n′u:` / `ki:nt′i:/ə` (plain palatal n′) — same distinction,
    verified the same way.
- No `[?]` transcription uncertainties — all glyphs were legible and
  cross-checked against the zoomed images.

## Pre-existing data-quality issue (flagged, not touched)
Lesson 133's grammar_rules 1–6 exist as **two parallel sets**: ids
168–173 (created 2026-07-06 22:49) and ids 174–179 (created
2026-07-06 23:07, ~18 minutes later, same numbers 1–6, same titles/scope,
reworded-but-equivalent bodies). This predates this routine's queue
history and this unit's scope. Not corrected here: create-only pipeline,
no delete tool, and deduplication is a human decision. **Suggested
follow-up for review**: a human should inspect ids 168–173 vs. 174–179 on
lesson 133 and delete whichever set is the stray duplicate.

## Warm-up
Direct HTTP GET to the Fly URL was blocked by this session's own sandbox
network policy (`CONNECT tunnel failed, response 403`), consistent with
every prior run's notes. The mayo-irish-app MCP connector worked normally
throughout (verified with a `list_records` call before writing), so
extraction proceeded per EXTRACTION.md §4.1's "MCP tools still
unavailable" carve-out not being triggered.

## Tooling
pymupdf + pillow (already installed from a prior run's pip install) were
used to rasterise spread 1 at 200dpi and 400dpi and crop close-ups for
glyph verification. No repository files were changed besides the queue
and this report.
