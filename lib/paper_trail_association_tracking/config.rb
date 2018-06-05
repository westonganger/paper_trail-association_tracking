# frozen_string_literal: true

module PaperTrailAssociationTracking
  module Config
    def association_reify_error_behaviour=(val)
      val = val.to_s
      if ['error', 'warn', 'ignore'].include?(val.to_s)
        @association_reify_error_behaviour = val.to_s
      else
        raise ArgumentError.new('Incorrect value passed to `association_reify_error_behaviour`')
      end
    end

    def association_reify_error_behaviour
      @association_reify_error_behaviour ||= "error"
    end

    def track_associations=(val)
      @track_associations = !!val
    end

    def track_associations?
      !!@track_associations
    end
  end
end
