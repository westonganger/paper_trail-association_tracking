# frozen_string_literal: true

module PaperTrailAssociationTracking
  module PaperTrail
    module ClassMethods
      def transaction?
        ::ActiveRecord::Base.connection.open_transactions.positive?
      end

      # @deprecated
      def clear_transaction_id
        ::ActiveSupport::Deprecation.warn(
          "PaperTrail.clear_transaction_id is deprecated, use PaperTrail.request.clear_transaction_id",
          caller(1)
        )
        request.clear_transaction_id
      end

      # @deprecated
      def transaction_id
        ::ActiveSupport::Deprecation.warn(
          "PaperTrail.transaction_id is deprecated without replacement.",
          caller(1)
        )
        request.transaction_id
      end

      # @deprecated
      def transaction_id=(id)
        ::ActiveSupport::Deprecation.warn(
          "PaperTrail.transaction_id= is deprecated without replacement.",
          caller(1)
        )
        request.transaction_id = id
      end
    end
  end
end
