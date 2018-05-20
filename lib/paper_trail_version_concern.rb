require "paper_trail"

require "paper_trail/config"
require "paper_trail/reifier"
require "paper_trail/version_association_concern"
require "paper_trail/version_concern"

module PaperTrail::AssociationsTracking
  # Returns PaperTrail::AssociationTracking's global configuration object, a singleton
  # @api private
  def self.config
    @config ||= PaperTrail::AssociationTracking::Config.instance

    if block_given?
      yield @config
    end

    return @config
  end

  def self.version
    VERSION::STRING
  end

  def self.gem_version
    ::Gem::Version.new(VERSION::STRING)
  end
end
