# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe ModelConfig, versioning: true do
    after do
      Timecop.return
    end

    describe "class_name" do
      before do
        @widget = Widget.create(name: "widget_0")
        @wotsit = Wotsit.create(widget_id: @widget.id, name: "wotsit_0")
        @version = @wotsit.versions.last
        @version_association = @version.version_associations.last
      end

      it "customize the version association class" do
        expect(@version).to be_a(CustomVersion)
        expect(@version_association).to be_a(CustomVersionAssociation)
      end
    end
  end
end
