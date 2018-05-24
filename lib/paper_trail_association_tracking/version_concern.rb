# frozen_string_literal: true

module PaperTrailAssociationTracking
  # Originally, PaperTrail did not provide this module, and all of this
  # functionality was in `PaperTrail::Version`. That model still exists (and is
  # used by most apps) but by moving the functionality to this module, people
  # can include this concern instead of sub-classing the `Version` model.
  module VersionConcern
    extend ::ActiveSupport::Concern

    included do
      # Since the test suite has test coverage for this, we want to declare the association when the test suite is running.
      # This makes it pass when DB is not initialized prior to test runs such as when we run on Travis CI
      # Ex. (there won't be a db in `spec/dummy_app/db/`).
      if PaperTrail.config.track_associations?
        has_many :version_associations, dependent: :destroy
      end

      scope(:within_transaction, ->(id) { where transaction_id: id })
    end

    # Restore the item from this version.
    #
    # In addition to the options provided by PaperTrail core. This Plugin provides the following Options:
    #
    # - :has_one
    #   - `true` - Also reify has_one associations.
    #   - `false - Default.
    # - :has_many
    #   - `true` - Also reify has_many and has_many :through associations.
    #   - `false` - Default.
    #
    #def reify(options = {})
    #  super
    #end
  end
end
