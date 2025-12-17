import SwiftUI
import UIKit
import FiveKit

//
//  PandyEditor.swift
//  PandyEditor 🐼
//
//  The "Harmony" File: A SwiftUI wrapper that unifies all components
//  into a simple, declarative interface.
//

public struct PandyEditor: UIViewRepresentable {
    
    // MARK: - Bindings & State
    @Binding public var text: String
    public var language: SupportedLanguage
    public var theme: CodeEditorTheme
    public var fontSize: CGFloat
    
    // MARK: - Feature Flags
    public var showLineNumbers: Bool = true
    public var showMinimap: Bool = true
    public var showBracketMatching: Bool = true
    public var isEditable: Bool = true
    
    // MARK: - Initialization
    public init(
        text: Binding<String>,
        language: SupportedLanguage = .swift,
        theme: CodeEditorTheme = .modernDark,
        fontSize: CGFloat = 14
    ) {
        self._text = text
        self.language = language
        self.theme = theme
        self.fontSize = fontSize
    }
    
    // MARK: - Modifiers (SwiftUI Style)
    public func showLineNumbers(_ show: Bool) -> PandyEditor {
        var copy = self
        copy.showLineNumbers = show
        return copy
    }
    
    public func showMinimap(_ show: Bool) -> PandyEditor {
        var copy = self
        copy.showMinimap = show
        return copy
    }
    
    // MARK: - UIViewRepresentable Lifecycle
    
    public func makeUIView(context: Context) -> EditorView {
        let editor = EditorView()
        editor.isEditable = isEditable
        
        // Initial Configuration
        editor.setLanguage(language)
        editor.setTheme(theme)
        editor.updateFontSize(fontSize)
        
        // Features
        editor.showLineNumbers = showLineNumbers
        editor.showMinimap = showMinimap
        editor.showBracketMatching = showBracketMatching
        
        // Delegate for text changes
        editor.delegate = context.coordinator
        
        return editor
    }
    
    public func updateUIView(_ uiView: EditorView, context: Context) {
        // PREVENT LOOP: Only update text if it actually changed
        // (Coordinator handles updates from View -> Binding)
        if (uiView.text == text).negated {
            uiView.text = text
            // Force re-highlight if text content changes drastically externally
            uiView.forceSyntaxUpdate() 
        }
        
        // Dynamic Updates
        if (uiView.theme.name == theme.name).negated {
            uiView.setTheme(theme)
        }
        
        // Language update is expensive, check if changed
        // Note: EditorView should expose a getter for current language to check diff, 
        // but for now we just set it (internal check inside setLanguage handles opt).
        uiView.setLanguage(language)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: PandyEditor
        
        init(_ parent: PandyEditor) {
            self.parent = parent
        }
        
        public func textViewDidChange(_ textView: UITextView) {
            // Update Binding
            DispatchQueue.main.async {
                self.parent.text = textView.text
            }
        }
    }
}
