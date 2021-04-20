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

  s.required_ruby_version = ">= 2.3.0"

  s.add_runtime_dependency "paper_trail", "< 12.0"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "byebug"
  s.add_development_dependency "ffaker"
  s.add_development_dependency "generator_spec"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "pg"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "timecop"
end
