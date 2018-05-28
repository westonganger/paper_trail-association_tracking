# frozen_string_literal: true

module PaperTrailAssociationTracking
  module Rails
    # See http://guides.rubyonrails.org/engines.html
    class Engine < ::Rails::Engine
      paths["app/models"] << "lib/paper_trail_association_tracking/frameworks/active_record/models"
    end
  end
end
