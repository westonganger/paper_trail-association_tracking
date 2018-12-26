# frozen_string_literal: true

require "paper_trail_association_tracking/reifiers/belongs_to"
require "paper_trail_association_tracking/reifiers/has_and_belongs_to_many"
require "paper_trail_association_tracking/reifiers/has_many"
require "paper_trail_association_tracking/reifiers/has_many_through"
require "paper_trail_association_tracking/reifiers/has_one"

module PaperTrailAssociationTracking
  # Given a version record and some options, builds a new model object.
  # @api private
  module Reifier
    module ClassMethods
      # See `VersionConcern#reify` for documentation.
      # @api private
      def reify(version, options)
        options = apply_defaults_to(options, version)
        model = super
        reify_associations(model, options, version)
        model
      end

      # Restore the `model`'s has_many associations as they were at version_at
      # timestamp We lookup the first child versions after version_at timestamp or
      # in same transaction.
      # @api private
      def reify_has_manys(transaction_id, model, options = {})
        assoc_has_many_through, assoc_has_many_directly =
          model.class.reflect_on_all_associations(:has_many).
            partition { |assoc| assoc.options[:through] }
        reify_has_many_associations(transaction_id, assoc_has_many_directly, model, options)
        reify_has_many_through_associations(transaction_id, assoc_has_many_through, model, options)
      end

      private

      # Given a hash of `options` for `.reify`, return a new hash with default
      # values applied.
      # @api private
      def apply_defaults_to(options, version)
        {
          version_at: version.created_at,
          mark_for_destruction: false,
          has_one: false,
          has_many: false,
          belongs_to: false,
          has_and_belongs_to_many: false,
          unversioned_attributes: :nil
        }.merge(options)
      end

      # @api private
      def each_enabled_association(associations, model)
        associations.each do |assoc|
          assoc_klass = assoc.polymorphic? ?
                          model.send(assoc.foreign_type).constantize : assoc.klass
          next unless ::PaperTrail.request.enabled_for_model?(assoc_klass)
          yield assoc
        end
      end

      # @api private
      def reify_associations(model, options, version)
        if options[:has_one]
          reify_has_one_associations(version.transaction_id, model, options)
        end
        if options[:belongs_to]
          reify_belongs_to_associations(version.transaction_id, model, options)
        end
        if options[:has_many]
          reify_has_manys(version.transaction_id, model, options)
        end
        if options[:has_and_belongs_to_many]
          reify_habtm_associations version.transaction_id, model, options
        end
      end

      # Restore the `model`'s has_one associations as they were when this
      # version was superseded by the next (because that's what the user was
      # looking at when they made the change).
      # @api private
      def reify_has_one_associations(transaction_id, model, options = {})
        associations = model.class.reflect_on_all_associations(:has_one)
        each_enabled_association(associations, model) do |assoc|
          ::PaperTrailAssociationTracking::Reifiers::HasOne.reify(assoc, model, options, transaction_id)
        end
      end

      # Reify all `belongs_to` associations of `model`.
      # @api private
      def reify_belongs_to_associations(transaction_id, model, options = {})
        associations = model.class.reflect_on_all_associations(:belongs_to)
        each_enabled_association(associations, model) do |assoc|
          ::PaperTrailAssociationTracking::Reifiers::BelongsTo.reify(assoc, model, options, transaction_id)
        end
      end

      # Reify all direct (not `through`) `has_many` associations of `model`.
      # @api private
      def reify_has_many_associations(transaction_id, associations, model, options = {})
        version_table_name = model.class.paper_trail.version_class.table_name
        each_enabled_association(associations, model) do |assoc|
          ::PaperTrailAssociationTracking::Reifiers::HasMany.reify(assoc, model, options, transaction_id, version_table_name)
        end
      end

      # Reify all HMT associations of `model`. This must be called after the
      # direct (non-`through`) has_manys have been reified.
      # @api private
      def reify_has_many_through_associations(transaction_id, associations, model, options = {})
        each_enabled_association(associations, model) do |assoc|
          ::PaperTrailAssociationTracking::Reifiers::HasManyThrough.reify(assoc, model, options, transaction_id)
        end
      end

      # Reify all HABTM associations of `model`.
      # @api private
      def reify_habtm_associations(transaction_id, model, options = {})
        model.class.reflect_on_all_associations(:has_and_belongs_to_many).each do |assoc|
          pt_enabled = ::PaperTrail.request.enabled_for_model?(assoc.klass)
          next unless model.class.paper_trail_save_join_tables.include?(assoc.name) || pt_enabled
          ::PaperTrailAssociationTracking::Reifiers::HasAndBelongsToMany.reify(pt_enabled, assoc, model, options, transaction_id)
        end
      end
    end
  end
end
