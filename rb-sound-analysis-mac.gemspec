# frozen_string_literal: true

require_relative "lib/sound_analysis_mac/version"

Gem::Specification.new do |spec|
  spec.name = "rb-sound-analysis-mac"
  spec.version = SoundAnalysisMac::VERSION
  spec.authors = ["bash0C7"]
  spec.email = ["ksb.4038.nullpointer+github@gmail.com"]

  spec.summary = "Ruby binding for Apple Sound Analysis framework on macOS"
  spec.description = "Calls Apple SoundAnalysis framework's built-in sound classifier (version1) on audio files from Ruby on macOS / Apple Silicon. Built on top of swift_gem."
  spec.homepage = "https://github.com/bash0C7/rb-sound-analysis-mac"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bash0C7/rb-sound-analysis-mac"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/sound_analysis_mac/extconf.rb"]
end
