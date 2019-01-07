# frozen_string_literal: true

require "spec_helper"
require "generator_spec/test_case"
require File.expand_path("../../../../lib/generators/paper_trail_association_tracking/add_foreign_type_to_version_associations_generator", __FILE__)

RSpec.describe PaperTrailAssociationTracking::AddForeignTypeToVersionAssociationsGenerator, type: :generator do
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

    it "generates a migration for adding the 'foreign_type' column to the 'version_associations' table" do
      expected_parent_class = lambda {
        old_school = "ActiveRecord::Migration"
        ar_version = ActiveRecord::VERSION
        if ar_version::MAJOR >= 5
          format("%s[%d.%d]", old_school, ar_version::MAJOR, ar_version::MINOR)
        else
          old_school
        end
      }.call

      expect(destination_root).to(
        have_structure {
          directory("db") {
            directory("migrate") {
              migration("add_foreign_type_to_version_associations") {
                contains("class AddForeignTypeToVersionAssociations < " + expected_parent_class)
                contains "def self.up"
                contains "add_column :version_associations, :foreign_type"
              }
            }
          }
        }
      )
    end
  end
end
