import Foundation
import UIKit
import FiveKit

//
//  EditorView+Keyboard.swift
//  PandyEditor 🐼
//
//  Extension: Keyboard Handling & Toolbar Delegation
//
//  This extension manages keyboard notifications (show/hide) and implements
//  the KeyboardToolbarDelegate for quick key input and editor actions.
//

// MARK: - Keyboard Toolbar Delegate
extension EditorView: KeyboardToolbarDelegate {
    
    // MARK: - Keyboard Notifications (Safety Quadruple)
    
    @objc internal func keyboardWillShow(notification: NSNotification) {
        // SAFETY GUARD 1: Window Check (Lag Prevention)
        // If view is off-screen, adjusting insets wastes CPU cycles
        guard window != nil else { return }
        
        // SAFETY GUARD 2: Thread Safety
        // Strictly forbids UI updates on background threads
        if Thread.isMainThread.negated {
            DispatchQueue.main.async { [weak self] in
                self?.keyboardWillShow(notification: notification)
            }
            return
        }
        
        // Extract keyboard frame from notification
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        // Calculate the bottom inset adjustment
        // We subtract safe area bottom because modern iPhones already account for it
        let adjustment = keyboardFrame.height - (window?.safeAreaInsets.bottom ?? 0) + 20
        
        // VIEW DIFFING: Only update if value actually changed (Lag Prevention)
        // On 120Hz devices, avoiding redundant layout passes is critical
        guard abs(contentInset.bottom - adjustment) > 0.5 else { return }
        
        var newContentInset = contentInset
        var newScrollIndicatorInset = verticalScrollIndicatorInsets
        
        newContentInset.bottom = adjustment
        newScrollIndicatorInset.bottom = adjustment
        
        contentInset = newContentInset
        verticalScrollIndicatorInsets = newScrollIndicatorInset
        
        // DEFERRED: Scroll to cursor after layout settles
        // We dispatch async to allow UIKit to complete the inset animation
        DispatchQueue.main.async { [weak self] in
            self?.scrollToCursor(animated: true)
        }
    }
    
    @objc internal func keyboardWillHide(notification: NSNotification) {
        // SAFETY GUARD 1: Window Check
        guard window != nil else { return }
        
        // SAFETY GUARD 2: Thread Safety
        if Thread.isMainThread.negated {
            DispatchQueue.main.async { [weak self] in
                self?.keyboardWillHide(notification: notification)
            }
            return
        }
        
        let originalBottomInset: CGFloat = 12
        
        // VIEW DIFFING: Only reset if actually changed
        guard abs(contentInset.bottom - originalBottomInset) > 0.5 else { return }
        
        var newContentInset = contentInset
        var newScrollIndicatorInset = verticalScrollIndicatorInsets
        
        newContentInset.bottom = originalBottomInset
        newScrollIndicatorInset.bottom = originalBottomInset
        
        contentInset = newContentInset
        verticalScrollIndicatorInsets = newScrollIndicatorInset
    }
    
    // MARK: - Scroll to Cursor (FiveKit Compliance)
    
    /// Scrolls the text view to ensure the cursor is visible.
    /// Follows the Safety Quadruple pattern and uses View Diffing.
    internal func scrollToCursor(animated: Bool = false, padding: CGFloat = 40) {
        // SAFETY GUARD 1: Window Check (Lag Prevention)
        guard window != nil else { return }
        
        // SAFETY GUARD 2: Thread Safety
        if Thread.isMainThread.negated {
            DispatchQueue.main.async { [weak self] in
                self?.scrollToCursor(animated: animated, padding: padding)
            }
            return
        }
        
        // SAFETY GUARD 3: Layout Validity
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // Get cursor position
        guard let selectedRange = selectedTextRange else { return }
        let cursorRect = caretRect(for: selectedRange.end)
        
        // Validate cursor rect (sanity check)
        guard cursorRect.origin.y.isFinite, cursorRect.height > 0 else { return }
        
        // VIEW DIFFING: Check if scroll is actually needed
        // Calculate visible rect accounting for keyboard inset
        let visibleRect = CGRect(
            x: contentOffset.x,
            y: contentOffset.y,
            width: bounds.width,
            height: bounds.height - contentInset.bottom
        )
        
        // Add padding around cursor for comfortable visibility
        let targetRect = cursorRect.insetBy(dx: 0, dy: -padding)
        
        // Only scroll if cursor is outside visible area
        if visibleRect.contains(targetRect).negated {
            scrollRectToVisible(targetRect, animated: animated)
        }
    }
    
    // MARK: - Text Input Override
    
    public override func insertText(_ text: String) {
        // Insert at cursor
        guard let range = selectedTextRange else { return }
        replace(range, withText: text)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Ensure cursor remains visible after insertion
        scrollToCursor(animated: false)
    }
    
    // MARK: - Toolbar Delegate Methods
    
    func undoAction() {
        // Main thread guard
        guard Thread.isMainThread else { return }
        undoManager?.undo()
    }
    
    func redoAction() {
        guard Thread.isMainThread else { return }
        undoManager?.redo()
    }
    
    func dismissKeyboard() {
        resignFirstResponder()
    }
    
    // Stub implementations for other delegate methods
    func insertTab() { insertText("    ") }
    func showFind() {}
    func showCommandPalette() {}
    func toolbarDidTapKey(_ key: String) { insertText(key) }
    func toolbarDidTapUndo() { undoAction() }
    func toolbarDidTapRedo() { redoAction() }
    func toolbarDidTapFind() { showFind() }
    func toolbarDidTapDismiss() { dismissKeyboard() }
    func toolbarDidTapMenu() { showCommandPalette() }
    
    func toolbarDidGlideCursor(offset: Int) {
        // Precise Cursor Glide Logic
        guard let start = selectedTextRange?.start else { return }
        if let newPos = position(from: start, offset: offset) {
            selectedTextRange = textRange(from: newPos, to: newPos)
            // Ensure cursor remains visible during glide
            scrollToCursor(animated: false)
        }
    }
}
