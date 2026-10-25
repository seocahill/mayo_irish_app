require "test_helper"
require "i18n/tasks"

# Guards the locale files: every key used in code exists, no key is left
# unused, and the files stay normalized so diffs are small for translators.
class I18nTest < ActiveSupport::TestCase
  setup { @i18n = I18n::Tasks::BaseTask.new }

  test "no translation keys are missing" do
    missing = @i18n.missing_keys
    assert_empty missing, "Missing #{missing.leaves.count} i18n keys:\n#{missing.inspect}"
  end

  test "no translation keys are unused" do
    unused = @i18n.unused_keys
    assert_empty unused, "#{unused.leaves.count} unused i18n keys:\n#{unused.inspect}"
  end

  test "locale files are normalized" do
    non_normalized = @i18n.non_normalized_paths
    assert_empty non_normalized, "Run `bundle exec i18n-tasks normalize` to fix:\n#{non_normalized.join("\n")}"
  end
end
