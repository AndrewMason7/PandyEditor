import Foundation
import UIKit
import SwiftUI
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

public class EditorView: UITextView, EditorSurface {
    
    // PATTERN: Lazy Loading
    // We defer the initialization of heavy subviews until they are actually needed
    // to keep the initial view controller load time minimal.
    lazy var lineNumberView = LineNumberView(textView: self)
    public var currentLanguage: SupportedLanguage = .plainText
    public var theme: CodeEditorTheme { highlighter.theme }
    internal var highlighter = SyntaxHighlighter()
    
    // MARK: - Metrics (Bulletproof Constants)
    internal struct Metrics {
        static let gutterWidth: CGFloat = 50
        static let minimapWidth: CGFloat = 60
        static let minimapPadding: CGFloat = 10
        static let defaultPadding: CGFloat = 12
        static let scrollPadding: CGFloat = 40
        static let headerHeight: CGFloat = 64
    }
    
    internal var currentLineHighlightView: UIView?
    internal var bracketHighlightViews: [UIView] = []
    internal var minimapView: MinimapView?
    internal var keyboardToolbar: KeyboardToolbarView?
    
    // MARK: - SwiftUI Bridge State
    public lazy var editorState: EditorState = {
        EditorState(
            showLineNumbers: showLineNumbers,
            showMinimap: showMinimap,
            wordWrapEnabled: wordWrapEnabled,
            showBracketMatching: showBracketMatching,
            showFileHeader: showFileHeader,
            fontSize: currentFontSize,
            theme: theme,
            language: currentLanguage,
            onUpdate: { [weak self] in self?.syncFromState() }
        )
    }()
    
    internal func syncFromState() {
        performSafeUpdate {
            // Unify logic: Only update if changed (View Diffing)
            if self.showLineNumbers != self.editorState.showLineNumbers {
                self.showLineNumbers = self.editorState.showLineNumbers
            }
            if self.showMinimap != self.editorState.showMinimap {
                self.showMinimap = self.editorState.showMinimap
            }
            if self.wordWrapEnabled != self.editorState.wordWrapEnabled {
                self.wordWrapEnabled = self.editorState.wordWrapEnabled
            }
            if self.showBracketMatching != self.editorState.showBracketMatching {
                self.showBracketMatching = self.editorState.showBracketMatching
            }
            if self.showFileHeader != self.editorState.showFileHeader {
                self.showFileHeader = self.editorState.showFileHeader
            }
            if self.currentFontSize != self.editorState.fontSize {
                self.updateFontSize(self.editorState.fontSize)
            }
            if (self.theme.name == self.editorState.theme.name).negated {
                self.setTheme(self.editorState.theme)
            }
            if self.currentLanguage != self.editorState.language {
                self.setLanguage(self.editorState.language)
            }
        }
    }
    
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
    
    internal var bracketMatchingWorkItem: DispatchWorkItem?
    
    // MARK: - Bracket Matching Cache (LAG PREVENTION)
    
    // Scanning for matching brackets is an O(n) operation. Doing this on every
    // cursor movement (layoutSubviews) causes lag in large files.
    // We cache the result and only re-scan if the cursor leaves the current bracket context.
    internal var lastBracketCursorPos: Int = -1
    internal var cachedBracketMatches: [(position: Int, matchPosition: Int)] = []
    
    // MARK: - Feature Toggles
    
    public var showLineNumbers = true {
        didSet {
            performSafeUpdate {
                self.lineNumberView.isHidden = self.showLineNumbers.negated
                self.setNeedsLayout()
            }
        }
    }
    
    public var showCurrentLineHighlight = true {
        didSet {
            performSafeUpdate {
                self.currentLineHighlightView?.isHidden = self.showCurrentLineHighlight.negated
                if self.showCurrentLineHighlight {
                    self.setNeedsLayout()
                }
            }
        }
    }
    
    public var showBracketMatching = true {
        didSet {
            performSafeUpdate {
                if self.showBracketMatching.negated {
                    self.bracketHighlightViews.forEach { $0.removeFromSuperview() }
                    self.bracketHighlightViews.removeAll()
                }
                self.setNeedsLayout()
            }
        }
    }
    
    public var showFileHeader = true {
        didSet {
            performSafeUpdate {
                let topInset: CGFloat = self.showFileHeader ? Metrics.headerHeight : Metrics.defaultPadding
                self.textContainerInset.top = topInset
                self.setNeedsLayout()
            }
        }
    }
    
    public var showMinimap = false {
        didSet {
            performSafeUpdate {
                if self.showMinimap {
                    self.setupMinimap()
                } else {
                    self.minimapView?.removeFromSuperview()
                    self.minimapView = nil
                }
                
                // BULLETPROOF: Update insets dynamically to prevent text overlap
                let rightPadding: CGFloat = self.showMinimap ? (Metrics.minimapWidth + Metrics.minimapPadding) : Metrics.defaultPadding
                self.textContainerInset.right = rightPadding
                self.setNeedsLayout()
            }
        }
    }
    
    public var wordWrapEnabled = true {
        didSet {
            performSafeUpdate {
                self.textContainer.lineBreakMode = self.wordWrapEnabled ? .byWordWrapping : .byClipping
                self.textContainer.widthTracksTextView = self.wordWrapEnabled
                if self.wordWrapEnabled.negated {
                    self.textContainer.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                }
                self.setNeedsLayout()
            }
        }
    }
    
    // MARK: - Font Management
    public var currentFontSize: CGFloat = 14 {
        didSet { 
            updateFontSize()
            // Sync back to state for Command Palette consistency
            if editorState.fontSize != currentFontSize {
                editorState.fontSize = currentFontSize
            }
        }
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
            lineNumberView.frame = CGRect(
                x: contentOffset.x,
                y: contentOffset.y,
                width: Metrics.gutterWidth,
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
    
    // MARK: - Safety Mixin
    
    /// Standardized "Safety" wrapper for UI updates.
    /// Ensures main thread and instance validity.
    /// Note: Window check is omitted here to allow eager configuration during setup.
    internal func performSafeUpdate(_ block: @escaping () -> Void) {
        CrashGuard.onMainThread { [weak self] in
            guard let self = self else { return }
            block()
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