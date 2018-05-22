# frozen_string_literal: true

module PaperTrailAssociationTracking
  class Config
    attr_writer :track_associations

    def initialize

    end

    def track_associations?
      !!@track_associations
    end
  end
end
