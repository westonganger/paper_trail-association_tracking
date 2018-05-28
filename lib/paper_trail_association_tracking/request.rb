# frozen_string_literal: true

module PaperTrailAssociationTracking
  module Request
    module ClassMethods
      # @api private
      def clear_transaction_id
        self.transaction_id = nil
      end

      # @api private
      def transaction_id
        store[:transaction_id]
      end

      # @api private
      def transaction_id=(id)
        store[:transaction_id] = id
      end

      private

      def validate_public_options(options)
        if options.keys.include?(:transaction_id)
          raise ::PaperTrail::Request::InvalidOption, "Cannot set private option: transaction_id"
        else
          super
        end
      end
    end
  end
end
