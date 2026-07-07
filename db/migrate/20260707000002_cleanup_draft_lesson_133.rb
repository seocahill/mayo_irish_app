# frozen_string_literal: true

# One-off data cleanup for the draft lesson "Noun Declension in Erris: Classes
# I–V" (Lesson 133), created through the MCP connector. Every operation is
# guarded so this is a safe no-op on databases where the records don't exist
# (development, test, CI). Runs once on production via the deploy migration.
class CleanupDraftLesson133 < ActiveRecord::Migration[8.1]
  LESSON_ID = 133

  def up
    lesson = Lesson.find_by(id: LESSON_ID)
    return unless lesson

    # (a) Drop the four superseded HTML-table lesson blocks, but only if they
    # still belong to this lesson — never delete a recycled id on another lesson.
    LessonBlock.where(id: [149, 150, 151, 152], lesson_id: LESSON_ID).destroy_all

    # (b) Give the first grammar section a proper label.
    GrammarSection.where(id: 359, grammar_rule_id: lesson.grammar_rules.select(:id))
                  .update_all(label: "A — monosyllables, allophonic change (§§497–498(i))")

    # (c) Fold the phonetics and source reference into the phrase gloss.
    Phrase.where(id: 1, lesson_id: LESSON_ID)
          .update_all(english: "keening woman (professional mourner; lit. 'woman " \
                               "of the lamenting') /b′an ə xiɴt′ə/ — VN caoineadh, " \
                               "gen. = participle caointe (§523)")
  end

  def down
    # Content cleanup; nothing meaningful to restore.
  end
end
