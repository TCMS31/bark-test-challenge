# frozen_string_literal: true

# Partial matches, so `passw` also keeps password_confirmation out of the logs.
Rails.application.config.filter_parameters += %i[
  passw secret token _key crypt salt certificate otp ssn
]
