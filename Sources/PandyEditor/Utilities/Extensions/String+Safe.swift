import Foundation
import FiveKit

// MARK: - Safe String Operations
/// Extensions for safe string manipulation via CrashGuard.
extension String {
    
    /// Safely access character at integer index.
    ///
    /// EXAMPLE:
    /// ```
    /// let text = "Hello"
    /// let char = text[safe: 10] // Returns nil instead of crashing
    /// ```
    public subscript(safe index: Int) -> Character? {
        return CrashGuard.safeCharacter(self, index)
    }
    
    /// Returns the character at the specified index or nil if out of bounds.
    /// Unified with CrashGuard logic.
    public func safeCharacter(at index: Int) -> Character? {
        return CrashGuard.safeCharacter(self, index)
    }
}
