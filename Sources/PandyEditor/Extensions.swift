import UIKit
import SwiftUI
import FiveKit

//
//  Extensions.swift
//  PandyEditor 🐼
//
//  Contains the KeyboardToolbarView - a custom input accessory view with
//  language-specific quick keys, undo/redo, find, and cursor glide.
//
//  FEATURES:
//  - Language-Aware Keys: Different snippets for Swift, JS, Python, etc.
//  - Cursor Glide: Swipe on the button areas to move the cursor
//  - Haptic Feedback: Tactile response for all interactions
//
//  HOW GLIDE WORKS:
//  1. User starts pan gesture on left/right button stack (not on keys)
//  2. Horizontal movement accumulates in 10-point increments
//  3. Each threshold crossed moves cursor by 1 character
//  4. Light haptic feedback on each step
//
//  FIVEKIT COMPLIANCE:
//  - Expressive Syntax: Uses `.negated` for boolean inversion
//  - Safe Casts: Uses `as?` with guard instead of force unwrap
//  - Bounds Checking: Array access protected by index validation
//  - Weak Delegate: Prevents retain cycles
//

// MARK: - Keyboard Toolbar Delegate
protocol KeyboardToolbarDelegate: AnyObject {
    func toolbarDidTapKey(_ key: String)
    func toolbarDidTapUndo()
    func toolbarDidTapRedo()
    func toolbarDidTapFind()
    func toolbarDidTapDismiss()
    func toolbarDidTapMenu()
    func toolbarDidGlideCursor(offset: Int)
}

// MARK: - Key Cell
class ToolbarKeyCell: UICollectionViewCell {
    static let id = "KeyCell"
    
    let label = UILabel()
    let bgView = UIView()
    
    override var isHighlighted: Bool {
        didSet {
            bgView.backgroundColor = isHighlighted ? UIColor.white.withAlphaComponent(0.3) : UIColor.white.withAlphaComponent(0.1)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bgView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        bgView.layer.cornerRadius = 6
        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        label.textColor = .white
        label.font = .monospacedSystemFont(ofSize: 15, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bgView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            bgView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            bgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Toolbar View
class KeyboardToolbarView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    weak var delegate: KeyboardToolbarDelegate?
    
    struct KeyItem {
        let title: String
        let value: String
    }
    
    private var keys: [KeyItem] = []
    
    // UI Components
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private var collectionView: UICollectionView!
    private let leftStack = UIStackView()
    private let rightStack = UIStackView()
    
    // Fixed Buttons
    let undoBtn = UIButton(type: .system)
    let redoBtn = UIButton(type: .system)
    let findBtn = UIButton(type: .system)
    let menuBtn = UIButton(type: .system)
    let dismissBtn = UIButton(type: .system)
    
    // Glide Typing State
    private var lastPanX: CGFloat = 0
    private var accumulation: CGFloat = 0
    private let panThreshold: CGFloat = 10.0 // Points per character move
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 48))
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Background
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurView)
        
