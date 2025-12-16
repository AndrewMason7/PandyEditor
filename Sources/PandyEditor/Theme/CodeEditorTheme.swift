import Foundation
import UIKit
import FiveKit // FIVEKIT: FoundationPlus

//
//  CodeEditorTheme.swift
//  PandyEditor 🐼
//
//  Defines the CodeEditorTheme struct and 12+ professionally tuned color palettes.
//  Each theme includes colors for all syntax elements and UI components.
//
//  THEME STRUCTURE:
//  - Syntax Colors: keywords, strings, comments, numbers, functions, types
//  - UI Colors: background, text, cursor, selection, current line
//  - Gutter Colors: line numbers, minimap background
//  - Feedback Colors: error, warning, bracket match
//
//  FIVEKIT COMPLIANCE:
//  - Value Type: CodeEditorTheme is an immutable struct
//  - No Force Unwraps: All properties are non-optional UIColor
//  - Default Fallback: theme(named:) returns .modernDark for unknown names
//  - Equatable: Enables View Diffing for theme changes
//

// MARK: - Code Editor Theme
public struct CodeEditorTheme: Equatable {
    public let name: String
    public let backgroundColor: UIColor
    public let textColor: UIColor
    public let keywordColor: UIColor
    public let stringColor: UIColor
    public let commentColor: UIColor
    public let numberColor: UIColor
    public let functionColor: UIColor
    public let operatorColor: UIColor
    public let typeColor: UIColor
    public let propertyColor: UIColor
    public let lineNumberColor: UIColor
    public let lineNumberBackground: UIColor
    public let cursorColor: UIColor
    public let selectionColor: UIColor
    public let currentLineColor: UIColor
    public let bracketMatchColor: UIColor
    public let minimapBackgroundColor: UIColor
    public let indentGuideColor: UIColor
    public let errorColor: UIColor
    public let warningColor: UIColor
    
    // MARK: - Bulletproof UI Helpers
    /// Automatically determines if the theme is Dark or Light based on background luminance.
    /// Used to set UIStatusBarStyle and UIKeyboardAppearance automatically.
    public var userInterfaceStyle: UIUserInterfaceStyle {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // Luma calculation: https://en.wikipedia.org/wiki/Luma_(video)
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance < 0.5 ? .dark : .light
    }
    
    public init(name: String, backgroundColor: UIColor, textColor: UIColor, keywordColor: UIColor, stringColor: UIColor, commentColor: UIColor, numberColor: UIColor, functionColor: UIColor, operatorColor: UIColor, typeColor: UIColor, propertyColor: UIColor, lineNumberColor: UIColor, lineNumberBackground: UIColor, cursorColor: UIColor, selectionColor: UIColor, currentLineColor: UIColor, bracketMatchColor: UIColor, minimapBackgroundColor: UIColor, indentGuideColor: UIColor, errorColor: UIColor, warningColor: UIColor) {
        self.name = name
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.keywordColor = keywordColor
        self.stringColor = stringColor
        self.commentColor = commentColor
        self.numberColor = numberColor
        self.functionColor = functionColor
        self.operatorColor = operatorColor
        self.typeColor = typeColor
        self.propertyColor = propertyColor
        self.lineNumberColor = lineNumberColor
        self.lineNumberBackground = lineNumberBackground
        self.cursorColor = cursorColor
        self.selectionColor = selectionColor
        self.currentLineColor = currentLineColor
        self.bracketMatchColor = bracketMatchColor
        self.minimapBackgroundColor = minimapBackgroundColor
        self.indentGuideColor = indentGuideColor
        self.errorColor = errorColor
        self.warningColor = warningColor
    }
}

// MARK: - DARK THEMES
extension CodeEditorTheme {
    
