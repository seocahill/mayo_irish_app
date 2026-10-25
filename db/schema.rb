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

ActiveRecord::Schema[8.1].define(version: 2026_10_25_000002) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.integer "chat_session_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["chat_session_id"], name: "index_chat_messages_on_chat_session_id"
  end

  create_table "chat_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lesson_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["lesson_id"], name: "index_chat_sessions_on_lesson_id"
    t.index ["user_id"], name: "index_chat_sessions_on_user_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.text "answer"
    t.datetime "created_at", null: false
    t.integer "lesson_id", null: false
    t.integer "number", null: false
    t.integer "position", default: 0, null: false
    t.text "prompt", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id", "position"], name: "index_exercises_on_lesson_id_and_position"
    t.index ["lesson_id"], name: "index_exercises_on_lesson_id"
  end

  create_table "grammar_rules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lesson_id", null: false
    t.integer "number", null: false
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id", "position"], name: "index_grammar_rules_on_lesson_id_and_position"
    t.index ["lesson_id"], name: "index_grammar_rules_on_lesson_id"
  end

  create_table "grammar_sections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grammar_rule_id", null: false
    t.string "label"
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["grammar_rule_id", "position"], name: "index_grammar_sections_on_grammar_rule_id_and_position"
    t.index ["grammar_rule_id"], name: "index_grammar_sections_on_grammar_rule_id"
  end

  create_table "lesson_blocks", force: :cascade do |t|
    t.string "block_type"
    t.string "caption"
    t.datetime "created_at", null: false
    t.integer "lesson_id", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["lesson_id"], name: "index_lesson_blocks_on_lesson_id"
  end

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
    t.text "content_html"
    t.datetime "created_at", null: false
    t.text "exercises"
    t.text "grammar"
    t.text "grammar_data"
    t.string "lesson_type", default: "curriculum", null: false
    t.integer "number", null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.text "texts"
    t.string "title", null: false
    t.text "tutor_prompt"
    t.datetime "updated_at", null: false
    t.text "vocabulary_notes"
    t.index ["lesson_type"], name: "index_lessons_on_lesson_type"
    t.index ["number"], name: "index_lessons_on_number", unique: true
    t.index ["position"], name: "index_lessons_on_position"
    t.index ["published"], name: "index_lessons_on_published"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer "application_id", null: false
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.integer "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in"
    t.string "previous_refresh_token", default: "", null: false
    t.string "refresh_token"
    t.integer "resource_owner_id"
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.string "secret"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "phrases", force: :cascade do |t|
    t.string "audio_url"
    t.datetime "created_at", null: false
    t.text "english"
    t.text "irish", null: false
    t.integer "lesson_id", null: false
    t.text "notes"
    t.string "phonetic"
    t.integer "position", default: 0, null: false
    t.integer "source_id"
    t.string "source_type"
    t.datetime "updated_at", null: false
    t.index ["lesson_id", "position"], name: "index_phrases_on_lesson_id_and_position"
    t.index ["lesson_id"], name: "index_phrases_on_lesson_id"
    t.index ["source_type", "source_id"], name: "index_phrases_on_source_type_and_source_id"
  end

  create_table "quiz_questions", force: :cascade do |t|
    t.string "answer", null: false
    t.datetime "created_at", null: false
    t.string "direction", null: false
    t.json "distractors", default: [], null: false
    t.integer "lesson_id", null: false
    t.text "prompt", null: false
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_quiz_questions_on_lesson_id"
    t.index ["source_type", "source_id", "direction"], name: "index_quiz_questions_uniqueness", unique: true
    t.index ["source_type", "source_id"], name: "index_quiz_questions_on_source"
  end

  create_table "quiz_reviews", force: :cascade do |t|
    t.integer "box", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "due_at"
    t.datetime "last_reviewed_at"
    t.integer "quiz_question_id", null: false
    t.integer "times_correct", default: 0, null: false
    t.integer "times_wrong", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["quiz_question_id"], name: "index_quiz_reviews_on_quiz_question_id"
    t.index ["user_id", "due_at"], name: "index_quiz_reviews_on_user_id_and_due_at"
    t.index ["user_id", "quiz_question_id"], name: "index_quiz_reviews_on_user_id_and_quiz_question_id", unique: true
    t.index ["user_id"], name: "index_quiz_reviews_on_user_id"
  end

  create_table "review_logs", force: :cascade do |t|
    t.datetime "answered_at", null: false
    t.integer "box_after", null: false
    t.integer "box_before", null: false
    t.boolean "correct", null: false
    t.datetime "created_at", null: false
    t.string "prompt", null: false
    t.integer "quiz_question_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["quiz_question_id"], name: "index_review_logs_on_quiz_question_id"
    t.index ["user_id", "answered_at"], name: "index_review_logs_on_user_id_and_answered_at"
    t.index ["user_id"], name: "index_review_logs_on_user_id"
  end

  create_table "section_progresses", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "lesson_id", null: false
    t.string "section_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["lesson_id"], name: "index_section_progresses_on_lesson_id"
    t.index ["user_id", "lesson_id", "section_type"], name: "index_section_progresses_uniqueness", unique: true
    t.index ["user_id"], name: "index_section_progresses_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "text_passages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lesson_id", null: false
    t.integer "position", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["lesson_id", "position"], name: "index_text_passages_on_lesson_id_and_position"
    t.index ["lesson_id"], name: "index_text_passages_on_lesson_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.boolean "approved", default: false, null: false
    t.datetime "created_at", null: false
    t.string "dialect_region"
    t.string "door"
    t.string "email_address", null: false
    t.datetime "onboarded_at"
    t.string "password_digest", null: false
    t.string "place"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "vocabulary_items", force: :cascade do |t|
    t.string "audio_url"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chat_messages", "chat_sessions"
  add_foreign_key "chat_sessions", "lessons"
  add_foreign_key "chat_sessions", "users"
  add_foreign_key "exercises", "lessons"
  add_foreign_key "grammar_rules", "lessons"
  add_foreign_key "grammar_sections", "grammar_rules"
  add_foreign_key "lesson_blocks", "lessons"
  add_foreign_key "lesson_rows", "lessons"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "phrases", "lessons"
  add_foreign_key "quiz_questions", "lessons"
  add_foreign_key "quiz_reviews", "quiz_questions"
  add_foreign_key "quiz_reviews", "users"
  add_foreign_key "review_logs", "quiz_questions", on_delete: :nullify
  add_foreign_key "review_logs", "users"
  add_foreign_key "section_progresses", "lessons"
  add_foreign_key "section_progresses", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "text_passages", "lessons"
  add_foreign_key "vocabulary_items", "lessons"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "search_documents", "fts5", ["record_type UNINDEXED", "record_id UNINDEXED", "lesson_number UNINDEXED", "title", "body", "tokenize = \"unicode61 remove_diacritics 2\""]
end
