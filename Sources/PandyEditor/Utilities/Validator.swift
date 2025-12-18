import Foundation
import FiveKit

// MARK: - Validation Helpers
/// Input validation utilities.
enum Validator {
    
    /// Validate file path.
    static func isValidPath(_ path: String) -> Bool {
        guard path.isEmpty.negated else { return false }
        // Check for dangerous paths
        let forbidden = ["../", "~/", "/System", "/private", "/usr", "/bin"]
        return forbidden.contains(where: { path.contains($0) }).negated
    }
    
    /// Validate file name.
    static func isValidFileName(_ name: String) -> Bool {
        guard name.isEmpty.negated && name.count <= 255 else { return false }
        let forbidden = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return name.rangeOfCharacter(from: forbidden) == nil
    }
    
    /// Validate text range.
    static func isValidRange(_ range: NSRange, in text: String) -> Bool {
        return range.location != NSNotFound &&
               range.location >= 0 &&
               range.location + range.length <= text.utf16.count
    }
}
