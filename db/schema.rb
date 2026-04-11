# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_11_002129) do
  create_table "lesson_rows", force: :cascade do |t|
    t.text "col_1"
    t.text "col_2"
    t.text "col_3"
    t.datetime "created_at", null: false
    t.integer "lesson_id"
    t.integer "position"
    t.string "row_type", default: "data", null: false
    t.string "section"
    t.datetime "updated_at", null: false
    t.index ["lesson_id", "section", "position"], name: "index_lesson_rows_on_lesson_id_and_section_and_position"
  end

  create_table "lessons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "exercises"
    t.text "grammar"
    t.text "grammar_data"
    t.integer "number", null: false
    t.integer "position", default: 0, null: false
    t.text "texts"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.text "vocabulary_notes"
    t.index ["number"], name: "index_lessons_on_number", unique: true
    t.index ["position"], name: "index_lessons_on_position"
  end

  create_table "vocabulary_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "english", null: false
    t.string "gender", default: "m"
    t.string "irish", null: false
    t.integer "lesson_id", null: false
    t.text "notes"
    t.string "phonetic"
    t.string "plural"
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id", "position"], name: "index_vocabulary_items_on_lesson_id_and_position"
    t.index ["lesson_id"], name: "index_vocabulary_items_on_lesson_id"
  end

  add_foreign_key "lesson_rows", "lessons"
  add_foreign_key "vocabulary_items", "lessons"
end
