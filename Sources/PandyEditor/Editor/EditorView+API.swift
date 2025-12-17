import Foundation
import UIKit

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
    public func forceSyntaxUpdate() {
        textDidChangeInternal()
    }
    
    /// Replaces the entire text content safely, handling all side effects.
    public func setText(_ text: String) {
        // Cancel everything
        highlightWorkItem?.cancel()
        _ = incrementTextVersion()
        
        // BULLETPROOF: Invalidate caches
        lastBracketCursorPos = -1
        cachedBracketMatches.removeAll()
        
        isUpdatingText = true
        isProcessingHighlight = true
        
        let savedSelection = self.selectedRange
        let savedOffset = self.contentOffset
        
        // Apply immediate highlight (Blocking, but necessary for full reload)
        self.attributedText = highlighter.highlight(text)
        
        // Reset Line Numbers
        lineNumberView.updateLineCache(with: text, version: currentTextVersion())
        lineNumberView.setNeedsDisplay()
        
        // Restore State
        if savedSelection.location + savedSelection.length <= text.count {
            self.selectedRange = savedSelection
        }
        self.setContentOffset(savedOffset, animated: false)
        
        isUpdatingText = false
        isProcessingHighlight = false
    }
    
    /// Updates the syntax highlighting language and associated toolbar keys.
    public func setLanguage(_ language: SupportedLanguage) {
        // Update state
        currentLanguage = language
        highlighter = SyntaxHighlighter(language: language.syntax, theme: highlighter.theme, fontSize: currentFontSize)
        keyboardToolbar?.update(language: language)
        
        // Re-highlight if we have text
        if let text = text {
            setText(text)
        }
    }
    
    public func setTheme(_ theme: CodeEditorTheme) {
        _ = incrementTextVersion()
        highlighter = SyntaxHighlighter(language: highlighter.language, theme: theme, fontSize: currentFontSize)
        
        // UI Updates
        backgroundColor = theme.backgroundColor
        tintColor = theme.cursorColor
        currentLineHighlightView?.backgroundColor = theme.currentLineColor
        
        lineNumberView.theme = theme
        lineNumberView.setNeedsDisplay()
        
        minimapView?.theme = theme
        
        // Re-highlight existing text with new theme colors
        if let text = text {
            setText(text) // Re-uses safe logic
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
