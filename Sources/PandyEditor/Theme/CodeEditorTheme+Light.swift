import UIKit
import FiveKit

//
//  CodeEditorTheme+Light.swift
//  PandyEditor 🐼
//
//  Light Theme Presets
//

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
