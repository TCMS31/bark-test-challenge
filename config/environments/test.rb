# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV['CI'].present?

  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => "public, max-age=#{1.hour.to_i}" }

  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Let rescue_from handle what it declares; anything else surfaces as a real
  # exception instead of a generic 500 page.
  config.action_dispatch.show_exceptions = :rescuable
  config.action_controller.allow_forgery_protection = false

  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  config.action_controller.raise_on_missing_callback_actions = true

  # bcrypt is deliberately slow. Use its cheapest cost factor in the suite: no
  # test asserts on how expensive the digest is, only that one was produced.
  ActiveModel::SecurePassword.min_cost = true
end
