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

public struct PandyEditor: View {
    
    // MARK: - Bindings & State
    @Binding public var text: String
    public var filename: String = "Untitled"
    public var language: SupportedLanguage
    public var theme: CodeEditorTheme
    public var fontSize: CGFloat
    
    // MARK: - Feature Flags
    public var showLineNumbers: Bool = true
    public var showMinimap: Bool = true
    public var showBracketMatching: Bool = true
    public var showFileHeader: Bool = true
    public var isEditable: Bool = true
    
    // MARK: - Initialization
    public init(
        text: Binding<String>,
        filename: String = "Untitled",
        language: SupportedLanguage = .swift,
        theme: CodeEditorTheme = .oneDarkPro,
        fontSize: CGFloat = 14
    ) {
        self._text = text
        self.filename = filename
        self.language = language
        self.theme = theme
        self.fontSize = fontSize
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            EditorBridge(
                text: $text,
                parentFilename: filename,
                language: language,
                theme: theme,
                fontSize: fontSize,
                showLineNumbers: showLineNumbers,
                showMinimap: showMinimap,
                showBracketMatching: showBracketMatching,
                showFileHeader: showFileHeader,
                isEditable: isEditable
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            if showFileHeader {
                FileHeaderView(filename: filename, text: text, theme: theme)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .background(Color(uiColor: theme.backgroundColor))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showFileHeader)
    }
    
    // MARK: - Modifiers
    public func showFileHeader(_ show: Bool) -> PandyEditor {
        var copy = self
        copy.showFileHeader = show
        return copy
    }
    
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
}

// MARK: - Internal Bridge
/// The actual UIViewRepresentable that hosts the UIKit EditorView.
internal struct EditorBridge: UIViewRepresentable {
    @Binding var text: String
    var parentFilename: String
    var language: SupportedLanguage
    var theme: CodeEditorTheme
    var fontSize: CGFloat
    var showLineNumbers: Bool
    var showMinimap: Bool
    var showBracketMatching: Bool
    var showFileHeader: Bool
    var isEditable: Bool
    
    func makeUIView(context: Context) -> EditorView {
        let editor = EditorView()
        editor.isEditable = isEditable
        
        // EAGER CONFIGURATION: Set language and theme BEFORE returning
        // to prevent the "Initialization Flash"
        editor.setLanguage(language)
        editor.setTheme(theme)
        editor.updateFontSize(fontSize)
        
        // Features (Order matters: set flags BEFORE setup/insets)
        editor.showLineNumbers = showLineNumbers
        editor.showMinimap = showMinimap
        editor.showBracketMatching = showBracketMatching
        editor.showFileHeader = showFileHeader
        
        // Sync State Bridge initially
        editor.editorState.showLineNumbers = showLineNumbers
        editor.editorState.showMinimap = showMinimap
        editor.editorState.fontSize = fontSize
        editor.editorState.theme = theme
        editor.editorState.language = language
        
        // Delegate for text changes
        editor.delegate = context.coordinator
        
        return editor
    }
    
    func updateUIView(_ uiView: EditorView, context: Context) {
        // REFRESH COORDINATOR: Ensure parent binding is current
        context.coordinator.parent = self
        
        // PREVENT LOOP: Only update text if it actually changed
        if (uiView.text == text).negated {
            uiView.text = text
            uiView.forceSyntaxUpdate()
        }
        
        // Dynamic Updates
        if (uiView.theme.name == theme.name).negated {
            uiView.setTheme(theme)
        }
        
        if uiView.currentLanguage != language {
            uiView.setLanguage(language)
        }
        
        // --- DIFF-AWARE FEATURE SYNC ---
        // We only apply struct properties if they differ from what we last saw.
        // This prevents the "Revert on Redraw" bug when the user changes settings
        // via the internal Command Palette but the parent struct properties are static.
        
        let coordinator = context.coordinator
        
        if coordinator.lastShowLineNumbers != showLineNumbers {
            uiView.showLineNumbers = showLineNumbers
            coordinator.lastShowLineNumbers = showLineNumbers
        }
        
        if coordinator.lastShowMinimap != showMinimap {
            uiView.showMinimap = showMinimap
            coordinator.lastShowMinimap = showMinimap
        }
        
        if coordinator.lastShowBracketMatching != showBracketMatching {
            uiView.showBracketMatching = showBracketMatching
            coordinator.lastShowBracketMatching = showBracketMatching
        }
        
        if coordinator.lastFontSize != fontSize {
            uiView.updateFontSize(fontSize)
            coordinator.lastFontSize = fontSize
        }
        
        if coordinator.lastThemeName != theme.name {
            uiView.setTheme(theme)
            coordinator.lastThemeName = theme.name
        }
        
        if coordinator.lastShowFileHeader != showFileHeader {
            uiView.showFileHeader = showFileHeader
            coordinator.lastShowFileHeader = showFileHeader
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: EditorBridge
        
        var lastShowLineNumbers: Bool?
        var lastShowMinimap: Bool?
        var lastShowBracketMatching: Bool?
        var lastShowFileHeader: Bool?
        var lastFontSize: CGFloat?
        var lastThemeName: String?
        var lastFilename: String?
        
        init(_ parent: EditorBridge) {
            self.parent = parent
            
            // Initial state capture
            self.lastShowLineNumbers = parent.showLineNumbers
            self.lastShowMinimap = parent.showMinimap
            self.lastShowBracketMatching = parent.showBracketMatching
            self.lastShowFileHeader = parent.showFileHeader
            self.lastFontSize = parent.fontSize
            self.lastThemeName = parent.theme.name
            self.lastFilename = parent.parentFilename
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // Update Binding on Main Thread (Safety Guard)
            CrashGuard.onMainThread {
                self.parent.text = textView.text
            }
        }
    }
}

