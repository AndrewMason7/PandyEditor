import UIKit

/// A protocol-oriented surface for the editor components.
/// This decouples views like Minimap and LineNumberView from the concrete EditorView,
/// improving testability and adhering to FiveKit's architectural standards.
internal protocol EditorSurface: AnyObject {
    var text: String? { get }
    var layoutManager: NSLayoutManager { get }
    var textContainer: NSTextContainer { get }
    var textContainerInset: UIEdgeInsets { get set }
    var contentOffset: CGPoint { get set }
    var contentSize: CGSize { get }
    var bounds: CGRect { get }
    var window: UIWindow? { get }
    
    func currentTextVersion() -> UInt64
    func setContentOffset(_ contentOffset: CGPoint, animated: Bool)
    func setNeedsDisplay()
    func setNeedsLayout()
}
