import Foundation

/// Модель одного сегмента круговой диаграммы
public struct Entity {
    public let value: Decimal
    public let label: String
    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
}
