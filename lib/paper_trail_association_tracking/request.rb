# frozen_string_literal: true

module PaperTrailAssociationTracking
  module Request
    # @api private
    def self.clear_transaction_id
      self.transaction_id = nil
    end

    # @api private
    def self.transaction_id
      store[:transaction_id]
    end

    # @api private
    def self.transaction_id=(id)
      store[:transaction_id] = id
    end
  end
end
