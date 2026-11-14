# Short notes about changes a learner can see, shown once each: a card on Today
# until the learner taps "Got it", and a page that lists them all.
#
# The notes live in config/whats_new.yml so each one ships in the same change as
# the feature it describes. A learner sees the notes added after they joined and
# not yet read; the newest note they have read is User#whats_new_seen_id.
class WhatsNew
  Entry = Data.define(:id, :date, :title, :body, :path)

  DEFAULT_PATH = Rails.root.join("config/whats_new.yml")

  @loaded = {}

  class << self
    # The notes for this environment, re-read only when the file changes.
    def current
      # An unset config.x entry is an empty options object, not nil, hence presence.
      path = Rails.configuration.x.whats_new_path.presence || DEFAULT_PATH
      stamp = File.mtime(path)
      key, whats_new = @loaded[path.to_s]
      return whats_new if key == stamp

      load(path).tap { |fresh| @loaded[path.to_s] = [ stamp, fresh ] }
    rescue Psych::Exception, KeyError, Errno::ENOENT => error
      # A broken notes file must never take Today down. CI checks the shipped
      # file, so this only guards a bad deploy; the report reaches Sentry.
      Rails.error.report(error, handled: true, context: { path: path.to_s })
      new([])
    end

    def load(path)
      rows = YAML.safe_load_file(path, permitted_classes: [ Date ]) || []
      new(rows.map { |row| entry_from(row) })
    end

    private

    def entry_from(row)
      Entry.new(id: row.fetch("id"), date: row.fetch("date"), title: row.fetch("title"),
                body: row.fetch("body"), path: row["path"])
    end
  end

  # Newest first.
  attr_reader :entries

  def initialize(entries)
    @entries = entries.sort_by { |entry| -entry.id }.freeze
  end

  def latest_id
    entries.first&.id.to_i
  end

  # Newest first: notes added since the learner joined that they haven't read.
  def unseen_for(user)
    seen = user.whats_new_seen_id.to_i
    joined = user.created_at.to_date
    entries.select { |entry| entry.id > seen && entry.date >= joined }
  end
end
