import Foundation
import SoundAnalysis

guard let input = CommandLine.arguments.dropFirst().first else {
    FileHandle.standardError.write(Data("usage: xcrun swift examples/sound_analysis_mac.swift <audio-path>\n".utf8))
    exit(1)
}

final class Printer: NSObject, SNResultsObserving {
    func request(_ request: any SNRequest, didProduce result: any SNResult) {
        guard let top = (result as? SNClassificationResult)?.classifications.first else { return }
        print("\(top.identifier)\t\(top.confidence)")
    }

    func request(_ request: any SNRequest, didFailWithError error: any Error) {
        FileHandle.standardError.write(Data("error: \(error)\n".utf8))
        exit(2)
    }
}

let printer = Printer()
do {
    let analyzer = try SNAudioFileAnalyzer(url: URL(filePath: input))
    try analyzer.add(SNClassifySoundRequest(classifierIdentifier: .version1), withObserver: printer)
    analyzer.analyze()
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(2)
}
