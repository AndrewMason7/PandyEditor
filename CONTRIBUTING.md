---
description: FiveKit compliance guidelines and safety patterns for PandyEditor
---

# FiveKit Compliance Workflow

This document outlines the strict engineering standards and patterns required for contributions to PandyEditor, based on FiveKit architectural principles.

## Core Principles

### 1. The Safety Quadruple

Every UI update method MUST include these four guards in order:

```swift
func updateSomeUI() {
    // GUARD 1: Feature Flag
    guard isFeatureEnabled else { return }
    
    // GUARD 2: Window Check (prevents off-screen CPU waste)
    guard window != nil else { return }
    
    // GUARD 3: Thread Safety
    if Thread.isMainThread.negated {
        DispatchQueue.main.async { [weak self] in self?.updateSomeUI() }
        return
    }
    
    // GUARD 4: Layout Validity
    guard bounds.width > 0 else { return }
    
    // ... actual update code
}
```

### 2. View Diffing (Lag Prevention)

NEVER write to UIView properties unless values have actually changed:

```swift
// ❌ BAD: Always writes, triggers layout
view.frame = newFrame

// ✅ GOOD: Only writes when needed
if abs(view.frame.origin.y - newFrame.origin.y) > 0.1 {
    view.frame = newFrame
}
```

### 3. Expressive Syntax (FoundationPlus)

Use FiveKit's FoundationPlus extensions for readability:

```swift
// ❌ BAD
if !condition { }
if array.isEmpty == false { }

// ✅ GOOD (FoundationPlus)
if condition.negated { }
if array.isEmpty.negated { }

// String subscripting
let char = text[i]  // FoundationPlus integer subscript
// Note: Do not define safe extensions locally. FiveKit/FoundationPlus handles this.
```

### 4. Delegate Trap Avoidance

Use NotificationCenter observers instead of adopting `self.delegate = self`:

```swift
// ❌ BAD: Consumer setting their own delegate breaks our logic
textView.delegate = self

// ✅ GOOD: Uses internal observation
NotificationCenter.default.addObserver(
    self,
    selector: #selector(textDidChange),
    name: UITextView.textDidChangeNotification,
    object: self
)
```

### 5. CrashGuard Utilities

Always use centralized safety utilities for bounds checking:

```swift
// ❌ BAD: Manual bounds checking (inconsistent)
guard index >= 0 && index < array.count else { return nil }

// ✅ GOOD: Centralized utility
CrashGuard.safeIndex(array, index)
CrashGuard.safeCharacter(string, index)
CrashGuard.validateRange(range, in: text)
```

### 6. Atomic Versioning (Race Protection)

For background work that updates UI, use version counters to discard stale results:

```swift
let editVersion = incrementTextVersion()

backgroundQueue.async {
    // Heavy work...
    let result = expensiveCalculation()
    
    DispatchQueue.main.async {
        // CRITICAL: Discard if text changed while we were working
        guard self.currentTextVersion() == editVersion else { return }
        self.applyResult(result)
    }
}
```

### 7. Dependency Management

Pin dependencies to semantic versions when available. For dependencies without version tags (like FiveKit), use `branch: "main"`:

```swift
// ✅ GOOD (when version tags exist)
.package(url: "...", from: "1.0.0")

// ✅ ALSO VALID (when no version tags exist, e.g., FiveKit)
.package(url: "https://github.com/FiveSheepCo/FiveKit.git", branch: "main")
```

> **Note:** FiveKit currently has no semantic version tags, so branch-based dependency is required.

## File Header Template

All Swift files must include this header:

```swift
//
//  FileName.swift
//  PandyEditor 🐼
//
//  Brief description of the file's purpose.
//
```

## Checklist for Pull Requests

Before submitting code, verify:

- [ ] All UI methods have the Safety Quadruple guards
- [ ] No direct UIView property writes without diffing
- [ ] Uses `.negated` instead of `!` for boolean negation
- [ ] Uses `CrashGuard` utilities for array/string access
- [ ] No `self.delegate = self` patterns
- [ ] Background work uses atomic versioning
- [ ] File has standard PandyEditor header
- [ ] Test coverage for new functionality
