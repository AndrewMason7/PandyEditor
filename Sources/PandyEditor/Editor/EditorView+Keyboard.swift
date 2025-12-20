import Foundation
import UIKit
import SwiftUI
// import FiveKit

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
        performSafeUpdate {
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
        CrashGuard.onMainThread { [weak self] in
            self?.scrollToCursor(animated: true)
        }
        }
    }
    
    @objc internal func keyboardWillHide(notification: NSNotification) {
        performSafeUpdate {
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
    }
    
    // MARK: - Scroll to Cursor (FiveKit Compliance)
    
    /// Scrolls the text view to ensure the cursor is visible.
    /// Follows the Safety Quadruple pattern and uses View Diffing.
    internal func scrollToCursor(animated: Bool = false, padding: CGFloat = 40) {
        performSafeUpdate {
            // SAFETY GUARD 3: Layout Validity
            guard self.bounds.width > 0, self.bounds.height > 0 else { return }
            
            // Get cursor position
            guard let selectedRange = self.selectedTextRange else { return }
            let cursorRect = self.caretRect(for: selectedRange.end)
            
            // Validate cursor rect (sanity check)
            guard cursorRect.origin.y.isFinite, cursorRect.height > 0 else { return }
            
            // VIEW DIFFING: Check if scroll is actually needed
            // Calculate visible rect accounting for keyboard inset
            let visibleRect = CGRect(
                x: self.contentOffset.x,
                y: self.contentOffset.y,
                width: self.bounds.width,
                height: self.bounds.height - self.contentInset.bottom
            )
            
            // Add padding around cursor for comfortable visibility
            let targetRect = cursorRect.insetBy(dx: 0, dy: -padding)
            
            // Only scroll if cursor is outside visible area
            if visibleRect.contains(targetRect).negated {
                self.scrollRectToVisible(targetRect, animated: animated)
            }
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
    func showFind() {
        // SAFETY GUARD 1: Thread Safety
        guard Thread.isMainThread else {
            CrashGuard.onMainThread { [weak self] in self?.showFind() }
            return
        }
        
        // SAFETY GUARD 2: Window Check
        guard window != nil else { return }
        
        // Premium Haptic Feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        if #available(iOS 16.0, *) {
            // Check if interaction exists (should be true via setup)
            if let interaction = findInteraction {
                // If the user has a word selected, the native interaction 
                // will automatically populate the search field.
                interaction.presentFindPanel()
            }
        } else {
            // Legacy fallback if needed in future development
            print("⚠️ [Safety] Find Interaction requires iOS 16.0+")
        }
    }
    func showCommandPalette() {
        // SAFETY: Thread
        guard Thread.isMainThread else {
            CrashGuard.onMainThread { [weak self] in self?.showCommandPalette() }
            return
        }
        
        // Premium Feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // 1. Sync state to bridge before showing
        editorState.showLineNumbers = showLineNumbers
        editorState.showMinimap = showMinimap
        editorState.wordWrapEnabled = wordWrapEnabled
        editorState.showBracketMatching = showBracketMatching
        editorState.theme = theme
        editorState.language = currentLanguage
        
        // 2. Present Controller
        let palette = CommandPaletteView(state: editorState)
        let hosting = UIHostingController(rootView: palette)
        
        if let controller = CrashGuard.topViewController() {
            controller.present(hosting, animated: true)
        }
    }
    func toolbarDidTapKey(_ key: String) { insertText(key) }
    func toolbarDidTapUndo() { undoAction() }
    func toolbarDidTapRedo() { redoAction() }
    func toolbarDidTapFind() { showFind() }
    func toolbarDidTapDismiss() { dismissKeyboard() }
    func toolbarDidTapMenu() { showCommandPalette() }
    
    func toolbarDidGlideCursor(offset: Int) {
        performSafeUpdate {
            // Precise Cursor Glide Logic
            guard let start = self.selectedTextRange?.start else { return }
            if let newPos = self.position(from: start, offset: offset) {
                self.selectedTextRange = self.textRange(from: newPos, to: newPos)
                // Ensure cursor remains visible during glide
                self.scrollToCursor(animated: false)
            }
        }
    }
    
    // MARK: - Undo/Redo Management (Bulletproof)
    
    internal func setupUndoObservers() {
        // Observe undo manager state changes
        NotificationCenter.default.addObserver(self, selector: #selector(updateToolbarUndoState), name: .NSUndoManagerDidUndoChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateToolbarUndoState), name: .NSUndoManagerDidRedoChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateToolbarUndoState), name: .NSUndoManagerCheckpoint, object: nil)
        
        // Initial update
        updateToolbarUndoState()
    }
    
    @objc internal func updateToolbarUndoState() {
        // SAFETY GUARD 1: Thread Safety
        guard Thread.isMainThread else {
            CrashGuard.onMainThread { [weak self] in self?.updateToolbarUndoState() }
            return
        }
        
        // SAFETY GUARD 2: Window Check (Lag Prevention)
        guard window != nil else { return }
        
        // Logic: Sync undo manager state to toolbar
        let canUndo = undoManager?.canUndo ?? false
        let canRedo = undoManager?.canRedo ?? false
        
        keyboardToolbar?.setUndoState(canUndo: canUndo, canRedo: canRedo)
    }
}
