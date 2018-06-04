# frozen_string_literal: true

require "spec_helper"

RSpec.describe PaperTrail do
  context "default" do
    it "has versioning off by default" do
      expect(described_class).not_to be_enabled
    end

    it "has versioning on in a `with_versioning` block" do
      expect(described_class).not_to be_enabled
      with_versioning do
        expect(described_class).to be_enabled
      end
      expect(described_class).not_to be_enabled
    end

    context "error within `with_versioning` block" do
      it "reverts the value of `PaperTrail.enabled?` to its previous state" do
        expect(described_class).not_to be_enabled
        expect { with_versioning { raise } }.to raise_error(RuntimeError)
        expect(described_class).not_to be_enabled
      end
    end
  end

  context "`versioning: true`", versioning: true do
    it "has versioning on by default" do
      expect(described_class).to be_enabled
    end

    it "keeps versioning on after a with_versioning block" do
      expect(described_class).to be_enabled
      with_versioning do
        expect(described_class).to be_enabled
      end
      expect(described_class).to be_enabled
    end
  end

  context "`with_versioning` block at class level" do
    it { expect(described_class).not_to be_enabled }

    with_versioning do
      it "has versioning on by default" do
        expect(described_class).to be_enabled
      end
    end
    it "does not leak the `enabled?` state into successive tests" do
      expect(described_class).not_to be_enabled
    end
  end

  describe "deprecated methods" do
    before do
      allow(ActiveSupport::Deprecation).to receive(:warn)
    end

    shared_examples "it delegates to request" do |method, args|
      it do
        #arguments = args || [no_args]
        #allow(described_class.request).to receive(method)
        described_class.public_send(method, *args)
        #expect(described_class.request).to have_received(method).with(*arguments)
        expect(ActiveSupport::Deprecation).to have_received(:warn)
      end
    end

    it_behaves_like "it delegates to request", :clear_transaction_id, nil
    it_behaves_like "it delegates to request", :transaction_id=, 123
    it_behaves_like "it delegates to request", :transaction_id, nil
  end
end
