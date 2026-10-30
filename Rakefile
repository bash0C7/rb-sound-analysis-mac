# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rake/extensiontask"

desc "Build the Swift package"
task :swift do
  sh "xcrun", "swift", "build", "-c", "release", "--package-path", "ext/sound_analysis_mac"
end

task compile: :swift

Rake::ExtensionTask.new("sound_analysis_mac") do |ext|
  ext.lib_dir = "lib/sound_analysis_mac"
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc "Validate the RBS signatures"
task :rbs do
  sh "rbs", "-I", "sig", "validate"
end

desc "Start an IRB console with sound_analysis_mac loaded"
task console: :compile do
  require "irb"
  $LOAD_PATH.unshift File.expand_path("lib", __dir__)
  require "sound_analysis_mac"
  ARGV.clear
  IRB.start
end

task test: %i[rbs compile]
task default: :test
