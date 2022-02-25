# frozen_string_literal: true

module PaperTrailAssociationTracking
  class Railtie < ::Rails::Railtie

    initializer "paper_trail_association_tracking", after: "paper_trail" do
      ActiveSupport.on_load(:active_record) do
        require "paper_trail_association_tracking/frameworks/active_record"
      end
    end

    config.to_prepare do
      ::PaperTrail::Version.include(::PaperTrailAssociationTracking::VersionConcern)
    end

  end
end
