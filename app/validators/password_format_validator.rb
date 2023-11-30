# frozen_string_literal: true

# Applies PasswordPolicy's character rules to an attribute.
#
#   validates :password, password_format: true
#
# Length is left to the built-in +length+ validator so that the standard
# +:too_short+ / +:too_long+ error types (and the matchers that assert on them)
# keep working; this validator only covers the composition rules.
class PasswordFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    PasswordPolicy.violations(value).each do |rule|
      record.errors.add(attribute, rule.message)
    end
  end
end
