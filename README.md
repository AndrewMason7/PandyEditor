# 🐼 Pandy Editor

<p align="center">
  <img src="Assets/icon.jpg" width="120" alt="Pandy Editor Icon" />
</p>

<p align="center">
  <strong>A professional-grade, high-performance code editor component for iOS</strong><br/>
  Engineered to <strong>Strict FiveKit Compliance</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/FiveKit-Certified-success?style=flat-square" alt="FiveKit Certified" />
  <img src="https://img.shields.io/badge/iOS-15.0%2B-blue?style=flat-square" alt="iOS 15+" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square" alt="Swift 5.9" />
</p>

---

## 📖 Overview

**Pandy Editor** is not just a `UITextView` wrapper. It is a fully engineered code editing environment built on the **FiveKit/FoundationPlus** architecture.

### Why "Pandy"?
- 🐼 **Gentle** - Won't crash, even with malformed input
- 🐼 **Calm** - Smooth 120Hz scrolling, no UI stutter
- 🐼 **Cuddly** - Friendly, easy to integrate

### Core Principles
| Principle | Implementation |
|-----------|----------------|
| **Lag Prevention** | View Diffing + Viewport Optimization |
| **Crash Prevention** | Safety Quadruple (4-layer guards) |
| **Thread Safety** | Main thread UI, background computation |
| **Expressive Code** | FiveKit syntax (`.negated`, `text[i]`) |

---

## ✨ Key Features

### ⚡️ FiveKit Engineered
*   **ProMotion Optimized**: Uses **"View Diffing"** to minimize layer updates during typing and scrolling, ensuring buttery smooth performance on 120Hz devices.
*   **Safety Quadruple**: All UI operations are protected by four layers of safety guards (Feature Flag, Window Check, Thread Safety, Layout Validity).
*   **FoundationPlus**: Built using expressive, safe syntax (`.negated`, `String.empty`, `text[safe: i]`) provided via `FiveKit` export.

### 🚀 Performance Optimizations
*   **Viewport-Based Highlighting**: Syntax colors are only applied to the visible range + 50% buffer. A 10,000-line file only highlights ~50 lines at a time.
*   **Bracket Matching Cache**: Cursor position is cached to avoid O(n) re-scans when the cursor hasn't moved.
*   **Atomic Text Versioning**: Rapid keystrokes invalidate stale background work, preventing race conditions.
*   **Regex Caching**: Patterns are compiled once per language, reused forever.
*   **Large File Protection**: Files >150K characters gracefully degrade to plain text.

### 🛠 Editor Capabilities
*   **Syntax Highlighting**: Real-time highlighting for Swift, Python, JS, HTML, JSON, and more.
*   **Line Numbers**: Integrated, synchronized gutter with O(log n) binary search.
*   **Minimap**: Scaled, clickable code overview with background rendering.
*   **Bracket Matching**: Rainbow brackets with intelligent matching.
*   **Current Line Highlight**: Subtle background highlight for better orientation.
*   **Keyboard Toolbar**: Language-specific quick keys with cursor glide.
*   **Rich Theming**: 12+ professionally tuned themes (Light/Dark).

---

## 📦 Installation

Add the following to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/AndrewMason7/PandyEditor.git", branch:"main"),
]
```

## 🚀 Usage

### Basic Setup

The `CodeEditorTextView` manages its own subcomponents (Line Numbers, Highlight Views). Just instantiate and configure:

```swift
import PandyEditor

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Create the editor
        let editor = CodeEditorTextView()
        editor.frame = view.bounds
        editor.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 2. Configure Syntax & Theme
        editor.setLanguage(.swift)
        editor.setTheme(.modernDark)
        
        // 3. Enable Features
        editor.showMinimap = true
        editor.showCurrentLineHighlight = true
        editor.showBracketMatching = true
        editor.showRainbowBrackets = true
        
        // 4. Set Content
        editor.text = """
        func greet() {
            print("Hello, Pandy Editor! 🐼")
        }
        """
        
        view.addSubview(editor)
    }
}
```

### 🎨 Available Themes

| Theme | Style |
|-------|-------|
| `.modernDark` | Premium Blue/Slate (Default) |
| `.dracula` | Classic purple/pink |
| `.oneDarkPro` | VS Code inspired |
| `.monokaiPro` | Warm syntax colors |
| `.githubDark` / `.githubLight` | GitHub style |
| `.xcodeDark` / `.xcodeLight` | Apple classic |
| `.solarizedDark` / `.solarizedLight` | Low contrast |
| `.nord` | Arctic, bluish |
| `.catppuccinMocha` | Pastel dark |
| `.tokyoNight` | Vibrant purple/blue |

### 💻 Supported Languages

| Language | Extensions |
|----------|------------|
| Swift | `.swift` |
| JavaScript | `.js`, `.jsx`, `.mjs` |
| TypeScript | `.ts`, `.tsx` |
| Python | `.py`, `.pyw` |
| Go | `.go` |
| Rust | `.rs` |
| SQL | `.sql` |
| HTML | `.html`, `.htm` |
| CSS | `.css`, `.scss` |
| JSON | `.json` |

---

## 🏗 Architecture

The project follows the **FiveKit Modular Pattern**:

```
PandyEditor/
├── Editor/             # Core Components
│   ├── CodeEditorTextView.swift    # Main Public API
│   ├── LineNumberView.swift        # Gutter (O(log n) lookup)
│   └── MinimapView.swift           # Code Overview
├── Syntax/             # Highlighting Engine
│   ├── SyntaxHighlighter.swift     # Two-Phase Viewport Optimizer
│   └── SyntaxLanguages.swift       # Language Definitions
├── Theme/              # Visual System
│   └── CodeEditorTheme.swift       # 12+ Color Palettes
└── Utilities/
    ├── CrashPrevention.swift       # Safety Guards
    └── Extensions.swift            # Keyboard Toolbar
```

### 🔄 Highlighting Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                 PANDY EDITOR SYNTAX ENGINE                  │
├─────────────────────────────────────────────────────────────┤
│  PHASE 1: Global Context Scan (Full Document)               │
│  ├── Find all Strings  ───────────────────────► [ranges]    │
│  ├── Find all Comments ───────────────────────► [ranges]    │
│  └── Resolve Overlaps (First match wins)                    │
├─────────────────────────────────────────────────────────────┤
│  PHASE 2: Viewport Optimization                              │
│  ├── Calculate Visible Range + 50% Buffer                   │
│  └── Skip attribute application for off-screen ranges       │
├─────────────────────────────────────────────────────────────┤
│  PHASE 3: Keyword Scan (Visible Code Gaps Only)             │
│  ├── Find Keywords  ──────────────────────────► [color]     │
│  ├── Find Numbers   ──────────────────────────► [color]     │
│  └── Find Functions ──────────────────────────► [color]     │
└─────────────────────────────────────────────────────────────┘
```

---

## 📜 License

MIT License. Copyright (c) 2025 Andrew Mason.

---

## 🐼 Credits

<p align="center">
  <img src="Assets/icon.jpg" width="80" alt="Pandy Editor" />
</p>

<p align="center">
  Built with ❤️
</p>

<p align="center">
  <em>"Gentle. Calm. Cuddly."</em>
</p>
