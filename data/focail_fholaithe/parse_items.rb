# frozen_string_literal: true

# Builds the Mayo Focail Fholaithe dataset (mayo_entries.csv / .json): one row per list entry,
# with the item page's fields where the archive has the page. Reads the files that
# download_pages.rb saved under html/, plus mayo_list_view.json (the earlier list-view scrape,
# which covers list pages the archive never captured).
#
#   ruby data/focail_fholaithe/parse_items.rb
#
# Every row has every column. Fields the source page doesn't have are empty, and has_detail says
# whether a row came with an item page.
require "cgi"
require "csv"
require "json"
require "nokogiri"

DIR = __dir__
HTML = File.join(DIR, "html")
COUNTY = "maigh-eo"

# Item page label => column. Labels are the site's own (Irish) field names.
DETAIL_FIELDS = {
  "Iontráil sa Lámhscríbhinn" => "manuscript_entry",
  "Iontráil" => "entry",
  "Ciall nó Míniú (BÉARLA)" => "meaning_en",
  "Ciall nó Míniú (Gaeilge)" => "meaning_ga",
  "Sampla(í) Úsáide" => "usage",
  "Leaganacha Malartacha" => "alternative_forms",
  "Foghraíocht" => "pronunciation",
  "Foirmeacha Gramadaí" => "grammar_forms",
  "Sonraí (eolas breise)" => "notes",
  "Contae" => "county_name",
  "Ceantar" => "district",
  "Bailitheoir/Údar" => "collector",
  "Canúint" => "dialect",
  "Teideal an Bhailiúcháin" => "collection_title",
  "Bliain" => "year"
}.freeze

COLUMNS = (%w[position county headword has_detail detail_path] + DETAIL_FIELDS.values).freeze
LIST_LABELS = { "meaning_en" => "Ciall nó Míniú (BÉARLA):", "usage" => "Sampla(í) Úsáide:" }.freeze

def squish(text, label = nil)
  text = text.to_s.sub(label.to_s, "").gsub(/[[:space:]]+/, " ").strip
  text.empty? ? nil : text
end

def read_html(file) = Nokogiri::HTML(File.read(file, encoding: "UTF-8"))

def list_row(li)
  link = li.at_css(".views-field-title a")
  {
    "headword" => squish(li.at_css(".views-field-title")&.text),
    "path" => link && CGI.unescape(link["href"]),
    "meaning_en" => squish(li.at_css(".views-field-field-meaning-or-explanation-en- .field-content")&.text),
    "usage" => squish(li.at_css(".views-field-field-usage-en- .field-content")&.text)
  }
end

def detail_fields(file)
  read_html(file).css(".field").each_with_object({}) do |field, values|
    label = field.at_css(".field-label")&.text.to_s.gsub(/[[:space:]]*:[[:space:]]*\z/, "").strip
    column = DETAIL_FIELDS[label]
    values[column] = squish(field.css(".field-items").text) if column
  end
end

# 1. The earlier scrape (positions 1..690) and the archived list pages (page * 10 + row + 1).
scraped = JSON.parse(File.read(File.join(DIR, "mayo_list_view.json"), encoding: "UTF-8")).to_h { |row| [row["position"], row] }
archived = {}
Dir[File.join(HTML, "list", "page-*.html")].each do |file|
  page = File.basename(file)[/\d+/].to_i
  read_html(file).css("li.views-row").each_with_index do |li, row|
    archived[(page * 10) + row + 1] = list_row(li)
  end
end

mismatched = archived.select { |position, row| scraped[position] && scraped[position]["headword"] != row["headword"] }
overlap = archived.keys & scraped.keys
puts "archived list pages: #{archived.size} rows; #{overlap.size} overlap the earlier scrape, #{mismatched.size} disagree on the headword"
mismatched.first(5).each { |position, row| puts "  #{position}: scrape #{scraped[position]['headword'].inspect} vs archive #{row['headword'].inspect}" }
abort "Positions don't line up; not guessing." if mismatched.size > 3

entries = scraped.transform_values { |row| row.slice("headword", "meaning_en", "usage") }
archived.each { |position, row| entries[position] ||= row.slice("headword", "meaning_en", "usage") }
entries = entries.sort.to_h
puts "#{entries.size} entries (#{entries.size - scraped.size} only on archived list pages)"

# 2. Item pages, matched to entries by headword; repeated headwords by their meaning and usage.
manifest = CSV.read(File.join(HTML, "manifest.csv"), headers: true, encoding: "UTF-8")
pages = manifest.select { |row| File.size?(File.join(HTML, row["file"])) }.map do |row|
  { "headword" => row["headword"], "path" => CGI.unescape(row["path"]), "fields" => detail_fields(File.join(HTML, row["file"])) }
end
pages_by_headword = pages.group_by { |page| page["headword"] }
puts "#{pages.size} item pages on disk for #{pages_by_headword.size} headwords"

detail_for = {}
entries.group_by { |_, entry| entry["headword"] }.each do |headword, group|
  candidates = pages_by_headword.fetch(headword, [])
  if group.size == 1 && candidates.size == 1
    detail_for[group.first.first] = candidates.first
    next
  end

  remaining = candidates.dup
  group.each do |position, entry|
    page = remaining.find { |c| c["fields"]["meaning_en"] == entry["meaning_en"] && c["fields"]["usage"] == entry["usage"] }
    page ||= remaining.find { |c| entry["meaning_en"] && c["fields"]["meaning_en"] == entry["meaning_en"] } ||
             remaining.find { |c| entry["usage"] && c["fields"]["usage"] == entry["usage"] }
    next unless page

    detail_for[position] = remaining.delete(page)
  end
end

rows = entries.map do |position, entry|
  page = detail_for[position]
  fields = page ? page["fields"] : {}
  row = { "position" => position, "county" => COUNTY, "headword" => entry["headword"], "has_detail" => !page.nil?, "detail_path" => page&.dig("path") }
  DETAIL_FIELDS.each_value { |column| row[column] = fields[column] }
  # Entries without a page keep what the list view showed.
  row["meaning_en"] ||= entry["meaning_en"]
  row["usage"] ||= entry["usage"]
  row
end

# 3. How the list view compares with the item pages, then write.
with_page = rows.select { |row| row["has_detail"] }
differs = with_page.count { |row| (e = entries[row["position"]])["meaning_en"] && e["meaning_en"] != row["meaning_en"] }
puts "matched #{with_page.size} entries to item pages; list-view meaning differs from the page's on #{differs}"
unmatched_pages = pages.size - detail_for.size
puts "#{unmatched_pages} item pages could not be matched to an entry" if unmatched_pages.positive?

CSV.open(File.join(DIR, "mayo_entries.csv"), "w", encoding: "UTF-8") do |csv|
  csv << COLUMNS
  rows.each { |row| csv << COLUMNS.map { |column| row[column] } }
end
File.write(File.join(DIR, "mayo_entries.json"), "#{JSON.pretty_generate(rows.map { |row| row.slice(*COLUMNS) })}\n", encoding: "UTF-8")
puts "wrote #{rows.size} rows to mayo_entries.csv / .json"
COLUMNS.each { |column| puts format("  %-18s %d", column, rows.count { |row| !row[column].nil? && row[column] != "" }) }
