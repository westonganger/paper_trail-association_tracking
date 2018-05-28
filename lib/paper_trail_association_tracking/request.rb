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
    end
  end
end
