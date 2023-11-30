# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = false

  # Eager load on boot so every request is served from warm code and copy-on-write
  # works across Puma workers.
  config.eager_load = true

  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Assets are precompiled during the image build; a miss should be a loud 404
  # rather than a slow runtime compile.
  config.assets.compile = false

  # On by default, but disable it (FORCE_SSL=false) when the container sits
  # behind something that already terminates TLS, or when running it locally
  # over plain HTTP - otherwise every request is redirected to https.
  config.force_ssl = ENV.fetch('FORCE_SSL', 'true') != 'false'

  config.logger = ActiveSupport::Logger.new($stdout)
                                       .tap { |logger| logger.formatter = Logger::Formatter.new }
                                       .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  config.log_tags = [:request_id]
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end
