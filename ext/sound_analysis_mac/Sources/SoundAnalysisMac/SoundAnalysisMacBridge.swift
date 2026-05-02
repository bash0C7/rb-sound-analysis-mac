import Foundation

@c
public func sound_analysis_mac_classify(_ path: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar> {
    let s = String(cString: path)
    return strdup(performClassify(path: s))!
}

@c
public func sound_analysis_mac_free(_ ptr: UnsafeMutablePointer<CChar>?) {
    free(ptr)
}
