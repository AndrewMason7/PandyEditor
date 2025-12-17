import Foundation
import UIKit
import FiveKit

//
//  EditorView+Bracket.swift
//  PandyEditor 🐼
//
//  Extension: Bracket Matching
//
//  This extension handles bracket pair highlighting with intelligent caching
//  to avoid O(n) string scans on every cursor movement.
//

extension EditorView {
    
    // MARK: - Feature: Bracket Matching
    
    func updateBracketMatching() {
        // SAFETY QUADRUPLE
        guard showBracketMatching else { return }
        guard window != nil else { return }
        if Thread.isMainThread.negated {
             DispatchQueue.main.async { [weak self] in self?.updateBracketMatching() }
             return
        }
        guard let textContent = text, textContent.isEmpty.negated else { return }
        
        // Logic
        let cursorPos = selectedRange.location
        let textLength = textContent.count
        
        // Cleanup if invalid
        guard cursorPos > 0, cursorPos <= textLength else {
            if bracketHighlightViews.isEmpty.negated {
                bracketHighlightViews.forEach { $0.removeFromSuperview() }
                bracketHighlightViews.removeAll()
            }
            return
        }
        
        var targetRects: [CGRect] = []
        
        // LAG PREVENTION: Smart Cache
        // Check cache first to avoid redundant O(n) string scanning.
        //
        // EXAMPLE: Cursor movement within same bracket context
        // ┌──────────────────────────────────────────────────────────┐
        // │ Code: func hello() { print("Hi") }                        │
        // │       Cursor at position 19 (after "{")                   │
        // ├──────────────────────────────────────────────────────────┤
        // │ First call:  cursorPos=19, lastPos=-1 → SCAN (slow path) │
        // │              Finds match: "{" at 13 ↔ "}" at 33          │
        // │              Cache: [(13, 33)], lastPos=19               │
        // ├──────────────────────────────────────────────────────────┤
        // │ Arrow key →: cursorPos=20, lastPos=19 → different        │
        // │              Scan again (cursor left bracket context)    │
        // ├──────────────────────────────────────────────────────────┤
        // │ Arrow key ←: cursorPos=19, lastPos=19 → SAME! (fast path)│
        // │              Skip scan, reuse cache ✓                    │
        // └──────────────────────────────────────────────────────────┘
        //
        if cursorPos == lastBracketCursorPos {
            // Fast path: Use cached match result
            for match in cachedBracketMatches {
                if let r1 = getGlyphRect(at: match.position) { targetRects.append(r1) }
                if let r2 = getGlyphRect(at: match.matchPosition) { targetRects.append(r2) }
            }
        } else {
            // Slow path: Compute and cache
            cachedBracketMatches.removeAll()
            lastBracketCursorPos = cursorPos
            
            // Safe character access with bounds validation
            let accessIndex = cursorPos - 1
            guard accessIndex >= 0, accessIndex < textLength else { return }
            let charBefore = textContent[accessIndex]
            
            // Find matches
            for pair in bracketPairs {
                if charBefore == pair.close {
                    if let matchPos = findMatchingBracket(from: accessIndex, isOpen: false, pair: pair, in: textContent) {
                        cachedBracketMatches.append((position: accessIndex, matchPosition: matchPos))
                        if let r1 = getGlyphRect(at: accessIndex) { targetRects.append(r1) }
                        if let r2 = getGlyphRect(at: matchPos) { targetRects.append(r2) }
                    }
                    break
                } else if charBefore == pair.open {
                    if let matchPos = findMatchingBracket(from: accessIndex, isOpen: true, pair: pair, in: textContent) {
                        cachedBracketMatches.append((position: accessIndex, matchPosition: matchPos))
                        if let r1 = getGlyphRect(at: accessIndex) { targetRects.append(r1) }
                        if let r2 = getGlyphRect(at: matchPos) { targetRects.append(r2) }
                    }
                    break
                }
            }
        }
        
        // VIEW DIFFING (Smart Recycling)
        
        // 1. Remove excess views
        while bracketHighlightViews.count > targetRects.count {
            bracketHighlightViews.last?.removeFromSuperview()
            bracketHighlightViews.removeLast()
        }
        
        // 2. Add missing views
        while bracketHighlightViews.count < targetRects.count {
            let v = UIView()
            v.backgroundColor = highlighter.theme.bracketMatchColor
            v.layer.cornerRadius = 3
            v.isUserInteractionEnabled = false
            insertSubview(v, at: 1) // Layer 1 (above line highlight, below text)
            bracketHighlightViews.append(v)
        }
        
        // 3. Diff Updates
        for (index, rect) in targetRects.enumerated() {
            let view = bracketHighlightViews[index]
            let currentFrame = view.frame
            
            // Only update if frame changed significantly (> 0.1pt)
            if abs(currentFrame.origin.x - rect.origin.x) > 0.1 ||
               abs(currentFrame.origin.y - rect.origin.y) > 0.1 ||
               abs(currentFrame.width - rect.width) > 0.1 {
                
                UIView.performWithoutAnimation {
                    view.frame = rect.insetBy(dx: -2, dy: -1)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Helper: Find Matching Bracket (Recursive/Stack Logic)
    private func findMatchingBracket(from position: Int, isOpen: Bool, pair: (open: Character, close: Character), in text: String) -> Int? {
        var depth = 1
        var pos = position
        let length = text.count
        
        if isOpen {
            pos += 1
            while pos < length {
                let char = text[pos] // Integer Indexing
                if char == pair.close {
                    depth -= 1
                    if depth == 0 { return pos }
                } else if char == pair.open {
                    depth += 1
                }
                pos += 1
            }
        } else {
            pos -= 1
            while pos >= 0 {
                let char = text[pos] // Integer Indexing
                if char == pair.open {
                    depth -= 1
                    if depth == 0 { return pos }
                } else if char == pair.close {
                    depth += 1
                }
                pos -= 1
            }
        }
        return nil
    }
    
    // Helper: Get Glyph Rect
    private func getGlyphRect(at position: Int) -> CGRect? {
        layoutManager.ensureLayout(for: textContainer)
        guard layoutManager.numberOfGlyphs > 0 else { return nil }
        
        // Safe Range Creation
        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: position, length: 1), actualCharacterRange: nil)
        guard glyphRange.location != NSNotFound, glyphRange.length > 0 else { return nil }
        guard glyphRange.location < layoutManager.numberOfGlyphs else { return nil }
        
        var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // Sanity Check for layout validity
        guard rect.width > 0, rect.height > 0, rect.origin.x.isFinite, rect.origin.y.isFinite else { return nil }
        
        rect.origin.x += textContainerInset.left
        rect.origin.y += textContainerInset.top
        return rect
    }
}