    // MARK: - One Dark Pro (Default)
    public static let oneDarkPro = CodeEditorTheme(
        name: "One Dark Pro",
        backgroundColor: UIColor(red: 0.14, green: 0.15, blue: 0.17, alpha: 1.0),
        textColor: UIColor(red: 0.67, green: 0.71, blue: 0.78, alpha: 1.0),
        keywordColor: UIColor(red: 0.78, green: 0.47, blue: 0.80, alpha: 1.0),
        stringColor: UIColor(red: 0.60, green: 0.78, blue: 0.51, alpha: 1.0),
        commentColor: UIColor(red: 0.35, green: 0.40, blue: 0.45, alpha: 1.0),
        numberColor: UIColor(red: 0.82, green: 0.58, blue: 0.40, alpha: 1.0),
        functionColor: UIColor(red: 0.38, green: 0.69, blue: 0.93, alpha: 1.0),
        operatorColor: UIColor(red: 0.34, green: 0.73, blue: 0.82, alpha: 1.0),
        typeColor: UIColor(red: 0.90, green: 0.73, blue: 0.47, alpha: 1.0),
        propertyColor: UIColor(red: 0.90, green: 0.46, blue: 0.45, alpha: 1.0),
        lineNumberColor: UIColor(red: 0.35, green: 0.38, blue: 0.42, alpha: 1.0),
        lineNumberBackground: UIColor(red: 0.12, green: 0.13, blue: 0.15, alpha: 1.0),
        cursorColor: UIColor(red: 0.53, green: 0.75, blue: 0.98, alpha: 1.0),
        selectionColor: UIColor(red: 0.24, green: 0.35, blue: 0.48, alpha: 0.5),
        currentLineColor: UIColor(red: 0.17, green: 0.18, blue: 0.20, alpha: 1.0),
        bracketMatchColor: UIColor(red: 0.53, green: 0.75, blue: 0.98, alpha: 0.4),
        minimapBackgroundColor: UIColor(red: 0.11, green: 0.12, blue: 0.14, alpha: 0.9),
        indentGuideColor: UIColor(red: 0.25, green: 0.27, blue: 0.30, alpha: 0.5),
        errorColor: UIColor(red: 0.95, green: 0.35, blue: 0.35, alpha: 1.0),
        warningColor: UIColor(red: 0.95, green: 0.75, blue: 0.30, alpha: 1.0)
    )
    
