module GrammarHelper
  # ── Public entry point ────────────────────────────────────────────────────

  # Renders a lesson's grammar.
  # If grammar_data (JSON) is present it renders structured blocks
  # (tables, 2-col examples, prose, subsections, notes).
  # Falls back to plain-text parsing of the legacy `grammar` field.
  def render_grammar(lesson)
    if lesson.grammar_structured?
      render_grammar_json(lesson.grammar_sections)
    elsif lesson.grammar.present?
      render_grammar_text(lesson.grammar)
    else
      ''.html_safe
    end
  end

  # ── JSON renderer ─────────────────────────────────────────────────────────

  def render_grammar_json(sections)
    sections.map { |s| render_section(s) }.join("\n").html_safe
  end

  private

  def render_section(section)
    n        = h(section["number"])
    t        = h(section["title"])
    heading  = <<~HTML
      <div class="grammar-section-heading">
        <span class="grammar-section-badge">#{n}</span>
        <span>#{t}</span>
      </div>
    HTML
    blocks = (section["blocks"] || []).map { |b| render_block(b) }.join("\n")
    heading + blocks
  end

  def render_block(block)
    case block["type"]
    when "subsection" then render_subsection(block)
    when "prose"      then render_prose(block)
    when "examples"   then render_examples(block)
    when "table"      then render_table(block)
    when "note"       then render_note(block)
    else ""
    end
  end

  # (i) Usage
  def render_subsection(block)
    label = h("#{block['label']} #{block['title']}".strip)
    %(<div class="grammar-subsection-heading">#{label}</div>)
  end

  # Prose paragraph
  def render_prose(block)
    %(<p class="grammar-prose">#{h(block['text'].to_s)}</p>)
  end

  # Two-column Irish / English example table
  def render_examples(block)
    rows = (block["rows"] || []).map do |row|
      irish   = h(row[0].to_s)
      english = h(row[1].to_s)
      <<~ROW
        <tr>
          <td class="grammar-eg-irish">#{irish}</td>
          <td class="grammar-eg-english">#{english}</td>
        </tr>
      ROW
    end.join

    caption = block["caption"].present? ? %(<caption class="grammar-table-caption">#{h(block['caption'])}</caption>) : ""
    <<~HTML
      <table class="grammar-examples-table">
        #{caption}
        <tbody>#{rows}</tbody>
      </table>
    HTML
  end

  # N-column paradigm table (possessive adjectives, gender endings, etc.)
  def render_table(block)
    headers = block["headers"] || []
    rows    = block["rows"] || []

    header_row = if headers.any?
      cells = headers.map { |h_| %(<th>#{h(h_.to_s)}</th>) }.join
      "<thead><tr>#{cells}</tr></thead>"
    else
      ""
    end

    body_rows = rows.map do |row|
      cells = row.map { |c| %(<td>#{h(c.to_s)}</td>) }.join
      "<tr>#{cells}</tr>"
    end.join("\n")

    caption = block["caption"].present? ? %(<caption class="grammar-table-caption">#{h(block['caption'])}</caption>) : ""
    note    = block["note"].present?    ? %(<p class="grammar-note">#{h(block['note'])}</p>) : ""

    <<~HTML
      <div class="grammar-table-wrapper">
        <table class="grammar-paradigm-table">
          #{caption}
          #{header_row}
          <tbody>#{body_rows}</tbody>
        </table>
        #{note}
      </div>
    HTML
  end

  # Footnote / Note box
  def render_note(block)
    %(<p class="grammar-note">#{h(block['text'].to_s)}</p>)
  end

  # ── Legacy plain-text renderer (fallback) ─────────────────────────────────

  SECTION_RE    = /\A(\d+)\.\s+(.+)\z/
  SUBSECTION_RE = /\A\(([ivxlcdmIVXLCDM]+)\)\s*(.*)\z/

  def render_grammar_text(text)
    blocks = parse_text_blocks(text)
    blocks.map { |b| render_text_block(b) }.join("\n").html_safe
  end

  def parse_text_blocks(text)
    blocks  = []
    current = []

    flush = lambda do
      lines = current.reject { |l| l.strip.empty? }
      blocks << { type: :prose_lines, lines: lines } unless lines.empty?
      current.clear
    end

    text.split("\n").each do |raw|
      line = raw.rstrip
      if (m = line.match(SECTION_RE))
        flush.call
        blocks << { type: :section, number: m[1], title: m[2] }
      elsif (m = line.match(SUBSECTION_RE))
        flush.call
        blocks << { type: :subsection_text, roman: m[1], title: m[2].strip }
      elsif line.strip.empty?
        flush.call
      else
        current << line
      end
    end
    flush.call
    blocks
  end

  def render_text_block(block)
    case block[:type]
    when :section
      n = h(block[:number]); t = h(block[:title])
      %(<div class="grammar-section-heading"><span class="grammar-section-badge">#{n}</span><span>#{t}</span></div>)
    when :subsection_text
      label = h("(#{block[:roman]})#{block[:title].present? ? ' ' + block[:title] : ''}")
      %(<div class="grammar-subsection-heading">#{label}</div>)
    when :prose_lines
      lines = block[:lines]
      avg   = lines.sum(&:length).to_f / lines.size
      if avg < 90
        items = lines.map { |l| "<li>#{h(l.strip)}</li>" }.join
        %(<ul class="grammar-examples-list">#{items}</ul>)
      else
        %(<p class="grammar-prose">#{h(lines.join(' ').strip)}</p>)
      end
    else
      ""
    end
  end
end
