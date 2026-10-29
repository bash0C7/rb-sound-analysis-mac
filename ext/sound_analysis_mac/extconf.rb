# frozen_string_literal: true

require_relative "swift_mkmf"

SwiftGem::Mkmf.create_swift_makefile(
  "sound_analysis_mac/sound_analysis_mac",
  package: "SoundAnalysisMac",
  source_dir: __dir__
)