    // MARK: - Modern Dark
    public static let modernDark = CodeEditorTheme(
        name: "Modern Dark",
        backgroundColor: UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1.0),
        textColor: UIColor(red: 0.92, green: 0.94, blue: 0.96, alpha: 1.0),
        keywordColor: UIColor(red: 0.60, green: 0.76, blue: 1.0, alpha: 1.0),
        stringColor: UIColor(red: 0.53, green: 0.93, blue: 0.65, alpha: 1.0),
        commentColor: UIColor(red: 0.45, green: 0.52, blue: 0.60, alpha: 1.0),
        numberColor: UIColor(red: 1.0, green: 0.67, blue: 0.42, alpha: 1.0),
        functionColor: UIColor(red: 0.82, green: 0.47, blue: 1.0, alpha: 1.0),
        operatorColor: UIColor(red: 0.40, green: 0.85, blue: 0.90, alpha: 1.0),
        typeColor: UIColor(red: 1.0, green: 0.82, blue: 0.40, alpha: 1.0),
        propertyColor: UIColor(red: 1.0, green: 0.55, blue: 0.65, alpha: 1.0),
        lineNumberColor: UIColor(red: 0.35, green: 0.42, blue: 0.50, alpha: 1.0),
        lineNumberBackground: UIColor(red: 0.03, green: 0.04, blue: 0.06, alpha: 1.0),
        cursorColor: UIColor(red: 0.60, green: 0.76, blue: 1.0, alpha: 1.0),
        selectionColor: UIColor(red: 0.15, green: 0.30, blue: 0.50, alpha: 0.45),
        currentLineColor: UIColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 1.0),
        bracketMatchColor: UIColor(red: 0.82, green: 0.47, blue: 1.0, alpha: 0.35),
        minimapBackgroundColor: UIColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 0.95),
        indentGuideColor: UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 0.6),
        errorColor: UIColor(red: 1.0, green: 0.38, blue: 0.38, alpha: 1.0),
        warningColor: UIColor(red: 1.0, green: 0.82, blue: 0.40, alpha: 1.0)
    )
    
    // MARK: - GitHub Dark
    public static let githubDark = CodeEditorTheme(
        name: "GitHub Dark",
        backgroundColor: UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 1.0),
        textColor: UIColor(red: 0.89, green: 0.93, blue: 0.97, alpha: 1.0),
        keywordColor: UIColor(red: 1.0, green: 0.49, blue: 0.47, alpha: 1.0),
        stringColor: UIColor(red: 0.64, green: 0.79, blue: 1.0, alpha: 1.0),
        commentColor: UIColor(red: 0.55, green: 0.60, blue: 0.66, alpha: 1.0),
        numberColor: UIColor(red: 0.47, green: 0.75, blue: 0.93, alpha: 1.0),
        functionColor: UIColor(red: 0.82, green: 0.67, blue: 1.0, alpha: 1.0),
        operatorColor: UIColor(red: 1.0, green: 0.49, blue: 0.47, alpha: 1.0),
        typeColor: UIColor(red: 0.49, green: 0.82, blue: 0.64, alpha: 1.0),
        propertyColor: UIColor(red: 0.47, green: 0.75, blue: 0.93, alpha: 1.0),
        lineNumberColor: UIColor(red: 0.40, green: 0.46, blue: 0.52, alpha: 1.0),
        lineNumberBackground: UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 1.0),
        cursorColor: UIColor(red: 0.21, green: 0.45, blue: 0.78, alpha: 1.0),
        selectionColor: UIColor(red: 0.21, green: 0.45, blue: 0.78, alpha: 0.4),
        currentLineColor: UIColor(red: 0.09, green: 0.11, blue: 0.14, alpha: 1.0),
        bracketMatchColor: UIColor(red: 0.82, green: 0.67, blue: 1.0, alpha: 0.3),
        minimapBackgroundColor: UIColor(red: 0.03, green: 0.05, blue: 0.07, alpha: 0.9),
        indentGuideColor: UIColor(red: 0.18, green: 0.22, blue: 0.27, alpha: 0.5),
        errorColor: UIColor(red: 1.0, green: 0.49, blue: 0.47, alpha: 1.0),
        warningColor: UIColor(red: 0.89, green: 0.73, blue: 0.35, alpha: 1.0)
    )
    
    // MARK: - Dracula
    public static let dracula = CodeEditorTheme(
        name: "Dracula",
        backgroundColor: UIColor(red: 0.16, green: 0.16, blue: 0.21, alpha: 1.0),
        textColor: UIColor(red: 0.97, green: 0.98, blue: 0.98, alpha: 1.0),
        keywordColor: UIColor(red: 1.0, green: 0.47, blue: 0.65, alpha: 1.0),
        stringColor: UIColor(red: 0.95, green: 0.98, blue: 0.48, alpha: 1.0),
        commentColor: UIColor(red: 0.38, green: 0.45, blue: 0.55, alpha: 1.0),
        numberColor: UIColor(red: 0.74, green: 0.58, blue: 0.98, alpha: 1.0),
        functionColor: UIColor(red: 0.31, green: 0.98, blue: 0.48, alpha: 1.0),
        operatorColor: UIColor(red: 1.0, green: 0.47, blue: 0.65, alpha: 1.0),
        typeColor: UIColor(red: 0.54, green: 0.93, blue: 0.99, alpha: 1.0),
        propertyColor: UIColor(red: 1.0, green: 0.72, blue: 0.42, alpha: 1.0),
        lineNumberColor: UIColor(red: 0.38, green: 0.42, blue: 0.50, alpha: 1.0),
        lineNumberBackground: UIColor(red: 0.13, green: 0.14, blue: 0.18, alpha: 1.0),
        cursorColor: UIColor(red: 0.97, green: 0.98, blue: 0.98, alpha: 1.0),
        selectionColor: UIColor(red: 0.27, green: 0.29, blue: 0.35, alpha: 0.7),
        currentLineColor: UIColor(red: 0.20, green: 0.21, blue: 0.26, alpha: 1.0),
        bracketMatchColor: UIColor(red: 1.0, green: 0.47, blue: 0.65, alpha: 0.3),
        minimapBackgroundColor: UIColor(red: 0.13, green: 0.14, blue: 0.18, alpha: 0.9),
        indentGuideColor: UIColor(red: 0.28, green: 0.30, blue: 0.36, alpha: 0.5),
        errorColor: UIColor(red: 1.0, green: 0.33, blue: 0.33, alpha: 1.0),
        warningColor: UIColor(red: 0.95, green: 0.98, blue: 0.48, alpha: 1.0)
    )
    
    // MARK: - Catppuccin Mocha
    static let catppuccinMocha = CodeEditorTheme(
        name: "Catppuccin Mocha",
        backgroundColor: UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0),
        textColor: UIColor(red: 0.80, green: 0.84, blue: 0.96, alpha: 1.0),
        keywordColor: UIColor(red: 0.80, green: 0.56, blue: 0.94, alpha: 1.0),
        stringColor: UIColor(red: 0.65, green: 0.89, blue: 0.63, alpha: 1.0),
        commentColor: UIColor(red: 0.42, green: 0.45, blue: 0.59, alpha: 1.0),
        numberColor: UIColor(red: 0.98, green: 0.74, blue: 0.56, alpha: 1.0),
        functionColor: UIColor(red: 0.54, green: 0.71, blue: 0.98, alpha: 1.0),
        operatorColor: UIColor(red: 0.58, green: 0.87, blue: 0.86, alpha: 1.0),
        typeColor: UIColor(red: 0.97, green: 0.90, blue: 0.58, alpha: 1.0),
        propertyColor: UIColor(red: 0.95, green: 0.55, blue: 0.66, alpha: 1.0),
        lineNumberColor: UIColor(red: 0.42, green: 0.45, blue: 0.59, alpha: 1.0),
        lineNumberBackground: UIColor(red: 0.10, green: 0.10, blue: 0.15, alpha: 1.0),
        cursorColor: UIColor(red: 0.95, green: 0.71, blue: 0.78, alpha: 1.0),
        selectionColor: UIColor(red: 0.27, green: 0.28, blue: 0.39, alpha: 0.6),
        currentLineColor: UIColor(red: 0.15, green: 0.15, blue: 0.22, alpha: 1.0),
        bracketMatchColor: UIColor(red: 0.54, green: 0.71, blue: 0.98, alpha: 0.4),
        minimapBackgroundColor: UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.9),
        indentGuideColor: UIColor(red: 0.22, green: 0.23, blue: 0.32, alpha: 0.5),
        errorColor: UIColor(red: 0.95, green: 0.55, blue: 0.66, alpha: 1.0),
        warningColor: UIColor(red: 0.97, green: 0.90, blue: 0.58, alpha: 1.0)
    )
}

