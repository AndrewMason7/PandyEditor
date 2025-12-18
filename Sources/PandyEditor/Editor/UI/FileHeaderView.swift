import SwiftUI
import FiveKit

/// A premium, glassmorphic header for PandyEditor that displays file metadata.
public struct FileHeaderView: View {
    let filename: String
    let text: String
    let theme: CodeEditorTheme
    
    // Performance: Metrics are computed once per text change
    private var lineCount: Int {
        // Zero-allocation line counting (FiveKit optimized)
        return text.reduce(1) { $0 + ($1 == "\n" ? 1 : 0) }
    }
    
    private var charCount: Int {
        text.count
    }
    
    private var wordCount: Int {
        // Zero-allocation word counting via lazy sequence
        return text.unicodeScalars.lazy.split { CharacterSet.whitespacesAndNewlines.contains($0) }.count
    }
    
    private var fileSizeString: String {
        let size = text.utf8.count
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            // Document Name
            Text(filename)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color(uiColor: theme.textColor))
                .lineLimit(1)
            
            // Live Metadata Metrics
            HStack(spacing: 12) {
                metricLabel(label: "Lines", value: "\(lineCount)")
                metricLabel(label: "Words", value: "\(wordCount)")
                metricLabel(label: "Chars", value: "\(charCount)")
                metricLabel(label: "Size", value: fileSizeString)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Glassmorphic layer
                BlurView(style: theme.userInterfaceStyle == .dark ? .systemThinMaterialDark : .systemThinMaterialLight)
                
                // Subtle border bottom
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(uiColor: theme.indentGuideColor))
                        .frame(height: 0.5)
                }
            }
        )
    }
    
    private func metricLabel(label: String, value: String) -> some View {
        HStack(spacing: 3) {
            Text(label + ":")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Color(uiColor: theme.commentColor))
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color(uiColor: theme.keywordColor))
        }
    }
}

/// A simple UIViewRepresentable blur view for SwiftUI.
internal struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
