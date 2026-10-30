# frozen_string_literal: true

# Downloads every list page and every item page of the Mayo Focail Fholaithe list
# (focailfholaithe.fng.ie, counties/8651) as raw HTML, so it can be parsed later
# without going back to the site. Needs the nokogiri gem.
#
#   ruby data/focail_fholaithe/download_pages.rb
#
# Resumable: files already on disk are skipped, so just run it again after an
# interruption or to retry failures. Output, under OUT:
#   list/page-0000.html ...   the list pages (0 up to the pager's "last" page)
#   items/<slug>.html         one file per item, named from its URL path
#   manifest.csv              page, row, headword, path, file for every item
#   failures.csv              pages that could not be fetched this run
#
# Settings (environment variables):
#   BASE   where to fetch from. The default is the Wayback Machine snapshot; the
#          "id_" form returns each page exactly as archived, without the toolbar.
#          For the live site use BASE=http://focailfholaithe.fng.ie
#   START  path of the first list page (default /counties/8651)
#   OUT    output directory (default: html/ next to this script)
#   DELAY  seconds between requests (default 1.5). Be gentle with the archive.
#   LIMIT  only fetch the first N item pages, for a trial run
#   HEADWORDS  JSON list of {"headword": ...} from the earlier scrape (default:
#          mayo_list_view.json next to this script). Headwords not found on the archived
#          list pages get their item URL predicted and tried; misses go to
#          predicted_not_archived.csv rather than failures.csv.
#   LIST_ALIASES  comma-separated alternative list paths tried when a list page
#          404s (default /counties/maigh-eo)
require "cgi"
require "csv"
require "digest"
require "fileutils"
require "json"
require "net/http"
require "nokogiri"
require "uri"

BASE = ENV.fetch("BASE", "https://web.archive.org/web/20251111112357id_/http://focailfholaithe.fng.ie")
START = ENV.fetch("START", "/counties/8651")
OUT = ENV.fetch("OUT", File.join(__dir__, "html"))
DELAY = Float(ENV.fetch("DELAY", "1.5"))
LIMIT = ENV["LIMIT"]&.to_i
# The same list is also served under its slug; the archive may hold pages under either URL.
LIST_ALIASES = ENV.fetch("LIST_ALIASES", "/counties/maigh-eo").split(",")
# Headwords from the earlier list-view scrape, used to look for items whose list page isn't archived.
HEADWORDS = ENV.fetch("HEADWORDS", File.join(__dir__, "mayo_list_view.json"))
MAX_TRIES = 6
MAX_REDIRECTS = 5
USER_AGENT = "focail-fholaithe-archiver (non-commercial research)"
NOT_ARCHIVED = /Wayback Machine has not archived|This page is not available/i

def escape(path)
  path.gsub(/[^A-Za-z0-9\-._~\/?=&%]/) { |char| char.bytes.map { |byte| format("%%%02X", byte) }.join }
end

# Returns the page body, nil for a 404, or raises once retries run out.
def get(url)
  redirects = tries = 0
  loop do
    uri = URI(url)
    begin
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 20, read_timeout: 60) do |http|
        http.get(uri.request_uri, "User-Agent" => USER_AGENT)
      end
    rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, EOFError => e
      response = e
    end

    case response
    when Net::HTTPSuccess
      return response.body.dup.force_encoding("UTF-8")
    when Net::HTTPRedirection
      redirects += 1
      raise "too many redirects: #{url}" if redirects > MAX_REDIRECTS
      url = URI.join(url, response["location"]).to_s
    when Net::HTTPNotFound
      return nil
    else
      tries += 1
      reason = response.is_a?(Net::HTTPResponse) ? "HTTP #{response.code}" : "#{response.class}: #{response.message}"
      raise "giving up on #{url} (#{reason})" if tries >= MAX_TRIES

      wait = response.is_a?(Net::HTTPResponse) && response["retry-after"] ? response["retry-after"].to_i : 5 * 2**tries
      warn "  #{reason}; retry #{tries}/#{MAX_TRIES - 1} in #{wait}s"
      sleep wait
    end
  end
end

def write_atomically(file, body)
  FileUtils.mkdir_p(File.dirname(file))
  File.write("#{file}.part", body)
  File.rename("#{file}.part", file)
end

# Fetches path into file unless it is already there. Returns :ok, :skipped or an error message.
def download(path, file, row_selector: nil)
  return :skipped if File.size?(file)

  sleep DELAY
  body = get(BASE + escape(path))
  return "404 not found" if body.nil?
  return "not archived" if body.match?(NOT_ARCHIVED) && body.size < 5_000
  return "no list rows in page" if row_selector && Nokogiri::HTML(body).css(row_selector).empty?

  write_atomically(file, body)
  :ok
rescue RuntimeError => e
  e.message
end

def item_file(path)
  name = CGI.escape(CGI.unescape(path.sub(%r{\A/}, "")))
  name = "#{name[0, 150]}-#{Digest::SHA1.hexdigest(path)[0, 8]}" if name.size > 180
  File.join(OUT, "items", "#{name}.html")
end

SMALL_WORDS = %w[a an as at before but by for from is in into like of off on onto per since than the this that to up via with and or].freeze

