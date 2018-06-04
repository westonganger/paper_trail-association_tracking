# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe Config do
    describe "track_associations?" do
      context "@track_associations is nil" do
        it "returns false and prints a deprecation warning" do
          config = described_class.instance
          config.track_associations = nil
          expect(config.track_associations?).to eq(false)
        end

        after do
          PaperTrail.config.track_associations = true
        end
      end
    end
  end
end
