import Foundation
import FiveKit

// MARK: - Safe Data Operations
/// Safe data operations.
extension Data {
    
    /// Safe string conversion.
    func safeString(encoding: String.Encoding = .utf8) -> String? {
        return CrashGuard.safely({ String(data: self, encoding: encoding) }, fallback: nil)
    }
    
    /// Safe write to file.
    func safeWrite(to url: URL) -> Bool {
        return CrashGuard.safely({
            try write(to: url, options: .atomic)
            return true
        }, fallback: false)
    }
}
