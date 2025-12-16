import Foundation
import UIKit
import FiveKit

//
//  LineNumberView.swift
//  PandyEditor 🐼
//
//  A high-performance gutter view that displays line numbers alongside the editor.
//  Uses binary search (O(log n)) to find line indices and only draws visible numbers.
//
//  HOW IT WORKS:
//  1. Cache Phase: When text changes, we scan for newlines and cache their positions
//  2. Draw Phase: We only draw line numbers that are currently visible on screen
//  3. Lookup: Binary search finds the starting line for the visible range
//
//  FIVEKIT COMPLIANCE:
//  - Thread Safety: NSLock protects cache, main thread dispatch for UI
//  - Lag Prevention: Only draws visible range with 100px buffer
//  - No Force Unwraps: Uses compile-time newline constant (0x0A)
//

// MARK: - Line Number View
internal class LineNumberView: UIView {
    weak var textView: UITextView?
    var theme: CodeEditorTheme
    
    // MARK: - Cached Line Data (Protected by cacheLock)
    private var lineStartIndices: [Int] = [0]
    private var cachedTextLength: Int = 0
    private var cachedVersion: UInt64 = 0
    private let cacheLock = NSLock()
    
    // Cached font and attributes
    var font: UIFont
    var attributes: [NSAttributedString.Key: Any]
    
