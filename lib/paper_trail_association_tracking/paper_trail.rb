# frozen_string_literal: true

module PaperTrailAssociationTracking
  module PaperTrail
    def transaction?
      ::ActiveRecord::Base.connection.open_transactions.positive?
    end
  end
end
