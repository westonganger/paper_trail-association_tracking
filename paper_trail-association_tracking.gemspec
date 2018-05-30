# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "paper_trail_association_tracking/version"

Gem::Specification.new do |s|
  s.name = "paper_trail-association_tracking"
  s.version = PaperTrailAssociationTracking::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Plugin for the PaperTrail gem to track and reify associations"
  s.description = "Plugin for the PaperTrail gem to track and reify associations"
  s.homepage = "https://github.com/westonganger/paper_trail-association_tracking"
  s.authors = ["Weston Ganger", "Jared Beck", "Ben Atkins"]
  s.email = "weston@westonganger.com"
  s.license = "MIT"

  s.files = Dir.glob("{lib/**/*}") + ['LICENSE', 'README.md', 'Rakefile', 'CHANGELOG.md']

  s.executables = []
  s.require_paths = ["lib"]

  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version = ">= 2.3.0"

  s.add_development_dependency "appraisal", "~> 2.2"
  s.add_development_dependency "byebug", "~> 9.1"
  s.add_development_dependency "ffaker", "~> 2.7"
  s.add_development_dependency "generator_spec", "~> 0.9.4"
  s.add_development_dependency "mysql2", "~> 0.4.10"
  s.add_development_dependency "pg", "~> 0.21.0"
  s.add_development_dependency "rack-test", [">= 0.6.3", "< 0.9"]
  s.add_development_dependency "rake", "~> 12.3"
  s.add_development_dependency "rspec-rails", "~> 3.7.2"
  s.add_development_dependency "rubocop", "~> 0.51.0"
  s.add_development_dependency "rubocop-rspec", "~> 1.19.0"
  s.add_development_dependency "sqlite3", "~> 1.3"
  s.add_development_dependency "timecop", "~> 0.9.1"
end
