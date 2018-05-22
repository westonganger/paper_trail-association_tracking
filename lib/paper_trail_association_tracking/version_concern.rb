# frozen_string_literal: true

module PaperTrail
  # Originally, PaperTrail did not provide this module, and all of this
  # functionality was in `PaperTrail::Version`. That model still exists (and is
  # used by most apps) but by moving the functionality to this module, people
  # can include this concern instead of sub-classing the `Version` model.
  module VersionConcern
    extend ::ActiveSupport::Concern

    included do
      if ::ActiveRecord.gem_version >= Gem::Version.new("5.0")
        belongs_to :item, polymorphic: true, optional: true
      else
        belongs_to :item, polymorphic: true
      end

      # Since the test suite has test coverage for this, we want to declare
      # the association when the test suite is running. This makes it pass when
      # DB is not initialized prior to test runs such as when we run on Travis
      # CI (there won't be a db in `spec/dummy_app/db/`).
      if PaperTrail.config.track_associations?
        has_many :version_associations, dependent: :destroy
      end

      validates_presence_of :event
      after_create :enforce_version_limit!
      scope(:within_transaction, ->(id) { where transaction_id: id })
    end

    # Restore the item from this version.
    #
    # Optionally this can also restore all :has_one and :has_many (including
    # has_many :through) associations as they were "at the time", if they are
    # also being versioned by PaperTrail.
    #
    # Options:
    #
    # - :has_one
    #   - `true` - Also reify has_one associations.
    #   - `false - Default.
    # - :has_many
    #   - `true` - Also reify has_many and has_many :through associations.
    #   - `false` - Default.
    # - :mark_for_destruction
    #   - `true` - Mark the has_one/has_many associations that did not exist in
    #     the reified version for destruction, instead of removing them.
    #   - `false` - Default. Useful for persisting the reified version.
    # - :dup
    #   - `false` - Default.
    #   - `true` - Always create a new object instance. Useful for
    #     comparing two versions of the same object.
    # - :unversioned_attributes
    #   - `:nil` - Default. Attributes undefined in version record are set to
    #     nil in reified record.
    #   - `:preserve` - Attributes undefined in version record are not modified.
    #
    def reify(options = {})
      return nil if object.nil?
      ::PaperTrail::Reifier.reify(self, options)
    end

  end
end
