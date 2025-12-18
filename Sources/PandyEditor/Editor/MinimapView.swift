import Foundation
import UIKit
import FiveKit // FoundationPlus & Elements

//
//  MinimapView.swift
//  PandyEditor 🐼
//
//  Component: Minimap & Navigation
//
//  A scaled-down preview of the entire document, rendered in the background.
//  Click or drag to navigate quickly through large files.
//
//  HOW IT WORKS:
//  1. Text changes → Enqueue background render job
//  2. Background thread → Draw scaled lines into UIImage
//  3. Main thread → Display cached image, update viewport indicator
//
//  FIVEKIT COMPLIANCE:
//  - Thread Safety: Heavy rendering on background queue
//  - Lag Prevention: Throttled generation, view diffing for viewport
//  - Safety Guards: Window/bounds checks, division-by-zero protection
//

// MARK: - Minimap View
internal class MinimapView: UIView {
    
    // MARK: - Configuration
    weak var textView: EditorSurface?
    var theme: CodeEditorTheme {
        didSet {
            backgroundColor = theme.backgroundColor.withAlphaComponent(0.9)
            // Invalidate cache but don't force regen immediately
            cachedImage = nil 
            invalidate()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            if oldValue.size != bounds.size { invalidate() }
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { invalidate() }
    }
    
    private func invalidate() {
        if let text = textView?.text { updateMinimap(with: text) }
    }
    
    // MARK: - State
    private let viewportIndicator = UIView()
    private var cachedImage: UIImage?
    private var isGeneratingCache = false
    
    // Throttling
    private var lastGenerationTime: TimeInterval = 0
    private let generationQueue = DispatchQueue(label: "com.editor.minimap", qos: .userInteractive)
    private var currentGenerationItem: DispatchWorkItem?
    
    // MARK: - Init
    init(textView: EditorSurface, theme: CodeEditorTheme) {
        self.textView = textView
        self.theme = theme
        super.init(frame: .zero)
        
        backgroundColor = theme.backgroundColor.withAlphaComponent(0.9)
        isUserInteractionEnabled = true
        clipsToBounds = true
        contentMode = .redraw // Ensure draw(_:) is called on bounds change
        
        // Viewport Indicator Setup
        viewportIndicator.backgroundColor = UIColor(white: 1, alpha: 0.1)
        viewportIndicator.layer.borderColor = UIColor(white: 1, alpha: 0.2).cgColor
        viewportIndicator.layer.borderWidth = 1
        viewportIndicator.isUserInteractionEnabled = false
        addSubview(viewportIndicator)
        
        // Gestures
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Public API
    func updateMinimap(with text: String) {
        // SAFETY GUARD 1: Window Check
        // If minimap is hidden or offscreen, don't burn CPU generating bitmaps
        guard window != nil else { return }
        
        // SAFETY GUARD 2: Bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // SAFETY GUARD 3: Throttling (Bulletproof)
        // Prevent generating more than once every 200ms (Audit Recommendation)
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastGenerationTime < 0.2 { return }
        lastGenerationTime = now
        
        generateCache(with: text)
    }
    
    // MARK: - Cache Generation
    private func generateCache(with text: String) {
        currentGenerationItem?.cancel()
        
        // Capture strictly immutable values for thread safety
        let currentTheme = self.theme
        let currentBounds = self.bounds
        let renderSize = currentBounds.size
        
        // Optimization: Don't process empty text
        if text.isEmpty {
            self.cachedImage = nil
            self.setNeedsDisplay()
            return
        }
        
        let item = DispatchWorkItem { [weak self] in
            // 1. Setup Context
            let renderer = UIGraphicsImageRenderer(size: renderSize)
            let image = renderer.image { ctx in
                let c = ctx.cgContext
                
                // Fill Background
                c.setFillColor(currentTheme.backgroundColor.cgColor)
                c.fill(CGRect(origin: .zero, size: renderSize))
                
                // 2. Metrics Calculation (STABLE SNAPSHOT)
                // We use the captured immutable 'text' string instead of referencing self
                let lines = text.components(separatedBy: .newlines)
                let totalLines = lines.count
                let effectiveLines = CGFloat(max(1, totalLines))
                
                // Determine scale to fit the ENTIRE document into the Minimap height
                let scale = renderSize.height / max(renderSize.height, effectiveLines * 2.0)
                let lineHeight = max(0.5, 1.5 * scale) // Scaled vertical line height
                
                // 3. Subsampling Optimization (Bulletproof)
                // If we have more lines than pixels, we MUST skip lines to avoid overdraw and lag.
                let maxDrawableLines = renderSize.height / (lineHeight + (1.0 * scale))
                let skipFactor = max(1, Int(effectiveLines / maxDrawableLines))
                
                var y: CGFloat = 0
                
                // Memoryless Line Enumeration with Scaling
                for (lineIndex, line) in lines.enumerated() {
                    // CANCELLATION CHECK: Abort if a newline is being processed
                    if item.isCancelled { break }
                    
                    // Subsampling: Only draw lines that fit the skip pattern
                    if lineIndex % skipFactor != 0 { continue }
                    
                    // Exit early if we somehow exceed bounds
                    if y > renderSize.height { break }
                    
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty.negated {
                        // Color Logic
                        if trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") {
                            c.setFillColor(currentTheme.commentColor.cgColor)
                        } else if trimmed.hasPrefix("func") || trimmed.hasPrefix("class") || trimmed.hasPrefix("struct") {
                            c.setFillColor(currentTheme.keywordColor.cgColor)
                        } else if trimmed.hasPrefix("var") || trimmed.hasPrefix("let") {
                            c.setFillColor(currentTheme.keywordColor.withAlphaComponent(0.8).cgColor)
                        } else {
                            c.setFillColor(currentTheme.textColor.withAlphaComponent(0.5).cgColor)
                        }
                        
                        // Indentation Logic
                        var indentCount = 0
                        for char in line {
                            if char == " " { indentCount += 1 }
                            else if char == "\t" { indentCount += 4 }
                            else { break }
                        }
                        
                        let x = CGFloat(indentCount) * 0.5 * scale + 2
                        let width = min(renderSize.width - x, CGFloat(trimmed.count) * 1.5 * scale)
                        if width > 0.5 {
                            c.fill(CGRect(x: x, y: y, width: width, height: lineHeight))
                        }
                    }
                    
                    y += lineHeight + (1.0 * scale)
                }
            }
            
            // 4. Main Thread Apply
            CrashGuard.onMainThread {
                guard let self = self else { return }
                self.cachedImage = image
                self.setNeedsDisplay()
            }
        }
        
        currentGenerationItem = item
        generationQueue.async(execute: item)
    }
    
    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        // SAFETY GUARD 1: Window check (Lag Prevention)
        guard window != nil else { return }
        
        // SAFETY GUARD 2: Bounds check
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // Draw cached image if available
        cachedImage?.draw(in: bounds)
        
        // Update viewport indicator position
        updateViewport()
    }
    
