import Foundation
import SoundAnalysis

/// Collects the top classification of each analysis window delivered by an analyzer.
private final class TopClassificationCollector: NSObject, SNResultsObserving {
    /// One `"label\tconfidence"` line per analysis window, in delivery order.
    var lines: [String] = []

    /// Whether the request ended with an error instead of completing.
    var failed = false

    func request(_ request: any SNRequest, didProduce result: any SNResult) {
        guard let top = (result as? SNClassificationResult)?.classifications.first else { return }
        lines.append("\(top.identifier)\t\(top.confidence)")
    }

    func request(_ request: any SNRequest, didFailWithError error: any Error) {
        failed = true
    }
}

/// Classifies the sounds in an audio file with the built-in `version1` sound classifier.
///
/// `SNAudioFileAnalyzer.analyze()` runs synchronously and delivers every observer callback on the
/// calling thread before it returns. ``cClassify(_:)`` exposes this function to C.
///
/// - Parameter path: The path of an audio file that `AVAudioFile` can open.
/// - Returns: One `"label\tconfidence"` line per analysis window joined by newlines, or an empty
///   string when the file cannot be opened as audio or the analysis fails.
func classify(path: String) -> String {
    let collector = TopClassificationCollector()
    do {
        let analyzer = try SNAudioFileAnalyzer(url: URL(filePath: path))
        try analyzer.add(SNClassifySoundRequest(classifierIdentifier: .version1), withObserver: collector)
        analyzer.analyze()
    } catch {
        return ""
    }
    return collector.failed ? "" : collector.lines.joined(separator: "\n")
}
