import Foundation

// TODO: Implement a self-contained Swift CLI for rb-sound-analysis-mac.
//
// Run with: swift examples/sound_analysis_mac.swift <input>

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write("usage: swift examples/sound_analysis_mac.swift <input>\n".data(using: .utf8)!)
    exit(1)
}

let input = CommandLine.arguments[1]
print(input)
