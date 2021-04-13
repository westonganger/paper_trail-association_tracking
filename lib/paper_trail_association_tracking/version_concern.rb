# frozen_string_literal: true

module PaperTrailAssociationTracking
  module VersionConcern
    extend ::ActiveSupport::Concern

    included do
      # Since the test suite has test coverage for this, we want to declare the association when the test suite is running.
      # This makes it pass when DB is not initialized prior to test runs such as when we run on Travis CI
      # Ex. (there won't be a db in `spec/dummy_app/db/`).
      if ::PaperTrail.config.track_associations?
        has_many :version_associations, dependent: :destroy
      end

      scope :within_transaction, ->(id) { where(transaction_id: id) }
    end
  end
end
