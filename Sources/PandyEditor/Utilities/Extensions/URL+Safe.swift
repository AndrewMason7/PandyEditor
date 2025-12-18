import Foundation
import FiveKit

// MARK: - Safe URL Operations
/// Safe URL operations.
extension URL {
    
    /// Safe resource values.
    func safeResourceValues(forKeys keys: Set<URLResourceKey>) -> URLResourceValues? {
        return CrashGuard.safely({ try resourceValues(forKeys: keys) }, fallback: nil)
    }
    
    /// Safe path component.
    var safeLastPathComponent: String {
        return CrashGuard.safely({ lastPathComponent }, fallback: "Unknown")
    }
    
    /// Safe path extension.
    var safePathExtension: String {
        return CrashGuard.safely({ pathExtension }, fallback: String.empty)
    }
}
