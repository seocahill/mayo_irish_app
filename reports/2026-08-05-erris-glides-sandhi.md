# Extraction report — erris-glides-sandhi (2026-08-05)

## Summary

Created draft lesson **138** ("The Sound System of Erris III: glides,
nasalization & the opening of sandhi", `number: 137`) covering IE
(Mhac an Fhailigh, *The Irish of Erris*) Chapter V "Glides" (§§195–205),
Chapter VI "Nasalization" (§§206–209), and the opening of Chapter VII
"Sandhi" (§§210–217, incomplete — see Scope below). Source: pp. 45–49,
`scans/erris_front/Irish_of_Erris_1_1.pdf` spreads 30–32, verified exact
against the printed page numbers on the images (spread 30 = pp.44–45,
where Chapter V begins exactly at §195/p.45; spread 32 = pp.48–49, the
last spread in the scan).

## Records created

| resource | ids |
|---|---|
| lessons | 138 |
| lesson_blocks | 166–167 |
| grammar_rules | 198–200 |
| grammar_sections | 449–460 |
| vocabulary_items | 4392–4395 |
| phrases | 25–27 |

Structure:
- **grammar_rule 198** "Glides (§§195–205)" — sections 449 (off-glides,
  §198), 450 (on-glides, §§199–202), 451 (transitional d/t stop in ʟr/nr
  clusters, §§203–205).
- **grammar_rule 199** "Nasalization (§§206–209)" — sections 452
  (nasalized vowels, §§206–207), 453 (nasalization of w/v′, §208), 454
  (nasalized r, §209).
- **grammar_rule 200** "Sandhi: opening rules (§§210–217, incomplete)" —
  sections 455–460, one per numbered assimilation pattern §§212–217.
- **lesson_blocks** 166 (source/notation) and 167 (scope note on the
  missing "stress" chapter and the sandhi continuation).
- **vocabulary_items** 4392 comhra, 4393 geamhar, 4394 maide rámha, 4395
  sgannraigh.
- **phrases** 25 gan rath, 26 an gcluin tú?, 27 ní fhuil aon chiall leis.

## Scope note (re-scoping during extraction)

The queue entry anticipated a "glides, stress & sandhi" unit. On inspection
of pp.45–49, there is **no standalone stress chapter** in this range: the
scan runs Chapter V Glides → Chapter VI Nasalization → the start of
Chapter VII Sandhi, with no stress chapter between or after them. Chapter
VII "Sandhi" is itself **not complete** within this scan — its last visible
paragraph, §217, is cut off mid-sentence at the physical page break between
printed p.49 (end of `erris_front`) and p.50 (start of `erris_1_2`, a
different scan file). Per EXTRACTION.md's "extract the unambiguous core,
flag the remainder, stop" rule, this lesson includes the complete,
self-contained core (Glides, Nasalization, and Sandhi §§210–216) plus the
introduced-but-truncated §217, with the missing final gloss marked `[?]`
in grammar_section 460 rather than invented.

**Follow-up needed:** a new queue unit for the continuation of Chapter VII
Sandhi (and any stress chapter that may follow it) starting at printed
p.50, using `scans/erris_1_2/` (spread N = pp. 48+2N / 49+2N, so p.50 =
spread 1). This also closes out `erris_front` as a source — all of pp.
iii–49 are now covered across the four erris front/vowel/consonant/
glide-sandhi lessons (135–138).

## [?] transcription uncertainties

- **grammar_section 460 (§217)**: the chapter's last example, `si:v′əɴ
  dit′`, has no Irish-spelling gloss visible in the scan — the source text
  is cut off by the physical page break at the end of printed p.49 (last
  page of `erris_front`); the gloss is presumably on p.50 in
  `scans/erris_1_2/`, out of scope for this unit. Recorded as `[?]` with an
  explanit note rather than guessed.

## Schema / pipeline notes

- `vocabulary_items.gender` again defaulted server-side to `"m"` for all
  four records created here, though gender was not supplied in any create
  call and not all four words are straightforwardly gendered nouns. Same
  behaviour flagged in the 2026-08-03 and 2026-08-04 reports; still not
  correctable from the MCP writable-fields list.
- Direct HTTP warm-up (`GET https://mayo-irish-app.fly.dev/`) was blocked
  again by this session's own sandbox network proxy (`403` to `CONNECT`,
  confirmed via `/__agentproxy/status` as a policy denial, not an app-sleep
  issue) — identical to the 2026-08-04 run. The `mayo-irish-app` MCP
  connector worked normally throughout and was explicitly verified with a
  `get_record` call before any writes, so EXTRACTION.md §4.1's stop
  condition ("MCP tools still unavailable") was not triggered.
- No `poppler-utils` preinstalled; `pymupdf` and `pillow` were
  pip-installed in-session to rasterise pages at high DPI for visual
  page-number verification and precise phonetic transcription (no repo
  files changed).

## Suggested follow-ups for review

1. Scope and add a queue unit for the Chapter VII Sandhi continuation
   (+ possible stress chapter) starting at IE p.50, `scans/erris_1_2/`.
2. Human check on `comhra` (vocabulary_item 4392, "coffin") — flagged in
   its own notes for orthographic closeness to `comhrá` ("conversation");
   the source doesn't disambiguate at this point in the text, worth
   double-checking against a dictionary before publishing.
3. Same recurring `gender` defaulting issue as prior lessons — a candidate
   for a small schema/UI fix upstream (default to null, not "m", when
   gender isn't supplied) rather than a per-record fix.
