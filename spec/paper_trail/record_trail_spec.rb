# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe RecordTrail, versioning: true do
    describe "saving belongs_to associations" do
      # The dummy app enables `belongs_to_required_by_default`, as apps that
      # call `load_defaults` do, so `VersionAssociation#version` validates its
      # presence here the way it does in most host apps.
      it "validates the presence of the version" do
        expect(::PaperTrail::VersionAssociation.validators_on(:version).map(&:kind)).to include(:presence)
      end

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
