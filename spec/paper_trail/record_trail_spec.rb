# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe RecordTrail, versioning: true do
    describe "saving belongs_to associations" do
      # Apps that use `load_defaults` have `belongs_to_required_by_default`
      # enabled, which gives `VersionAssociation#version` this validation.
      context "when VersionAssociation validates the presence of its version" do
        before { ::PaperTrail::VersionAssociation.validates_presence_of :version, message: :required }
        after { ::PaperTrail::VersionAssociation.clear_validators! }

        it "writes the association row without loading the version it just created" do
          widget = Widget.create!(name: "widget")
          queries = []
          callback = lambda do |*, payload|
            next if %w[SCHEMA TRANSACTION CACHE].include?(payload[:name].to_s) || payload[:cached]

            queries << payload[:sql]
          end

          bizzo = ::ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
            Bizzo.create!(widget: widget, name: "bizzo")
          end

          expect(queries.grep(/SELECT .* FROM .*versions.* WHERE/i)).to be_empty
          expect(queries.grep(/INSERT INTO .*version_associations/i).size).to eq(1)
          association = ::PaperTrail::VersionAssociation.find_by!(
            version_id: bizzo.versions.last.id, foreign_key_name: "widget_id"
          )
          expect(association.foreign_key_id).to eq(widget.id)
        end

        it "still writes the row when the version is not the association's version class" do
          widget = Widget.create!(name: "widget")
          audited = AuditedBizzo.create!(widget: widget, name: "audited")

          expect(audited.versions.last).to be_a(ConcernOnlyVersion)
          association = ::PaperTrail::VersionAssociation.find_by!(
            version_id: audited.versions.last.id, foreign_key_name: "widget_id"
          )
          expect(association.foreign_key_id).to eq(widget.id)
        end
      end
    end
  end
end
