import Foundation
import UIKit
import FiveKit

//
//  SyntaxHighlighter.swift
//  PandyEditor 🐼
//
//  The syntax highlighting engine. Applies regex-based colorization while
//  respecting string/comment boundaries (context-aware).
//
//  TWO-PHASE ARCHITECTURE:
//  
//  PHASE 1 - Global Context Scan:
//    Scans the ENTIRE document for Strings and Comments to establish context.
//    This ensures a block comment starting on line 10 is recognized on line 500.
//
//  PHASE 2 - Local Keyword Scan:
//    Only applies Keywords/Numbers/Functions to VISIBLE code gaps.
//    This dramatically reduces CPU and memory usage on large files.
//


internal class SyntaxHighlighter {
    
    // MARK: - Properties
    let theme: CodeEditorTheme
    let font: UIFont
    let language: SyntaxLanguage
    
    // MARK: - Regex Caching (Performance)
    // We compile Regex patterns ONCE per language definition, not per highlight pass.
    private struct CachedPatterns {
        let singleLineComment: NSRegularExpression?
        let multiLineComment: NSRegularExpression?
        let strings: [NSRegularExpression]
        let numbers: NSRegularExpression?
        let functionCall: NSRegularExpression?
        let keywords: [NSRegularExpression]
        let builtins: [NSRegularExpression]
        
        init(language: SyntaxLanguage) {
            // Helper for safe regex compilation
            let makeRegex = { (pattern: String, options: NSRegularExpression.Options) -> NSRegularExpression? in
                return try? NSRegularExpression(pattern: pattern, options: options)
            }
            
            singleLineComment = makeRegex(language.singleLineCommentPattern, .anchorsMatchLines)
            
            if let multiPattern = language.multiLineCommentPattern {
                multiLineComment = makeRegex(multiPattern, [])
            } else {
                multiLineComment = nil
            }
            
            strings = language.stringPatterns.compactMap { makeRegex($0, []) }
            numbers = makeRegex(language.numberPattern, [])
            functionCall = makeRegex(language.functionCallPattern, [])
            
            // Compile keywords into individual regexes (Word Boundary \b is critical)
            self.keywords = language.keywords.compactMap { keyword in makeRegex("\\b\(keyword)\\b", []) }
            self.builtins = language.builtins.compactMap { builtin in makeRegex("\\b\(builtin)\\b", []) }
        }
    }
    
    // Lazy load patterns to avoid initialization cost until the first highlight request
    private lazy var patterns: CachedPatterns = CachedPatterns(language: language)
    
    // MARK: - Initialization
    
