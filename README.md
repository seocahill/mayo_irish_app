# Gaeilge Mhaigh Eo — Mayo Irish Learning Platform

A structured online course for the Mayo dialect of Irish, built on Rails 8.
Based on *Learning Irish* by Mícheál Ó Siadhail, adapted for Connacht/Mayo Irish.

## Stack

- **Ruby on Rails 8** (SQLite, Propshaft, Hotwire)
- **Tailwind CSS** with `@tailwindcss/typography`
- **Stimulus** for the vocabulary table editor
- No authentication yet — add `rails generate authentication` when ready

## Setup

```bash
# 1. Install dependencies
bundle install

# 2. Set up the database and import all 36 lessons
rails db:create db:migrate db:seed

# 3. Build Tailwind CSS
rails tailwindcss:build

# 4. Start the server
bin/dev
```

## What's seeded

- **36 lessons** from Ó Siadhail's book, used as a structural skeleton
- **~1,577 vocabulary items** parsed from the book, ready to be updated with Mayo forms
- Grammar, texts, and exercise sections imported as plain text — editable immediately

## Editing content

Each lesson has an edit page at `/lessons/:number/edit` with:

- **Vocabulary table** — add/edit/delete rows inline (Irish, phonetic, plural, gender, English)
- **Vocabulary notes** — plain text notes on pronunciation/forms
- **Grammar** — free text, use simple formatting
- **Texts** — dialogues and reading passages
- **Exercises** — translation and practice exercises

The edit link is available from both the lesson index and the lesson show page.

## Adding authentication later

```bash
rails generate authentication
rails db:migrate
```

Then add `before_action :require_authentication` to `LessonsController` for the edit/update actions only,
so learners can read freely but only you can edit.

## Dialect notes

The imported content reflects Cois Fhairrge (Connemara) Irish. Key Mayo differences to update:

- Phonetics: Mayo has distinct vowel qualities, especially in unstressed syllables
- Vocabulary: some words differ, e.g. *pisreoga* vs *piseoga*
- Verb endings: 1st person plural `-imid` vs `-muid`
- Mutations: some lenition/eclipsis patterns differ after certain prepositions
