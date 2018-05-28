# frozen_string_literal: true

module PaperTrailAssociationTracking
  # Configures an ActiveRecord model, mostly at application boot time, but also
  # sometimes mid-request, with methods like enable/disable.
  module ModelConfig
    # Set up `@model_class` for PaperTrail. Installs callbacks, associations,
    # "class attributes", instance methods, and more.
    # @api private
    def setup(options = {})
      super

      setup_associations(options)
      setup_transaction_callbacks
      setup_callbacks_for_habtm options[:join_tables]
    end

    private

    # Raises an error if the provided class is an `abstract_class`.
    # @api private
    def assert_concrete_activerecord_class(class_name)
      if class_name.constantize.abstract_class?
        raise format(::PaperTrail::ModelConfig::E_HPT_ABSTRACT_CLASS, @model_class, class_name)
      end
    end

    def habtm_assocs_not_skipped
      @model_class.reflect_on_all_associations(:has_and_belongs_to_many).
        reject { |a| @model_class.paper_trail_options[:skip].include?(a.name.to_s) }
    end

    def setup_associations(options)
      @model_class.class_attribute :version_association_name
      @model_class.version_association_name = options[:version] || :version

      # The version this instance was reified from.
      @model_class.send :attr_accessor, @model_class.version_association_name

      @model_class.class_attribute :version_class_name
      @model_class.version_class_name = options[:class_name] || "PaperTrail::Version"

      @model_class.class_attribute :versions_association_name
      @model_class.versions_association_name = options[:versions] || :versions

      @model_class.send :attr_accessor, :paper_trail_event

      assert_concrete_activerecord_class(@model_class.version_class_name)

      @model_class.has_many(
        @model_class.versions_association_name,
        -> { order(model.timestamp_sort_order) },
        class_name: @model_class.version_class_name,
        as: :item
      )
    end

    # Adds callbacks to record changes to habtm associations such that on save
    # the previous version of the association (if changed) can be reconstructed.
    def setup_callbacks_for_habtm(join_tables)
      @model_class.send :attr_accessor, :paper_trail_habtm
      @model_class.class_attribute :paper_trail_save_join_tables
      @model_class.paper_trail_save_join_tables = Array.wrap(join_tables)
      habtm_assocs_not_skipped.each(&method(:setup_habtm_change_callbacks))
    end

    def setup_habtm_change_callbacks(assoc)
      assoc_name = assoc.name
      %w[add remove].each do |verb|
        @model_class.send(:"before_#{verb}_for_#{assoc_name}").send(
          :<<,
          lambda do |*args|
            update_habtm_state(assoc_name, :"before_#{verb}", args[-2], args.last)
          end
        )
      end
    end

    # Reset the transaction id when the transaction is closed.
    def setup_transaction_callbacks
      @model_class.after_commit { ::PaperTrail.request.clear_transaction_id }
      @model_class.after_rollback { ::PaperTrail.request.clear_transaction_id }
      @model_class.after_rollback { paper_trail.clear_rolled_back_versions }
    end

    def update_habtm_state(name, callback, model, assoc)
      model.paper_trail_habtm ||= {}
      model.paper_trail_habtm[name] ||= { removed: [], added: [] }
      state = model.paper_trail_habtm[name]
      assoc_id = assoc.id
      case callback
      when :before_add
        state[:added] |= [assoc_id]
        state[:removed] -= [assoc_id]
      when :before_remove
        state[:removed] |= [assoc_id]
        state[:added] -= [assoc_id]
      else
        raise "Invalid callback: #{callback}"
      end
    end
  end
end
