# Course designer: design

Status: **design only, nothing built.** Written 2026-11-14 from a conversation
with the owner. The architect and builder can slice it into issues (see §9).
It serves the "powerful course design interface" priority in `VISION.md`.

## 1. The idea

Darren is the only person who holds every element a Mayo Irish course needs,
and his time is scarce. The course designer is an agent plus a channel that
lets him shape the course with the least possible friction:

- the **agent** reads all the data we hold and proposes lessons, changes,
  merges and retirements, and finds the material behind each proposal;
- the **channel** is a small MCP server he reaches from the chat app on his
  phone (ChatGPT or any other), where he reviews proposals, answers one-line
  questions and speaks his own ideas in English;
- the **structure** of the course is decided in English. The Irish content is
  filled in afterwards, in small jobs, from sources or by hand.

## 2. What exists today (and what this adds)

| Exists | Role |
|---|---|
| Nightly extractor (`ROUTINE_PROMPT.md`, `EXTRACTION.md`) | monograph scans to draft lessons; create-only |
| Architect and builder (`ARCHITECT.md`, `BUILDER.md`) | product and code, via GitHub issues |
| Admin MCP (`app/services/mcp/`) | generic list/get/create/update; OAuth with dynamic registration; no delete; lessons always drafts |
| PaperTrail and `VersionUndo` | every edit versioned and reversible |
| `RecordingSuggestion` | the pending / approved / rejected pattern, for recordings only |
| `AbairClient#recognise`, `AbairtClient` | ABAIR speech recogniser; Abairt search and recordings |

