namespace :search do
  desc "Rebuild the global full-text search index from scratch"
  task reindex: :environment do
    print "Rebuilding search index… "
    SearchIndex.rebuild!
    count = ApplicationRecord.connection.select_value("SELECT COUNT(*) FROM search_documents")
    puts "done (#{count} documents indexed)."
  end

  # Boot-time safety net. The index lives in the app's SQLite database on the
  # persistent volume, so it normally only needs building once. Fly's
  # release_command runs in a throwaway VM without the volume mounted, so the
  # index must be built from the running app machine (via bin/docker-entrypoint)
  # instead — this task does that, and only when the index is actually empty so
  # repeated boots stay cheap.
  desc "Build the search index only if it is currently empty"
  task reindex_if_empty: :environment do
    built = SearchIndex.rebuild_if_empty!
    if built
      puts "Search index was empty — built #{built} documents."
    elsif SearchIndex.table_exists?
      puts "Search index already populated (#{SearchIndex.count} documents)."
    else
      warn "search_documents table missing; skipping reindex."
    end
  end
end
