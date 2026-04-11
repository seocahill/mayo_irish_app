class CreateLessonStructure < ActiveRecord::Migration[8.1]
  def change
    create_table :grammar_rules do |t|
      t.references :lesson, null: false, foreign_key: true
      t.integer :number,   null: false
      t.string  :title,    null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :grammar_rules, [ :lesson_id, :position ]

    create_table :grammar_sections do |t|
      t.references :grammar_rule, null: false, foreign_key: true
      t.string  :label              # "(i) Forms", nil for unlabelled intro text
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :grammar_sections, [ :grammar_rule_id, :position ]

    create_table :text_passages do |t|
      t.references :lesson, null: false, foreign_key: true
      t.string  :title
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :text_passages, [ :lesson_id, :position ]

    create_table :exercises do |t|
      t.references :lesson, null: false, foreign_key: true
      t.integer :number,   null: false
      t.text    :prompt,   null: false   # English sentence to translate
      t.text    :answer                  # Irish — blank initially
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :exercises, [ :lesson_id, :position ]

    create_table :phrases do |t|
      t.references :lesson, null: false, foreign_key: true
      t.text    :irish,     null: false
      t.text    :english
      t.string  :source_type   # "GrammarSection", "TextPassage", "Exercise"
      t.integer :source_id
      t.string  :audio_url     # cached abair.ie TTS
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :phrases, [ :lesson_id, :position ]
    add_index :phrases, [ :source_type, :source_id ]
  end
end
