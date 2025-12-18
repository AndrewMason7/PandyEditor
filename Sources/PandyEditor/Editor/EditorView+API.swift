import Foundation
import UIKit
import FiveKit

//
//  EditorView+API.swift
//  PandyEditor 🐼
//
//  Extension: Public API & User Controls
//
//  Exposes the public interface for controlling the editor,
//  changing themes, text content, and font sizes.
//

extension EditorView {
    
    // MARK: - Public API (State Reset)
    
    /// Forces a re-run of the syntax highlighting engine.
    /// Useful when programmatically changing text or themes.
    public func forceSyntaxUpdate(immediate: Bool = true) {
        textDidChangeInternal(immediate: immediate)
    }
    
    /// Replaces the entire text content safely, handling all side effects asynchronously.
    public func setText(_ text: String, completion: (() -> Void)? = nil) {
        // 1. Snapshot State & increment version
        let version = incrementTextVersion()
        
        // Cancel pending work
        highlightWorkItem?.cancel()
        
        // BULLETPROOF: Invalidate caches immediately
        lastBracketCursorPos = -1
        cachedBracketMatches.removeAll()
        
        isUpdatingText = true
        isProcessingHighlight = true
        
        let savedSelection = self.selectedRange
        let savedOffset = self.contentOffset
        
        // 2. Background Processing (Lag Prevention)
        textProcessingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Perform heavy regex highlighting off-main-thread
            let attributed = self.highlighter.highlight(text)
            
            // 3. Main Thread Apply (Atomic Version Check)
            CrashGuard.onMainThread { [weak self] in
                guard let self = self else { return }
                
                // RACE CONDITION PROTECTION:
                // Only apply if the text hasn't changed since we started processing
                guard self.currentTextVersion() == version else { return }
                
                self.attributedText = attributed
                
                // Reset Line Numbers
                self.lineNumberView.updateLineCache(with: text, version: version)
                self.lineNumberView.setNeedsLayout() // Defer redraw
                
                // Restore State Safely
                if savedSelection.location + savedSelection.length <= text.utf16.count {
                    self.selectedRange = savedSelection
                }
                self.setContentOffset(savedOffset, animated: false)
                
                self.isUpdatingText = false
                self.isProcessingHighlight = false
                
                // BULLETPROOF: Final Redraw Verification
                self.lineNumberView.setNeedsDisplay()
                self.minimapView?.setNeedsDisplay()
                
                // Update Minimap (Lag Prevention)
                self.minimapView?.updateMinimap(with: text)
                
                completion?()
            }
        }
    }
    
    /// Updates the syntax highlighting language and associated toolbar keys.
    public func setLanguage(_ language: SupportedLanguage) {
        // Update state
        currentLanguage = language
        highlighter = SyntaxHighlighter(language: language.syntax, theme: highlighter.theme, fontSize: currentFontSize)
        font = highlighter.font
        keyboardToolbar?.update(language: language)
        
        // Re-highlight if we have text (Asynchronous)
        if let text = text {
            setText(text)
        }
    }
    
    public func setTheme(_ theme: CodeEditorTheme) {
        _ = incrementTextVersion()
        highlighter = SyntaxHighlighter(language: highlighter.language, theme: theme, fontSize: currentFontSize)
        font = highlighter.font
        
        performSafeUpdate {
            self.backgroundColor = theme.backgroundColor
            self.tintColor = theme.cursorColor
            self.currentLineHighlightView?.backgroundColor = theme.currentLineColor
            
            self.lineNumberView.theme = theme
            self.lineNumberView.setNeedsDisplay()
            
            self.minimapView?.theme = theme
            
            // INSTEAD OF setText(): High-performance re-highlight
            // Only re-runs the highlighting logic on the existing attributed string
            // to update colors, avoiding O(n) background regex parsing for theme-only changes.
            self.forceSyntaxUpdate()
        }
    }
    
    // MARK: - User Actions (Font Size)
    
    /// Updates the font size for the editor and all subcomponents.
    /// - Parameter newSize: Optional new font size. If nil, uses `currentFontSize`.
    public func updateFontSize(_ newSize: CGFloat? = nil) {
        // If a new size is provided, update currentFontSize (which triggers didSet calling this again)
        if let newSize = newSize, newSize != currentFontSize {
            currentFontSize = min(Self.maxFontSize, max(Self.minFontSize, newSize))
            return // didSet will call updateFontSize() again with nil
        }
        
        highlighter = SyntaxHighlighter(language: highlighter.language, theme: highlighter.theme, fontSize: currentFontSize)
        font = highlighter.font
        lineNumberView.updateFontSize(currentFontSize)
        
        if let text = text {
            setText(text)
        }
    }
    
    @objc internal func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            // Simple throttle for pinch
            let newSize = currentFontSize * gesture.scale
            if abs(newSize - currentFontSize) > 1.0 {
                currentFontSize = min(Self.maxFontSize, max(Self.minFontSize, newSize))
                gesture.scale = 1.0
            }
        }
    }
}
