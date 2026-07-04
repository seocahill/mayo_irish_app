# Low-level read/write access to the `search_documents` FTS5 virtual table.
#
# Virtual tables don't play nicely with the usual Active Record row lifecycle
# (no real primary key, no unique constraints), so a small module owns the raw
# SQL. Callers use Searchable (write side) and Search (read side); this is the
# seam between them and SQLite.
module SearchIndex
  module_function

  def connection
    ApplicationRecord.connection
  end

  # Replace the row(s) for a record. Delete-then-insert keeps things simple and
  # correct: there's no unique key on an FTS5 table to UPSERT against.
  def upsert(record)
    delete(record)
    body = record.search_body
    return if body.blank?

    sql = <<~SQL
      INSERT INTO search_documents (record_type, record_id, lesson_number, title, body)
      VALUES (?, ?, ?, ?, ?)
    SQL
    binds = bind_params([
      record.class.name,
      record.id,
      record.search_lesson_number,
      record.search_title.to_s,
      body
    ])
    connection.exec_insert(sql, "SearchIndex Insert", binds)
  end

  def delete(record)
    connection.exec_delete(
      "DELETE FROM search_documents WHERE record_type = ? AND record_id = ?",
      "SearchIndex Delete",
      bind_params([record.class.name, record.id])
    )
  end

  # Drop every row and rebuild from all registered models. Safe to run any
  # number of times.
  def rebuild!
    # Models register themselves with Searchable as they're loaded, so make sure
    # they're all loaded before reading the registry (rake/seeds run cold).
    Rails.application.eager_load!
    connection.exec_delete("DELETE FROM search_documents", "SearchIndex Clear", [])
    Searchable.registered_models.each(&:reindex_all)
  end

  def bind_params(values)
    values.map { |v| ActiveRecord::Relation::QueryAttribute.new(nil, v, ActiveRecord::Type::Value.new) }
  end
end
