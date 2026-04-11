namespace :vocabulary do
  desc "Split plural out of english field where plural column is blank"
  task fix_plurals: :environment do
    fixed = 0
    skipped = 0

    VocabularyItem.where(plural: [nil, '']).find_each do |item|
      english = item.english.to_s.strip
      next if english.blank?

      # Already starts uppercase or punctuation → no plural prefix
      next skipped += 1 if english.match?(/\A[A-Z(\/;]/)

      # Split on the boundary between the last Irish token and the first purely
      # ASCII English word. Irish tokens contain fadas or typical Irish endings.
      # We tokenise and find the first token that is purely [a-z] with no fadas
      # and doesn't look like an Irish word (no -acha, -aí, -aigh, -óir etc.)
      tokens = english.split(' ')

      # If the first token has no fada and no typical Irish plural ending,
      # it's probably English already — skip
      first = tokens[0]
      unless first.match?(/[áéíóú]/) ||
             first.match?(/(acha|anna|aí|aigh|óir|eoir|úir|acha|anta|te|taí|íní|ínigh)\z/i)
        skipped += 1
        next
      end

      split_at = nil
      tokens.each_with_index do |tok, i|
        next if i == 0  # first token is always Irish
        # purely ASCII lowercase word → start of English
        if tok.match?(/\A[a-z]/) && !tok.match?(/[áéíóú]/)
          split_at = i
          break
        end
        # uppercase signals start of English too
        if tok.match?(/\A[A-Z(\/;]/)
          split_at = i
          break
        end
      end

      if split_at
        plural  = tokens[0...split_at].join(' ').strip
        meaning = tokens[split_at..].join(' ').strip
        item.update_columns(plural: plural, english: meaning)
        fixed += 1
      else
        skipped += 1
      end
    end

    puts "Fixed: #{fixed}, skipped: #{skipped}"
  end
end
