# frozen_string_literal: true

module PaperTrailAssociationTracking
  module RecordTrail
    # Utility method for reifying. Anything executed inside the block will
    # appear like a new record.
    #
    # > .. as best as I can tell, the purpose of
    # > appear_as_new_record was to attempt to prevent the callbacks in
    # > AutosaveAssociation (which is the module responsible for persisting
    # > foreign key changes earlier than most people want most of the time
    # > because backwards compatibility or the maintainer hates himself or
    # > something) from running. By also stubbing out persisted? we can
    # > actually prevent those. A more stable option might be to use suppress
    # > instead, similar to the other branch in reify_has_one.
    # > -Sean Griffin (https://github.com/paper-trail-gem/paper_trail/pull/899)
    #
    # @api private
    def appear_as_new_record
      @record.instance_eval {
        alias :old_new_record? :new_record?
        alias :new_record? :present?
        alias :old_persisted? :persisted?
        alias :persisted? :nil?
      }
      yield
      @record.instance_eval {
        alias :new_record? :old_new_record?
        alias :persisted? :old_persisted?
      }
    end

    # @api private
    def record_create
      version = super
      if version
        update_transaction_id(version)
        save_associations(version)
      end
    end

    # @api private
    def data_for_create
      data = super
      add_transaction_id_to(data)
      data
    end

    # @api private
    def record_destroy(*args)
      version = super
      if version && version.respond_to?(:errors) && version.errors.empty?
        update_transaction_id(version)
        save_associations(version)
      end
      version
    end

    # @api private
    def data_for_destroy
      data = super
      add_transaction_id_to(data)
      data
    end

    # Returns a boolean indicating whether to store serialized version diffs
    # in the `object_changes` column of the version record.
    # @api private
    def record_object_changes?
      @record.paper_trail_options[:save_changes] &&
        @record.class.paper_trail.version_class.column_names.include?("object_changes")
    end

    # @api private
    def record_update(**opts)
      version = super
      if version && version.respond_to?(:errors) && version.errors.empty?
        update_transaction_id(version)
        save_associations(version)
      end
      version
    end

    # Used during `record_update`, returns a hash of data suitable for an AR
    # `create`. That is, all the attributes of the nascent `Version` record.
    #
    # @api private
    def data_for_update(*args)
      data = super
      add_transaction_id_to(data)
      data
    end

    # @api private
    def record_update_columns(*args)
      version = super
      if version && version.respond_to?(:errors) && version.errors.empty?
        update_transaction_id(version)
        save_associations(version)
      end
      version
    end

    # Returns data for record_update_columns
    # @api private
    def data_for_update_columns(*args)
      data = super
      add_transaction_id_to(data)
      data
    end

    # Saves associations if the join table for `VersionAssociation` exists.
    def save_associations(version)
      return unless ::PaperTrail.config.track_associations?
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
          ::PaperTrail::VersionAssociation.create(
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
      data[:transaction_id] = ::PaperTrail.request.transaction_id
    end

    # Given a HABTM association, returns an array of ids.
    #
    # @api private
    def habtm_assoc_ids(habtm_assoc)
      current = @record.send("#{habtm_assoc.name.to_s.singularize}_ids")
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
        if associated_record && ::PaperTrail.request.enabled_for_model?(associated_record.class)
          assoc_version_args[:foreign_key_id] = associated_record.id
        end
      elsif ::PaperTrail.request.enabled_for_model?(assoc.klass)
        assoc_version_args[:foreign_key_id] = @record.send(assoc.foreign_key)
      end

      if assoc_version_args.key?(:foreign_key_id)
        ::PaperTrail::VersionAssociation.create(assoc_version_args)
      end
    end

    # Returns true if the given HABTM association should be saved.
    # @api private
    def save_habtm_association?(assoc)
      @record.class.paper_trail_save_join_tables.include?(assoc.name) ||
        ::PaperTrail.request.enabled_for_model?(assoc.klass)
    end

    def update_transaction_id(version)
      return unless @record.class.paper_trail.version_class.column_names.include?("transaction_id")
      if ::PaperTrail.transaction? && ::PaperTrail.request.transaction_id.nil?
        ::PaperTrail.request.transaction_id = version.id
        version.transaction_id = version.id
        version.save
      end
    end
  end
end
