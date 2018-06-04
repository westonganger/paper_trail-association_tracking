# frozen_string_literal: true

require "spec_helper"

RSpec.describe PaperTrailAssociationTracking do
  describe ".gem_version" do
    it "returns a Gem::Version" do
      v = described_class.gem_version
      expect(v).to be_a(::Gem::Version)
      expect(v.to_s).to eq(described_class::VERSION)
    end
  end
end
