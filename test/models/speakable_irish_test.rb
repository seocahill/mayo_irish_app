require "test_helper"

class SpeakableIrishTest < ActiveSupport::TestCase
  setup do
    @language = CourseLanguage.new(irish: [ "Tá Cáit thuas", "suas", "maith", "níos fearr", "Nach bhfuil" ],
                                   english: [ "up, upwards", "good", "better", "Irregular verb, hear", "Other verbs" ])
  end

  test "bold and italic text is Irish unless it's plainly English" do
    html = mark("<p><strong>Tá Cáit thuas.</strong> — Cáit is up. <em>Suas</em> 'up'.</p><p><strong>Other verbs (§581)</strong></p>")

    assert_equal [ "Tá Cáit thuas.", "Suas" ], spoken(html)
    assert_includes html, %(<strong lang="ga" data-speak="Tá Cáit thuas.">)
  end

  test "table cells only when they're plainly Irish, read without phonetics or a gloss" do
    html = mark(<<~HTML)
      <table><tbody>
        <tr><td>maith</td><td>níos/is fearr</td></tr>
        <tr><td>good</td><td>better</td></tr>
        <tr><td>suas /su:sə/</td><td>/hu:sə/</td></tr>
        <tr><td>Nach bhfuil — is it not</td><td><strong>Tá</strong> Cáit</td></tr>
      </tbody></table>
    HTML

    assert_equal [ "maith", "níos/is fearr", "suas", "Nach bhfuil", "Tá" ], spoken(html)
  end

  test "leaves out section references, fragments and phonetics" do
    html = mark("<p><strong>feicim (§589)</strong>, <em>-áil</em>, <em>an t-</em>, <em>c</em>, <em>ə çe:xd</em></p>")

    assert_equal [ "feicim" ], spoken(html)
  end

  private

  def mark(html) = SpeakableIrish.new(html, language: @language).to_html

  def spoken(html) = Nokogiri::HTML5.fragment(html).css("[data-speak]").map { |node| node["data-speak"] }
end
