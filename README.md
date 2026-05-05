# rb-sound-analysis-mac

Ruby binding for Apple's Sound Analysis framework on macOS / Apple Silicon. Calls file-based sound classification using the built-in `MLSoundIdentifierVersion1` classifier (300+ environmental sounds: speech, music, applause, laughter, etc.) directly from Ruby via Swift Package Manager and a thin C bridge. Built on [swift_gem](https://github.com/bash0C7/swift_gem).

## Requirements

- macOS 12+, Apple Silicon
- Swift 6.3+ (SE-0495 `@c` attribute) for the library build. Install via [swiftly](https://www.swift.org/install/macos/).
- Ruby 3.2+, Bundler 4.x
- **Xcode Command Line Tools** only if you want to run `examples/sound_analysis_mac.swift`. The pure-Swift sample must run under `xcrun swift`; swiftly's 6.3 swift binary cannot JIT-link Apple system frameworks (SoundAnalysis) in interpret mode. The library build itself does not need CLT. Install with `xcode-select --install`.

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

Output is one `label\tconfidence` line per analysis time window. The default Apple `version1` classifier emits one classification per ~1s of audio. On SoundAnalysis-side failure (unreadable audio content, classifier unavailable, OS error, 30s timeout) the method returns `""`. **A missing path raises `Errno::ENOENT`** rather than silently returning `""`, so callers can distinguish bad input from a genuine empty classification. Unlike `rb-speech-mac`, this gem does **not** require Speech Recognition permission and works directly from a CLI Ruby session.

Or open an IRB console with the gem preloaded:

```bash
bundle exec rake console
```

## Preconditions: caller is responsible for audio preprocessing

This gem is a **thin pass-through wrapper** around `SNAudioFileAnalyzer` + `SNClassifySoundRequest(.version1)`. It does no audio preprocessing — no format conversion, resampling, channel downmix, denoise, trim, or gain normalization. If `SNAudioFileAnalyzer` can't open the file or the classifier emits nothing, `classify` returns `""`.

Apple's built-in `version1` classifier has known weak spots:

- **Container / codec must be supported by `AVAudioFile`** — typically `aiff`, `wav`, `caf`, `m4a`, `mp3`. Anything else (raw `.pcm`, `.opus`, `.flac` on older macOS) fails to open and the method returns `""`. Convert upstream (e.g. `afconvert`, `ffmpeg`) before calling.
- **Short clips (≲ 1 second)** — the classifier emits one classification per ~1s analysis window, so a 0.4s clip can return `""` even though "real" sound is in there. Pad / loop / aggregate upstream if you need labels for short clips.
- **Heavy background music or noise** — the top-1 label tracks whatever is loudest in the window. If you want speech detected over music, the caller should denoise / source-separate first; this gem only reports what `version1` heard.
- **Quiet / low-gain audio** — sub-threshold volume returns no labels. Normalize gain upstream.
- **Multichannel handling** — Apple's analyzer downmixes internally; callers who care about per-channel classification must split channels before passing each path in.
- **Streaming / live audio** — file-based only by design (mirrors `SNAudioFileAnalyzer`, not `SNAudioStreamAnalyzer`). Recording / chunking is the caller's responsibility.

**Detection of these cases is also the caller's job.** `classify` returns `""` for "audio loaded but classifier emitted nothing", "format unsupported", "30s timeout", and "internal OS error" alike — the gem does not distinguish them. Callers that need branching behavior should branch on `output.empty?` and apply their own fallback chain (convert → retry → trim → retry → give up).

A missing path is the one failure mode this gem **does** surface as an exception (`Errno::ENOENT`), since that is unambiguously bad input and never a legitimate empty classification.

## Reference: Ruby example

`example.rb` at the repo root demonstrates the call:

```bash
bundle exec ruby example.rb path/to/audio.aiff
```

It defaults to `test/fixtures/sample.aiff` (generated via `say -v Samantha`) if no argument is given.

## Reference: pure Swift sample

A self-contained Swift script lives at `examples/sound_analysis_mac.swift` for sanity-checking SoundAnalysis behavior without going through Ruby:

```bash
xcrun swift examples/sound_analysis_mac.swift path/to/audio.aiff
```

Use `xcrun swift` (Xcode toolchain), not bare `swift` from swiftly — swiftly 6.3's interpret mode does not JIT-link Apple system frameworks (SoundAnalysis) and fails at startup with symbol-resolution errors. Xcode's swift uses dyld and works as-is.

## Development

```bash
bundle install
bundle exec rake test
```

`rake test` automatically compiles the Swift Package (`swift build -c release`) and links the C bridge into `lib/sound_analysis_mac/sound_analysis_mac.bundle` before running the spec, via `Rake::ExtensionTask`.

To run only the build step: `bundle exec rake compile`.

## License

MIT.
