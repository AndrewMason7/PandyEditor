//
//  CrashGuard.swift
//  PandyEditor 🐼
//
//  Comprehensive crash prevention utilities implementing the "Safety Quadruple" pattern.
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
    
    // MARK: - Safe String Access
    
    /// Safely access a character at index in a string.
    /// Prevents index out of bounds crashes for string operations.
    ///
    /// EXAMPLE: Safe vs Unsafe string character access
    /// ```
    /// let text = "Hello"
    ///
    /// // UNSAFE (will crash):
    /// let char = text[text.index(text.startIndex, offsetBy: 10)]  // 💥 Fatal error
    ///
    /// // SAFE (returns nil):
    /// let char = CrashGuard.safeCharacter(text, 10)  // ✓ Returns nil
    /// ```
    static func safeCharacter(_ string: String, _ index: Int) -> Character? {
        guard index >= 0 && index < string.count else { return nil }
        return string[string.index(string.startIndex, offsetBy: index)]
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
    // MARK: - Presentation Safety
    
    /// Recursively finds the top-most visible view controller for reliable presentation.
    /// Handles NavigationControllers, TabBarControllers, and nested Modals.
    static func topViewController(_ base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}
