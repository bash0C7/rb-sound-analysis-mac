# rb-sound-analysis-mac

Ruby binding for Apple's Sound Analysis framework on macOS / Apple Silicon. Classifies the sounds in an audio file with the built-in `version1` sound classifier (environmental sounds such as speech, music, applause, and laughter) from Ruby via Swift Package Manager and a thin C bridge. Built on [swift_gem](https://github.com/bash0C7/swift_gem).

## Requirements

- macOS 27+, Apple Silicon
- Xcode 27 (builds run `xcrun swift`)
- Ruby 4.0+, Bundler 4.x

## Installation

Install from source:

```bash
git clone https://github.com/bash0C7/rb-sound-analysis-mac.git
cd rb-sound-analysis-mac
bundle install
bundle exec rake compile
```

## Usage

```ruby
require "sound_analysis_mac"

SoundAnalysisMac.classify("path/to/audio.aiff")
# => "speech\t0.9190546274185181\nspeech\t0.9189109802246094\nspeech\t0.9176614880561829"
```

`classify(path)` runs `SNAudioFileAnalyzer` with `SNClassifySoundRequest(classifierIdentifier: .version1)` and returns one `label\tconfidence` line per analysis window, using the top classification of each window. The classifier's default window is 3 seconds and consecutive windows overlap by half, so a new line appears every 1.5 seconds of audio. It returns `""` when the file cannot be opened as audio or the analysis fails. A path that does not exist raises `Errno::ENOENT`. File analysis needs no privacy permission, so the gem works from a plain CLI Ruby session.

Open an IRB console with the gem preloaded:

```bash
bundle exec rake console
```

## Preconditions: caller is responsible for audio preprocessing

This gem passes the file to `SNAudioFileAnalyzer` as-is. It does no format conversion, resampling, channel downmix, denoising, trimming, or gain normalization.

Apple's built-in `version1` classifier has known weak spots:

- **Container / codec must be supported by `AVAudioFile`**, such as `aiff`, `wav`, `caf`, `m4a`, and `flac`. Files it cannot open, such as headerless raw PCM, return `""`. Convert upstream (for example with `afconvert` or `ffmpeg`).
- **Clips shorter than one analysis window (3 seconds)** return `""` even when they contain sound. Pad or loop short clips upstream.
- **Heavy background music or noise**. The top label tracks whatever dominates the window. Denoise or source-separate upstream if you want speech detected over music.
- **Quiet / low-gain audio** may produce no labels. Normalize gain upstream.
- **Multichannel audio**. The classifier analyzes the first channel. Split channels upstream and classify each file if you need per-channel labels.
- **Streaming / live audio** is out of scope. This gem is file-based (`SNAudioFileAnalyzer`, not `SNAudioStreamAnalyzer`); recording and chunking are the caller's job.

`classify` returns the same `""` for "classifier emitted nothing", "unsupported format", and "analysis failed". Branch on `output.empty?` and apply your own fallback (convert, pad, retry). A missing path is the one failure surfaced as an exception (`Errno::ENOENT`).

## Reference: Ruby example

```bash
bundle exec rake compile
bundle exec ruby example.rb path/to/audio.aiff
```

`example.rb` prints the classification of the given file, or of `test/fixtures/sample.aiff` when no argument is given.

## Reference: pure Swift sample

`examples/sound_analysis_mac.swift` runs the same classification without Ruby:

```bash
xcrun swift examples/sound_analysis_mac.swift path/to/audio.aiff
```

## Development

```bash
bundle install
bundle exec rake test
```

`rake test` validates `sig/sound_analysis_mac.rbs`, runs `xcrun swift build -c release --package-path ext/sound_analysis_mac`, builds the C extension into `lib/sound_analysis_mac/sound_analysis_mac.bundle`, then runs the tests. `bundle exec rake compile` runs only the build.

## License

MIT.
