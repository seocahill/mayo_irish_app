# EXTRACTION.md — Mayo Irish lesson extraction conventions

This repo drives the nightly extraction of lessons from three DIAS dialect
monographs into the mayo-irish-app (https://mayo-irish-app.fly.dev). One
routine run = one queue unit = one **draft** lesson. A human reviews and
publishes in the admin. Read this whole file before touching anything.

## 1. Sources & repo layout

```
scans/erris_front/   pp. iii–49   from Irish_of_Erris_1_1.pdf
scans/erris_1_2/     pp. 50–131   from Irish_of_Erris_1_2.pdf
scans/erris_3/       pp. 132–189  from Irish_of_Erris__3.pdf
scans/erris_4/       pp. 190+     from Irish_of_Erris__4.pdf
scans/foxford/       full book    FoxfordNOTES_ON_A_MAYO_DIALECT.pdf
scans/tourmakeady/   unscoped     tourmaceady_*.pdf, tourmaceady_201.docx
extraction_queue.yml
EXTRACTION.md        (this file)
reports/             one report per run
```

Upstream: all scans come from https://github.com/seaininoceallaigh —
repos `irishoferris`, `Foxford-Irish`, `The-Irish-of-Tourmakeady`. (The
fourth repo, `proof-of-trace`, is an unrelated web page — not a source.)

One-time setup notes:
- Upstream `irishoferris` holds **four distinct** files: `1.1`, `1.2`, `3`,
  `4`. An earlier note in this file claimed the `1_1 / _1_11 / _1_12`
  variants were byte-identical; that is **wrong for `1.2`**, which is a
  different scan covering pp. 50–131. Do not dedupe them by name.
- As currently downloaded (2026-08-02) **every file is a real PDF**;
  `pdftoppm` works on all of them. Historically some "PDFs" were ZIP
  archives of JPEG spreads — if `pdftoppm` ever fails with syntax errors,
  do `unzip <file> -d scans/<dir>/` and treat the dir as spreads.
- Each PDF page is **one two-page spread** (A4 landscape), left page even,
  right page odd.
- `erris_front` (32 spreads): spread 1 = title page; last spread = pp. 48–49.
- `erris_1_2` (41 spreads): spread `N` = printed pp. `48+2N` and `49+2N`
  — verified exact at N=1 (50–51), N=20 (88–89), N=41 (130–131), no drift.
- `erris_3`: 29 spreads; spread `N` ≈ printed pp. `130+2N` and `131+2N`
  (so 20 ≈ 170–171, 28 = 186–187). **Always verify against the printed
  page numbers on the image** and adjust ±2 spreads.
- `erris_4`: spreads in order; locate by printed page numbers. Foxford is a
  real PDF; rasterise pages as needed.
- Erris pp. iii–189+ are now **fully covered** by the four Erris scans;
  there is no longer a gap at pp. 50–131. Still never invent content for
  any page you cannot see.
- `tourmakeady` holds six files: `tourmaceady_1..4.pdf` (19/21/21/29 pp.),
  `tourmaceady_part1.pdf` (8 pp.) and `tourmaceady_201.docx`. The docx is
  upstream's `tourmaceady%201.docx` (i.e. "tourmaceady 1.docx"); the name
  here keeps the spelling the queue already uses. Page coverage of these is
  still **unscoped** — see §6.

## 2. Content policy

- **Phonetics**: reproduce the author's own notation character-faithfully as
  the primary layer (ʟ ɴ = velarised lateral/nasal; C′ = palatalised; `:` =
  length; ˜ = nasalisation; ə, ʃ, ç, x, γ, ŋ as printed). If a glyph is
  unreadable, give a best guess marked `[?]` and list it in the run report.
- **Orthography**: keep the source's Irish spellings (e.g. *sgéal*, *inghin*);
  do not modernise. Reconstruct a spelling only where the source gives none
  and you are confident; flag reconstructions in notes.
- **Provenance in every record**: cite section and page, e.g. `(§498, IE
  p. 180)`. Book sigla: IE = Mhac an Fhailigh, *The Irish of Erris*; FX =
  *Notes on a Mayo Dialect* (Foxford); TM = de Búrca, *The Irish of
  Tourmakeady*.
- Preserve informant/district attributions where the source gives them
  (Sb, SOG, AOS, POR, EOM; Doohoma / Faulmore / Dú Chaocháin).
- English glosses: plain, learner-friendly, literal sense in quotes where
  idiomatic.

## 3. App schema (learned by probing — trust this over guesses)

Connector: **mayo-irish-app** (MCP). Tools: create_record, update_record,
get_record, list_records. **There is no delete tool.**

| resource | writable fields | gotchas |
|---|---|---|
| lessons | title, number, position, lesson_type | created `published: false`; `content_html` is NOT writable via MCP — put the source note in the first lesson_block |
| grammar_rules | lesson_id, **number (required)**, position, title, body (HTML) | one rule per major topic/class |
| grammar_sections | **grammar_rule_id (required)**, **label** (not "title"), position, body (HTML) | one section per sub-pattern |
| vocabulary_items | lesson_id, irish, english, phonetic, gender (m/f), plural, notes, position | |
| phrases | lesson_id, irish, english, phonetic, notes, position | phonetic/notes columns added 2026-07 |
| lesson_blocks | lesson_id, position, block_type ("text"), body (HTML), caption | |
| text_passages, exercises | **unknown** | probe with one superset create; read validation errors; report the learned schema |

Structural mapping:
- **lesson** = the unit container (lesson_type: `dias_material` unless the
  queue says otherwise; number/position from `next_lesson_number`).
- **grammar_rules** = major topics (declension class, mutation type…).
- **grammar_sections** = sub-patterns; body = one short intro `<p>` + a
  compact HTML `<table>` (headers like nds / Irish / gvs / ndp / gp; use —
  for unattested cells).
- **vocabulary_items** = individually notable words (irregulars, key items).
- **phrases** = idioms and set-phrase examples.
- **lesson_blocks** = block 1: source + abbreviations + notation legend;
  further blocks: short prose asides only. **Never** duplicate paradigm
  tables in blocks.

## 4. Operational rules (safety)

1. **Warm the app first**: it runs on Fly with auto-sleep. GET
   `https://mayo-irish-app.fly.dev/` and retry up to 5 times over ~2 minutes
   until it responds; only then use the MCP tools. If the connector is still
   unavailable, stop and write a report — do not find another write path.
2. **Create-only.** update_record is unreliable in this pipeline ("No
   approval received") and there is no delete. If you create something
   wrong, create the corrected record and list the bad id under "for human
   deletion" in the report.
3. **Draft-only.** Lessons cannot be published via MCP; never try.
4. Touch only the lesson you create — except when a queue entry names an
   explicit `target_lesson_id` to append to.
5. **Never ask, never improvise scope.** If a unit is ambiguous, extract the
   unambiguous core, flag the remainder in the report, and stop.
6. Consume `next_lesson_number` for new lessons and increment it in the
   queue header on completion.

## 5. Run report (reports/YYYY-MM-DD-<unit-id>.md)

Record: created lesson id + record id ranges per resource; §§ and pages
covered; transcription uncertainties (`[?]` list); anything created in error
(for human deletion); schema discoveries; suggested follow-ups for review.

## 6. Out of scope for the routine

- Abairt (transcription corpus) — future validation layer only.
- Queue entries with `status: needs_scoping` — these need an interactive
  session; stop and report if one is at the head of the queue.
- Erris index pp. 217+ — skip permanently.
