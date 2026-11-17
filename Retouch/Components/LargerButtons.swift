import SwiftUI

extension EnvironmentValues {
    @Entry var isLargerButtons = false
}

enum LargerButtons {
    static let baseSize: CGFloat = 54
    static let minimumTypeSize = DynamicTypeSize.accessibility2

    static func typeSize(_ size: DynamicTypeSize, isLarger: Bool) -> DynamicTypeSize {
        isLarger ? max(size, minimumTypeSize) : size
    }

    static func controlSize(isLarger: Bool, typeSize: DynamicTypeSize) -> CGFloat {
        guard isLarger else { return baseSize }
        let font = PickerMetrics.font(for: Self.typeSize(typeSize, isLarger: true))
        return PickerMetrics.height(baseSize, font: font)
    }
}

extension View {
    func largerButtonsTypeSize(_ isLarger: Bool) -> some View {
        dynamicTypeSize(isLarger ? LargerButtons.minimumTypeSize... : DynamicTypeSize.xSmall...)
    }
}
