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
  <img src="https://img.shields.io/badge/Tests-Passing-brightgreen?style=flat-square" alt="Tests Passing" />
</p>

---

## 📖 Overview

**Pandy Editor** is not just a `UITextView` wrapper. It is a fully engineered code editing environment built on the **FiveKi** architecture.

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
*   **FoundationPlus**: Built using expressive, safe syntax (`.negated`, `String.empty`, `text[i]`) provided via `FiveKit` export.
*   **Branch Dependency**: FiveKit uses `branch: "main"`

### 🚀 Performance Optimizations
*   **Viewport-Based Highlighting**: Syntax colors are only applied to the visible range + 50% buffer. A 10,000-line file only highlights ~50 lines at a time.
*   **Bracket Matching Cache**: Cursor position is cached to avoid O(n) re-scans when the cursor hasn't moved.
*   **Atomic Text Versioning**: Rapid keystrokes invalidate stale background work, preventing race conditions.
*   **Regex Caching**: Patterns are compiled once per language, reused forever.
*   **Large File Protection**: Files >150K characters gracefully degrade to plain text.

### 🛠 Editor Capabilities
*   **Syntax Highlighting**: Real-time highlighting for 11 languages (Swift, Python, JS, TS, Go, Rust, SQL, HTML, CSS, JSON, Plain Text).
*   **Line Numbers**: Integrated, synchronized gutter with O(log n) binary search.
*   **Minimap**: Scaled, clickable code overview with background rendering.
*   **Bracket Matching**: Rainbow brackets with intelligent matching.
*   **Current Line Highlight**: Subtle background highlight for better orientation.
*   **Keyboard Toolbar**: Language-specific quick keys with cursor glide.
*   **Rich Theming**: 9 professionally tuned themes (5 Dark + 4 Light).

---

## 📦 Installation

Add the following to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/AndrewMason7/PandyEditor.git", branch: "main"),
]
```

## 🚀 Usage
    
### SwiftUI (Recommended)

Use the `PandyEditor` wrapper for a seamless SwiftUI experience:

```swift
import PandyEditor

struct ContentView: View {
    @State private var code = "func hello() {}"
    
    var body: some View {
        PandyEditor(text: $code, language: .swift, theme: .modernDark)
            .showLineNumbers(true)
            .showMinimap(true)
            .edgesIgnoringSafeArea(.all)
    }
}
```

### UIKit (Advanced)
    
The `EditorView` manages its own subcomponents (Line Numbers, Highlight Views). Just instantiate and configure:

```swift
import PandyEditor

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Create the editor
        let editor = EditorView()
        editor.frame = view.bounds
        editor.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 2. Configure Syntax & Theme
        editor.setLanguage(.swift)
        editor.setTheme(.modernDark)
        
        // 3. Enable Features
        editor.showLineNumbers = true
        editor.showMinimap = true
        editor.showCurrentLineHighlight = true
        editor.showBracketMatching = true
        
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

**Dark Themes:**
| Theme | Style |
|-------|-------|
| `.modernDark` | Premium Blue/Slate (Default) |
| `.oneDarkPro` | VS Code inspired |
| `.githubDark` | GitHub style |
| `.dracula` | Classic purple/pink |
| `.catppuccinMocha` | Pastel dark |

**Light Themes:**
| Theme | Style |
|-------|-------|
| `.githubLight` | GitHub style |
| `.xcodeLight` | Apple classic |
| `.atomOneLight` | Atom-inspired |
| `.solarizedLight` | Low contrast |

### 💻 Supported Languages

| Language | Extensions | Quick Keys |
|----------|------------|------------|
| Plain Text | `.txt`, `.md` | Generic punctuation |
| Swift | `.swift` | `func`, `guard`, `let`, `->` |
| JavaScript | `.js`, `.jsx`, `.mjs` | `const`, `=>`, `function` |
| TypeScript | `.ts`, `.tsx` | `interface`, `type`, `async` |
| Python | `.py`, `.pyw` | `def`, `class`, `self` |
| Go | `.go` | `func`, `:=`, `chan`, `defer` |
| Rust | `.rs` | `fn`, `mut`, `impl`, `match` |
| SQL | `.sql` | `SELECT`, `FROM`, `WHERE` |
| HTML | `.html`, `.htm` | `<`, `>`, `div`, `class` |
| CSS | `.css`, `.scss` | `px`, `rem`, `!important` |
| JSON | `.json` | `true`, `false`, `null` |

---

## 🏗 Architecture

The project follows the **FiveKit Modular Pattern**:

```
PandyEditor/
├── Sources/PandyEditor/
│   ├── Editor/                     # Core Components
│   │   ├── PandyEditor.swift           # SwiftUI Wrapper ("Harmony File")
│   │   ├── EditorView.swift            # Main Class Definition
│   │   ├── EditorView+API.swift        # Public API & User Controls
│   │   ├── EditorView+Bracket.swift    # Bracket Matching
│   │   ├── EditorView+Keyboard.swift   # Keyboard & Toolbar Delegation
│   │   ├── EditorView+Layout.swift     # Layout & Rendering
│   │   ├── EditorView+Setup.swift      # Initialization
│   │   ├── LineNumberView.swift        # Gutter (O(log n) lookup)
│   │   ├── MinimapView.swift           # Code Overview
│   │   ├── KeyboardToolbarView.swift   # Quick Keys & Cursor Glide
│   │   ├── Syntax/                     # Highlighting Engine
│   │   │   ├── EditorView+Syntax.swift     # Text Change Handling
│   │   │   ├── SyntaxHighlighter.swift     # Two-Phase Optimizer
│   │   │   └── SyntaxLanguages.swift       # 11 Language Definitions
│   │   └── UI/
│   │       └── ToolbarKeyCell.swift    # Keyboard Quick Key Cell
│   ├── Theme/                      # Visual System
│   │   ├── CodeEditorTheme.swift       # Registry & Core
│   │   ├── CodeEditorTheme+Dark.swift  # 5 Dark Themes
│   │   └── CodeEditorTheme+Light.swift # 4 Light Themes
│   ├── Utilities/                  # Safety & Extensions
│   │   ├── CrashGuard.swift            # Safety Quadruple Utilities
│   │   ├── Validator.swift             # Input Validation
│   │   └── Extensions/                 # Safe Type Extensions
│   │       ├── Data+Safe.swift
│   │       ├── URL+Safe.swift
│   │       └── FileManager+Safe.swift
│   └── Resources/
│       └── icon.jpg                    # Bundled Asset
└── Tests/PandyEditorTests/
    └── PandyEditorTests.swift          # Unit Tests
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

## 🐑 Thank You

Special thanks to [**FiveSheep Co.**](https://github.com/FiveSheepCo) for creating and maintaining:

- **[FiveKit](https://github.com/FiveSheepCo/FiveKit)** - The foundation this editor is built upon
- **[FoundationPlus](https://github.com/FiveSheepCo/FoundationPlus)** - Expressive Swift extensions that make code readable
- **[SwiftUIElements](https://github.com/FiveSheepCo/SwiftUIElements)** - SwiftUI utilities

Their work on developer tooling has made this project possible.

Check out the their extraordinary **[Mister Keyboard](https://apps.apple.com/be/app/mister-keyboard-build-type/id6670610903)** on the App Store — The infinitely customizable keyboard.

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

---

## 📜 License

MIT License. Copyright (c) 2025 Andrew Mason.
