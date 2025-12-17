import UIKit
import FiveKit

//
//  CodeEditorTheme+Dark.swift
//  PandyEditor 🐼
//
//  Dark Theme Presets
//

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
    public static let catppuccinMocha = CodeEditorTheme(
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
