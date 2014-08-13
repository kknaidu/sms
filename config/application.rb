require File.expand_path('../boot', __FILE__)

#require 'rails/all'
require "action_controller/railtie"
require "action_mailer/railtie"
# require "active_resource/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sms
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    class MongoidDbSwitcher
      def initialize(app)
        @app = app
      end

      ADMIN_SERVERS = %w(app.lvh.me app.sms.in)

      def call(env)
        server_name = env['SERVER_NAME'].downcase
        #translate server_name to a subdomain based url
        server_name = translate(server_name)
        db_name = "#{server_name.gsub('.', '_')}"
        if !ADMIN_SERVERS.include?(server_name)
          ::Mongoid.override_database(db_name)
          log("[DB_SWITCH] #{db_name}")
        end
        response = @app.call(env)
        ::Mongoid.override_database(nil)
        log("[DB_SWITCH] reset")
        response
      end

      def translate(server_name)
        domain = Domain.where(_id: server_name).first
        domain.try(:subdomain) || server_name
      end

      def log(msg)
        Rails.logger.debug msg
      end

    end


    config.middleware.insert_before Rack::Lock, MongoidDbSwitcher
  end
end
