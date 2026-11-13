import SwiftUI
import UIKit

enum PickerMetrics {
    private static let baseSize: CGFloat = 15
    private static let textVerticalInset: CGFloat = 18

    static func font(for typeSize: DynamicTypeSize) -> UIFont {
        let regular = UIFont.systemFont(ofSize: baseSize, weight: .regular)
        let base = regular.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: baseSize) } ?? regular
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(typeSize))
        return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: base, compatibleWith: traits)
    }

    static func textWidth(_ text: String, font: UIFont) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    static func height(_ minimum: CGFloat, font: UIFont) -> CGFloat {
        max(minimum, ceil(font.lineHeight) + 2 * textVerticalInset)
    }
}
