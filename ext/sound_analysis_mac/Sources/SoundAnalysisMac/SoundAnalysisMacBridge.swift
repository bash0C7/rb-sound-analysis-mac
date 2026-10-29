import Foundation

/// Calls ``classify(path:)`` from C as `sound_analysis_mac_classify`.
///
/// The returned buffer is allocated with `strdup`. Release it with ``cFree(_:)``.
///
/// - Parameter path: A NUL-terminated UTF-8 file path.
/// - Returns: A newly allocated NUL-terminated UTF-8 string owned by the caller.
@c(sound_analysis_mac_classify)
public func cClassify(_ path: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar> {
    strdup(classify(path: String(cString: path)))!
}

/// Releases a buffer returned by ``cClassify(_:)``, exposed to C as `sound_analysis_mac_free`.
///
/// The caller owns every buffer ``cClassify(_:)`` returns and must pass it to this function exactly once.
///
/// - Parameter ptr: The buffer to release, or `nil`.
@c(sound_analysis_mac_free)
public func cFree(_ ptr: UnsafeMutablePointer<CChar>?) {
    free(ptr)
}
