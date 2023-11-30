# frozen_string_literal: true

# Single source of truth for what makes a password acceptable.
#
# The rules are data rather than code so that the two places that enforce them
# cannot drift apart: +PasswordFormatValidator+ checks them on the server, and
# the same list is serialised into the signup form (see
# +app/views/users/new.html.erb+) for the Stimulus controller to check as the
# user types. Adding a rule means adding one entry here plus one translation.
class PasswordPolicy
  MIN_LENGTH = 8
  # bcrypt silently truncates input past 72 bytes, so reject longer passwords
  # rather than accept one whose tail is quietly ignored.
  MAX_LENGTH = 72

  # +pattern+ is deliberately limited to syntax both Ruby and JavaScript
  # understand, because +Regexp#source+ is handed to +new RegExp+ in the
  # browser. No named groups, no POSIX classes, no lookbehind.
  Rule = Struct.new(:key, :pattern, keyword_init: true) do
    def satisfied_by?(password)
      pattern.match?(password.to_s)
    end

    # Sentence fragment used as a validation error ("Password must include...").
    def message
      I18n.t("password_policy.rules.#{key}")
    end

    # Short form used for the live checklist on the signup form.
    def label
      I18n.t("password_policy.labels.#{key}")
    end

    def as_json(*)
      { 'key' => key.to_s, 'pattern' => pattern.source, 'message' => message, 'label' => label }
    end
  end

  RULES = [
    Rule.new(key: :lowercase, pattern: /[a-z]/),
    Rule.new(key: :uppercase, pattern: /[A-Z]/),
    Rule.new(key: :digit, pattern: /[0-9]/),
    Rule.new(key: :special, pattern: /[^A-Za-z0-9\s]/)
  ].freeze

  class << self
    # Rules the given password fails, in declaration order.
    def violations(password)
      RULES.reject { |rule| rule.satisfied_by?(password) }
    end

    def long_enough?(password)
      password.to_s.length.between?(MIN_LENGTH, MAX_LENGTH)
    end

    def satisfied_by?(password)
      long_enough?(password) && violations(password).none?
    end

    # Consumed by the Stimulus controller via a data attribute.
    def as_json(*)
      {
        'minLength' => MIN_LENGTH,
        'maxLength' => MAX_LENGTH,
        'lengthMessage' => I18n.t('password_policy.rules.length', count: MIN_LENGTH),
        'lengthLabel' => I18n.t('password_policy.labels.length', count: MIN_LENGTH),
        'feedback' => I18n.t('password_policy.feedback').stringify_keys,
        'rules' => RULES.map(&:as_json)
      }
    end
  end
end