        // Separator
        let border = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 0.5))
        border.backgroundColor = UIColor(white: 1, alpha: 0.15)
        border.autoresizingMask = .flexibleWidth
        addSubview(border)
        
        // Collection View Layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 44, height: 40)
        layout.estimatedItemSize = .zero // Performance optimization
        layout.sectionInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ToolbarKeyCell.self, forCellWithReuseIdentifier: ToolbarKeyCell.id)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Stacks
        leftStack.axis = .horizontal
        leftStack.spacing = 2
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        
        rightStack.axis = .horizontal
        rightStack.spacing = 2
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(leftStack)
        addSubview(collectionView)
        addSubview(rightStack)
        
        // Setup Buttons
        configureBtn(undoBtn, icon: "arrow.uturn.backward", action: #selector(undoTap))
        configureBtn(redoBtn, icon: "arrow.uturn.forward", action: #selector(redoTap))
        configureBtn(findBtn, icon: "magnifyingglass", action: #selector(findTap))
        configureBtn(menuBtn, icon: "command", action: #selector(menuTap))
        configureBtn(dismissBtn, icon: "keyboard.chevron.compact.down", action: #selector(dismissTap))
        
        // Add to Stacks
        leftStack.addArrangedSubview(undoBtn)
        leftStack.addArrangedSubview(redoBtn)
        leftStack.addArrangedSubview(findBtn)
        
        rightStack.addArrangedSubview(menuBtn)
        rightStack.addArrangedSubview(dismissBtn)
        
        // Constraints
        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            leftStack.topAnchor.constraint(equalTo: topAnchor),
            leftStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftStack.widthAnchor.constraint(equalToConstant: 120), // 3 buttons
            
            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            rightStack.topAnchor.constraint(equalTo: topAnchor),
            rightStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightStack.widthAnchor.constraint(equalToConstant: 80), // 2 buttons
            
            collectionView.leadingAnchor.constraint(equalTo: leftStack.trailingAnchor, constant: 4),
            collectionView.trailingAnchor.constraint(equalTo: rightStack.leadingAnchor, constant: -4),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func configureBtn(_ btn: UIButton, icon: String, action: Selector) {
        btn.setImage(UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(weight: .medium)), for: .normal)
        btn.tintColor = .white
        btn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        btn.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            // Determine touch location
            let loc = pan.location(in: self)
            
            // Allow gliding ONLY if touch starts outside the scrolling collection view
            // i.e., on the Left/Right button stacks
            let inCV = collectionView.frame.contains(loc)
            return inCV.negated // FIVEKIT: Expressive Syntax
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        // EXAMPLE: Cursor glide accumulation
        // ┌────────────────────────────────────────────────────────────┐
        // │ User swipes 35 points to the right on the button stack    │
        // ├────────────────────────────────────────────────────────────┤
        // │ state=.began:  lastPanX=100, accumulation=0               │
        // │ state=.changed: x=115, diff=+15, accumulation=15 (< 10)   │
        // │ state=.changed: x=125, diff=+10, accumulation=25          │
        // │                 → 25/10 = 2 steps → cursor moves +2 chars │
        // │                 → accumulation = 25 - 20 = 5 (remainder)  │
        // │ state=.changed: x=135, diff=+10, accumulation=15          │
        // │                 → 15/10 = 1 step → cursor moves +1 char   │
        // │                 → accumulation = 15 - 10 = 5              │
        // └────────────────────────────────────────────────────────────┘
        //
        switch gesture.state {
        case .began:
            lastPanX = gesture.location(in: self).x
            accumulation = 0
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .changed:
            let x = gesture.location(in: self).x
            let diff = x - lastPanX
            lastPanX = x
            
            accumulation += diff
            
            // Threshold check: Only move cursor when enough movement accumulated
            if abs(accumulation) >= panThreshold {
                let steps = Int(accumulation / panThreshold)
                delegate?.toolbarDidGlideCursor(offset: steps)
                accumulation -= CGFloat(steps) * panThreshold // Keep remainder
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
        default:
            break
        }
    }
    
    // MARK: - Actions
    @objc func undoTap() { delegate?.toolbarDidTapUndo() }
    @objc func redoTap() { delegate?.toolbarDidTapRedo() }
    @objc func findTap() { delegate?.toolbarDidTapFind() }
    @objc func menuTap() { delegate?.toolbarDidTapMenu() }
    @objc func dismissTap() { delegate?.toolbarDidTapDismiss() }
    
    // MARK: - Public API
    func update(language: SupportedLanguage) {
        // FIVEKIT SAFETY GUARD: Thread
        if Thread.isMainThread.negated {
            DispatchQueue.main.async { [weak self] in self?.update(language: language) }
            return
        }
        
        switch language {
        case .javascript:
            setKeys(["{", "}", "(", ")", "[", "]", "=>", "const", "let", "func", ";", ".", "=", "!"])
        case .swift:
            setKeys(["{", "}", "(", ")", "[", "]", "func", "var", "let", "guard", "if", ".", ":", "->"])
        case .python:
            setKeys([":", "(", ")", "[", "]", "{", "}", "def", "class", "self", "import", "=", "\"", "'"])
        case .typescript:
            setKeys(["{", "}", ":", ";", "interface", "type", "any", "export", "async", "=>", "import", "as"])
        case .go:
            setKeys(["{", "}", ":=", "func", "struct", "chan", "go", "if", "nil", "defer", "map", "range"])
        case .rust:
            setKeys(["{", "}", "fn", "let", "mut", "::", "->", "impl", "match", "pub", "use", "&", "=>"])
        case .sql:
            setKeys(["SELECT", "FROM", "WHERE", "JOIN", "ON", "AND", "OR", "NULL", "INSERT", "UPDATE", "DELETE", ";"])
        case .html:
            setKeys(["<", ">", "/", "=", "\"", "div", "class", "id", "style", "src", "href"])
        case .css:
            setKeys(["{", "}", ":", ";", "#", ".", "px", "%", "rem", "em", "!important"])
        case .json:
            setKeys(["{", "}", "[", "]", ":", "\"", ",", "true", "false", "null"])
        }
    }
    
    private func setKeys(_ items: [String]) {
        self.keys = items.map { KeyItem(title: $0, value: $0) }
        collectionView.reloadData()
        
        // Scroll to start safely
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.keys.isEmpty.negated && self.collectionView.numberOfItems(inSection: 0) > 0 {
                self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
            }
        }
    }
    
    func setUndoState(canUndo: Bool, canRedo: Bool) {
        // FIVEKIT OPTIMIZATION: Diffing
        let currentUndoAlpha = undoBtn.alpha
        let targetUndoAlpha: CGFloat = canUndo ? 1.0 : 0.4
        
        if abs(currentUndoAlpha - targetUndoAlpha) > 0.01 {
            undoBtn.alpha = targetUndoAlpha
        }
        
        let currentRedoAlpha = redoBtn.alpha
        let targetRedoAlpha: CGFloat = canRedo ? 1.0 : 0.4
        
        if abs(currentRedoAlpha - targetRedoAlpha) > 0.01 {
            redoBtn.alpha = targetRedoAlpha
        }
    }
    
    // MARK: - CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return keys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // SAFETY: Use safe cast
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ToolbarKeyCell.id, for: indexPath) as? ToolbarKeyCell else {
            return UICollectionViewCell()
        }
        // SAFETY: Bounds check
        guard indexPath.item >= 0, indexPath.item < keys.count else {
            return cell
        }
        cell.label.text = keys[indexPath.item].title
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // SAFETY: Bounds check
        guard indexPath.item >= 0, indexPath.item < keys.count else { return }
        let key = keys[indexPath.item]
        delegate?.toolbarDidTapKey(key.value)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}