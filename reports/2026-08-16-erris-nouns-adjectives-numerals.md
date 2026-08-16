# Extraction report — erris-nouns-adjectives-numerals (2026-08-16)

## Summary

Created lesson 143 (number 142), "Nouns, Adjectives & Numerals in Erris:
flexions, the dual, comparison, counting", from IE Chapter XIX "Nouns and
Adjectives" continuation (§§530–561), pp. 192–199. Source:
`scans/erris_4/Irish_of_Erris__4.pdf` spreads 2–5, verified exact against
printed page numbers (no ±2 spread adjustment needed — the queue's own
2026-08-15 boundary check held precisely). This continues directly from
lesson 133 (pp.190–191, §§525–529) and ends exactly at the p.199/p.200
boundary where Chapter XX "Pronouns, Prepositions, etc." begins (§562) —
confirmed by direct inspection, so no gap or overlap with the next queued
unit (erris-pronouns-prepositions).

## Records created

| resource | ids |
|---|---|
| lessons | 143 (number 142) |
| lesson_blocks | 176–177 |
| grammar_rules | 217–221 |
| grammar_sections | 513–533 (513 superseded by 514) |
| vocabulary_items | 4410–4413 |
| phrases | 39–41 |

## Structure

Five grammar_rules, one per numbered subsection of the queue's scoping,
21 grammar_sections total:

1. **Further plural-suffix classes & the genitive plural** (§§530–534) — 3
   sections: classes (i)–(v) table (p.192); classes (vi)–(x) table incl.
   the bláth/tráigh coalescence forms (p.193); genitive plural formation &
   dialectal instability (§§531–534).
2. **The dual** (§535) — 1 section: nom./dat. syncretism, gen. = gen. pl.,
   7 examples incl. *dhá dtrian*, *greim dhá chos air*.
3. **Declension of adjectives** (§§536–544) — 4 sections: living vs.
   petrified forms + the *mór* paradigm table (masc./fem. × n./d./g./v.);
   vowel-change gs. forms (*deas*, *dubh/trom*, *maith*);
   disyllabic/trisyllabic *uasal* + the inconclusive -úil/-mhar data;
   indeclinable -ach and vowel-final adjectives.
4. **Comparatives** (§§545–551) — 5 sections: regular -C/-C'ə; vowel-change;
   disyllabic stem alternation & syncope; -əx/-i: and -xd'ə forms; irregular
   comparatives table (incl. *olc*→m'asə, *maith*→f'a:r, *mór*→mu:).
5. **Numerals** (§§552–561) — 7 sections: cardinals; forms used before
   nouns with *ceann*; noun number & initial mutation after 3–10;
   approximate numbers with *nó* & age idioms with *i gcionn*; noun form
   after *cupla/céad/fiche/míle*; ordinals; collectives.

Four vocabulary_items (*olc*, *maith* — suppletive comparatives; *alt*
'cliff' — the source's own bracketed gloss flags a specialized local sense
distinct from the standard 'joint'; *fada* — irregular comparative fid'ə).
Three phrases (*dhá dtrian*, *bó i gcionn a dhá bhliain*, *cúigear nó
seisear*). Two lesson_blocks: source/notation + a short aside on chapter
shape and the p.200/§562 boundary into the next unit.

## Transcription error caught and corrected (create-only, no delete tool)

- **grammar_section 513** (plural-suffix classes (i)–(v), p.192): I
  mistakenly included a row for *cioth* (k'ahəni:) and the *bláth/tráigh*
  coalescence examples in this section. On re-checking against the source
  image, both actually belong to class (vi) and the (vi)/(vii) boundary on
  the facing page (p.193) — not classes (i)–(v). Caught before moving on.
  **grammar_section 514** was created as the corrected replacement (without
  the misplaced rows); the *cioth* row and coalescence examples were
  correctly placed in **grammar_section 515** (classes (vi)–(x)) instead.
  **513 is flagged for human deletion.**

No [?] transcription uncertainties beyond the above — all glyphs in this
range were legible on the 200dpi renders.

## Schema / state notes

- `get_record` on lesson 142 before creating confirmed id=142, number=141
  (id = number+1), matching `next_lesson_number: 142` in the queue header
  exactly — same pattern noted by every prior run.
- `vocabulary_items.gender` again defaulted to "m" server-side for all four
  records in this unit even though gender was not set in the create call
  (recurring schema quirk noted in every prior unit's report; not corrected
  here since it is not in the writable-fields list).

## Environment notes

- Direct HTTP warm-up (`GET https://mayo-irish-app.fly.dev/`) was again
  blocked by this session's own sandbox network policy
  (`EGRESS_BLOCKED` via WebFetch) — consistent with all eight prior runs.
  The mayo-irish-app MCP connector worked normally throughout (verified
  with a `get_record` call before writing), so extraction proceeded per
  EXTRACTION.md §4.1's "MCP tools still unavailable" carve-out not being
  triggered.
- `pymupdf` + `pillow` were pip-installed to rasterise pages at 200dpi for
  visual page-number verification (no repo files changed; poppler-utils
  still not preinstalled in this environment).

## Suggested follow-ups for review

- Delete grammar_section 513 (superseded, see above).
- Publish lesson 143 once reviewed.
- Next queue unit (erris-pronouns-prepositions) is scoped and ready; its
  page boundaries were already verified 2026-08-15 alongside this unit's.