    // MARK: - Viewport Logic (Lag Prevention)
    func updateViewport() {
        // SAFETY GUARD 1: Window check
        guard window != nil else { return }
        
        // SAFETY GUARD 2: TextView validity
        guard let tv = textView else { return }
        
        // Metrics
        let contentHeight = tv.contentSize.height
        let visibleHeight = tv.bounds.height
        let offsetY = tv.contentOffset.y
        
        // SAFETY GUARD 3: Prevent division by zero
        guard contentHeight > 0, bounds.height > 0 else { return }
        
        // Calculate Ratio
        let ratio = bounds.height / contentHeight
        let y = offsetY * ratio
        let h = visibleHeight * ratio
        
        // Target Frame
        // Clamp height to minimum 10pt for usability
        let targetFrame = CGRect(x: 0, y: y, width: bounds.width, height: max(10, h))
        
        // LAG PREVENTION: View Diffing
        // Only update frame if it has actually changed
        let currentFrame = viewportIndicator.frame
        let yChanged = abs(currentFrame.origin.y - targetFrame.origin.y) > 0.5
        let hChanged = abs(currentFrame.height - targetFrame.height) > 0.5
        
        if yChanged || hChanged {
            viewportIndicator.frame = targetFrame
        }
    }
    
    // MARK: - Interaction
    @objc private func handleTap(_ g: UITapGestureRecognizer) {
        scrollTo(y: g.location(in: self).y)
    }
    
    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        scrollTo(y: g.location(in: self).y)
    }
    
    private func scrollTo(y: CGFloat) {
        // SAFETY GUARD: Prevent division by zero and invalid scroll
        guard let tv = textView else { return }
        guard bounds.height > 0 else { return }
        
        let ratio = y / bounds.height
        let contentY = ratio * tv.contentSize.height
        
        // Center the view on that point, clamped to valid range
        let centeredY = contentY - (tv.bounds.height / 2)
        let maxY = max(0, tv.contentSize.height - tv.bounds.height)
        let clampedY = max(0, min(centeredY, maxY))
        
        tv.setContentOffset(CGPoint(x: 0, y: clampedY), animated: false)
    }
}

// MARK: - Indent Guide Layer
/// Draws vertical indent guides for visual code structure indication.
internal class IndentGuideLayer: CALayer {
    
    var theme: CodeEditorTheme = .oneDarkPro {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var indentWidth: CGFloat = 4 * 7.5  // 4 spaces * approx char width
    
    override func draw(in ctx: CGContext) {
        // SAFETY GUARD 1: Bounds check
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // SAFETY GUARD 2: Indent width validity
        guard indentWidth > 0 else { return }
        
        ctx.setStrokeColor(theme.indentGuideColor.cgColor)
        ctx.setLineWidth(0.5) // Hairline
        
        // Optimization: Don't draw guides beyond half screen (rarely needed, saves CPU)
        let maxX = min(bounds.width, 500)
        
        var x = indentWidth
        
        // Simple loop, efficient drawing
        while x < maxX {
            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: bounds.height))
            x += indentWidth
        }
        
        ctx.strokePath()
    }
}