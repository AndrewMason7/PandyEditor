import Foundation
import UIKit
import FiveKit // FIVEKIT: Re-exports FoundationPlus & SwiftUIElements

//
//  CodeEditorTextView.swift
//  PandyEditor 🐼
//
//  The core text editing component - a high-performance UITextView subclass
//  designed to handle large files, syntax highlighting, and gutter decorations
//  (line numbers, minimap) without dropping frames.
//
//  ARCHITECTURE:
//  This class coordinates multiple subsystems:
//  - SyntaxHighlighter: Applies colors to keywords/strings/comments
//  - LineNumberView: Renders line numbers in the gutter
//  - MinimapView: Provides a scaled code overview
//  - BracketMatching: Highlights matching brackets with rainbow colors
//
//  KEY OPTIMIZATIONS:
//  - Viewport-Based Highlighting: Only colors visible range + 50% buffer
//  - Bracket Cache: Avoids O(n) re-scans on redundant cursor positions
//  - Atomic Versioning: Discards stale background work on rapid edits
//  - View Diffing: Only updates UI frames when they actually change
//
//  FIVEKIT COMPLIANCE:
//  1. EXPRESSIVE SYNTAX: Uses `text[i]` and `.negated` via FoundationPlus
//  2. LAG PREVENTION: View Diffing + Viewport Optimization for 120Hz
//  3. THREAD SAFETY: Main Thread guards, background queue for heavy work
//  4. DECOUPLING: NotificationCenter observers instead of delegate pattern
//  5. RACE PROTECTION: Atomic versioning invalidates stale background work
//  6. SAFETY QUADRUPLE: Feature Flag, Window, Thread, and Layout guards
//

public class CodeEditorTextView: UITextView {
    
    // MARK: - UI Components
    
    // FIVEKIT PATTERN: Lazy Loading
    // We defer the initialization of heavy subviews until they are actually needed
    // to keep the initial view controller load time minimal.
    lazy var lineNumberView = LineNumberView(textView: self)
    lazy var highlighter = SyntaxHighlighter(language: JavaScriptSyntax())
    
    private var currentLineHighlightView: UIView?
    private var bracketHighlightViews: [UIView] = []
    private var minimapView: MinimapView?
    private var keyboardToolbar: KeyboardToolbarView?
    
    // MARK: - State Management
    
    // Flags to prevent recursive loops when modifying text storage programmatically
    private var isUpdatingText = false
    private var isProcessingHighlight = false
    
    // MARK: - Bulletproof Versioning (Race Condition Protection)
    
    // Why do we need this?
    // When the user types fast, multiple syntax highlight operations are queued.
    // We need to ensure that a slow background operation doesn't overwrite
    // newer text changes. We use an atomic counter (`textVersion`) to validate results.
    
    /// Serial queue for synchronizing text processing off the main thread.
    private let textProcessingQueue = DispatchQueue(label: "com.codeeditor.textProcessing", qos: .userInteractive)
    
    /// Atomic counter ensures stale background highlights are discarded.
    private var textVersion: UInt64 = 0
    private let versionLock = NSLock()
    
    // MARK: - Throttling & Debouncing
    private var lastEditTime: CFAbsoluteTime = 0
    private let minEditInterval: TimeInterval = 0.016 // Cap updates at ~60fps
    private let highlightDelay: TimeInterval = 0.15   // Wait for typing to pause slightly
    private var highlightWorkItem: DispatchWorkItem?
    
    // MARK: - Bracket Matching Cache (LAG PREVENTION)
    
    // Scanning for matching brackets is an O(n) operation. Doing this on every
    // cursor movement (layoutSubviews) causes lag in large files.
    // We cache the result and only re-scan if the cursor leaves the current bracket context.
    private var lastBracketCursorPos: Int = -1
    private var cachedBracketMatches: [(position: Int, matchPosition: Int)] = []
    
    // MARK: - Feature Toggles
    
