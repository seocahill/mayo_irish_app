module GrammarHelper
  # Matches top-level sections: "1. SECTION TITLE"
  SECTION_RE    = /\A(\d+)\.\s+(.+)\z/
  # Matches subsections: "(i) subtitle" or "(ii)"
  SUBSECTION_RE = /\A\(([ivxlcdmIVXLCDM]+)\)\s*(.*)\z/

  # Parse and render stored grammar text into structured HTML.
  # The text mixes numbered sections, Roman-numeral subsections,
  # two-column Irish/English examples, and prose paragraphs.
  def render_grammar(text)
    return ''.html_safe if text.blank?

    blocks = parse_grammar_blocks(text)
    blocks.map { |b| render_grammar_block(b) }.join("\n").html_safe
  end

  private

  # Split raw text into typed blocks: :section, :subsection, :prose
  def parse_grammar_blocks(text)
    blocks  = []
    current = []

    flush = lambda do
      lines = current.reject { |l| l.strip.empty? }
      blocks << { type: :prose, lines: lines } unless lines.empty?
      current.clear
    end

    text.split("\n").each do |raw|
      line = raw.rstrip

      if (m = line.match(SECTION_RE))
        flush.call
        blocks << { type: :section, number: m[1], title: m[2] }
      elsif (m = line.match(SUBSECTION_RE))
        flush.call
        blocks << { type: :subsection, roman: m[1], title: m[2].strip }
      elsif line.strip.empty?
        flush.call
      else
        current << line
      end
    end

    flush.call
    blocks
  end

  def render_grammar_block(block)
    case block[:type]
    when :section
      n = h(block[:number])
      t = h(block[:title])
      <<~HTML.chomp
        <div class="grammar-section-heading">
          <span class="grammar-section-badge">#{n}</span>
          <span>#{t}</span>
        </div>
      HTML

    when :subsection
      parts = ["(#{block[:roman]})"]
      parts << block[:title] if block[:title].present?
      "<div class=\"grammar-subsection-heading\">#{h(parts.join(' '))}</div>"

    when :prose
      lines = block[:lines]
      if example_lines?(lines)
        items = lines.map { |l| "<li>#{h(l.strip)}</li>" }.join
        "<ul class=\"grammar-examples\">#{items}</ul>"
      else
        # Join continuation lines into a single paragraph
        "<p class=\"grammar-prose\">#{h(lines.join(' ').strip)}</p>"
      end

    else
      ''
    end
  end

  # Short-line blocks are rendered as example lists (Irish/English pairs,
  # consonant tables, etc.). Long-line blocks are prose.
  def example_lines?(lines)
    return false if lines.size == 1 && lines.first.length > 100
    avg = lines.sum(&:length).to_f / lines.size
    avg < 90
  end
end
