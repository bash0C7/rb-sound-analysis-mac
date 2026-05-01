import SoundAnalysis
import Foundation

// Run with: swift examples/sound_analysis_mac.swift <audio-path>

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write("usage: swift examples/sound_analysis_mac.swift <audio-path>\n".data(using: .utf8)!)
    exit(1)
}

let path = CommandLine.arguments[1]
let url = URL(fileURLWithPath: path)

final class Collector: NSObject, SNResultsObserving {
    let semaphore: DispatchSemaphore
    init(_ s: DispatchSemaphore) { self.semaphore = s }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let cr = result as? SNClassificationResult,
              let top = cr.classifications.first else { return }
        print("\(top.identifier)\t\(top.confidence)")
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        FileHandle.standardError.write("error: \(error)\n".data(using: .utf8)!)
        semaphore.signal()
    }

    func requestDidComplete(_ request: SNRequest) {
        semaphore.signal()
    }
}

let semaphore = DispatchSemaphore(value: 0)
let collector = Collector(semaphore)

do {
    let analyzer = try SNAudioFileAnalyzer(url: url)
    let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
    try analyzer.add(request, withObserver: collector)
    analyzer.analyze()
    _ = semaphore.wait(timeout: .now() + .seconds(30))
} catch {
    FileHandle.standardError.write("setup error: \(error)\n".data(using: .utf8)!)
    exit(2)
}