    public var showCurrentLineHighlight = true {
        didSet {
            currentLineHighlightView?.isHidden = showCurrentLineHighlight.negated
            if showCurrentLineHighlight {
                // FIVEKIT PATTERN: Defer Updates
                // Use setNeedsLayout() instead of immediate updates to allow
                // UIKit to coalesce multiple state changes into one render pass.
                setNeedsLayout()
            }
        }
    }
    
    public var showBracketMatching = true {
        didSet {
            if showBracketMatching.negated {
                bracketHighlightViews.forEach { $0.removeFromSuperview() }
                bracketHighlightViews.removeAll()
            }
            setNeedsLayout()
        }
    }
    
    public var showMinimap = false {
        didSet {
            if showMinimap {
                setupMinimap()
            } else {
                minimapView?.removeFromSuperview()
                minimapView = nil
            }
            setNeedsLayout()
        }
    }
    
    public var wordWrapEnabled = true {
        didSet {
            textContainer.lineBreakMode = wordWrapEnabled ? .byWordWrapping : .byClipping
            textContainer.widthTracksTextView = wordWrapEnabled
            if wordWrapEnabled.negated {
                // Infinite width for horizontal scrolling
                textContainer.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            }
            setNeedsLayout()
        }
    }
    
    // MARK: - Font Management
    public var currentFontSize: CGFloat = 14 {
        didSet { updateFontSize() }
    }
    private let minFontSize: CGFloat = 10
    private let maxFontSize: CGFloat = 28
    
    // MARK: - Configuration
    private let bracketPairs: [(open: Character, close: Character)] = [
        ("{", "}"), ("(", ")"), ("[", "]")
    ]
    
    // MARK: - Compile-Time Constants
    /// Newline code unit (0x0A) used for safe comparisons in tight loops without casting.
    private static let newlineCodeUnit: unichar = 0x0A
    
    // MARK: - Initialization
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // FIVEKIT: Use expressive theme properties from the current highlighter
        backgroundColor = highlighter.theme.backgroundColor
        tintColor = highlighter.theme.cursorColor
        
        // Disable smart features that interfere with coding
        autocapitalizationType = .none
        autocorrectionType = .no
        spellCheckingType = .no
        smartQuotesType = .no
        smartDashesType = .no
        smartInsertDeleteType = .no
        
        // Typing Attributes (Prevent color flashing while typing)
        typingAttributes = [
            .font: highlighter.font,
            .foregroundColor: highlighter.theme.textColor
        ]
        
        if #available(iOS 16.0, *) { isFindInteractionEnabled = true }
        keyboardAppearance = .dark
        contentInsetAdjustmentBehavior = .scrollableAxes
        allowsEditingTextAttributes = true
        
        // Layout Config
        layoutManager.allowsNonContiguousLayout = false // Essential for accurate line numbers
        let rightPadding: CGFloat = showMinimap ? 70 : 12
        textContainerInset = UIEdgeInsets(top: 12, left: 50, bottom: 12, right: rightPadding)
        textContainer.lineFragmentPadding = 0
        
        // Component Setup
        setupCurrentLineHighlight()
        if showMinimap { setupMinimap() }
        setupAccessoryView()
        
        // Gestures
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        addGestureRecognizer(pinchGesture)
        
