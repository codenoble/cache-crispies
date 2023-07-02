# frozen_string_literal: true

require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true

SimpleCov.start do
  enable_coverage :branch
  formatter(
    SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::HTMLFormatter,
        SimpleCov::Formatter::LcovFormatter
      ]
    )
  )
end

require 'byebug'
require_relative '../lib/cache_crispies'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end
