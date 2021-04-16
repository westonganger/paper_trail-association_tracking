# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["DB"] ||= "sqlite"

require "byebug"

unless File.exist?(File.expand_path("dummy_app/config/database.yml", __dir__))
  warn "WARNING: No database.yml detected for the dummy app, please run `rake prepare` first"
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_results"

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Support for disabling `verify_partial_doubles` on specific examples.
  config.around(:each, verify_stubs: false) do |ex|
    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = false
      ex.run
      mocks.verify_partial_doubles = true
    end
  end

  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.warnings = false

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
  config.order = :random

  Kernel.srand(config.seed)
end

require "active_record/railtie"

require "rspec/rails"
require "ffaker"
require "timecop"

require File.expand_path("../dummy_app/config/environment", __FILE__)

# Run any available migration
if ActiveRecord.gem_version >= Gem::Version.new("6.0")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__), ActiveRecord::SchemaMigration).migrate
elsif ActiveRecord.gem_version >= Gem::Version.new("5.2")
  ActiveRecord::MigrationContext.new(File.expand_path("dummy_app/db/migrate/", __dir__)).migrate
else
  ActiveRecord::Migrator.migrate File.expand_path("dummy_app/db/migrate/", __dir__)
end

require "rspec/core"
require "rspec/matchers"

RSpec::Matchers.define :have_a_version_with do |attributes|
  # check if the model has a version with the specified attributes
  match do |actual|
    versions_association = actual.class.versions_association_name
    actual.send(versions_association).where_object(attributes).any?
  end
end

RSpec::Matchers.define :have_a_version_with_changes do |attributes|
  # check if the model has a version changes with the specified attributes
  match do |actual|
    versions_association = actual.class.versions_association_name
    actual.send(versions_association).where_object_changes(attributes).any?
  end
end

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
end
