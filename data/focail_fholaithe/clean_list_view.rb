# Normalises the old list-view scrape of focailfholaithe.fng.ie/counties/maigh-eo
# (counties/8651) into a consistent CSV + JSON. Usage:
#   ruby data/focail_fholaithe/clean_list_view.rb
require "csv"
require "json"

DIR = __dir__
LABELS = {
  "meaning" => "Ciall nó Míniú (BÉARLA):",
  "usage" => "Sampla(í) Úsáide:"
}.freeze

def clean(value, label)
  text = value.to_s.sub(label, "").gsub(/\s+/, " ").strip
  text.empty? ? nil : text
end

rows = CSV.read(File.join(DIR, "raw_list_view_backup.csv"), headers: true, encoding: "UTF-8").map.with_index(1) do |row, index|
  {
    "position" => index,
    "county" => "maigh-eo",
    "headword" => row["title"].to_s.strip,
    "meaning_en" => clean(row["meaning"], LABELS["meaning"]),
    "usage" => clean(row["usage"], LABELS["usage"])
  }
end

CSV.open(File.join(DIR, "mayo_list_view.csv"), "w", encoding: "UTF-8") do |csv|
  csv << rows.first.keys
  rows.each { |row| csv << row.values }
end
File.write(File.join(DIR, "mayo_list_view.json"), JSON.pretty_generate(rows) + "\n", encoding: "UTF-8")
puts "wrote #{rows.size} rows"
