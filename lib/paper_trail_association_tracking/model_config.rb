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

      setup_transaction_callbacks
      setup_callbacks_for_habtm(options[:join_tables])
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

    # Adds callbacks to record changes to habtm associations such that on save
    # the previous version of the association (if changed) can be reconstructed.
    def setup_callbacks_for_habtm(join_tables)
      @model_class.send :attr_accessor, :paper_trail_habtm
      @model_class.class_attribute :paper_trail_save_join_tables
      @model_class.paper_trail_save_join_tables = Array.wrap(join_tables)
      habtm_assocs_not_skipped.each(&method(:setup_habtm_change_callbacks))
    end

    def setup_habtm_change_callbacks(association)
      association_name = association.name

      if ActiveRecord::VERSION::MAJOR >= 7
        ### https://github.com/westonganger/paper_trail-association_tracking/pull/37#issuecomment-1067146121

        before_add_callback = lambda do |*args|
          update_habtm_state(association_name, :before_add, args[-2], args.last)
        end

        before_remove_callback = lambda do |*args|
          update_habtm_state(association_name, :before_remove, args[-2], args.last)
        end

        assoc_opts = association.options.merge(before_add: before_add_callback, before_remove: before_remove_callback)

        association.instance_variable_set(:@options, **assoc_opts)

        ::ActiveRecord::Associations::Builder::CollectionAssociation.send(:define_callbacks, @model_class, association)
      else
        %w[add remove].each do |verb|
          @model_class.send("before_#{verb}_for_#{association_name}").send(
            :<<,
            lambda do |*args|
              update_habtm_state(association_name, :"before_#{verb}", args[-2], args.last)
            end
          )
        end
      end
    end

    # Reset the transaction id when the transaction is closed.
    def setup_transaction_callbacks
      @model_class.after_commit { ::PaperTrail.request.clear_transaction_id }
      @model_class.after_rollback { ::PaperTrail.request.clear_transaction_id }
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
