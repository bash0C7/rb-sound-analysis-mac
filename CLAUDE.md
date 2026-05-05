# CLAUDE.md — rb-sound-analysis-mac

## Position

Ruby native binding for Apple's Sound Analysis framework on macOS. Sibling of `rb-vision-ocrmac`, built on the same `bash0C7/swift_gem` scaffold. Exposes file-based sound classification using Apple's built-in `MLSoundIdentifierVersion1` classifier (300+ environmental sounds: speech, music, applause, laughter, etc.).

## Core design principles

1. Thin wrapper. Pass-through Sound Analysis API. One audio file → one classification string (newline-separated `label\tconfidence` pairs, one per analysis time window).
2. Fixed defaults: built-in `.version1` classifier, `SNAudioFileAnalyzer` (sync), top-1 classification per window. Custom CoreML models, multi-classification, and stream analysis are intentionally not added until needed.
3. SoundAnalysis-side failure (unreadable audio content, classifier unavailable, OS error, 30s timeout) → empty string, no exception. Missing path → `Errno::ENOENT` (the C wrapper `stat()`s the path before handoff so callers can tell bad input from a genuine empty result).
4. C bridge string handoff. Single `@c` (SE-0495) pair plus shared `sound_analysis_mac_free`. Bridge function signatures fixed at `UnsafePointer<CChar>` ↔ `UnsafeMutablePointer<CChar>`.
5. Scaffold parity. `swift_gem new rb-sound-analysis-mac` produces a skeleton whose only diffs against this repo are the implementation body, fixtures, and build artifacts.

## Public API

| Method | Returns | Notes |
|---|---|---|
| `SoundAnalysisMac.classify(path)` | newline-separated `"label\tconfidence"` pairs (top-1 per analysis window) | `SNAudioFileAnalyzer` + `SNClassifySoundRequest(classifierIdentifier: .version1)`. Empty string on SoundAnalysis-side failure; `Errno::ENOENT` on missing path |

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
ext/sound_analysis_mac/Sources/SoundAnalysisMac/SoundAnalysisMacBridge.swift   ← @c (SE-0495)
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
| `SoundAnalysisMacBridge.swift` | C ABI export via `@c` (SE-0495) |
| `SoundAnalysisMac.swift` | Real implementation: `SNAudioFileAnalyzer.analyze()` (synchronous) + an `SNResultsObserving` collector |
| `ext/sound_analysis_mac/extconf.rb` | `SwiftGem::Mkmf.create_swift_makefile("sound_analysis_mac/sound_analysis_mac", package: "SoundAnalysisMac", source_dir: __dir__)` |
| `examples/sound_analysis_mac.swift` | Pure-Swift sample script: `xcrun swift examples/sound_analysis_mac.swift <path>`. Must use `xcrun swift` (Xcode toolchain) — swiftly 6.3's interpret mode cannot JIT-link Apple system frameworks |
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

macOS 12+, Apple Silicon, Swift 6.3+ (SE-0495 `@c` requires 6.3; install via [swiftly](https://www.swift.org/install/macos/)), Ruby 3.2+, bundler 4.x, rake-compiler 1.2+. `Gemfile` references swift_gem via `path: "../swift_gem"` until publish. `Gemfile.lock` not git-tracked.

Xcode Command Line Tools required only for running `examples/sound_analysis_mac.swift` via `xcrun swift` — swiftly's 6.3 swift binary has broken Apple-framework JIT linkage in interpret mode (verified: SDKROOT, -F, -Xlinker, -sdk all fail). The library build itself does not need CLT. example does not use SE-0495 `@c`, so CLT's older swift (6.2.4) suffices. Install with `xcode-select --install`.

## Prohibitions

- No Python source
- Do not git-track `Gemfile.lock`
- Do not bundle a custom CoreML model here — keep this gem on the built-in classifier. Custom models are a separate concern
- Do not add stream-based analysis (`SNAudioStreamAnalyzer`) here — file-based only
- Do not promise thread safety for concurrent calls
- Do not cache, normalize, or post-process classification results here
- Commit messages in English, conventional commits style
- `.claude/` is committed
