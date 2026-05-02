#!/usr/bin/env ruby
# frozen_string_literal: true

# Run with: bundle exec ruby example.rb [<audio-path>]
# Build the native extension first: bundle exec rake compile

require_relative "lib/sound_analysis_mac"

path = ARGV.first || File.expand_path("test/fixtures/sample.aiff", __dir__)

puts "audio: #{path}"
puts
output = SoundAnalysisMac.classify(path)
if output.empty?
  puts "(no classification)"
else
  puts "label\tconfidence"
  puts output
end