    init(textView: UITextView, fontSize: CGFloat = 14, theme: CodeEditorTheme = .oneDarkPro) {
        self.textView = textView
        self.theme = theme
        self.font = UIFont(name: "Menlo", size: fontSize) ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        self.attributes = [
            .font: font,
            .foregroundColor: theme.lineNumberColor
        ]
        super.init(frame: .zero)
        backgroundColor = theme.lineNumberBackground
        isUserInteractionEnabled = false
        clearsContextBeforeDrawing = true
        isOpaque = true
        contentMode = .redraw
        
        // Performance: Disable async drawing for sharp text, disable rasterization for clear scrolling
        layer.drawsAsynchronously = false
        layer.shouldRasterize = false
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    // MARK: - Compile-Time Constants (Avoids Force Unwraps)
    /// Newline code unit (0x0A) for safe comparisons without force unwrapping
    private static let newlineCodeUnit: unichar = 0x0A
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Font Size Update
    func updateFontSize(_ newSize: CGFloat) {
        font = UIFont(name: "Menlo", size: newSize) ?? UIFont.monospacedSystemFont(ofSize: newSize, weight: .regular)
        attributes = [
            .font: font,
            .foregroundColor: theme.lineNumberColor
        ]
        setNeedsDisplay()
    }
    
    // MARK: - Cache Updates (Thread-Safe)
    func invalidateLineCache() {
        // SAFETY GUARD: Check text validity
        guard let textView = textView as? CodeEditorTextView, let text = textView.text else {
            resetCache()
            return
        }
        updateLineCache(with: text, version: textView.currentTextVersion())
        setNeedsDisplay()
    }
    
    private func resetCache() {
        cacheLock.lock()
        lineStartIndices = [0]
        cachedTextLength = 0
        cachedVersion = 0
        cacheLock.unlock()
        
        DispatchQueue.main.async { [weak self] in self?.setNeedsDisplay() }
    }
    
    func updateLineCache(indices: [Int], length: Int, version: UInt64) {
        cacheLock.lock()
        self.lineStartIndices = indices.isEmpty ? [0] : indices
        self.cachedTextLength = length
        self.cachedVersion = version
        cacheLock.unlock()
        
        if Thread.isMainThread {
            setNeedsDisplay()
        } else {
            DispatchQueue.main.async { [weak self] in self?.setNeedsDisplay() }
        }
    }
    
    func updateLineCache(with text: String, version: UInt64) {
        // FIVEKIT OPTIMIZATION: Use UTF16 count for UIKit compatibility
        let length = text.utf16.count
        let nsText = text as NSString
        
        var indices: [Int] = [0]
        
        // Scan for newlines using compile-time constant (no force unwrap)
        for i in 0..<nsText.length {
            if nsText.character(at: i) == Self.newlineCodeUnit {
                indices.append(i + 1)
            }
        }
        
        updateLineCache(indices: indices, length: length, version: version)
    }

    override func draw(_ rect: CGRect) {
        // SAFETY GUARD 1: Window & Bounds
        guard window != nil, bounds.width > 0, bounds.height > 0 else { return }
        
        // SAFETY GUARD 2: Context
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw Background
        context.setFillColor(theme.lineNumberBackground.cgColor)
        context.fill(bounds)
        
        guard let textView = textView as? CodeEditorTextView else { return }
        
        // Capture Cache Snapshot (Thread-Safe)
        cacheLock.lock()
        let indices = lineStartIndices
        cacheLock.unlock()
        
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        // --- CALCULATION PHASE ---
        
        // 1. Determine Visible Range
        let visibleRect = CGRect(origin: textView.contentOffset, size: textView.bounds.size)
        let rangeRect = visibleRect.insetBy(dx: 0, dy: -100) // Buffer for scrolling
        
        let glyphRange = layoutManager.glyphRange(forBoundingRect: rangeRect, in: textContainer)
        let totalGlyphs = layoutManager.numberOfGlyphs
        
        // Safety: Validate Range
        guard glyphRange.location != NSNotFound, totalGlyphs > 0 else {
            // Draw "1" for empty state
            drawNumber(1, atY: textView.textContainerInset.top, width: bounds.width)
            return
        }
        
        // Clamp Range
        let safeLength = min(glyphRange.length, totalGlyphs - glyphRange.location)
        let validGlyphRange = NSRange(location: glyphRange.location, length: max(0, safeLength))
        
        // 2. Optimization: Fast-Forward Index Pointer
        // Instead of binary searching every line, find the starting line once.
        let startCharIndex = layoutManager.characterIndexForGlyph(at: validGlyphRange.location)
        var currentLineIndex = findLineIndex(for: startCharIndex, in: indices)
        
        // Track paragraph uniqueness to handle wrapped lines
        var lastDrawnParagraphStart = -1
        
        // 3. Draw Loop
        layoutManager.enumerateLineFragments(forGlyphRange: validGlyphRange) { rect, _, _, fragmentGlyphRange, _ in
            
            // Validate Frame
            guard rect.height > 0, rect.width > 0 else { return }
            
            // Map Glyph to Character
            let charRange = layoutManager.characterRange(forGlyphRange: fragmentGlyphRange, actualGlyphRange: nil)
            let charStart = charRange.location
            
            // Determine Paragraph Start (Logical Line)
            // Note: We avoid `textView.text` here if possible, but paragraphRange needs it.
            // Optimization: Assume `indices` tracks paragraph starts accurately enough for numbers.
            
            // Advance our line index pointer if we've moved past the current line's start
            while currentLineIndex + 1 < indices.count && indices[currentLineIndex + 1] <= charStart {
                currentLineIndex += 1
            }
            
            let paragraphStart = indices[currentLineIndex]
            
            // Only draw number if this is the start of a new logical paragraph (handle word wrap)
            if charStart == paragraphStart {
                if paragraphStart != lastDrawnParagraphStart {
                    lastDrawnParagraphStart = paragraphStart
                    
                    // Display number is 1-based index
                    let lineNum = currentLineIndex + 1
                    let yPos = rect.origin.y + textView.textContainerInset.top - textView.contentOffset.y + (rect.height - self.font.lineHeight) / 2.0
                    
                    self.drawNumber(lineNum, atY: yPos, width: self.bounds.width)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Optimized Binary Search for initial line position
    ///
    /// EXAMPLE: Finding line number for character index 150
    /// ┌───────────────────────────────────────────────────────────┐
    /// │ indices = [0, 45, 89, 140, 185, 230, 280]                 │
    /// │         line 1  2   3    4    5    6    7                 │
    /// ├───────────────────────────────────────────────────────────┤
    /// │ Looking for: charIndex = 150                              │
    /// ├───────────────────────────────────────────────────────────┤
    /// │ Binary Search Steps:                                      │
    /// │ low=0, high=6, mid=3 → indices[3]=140 ≤ 150 → low=3       │
    /// │ low=3, high=6, mid=5 → indices[5]=230 > 150 → high=4      │
    /// │ low=3, high=4, mid=4 → indices[4]=185 > 150 → high=3      │
    /// │ low=3, high=3 → DONE! Return 3 (line 4)                   │
    /// ├───────────────────────────────────────────────────────────┤
    /// │ Result: O(log n) = 3 steps vs O(n) = 4 steps              │
    /// │         For 10,000 lines: 14 steps vs 5,000 steps! ✓      │
    /// └───────────────────────────────────────────────────────────┘
    ///
    private func findLineIndex(for charIndex: Int, in indices: [Int]) -> Int {
        var low = 0
        var high = indices.count - 1
        
        while low < high {
            let mid = (low + high + 1) / 2
            if indices[mid] <= charIndex {
                low = mid
            } else {
                high = mid - 1
            }
        }
        return low
    }
    
    private func drawNumber(_ num: Int, atY y: CGFloat, width: CGFloat) {
        // Safety bounds check for drawing
        guard y > -50, y < bounds.height + 50 else { return }
        
        let numStr = "\(num)" as NSString
        let size = numStr.size(withAttributes: attributes)
        let x = width - size.width - 8 // Right aligned with padding
        
        numStr.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
    }
}