The designer is the **content-level** agent the other three lack. It does not
replace any of them. It can feed the extractor ("extract Erris §§ on X for
lesson Y") by proposing queue entries.

## 2a. The one rule from `VISION.md` that shapes everything

The tool never writes Irish into the course itself. So the designer's output
is **structure in English plus sourced material**, never drafted Irish.
Irish enters the course only from: monograph text, Abairt, other cited
sources, or a native speaker's own confirmed words. A proposal can quote Irish
from a source, verbatim, with provenance.

## 3. Roles and access

- **Darren** is a normal user who logs in with a username and password. He
  gets a new, narrow `editor` role (a nullable column). The OAuth connector he
  authorises can reach **only** the designer toolset (§6), never the generic
  create/update tools. Least privilege.
- **Admins** keep the generic admin MCP.
- **The designer agent** runs as a scheduled routine (like the extractor)
  with a create-only tool, `create_proposal`, and read access to the app and
  Abairt. It never edits course content.
- Up to four people use the app in a private beta, so web research is fair
  use (owner, 2026-11-14). Even so, record the URL as provenance on every
  web-derived item, and treat web finds as **leads**, not evidence, until a
  person or a better source confirms them.

## 4. Data model (all new tables; none of this mutates existing data)

**`course_proposals`**

- `origin`: `designer` or `darren` (or another contributor)
- `kind`: `new_lesson`, `revise_lesson`, `merge`, `retire`, `cross_reference`,
  `recording_match`, `reorder`, `gap`, `dialect_question`, `extraction_request`
- `target`: polymorphic (a lesson, vocabulary item, grammar rule, and so on)
- `title`, `rationale` (English)
- `outline` (structured English: sections, what to teach, in what order)
- `status`: `captured → grounded → proposed → discussing → accepted → applied`,
  or `edited` / `dismissed` / `deferred`
- `priority`, `created_by_run`, `decided_by`, `decided_at`
- `raw_text`: for Darren's ideas, **his words verbatim**, never overwritten

**`proposal_evidence`**: one row per supporting item. It carries provenance
(book sigla and § and page, or Abairt entry id and speaker, or URL and date
retrieved), a verbatim quote if any, and a link to audio if any.

**`proposal_comments`**: the discussion thread, so his feedback is data.

**`lesson_slots`**: placeholders for Irish content (see §5).

**`designer_preferences`**: standing preferences learned from dismissals and
answers, like the "Standing preferences" section of `DECISIONS.md`, so nothing
is re-proposed without new evidence.

## 5. Slots: Irish content as small, fillable jobs

A **slot** is a real record, never fake Irish typed into a lesson.

- Fields: `lesson_id`, `slot_type` (example sentences, vocabulary, phrases,
  dialogue, listening clip, grammar table), `spec` in English ("3 to 5
  example sentences for the conditional after `dá`, Erris preferred"),
  `status` (`open`, `candidates_ready`, `filled`, `removed`), `filled_by`,
  `filled_at`, and a reference to the record created when filled.
- Slots belong to the draft lesson that needs them. We never put "TODO"
  strings into `vocabulary_items.irish` or lesson blocks.
- **A lesson with open slots cannot be published.** The admin UI shows
  "7 slots open" and blocks publishing until they are filled or removed.
  Publishing is already human-only; this adds one check.
- **Caps** keep slots from piling up: a maximum number of drafts with open
  slots at once, and the weekly summary lists the oldest open slots.
- **Merging existing lessons needs no new Irish.** A merge proposal builds a
  new draft outline that **references** existing blocks, vocabulary and
  phrases. Only genuinely new material gets slots. Old lessons are retired
  only when Darren accepts.
- The agent pre-fills slots with **candidates**: sourced items from Abairt,
  the monographs, the Focail Fholaithe and the web, with provenance and
  audio. Filling a slot is then a pick, a recording or a typed entry. Anyone
  among the four can fill one, and each fill is credited.

## 6. Darren's toolset (a separate MCP surface)

About a dozen tools, named for conversation, not CRUD. Reads are marked
read-only; no tool deletes anything.

| Tool | What it does |
|---|---|
| `what_changed` | opens a session: what became of his ideas, what is waiting on him |
| `review_queue` | next 3 to 5 proposals, two lines each, ranked |
| `get_proposal` | rationale, evidence, quotes, audio links |
| `respond` | accept, dismiss, edit, ask a question or defer, with a note |
| `capture_idea` | stores his idea verbatim; Irish terms go in a separate field (§7) |
| `answer_question` | answers one of the designer's open questions |
| `fill_queue` | open slots, one job at a time, with candidates |
| `fill_slot` | pick a candidate, attach a recording or enter typed Irish |
| `where_is_taught` | where a word or rule is taught, heard and reviewed |
| `search_corpus` | search lessons, Abairt, monograph reports |

The server's own MCP `instructions` field tells the chat app how to behave:
never guess Irish spelling from dictation; ask Darren to type it or pick a
candidate; keep each exchange to a single question he can answer in a line.

## 7. Darren's own ideas

Ideas flow through the same table and queue as the agent's proposals.

1. **Capture.** He speaks or types English. `capture_idea` stores his words
   verbatim with a timestamp. The chat app's interpretation sits beside them
   and never replaces them.
2. **Grounding.** The agent finds the corpus material behind the idea,
   notes which existing lessons it touches, and asks only the questions data
   can't answer, each answerable in one line.
3. **Merging.** When an idea overlaps an agent proposal or an earlier idea,
   the agent links or merges them and credits both origins. His ideas rank
   above the agent's by default.
4. **Closing the loop.** `what_changed` tells him "you said X, it became
   draft lesson 147" or "you said Y, one question is waiting".

### Irish inside an idea

Dictated Irish will be mangled by speech-to-text. Resolve it in this order,
first success wins:

1. **The agent finds it.** From his English description it searches Abairt,
   the Focail Fholaithe and the monograph reports and offers two or three
   candidates with audio. He says "the second one". Spelling comes from a
   source, never from a transcription.
2. **A one-tap recording link.** If nothing matches, the tool returns a
   short link to a mobile page. He holds to record, `AbairClient#recognise`
   proposes a transcript, and he confirms or corrects it by typing. The
   recording is kept as evidence. ABAIR's output is a **draft only**: its
   accuracy on Mayo speech is unproven (5 MB limit per clip). Treat it as a
   convenience until tested on real Abairt clips.
3. **He types or spells it.**

Every Irish string carries a status: `unverified`, `confirmed_by_speaker` or
`matched_to_source`. Only the last two can reach a lesson draft. Irish he
types or confirms is stored as his contribution, with his name as
provenance. This is allowed by `VISION.md` because it comes from a native
speaker, not from the tool.

## 8. Accepting and applying

- **Accept** is Darren's explicit decision.
- **New lessons**: accept creates a **draft** with its slots. A human
  publishes, as today.
- **Edits to existing content** (revise, merge, retire, reorder): accept
  applies the change through the normal versioned path, so it is undoable
  with `VersionUndo`. Retire means unpublish, never delete.
- The agent never applies anything.
- **Decided (owner, 2026-11-14):** accepting an edit to existing content
  applies it straight away, versioned and undoable. Because applying changes
  existing data (Stop 1, `CADENCE.md`), the owner's yes covers the approach,
  not each build: open a `data-change` issue (`needs-human`) for each kind of
  apply (revise, merge, retire, reorder) as the build reaches it, and merge
  that PR only after the owner adds `approved`.

## 9. Phased plan (each step ships alone)

1. **Foundations.** `course_proposals`, `proposal_evidence`,
   `proposal_comments`, `lesson_slots`; the `editor` role; a narrow OAuth
   scope; an admin list view of proposals.
2. **Idea inbox.** `capture_idea` and `what_changed`. Darren gets a
   voice-friendly place to dump ideas, useful before the agent is any good.
3. **Coverage report.** The designer writes a read-only markdown report
   (gaps, duplicates, cross-references, missing themes) in `reports/`, no
   schema needed. This tests suggestion quality early.
4. **Designer routine.** It writes proposals through `create_proposal` and
   grounds Darren's ideas.
5. **Review tools.** `review_queue`, `get_proposal`, `respond`,
   `answer_question`, `where_is_taught`, `search_corpus`.
6. **Slots.** The slot model, the publish guard, `fill_queue`, `fill_slot`,
   the one-tap recording page.
7. **Accept-to-apply**, one kind at a time, starting with new-lesson drafts.
8. **Preference learning and web research.**

Step 2 may be built before step 1 finishes if it is the smallest way to give
Darren value. Before step 5, check ChatGPT's current requirements for custom
remote MCP connectors (transport, OAuth and tool-confirmation behaviour), as
this has not been verified.

## 9a. Source intake and the extractor

Today `extraction_queue.yml` is hand-written. Nothing records which files
exist in `scans/`, which pages are covered or whether a file changed, so a
newly dropped file is invisible to the nightly routine. The Tourmakeady files
have never been processed: the queue's `tourmakeady-scoping` entry tells the
routine to stop, and it has written a "needs scoping" report almost every
night since August. Fix this in front of the extractor, not by merging
everything into one process.

- **Keep the extractor separate.** Its rules (create-only, draft-only, never
  improvise scope) are what make it safe to run unattended. Nothing here
  loosens them.
- **Source manifest.** A generated `scans/MANIFEST.yml` lists each source
  file with its hash, page count and status (`new`, `inventoried`, `scoped`,
  `extracting`, `done`), plus page ranges covered and the lesson and record
  ids created from them. A small script flags files that are new or whose hash
  changed. The format is the builder's call, as long as it works.
- **Scoper step (proposes only).** For a new or unscoped file the routine
  inventories it instead of stopping: it rasterises pages, reads the printed
  page numbers and contents, and writes proposed units to the queue with
  `status: proposed`. A person approves them, and only then do they become
  `pending`.
- **The designer's front door.** The `extraction_request` proposal kind
  (§4) is where approval happens. Darren sees "Tourmakeady pp. 3 to 9,
  proposed as unit T1" in his queue and accepts it, and a queue entry
  appears. Until the designer exists, approval is a manual edit of the queue.
- **Quiet when idle.** With nothing pending or proposed, the routine writes
  no report and makes no commit. At most it updates one open issue.
- **Rule across the system:** agents propose, a person decides, and the
  extractor only builds what was approved.

First slice (needs no schema change): the manifest and its script, plus the
quiet-when-idle change. It unblocks Tourmakeady without waiting for the
designer.

## 10. Guardrails (from `VISION.md` and `CADENCE.md`)

- Never invent, correct or normalise Irish or dialect forms. Dialect labels
  stay as sources and speakers give them.
- Every item carries provenance. Web finds are leads until confirmed.
- No guilt mechanics or nagging toward Darren: his queue is capped, and
  questions are single and short.
- Dialect decisions ("which form first?") are always questions to Darren, never
  silent choices.
- No delete tool anywhere in the designer's surface.
- Collect only what helps the course; recordings are the speakers' and
  Abairt's.

## 11. Open questions

1. ~~Accept-to-apply for edits to existing content~~ decided (§8).
2. Which chat app does Darren actually use, and what do its connectors
   require? (Verified before step 5.)
3. How large should the caps be: pending proposals in his queue, and
   drafts with open slots?
4. Who among the four fills slots, besides Darren?
