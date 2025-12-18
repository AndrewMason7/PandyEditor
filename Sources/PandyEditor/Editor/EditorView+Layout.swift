import Foundation
import UIKit
import FiveKit

//
//  EditorView+Layout.swift
//  PandyEditor 🐼
//
//  Extension: Layout & Rendering
//
//  Handles low-level layout calculations, geometry updates,
//  and view diffing for overlays like highlighting and minimap.
//

extension EditorView {
    
    // MARK: - Feature: Current Line Highlight
    
    internal func setupCurrentLineHighlight() {
        let view = UIView()
        view.backgroundColor = highlighter.theme.currentLineColor
        view.isUserInteractionEnabled = false
        insertSubview(view, at: 0)
        currentLineHighlightView = view
    }
    
    internal func updateCurrentLineHighlight() {
        // SAFETY GUARD 1: Feature Flag
        guard showCurrentLineHighlight else {
            currentLineHighlightView?.isHidden = true
            return
        }
        
        // SAFETY GUARD 2: Window Check (Lag Prevention)
        // If the view is off-screen, calculating layout is a waste of CPU.
        guard window != nil else { return }
        
        // SAFETY GUARD 3: Thread Safety
        // Strictly forbids UI updates on background threads.
        if Thread.isMainThread.negated {
            CrashGuard.onMainThread { [weak self] in self?.updateCurrentLineHighlight() }
            return
        }
        
        // SAFETY GUARD 4: Layout Validity
        guard bounds.width > 0, let highlightView = currentLineHighlightView else { return }
        
        // --- Calculation Phase ---
        
        var targetFrame: CGRect
        
        // Use expressive properties (FoundationPlus)
        if text.isEmpty {
            let lineHeight = font?.lineHeight ?? 20
            targetFrame = CGRect(x: 0, y: textContainerInset.top, width: bounds.width, height: lineHeight)
        } else {
            let location = selectedRange.location
            let textLength = text.count
            
            // Bounds check
            guard location <= textLength else { return }
            
            // Use FoundationPlus integer subscripting `text[i]`
            let isAtEnd = location == textLength
            let endsWithNewline = (textLength > 0 && text[textLength - 1] == Character.newline)
            
            if isAtEnd && endsWithNewline {
                // "Phantom" Line Logic:
                // The cursor is sitting AFTER the last newline. This line doesn't exist
                // in the string indices yet, so we ask LayoutManager for the "extra" fragment.
                let extraRect = layoutManager.extraLineFragmentRect
                var rect = extraRect
                rect.origin.y += textContainerInset.top
                
                // Fallback: If LayoutManager hasn't computed the extra rect yet
                if rect.height == 0 {
                    rect.size.height = font?.lineHeight ?? 20
                    rect.origin.y = (layoutManager.usedRect(for: textContainer).maxY) + textContainerInset.top
                }
                targetFrame = rect
            } else {
                // Visual Line Logic:
                // We highlight the VISUAL line fragment (supporting word wrap).
                let safeCharIndex = min(location, textLength > 0 ? textLength - 1 : 0)
                let glyphIndex = layoutManager.glyphIndexForCharacter(at: safeCharIndex)
                
                var rect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
                rect.origin.y += textContainerInset.top
                targetFrame = rect
            }
        }
        
        targetFrame.origin.x = contentOffset.x
        targetFrame.size.width = bounds.width
        
        // LAG PREVENTION (View Diffing):
        // We only touch the UIView if the frame has *actually* changed.
        // Writing to `.frame` triggers a layout pass in UIKit.
        // Skipping redundant writes significantly smoothes out 120Hz scrolling.
        let currentFrame = highlightView.frame
        let xChanged = abs(currentFrame.origin.x - targetFrame.origin.x) > 0.1
        let yChanged = abs(currentFrame.origin.y - targetFrame.origin.y) > 0.1
        let wChanged = abs(currentFrame.width - targetFrame.width) > 0.1
        let hChanged = abs(currentFrame.height - targetFrame.height) > 0.1
        let isHidden = highlightView.isHidden
        
        if xChanged || yChanged || wChanged || hChanged || isHidden {
            UIView.performWithoutAnimation {
                highlightView.frame = targetFrame
                highlightView.isHidden = false
            }
        }
    }
    
    // MARK: - Feature: Minimap
    
    internal func setupMinimap() {
        minimapView?.removeFromSuperview()
        minimapView = MinimapView(textView: self, theme: highlighter.theme)
        if let minimap = minimapView {
            addSubview(minimap) // Frame is handled in layoutSubviews
        }
    }
    
    internal func updateMinimapFrame() {
        guard let minimap = minimapView, showMinimap else { return }
        
        let visibleBounds = bounds
        let contentOffset = self.contentOffset
        let mWidth = Metrics.minimapWidth
        
        // Pin to right edge relative to current scroll
        let minimapX = contentOffset.x + visibleBounds.width - mWidth
        
        // Frame Diffing
        let targetFrame = CGRect(x: minimapX, y: contentOffset.y, width: mWidth, height: frame.height)
        
        if abs(minimap.frame.origin.x - targetFrame.origin.x) > 0.5 ||
           abs(minimap.frame.origin.y - targetFrame.origin.y) > 0.5 {
            minimap.frame = targetFrame
            minimap.isHidden = false
            minimap.updateViewport()
        }
    }
    
    // MARK: - Visible Range Calculation
    
    /// Calculates the visible character range with buffer for smooth scrolling
    /// - Returns: The character range currently visible on screen, plus a buffer
    internal func calculateVisibleCharacterRange() -> NSRange? {
        // SAFETY GUARDS
        guard window != nil else { return nil }
        guard layoutManager.numberOfGlyphs > 0 else { return nil }
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        
        // Calculate visible rect with buffer for scrolling
        let buffer: CGFloat = bounds.height * 0.5 // 50% buffer above and below
        let visibleRect = CGRect(
            x: 0,
            y: max(0, contentOffset.y - buffer),
            width: bounds.width,
            height: bounds.height + (buffer * 2)
        )
        
        // Convert to glyph range
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        guard glyphRange.location != NSNotFound, glyphRange.length > 0 else { return nil }
        
        // Convert to character range
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        guard charRange.location != NSNotFound, charRange.length > 0 else { return nil }
        
        return charRange
    }
}
