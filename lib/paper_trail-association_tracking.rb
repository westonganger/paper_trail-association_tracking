# frozen_string_literal: true

require 'paper_trail'
require "paper_trail_association_tracking/config"
require "paper_trail_association_tracking/model_config"
require "paper_trail_association_tracking/reifier"
require "paper_trail_association_tracking/record_trail"
require "paper_trail_association_tracking/request"
require "paper_trail_association_tracking/paper_trail"
require "paper_trail_association_tracking/version_concern"

module PaperTrailAssociationTracking
  def self.version
    VERSION
  end

  def self.gem_version
    ::Gem::Version.new(VERSION)
  end
end

module PaperTrail
  class << self
    prepend ::PaperTrailAssociationTracking::PaperTrail::ClassMethods
  end

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
    class << self
      prepend ::PaperTrailAssociationTracking::Reifier::ClassMethods
    end
  end

  module Request
    class << self
      prepend ::PaperTrailAssociationTracking::Request::ClassMethods
    end
  end

  module VersionConcern
    include ::PaperTrailAssociationTracking::VersionConcern
    prepend ::PaperTrailAssociationTracking::VersionConcern::ClassMethods
  end
end

# Require frameworks
if defined?(::Rails)
  # Rails module is sometimes defined by gems like rails-html-sanitizer so we check for presence of Rails.application.
  if defined?(::Rails.application)
    require "paper_trail_association_tracking/frameworks/rails"
  else
    ::Kernel.warn('PaperTrail has been loaded too early, before rails is loaded. This can happen when another gem defines the ::Rails namespace, then PT is loaded, all before rails is loaded. You may want to reorder your Gemfile, or defer the loading of PT by using `require: false` and a manual require elsewhere.')
  end
else
  require "paper_trail_association_tracking/frameworks/active_record"
end
