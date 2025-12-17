import Foundation
import UIKit

//
//  EditorView+Setup.swift
//  PandyEditor 🐼
//
//  Extension: Initialization & Component Setup
//
//  Handles the setup of the editor, including gestures,
//  observers, and UI component initialization.
//

extension EditorView {
    
    // MARK: - Setup
    
    internal func setup() {
        // Use expressive theme properties from the current highlighter
        backgroundColor = highlighter.theme.backgroundColor
        tintColor = highlighter.theme.cursorColor
        
        // Disable smart features that interfere with coding
        autocapitalizationType = .none
        autocorrectionType = .no
        spellCheckingType = .no
        smartQuotesType = .no
        smartDashesType = .no
        smartInsertDeleteType = .no
        
        // Typing Attributes (Prevent color flashing while typing)
        typingAttributes = [
            .font: highlighter.font,
            .foregroundColor: highlighter.theme.textColor
        ]
        
        if #available(iOS 16.0, *) { isFindInteractionEnabled = true }
        keyboardAppearance = .dark
        contentInsetAdjustmentBehavior = .scrollableAxes
        allowsEditingTextAttributes = true
        
        // Layout Config
        layoutManager.allowsNonContiguousLayout = false // Essential for accurate line numbers
        let rightPadding: CGFloat = showMinimap ? 70 : 12
        textContainerInset = UIEdgeInsets(top: 12, left: 50, bottom: 12, right: rightPadding)
        textContainer.lineFragmentPadding = 0
        
        // Component Setup
        setupCurrentLineHighlight()
        if showMinimap { setupMinimap() }
        setupAccessoryView()
        
        // Gestures
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        addGestureRecognizer(pinchGesture)
        
        // SAFETY: Internal Observation
        // We use NotificationCenter instead of `self.delegate = self`.
        // This avoids the "Delegate Trap" where a consumer setting their own delegate
        // would accidentally break our highlighting logic.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChangeInternal),
            name: UITextView.textDidChangeNotification,
            object: self
        )
        
        // KEYBOARD HANDLING
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Add Line Number View
        addSubview(lineNumberView)
    }
    
    // MARK: - Toolbar Setup
    
    internal func setupAccessoryView() {
        let toolbar = KeyboardToolbarView()
        toolbar.delegate = self
        toolbar.update(language: currentLanguage)
        self.keyboardToolbar = toolbar
        self.inputAccessoryView = toolbar
    }
}
