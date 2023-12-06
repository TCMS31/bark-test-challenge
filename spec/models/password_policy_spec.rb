# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordPolicy do
  describe '.violations' do
    it 'returns nothing for a password that satisfies every rule' do
      expect(described_class.violations('Sufficient1!')).to be_empty
    end

    it 'names the missing lowercase letter' do
      expect(described_class.violations('SUFFICIENT1!').map(&:key)).to eq([:lowercase])
    end

    it 'names the missing uppercase letter' do
      expect(described_class.violations('sufficient1!').map(&:key)).to eq([:uppercase])
    end

    it 'names the missing digit' do
      expect(described_class.violations('Sufficient!').map(&:key)).to eq([:digit])
    end

    it 'names the missing special character' do
      expect(described_class.violations('Sufficient1').map(&:key)).to eq([:special])
    end

    it 'reports every missing rule at once' do
      expect(described_class.violations('aaaaaaaa').map(&:key))
        .to contain_exactly(:uppercase, :digit, :special)
    end

    it 'does not accept whitespace as a special character' do
      expect(described_class.violations('Suffici ent1').map(&:key)).to eq([:special])
    end

    it 'treats nil as failing every rule' do
      expect(described_class.violations(nil).count).to eq(described_class::RULES.count)
    end
  end

  describe '.satisfied_by?' do
    it 'rejects a password that is too short even when every character rule passes' do
      expect(described_class.satisfied_by?('Aa1!')).to be(false)
    end

    it 'rejects a password longer than bcrypt will actually hash' do
      too_long = "Aa1!#{'x' * described_class::MAX_LENGTH}"
      expect(described_class.satisfied_by?(too_long)).to be(false)
    end

    it 'accepts a password at the minimum length' do
      password = 'Aa1!bcde'
      expect(password.length).to eq(described_class::MIN_LENGTH)
      expect(described_class.satisfied_by?(password)).to be(true)
    end
  end

  describe '.as_json' do
    subject(:payload) { described_class.as_json }

    it 'publishes the limits the browser needs' do
      expect(payload).to include(
        'minLength' => described_class::MIN_LENGTH,
        'maxLength' => described_class::MAX_LENGTH
      )
    end

    it 'publishes one entry per rule, with a pattern and a human message' do
      expect(payload['rules'].map { |rule| rule['key'] })
        .to eq(described_class::RULES.map { |rule| rule.key.to_s })
      expect(payload['rules']).to all(include('pattern', 'message', 'label'))
    end

    it 'serialises cleanly to the JSON embedded in the signup form' do
      expect { JSON.parse(payload.to_json) }.not_to raise_error
    end
  end

  describe 'rule patterns' do
    # The browser compiles these with `new RegExp(pattern)`, so anything Ruby
    # understands but JavaScript does not would silently break client-side
    # feedback while the server kept working.
    unsupported_by_javascript = /
      \(\?<[=!] |  # lookbehind
      \[\[:      |  # POSIX bracket class
      \\[AzZhHRXG] |  # Ruby-only anchors and escapes
      \(\?\#
    /x

    it 'uses only regexp syntax that JavaScript can compile' do
      described_class::RULES.each do |rule|
        expect(rule.pattern.source).not_to match(unsupported_by_javascript),
                                           "#{rule.key} pattern #{rule.pattern.source.inspect} is not portable"
      end
    end

    it 'exposes no regexp options, which do not survive the source round trip' do
      expect(described_class::RULES.map { |rule| rule.pattern.options }).to all(eq(0))
    end
  end
end
