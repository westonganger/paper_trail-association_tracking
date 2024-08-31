require "bundler"
Bundler::GemHelper.install_tasks

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

task test: [:spec]

task default: [:spec]

task :console do
  require "paper_trail-association-tracking"

  require "irb"
  binding.irb
end
