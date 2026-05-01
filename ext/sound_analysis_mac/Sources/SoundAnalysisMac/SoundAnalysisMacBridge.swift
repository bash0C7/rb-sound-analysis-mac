import Foundation

@_cdecl("sound_analysis_mac_perform")
public func sound_analysis_mac_perform(_ input: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar> {
    let s = String(cString: input)
    let result = sound_analysis_mac_perform(s)
    return strdup(result)!
}

@_cdecl("sound_analysis_mac_free")
public func sound_analysis_mac_free(_ ptr: UnsafeMutablePointer<CChar>?) {
    free(ptr)
}
