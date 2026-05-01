# CLAUDE.md — rb-sound-analysis-mac

## Position

Ruby native binding for Apple's Sound Analysis framework on macOS. Sibling of `rb-vision-ocrmac`, built on the same `bash0C7/swift_gem` scaffold. Exposes file-based sound classification using Apple's built-in `MLSoundIdentifierVersion1` classifier (300+ environmental sounds: speech, music, applause, laughter, etc.).

## Core design principles

1. Thin wrapper. Pass-through Sound Analysis API. One audio file → one classification string (newline-separated `label\tconfidence` pairs, one per analysis time window).
2. Fixed defaults: built-in `.version1` classifier, `SNAudioFileAnalyzer` (sync), top-1 classification per window. Custom CoreML models, multi-classification, and stream analysis are intentionally not added until needed.
3. 30s overall timeout. Failure (unreadable file, classifier unavailable, OS error, timeout) → empty string. Does not raise exceptions.
4. C bridge string handoff. Single `@_cdecl` pair plus shared `sound_analysis_mac_free`. Bridge function signatures fixed at `UnsafePointer<CChar>` ↔ `UnsafeMutablePointer<CChar>`.
5. Scaffold parity. `swift_gem new rb-sound-analysis-mac` produces a skeleton whose only diffs against this repo are the implementation body, fixtures, and build artifacts.

## Public API

| Method | Returns | Notes |
|---|---|---|
| `SoundAnalysisMac.classify(path)` | newline-separated `"label\tconfidence"` pairs (top-1 per analysis window) | `SNAudioFileAnalyzer` + `SNClassifySoundRequest(classifierIdentifier: .version1)`. Empty string on failure |

Sound Analysis does **not** require microphone permission for file analysis (no TCC privacy gate), so unlike `rb-speech-mac` this gem actually works from a CLI Ruby session.

## Architecture

```
[caller (Ruby)]
  │
  │   SoundAnalysisMac.classify(path) → String
  ▼
lib/sound_analysis_mac.rb
  │
  ▼
ext/sound_analysis_mac/sound_analysis_mac.c   ← rb_define_singleton_method
  │
  │   sound_analysis_mac_classify(c_path)
  ▼
ext/sound_analysis_mac/Sources/SoundAnalysisMac/SoundAnalysisMacBridge.swift   ← @_cdecl
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
| `ext/sound_analysis_mac/sound_analysis_mac.c` | `Init_sound_analysis_mac` exposes `classify`; copies Swift-returned `char*` into a Ruby UTF-8 String, then calls `sound_analysis_mac_free` |
| `SoundAnalysisMacBridge.swift` | C ABI export via `@_cdecl` |
| `SoundAnalysisMac.swift` | Real implementation: `SNAudioFileAnalyzer.analyze()` (synchronous) + an `SNResultsObserving` collector |
| `ext/sound_analysis_mac/extconf.rb` | `SwiftGem::Mkmf.create_swift_makefile("sound_analysis_mac/sound_analysis_mac", package: "SoundAnalysisMac", source_dir: __dir__)` |
| `examples/sound_analysis_mac.swift` | Pure-Swift sample script |
| `Rakefile` | `Rake::ExtensionTask("sound_analysis_mac")` + `task test: :compile`. `task console: :compile` for IRB |

## Build flow

`bundle exec rake test` in one shot — same as `rb-vision-ocrmac`.

## Usage / why no CLI

Library only — same rationale as `rb-vision-ocrmac`. Interactive checks via `bundle exec rake console`. `examples/sound_analysis_mac.swift` exists as a minimal pure-Swift sample for verifying SoundAnalysis behavior without Ruby.

## TDD discipline

t-wada style RED → GREEN → REFACTOR independent commits. test-unit. Fixture: `test/fixtures/sample.aiff` reused from `rb-speech-mac` (same `say -v Samantha` clip; classifier should label it `speech`).

## Related projects

- `~/dev/src/github.com/bash0C7/swift_gem` — scaffold/Mkmf framework
- `~/dev/src/github.com/bash0C7/rb-vision-ocrmac` — sibling reference implementation
- `~/dev/src/github.com/bash0C7/rb-speech-mac` — sibling, file-based audio gem (different framework, TCC-restricted)

## Environment requirements

macOS 12+, Apple Silicon, Swift 6.0+, Ruby 3.2+, bundler 4.x, rake-compiler 1.2+. `Gemfile` references swift_gem via `path: "../swift_gem"` until publish. `Gemfile.lock` not git-tracked.

## Prohibitions

- No Python source
- Do not git-track `Gemfile.lock`
- Do not bundle a custom CoreML model here — keep this gem on the built-in classifier. Custom models are a separate concern
- Do not add stream-based analysis (`SNAudioStreamAnalyzer`) here — file-based only
- Do not promise thread safety for concurrent calls
- Do not cache, normalize, or post-process classification results here
- Commit messages in English, conventional commits style
- `.claude/` is committed
