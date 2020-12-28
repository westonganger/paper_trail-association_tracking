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
      if ::PaperTrail.config.track_associations?
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

    module ClassMethods
      def changeset(options = {})
        super()
        return @changeset unless ::PaperTrail.config.track_associations?

        @changeset = load_changeset_has_many_through(@changeset) if options[:has_many_through]
        @changeset
      end

      private

      def load_changeset_has_many_through(changes)
        has_many_through_assocs
          .reduce(changes) do |acc, assoc|
              assoc_changes = has_many_through_changes(assoc)
              acc.merge!(assoc_changes) if assoc_changes.any?

              acc
          end

        changes
      end

      def has_many_assocs
        item_type.to_s.classify.constantize
          .reflect_on_all_associations(:has_many)
      end

      def has_many_through_assocs
        has_many_assocs
          .select { |assoc| assoc.through_reflection? }
      end

      def paper_trail_enabled?(assoc)
        ::PaperTrail.request.enabled_for_model?(assoc.klass) ||
          (assoc.through_reflection? && ::PaperTrail.request.enabled_for_model?(assoc.through_reflection.klass))
      end

      def has_many_through_changes(assoc)
        return {} unless object_changes.present?

        versions = find_associated_versions(assoc.through_reflection)

        return { "#{assoc.name}": updated_changes(assoc, versions) } if updated_changes(assoc, versions).any?

        { "#{assoc.name}": [removed_changes(assoc, versions), added_changes(assoc, versions)] }
      end

      def find_associated_versions(assoc)
        ::PaperTrail::Version.where(item_type: assoc.class_name, transaction_id: transaction_id)
          .joins(:version_associations)
          .where(version_associations: { foreign_key_name: assoc.foreign_key, foreign_key_id: item_id })
          .order('versions.created_at desc')
      end

      def updated_changes(assoc, versions)
        versions.select { |version| version.event == "update" }
          .map(&:changeset)
          .pluck(assoc.foreign_key)
          .flat_map do |change|
            [
              assoc.klass.find_by(id: change.first),
              assoc.klass.find_by(id: change.second)
            ]
          end
      end

      def added_changes(assoc, versions)
        versions.select { |version| version.event == "create" }
          .map(&:changeset)
          .pluck(assoc.foreign_key)
          .map { |change| assoc.klass.find_by(id: change.second) }
      end

      def removed_changes(assoc, versions)
        versions.select { |version| version.event == "destroy" }
          .map(&:changeset)
          .pluck(assoc.foreign_key)
          .map { |change| assoc.klass.find_by(id: change.first) }
      end
    end
  end
end
