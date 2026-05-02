# rb-sound-analysis-mac

Ruby binding for Apple's Sound Analysis framework on macOS / Apple Silicon. Calls file-based sound classification using the built-in `MLSoundIdentifierVersion1` classifier (300+ environmental sounds: speech, music, applause, laughter, etc.) directly from Ruby via Swift Package Manager and a thin C bridge. Built on [swift_gem](https://github.com/bash0C7/swift_gem).

## Installation

```bash
bundle add rb-sound-analysis-mac
```

```bash
gem install rb-sound-analysis-mac
```

## Usage

```ruby
require "sound_analysis_mac"

SoundAnalysisMac.classify("path/to/audio.aiff")
# => "speech\t0.91\nspeech\t0.88\nspeech\t0.93\n..."
```

Output is one `label\tconfidence` line per analysis time window. The default Apple `version1` classifier emits one classification per ~1s of audio. On failure (unreadable file, OS error, 30s timeout) the method returns `""`. Unlike `rb-speech-mac`, this gem does **not** require Speech Recognition permission and works directly from a CLI Ruby session.

Or open an IRB console with the gem preloaded:

```bash
bundle exec rake console
```

## Reference: Ruby example

`example.rb` at the repo root demonstrates the call:

```bash
bundle exec ruby example.rb path/to/audio.aiff
```

It defaults to `test/fixtures/sample.aiff` (generated via `say -v Samantha`) if no argument is given.

## Reference: pure Swift sample

A self-contained Swift script lives at `examples/sound_analysis_mac.swift` for sanity-checking SoundAnalysis behavior without going through Ruby:

```bash
swift examples/sound_analysis_mac.swift path/to/audio.aiff
```

## Development

```bash
bundle install
bundle exec rake test
```

`rake test` automatically compiles the Swift Package (`swift build -c release`) and links the C bridge into `lib/sound_analysis_mac/sound_analysis_mac.bundle` before running the spec, via `Rake::ExtensionTask`.

To run only the build step: `bundle exec rake compile`.

## License

MIT.
