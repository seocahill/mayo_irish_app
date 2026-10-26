# Compares pieces of Irish loosely: case, accents and punctuation aside, since
# transcriptions and the speech recogniser don't always agree on them.
module IrishText
  module_function

  def words(text)
    text.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.tr("’", "'").scan(/[\p{L}']+/)
  end

  # Does `text` contain `phrase` as whole words?
  def includes?(text, phrase)
    needle = words(phrase)
    needle.any? && words(text).each_cons(needle.size).include?(needle)
  end

  def same?(a, b) = words(a) == words(b)
end
