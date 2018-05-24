# frozen_string_literal: true

require "paper_trail_association_tracking/config"
require "paper_trail_association_tracking/model_config"
require "paper_trail_association_tracking/version_concern"
require "paper_trail_association_tracking/reifier"

module PaperTrailAssociationTracking
  def self.version
    VERSION::STRING
  end

  def self.gem_version
    ::Gem::Version.new(VERSION::STRING)
  end
end

module PaperTrail
  #class << self
  #  prepend ::PaperTrailAssociationTracking::PaperTrail
  #end

  class Config
    prepend ::PaperTrailAssociationTracking::Config
  end

  class ModelConfig
    prepend ::PaperTrailAssociationTracking::ModelConfig
  end

  class RecordTrail
    prepend ::PaperTrailAssociationTracking::RecordTrail
  end

  module Reifier
    prepend ::PaperTrailAssociationTracking::Reifier
  end

  module VersionConcern
    include ::PaperTrailAssociationTracking::VersionConcern
  end

  module VersionAssociationConcern
    include ::PaperTrailAssociationTracking::VersionAssociationConcern
  end
end
