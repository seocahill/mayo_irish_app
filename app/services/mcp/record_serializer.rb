module Mcp
  # Serializes an ActiveRecord record to a plain hash: DB columns plus any
  # ActionText rich-text fields rendered as HTML. Never exposes password digests.
  module RecordSerializer
    module_function

    def call(record)
      record.attributes.except("password_digest").merge(rich_text_fields(record))
    end

    def rich_text_fields(record)
      rich_text_names(record.class).index_with do |name|
        record.public_send(name)&.body&.to_html
      end
    end

    def rich_text_names(klass)
      klass.reflect_on_all_associations(:has_one)
           .select { |assoc| assoc.options[:class_name].to_s == "ActionText::RichText" }
           .map { |assoc| assoc.name.to_s.delete_prefix("rich_text_") }
    end
  end
end
