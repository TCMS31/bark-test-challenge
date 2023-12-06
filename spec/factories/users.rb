# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    # Built from the policy rather than hardcoded so a new rule makes the
    # factory fail loudly instead of quietly producing invalid users.
    password { "Aa1!#{Faker::Alphanumeric.alpha(number: PasswordPolicy::MIN_LENGTH)}" }
    password_confirmation { password }
  end
end
