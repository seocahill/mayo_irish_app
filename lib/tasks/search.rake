namespace :search do
  desc "Rebuild the global full-text search index from scratch"
  task reindex: :environment do
    print "Rebuilding search index… "
    SearchIndex.rebuild!
    count = ApplicationRecord.connection.select_value("SELECT COUNT(*) FROM search_documents")
    puts "done (#{count} documents indexed)."
  end
end
