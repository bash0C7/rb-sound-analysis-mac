import Foundation

@_cdecl("sound_analysis_mac_classify")
public func sound_analysis_mac_classify(_ path: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar> {
    let s = String(cString: path)
    return strdup(performClassify(path: s))!
}

@_cdecl("sound_analysis_mac_free")
public func sound_analysis_mac_free(_ ptr: UnsafeMutablePointer<CChar>?) {
    free(ptr)
}