// MARK: - LIGHT THEMES
extension CodeEditorTheme {
    
    // MARK: - GitHub Light
    public static let githubLight = CodeEditorTheme(
        name: "GitHub Light",
        backgroundColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),      // #ffffff
        textColor: UIColor(red: 0.14, green: 0.16, blue: 0.18, alpha: 1.0),            // #24292e
        keywordColor: UIColor(red: 0.84, green: 0.23, blue: 0.29, alpha: 1.0),         // #d73a49 (Red)
        stringColor: UIColor(red: 0.01, green: 0.26, blue: 0.56, alpha: 1.0),          // #032f62 (Dark Blue)
        commentColor: UIColor(red: 0.42, green: 0.45, blue: 0.49, alpha: 1.0),         // #6a737d (Gray)
        numberColor: UIColor(red: 0.00, green: 0.36, blue: 0.77, alpha: 1.0),          // #005cc5 (Blue)
        functionColor: UIColor(red: 0.44, green: 0.28, blue: 0.75, alpha: 1.0),        // #6f42c1 (Purple)
        operatorColor: UIColor(red: 0.84, green: 0.23, blue: 0.29, alpha: 1.0),        // Red
        typeColor: UIColor(red: 0.44, green: 0.28, blue: 0.75, alpha: 1.0),            // Purple
        propertyColor: UIColor(red: 0.00, green: 0.36, blue: 0.77, alpha: 1.0),        // Blue
        lineNumberColor: UIColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 1.0),
        lineNumberBackground: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
        cursorColor: UIColor(red: 0.14, green: 0.16, blue: 0.18, alpha: 1.0),
        selectionColor: UIColor(red: 0.01, green: 0.26, blue: 0.56, alpha: 0.2),
        currentLineColor: UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0),     // #f6f8fa
        bracketMatchColor: UIColor(red: 0.00, green: 0.36, blue: 0.77, alpha: 0.3),
        minimapBackgroundColor: UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0),
        indentGuideColor: UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0),
        errorColor: UIColor(red: 0.79, green: 0.13, blue: 0.13, alpha: 1.0),           // #cb2431
        warningColor: UIColor(red: 0.96, green: 0.87, blue: 0.06, alpha: 1.0)
    )
    
    // MARK: - Xcode Light
    public static let xcodeLight = CodeEditorTheme(
        name: "Xcode Light",
        backgroundColor: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
        textColor: UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.0),
        keywordColor: UIColor(red: 0.61, green: 0.14, blue: 0.58, alpha: 1.0),         // #9b2393 (Magenta)
        stringColor: UIColor(red: 0.77, green: 0.10, blue: 0.09, alpha: 1.0),          // #c41a16 (Red)
        commentColor: UIColor(red: 0.34, green: 0.45, blue: 0.49, alpha: 1.0),         // #56737d (Gray Green)
        numberColor: UIColor(red: 0.11, green: 0.00, blue: 0.81, alpha: 1.0),          // #1c00cf (Blue)
        functionColor: UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.0),        // Black (Xcode default)
        operatorColor: UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.0),
        typeColor: UIColor(red: 0.22, green: 0.40, blue: 0.54, alpha: 1.0),            // #38678a (Teal/Blue)
        propertyColor: UIColor(red: 0.22, green: 0.40, blue: 0.54, alpha: 1.0),
        lineNumberColor: UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.0),
        lineNumberBackground: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
        cursorColor: UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.0),
        selectionColor: UIColor(red: 0.64, green: 0.79, blue: 1.00, alpha: 0.5),       // Light Blue selection
        currentLineColor: UIColor(red: 0.92, green: 0.96, blue: 1.00, alpha: 1.0),     // #ecf5ff
        bracketMatchColor: UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 0.5),    // Yellow highlight
        minimapBackgroundColor: UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0),
        indentGuideColor: UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0),
        errorColor: UIColor(red: 0.85, green: 0.00, blue: 0.00, alpha: 1.0),
        warningColor: UIColor(red: 0.85, green: 0.65, blue: 0.00, alpha: 1.0)
    )
    
    // MARK: - Atom One Light
    public static let atomOneLight = CodeEditorTheme(
        name: "Atom One Light",
        backgroundColor: UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0),      // #fafafa
        textColor: UIColor(red: 0.22, green: 0.23, blue: 0.26, alpha: 1.0),            // #383a42
        keywordColor: UIColor(red: 0.65, green: 0.15, blue: 0.64, alpha: 1.0),         // #a626a4 (Purple)
        stringColor: UIColor(red: 0.31, green: 0.63, blue: 0.31, alpha: 1.0),          // #50a14f (Green)
        commentColor: UIColor(red: 0.63, green: 0.64, blue: 0.66, alpha: 1.0),         // #a0a1a7 (Gray)
        numberColor: UIColor(red: 0.60, green: 0.40, blue: 0.16, alpha: 1.0),          // #986801 (Orange/Brown)
        functionColor: UIColor(red: 0.25, green: 0.47, blue: 0.85, alpha: 1.0),        // #4078f2 (Blue)
        operatorColor: UIColor(red: 0.22, green: 0.23, blue: 0.26, alpha: 1.0),
        typeColor: UIColor(red: 0.74, green: 0.56, blue: 0.16, alpha: 1.0),            // #be8f28 (Mustard)
        propertyColor: UIColor(red: 0.88, green: 0.33, blue: 0.34, alpha: 1.0),        // #e45649 (Red)
        lineNumberColor: UIColor(red: 0.63, green: 0.64, blue: 0.66, alpha: 1.0),
        lineNumberBackground: UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0),
        cursorColor: UIColor(red: 0.32, green: 0.36, blue: 0.95, alpha: 1.0),          // #526fff
        selectionColor: UIColor(red: 0.91, green: 0.93, blue: 0.96, alpha: 1.0),       // #e5e5e6
        currentLineColor: UIColor(red: 0.94, green: 0.94, blue: 0.95, alpha: 1.0),     // #f0f0f1
        bracketMatchColor: UIColor(red: 0.32, green: 0.36, blue: 0.95, alpha: 0.2),
        minimapBackgroundColor: UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0),
        indentGuideColor: UIColor(red: 0.88, green: 0.88, blue: 0.89, alpha: 1.0),
        errorColor: UIColor(red: 0.88, green: 0.33, blue: 0.34, alpha: 1.0),
        warningColor: UIColor(red: 0.74, green: 0.56, blue: 0.16, alpha: 1.0)
    )
    
    // MARK: - Solarized Light
    public static let solarizedLight = CodeEditorTheme(
        name: "Solarized Light",
        backgroundColor: UIColor(red: 0.99, green: 0.96, blue: 0.89, alpha: 1.0),      // #fdf6e3
        textColor: UIColor(red: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),            // #657b83
        keywordColor: UIColor(red: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),         // #859900 (Green)
        stringColor: UIColor(red: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),          // #2aa198 (Cyan)
        commentColor: UIColor(red: 0.58, green: 0.63, blue: 0.63, alpha: 1.0),         // #93a1a1
        numberColor: UIColor(red: 0.83, green: 0.21, blue: 0.51, alpha: 1.0),          // #d33682 (Magenta)
        functionColor: UIColor(red: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),        // #268bd2 (Blue)
        operatorColor: UIColor(red: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),
        typeColor: UIColor(red: 0.71, green: 0.54, blue: 0.00, alpha: 1.0),            // #b58900 (Yellow)
        propertyColor: UIColor(red: 0.80, green: 0.29, blue: 0.09, alpha: 1.0),        // #cb4b16 (Orange)
        lineNumberColor: UIColor(red: 0.58, green: 0.63, blue: 0.63, alpha: 1.0),
        lineNumberBackground: UIColor(red: 0.93, green: 0.91, blue: 0.84, alpha: 1.0), // #eee8d5
        cursorColor: UIColor(red: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),
        selectionColor: UIColor(red: 0.58, green: 0.63, blue: 0.63, alpha: 0.3),
        currentLineColor: UIColor(red: 0.93, green: 0.91, blue: 0.84, alpha: 0.5),     // #eee8d5
        bracketMatchColor: UIColor(red: 0.15, green: 0.55, blue: 0.82, alpha: 0.3),
        minimapBackgroundColor: UIColor(red: 0.97, green: 0.95, blue: 0.89, alpha: 1.0),
        indentGuideColor: UIColor(red: 0.85, green: 0.82, blue: 0.75, alpha: 1.0),
        errorColor: UIColor(red: 0.86, green: 0.20, blue: 0.18, alpha: 1.0),           // #dc322f
        warningColor: UIColor(red: 0.71, green: 0.54, blue: 0.00, alpha: 1.0)
    )
}

