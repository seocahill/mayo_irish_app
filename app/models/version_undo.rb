# Reverses one recorded change: a creation is deleted, an edit goes back to the
# values it replaced, a deletion is brought back. The undo is itself recorded,
# so it can be undone in turn.
class VersionUndo
  TIMESTAMPS = %w[created_at updated_at].freeze

  # What an edit replaced, by field, ignoring bookkeeping timestamps.
  def self.edits(version) = version.changeset.except(*TIMESTAMPS)

  def initialize(version)
    @version = version
  end

  def possible?
    case @version.event
    when "create" then item.present?
    when "update" then item.present? && self.class.edits(@version).present?
    when "destroy" then item.nil? && @version.object.present?
    else false
    end
  end

  def call
    raise ActiveRecord::RecordNotFound, "Nothing to undo" unless possible?

    case @version.event
    when "create" then item.destroy!
    when "update" then item.update!(self.class.edits(@version).transform_values(&:first))
    when "destroy" then @version.reify.save!
    end
  end

  private

  def item = @version.item
end
