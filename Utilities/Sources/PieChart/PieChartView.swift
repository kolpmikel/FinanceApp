import UIKit

/// Круговая диаграмма (donut)
public class PieChartView: UIView {
    /// Массив сегментов
    public var entities: [Entity] = [] {
        didSet { setNeedsDisplay() }
    }

    /// Цвета для максимум 6 сегментов (5 основных + "Остальные")
    private let colors: [UIColor] = [
        UIColor(red: 0.95, green: 0.45, blue: 0.45, alpha: 1), // сегмент 1
        UIColor(red: 0.45, green: 0.75, blue: 0.95, alpha: 1), // сегмент 2
        UIColor(red: 0.95, green: 0.75, blue: 0.45, alpha: 1), // сегмент 3
        UIColor(red: 0.55, green: 0.95, blue: 0.45, alpha: 1), // сегмент 4
        UIColor(red: 0.75, green: 0.45, blue: 0.95, alpha: 1), // сегмент 5
        UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1)  // Остальные
    ]

    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), !entities.isEmpty else { return }
        // Собираем до 5 сегментов, остаток в "Остальные"
        let top5 = Array(entities.prefix(5))
        let rest = entities.dropFirst(5)
        var display = top5
        if !rest.isEmpty {
            let sumRest = rest.map({ $0.value }).reduce(0, +)
            display.append(Entity(value: sumRest, label: "Остальные"))
        }
        let total = display.map({ $0.value }).reduce(0, +)
        guard total > 0 else { return }

        // Параметры кольца
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.4
        let thickness = radius * 0.1
        var startAngle = -CGFloat.pi / 2

        // Рисуем сегменты штрихами (donut)
        for (i, ent) in display.enumerated() {
            let fraction = CGFloat((ent.value / total) as NSDecimalNumber)
            let endAngle = startAngle + fraction * 2 * .pi
            // Строим двухточечную дугу
            let path = UIBezierPath(arcCenter: center,
                                    radius: radius - thickness/2,
                                    startAngle: startAngle,
                                    endAngle: endAngle,
                                    clockwise: true)
            path.lineWidth = thickness
            colors[min(i, colors.count-1)].setStroke()
            path.stroke()
            startAngle = endAngle
        }

        // Отрисовка легенды внутри круга
        let legendRect = CGRect(x: center.x - radius * 0.6,
                                y: center.y - radius * 0.6,
                                width: radius * 1.2,
                                height: radius * 1.2)
        drawLegend(in: legendRect, items: display, total: total)
    }

    /// Рисует текст и цветные буллеты
    private func drawLegend(in rect: CGRect, items: [Entity], total: Decimal) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: paragraph,
            .foregroundColor: UIColor.label
        ]
        let lineHeight: CGFloat = 16
        for (i, ent) in items.enumerated() {
            let y = rect.origin.y + CGFloat(i) * lineHeight
            // кружок
            let bullet = UIBezierPath(ovalIn: CGRect(x: rect.origin.x,
                                                    y: y + 4,
                                                    width: 8,
                                                    height: 8))
            colors[min(i, colors.count-1)].setFill()
            bullet.fill()
            // текст
            let pct = ((ent.value / total) as NSDecimalNumber).doubleValue * 100
            let text = String(format: " %.0f%% %@", pct, ent.label)
            text.draw(at: CGPoint(x: rect.origin.x + 12, y: y), withAttributes: attrs)
        }
    }
}
