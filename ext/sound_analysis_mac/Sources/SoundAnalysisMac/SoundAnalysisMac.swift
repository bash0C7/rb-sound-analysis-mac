import SoundAnalysis
import Foundation

private let timeoutSeconds: Int = 30

private final class ResultCollector: NSObject, SNResultsObserving {
    var lines: [String] = []
    var failed: Bool = false
    let semaphore: DispatchSemaphore

    init(semaphore: DispatchSemaphore) {
        self.semaphore = semaphore
        super.init()
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let cr = result as? SNClassificationResult,
              let top = cr.classifications.first else { return }
        lines.append("\(top.identifier)\t\(top.confidence)")
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        failed = true
        semaphore.signal()
    }

    func requestDidComplete(_ request: SNRequest) {
        semaphore.signal()
    }
}

func performClassify(path: String) -> String {
    if path.isEmpty { return "" }
    if !FileManager.default.fileExists(atPath: path) { return "" }

    let url = URL(fileURLWithPath: path)
    let semaphore = DispatchSemaphore(value: 0)
    let collector = ResultCollector(semaphore: semaphore)

    do {
        let analyzer = try SNAudioFileAnalyzer(url: url)
        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        try analyzer.add(request, withObserver: collector)
        analyzer.analyze()
        if semaphore.wait(timeout: .now() + .seconds(timeoutSeconds)) == .timedOut {
            return ""
        }
    } catch {
        return ""
    }

    if collector.failed { return "" }
    return collector.lines.joined(separator: "\n")
}
