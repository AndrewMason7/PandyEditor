import SwiftUI
import FiveKit

/// A modern, glassmorphic command palette for PandyEditor.
/// Provides quick access to editor settings, themes, and languages.
public struct CommandPaletteView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Core State (Passed from EditorView)
    @ObservedObject var state: EditorState
    
    public init(state: EditorState) {
        self.state = state
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                // Background Glassmorphism
                Color(uiColor: state.theme.backgroundColor)
                    .ignoresSafeArea()
                
                List {
                    Section("Editor Settings") {
                        Toggle("Line Numbers", isOn: $state.showLineNumbers)
                        Toggle("Minimap", isOn: $state.showMinimap)
                        Toggle("Word Wrap", isOn: $state.wordWrapEnabled)
                        Toggle("Bracket Matching", isOn: $state.showBracketMatching)
                        Toggle("File Header", isOn: $state.showFileHeader)
                        
                        Stepper("Font Size: \(Int(state.fontSize))pt", value: $state.fontSize, in: 10...28)
                    }
                    
                    Section("Theme") {
                        Picker("Select Theme", selection: $state.theme) {
                            ForEach(CodeEditorTheme.allThemes, id: \.name) { theme in
                                Text(theme.name).tag(theme)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                    
                    Section("Language") {
                        Picker("Select Language", selection: $state.language) {
                            ForEach(SupportedLanguage.allCases, id: \.rawValue) { lang in
                                HStack {
                                    Image(systemName: lang.icon)
                                    Text(lang.rawValue)
                                }.tag(lang)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }
                .onChange(of: state.showLineNumbers) { _ in state.notifyUpdate() }
                .onChange(of: state.showMinimap) { _ in state.notifyUpdate() }
                .onChange(of: state.wordWrapEnabled) { _ in state.notifyUpdate() }
                .onChange(of: state.showBracketMatching) { _ in state.notifyUpdate() }
                .onChange(of: state.showFileHeader) { _ in state.notifyUpdate() }
                .onChange(of: state.fontSize) { _ in state.notifyUpdate() }
                .onChange(of: state.theme) { _ in state.notifyUpdate() }
                .onChange(of: state.language) { _ in state.notifyUpdate() }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .navigationTitle("Command Palette")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

/// Observable state for the Command Palette to communicate back to UIKit.
public class EditorState: ObservableObject {
    @Published var showLineNumbers: Bool
    @Published var showMinimap: Bool
    @Published var wordWrapEnabled: Bool
    @Published var showBracketMatching: Bool
    @Published var showFileHeader: Bool
    @Published var fontSize: CGFloat
    @Published var theme: CodeEditorTheme
    @Published var language: SupportedLanguage
    
    // Callbacks to trigger UIKit updates
    var onUpdate: () -> Void
    
    public init(
        showLineNumbers: Bool,
        showMinimap: Bool,
        wordWrapEnabled: Bool,
        showBracketMatching: Bool,
        showFileHeader: Bool,
        fontSize: CGFloat,
        theme: CodeEditorTheme,
        language: SupportedLanguage,
        onUpdate: @escaping () -> Void
    ) {
        self.showLineNumbers = showLineNumbers
        self.showMinimap = showMinimap
        self.wordWrapEnabled = wordWrapEnabled
        self.showBracketMatching = showBracketMatching
        self.showFileHeader = showFileHeader
        self.fontSize = fontSize
        self.theme = theme
        self.language = language
        self.onUpdate = onUpdate
    }
    
    func notifyUpdate() {
        onUpdate()
    }
}
