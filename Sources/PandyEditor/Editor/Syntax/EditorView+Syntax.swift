import Foundation
import UIKit
import FiveKit

//
//  EditorView+Syntax.swift
//  PandyEditor 🐼
//
//  Extension: Syntax Highlighting & Text Processing
//
//  This extension handles all text change events, version management,
//  and background syntax highlighting logic.
//

extension EditorView {
    
    // MARK: - Text Change Handling (Bulletproof)
    
    @objc internal func textDidChangeInternal() {
        // Prevent recursive loops if we change text storage internally
        guard isProcessingHighlight.negated else { return }
        guard let currentText = self.text else { return }
        
        // BULLETPROOF: Invalidate bracket cache immediately on text change
        lastBracketCursorPos = -1
        cachedBracketMatches.removeAll()
        
        // 1. Throttle (Lag Prevention)
        // Prevent syntax highlighting from running on every single keystroke of a fast typist
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastEditTime < minEditInterval { return }
        lastEditTime = now
        
        // 2. Increment Version (Invalidates previous in-flight background work)
        //
        // EXAMPLE: Fast typing scenario
        // ┌─────────────────────────────────────────────────────────────┐
        // │ User types: "func hello() {" very quickly                   │
        // ├─────────────────────────────────────────────────────────────┤
        // │ t=0ms:  "f" → version=1, background job A queued            │
        // │ t=50ms: "u" → version=2, job A still running                │
        // │ t=100ms: "n" → version=3, job A still running               │
        // │ t=200ms: job A completes → version check (1≠3) → DISCARDED  │
        // │ t=250ms: job C completes → version check (3=3) → APPLIED ✓  │
        // └─────────────────────────────────────────────────────────────┘
        //
        let editVersion = incrementTextVersion()
        
        // 3. Immediate UI updates
        updateCurrentLineHighlight()
        
        // 4. Update Line Numbers (Fast Track)
        // We do this separately from syntax highlighting because scanning for newlines
        // is much faster than regex parsing. This ensures line numbers don't lag.
        let capturedText = currentText
        textProcessingQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.currentTextVersion() == editVersion else { return }
            
            // Fast newline scan
            let nsText = capturedText as NSString
            let len = nsText.length
            var indices: [Int] = [0]
            for i in 0..<len {
                if nsText.character(at: i) == Self.newlineCodeUnit { indices.append(i + 1) }
            }
            
            DispatchQueue.main.async {
                guard self.currentTextVersion() == editVersion else { return }
                self.lineNumberView.updateLineCache(indices: indices, length: len, version: editVersion)
                self.lineNumberView.setNeedsDisplay()
            }
        }
        
        // 5. Background Syntax Highlighting (Viewport Optimized)
        highlightWorkItem?.cancel()
        
        // VIEWPORT OPTIMIZATION: Capture visible range on main thread
        // We calculate this BEFORE going to background since layoutManager must be accessed on main thread
        let capturedVisibleRange = calculateVisibleCharacterRange()
        
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard self.currentTextVersion() == editVersion else { return }
            
            // Heavy calculation (Regex Parsing) - now uses visible range for optimization
            let newAttributedText = self.highlighter.highlight(capturedText, visibleRange: capturedVisibleRange)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard self.currentTextVersion() == editVersion else { return }
                
                // BULLETPROOF CHECK: Length Mismatch
                // If text length changed while we were calculating, abort to prevent crash.
                if self.textStorage.length != newAttributedText.length { return }
                
                self.isProcessingHighlight = true
                self.isUpdatingText = true
                
                // Safe Storage Edit
                // We modify the storage directly to apply attributes without resetting cursor position
                self.textStorage.beginEditing()
                
                newAttributedText.enumerateAttributes(in: NSRange(location: 0, length: newAttributedText.length), options: []) { (attrs, range, _) in
                    if let fg = attrs[.foregroundColor] {
                        self.textStorage.addAttribute(.foregroundColor, value: fg, range: range)
                    }
                    if let font = attrs[.font] {
                        self.textStorage.addAttribute(.font, value: font, range: range)
                    }
                }
                
                self.textStorage.endEditing()
                
                self.isUpdatingText = false
                self.isProcessingHighlight = false
            }
        }
        
        highlightWorkItem = item
        textProcessingQueue.asyncAfter(deadline: .now() + highlightDelay, execute: item)
    }
}
