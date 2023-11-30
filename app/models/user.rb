# frozen_string_literal: true

# A registered account. Passwords are never stored: +has_secure_password+
# keeps only a bcrypt digest in +password_digest+.
class User < ApplicationRecord
  has_secure_password

  # Fold the address before it is written or compared. Without this,
  # "Ada@Example.com" and "ada@example.com" are two different rows and the
  # unique index on +email+ never fires, so the uniqueness validation is the
  # only thing standing between the app and duplicate accounts.
  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: :invalid_format }

  validates :password,
            presence: true,
            length: { minimum: PasswordPolicy::MIN_LENGTH, maximum: PasswordPolicy::MAX_LENGTH },
            password_format: true

  # +has_secure_password+ allows a blank confirmation; signup requires one.
  validates :password_confirmation, presence: true, if: -> { password.present? }
end
