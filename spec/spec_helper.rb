# frozen_string_literal: true

require 'bundler/setup'
require 'html2rss'
require 'html2rss/configs'
require 'active_support'
require 'active_support/core_ext/time'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.filter_run_excluding fetch: true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