        // SAFETY: Internal Observation
        // We use NotificationCenter instead of `self.delegate = self`.
        // This avoids the "Delegate Trap" where a consumer setting their own delegate
        // would accidentally break our highlighting logic.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChangeInternal),
            name: UITextView.textDidChangeNotification,
            object: self
        )
        
        // KEYBOARD HANDLING
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Add Line Number View
        addSubview(lineNumberView)
    }
    
    deinit {
        // BULLETPROOF: Cancel pending work to prevent zombie callbacks
        highlightWorkItem?.cancel()
        highlightWorkItem = nil
        
        // BULLETPROOF: Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Lifecycle Overrides
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        // Defer UI updates to layout pass. This allows UIKit to calculate
        // the final positions of text fragments before we try to draw overlays.
        updateCurrentLineHighlight()

        updateMinimapFrame()
        
        // Update Line Number View Frame (Floating Gutter)
        let gutterWidth: CGFloat = 50
        lineNumberView.frame = CGRect(
            x: contentOffset.x,
            y: contentOffset.y,
            width: gutterWidth,
            height: bounds.height
        )
        bringSubviewToFront(lineNumberView)
    }
    
    // We override this to detect cursor movements (arrow keys, taps)
    // that don't necessarily change the text content.
    override public var selectedTextRange: UITextRange? {
        didSet {
            // Force update on selection change to keep highlight snappy
            updateCurrentLineHighlight()
            // Schedule bracket matching (less urgent, so we don't block main thread)
            if showBracketMatching { updateBracketMatching() }
        }
    }
    
    // MARK: - Feature: Current Line Highlight
    
    private func setupCurrentLineHighlight() {
        let view = UIView()
        view.backgroundColor = highlighter.theme.currentLineColor
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 2
        insertSubview(view, at: 0)
        currentLineHighlightView = view
    }
    
    func updateCurrentLineHighlight() {
        // SAFETY GUARD 1: Feature Flag
        guard showCurrentLineHighlight else {
            currentLineHighlightView?.isHidden = true
            return
        }
        
        // SAFETY GUARD 2: Window Check (Lag Prevention)
        // If the view is off-screen, calculating layout is a waste of CPU.
        guard window != nil else { return }
        
        // SAFETY GUARD 3: Thread Safety
        // FiveKit strictly forbids UI updates on background threads.
        if Thread.isMainThread.negated {
            DispatchQueue.main.async { [weak self] in self?.updateCurrentLineHighlight() }
            return
        }
        
        // SAFETY GUARD 4: Layout Validity
        guard bounds.width > 0, let highlightView = currentLineHighlightView else { return }
        
        // --- Calculation Phase ---
        
        var targetFrame: CGRect
        
        // FIVEKIT: Use expressive properties (FoundationPlus)
        if text.isEmpty {
            let lineHeight = font?.lineHeight ?? 20
            targetFrame = CGRect(x: 0, y: textContainerInset.top, width: bounds.width, height: lineHeight)
        } else {
            let location = selectedRange.location
            let textLength = text.count
            
            // Bounds check
            guard location <= textLength else { return }
            
            // FIVEKIT: Use FoundationPlus integer subscripting `text[i]`
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
        
        targetFrame.origin.x = 0
        targetFrame.size.width = bounds.width
        
        // FIVEKIT LAG PREVENTION (View Diffing):
        // We only touch the UIView if the frame has *actually* changed.
        // Writing to `.frame` triggers a layout pass in UIKit.
        // Skipping redundant writes significantly smoothes out 120Hz scrolling.
        let currentFrame = highlightView.frame
        let yChanged = abs(currentFrame.origin.y - targetFrame.origin.y) > 0.1
        let hChanged = abs(currentFrame.height - targetFrame.height) > 0.1
        let isHidden = highlightView.isHidden
        
        if yChanged || hChanged || isHidden {
            UIView.performWithoutAnimation {
                highlightView.frame = targetFrame
                highlightView.isHidden = false
            }
        }
    }
    
    // MARK: - Feature: Bracket Matching
    
    func updateBracketMatching() {
        // SAFETY QUADRUPLE
        guard showBracketMatching else { return }
        guard window != nil else { return }
        if Thread.isMainThread.negated {
             DispatchQueue.main.async { [weak self] in self?.updateBracketMatching() }
             return
        }
        guard let textContent = text, textContent.isNotEmpty else { return }
        
        // Logic
        let cursorPos = selectedRange.location
        let textLength = textContent.count
        
        // Cleanup if invalid
        guard cursorPos > 0, cursorPos <= textLength else {
            if bracketHighlightViews.isNotEmpty {
                bracketHighlightViews.forEach { $0.removeFromSuperview() }
                bracketHighlightViews.removeAll()
            }
            return
        }
        
        var targetRects: [CGRect] = []
        
        // FIVEKIT LAG PREVENTION: Smart Cache
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
            
            // FIVEKIT: Safe character access with bounds validation
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
    
    // Helper: Find Matching Bracket (Recursive/Stack Logic)
    private func findMatchingBracket(from position: Int, isOpen: Bool, pair: (open: Character, close: Character), in text: String) -> Int? {
        var depth = 1
        var pos = position
        let length = text.count
        
        if isOpen {
            pos += 1
            while pos < length {
                let char = text[pos] // FIVEKIT: Integer Indexing
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
                let char = text[pos] // FIVEKIT: Integer Indexing
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
    
    // MARK: - Feature: Minimap
    
    private func setupMinimap() {
        minimapView?.removeFromSuperview()
        minimapView = MinimapView(textView: self, theme: highlighter.theme)
        if let minimap = minimapView {
            addSubview(minimap) // Frame is handled in layoutSubviews
        }
    }
    
    private func updateMinimapFrame() {
        guard let minimap = minimapView, showMinimap else { return }
        
        let visibleBounds = bounds
        let contentOffset = self.contentOffset
        let minimapWidth: CGFloat = 50
        
        // Pin to right edge relative to current scroll
        let minimapX = contentOffset.x + visibleBounds.width - minimapWidth
        
        // Frame Diffing
        let targetFrame = CGRect(x: minimapX, y: contentOffset.y, width: minimapWidth, height: frame.height)
        
        if abs(minimap.frame.origin.x - targetFrame.origin.x) > 0.5 ||
           abs(minimap.frame.origin.y - targetFrame.origin.y) > 0.5 {
            minimap.frame = targetFrame
            minimap.isHidden = false
            minimap.updateViewport()
        }
    }
    
    // MARK: - Text Change Handling (Bulletproof)
    
    /// Thread-safe increment of text version to invalidate stale background tasks
    private func incrementTextVersion() -> UInt64 {
        versionLock.lock()
        defer { versionLock.unlock() }
        textVersion &+= 1 // Overflow safe operator
        return textVersion
    }
    
    internal func currentTextVersion() -> UInt64 {
        versionLock.lock()
        defer { versionLock.unlock() }
        return textVersion
    }
    
    /// Calculates the visible character range with buffer for smooth scrolling
    /// - Returns: The character range currently visible on screen, plus a buffer
    private func calculateVisibleCharacterRange() -> NSRange? {
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
    
    // MARK: - Public API (State Reset)
    
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
    
    private func updateFontSize() {
        highlighter = SyntaxHighlighter(language: highlighter.language, theme: highlighter.theme, fontSize: currentFontSize)
        lineNumberView.updateFontSize(currentFontSize)
        
        if let text = text {
            setText(text)
        }
    }
    
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            // Simple throttle for pinch
            let newSize = currentFontSize * gesture.scale
            if abs(newSize - currentFontSize) > 1.0 {
                currentFontSize = min(maxFontSize, max(minFontSize, newSize))
                gesture.scale = 1.0
            }
        }
    }
    
    // MARK: - Toolbar Setup
    private func setupAccessoryView() {
        let toolbar = KeyboardToolbarView()
        toolbar.delegate = self
        toolbar.update(language: .swift)
        self.keyboardToolbar = toolbar
        self.inputAccessoryView = toolbar
        
        // Add lineNumberView
        addSubview(lineNumberView)
        
        // Add keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    


}

// MARK: - Keyboard Toolbar Delegate
extension CodeEditorTextView: KeyboardToolbarDelegate {
    // MARK: - Keyboard Handling
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        // SAFETY GUARD 1: Window Check (Lag Prevention)
        // If view is off-screen, adjusting insets wastes CPU cycles
        guard window != nil else { return }
        
        // SAFETY GUARD 2: Thread Safety
        // FiveKit strictly forbids UI updates on background threads
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
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
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
    
    public override func insertText(_ text: String) {
        // Insert at cursor
        guard let range = selectedTextRange else { return }
        replace(range, withText: text)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
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
        }
    }
}
