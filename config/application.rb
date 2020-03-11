require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'http://localhost:8888', 'http://localhost:3000', 'http://localhost:3001', 'https://chat.optobot.ai', 'https://optobot-test.now.sh', 'https://beta.optobot.ai'
        resource '*',
          :headers => :any,
          :expose => ['access-token', 'expiry', 'token-type', 'uid', 'client'],
          :methods => [:get, :post, :options, :delete, :put, :head],
          :credentials => true
      end
    end


  end
end
