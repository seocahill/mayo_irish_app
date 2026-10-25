# A lesson's edit history, newest first: every change made to the lesson, its
# vocabulary, grammar and blocks, ready to list and (where possible) undo.
class LessonHistory
  Entry = Struct.new(:version, :who, :kind, :subject, :changes, :undoable, keyword_init: true) do
    def event = version.event
    def at = version.created_at
    def undoable? = undoable
  end

  Change = Struct.new(:field, :from, :to)

  EXCERPT = 140

  def initialize(lesson, limit: 100)
    @lesson = lesson
    @limit = limit
  end

  def entries
    versions = PaperTrail::Version.where(lesson_id: @lesson.id)
                                  .includes(:item).order(created_at: :desc, id: :desc).limit(@limit)
    people = User.where(id: versions.map(&:whodunnit).compact).index_by { |u| u.id.to_s }

    versions.map { |version| entry_for(version, people[version.whodunnit]) }
  end

  private

  def entry_for(version, person)
    item = version.item || version.reify
    Entry.new(version: version,
              who: person&.email_address,
              kind: I18n.t("history.kinds.#{version.item_type.underscore.tr('/', '_')}"),
              subject: item&.history_label,
              changes: changes_for(version),
              undoable: VersionUndo.new(version).possible?)
  end

  def changes_for(version)
    return [] unless version.event == "update"

    VersionUndo.edits(version).map do |field, (from, to)|
      Change.new(version.item_type.constantize.human_attribute_name(field), excerpt(from), excerpt(to))
    end
  end

  def excerpt(value)
    ActionController::Base.helpers.strip_tags(value.to_s).squish.truncate(EXCERPT)
  end
end
