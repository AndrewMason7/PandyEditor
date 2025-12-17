import Foundation
import UIKit
import FiveKit

//
//  CodeEditorTheme.swift
//  PandyEditor 🐼
//
//  Defines the CodeEditorTheme struct and registry.
//  See +Dark.swift and +Light.swift for specific theme definitions.
//
//  THEME STRUCTURE:
//  - Syntax Colors: keywords, strings, comments, numbers, functions, types
//  - UI Colors: background, text, cursor, selection, current line
//  - Gutter Colors: line numbers, minimap background
//  - Feedback Colors: error, warning, bracket match
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

// MARK: - Registry
extension CodeEditorTheme {
    // Consolidated Registry
    // Note: Some themes might be defined in other files not visible in this refactor.
    // If you encounter "Identifier not found", ensure all theme files are included.
    public static let allThemes: [CodeEditorTheme] = [
        // Dark
        modernDark, oneDarkPro, githubDark, dracula, catppuccinMocha,
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