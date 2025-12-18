import Foundation
import FiveKit

// MARK: - Safe Array Operations
/// Extensions for safe array access and manipulation.
extension Array {
    
    /// Safely access element at index.
    ///
    /// EXAMPLE:
    /// ```
    /// let items = ["a", "b", "c"]
    /// let val = items[safe: 5] // Returns nil instead of crashing
    /// ```
    public subscript(safe index: Int) -> Element? {
        return CrashGuard.safeIndex(self, index)
    }
    
    /// Safely gets a prefix of the array.
    /// Handles negative numbers and out of bounds counts gracefully.
    public func safePrefix(_ count: Int) -> [Element] {
        guard count > 0 else { return [] }
        return Array(self.prefix(count))
    }
}
