# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "paper_trail/version_number"

Gem::Specification.new do |s|
  s.name = "paper_trail_association_tracking"
  s.version = PaperTrail::VERSION::STRING
  s.platform = Gem::Platform::RUBY
  s.summary = "Track changes to your models."
  s.description = "paper_trail plugin to track and reify associations"
  s.homepage = "https://github.com/westonganger/paper_trail_associations_tracking"
  s.authors = ["Weston Ganger", "Jared Beck", "Ben Atkins"]
  s.email = "weston@westonganger.com"
  s.license = "MIT"

  s.files = `git ls-files -z`.split("\x0").select { |f|
    f.match(%r{^(Gemfile|LICENSE|lib|paper_trail.gemspec)/})
  }
  s.executables = []
  s.require_paths = ["lib"]

  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version = ">= 2.3.0"

  # Rails does not follow semver, makes breaking changes in minor versions.
  s.add_dependency "paper_trail"#, ">= 10"
  #s.add_dependency "activerecord", [">= 4.2", "< 5.2"]

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
