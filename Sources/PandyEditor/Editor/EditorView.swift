import Foundation
import UIKit
import FiveKit // Re-exports FoundationPlus & SwiftUIElements

//
//  EditorView.swift
//  PandyEditor 🐼
//
//  Core: Main Class Definition & State Management
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
//  7. STABLE DEPENDENCIES: Pinned to semantic versions for deterministic builds
//

public class EditorView: UITextView {
    
    // MARK: - UI Components
    
    // PATTERN: Lazy Loading
    // We defer the initialization of heavy subviews until they are actually needed
    // to keep the initial view controller load time minimal.
    lazy var lineNumberView = LineNumberView(textView: self)
    public var currentLanguage: SupportedLanguage = .plainText
    lazy var highlighter = SyntaxHighlighter(language: currentLanguage.syntax)
    
    internal var currentLineHighlightView: UIView?
    internal var bracketHighlightViews: [UIView] = []
    internal var minimapView: MinimapView?
    internal var keyboardToolbar: KeyboardToolbarView?
    
    // MARK: - State Management
    
    // Flags to prevent recursive loops when modifying text storage programmatically
    internal var isUpdatingText = false
    internal var isProcessingHighlight = false
    
    // MARK: - Bulletproof Versioning (Race Condition Protection)
    
    // Why do we need this?
    // When the user types fast, multiple syntax highlight operations are queued.
    // We need to ensure that a slow background operation doesn't overwrite
    // newer text changes. We use an atomic counter (`textVersion`) to validate results.
    
    /// Serial queue for synchronizing text processing off the main thread.
    internal let textProcessingQueue = DispatchQueue(label: "com.codeeditor.textProcessing", qos: .userInteractive)
    
    /// Atomic counter ensures stale background highlights are discarded.
    internal var textVersion: UInt64 = 0
    internal let versionLock = NSLock()
    
    // MARK: - Throttling & Debouncing
    internal var lastEditTime: CFAbsoluteTime = 0
    internal let minEditInterval: TimeInterval = 0.016 // Cap updates at ~60fps
    internal let highlightDelay: TimeInterval = 0.15   // Wait for typing to pause slightly
    internal var highlightWorkItem: DispatchWorkItem?
    
    // MARK: - Bracket Matching Cache (LAG PREVENTION)
    
    // Scanning for matching brackets is an O(n) operation. Doing this on every
    // cursor movement (layoutSubviews) causes lag in large files.
    // We cache the result and only re-scan if the cursor leaves the current bracket context.
    internal var lastBracketCursorPos: Int = -1
    internal var cachedBracketMatches: [(position: Int, matchPosition: Int)] = []
    
    // MARK: - Feature Toggles
    
    public var showLineNumbers = true {
        didSet {
            lineNumberView.isHidden = showLineNumbers.negated
            setNeedsLayout()
        }
    }
    
    public var showCurrentLineHighlight = true {
        didSet {
            currentLineHighlightView?.isHidden = showCurrentLineHighlight.negated
            if showCurrentLineHighlight {
                // PATTERN: Defer Updates
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
    
    /// Minimum allowed font size for pinch-to-zoom
    internal static let minFontSize: CGFloat = 10
    /// Maximum allowed font size for pinch-to-zoom
    internal static let maxFontSize: CGFloat = 28
    
    // MARK: - Configuration
    internal let bracketPairs: [(open: Character, close: Character)] = [
        ("{", "}"), ("(", ")"), ("[", "]")
    ]
    
    // MARK: - Compile-Time Constants
    /// Newline code unit (0x0A) used for safe comparisons in tight loops without casting.
    internal static let newlineCodeUnit: unichar = 0x0A
    
    // MARK: - Initialization
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
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
        // CRITICAL STABILITY FIX:
        // 1. Disable implicit animations to prevent "floating" lag
        // 2. Force redraw to sync numbers with new content offset
        UIView.performWithoutAnimation {
            let gutterWidth: CGFloat = 50
            lineNumberView.frame = CGRect(
                x: contentOffset.x,
                y: contentOffset.y,
                width: gutterWidth,
                height: bounds.height
            )
            lineNumberView.setNeedsDisplay()
        }
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
}

// MARK: - Version Management (Thread-Safe)
extension EditorView {
    
    /// Atomically increments and returns the new text version.
    /// Used to invalidate stale background work when text changes rapidly.
    ///
    /// RACE CONDITION PROTECTION:
    /// This method is critical for preventing stale syntax highlighting results
    /// from overwriting newer text states when the user types quickly.
    @discardableResult
    internal func incrementTextVersion() -> UInt64 {
        versionLock.lock()
        defer { versionLock.unlock() }
        textVersion += 1
        return textVersion
    }
    
    /// Returns the current text version in a thread-safe manner.
    /// Used by background workers to verify their results are still valid.
    internal func currentTextVersion() -> UInt64 {
        versionLock.lock()
        defer { versionLock.unlock() }
        return textVersion
    }
}