    init(language: SyntaxLanguage = JavaScriptSyntax(), theme: CodeEditorTheme = .oneDarkPro, fontSize: CGFloat = 14) {
        self.language = language
        self.theme = theme
        self.font = UIFont(name: "Menlo", size: fontSize) ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
    
    // MARK: - Public API
    
    /// Full highlight - used for initial load or major changes
    func highlight(_ text: String) -> NSAttributedString {
        // Delegate to the optimized version with full range as visible
        return highlight(text, visibleRange: nil)
    }
    
    /// Viewport-optimized highlight - only applies attributes to visible range
    /// - Parameters:
    ///   - text: The full text to highlight
    ///   - visibleRange: The visible character range (pass nil for full highlight)
    /// - Note: Context scanning still happens globally, but attribute application is limited to visible range
    func highlight(_ text: String, visibleRange: NSRange?) -> NSAttributedString {
        // SAFETY GUARD 1: Empty Text
        guard text.isEmpty.negated else {
            return NSAttributedString(string: String.empty, attributes: [
                .font: font,
                .foregroundColor: theme.textColor
            ])
        }
        
        // SAFETY GUARD 2: Large File Protection
        // If text is too large (e.g. > 150,000 chars), skip regex highlighting to prevent UI freeze
        if text.count > 150_000 {
            let attributedString = NSMutableAttributedString(string: text)
            let fullRange = NSRange(location: 0, length: attributedString.length)
            attributedString.addAttribute(.font, value: font, range: fullRange)
            attributedString.addAttribute(.foregroundColor, value: theme.textColor, range: fullRange)
            return attributedString
        }
        
        let attributedString = NSMutableAttributedString(string: text)
        let stringLength = attributedString.length
        
        // Safety: Validate length matches
        guard stringLength > 0 else {
            return attributedString
        }
        
        let fullRange = NSRange(location: 0, length: stringLength)
        
        // Base attributes
        attributedString.addAttribute(.font, value: font, range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: theme.textColor, range: fullRange)
        
        // VIEWPORT OPTIMIZATION: Use provided visible range or fall back to full
        let effectiveVisibleRange = visibleRange ?? fullRange
        applyHighlighting(to: attributedString, fullRange: fullRange, visibleRange: effectiveVisibleRange)
        
        return attributedString
    }
    
    // MARK: - Core Logic
    
    private func applyHighlighting(to attributedString: NSMutableAttributedString, fullRange: NSRange, visibleRange: NSRange) {
        let text = attributedString.string as NSString
        let actualVisibleRange = NSIntersectionRange(fullRange, visibleRange)
        
        // --- PHASE 1: Context Identification ---
        // We must identify "Code", "String", and "Comment" regions globally.
        // Even if a comment starts off-screen, it affects the highlighting of on-screen text.
        
        enum TokenType {
            case comment
            case string
        }
        
        struct TokenMatch {
            let range: NSRange
            let type: TokenType
        }
        
        var matches: [TokenMatch] = []
        
        // Find Comments (Single Line)
        if let slc = patterns.singleLineComment {
            slc.enumerateMatches(in: text as String, options: [], range: fullRange) { match, _, _ in
                if let match = match { matches.append(TokenMatch(range: match.range, type: .comment)) }
            }
        }
        
        // Find Comments (Multi Line)
        if let mlc = patterns.multiLineComment {
            mlc.enumerateMatches(in: text as String, options: [], range: fullRange) { match, _, _ in
                if let match = match { matches.append(TokenMatch(range: match.range, type: .comment)) }
            }
        }
        
        // Find Strings
        for strRegex in patterns.strings {
            strRegex.enumerateMatches(in: text as String, options: [], range: fullRange) { match, _, _ in
                if let match = match { matches.append(TokenMatch(range: match.range, type: .string)) }
            }
        }
        
        // Sort by location to resolve overlaps
        matches.sort { $0.range.location < $1.range.location }
        
        // --- PHASE 2: Context Resolution ---
        // "First winner takes all" logic. If a string starts inside a comment, it's ignored.
        //
        // EXAMPLE: Overlapping patterns
        // ┌──────────────────────────────────────────────────────────┐
        // │ Code:  // This is "not a string"                          │
        // ├──────────────────────────────────────────────────────────┤
        // │ Comment match: [0..26] "// This is \"not a string\""      │
        // │ String match:  [12..26] "\"not a string\""                │
        // ├──────────────────────────────────────────────────────────┤
        // │ Resolution: Comment starts at 0, maxIndex → 26           │
        // │             String starts at 12 < 26 → REJECTED          │
        // │ Result: Entire line is colored as comment ✓              │
        // └──────────────────────────────────────────────────────────┘
        //
        
        var validMatches: [TokenMatch] = []
        var maxIndex = -1
        
        for match in matches {
            if match.range.location >= maxIndex {
                validMatches.append(match)
                maxIndex = match.range.location + match.range.length
            }
        }
        
        // --- PHASE 3: Apply Context Colors ---
        
        let stringLength = attributedString.length
        
        for match in validMatches {
            // Safety: Validate bounds
            guard match.range.location >= 0,
                  match.range.length > 0,
                  match.range.location + match.range.length <= stringLength else {
                continue
            }
            
            // Optimization: Only apply attributes if this container intersects the visible range.
            // This saves creating attribute dictionaries for off-screen text.
            if NSIntersectionRange(match.range, actualVisibleRange).length > 0 {
                let color = (match.type == .comment) ? theme.commentColor : theme.stringColor
                attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }
        
        // --- PHASE 4: Identify Code Gaps ---
        // Code Gaps are regions NOT covered by strings or comments.
        // We only scan for keywords inside these gaps.
        
        var codeRanges: [NSRange] = []
        var currentIdx = fullRange.location
        let endIdx = fullRange.location + fullRange.length
        
        for match in validMatches {
            if match.range.location > currentIdx {
                let length = match.range.location - currentIdx
                if length > 0 {
                    codeRanges.append(NSRange(location: currentIdx, length: length))
                }
            }
            currentIdx = match.range.location + match.range.length
        }
        // Final gap after last match
        if currentIdx < endIdx {
            codeRanges.append(NSRange(location: currentIdx, length: endIdx - currentIdx))
        }
        
        // --- PHASE 5: Keyword Highlighting (Optimized) ---
        //
        // EXAMPLE: Viewport optimization on large file
        // ┌───────────────────────────────────────────────────────────┐
        // │ 10,000 line file, user is viewing lines 500-550           │
        // ├───────────────────────────────────────────────────────────┤
        // │ WITHOUT optimization: Regex runs on all 10,000 lines      │
        // │                       → 50ms of CPU time, UI stutter      │
        // ├───────────────────────────────────────────────────────────┤
        // │ WITH optimization: Regex only runs on lines 475-575       │
        // │                    (visible + 50% buffer)                 │
        // │                    → 2ms of CPU time, silky smooth ✓      │
        // └───────────────────────────────────────────────────────────┘
        //
        
        for codeRange in codeRanges {
            // OPTIMIZATION: Intersection Check
            // We only regex-search code gaps that are actually visible.
            // This saves massive CPU on large files.
            let intersect = NSIntersectionRange(codeRange, actualVisibleRange)
            guard intersect.length > 0 else { continue }
            
            let searchRange = intersect
            
            // Numbers
            if let nums = patterns.numbers {
                applyPattern(nums, to: attributedString, text: text, in: searchRange, color: theme.numberColor)
            }
            
            // Keywords (e.g. func, var)
            for keywordRegex in patterns.keywords {
                applyPattern(keywordRegex, to: attributedString, text: text, in: searchRange, color: theme.keywordColor)
            }
            
            // Builtins (e.g. String, Int)
            for builtinRegex in patterns.builtins {
                applyPattern(builtinRegex, to: attributedString, text: text, in: searchRange, color: theme.functionColor)
            }
            
            // Function Calls
            if let funcCall = patterns.functionCall {
                applyPattern(funcCall, to: attributedString, text: text, in: searchRange, color: theme.functionColor, captureGroup: 1)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Safely applies a regex pattern to a specific range
    private func applyPattern(_ regex: NSRegularExpression, to attributedString: NSMutableAttributedString, text: NSString, in searchRange: NSRange, color: UIColor, captureGroup: Int = 0) {
        
        // Safety: Validate searchRange bounds
        let stringLength = attributedString.length
        guard searchRange.location >= 0,
              searchRange.length >= 0,
              searchRange.location + searchRange.length <= stringLength else {
            return
        }
        
        // Perform Regex Match
        let matches = regex.matches(in: text as String, range: searchRange)
        
        for match in matches {
            // Handle capture groups (e.g. function names without parentheses)
            let range = captureGroup > 0 && captureGroup < match.numberOfRanges ? match.range(at: captureGroup) : match.range
            
            // Double Check Bounds before applying
            if range.location != NSNotFound,
               range.location >= 0,
               range.length > 0,
               range.location + range.length <= stringLength {
                attributedString.addAttribute(.foregroundColor, value: color, range: range)
            }
        }
    }
}
