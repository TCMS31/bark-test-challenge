# frozen_string_literal: true

require_relative 'boot'

# Only the frameworks this app actually uses. `rails/all` additionally boots
# Active Storage, Action Mailbox, Action Text and Action Mailer, none of which
# are referenced anywhere here; loading them costs boot time and adds
# configuration surface that has to be maintained for no benefit.
require 'rails'

%w[
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  active_job/railtie
  action_cable/engine
].each { |railtie| require railtie }

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BarkTestChallenge
  # Application-wide configuration; per-environment overrides live in
  # config/environments.
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Sole source of user-facing copy; see config/locales.
    config.i18n.default_locale = :en

    # Generators are scoped to what this app actually uses so a new resource
    # does not scaffold fixtures, helpers and stylesheets nobody asked for.
    config.generators do |generate|
      generate.test_framework :rspec, request_specs: true
      generate.helper false
      generate.assets false
    end
  end
end
