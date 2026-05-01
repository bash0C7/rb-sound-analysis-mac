# rb-sound-analysis-mac

Ruby binding for Apple's Sound Analysis framework on macOS. Wraps file-based sound classification using the built-in `MLSoundIdentifierVersion1` classifier (300+ environmental sounds: speech, music, applause, laughter, etc.).

Built on top of [swift_gem](https://github.com/bash0C7/swift_gem). macOS / Apple Silicon only.

## Usage

```ruby
require "sound_analysis_mac"

SoundAnalysisMac.classify("path/to/audio.aiff")
# => "speech\t0.91\nspeech\t0.88\nspeech\t0.93\n..."
```

Output is one `label\tconfidence` line per analysis time window. The default Apple `version1` classifier emits one classification per ~1s of audio.

On failure (unreadable file, OS error, 30s timeout) the method returns `""`.

Unlike `rb-speech-mac`, this gem does **not** require Speech Recognition permission and works directly from a CLI Ruby session.

## Reference Swift example

```bash
swift examples/sound_analysis_mac.swift path/to/audio.aiff
```

## Development

```bash
bundle install
bundle exec rake test
```

The test fixture `test/fixtures/sample.aiff` is shared with `rb-speech-mac` (generated via `say -v Samantha`).

## License

MIT.
