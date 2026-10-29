# CLAUDE.md — rb-sound-analysis-mac

## Position

Ruby native binding for Apple's Sound Analysis framework on macOS, built on the `bash0C7/swift_gem` scaffold. Exposes file-based sound classification with Apple's built-in `version1` classifier (`SNClassifierIdentifier.version1`: environmental sounds such as speech, music, applause, laughter). Sibling of `rb-vision-mac`.

## Core design principles

1. Thin wrapper. Pass-through Sound Analysis API. One audio file → one classification string (newline-separated `label\tconfidence` pairs, one per analysis window).
2. Fixed defaults: built-in `.version1` classifier with its default window and overlap, `SNAudioFileAnalyzer`, top-1 classification per window. Custom CoreML models, multi-classification, and stream analysis wait until needed.
3. Synchronous call. `SNAudioFileAnalyzer.analyze()` is synchronous and delivers every observer callback on the calling thread before it returns, so there is no semaphore or timeout. SoundAnalysis-side failure (file not openable as audio, request failure) → empty string, no exception. A path that cannot be `stat`ed → `Errno::ENOENT` (the C wrapper `stat()`s the path before handoff so callers can tell bad input from a genuine empty result).
4. C bridge string handoff. One `@c(sound_analysis_mac_classify)` (SE-0495) function plus `cFree` exported as `sound_analysis_mac_free`. Signature fixed at `UnsafePointer<CChar>` → `UnsafeMutablePointer<CChar>`.
5. Scaffold parity. `bundle exec rake "new[rb-sound-analysis-mac,<dir>]"` in swift_gem produces a skeleton whose only diffs against this repo are the implementation body, `sig/` contents, example scripts, fixtures, tests, docs, gemspec summary and description, and build artifacts.

## Public API

| Method | Returns | Notes |
|---|---|---|
| `SoundAnalysisMac.classify(path)` | newline-separated `"label\tconfidence"` pairs (top-1 per analysis window) | `SNAudioFileAnalyzer` + `SNClassifySoundRequest(classifierIdentifier: .version1)`. Default window 3 s with 0.5 overlap; audio shorter than one window returns `""`. `""` on SoundAnalysis-side failure; `Errno::ENOENT` on missing path |

Signatures and their documentation live in `sig/sound_analysis_mac.rbs`. File analysis has no TCC privacy gate, so the gem works from a CLI Ruby session.

## Architecture

```
[caller (Ruby)]
  │
  │   SoundAnalysisMac.classify(path) → String
  ▼
lib/sound_analysis_mac.rb
  │
  ▼
ext/sound_analysis_mac/sound_analysis_mac.c   ← rb_define_singleton_method, stat()
  │
  │   sound_analysis_mac_classify(c_path)
  ▼
ext/sound_analysis_mac/Sources/SoundAnalysisMac/SoundAnalysisMacBridge.swift   ← @c(name) (SE-0495)
  │
  ▼
ext/sound_analysis_mac/Sources/SoundAnalysisMac/SoundAnalysisMac.swift   ← SNAudioFileAnalyzer + SNClassifySoundRequest
  │
  ▼
[Apple SoundAnalysis framework]
```

## Module boundaries

| Layer | Responsibility |
|---|---|
| `lib/sound_analysis_mac.rb` | `require_relative` to load the .bundle; host of `module SoundAnalysisMac` |
| `sig/sound_analysis_mac.rbs` | RBS for `VERSION`, `Error`, and `classify` |
| `ext/sound_analysis_mac/sound_analysis_mac.c` | `Init_sound_analysis_mac` exposes `classify`; `stat()`s the path, copies the Swift-returned `char*` into a Ruby UTF-8 String, then calls `sound_analysis_mac_free` |
| `SoundAnalysisMacBridge.swift` | C ABI exports via `@c(name)`. Calls `classify(path:)` and returns a C string via `strdup` |
| `SoundAnalysisMac.swift` | Real implementation: `SNAudioFileAnalyzer.analyze()` + an `SNResultsObserving` collector |
| `ext/sound_analysis_mac/extconf.rb` | `require_relative "swift_mkmf"` + `SwiftGem::Mkmf.create_swift_makefile("sound_analysis_mac/sound_analysis_mac", package: "SoundAnalysisMac", source_dir: __dir__)` |
| `ext/sound_analysis_mac/swift_mkmf.rb` | Vendored copy of swift_gem's `lib/swift_gem/mkmf.rb`, kept identical |
| `examples/sound_analysis_mac.swift` | Ruby-free SoundAnalysis sample: `xcrun swift examples/sound_analysis_mac.swift <path>` |
| `example.rb` | Ruby sample: `bundle exec ruby example.rb [<path>]` |
| `Rakefile` | `task :swift` + `task compile: :swift` before `Rake::ExtensionTask("sound_analysis_mac")`; `task :rbs`; `task test: %i[rbs compile]`; `task console: :compile` |

## Build flow

`bundle exec rake test` validates the RBS, builds, and tests in one shot. `xcrun swift build -c release --package-path ext/sound_analysis_mac` writes `SoundAnalysisMac-Swift.h` under `ext/sound_analysis_mac/.build/out/Intermediates.noindex/GeneratedModuleMaps/` (added with `-I`) and the dylib under `ext/sound_analysis_mac/.build/release`.

## Usage / why no CLI

Library only, same as `rb-vision-mac`. Interactive checks via `bundle exec rake console`.

## TDD discipline

t-wada style RED → GREEN → REFACTOR independent commits. test-unit. Tests call the real framework. Fixture: `test/fixtures/sample.aiff` (a `say -v Samantha` clip; the classifier labels it `speech`).

## Related projects

- `~/dev/src/github.com/bash0C7/swift_gem` — scaffold/Mkmf framework
- `~/dev/src/github.com/bash0C7/rb-vision-mac` — sibling built on the same scaffold
- `~/dev/src/github.com/bash0C7/rb-speech-mac` — sibling file-based audio gem (Speech framework, TCC-restricted)

## Environment requirements

macOS 27+, Apple Silicon, Xcode 27 (Swift 6.4, builds run `xcrun swift`), Ruby 4.0+, bundler 4.x, rake-compiler 1.2+. `Gemfile.lock` is not git-tracked.

## Prohibitions

- No Python source
- No code comments. Swift is documented with DocC (`///`, `- Parameter`, `- Returns`, ``` ``symbol`` ``` links); Ruby is documented with `#` comments above declarations in `sig/sound_analysis_mac.rbs`. History goes in commit messages
- Do not hand-edit `ext/sound_analysis_mac/swift_mkmf.rb`; re-copy it from swift_gem
- Do not git-track `Gemfile.lock`
- Do not bundle a custom CoreML model here — keep this gem on the built-in classifier
- Do not add stream-based analysis (`SNAudioStreamAnalyzer`) here — file-based only
- Do not promise thread safety for concurrent calls
- Do not cache, normalize, or post-process classification results here
- Commit messages in English, conventional commits style
- `.claude/` is committed
