# frozen_string_literal: true

module PaperTrailAssociationTracking
  module Reifiers
    # Reify a single HMT association of `model`.
    # @api private
    module HasManyThrough
      class << self
        # @api private
        def reify(assoc, model, options, transaction_id)
          # Load the collection of through-models. For example, if `model` is a
          # Chapter, having many Paragraphs through Sections, then
          # `through_collection` will contain Sections.
          through_collection = through_collection(assoc, model, options, transaction_id)

          # Now, given the collection of "through" models (e.g. sections), load
          # the collection of "target" models (e.g. paragraphs)
          collection = collection(through_collection, assoc, options, transaction_id)

          # Finally, assign the `collection` of "target" models, e.g. to
          # `model.paragraphs`.
          model.send(assoc.name).proxy_association.target = collection
        end

        private

        # Examine the `through_reflection`, i.e., the "through:" option on the association.
        #
        # @api private
        def through_collection(assoc, model, options, transaction_id)
          through_reflection = assoc.through_reflection
          # If the through association is has_many, we can just return the reified association
          return model.send(assoc.options[:through]) if through_reflection.collection?

          # If the model wasn't reified with belongs_to: true/has_one: true, then
          # the through association hasn't been reified yet.
          unless model.association(assoc.options[:through]).loaded?
            if through_reflection.belongs_to?
              BelongsTo.reify(through_reflection, model, options, transaction_id)
            else
              HasOne.reify(through_reflection, model, options, transaction_id)
            end
          end
          # Wrap the association in a collection for `collection_through_has_many`
          [*model.send(assoc.options[:through])]
        end

        # Examine the `source_reflection`, i.e. the "source" of `assoc` the
        # `ThroughReflection`. The source can be a `BelongsToReflection`
        # or a `HasManyReflection`.
        #
        # If the association is a has_many association again, then call
        # reify_has_manys for each record in `through_collection`.
        #
        # @api private
        def collection(through_collection, assoc, options, transaction_id)
          if !assoc.source_reflection.belongs_to? && through_collection.present?
            collection_through_has_many(through_collection, assoc, options, transaction_id)
          else
            collection_through_belongs_to(through_collection, assoc, options, transaction_id)
          end
        end

        # @api private
        def collection_through_has_many(through_collection, assoc, options, transaction_id)
          through_collection.each do |through_model|
            ::PaperTrail::Reifier.reify_has_manys(transaction_id, through_model, options)
          end

          # At this point, the "through" part of the association chain has
          # been reified, but not the final, "target" part. To continue our
          # example, `model.sections` (including `model.sections.paragraphs`)
          # has been loaded. However, the final "target" part of the
          # association, that is, `model.paragraphs`, has not been loaded. So,
          # we do that now.
          through_collection.flat_map { |through_model|
            records = through_model.public_send(assoc.source_reflection_name)
            
            if records.respond_to?(:to_a)
              # Has Many association
              records = records.to_a
            else
              # Has One association - Nothing more to do
            end
            
            records
          }
        end

        # @api private
        def collection_through_belongs_to(through_collection, assoc, options, tx_id)
          ids = through_collection.map { |through_model|
            through_model.send(assoc.source_reflection.foreign_key)
          }
          versions = load_versions_for_hmt_association(assoc, ids, tx_id, options[:version_at])
          collection = Array.new assoc.klass.where(assoc.klass.primary_key => ids)
          ::PaperTrailAssociationTracking::Reifiers::HasMany.prepare_array(collection, options, versions)
          collection
        end

        # Given a `has_many(through:)` association and an array of `ids`, return
        # the version records from the point in time identified by `tx_id` or
        # `version_at`.
        # @api private
        def load_versions_for_hmt_association(assoc, ids, tx_id, version_at)
          version_ids = assoc.klass.paper_trail.version_class.
            select("MIN(id) as id").
            where("item_type = ?", assoc.klass.base_class.name).
            where("item_id IN (?)", ids).
            where(
              "created_at >= ? OR transaction_id = ?",
              version_at,
              tx_id
            ).
            group("item_id").
            map{|e| e.id}
          ::PaperTrailAssociationTracking::Reifiers::HasMany.versions_by_id(assoc.klass, version_ids)
        end
      end
    end
  end
end
