//
//  CrashPrevention.swift
//  PandyEditor 🐼
//
//  Comprehensive crash prevention utilities implementing the "Safety Quadruple" pattern.
//  Provides safe wrappers for operations that could crash: arrays, files, strings, URLs.
//
//  KEY UTILITIES:
//  - CrashGuard: Thread safety, safe execution with fallbacks, range validation
//  - FileManager+Safe: Non-throwing file operations (safeFileExists, safeRemoveItem)
//  - String+Safe: Bounds-checked subscripting, safe regex matching
//  - Array+Safe: array[safe: index] returns nil instead of crashing
//  - Validator: Input validation for paths, filenames, and ranges
//
//  USAGE EXAMPLE:
//  ```
//  // Instead of: array[index] which can crash
//  let value = array[safe: index] ?? defaultValue
//  
//  // Instead of: try fileManager.removeItem() which can throw
//  let success = fileManager.safeRemoveItem(at: url)
//  ```
//


import Foundation
import UIKit
import FiveKit

// MARK: - Crash Prevention Helper
/// Comprehensive crash prevention utilities following strict safety standards.
enum CrashGuard {
    
    // MARK: - Thread Safety
    
    /// Ensures block runs on main thread. Executes immediately if already on main.
    /// Prevents background thread UI crashes.
    static func onMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
    
    /// Asserts execution is on main thread (for debug builds).
    static func assertMainThread(file: String = #file, line: Int = #line) {
        #if DEBUG
        guard Thread.isMainThread else {
            print("⚠️ [Safety] Thread Violation at \(file):\(line) - Expected Main Thread")
            return
        }
        #endif
    }
    
    // MARK: - Safe Execution
    
    /// Safely execute a block that might crash, with fallback.
    /// Uses expressive error handling for readability.
    static func safely<T>(_ block: () throws -> T, fallback: T, file: String = #file, line: Int = #line) -> T {
        do {
            return try block()
        } catch {
            print("⚠️ [Safety] Crash prevented at \(file):\(line) - \(error.localizedDescription)")
            return fallback
        }
    }
    
    /// Safely execute void operations.
    static func safelyExecute(_ block: () throws -> Void, file: String = #file, line: Int = #line) {
        do {
            try block()
        } catch {
            print("⚠️ [Safety] Crash prevented at \(file):\(line) - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Safe Array Access
    
    /// Safely access array with bounds checking.
    /// Prevents index out of bounds crashes.
    ///
    /// EXAMPLE: Safe vs Unsafe array access
    /// ```
    /// let items = ["a", "b", "c"]
    ///
    /// // UNSAFE (will crash):
    /// let value = items[5]  // 💥 Fatal error: Index out of range
    ///
    /// // SAFE (returns nil):
    /// let value = CrashGuard.safeIndex(items, 5)  // ✓ Returns nil
    /// ```
    static func safeIndex<T>(_ array: [T], _ index: Int) -> T? {
        guard index >= 0 && index < array.count else { return nil }
        return array[index]
    }
    
    // MARK: - Safe Optional Unwrapping
    
    /// Safely unwrap optional with logging.
    static func safeUnwrap<T>(_ optional: T?, message: String = "Unexpected nil", file: String = #file, line: Int = #line) -> T? {
        guard let value = optional else {
            print("⚠️ [Safety] Nil value at \(file):\(line) - \(message)")
            return nil
        }
        return value
    }
    
    // MARK: - Range Validation
    
    /// Validate range is within bounds.
    /// Essential for safe string/text operations.
    static func validateRange(_ range: NSRange, in text: String) -> NSRange? {
        guard range.location != NSNotFound,
              range.location >= 0,
              range.location + range.length <= text.utf16.count else {
            return nil
        }
        return range
    }
    
    /// Safe string operations with range checking.
    static func safeSubstring(from text: String, range: NSRange) -> String? {
        guard let validRange = validateRange(range, in: text),
              let swiftRange = Range(validRange, in: text) else {
            return nil
        }
        return String(text[swiftRange])
    }
}

// MARK: - Safe FileManager Operations
/// Safe file system operations with crash prevention.
extension FileManager {
    
    /// Safely check if file exists.
    func safeFileExists(atPath path: String) -> Bool {
        return CrashGuard.safely({ fileExists(atPath: path) }, fallback: false)
    }
    
    /// Safely get file size.
    func safeFileSize(at url: URL) -> Int64 {
        return CrashGuard.safely({
            let attrs = try attributesOfItem(atPath: url.path)
            return attrs[.size] as? Int64 ?? 0
        }, fallback: 0)
    }
    
    /// Safely create directory.
    func safeCreateDirectory(at url: URL) -> Bool {
        return CrashGuard.safely({
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return true
        }, fallback: false)
    }
    
    /// Safely copy file.
    func safeCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        return CrashGuard.safely({
            try copyItem(at: srcURL, to: dstURL)
            return true
        }, fallback: false)
    }
    
    /// Safely move file.
    func safeMoveItem(at srcURL: URL, to dstURL: URL) -> Bool {
        return CrashGuard.safely({
            try moveItem(at: srcURL, to: dstURL)
            return true
        }, fallback: false)
    }
    
    /// Safely delete file.
    func safeRemoveItem(at url: URL) -> Bool {
        return CrashGuard.safely({
            try removeItem(at: url)
            return true
        }, fallback: false)
    }
    
    /// Safely list directory contents.
    func safeContentsOfDirectory(at url: URL) -> [URL] {
        return CrashGuard.safely({
            try contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        }, fallback: [])
    }
}

// MARK: - Safe String Operations
/// Safe string operations using FoundationPlus patterns.
extension String {
    
    /// Safe subscript access.
    /// This complements FoundationPlus integer subscripting with safety.
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
    
    /// Safe range substring.
    func safeSubstring(with nsRange: NSRange) -> String? {
        return CrashGuard.safeSubstring(from: self, range: nsRange)
    }
    
    /// Safe regex matching.
    func safeMatches(pattern: String) -> [NSTextCheckingResult] {
        return CrashGuard.safely({
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
        }, fallback: [])
    }
}

// MARK: - Safe Array Operations
/// Safe array operations with bounds checking.
extension Array {
    
    /// Safe subscript access.
    subscript(safe index: Int) -> Element? {
        return CrashGuard.safeIndex(self, index)
    }
    
    /// Safe first n elements.
    func safePrefix(_ n: Int) -> [Element] {
        guard n > 0 else { return [] }
        let count = self.count
        return Array(prefix(n < count ? n : count))
    }
}

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