// MARK: - Registry
extension CodeEditorTheme {
    // Consolidated Registry
    public static let allThemes: [CodeEditorTheme] = [
        // Dark
        modernDark, oneDarkPro, githubDark, dracula, monokaiPro, nord, solarizedDark, catppuccinMocha,
        // Light
        githubLight, xcodeLight, atomOneLight, solarizedLight
    ]
    
    // Bulletproof lookup (case-insensitive fallback)
    public static func theme(named name: String) -> CodeEditorTheme {
        return allThemes.first(where: { $0.name.lowercased() == name.lowercased() }) ?? .modernDark
    }
    
    // Helper Colors
    static let rainbowBracketColors: [UIColor] = [
        UIColor(red: 0.98, green: 0.78, blue: 0.25, alpha: 1.0),  // Gold
        UIColor(red: 0.85, green: 0.44, blue: 0.84, alpha: 1.0),  // Magenta
        UIColor(red: 0.38, green: 0.70, blue: 0.93, alpha: 1.0),  // Cyan
        UIColor(red: 0.55, green: 0.83, blue: 0.42, alpha: 1.0),  // Green
        UIColor(red: 1.0, green: 0.55, blue: 0.35, alpha: 1.0),   // Orange
        UIColor(red: 0.75, green: 0.55, blue: 0.95, alpha: 1.0)   // Purple
    ]
}