# The path the site gives an item (Drupal's pathauto): lowercase, apostrophes dropped, other
# punctuation and spaces become hyphens, small words removed.
def predict_slug(headword)
  words = headword.downcase.delete("'’´`").gsub(/[^[:alnum:]\s-]/, " ").split(/[\s-]+/).reject(&:empty?)
  (words - SMALL_WORDS).then { |kept| kept.empty? ? words : kept }.join("-")
end

def to_path(href)
  uri = URI(escape(href.strip))
  uri.path + (uri.query ? "?#{uri.query}" : "")
end

failures = []
record = lambda do |path, result|
  next if %i[ok skipped].include?(result)

  warn "FAILED #{path}: #{result}"
  failures << [path, result]
end

# 1. List pages. Page 0 is START; the pager's "last" link says how many follow.
first_file = File.join(OUT, "list", "page-0000.html")
result = download(START, first_file, row_selector: "li.views-row")
record.call(START, result)
abort "Could not fetch the first list page (#{START}); nothing to do." unless File.size?(first_file)

last_href = Nokogiri::HTML(File.read(first_file, encoding: "UTF-8")).at_css('a[title="Go to last page"]')&.[]("href")
last_page = last_href ? Integer(last_href[/page=(\d+)/, 1]) : 0
list_path = last_href ? to_path(last_href).split("?").first : START
puts "List has #{last_page + 1} pages (0..#{last_page}), path #{list_path}"

bases = [list_path, *LIST_ALIASES].uniq
(1..last_page).each do |page|
  file = File.join(OUT, "list", format("page-%04d.html", page))
  result = nil
  bases.each do |base|
    path = "#{base}?page=#{page}"
    result = download(path, file, row_selector: "li.views-row")
    if result == :ok
      bases.unshift(bases.delete(base)) # try whichever URL form worked first next time
      break
    end
    break if result == :skipped

    warn "  #{path}: #{result}"
  end
  record.call("#{list_path}?page=#{page}", result)
  puts "list page #{page}/#{last_page}: #{result}" if result == :ok && (page % 10).zero?
end

# 2. Manifest of items, read back from the list pages on disk.
items = {}
(0..last_page).each do |page|
  file = File.join(OUT, "list", format("page-%04d.html", page))
  next warn("missing list page #{page}") unless File.size?(file)

  Nokogiri::HTML(File.read(file, encoding: "UTF-8")).css("li.views-row").each_with_index do |li, row|
    link = li.at_css(".views-field-title a")
    next unless link

    path = to_path(link["href"])
    warn "duplicate link #{path} (page #{page}, row #{row}); keeping the first" if items.key?(path)
    items[path] ||= [page, row, link.text.strip, path, item_file(path).delete_prefix("#{OUT}/"), "list"]
  end
end

# 2b. The archive holds many item pages whose list page it never captured. Item URLs are the
# headword, lowercased, without punctuation or small words (a ro -> /content/ro), with -0, -1
# added when a headword repeats. For headwords the list pages did not give us, try that URL.
if File.exist?(HEADWORDS)
  slug_hits = items.values.count { |row| CGI.unescape(row[3].delete_prefix("/content/")) == predict_slug(row[2]) }
  puts "URL prediction matches #{slug_hits} of #{items.size} items known from the list pages"

  known = items.values.map { |row| row[2] }.tally
  JSON.parse(File.read(HEADWORDS, encoding: "UTF-8")).map { |entry| entry["headword"] }.tally.each do |headword, count|
    next unless count > known.fetch(headword, 0)

    slug = predict_slug(headword)
    candidates = count == 1 ? [slug] : [slug, *(0...count).map { |suffix| "#{slug}-#{suffix}" }]
    candidates.each do |candidate|
      path = to_path("/content/#{candidate}")
      items[path] ||= [nil, nil, headword, path, item_file(path).delete_prefix("#{OUT}/"), "predicted"]
    end
  end
end

CSV.open(File.join(OUT, "manifest.csv"), "w") do |csv|
  csv << %w[page row headword path file source]
  items.each_value { |row| csv << row }
end
puts "#{items.size} items in manifest.csv (#{items.values.count { |row| row[5] == 'predicted' }} predicted)"

# 3. Item pages.
todo = items.values
todo = todo.first(LIMIT) if LIMIT
counts = Hash.new(0)
not_archived = []
todo.each_with_index do |(_, _, headword, path, file, source), index|
  result = download(path, File.join(OUT, file))
  if source == "predicted" && result == "404 not found"
    not_archived << [path, headword]
    counts[:not_archived] += 1
    next
  end

  record.call(path, result)
  counts[result.is_a?(Symbol) ? result : :failed] += 1
  puts "[#{index + 1}/#{todo.size}] #{headword} #{result == :skipped ? '(already have it)' : result}" unless result == :skipped && (index % 50).nonzero?
end

CSV.open(File.join(OUT, "failures.csv"), "w") do |csv|
  csv << %w[path error]
  failures.each { |row| csv << row }
end
CSV.open(File.join(OUT, "predicted_not_archived.csv"), "w") do |csv|
  csv << %w[path headword]
  not_archived.each { |row| csv << row }
end
puts "Done. items: #{counts[:ok]} downloaded, #{counts[:skipped]} already on disk, #{counts[:failed]} failed, " \
     "#{counts[:not_archived]} predicted URLs not in the archive. " \
     "#{failures.size} failures in total (see failures.csv)."
