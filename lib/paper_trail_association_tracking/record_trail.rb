# frozen_string_literal: true

module PaperTrail
  # Represents the "paper trail" for a single record.
  class RecordTrail
    # Saves associations if the join table for `VersionAssociation` exists.
    def save_associations(version)
      return unless PaperTrail.config.track_associations?
      save_bt_associations(version)
      save_habtm_associations(version)
    end

    # Save all `belongs_to` associations.
    # @api private
    def save_bt_associations(version)
      @record.class.reflect_on_all_associations(:belongs_to).each do |assoc|
        save_bt_association(assoc, version)
      end
    end

    # When a record is created, updated, or destroyed, we determine what the
    # HABTM associations looked like before any changes were made, by using
    # the `paper_trail_habtm` data structure. Then, we create
    # `VersionAssociation` records for each of the associated records.
    # @api private
    def save_habtm_associations(version)
      @record.class.reflect_on_all_associations(:has_and_belongs_to_many).each do |a|
        next unless save_habtm_association?(a)
        habtm_assoc_ids(a).each do |id|
          PaperTrail::VersionAssociation.create(
            version_id: version.transaction_id,
            foreign_key_name: a.name,
            foreign_key_id: id
          )
        end
      end
    end

    private

    def add_transaction_id_to(data)
      return unless @record.class.paper_trail.version_class.column_names.include?("transaction_id")
      data[:transaction_id] = PaperTrail.request.transaction_id
    end

    # Given a HABTM association, returns an array of ids.
    #
    # @api private
    def habtm_assoc_ids(habtm_assoc)
      current = @record.send(habtm_assoc.name).to_a.map(&:id) # TODO: `pluck` would use less memory
      removed = @record.paper_trail_habtm.try(:[], habtm_assoc.name).try(:[], :removed) || []
      added = @record.paper_trail_habtm.try(:[], habtm_assoc.name).try(:[], :added) || []
      current + removed - added
    end

    # Save a single `belongs_to` association.
    # @api private
    def save_bt_association(assoc, version)
      assoc_version_args = {
        version_id: version.id,
        foreign_key_name: assoc.foreign_key
      }

      if assoc.options[:polymorphic]
        associated_record = @record.send(assoc.name) if @record.send(assoc.foreign_type)
        if associated_record && PaperTrail.request.enabled_for_model?(associated_record.class)
          assoc_version_args[:foreign_key_id] = associated_record.id
        end
      elsif PaperTrail.request.enabled_for_model?(assoc.klass)
        assoc_version_args[:foreign_key_id] = @record.send(assoc.foreign_key)
      end

      if assoc_version_args.key?(:foreign_key_id)
        PaperTrail::VersionAssociation.create(assoc_version_args)
      end
    end

    # Returns true if the given HABTM association should be saved.
    # @api private
    def save_habtm_association?(assoc)
      @record.class.paper_trail_save_join_tables.include?(assoc.name) ||
        PaperTrail.request.enabled_for_model?(assoc.klass)
    end

    def update_transaction_id(version)
      return unless @record.class.paper_trail.version_class.column_names.include?("transaction_id")
      if PaperTrail.transaction? && PaperTrail.request.transaction_id.nil?
        PaperTrail.request.transaction_id = version.id
        version.transaction_id = version.id
        version.save
      end
    end
  end
end
