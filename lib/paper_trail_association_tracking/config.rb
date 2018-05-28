# frozen_string_literal: true

module PaperTrailAssociationTracking
  module Config
    attr_accessor :association_reify_error_behaviour
    attr_writer :track_associations

    def track_associations?
      !!@track_associations
    end
  end
end
