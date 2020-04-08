# frozen_string_literal: true

require "spec_helper"
require "generator_spec/test_case"
require File.expand_path("../../../../lib/generators/paper_trail_association_tracking/install_generator", __FILE__)

RSpec.describe PaperTrailAssociationTracking::InstallGenerator, type: :generator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../tmp", __FILE__)

  after do
    prepare_destination # cleanup the tmp directory
  end

  describe "no options" do
    before do
      prepare_destination
      run_generator
    end

    it "generates a migration for creating the 'versions' table" do
      expected_parent_class = lambda {
        ar_version = ActiveRecord::VERSION
        format("%s[%d.%d]", "ActiveRecord::Migration", ar_version::MAJOR, ar_version::MINOR)
      }.call

      expect(destination_root).to(
        have_structure {
          directory("db") {
            directory("migrate") {
              migration("create_version_associations") {
                contains("class CreateVersionAssociations < " + expected_parent_class)
                contains "def self.up"
                contains "create_table :version_associations"
              }
            }
          }
        }
      )

      expect(destination_root).to(
        have_structure {
          directory("db") {
            directory("migrate") {
              migration("add_transaction_id_column_to_versions") {
                contains("class AddTransactionIdColumnToVersions < " + expected_parent_class)
                contains "def self.up"
                contains "add_column :versions, :transaction_id,"
              }
            }
          }
        }
      )
    end
  end
end
