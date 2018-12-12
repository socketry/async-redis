require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test)

import "tasks/generate_dsl.rake"

task :default => :test
