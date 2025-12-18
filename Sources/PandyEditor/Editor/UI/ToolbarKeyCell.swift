//
//  ToolbarKeyCell.swift
//  PandyEditor 🐼
//
//  Component: Keyboard Toolbar Key Cell
//
//  A reusable collection view cell representing a quick key in the keyboard toolbar.
//  Provides visual feedback on highlight and configurable key labels.
//

import UIKit

// MARK: - Key Cell
public class ToolbarKeyCell: UICollectionViewCell {
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
            bgView.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            label.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -12)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
