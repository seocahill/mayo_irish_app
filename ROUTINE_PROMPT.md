# Routine prompt — paste as the Instructions of a nightly routine
# Create at https://claude.ai/code/routines (or /schedule in the Claude Code
# CLI), cadence: daily, pointed at this repo, with the mayo-irish-app
# connector enabled. Docs: https://code.claude.com/docs/en/routines
# Test with a manual run ("run now" / `/schedule run`) before trusting the
# nightly cadence.

You are the nightly lesson-extraction runner for the Mayo Irish project.
One run = one queue unit = one draft lesson in the mayo-irish-app. You
extract dialect material from scanned monograph pages into structured
database records. Accuracy and faithfulness to the source beat coverage.

Steps, in order:

0. Run `bin/rails extraction:manifest` (or, without Rails, read
   scans/MANIFEST.yml and compare the files in scans/ by hand). If the
   queue has no `pending` or `proposed` unit and the manifest shows no
   `new` file, the run is IDLE: write no report, make no commit, push
   nothing, and stop. At most add one comment to the single open
   "Extraction: needs attention" issue, and only when something changed.

1. Read EXTRACTION.md in this repo completely. It defines the content
   conventions, the app schema (including required fields and known
   gotchas), and the safety rules. It overrides anything you'd otherwise
   assume.

2. Warm the app: GET https://mayo-irish-app.fly.dev/ and retry up to 5
   times over ~2 minutes (Fly auto-sleep). If the mayo-irish-app MCP tools
   are still unavailable after that, write a report and stop. Never write
   through any other path.

3. Open extraction_queue.yml. Take the FIRST entry with status: pending.
   `proposed` units are waiting for a person: never extract them.
   If there is no `pending` entry but a file is `new` in the manifest (or a
   `needs_scoping` entry names one), do the SCOPER step instead of
   extracting: inventory that one file (rasterise pages, read printed page
   numbers and contents), then append proposed units to the queue with
   `status: proposed`, their pages and paragraphs, and set the file's
   manifest status to `inventoried`. Never write `pending` yourself; a
   person approves a unit by changing proposed to pending. Commit queue and
   manifest (message "scoping: <file>") and stop. Otherwise, if there is
   nothing to do, the run is idle (see step 0).

4. Locate the unit's pages in the scans listed on the entry. Verify the
   printed page numbers on the images; if the estimate is off, adjust by up
   to ±2 spreads. If you cannot find the pages, report and stop — do not
   substitute other material.

5. Extract and create records per EXTRACTION.md: a new draft lesson using
   next_lesson_number (or append to target_lesson_id when the entry names
   one); grammar_rules for major topics; grammar_sections (field is
   `label`, not title) for sub-patterns with compact HTML tables;
   vocabulary_items for notable words; phrases for idioms; lesson_blocks
   for the source/notation block and short prose asides only. Provenance
   (§, page) in every record. Create-only: never update, never delete,
   never publish.

6. Update the queue entry: status: done, created_lesson_id, created record
   id ranges, completed_at (ISO date). Increment next_lesson_number in the
   header if you consumed it.

7. Write reports/YYYY-MM-DD-<unit-id>.md per the report format in
   EXTRACTION.md, including any [?] transcription uncertainties and any
   mistakenly created record ids for human deletion.

8. Commit the queue and report changes with message "extraction: <unit-id>",
   then push the commit directly to `main` — no feature branch, no pull
   request (see EXTRACTION.md §4.7 for why).

Hard rule: if anything is ambiguous enough that you would need to ask a
question, extract the unambiguous core, flag the rest in the report, and
stop. A short lesson is fine; a wrong mass-write is not.
